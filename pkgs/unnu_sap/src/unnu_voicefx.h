#ifndef _UNNU_VOICEFX_H
#define _UNNU_VOICEFX_H

#include "common.h"

#ifdef __cplusplus
extern "C"
{
#endif

typedef void* STProc_HANDLE;


typedef enum EEMOTION : uint8_t {
	EMOTION_HAPPY = 0,
	EMOTION_SAD = 1,
	EMOTION_AFRAID = 2,
	EMOTION_SURPRISE = 3,
	EMOTION_DISGUST = 4,
	EMOTION_EXCITED = 5,
	EMOTION_JOY = 6,
	EMOTION_DISTRESS = 7,
	EMOTION_DEPRESSED = 8,
	EMOTION_BORED = 9,
	EMOTION_SLEEPY = 10,
	EMOTION_CALM = 11,
	EMOTION_RELAXED = 12,
	EMOTION_TRUST = 13,
	EMOTION_CONTENT = 14,
	EMOTION_NEUTRAL = 15
} EEMOTION_t ;

typedef struct EmotionDSPParams {
    float pitchSemiTones;
    float formantShift;
    float eqFreq;
    float eqGain;
    float compThreshold;
    float compRatio;
    float reverbAmount;
    float distortionAmount;
} EmotionDSPParams_t;

typedef struct SpeakerState {
    int32_t speaker;
	STProc_HANDLE stEmotions;
	STProc_HANDLE stPitch;
	STProc_HANDLE stFormant;
	int32_t sampleRate;
    EmotionDSPParams_t blendedParams;
    float currentPitch, currentFormantShift, currentEQFreq, currentEQGain;
    float currentCompThreshold, currentCompRatio, currentReverbAmount, currentDistortionAmount;
	bool  isRobot;
} SpeakerState_t;


#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT EmotionDSPParams_t unnu_tts_get_emotion_settings(EEMOTION_t setting);

FFI_PLUGIN_EXPORT void unnu_tts_update_sfx(SpeakerState_t* spk, EmotionDSPParams_t blendedParams, float alpha);

FFI_PLUGIN_EXPORT UnnuAudioSample_t* unnu_tts_apply_sfx(SpeakerState_t* spk, float *samples, int count);

FFI_PLUGIN_EXPORT void unnu_tts_speaker_state_free(SpeakerState_t* state);

#endif // _UNNU_VOICEFX_H