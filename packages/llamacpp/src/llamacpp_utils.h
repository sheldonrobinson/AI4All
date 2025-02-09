#pragma once
#include "llamacpp_common.h"

#ifdef __cplusplus
extern "C" {
#endif
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
		int32_t index;
		uint8_t type;
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

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT lcpp_machine_info_t* lcpp_get_machine_info();

FFI_PLUGIN_EXPORT void lcpp_free_machine_info(lcpp_machine_info_t* mach_info);

FFI_PLUGIN_EXPORT lcpp_model_rt_t* lcpp_model_details(const char* model_path);

FFI_PLUGIN_EXPORT void lcpp_free_model_mem(lcpp_model_mem_t* model_mem);

FFI_PLUGIN_EXPORT void lcpp_free_model_rt(lcpp_model_rt_t* model_rt);

FFI_PLUGIN_EXPORT lcpp_model_info_t* lcpp_get_model_info(const char* model_file);

FFI_PLUGIN_EXPORT void lcpp_free_model_info(lcpp_model_info_t* model_info);
