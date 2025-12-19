#ifndef _UNNU_ASR_H
#define _UNNU_ASR_H

#include "common.h"

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

typedef void (*TranscriptCallback)(int type, UnnuSapTextStruct_t* transcript);
typedef void (*SoundEventCallback)(float);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_asr_set_sound_callback(SoundEventCallback sound_callback);

FFI_PLUGIN_EXPORT void unnu_asr_unset_sound_callback();

FFI_PLUGIN_EXPORT void unnu_asr_set_transcript_callback(TranscriptCallback transcript_callback);

FFI_PLUGIN_EXPORT void unnu_asr_unset_transcript_callback();

FFI_PLUGIN_EXPORT bool unnu_asr_is_enabled();

FFI_PLUGIN_EXPORT void unnu_asr_mute(bool mute);

FFI_PLUGIN_EXPORT bool unnu_asr_is_muted();

FFI_PLUGIN_EXPORT void unnu_asr_destroy();

#endif // _UNNU_ASR_H
