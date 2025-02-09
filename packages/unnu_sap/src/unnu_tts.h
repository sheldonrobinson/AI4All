#ifndef _UNNU_TTS_H
#define _UNNU_TTS_H

#ifdef __cplusplus
	#ifdef WIN32
		#define FFI_PLUGIN_EXPORT extern "C" __declspec(dllexport)
	#else
		#define FFI_PLUGIN_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
	#endif
#else
    #ifdef WIN32
    #define FFI_PLUGIN_EXPORT extern
    #else
    #define FFI_PLUGIN_EXPORT extern __attribute__((visibility("default"))) __attribute__((used))
    #endif
#endif

#ifdef __cplusplus
	#include <cstdint>
	#include <cstdbool>
	#include "c-api.h"
#else // __cplusplus - Objective-C or other C platform
	#include <stdint.h>
	#include <stdbool.h>
	#include "c-api.h"
#endif

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct UnnuTTSBoolStruct {
	bool value;
} UnnuTTSBoolStruct_t;

typedef void (*SpeakingActivityCallback)(UnnuTTSBoolStruct_t*);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_tts(const char* text, int32_t sid, float speed);

FFI_PLUGIN_EXPORT void unnu_tts_init(SherpaOnnxOfflineTtsConfig config);

FFI_PLUGIN_EXPORT void unnu_tts_set_speaking_callback(SpeakingActivityCallback speaking_callback);

FFI_PLUGIN_EXPORT void unnu_tts_unset_speaking_callback();

FFI_PLUGIN_EXPORT void unnu_tts_enable(bool enable);

FFI_PLUGIN_EXPORT void unnu_tts_mute(bool mute);

FFI_PLUGIN_EXPORT void unnu_tts_free_bool(UnnuTTSBoolStruct_t* ptr);

FFI_PLUGIN_EXPORT bool unnu_tts_is_supported();

FFI_PLUGIN_EXPORT bool unnu_tts_is_streaming();

FFI_PLUGIN_EXPORT bool unnu_tts_is_enabled();

FFI_PLUGIN_EXPORT bool unnu_tts_is_muted();

FFI_PLUGIN_EXPORT bool unnu_tts_is_speaking();

// FFI_PLUGIN_EXPORT bool unnu_tts_start();

// FFI_PLUGIN_EXPORT bool unnu_tts_stop();

FFI_PLUGIN_EXPORT void unnu_tts_destroy();

#endif // _UNNU_TTS_H