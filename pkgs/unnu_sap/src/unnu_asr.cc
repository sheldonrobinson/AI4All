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
#include <cctype>
#include <filesystem>

#include "sherpa-onnx/c-api/c-api.h"
#include "unnu_asr.h"
#include "microphone.h"
#include "unnu_vad.h"


#define UNNU_ASR_SAMPLE_FREQUENCY  (0.2f)

#define SILENCE_BUFFER_DURATION (3.0f)

typedef struct SherpaOnnxOnlineRecognizer_deleter {
	void operator()(SherpaOnnxOnlineRecognizer *recognizer) {
		if (recognizer != NULL) {
			SherpaOnnxDestroyOnlineRecognizer(recognizer);
		}

	}
} SherpaOnnxOnlineRecognizer_deleter_t;

typedef std::unique_ptr<SherpaOnnxOnlineRecognizer, SherpaOnnxOnlineRecognizer_deleter_t> SherpaOnnxOnlineRecognizer_ptr;

static const SherpaOnnxOnlineRecognizer* g_recognizer = nullptr;

typedef struct SherpaOnnxOnlineStream_deleter {
	void operator()(SherpaOnnxOnlineStream *stream) {
		if (stream != NULL) {
			SherpaOnnxDestroyOnlineStream(stream);
		}

	}
} SherpaOnnxOnlineStream_deleter_t;

typedef std::unique_ptr<SherpaOnnxOnlineStream, SherpaOnnxOnlineStream_deleter_t> SherpaOnnxOnlineStream_ptr;

static const SherpaOnnxOnlineStream* g_stream = nullptr;

typedef struct SherpaOnnxOnlineRecognizerResult_deleter {
	void operator()(SherpaOnnxOnlineRecognizerResult *result) {
		if (result != NULL) {
			SherpaOnnxOnlineRecognizerResult(result);
		}

	}
} SherpaOnnxOnlineRecognizerResult_deleter_t;

typedef std::unique_ptr<SherpaOnnxOnlineRecognizerResult, SherpaOnnxOnlineRecognizerResult_deleter_t> SherpaOnnxOnlineRecognizerResult_ptr;

static bool _muted{ false };

static std::atomic<bool> _is_enabled{ false };

static bool _is_listening{ false };

static bool _transcribing{ false };

static TranscriptCallback transcription_cb = nullptr;
static SoundEventCallback activityDetected_cb = nullptr;

void _send_transcript(UnnuTranscriptType_t type, const char* text) {
	if (transcription_cb != nullptr) {
		UnnuSapTextStruct_t* t = (UnnuSapTextStruct_t*)malloc(sizeof(UnnuSapTextStruct_t));
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

typedef enum asr_model_type {
	KROKO,
	ZIPFORMER,
	PARAFORMER,
	CTC,
	UNKNOWN,
} asr_model_type_t;

typedef struct asr_model_details {
	asr_model_type_t type;
	std::string kroko_model;
	std::string joiner_model;
	std::string encoder_model;
	std::string decoder_model;
	std::string ctc_model;
	std::string tokens_txt;
	std::string bpe_model;
	
} asr_model_details_t;

// Convert a char to lowercase safely (unsigned char to avoid UB)
inline char to_lower_char(char ch) {
    return static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
}

// Case-insensitive starts_with
bool starts_with_ci(const std::string& str, const std::string& prefix) {
    if (prefix.size() > str.size()) return false;
    return std::equal(prefix.begin(), prefix.end(), str.begin(),
                      [](char a, char b) { return to_lower_char(a) == to_lower_char(b); });
}

// Case-insensitive ends_with
bool ends_with_ci(const std::string& str, const std::string& suffix) {
    if (suffix.size() > str.size()) return false;
    return std::equal(suffix.rbegin(), suffix.rend(), str.rbegin(),
                      [](char a, char b) { return to_lower_char(a) == to_lower_char(b); });
}

static asr_model_details_t get_model_details(const char* model_dirpath){
	std::filesystem::path model_directory(model_dirpath);
	bool found_ctc_model_onnx = false;
	bool found_joiner_onnx = false;
	bool found_encoder_onnx = false;
	bool found_decoder_onnx = false;
	asr_model_details_t model_details;
	model_details.type = asr_model_type::UNKNOWN;
	for (auto const& dir_entry : std::filesystem::directory_iterator(model_directory)){
		if(!dir_entry.is_regular_file()){
			continue;
		}
		auto& filename = dir_entry.path().filename();
		std::string extension = filename.extension().generic_string();
		std::string filename_wo_ext = filename.extension().stem().generic_string();
		if(extension.compare(".data") == 0){
			model_details.type = asr_model_type::KROKO;
			model_details.kroko_model = dir_entry.path().generic_string();
			break;
		}
		if(extension.compare(".onnx") == 0){
			if(!found_encoder_onnx && starts_with_ci(filename_wo_ext, "encoder")){
				found_encoder_onnx = true;
				model_details.encoder_model = dir_entry.path().generic_string();
			}
			if(!found_decoder_onnx && starts_with_ci(filename_wo_ext, "decoder")){
				found_decoder_onnx = true;
				model_details.decoder_model = dir_entry.path().generic_string();
			}
			if(!found_joiner_onnx && starts_with_ci(filename_wo_ext, "joiner")){
				found_joiner_onnx = true;
				model_details.joiner_model = dir_entry.path().generic_string();
			}
			if(!found_ctc_model_onnx && starts_with_ci(filename_wo_ext, "model")){
				found_ctc_model_onnx = true;
				model_details.type = asr_model_type::CTC;
				model_details.ctc_model = dir_entry.path().generic_string();
			}
		}
		if(extension.compare(".txt") == 0 && starts_with_ci(filename_wo_ext, "tokens")){
			model_details.tokens_txt = dir_entry.path().generic_string();
		}
		if(extension.compare(".model") == 0 && starts_with_ci(filename_wo_ext, "bpe")){
			model_details.bpe_model = dir_entry.path().generic_string();
		}
	}
	if(model_details.type == asr_model_type::UNKNOWN){
		if(found_decoder_onnx && found_encoder_onnx){
			model_details.type = found_joiner_onnx ? asr_model_type::ZIPFORMER : asr_model_type::PARAFORMER;
		}
	}
	return model_details;
	
}

static size_t ReadFile(const char *filename, const char **buffer_out) {
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
    return -1;
  }
  fseek(file, 0L, SEEK_END);
  long size = ftell(file);
  rewind(file);
  *buffer_out = (char*) malloc(size*sizeof(char));
  if (*buffer_out == NULL) {
    fclose(file);
    return -1;
  }
  size_t read_bytes = fread((void *)*buffer_out, 1, size, file);
  if (read_bytes != size) {
    free((void *)*buffer_out);
    *buffer_out = NULL;
    fclose(file);
    return -1;
  }
  fclose(file);
  return read_bytes;
}

void unnu_asr_init(const char* model_dirpath) {
	auto& details = get_model_details(model_dirpath);
	// Online model config
	SherpaOnnxOnlineModelConfig online_model_config;
	memset(&online_model_config, 0, sizeof(online_model_config));
	online_model_config.debug = 1;
	online_model_config.num_threads = 1;
	bool using_token_buf = false;
	const char *tokens_buf;
	if(!details.tokens_txt.empty() && details.type != asr_model_type::KROKO){
	  // reading tokens to buffers
	  size_t token_buf_size = ReadFile(details.tokens_txt.c_str(), &tokens_buf);
	  if(token_buf_size > 0){
		  online_model_config.tokens_buf = tokens_buf;
		  online_model_config.tokens_buf_size = token_buf_size;
	  } else {
		  online_model_config.tokens = details.tokens_txt.c_str();
	  }
	  
	}
	if(details.type == asr_model_type::PARAFORMER){
		// Paraformer config
		SherpaOnnxOnlineParaformerModelConfig paraformer_config;
		memset(&paraformer_config, 0, sizeof(paraformer_config));
		paraformer_config.encoder = details.encoder_model.c_str();
		paraformer_config.decoder = details.decoder_model.c_str();
		
		// {
			// auto len = strlen(details.encoder_model.c_str());
			// paraformer_config.encoder = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(paraformer_config.encoder, details.encoder_model.c_str(), len);
			// }
			// paraformer_config.encoder[len] = '\0';
		// }
		// {
			// auto len = strlen(details.decoder_model.c_str());
			// paraformer_config.decoder = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(paraformer_config.decoder, details.decoder_model.c_str(), len);
			// }
			// paraformer_config.decoder[len] = '\0';
		// }
		// {
			// auto len = strlen(details.tokens_txt.c_str());
			// online_model_config.tokens = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(online_model_config.tokens, details.tokens_txt.c_str(), len);
			// }
			// online_model_config.tokens[len] = '\0';
		// }
		online_model_config.paraformer = paraformer_config;
	}
	if(details.type == asr_model_type::ZIPFORMER){
		// Zipformer config
		SherpaOnnxOnlineTransducerModelConfig zipformer_config;
		memset(&zipformer_config, 0, sizeof(zipformer_config));
		zipformer_config.encoder = details.encoder_model.c_str();
		zipformer_config.decoder = details.decoder_model.c_str();
		zipformer_config.joiner = details.joiner_model.c_str();
		// {
			// auto len = strlen(details.encoder_model.c_str());
			// zipformer_config.encoder = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(zipformer_config.encoder, details.encoder_model.c_str(), len);
			// }
			// zipformer_config.encoder[len] = '\0';
		// }
		// {
			// auto len = strlen(details.decoder_model.c_str());
			// zipformer_config.decoder = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(zipformer_config.decoder, details.decoder_model.c_str(), len);
			// }
			// zipformer_config.decoder[len] = '\0';
		// }
		// {
			// auto len = strlen(details.joiner_model.c_str());
			// zipformer_config.joiner = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(zipformer_config.joiner, details.joiner_model.c_str(), len);
			// }
			// zipformer_config.joiner[len] = '\0';
		// }
		// {
			// auto len = strlen(details.tokens_txt.c_str());
			// online_model_config.tokens = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(online_model_config.tokens, details.tokens_txt.c_str(), len);
			// }
			// online_model_config.tokens[len] = '\0';
		// }
		online_model_config.transducer = zipformer_config;
	}
	if(details.type == asr_model_type::CTC){
		// Zipformer2Ctc config
		SherpaOnnxOnlineZipformer2CtcModelConfig zipformer2_ctc_config;
		memset(&zipformer2_ctc_config, 0, sizeof(zipformer2_ctc_config));
		zipformer2_ctc_config.model = details.ctc_model.c_str();
		// {
			// auto len = strlen(details.ctc_model.c_str());
			// zipformer2_ctc_config.model = (char*)std::calloc(len + 1, sizeof(char));
			// if (len > 0) {
				// std::memcpy(zipformer2_ctc_config.model, details.ctc_model.c_str(), len);
			// }
			// zipformer2_ctc_config.model[len] = '\0';
		// }
		online_model_config.zipformer2_ctc = zipformer2_ctc_config;
	}
#if defined(_WIN32)
	online_model_config.provider = "dml";
#else
	online_model_config.provder = "cpu";
#endif
#if defined(_DEBUG) || defined(DEBUG)
	online_model_config.debug = 1;
#else
	online_model_config.debug = 0;
#endif	
	// Recognizer config
    SherpaOnnxOnlineRecognizerConfig recognizer_config;
    memset(&recognizer_config, 0, sizeof(recognizer_config));
    recognizer_config.decoding_method = "greedy_search";
	recognizer_config.model_config = online_model_config;
	 
	g_recognizer = SherpaOnnxCreateOnlineRecognizer(&recognizer_config);
	
	g_stream = SherpaOnnxCreateOnlineStream(g_recognizer);

	free((void *)tokens_buf);
	tokens_buf = NULL;
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
	SherpaOnnxDestroyOnlineStream(g_stream);
	SherpaOnnxDestroyOnlineRecognizer(g_recognizer);
	
	g_stream = nullptr;
	g_recognizer = nullptr;
}
