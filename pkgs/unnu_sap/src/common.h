#ifndef _UNNU_SAP_COMMON_H
#define _UNNU_SAP_COMMON_H

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
#else // __cplusplus - Objective-C or other C platform
	#include <stdint.h>
	#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C"
{
#endif

/// Possible capture errors
typedef enum AudioDeviceErrors
{
    /// No error
    noError = 0,
    /// The capture device has failed to initialize.
    initFailed = 1,
    /// The capture device has not yet been initialized.
    notInited = 2,
    /// Device not found
    deviceNotFound = 3,
    /// Failed to start the device.
    failedToStartDevice = 4,
	/// Failed to stop the device.
    failedToStopDevice = 5,
    /// Failed to initialize wav recording / playback / buffer.
    failedToInitialize = 6,
    /// Failed to start wav recording / playback.
    failedToStart = 7,
    /// Failed to initialize wav recording / playback.
    failedToStop = 8,
	/// Failed to initialize wav recording / playback.
    failedToAbort = 9,
    /// Invalid arguments while initializing wav recording.
    invalidArgs = 10,
    /// Failed to read from buffer
    failedToRead = 11,
    /// Failed to write to buffer
    failedToWrite = 12,

} AudioDeviceErrors_t;

typedef enum PCMFormat
{
    pcm_u8,
    pcm_s16,
    pcm_s24,
    pcm_s32,
    pcm_f32
} PCMFormatInternal_t;

typedef struct UnnuAudioSample {
  /**
   * \brief Raw samples returned from the voice model.
   */
  float *samples;

  /**
   * \brief Number of samples in the audio chunk.
   */
  size_t num_samples;

  /**
   * \brief Sample rate in Hertz.
   */
  int sample_rate;
} UnnuAudioSample_t;

typedef struct UnnuSapTextStruct {
	char* text;
	int32_t length;
} UnnuSapTextStruct_t;



// Define an enum for supported locales
typedef enum unnu_lang_code {
    LANG_EN,  // English
    LANG_FR,  // French
    LANG_ES,  // Spanish
    LANG_DE,  // German)
	LANG_IT,  // Italian
	LANG_NL,  // Dutch
	LANG_PT,  // Portugese
	LANG_ZH,  // Chinese
    LANG_UNKNOWN // Fallback for unsupported locales
} unnu_lang_code_t;

// Define an enum for supported locales
typedef enum unnu_locale_code {
    LOCALE_EN_US,  // English (United States)
    LOCALE_EN_GB,  // English (United Kingdom)
    LOCALE_FR_FR,  // French (France)
    LOCALE_ES_ES,  // Spanish (Spain)
    LOCALE_DE_DE,  // German (Germany)
	LOCALE_IT_IT,  // Italian (Italy)
	LOCALE_NL_NL,  // Dutuch (Netherlands)
	LOCALE_PT_PT,  // Portugese (Portugal)
	LOCALE_PT_BR,  // Portugese (Brazil)
	LOCALE_ZH_CN,  // Chinese (China)
    LOCALE_UNKNOWN // Fallback for unsupported locales
} unnu_locale_code_t;

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT UnnuSapTextStruct_t* unnu_sap_get_asr_model_path(unnu_lang_code_t langcode, const char* model_dirpath);

FFI_PLUGIN_EXPORT UnnuSapTextStruct_t* unnu_sap_get_tts_model_path(unnu_locale_code_t langcode, const char* model_dirpath);

FFI_PLUGIN_EXPORT void unnu_sap_text_free(UnnuSapTextStruct_t* ptr);

FFI_PLUGIN_EXPORT void unnu_sap_audio_sample_free(UnnuAudioSample_t* audio);

#endif //_UNNU_SAP_COMMON_H