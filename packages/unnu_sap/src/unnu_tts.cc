#include <float.h>
#include <time.h>
#include <queue>
#include <atomic>
#include <thread>
#include <string>


#if defined(__WIN32__) || defined(_WIN32) || defined(WIN32) || defined(__WINDOWS__) || defined(__TOS_WIN__)

#include <windows.h>

#if defined(WIN32_LEAN_AND_MEAN)
#include <timeapi.h>
#endif

inline void tts_delay(unsigned long ms)
{
	Sleep(ms);
}

#else  /* presume POSIX */

#include <unistd.h>

inline void tts_delay(unsigned long ms)
{
	usleep(ms * 1000);
}

#endif
#define  THREAD_IMPLEMENTATION

#include "mgthread.h"
#include "common.h"
#include "osaudio.h"
#include "unnu_tts.h"

#define UNNU_TTS_SAMPLE_FREQUENCY  (0.5f)
typedef struct maTtsData
{
	int32_t sampleRate;
	bool streaming;
} maTtsData_t;

void tts_notification(void* user_data, const osaudio_notification_t* notification) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "tts_notification: type %i\n", notification->type);
#endif
	maTtsData_t* data = (maTtsData_t*)user_data;
	switch (notification->type)
	{
	case OSAUDIO_NOTIFICATION_STARTED:
	{
		data->streaming = true;
	} break;
	case OSAUDIO_NOTIFICATION_STOPPED:
	{
		data->streaming = false;
	} break;
	case OSAUDIO_NOTIFICATION_INTERRUPTION_BEGIN:
	case OSAUDIO_NOTIFICATION_INTERRUPTION_END:
	case OSAUDIO_NOTIFICATION_REROUTED:
		break;
	}

}

static thread_ptr_t playback_worker;

static thread_ptr_t oratory_flinger;

static const SherpaOnnxOfflineTts* _tts = NULL;

static bool _enabled{ false };

static bool _muted{ false };
static bool _isSpeaking{ false };
static bool _supported{ false };

typedef struct thread_queue_deleter {
	void operator()(thread_queue_t* queue) {
		if (queue != NULL) {
			thread_queue_term(queue);
		}

	}
} thread_queue_deleter_t;

typedef std::unique_ptr<thread_queue_t, thread_queue_deleter_t> thread_queue_ptr;

typedef struct unnu_oratory {
	std::string text;
	int sid;
	float speed;
} unnu_oratory_t;

typedef struct unnu_phrase {
	float* audio;
	size_t numSamples;
} unnu_phrase_t;

#define MAX_QUEUED_PHRASES 32

static thread_queue_ptr _phrases = thread_queue_ptr(std::make_unique<thread_queue_t>().release());

static unnu_phrase_t queued[MAX_QUEUED_PHRASES];

static thread_atomic_int_t play_flag;

static std::unique_ptr<osaudio_t> speaker = std::make_unique<osaudio_t>();

static std::unique_ptr<maTtsData_t> tts_data = std::make_unique<maTtsData_t>();

static std::queue< unnu_oratory_t> sentences;

SpeakingActivityCallback speechEventCallback = nullptr;

void unnu_tts_clear(std::queue<unnu_oratory_t>& q)
{
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_clear()\n");
#endif
	std::queue<unnu_oratory_t> empty;
	std::swap(q, empty);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_clear::>\n");
#endif
}

void unnu_tts_clear(std::queue<std::vector<float>>& q)
{
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_clear()\n");
#endif
	std::queue<std::vector<float>> empty;
	std::swap(q, empty);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_clear::>\n");
#endif
}


void on_speaking_event(bool isSpeaking) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "on_speaking_event(%s)\n", isSpeaking ? "true" : "false");
#endif
	if (speechEventCallback != nullptr) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "speechEventCallback\n");
#endif
		UnnuTTSBoolStruct_t* _bool = (UnnuTTSBoolStruct_t*)malloc(sizeof(UnnuTTSBoolStruct_t));

		_bool->value = isSpeaking;
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "on_speaking_event -> speechEventCallback(%s)\n", isSpeaking ? "true" : "false");
#endif
		speechEventCallback(_bool);
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "on_speaking_event <- speechEventCallback\n");
#endif
	}
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "on_speaking_event::>\n");
#endif
}

void _speaker_init()
{
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "_speaker_init()\n");
#endif

	osaudio_config_t config;

	osaudio_config_init(&config, OSAUDIO_OUTPUT);
	config.format = OSAUDIO_FORMAT_F32;
	config.channels = 2;
	config.rate = 24000;
	config.user_data = tts_data.get();
	config.notification = tts_notification;

	if (osaudio_open(speaker.get(), &config) != OSAUDIO_SUCCESS) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "_speaker_init Failed to open device.\n");
#endif
		_supported = false;
		return;
	}

	_supported = true;
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "_speaker_init:>\n");
#endif
}

void unnu_tts_init(SherpaOnnxOfflineTtsConfig config) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_init()\n");
#endif
	if (_tts == NULL) {
		_tts = SherpaOnnxCreateOfflineTts(&config);
	}

	{
		_speaker_init();
	}

#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_init::>\n");
#endif
}

void unnu_tts_set_speaking_callback(
	SpeakingActivityCallback speaking_callback)
{
	speechEventCallback = speaking_callback;
}

void unnu_tts_unset_speaking_callback()
{
	speechEventCallback = nullptr;
}



int fling(void* user_data) {
	thread_set_high_priority();
	unnu_oratory_t empty;
	empty.text = "";
	empty.sid = 0;
	empty.speed = 1.0;
	auto pempty = std::make_pair(false, empty);
	thread_atomic_int_t* exit_flag = (thread_atomic_int_t*)user_data;
	while (thread_atomic_int_load(exit_flag) == 0) {
		auto _phrase = !sentences.empty() ? std::make_pair(true, sentences.front()) : pempty; // pseudo atomic
		if (_phrase.first) {
			if (!_phrase.second.text.empty()) {
				auto result = SherpaOnnxOfflineTtsGenerate(_tts, _phrase.second.text.c_str(), _phrase.second.sid, _phrase.second.speed);
#if defined(DEBUG) || defined(_DEBUG)
				fprintf(stderr, "playbackCall %i audio samples for: %s\n", result->n, _phrase.second.text.c_str());
#endif
				int32_t num_samples = result->n;
				int numChannels = 2;
				int expanded = numChannels * num_samples;
				unnu_phrase_t* oratory = (unnu_phrase_t*)malloc(sizeof(unnu_phrase_t));
				oratory->audio = (float*)malloc(expanded * sizeof(float));
#pragma omp parallel for
				for (int32_t i = 0; i < expanded; i++) { //convert to stereo
					oratory->audio[i] = result->samples[(int)(i / numChannels)];
				}
				oratory->numSamples = num_samples;
				SherpaOnnxDestroyOfflineTtsGeneratedAudio(result);
				if (thread_atomic_int_load(exit_flag) == 0) {
					thread_queue_produce(_phrases.get(), oratory, THREAD_QUEUE_WAIT_INFINITE);
				}
			}
			if (!sentences.empty()) {
				sentences.pop();
			}
		}
		else {
			thread_yield();
		}
	}
	unnu_tts_clear(sentences);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "fling::>\n");
#endif
	thread_exit(0);
	return 0;
}

int playbackCall(void* user_data) {
	thread_set_high_priority();
	_phrases = thread_queue_ptr(std::make_unique<thread_queue_t>().release());
	thread_queue_init(_phrases.get(), MAX_QUEUED_PHRASES, (void**)&queued, 0);
	osaudio_flush(*speaker.get());
	if (osaudio_resume(*speaker.get()) == OSAUDIO_SUCCESS) {
		tts_data->streaming = true;
	} else {
		thread_exit(-1);
		return -1;
	}
	thread_atomic_int_t exit_flag;
    thread_atomic_int_store( &exit_flag, 0 );
	oratory_flinger = thread_create(fling, &exit_flag,THREAD_STACK_SIZE_DEFAULT);
	thread_atomic_int_t* playback_flag = (thread_atomic_int_t*) user_data;
	while (thread_atomic_int_load(playback_flag ) == 0) {
		auto _phrase = (unnu_phrase_t*)thread_queue_consume(_phrases.get(), 10);
		if (_phrase != NULL) {
			if (!_isSpeaking) {
				_isSpeaking = true;
				on_speaking_event(true);
			}

			if (!_muted) {
				osaudio_write(*speaker.get(), _phrase->audio, _phrase->numSamples);
			}

			
			if (_phrase->audio != NULL) {
				free(_phrase->audio);
			}
			free(_phrase);
		}
		else {
			thread_yield();
		}
		if (!(thread_queue_count(_phrases.get()) > 0)) {
			if (_isSpeaking)
			{
				_isSpeaking = false;
				on_speaking_event(false);
			}
		}
	}

	if (_isSpeaking)
	{
		_isSpeaking = false;
		on_speaking_event(false);
	}
	// tts_data->streaming = false;
	thread_atomic_int_store(&exit_flag, 1);

	osaudio_flush(*speaker.get());
	if (osaudio_pause(*speaker.get()) == OSAUDIO_SUCCESS) {
		tts_data->streaming = false;
	} else {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "playbackCall osaudio_pause failed\n");
#endif
		thread_exit(-1);
		return -1;
	}
	
	thread_exit(0);
	return 0;
}

void unnu_tts(const char* text, int32_t sid, float speed) {
	if (tts_data->streaming) {
		if (text != NULL && strlen(text) > 0) {
			unnu_oratory_t phrase;
			phrase.text = std::string(text);
			phrase.sid = sid;
			phrase.speed = speed;
			sentences.push(phrase);
		}
	}
}



bool unnu_tts_start() {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_start()\n");
#endif
	if (_supported && thread_atomic_int_load(&play_flag) != 0) {
		
        thread_atomic_int_store( &play_flag, 0 );
		playback_worker = thread_create(playbackCall, &play_flag, THREAD_STACK_SIZE_DEFAULT);
		tts_data->streaming = true;
	}
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_start::>\n");
#endif
	return tts_data->streaming;
}

bool unnu_tts_stop() {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_stop\n");
#endif
	if (_supported) {
		tts_data->streaming = false;
		thread_atomic_int_store( &play_flag, 1 );
	}
	return !tts_data->streaming;
}

void unnu_tts_free_bool(UnnuTTSBoolStruct_t* ptr) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_free_bool()\n");
#endif
	free(ptr);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_free_bool::>\n");
#endif
}

void unnu_tts_destroy() {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_destroy()\n");
#endif
	unnu_tts_stop();
	
	if (osaudio_close(*(speaker.get())) == OSAUDIO_SUCCESS) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "osaudio_close closed speaker.\n");
#endif
		_supported = false;
	}

	if (_tts != NULL) {
		SherpaOnnxDestroyOfflineTts(_tts);
	}
	unnu_tts_unset_speaking_callback();
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_destroy::>\n");
#endif	
}

void unnu_tts_enable(bool enable) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_enable(%s)\n", enable ? "true" : "false");
#endif
	_enabled = enable ? unnu_tts_start() : !unnu_tts_stop();
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_enable::>\n");
#endif
}

bool unnu_tts_is_streaming() {
	return tts_data->streaming;
}

bool unnu_tts_is_supported() {
	return _supported;
}

bool unnu_tts_is_enabled() {
	return _enabled;
}

void unnu_tts_mute(bool mute) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_mute(%s)\n", mute ? "true" : "false");
#endif
	_muted = mute;
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_tts_mute:>\n");
#endif
}

bool unnu_tts_is_muted() {
	return _muted;
}

bool unnu_tts_is_speaking() {
	return _isSpeaking;
}


