#ifndef _UNNU_CE_H
#define _UNNU_CE_H

#include "common.h"

#ifdef __cplusplus
extern "C"
{
#endif

    typedef struct  UnnuSentence {
        char* text;
        int length;
    } UnnuSentence_t;

	typedef enum UnnuTokenizerType : uint8_t {
		TOKENIZER_TYPE_NONE,
		TOKENIZER_TYPE_SENTENCEPIECE,
		TOKENIZER_TYPE_HUGGINGFACE,
		TOKENIZER_TYPE_RWKV
	} UnnuTokenizerType_t;

	typedef struct UnnuTokenizerConfig {
		UnnuTokenizerType_t type;
		char* tokenizer_path;
		int length;
	} UnnuTokenizerConfig_t;

	typedef enum UnnuOrtOperationType : uint8_t {
		
		UNNU_ORT_CNER,
		UNNU_ORT_EMBEDDING,
		UNNU_ORT_TOKENIZE,
	} UnnuOrtOperationType_t;

	typedef enum SoarRunFlags : uint8_t
	{
		SOAR_SML_RUN_NONE = 0,           // No special flags set
		SOAR_SML_RUN_SELF = 1 << 0,      // User included --self flag when running agent
		SOAR_SML_RUN_ALL = 1 << 1,      // User ran all agents
		SOAR_SML_UPDATE_CORPUS = 1 << 2,      // User explicitly requested corpus to update
		SOAR_SML_DONT_UPDATE_CORPUS = 1 << 3,      // User explicitly requested corpus to not update
	} SoarRunFlags_t;

	typedef enum SoarDataType : uint8_t {
		SOAR_BOOL,
		SOAR_INT,
		SOAR_FLOAT,
		SOAR_STRING,
		SOAR_ELEMENTXML,
		SOAR_ERROR
	} SoarDataType_t;

	typedef enum UnnuEntityInfo {
		UNNU_ENTITY_UNKNOWN = 0,
		UNNU_ENTITY_ANIMAL = 1 << 0,
		UNNU_ENTITY_DISEASE = 1 << 1,
		UNNU_ENTITY_DISCIPLINE = 1 << 2,
		UNNU_ENTITY_LANGUAGE = 1 << 3,
		UNNU_ENTITY_EVENT = 1 << 4,
		UNNU_ENTITY_FOOD = 1 << 5,
		UNNU_ENTITY_ARTIFACT = 1 << 6,
		UNNU_ENTITY_MEDIA = 1 << 7,
		UNNU_ENTITY_GROUP = 1 << 8,
		UNNU_ENTITY_ORGANIZATION = 1 << 9,
		UNNU_ENTITY_PERSON = 1 << 10,
		UNNU_ENTITY_STRUCTURE = 1 << 11,
		UNNU_ENTITY_LOCATION = 1 << 12,
		UNNU_ENTITY_PLANT = 1 << 13,
		UNNU_ENTITY_MONEY = 1 << 14,
		UNNU_ENTITY_BIOLOGY = 1 << 15,
		UNNU_ENTITY_MEASURE = 1 << 16,
		UNNU_ENTITY_SUPERSTITION = 1 << 17,
		UNNU_ENTITY_CELESTIAL = 1 << 18,
		UNNU_ENTITY_LAW = 1 << 19,
		UNNU_ENTITY_SUBSTANCE = 1 << 20,
		UNNU_ENTITY_PART = 1 << 21,
		UNNU_ENTITY_CULTURE = 1 << 22,
		UNNU_ENTITY_PROPERTY = 1 << 23,
		UNNU_ENTITY_FEELING = 1 << 24,
		UNNU_ENTITY_PSYCHOLOGY = 1 << 25,
		UNNU_ENTITY_RELATIONSHIP = 1 << 26,
		UNNU_ENTITY_DATETIME = 1 << 27,
		UNNU_ENTITY_ASSET = 1 << 28,	
		UNNU_ENTITY_UNSPECIFIED = 1 << 30

	} UnnuEntityInfo_t;

	typedef enum UnnuLearningProfile {
		DEITY,
		SPHINX,
		ORACLE,
		PHILOSOPHER,
		CHILD
	} UnnuLearningProfile_t;

	typedef struct UnnuLearningConfig {
		char* prompt;
		int length;
		UnnuLearningProfile_t profile;

	} UnnuLearningConfig_t;

	typedef struct UnnuOgaResult {
		char* result;
		int length;

	} UnnuOgaResult_t;

	typedef void (*OgaResultCallback)(UnnuOgaResult_t result);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_soar_init(const char* path);

FFI_PLUGIN_EXPORT void unnu_soar_destroy();

FFI_PLUGIN_EXPORT void unnu_soar_start();

FFI_PLUGIN_EXPORT void unnu_soar_stop();

FFI_PLUGIN_EXPORT void unnu_soar_reset();

FFI_PLUGIN_EXPORT void unnu_oga_init(const char* model_path);

FFI_PLUGIN_EXPORT void unnu_oga_prompt(const char* prompt);

FFI_PLUGIN_EXPORT void unnu_set_oga_result_callback(OgaResultCallback callback);

FFI_PLUGIN_EXPORT void unnu_unset_oga_result_callback();

FFI_PLUGIN_EXPORT void unnu_cner_init(const char* model_path, UnnuTokenizerConfig_t tokenizer_cfg);

FFI_PLUGIN_EXPORT void unnu_cner_destroy();

// FFI_PLUGIN_EXPORT void unnu_cner_process(UnnuExtract_t* extract);

#endif // _UNNU_CE_H

