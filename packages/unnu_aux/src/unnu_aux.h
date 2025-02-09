#ifndef _UNNU_AUX_H
#define _UNNU_AUX_H

#ifdef __cplusplus
	#ifdef WIN32
		#define FFI_PLUGIN_EXPORT extern "C" __declspec(dllexport)
	#else
		#define FFI_PLUGIN_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
	#endif
#else
	#define FFI_PLUGIN_EXPORT extern
#endif

#ifdef __cplusplus
	#include <cstdint>
	#include <cstdbool>
#else // __cplusplus - Objective-C or other C platform
	#include <stdint.h>
	#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C"
{
#endif

typedef enum UnnuAuxConfigValueType : uint8_t {
    UNNU_AUX_CONFIG_BOOL = 0,
    UNNU_AUX_CONFIG_INT = 1,
    UNNU_AUX_CONFIG_LONG = 2,
    UNNU_AUX_CONFIG_FLOAT = 3,
    UNNU_AUX_CONFIG_DOUBLE = 4,
    UNNU_AUX_CONFIG_STRING = 5,
    UNNU_AUX_CONFIG_STR_ARRAY = 6,
    UNNU_AUX_CONFIG_LIST = 7,
    UNNU_AUX_CONFIG_NONE = 8,
} UnnuAuxConfigValueType_t;

typedef union UnnuAuxConfigValue
{
  uint8_t bval;
  int32_t ival;
  int64_t lval;
  float fval;
  double dval;
  size_t zval;
  char *sval;
  void *object;
  struct UnnuAuxConfigList *list;
} UnnuAuxConfigValue_t;

typedef struct UnnuAuxConfigSetting
{
  char *name;
  int32_t n_name;
  UnnuAuxConfigValueType_t type;
  UnnuAuxConfigValue_t value;
  int32_t length;
  struct UnnuAuxConfigSetting* parent;
  struct UnnuAuxConfig* attributes;
} UnnuAuxConfigSetting_t;

typedef struct UnnuAuxConfigList
{
  unsigned int count;
  UnnuAuxConfigSetting_t **elements;
} UnnuAuxConfigList_t;

typedef struct UnnuAuxConfig
{
  UnnuAuxConfigSetting_t *root;
} UnnuAuxConfig_t;

typedef struct UnnuAuxModelSettings {
	char* uri;
	int32_t n_uri;
	char* id;
	int32_t n_id;
	char* type;
	int32_t n_type;
	char* location;
	int32_t n_location;
	char* path;
	int32_t n_path;
	char* sha;
	int32_t n_sha;
} UnnuAuxModelSettings_t;

typedef struct UnnuAuxCorpusSettings {
	char* uri;
	int32_t n_uri;
	char* id;
	int32_t n_id;
	char* path;
	int32_t n_path;
	char* kbase;
	int32_t n_kbase;
	char* sha;
	int32_t n_sha;
} UnnuAuxCorpusSettings_t;

typedef struct UnnuAuxProfileSettings {
	char* uri;
	int32_t n_uri;
	char* id;
	int32_t n_id;
	char* name;
	int32_t n_name;
	char* prompt;
	int32_t n_prompt;
	char* model_id;
	int32_t n_model_id;
	char* corpus_id;
	int32_t n_corpus_id;
} UnnuAuxProfileSettings_t;

typedef struct UnnuAuxConversationSettings {
	char* uri;
	int32_t n_uri;
	char* id;
	int32_t n_id;
	char* summary;
	int32_t n_summary;
	char* profile_id;
	int32_t n_profile_id;
} UnnuAuxConversationSettings_t;

typedef struct UnnuTextStruct {
	char* text;
	int32_t length;
} UnnuTextStruct_t;

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT UnnuTextStruct_t* unnu_aux_hash(const char* path);

FFI_PLUGIN_EXPORT void unnu_aux_free_text(UnnuTextStruct_t* ptr);

FFI_PLUGIN_EXPORT UnnuAuxConfig_t* unnu_aux_load_config(const char* filepath);

FFI_PLUGIN_EXPORT void unnu_aux_update_corpora(const char* filepath);

FFI_PLUGIN_EXPORT int32_t unnu_aux_check_min_hw_specs();

FFI_PLUGIN_EXPORT void unnu_aux_upsert_model_settings(const char* filepath, UnnuAuxModelSettings_t config);
FFI_PLUGIN_EXPORT void unnu_aux_upsert_corpus_settings(const char* filepath, UnnuAuxCorpusSettings_t config);
FFI_PLUGIN_EXPORT void unnu_aux_upsert_profile_settings(const char* filepath, UnnuAuxProfileSettings_t config);
FFI_PLUGIN_EXPORT void unnu_aux_upsert_conversation_settings(const char* filepath, UnnuAuxConversationSettings_t config);

FFI_PLUGIN_EXPORT void unnu_aux_delete_model_settings(const char* filepath, UnnuAuxModelSettings_t config);
FFI_PLUGIN_EXPORT void unnu_aux_delete_corpus_settings(const char* filepath, UnnuAuxCorpusSettings_t config);
FFI_PLUGIN_EXPORT void unnu_aux_delete_profile_settings(const char* filepath, UnnuAuxProfileSettings_t config);
FFI_PLUGIN_EXPORT void unnu_aux_delete_conversation_settings(const char* filepath, UnnuAuxConversationSettings_t config);

FFI_PLUGIN_EXPORT void unnu_aux_free_config(UnnuAuxConfig_t* config);

#endif //_UNNU_AUX_H