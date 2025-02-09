#include <stdlib.h>
#include <float.h>
#include <filesystem>
#include <string>
#include <cmath>
#include <numeric>
#include <cstring>
#include <regex>
#include <sstream>
#include <string.h>
#include <vector>
#include <set>
#include <cpuinfo.h>
#include <infoware/infoware.hpp>

#include "llamacpp_utils.h"

#include "llamacpp_constants.hpp"

#include "ggml-cpp.h"

typedef struct gguf_init_params gguf_init_params_t;

static std::regex EXPERTS_LAYER_REGEX = std::regex("_(ch|)exps(\\.bias|\\.weight|)$");

void lcpp_free_model_info(lcpp_model_info_t* model_info) {
	if (model_info != nullptr) {
		lcpp_model_info_t val = *model_info;
		if (val.n_architecture > 0) free(val.architecture);
		if (val.n_name > 0) free(val.name);
		if (val.n_author > 0) free(val.author);
		if (val.n_version > 0) free(val.version);
		if (val.n_organization > 0) free(val.organization);
		if (val.n_basename > 0) free(val.basename);
		if (val.n_finetune > 0) free(val.finetune);
		if (val.n_description > 0) free(val.description);
		if (val.n_size_label > 0) free(val.size_label);
		if (val.n_license > 0) free(val.license);
		if (val.n_license_link > 0) free(val.license_link);
		if (val.n_url > 0) free(val.url);
		if (val.n_doi > 0) free(val.uuid);
		if (val.n_repo_url > 0) free(val.repo_url);
		if (val.n_rope_scaling_type > 0) free(val.rope_scaling_type);
		free(model_info);
	}
}

void lcpp_free_model_mem(lcpp_model_mem_t* model_mem) {
	if (model_mem != nullptr) {
		free(model_mem);
	}
}


void lcpp_free_model_rt(lcpp_model_rt_t* model_rt) {
	if (model_rt != nullptr) {
		if ((*model_rt).memory != nullptr) lcpp_free_model_mem((*model_rt).memory);
		if ((*model_rt).info != nullptr) lcpp_free_model_info((*model_rt).info);
		free(model_rt);
	}
}

void lcpp_free_machine_info(lcpp_machine_info_t* mach_info) {
	if (mach_info != nullptr) {
		lcpp_machine_info_t _mach = *mach_info;
		if (_mach.sysinfo != nullptr) {
			lcpp_system_info_t _sys = *(_mach.sysinfo);
			if (_sys.n_os_name > 0) free(_sys.os_name);
			if (_sys.n_os_version > 0) free(_sys.os_version);
			if (_sys.n_full_name > 0) free(_sys.full_name);
			free(_mach.sysinfo);
		}
		if (mach_info->cpuinfo != nullptr) {
			lcpp_cpu_info_t _cpu = *(_mach.cpuinfo);
			if (_cpu.n_chipset_vendor > 0) { free(_cpu.chipset_vendor); }
			if (_cpu.n_vendor_id > 0) { free(_cpu.vendor_id); }
			if (_cpu.n_processor_name > 0) { free(_cpu.processor_name); }
			if (_cpu.n_uarch > 0) { free(_cpu.uarch); }
			free(_mach.cpuinfo);
		}
		if (_mach.gpuinfo != nullptr) {
			for (int i = 0, n = _mach.n_gpuinfo; i < n; i++) {
				lcpp_gpu_info_t* _gpu = _mach.gpuinfo[i];
				if (_gpu != nullptr) {
					lcpp_gpu_info_t _val = *_gpu;
					if (_val.n_vendor > 0) { free(_val.vendor); }
					if (_val.n_device_name > 0) { free(_val.device_name); }
					free(_gpu);
				}
			}
			free(_mach.gpuinfo);
		}
		if (_mach.meminfo != nullptr) {
			free(_mach.meminfo);
		}
		free(mach_info);
	}
}



lcpp_machine_info_t* lcpp_get_machine_info() {
	lcpp_machine_info_t* machine_info = (lcpp_machine_info_t*) std::malloc(sizeof(lcpp_machine_info_t));
	(*machine_info).cpuinfo = (lcpp_cpu_info_t*) std::malloc(sizeof(lcpp_cpu_info_t));
	(*machine_info).meminfo = (lcpp_memory_info_t*) std::malloc(sizeof(lcpp_memory_info_t));
	(*machine_info).sysinfo = (lcpp_system_info_t*) std::malloc(sizeof(lcpp_system_info_t));
	lcpp_machine_info_t _mach = *machine_info;
	const auto quantities = iware::cpu::quantities();

	(*_mach.cpuinfo).endianess = iware_endianness_name(iware::cpu::endianness());
	(*_mach.cpuinfo).frequency = iware::cpu::frequency();

	iware::system::memory_t memory = iware::system::memory();
	(*_mach.meminfo).physical_mem = memory.physical_total;
	(*_mach.meminfo).virtual_mem = memory.virtual_total;

	std::string vendor_id_string = iware::cpu::vendor_id();
	if (vendor_id_string.length() > 0) {
		int len = vendor_id_string.length();
		(*_mach.cpuinfo).vendor_id = (char*)std::calloc(len + 1, sizeof(char));
		std::memcpy((*_mach.cpuinfo).vendor_id, vendor_id_string.c_str(), len);
		(*_mach.cpuinfo).vendor_id[len] = '\0';
		(*_mach.cpuinfo).n_vendor_id = len;
	}
	else {
		(*_mach.cpuinfo).n_vendor_id = 0;
	}

	std::string processor_name_string = iware::cpu::model_name();
	if (processor_name_string.length() > 0) {
		int len = processor_name_string.length();
		(*_mach.cpuinfo).processor_name = (char*)std::calloc(len + 1, sizeof(char));
		std::memcpy((*_mach.cpuinfo).processor_name, processor_name_string.c_str(), len);
		(*_mach.cpuinfo).processor_name[len] = '\0';
		(*_mach.cpuinfo).n_processor_name = len;
	}
	else {
		(*_mach.cpuinfo).n_processor_name = 0;
	}
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
			(*_mach.cpuinfo).uarch = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy((*_mach.cpuinfo).uarch, uarch_string.c_str(), len);
			(*_mach.cpuinfo).uarch[len] = '\0';
			(*_mach.cpuinfo).n_uarch = len;
		}
		else {
			(*_mach.cpuinfo).n_uarch = 0;
		}

		std::set<std::string> _chipset_vendors;
		for (uint32_t i = 0; i < cpuinfo_get_clusters_count(); i++) {
			const struct cpuinfo_cluster* cluster = cpuinfo_get_cluster(0);
			const char* vendor_string = cpuinfo_vendor_to_string(cluster->vendor);
			_chipset_vendors.insert(vendor_string);
		}

		if (_chipset_vendors.size() > 0) {
			std::ostringstream vendor_oss;
			for (std::string vendor : _chipset_vendors) {
				if (!vendor_oss.str().empty()) vendor_oss << ",";
				vendor_oss << vendor;
			}
			std::string chipset_vendor_string = vendor_oss.str();
			int len = chipset_vendor_string.length();
			(*_mach.cpuinfo).chipset_vendor = (char*)std::calloc(len + 1, sizeof(char));
			std::memcpy((*_mach.cpuinfo).chipset_vendor, chipset_vendor_string.c_str(), len);
			(*_mach.cpuinfo).chipset_vendor[len] = '\0';
			(*_mach.cpuinfo).n_chipset_vendor = len;
		}
		else {
			(*_mach.cpuinfo).n_chipset_vendor = 0;
		}

		(*_mach.cpuinfo).num_processors = cpuinfo_get_processors_count();
		(*_mach.cpuinfo).num_cores = cpuinfo_get_cores_count();
		(*_mach.cpuinfo).num_clusters = cpuinfo_get_clusters_count();
	}
	else {
		(*_mach.cpuinfo).num_processors = quantities.logical;
		(*_mach.cpuinfo).num_cores = quantities.physical;
		(*_mach.cpuinfo).num_clusters = quantities.packages;
		(*_mach.cpuinfo).n_uarch = 0;
		(*_mach.cpuinfo).n_chipset_vendor = 0;
	}
	iware::system::OS_info_t OS_info = iware::system::OS_info();
	if (OS_info.name.length() > 0) {
		int len = OS_info.name.length();
		(*_mach.sysinfo).os_name = (char*)std::calloc(len + 1, sizeof(char));
		std::memcpy((*_mach.sysinfo).os_name, OS_info.name.c_str(), len);
		(*_mach.sysinfo).os_name[len] = '\0';
		(*_mach.sysinfo).n_os_name = len;
	}
	else {
		(*_mach.sysinfo).n_os_name = 0;
	}

	if (OS_info.full_name.length() > 0) {
		int len = OS_info.full_name.length();
		(*_mach.sysinfo).full_name = (char*)std::calloc(len + 1, sizeof(char));
		std::memcpy((*_mach.sysinfo).full_name, OS_info.full_name.c_str(), len);
		(*_mach.sysinfo).full_name[len] = '\0';
		(*_mach.sysinfo).n_full_name = len;
	}
	else {
		(*_mach.sysinfo).n_full_name = 0;
	}

	std::ostringstream oss(std::ios_base::out | std::ios_base::app);
	oss.str("");
	oss << OS_info.major << '.' << OS_info.minor << '.' << OS_info.patch << " build " << OS_info.build_number;
	std::string os_version = oss.str();
	if (os_version.length() > 0) {
		int len = os_version.length();
		(*_mach.sysinfo).os_version = (char*)std::calloc(len + 1, sizeof(char));
		std::memcpy((*_mach.sysinfo).os_version, os_version.c_str(), len);
		(*_mach.sysinfo).os_version[len] = '\0';
		(*_mach.sysinfo).n_os_version = len;
	}
	else {
		(*_mach.sysinfo).n_os_version = 0;
	}
	oss.clear();


	{
		std::vector<iware::gpu::device_properties_t> device_properties = iware::gpu::device_properties();
		size_t vram = 0;
		size_t blkmax_vram = 0;
		std::vector< lcpp_gpu_info_t*> gpus;

		size_t os_vram = 0;
		int32_t gpu_idx = 0;
		for (auto it = device_properties.cbegin(), end = device_properties.cend(); it != end; it++, gpu_idx++) {
			const iware::gpu::device_properties_t properties_of_device = *it;
			if (properties_of_device.vendor != iware::gpu::vendor_t::microsoft) {
				lcpp_gpu_info_t* gpuinfo = (lcpp_gpu_info_t*) std::malloc(sizeof(lcpp_gpu_info_t));
				(*gpuinfo).type = properties_of_device.vendor == iware::gpu::vendor_t::nvidia 
					|| properties_of_device.vendor == iware::gpu::vendor_t::amd 
					|| properties_of_device.vendor == iware::gpu::vendor_t::intel 
					? 1 : 2;
				(*gpuinfo).index = gpu_idx;
				(*gpuinfo).memory = properties_of_device.memory_size;
				vram += properties_of_device.memory_size;
				blkmax_vram = std::max(properties_of_device.memory_size, blkmax_vram);
				(*gpuinfo).frequency = properties_of_device.max_frequency;
				int n_device_name = properties_of_device.name.length();
				if (n_device_name > 0) {
					(*gpuinfo).device_name = (char*)std::calloc(n_device_name + 1, sizeof(char));
					std::memcpy((*gpuinfo).device_name, properties_of_device.name.c_str(), n_device_name);
					(*gpuinfo).device_name[n_device_name] = '\0';
					(*gpuinfo).n_device_name = n_device_name;
				}
				else {
					(*gpuinfo).n_device_name = 0;
				}
				std::string gpu_vendor(iware_vendor_name(properties_of_device.vendor));
				int n_vendor = gpu_vendor.length();
				if (n_vendor > 0) {
					(*gpuinfo).vendor = (char*)std::calloc(n_vendor + 1, sizeof(char));
					std::memcpy((*gpuinfo).vendor, gpu_vendor.c_str(), n_vendor);
					(*gpuinfo).vendor[n_vendor] = '\0';
					(*gpuinfo).n_vendor = n_vendor;

				}
				else {
					(*gpuinfo).n_vendor = 0;
				}
				gpus.push_back(gpuinfo);
			}
			else {
				os_vram = properties_of_device.memory_size;
			}
		}
		if (gpus.size() > 0) {
			int n_gpus = gpus.size();
			for (lcpp_gpu_info_t* gpu : gpus) {
				gpu->memory -= os_vram;
				if (gpu->memory < 536870913) { // less than 512 MiB + 1 byte assume iGPU
					gpu->type = 0;
				}
			}

			machine_info->gpuinfo = (lcpp_gpu_info_t**) std::calloc(n_gpus, sizeof(lcpp_gpu_info_t*));
			std::memcpy((*machine_info).gpuinfo, gpus.data(), sizeof(lcpp_gpu_info_t*) * n_gpus);
			(*machine_info).n_gpuinfo = n_gpus;
		}
		else {
			(*machine_info).n_gpuinfo = 0;
		}
		(*machine_info).total_vram = vram - (gpus.size() * os_vram);
		(*machine_info).blkmax_vram = blkmax_vram - os_vram;
	}
	return machine_info;
}

typedef struct GgufKVTypeStruct {
	gguf_type type;
	union value_t {
		uint8_t u8;
		int8_t i8;
		uint16_t u16;
		int16_t i16;
		uint32_t u32;
		int32_t i32;
		uint64_t u64;
		int64_t i64;
		int _default;
	} value;

	void* getValue() {
		switch (type) {
		case GGUF_TYPE_UINT8: return &(value.u8);
		case GGUF_TYPE_INT8: return &(value.i8);
		case GGUF_TYPE_UINT16: return &(value.u16);
		case GGUF_TYPE_INT16: return &(value.i16);
		case GGUF_TYPE_UINT32: return &(value.u32);
		case GGUF_TYPE_INT32: return &(value.i32);
		case GGUF_TYPE_UINT64: return &(value.u64);
		case GGUF_TYPE_INT64: return &(value.i64);
		default: return &(value._default);
		}
	}
} GgufKVTypeStruct_t;



GgufKVTypeStruct_t get_ggml_kv_type(const gguf_context* ctx, const char* key, int _default) {
	auto keyidx = gguf_find_key(ctx, key);
	GgufKVTypeStruct_t _result;
	if (keyidx != -1) {
		gguf_type _type = gguf_get_kv_type(ctx, keyidx);
		_result.type = _type;
		switch (_type) {
		case GGUF_TYPE_UINT8:

			_result.value.u8 = gguf_get_val_u8(ctx, keyidx);
			break;
		case GGUF_TYPE_INT8:
			_result.value.i8 = gguf_get_val_i8(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT16:
			_result.value.u16 = gguf_get_val_u16(ctx, keyidx);
			break;
		case GGUF_TYPE_INT16:
			_result.value.i16 = gguf_get_val_i16(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT32:
			_result.value.u32 = gguf_get_val_u32(ctx, keyidx);
			break;
		case GGUF_TYPE_INT32:
			_result.value.i32 = gguf_get_val_i32(ctx, keyidx);
			break;
		case GGUF_TYPE_UINT64:
			_result.value.u64 = gguf_get_val_u64(ctx, keyidx);
			break;
		case GGUF_TYPE_INT64:
			_result.value.i64 = gguf_get_val_i64(ctx, keyidx);
			break;
		default:
			_result.value._default = _default;
			break;
		}

	}
	else {
		_result.value._default = _default;
	}
	return _result;
}

lcpp_model_info_t* _lcpp_get_model_info(const gguf_context* ctx) {

	lcpp_model_info_t* model_info = (lcpp_model_info_t*)std::malloc(sizeof(lcpp_model_info_t));


	model_info->gguf_version = gguf_get_version(ctx);

	bool has_architecture = false;
	int64_t keyidx = gguf_find_key(ctx, "general.architecture");

	if (keyidx != -1) {
		const char* key_value = gguf_get_val_str(ctx, keyidx);
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
		if (key_value != nullptr && strlen(key_value) > 0) {
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
			if (key_value != nullptr && strlen(key_value) > 0) {
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
		std::string split_string = target.substr(offset + 9, 5);
		std::string base_string = target.substr(0, target.length() - offset);
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

	std::pair<std::string, int> _file = lcpp_get_model_file(model_path);

	std::vector<std::string> filelist;

	if (_file.second > 0) {
		std::filesystem::path file_path(_file.first);
		std::string parent_path = file_path.parent_path().generic_string();
		int n_shards = _file.second;
		std::string base_name = _file.first.substr(0, _file.first.length() - 19);
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
	std::vector<std::string> filelist = _llm_model_file_list(model_path);
	int n_layers = 0, n_head = 0, d_head = 0, n_ctx = 0, n_embd = 0, d_k = 0, d_v = 0, n_experts = 0, n_experts_used = 0;
	size_t vram = 0, v_experts = 0;
	lcpp_model_rt_t* result = (lcpp_model_rt_t*)malloc(sizeof(lcpp_model_rt_t));
	if (!filelist.empty()) {
		bool load_info = true;
		for (auto it = filelist.cbegin(), end = filelist.cend(); it != end; it++) {
			const std::string model_file = *it;
			gguf_init_params_t gguf_params;
			gguf_params.no_alloc = true;
			gguf_params.ctx = nullptr;
			gguf_context_ptr ctx = gguf_context_ptr(gguf_init_from_file(model_file.c_str(), gguf_params));
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
			std::pair<size_t, size_t> ram = llm_model_ram(ctx.get());
			vram += ram.first;
			v_experts += ram.second;
		}
		(*result).memory = (lcpp_model_mem_t*) malloc(sizeof(lcpp_model_mem_t));
		(*result->memory).tensor_mem = vram;
		(*result->memory).mem_experts = v_experts;
	}
	return result;
}