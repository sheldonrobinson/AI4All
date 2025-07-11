#include <map>
#include <filesystem>
#include <thread>
#include <regex>

#include <tokenizers_cpp.h>
#include <ctranslate2/encoder.h>
#include <cpuinfo.h>
#include <armadillo>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <pthreadpool.h>

#include <duckdb.hpp>
#include <duckdb/main/db_instance_cache.hpp>

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

// typedef std::unique_ptr<sentencepiece::SentencePieceProcessor> sentencepiece_processor_ptr;
typedef std::unique_ptr<tokenizers::Tokenizer> tokenizer_ptr;
typedef std::unique_ptr<ctranslate2::Encoder> ct2_encoder_ptr;

static std::unique_ptr<duckdb::DuckDB> database = nullptr;
static std::unique_ptr<duckdb::Connection> connection = nullptr;

static std::unique_ptr<duckdb::PreparedStatement> pstmt = nullptr;

static tokenizer_ptr _tokenizer = nullptr;
static ct2_encoder_ptr _encoder = nullptr;

static UnnuRaglResponseCallback response_cb = nullptr;

static UnnuRaglEmbeddingCallback embedding_cb = nullptr;

static int32_t EMBEDDING_SIZE = 768;

static bool PARAGRAPH_CHUNKING = true;

static int32_t CHUNKING_SIZE = 384;

static int32_t QUERY_RESULT_LIMIT = 5;

static int32_t MAX_QUEUED_BATCHES = 512;

static int32_t POOLING_TYPE = 0; // 0 - mean, 1 - cls, 2 - max

std::string _loadBytesFromFile(const std::string& path) {
	std::ifstream fs(path, std::ios::in | std::ios::binary);
	if (fs.fail()) {
		std::cerr << "Cannot open " << path << std::endl;
		exit(1);
	}
	std::string data;
	fs.seekg(0, std::ios::end);
	size_t size = static_cast<size_t>(fs.tellg());
	fs.seekg(0, std::ios::beg);
	data.resize(size);
	fs.read(data.data(), size);
	return data;
}

void unnu_rag_lite_init(const char* path) {
	const ctranslate2::Device device = ctranslate2::str_to_device("auto");

	std::vector<int> device_indices = { 0 };

	ctranslate2::ReplicaPoolConfig _config;
	_config.num_threads_per_replica = 1;

	if (cpuinfo_initialize()) {
		int cores = cpuinfo_get_cores_count();
		if (cores > 2) {
			_config.max_queued_batches = MAX_QUEUED_BATCHES;
			_config.num_threads_per_replica = cores / 2;
		}
		else {
			_config.max_queued_batches = MAX_QUEUED_BATCHES;
		}
	}

	_encoder = std::make_unique<ctranslate2::Encoder>(path, device, ctranslate2::ComputeType::INT8, device_indices, false, _config);

	std::filesystem::path _spm_path(path);
	_spm_path /= "tokenizer.json";

	// Read blob from file.
	std::string blob = _loadBytesFromFile(_spm_path.generic_string());

	// Note: all the current factory APIs takes in-memory blob as input.
	// This gives some flexibility on how these blobs can be read.
	_tokenizer = tokenizers::Tokenizer::FromBlobJSON(blob);
}

void _unnu_overwrite_fts_index(int* errorCode) {

	duckdb::Connection conn(*database);

	std::string query = "pragma create_fts_index(embeddings, frag_id,'text',stemmer = 'porter',stopwords = 'english', strip_accents = 1,lower = 1,overwrite = 1);";
	auto result = conn.Query(query);
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: _unnu_create_fts_index creating fts_index embedding %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
	}
}

void _unnu_ragl_db_setup(int embedsize, int* errorCode) {
	duckdb::Connection conn(*database);

	std::string query = "CREATE TABLE IF NOT EXISTS embeddings (frag_id VARCHAR(64) UNIQUE NOT NULL, text VARCHAR, embedding FLOAT[";
	query = query.append(std::to_string(embedsize)).append("]);");
	auto result = conn.Query(query);
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: creating table embeddings %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
		return;
	}

	query = "CREATE TABLE IF NOT EXISTS doxinfo (document_id VARCHAR(64) NOT NULL, uri VARCHAR, embedding_size INTEGER, PRIMARY KEY (document_id, uri));";
	result = conn.Query(query);
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: creating table doxinfo: %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
		return;
	}

	query = "CREATE TABLE IF NOT EXISTS doxmap (document_id VARCHAR(64) NOT NULL, frag_id VARCHAR(64) NOT NULL, PRIMARY KEY (document_id, frag_id));";
	result = conn.Query(query);
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: creating table doxmap %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
		return;
	}

	result = conn.Query("Load VSS;");
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: loading vss extension %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
		return;
	}

	result = conn.Query("SET GLOBAL hnsw_enable_experimental_persistence = true;");
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: enabling hnsw persistence %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
		return;
	}

	query = "CREATE INDEX IF NOT EXISTS embeddings_hnsw_index ON embeddings USING HNSW(embedding) WITH (metric = 'cosine');";
	result = conn.Query(query);
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: creating index embedding_hsnw %s\n", result->GetError().c_str());
#endif
		* errorCode = 5642;
		return;
	}

	result = conn.Query("pragma create_fts_index(embeddings, frag_id,'text',stemmer = 'porter',stopwords = 'english', strip_accents = 1,lower = 1,overwrite = 0);");
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: creating ftx_index embeddings %s\n", result->GetError().c_str());
#endif
		result = conn.Query("pragma create_fts_index(embeddings, frag_id,'text',stemmer = 'porter',stopwords = 'english', strip_accents = 1,lower = 1,overwrite = 1);");
		if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "error: overwriting fts_index embedding %s\n", result->GetError().c_str());
#endif
			* errorCode = 5642;
		}
	}

	std::string select = "with fts as (select text, fts_main_embeddings.match_bm25(frag_id,$1) as score from embeddings), ";
	select.append("embd as (select text, array_cosine_distance(embedding, $2 ) as score from embeddings), ");
	select.append("normalized_scores as (select fts.text, fts.score as raw_fts_score, embd.score as raw_embd_score, ");
	select.append("(fts.score / (select max(score) from fts)) as norm_fts_score, ((embd.score + 1) / (select max(score) + 1 from embd)) as norm_embd_score ");
	select.append("from	fts	inner join embd on fts.frag_id = embd.frag_id) ");
	select.append("select text, (0.8 * norm_embd_score + 0.2 * norm_fts_score) as score_cc from normalized_scores order by score_cc desc limit $3;");

	pstmt = std::unique_ptr<duckdb::PreparedStatement>((*connection).Prepare(select));

	*errorCode = 0;
}

void unnu_rag_lite_delete(const char* document_id, const char* uri) {
	// see https://www.sqlite.org/fts5.html#the_delete_command
	// https://duckdb.org/docs/stable/core_extensions/full_text_search

	duckdb::Connection conn(*database);

	std::string deleteEmbeddingsSQL = "WITH fragments AS (SELECT frag_id FROM doxmap INNER JOIN doxinfo on doxmap.document_id = doxinfo.document_id WHERE doxinfo.document_id = '";  
	deleteEmbeddingsSQL.append(document_id).append("' AND doxinfo.uri = '").append(uri).append("') DELETE FROM embeddings USING fragments WHERE embeddings.frag_id = fragments.frag_id;");

	auto result = conn.Query(deleteEmbeddingsSQL);
	if (result->HasError()) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: deleting embedding for %s:  %s\n", uri, result->GetError().c_str());
#endif
		return;
	}

	std::string deleteDoxmapSQL = "WITH documents AS (SELECT document_id FROM doxinfo WHERE document_id = '";
	deleteDoxmapSQL.append(document_id).append("' AND uri = '").append(uri).append("') DELETE FROM doxmap USING documents WHERE doxmap.document_id = documents.document_id;");


	result = conn.Query(deleteDoxmapSQL);
	if (result->HasError()) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: deleting doxmap for %s:  %s\n", uri, result->GetError().c_str());
#endif
		return;
	}

	std::string deleteDoxInfoSQL = "DELETE FROM doxinfo WHERE document_id = '";
	deleteDoxInfoSQL.append(document_id).append("' AND uri = '").append(uri).append("';");


	result = conn.Query(deleteDoxInfoSQL);
	if (result->HasError()) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: deleting doxinfo for %s:  %s\n", uri, result->GetError().c_str());
#endif
		return;
	}

	result = conn.Query("PRAGMA hnsw_compact_index('embeddings_hnsw_index');");
	if (result->HasError()) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: compacting embedding_hsnw_index for %s:  %s\n", uri, result->GetError().c_str());
#endif
		return;
	}
	
	result = conn.Query("CHECKPOINT;");
	if (result->HasError()) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: reclaiming space after deleting %s:  %s\n", uri, result->GetError().c_str());
#endif
		return;
	}

	int errorCode = 0;
	std::thread thr(_unnu_overwrite_fts_index, &errorCode);
	thr.detach();
}

void _unnu_ragl_query(const char* text, std::vector<float> embeddings, int limit, int* errorCode) {


	duckdb::vector<duckdb::Value> _array(embeddings.size());
	std::transform(embeddings.cbegin(), embeddings.cend(), _array.begin(), [](float d) -> duckdb::Value { return duckdb::Value(d); });

	auto embd = duckdb::Value::ARRAY(duckdb::LogicalType::FLOAT, _array);

	auto result = pstmt->Execute(text, embd, limit);
	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: executing pstmt %s\n", result->GetError().c_str());
#endif
		return;
	}

	std::vector< UnnuRaglFragment_t*> fragments;
	auto output = result.get();
	while (true) {
		auto chunk = output->Fetch();
		if (chunk) {
			for (idx_t i = 0; i < chunk->size(); i++) {
				auto line = chunk->GetValue(0, i).GetValue<std::string>();
				if (!line.empty()) {
					UnnuRaglFragment_t* frag = (UnnuRaglFragment_t*)malloc(sizeof(UnnuRaglFragment_t));
					auto len = line.length();
					frag->length = len;
					frag->text = (char*)std::calloc(len + 1, sizeof(char));
					std::memcpy(frag->text, line.c_str(), len);
					frag->text[len] = '\0';
					fragments.push_back(frag);
				}
			}
		}
		else {
			break;
		}
	}

	if (response_cb != nullptr) {
		int frag_sz = fragments.size();
		if (frag_sz > 0) {
			UnnuRaglResult_t* response = (UnnuRaglResult_t*)malloc(sizeof(UnnuRaglResult_t));
			response->count = frag_sz;
			response->type = UnnuRaglResultType::UNNU_RAGL_QUERY;
			response->fragments = (UnnuRaglFragment_t**)std::calloc(frag_sz, sizeof(UnnuRaglFragment_t*));
			std::memcpy(response->fragments, fragments.data(), frag_sz * sizeof(UnnuRaglFragment_t*));
			response_cb(response);
		}
	}
}

void unnu_rag_lite_open_kb(char* db_path, int* errorCode) {
	std::string key = db_path != nullptr ? db_path : ":memory:";
	duckdb::DBConfigOptions options;
	options.autoload_known_extensions = true;
	options.autoinstall_known_extensions = true;
	options.force_checkpoint = true;
	options.checkpoint_on_shutdown = true;
	duckdb::DBConfig config;
	config.options = options;

	database = std::make_unique<duckdb::DuckDB>(db_path, &config);

	connection = std::make_unique<duckdb::Connection>(*database);

	_unnu_ragl_db_setup(EMBEDDING_SIZE, errorCode);
}


std::string _unnu_string_trim(const std::string& str) {
	std::regex pattern("^\\s+|\\s+$",std::regex_constants::ECMAScript);
	return std::regex_replace(str, pattern, "");
}

std::vector<std::string> _unnu_split_text_into_sentences(std::string& text) {
	std::vector<std::string> sentences;
	std::regex split_sentences("([!.?]+)\\s+",
		std::regex_constants::ECMAScript);
	std::sregex_token_iterator it(text.begin(), text.end(), split_sentences, -1);
	std::sregex_token_iterator sep(text.begin(), text.end(), split_sentences);
	std::sregex_token_iterator end;
	for(;it != end && sep != end; it++,sep++){
		std::string val(*it);
		if (!val.empty()) {
			std::string delim(*sep);
			val.append(1, delim.c_str()[0]);
			sentences.push_back(val);
		}
	}
	
	for(;it != end; it++){
		sentences.push_back(*it);
	}
	return sentences;
}

std::vector<std::string> _unnu_split_text_into_paragraphs(std::string& text) {
	std::regex regexPattern("(\\s*\\n){2,}",std::regex_constants::ECMAScript);
    std::sregex_token_iterator it(text.begin(), text.end(), regexPattern, -1);
	std::sregex_token_iterator end;
    std::vector<std::string> paragraphs(it, end);
    return paragraphs;
}

std::vector<std::string> _unnu_ragl_split_text_into_chunks(std::string& text, int chunksize, bool overlap) {
	std::vector<std::string> chunks;
	std::vector<std::string> paragraphs = _unnu_split_text_into_paragraphs(text);
	for (std::string text : paragraphs) {
		bool first_chunk = true;
		std::vector<std::string> sentences  = _unnu_split_text_into_sentences(text);
		std::string currentChunk = "";
		std::string overlapping = "";
		for (std::string sentence : sentences) {
			// change to unix style eol
			// sentence.erase(std::remove(sentence.begin(), sentence.end(), '\r'), sentence.end());
			if (!sentence.empty()) {
				if (overlap) {
					overlapping.append(first_chunk ? "" : " ").append(sentence);
				}
				if ((currentChunk.length() + sentence.length()) > chunksize) {
					if (overlap && !overlapping.empty()) {
						chunks.push_back(overlapping);
					}
					else if (!currentChunk.empty()) {
						chunks.push_back(currentChunk);
					}
					if (overlap) {
						overlapping = sentence;
					}
					currentChunk = sentence;
					first_chunk = false;
				}
				else if (first_chunk) {
					currentChunk = sentence;
					first_chunk = false;
				}
				else {
					currentChunk.append(" ").append(sentence);
				}
			}
		}
		if (overlap && !overlapping.empty()) {
			chunks.push_back(overlapping);
		}
		else if (!currentChunk.empty()) {
			chunks.push_back(currentChunk);
		}
	}
	return chunks;
}



static void _unnu_rag_lite_retrieve(std::string id) {

	std::string select = "WITH fragments AS (SELECT frag_id FROM doxmap WHERE document_id = '";
	select.append(id).append("') SELECT embeddings.text, embeddings.embedding FROM embeddings INNER JOIN fragments ON embeddings.frag_id = fragments.frag_id;");

	duckdb::Connection conn(*database);

	auto result = conn.Query(select);

	if (result->HasError()) {

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: executing pcache_stmt %s\n", result->GetError().c_str());
#endif
		return;
	}

	std::vector< UnnuRaglFragment_t*> fragments;
	auto output = result.get();
	while (true) {
		auto chunk = output->Fetch();
		if (chunk) {
			for (idx_t i = 0; i < chunk->size(); i++) {
				auto line = chunk->GetValue(0, i).GetValue<std::string>();
				auto vec = chunk->GetValue(1, i).GetValue<duckdb::Value>();
				auto values = duckdb::ArrayValue::GetChildren(vec);
				if (!line.empty() && values.size() > 0) {
					UnnuRagEmbdVec_t* frag = (UnnuRagEmbdVec_t*)malloc(sizeof(UnnuRagEmbdVec_t));
					frag->type = UNNU_RAGL_EMBEDDING;

					auto len = line.length();
					frag->length = len;
					frag->text = (char*)std::calloc(len + 1, sizeof(char));
					std::memcpy(frag->text, line.c_str(), len);
					frag->text[len] = '\0';

					auto cnt = values.size();
					frag->count = cnt;
					std::vector<float> vdata(cnt);
					std::transform(values.cbegin(), values.cend(), vdata.begin(),
						[](duckdb::Value d) -> float { return d.GetValue<float>(); });
					frag->values = (float*)calloc(cnt, sizeof(float));
					std::memcpy(frag->values, vdata.data(), cnt * sizeof(float));

					frag->reflen = 0;
					if (embedding_cb != nullptr) {
						embedding_cb(frag);
					}
				}
			}
		}
		else {
			break;
		}
	}

	if (embedding_cb != nullptr) {
		UnnuRagEmbdVec_t* vec = (UnnuRagEmbdVec_t*)malloc(sizeof(UnnuRagEmbdVec_t));
		vec->type = UnnuRaglResultType::UNNU_RAGL_FINISH;
		vec->reflen = 0;
		vec->length = 0;
		vec->count = 0;
		embedding_cb(vec);
	}
}

void unnu_rag_lite_retrieve(const char* uri) {
	std::string input(uri);
	std::thread thr(_unnu_rag_lite_retrieve, input);
	thr.detach();
}

void unnu_rag_lite_mapping(const char* uri, const char* document_id) {
	duckdb::Connection conn(*database);
	try {
		duckdb::Appender doxinfo_appender(conn, "doxinfo");
		doxinfo_appender.AppendRow(document_id, uri, EMBEDDING_SIZE);
	}
	catch (...) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: doxinfo appender %s, %s\n", document_id, uri);
#endif
	}
}

static inline std::vector<float> _unnu_ragl_process(std::string input) {
	constexpr std::chrono::seconds zero_sec(0);
	auto ids = _tokenizer->Encode(input);
	std::vector<size_t> _encoder_ids;

	std::transform(ids.begin(), ids.end(), std::back_inserter(_encoder_ids),
		[](int32_t value) { return static_cast<size_t>(value); });

	std::vector<std::vector<size_t>> _inputs_ids;
	_inputs_ids.push_back(_encoder_ids);
	while (_encoder->num_queued_batches() == MAX_QUEUED_BATCHES) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "info: delayed num_queued_batches() == MAX_QUEUED_BATCHES\n");
#endif
		delay(10);
	}
	auto _val = _encoder->forward_batch_async(_inputs_ids);
	// bool _done = false;
	while (!(_val.wait_for(zero_sec) == std::future_status::ready)) {
		delay(50);
	}

	ctranslate2::EncoderForwardOutput output = _val.get();
	ctranslate2::Shape _shape = output.last_hidden_state.shape();
	auto lsz = output.last_hidden_state.size();
	std::vector<float> _data(lsz);

	std::memcpy(_data.data(), output.last_hidden_state.to_vector<float>().data(), lsz * sizeof(float));
	output.last_hidden_state.release();

	arma::fmat _mat(_data.data(), _shape[2], _shape[1], true, true);
	arma::fmat _mean = POOLING_TYPE == 0 ? arma::mean(_mat, 1).eval() : POOLING_TYPE == 1 ? _mat.col(0).eval() : arma::max(_mat, 1).eval();

	auto _normalised = arma::normalise(_mean.t(), 2, 1);
	auto _embedding = _normalised.eval();
	auto sz = _embedding.size();
	std::vector<float> _vals(sz);
	std::memcpy(_vals.data(), _embedding.memptr(), sz * sizeof(float));

	return _vals;
}

void _unnu_ragl_insert_embedding(const char* document_id, const char* text, int* errorCode) {
	boost::uuids::random_generator gen;
	std::string frag_id(boost::uuids::to_string(gen()).c_str());
	auto embeddings = _unnu_ragl_process(text);

	try {
		duckdb::Connection conn(*database);
		duckdb::vector<duckdb::Value> _array;
		std::transform(embeddings.cbegin(), embeddings.cend(), std::back_inserter(_array), [](float d) { return duckdb::Value(d); });

		auto embd = duckdb::Value::ARRAY(duckdb::LogicalType::FLOAT, _array);
		try {
			duckdb::Appender embd_appender(conn, "embeddings");
			embd_appender.AppendRow(frag_id.c_str(), text, embd);
		}
		catch (...) {
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "error: embeddings appender %s, %s\n", frag_id.c_str(), text);
#endif
		}

		try {
			duckdb::Appender dm_appender(conn, "doxmap");
			dm_appender.AppendRow(document_id, frag_id.c_str());
		}
		catch (...) {
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "error: doxmap appender %s, %s\n", document_id, frag_id.c_str());
#endif
		}
	}
	catch (...) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: _unnu_ragl_insert_embedding %s, %s\n", document_id, frag_id.c_str());
#endif
		return;
	}

	if (embedding_cb != nullptr) {
		int len = strlen(text);
		if (len > 0) {
			UnnuRagEmbdVec_t* response = (UnnuRagEmbdVec_t*)malloc(sizeof(UnnuRagEmbdVec_t));
			response->type = UnnuRaglResultType::UNNU_RAGL_EMBEDDING;
			response->length = len;
			response->text = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(response->text, text, len * sizeof(char));
			response->text[len] = '\0';
			int reflen = frag_id.length();
			response->reflen = reflen;
			response->ref_id = (char*)std::calloc(reflen + 1, sizeof(char));
			std::memcpy(response->ref_id, frag_id.c_str(), reflen * sizeof(char));
			response->ref_id[reflen] = '\0';
			int count = embeddings.size();
			response->count = count;
			response->values = (float*)calloc(count, sizeof(float));
			std::memcpy(response->values, embeddings.data(), count * sizeof(float));
			embedding_cb(response);
		}
	}
}

typedef struct embedding_context {
	std::string document_id;
	std::vector<std::string> chunks;
} embedding_context_t;

static void _unnu_ragl_embed(embedding_context_t* context, size_t i) {
	try {
	std::string input = context->chunks[i];
	int errorCode = 0;
		_unnu_ragl_insert_embedding(context->document_id.c_str(), input.c_str(), &errorCode);
	}
	catch (...) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "error: _unnu_ragl_embed\n");
#endif
	}
}

void _unnu_rag_lite_embed(std::string text) {
	//std::string _text_in(text);
	embedding_context_t context;
	boost::uuids::random_generator gen;
	context.document_id = boost::uuids::to_string(gen()).c_str();
	context.chunks = _unnu_ragl_split_text_into_chunks(text, CHUNKING_SIZE, true);
	int errorCode = 0;

	if (context.chunks.size() > 0) {
		pthreadpool_t threadpool = pthreadpool_create(0);
		pthreadpool_parallelize_1d(threadpool, (pthreadpool_task_1d_t)_unnu_ragl_embed,
			(void*)&context, context.chunks.size(),
			/*flags=*/0);
		pthreadpool_destroy(threadpool);
		threadpool = NULL;
	}

	if (embedding_cb != nullptr) {
		UnnuRagEmbdVec_t* vec = (UnnuRagEmbdVec_t*)malloc(sizeof(UnnuRagEmbdVec_t));
		vec->type = UnnuRaglResultType::UNNU_RAGL_FINISH;
		int reflen = context.document_id.length();
		vec->reflen = reflen;
		vec->ref_id = (char*)calloc(reflen + 1, sizeof(char));
		std::memcpy(vec->ref_id, context.document_id.c_str(), reflen * sizeof(char));
		vec->ref_id[reflen] = '\0';
		vec->length = 0;
		vec->count = 0;
		embedding_cb(vec);
	}
	_unnu_overwrite_fts_index(&errorCode);
}

void unnu_rag_lite_embed(const char* text) {
	std::string input(text);
	std::thread thr(_unnu_rag_lite_embed, input);
	thr.detach();
}

void _unnu_rag_lite_query(std::string text) {
	int errorCode = 0;

	std::vector<float> _vals(_unnu_ragl_process(text));
	//if (response_cb != nullptr) {
	//	_unnu_ragl_query(text.c_str(), _vals, QUERY_RESULT_LIMIT, &errorCode);
	//	UnnuRaglResult_t* response = (UnnuRaglResult_t*)malloc(sizeof(UnnuRaglResult_t));
	//	response->type = UnnuRaglResultType::UNNU_RAGL_FINISH;
	//	response->count = 0;
	//	response->length = 0;
	//	response_cb(response);
	//}
	if (embedding_cb != nullptr) {
		UnnuRagEmbdVec_t* vec = (UnnuRagEmbdVec_t*)malloc(sizeof(UnnuRagEmbdVec_t));
		vec->type = UnnuRaglResultType::UNNU_RAGL_QUERY;
		int len = text.size();
		vec->length = len;
		vec->text = (char*)calloc(len + 1, sizeof(char));
		std::memcpy(vec->text, text.c_str(), len * sizeof(char));
		vec->text[len] = '\0';
		vec->reflen = 0;
		int cnt = _vals.size();
		vec->count = cnt;
		vec->values = (float*)calloc(cnt, sizeof(float));
		std::memcpy(vec->values, _vals.data(), cnt * sizeof(float));
		embedding_cb(vec);
		{
			UnnuRagEmbdVec_t* endVec = (UnnuRagEmbdVec_t*)malloc(sizeof(UnnuRagEmbdVec_t));
			endVec->type = UnnuRaglResultType::UNNU_RAGL_FINISH;
			endVec->reflen = 0;
			endVec->length = 0;
			endVec->count = 0;
			embedding_cb(endVec);
		}
	}
}

void unnu_rag_lite_query(const char* text) {
	std::string input(text);
	std::thread thr(_unnu_rag_lite_query, input);
	thr.detach();
}


void unnu_rag_lite_closeall_kb() {
	pstmt = nullptr;
	connection = nullptr;
	database = nullptr;
}

void unnu_rag_lite_update_dims(int32_t sz) {
	EMBEDDING_SIZE = sz;
}

void unnu_rag_lite_enable_paragraph_chunking(int8_t val) {
	PARAGRAPH_CHUNKING = (val == 0);
}

void unnu_rag_lite_set_chunk_size(int32_t val) {
	CHUNKING_SIZE = val;
}

void unnu_rag_lite_set_pooling_type(int32_t val) {
	POOLING_TYPE = val;
}

void unnu_rag_lite_result_limit(int32_t sz) {
	QUERY_RESULT_LIMIT = sz;
}


void unnu_set_ragl_result_callback(UnnuRaglResponseCallback callback) {
	response_cb = callback;
}

void unnu_set_ragl_embedding_callback(UnnuRaglEmbeddingCallback callback) {
	embedding_cb = callback;
}

void unnu_ragl_free_result(UnnuRaglResult_t* result) {
	if (result != nullptr) {
		if (result->text != nullptr) free(result->text);
		if (result->ref_id != nullptr) free(result->ref_id);
		if (result->count > 0) {
			for (int k = 0, n = result->count; k < n; k++) {
				auto fragment = result->fragments[k];
				if (fragment != nullptr) {
					free(fragment->text);
				}
			}
		}
		free(result);
	}
}

void unnu_ragl_free_embedvector(UnnuRagEmbdVec_t* vec) {
	if (vec != nullptr) {
		if (vec->length > 0) free(vec->text);
		if (vec->reflen > 0) free(vec->ref_id);
		if (vec->count > 0) {
			free(vec->values);
		}
		free(vec);
	}
}

void unnu_unset_ragl_result_callback() {
	response_cb = nullptr;
}

void unnu_unset_ragl_embedding_callback() {
	embedding_cb = nullptr;
}

void unnu_rag_lite_destroy() {
	unnu_rag_lite_closeall_kb();
	unnu_unset_ragl_result_callback();
	unnu_unset_ragl_embedding_callback();
	if (_encoder != nullptr) _encoder->clear_cache();
	_encoder = nullptr;
	_tokenizer = nullptr;
}

