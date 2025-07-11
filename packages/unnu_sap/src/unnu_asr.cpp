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
#include <fvad.h>

#define UNNU_ASR_SAMPLE_FREQUENCY  (0.2f)

#define SILENCE_BUFFER_DURATION (3.0f)

#if defined(__WIN32__) || defined(_WIN32) || defined(WIN32) || defined(__WINDOWS__) || defined(__TOS_WIN__)

#include <windows.h>

#if defined(WIN32_LEAN_AND_MEAN)
#include <timeapi.h>
#endif

inline void asr_delay(unsigned long ms)
{
	Sleep(ms);
}

#else  /* presume POSIX */

#include <unistd.h>

inline void asr_delay(unsigned long ms)
{
	usleep(ms * 1000);
}

#endif

#define  THREAD_IMPLEMENTATION
#include "mgthread.h"
#include "common.h"
#include "osaudio.h"
#include "unnu_asr.h"

typedef struct maAsrData
{
	int32_t sampleRate;
	bool streaming;
} maAsrData_t;


static const SherpaOnnxOnlineRecognizer* _recognizer = NULL;

static const SherpaOnnxOnlineStream* _stream = NULL;

static const SherpaOnnxVoiceActivityDetector* _vad = NULL;

static const SherpaOnnxOnlinePunctuation* _punct = NULL;

// static std::atomic<bool> _voice_activity_detected{ false };

static bool _muted{ false };

static std::atomic<bool> _enabled{ true };

static std::atomic<bool> _punctuate{ false };

static bool _supported{ false };

static bool _is_listening{ false };

static bool _transcribing{ false };

static thread_ptr_t recording_worker = nullptr;

static thread_atomic_int_t record_flag;

static TranscriptCallback transcription_cb = nullptr;
static VoiceActivityDetectedCallback nowListening_cb = nullptr;
static SoundEventCallback activityDetected_cb = nullptr;

typedef struct fvad_deleter {
	void operator()(Fvad* vad) {
		if (vad != NULL) {
			fvad_free(vad);
		}

	}
} fvad_deleter_t;

typedef std::unique_ptr<Fvad, fvad_deleter_t> fvad_ptr;

static std::unique_ptr<osaudio_t> capture = std::make_unique<osaudio_t>();

static std::unique_ptr<maAsrData_t> ma_data = std::make_unique<maAsrData_t>();

void asr_notification(void* user_data, const osaudio_notification_t* notification) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "asr_notification: type %i\n", notification->type);
#endif
	maAsrData_t* data = (maAsrData_t*)user_data;
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

void now_listening_event(bool isListening) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "now_listening_event(%s)\n", isListening ? "true" : "false");
#endif
	if (nowListening_cb != nullptr) {

		UnnuASRBoolStruct_t* _bool = (UnnuASRBoolStruct_t*)malloc(sizeof(UnnuASRBoolStruct_t));
		_bool->value = isListening;
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "now_listening_event -> nowListening_cb(%s)\n", isListening ? "true" : "false");
#endif
		nowListening_cb(_bool);
#if defined(DEBUG) || defined(_DEBUG)
		//		fprintf(stderr, "now_listening_event <- nowListening_cb\n");
#endif	
	}
#if defined(DEBUG) || defined(_DEBUG)
	//	fprintf(stderr, "now_listening_event::>\n");
#endif
}

void _send_transcript(UnnuTranscriptType_t type, const char* text) {
	if (transcription_cb != nullptr) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "_send_transcript: %s\n", text);
#endif
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

void disableOnNoVAD(int32_t ms) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "disableOnNoVAD()\n");
#endif
	_transcribing = true;
	delay(ms);
	do {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "disableOnNoVAD waiting %i ms\n", ms);
#endif
		thread_yield();
	} while (_transcribing);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "disableOnNoVAD wait ended\n");
#endif
	_send_transcript(UnnuTranscriptType::END, "");
	unnu_asr_enable(false);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "disableOnNoVAD(streaming: %s)\n", ma_data->streaming ? "true" : "false");
#endif
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "disableOnNoVAD::>\n");
#endif
}

// Function to convert energy to decibels
inline float _to_decibels(std::vector<float> audio)
{
	if (audio.size() > 0) {
		auto minmax = std::minmax_element(audio.cbegin(), audio.cend());

		auto loudest = fmax(fabs(*minmax.first), fabs(*minmax.second));

		return (20.0f * log10f(loudest + FLT_EPSILON)) + 60.2369;  // FLT_EPSILON = -138.4738dB
	}
	return 0.0f;
}

void _unnu_asr_got_sound(float soundDb) {
	if (activityDetected_cb != nullptr) {
		UnnuASRFloatStruct_t* _float = (UnnuASRFloatStruct_t*)malloc(sizeof(UnnuASRFloatStruct_t));
		_float->value = soundDb;
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "_unnu_asr_got_sound -> activityDetected_cb(%f)\n", soundDb);
#endif
		activityDetected_cb(_float);
	}
}

void unnu_asr_nudge(int32_t ms) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_nudge(ms: %i)\n", ms);
#endif
	unnu_asr_mute(false);
	unnu_asr_enable(true);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_nudge new thread\n");
#endif
	std::thread thr(disableOnNoVAD, ms);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_nudge started thr\n");
#endif
	thr.detach();
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_nudge detached thr\n");
#endif

#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_nudge::>\n");
#endif
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

void unnu_asr_set_listening_callback(
	VoiceActivityDetectedCallback listening_callback)
{
	nowListening_cb = listening_callback;
}

void unnu_asr_unset_listening_callback() {
	nowListening_cb = nullptr;
}

void unnu_asr_free_bool(UnnuASRBoolStruct_t* ptr) {
	free(ptr);
}

void unnu_asr_free_transcript(UnnuASRTextStruct_t* ptr) {
	if (ptr != nullptr) {
		if(ptr->length > 0) free(ptr->text);
	}
	free(ptr);
}

void unnu_asr_free_float(UnnuASRFloatStruct_t* ptr) {
	free(ptr);
}


void _mic_init(
	double bufferInMilliSec)
{
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "_mic_init(%f)\n", bufferInMilliSec);
#endif

	osaudio_config_t config;

	osaudio_config_init(&config, OSAUDIO_INPUT);
	config.format = OSAUDIO_FORMAT_F32;
	config.channels = 1;
	config.rate = 48000;
	config.notification = asr_notification;
	config.user_data = ma_data.get();


	double frequency = bufferInMilliSec / 1000.0;
	size_t numSamplesInFrames = pow(2, ceil(log2(config.rate * frequency)));

	config.buffer_size = numSamplesInFrames;

	if (osaudio_open(capture.get(), &config) != OSAUDIO_SUCCESS) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "_mic_init Failed to open device.\n");
#endif
		_supported = false;
		return;
	}
	_supported = true;
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "_mic_init:>\n");
#endif
}

void unnu_asr_init(SherpaOnnxOnlineRecognizerConfig  config, SherpaOnnxVadModelConfig  vadConfig, SherpaOnnxOnlinePunctuationConfig punctConfig) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_init()\n");
#endif

	if (_recognizer == NULL) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "_recognizer()\n");
#endif
		_recognizer = SherpaOnnxCreateOnlineRecognizer(&config);
	}

	if (_stream == NULL && _recognizer != NULL) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "_stream()\n");
#endif
		_stream = SherpaOnnxCreateOnlineStream(_recognizer);
	}
	if (strlen(vadConfig.silero_vad.model) > 0) {
		if (_vad == NULL) {
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(stderr, "_vad()\n");
#endif
			_vad = SherpaOnnxCreateVoiceActivityDetector(&vadConfig, SILENCE_BUFFER_DURATION);
		}
	}

	if (strlen(punctConfig.model.bpe_vocab) >0 && strlen(punctConfig.model.cnn_bilstm) > 0) {
		if (_punct == NULL) {
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(stderr, "_punct()\n");
#endif
			_punct = SherpaOnnxCreateOnlinePunctuation(&punctConfig);
			_punctuate = true;
		}
	}

	{
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "unnu_asr_init -> _mic_init\n");
#endif

		_mic_init(vadConfig.silero_vad.min_silence_duration * 1000);
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "unnu_asr_init <- _mic_init\n");
#endif
	}
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_init::>\n");
#endif
}



/* This routine is run in a separate thread to write data from the ring buffer into a file (during Recording) */

int recordingCallback(void* user_data)
{
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "recordingCallback()\n");
#endif
	thread_set_high_priority();
	if (!_is_listening) {
		_is_listening = true;
		now_listening_event(true);
	}
	std::string response = "";
	// Fvad* vad = fvad_new();
	fvad_ptr vad = fvad_ptr(fvad_new());
	fvad_set_mode(vad.get(), 0);
	fvad_set_sample_rate(vad.get(), 48000);
	int vadFrames = 5, vadOffset = 960;
	// float tail_paddings[9600] = { 0 }; // 0.2 seconds at 16 kHz sample rate
	osaudio_flush(*capture.get());
	if (osaudio_resume(*capture.get()) == OSAUDIO_SUCCESS) {
		ma_data->streaming = true;
	} else {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "recordingCallback osaudio_resume failed\n");
#endif
		thread_exit(-1);
		return -1;
	}
	thread_atomic_int_t* running_flag = (thread_atomic_int_t*) user_data;
	while (thread_atomic_int_load( running_flag ) == 0) {
		float frames[4800] = { 0 };
		unsigned int frameCount = 4800;
		int  result = osaudio_read(*capture.get(), frames, 4800);

		if (result != OSAUDIO_SUCCESS && result != OSAUDIO_XRUN) {
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(stderr, "unnu_asr Error reading from capture device.\n");
#endif
			break;
		}
		
		SherpaOnnxOnlineStreamAcceptWaveform(_stream, 48000,
			frames, 4800);

		while (SherpaOnnxIsOnlineStreamReady(_recognizer, _stream)) {
			SherpaOnnxDecodeOnlineStream(_recognizer, _stream);
		}

		const SherpaOnnxOnlineRecognizerResult* r =
			SherpaOnnxGetOnlineStreamResult(_recognizer, _stream);

		if (strlen(r->text) > 0) {
			std::string text = r->text;
			size_t resp_len =  response.length();
			size_t txt_len = text.length();
			size_t offset = resp_len < txt_len ? resp_len : txt_len;
			std::string token = text.substr(offset);
			response.append(token);
			if (!_muted && !token.empty()) {
#if defined(DEBUG) || defined(_DEBUG)
				fprintf(stderr, "stt: %s\n", response.c_str());
#endif
				_send_transcript(UnnuTranscriptType::CHUNK, token.c_str());
				short vadAudio[4800] = { 0 };
#pragma omp parallel for
				for (int32_t i = 0; i < 4800; i++) { //convert to stereo
					vadAudio[i] = frames[i] * 32767;
				}
				bool foundVAD = false;
				for (int i = 0; i < vadFrames; i++) {
					if (fvad_process(vad.get(), vadAudio + (i * vadOffset), vadOffset) == 1) {
						foundVAD = true;
						break;
					}
				}

				if (foundVAD) {
					std::vector<float> audio(4800);
					std::memcpy(audio.data(), frames, 4800);
					float _decibels = _to_decibels(audio);
					_unnu_asr_got_sound(_decibels);
				}
				else {
					_unnu_asr_got_sound(0.0f);
				}
			}
		}
		SherpaOnnxDestroyOnlineRecognizerResult(r);

		if (SherpaOnnxOnlineStreamIsEndpoint(_recognizer, _stream)) {
			SherpaOnnxOnlineStreamReset(_recognizer, _stream);

			_transcribing = false;
			if (_enabled.load() && !response.empty()) {
#if defined(DEBUG) || defined(_DEBUG)
				fprintf(stderr, "_heard %s\n", response.c_str());
#endif
				std::transform(response.begin(), response.end(), response.begin(),
					[](auto c) { return std::tolower(c); });
				auto result = _punctuate.load() && _punct != NULL ? SherpaOnnxOnlinePunctuationAddPunct(_punct, response.c_str()) : response.c_str();
#if defined(DEBUG) || defined(_DEBUG)
				fprintf(stderr, "_punct %s\n", result);
#endif
				if (!_muted) {
					_send_transcript(UnnuTranscriptType::FINAL, result);
				}
				if (_punctuate.load() && _punct != NULL) {
					SherpaOfflinePunctuationFreeText(result);
				}
				
			}
			response = "";
		}
	}
	SherpaOnnxOnlineStreamReset(_recognizer, _stream);
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "recordingCallback := is_listening(%s)\n", _is_listening ? "true" : "false");
#endif
	if (_is_listening) {
		_is_listening = false;
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "recordingCallback -> now_listening_event(false)\n");
#endif
		now_listening_event(false);
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "recordingCallback <- now_listening_event\n");
#endif
		
	}
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "recordingCallback::>\n");
#endif
	osaudio_flush(*capture.get());
	if (osaudio_pause(*capture.get()) == OSAUDIO_SUCCESS) {
		ma_data->streaming = false;
	}
	else {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "recordingCallback osaudio_pause failed\n");
#endif
		thread_exit(-1);
		return -1;
	}
	thread_exit(0);
	return 0;
}

bool unnu_asr_start() {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_start()\n");
#endif
	if (_supported && thread_atomic_int_load(&record_flag) != 0) {
			thread_atomic_int_store( &record_flag, 0 );
			recording_worker = thread_create(recordingCallback, &record_flag, THREAD_STACK_SIZE_DEFAULT);
			ma_data->streaming = true;
	}
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_start::>\n");
#endif	
	return ma_data->streaming;
}

bool unnu_asr_stop() {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_stop(streaming: %s)\n", ma_data->streaming ? "true" : "false");
#endif
	if (_supported) {
		ma_data->streaming = false;
		thread_atomic_int_store( &record_flag, 1 );
	}
	return !ma_data->streaming;
}

void unnu_asr_destroy() {

	unnu_asr_stop();
	if (osaudio_close(*(capture.get())) == OSAUDIO_SUCCESS) {
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(stderr, "osaudio_close closed mic.\n");
#endif
		ma_data->streaming = false;
		_supported = false;
	}

	if (_punct != NULL) {
		SherpaOnnxDestroyOnlinePunctuation(_punct);
	}

	if (_stream != NULL) {
		SherpaOnnxDestroyOnlineStream(_stream);
	}
	if (_recognizer != NULL) {
		SherpaOnnxDestroyOnlineRecognizer(_recognizer);
	}

	if (_vad != NULL) {
		SherpaOnnxDestroyVoiceActivityDetector(_vad);
	}

	unnu_asr_unset_transcript_callback();

	unnu_asr_unset_sound_callback();

	unnu_asr_unset_listening_callback();

}

bool unnu_asr_is_streaming() {
	return ma_data->streaming;
}

bool unnu_asr_is_supported() {
	return _supported;
}

void unnu_asr_mute(bool mute) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_mute(%s)\n", mute ? "true" : "false");
#endif
	_muted = mute;
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_mute:>\n");
#endif
}

bool unnu_asr_is_muted() {
	return _muted;
}

void unnu_asr_punctuate(bool punctuate) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_punctuate(%s)\n", punctuate ? "true" : "false");
#endif
	_punctuate = punctuate;
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_punctuate:>\n");
#endif
}

bool unnu_asr_is_punctuated() {
	return _punctuate.load();
}

void unnu_asr_enable(bool enable) {
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_enable(%s)\n", enable ? "true" : "false");
#endif
	_enabled = enable ? unnu_asr_start() : !unnu_asr_stop();
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(stderr, "unnu_asr_enable::>\n");
#endif
}

bool unnu_asr_is_enabled() {
	return _enabled.load();
}
