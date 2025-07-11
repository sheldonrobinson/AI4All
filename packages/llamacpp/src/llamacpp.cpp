#include <stdlib.h>
#include <float.h>
#include <algorithm>
#include <time.h>
#include <string.h>
#include <queue>
#include <string>
#include <cmath>
#include <numeric>
#include <cstring>
#include <thread>
#include <atomic>
#include <limits>
#include <filesystem>
#include <regex>
#include <cpuinfo.h>
#include <infoware/infoware.hpp>


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

// typedef struct ggml_threadpool_params ggml_threadpool_params_t;

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

// std::string shard_regex("\\d\\{m\\}-of-\\d\\{m\\}?\\.gguf$");

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

static std::atomic<bool> _inited{ false };

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
		if (msg->n_role) message.role = msg->role;
	}
	if (msg->content != nullptr) {
		if (msg->n_content) {
			//std::string text(msg->content);
			//std::replace(text.begin(), text.end(), '\n', ' ');

			//auto updated = std::remove(text.begin(), text.end(), '\r');
			//text.erase(updated, text.end());

			message.content = msg->content;
		}
	}
	if (msg->tool_name != nullptr) {
		if (msg->n_tool_name) message.tool_name = msg->tool_name;
	}
	if (msg->tool_call_id != nullptr) {
		if (msg->n_tool_call_id) message.tool_call_id = msg->tool_call_id;
	}
	if (msg->reasoning_content != nullptr) {
		if (msg->n_reasoning_content) message.reasoning_content = msg->reasoning_content;
	}
	if (msg->n_tool_calls > 0) {
		for (auto it = msg->tool_calls; it != nullptr; it++) {
			auto result = *it;
			common_chat_tool_call toolcall;
			if (result->arguments != nullptr) {
				if (result->n_arguments) toolcall.arguments = result->arguments;
			}
			if (result->id != nullptr) {
				if (result->n_id) toolcall.id = result->id;
			}
			if (result->name != nullptr) {
				if (result->n_name) toolcall.name = result->name;
			}
			message.tool_calls.push_back(toolcall);
		}
	}
	if (msg->n_content_parts > 0) {
		for (auto it = msg->content_parts; it != nullptr; it++) {
			auto result = *it;
			common_chat_msg_content_part content;
			if (result->text != nullptr) {
				if (result->n_text) content.text = result->text;
			}
			if (result->type != nullptr) {
				if (result->n_type) content.type = result->type;
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
		if (msg->n_content) free(msg->content);
		if (msg->n_role) free(msg->role);

		if (msg->n_content_parts > 0) {
			for (int i = 0; i < msg->n_content_parts; i++) {
				if (msg->content_parts[i] != nullptr) {
					if (msg->content_parts[i]->n_text > 0) free(msg->content_parts[i]->text);
					if (msg->content_parts[i]->n_type > 0) free(msg->content_parts[i]->type);
				}
			}
		}

		if (msg->n_tool_calls > 0) {
			for (int j = 0; j < msg->n_tool_calls; j++) {
				if (msg->tool_calls[j] != nullptr) {
					if (msg->tool_calls[j]->n_arguments) free(msg->tool_calls[j]->arguments);
					if (msg->tool_calls[j]->n_name) free(msg->tool_calls[j]->name);
					if (msg->tool_calls[j]->n_id) free(msg->tool_calls[j]->id);
				}
			}
		}

		if (msg->n_reasoning_content) free(msg->reasoning_content);
		if (msg->n_tool_name) free(msg->tool_name);
		if (msg->n_tool_call_id) free(msg->tool_call_id);

		free(msg);
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

typedef struct gguf_init_params gguf_init_params_t;

// static common_sampler_ptr _sampler;

static common_chat_templates_ptr _chat_templates;

static std::atomic<bool> _use_jinja{ false };

void lcpp_free_model_info(lcpp_model_info_t* model_info) {
	if (model_info != NULL) {
		if (model_info->n_architecture > 0) free(model_info->architecture);
		if (model_info->n_name > 0) free(model_info->name);
		if (model_info->n_author > 0) free(model_info->author);
		if (model_info->n_version > 0) free(model_info->version);
		if (model_info->n_organization > 0) free(model_info->organization);
		if (model_info->n_basename > 0) free(model_info->basename);
		if (model_info->n_finetune > 0) free(model_info->finetune);
		if (model_info->n_description > 0) free(model_info->description);
		if (model_info->n_size_label > 0) free(model_info->size_label);
		if (model_info->n_license > 0) free(model_info->license);
		if (model_info->n_license_link > 0) free(model_info->license_link);
		if (model_info->n_url > 0) free(model_info->url);
		if (model_info->n_doi > 0) free(model_info->doi);
		if (model_info->n_uuid > 0) free(model_info->uuid);
		if (model_info->n_repo_url > 0) free(model_info->repo_url);
		if (model_info->n_rope_scaling_type > 0) free(model_info->rope_scaling_type);
	}
}

typedef struct lcpp_model_info_deleter {
	void operator()(lcpp_model_info_t* info) {
		lcpp_free_model_info(info);
	}
} lcpp_model_info_deleter_t;

typedef std::unique_ptr<lcpp_model_info_t, lcpp_model_info_deleter_t> lcpp_model_info_ptr;

void lcpp_free_model_mem(lcpp_model_mem_t* model_mem) {
	if (model_mem != NULL) {
		free(model_mem);
	}
}

typedef struct lcpp_model_mem_deleter {
	void operator()(lcpp_model_mem_t* filepath) {
		lcpp_free_model_mem(filepath);
	}
} lcpp_model_mem_deleter_t;

typedef std::unique_ptr<lcpp_model_mem_t, lcpp_model_mem_deleter_t> lcpp_model_mem_ptr;

void lcpp_free_model_rt(lcpp_model_rt_t* model_rt) {
	if (model_rt != NULL) {
		if (model_rt->memory != NULL) lcpp_free_model_mem(model_rt->memory);
		if (model_rt->info != NULL) lcpp_free_model_info(model_rt->info);
		free(model_rt);
	}
}

typedef struct lcpp_model_rt_deleter {
	void operator()(lcpp_model_rt_t* filepath) {
		lcpp_free_model_rt(filepath);
	}
} lcpp_model_rt_deleter_t;

typedef std::unique_ptr<lcpp_model_rt_t, lcpp_model_rt_deleter_t> lcpp_model_rt_ptr;

void lcpp_free_machine_info(lcpp_machine_info_t* mach_info) {
	if (mach_info != NULL) {
		if (mach_info->sysinfo != NULL) {
			lcpp_system_info_t* sys_info = mach_info->sysinfo;
			if (sys_info->n_os_name > 0) free(sys_info->os_name);
			if (sys_info->n_os_version > 0) free(sys_info->os_version);
			if (sys_info->n_full_name > 0) free(sys_info->full_name);
			free(mach_info->sysinfo);
		}
		if (mach_info->cpuinfo != NULL) {
			lcpp_cpu_info_t* cpu_info = mach_info->cpuinfo;
			if (cpu_info->n_chipset_vendor > 0) free(cpu_info->chipset_vendor);
			if (cpu_info->n_vendor_id > 0) free(cpu_info->vendor_id);
			if (cpu_info->n_processor_name > 0) free(cpu_info->processor_name);
			if (cpu_info->n_uarch > 0) free(cpu_info->uarch);
			free(mach_info->cpuinfo);
		}
		if (mach_info->gpuinfo != NULL) {
			for (int i = 0, n = mach_info->n_gpuinfo; i < n; i++) {
				lcpp_gpu_info_t* gpu_info = mach_info->gpuinfo[i];
				if (gpu_info != NULL) {
					if (gpu_info->n_vendor > 0) free(gpu_info->vendor);
					if (gpu_info->n_device_name > 0) free(gpu_info->device_name);
					free(gpu_info);
				}
			}
			free(mach_info->gpuinfo);
		}
		if (mach_info->meminfo != NULL) free(mach_info->meminfo);
		free(mach_info);
	}
}

typedef struct lcpp_machine_info_deleter {
	void operator()(lcpp_machine_info_t* info) {
		lcpp_free_machine_info(info);
	}
} lcpp_machine_info_deleter_t;

typedef std::unique_ptr<lcpp_machine_info_t, lcpp_machine_info_deleter_t> lcpp_machine_info_ptr;

static const char* cpuinfo_vendor_to_string(enum cpuinfo_vendor vendor) {
	switch (vendor) {
	case cpuinfo_vendor_unknown:
		return "unknown";
	case cpuinfo_vendor_intel:
		return "Intel";
	case cpuinfo_vendor_amd:
		return "AMD";
	case cpuinfo_vendor_huawei:
		return "Huawei";
	case cpuinfo_vendor_hygon:
		return "Hygon";
	case cpuinfo_vendor_arm:
		return "ARM";
	case cpuinfo_vendor_qualcomm:
		return "Qualcomm";
	case cpuinfo_vendor_apple:
		return "Apple";
	case cpuinfo_vendor_samsung:
		return "Samsung";
	case cpuinfo_vendor_nvidia:
		return "Nvidia";
	case cpuinfo_vendor_mips:
		return "MIPS";
	case cpuinfo_vendor_ibm:
		return "IBM";
	case cpuinfo_vendor_ingenic:
		return "Ingenic";
	case cpuinfo_vendor_via:
		return "VIA";
	case cpuinfo_vendor_cavium:
		return "Cavium";
	case cpuinfo_vendor_broadcom:
		return "Broadcom";
	case cpuinfo_vendor_apm:
		return "Applied Micro";
	default:
		return NULL;
	}
}

static const char* cpuinfo_uarch_to_string(enum cpuinfo_uarch uarch) {
	switch (uarch) {
	case cpuinfo_uarch_unknown:
		return "unknown";
	case cpuinfo_uarch_p5:
		return "P5";
	case cpuinfo_uarch_quark:
		return "Quark";
	case cpuinfo_uarch_p6:
		return "P6";
	case cpuinfo_uarch_dothan:
		return "Dothan";
	case cpuinfo_uarch_yonah:
		return "Yonah";
	case cpuinfo_uarch_conroe:
		return "Conroe";
	case cpuinfo_uarch_penryn:
		return "Penryn";
	case cpuinfo_uarch_nehalem:
		return "Nehalem";
	case cpuinfo_uarch_sandy_bridge:
		return "Sandy Bridge";
	case cpuinfo_uarch_ivy_bridge:
		return "Ivy Bridge";
	case cpuinfo_uarch_haswell:
		return "Haswell";
	case cpuinfo_uarch_broadwell:
		return "Broadwell";
	case cpuinfo_uarch_sky_lake:
		return "Sky Lake";
	case cpuinfo_uarch_palm_cove:
		return "Palm Cove";
	case cpuinfo_uarch_sunny_cove:
		return "Sunny Cove";
	case cpuinfo_uarch_willow_cove:
		return "Willow Cove";
	case cpuinfo_uarch_willamette:
		return "Willamette";
	case cpuinfo_uarch_prescott:
		return "Prescott";
	case cpuinfo_uarch_bonnell:
		return "Bonnell";
	case cpuinfo_uarch_saltwell:
		return "Saltwell";
	case cpuinfo_uarch_silvermont:
		return "Silvermont";
	case cpuinfo_uarch_airmont:
		return "Airmont";
	case cpuinfo_uarch_goldmont:
		return "Goldmont";
	case cpuinfo_uarch_goldmont_plus:
		return "Goldmont Plus";
	case cpuinfo_uarch_tremont:
		return "Tremont";
	case cpuinfo_uarch_gracemont:
		return "Gracemont";
	case cpuinfo_uarch_crestmont:
		return "Crestmont";
	case cpuinfo_uarch_darkmont:
		return "Darkmont";
	case cpuinfo_uarch_knights_ferry:
		return "Knights Ferry";
	case cpuinfo_uarch_knights_corner:
		return "Knights Corner";
	case cpuinfo_uarch_knights_landing:
		return "Knights Landing";
	case cpuinfo_uarch_knights_hill:
		return "Knights Hill";
	case cpuinfo_uarch_knights_mill:
		return "Knights Mill";
	case cpuinfo_uarch_k5:
		return "K5";
	case cpuinfo_uarch_k6:
		return "K6";
	case cpuinfo_uarch_k7:
		return "K7";
	case cpuinfo_uarch_k8:
		return "K8";
	case cpuinfo_uarch_k10:
		return "K10";
	case cpuinfo_uarch_bulldozer:
		return "Bulldozer";
	case cpuinfo_uarch_piledriver:
		return "Piledriver";
	case cpuinfo_uarch_steamroller:
		return "Steamroller";
	case cpuinfo_uarch_excavator:
		return "Excavator";
	case cpuinfo_uarch_zen:
		return "Zen";
	case cpuinfo_uarch_zen2:
		return "Zen 2";
	case cpuinfo_uarch_zen3:
		return "Zen 3";
	case cpuinfo_uarch_zen4:
		return "Zen 4";
	case cpuinfo_uarch_zen5:
		return "Zen 5";
	case cpuinfo_uarch_geode:
		return "Geode";
	case cpuinfo_uarch_bobcat:
		return "Bobcat";
	case cpuinfo_uarch_jaguar:
		return "Jaguar";
	case cpuinfo_uarch_puma:
		return "Puma";
	case cpuinfo_uarch_xscale:
		return "XScale";
	case cpuinfo_uarch_arm7:
		return "ARM7";
	case cpuinfo_uarch_arm9:
		return "ARM9";
	case cpuinfo_uarch_arm11:
		return "ARM11";
	case cpuinfo_uarch_cortex_a5:
		return "Cortex-A5";
	case cpuinfo_uarch_cortex_a7:
		return "Cortex-A7";
	case cpuinfo_uarch_cortex_a8:
		return "Cortex-A8";
	case cpuinfo_uarch_cortex_a9:
		return "Cortex-A9";
	case cpuinfo_uarch_cortex_a12:
		return "Cortex-A12";
	case cpuinfo_uarch_cortex_a15:
		return "Cortex-A15";
	case cpuinfo_uarch_cortex_a17:
		return "Cortex-A17";
	case cpuinfo_uarch_cortex_a32:
		return "Cortex-A32";
	case cpuinfo_uarch_cortex_a35:
		return "Cortex-A35";
	case cpuinfo_uarch_cortex_a53:
		return "Cortex-A53";
	case cpuinfo_uarch_cortex_a55r0:
		return "Cortex-A55r0";
	case cpuinfo_uarch_cortex_a55:
		return "Cortex-A55";
	case cpuinfo_uarch_cortex_a57:
		return "Cortex-A57";
	case cpuinfo_uarch_cortex_a65:
		return "Cortex-A65";
	case cpuinfo_uarch_cortex_a72:
		return "Cortex-A72";
	case cpuinfo_uarch_cortex_a73:
		return "Cortex-A73";
	case cpuinfo_uarch_cortex_a75:
		return "Cortex-A75";
	case cpuinfo_uarch_cortex_a76:
		return "Cortex-A76";
	case cpuinfo_uarch_cortex_a77:
		return "Cortex-A77";
	case cpuinfo_uarch_cortex_a78:
		return "Cortex-A78";
	case cpuinfo_uarch_cortex_a510:
		return "Cortex-A510";
	case cpuinfo_uarch_cortex_a710:
		return "Cortex-A710";
	case cpuinfo_uarch_cortex_a715:
		return "Cortex-A715";
	case cpuinfo_uarch_cortex_x1:
		return "Cortex-X1";
	case cpuinfo_uarch_cortex_x2:
		return "Cortex-X2";
	case cpuinfo_uarch_cortex_x3:
		return "Cortex-X3";
	case cpuinfo_uarch_neoverse_n1:
		return "Neoverse N1";
	case cpuinfo_uarch_neoverse_e1:
		return "Neoverse E1";
	case cpuinfo_uarch_neoverse_v1:
		return "Neoverse V1";
	case cpuinfo_uarch_neoverse_n2:
		return "Neoverse N2";
	case cpuinfo_uarch_neoverse_v2:
		return "Neoverse V2";
	case cpuinfo_uarch_scorpion:
		return "Scorpion";
	case cpuinfo_uarch_krait:
		return "Krait";
	case cpuinfo_uarch_kryo:
		return "Kryo";
	case cpuinfo_uarch_falkor:
		return "Falkor";
	case cpuinfo_uarch_saphira:
		return "Saphira";
	case cpuinfo_uarch_oryon:
		return "Oryon";
	case cpuinfo_uarch_denver:
		return "Denver";
	case cpuinfo_uarch_denver2:
		return "Denver 2";
	case cpuinfo_uarch_carmel:
		return "Carmel";
	case cpuinfo_uarch_exynos_m1:
		return "Exynos M1";
	case cpuinfo_uarch_exynos_m2:
		return "Exynos M2";
	case cpuinfo_uarch_exynos_m3:
		return "Exynos M3";
	case cpuinfo_uarch_exynos_m4:
		return "Exynos M4";
	case cpuinfo_uarch_exynos_m5:
		return "Exynos M5";
	case cpuinfo_uarch_swift:
		return "Swift";
	case cpuinfo_uarch_cyclone:
		return "Cyclone";
	case cpuinfo_uarch_typhoon:
		return "Typhoon";
	case cpuinfo_uarch_twister:
		return "Twister";
	case cpuinfo_uarch_hurricane:
		return "Hurricane";
	case cpuinfo_uarch_monsoon:
		return "Monsoon";
	case cpuinfo_uarch_mistral:
		return "Mistral";
	case cpuinfo_uarch_vortex:
		return "Vortex";
	case cpuinfo_uarch_tempest:
		return "Tempest";
	case cpuinfo_uarch_lightning:
		return "Lightning";
	case cpuinfo_uarch_thunder:
		return "Thunder";
	case cpuinfo_uarch_firestorm:
		return "Firestorm";
	case cpuinfo_uarch_icestorm:
		return "Icestorm";
	case cpuinfo_uarch_avalanche:
		return "Avalanche";
	case cpuinfo_uarch_blizzard:
		return "Blizzard";
	case cpuinfo_uarch_everest:
		return "Everest";
	case cpuinfo_uarch_sawtooth:
		return "Sawtooth";
	case cpuinfo_uarch_coll_everest:
		return "Coll_Everest";
	case cpuinfo_uarch_coll_sawtooth:
		return "Coll_Sawtooth";
	case cpuinfo_uarch_tupai_everest:
		return "Tupai_Everest";
	case cpuinfo_uarch_tupai_sawtooth:
		return "Tupai_Sawtooth";
	case cpuinfo_uarch_tahiti_everest:
		return "Tahiti_Everest";
	case cpuinfo_uarch_tahiti_sawtooth:
		return "Tahiti_Sawtooth";
	case cpuinfo_uarch_thunderx:
		return "ThunderX";
	case cpuinfo_uarch_thunderx2:
		return "ThunderX2";
	case cpuinfo_uarch_pj4:
		return "PJ4";
	case cpuinfo_uarch_brahma_b15:
		return "Brahma B15";
	case cpuinfo_uarch_brahma_b53:
		return "Brahma B53";
	case cpuinfo_uarch_xgene:
		return "X-Gene";
	case cpuinfo_uarch_dhyana:
		return "Dhyana";
	case cpuinfo_uarch_taishan_v110:
		return "TaiShan v110";
	default:
		return NULL;
	}
}

static lcpp_cpu_endianess_t iware_endianness_name(iware::cpu::endianness_t endianness) noexcept {
	switch (endianness) {
	case iware::cpu::endianness_t::little:
		return lcpp_cpu_endianess_t::LCPP_CPU_ENDIANESS_LITTLE;
	case iware::cpu::endianness_t::big:
		return lcpp_cpu_endianess_t::LCPP_CPU_ENDIANESS_BIG;
	default:
		return lcpp_cpu_endianess_t::LCPP_CPU_ENDIANESS_UNKNOWN;
	}
}

static const char* iware_vendor_name(iware::gpu::vendor_t vendor) noexcept {
	switch (vendor) {
	case iware::gpu::vendor_t::intel:
		return "Intel";
	case iware::gpu::vendor_t::amd:
		return "AMD";
	case iware::gpu::vendor_t::nvidia:
		return "NVidia";
	case iware::gpu::vendor_t::microsoft:
		return "Microsoft";
	case iware::gpu::vendor_t::qualcomm:
		return "Qualcomm";
	case iware::gpu::vendor_t::apple:
		return "Apple";
	default:
		return "Unknown";
	}
}

lcpp_machine_info_t* lcpp_get_machine_info() {
	lcpp_machine_info_t* machine_info = (lcpp_machine_info_t*)malloc(sizeof(lcpp_machine_info_t));
	machine_info->cpuinfo = (lcpp_cpu_info_t*)malloc(sizeof(lcpp_cpu_info_t));
	lcpp_cpu_info_t* cpu_info = machine_info->cpuinfo;
	const auto quantities = iware::cpu::quantities();
	machine_info->cpuinfo->num_clusters = quantities.packages;
	if (cpuinfo_initialize()) {
		std::vector<std::string> _uarch;
		std::ostringstream oss(std::ios_base::out | std::ios_base::app);
		for (uint32_t i = 0, n = cpuinfo_get_uarchs_count(); i < n; i++) {
			const struct cpuinfo_uarch_info* uarch_info = cpuinfo_get_uarch(i);
			const char* uarch_string = cpuinfo_uarch_to_string(uarch_info->uarch);
			oss.str("");
			if (uarch_string != NULL) {
				std::string s;
				oss << uarch_info->core_count << " x " << uarch_string;
				_uarch.push_back(oss.str());
				oss.clear();
			}
		}
		if (_uarch.size() > 0) {
			std::ostringstream uarch_oss;
			for (const auto& arch : _uarch) {
				if (!uarch_oss.str().empty()) uarch_oss << ",";
				uarch_oss << arch;
			}
			std::string uarch_string = uarch_oss.str();
			int len = uarch_string.length();
			cpu_info->uarch = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(cpu_info->uarch, uarch_string.c_str(), len);
			cpu_info->uarch[len] = '\0';
			cpu_info->n_uarch = len;
		}
		else {
			cpu_info->n_uarch = 0;
		}

		std::set<std::string> _chipset_vendors;
		for (uint32_t i = 0; i < cpuinfo_get_clusters_count(); i++) {
			const struct cpuinfo_cluster* cluster = cpuinfo_get_cluster(0);
			const char* vendor_string = cpuinfo_vendor_to_string(cluster->vendor);
			_chipset_vendors.insert(vendor_string);
		}

		if (_chipset_vendors.size() > 0) {
			std::ostringstream vendor_oss;
			for (const auto& vendor : _chipset_vendors) {
				if (!vendor_oss.str().empty()) vendor_oss << ",";
				vendor_oss << vendor;
			}
			std::string chipset_vendor_string = vendor_oss.str();
			int len = chipset_vendor_string.length();
			cpu_info->chipset_vendor = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(cpu_info->chipset_vendor, chipset_vendor_string.c_str(), len);
			cpu_info->chipset_vendor[len] = '\0';
			cpu_info->n_chipset_vendor = len;
		}
		else {
			cpu_info->n_chipset_vendor = 0;
		}

		cpu_info->num_processors = cpuinfo_get_processors_count();
		cpu_info->num_cores = cpuinfo_get_cores_count();
	}
	else {
		cpu_info->num_processors = quantities.logical;
		cpu_info->num_cores = quantities.physical;

	}

	cpu_info->num_clusters = cpuinfo_get_clusters_count();
	cpu_info->endianess = iware_endianness_name(iware::cpu::endianness());

	{
		const auto vendor_id_string = iware::cpu::vendor_id();
		if (vendor_id_string.length() > 0) {
			int len = vendor_id_string.length();
			cpu_info->vendor_id = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(cpu_info->vendor_id, vendor_id_string.c_str(), len);
			cpu_info->vendor_id[len] = '\0';
			cpu_info->n_vendor_id = len;
		}
	}

	{
		const auto processor_name_string = iware::cpu::model_name();
		if (processor_name_string.length() > 0) {
			int len = processor_name_string.length();
			cpu_info->processor_name = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(cpu_info->processor_name, processor_name_string.c_str(), len);
			cpu_info->processor_name[len] = '\0';
			cpu_info->n_processor_name = len;
		}
	}

	{
		const auto processor_name_string = iware::cpu::model_name();
		if (processor_name_string.length() > 0) {
			int len = processor_name_string.length();
			cpu_info->processor_name = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(cpu_info->processor_name, processor_name_string.c_str(), len);
			cpu_info->processor_name[len] = '\0';
			cpu_info->n_processor_name = len;
		}
	}
	{
		cpu_info->frequency = iware::cpu::frequency();
	}

	{
		machine_info->meminfo = (lcpp_memory_info_t*)std::malloc(sizeof(lcpp_memory_info_t));
		const auto memory = iware::system::memory();
		machine_info->meminfo->physical_mem = memory.physical_total;
		machine_info->meminfo->virtual_mem = memory.virtual_total;
	}

	{
		machine_info->sysinfo = (lcpp_system_info_t*)std::malloc(sizeof(lcpp_system_info_t));
		lcpp_system_info_t* sys_info = machine_info->sysinfo;
		const auto OS_info = iware::system::OS_info();
		if (OS_info.name.length() > 0) {
			int len = OS_info.name.length();
			sys_info->os_name = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(sys_info->os_name, OS_info.name.c_str(), len);
			sys_info->os_name[len] = '\0';
			sys_info->n_os_name = len;
		}
		else {
			sys_info->n_os_name = 0;
		}

		if (OS_info.full_name.length() > 0) {
			int len = OS_info.full_name.length();
			sys_info->full_name = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(sys_info->full_name, OS_info.full_name.c_str(), len);
			sys_info->full_name[len] = '\0';
			sys_info->n_full_name = len;
		}
		else {
			sys_info->n_full_name = 0;
		}

		std::ostringstream oss(std::ios_base::out | std::ios_base::app);
		oss.str("");
		oss << OS_info.major << '.' << OS_info.minor << '.' << OS_info.patch << " build " << OS_info.build_number;
		std::string os_version = oss.str();
		if (os_version.length() > 0) {
			int len = os_version.length();
			sys_info->os_version = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(sys_info->os_version, os_version.c_str(), len);
			sys_info->os_version[len] = '\0';
			sys_info->n_os_version = len;
		}
		else {
			sys_info->n_os_version = 0;
		}
		oss.clear();
	}

	{
		const auto device_properties = iware::gpu::device_properties();
		size_t vram = 0;
		size_t blkmax_vram = 0;
		std::vector< lcpp_gpu_info_t*> gpus;

		size_t os_vram = 0;

		for (auto it = device_properties.cbegin(), end = device_properties.cend(); it != end; it++) {
			const iware::gpu::device_properties_t properties_of_device = *it;
			if (properties_of_device.vendor != iware::gpu::vendor_t::microsoft) {
				lcpp_gpu_info_t* gpuinfo = (lcpp_gpu_info_t*)std::malloc(sizeof(lcpp_gpu_info_t));
				gpuinfo->memory = properties_of_device.memory_size;
				vram += properties_of_device.memory_size;
				blkmax_vram = std::max(properties_of_device.memory_size, blkmax_vram);
				gpuinfo->frequency = properties_of_device.max_frequency;
				int n_device_name = properties_of_device.name.length();
				if (n_device_name > 0) {
					gpuinfo->device_name = (char*)std::calloc(n_device_name + 1, sizeof(char));
					std::memcpy(gpuinfo->device_name, properties_of_device.name.c_str(), n_device_name);
					gpuinfo->device_name[n_device_name] = '\0';
					gpuinfo->n_device_name = n_device_name;
				}
				else {
					gpuinfo->n_device_name = 0;
				}
				const auto gpu_vendor = iware_vendor_name(properties_of_device.vendor);
				int n_vendor = strlen(gpu_vendor);
				if (n_vendor > 0) {
					gpuinfo->vendor = (char*)std::calloc(n_vendor + 1, sizeof(char));
					std::memcpy(gpuinfo->vendor, gpu_vendor, n_vendor);
					gpuinfo->vendor[n_vendor] = '\0';
					gpuinfo->n_vendor = n_vendor;

				}
				else {
					gpuinfo->n_vendor = 0;
				}
				gpus.push_back(gpuinfo);
			}
			else {
				os_vram = properties_of_device.memory_size;
			}
		}
		if (gpus.size() > 0) {
			int n_gpus = gpus.size();
			machine_info->gpuinfo = (lcpp_gpu_info_t**)std::calloc(n_gpus, sizeof(lcpp_gpu_info_t*));
			std::memcpy(machine_info->gpuinfo, gpus.data(), sizeof(gpus));
			machine_info->n_gpuinfo = n_gpus;
		}
		else {
			machine_info->n_gpuinfo = 0;
		}
		machine_info->total_vram = vram - (gpus.size() * os_vram);
		machine_info->blkmax_vram = blkmax_vram - os_vram;
	}
	return machine_info;
}

lcpp_model_info_t* _lcpp_get_model_info(const gguf_context* ctx) {

	lcpp_model_info_t* model_info = (lcpp_model_info_t*)std::malloc(sizeof(lcpp_model_info_t));


	model_info->gguf_version = gguf_get_version(ctx);

	bool has_architecture = false;
	auto keyidx = gguf_find_key(ctx, "general.architecture");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_architecture = len;
			model_info->architecture = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->architecture, key_value, len);
			model_info->architecture[len] = '\0';
			has_architecture = true;
		}
		else {
			model_info->n_architecture = 0;
		}
	}
	else {
		model_info->n_architecture = 0;
	}

	keyidx = gguf_find_key(ctx, "general.name");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_name = len;
			model_info->name = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->name, key_value, len);
			model_info->name[len] = '\0';
		}
		else {
			model_info->n_name = 0;
		}
	}
	else {
		model_info->n_name = 0;
	}

	keyidx = gguf_find_key(ctx, "general.author");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_author = len;
			model_info->author = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->author, key_value, len);
			model_info->author[len] = '\0';
		}
		else {
			model_info->n_author = 0;
		}
	}
	else {
		model_info->n_author = 0;
	}

	keyidx = gguf_find_key(ctx, "general.version");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_version = len;
			model_info->version = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->version, key_value, len);
			model_info->version[len] = '\0';
		}
		else {
			model_info->n_version = 0;
		}
	}
	else {
		model_info->n_version = 0;
	}

	keyidx = gguf_find_key(ctx, "general.organization");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_organization = len;
			model_info->organization = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->organization, key_value, len);
			model_info->organization[len] = '\0';
		}
		else {
			model_info->n_organization = 0;
		}
	}
	else {
		model_info->n_organization = 0;
	}

	keyidx = gguf_find_key(ctx, "general.basename");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_basename = len;
			model_info->basename = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->basename, key_value, len);
			model_info->basename[len] = '\0';
		}
		else {
			model_info->n_basename = 0;
		}
	}
	else {
		model_info->n_basename = 0;
	}

	keyidx = gguf_find_key(ctx, "general.finetune");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_finetune = len;
			model_info->finetune = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->finetune, key_value, len);
			model_info->finetune[len] = '\0';
		}
		else {
			model_info->n_finetune = 0;
		}
	}
	else {
		model_info->n_finetune = 0;
	}

	keyidx = gguf_find_key(ctx, "general.description");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_description = len;
			model_info->description = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->description, key_value, len);
			model_info->description[len] = '\0';
		}
		else {
			model_info->n_description = 0;
		}
	}
	else {
		model_info->n_description = 0;
	}

	keyidx = gguf_find_key(ctx, "general.size_label");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_size_label = len;
			model_info->size_label = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->size_label, key_value, len);
			model_info->size_label[len] = '\0';
		}
		else {
			model_info->n_size_label = 0;
		}
	}
	else {
		model_info->n_size_label = 0;
	}

	keyidx = gguf_find_key(ctx, "general.license");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_license = len;
			model_info->license = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->license, key_value, len);
			model_info->license[len] = '\0';
		}
		else {
			model_info->n_license = 0;
		}
	}
	else {
		model_info->n_license = 0;
	}

	keyidx = gguf_find_key(ctx, "general.license.link");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_license_link = len;
			model_info->license_link = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->license_link, key_value, len);
			model_info->license_link[len] = '\0';
		}
		else {
			model_info->n_license_link = 0;
		}
	}
	else {
		model_info->n_license_link = 0;
	}

	keyidx = gguf_find_key(ctx, "general.url");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_url = len;
			model_info->url = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->url, key_value, len);
			model_info->url[len] = '\0';
		}
		else {
			model_info->n_url = 0;
		}
	}
	else {
		model_info->n_url = 0;
	}

	keyidx = gguf_find_key(ctx, "general.doi");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_doi = len;
			model_info->doi = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->doi, key_value, len);
			model_info->doi[len] = '\0';
		}
		else {
			model_info->n_doi = 0;
		}
	}
	else {
		model_info->n_doi = 0;
	}

	keyidx = gguf_find_key(ctx, "general.uuid");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_uuid = len;
			model_info->uuid = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->uuid, key_value, len);
			model_info->uuid[len] = '\0';
		}
		else {
			model_info->n_uuid = 0;
		}
	}
	else {
		model_info->n_uuid = 0;
	}

	keyidx = gguf_find_key(ctx, "general.repo_url");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value)) {
			size_t len = strlen(key_value);
			model_info->n_repo_url = len;
			model_info->repo_url = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy(model_info->repo_url, key_value, len);
			model_info->repo_url[len] = '\0';
		}
		else {
			model_info->n_repo_url = 0;
		}
	}
	else {
		model_info->n_repo_url = 0;
	}

	keyidx = gguf_find_key(ctx, "general.quantization_version");

	if (keyidx != -1) {
		auto _type = gguf_get_kv_type(ctx, keyidx);
		switch (_type) {
		case GGUF_TYPE_UINT8:
			model_info->quantization_version = gguf_get_val_u8(ctx, keyidx);
			break;
		case GGUF_TYPE_INT8:
			model_info->quantization_version = gguf_get_val_i8(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT16:
			model_info->quantization_version = gguf_get_val_u16(ctx, keyidx);
			break;
		case GGUF_TYPE_INT16:
			model_info->quantization_version = gguf_get_val_i16(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT32:
			model_info->quantization_version = gguf_get_val_u32(ctx, keyidx);
			break;
		case GGUF_TYPE_INT32:
			model_info->quantization_version = gguf_get_val_i32(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT64:
			model_info->quantization_version = gguf_get_val_u64(ctx, keyidx);
			break;
		case GGUF_TYPE_INT64:
			model_info->quantization_version = gguf_get_val_i64(ctx, keyidx);
			break;
		default:
			model_info->quantization_version = 0;
			break;
		}

	}
	else {
		model_info->quantization_version = 0;
	}

	keyidx = gguf_find_key(ctx, "general.alignment");

	if (keyidx != -1) {
		auto _type = gguf_get_kv_type(ctx, keyidx);
		switch (_type) {
		case GGUF_TYPE_UINT8:
			model_info->alignment = gguf_get_val_u8(ctx, keyidx);
			break;
		case GGUF_TYPE_INT8:
			model_info->alignment = gguf_get_val_i8(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT16:
			model_info->alignment = gguf_get_val_u16(ctx, keyidx);
			break;
		case GGUF_TYPE_INT16:
			model_info->alignment = gguf_get_val_i16(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT32:
			model_info->alignment = gguf_get_val_u32(ctx, keyidx);
			break;
		case GGUF_TYPE_INT32:
			model_info->alignment = gguf_get_val_i32(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT64:
			model_info->alignment = gguf_get_val_u64(ctx, keyidx);
			break;
		case GGUF_TYPE_INT64:
			model_info->alignment = gguf_get_val_i64(ctx, keyidx);
			break;
		default:
			model_info->alignment = 0;
			break;
		}
	}
	else {
		model_info->alignment = 0;
	}

	keyidx = gguf_find_key(ctx, "general.file_type");

	if (keyidx != -1) {
		auto _type = gguf_get_kv_type(ctx, keyidx);
		switch (_type) {
		case GGUF_TYPE_UINT8:
			model_info->file_type = gguf_get_val_u8(ctx, keyidx);
			break;
		case GGUF_TYPE_INT8:
			model_info->file_type = gguf_get_val_i8(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT16:
			model_info->file_type = gguf_get_val_u16(ctx, keyidx);
			break;
		case GGUF_TYPE_INT16:
			model_info->file_type = gguf_get_val_i16(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT32:
			model_info->file_type = gguf_get_val_u32(ctx, keyidx);
			break;
		case GGUF_TYPE_INT32:
			model_info->file_type = gguf_get_val_i32(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT64:
			model_info->file_type = gguf_get_val_u64(ctx, keyidx);
			break;
		case GGUF_TYPE_INT64:
			model_info->file_type = gguf_get_val_i64(ctx, keyidx);
			break;
		default:
			model_info->file_type = -1;
			break;
		}

	}
	else {
		model_info->file_type = -1;
	}

	keyidx = gguf_find_key(ctx, "split.count");

	if (keyidx != -1) {
		auto _type = gguf_get_kv_type(ctx, keyidx);
		switch (_type) {
		case GGUF_TYPE_UINT8:
			model_info->split_count = gguf_get_val_u8(ctx, keyidx);
			break;
		case GGUF_TYPE_INT8:
			model_info->split_count = gguf_get_val_i8(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT16:
			model_info->split_count = gguf_get_val_u16(ctx, keyidx);
			break;
		case GGUF_TYPE_INT16:
			model_info->split_count = gguf_get_val_i16(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT32:
			model_info->split_count = gguf_get_val_u32(ctx, keyidx);
			break;
		case GGUF_TYPE_INT32:
			model_info->split_count = gguf_get_val_i32(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT64:
			model_info->split_count = gguf_get_val_u64(ctx, keyidx);
			break;
		case GGUF_TYPE_INT64:
			model_info->split_count = gguf_get_val_i64(ctx, keyidx);
			break;
		default:
			model_info->split_count = 0;
			break;
		}
	}
	else {
		model_info->split_count = 0;
	}

	keyidx = gguf_find_key(ctx, "split.tensors.count");
	if (keyidx != -1) {
		auto _type = gguf_get_kv_type(ctx, keyidx);
		switch (_type) {
		case GGUF_TYPE_UINT8:
			model_info->split_tensor_count = gguf_get_val_u8(ctx, keyidx);
			break;
		case GGUF_TYPE_INT8:
			model_info->split_tensor_count = gguf_get_val_i8(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT16:
			model_info->split_tensor_count = gguf_get_val_u16(ctx, keyidx);
			break;
		case GGUF_TYPE_INT16:
			model_info->split_tensor_count = gguf_get_val_i16(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT32:
			model_info->split_tensor_count = gguf_get_val_u32(ctx, keyidx);
			break;
		case GGUF_TYPE_INT32:
			model_info->split_tensor_count = gguf_get_val_i32(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT64:
			model_info->split_tensor_count = gguf_get_val_u64(ctx, keyidx);
			break;
		case GGUF_TYPE_INT64:
			model_info->split_tensor_count = gguf_get_val_i64(ctx, keyidx);
			break;
		default:
			model_info->split_tensor_count = 0;
			break;
		}

	}
	else {
		model_info->split_tensor_count = 0;
	}

	if (has_architecture) {

		std::string prefix(model_info->architecture);

		keyidx = gguf_find_key(ctx, (prefix + ".context_length").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->context_length = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->context_length = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->context_length = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->context_length = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->context_length = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->context_length = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->context_length = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->context_length = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->context_length = 0;
				break;
			}
		}
		else {
			model_info->context_length = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".embedding_length").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->embedding_length = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->embedding_length = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->embedding_length = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->embedding_length = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->embedding_length = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->embedding_length = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->embedding_length = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->embedding_length = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->embedding_length = 0;
				break;
			}
		}
		else {
			model_info->embedding_length = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".block_count").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->block_count = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->block_count = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->block_count = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->block_count = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->block_count = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->block_count = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->block_count = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->block_count = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->block_count = 0;
				break;
			}
		}
		else {
			model_info->block_count = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".feed_forward_length").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->feed_forward_length = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->feed_forward_length = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->feed_forward_length = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->feed_forward_length = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->feed_forward_length = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->feed_forward_length = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->feed_forward_length = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->feed_forward_length = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->feed_forward_length = 0;
				break;
			}
		}
		else {
			model_info->feed_forward_length = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".use_parallel_residual").c_str());

		if (keyidx != -1) {
			model_info->use_parallel_residual = gguf_get_val_bool(ctx, keyidx) ? 1 : 0;
		}
		else {
			model_info->use_parallel_residual = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".expert_count").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->expert_count = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->expert_count = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->expert_count = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->expert_count = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->expert_count = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->expert_count = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->expert_count = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->expert_count = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->expert_count = 0;
				break;
			}
		}
		else {
			model_info->expert_count = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".expert_used_count").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->expert_used_count = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->expert_used_count = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->expert_used_count = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->expert_used_count = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->expert_used_count = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->expert_used_count = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->expert_used_count = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->expert_used_count = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->expert_used_count = 0;
				break;
			}
		}
		else {
			model_info->expert_used_count = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.head_count").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->attention_head_count = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_head_count = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_head_count = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_head_count = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_head_count = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_head_count = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_head_count = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_head_count = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_head_count = 0;
				break;
			}
		}
		else {
			model_info->attention_head_count = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.head_count_kv").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->attention_head_count_kv = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_head_count_kv = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_head_count_kv = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_head_count_kv = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_head_count_kv = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_head_count_kv = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_head_count_kv = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_head_count_kv = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_head_count_kv = 0;
				break;
			}
		}
		else {
			model_info->attention_head_count_kv = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.max_alibi_bias").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_FLOAT32:
				model_info->attention_max_alibi_bias = gguf_get_val_f32(ctx, keyidx);
				break;
			case GGUF_TYPE_FLOAT64:
				model_info->attention_max_alibi_bias = gguf_get_val_f64(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT8:
				model_info->attention_max_alibi_bias = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_max_alibi_bias = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_max_alibi_bias = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_max_alibi_bias = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_max_alibi_bias = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_max_alibi_bias = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_max_alibi_bias = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_max_alibi_bias = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_max_alibi_bias = 0;
				break;
			}
		}
		else {
			model_info->attention_max_alibi_bias = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.clamp_kqv").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_FLOAT32:
				model_info->attention_clamp_kqv = gguf_get_val_f32(ctx, keyidx);
				break;
			case GGUF_TYPE_FLOAT64:
				model_info->attention_clamp_kqv = gguf_get_val_f64(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT8:
				model_info->attention_clamp_kqv = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_clamp_kqv = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_clamp_kqv = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_clamp_kqv = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_clamp_kqv = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_clamp_kqv = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_clamp_kqv = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_clamp_kqv = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_clamp_kqv = 0;
				break;
			}
		}
		else {
			model_info->attention_clamp_kqv = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.layer_norm_epsilon").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_FLOAT32:
				model_info->attention_layer_norm_epsilon = gguf_get_val_f32(ctx, keyidx);
				break;
			case GGUF_TYPE_FLOAT64:
				model_info->attention_layer_norm_epsilon = gguf_get_val_f64(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT8:
				model_info->attention_layer_norm_epsilon = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_layer_norm_epsilon = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_layer_norm_epsilon = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_layer_norm_epsilon = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_layer_norm_epsilon = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_layer_norm_epsilon = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_layer_norm_epsilon = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_layer_norm_epsilon = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_layer_norm_epsilon = 0;
				break;
			}
		}
		else {
			model_info->attention_layer_norm_epsilon = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.layer_norm_rms_epsilon").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_FLOAT32:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_f32(ctx, keyidx);
				break;
			case GGUF_TYPE_FLOAT64:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_f64(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT8:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_layer_norm_rms_epsilon = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_layer_norm_rms_epsilon = 0;
				break;
			}
		}
		else {
			model_info->attention_layer_norm_rms_epsilon = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.key_length").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->attention_key_length = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_key_length = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_key_length = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_key_length = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_key_length = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_key_length = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_key_length = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_key_length = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_key_length = 0;
				break;
			}
		}
		else {
			model_info->attention_key_length = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".attention.value_length").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->attention_value_length = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->attention_value_length = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->attention_value_length = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->attention_value_length = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->attention_value_length = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->attention_value_length = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->attention_value_length = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->attention_value_length = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->attention_value_length = 0;
				break;
			}
		}
		else {
			model_info->attention_value_length = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".rope.dimension_count").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->rope_dimension_count = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->rope_dimension_count = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->rope_dimension_count = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->rope_dimension_count = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->rope_dimension_count = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->rope_dimension_count = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->rope_dimension_count = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->rope_dimension_count = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->rope_dimension_count = 0;
				break;
			}
		}
		else {
			model_info->rope_dimension_count = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".rope.freq_base").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_FLOAT32:
				model_info->rope_freq_base = gguf_get_val_f32(ctx, keyidx);
				break;
			case GGUF_TYPE_FLOAT64:
				model_info->rope_freq_base = gguf_get_val_f64(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT8:
				model_info->rope_freq_base = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->rope_freq_base = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->rope_freq_base = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->rope_freq_base = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->rope_freq_base = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->rope_freq_base = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->rope_freq_base = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->rope_freq_base = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->rope_freq_base = 0;
				break;
			}
		}
		else {
			model_info->rope_freq_base = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".rope.scaling.type").c_str());

		if (keyidx != -1) {
			const char* key_value = gguf_get_val_str(ctx, keyidx);
			if (key_value != nullptr && strlen(key_value)) {
				size_t len = strlen(key_value);
				model_info->n_rope_scaling_type = len;
				model_info->rope_scaling_type = (char*)std::calloc(len + 1, sizeof(char));
				std::memcpy(model_info->rope_scaling_type, key_value, len);
				model_info->rope_scaling_type[len] = '\0';
			}
			else {
				model_info->n_rope_scaling_type = 0;
			}
		}
		else {
			model_info->n_rope_scaling_type = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".rope.scaling.factor").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_FLOAT32:
				model_info->rope_scaling_factor = gguf_get_val_f32(ctx, keyidx);
				break;
			case GGUF_TYPE_FLOAT64:
				model_info->rope_scaling_factor = gguf_get_val_f64(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT8:
				model_info->rope_scaling_factor = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->rope_scaling_factor = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->rope_scaling_factor = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->rope_scaling_factor = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->rope_scaling_factor = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->rope_scaling_factor = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->rope_scaling_factor = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->rope_scaling_factor = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->rope_scaling_factor = 0;
				break;
			}
		}
		else {
			model_info->rope_scaling_factor = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".rope.scaling.original_context_length").c_str());

		if (keyidx != -1) {
			auto _type = gguf_get_kv_type(ctx, keyidx);
			switch (_type) {
			case GGUF_TYPE_UINT8:
				model_info->rope_original_context_length = gguf_get_val_u8(ctx, keyidx);
				break;
			case GGUF_TYPE_INT8:
				model_info->rope_original_context_length = gguf_get_val_i8(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT16:
				model_info->rope_original_context_length = gguf_get_val_u16(ctx, keyidx);
				break;
			case GGUF_TYPE_INT16:
				model_info->rope_original_context_length = gguf_get_val_i16(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT32:
				model_info->rope_original_context_length = gguf_get_val_u32(ctx, keyidx);
				break;
			case GGUF_TYPE_INT32:
				model_info->rope_original_context_length = gguf_get_val_i32(ctx, keyidx);
				break;
			case GGUF_TYPE_UINT64:
				model_info->rope_original_context_length = gguf_get_val_u64(ctx, keyidx);
				break;
			case GGUF_TYPE_INT64:
				model_info->rope_original_context_length = gguf_get_val_i64(ctx, keyidx);
				break;
			default:
				model_info->rope_original_context_length = 0;
				break;
			}
		}
		else {
			model_info->rope_original_context_length = 0;
		}

		keyidx = gguf_find_key(ctx, (prefix + ".rope.scaling.finetuned").c_str());

		if (keyidx != -1) {
			model_info->rope_scaling_finetuned = gguf_get_val_bool(ctx, keyidx) ? 1 : 0;
		}
		else {
			model_info->rope_scaling_finetuned = 0;
		}

	}
	else {
		model_info->context_length = 0;
		model_info->embedding_length = 0;
		model_info->block_count = 0;
		model_info->feed_forward_length = 0;
		model_info->use_parallel_residual = 0;
		model_info->expert_count = 0;
		model_info->expert_used_count = 0;
		model_info->attention_head_count = 0;
		model_info->attention_head_count_kv = 0;
		model_info->attention_max_alibi_bias = 0;
		model_info->attention_clamp_kqv = FLT_MAX;
		model_info->attention_layer_norm_epsilon = FLT_EPSILON;
		model_info->attention_layer_norm_rms_epsilon = FLT_EPSILON;
		model_info->attention_key_length = 0;
		model_info->attention_value_length = 0;
		model_info->rope_dimension_count = 0;
		model_info->rope_freq_base = 0;
		model_info->n_rope_scaling_type = 0;
		model_info->rope_scaling_factor = 0;
		model_info->rope_original_context_length = 0;
		model_info->rope_scaling_finetuned = 0;
	}
	return model_info;
}

std::pair<std::string, int> lcpp_get_model_file(const char* model_file) {
	std::regex pattern("(\\d{5})-of-(\\d{5})\\.gguf$");
	std::smatch sm;
	std::string target(model_file);
	std::ostringstream oss;
	int splits = 0;
	if (std::regex_search(target, sm, pattern)) {
		int offset = sm.position();
		auto split_string = target.substr(offset + 9, 5);
		auto base_string = target.substr(0, target.length() - offset);
		splits = atoi(split_string.c_str());
		oss << base_string << "00001-of-" << split_string << ".gguf";
	}
	else {
		oss << model_file;
	}
	return std::make_pair(oss.str(), splits);
}

lcpp_model_info_t* lcpp_get_model_info(const char* model_file) {
	auto _file = lcpp_get_model_file(model_file);

	gguf_init_params_t gguf_params;

	gguf_params.no_alloc = true;

	gguf_params.ctx = nullptr;

	auto ctx = gguf_init_from_file(_file.first.c_str(), gguf_params);

	lcpp_model_info_t* result = _lcpp_get_model_info(ctx);
	gguf_free(ctx);
	return result;
}

static float sizeof_ggml_type(ggml_type type) {
	static constexpr double ONE_EIGHT_BYTE = 0.125 * sizeof(char);
	static constexpr double QUARTER_BYTE = 0.25 * sizeof(char);
	static constexpr double THREE_EIGHTS_BYTE = 0.325 * sizeof(char);
	static constexpr double HALF_BYTE = 0.5 * sizeof(char);
	static constexpr double FIVE_EIGHTS_BYTE = 0.625 * sizeof(char);
	static constexpr double THREE_QUARTER_BYTE = 0.75 * sizeof(char);
	static constexpr double FULL_BYTE = sizeof(char);
	static constexpr double TWO_BYTE = 2.0 * sizeof(char);
	static constexpr double FOUR_BYTE = 4.0 * sizeof(char);
	static constexpr double EIGHT_BYTE = 8.0 * sizeof(char);

	switch (type) {
	case GGML_TYPE_F32:
	case GGML_TYPE_I32:
		return FOUR_BYTE;
	case GGML_TYPE_F16:
	case GGML_TYPE_I16:
	case GGML_TYPE_BF16:
		return TWO_BYTE;
	case GGML_TYPE_Q4_0:
	case GGML_TYPE_Q4_1:
	case GGML_TYPE_Q4_K:
	case GGML_TYPE_IQ4_NL:
	case GGML_TYPE_IQ4_XS:
	case GGML_TYPE_MXFP4:
		return HALF_BYTE;
	case GGML_TYPE_Q5_0:
	case GGML_TYPE_Q5_1:
	case GGML_TYPE_Q5_K:
		return FIVE_EIGHTS_BYTE;
	case GGML_TYPE_Q8_0:
	case GGML_TYPE_Q8_1:
	case GGML_TYPE_Q8_K:
	case GGML_TYPE_I8:
		return FULL_BYTE;
	case GGML_TYPE_Q2_K:
	case GGML_TYPE_IQ2_XXS:
	case GGML_TYPE_IQ2_XS:
	case GGML_TYPE_IQ2_S:
	case GGML_TYPE_TQ2_0:
		return QUARTER_BYTE;
	case GGML_TYPE_Q3_K:
	case GGML_TYPE_IQ3_XXS:
	case GGML_TYPE_IQ3_S:
		return THREE_EIGHTS_BYTE;
	case GGML_TYPE_Q6_K:
		return THREE_QUARTER_BYTE;
	case GGML_TYPE_IQ1_S:
	case GGML_TYPE_IQ1_M:
	case GGML_TYPE_TQ1_0:
		return ONE_EIGHT_BYTE;
	case GGML_TYPE_I64:
	case GGML_TYPE_F64:
		return EIGHT_BYTE;
	default:
		return FULL_BYTE;
	}
}


static std::regex EXPERTS_LAYER_REGEX = std::regex("_(ch|)exps(\\.bias|\\.weight|)$");

std::pair<size_t, size_t> llm_model_ram(const gguf_context* ctx) {
	// tensor info
	const int n_tensors = gguf_get_n_tensors(ctx);
	size_t vram = 0;
	size_t v_experts = 0;

	for (int i = 0; i < n_tensors; ++i) {
		const char* name = gguf_get_tensor_name(ctx, i);
		const size_t size = gguf_get_tensor_size(ctx, i);
		const size_t offset = gguf_get_tensor_offset(ctx, i);
		ggml_type type = gguf_get_tensor_type(ctx, i);
		size_t sz = size * sizeof_ggml_type(type);
		vram += sz;
		std::string layer(name);
		if (std::regex_search(layer, EXPERTS_LAYER_REGEX)) {
			v_experts += sz;
		}
	}
	return std::make_pair(vram, v_experts);
}

std::vector<std::string> _llm_model_file_list(const char* model_path) {

	auto _file = lcpp_get_model_file(model_path);

	std::vector<std::string> filelist;

	if (_file.second > 0) {
		std::filesystem::path file_path(_file.first);
		auto parent_path = file_path.parent_path().generic_string();
		int n_shards = _file.second;
		auto base_name = _file.first.substr(0, _file.first.length() - 19);
		std::ostringstream oss(std::ios_base::out | std::ios_base::app);
		oss.str("");
		oss << std::setfill('0') << std::setw(5) << n_shards;
		std::string shard_total_string = oss.str();
		oss.clear();
		std::ostringstream fn_oss(std::ios_base::out | std::ios_base::app);
		for (int i = 0; i < n_shards; i++) {
			oss.str("");
			oss << std::setfill('0') << std::setw(5) << (i + 1);
			// std::string shard_num_string = oss.str();
			fn_oss.str("");
			fn_oss << base_name << oss.str() << "-of-" << shard_total_string << ".gguf";
			oss.clear();
			std::filesystem::path directory_path(parent_path);
			filelist.push_back(directory_path.append(fn_oss.str()).generic_string());
			fn_oss.clear();
		}

	}
	else {
		filelist.push_back(_file.first);
	}
	return filelist;
}

lcpp_model_rt_t* lcpp_model_details(const char* model_path) {
	auto filelist = _llm_model_file_list(model_path);
	int n_layers = 0, n_head = 0, d_head = 0, n_ctx = 0, n_embd = 0, d_k = 0, d_v = 0, n_experts = 0, n_experts_used = 0;
	size_t vram = 0, v_experts = 0;
	auto result = (lcpp_model_rt_t*)malloc(sizeof(lcpp_model_rt_t));
	if (!filelist.empty()) {
		bool load_info = true;
		for (auto it = filelist.cbegin(), end = filelist.cend(); it != end; it++) {
			auto model_file = *it;
			gguf_init_params_t gguf_params;
			gguf_params.no_alloc = true;
			gguf_params.ctx = nullptr;
			auto ctx = gguf_context_ptr(gguf_init_from_file(model_file.c_str(), gguf_params));
			if (load_info) {
				result->info = _lcpp_get_model_info(ctx.get());
				n_layers = result->info->block_count;
				n_head = result->info->attention_head_count;
				n_ctx = result->info->context_length;
				n_embd = result->info->embedding_length;
				d_k = result->info->attention_key_length;
				d_v = result->info->attention_value_length;
				d_head = result->info->attention_head_count_kv;
				n_experts = result->info->expert_count;
				n_experts_used = result->info->expert_used_count;
			}
			auto ram = llm_model_ram(ctx.get());
			vram += ram.first;
			v_experts += ram.second;
		}
		result->memory = (lcpp_model_mem_t*)malloc(sizeof(lcpp_model_mem_t));
		result->memory->tensor_mem = vram;
		result->memory->mem_experts = v_experts;
	}
	return result;
}



lcpp_sampling_params_t lcpp_sampling_params_defaults() {
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
		/* samplers[8] */
		8,
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
		samplers,
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
		case LCPP_MODEL_FAMILY_GPT_OSS:
		case LCPP_MODEL_FAMILY_SEED_OSS:
		case LCPP_MODEL_FAMILY_GENERIC:
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
            _chat_format.format = COMMON_CHAT_FORMAT_DEEPSEEK_R1;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_DEEPSEEK;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_QWEN:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_DEEPSEEK_R1;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_DEEPSEEK;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_GRANITE:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_GRANITE;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_DEEPSEEK;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_LLAMA:
        {
            _chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_LLAMA_3_X_WITH_BUILTIN_TOOLS : COMMON_CHAT_FORMAT_LLAMA_3_X;
            _chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_AUTO : COMMON_REASONING_FORMAT_NONE;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_MISTRAL:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_MISTRAL_NEMO;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_AUTO;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_PHI:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_GENERIC;
            _chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_GEMMA:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_CONTENT_ONLY;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_NONE;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_GPT_OSS:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_GPT_OSS;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_AUTO;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_SEED_OSS:
        {
            _chat_format.format = COMMON_CHAT_FORMAT_DEEPSEEK_R1;
            _chat_format.reasoning = COMMON_REASONING_FORMAT_DEEPSEEK;
            _chat_format.is_reasoning = is_reasoning;
        }
        break;
	case LCPP_MODEL_FAMILY_GENERIC:
    	{
    		_chat_format.format = COMMON_CHAT_FORMAT_GENERIC;
    		_chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_DEEPSEEK : COMMON_REASONING_FORMAT_NONE;
    		_chat_format.is_reasoning = is_reasoning;
    	}
    	break;
	default:
        {
            _chat_format.format = is_reasoning ? COMMON_CHAT_FORMAT_GENERIC : COMMON_CHAT_FORMAT_CONTENT_ONLY;
            _chat_format.reasoning = is_reasoning ? COMMON_REASONING_FORMAT_AUTO : COMMON_REASONING_FORMAT_NONE;
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
	syntax.reasoning_in_content = format.reasoning == COMMON_REASONING_FORMAT_DEEPSEEK_LEGACY;
	syntax.thinking_forced_open = format.reasoning != COMMON_REASONING_FORMAT_DEEPSEEK;
	syntax.reasoning_format = format.reasoning;
	syntax.parse_tool_calls = format.format != COMMON_CHAT_FORMAT_CONTENT_ONLY;
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
			auto part = (plcpp_common_chat_msg_content_part_t)std::malloc(sizeof(lcpp_common_chat_msg_content_part_t));
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
		_msg->content_parts = (plcpp_common_chat_msg_content_part_t*)std::calloc(sz, sizeof(plcpp_common_chat_msg_content_part_t));
		std::memcpy(parts.data(), _msg->content_parts, sizeof(plcpp_common_chat_msg_content_part_t) * sz);
		_msg->n_content_parts = sz;
	}
	else {
		_msg->content_parts = nullptr;
		_msg->n_content_parts = 0;
	}

	if (!msg.tool_calls.empty()) {
		std::vector<lcpp_common_chat_tool_call_t*> toolcalls(msg.tool_calls.size());
		for (auto it = msg.tool_calls.cbegin(); it != msg.tool_calls.cend(); it++) {
			auto tool_call = *it;
			auto toolcall = (lcpp_common_chat_tool_call_t*)std::malloc(sizeof(lcpp_common_chat_tool_call_t));
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
		std::memcpy(toolcalls.data(), _msg->tool_calls, sizeof(lcpp_common_chat_tool_call_t*) * sz);

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

	auto _sampler = common_sampler_ptr(prompt_args.sampler);

	// helper function to evaluate a prompt and generate a response
	auto generate = [&](const std::string& prompt) {
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "_prompt:generate %s\n", prompt.c_str());
#endif
		std::string response;
		auto _vocab = llama_model_get_vocab(prompt_args.model);

		const bool is_first = llama_memory_seq_pos_max(llama_get_memory(prompt_args.context), 0) == -1;

		// tokenize the prompt
		// auto prompt_tokens = common_tokenize(prompt_args.context, prompt, is_first, true);

		const int n_prompt_tokens = -llama_tokenize(_vocab, prompt.c_str(), prompt.size(), NULL, 0, is_first, true);
		std::vector<llama_token> prompt_tokens(n_prompt_tokens);
		if (llama_tokenize(_vocab, prompt.c_str(), prompt.size(), prompt_tokens.data(), prompt_tokens.size(), is_first, true) < 0) {
			GGML_ABORT("failed to tokenize the prompt\n");
		}

		// prepare a batch for the prompt
		llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
		llama_token new_token_id;

		while (true) {
			// check if we have enough space in the context to evaluate this batch
			int n_ctx = llama_n_ctx(prompt_args.context);
			int n_ctx_used = llama_memory_seq_pos_max(llama_get_memory(prompt_args.context), 0) + 1;
			if (n_ctx_used + batch.n_tokens > n_ctx) {
#if defined(_DEBUG) || defined(DEBUG) 
				fprintf(stderr, "context size exceeded\n");
#endif
				return GGML_EXIT_ABORTED;
			}


			// if (llama_decode(prompt_args.context, batch)) {
			int ret = llama_decode(prompt_args.context, batch);
			if (ret != 0) {
#if defined(_DEBUG) || defined(DEBUG) 
				fprintf(stderr, "failed to decode\n");
#endif
				return GGML_EXIT_ABORTED;
			}

			// sample the next token
			new_token_id = common_sampler_sample(_sampler.get(), prompt_args.context, -1, false);

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
	return _sampling;
}

int lcpp_prompt(const lcpp_sampling_params_t sampling_params, lcpp_common_chat_msg_t** messages, int n_messages) {
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
	args.sampler = common_sampler_init(_model.get(), _lcpp_params_sampling(sampling_params));
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

int _conf(common_params_t cmParams) {

	auto ctxParams = common_context_params_to_llama(cmParams);

	ctxParams.abort_callback = _ggml_abort_callback;
	ctxParams.abort_callback_data = nullptr;
	auto mparams = common_model_params_to_llama(cmParams);
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_conf  %s\n", cmParams.model.path.c_str());
#endif
	_model = llama_model_ptr(llama_model_load_from_file(cmParams.model.path.c_str(), mparams));
	if (_model.get() == nullptr) {
		if (LoadingProgressCallback != nullptr) {
			LcppFloatStruct_t* _float = (LcppFloatStruct_t*)malloc(sizeof(LcppFloatStruct_t));
			_float->value = -1.0f;
			LoadingProgressCallback(_float);
		}
		return EXIT_FAILURE;
	}
	_loaded = true;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stdout, "lcpp_reconfigure finished _load_model \n");
#endif
	_ctx = llama_context_ptr(llama_init_from_model(_model.get(), ctxParams));
	if (_ctx.get() == nullptr) {
		if (LoadingProgressCallback != nullptr) {
			LcppFloatStruct_t* _float = (LcppFloatStruct_t*)malloc(sizeof(LcppFloatStruct_t));
			_float->value = -1.0f;
			LoadingProgressCallback(_float);
		}
		return EXIT_FAILURE;
	}



	cmParams.numa = GGML_NUMA_STRATEGY_DISABLED;

	postprocess_cpu_params(cmParams.cpuparams, nullptr);

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
				if (threadpool_batch) { // Start the non-batch threadpool in the paused state
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
	fprintf(stderr, "lcpp_reconfigure common_chat_templates_init, model is_null: %s  chat_template: %s\n", _model.get() == nullptr ? "true" : "false", cmParams.chat_template.c_str());
#endif
	_chat_templates = common_chat_templates_init(_model.get(), cmParams.chat_template);

	if (LoadingProgressCallback != nullptr) {
		LcppFloatStruct_t* _float = (LcppFloatStruct_t*)malloc(sizeof(LcppFloatStruct_t));
		_float->value = 1.0f;
		LoadingProgressCallback(_float);
	}
	return EXIT_SUCCESS;
}

void lcpp_reset() {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reset()\n");
#endif
	if (_ctx != nullptr) {
		llama_memory_clear(llama_get_memory(_ctx.get()), true);
	}
	_abort = false;
	_cancel = false;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reset::>\n");
#endif
}

void lcpp_unload() {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_lcpp_unload()\n");
#endif
	lcpp_reset();
	if (_ctx != nullptr) {
		llama_detach_threadpool(_ctx.get());
	}
	_chat_templates = nullptr;
	_ctx = nullptr;
	_model = nullptr;
	_loaded = false;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "_lcpp_unload::>\n");
#endif

}

void lcpp_reconfigure(const llama_context_params_t context_params, const lcpp_params_t lcpp_params) {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_reconfigure \n");
#endif

	// only print errors
	llama_log_set([](enum ggml_log_level level, const char* text, void* /* user_data */) {
		if (level >= GGML_LOG_LEVEL_DEBUG) {
			fprintf(stderr, "%s", text);
		}
		}, nullptr);

	if (!_inited.load()) {
		llama_backend_init();
		_inited = true;
	}
	else {
		lcpp_unload();
	}



	GGML_ASSERT(lcpp_params.model_path != nullptr);

	common_params_t params;
	params.model.path = std::string(lcpp_params.model_path);
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "lcpp_reconfigure generated common_params \n");
#endif
		
		params.numa = GGML_NUMA_STRATEGY_DISTRIBUTE;
		lcpp_model_family_t _family = lcpp_params.model_family;
		switch (_family) {
		case LCPP_MODEL_FAMILY_PHI:
		case LCPP_MODEL_FAMILY_MISTRAL:
			params.reasoning_format = COMMON_REASONING_FORMAT_AUTO;
			break;
		case LCPP_MODEL_FAMILY_DEEPSEEK:
		case LCPP_MODEL_FAMILY_GRANITE:
		case LCPP_MODEL_FAMILY_QWEN:
		case LCPP_MODEL_FAMILY_SEED_OSS:
			params.reasoning_format = COMMON_REASONING_FORMAT_DEEPSEEK;
			break;
		case LCPP_MODEL_FAMILY_GENERIC:
		    params.reasoning_format = COMMON_REASONING_FORMAT_AUTO;
            break;
		case LCPP_MODEL_FAMILY_LLAMA:
		case LCPP_MODEL_FAMILY_GPT_OSS:
		case LCPP_MODEL_FAMILY_GEMMA:
		default:
			params.reasoning_format = COMMON_REASONING_FORMAT_NONE;
			break;
		}

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

#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "lcpp_reconfigure finished common_params:>\n");
#endif
	}

	if (lcpp_params.offload_experts) {
		params.tensor_buft_overrides.push_back(llm_ffn_exps_cpu_override());
		params.tensor_buft_overrides.push_back({ nullptr, nullptr });
	}

	_set_use_jinja_by_model_family(lcpp_params.model_family);

	_set_common_format_by_model_family(lcpp_params.model_family, lcpp_params.is_reasoning);

	if (!params.system_prompt.empty()) {
		_system_prompt = std::string(params.system_prompt);
	}

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
	std::memcpy(llama_tokens.data(), tokens, sizeof(int) * n_tokens);

	auto _text = common_detokenize(_ctx.get(), llama_tokens, special);
	int n_text = _text.size();
	text->value = (char*)std::calloc(n_text + 1, sizeof(char));
	std::memcpy(text->value, _text.c_str(), n_text);
	text->value[n_text] = '\0';
	text->length = n_text;
	text->found = n_text > 0;
}



void lcpp_destroy() {
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_destroy()\n");
#endif
	lcpp_unload();
	lcpp_unset_token_stream_callback();
	lcpp_unset_chat_message_callback();
	lcpp_unset_model_load_progress_callback();
	llama_backend_free();
	_inited = false;
#if defined(_DEBUG) || defined(DEBUG)
	fprintf(stderr, "lcpp_destroy::>\n");
#endif

}



void lcpp_free_float(LcppFloatStruct_t* ptr) {
	free(ptr);
}

void lcpp_free_text(LcppTextStruct_t* ptr) {
	if (ptr != nullptr) {
		if (ptr->length > 0) free(ptr->text);
	}
	free(ptr);
}

void lcpp_native_free(void* ptr) {
	free(ptr);
}
