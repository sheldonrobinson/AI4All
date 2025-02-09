#include <map>
#include <filesystem>
#include <thread>
#include <regex>
// #include <tokenizers_cpp.h>
#include <sentencepiece_processor.h>
#include <ctranslate2/encoder.h>
#include <cpuinfo.h>
#include <armadillo>
#include <minimal_uuid4.h>
#include <pthreadpool.h>

#include "duckdb.h"

#include "unnu_ragl.h"


#if defined(__WIN32__) || defined(_WIN32) || defined(WIN32) || defined(__WINDOWS__) || defined(__TOS_WIN__)

#include <windows.h>

inline void delay(unsigned long ms)
{
	Sleep(ms);
}

#else  /* presume POSIX */

#include <unistd.h>

inline void delay(unsigned long ms)
{
	usleep(ms * 1000);
}

#endif

typedef std::unique_ptr<sentencepiece::SentencePieceProcessor> sentencepiece_processor_ptr;
typedef std::unique_ptr<ctranslate2::Encoder> ct2_encoder_ptr;
typedef std::unique_ptr<duckdb_connection> duckdb_connection_ptr;
typedef std::unique_ptr< duckdb_prepared_statement> duckdb_prepared_statement_ptr;
static duckdb_connection_ptr dbconn = nullptr;
static duckdb_prepared_statement_ptr pstmt = nullptr;

static sentencepiece_processor_ptr _spp;
static ct2_encoder_ptr _encoder;

static std::map<std::string, duckdb_database*> kbhandles;

static UnnuRaglResponseCallback response_cb = nullptr;

typedef struct UnnuRagProcessInput {
	bool query = true;
	int count = 0;
	std::string text;
} UnnuRagProcessInput_t;

std::vector<std::string> _unnu_rag_lite_tokenize(const std::string& text) {
	std::vector<std::string> tokens;
	_spp->Encode(text, &tokens);
	return tokens;
}

std::string _unnu_rag_lite_detokenize(const std::vector<int>& tokens) {
	std::string text;
	_spp->Decode(tokens, &text);
	return text;
}

void unnu_rag_lite_init(const char* path) {
	const ctranslate2::Device device = ctranslate2::str_to_device("auto");
	ctranslate2::ComputeType compute_type = ctranslate2::ComputeType::INT8;

	const auto model = ctranslate2::models::Model::load(path, device, 0, compute_type);

	ctranslate2::ReplicaPoolConfig _config;
	_config.num_threads_per_replica = 1;
	// size_t num_replicas = 0;
	// size_t max_batch_size = 0;

	if (cpuinfo_initialize()) {
		int cores = cpuinfo_get_cores_count();
		if (cores > 2) {
			_config.max_queued_batches = 512;
			_config.num_threads_per_replica = cores / 2;
		}
		else {
			_config.max_queued_batches = 1024;
			// _config.num_threads_per_replica = cores / 2;
		}
	}

	_encoder = std::make_unique<ctranslate2::Encoder>(model, _config);
	_spp = std::make_unique<sentencepiece::SentencePieceProcessor>();

	std::filesystem::path _spm_path(path);
	_spm_path += std::string("sentencepiece.bpe.model");

	auto status = _spp->Load(_spm_path.generic_string());
	if (!status.ok()) {
		throw std::invalid_argument("Unable to open SentencePiece model");
	}
}

void _unnu_create_fts_index(int* errorCode) {
	auto query = "PRAGMA drop_fts_index(embeddings)";
	if (duckdb_query(*dbconn.get(), query, nullptr) == DuckDBError) {
		// handle error
		*errorCode = 5642;
	}

	query = "pragma create_fts_index(embeddings, frag_id,'text',stemmer = 'porter',stopwords = 'english', strip_accents = 1,lower = 1,overwrite = 1);";
	if (duckdb_query(*dbconn.get(), query, nullptr) == DuckDBError) {
		// handle error
		*errorCode = 156424;
		return;
	}
}

void _unnu_ragl_db_setup(duckdb_connection conn, int* errorCode) {
	auto query = "CREATE TABLE IF NOT EXISTS embeddings (embedding_id INTEGER PRIMARY KEY AUTOINCREMENT, frag_id VARCHAR(36), text VARCHAR, embedding FLOAT[768]);";
	if (duckdb_query(conn, query, nullptr) == DuckDBError) {
		// handle error
		*errorCode = 5642;
		return;
	}
	query = "CREATE INDEX IF NOT EXISTS embeddings_hnsw_index ON embeddings USING HNSW(embedding) WITH (metric = 'cosine');";
	if (duckdb_query(conn, query, nullptr) == DuckDBError) {
		// handle error
		*errorCode = 5642;
		return;
	}

	query = "pragma create_fts_index(embeddings, frag_id,'text',stemmer = 'porter',stopwords = 'english', strip_accents = 1,lower = 1,overwrite = 0);";
	if (duckdb_query(conn, query, nullptr) == DuckDBError) {
		// handle error
		*errorCode = 5642;
		return;
	}
	auto select = std::string("with fts as(select text, fts_main_embeddings.match_bm25(frag_id,?) as score from embeddings), ");
	select.append("embd as(select text, array_cosine_distance(embedding, ? ) as score from embeddings), ");
	select.append("normalized_scores as(select fts.text, fts.score as raw_fts_score, embd.score as raw_embd_score, ");
	select.append("(fts.score / (select max(score) from fts)) as norm_fts_score, ((embd.score + 1) / (select max(score) + 1 from embd)) as norm_embd_score ");
	select.append("from	fts	inner join	embd on fts.frag_id = embd.frag_id) ");
	select.append("select text, (0.8 * norm_embd_score + 0.2 * norm_fts_score) as score_cc from normalized_scores order by score_cc desc limit 5;");

	duckdb_prepared_statement* out_prepared_statement;
	if (duckdb_prepare(conn, select.c_str(), out_prepared_statement) == DuckDBError) {
		// handle error
		*errorCode = 1043;
		return;
	}
	pstmt = duckdb_prepared_statement_ptr(out_prepared_statement);
	*errorCode = 0;
}

void duckdb_destroy_value_ref(duckdb_value value) {
	duckdb_destroy_value(&value);
}

void _unnu_ragl_query_result(UnnuRaglResult_t* response) {
	if (response_cb != nullptr) {
		response_cb(response);
	}
}

void _unnu_ragl_query(const char* text, std::vector<float> embeddings, int* errorCode) {

	if (duckdb_clear_bindings(*pstmt.get()) == DuckDBError) {
		// handle error
		*errorCode = 1043;
		return;
	}

	auto type = duckdb_param_logical_type(*pstmt.get(), 2);
	std::vector<duckdb_value> _array(embeddings.size());
	std::transform(embeddings.cbegin(), embeddings.cend(), _array.begin(), duckdb_create_float);
	auto value = duckdb_create_array_value(type, _array.data(), _array.size());

	if (duckdb_bind_varchar(*pstmt.get(), 1, text) == DuckDBError) {
		// handle error
		*errorCode = 3091;
		return;
	}

	if (duckdb_bind_value(*pstmt.get(), 2, value) == DuckDBError) {
		// handle error
		*errorCode = 3091;
		return;
	}

	duckdb_result output;
	if (duckdb_execute_prepared(*pstmt.get(), &output) == DuckDBError) {
		// handle error
		*errorCode = 1043;
		return;
	}


	UnnuRaglResult_t response;
	// response.length = strlen(text);
	/* if (response.length > 0) {
		response.text = (char*)std::calloc(response.length + 1, sizeof(char));
		std::memcpy(response.text, text, response.length + 1);
	}*/
	std::vector< UnnuRaglFragment_t> fragments;
	// iterate until result is exhausted
	while (true) {
		duckdb_data_chunk result = duckdb_fetch_chunk(output);
		if (!result) {
			// result is exhausted
			break;
		}
		// get the number of rows from the data chunk
		idx_t row_count = duckdb_data_chunk_get_size(result);
		// get the first column
		duckdb_vector col1 = duckdb_data_chunk_get_vector(result, 0);
		auto col1_data = static_cast<duckdb_string_t *>(duckdb_vector_get_data(col1));
		uint64_t* col1_validity = duckdb_vector_get_validity(col1);

		// iterate over the rows
		for (idx_t row = 0; row < row_count; row++) {
			if (duckdb_validity_row_is_valid(col1_validity, row)) {
				UnnuRaglFragment_t frag;
				frag.length = duckdb_string_t_length(col1_data[row]);
				if (frag.length > 0) {
					frag.text = (char*)std::calloc(frag.length + 1, sizeof(char));
					auto data = duckdb_string_t_data(col1_data + row);
					std::memcpy(frag.text, data, frag.length + 1);
					fragments.push_back(frag);
				}
			}
		}
		duckdb_destroy_data_chunk(&result);
	}

	duckdb_destroy_result(&output);
	duckdb_destroy_value(&value);
	std::for_each(_array.begin(), _array.end(), duckdb_destroy_value_ref);
	duckdb_destroy_logical_type(&type);
	response.count = fragments.size();
	response.type = UnnuRaglResultType::UNNU_RAGL_QUERY;
	if (response.count > 0) {
		response.fragments = (UnnuRaglFragment_t*)std::calloc(response.count, sizeof(UnnuRaglFragment_t));
		std::memcpy(response.fragments, fragments.data(), response.count * sizeof(UnnuRaglFragment_t));
		_unnu_ragl_query_result(&response);
	}
}

void _unnu_ragl_insert_embedding(const char* text, std::vector<float> embeddings, int* errorCode) {
	minimal_uuid4::Generator gen;
	duckdb_appender appender;
	if (duckdb_appender_create(*dbconn.get(), nullptr, "embeddings", &appender) == DuckDBError) {
		// handle error
		*errorCode = 2323;
		return;
	}
	/*
	if (duckdb_appender_clear_columns(appender) == DuckDBError) {
		// handle error
		*errorCode = 14;
		return;
	}*/
	
	if (duckdb_appender_add_column(appender, "frag_id") == DuckDBError) {
		// handle error
		*errorCode = 2323;
		return;
	}
	
	if (duckdb_appender_add_column(appender, "text") == DuckDBError) {
		// handle error
		*errorCode = 2323;
		return;
	}
	
	if (duckdb_appender_add_column(appender, "embedding") == DuckDBError) {
		// handle error
		*errorCode = 2323;
		return;
	}
	
	std::vector<duckdb_logical_type> coltypes;
	coltypes.push_back(duckdb_appender_column_type(appender, 0));
	coltypes.push_back(duckdb_appender_column_type(appender, 1));
	coltypes.push_back(duckdb_appender_column_type(appender, 2));

	auto data_chunk = duckdb_create_data_chunk(coltypes.data(), 3);
	duckdb_vector id0 = duckdb_data_chunk_get_vector(data_chunk, 0);
	duckdb_vector v0 = duckdb_data_chunk_get_vector(data_chunk, 1);
	duckdb_vector v1 = duckdb_data_chunk_get_vector(data_chunk, 2);
	duckdb_vector_assign_string_element(id0, 0, gen.uuid4().str().c_str());
	duckdb_vector_assign_string_element(v0, 0, text);

	if (duckdb_list_vector_set_size(v1, embeddings.size()) == DuckDBError) {
		// handle error
		*errorCode = 3091;
		return;
	}
	auto child = duckdb_list_vector_get_child(v1);
	auto d1 = duckdb_vector_get_data(child);
	std::memcpy(d1, embeddings.data(), embeddings.size());

	if (duckdb_append_data_chunk(appender, data_chunk) == DuckDBError) {
		// handle error
		*errorCode = 3091;
		return;
	}
	duckdb_data_chunk_set_size(data_chunk, 1);
	if (duckdb_appender_end_row(appender) == DuckDBError) {
		// handle error
		*errorCode = 7690;
		return;
	}

	if (duckdb_appender_close(appender) == DuckDBError) {
		// handle error
		auto errMsg = duckdb_appender_error(appender);
		*errorCode = 4106;
		return;
	}

	if (duckdb_appender_destroy(&appender) == DuckDBError) {
		// handle error
		*errorCode = 4106;
		return;
	}

	duckdb_destroy_data_chunk(&data_chunk);
	duckdb_destroy_logical_type(&coltypes[0]);
	duckdb_destroy_logical_type(&coltypes[1]);
	duckdb_destroy_logical_type(&coltypes[2]);
	_unnu_create_fts_index(errorCode);
	*errorCode = 0;
	
	duckdb_result res;
	if(duckdb_query(*dbconn.get(), "select seq from sqlite_sequence where name='embeddings';", &res)== DuckDBError){
		// handle error
		*errorCode = 5642;
		return;
	}
	
	// iterate until result is exhausted
	duckdb_data_chunk result = duckdb_fetch_chunk(res);
	int64_t rowid = 0;
	if (result) {
		// get the first column
		duckdb_vector col1 = duckdb_data_chunk_get_vector(result, 0);
		int64_t *col1_data = (int64_t *) duckdb_vector_get_data(col1);
		uint64_t *col1_validity = duckdb_vector_get_validity(col1);
		if (duckdb_validity_row_is_valid(col1_validity, 0)) {
            rowid = col1_data[0];
        }
		duckdb_destroy_data_chunk(&result);
	}
	// clean-up
	duckdb_destroy_result(&res);
	
	UnnuRaglResult_t response;
	response.length = strlen(text);
	if (response.length > 0) {
		response.text = (char*)std::calloc(response.length + 1, sizeof(char));
		std::memcpy(response.text, text, response.length + 1);
	}
	response.type = UnnuRaglResultType::UNNU_RAGL_EMBEDDING;
	response.count = rowid;
	_unnu_ragl_query_result(&response);
}

void unnu_rag_lite_open_kb(char* db_path, int* errorCode) {

	std::string key = db_path != nullptr ? std::string(db_path) : ":memory:";
	if (kbhandles.find(key) != kbhandles.cend()) {
		*errorCode = (26 << 8); // SQLITE_IOERR_CONVPATH
		return;
	}

	duckdb_database* db = nullptr;
	if (duckdb_open(db_path, db) == DuckDBError) {
		// handle error
		*errorCode = 782;
		return;
	}
	kbhandles.insert({ key, db });
	if (dbconn != nullptr) {
		duckdb_disconnect(dbconn.get());
	}
	duckdb_connection conn;
	if (duckdb_connect(*db, &conn) == DuckDBError) {
		// handle error
		*errorCode = 3338;
		return;
	}
	dbconn = duckdb_connection_ptr(&conn);
	_unnu_ragl_db_setup(conn, errorCode);
}

void unnu_rag_lite_open_memory(char* mem_id, int* errorCode) {
	int n = snprintf(nullptr, 0, "file:%s?mode=memory&cache=shared", mem_id);
	auto buffer = (char*)calloc(n + 1, sizeof(char));
	snprintf(buffer, n + 1, "file:%s?mode=memory&cache=shared", mem_id);
	std::string key = std::string(buffer);
	free(buffer);
	duckdb_database* db = nullptr;
	if (duckdb_open(key.c_str(), db) == DuckDBError) {
		// handle error
		*errorCode = 782;
		return;
	}

	kbhandles.insert({ mem_id, db });
	if (dbconn != nullptr) {
		if (pstmt != nullptr) {
			duckdb_destroy_prepare(pstmt.get());
			pstmt = nullptr;
		}
		duckdb_disconnect(dbconn.get());
		dbconn = nullptr;
	}
	duckdb_connection conn;
	if (duckdb_connect(*db, &conn) == DuckDBError) {
		// handle error
		*errorCode = 3338;
		return;
	}
	dbconn = duckdb_connection_ptr(&conn);
	_unnu_ragl_db_setup(conn, errorCode);
}

std::string _unnu_string_trim(const std::string& str) {
	std::regex pattern("^\\s+|\\s+$");
	return std::regex_replace(str, pattern, "");
}

std::vector<std::string> _unnu_split_text_into_sentences(std::string& text) {
	std::vector<std::string> sentences;
	std::regex split_sentences("([^.?!]*)[.?!]",
		std::regex_constants::ECMAScript);
	int start_of_sentence = 0, end_of_sentence = -1, text_length = text.size();

	for (std::sregex_iterator i = std::sregex_iterator(text.cbegin(), text.cend(), split_sentences), sentences_end = std::sregex_iterator(); i != sentences_end; ++i)
	{
		std::smatch match = *i;
		if (match.ready()) {
			std::string match_str = match.str(0);
			std::string captured = match.str(1);
			// end_of_sentence = match.position(0);
			auto sentence = _unnu_string_trim(captured);
			if (!sentence.empty()) {
				sentences.push_back(sentence);
			}
			start_of_sentence = match.position(0) + match_str.size();
		}
	}

	if(start_of_sentence < text_length){
		auto sentence = _unnu_string_trim(text.substr(start_of_sentence, text_length - start_of_sentence));
		if (sentence.size() > 0) {
			sentences.push_back(sentence);
		}
	}
	return sentences;
}

std::vector<std::string> _unnu_split_text_into_paragraphs(std::string& text) {
	std::vector<std::string> sentences;
	std::regex split_sentences("\n{2,}",
		std::regex_constants::ECMAScript);
	int start_of_paragraph = 0, end_of_paragraph = -1, text_length = text.size();

	for (std::sregex_iterator i = std::sregex_iterator(text.cbegin(), text.cend(), split_sentences), sentences_end = std::sregex_iterator(); i != sentences_end; ++i)
	{
		std::smatch match = *i;
		if (match.ready()) {
			std::string match_str = match.str();
			end_of_paragraph = match.position(0);
			int paragraph_length = end_of_paragraph - start_of_paragraph;
			if (paragraph_length > 0) {
				auto sentence = _unnu_string_trim(text.substr(start_of_paragraph, paragraph_length));
				sentences.push_back(sentence);
			}
			start_of_paragraph = end_of_paragraph + match_str.size();
		}
	}

	if (start_of_paragraph < text_length) {
		auto sentence = _unnu_string_trim(text.substr(start_of_paragraph, text_length - start_of_paragraph));
		if (sentence.size() > 0) {
			sentences.push_back(sentence);
		}
	}
	return sentences;
}

std::vector<std::string> _unnu_ragl_split_text_into_chunks(std::string& text, int chunksize, bool overlap) {
    std::vector<std::string> chunks;
    std::string currentChunk = "";
	std::string overlapping = "";
	bool first_chunk = true;
	auto sentences = _unnu_split_text_into_sentences(text);
    for (auto sentence : sentences) {
		if(overlap){
			overlapping.append(first_chunk ? "" : "\n").append(sentence);
		}
        if ((currentChunk.length() + sentence.length()) > chunksize) {
			if(overlap && !overlapping.empty()){
				chunks.push_back(overlapping);
			} else if (!currentChunk.empty()) {
				chunks.push_back(currentChunk);
			}
			if(overlap){
				overlapping = sentence;
			}
			currentChunk = sentence;
			first_chunk = false;
        } else if(first_chunk) {
			currentChunk = sentence;
			first_chunk = false;
		} else {
			currentChunk.append("\n").append(sentence);
		}
    }
	
	if(overlap && !overlapping.empty()){
		chunks.push_back(overlapping);
	} else if (!currentChunk.empty()) {
		chunks.push_back(currentChunk);
    }
	return chunks;
}



void _unnu_ragl_process(UnnuRagProcessInput_t input) {
	constexpr std::chrono::seconds zero_sec(0);
	auto ids = _unnu_rag_lite_tokenize(input.text);
	std::vector<std::vector<std::string>> _input;
	_input.push_back(ids);
	auto _val = _encoder->forward_batch_async(_input);
	bool _done = false;
	while (!(_val.wait_for(zero_sec) == std::future_status::ready)) {
		delay(50);
	}

	auto _hidden_state = _val.get().last_hidden_state;
	auto _shape = _hidden_state.shape();
	auto _data = _hidden_state.to_float32().data<float>();
	arma::fmat _mat(_data, _shape[0], _shape[1]);
	auto _normalised = arma::normalise(_mat, 2, 1);
	auto _embedding = _normalised.eval().col(0);
	std::vector<float> _vals(_embedding.cbegin(), _embedding.cend());
	int errorCode = 0;
	input.query ? _unnu_ragl_query(input.text.c_str(), _vals, &errorCode)
		: _unnu_ragl_insert_embedding(input.text.c_str(), _vals, &errorCode);
}

typedef struct embedding_context {
  std::vector<std::string> chunks;
} embedding_context_t;

static void _unnu_ragl_embed(embedding_context_t* context, size_t i) {
	UnnuRagProcessInput_t input;
	input.text = context->chunks[i];
	input.query = false;
	_unnu_ragl_process(input);
}

void unnu_rag_lite_embed(const char* text, bool paragraph_chunking) {

	std::string _text_in(text);
	embedding_context_t context;
	context.chunks = paragraph_chunking ? _unnu_split_text_into_paragraphs(_text_in) : _unnu_ragl_split_text_into_chunks(_text_in, 1280, true);
	/*for (auto chunk : chunks) {
		UnnuRagProcessInput_t input;
		input.text = chunk;
		input.query = false;
		std::thread thr(_unnu_ragl_process, std::ref(input));
		thr.detach();
	}*/
	
	if(context.chunks.size()>0){
		pthreadpool_t threadpool = pthreadpool_create(0);
		pthreadpool_parallelize_1d(threadpool, (pthreadpool_task_1d_t)_unnu_ragl_embed,
                             (void *) &context, context.chunks.size(),
                             /*flags=*/0);
		pthreadpool_destroy(threadpool);
		threadpool = NULL;
	}
	UnnuRaglResult_t response;
	response.type = UnnuRaglResultType::UNNU_RAGL_FINISH;
	_unnu_ragl_query_result(&response);
}

void unnu_rag_lite_query(const char* text) {
	UnnuRagProcessInput_t input;
	input.text = std::string(text);
	input.query = true;
	std::thread thr(_unnu_ragl_process, std::ref(input));
	thr.detach();
}


// void unnu_rag_lite_close_kb(char* tag){
//	std::string key = tag != nullptr ? std::string(tag) : ":memory:";
//	auto search = kbhandles.find(key);
//	if ( search != kbhandles.end()){
//		duckdb_close(search->second);
//		kbhandles.erase(key);
//	}
// }

void unnu_rag_lite_closeall_kb() {
	if (pstmt != nullptr) {
		duckdb_destroy_prepare(pstmt.get());
		pstmt = nullptr;
	}
	for (auto it = kbhandles.cbegin(); it != kbhandles.cend(); it++) {
		auto val = *it;
		duckdb_close(val.second);
	}
	kbhandles.clear();
	dbconn = nullptr;
}

void unnu_set_ragl_result_callback(UnnuRaglResponseCallback callback) {
	response_cb = callback;
}

void unnu_unset_ragl_result_callback() {
	response_cb = nullptr;
}

void unnu_rag_lite_destroy(){
	unnu_unset_ragl_result_callback();
	_encoder->clear_cache();
	_encoder = nullptr;
	_spp = nullptr;
}

