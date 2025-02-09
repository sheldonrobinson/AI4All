#include <queue>
#include <atomic>
#include <thread>
#include <string>
#include <memory>
#include <map>

#include <piper.h>
#include "unnu_voicefx.h"
#include "SoundTouch.h"
#include "unnu_tts.h"

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

void unnu_tts(int32_t speaker_id, const char* text, float speed){
	// unnu_speaker_t _speaker = g_speakers[_name];
	piper_synthesizer* synth = g_speakers[speaker_id].synthesizer.get();
	piper_synthesize_start(synth, text,
                           &(g_speakers[speaker_id].options) /* NULL for defaults */);
						   
	piper_audio_chunk chunk;
	std::vector<float> _audio;
    while (piper_synthesize_next(synth, &chunk) != PIPER_DONE) {
		_audio.insert(_audio.end(), chunk.samples, chunk.samples + chunk.num_samples);
    }
	UnnuAudioSample_t* sample = unnu_tts_apply_sfx(&(g_speakers[speaker_id].state), _audio.data(), _audio.size());
	chunk.is_last = true;
	
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
