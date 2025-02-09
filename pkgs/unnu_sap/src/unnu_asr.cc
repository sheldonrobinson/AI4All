#include <float.h>
#include <time.h>
#include <math.h>
#include <cstring>
#include <cmath>
#include <queue>
#include <numeric>
#include <algorithm>
#include <string>
#include <atomic>
#include <cstdlib>
#include <thread>

#define UNNU_ASR_SAMPLE_FREQUENCY  (0.2f)

#define SILENCE_BUFFER_DURATION (3.0f)

#include "unnu_asr.h"
#include "microphone.h"
#include "unnu_vad.h"

static bool _muted{ false };

static std::atomic<bool> _is_enabled{ false };

static bool _is_listening{ false };

static bool _transcribing{ false };

static TranscriptCallback transcription_cb = nullptr;
static SoundEventCallback activityDetected_cb = nullptr;

void _send_transcript(UnnuTranscriptType_t type, const char* text) {
	if (transcription_cb != nullptr) {
		UnnuASRTextStruct_t* t = (UnnuASRTextStruct_t*)malloc(sizeof(UnnuASRTextStruct_t));
		auto len = strlen(text);
		t->length = len;
		t->text = (char*)std::calloc(len + 1, sizeof(char));
		if (len > 0) {
			std::memcpy(t->text, text, len);
		}
		t->text[len] = '\0';
		transcription_cb(type, t);
	}
}

void unnu_asr_set_transcript_callback(TranscriptCallback transcript_callback) {
	transcription_cb = transcript_callback;
}

void unnu_asr_unset_transcript_callback() {
	transcription_cb = nullptr;
}

void unnu_asr_set_sound_callback(
	SoundEventCallback sound_callback)
{
	activityDetected_cb = sound_callback;
}

void unnu_asr_unset_sound_callback() {
	activityDetected_cb = nullptr;
}

void unnu_asr_init(const char* lang) {

}

void unnu_asr_mute(bool mute) {

	_muted = mute;
}

bool unnu_asr_is_muted() {
	return _muted;
}

void unnu_asr_enable(bool enable) {
	_is_enabled = enable;
}

bool unnu_asr_is_enabled() {
	return _is_enabled.load();
}

void unnu_asr_destroy() {

	unnu_asr_enable(false);

	unnu_asr_unset_transcript_callback();

	unnu_asr_unset_sound_callback();
}
