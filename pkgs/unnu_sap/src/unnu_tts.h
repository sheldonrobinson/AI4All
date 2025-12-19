#ifndef _UNNU_TTS_H
#define _UNNU_TTS_H

#include "common.h"
#include "unnu_voicefx.h"
#include <mglibs/dialog.h>

#ifdef __cplusplus
extern "C"
{
#endif
typedef struct UnnuTTS_DialogueItem {
	int32_t speaker_id;
	UnnuAudioSample_t* audio;
	/**
	* \brief True if this is the last audio chunk.
	*/
	bool is_last;
} UnnuTTS_DialogueItem_t;

typedef void (*UnnuTTSEventsCallback)(int32_t);

typedef void (*UnnuTTSDialogueCallback)(UnnuTTS_DialogueItem_t*);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_tts_init(); 

FFI_PLUGIN_EXPORT void unnu_tts_add_speaker(const char* model_path, int32_t voice_id, int32_t speaker_id, const char* actor_name, bool is_robot); // sid speaker id, vid voice id

FFI_PLUGIN_EXPORT void unnu_tts_rm_speaker(const char* actor_name); 

FFI_PLUGIN_EXPORT int32_t unnu_tts_get_speaker_id(const char* actor_name); 

FFI_PLUGIN_EXPORT void unnu_tts(int32_t speaker_id, EEMOTION_t emotion, const char* text);

FFI_PLUGIN_EXPORT void unnu_tts_using_json(const char* dialog);

FFI_PLUGIN_EXPORT void unnu_tts_using_dialog(const dialog_t* dialog);

FFI_PLUGIN_EXPORT void unnu_tts_set_dialogue_callback(UnnuTTSDialogueCallback callback);

FFI_PLUGIN_EXPORT void unnu_tts_unset_dialogue_callback();

FFI_PLUGIN_EXPORT void unnu_tts_set_speaking_callback(UnnuTTSEventsCallback callback);

FFI_PLUGIN_EXPORT void unnu_tts_unset_speaking_callback();

FFI_PLUGIN_EXPORT void unnu_tts_destroy();

#endif // _UNNU_TTS_H
