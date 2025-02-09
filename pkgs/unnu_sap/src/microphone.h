#ifndef UNNU_ASR_MICROPHONE_H_
#define UNNU_ASR_MICROPHONE_H_
#include <cstdint>

#include <portaudio.h>  // NOLINT
namespace unnu_asr {

class Microphone {
 public:
  Microphone();
  ~Microphone();

  int32_t GetDeviceCount() const;
  int32_t GetDefaultInputDevice() const;

  bool OpenDevice(int32_t index, int32_t sample_rate, int32_t channel,
                  PaStreamCallback cb, void *userdata);

  void CloseDevice();

 private:
  PaStream *stream = nullptr;
  PaError status = paNoError;
};

}  // namespace unnu_asr

#endif  // UNNU_ASR_MICROPHONE_H_
