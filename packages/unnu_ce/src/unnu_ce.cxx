#include <atomic>
#include <algorithm>
#include <numeric>
#include <thread>
#include <queue>
#include <fstream>
#include <filesystem>
#include <regex>
#include <forward_list>

#include <cpuinfo.h>
#include <tokenizers_cpp.h>
#include <armadillo>

#include <minimal_uuid4.h>
#include <nlohmann/json.hpp>
// #include <re2/re2.h>

#include "sml_ClientAgent.h"
#include "sml_ClientKernel.h"
#include "sml_ClientAnalyzedXML.h"
#include "sml_Connection.h"

#include "unnu_ce.h"
#include "onnxruntime_c_api.h"
#include "ort_genai.h"
#include "slm_engine.h"

using json = nlohmann::json;


#define UNNU_CE_TEMP 0.1f
#define UNNU_CE_TOP_K 10
#define UNNU_CE_TOP_P 0.80f
#define UNNU_CE_MAX_LENGTH 2048

#define ORT_ABORT_ON_ERROR(expr)                                \
   do {                                                         \
	  OrtStatus* onnx_status = (expr);                          \
	  if (onnx_status != NULL) {                                \
		 const char* msg = g_ort->GetErrorMessage(onnx_status); \
		 fprintf(stderr, "%s\n", msg);                          \
		 g_ort->ReleaseStatus(onnx_status);                     \
		 abort();                                               \
	  }                                                         \
   } while (0);



typedef std::unique_ptr<tokenizers::Tokenizer> tokenizer_ptr;

typedef struct InternalTokenizerSettings {
	std::string blob;
	UnnuTokenizerType_t type = TOKENIZER_TYPE_NONE;
	tokenizer_ptr tokenizer = nullptr;
} InternalTokenizerSettings_t;

typedef struct category_ent {
	std::string id;
	std::string value;
	int entity_type;
	int grouping;
} category_ent_t;

typedef struct ThoughtBuffer {
	category_ent_t* blob;
	std::string uuid;
} ThoughtBuffer_t;

typedef struct Musing {
	std::vector<ThoughtBuffer_t> thoughts;
} Musing_t;

typedef struct Prompt {
  std::string system_prompt;
  std::string user_prompt;
  std::string assistant_response;
} Prompt_t;

static ThoughtBuffer_t thought;
static Musing_t musing;
static InternalTokenizerSettings_t _tokenizer_settings;

typedef std::unique_ptr<OgaModel> oga_model_ptr;
typedef std::unique_ptr<OgaTokenizer> oga_tokenizer_ptr;
typedef std::unique_ptr<OgaTokenizerStream> oga_tokenizerstream_ptr;
typedef std::unique_ptr<OgaGenerator> oga_generator_ptr;
typedef std::unique_ptr<microsoft::slm_engine::SLMEngine> slm_engine_ptr;

static oga_model_ptr _model = nullptr;
static oga_tokenizer_ptr _tokenizer = nullptr;
static OgaResultCallback result_cb = nullptr;
static slm_engine_ptr _slm_engine = nullptr;
static std::string _sysprompt = "";


static std::queue<Prompt_t> _prompts = {};
static std::atomic<bool> isRunning = { false };

typedef std::unique_ptr<sml::Kernel> sml_kernel_ptr;

static sml_kernel_ptr smlkernel = nullptr;
static sml::Agent* unnu = nullptr;

typedef std::unique_ptr<OrtEnv> ort_env_ptr;
typedef std::unique_ptr<OrtSessionOptions> ortsession_options_ptr;
typedef std::unique_ptr<OrtSession> ort_session_ptr;

static OrtEnv* _ort_env;
static OrtSession* _ort_session;
static OrtSessionOptions* _session_options;
static OrtRunOptions* _run_options;

const OrtApi* g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);

static std::atomic<bool> m_StopNow{ false };

static std::string LoadBytesFromFile(const std::string& path) {
	std::ifstream fs(path, std::ios::in | std::ios::binary);
	if (fs.fail()) {
		fprintf(stderr, "Cannot open %s\n", path);
		return "";
	}
	std::string data;
	fs.seekg(0, std::ios::end);
	size_t size = static_cast<size_t>(fs.tellg());
	fs.seekg(0, std::ios::beg);
	data.resize(size);
	fs.read(data.data(), size);
	return data;
}

void tokenizer_init(UnnuTokenizerConfig_t tokenizer_cfg) {
	_tokenizer_settings.blob = LoadBytesFromFile(tokenizer_cfg.tokenizer_path);
	_tokenizer_settings.type = tokenizer_cfg.type;

	switch (_tokenizer_settings.type) {
	case UnnuTokenizerType::TOKENIZER_TYPE_SENTENCEPIECE:
		if (!_tokenizer_settings.blob.empty()) {
			_tokenizer_settings.tokenizer = tokenizer_ptr(tokenizers::Tokenizer::FromBlobSentencePiece(_tokenizer_settings.blob).release());
		}
		break;
	case UnnuTokenizerType::TOKENIZER_TYPE_HUGGINGFACE:
		if (!_tokenizer_settings.blob.empty()) {
			_tokenizer_settings.tokenizer = tokenizer_ptr(tokenizers::Tokenizer::FromBlobJSON(_tokenizer_settings.blob).release());
		}
		break;
	case UnnuTokenizerType::TOKENIZER_TYPE_RWKV:
		if (!_tokenizer_settings.blob.empty()) {
			_tokenizer_settings.tokenizer = tokenizer_ptr(tokenizers::Tokenizer::FromBlobRWKVWorld(_tokenizer_settings.blob).release());
		}
		break;
	default:
		break;
	}
}

static const  OrtApi* _get_ortapi([[maybe_unused]] void* unused) {
	if (!g_ort)
	{
		g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);
	}
	return g_ort;
}

void unnu_cner_init(const char* model_path, UnnuTokenizerConfig_t tokenizer_cfg) {
	if (!g_ort)
	{
		g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);
		if (!g_ort) {
			fprintf(stderr, "Failed to init ONNX Runtime engine.\n");
			return;
		}
	}

	ORT_ABORT_ON_ERROR(g_ort->CreateEnv(ORT_LOGGING_LEVEL_ERROR, "unnu", &_ort_env));
	ORT_ABORT_ON_ERROR(g_ort->DisableTelemetryEvents(_ort_env));

	// Creation: OrtSessionOptions* _session_options;
	ORT_ABORT_ON_ERROR(g_ort->CreateSessionOptions(&_session_options))
		ORT_ABORT_ON_ERROR(g_ort->SetSessionGraphOptimizationLevel(_session_options, GraphOptimizationLevel::ORT_ENABLE_ALL));

	if (cpuinfo_initialize()) {
		int cores = cpuinfo_get_cores_count();
		if (cores > 1) {
			ORT_ABORT_ON_ERROR(g_ort->SetSessionExecutionMode(_session_options, ExecutionMode::ORT_PARALLEL));
		}
		else {
			ORT_ABORT_ON_ERROR(g_ort->SetSessionExecutionMode(_session_options, ExecutionMode::ORT_SEQUENTIAL));
		}
	}

	ORT_ABORT_ON_ERROR(g_ort->EnableCpuMemArena(_session_options));
#ifdef _WIN32
	size_t newsize = strlen(model_path) + 1;
	wchar_t* wcstring = new wchar_t[newsize];
	size_t convertedChars = 0;
	mbstowcs_s(&convertedChars, wcstring, newsize, model_path, _TRUNCATE);
	// Creation:  OrtSession* _ortsession
	ORT_ABORT_ON_ERROR(g_ort->CreateSession(_ort_env, wcstring, _session_options, &_ort_session));
	delete[] wcstring;
#else
	ORT_ABORT_ON_ERROR(g_ort->CreateSession(env, model_path, _session_options, &_ortsession));
#endif

	ORT_ABORT_ON_ERROR(g_ort->CreateRunOptions(&_run_options));

	ORT_ABORT_ON_ERROR(g_ort->RunOptionsSetRunLogSeverityLevel(_run_options, OrtLoggingLevel::ORT_LOGGING_LEVEL_ERROR));
	ORT_ABORT_ON_ERROR(g_ort->RunOptionsSetRunLogVerbosityLevel(_run_options, OrtLoggingLevel::ORT_LOGGING_LEVEL_ERROR));

	tokenizer_init(tokenizer_cfg);
}

std::vector<int> _cner_tokenizer_encode(const char* text) {
	return _tokenizer_settings.tokenizer != nullptr ? _tokenizer_settings.tokenizer->Encode(text) : std::vector<int>();
}

std::tuple<std::vector<std::vector<int>>, std::vector<std::vector<int>>> _cner_tokenizer_encode_with_masks(std::vector<std::string> input) {
	if (_tokenizer_settings.type == TOKENIZER_TYPE_HUGGINGFACE && _tokenizer_settings.tokenizer != nullptr) {
		auto _tok = (tokenizers::HFTokenizer*)_tokenizer_settings.tokenizer.get();
		return _tok->EncodeBatchWithMask(input, false);
	}
	auto tokens = _tokenizer_settings.tokenizer->EncodeBatch(input);
	std::vector<std::vector<int>> masks;
	masks.reserve(tokens.size());
	for (auto encoded : tokens) {
		std::vector<int> mask(encoded.size(), 1);
		masks.push_back(mask);
	}
	return std::make_tuple(tokens, masks);
}

std::string _cner_decode(std::vector<int> tokens) {
	return _tokenizer_settings.tokenizer != nullptr ? _tokenizer_settings.tokenizer->Decode(tokens) : "";
}

static int _unnu_cner_category(int idx) {
	return idx != 0 ? (idx >> 1) + (idx % 2) : 0;
}

std::forward_list<category_ent_t> _unnu_cner_process_paragraph(std::vector<std::string> text) {
	auto _input = _cner_tokenizer_encode_with_masks(text);
	OrtMemoryInfo* mem_info;
	ORT_ABORT_ON_ERROR(g_ort->CreateCpuMemoryInfo(OrtAllocatorType::OrtArenaAllocator, OrtMemTypeDefault, &mem_info));
	auto _tokens = _input._Myfirst._Val;
	auto _masks = _input._Get_rest()._Myfirst._Val;

	// Flatten the 2D vector into a 1D vector
	std::vector<int> flattened_tokens;
	for (const auto& vec : _tokens) {
		flattened_tokens.insert(flattened_tokens.end(), vec.begin(), vec.end());
	}

	// Flatten the 2D vector into a 1D vector
	std::vector<int> flattened_masks;
	for (const auto& vec : _masks) {
		flattened_masks.insert(flattened_masks.end(), vec.begin(), vec.end());
	}

	// Define the shape of the tensor
	std::vector<int64_t> shape = { static_cast<int64_t>(_tokens.size()), static_cast<int64_t>(_tokens[0].size()) };

	OrtValue* value = NULL;
	ORT_ABORT_ON_ERROR(g_ort->CreateTensorWithDataAsOrtValue(mem_info, flattened_tokens.data(), flattened_tokens.size(), shape.data(), shape.size(), ONNXTensorElementDataType::ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32, &value));

	int is_tensor;
	ORT_ABORT_ON_ERROR(g_ort->IsTensor(value, &is_tensor));

	OrtValue* mask = NULL;
	ORT_ABORT_ON_ERROR(g_ort->CreateTensorWithDataAsOrtValue(mem_info, flattened_masks.data(), flattened_masks.size(), shape.data(), shape.size(), ONNXTensorElementDataType::ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32, &value));

	ORT_ABORT_ON_ERROR(g_ort->IsTensor(mask, &is_tensor));

	g_ort->ReleaseMemoryInfo(mem_info);

	std::vector<const char*> ort_input_names;
	ort_input_names.push_back("input_ids");
	ort_input_names.push_back("attention_mask");

	std::vector<OrtValue*> ort_inputs;
	ort_inputs.push_back(value);
	ort_inputs.push_back(mask);

	std::vector<const char*> ort_output_names;
	ort_output_names.push_back("logits");
	OrtValue* output = NULL;
	ORT_ABORT_ON_ERROR(g_ort->Run(_ort_session, _run_options, ort_input_names.data(), ort_inputs.data(), ort_inputs.size(), ort_output_names.data(), ort_output_names.size(), &output));
	ORT_ABORT_ON_ERROR(g_ort->IsTensor(output, &is_tensor));
	OrtTensorTypeAndShapeInfo* info = NULL;
	// ORT_ABORT_ON_ERROR(g_ort->CreateTensorTypeAndShapeInfo(&info));
	ORT_ABORT_ON_ERROR(g_ort->GetTensorTypeAndShape(output, &info));
	size_t dim_sz = NULL;
	ORT_ABORT_ON_ERROR(g_ort->GetDimensionsCount(info, &dim_sz));
	int64_t* dims = NULL;
	ORT_ABORT_ON_ERROR(g_ort->GetDimensions(info, dims, dim_sz));

	if (dim_sz != 2) {
		fprintf(stderr, "Unable to process output from cner, number of dims %z", dim_sz);
		return std::forward_list<category_ent_t>();
		// return std::map < std::string, std::pair<int,int> > ();
	}

	uint64_t* output_data = NULL;
	ORT_ABORT_ON_ERROR(g_ort->GetTensorMutableData(output, (void**)&output_data));


	g_ort->ReleaseValue(value);
	g_ort->ReleaseValue(mask);
	g_ort->ReleaseTensorTypeAndShapeInfo(info);
	g_ort->ReleaseValue(output);

	arma::u64_mat mat(output_data, dims[0], dims[1], false);
	auto maxIdx = arma::Row(arma::index_max(mat, 0));
	int i = 0;

	std::string last = "";
	// std::unordered_map<std::string, std::pair<int,int>> symbols;
	std::forward_list<category_ent_t> symbols;
	int last_category = 0;
	int last_id = 0;
	int len = flattened_tokens.size();
	minimal_uuid4::Generator gen;
	int dist = 1;
	for (auto token_id : flattened_tokens) {
		int val = maxIdx(i);
		int current_category = _unnu_cner_category(val);
		if (val != 0) {
			// determine if continuation
			if ((val % 2) && last_category == current_category) {
				last.append(_tokenizer_settings.tokenizer->IdToToken(token_id));
			}
			else if (last_category == current_category) { // new but same category
				category_ent_t entity;
				entity.id = last.append("|").substr(0, 36);;
				entity.value = last.substr(37);
				entity.entity_type = last_category;
				entity.grouping = dist;
				// symbols.push_front(std::pair < std::string, std::pair<int, int> > (last.append("|"), std::make_pair(last_category, dist)));
				symbols.push_front(entity);
				last = gen.uuid4().str();
				last.erase(std::remove(last.begin(), last.end(), '-'), last.end());
				last.append("+|").append(_tokenizer_settings.tokenizer->IdToToken(token_id));
				dist = 0;
			}
			else { // new and different
				if (!last.empty()) {
					category_ent_t entity;
					entity.id = last.append("|").substr(0, 36);;
					entity.value = last.substr(37);
					entity.entity_type = last_category;
					entity.grouping = dist;
					symbols.push_front(entity);
					dist = 0;
				}
				last = gen.uuid4().str();
				last.erase(std::remove(last.begin(), last.end(), '-'), last.end());
				last.append("+|").append(_tokenizer_settings.tokenizer->IdToToken(token_id));
				last_category = current_category;
			}
		} else if (last_category != 0) {  // complete last symbol, do not start new
			if (!last.empty()) {
				category_ent_t entity;
				entity.id = last.append("|").substr(0, 36);;
				entity.value = last.substr(37);
				entity.entity_type = last_category;
				entity.grouping = dist;
				symbols.push_front(entity);
				dist = -1;
			}
			last = "";
			last_category = current_category; // this should always be 0
		} else {
		    auto tok = _tokenizer_settings.tokenizer->IdToToken(token_id);
			if (!(tok.find('.') != std::string::npos || tok.find('?') != std::string::npos || tok.find('!') != std::string::npos)) {
		        dist=1;
		    }
		}

		i++;
		if (i == len) {
			if (!last.empty()) { // write the end
				category_ent_t entity;
				entity.id = last.append("|").substr(0, 36);;
				entity.value = last.substr(37);
				entity.entity_type = last_category;
				entity.grouping = dist;
				symbols.push_front(entity);
				dist = 0;
			}
		}
	}
	return symbols;
}

std::forward_list<category_ent_t> _unnu_cner_process_statement(std::string statement) {
	if (!statement.empty()) {
		std::vector<std::string> sentences;
		sentences.push_back(statement);
		if (sentences.size() > 0) {
			return _unnu_cner_process_paragraph(sentences);
		}
	}
	return std::forward_list<category_ent_t>();
}

const char* unnu_soar_run(const char* cmdln) {
	return unnu->ExecuteCommandLine(cmdln);
}

std::string add_to_smem_command(std::forward_list<category_ent_t> entries) {
	std::string concept = "";
	std::string command = "";
	std::vector<std::string> snippets;
	std::vector<std::string> statements;
	int i = 0;
	bool found_new_concept = false;
	int flag = 0;
	for (auto it = entries.cbegin(), end = entries.cend(); it != end; it++, i++) {
		auto val = *it;
		std::string snippet;
		snippet.append("(<").append(val.id).append("> ^type ").append("" + val.entity_type).append("\n")
			.append("^value |").append(val.value).append("|)");
		snippets.push_back(snippet);

		if (val.grouping == 0) {
			if (!concept.empty()) {
				concept.append(" ");
			}
			concept.append(val.value);
			flag |= val.entity_type;
			found_new_concept = (concept.compare(val.value) != 0);
		} else {
			if (found_new_concept) {
				std::string novelty;
				novelty.append("(<c" + i).append("> ^type ").append("" + flag).append("\n")
					.append("^value |").append(concept).append("|)");
				snippets.push_back(novelty);
				command.append(" ^novelty <").append("<c" + i).append(">\n");
			}
			concept = val.value;
			flag = val.entity_type;
		}

		if (val.grouping == 1) {
			if (!command.empty()) {
				command.append(")");
				statements.push_back(command);
				command = "";
			}
			command.append("(<s"+i).append(val.id).append("> ^clause <").append(val.id).append(">\n");
		}
		else {
			command.append(" ^clause <").append(val.id).append(">\n");
		}
	}

	if (!command.empty()) {
		command.append(")");
		statements.push_back(command);
	}

	auto stmt = std::accumulate(
		std::next(statements.begin()),
		statements.end(),
		statements[0],
		[](std::string a, std::string b) {
			return a + "\n" + b;
		}
	);

	auto snips = std::accumulate(
		std::next(snippets.begin()),
		snippets.end(),
		snippets[0],
		[](std::string a, std::string b) {
			return a + "\n" + b;
		}
	);

	std::string cmdln = "smem --add {\n";
	cmdln.append(stmt).append("\n").append(snips).append("\n}");
	return cmdln;
}

std::string _unnu_learn(sml::smlRhsEventId id, void* pUserData, sml::Agent* pAgent,
	char const* pFunctionName, char const* pArgument) {
	auto thought = (ThoughtBuffer_t*) pUserData;
	std::string result;

	std::string statement(pArgument);
	auto ret = _unnu_cner_process_statement(statement);
	auto cmdln = add_to_smem_command(ret);
	return std::string(unnu_soar_run(cmdln.c_str()));
}

void _updateCorpus() {
	// See if any commands were generated on the output link
	// (In general we might want to update the world when the agent
	// takes no action in which case some code would be outside this if statement
	// but for this environment that's not necessary).
	if (unnu->Commands())
	{
		/*for (int i = 0, cmds = unnu->GetNumberCommands(); i < cmds; i++) {
			// perform the command on the output link
			sml::Identifier* const command = unnu->GetCommand(i);
			// "agent.GetCommand(n)" is based on watching for changes to the output link
			// so before we do a run we clear the last set of changes.
			// (You can always read the output link directly and not use the
			//  commands model to determine what has changed between runs).
		}*/
		// Send the new input link changes to the agent
		if (!smlkernel->IsAutoCommitEnabled()) {
			unnu->Commit();
		}

		unnu->ClearOutputLinkChanges();
	}
}

void _UpdateEventHandler(sml::smlUpdateEventId id, void* pUserData, sml::Kernel* pKernel, sml::smlRunFlags runFlags) {
	if (runFlags & sml::smlRunFlags::sml_DONT_UPDATE_WORLD) {
		return;
	}
	// Might not call updateWorld() depending on runFlags in a fuller environment.
	// See the section below for more on this.
	_updateCorpus();

	// We have a problem at the moment with calling Stop() from arbitrary threads
	// so for now we'll make sure to call it within an event callback.
	// Do this test after calling updateWorld() so that method can set m_StopNow if it
	// wishes and trigger an immediate stop.
	if (m_StopNow)
	{
		m_StopNow = false;
		smlkernel->StopAllAgents();
	}
}

void _llm_handler(void* pUserData, sml::Agent* pAgent, char const* pCommandName, sml::WMElement* pOutputWme) {

	if (pOutputWme != NULL && pCommandName != NULL) {
		if (pOutputWme->IsIdentifier()) {
			auto wme = pOutputWme->ConvertToIdentifier();
			auto type = wme->GetParameterValue("type");
			if (type != NULL) {
				if (strcmp(pCommandName, "lm-request") == 0) {
					auto task_handle = wme->FindByAttribute("task-handle", 0);
					if (task_handle != NULL && strcmp(type, "get-next-goal") == 0) {
							auto tmpl = wme->FindByAttribute("template", 0);
							auto goal = wme->FindByAttribute("task-goal", 0);

					}
				}
				else if (strcmp(pCommandName, "lm-request-step") == 0) {
					auto current_step = wme->FindByAttribute("current-step", 0);
					if (current_step != NULL && current_step->IsIdentifier()) {
						auto expand_wme = current_step->ConvertToIdentifier();
						auto post_proc = wme->FindByAttribute("post-processing", 0);

					} else {
						auto user_step = wme->FindByAttribute("user-step", 0);
						if (user_step != NULL && user_step->IsIdentifier()) {
							auto user_wme = user_step->ConvertToIdentifier();
							auto post_proc = wme->FindByAttribute("post-processing", 0);
							auto sentence_wme = user_wme->FindByAttribute("sentence", 0);
							if (sentence_wme != NULL) {
								auto sentence = sentence_wme->GetValueAsString();

							}
						}
					}
				}
				else if (strcmp(pCommandName, "lm-request-retry") == 0) {
					auto current_node = wme->FindByAttribute("current-node", 0);
					if (current_node != NULL && current_node->IsIdentifier()) {
						auto expand_wme = current_node->ConvertToIdentifier();
						if (strcmp(type, "retry-goal") == 0) {
						}
					}
				}
				else if (strcmp(pCommandName, "lm-selection-request") == 0) {
					auto task_goal = wme->FindByAttribute("task-goal", 0);
					if (task_goal != NULL && task_goal->IsIdentifier()) {
						auto expand_wme = task_goal->ConvertToIdentifier();
						if (strcmp(type, "lm-selection-request") == 0) {
							auto options = wme->FindByAttribute("options", 0);
							if (options != NULL && options->IsIdentifier()) {
								auto options_wme = options->ConvertToIdentifier();
								for (auto iter = options_wme->GetChildrenBegin(), end = options_wme->GetChildrenEnd(); iter != end; iter++)
								{
									auto elem = *iter;
									if (elem != NULL && elem->IsIdentifier()) {
										auto pWME = elem->ConvertToIdentifier();
										auto opt = pWME->FindByAttribute("option", 0);
										
									}
								}
							}
						}
					}
				}
				else if (strcmp(pCommandName, "send-message") == 0) {
					if (strcmp(type, "single-word-response") == 0) {
						auto fields = wme->FindByAttribute("fields", 0);
						if (fields != NULL && fields->IsIdentifier()) {
							auto fields_wme = fields->ConvertToIdentifier();
							for (auto iter = fields_wme->GetChildrenBegin(), end = fields_wme->GetChildrenEnd(); iter != end; iter++)
							{
								auto elem = *iter;
								if (elem != NULL && strcmp(elem->GetIdentifierName(), "word") ==0) {
									auto ans = elem->GetValueAsString();
								}
							}
						}
					}
				}
			}
			wme->AddStatusComplete();
		}
	}
}

void _unnu_soar_setup(std::string& path) {
	smlkernel = sml_kernel_ptr(sml::Kernel::CreateKernelInCurrentThread(true, 0));
	unnu = smlkernel->CreateAgent("unnu");
	if (!smlkernel->IsAutoCommitEnabled()) {
		smlkernel->SetAutoCommit(true);
	}
	unnu->AddOutputHandler("send-message", _llm_handler, NULL, true);
	unnu->AddOutputHandler("lm-request", _llm_handler, NULL, true);
	unnu->AddOutputHandler("lm-request-step", _llm_handler, NULL, true);
	unnu->AddOutputHandler("lm-request-retry", _llm_handler, NULL, true);
    unnu->AddOutputHandler("lm-selection-request", _llm_handler, NULL, true);
	smlkernel->RegisterForUpdateEvent(sml::smlEVENT_AFTER_ALL_OUTPUT_PHASES, _UpdateEventHandler, &musing, true);
	smlkernel->AddRhsFunction("learn", _unnu_learn, &thought, true);
	auto soarpath = std::filesystem::path(path);
	soarpath += "load.soar";
	unnu->LoadProductions(soarpath.generic_string().c_str(), false);
}

void unnu_soar_reset() {
	unnu->InitSoar();
}

void unnu_soar_init(const char* path) {
	if (smlkernel == nullptr) {
		std::string production(path);
		// _unnu_soar_setup(production);
		std::thread thr(_unnu_soar_setup, std::ref(production));
		thr.detach();
	}
}

void unnu_soar_destroy()
{
	if (unnu != nullptr) {
		smlkernel->DestroyAgent(unnu);
		unnu = nullptr;
	}
	smlkernel->Shutdown();
	smlkernel = nullptr;
	// unnu_unset_soar_response_callback();
}

void unnu_soar_start() {
	if (!smlkernel->IsSoarRunning()) {
		smlkernel->RunAllAgentsForever();
	}
}

void unnu_soar_stop() {
	smlkernel->StopAllAgents();
}

void unnu_oga_init(const char* model_path) {
	_slm_engine = microsoft::slm_engine::SLMEngine::CreateEngine(
        model_path, false);
/*
	auto config = OgaConfig::Create(model_path);
	config->ClearProviders();

	_model = oga_model_ptr(OgaModel::Create(*config));
	_tokenizer = oga_tokenizer_ptr(OgaTokenizer::Create(*_model));
*/
}

static void _oga_prompt() {
	// auto params = OgaGeneratorParams::Create(*_model);
	// params->SetSearchOption("max_length", UNNU_CE_MAX_LENGTH);
	while (isRunning.load()) {
		auto _current = _prompts.front();
		try {
			json msgs = json::array();
			if(!_current.system_prompt.empty()){
				json system_prompt = json::object();
				system_prompt["role"] = "system";
				system_prompt["content"] = _current.system_prompt;
				msgs.push_back(system_prompt);
			}
			json user_prompt = json::object();
			user_prompt["role"] = "user";
			user_prompt["content"] = _current.user_prompt;
			msgs.push_back(user_prompt);
			
			json _input = json::object();
			_input["messages"] = msgs;
			_input["temperature"]= UNNU_CE_TEMP;
			_input["top_k"]= UNNU_CE_TOP_K;
			_input["top_p"]= UNNU_CE_TOP_P;
			_input["max_tokens"]= UNNU_CE_MAX_LENGTH;
			
			auto response = _slm_engine->complete(_input.dump().c_str());
			try{
				json output_json = json::parse(response);
				if (output_json.contains("response")) {
					UnnuOgaResult_t res;
					std::string result = output_json["response"].get<std::string>();
					res.length = result.length();
					res.result = (char*)std::calloc(res.length + 1, sizeof(char));
					std::memcpy(res.result, result.c_str(), res.length);
					res.result[res.length] = '\0';
					result_cb(res);
				}
			} catch (const nlohmann::json::parse_error& e) {
				fprintf(stderr,"Failed to parse JSON:\n%s\n", e.what());
			}
			
			/*
			auto tokenizer_stream = OgaTokenizerStream::Create(*_tokenizer);

			auto sequences = OgaSequences::Create();
			_tokenizer->Encode(prompt.c_str(), *sequences);

			auto generator = OgaGenerator::Create(*_model, *params);

			generator->AppendTokenSequences(*sequences);

			try {
				std::string result;
				while (!generator->IsDone()) {
					generator->GenerateNextToken();

					const auto num_tokens = generator->GetSequenceCount(0);
					const auto new_token = generator->GetSequenceData(0)[num_tokens - 1];
					result.append(tokenizer_stream->Decode(new_token));
				}
				if (!result.empty()) {
					UnnuOgaResult_t res;
					res.length = result.length();
					res.result = (char*)std::calloc(res.length + 1, sizeof(char));
					std::memcpy(res.result, result.c_str(), res.length + 1);
					result_cb(res);
				}
			*/
		}catch (const std::exception& e) {
			printf("Session Terminated: %s\n", e.what());
		}
		_prompts.pop();
		isRunning = !_prompts.empty();
	}
}


void unnu_oga_prompt(const char* prompt) {
	Prompt_t p;
	p.system_prompt = !_sysprompt.empty() ? _sysprompt : "";
	p.user_prompt = prompt;
	// std::string str(prompt);
	_prompts.push(p);
	if (!isRunning.load()) {
	    isRunning = !_prompts.empty();
		std::thread thr(_oga_prompt);
		thr.detach();
	}
}

void unnu_cner_destroy() {
	if (_ort_session != nullptr) {
		auto g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION);
		if (!g_ort)
		{
			fprintf(stderr, "Failed to init ONNX Runtime engine.\n");
			return;
		}
		g_ort->ReleaseSession(_ort_session);
		g_ort->ReleaseSessionOptions(_session_options);
		g_ort->ReleaseRunOptions(_run_options);
		g_ort->ReleaseEnv(_ort_env);
	}
}

void unnu_set_oga_result_callback(OgaResultCallback callback) {
	result_cb = callback;
}

void unnu_unset_oga_result_callback() {
	result_cb = nullptr;
}