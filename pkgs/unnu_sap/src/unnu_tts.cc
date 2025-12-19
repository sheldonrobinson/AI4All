#include <queue>
#include <atomic>
#include <thread>
#include <string>
#include <memory>
#include <map>

#include <piper.h>
#include <nlohmann/json.hpp>
#include "unnu_voicefx.h"
#include "SoundTouchDLL.h"
#include "SoundTouch.h"
#include "unnu_tts.h"

#ifndef DIALOG_IMPLEMENTATION
#define DIALOG_IMPLEMENTATION
#endif

#include <mglibs/dialog.h>

#define SAMPLE_RATE 22050

static bool _enabled{ false };

static bool _muted{ false };
static bool _isSpeaking{ false };
static bool _supported{ false };

typedef struct piper_synthesizer_deleter {
	void operator()(piper_synthesizer* synth) {
		if (synth != NULL) {
			piper_free(synth);
		}

	}
} piper_synthesizer_deleter_t;

typedef std::unique_ptr<piper_synthesizer, piper_synthesizer_deleter_t> piper_synthesizer_ptr;


UnnuTTSEventsCallback speechEventCallback = nullptr;

UnnuTTSDialogueCallback dialogueCallback = nullptr;

typedef struct unnu_speaker {
	std::string name;
	piper_synthesize_options options;
	SpeakerState_t state;
	piper_synthesizer_ptr synthesizer;
} unnu_speaker_t;

static std::map<int32_t, unnu_speaker_t> g_speakers;

void unnu_tts_init(){
}

void unnu_tts_add_speaker(const char* model_path, int32_t voice_id, int32_t speaker_id, const char* actor_name, bool is_robot){ // sid speaker id, vid voice id
	unnu_speaker_t speaker;
	std::string _path(model_path);
	piper_synthesizer *synth = piper_create(model_path, NULL, NULL);
	speaker.synthesizer = piper_synthesizer_ptr(synth);

	speaker.name = std::string(actor_name);
	speaker.options = piper_default_synthesize_options(speaker.synthesizer.get());
	speaker.options.speaker_id = voice_id;
	speaker.state.speaker = speaker_id;
	speaker.state.sampleRate = SAMPLE_RATE;
	speaker.state.isRobot = is_robot;
	speaker.state.stEmotions = soundtouch_createInstance();
	soundtouch_setChannels(speaker.state.stEmotions, 1);
	soundtouch_setSampleRate(speaker.state.stEmotions, SAMPLE_RATE);
	soundtouch_setSetting(speaker.state.stEmotions, SETTING_USE_QUICKSEEK, 0);
	soundtouch_setSetting(speaker.state.stEmotions, SETTING_USE_AA_FILTER, 1);
	
	speaker.state.stPitch = soundtouch_createInstance();
	soundtouch_setChannels(speaker.state.stPitch, 1);
	soundtouch_setSampleRate(speaker.state.stPitch, SAMPLE_RATE);
	soundtouch_setTempo(speaker.state.stPitch, 1.0f);
	soundtouch_setPitchSemiTones(speaker.state.stPitch, 2.0f);
	
	speaker.state.stFormant = soundtouch_createInstance();
	soundtouch_setChannels(speaker.state.stFormant, 1);
	soundtouch_setSampleRate(speaker.state.stFormant, SAMPLE_RATE);
	soundtouch_setTempo(speaker.state.stFormant, 1.05f);
	soundtouch_setPitchSemiTones(speaker.state.stFormant, 0.0f);

	// Use emplace to avoid copy/move assignment of unnu_speaker_t
	g_speakers.emplace(speaker_id, std::move(speaker));
	// g_speakers[_name] = speaker;
}

void unnu_tts_rm_speaker(int32_t speaker_id) {
	auto search = g_speakers.find(speaker_id);
	if (search != g_speakers.end()){
		SpeakerState_t _state = g_speakers[speaker_id].state;
		if(_state.stEmotions){
			soundtouch_destroyInstance(_state.stEmotions);
		}
		if(_state.stPitch){
			soundtouch_destroyInstance(_state.stPitch);
		}
		if(_state.stFormant){
			soundtouch_destroyInstance(_state.stFormant);
		}
		g_speakers[speaker_id].synthesizer = nullptr;
		g_speakers.erase(speaker_id);
	}
}

int32_t unnu_tts_get_speaker_id(const char* actor_name){
	std::string name(actor_name);
	for (const auto& [key, value] : g_speakers){
		if (value.name.compare(name) == 0){
			return key;
		}
	}
	return -1;
}

void unnu_tts_using_json(const char* dialog) {
	std::string dialog_str(dialog);
}

void unnu_tts_using_dialog(const dialog_t* dialog) {
	for (int i = 0; i < dialog_conversation_count(dialog); ++i) {
		dialog_conversation_t conversation = dialog_conversation(dialog, i);
		std::string conv_id = dialog_conversation_id(dialog, conversation);
		for (int j = 0; j < dialog_conversation_entry_count(dialog, conversation); ++j) {
			dialog_entry_t entry = dialog_conversation_entry(dialog, conversation, j);
			dialog_entry_type_t type = dialog_entry_type(dialog, entry);
			char const* id = dialog_entry_id(dialog, entry);
			std::string id_str = id ? std::string(id) : "";
			if (type == DIALOG_ENTRY_TYPE_LINE) {
				dialog_line_t line = dialog_entry_line(dialog, entry);
				std::string actor = dialog_line_actor(dialog, line);
				std::string text = dialog_line_text(dialog, line);
			}
			else if (type == DIALOG_ENTRY_TYPE_OPTION) {
				dialog_option_t option = dialog_entry_option(dialog, entry);
				bool is_persistent = dialog_option_is_persistent(dialog, option);
				std::string option_text = dialog_option_text(dialog, option);
				std::string option_target = dialog_option_target(dialog, option);
			}
			else if (type == DIALOG_ENTRY_TYPE_REDIRECT) {
				dialog_redirect_t redirect = dialog_entry_redirect(dialog, entry);
				std::string redirect_target = dialog_redirect_target(dialog, redirect);
			}
			else if (type == DIALOG_ENTRY_TYPE_EVENT) {
				dialog_event_t event = dialog_entry_event(dialog, entry);
				std::string event_name = dialog_event_event(dialog, event);
			}
		}
	}
}

void unnu_tts(int32_t speaker_id, EEMOTION_t emotion, const char* text){
	if(dialogueCallback != nullptr){
		piper_synthesizer* synth = g_speakers[speaker_id].synthesizer.get();
		piper_synthesize_start(synth, text,
							   &(g_speakers[speaker_id].options) /* NULL for defaults */);
		auto& blendedparams = unnu_tts_get_emotion_settings(emotion);
		unnu_tts_update_sfx(&(g_speakers[speaker_id].state), blendedparams, 1.0f);
		piper_audio_chunk chunk;
		std::vector<float> _audio;
		while (piper_synthesize_next(synth, &chunk) != PIPER_DONE) {	
			_audio.insert(_audio.end(), chunk.samples, chunk.samples + chunk.num_samples);
			UnnuTTS_DialogueItem_t* item = (UnnuTTS_DialogueItem_t*) malloc(sizeof(UnnuTTS_DialogueItem_t));
			item->speaker_id = speaker_id;
			item->audio = unnu_tts_apply_sfx(&(g_speakers[speaker_id].state), _audio.data(), _audio.size());
			item->is_last = chunk.is_last;
			dialogueCallback(item);
			_audio.clear();
		}
	}

}

void unnu_tts_set_dialogue_callback(UnnuTTSDialogueCallback callback){
	dialogueCallback = callback;
}

void unnu_tts_unset_dialogue_callback() {
	dialogueCallback  = nullptr;
}

void unnu_tts_set_speaking_callback(
	UnnuTTSEventsCallback speaking_callback)
{
	speechEventCallback = speaking_callback;
}

void unnu_tts_unset_speaking_callback()
{
	speechEventCallback = nullptr;
}

void unnu_tts_destroy() {
	for( auto &p : g_speakers){
		unnu_tts_rm_speaker(p.first);
	}
	g_speakers.clear();
}
