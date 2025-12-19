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

#endif // _UNNU_CE_H

