#include <stdlib.h>
#include <float.h>
// #include <threads.h>
#include <time.h>
#include <string.h>
#include <queue>
#include <string>
#include <cmath>
#include <cstring>
#include <thread>
#include <atomic>
#include <cpuinfo.h>


#include "llamacpp.h"

#include "common.h"

#include "chat.h"

#include "sampling.h"

#include "llama-context.h"


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

typedef struct common_params common_params_t;

typedef struct cpu_params cpu_params_t;

typedef struct ggml_threadpool_params ggml_threadpool_params_t;

// typedef struct ggml_threadpool ggml_threadpool_t;

typedef struct ggml_threadpool* ggml_threadpool_ptr;

typedef struct common_params_sampling common_params_sampling_t;


typedef struct common_params_model common_params_model_t;

typedef struct common_init_result common_init_result_t;

typedef struct llama_vocab llama_vocab_t;

typedef struct common_chat_templates common_chat_templates_t;
typedef struct common_sampler common_sampler_t;
typedef struct llama_model llama_model_t;
typedef struct llama_context llama_context_t;
typedef struct common_chat_syntax common_chat_syntax_t;

typedef struct chat_syntax {
	common_chat_format format;
	common_reasoning_format reasoning;
	bool is_reasoning;

} chat_syntax_t;

static chat_syntax_t _chat_format;

static std::string _system_prompt;

typedef struct lcpp_prompt_args {
	std::vector<common_chat_msg_t> messages;
	llama_model_t* model = nullptr;
	llama_context_t* context = nullptr;
	common_sampler_t* sampler = nullptr;
	common_chat_templates_t* chat_templates = nullptr;
} lcpp_prompt_args_t;

static std::atomic<bool> _abort{ false };

static std::atomic<bool> _cancel{ false };

static std::atomic<bool> _loaded{ false };

static LppTokenStreamCallback TokenStreamCallback = nullptr;

static LppProgressCallback LoadingProgressCallback = nullptr;

typedef struct free_deleter {
	void operator()(void* p) {
		free(p);
	}
} free_deleter_t;

typedef std::unique_ptr<char, free_deleter_t> char_array_ptr;

// static std::vector<LcppTextStruct_t*> tokenStreamResponses;

static LppChatMessageCallback ChatMessageCallback = nullptr;

typedef struct common_init_result_deleter {
	void operator()(common_init_result_t* result) {
		if (!result->lora.empty()) {
			size_t len = result->lora.size();
			for (int i = 0; i < len; i++) {
				llama_adapter_lora_free(result->lora[i].get());
			}
		}

		llama_free(result->context.get());
		llama_model_free(result->model.get());
	}
} common_init_result_deleter_t;

typedef std::unique_ptr<common_init_result_t, common_init_result_deleter_t> common_init_result_ptr;

static llama_model_ptr _model;

static llama_context_ptr _ctx;

typedef struct common_sampler_deleter {
	void operator()(common_sampler_t* gsmpl) {
		common_sampler_free(gsmpl);
	}
} common_sampler_deleter_t;

typedef std::unique_ptr<common_sampler_t, common_sampler_deleter_t> common_sampler_ptr;

common_chat_msg_t lcpp_common_chat_msg_to_common_chat_msg(lcpp_common_chat_msg_t* msg) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_common_chat_msg_to_common_chat_msg()\n");
#endif
	GGML_ASSERT(msg != nullptr);
	common_chat_msg_t message;
	if (msg->role != nullptr) {
		message.role = std::string(msg->role);
	}
	if (msg->content != nullptr) {
		message.content = std::string(msg->content);
	}
	if (msg->tool_name != nullptr) {
		message.tool_name = std::string(msg->tool_name);
	}
	if (msg->tool_call_id != nullptr) {
		message.tool_call_id = std::string(msg->tool_call_id);
	}
	if (msg->reasoning_content != nullptr) {
		message.reasoning_content = std::string(msg->reasoning_content);
	}
	if (msg->n_tool_calls > 0) {
		for (auto it = msg->tool_calls; it != nullptr; it++) {
			auto result = *it;
			common_chat_tool_call toolcall;
			if (result->arguments != nullptr) {
				toolcall.arguments = std::string(result->arguments);
			}
			if (result->id != nullptr) {
				toolcall.id = std::string(result->id);
			}
			if (result->name != nullptr) {
				toolcall.name = std::string(result->name);
			}
			message.tool_calls.push_back(toolcall);
		}
	}
	if (msg->n_content_parts > 0) {
		for (auto it = msg->content_parts; it != nullptr; it++) {
			auto result = *it;
			common_chat_msg_content_part content;
			if (result->text != nullptr) {
				content.text = std::string(result->text);
			}
			if (result->type != nullptr) {
				content.type = std::string(result->type);
			}
			message.content_parts.push_back(content);
		}
	}
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_common_chat_msg_to_common_chat_msg::>\n");
#endif
	return message;
}

void lcpp_free_common_chat_msg(lcpp_common_chat_msg_t* msg) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_free_common_chat_msg()\n");
#endif
	if (msg) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "lcpp_free_common_chat_msg deleting ...\n");
#endif
		free(msg->content);
		free(msg->role);

		if (msg->n_content_parts > 0) {
			for (int i = 0; i < msg->n_content_parts; i++) {
				if (msg->content_parts[i] != nullptr) {
					free(msg->content_parts[i]->text);
					free(msg->content_parts[i]->type);
				}
			}
		}

		if (msg->n_tool_calls > 0) {
			for (int j = 0; j < msg->n_tool_calls; j++) {
				if (msg->tool_calls[j] != nullptr) {
					free(msg->tool_calls[j]->arguments);
					free(msg->tool_calls[j]->name);
					free(msg->tool_calls[j]->id);
				}
			}
		}

		free(msg->reasoning_content);
		free(msg->tool_name);
		free(msg->tool_call_id);

		delete msg;
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "lcpp_free_common_chat_msg=deleted\n");
#endif
	}
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_free_common_chat_msg::>\n");
#endif
}

typedef struct lcpp_common_chat_msg_deleter {
	void operator()(lcpp_common_chat_msg_t* msg) {
		lcpp_free_common_chat_msg(msg);
	}
} lcpp_common_chat_msg_deleter_t;

typedef std::unique_ptr<lcpp_common_chat_msg_t, lcpp_common_chat_msg_deleter_t> lcpp_common_chat_msg_ptr;

static common_sampler_ptr _sampler;

static common_chat_templates_ptr _chat_templates;

static std::atomic<bool> _use_jinja{ false };



lcpp_params_t lcpp_params_defaults() {

	lcpp_common_sampler_type_t samplers[8] = {
			LCPP_COMMON_SAMPLER_TYPE_PENALTIES,
			LCPP_COMMON_SAMPLER_TYPE_DRY,
			LCPP_COMMON_SAMPLER_TYPE_TOP_K,
			LCPP_COMMON_SAMPLER_TYPE_TYPICAL_P,
			LCPP_COMMON_SAMPLER_TYPE_TOP_P,
			LCPP_COMMON_SAMPLER_TYPE_MIN_P,
			LCPP_COMMON_SAMPLER_TYPE_XTC,
			LCPP_COMMON_SAMPLER_TYPE_TEMPERATURE
	};

	lcpp_params_t result = {
		/* <= 0.0 to sample greedily, 0.0 to not output probabilities float temp =*/
		0.80f,
		/* 0.0 = disabled float dynatemp_range =*/
		0.00f,
		/* controls how entropy maps to temperature in dynamic temperature sampler float dynatemp_exponent =*/
		1.00f,
		/* 1.0 = disabled float top_p =*/
		0.95f,
		/* 0.0 = disabled float min_p =*/
		0.05f,
		/* 0.0 = disabled float xtc_probability =*/
		0.00f,
		/* > 0.5 disables XTC float xtc_threshold =*/
		0.10f,
		/* typical_p, 1.0 = disabled float typ_p =*/
		1.00f,
		/* 1.0 = disabled float penalty_repeat =*/
		1.00f,
		/* 0.0 = disabled float penalty_freq =*/
		0.00f,
		/* 0.0 = disabled float penalty_present =*/
		0.00f,
		/* 0.0 = disabled; DRY repetition penalty for tokens extending repetition: float dry_multiplier =*/
		0.0f,
		/* 0.0 = disabled; multiplier* base ^ (length of sequence before token - allowed length) float dry_base =*/
		1.75f,
		/* -1.0 = disabled float top_n_sigma =*/
		-1.00f,
		/* target entropy float mirostat_tau =*/
		5.00f,
		/* learning rate float mirostat_eta =*/
		0.10f,
		/* the seed used to initialize llama_sampler, uint32_t seed =*/
		LLAMA_DEFAULT_SEED,
		/* number of previous tokens to remember int32_t n_prev = */
		64,
		/* if greater than 0, output the probabilities of top n_probs tokens. int32_t n_probs =*/
		0,
		/* 0 = disabled, otherwise samplers should return at least min_keep tokens int32_t min_keep =*/
		0,
		/* <= 0 to use vocab size int32_t top_k = */
		40,
		/* last n tokens to penalize (0 = disable penalty, -1 = context size) int32_t penalty_last_n =*/
		64,
		/* tokens extending repetitions beyond this receive penalty int32_t dry_allowed_length =*/
		2,
		/* how many tokens to scan for repetitions(0 = disable penalty, -1 = context size) int32_t dry_penalty_last_n = */
		-1,
		/* number of layers to store in VRAM, int32_t n_gpu_layers= */
		-1,
		/* the GPU that is used for the entire model when split_mode is LLAMA_SPLIT_MODE_NONE, int32_t main_gpu = */
		0,
		/* samplers[8] */
		8,
		/* grammar = nullptr */
		0,
		/* model_path = nullptr */
		0,
		/* 0 = disabled, 1 = mirostat, 2 = mirostat 2.0 int32_t mirostat =*/
		LCPP_MIROSTAT_NONE,
		/* model family based on file name e.g. deepseek qwen*/
		LCPP_MODEL_FAMILY_UNSPECIFIED,
		/* how to split the model across multiple GPUs */
		LCPP_SPLIT_MODE_NONE,
		/* bool ignore_eos = */
		false,
		/* disable performance metrics bool no_perf = */
		true,
		/* bool timing_per_token = */
		false,
		/* bool grammar_lazy =*/
		false,
		/* only load the vocabulary (no weights), bool vocab_only = */
		false,
		/* use mmap if possible , bool use_mmap=*/
		true,
		/* force system to keep model in RAM, bool use_mlock= */
		true,
		/* validate model tensor data, bool check_tensors= */
		false,
		/* escape "\n", "\r", "\t", "\'", "\"", and "\\" bool escape= */
		false,
		/* reverse the usage of `\` bool multiline_input=*/
		 false,
		 /* loading reasoning model*/
		 false,
		 /* common_sampler_type samplers[8] =*/
		 samplers,
		 /* optional BNF-like grammar to constrain sampling char* grammar =*/
		 nullptr,
		 /* required path to GGUF model file */
		 nullptr
	};

	return result;
}

void lcpp_send_abort_signal(bool abort) {
	_abort = abort;
}

void lcpp_send_cancel_signal(bool cancel) {
	_cancel = cancel;
}

bool _ggml_progress_callback(float progress, void* user_data) {
	if (LoadingProgressCallback != nullptr) {
		LcppFloatStruct_t* _float = (LcppFloatStruct_t*)malloc(sizeof(LcppFloatStruct_t));
		_float->value = progress;
		LoadingProgressCallback(_float);
	}

	if (_cancel.load()) {
		_cancel = false; // reset
		return true;
	}
	return false;
}

bool _ggml_abort_callback(void* data) {
	if (_abort.load()) {
		_abort = false; // reset
		return true;
	}
	return false;
}

void on_new_token(const char* token) {

	auto response = (LcppTextStruct_t*)malloc(sizeof(LcppTextStruct_t));
	size_t len = strlen(token);
	response->length = len;
	response->text = (char*)std::calloc(len + 1, sizeof(char));
	std::memcpy(response->text, token, len);
	response->text[len] = '\0';
	// #if defined(_DEBUG) || defined(DEBUG)
	// printf("ont: %s\n", response->text);
	// #endif
	TokenStreamCallback(response);
	// tokenStreamResponses.push_back(response);
}

void lcpp_set_token_stream_callback(LppTokenStreamCallback new_token_callback) {
	TokenStreamCallback = new_token_callback;
}

void lcpp_unset_token_stream_callback() {
	TokenStreamCallback = nullptr;
}

void lcpp_set_chat_message_callback(LppChatMessageCallback chat_message_callback) {
	ChatMessageCallback = chat_message_callback;
}

void lcpp_unset_chat_message_callback() {
	ChatMessageCallback = nullptr;
}

void lcpp_set_model_load_progress_callback(LppProgressCallback model_loading_callback) {
	LoadingProgressCallback = model_loading_callback;
}

void lcpp_unset_model_load_progress_callback() {
	LoadingProgressCallback = nullptr;
}

static void _set_use_jinja_by_model_family(lcpp_model_family_t model_family) {

	switch (model_family) {
	case LCPP_MODEL_FAMILY_DEEPSEEK:
	case LCPP_MODEL_FAMILY_LLAMA:
	case LCPP_MODEL_FAMILY_MISTRAL:
	case LCPP_MODEL_FAMILY_GRANITE:
	case LCPP_MODEL_FAMILY_GEMMA:
	case LCPP_MODEL_FAMILY_QWEN:
	case LCPP_MODEL_FAMILY_PHI:
		_use_jinja = true;
		break;
	default:
		_use_jinja = false;
		break;
	}
}

static void _set_common_format_by_model_family(lcpp_model_family_t model_family, bool is_reasoning) {

	switch (model_family) {
	case LCPP_MODEL_FAMILY_DEEPSEEK:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_GENERIC;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	case LCPP_MODEL_FAMILY_QWEN:
	case LCPP_MODEL_FAMILY_GRANITE:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_GENERIC;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	break;
	case LCPP_MODEL_FAMILY_LLAMA:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_LLAMA_3_X_WITH_BUILTIN_TOOLS;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK_LEGACY : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	break;
	case LCPP_MODEL_FAMILY_MISTRAL:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_MISTRAL_NEMO;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK_LEGACY : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	break;
	case LCPP_MODEL_FAMILY_PHI:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_GENERIC;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	break;
	case LCPP_MODEL_FAMILY_GEMMA:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_CONTENT_ONLY;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK_LEGACY : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	break;
	default:
	{
		_chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_DEEPSEEK_R1 : COMMON_CHAT_FORMAT_CONTENT_ONLY;
		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
		_chat_format.is_reasoning = is_reasoning;
	}
	break;
	}
}

lcpp_common_chat_msg_t* _to_lcpp_common_chat_msg(std::string& response, chat_syntax_t format) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_to_lcpp_common_chat_msg\n");
#endif
	common_chat_syntax_t syntax;
	syntax.format = format.format;
	syntax.reasoning_in_content = (format.is_reasoning && format.format == COMMON_CHAT_FORMAT_DEEPSEEK_R1);
	syntax.thinking_forced_open = (format.is_reasoning && format.reasoning == COMMON_REASONING_FORMAT_DEEPSEEK_LEGACY);
	syntax.reasoning_format = format.reasoning;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "common_chat_parse\n");
#endif
	common_chat_msg_t msg = common_chat_parse(response, false, syntax);
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "common_chat_parse::>\n");
#endif

	lcpp_common_chat_msg_t* _msg = (lcpp_common_chat_msg_t*)malloc(sizeof(lcpp_common_chat_msg_t));
	_msg->n_role = msg.role.length();
	if (_msg->n_role > 0) {
		_msg->role = (char*)std::calloc(_msg->n_role + 1, sizeof(char));
		memcpy(_msg->role, msg.role.c_str(), _msg->n_role);
		_msg->role[_msg->n_role] = '\0';
	}
	else {
		_msg->role = nullptr;
	}

	_msg->n_content = msg.content.length();
	if (_msg->n_content > 0) {
		_msg->content = (char*)std::calloc(_msg->n_content + 1, sizeof(char));
		memcpy(_msg->content, msg.content.c_str(), _msg->n_content);
		_msg->content[_msg->n_content] = '\0';
	}
	else {
		_msg->content = nullptr;
	}

	_msg->n_reasoning_content = msg.reasoning_content.length();
	if (_msg->n_reasoning_content > 0) {
		_msg->reasoning_content = (char*)std::calloc(_msg->n_reasoning_content + 1, sizeof(char));
		memcpy(_msg->reasoning_content, msg.reasoning_content.c_str(), _msg->n_reasoning_content);
		_msg->reasoning_content[_msg->n_reasoning_content] = '\0';
	}
	else {
		_msg->reasoning_content = nullptr;
	}

	_msg->n_tool_name = msg.tool_name.length();
	if (_msg->n_tool_name > 0) {
		_msg->tool_name = (char*)std::calloc(_msg->n_tool_name + 1, sizeof(char));
		memcpy(_msg->tool_name, msg.tool_name.c_str(), _msg->n_tool_name);
		_msg->tool_name[_msg->n_tool_name] = '\0';
	}
	else {
		_msg->tool_name = nullptr;
	}

	_msg->n_tool_call_id = msg.tool_call_id.length();
	if (_msg->n_tool_call_id > 0) {
		_msg->tool_call_id = (char*)std::calloc(_msg->n_tool_call_id + 1, sizeof(char));
		memcpy(_msg->tool_call_id, msg.tool_call_id.c_str(), _msg->n_tool_call_id);
		_msg->tool_call_id[_msg->n_tool_call_id] = '\0';
	}
	else {
		_msg->tool_call_id = nullptr;
	}

	if (!msg.content_parts.empty()) {
		std::vector<plcpp_common_chat_msg_content_part_t> parts(msg.content_parts.size());
		for (auto it = msg.content_parts.cbegin(); it != msg.content_parts.cend(); it++) {
			auto contents = *it;
			auto part = (plcpp_common_chat_msg_content_part_t)malloc(sizeof(lcpp_common_chat_msg_content_part_t));
			part->n_text = contents.text.size();
			if (part->n_text > 0) {
				part->text = (char*)std::calloc(part->n_text + 1, sizeof(char));
				memcpy(part->text, contents.text.c_str(), part->n_text);
				part->text[part->n_text] = '\0';
			}
			else {
				part->text = nullptr;
			}

			part->n_type = contents.type.size();
			if (part->n_type > 0) {
				part->type = (char*)std::calloc(part->n_type + 1, sizeof(char));
				memcpy(part->type, contents.text.c_str(), part->n_type);
				part->type[part->n_type] = '\0';
			}
			else {
				part->type = nullptr;
			}
			parts.push_back(part);
		}
		int sz = parts.size();
		_msg->content_parts = (plcpp_common_chat_msg_content_part_t*)calloc(sizeof(plcpp_common_chat_msg_content_part_t), sz);
		memcpy(parts.data(), _msg->content_parts, sizeof(plcpp_common_chat_msg_content_part_t) * sz);
		_msg->n_content_parts = sz;
	}
	else {
		_msg->content_parts = nullptr;
		_msg->n_content_parts = 0;
	}

	if (!msg.tool_calls.empty()) {
		std::vector<plcpp_common_chat_tool_call_t> toolcalls(msg.tool_calls.size());
		for (auto it = msg.tool_calls.cbegin(); it != msg.tool_calls.cend(); it++) {
			auto tool_call = *it;
			auto toolcall = (plcpp_common_chat_tool_call_t)malloc(sizeof(lcpp_common_chat_tool_call_t));
			toolcall->n_name = tool_call.name.size();
			if (toolcall->n_name > 0) {
				toolcall->name = (char*)std::calloc(toolcall->n_name + 1, sizeof(char));
				memcpy(toolcall->name, tool_call.name.c_str(), toolcall->n_name);
				toolcall->name[toolcall->n_name] = '\0';
			}
			else {
				toolcall->name = nullptr;
			}

			toolcall->n_id = tool_call.id.size();
			if (toolcall->n_id > 0) {
				toolcall->id = (char*)std::calloc(toolcall->n_id + 1, sizeof(char));
				memcpy(toolcall->id, tool_call.id.c_str(), toolcall->n_id);
				toolcall->id[toolcall->n_id] = '\0';
			}
			else {
				toolcall->id = nullptr;
			}

			toolcall->n_arguments = tool_call.arguments.size();
			if (toolcall->n_arguments > 0) {
				toolcall->arguments = (char*)std::calloc(toolcall->n_arguments + 1, sizeof(char));
				memcpy(toolcall->arguments, tool_call.arguments.c_str(), toolcall->n_arguments);
				toolcall->arguments[toolcall->n_arguments] = '\0';
			}
			else {
				toolcall->arguments = nullptr;
			}

			toolcalls.push_back(toolcall);
		}

		int sz = toolcalls.size();
		_msg->tool_calls = (plcpp_common_chat_tool_call_t*)calloc(sizeof(plcpp_common_chat_tool_call_t), sz);
		memcpy(toolcalls.data(), _msg->tool_calls, sizeof(plcpp_common_chat_tool_call_t) * sz);

		_msg->n_tool_calls = sz;
	}
	else {
		_msg->tool_calls = nullptr;
		_msg->n_tool_calls = 0;
	}
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_to_lcpp_common_chat_msg:>\n");
#endif
	return _msg;
}
/*
bool _is_first(llama_context_t* ctx) {
	for (uint32_t s = 0; s < ctx->n_seq_max(); s++) {
		int32_t pos_min = llama_kv_self_seq_pos_min(ctx, s);
		if (pos_min > -1) {
			return false;
		}
	}
	return true;
}

int32_t used_cells(llama_context_t* ctx) {
	int32_t res = 0;
	for (uint32_t s = 0; s < ctx->n_seq_max(); s++) {
		int32_t pos_max = llama_kv_self_seq_pos_max(ctx, s);
		int32_t pos_min = llama_kv_self_seq_pos_min(ctx, s);
		if (pos_min > -1) {
			res += (pos_max - pos_min) + 1;
		}
	}
	return res;
}*/

// int _prompt(void* args) {
int _prompt(lcpp_prompt_args_t prompt_args) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_prompt()\n");
#endif
	if (!(prompt_args.messages.size() > 0)) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "_prompt: GGML_EXIT_ABORTED\n");
#endif
		return GGML_EXIT_ABORTED;
	}
	std::vector<common_chat_msg_t> chat_msgs;
	int sz = prompt_args.messages.size();
	for (int i = 0; i < sz; i++) {
		chat_msgs.push_back(prompt_args.messages[i]);
	}

	common_chat_msg_t usr_prompt = chat_msgs.back();
	chat_msgs.pop_back();

	// helper function to evaluate a prompt and generate a response
	auto generate = [&](const std::string& prompt) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "_prompt:generate %s\n", prompt.c_str());
#endif
		std::string response;

		const bool is_first = llama_kv_self_used_cells(prompt_args.context) == 0;

		// tokenize the prompt
		auto prompt_tokens = common_tokenize(prompt_args.context, prompt, is_first, true);

		// prepare a batch for the prompt
		llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
		llama_token new_token_id;
		auto _vocab = llama_model_get_vocab(prompt_args.model);
		while (true) {
			// check if we have enough space in the context to evaluate this batch
			int n_ctx = llama_n_ctx(prompt_args.context);
			int n_ctx_used = llama_kv_self_used_cells(prompt_args.context);
			if (n_ctx_used + batch.n_tokens > n_ctx) {
#if defined(_DEBUG) || defined(DEBUG) 
				fprintf(stderr, "context size exceeded\n");
#endif
				return GGML_EXIT_ABORTED;
			}

			if (llama_decode(prompt_args.context, batch)) {
#if defined(_DEBUG) || defined(DEBUG) 
				fprintf(stderr, "failed to decode\n");
#endif
				return GGML_EXIT_ABORTED;
			}

			// sample the next token
			new_token_id = common_sampler_sample(prompt_args.sampler, prompt_args.context, -1, false);

			// is it an end of generation?
			if (llama_vocab_is_eog(_vocab, new_token_id)) {
				break;
			}

			// convert the token to a string, print it and add it to the response
			char buf[256];
			int n = llama_token_to_piece(_vocab, new_token_id, buf, sizeof(buf), 0, true);
			if (n < 0) {
				// GGML_ABORT("failed to convert token to piece\n");
#if defined(_DEBUG) || defined(DEBUG) 
				fprintf(stderr, "failed to convert token to piece\n");
#endif
				return GGML_EXIT_ABORTED;
			}
			std::string piece(buf, n);
			if (TokenStreamCallback != nullptr && piece.length() > 0) {
				on_new_token(piece.c_str());
			}

			response += piece;

			// prepare the next batch with the sampled token
			batch = llama_batch_get_one(&new_token_id, 1);
		}

		if (ChatMessageCallback != nullptr && !response.empty()) {
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "_prompt:ChatMessageCallback %s\n", response.c_str());
#endif
			auto chat_msg = _to_lcpp_common_chat_msg(response, (chat_syntax_t)_chat_format);
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "_prompt:ChatMessageCallback <- _to_lcpp_common_chat_msg\n");
#endif
			ChatMessageCallback(chat_msg);
		}
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "_prompt:GGML_EXIT_SUCCESS\n");
#endif
		return GGML_EXIT_SUCCESS;
		};


	auto chat_add_and_format = [&chat_msgs, &prompt_args](common_chat_msg_t prompt) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "_prompt:chat_add_and_format\n");
#endif
		auto formatted = common_chat_format_single(prompt_args.chat_templates, chat_msgs, prompt, prompt.role == "user", _use_jinja.load());
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "_prompt:chat_add_and_format: %s\n", formatted.c_str());
#endif
		chat_msgs.push_back(prompt);
		return formatted;
		};

	if (chat_msgs.empty()) {
		// format the system prompt in conversation mode (will use template default if empty)
		if (!_system_prompt.empty()) {
			common_chat_msg systemmsg;
			systemmsg.role = "system";
			systemmsg.content = _system_prompt;
			chat_add_and_format(systemmsg);
		}
	}

	std::string prompt = chat_add_and_format(usr_prompt);

	int res = generate(prompt);
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_prompt::>\n");
#endif
	return res;
}

int lcpp_prompt(lcpp_common_chat_msg_t** messages, int n_messages) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_prompt \n");
#endif
	lcpp_prompt_args_t args;
	for (int i = 0; i < n_messages; i++) {
		auto msg = messages[i];
		if (msg != nullptr) {
			auto message = lcpp_common_chat_msg_to_common_chat_msg(msg);
			args.messages.push_back(message);
		}
	}
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_prompt msg.count %i \n", n_messages);
#endif
	args.model = _model.get();
	args.context = _ctx.get();
	args.sampler = _sampler.get();
	args.chat_templates = _chat_templates.get();
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_prompt new thread\n");
#endif
	std::thread thr(_prompt, args);
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_prompt started thr\n");
#endif
	thr.detach();
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_prompt detached thr EXIT_SUCCESS\n");
#endif
	return EXIT_SUCCESS;
}

static std::vector<common_sampler_type> _lcpp_params_sampler_types(const lcpp_params_t& lcpp_params) {
	int n_samplers = lcpp_params.n_samplers;
	std::vector<common_sampler_type> samplerTypes;

	for (int i = 0; i < n_samplers; i++) {
		lcpp_common_sampler_type _type = (lcpp_common_sampler_type)lcpp_params.samplers[i];
		switch (_type) {
		case LCPP_COMMON_SAMPLER_TYPE_NONE:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_NONE);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_DRY:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_DRY);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_TOP_K:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_TOP_K);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_TOP_P:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_TOP_P);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_MIN_P:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_MIN_P);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_TYPICAL_P:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_TYPICAL_P);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_TEMPERATURE:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_TEMPERATURE);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_XTC:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_XTC);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_INFILL:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_INFILL);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_PENALTIES:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_PENALTIES);
			break;
		case LCPP_COMMON_SAMPLER_TYPE_TOP_N_SIGMA:
			samplerTypes.push_back(COMMON_SAMPLER_TYPE_TOP_N_SIGMA);
			break;
		}
	}
	return samplerTypes;
}

static common_params_sampling_t _lcpp_params_sampling(const lcpp_params_t& lcpp_params) {
	common_params_sampling_t _sampling;

	_sampling.dry_allowed_length = lcpp_params.dry_allowed_length;
	_sampling.dry_base = lcpp_params.dry_base;
	_sampling.dry_multiplier = lcpp_params.dry_multiplier;
	_sampling.dry_penalty_last_n = lcpp_params.dry_penalty_last_n;
	_sampling.dry_allowed_length = lcpp_params.dry_allowed_length;

	_sampling.dynatemp_exponent = lcpp_params.dynatemp_exponent;
	_sampling.dynatemp_range = lcpp_params.dynatemp_range;
	if (lcpp_params.n_grammar_length > 0) {
		_sampling.grammar = std::string(lcpp_params.grammar);
	}
	_sampling.grammar_lazy = lcpp_params.grammar_lazy;
	_sampling.ignore_eos = lcpp_params.ignore_eos;
	_sampling.min_keep = lcpp_params.min_keep;
	_sampling.min_p = lcpp_params.min_p;
	_sampling.mirostat = lcpp_params.mirostat;
	_sampling.mirostat_eta = lcpp_params.mirostat_eta;
	_sampling.mirostat_tau = lcpp_params.mirostat_tau;
	_sampling.no_perf = lcpp_params.no_perf;
	_sampling.n_prev = lcpp_params.n_prev;
	_sampling.n_probs = lcpp_params.n_probs;
	_sampling.penalty_freq = lcpp_params.penalty_freq;
	_sampling.penalty_last_n = lcpp_params.penalty_last_n;
	_sampling.penalty_present = lcpp_params.penalty_present;
	_sampling.penalty_repeat = lcpp_params.penalty_repeat;

	_sampling.seed = lcpp_params.seed;
	_sampling.temp = lcpp_params.temp;
	_sampling.timing_per_token = lcpp_params.timing_per_token;
	_sampling.top_k = lcpp_params.top_k;
	_sampling.top_n_sigma = lcpp_params.top_n_sigma;
	_sampling.top_p = lcpp_params.top_p;
	_sampling.typ_p = lcpp_params.typ_p;
	_sampling.xtc_probability = lcpp_params.xtc_probability;
	_sampling.xtc_threshold = lcpp_params.xtc_threshold;
	return _sampling;
}

static common_params_t _lcpp_params_to_common_params(const llama_context_params_t& context_params, const lcpp_params_t& lcpp_params) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_lcpp_params_to_common_params \n");
#endif
	GGML_ASSERT(lcpp_params.model_path != nullptr);

	common_params_t _c;

	_c.numa = GGML_NUMA_STRATEGY_DISTRIBUTE;
	lcpp_model_family_t _family = lcpp_params.model_family;
	switch (_family) {
	case LCPP_MODEL_FAMILY_LLAMA:
	case LCPP_MODEL_FAMILY_GEMMA:
	case LCPP_MODEL_FAMILY_PHI:
	case LCPP_MODEL_FAMILY_MISTRAL:
		_c.reasoning_format = COMMON_REASONING_FORMAT_NONE;
		break;
	case LCPP_MODEL_FAMILY_DEEPSEEK:
	case LCPP_MODEL_FAMILY_GRANITE:
	case LCPP_MODEL_FAMILY_QWEN:
		_c.reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		break;
	default:
		_c.reasoning_format = COMMON_REASONING_FORMAT_NONE;
		break;
	}

	_c.webui = false;
	_c.enable_chat_template = true;
	_c.conversation_mode = COMMON_CONVERSATION_MODE_AUTO;
	_c.cache_type_k = GGML_TYPE_F16;
	_c.cache_type_v = GGML_TYPE_F16;
	_c.escape = lcpp_params.escape;
	_c.multiline_input = lcpp_params.multiline_input;
	_c.use_mlock = lcpp_params.use_mlock;
	_c.use_mmap = lcpp_params.use_mmap;
	_c.check_tensors = lcpp_params.check_tensors;
	_c.main_gpu = lcpp_params.main_gpu;
	lcpp_split_mode_t split_mode = lcpp_params.split_mode;
	switch (split_mode) {
	case LCPP_SPLIT_MODE_NONE:
		_c.split_mode = LLAMA_SPLIT_MODE_NONE;
		break;
	case LCPP_SPLIT_MODE_LAYER:
		_c.split_mode = LLAMA_SPLIT_MODE_LAYER;
		break;
	case LCPP_SPLIT_MODE_ROW:
		_c.split_mode = LLAMA_SPLIT_MODE_ROW;
		break;
	}

	_c.n_gpu_layers = lcpp_params.n_gpu_layers;

	_c.n_ctx = context_params.n_ctx;
	_c.no_perf = context_params.no_perf;
	_c.n_batch = context_params.n_batch;
	_c.n_ubatch = context_params.n_ubatch;
	_c.rope_freq_base = context_params.rope_freq_base;
	_c.rope_freq_scale = context_params.rope_freq_scale;
	_c.rope_scaling_type = context_params.rope_scaling_type;
	_c.yarn_attn_factor = context_params.yarn_attn_factor;
	_c.yarn_beta_fast = context_params.yarn_beta_fast;
	_c.yarn_beta_slow = context_params.yarn_beta_slow;
	_c.yarn_ext_factor = context_params.yarn_ext_factor;
	_c.yarn_orig_ctx = context_params.yarn_orig_ctx;
	_c.cb_eval = context_params.cb_eval;
	_c.cb_eval_user_data = context_params.cb_eval_user_data;
	_c.embedding = context_params.embeddings;
	_c.flash_attn = context_params.flash_attn;
	_c.display_prompt = false;
	_c.warmup = true;

	_c.kv_overrides = std::vector<llama_model_kv_override>();
	_c.tensor_buft_overrides = std::vector<llama_model_tensor_buft_override>();
	_c.antiprompt = std::vector<std::string>();
	_c.in_files = std::vector<std::string>();
	_c.api_keys = std::vector<std::string>();
	_c.context_files = std::vector<std::string>();

	// _c.no_kv_offload = !context_params->offload_kqv;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_lcpp_params_to_common_params::>\n");
#endif
	return _c;
}

typedef struct conf_params {
    llama_context_params_t ctxParams;
    common_params_t cmParams;
	common_params_model_t model;
	common_params_sampling_t sampling;
} conf_params_t;

int _conf(common_params_t cmParams) {

	auto ctxParams = common_context_params_to_llama(cmParams);

    ctxParams.abort_callback = _ggml_abort_callback;
    ctxParams.abort_callback_data = nullptr;
    auto mparams = common_model_params_to_llama(cmParams);
#if defined(_DEBUG) || defined(DEBUG)
    fprintf(stderr, "_conf  %s\n", cmParams.model.path.c_str());
#endif
    _model = llama_model_ptr(llama_model_load_from_file(cmParams.model.path.c_str(), mparams));
    _loaded = true;
#if defined(_DEBUG) || defined(DEBUG)
    fprintf(stdout, "lcpp_reconfigure finished _load_model \n");
#endif
    _ctx = llama_context_ptr(llama_init_from_model(_model.get(),ctxParams));

    postprocess_cpu_params(cmParams.cpuparams, nullptr);

    cmParams.numa = GGML_NUMA_STRATEGY_DISABLED;

    if (cpuinfo_initialize()) {
        int nprocs = cpuinfo_get_processors_count();
        cmParams.cpuparams_batch.n_threads = nprocs;
        int ncores = cpuinfo_get_cores_count();
        cmParams.cpuparams.n_threads = ncores;

        int clusters = cpuinfo_get_clusters_count();
        if (clusters > 1) {
            cmParams.numa = GGML_NUMA_STRATEGY_MIRROR;
        }
        else if (cmParams.cpuparams_batch.n_threads != cmParams.cpuparams.n_threads) {
            cmParams.numa = GGML_NUMA_STRATEGY_DISTRIBUTE;
            int nbatch_threads = (nprocs - (int)std::ceil((float)(nprocs + 0.0f) / ncores) * clusters) * 0.5f;
            cmParams.cpuparams_batch.n_threads = nbatch_threads > 1 ? nbatch_threads : 1;
            int n_threads = (ncores - clusters) * 0.5f;
            cmParams.cpuparams.n_threads = n_threads > 1 ? n_threads : 1;
        }
        else {
            cmParams.numa = GGML_NUMA_STRATEGY_ISOLATE;
        }

        auto* cpu_dev = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);
        if (cpu_dev) {
            auto* reg = ggml_backend_dev_backend_reg(cpu_dev);
#if defined(_DEBUG) || defined(DEBUG)
            fprintf(stderr, "lcpp_reconfigure ggml_backend_dev_backend_reg is null: %s\n", ggml_backend_dev_backend_reg == nullptr ? "true" : "false");
#endif
            auto* ggml_threadpool_new_fn = (decltype(ggml_threadpool_new)*)ggml_backend_reg_get_proc_address(reg, "ggml_threadpool_new");
#if defined(_DEBUG) || defined(DEBUG)
            fprintf(stderr, "lcpp_reconfigure ggml_threadpool_new_fn is null: %s\n", ggml_threadpool_new_fn == nullptr ? "true" : "false");
#endif
            auto* ggml_threadpool_free_fn = (decltype(ggml_threadpool_free)*)ggml_backend_reg_get_proc_address(reg, "ggml_threadpool_free");
#if defined(_DEBUG) || defined(DEBUG)
            fprintf(stderr, "lcpp_reconfigure ggml_threadpool_free_fn is null: %s\n", ggml_threadpool_free_fn == nullptr ? "true" : "false");
#endif
            auto tpp_batch =
                    ggml_threadpool_params_from_cpu_params(cmParams.cpuparams_batch);
            auto tpp =
                    ggml_threadpool_params_from_cpu_params(cmParams.cpuparams);

            ggml_threadpool_ptr threadpool_batch = nullptr;
            if (!ggml_threadpool_params_match(&tpp, &tpp_batch)) {
                threadpool_batch = ggml_threadpool_new_fn(&tpp_batch);
                if (threadpool_batch) {
                    // Start the non-batch threadpool in the paused state
                    tpp.paused = true;
                }
            }

            ggml_threadpool_ptr threadpool = ggml_threadpool_new_fn(&tpp);
            if (threadpool) {
#if defined(_DEBUG) || defined(DEBUG)
                fprintf(stderr, "lcpp_reconfigure threadpool is null: %s\n", threadpool == nullptr ? "true" : "false");
#endif
                llama_attach_threadpool(_ctx.get(), threadpool, threadpool_batch);
            }
			set_process_priority(cmParams.cpuparams.priority);
        }
    }

    if (ggml_is_numa()) {
        if (cmParams.numa != GGML_NUMA_STRATEGY_DISABLED) {
            llama_numa_init(cmParams.numa);
        }
        else {
            llama_numa_init(GGML_NUMA_STRATEGY_NUMACTL);
        }
    }
    else {
        llama_numa_init(GGML_NUMA_STRATEGY_DISABLED);
    }

#if defined(_DEBUG) || defined(DEBUG)
    fprintf(stderr, "lcpp_reconfigure common_chat_templates_init, model is null:  chat_template: %s,  is null: %s\n", _model.get() == nullptr ? "true" : "false", cmParams.chat_template.c_str());
#endif
    _chat_templates = common_chat_templates_init(_model.get(), cmParams.chat_template);

    auto sampler = common_sampler_init(_model.get(), cmParams.sampling);
    _sampler = common_sampler_ptr(sampler);

    if (LoadingProgressCallback != nullptr) {
        LcppFloatStruct_t* _float = (LcppFloatStruct_t*)malloc(sizeof(LcppFloatStruct_t));
        _float->value = 1.0f;
        LoadingProgressCallback(_float);
    }
	return EXIT_SUCCESS;
}

void lcpp_reconfigure(const llama_context_params_t context_params, const lcpp_params_t lcpp_params) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reconfigure \n");
#endif
	_loaded = false;
	// only print errors
	llama_log_set([](enum ggml_log_level level, const char* text, void* /* user_data */) {
		if (level >= GGML_LOG_LEVEL_DEBUG) {
			fprintf(stderr, "%s", text);
		}
		}, nullptr);

	llama_backend_init();
	common_params_model_t modelParams;
	modelParams.path = std::string(lcpp_params.model_path);

	auto params = _lcpp_params_to_common_params(context_params, lcpp_params);
	params.model = modelParams;
	params.sampling = _lcpp_params_sampling(lcpp_params);

#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reconfigure start _conf \n");
#endif
	std::thread thr(_conf, params);
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reconfigure join _load_model \n");
#endif
	thr.detach();
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stdout, "lcpp_reconfigure finished _load_model \n");
#endif

	if (!params.system_prompt.empty()) {
		_system_prompt = std::string(params.system_prompt.c_str());
	}

	_set_use_jinja_by_model_family(lcpp_params.model_family);

	_set_common_format_by_model_family(lcpp_params.model_family, lcpp_params.is_reasoning);

}

int32_t lcpp_tokenize(const char* text, int n_text, bool add_special,
	bool parse_special, llama_token** tokens) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_tokenize: %s\n", text);
#endif
	std::string _text(text);
	auto llama_tokens = common_tokenize(_ctx.get(), _text, add_special, parse_special);

	if (!llama_tokens.empty()) {
		int n = llama_tokens.size();
		*tokens = (llama_token*)std::calloc(n, sizeof(llama_token));
		std::memcpy(*tokens, llama_tokens.data(), sizeof(llama_token) * n);
		return n;
	}
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_tokenize::>\n");
#endif
	return 0;
}

void lcpp_detokenize(int* tokens, int n_tokens, bool special,
	lcpp_data_pvalue_t* text) {
	std::vector<llama_token> llama_tokens(n_tokens);
	memcpy(llama_tokens.data(), tokens, sizeof(int) * n_tokens);

	auto _text = common_detokenize(_ctx.get(), llama_tokens, special);
	int n_text = _text.size();
	text->value = (char*)std::calloc(n_text + 1, sizeof(char));
	memcpy(text->value, _text.c_str(), n_text);
	text->value[n_text] = '\0';
	text->length = n_text;
	text->found = n_text > 0;
}

void lcpp_destroy() {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_destroy()\n");
#endif
	lcpp_reset();
	lcpp_unset_token_stream_callback();
	lcpp_unset_chat_message_callback();
	lcpp_unset_model_load_progress_callback();
	_chat_templates = nullptr;
	_ctx = nullptr;
	_sampler = nullptr;
	_model = nullptr;

	llama_backend_free();
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_destroy::>\n");
#endif

}

void lcpp_reset() {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reset()\n");
#endif
	if (_ctx != nullptr) {
		llama_kv_self_clear(_ctx.get());
	}
    _abort = false;
    _cancel = false;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reset::>\n");
#endif
}

void lcpp_free_float(LcppFloatStruct_t* ptr) {
	free(ptr);
}

void lcpp_free_text(LcppTextStruct_t* ptr) {
	if (ptr != nullptr && ptr->text != nullptr) {
		free(ptr->text);
	}
	free(ptr);
}

void lcpp_native_free(void* ptr) {
	free(ptr);
}
