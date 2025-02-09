#ifndef _UNNU_VAD_H
#define _UNNU_VAD_H

#include "common.h"

#ifdef __cplusplus
extern "C"
{
#endif

typedef enum EVOICE_ACTIVITY : uint8_t {
	EVOICE_ACTIVITY_START = 0,
	EVOICE_ACTIVITY_END = 1,
	EVOICE_ACTIVITY_SPEAKING = 2,
	EVOICE_ACTIVITY_OVERLAP = 3,
	EVOICE_ACTIVITY_LISTENING = 4,
	EVOICE_ACTIVITY_IDLING = 5,
	EVOICE_ACTIVITY_IDENTIFIED = 6
} EVOICE_ACTIVITY_t ;

typedef struct VoiceActivityState {
    int32_t speaker;
	EVOICE_ACTIVITY_t status;
} VoiceActivityState_t;


typedef void (*UnnuVoiceActivityCallback)(VoiceActivityState*);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_vad_init();

FFI_PLUGIN_EXPORT void unnu_vad_destroy();

FFI_PLUGIN_EXPORT void unnu_vad_speaker_add(int32_t id, UnnuAudioSample_t* sample);

FFI_PLUGIN_EXPORT void unnu_vad_speaker_id(UnnuAudioSample_t* sample);

FFI_PLUGIN_EXPORT bool unnu_vad_speaker_check(int32_t id, UnnuAudioSample_t* sample);

FFI_PLUGIN_EXPORT void unnu_vad_speaker_rm(int32_t id, UnnuAudioSample_t* sample);

FFI_PLUGIN_EXPORT void unnu_vad_speaker_notify(int32_t id, UnnuAudioSample_t* sample);

FFI_PLUGIN_EXPORT void unnu_vad_set_detect_callback(UnnuVoiceActivityCallback callback);

FFI_PLUGIN_EXPORT void unnu_vad_unset_detect_callback();


#endif // _UNNU_VAD_H