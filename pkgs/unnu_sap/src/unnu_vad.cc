#define _USE_MATH_DEFINES
#include <vector>
#include <map>
#include <cmath>
#include <string>
#include <stdexcept>
#include <Eigen/Dense>
#include <kissfft/kiss_fft.h>
#include <onnxruntime_cxx_api.h>
#include "unnu_vad.h"


#define SAMPLE_RATE 16000
#define FRAMES_PER_BUFFER 480 // 30ms at 16kHz
#define CHUNK_SECONDS 1
#define CHUNK_SAMPLES (SAMPLE_RATE * CHUNK_SECONDS)
#define NUM_MFCC 13
#define FFT_SIZE 512
#define HOP_LENGTH 160
#define N_MELS 40


typedef struct VoiceSample {
	int32_t id;
	std::vector<float> sammple;
	std::vector<float> embedding;
	int sample_rate;
} VoiceSample_t;


static std::map<int32_t, std::vector<float>> gVoices;

std::vector<float> speech_sample_to_vector(const UnnuAudioSample_t& sample){
	std::vector<float> _audio(sample.num_samples);
	std::memcpy(_audio.data(), sample.samples, sample.num_samples*sizeof(float));
	return _audio;
}

// ===================== DTW Matching =====================
float dtwDistance(const std::vector<std::vector<float>> &seq1,
                   const std::vector<std::vector<float>> &seq2) {
    size_t n = seq1.size(), m = seq2.size();
    Eigen::MatrixXd dp = Eigen::MatrixXd::Constant(n + 1, m + 1, INFINITY);
    dp(0, 0) = 0.0;

    auto euclidean = [](const std::vector<float> &a, const std::vector<float> &b) {
        float sum = 0;
        for (size_t i = 0; i < a.size(); i++)
            sum += (a[i] - b[i]) * (a[i] - b[i]);
        return sqrt(sum);
    };

    for (size_t i = 1; i <= n; i++) {
        for (size_t j = 1; j <= m; j++) {
            float cost = euclidean(seq1[i - 1], seq2[j - 1]);
            dp(i, j) = cost + std::min({dp(i - 1, j), dp(i, j - 1), dp(i - 1, j - 1)});
        }
    }
    return dp(n, m);
}

// ===================== CNN Embedding Extraction =====================
std::vector<float> extractEmbeddingONNX(const std::string &modelPath, const std::vector<float> &audio) {
    Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "SpeakerVerification");
    Ort::SessionOptions sessionOptions;
#if defined(_WIN32)
    std::string_view model_path_strv(modelPath);
    auto ort_model_path = std::wstring(model_path_strv.begin(), model_path_strv.end()).c_str();
#else
    auto ort_model_path = model_path;
#endif
    Ort::Session session(env, ort_model_path, sessionOptions);

    // Prepare input tensor (dummy reshape for example)
    std::vector<int64_t> inputShape = {1, 1, (int64_t)audio.size()};

    Ort::MemoryInfo memInfo = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
    Ort::Value inputTensor = Ort::Value::CreateTensor<float>(memInfo, const_cast<float*>(audio.data()), audio.size(), inputShape.data(), inputShape.size());

    auto outputNames = session.GetOutputNameAllocated(0, Ort::AllocatorWithDefaultOptions());
    auto inputNames = session.GetInputNameAllocated(0, Ort::AllocatorWithDefaultOptions());

    std::vector<const char*> inputNameVec = {inputNames.get()};
    std::vector<const char*> outputNameVec = {outputNames.get()};

    auto outputTensors = session.Run(
        Ort::RunOptions{nullptr},
        inputNameVec.data(), &inputTensor, 1,
        outputNameVec.data(), 1
    );

    // Extract output embedding
    float* outputData = outputTensors.front().GetTensorMutableData<float>();
    size_t outputSize = outputTensors.front().GetTensorTypeAndShapeInfo().GetElementCount();

    std::vector<float> embedding(outputData, outputData + outputSize);
    return embedding;
}

// ===================== Cosine Similarity for Embeddings =====================
double cosineSimilarity(const std::vector<float> &a, const std::vector<float> &b) {
    if (a.size() != b.size()) throw std::runtime_error("Embedding size mismatch");
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (size_t i = 0; i < a.size(); i++) {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }
    return dot / (sqrt(normA) * sqrt(normB) + 1e-8);
}

// Hann window
std::vector<float> hannWindow(int size) {
    std::vector<float> win(size);
    for (int i = 0; i < size; i++)
        win[i] = 0.5f - 0.5f * cosf(2.0f * M_PI * i / (size - 1));
    return win;
}

// DCT-II for MFCC
std::vector<std::vector<float>> dct(const std::vector<std::vector<float>>& logMel) {
    int numFrames = logMel.size();
    int numMels = logMel[0].size();
    std::vector<std::vector<float>> mfcc(numFrames, std::vector<float>(NUM_MFCC, 0.0f));
    for (int k = 0; k < NUM_MFCC; k++) {
        for (int n = 0; n < numMels; n++) {
            float coeff = cosf(M_PI * k * (2 * n + 1) / (2.0f * numMels));
            for (int t = 0; t < numFrames; t++)
                mfcc[t][k] += logMel[t][n] * coeff;
        }
    }
    return mfcc;
}

// Mel filterbank
std::vector<std::vector<float>> melFilterbank(int nMels, int fftSize, int sampleRate) {
    auto hzToMel = [](float hz) { return 2595.0f * log10f(1.0f + hz / 700.0f); };
    auto melToHz = [](float mel) { return 700.0f * (powf(10.0f, mel / 2595.0f) - 1.0f); };

    float melMin = hzToMel(0);
    float melMax = hzToMel(sampleRate / 2.0f);

    std::vector<float> melPoints(nMels + 2);
    for (int i = 0; i < nMels + 2; i++)
        melPoints[i] = melMin + (melMax - melMin) * i / (nMels + 1);

    std::vector<int> bin(nMels + 2);
    for (int i = 0; i < nMels + 2; i++)
        bin[i] = static_cast<int>(floor((fftSize + 1) * melToHz(melPoints[i]) / sampleRate));

    std::vector<std::vector<float>> fb(nMels, std::vector<float>(fftSize / 2 + 1, 0.0f));
    for (int m = 1; m <= nMels; m++) {
        for (int k = bin[m - 1]; k < bin[m]; k++)
            fb[m - 1][k] = (k - bin[m - 1]) / float(bin[m] - bin[m - 1]);
        for (int k = bin[m]; k < bin[m + 1]; k++)
            fb[m - 1][k] = (bin[m + 1] - k) / float(bin[m + 1] - bin[m]);
    }
    return fb;
}

// Compute MFCC
std::vector<std::vector<float>> computeMFCC(const std::vector<float>& pcm) {
    auto window = hannWindow(FFT_SIZE);
    auto melFB = melFilterbank(N_MELS, FFT_SIZE, SAMPLE_RATE);
    std::vector<std::vector<float>> logMelEnergies;

    for (size_t start = 0; start + FFT_SIZE <= pcm.size(); start += HOP_LENGTH) {
        std::vector<float> frame(window.size());
        for (size_t i = 0; i < window.size(); i++)
            frame[i] = pcm[start + i] * window[i];

        kiss_fft_cfg cfg = kiss_fft_alloc(FFT_SIZE, 0, nullptr, nullptr);
        std::vector<kiss_fft_cpx> in(FFT_SIZE), out(FFT_SIZE);
        for (int i = 0; i < FFT_SIZE; i++) {
            in[i].r = frame[i];
            in[i].i = 0;
        }
        kiss_fft(cfg, in.data(), out.data());
        free(cfg);

        std::vector<float> power(FFT_SIZE / 2 + 1);
        for (int i = 0; i <= FFT_SIZE / 2; i++)
            power[i] = (out[i].r * out[i].r + out[i].i * out[i].i) / FFT_SIZE;

        std::vector<float> melEnergies(N_MELS, 0.0f);
        for (int m = 0; m < N_MELS; m++) {
            for (int k = 0; k <= FFT_SIZE / 2; k++)
                melEnergies[m] += power[k] * melFB[m][k];
            melEnergies[m] = logf(melEnergies[m] + 1e-6f);
        }
        logMelEnergies.push_back(melEnergies);
    }
    return dct(logMelEnergies);
}

// ===================== MFCC Extraction =====================
class MFCC {
public:
    MFCC(int sampleRate, int numCoeffs = 13, int frameSize = 512, int hopSize = 256)
        : sr(sampleRate), numCoeffs(numCoeffs), frameSize(frameSize), hopSize(hopSize) {}

    std::vector<std::vector<float>> extract(const std::vector<float> &signal) {
		// Pre-emphasis
		std::vector<float> preEmphasized(signal.size());
		for (size_t i = 1; i < signal.size(); i++)
			preEmphasized[i] = signal[i] - 0.97 * signal[i - 1];

		// Frame blocking + Hamming window
		std::vector<std::vector<float>> frames;
		for (size_t start = 0; start + frameSize <= preEmphasized.size(); start += hopSize) {
			std::vector<float> frame(preEmphasized.begin() + start, preEmphasized.begin() + start + frameSize);
			for (int i = 0; i < frameSize; i++)
				frame[i] *= 0.54 - 0.46 * cos(2 * M_PI * i / (frameSize - 1));
			frames.push_back(frame);
		}

		// FFT + Mel filterbank + DCT
		std::vector<std::vector<float>> mfccs;
		for (auto &frame : frames) {
			Eigen::VectorXd spectrum = Eigen::VectorXd::Zero(frameSize / 2 + 1);
			// Simple magnitude spectrum (replace with FFT library for speed)
			for (size_t k = 0; k < spectrum.size(); k++) {
                float real = 0, imag = 0;
				for (size_t n = 0; n < frame.size(); n++) {
					real += frame[n] * cos(2 * M_PI * k * n / frameSize);
					imag -= frame[n] * sin(2 * M_PI * k * n / frameSize);
				}
				spectrum[k] = sqrt(real * real + imag * imag);
			}

			// Mel filterbank (simplified)
			std::vector<float> melEnergies(numCoeffs, 0.0);
			for (int m = 0; m < numCoeffs; m++) {
				for (int k = 0; k < spectrum.size(); k++)
					melEnergies[m] += spectrum[k] * exp(-0.5 * pow((k - m * 2), 2) / 4.0);
			}

			// Log + DCT
			for (auto &e : melEnergies) e = log(e + 1e-8);
			std::vector<float> coeffs(numCoeffs, 0.0);
			for (int i = 0; i < numCoeffs; i++) {
				for (int j = 0; j < numCoeffs; j++)
					coeffs[i] += melEnergies[j] * cos(M_PI * i * (j + 0.5) / numCoeffs);
			}
			mfccs.push_back(coeffs);
		}
		return mfccs;
	}

private:
    int sr, numCoeffs, frameSize, hopSize;
};

// ===================== Hybrid Speaker Verification =====================
typedef struct VoiceFeatures {
	std::vector<float> raw;
	
} VoiceFeatures_t;
class SpeakerVerifier {
public:
    SpeakerVerifier(const std::string &onnxModelPath, int sampleRate)
        : modelPath(onnxModelPath), sr(sampleRate), mfccExtractor(sampleRate) {}

    bool verify(const UnnuAudioSample_t &enrolledAudio, const UnnuAudioSample_t&audio,
			double dtwThreshold = 50.0, double cosineThreshold = 0.75) {
		// Load audio
		if (enrolledAudio.sample_rate != sr || audio.sample_rate != sr) throw std::runtime_error("Sample rate mismatch");
		auto enrollAudio = speech_sample_to_vector(enrolledAudio);
		auto testAudio = speech_sample_to_vector(audio);
	   

		// Classical MFCC + DTW
		auto mfccEnroll = mfccExtractor.extract(enrollAudio);
		auto mfccTest = mfccExtractor.extract(testAudio);
		double dtwDist = dtwDistance(mfccEnroll, mfccTest);

		// CNN Embeddings + Cosine Similarity
		auto embEnroll = extractEmbeddingONNX(modelPath, enrollAudio);
		auto embTest = extractEmbeddingONNX(modelPath, testAudio);
		double cosSim = cosineSimilarity(embEnroll, embTest);

		// Hybrid decision: both must pass
		return (dtwDist < dtwThreshold) && (cosSim > cosineThreshold);
	}

private:
    std::string modelPath;
    int sr;
    MFCC mfccExtractor;
};


void unnu_vad_speaker_add(int32_t id, UnnuAudioSample_t* sample) {
}

void unnu_vad_speaker_id(UnnuAudioSample_t* sample) {
	
}

bool unnu_vad_speaker_check(int32_t id, UnnuAudioSample_t* sample) {
	return false;
}

void unnu_vad_speaker_rm(int32_t id, UnnuAudioSample_t* sample) {
}

void unnu_vad_speaker_notify(int32_t id, UnnuAudioSample_t* sample) {
}

void unnu_vad_set_detect_callback(UnnuVoiceActivityCallback callback) {
}

void unnu_vad_unset_detect_callback() {
}

void unnu_vad_destroy(){
}

