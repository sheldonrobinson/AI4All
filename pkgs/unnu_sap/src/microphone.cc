#include "microphone.h"

#include <stdio.h>
#include <stdlib.h>

namespace unnu_asr {

Microphone::Microphone() {
  status = Pa_Initialize();
#if defined(_DEBUG)
  if (status != paNoError) {
    fprintf(stderr, "portaudio error: %s\n", Pa_GetErrorText(status));
  }
#endif
}

Microphone::~Microphone() {
  CloseDevice();
  status = Pa_Terminate();
#if defined(_DEBUG)
  if (status != paNoError) {
      fprintf(stderr, "portaudio error: %s\n", Pa_GetErrorText(status));
  }
#endif
}

int Microphone::GetDeviceCount() const { return Pa_GetDeviceCount(); }

int Microphone::GetDefaultInputDevice() const {
  return Pa_GetDefaultInputDevice();
}

bool Microphone::OpenDevice(int index, int sample_rate, int channel,
                            PaStreamCallback cb, void *userdata) {
  if (index < 0 || index >= Pa_GetDeviceCount()) {
#if defined(_DEBUG)
    fprintf(stderr, "Invalid device index: %d\n", index);
#endif
    return false;
  }

  const PaDeviceInfo *info = Pa_GetDeviceInfo(index);
  if (!info) {
#if defined(_DEBUG)
    fprintf(stderr, "No device info found for index: %d\n", index);
#endif
    return false;
  }

  PaStreamParameters param;
  param.device = index;
  param.channelCount = channel;
  param.sampleFormat = paFloat32;
  param.suggestedLatency = info->defaultLowInputLatency;
  param.hostApiSpecificStreamInfo = nullptr;

  status =
      Pa_OpenStream(&stream, &param, nullptr, /* &outputParameters, */
                    sample_rate,
                    0,          // frames per buffer
                    paClipOff,  // we won't output out of range samples
                                // so don't bother clipping them
                    cb, userdata);
  if (status != paNoError) {
#if defined(_DEBUG)
    fprintf(stderr, "portaudio error: %s\n", Pa_GetErrorText(status));
#endif
    return false;
  }

  status = Pa_StartStream(stream);

  if (status != paNoError) {
#if defined(_DEBUG)
    fprintf(stderr, "portaudio error: %s\n", Pa_GetErrorText(status));
#endif
    CloseDevice();
    return false;
  }
  return true;
}

void Microphone::CloseDevice() {
  if (stream) {
      status = Pa_CloseStream(stream);
#if defined(_DEBUG)
    if (status != paNoError) {
      fprintf(stderr, "Pa_CloseStream error: %s\n", Pa_GetErrorText(status));
    }
#endif
    stream = nullptr;
  }
}

} 
