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
#ifdef WIN32
#define FFI_PLUGIN_EXPORT extern
#else
#define FFI_PLUGIN_EXPORT extern __attribute__((visibility("default"))) __attribute__((used))
#endif
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
		LCPP_MODEL_FAMILY_GPT_OSS = 7,
		LCPP_MODEL_FAMILY_SEED_OSS = 8,
		LCPP_MODEL_FAMILY_GENERIC = 16,
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


	typedef struct lcpp_sampling_params {

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

		int32_t n_samplers;
		int32_t n_grammar_length;

		lcpp_mirostat_type_t mirostat;     // 0 = disabled, 1 = mirostat, 2 = mirostat 2.0

		bool    ignore_eos;
		bool    no_perf; // disable performance metrics
		bool    timing_per_token;
		bool	grammar_lazy;

		lcpp_common_sampler_type_t* samplers;
		char* grammar; // optional BNF-like grammar to constrain sampling

	} lcpp_sampling_params_t;

	// sampling parameters
	typedef struct lcpp_params {
		
		int32_t n_gpu_layers; // number of layers to store in VRAM
		// the GPU that is used for the entire model when split_mode is LLAMA_SPLIT_MODE_NONE
        int32_t main_gpu;
		int32_t n_model_path_length;
		lcpp_model_family_t model_family; // model family e.g. deepseek phi
		lcpp_split_mode_t split_mode; // how to split the model across multiple GPUs
		
		// Keep the booleans together to avoid misalignment during copy-by-value.
        bool vocab_only;    // only load the vocabulary, no weights
        bool use_mmap;      // use mmap if possible
        bool use_mlock;     // force system to keep model in RAM
        bool check_tensors; // validate model tensor data
		bool escape;  // escape "\n", "\r", "\t", "\'", "\"", and "\\"
		bool multiline_input; // reverse the usage of `\`
		bool is_reasoning; // loading reasoning model
		bool offload_experts; // mixture of experts offload to cpu
		char* model_path; // path to GGUF model file

	} lcpp_params_t;

	typedef struct lcpp_common_chat_tool_call {
		char* name;
		char* arguments;
		char* id;
		uint32_t n_name;
		uint32_t n_arguments;
		uint32_t n_id;
	} lcpp_common_chat_tool_call_t;

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
	
	
	typedef struct lcpp_model_info {
		// required
		char* architecture;
		uint32_t n_architecture;
		uint32_t quantization_version;
		uint32_t alignment;
		uint32_t gguf_version;
		int32_t file_type;

		// metadata
		char* name;
		uint32_t n_name;
		char* author;
		uint32_t n_author;
		char* version;
		uint32_t n_version;
		char* organization;
		uint32_t n_organization;
		char* basename;
		uint32_t n_basename;
		char* finetune;
		uint32_t n_finetune;
		char* description;
		uint32_t n_description;
		char* size_label;
		uint32_t n_size_label;
		char* license;
		uint32_t n_license;
		char* license_link;
		uint32_t n_license_link;
		char* url;
		uint32_t n_url;
		char* doi;
		uint32_t n_doi;
		char* uuid;
		uint32_t n_uuid;
		char* repo_url;
		uint32_t n_repo_url;
		
		// LLM
		uint64_t context_length; // n_ctx
		uint64_t embedding_length; // n_embd
		uint64_t block_count;  // n_gpu_layers
		uint64_t feed_forward_length; // n_ff
		uint8_t use_parallel_residual;
		uint32_t expert_count;
		uint32_t expert_used_count; 
		
		// Attention
		uint64_t attention_head_count; //n_head
		uint64_t attention_head_count_kv; // set equal to n_head if model does not use GQA
		double attention_max_alibi_bias;
		double attention_clamp_kqv;
		double attention_layer_norm_epsilon;
		double attention_layer_norm_rms_epsilon;
		uint32_t attention_key_length;
		uint32_t attention_value_length;
		
		// ROPE
		uint64_t rope_dimension_count;
		double rope_freq_base;
		char* rope_scaling_type;
		uint32_t n_rope_scaling_type;
		double rope_scaling_factor;
		uint32_t rope_original_context_length;
		uint8_t rope_scaling_finetuned;


		// Split
		uint64_t split_count;
		uint64_t split_tensor_count;
	} lcpp_model_info_t;

	typedef enum lcpp_cpu_endianess : uint8_t {
		LCPP_CPU_ENDIANESS_UNSPECIFIED = 0,
		LCPP_CPU_ENDIANESS_BIG = 1,
		LCPP_CPU_ENDIANESS_LITTLE = 2,
		LCPP_CPU_ENDIANESS_UNKNOWN = 3
	} lcpp_cpu_endianess_t;


	typedef struct lcpp_cpu_info {
		char* vendor_id;
		int32_t n_vendor_id;
		char* processor_name;
		int32_t n_processor_name;
		char* chipset_vendor;
		int32_t n_chipset_vendor;
		char* uarch;
		int32_t n_uarch;
		lcpp_cpu_endianess_t endianess;
		uint64_t frequency;
		uint32_t num_cores;
		uint32_t num_processors;
		uint32_t num_clusters;

	} lcpp_cpu_info_t;

	typedef struct lcpp_memory_info {
		uint64_t physical_mem;
		uint64_t virtual_mem;

	} lcpp_memory_info_t;

	typedef struct lcpp_gpu_info {
		char* vendor;
		int32_t n_vendor;
		char* device_name;
		int32_t n_device_name;
		uint64_t memory;
		int32_t frequency;
	} lcpp_gpu_info_t;

	typedef struct lcpp_system_info {
		char* os_name;
		int32_t n_os_name;
		char* os_version;
		int32_t n_os_version;
		char* full_name;
		int32_t n_full_name;
	} lcpp_system_info_t;

	typedef struct lcpp_machine_info {
		lcpp_system_info_t* sysinfo;
		lcpp_cpu_info_t* cpuinfo;
		lcpp_memory_info_t* meminfo;
		lcpp_gpu_info_t** gpuinfo;
		int32_t n_gpuinfo;
		uint64_t total_vram;
		uint64_t blkmax_vram;
	} lcpp_machine_info_t;

	typedef struct LcppTextStruct {
    	char* text;
    	int32_t length;
    } LcppTextStruct_t;
	
	typedef struct LcppFloatStruct {
		float value;
	} LcppFloatStruct_t;

	typedef struct lcpp_model_filepath {
		char* directory;
		int32_t n_directory;
		char* basename;
		int32_t n_basename;
		char* file_ext;
		int32_t n_file_ext;
		uint8_t is_sharded;
		int32_t n_shards;

	} lcpp_model_filepath_t;

	typedef struct lcpp_model_mem {
		size_t mem_model;
		size_t tensor_mem;
		size_t mem_experts;
		size_t mem_context;
		size_t mem_attention;
		size_t mem_kv_cache;
	} lcpp_model_mem_t;

	typedef struct lcpp_model_rt {
		lcpp_model_mem_t* memory;
		lcpp_model_info_t* info;
	} lcpp_model_rt_t;
	

	typedef struct llama_model_params llama_model_params_t;

	typedef struct llama_context_params llama_context_params_t;

	typedef void (*LppTokenStreamCallback)(LcppTextStruct_t*);

	typedef void (*LppChatMessageCallback)(lcpp_common_chat_msg_t*);
	
	typedef void (*LppProgressCallback)(LcppFloatStruct_t*);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT int lcpp_prompt(const lcpp_sampling_params_t sampling_params, lcpp_common_chat_msg_t** messages, int n_messages);

FFI_PLUGIN_EXPORT lcpp_params_t lcpp_params_defaults();

FFI_PLUGIN_EXPORT lcpp_sampling_params_t lcpp_sampling_params_defaults();

FFI_PLUGIN_EXPORT void lcpp_reconfigure(const llama_context_params_t context_params, const lcpp_params_t lcpp_params);

FFI_PLUGIN_EXPORT lcpp_machine_info_t* lcpp_get_machine_info();

FFI_PLUGIN_EXPORT void lcpp_free_machine_info(lcpp_machine_info_t* mach_info);

FFI_PLUGIN_EXPORT lcpp_model_rt_t* lcpp_model_details(const char* model_path);

// FFI_PLUGIN_EXPORT void lcpp_free_model_filepath(lcpp_model_filepath_t* model_path);

FFI_PLUGIN_EXPORT void lcpp_free_model_mem(lcpp_model_mem_t* model_mem);

FFI_PLUGIN_EXPORT void lcpp_free_model_rt(lcpp_model_rt_t* model_rt);

FFI_PLUGIN_EXPORT lcpp_model_info_t* lcpp_get_model_info(const char* model_file);

FFI_PLUGIN_EXPORT void lcpp_free_model_info(lcpp_model_info_t* model_info);

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


FFI_PLUGIN_EXPORT void lcpp_unload();

// FFI_PLUGIN_EXPORT void lcpp_clear_token_stream_responses();

FFI_PLUGIN_EXPORT void lcpp_destroy();

#endif // _LLAMACPP_H