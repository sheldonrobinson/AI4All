#ifndef _LLAMACPP_H
#define _LLAMACPP_H

#ifdef __cplusplus
#ifdef WIN32
#define FFI_PLUGIN_EXPORT extern "C" __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif // WIN32
#include <cstdint>
#include <cstdbool>

#else // __cplusplus - Objective-C or other C platform
#define FFI_PLUGIN_EXPORT extern
#include <stdint.h>
#include <stdbool.h>
#endif

#include "llama.h"

#ifdef __cplusplus
extern "C" {
#endif

	typedef struct common_chat_msg common_chat_msg_t;

	typedef struct lcpp_data_pvalue {
		char* value;
		int32_t length;
		bool found;

	} lcpp_data_pvalue_t;
	
	typedef enum lcpp_split_mode : uint8_t {
        LCPP_SPLIT_MODE_NONE  = 0, // single GPU
        LCPP_SPLIT_MODE_LAYER = 1, // split layers and KV across GPUs
        LCPP_SPLIT_MODE_ROW   = 2, // split layers and KV across GPUs, use tensor parallelism if supported
    } lcpp_split_mode_t;


	typedef enum lcpp_mirostat_type : uint8_t {
		LCPP_MIROSTAT_NONE = 0, // disabled, 
		LCPP_MIROSTAT_V1 = 1, // mirostat 1.0
		LCPP_MIROSTAT_V2 = 2, // mirostat 2.0

	} lcpp_mirostat_type_t;

	typedef enum lcpp_model_family : uint8_t {
		LCPP_MODEL_FAMILY_LLAMA = 0,
		LCPP_MODEL_FAMILY_QWEN = 1,
		LCPP_MODEL_FAMILY_PHI = 2,
		LCPP_MODEL_FAMILY_GEMMA = 3,
		LCPP_MODEL_FAMILY_GRANITE = 4,
		LCPP_MODEL_FAMILY_DEEPSEEK = 5,
		LCPP_MODEL_FAMILY_MISTRAL = 6,
		LCPP_MODEL_FAMILY_COUNT,
		LCPP_MODEL_FAMILY_UNSPECIFIED = 30,
		LCPP_MODEL_FAMILY_UNKNOWN = 31
	} lcpp_model_family_t;

	// from common.h
	typedef enum lcpp_common_sampler_type : uint8_t {
		LCPP_COMMON_SAMPLER_TYPE_NONE = 0,
		LCPP_COMMON_SAMPLER_TYPE_DRY = 1,
		LCPP_COMMON_SAMPLER_TYPE_TOP_K = 2,
		LCPP_COMMON_SAMPLER_TYPE_TOP_P = 3,
		LCPP_COMMON_SAMPLER_TYPE_MIN_P = 4,
		//LCPP_COMMON_SAMPLER_TYPE_TFS_Z       = 5,
		LCPP_COMMON_SAMPLER_TYPE_TYPICAL_P = 6,
		LCPP_COMMON_SAMPLER_TYPE_TEMPERATURE = 7,
		LCPP_COMMON_SAMPLER_TYPE_XTC = 8,
		LCPP_COMMON_SAMPLER_TYPE_INFILL = 9,
		LCPP_COMMON_SAMPLER_TYPE_PENALTIES = 10,
		LCPP_COMMON_SAMPLER_TYPE_TOP_N_SIGMA = 11,
	} lcpp_common_sampler_type_t, plcpp_common_sampler_type_t;

	// sampling parameters
	typedef struct lcpp_params {
		float   temp; // <= 0.0 to sample greedily, 0.0 to not output probabilities
		float   dynatemp_range; // 0.0 = disabled
		float   dynatemp_exponent; // controls how entropy maps to temperature in dynamic temperature sampler
		float   top_p; // 1.0 = disabled
		float   min_p; // 0.0 = disabled
		float   xtc_probability; // 0.0 = disabled
		float   xtc_threshold; // > 0.5 disables XTC
		float   typ_p; // typical_p, 1.0 = disabled
		float   penalty_repeat; // 1.0 = disabled
		float   penalty_freq; // 0.0 = disabled
		float   penalty_present; // 0.0 = disabled
		float   dry_multiplier;  // 0.0 = disabled;      DRY repetition penalty for tokens extending repetition:
		float   dry_base; // 0.0 = disabled;      multiplier * base ^ (length of sequence before token - allowed length)
		float   top_n_sigma;// -1.0 = disabled
		float   mirostat_tau; // target entropy
		float   mirostat_eta; // learning rate
		uint32_t seed; // the seed used to initialize llama_sampler
		int32_t n_prev;    // number of previous tokens to remember
		int32_t n_probs;     // if greater than 0, output the probabilities of top n_probs tokens.
		int32_t min_keep;     // 0 = disabled, otherwise samplers should return at least min_keep tokens
		int32_t top_k;    // <= 0 to use vocab size
		int32_t penalty_last_n;    // last n tokens to penalize (0 = disable penalty, -1 = context size)
		int32_t dry_allowed_length;     // tokens extending repetitions beyond this receive penalty
		int32_t dry_penalty_last_n;    // how many tokens to scan for repetitions (0 = disable penalty, -1 = context size)
		int32_t n_gpu_layers; // number of layers to store in VRAM
		// the GPU that is used for the entire model when split_mode is LLAMA_SPLIT_MODE_NONE
        int32_t main_gpu;
		int32_t n_samplers;
		int32_t n_grammar_length;
		int32_t n_model_path_length;

		lcpp_mirostat_type_t mirostat;     // 0 = disabled, 1 = mirostat, 2 = mirostat 2.0
		lcpp_model_family_t model_family; // model family e.g. deepseek phi
		lcpp_split_mode_t split_mode; // how to split the model across multiple GPUs

		bool    ignore_eos;
		bool    no_perf; // disable performance metrics
		bool    timing_per_token;
		bool	grammar_lazy;
		// Keep the booleans together to avoid misalignment during copy-by-value.
        bool vocab_only;    // only load the vocabulary, no weights
        bool use_mmap;      // use mmap if possible
        bool use_mlock;     // force system to keep model in RAM
        bool check_tensors; // validate model tensor data
		bool escape;  // escape "\n", "\r", "\t", "\'", "\"", and "\\"
		bool multiline_input; // reverse the usage of `\`
		bool is_reasoning; // loading reasoning model

		lcpp_common_sampler_type_t* samplers;
		char* grammar; // optional BNF-like grammar to constrain sampling
		char* model_path; // path to GGUF model file

	} lcpp_params_t;

	typedef struct lcpp_common_chat_tool_call {
		char* name;
		char* arguments;
		char* id;
		uint32_t n_name;
		uint32_t n_arguments;
		uint32_t n_id;
	} lcpp_common_chat_tool_call_t, *plcpp_common_chat_tool_call_t;

	typedef struct lcpp_common_chat_msg_content_part {
		char* type;
		char* text;
		uint32_t n_type;
		uint32_t n_text;
	} lcpp_common_chat_msg_content_part_t, *plcpp_common_chat_msg_content_part_t;

	typedef struct lcpp_common_chat_msg {
		char* role;
		char* content;
		uint32_t n_role;
		uint32_t n_content;
		lcpp_common_chat_msg_content_part_t** content_parts;
		int32_t n_content_parts;
		lcpp_common_chat_tool_call_t** tool_calls;
		int32_t n_tool_calls;
		char* reasoning_content;
		uint32_t n_reasoning_content;
		char* tool_name;
		uint32_t n_tool_name;
		char* tool_call_id;
		uint32_t n_tool_call_id;
	} lcpp_common_chat_msg_t;

	typedef struct LcppTextStruct {
    	char* text;
    	int32_t length;
    } LcppTextStruct_t;
	
	typedef struct LcppFloatStruct {
		float value;
	} LcppFloatStruct_t;
	

	typedef struct llama_model_params llama_model_params_t;

	typedef struct llama_context_params llama_context_params_t;

	typedef void (*LppTokenStreamCallback)(LcppTextStruct_t*);

	typedef void (*LppChatMessageCallback)(lcpp_common_chat_msg_t*);
	
	typedef void (*LppProgressCallback)(LcppFloatStruct_t*);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT int lcpp_prompt(lcpp_common_chat_msg_t** messages, int n_messages);

FFI_PLUGIN_EXPORT lcpp_params_t lcpp_params_defaults();

FFI_PLUGIN_EXPORT void lcpp_reconfigure(const llama_context_params_t context_params, const lcpp_params_t lcpp_params);

FFI_PLUGIN_EXPORT void lcpp_set_token_stream_callback(LppTokenStreamCallback newtoken_callback);

FFI_PLUGIN_EXPORT void lcpp_unset_token_stream_callback();

FFI_PLUGIN_EXPORT void lcpp_set_chat_message_callback(LppChatMessageCallback chat_msg_callback);

FFI_PLUGIN_EXPORT void lcpp_unset_chat_message_callback();

FFI_PLUGIN_EXPORT void lcpp_set_model_load_progress_callback(LppProgressCallback model_loading_callback);

FFI_PLUGIN_EXPORT void lcpp_unset_model_load_progress_callback();

FFI_PLUGIN_EXPORT int32_t lcpp_tokenize(const char* text, int n_text, bool add_special,
	bool parse_special, llama_token** tokens);

FFI_PLUGIN_EXPORT void lcpp_detokenize(int* tokens, int n_tokens, bool special, lcpp_data_pvalue_t* text);

// FFI_PLUGIN_EXPORT void lcpp_model_description(lcpp_data_pvalue_t* pvalue);

// FFI_PLUGIN_EXPORT void lcpp_model_architecture(lcpp_data_pvalue_t* pvalue);

FFI_PLUGIN_EXPORT void lcpp_send_abort_signal(bool abort);

FFI_PLUGIN_EXPORT void lcpp_send_cancel_signal(bool cancel);

FFI_PLUGIN_EXPORT void lcpp_native_free(void* ptr);

FFI_PLUGIN_EXPORT void lcpp_free_common_chat_msg(lcpp_common_chat_msg_t* msg);

FFI_PLUGIN_EXPORT void lcpp_free_float(LcppFloatStruct_t* ptr);

FFI_PLUGIN_EXPORT void lcpp_free_text(LcppTextStruct_t* ptr);

FFI_PLUGIN_EXPORT void lcpp_reset();

// FFI_PLUGIN_EXPORT void lcpp_clear_token_stream_responses();

FFI_PLUGIN_EXPORT void lcpp_destroy();

#endif // _LLAMACPP_H