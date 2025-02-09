#include <stdlib.h>
#include <float.h>
#include <algorithm>
#include <string.h>
#include <queue>
#include <string>
#include <cmath>
#include <numeric>
#include <cstring>
#include <thread>
#include <atomic>
#include <limits>
#include <vector>
#include <cpuinfo.h>

#include "llamacpp_platform.h"

#include "llamacpp_llm.h"

#include "chat-parser.h"

#include "chat.h"

#include "common.h"

#include "llama.h"

#include "sampling.h"

#include "llama-context.h"


typedef struct common_params common_params_t;

typedef struct common_chat_params common_chat_params_t;

// typedef struct ggml_threadpool ggml_threadpool_t;
typedef struct ggml_threadpool_params ggml_threadpool_params_t;

typedef struct common_params_sampling common_params_sampling_t;

typedef struct common_chat_templates common_chat_templates_t;
typedef struct common_sampler common_sampler_t;
typedef struct common_chat_syntax common_chat_syntax_t;
typedef struct common_chat_tool common_chat_tool_t;
typedef struct common_chat_templates_inputs common_chat_templates_inputs_t;

typedef struct common_init_result common_init_result_t;

typedef struct common_chat_msg common_chat_msg_t;
typedef struct common_chat_tool_call common_chat_tool_call_t;
typedef struct common_chat_msg_content_part common_chat_msg_content_part_t;


typedef struct common_chat_syntax_deleter {
	void operator()(common_chat_syntax_t* gsmpl) {
		free(gsmpl);
	}
} common_chat_syntax_deleter_t;

typedef std::unique_ptr<common_chat_syntax_t, common_chat_syntax_deleter_t> common_chat_syntax_ptr;

static std::unique_ptr<std::atomic<bool>> bLLAMACPP_abort = std::make_unique<std::atomic<bool>>(false);

static std::unique_ptr<std::atomic<bool>> bLLAMACPP_cancel = std::make_unique<std::atomic<bool>>(false);

static std::atomic<std::uint8_t> iLLAMACPP_continue{ lcpp_finish_reason::LCPP_FINISH_REASON_STOP };

static std::atomic<bool> bLLAMACPP_loaded{ false };

static std::atomic<bool> bLLAMACPP_inited{ false };

static LppTokenStreamCallback TokenStreamCallback = nullptr;

static LppProgressCallback LoadingProgressCallback = nullptr;

static LcppOnCancelCallback OnCancelCallback = nullptr;

static LcppOnAbortCallback OnAbortCallback = nullptr;

static LppChatMessageCallback ChatMessageCallback = nullptr;

static common_chat_templates_ptr _chat_templates;

// static common_chat_syntax_ptr _chat_syntax;


typedef struct common_init_result_deleter {
	void operator()(common_init_result_t* cmResult) {
		if (cmResult != nullptr) {
			if ((*cmResult).context != nullptr) { (*cmResult).context.reset(); }
			if ((*cmResult).model != nullptr) { (*cmResult).model.reset(); }
			for(llama_adapter_lora_ptr& lora_ptr : (*cmResult).lora) {
				if (lora_ptr != nullptr) {
					lora_ptr.reset();
				}
			}
			(*cmResult).lora.clear();
			free(cmResult);
		}
	}
} common_init_result_deleter_t;

typedef std::unique_ptr < common_init_result_t, common_init_result_deleter_t> common_init_result_ptr;

static common_init_result_ptr _common;

typedef struct common_sampler_deleter {
	void operator()(common_sampler_t* gsmpl) {
		if (gsmpl != nullptr) {
			// reset internal pointers to avoid double free
			common_sampler_free(gsmpl);
		}
		
	}
} common_sampler_deleter_t;

typedef std::unique_ptr<common_sampler_t, common_sampler_deleter_t> common_sampler_ptr;

void lcpp_free_common_chat_msg(lcpp_common_chat_msg_t* msg) {
	if (msg != nullptr) {
		if (msg->n_content > 0) free(msg->content);
		if (msg->n_role > 0) free(msg->role);

		if (msg->n_content_parts > 0) {
			for (int i = 0, n = msg->n_content_parts; i < n; i++) {
				if (msg->content_parts[i] != nullptr) {
					lcpp_common_chat_msg_content_part_t* part = msg->content_parts[i];
					if (part->n_text > 0) free(part->text);
					if (part->n_type > 0) free(part->type);
					free(part);
				}
			}
			free(msg->content_parts);
		}

		if (msg->n_tool_calls > 0) {
			for (int j = 0, n = msg->n_tool_calls; j < n; j++) {
				if (msg->tool_calls[j] != nullptr) {
					lcpp_common_chat_tool_call_t* tool_call = msg->tool_calls[j];
					if (tool_call->n_arguments > 0) free(tool_call->arguments);
					if (tool_call->n_name > 0) free(tool_call->name);
					if (tool_call->n_id > 0) free(tool_call->id);
					free(tool_call);
				}
			}
			free(msg->tool_calls);
		}

		if (msg->n_reasoning_content > 0) free(msg->reasoning_content);
		if (msg->n_tool_name > 0) free(msg->tool_name);
		if (msg->n_tool_call_id > 0) free(msg->tool_call_id);
		free(msg);
	}
}

typedef struct lcpp_common_chat_msg_deleter {
	void operator()(lcpp_common_chat_msg_t* msg) {
		lcpp_free_common_chat_msg(msg);
	}
} lcpp_common_chat_msg_deleter_t;

typedef std::unique_ptr<lcpp_common_chat_msg_t, lcpp_common_chat_msg_deleter_t> lcpp_common_chat_msg_ptr;

typedef struct lcpp_prompt_args {
	common_chat_syntax_t syntax;
	common_chat_params_t params;
	common_init_result_t* common = nullptr;
	common_sampler_t* sampler = nullptr;
} lcpp_prompt_args_t;

common_chat_tool_t lcpp_common_chat_tool_to_common_chat_tool(lcpp_common_chat_tool_t* tool) {
	GGML_ASSERT(tool != nullptr);
	common_chat_tool_t function;
	if (tool->name != nullptr) {
		if (tool->n_name > 0) function.name = tool->name;
	}
	if (tool->description != nullptr) {
		if (tool->n_description > 0) function.description= tool->description;
	}
	if (tool->paramaeters_schema != nullptr) {
		if (tool->n_paramaeters_schema > 0) function.parameters = tool->paramaeters_schema;
	}
	return function;
}

common_chat_msg_t lcpp_common_chat_msg_to_common_chat_msg(lcpp_common_chat_msg_t* msg) {
	GGML_ASSERT(msg != nullptr);
	common_chat_msg_t message;
	if (msg->role != nullptr) {
		if (msg->n_role > 0) message.role = msg->role;
	}
	if (msg->content != nullptr) {
		if (msg->n_content > 0) message.content = msg->content;
	}
	if (msg->tool_name != nullptr) {
		if (msg->n_tool_name > 0) message.tool_name = msg->tool_name;
	}
	if (msg->tool_call_id != nullptr) {
		if (msg->n_tool_call_id > 0) message.tool_call_id = msg->tool_call_id;
	}
	if (msg->reasoning_content != nullptr) {
		if (msg->n_reasoning_content > 0) message.reasoning_content = msg->reasoning_content;
	}
	if (msg->n_tool_calls > 0) {
		for (int j = 0, n = msg->n_tool_calls; j < n; j++) {
			lcpp_common_chat_tool_call_t* result = msg->tool_calls[j];
			if (result != nullptr) {
				common_chat_tool_call_t toolcall;
				if (result->arguments != nullptr) {
					if (result->n_arguments > 0) toolcall.arguments = result->arguments;
				}
				if (result->id != nullptr) {
					if (result->n_id > 0) toolcall.id = result->id;
				}
				if (result->name != nullptr) {
					if (result->n_name > 0) toolcall.name = result->name;
				}
				message.tool_calls.push_back(toolcall);
			}
		}
	}
	if (msg->n_content_parts > 0) {
		for (int i = 0, n  = msg->n_content_parts; i < n; i++) {
			lcpp_common_chat_msg_content_part_t* result = msg->content_parts[i];
			if (result == nullptr) {
				common_chat_msg_content_part_t content;
				if (result->text != nullptr) {
					if (result->n_text > 0) content.text = result->text;
				}
				if (result->type != nullptr) {
					if (result->n_type > 0) content.type = result->type;
				}
				message.content_parts.push_back(content);
			}
		}
	}
	return message;
}


lcpp_sampling_params_t lcpp_sampling_params_defaults() {
	std::vector<lcpp_common_sampler_type_t> samplers = {
			LCPP_COMMON_SAMPLER_TYPE_PENALTIES,
			LCPP_COMMON_SAMPLER_TYPE_DRY,
			LCPP_COMMON_SAMPLER_TYPE_TOP_N_SIGMA,
			LCPP_COMMON_SAMPLER_TYPE_TOP_K,
			LCPP_COMMON_SAMPLER_TYPE_TYPICAL_P,
			LCPP_COMMON_SAMPLER_TYPE_TOP_P,
			LCPP_COMMON_SAMPLER_TYPE_MIN_P,
			LCPP_COMMON_SAMPLER_TYPE_XTC,
			LCPP_COMMON_SAMPLER_TYPE_TEMPERATURE
	};

	lcpp_sampling_params_t result = {
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
		/* samplers[9] */
		samplers.size(),
		/* grammar = nullptr */
		0,
		/* 0 = disabled, 1 = mirostat, 2 = mirostat 2.0 int32_t mirostat =*/
		LCPP_MIROSTAT_NONE,
		/* bool ignore_eos = */
		false,
		/* disable performance metrics bool no_perf = */
		true,
		/* bool timing_per_token = */
		false,
		/* bool grammar_lazy =*/
		false,
		/* common_sampler_type samplers[8] =*/
		samplers.data(),
		/* optional BNF-like grammar to constrain sampling char* grammar =*/
		nullptr };
	return result;
}

lcpp_params_t lcpp_params_defaults() {

	lcpp_params_t result = {
		/* number of layers to store in VRAM, int32_t n_gpu_layers= */
		-1,
		/* the GPU that is used for the entire model when split_mode is LLAMA_SPLIT_MODE_NONE, int32_t main_gpu = */
		0,

		/* model_path = nullptr */
		0,

		/* model family based on file name e.g. deepseek qwen*/
		LCPP_MODEL_FAMILY_UNSPECIFIED,
		/* how to split the model across multiple GPUs */
		LCPP_SPLIT_MODE_NONE,
		/* how to split the model across multiple CPUs */
		LCPP_NUMA_STRATEGY_DISABLED,

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
		 // mixture of experts offload to cpu
		 false,
		 /* required path to GGUF model file */
		 nullptr
	};

	return result;
}

void lcpp_send_abort_signal(bool abort) {
	(*bLLAMACPP_abort).store(abort);
}

void lcpp_send_cancel_signal(bool cancel) {
	(*bLLAMACPP_cancel).store(cancel);
}

bool _ggml_progress_callback(float progress, void* user_data) {
	std::unique_ptr<std::atomic<bool>>* _val = (std::unique_ptr<std::atomic<bool>>*) user_data;
	if (LoadingProgressCallback != nullptr) {
		LoadingProgressCallback(static_cast<double>(progress));
	}
	std::atomic<bool>* _bval = (*_val).get();
	if ((*_bval).load()) {
		(*_bval).store(false); // reset
		if (OnCancelCallback != nullptr) {
			OnCancelCallback(lcpp_finish_reason::LCPP_FINISH_REASON_CANCELLED);
		}
		return false;
	}
	return true;
}

bool _ggml_abort_callback(void* data) {
	std::unique_ptr<std::atomic<bool>>* _val = (std::unique_ptr<std::atomic<bool>>*) data;
	std::atomic<bool>* _bval = (*_val).get();
	if ((*_bval).load()) {
		iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_ABORTED);
		if (OnAbortCallback != nullptr) {
			OnAbortCallback(lcpp_finish_reason::LCPP_FINISH_REASON_ABORTED);
		}
		(*_bval).store(false); // reset
		return true;
	}
	return false;
}

void _ggml_abort_callback_t(const char* error_message) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "%s", error_message);
#endif
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


void lcpp_set_on_cancel_callback(LcppOnCancelCallback on_cancel_callback) {
	OnCancelCallback = on_cancel_callback;
}

void lcpp_unset_on_cancel_callback() {
	OnCancelCallback = nullptr;
}

void lcpp_set_on_abort_callback(LcppOnAbortCallback on_abort_callback) {
	OnAbortCallback = on_abort_callback;
}

void lcpp_unset_on_abort_callback() {
	OnAbortCallback = nullptr;
}

/*
static common_chat_syntax_ptr chat_syntax_for_model_family(lcpp_model_family_t model_family, bool is_reasoning) {
	common_chat_syntax_ptr _syntax(new common_chat_syntax());

	switch (model_family) {
	case LCPP_MODEL_FAMILY_DEEPSEEK:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_DEEPSEEK_V3_1;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_QWEN:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_DEEPSEEK_V3_1;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_GRANITE:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_GRANITE;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_LLAMA:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_LLAMA_3_X_WITH_BUILTIN_TOOLS;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_AUTO;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_MISTRAL:
	{
		(*_syntax).format = is_reasoning ? COMMON_CHAT_FORMAT_MAGISTRAL : COMMON_CHAT_FORMAT_MISTRAL_NEMO;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_AUTO;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_PHI:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_GENERIC;
		(*_syntax).reasoning_format = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_GEMMA:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_GENERIC;
		(*_syntax).reasoning_format = is_reasoning ? COMMON_REASONING_FORMAT_AUTO : COMMON_REASONING_FORMAT_NONE;
		(*_syntax).parse_tool_calls = false;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_GPT_OSS:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_GPT_OSS;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_AUTO;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_SEED_OSS:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_SEED_OSS;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_APERTUS:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_APERTUS;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_NEMOTRON:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_NEMOTRON_V2;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_LIQUID:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_LFM2_WITH_JSON_TOOLS;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_NONE;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_GLM:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_GLM_4_5;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_MINIMAX:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_MINIMAX_M2;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_COHERE:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_COMMAND_R7B;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	case LCPP_MODEL_FAMILY_GENERIC:
	{
		(*_syntax).format = is_reasoning ? COMMON_CHAT_FORMAT_GENERIC : COMMON_CHAT_FORMAT_CONTENT_ONLY;
		(*_syntax).reasoning_format = is_reasoning ? COMMON_REASONING_FORMAT_AUTO : COMMON_REASONING_FORMAT_NONE;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	default:
	{
		(*_syntax).format = COMMON_CHAT_FORMAT_CONTENT_ONLY;
		(*_syntax).reasoning_format = COMMON_REASONING_FORMAT_AUTO;
		(*_syntax).parse_tool_calls = true;
		(*_syntax).reasoning_in_content = false;
		(*_syntax).thinking_forced_open = false;
	}
	break;
	}
	return _syntax;
} */

lcpp_common_chat_msg_t* _to_lcpp_common_chat_msg(std::string& response, bool is_partial, common_chat_syntax_t syntax) {

	common_chat_msg_t msg = common_chat_parse(response, is_partial, syntax);

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
		std::vector<lcpp_common_chat_msg_content_part_t*> parts;
		for (auto it = msg.content_parts.cbegin(); it != msg.content_parts.cend(); it++) {
			common_chat_msg_content_part_t contents = *it;
			lcpp_common_chat_msg_content_part_t* part = (lcpp_common_chat_msg_content_part_t*)std::malloc(sizeof(lcpp_common_chat_msg_content_part_t));
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
				std::memcpy(part->type, contents.text.c_str(), part->n_type);
				part->type[part->n_type] = '\0';
			}
			else {
				part->type = nullptr;
			}
			parts.push_back(part);
		}
		int sz = parts.size();
		_msg->content_parts = (lcpp_common_chat_msg_content_part_t**)std::calloc(sz, sizeof(lcpp_common_chat_msg_content_part_t*));
		std::memcpy( _msg->content_parts, parts.data(), sizeof(lcpp_common_chat_msg_content_part_t*) * sz);
		_msg->n_content_parts = sz;
	}
	else {
		_msg->content_parts = nullptr;
		_msg->n_content_parts = 0;
	}

	if (!msg.tool_calls.empty()) {
		std::vector<lcpp_common_chat_tool_call_t*> toolcalls;
		for (auto it = msg.tool_calls.cbegin(); it != msg.tool_calls.cend(); it++) {
			common_chat_tool_call tool_call = *it;
			lcpp_common_chat_tool_call_t* toolcall = (lcpp_common_chat_tool_call_t*)std::malloc(sizeof(lcpp_common_chat_tool_call_t));
			toolcall->n_name = tool_call.name.size();
			if (toolcall->n_name > 0) {
				toolcall->name = (char*)std::calloc(toolcall->n_name + 1, sizeof(char));
				std::memcpy(toolcall->name, tool_call.name.c_str(), toolcall->n_name);
				toolcall->name[toolcall->n_name] = '\0';
			}
			else {
				toolcall->name = nullptr;
			}

			toolcall->n_id = tool_call.id.size();
			if (toolcall->n_id > 0) {
				toolcall->id = (char*)std::calloc(toolcall->n_id + 1, sizeof(char));
				std::memcpy(toolcall->id, tool_call.id.c_str(), toolcall->n_id);
				toolcall->id[toolcall->n_id] = '\0';
			}
			else {
				toolcall->id = nullptr;
			}

			toolcall->n_arguments = tool_call.arguments.size();
			if (toolcall->n_arguments > 0) {
				toolcall->arguments = (char*)std::calloc(toolcall->n_arguments + 1, sizeof(char));
				std::memcpy(toolcall->arguments, tool_call.arguments.c_str(), toolcall->n_arguments);
				toolcall->arguments[toolcall->n_arguments] = '\0';
			}
			else {
				toolcall->arguments = nullptr;
			}

			toolcalls.push_back(toolcall);
		}

		int sz = toolcalls.size();
		_msg->tool_calls = (lcpp_common_chat_tool_call_t**)std::calloc(sz, sizeof(lcpp_common_chat_tool_call_t*));
		std::memcpy(_msg->tool_calls, toolcalls.data(), sizeof(lcpp_common_chat_tool_call_t*) * sz);

		_msg->n_tool_calls = sz;
	}
	else {
		_msg->tool_calls = nullptr;
		_msg->n_tool_calls = 0;
	}
	return _msg;
}

int _prompt(lcpp_prompt_args_t prompt_args) {
	auto _sampler = common_sampler_ptr(prompt_args.sampler);
	
	// helper function to evaluate a prompt and generate a response
	auto generate = [&](const std::string& prompt) {
		iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_STOP);
		std::string response;

		auto _vocab = llama_model_get_vocab(prompt_args.common->model.get());

		auto _ctx = prompt_args.common->context.get();

		bool is_first = llama_memory_seq_pos_max(llama_get_memory(_ctx), 0) == -1;

		// tokenize the prompt
		int n_prompt_tokens = -llama_tokenize(_vocab, prompt.c_str(), prompt.size(), NULL, 0, is_first, true);

		std::vector<llama_token> prompt_tokens(n_prompt_tokens);

		if (llama_tokenize(_vocab, prompt.c_str(), prompt.size(), prompt_tokens.data(), prompt_tokens.size(), is_first, true) < 0) {
#if defined(_DEBUG) || defined(DEBUG)
			GGML_ABORT("%s %s - %i : failed to tokenize the prompt\n", __FILE__, __func__, __LINE__);
#endif
			iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_ERROR_TOKENIZE);
		}

		// prepare a batch for the prompt
		llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
		llama_token new_token_id;
		while (true) {
			// check if we have enough space in the context to evaluate this batch
			int n_ctx = llama_n_ctx(_ctx);
			int n_ctx_used = llama_memory_seq_pos_max(llama_get_memory(_ctx), 0) + 1;
			if (n_ctx_used + batch.n_tokens > n_ctx) {
#if defined(_DEBUG) || defined(DEBUG)
				GGML_ABORT("%s  %s - %i : context size exceeded, needed %i, available  %i\n", __FILE__, __func__, __LINE__, (n_ctx_used + batch.n_tokens), n_ctx);
#endif
				iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_LENGTH);
			}
			try {
				int ret = llama_decode(_ctx, batch);
				if (ret != 0) {
#if defined(_DEBUG) || defined(DEBUG)
					GGML_ABORT("%s  %s - %i : failed to decode, ret = %d\n", __FILE__, __func__, __LINE__, ret);
#endif
					switch (ret) {
						case 0:iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_STOP);
							break;
						case 1:iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_NO_KV_SLOT_AVAILABLE);
							break;
						case 2:iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_ABORTED);
							break;
						case -1:iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_INVALID_BATCH_INPUT);
							break;
						default:iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_FATAL_ERROR);
							break;
					}
				}
			}
			catch (...) {
				iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_UNHANDLED_EXCEPTION);
				break;
			}

			// sample the next token
			new_token_id = common_sampler_sample(_sampler.get(), _ctx, -1, false);

			// is it an end of generation?
			if (llama_vocab_is_eog(_vocab, new_token_id)) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "%s %s - %i :<if> llama_vocab_is_eog [BREAK]\n", __FILE__, __func__, __LINE__);
#endif
				break;
			}

			// convert the token to a string, print it and add it to the response
			char buf[256];
			int n = llama_token_to_piece(_vocab, new_token_id, buf, sizeof(buf), 0, true);
			if (n < 0) {
#if defined(_DEBUG) || defined(DEBUG)
				GGML_ABORT("failed to convert token [%i] to piece\n", new_token_id);
#endif

				iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_ERROR_DETOKENIZE);
			}
			std::string piece(buf, n);
			if (TokenStreamCallback != nullptr && piece.length() > 0) {
				LcppTextStruct_t* response = (LcppTextStruct_t*)malloc(sizeof(LcppTextStruct_t));
				size_t len = piece.length();
				response->length = len;
				response->text = (char*)std::calloc(len + 1, sizeof(char));
				std::memcpy(response->text, piece.c_str(), len);
				response->text[len] = '\0';
				TokenStreamCallback(response);
			}

			response += piece;

			batch = llama_batch_get_one(&new_token_id, 1);
		}

		if (ChatMessageCallback != nullptr && !response.empty()) {
			auto chat_msg = _to_lcpp_common_chat_msg(response, iLLAMACPP_continue.load()!=lcpp_finish_reason::LCPP_FINISH_REASON_STOP, prompt_args.syntax);
			ChatMessageCallback(chat_msg);
		}

		if (OnAbortCallback != nullptr) {

			OnAbortCallback(iLLAMACPP_continue.load());
		}

		return GGML_EXIT_SUCCESS;
		};

	int res = generate(prompt_args.params.prompt);
	_sampler.reset(nullptr);
	return res;
}

static common_params_sampling_t _lcpp_params_sampling(const lcpp_sampling_params_t& lcpp_params) {
	common_params_sampling_t _sampling;

	_sampling.dry_allowed_length = lcpp_params.dry_allowed_length;
	_sampling.dry_base = lcpp_params.dry_base;
	_sampling.dry_multiplier = lcpp_params.dry_multiplier;
	_sampling.dry_penalty_last_n = lcpp_params.dry_penalty_last_n;
	_sampling.dry_allowed_length = lcpp_params.dry_allowed_length;

	_sampling.dynatemp_exponent = lcpp_params.dynatemp_exponent;
	_sampling.dynatemp_range = lcpp_params.dynatemp_range;
	if (lcpp_params.n_grammar_length > 0) {
		_sampling.grammar = lcpp_params.grammar;
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

	std::vector<enum common_sampler_type> samplers;
	for(int i=0,n = lcpp_params.n_samplers; i < n; i++) {
		lcpp_common_sampler_type_t _val = lcpp_params.samplers[i];
		switch (_val) {
			case LCPP_COMMON_SAMPLER_TYPE_TEMPERATURE:
				samplers.push_back(COMMON_SAMPLER_TYPE_TEMPERATURE);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_TOP_P:
				samplers.push_back(COMMON_SAMPLER_TYPE_TOP_P);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_TOP_K:
				samplers.push_back(COMMON_SAMPLER_TYPE_TOP_K);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_TYPICAL_P:
				samplers.push_back(COMMON_SAMPLER_TYPE_TYPICAL_P);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_MIN_P:
				samplers.push_back(COMMON_SAMPLER_TYPE_MIN_P);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_TOP_N_SIGMA:
				samplers.push_back(COMMON_SAMPLER_TYPE_TOP_N_SIGMA);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_INFILL:
				samplers.push_back(COMMON_SAMPLER_TYPE_INFILL);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_DRY:
				samplers.push_back(COMMON_SAMPLER_TYPE_DRY);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_PENALTIES:
				samplers.push_back(COMMON_SAMPLER_TYPE_PENALTIES);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_XTC:
				samplers.push_back(COMMON_SAMPLER_TYPE_XTC);
				break;
			case LCPP_COMMON_SAMPLER_TYPE_NONE:
				samplers.push_back(COMMON_SAMPLER_TYPE_NONE);
				break;
		}		
	}
	if (samplers.size() > 0) {
		_sampling.samplers = samplers;
	}

	return _sampling;
}

int lcpp_prompt(const lcpp_sampling_params_t sampling_params, lcpp_common_chat_msg_t** messages, int n_messages, lcpp_common_chat_tool_t** tools, int n_tools) {

	lcpp_prompt_args_t args;
	common_chat_templates_inputs_t inputs;
	for (int i = 0; i < n_messages; i++) {
		lcpp_common_chat_msg_t* msg = messages[i];
		if (msg != nullptr) {
			auto message = lcpp_common_chat_msg_to_common_chat_msg(msg);
			inputs.messages.push_back(message);
		}
	}
	int count = inputs.messages.size();
	inputs.add_generation_prompt = inputs.messages[count - 1].role.compare("user") == 0 || inputs.messages[count - 1].role.compare("tool") == 0;
	inputs.use_jinja = true;
	inputs.enable_thinking = true;
	for (int i = 0; i < n_tools; i++) {
		lcpp_common_chat_tool_t* tool = tools[i];
		if (tool != nullptr) {
			auto function = lcpp_common_chat_tool_to_common_chat_tool(tool);
			inputs.tools.push_back(function);
		}
	}
	args.params = common_chat_templates_apply(_chat_templates.get(),inputs);
	args.syntax.format = args.params.format;
	args.syntax.parse_tool_calls = !inputs.tools.empty();
	args.syntax.reasoning_in_content = false;
	args.syntax.thinking_forced_open = args.params.thinking_forced_open;

	switch (args.params.format) {
		case COMMON_CHAT_FORMAT_DEEPSEEK_R1:
		case COMMON_CHAT_FORMAT_DEEPSEEK_V3_1:
		case COMMON_CHAT_FORMAT_GRANITE:
		case COMMON_CHAT_FORMAT_SEED_OSS:
		case COMMON_CHAT_FORMAT_GLM_4_5:
		case COMMON_CHAT_FORMAT_MINIMAX_M2:
		case COMMON_CHAT_FORMAT_COMMAND_R7B:
		case COMMON_CHAT_FORMAT_APERTUS:
		case COMMON_CHAT_FORMAT_NEMOTRON_V2:
		case COMMON_CHAT_FORMAT_KIMI_K2:
		case COMMON_CHAT_FORMAT_HERMES_2_PRO:
			args.syntax.reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
			break;
		case COMMON_CHAT_FORMAT_GPT_OSS:
		case COMMON_CHAT_FORMAT_MISTRAL_NEMO:
		case COMMON_CHAT_FORMAT_MAGISTRAL:
			args.syntax.reasoning_format = COMMON_REASONING_FORMAT_AUTO;
			break;
		case COMMON_CHAT_FORMAT_LLAMA_3_X:
		case COMMON_CHAT_FORMAT_LLAMA_3_X_WITH_BUILTIN_TOOLS:
		case COMMON_CHAT_FORMAT_LFM2_WITH_JSON_TOOLS:
		case COMMON_CHAT_FORMAT_FUNCTIONARY_V3_1_LLAMA_3_1:
		case COMMON_CHAT_FORMAT_FUNCTIONARY_V3_2:
		case COMMON_CHAT_FORMAT_FIREFUNCTION_V2:
		case COMMON_CHAT_FORMAT_CONTENT_ONLY:
			args.syntax.reasoning_format = COMMON_REASONING_FORMAT_NONE;
			break;
		default:
			args.syntax.reasoning_format = COMMON_REASONING_FORMAT_AUTO;
			break;
	}

	lcpp_reset();
	
	args.common = _common.get();
	args.sampler = common_sampler_init((*_common).model.get(), _lcpp_params_sampling(sampling_params));
	std::thread thr(_prompt, args);

	thr.detach();

	return EXIT_SUCCESS;
}

int _conf(common_params_t cmParams) {

	std::unique_ptr<common_init_result_t, std::default_delete< common_init_result_t>> llama_init = std::make_unique<common_init_result_t>(common_init_from_params(cmParams));
	if ((*llama_init).model == nullptr || (*llama_init).context == nullptr) {
		if (OnCancelCallback != nullptr) {
			OnCancelCallback(lcpp_finish_reason::LCPP_FINISH_REASON_FATAL_ERROR);
		}
		(*bLLAMACPP_cancel).store(true);
		return EXIT_FAILURE;
	}
	
	_common.reset(llama_init.release());

	llama_set_abort_callback((*_common).context.get(), _ggml_abort_callback, &bLLAMACPP_abort);

	ggml_backend_dev_t cpu_dev = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_CPU);

	if (cpu_dev) {
		ggml_backend_reg_t reg = ggml_backend_dev_backend_reg(cpu_dev);

		auto* ggml_threadpool_new_fn = (decltype(ggml_threadpool_new)*)ggml_backend_reg_get_proc_address(reg, "ggml_threadpool_new");

		auto* ggml_threadpool_free_fn = (decltype(ggml_threadpool_free)*)ggml_backend_reg_get_proc_address(reg, "ggml_threadpool_free");

		ggml_threadpool_params_t tpp_batch =
			ggml_threadpool_params_from_cpu_params(cmParams.cpuparams_batch);

		ggml_threadpool_params_t tpp =
			ggml_threadpool_params_from_cpu_params(cmParams.cpuparams);

		ggml_threadpool_t threadpool_batch = nullptr;
		if (!ggml_threadpool_params_match(&tpp, &tpp_batch)) {
			threadpool_batch = ggml_threadpool_new_fn(&tpp_batch);
			if (threadpool_batch) { // Start the non-batch threadpool in the paused state
				tpp.paused = true;
			}
		}

		ggml_threadpool_t threadpool = ggml_threadpool_new_fn(&tpp);

		if (threadpool) {
			llama_attach_threadpool((*_common).context.get(), threadpool, threadpool_batch);
		}
		set_process_priority(cmParams.cpuparams.priority);
	}

	_chat_templates.reset(common_chat_templates_init((*_common).model.get(), cmParams.chat_template).release());

	if (OnCancelCallback != nullptr) {
		OnCancelCallback(0);
	}

	bLLAMACPP_loaded = true;

	return EXIT_SUCCESS;
}

void lcpp_reset() {
	if (_common != nullptr && _common->context != nullptr) {
		llama_memory_clear(llama_get_memory((*_common).context.get()), true);
	}
	(*bLLAMACPP_abort).store(false);
	(*bLLAMACPP_cancel).store(false);
	iLLAMACPP_continue.store(lcpp_finish_reason::LCPP_FINISH_REASON_STOP);
}

void lcpp_unload() {
	lcpp_reset();
	if (_common != nullptr && _common->context != nullptr) {
		llama_detach_threadpool((*_common).context.get());
	}

	_chat_templates.reset();
	// _chat_syntax.reset();
	_common.reset();
	bLLAMACPP_loaded = false;

}

void lcpp_initialize() {
	if (!bLLAMACPP_inited.load()) {

		ggml_set_abort_callback(_ggml_abort_callback_t);

		common_init();

		// only print errors
		llama_log_set([](enum ggml_log_level level, const char* text, void* /* user_data */) {
			if (level >= GGML_LOG_LEVEL_ERROR) {
				fprintf(stderr, "%s", text);
			}
			}, nullptr);

		// Based on tools/llama-bench/llama-bench.cpp
		// load dynamic backends
		ggml_backend_load_all();
		
		llama_backend_init();
		

		bLLAMACPP_inited.store(true);
	}


}

void lcpp_reconfigure(const llama_context_params_t context_params, const lcpp_params_t lcpp_params) {

	if (!bLLAMACPP_inited.load()) {
		lcpp_initialize();
	}

	lcpp_unload();

	GGML_ASSERT(lcpp_params.model_path != nullptr);
	// _chat_syntax.reset(chat_syntax_for_model_family(lcpp_params.model_family, lcpp_params.is_reasoning).release());

	common_params_t params;
	{
		params.model.path = std::string(lcpp_params.model_path);
		lcpp_numa_strategy_t numa_strategy = lcpp_params.split_mode == LCPP_SPLIT_MODE_NONE ? LCPP_NUMA_STRATEGY_MIRROR : LCPP_NUMA_STRATEGY_DISTRIBUTE;
		switch (numa_strategy) {
			case LCPP_NUMA_STRATEGY_DISABLED:
				params.numa = GGML_NUMA_STRATEGY_DISABLED;
				break;
			case LCPP_NUMA_STRATEGY_DISTRIBUTE:
				params.numa = GGML_NUMA_STRATEGY_DISTRIBUTE;
				break;
			case LCPP_NUMA_STRATEGY_ISOLATE:
				params.numa = GGML_NUMA_STRATEGY_ISOLATE;
				break;
			case LCPP_NUMA_STRATEGY_NUMACTL:
				params.numa = GGML_NUMA_STRATEGY_NUMACTL;
				break;
			case LCPP_NUMA_STRATEGY_MIRROR:
				params.numa = GGML_NUMA_STRATEGY_MIRROR;
				break;
			default:
				params.numa = GGML_NUMA_STRATEGY_DISABLED;
				break;
		}
		// params.reasoning_format = _chat_syntax->reasoning_format;

		params.webui = false;
		params.enable_chat_template = true;
		params.conversation_mode = COMMON_CONVERSATION_MODE_AUTO;
		params.cache_type_k = GGML_TYPE_F16;
		params.cache_type_v = GGML_TYPE_F16;
		params.escape = lcpp_params.escape;
		params.multiline_input = lcpp_params.multiline_input;
		params.use_mlock = lcpp_params.use_mlock;
		params.use_mmap = lcpp_params.use_mmap;
		params.check_tensors = lcpp_params.check_tensors;
		params.main_gpu = lcpp_params.main_gpu;
		lcpp_split_mode_t split_mode = lcpp_params.split_mode;
		switch (split_mode) {
			case LCPP_SPLIT_MODE_NONE:
				params.split_mode = LLAMA_SPLIT_MODE_NONE;
				break;
			case LCPP_SPLIT_MODE_LAYER:
				params.split_mode = LLAMA_SPLIT_MODE_LAYER;
				break;
			case LCPP_SPLIT_MODE_ROW:
				params.split_mode = LLAMA_SPLIT_MODE_ROW;
				break;
			default:
				params.split_mode = LLAMA_SPLIT_MODE_NONE;
				break;
		}

		params.n_gpu_layers = lcpp_params.n_gpu_layers;
		params.n_ctx = context_params.n_ctx;
		params.no_perf = context_params.no_perf;
		params.n_batch = context_params.n_batch;
		params.n_ubatch = context_params.n_ubatch;
		params.rope_freq_base = context_params.rope_freq_base;
		params.rope_freq_scale = context_params.rope_freq_scale;
		params.rope_scaling_type = context_params.rope_scaling_type;
		params.yarn_attn_factor = context_params.yarn_attn_factor;
		params.yarn_beta_fast = context_params.yarn_beta_fast;
		params.yarn_beta_slow = context_params.yarn_beta_slow;
		params.yarn_ext_factor = context_params.yarn_ext_factor;
		params.yarn_orig_ctx = context_params.yarn_orig_ctx;
		params.cb_eval = context_params.cb_eval;
		params.cb_eval_user_data = context_params.cb_eval_user_data;
		params.embedding = context_params.embeddings;
		params.display_prompt = false;
		params.warmup = true;

		postprocess_cpu_params(params.cpuparams, nullptr);
		params.cpuparams_batch.n_threads = params.cpuparams.n_threads;

		params.load_progress_callback = _ggml_progress_callback;
		params.load_progress_callback_user_data = &bLLAMACPP_cancel;

		if (lcpp_params.offload_experts) {
			params.tensor_buft_overrides.push_back(llm_ffn_exps_cpu_override());
			params.tensor_buft_overrides.push_back({ nullptr, nullptr });
		}
	}
	llama_numa_init(params.numa);

	

	std::thread thr(_conf, params);

	thr.detach();
}

int32_t lcpp_tokenize(const char* text, int n_text, bool add_special,
	bool parse_special, llama_token** tokens) {
	std::string _text(text);
	llama_tokens llama_tokens = common_tokenize((*_common).context.get(), _text, add_special, parse_special);

	if (!llama_tokens.empty()) {
		int n = llama_tokens.size();
		*tokens = (llama_token*)std::calloc(n, sizeof(llama_token));
		std::memcpy(*tokens, llama_tokens.data(), sizeof(llama_token) * n);
		return n;
	}

	return 0;
}

void lcpp_destroy() {

	lcpp_unload();

	lcpp_unset_token_stream_callback();
	lcpp_unset_chat_message_callback();
	lcpp_unset_model_load_progress_callback();
	lcpp_unset_on_cancel_callback();
	lcpp_unset_on_abort_callback();

	llama_backend_free();
	ggml_set_abort_callback(NULL);

	bLLAMACPP_inited = false;
}

void lcpp_free_text(LcppTextStruct_t* ptr) {
	if (ptr != nullptr) {
		if (ptr->length > 0) free(ptr->text);
		free(ptr);
	}
}
