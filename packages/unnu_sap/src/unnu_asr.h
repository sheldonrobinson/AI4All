#ifndef _UNNU_ASR_H
#define _UNNU_ASR_H

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

typedef enum UnnuTranscriptType : uint8_t {
	START = 0,
	CHUNK = 1,
	PARTIAL = 2,
	FINAL = 3,
	END = 4
} UnnuTranscriptType_t;

typedef struct UnnuASRBoolStruct {
	bool value;
} UnnuASRBoolStruct_t;

typedef struct UnnuASRTextStruct {
	char* text;
	int32_t length;
} UnnuASRTextStruct_t;


typedef struct UnnuASRFloatStruct {
	float value;
} UnnuASRFloatStruct_t;

typedef void (*TranscriptCallback)(int type, UnnuASRTextStruct_t* transcript);
typedef void (*SoundEventCallback)(UnnuASRFloatStruct_t*);
typedef void (*VoiceActivityDetectedCallback)(UnnuASRBoolStruct_t*);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_asr_init(SherpaOnnxOnlineRecognizerConfig config, SherpaOnnxVadModelConfig vadConfig, SherpaOnnxOnlinePunctuationConfig punctConfig);

FFI_PLUGIN_EXPORT void unnu_asr_set_sound_callback(SoundEventCallback sound_callback);

FFI_PLUGIN_EXPORT void unnu_asr_unset_sound_callback();

FFI_PLUGIN_EXPORT void unnu_asr_set_transcript_callback(TranscriptCallback transcript_callback);

FFI_PLUGIN_EXPORT void unnu_asr_unset_transcript_callback();

FFI_PLUGIN_EXPORT void unnu_asr_set_listening_callback(VoiceActivityDetectedCallback listening_callback);

FFI_PLUGIN_EXPORT void unnu_asr_unset_listening_callback();

FFI_PLUGIN_EXPORT void unnu_asr_free_bool(UnnuASRBoolStruct_t* ptr);

FFI_PLUGIN_EXPORT void unnu_asr_free_transcript(UnnuASRTextStruct_t* ptr);

FFI_PLUGIN_EXPORT void unnu_asr_free_float(UnnuASRFloatStruct_t* ptr);

FFI_PLUGIN_EXPORT void unnu_asr_enable(bool enable);

FFI_PLUGIN_EXPORT bool unnu_asr_is_enabled();

FFI_PLUGIN_EXPORT void unnu_asr_mute(bool mute);

FFI_PLUGIN_EXPORT bool unnu_asr_is_muted();

FFI_PLUGIN_EXPORT void unnu_asr_punctuate(bool punctuate);

FFI_PLUGIN_EXPORT bool unnu_asr_is_punctuated();

FFI_PLUGIN_EXPORT void unnu_asr_nudge(int32_t ms);

// FFI_PLUGIN_EXPORT bool unnu_asr_start();

// FFI_PLUGIN_EXPORT bool unnu_asr_stop();

FFI_PLUGIN_EXPORT bool unnu_asr_is_streaming();

FFI_PLUGIN_EXPORT bool unnu_asr_is_supported();

FFI_PLUGIN_EXPORT void unnu_asr_destroy();


#endif // _UNNU_ASR_H