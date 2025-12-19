#define _USE_MATH_DEFINES
#include <cmath>
#include <queue>
#include <atomic>
#include <thread>
#include <string>
#include <vector>
#include <kissfft/kiss_fftr.h>
#include "unnu_voicefx.h"
#include "SoundTouchDLL.h"

#define NUM_EMOTIONS 15

EmotionDSPParams_t emotionPresets[NUM_EMOTIONS] = {
    // Happy
    { +2.0f, 1.05f, 3500.0f, 1.5f, 0.6f, 3.0f, 0.2f, 0.0f },
    // Sad
    { -2.0f, 0.95f, 200.0f, 1.3f, 0.5f, 2.0f, 0.4f, 0.0f },
    // Afraid
    { +3.0f, 1.10f, 4000.0f, 1.6f, 0.5f, 4.0f, 0.1f, 0.1f },
    // Surprise
    { +4.0f, 1.15f, 4500.0f, 1.7f, 0.5f, 4.0f, 0.05f, 0.0f },
    // Disgust
    { -1.0f, 0.90f, 250.0f, 1.4f, 0.6f, 3.0f, 0.3f, 0.05f },
    // Excited
    { +3.0f, 1.08f, 3800.0f, 1.5f, 0.5f, 4.0f, 0.05f, 0.1f },
    // Joyous
    { +2.5f, 1.06f, 3600.0f, 1.5f, 0.6f, 3.0f, 0.1f, 0.0f },
    // Distressed
    { +1.0f, 0.97f, 3000.0f, 1.4f, 0.5f, 4.0f, 0.05f, 0.1f },
    // Depressed
    { -3.0f, 0.90f, 180.0f, 1.3f, 0.4f, 2.0f, 0.5f, 0.0f },
    // Bored
    { -1.5f, 0.95f, 250.0f, 1.2f, 0.5f, 2.0f, 0.4f, 0.0f },
    // Sleepy
    { -2.0f, 0.92f, 200.0f, 1.2f, 0.4f, 2.0f, 0.6f, 0.0f },
    // Calm
    { 0.0f, 1.00f, 2500.0f, 1.3f, 0.5f, 2.0f, 0.3f, 0.0f },
    // Relaxed
    { 0.0f, 1.00f, 2400.0f, 1.3f, 0.5f, 2.0f, 0.4f, 0.0f },
    // Trust
    { +0.5f, 1.02f, 2600.0f, 1.4f, 0.5f, 2.0f, 0.2f, 0.0f },
    // Content
    { +0.5f, 1.01f, 2500.0f, 1.3f, 0.5f, 2.0f, 0.2f, 0.0f }
};

typedef struct EmotionCoord {
    EEMOTION_t name;
    float valence; // -1.0 to +1.0
    float arousal; // -1.0 to +1.0
} EmotionCoord_t;

EmotionCoord_t emotionCoords[NUM_EMOTIONS] = {
    {EMOTION_HAPPY,     0.8f,  0.7f},
    {EMOTION_SAD,      -0.8f, -0.6f},
    {EMOTION_AFRAID,   -0.7f,  0.8f},
    {EMOTION_SURPRISE,  0.5f,  0.9f},
    {EMOTION_DISGUST,  -0.9f,  0.4f},
    {EMOTION_EXCITED,   0.9f,  0.9f},
    {EMOTION_JOY,       1.0f,  0.8f},
    {EMOTION_DISTRESS, -0.8f,  0.7f},
    {EMOTION_DEPRESSED,-1.0f, -0.8f},
    {EMOTION_BORED,    -0.5f, -0.7f},
    {EMOTION_SLEEPY,    0.0f, -0.9f},
    {EMOTION_CALM,      0.6f, -0.5f},
    {EMOTION_RELAXED,   0.7f, -0.4f},
    {EMOTION_TRUST,     0.8f, -0.2f},
    {EMOTION_CONTENT,   0.9f, -0.3f}
};

// Normalize audio
void normalize(std::vector<float> &audio) {
    float maxVal = 0.0f;
    for (auto &s : audio) maxVal = std::max(maxVal, std::fabs(s));
    if (maxVal > 0.0f) {
        for (auto &s : audio) s /= maxVal;
    }
}

// Apply short metallic delay
void addShortDelay(std::vector<float> &audio, int sampleRate, float delayMs, float mix) {
    int delaySamples = static_cast<int>((delayMs / 1000.0f) * sampleRate);
    std::vector<float> delayed(audio.size(), 0.0f);

    for (size_t i = delaySamples; i < audio.size(); ++i) {
        delayed[i] = audio[i - delaySamples];
    }

    for (size_t i = 0; i < audio.size(); ++i) {
        audio[i] = (1.0f - mix) * audio[i] + mix * delayed[i];
    }
}

void unnu_tts_speaker_state_free(SpeakerState_t* state){
	if(state != NULL){
		if(state->stEmotions != NULL){
			soundtouch_destroyInstance(state->stEmotions);
		}
		if(state->stPitch != NULL){
			soundtouch_destroyInstance(state->stPitch);
		}
		if(state->stFormant != NULL){
			soundtouch_destroyInstance(state->stFormant);
		}
		free(state);
	}
}


UnnuAudioSample_t* vector_to_unnu_audio_sample(SpeakerState_t* spk, std::vector<float> &processed){
	UnnuAudioSample_t* sample = (UnnuAudioSample_t*) malloc(sizeof(UnnuAudioSample_t));
	sample->sample_rate = spk->sampleRate;
	sample->num_samples = processed.size();
	sample->samples = (float*) calloc(sizeof(float), processed.size());
	std::memcpy(sample->samples, processed.data(), sizeof(float) * processed.size());
	return sample;
}

EmotionDSPParams_t blendEmotions(float* emotionWeights) {
    EmotionDSPParams result = {0};
    float totalWeight = 0.0f;

    for (int i = 0; i < NUM_EMOTIONS; i++) {
        if (emotionWeights[i] > 0.0f) {
            result.pitchSemiTones   += emotionPresets[i].pitchSemiTones   * emotionWeights[i];
            result.formantShift     += emotionPresets[i].formantShift     * emotionWeights[i];
            result.eqFreq           += emotionPresets[i].eqFreq           * emotionWeights[i];
            result.eqGain           += emotionPresets[i].eqGain           * emotionWeights[i];
            result.compThreshold    += emotionPresets[i].compThreshold    * emotionWeights[i];
            result.compRatio        += emotionPresets[i].compRatio        * emotionWeights[i];
            result.reverbAmount     += emotionPresets[i].reverbAmount     * emotionWeights[i];
            result.distortionAmount += emotionPresets[i].distortionAmount * emotionWeights[i];
            totalWeight += emotionWeights[i];
        }
    }

    if (totalWeight > 0.0f) {
        result.pitchSemiTones   /= totalWeight;
        result.formantShift     /= totalWeight;
        result.eqFreq           /= totalWeight;
        result.eqGain           /= totalWeight;
        result.compThreshold    /= totalWeight;
        result.compRatio        /= totalWeight;
        result.reverbAmount     /= totalWeight;
        result.distortionAmount /= totalWeight;
    }

    return result;
}

EmotionDSPParams_t fromValenceArousalToBlendedEmotions(float valence, float arousal) {
    float totalWeight = 0.0f;
	float emotionWeights[NUM_EMOTIONS] = {0}; // dynamic weights
    // Compute weights based on inverse distance
    for (int i = 0; i < NUM_EMOTIONS; i++) {
        float dx = valence - emotionCoords[i].valence;
        float dy = arousal - emotionCoords[i].arousal;
        float dist = sqrtf(dx*dx + dy*dy);

        // Avoid division by zero
        float weight = (dist < 0.00001f) ? 1.0f : 1.0f / (dist + 0.00001f);

        emotionWeights[i] = weight;
        totalWeight += weight;
    }

    // Normalize weights
    for (int i = 0; i < NUM_EMOTIONS; i++) {
        emotionWeights[i] /= totalWeight;
    }

    // Blend DSP parameters
    return blendEmotions(emotionWeights);
}

// Smooth parameter transitions
float smooth(float current, float target, float alpha) {
    return current + alpha * (target - current);
}

// EQ + compression
void applyEQandCompression(float *samples, int count, int sampleRate,
                           float eqFreq, float eqGain,
                           float compThreshold, float compRatio) {
    float omega = 2.0f * M_PI * eqFreq / sampleRate;
    float alpha = sinf(omega) / (2.0f * 0.707f); // Q=0.707
    float b0 = 1 + alpha * eqGain;
    float b1 = -2 * cosf(omega);
    float b2 = 1 - alpha * eqGain;
    float a0 = 1 + alpha / eqGain;
    float a1 = -2 * cosf(omega);
    float a2 = 1 - alpha / eqGain;

    float x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    for (int i = 0; i < count; i++) {
        float x0 = samples[i];
        float y0 = (b0/a0)*x0 + (b1/a0)*x1 + (b2/a0)*x2
                   - (a1/a0)*y1 - (a2/a0)*y2;

        x2 = x1; x1 = x0;
        y2 = y1; y1 = y0;
        // Compression
        float absY = fabs(y0);
        if (absY > compThreshold) {
            float excess = absY - compThreshold;
            y0 = (y0 > 0 ? 1 : -1) * (compThreshold + excess / compRatio);
        }
        samples[i] = y0;
        
    }
}

// Formant shifting with overlap-add & interpolation
void shiftFormants(float *samples, int count, float shiftFactor) {
    kiss_fft_cfg cfg = kiss_fft_alloc(count, 0, nullptr, nullptr);
    std::vector<kiss_fft_cpx> in(count), out(count);

    for (int i = 0; i < count; i++) {
        in[i].r = samples[i];
        in[i].i = 0;
    }

    kiss_fft(cfg, in.data(), out.data());

    int shiftBins = (int)((count / 2) * (shiftFactor - 1.0f));
    std::vector<kiss_fft_cpx> shifted(count);
    for (int i = 0; i < count; i++) {
        int src = i - shiftBins;
        if (src >= 0 && src < count)
            shifted[i] = out[src];
        else
            shifted[i] = {0, 0};
    }

    kiss_fft(cfg, shifted.data(), in.data()); // inverse FFT
    for (int i = 0; i < count; i++)
        samples[i] = in[i].r / count;

    free(cfg);
}

// Simple reverb
void applyReverb(float *samples, int count, float amount) {
    if (amount <= 0.0f) return;
    static float delayBuffer[22050] = {0};
    static int delayIndex = 0;
    int delaySamples = 1000;
    for (int i = 0; i < count; i++) {
        float delayed = delayBuffer[delayIndex];
        delayBuffer[delayIndex] = samples[i] + delayed * 0.5f;
        samples[i] += delayed * amount;
        delayIndex = (delayIndex + 1) % delaySamples;
    }
}

// Simple distortion
void applyDistortion(float *samples, int count, float amount) {
    if (amount <= 0.0f) return;
    for (int i = 0; i < count; i++) {
        float s = samples[i] * (1.0f + amount * 5.0f);
        if (s > 1.0f) s = 1.0f;
        if (s < -1.0f) s = -1.0f;
        samples[i] = s;
    }
}

EmotionDSPParams_t unnu_tts_get_emotion_settings(EEMOTION_t setting){
	float emotionWeights[NUM_EMOTIONS] = {0.0f};
	if(setting != EEMOTION::EMOTION_NEUTRAL){
		emotionWeights[setting] = 1.0f;
	}
	return blendEmotions(emotionWeights);
}

void unnu_tts_update_sfx(SpeakerState_t* spk, EmotionDSPParams_t blendedParams, float alpha){
	// Smooth params
    spk->currentPitch        = smooth(spk->currentPitch, blendedParams.pitchSemiTones, alpha);
    spk->currentFormantShift = smooth(spk->currentFormantShift, blendedParams.formantShift, alpha);
    spk->currentEQFreq       = smooth(spk->currentEQFreq, blendedParams.eqFreq, alpha);
    spk->currentEQGain       = smooth(spk->currentEQGain, blendedParams.eqGain, alpha);
    spk->currentCompThreshold= smooth(spk->currentCompThreshold, blendedParams.compThreshold, alpha);
    spk->currentCompRatio    = smooth(spk->currentCompRatio, blendedParams.compRatio, alpha);
    spk->currentReverbAmount = smooth(spk->currentReverbAmount, blendedParams.reverbAmount, alpha);
    spk->currentDistortionAmount = smooth(spk->currentDistortionAmount, blendedParams.distortionAmount, alpha);
}

// Apply emotions
UnnuAudioSample_t* unnu_tts_apply_sfx(SpeakerState_t* spk, float *samples, int count){
	
	// Pitch shift
	soundtouch_setPitchSemiTones(spk->stEmotions, spk->currentPitch);
	soundtouch_putSamples(spk->stEmotions, samples, count);
    std::vector<float> processed(count);
	int received = soundtouch_receiveSamples(spk->stEmotions, processed.data(), count);

	// Formant shift
	shiftFormants(processed.data(), received, spk->currentFormantShift);

	// EQ + compression
	applyEQandCompression(processed.data(), received, spk->sampleRate,
        spk->blendedParams.eqFreq, spk->blendedParams.eqGain,
        spk->blendedParams.compThreshold, spk->blendedParams.compRatio);

	// Reverb + distortion
	applyReverb(processed.data(), received, spk->blendedParams.reverbAmount);
	applyDistortion(processed.data(), received, spk->blendedParams.distortionAmount);
	
	if (spk->isRobot) {
		soundtouch_putSamples(spk->stPitch, processed.data(), received);
		std::vector<float> pitched(received);
		int receivedPitched = soundtouch_receiveSamples(spk->stPitch, pitched.data(), received);
		
		soundtouch_putSamples(spk->stFormant, pitched.data(), receivedPitched);
		processed.clear(); processed.resize(receivedPitched);
		received = soundtouch_receiveSamples(spk->stFormant, processed.data(), receivedPitched);
		
		// Add short metallic delay (~15ms) for C-3PO style
		addShortDelay(processed, spk->sampleRate, 15.0f, 0.35f);
		
		// Normalize
		normalize(processed);
	}
	
	processed.resize(received);
	
	return vector_to_unnu_audio_sample(spk, processed);
}
