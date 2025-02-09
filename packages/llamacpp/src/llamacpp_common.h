#pragma once

#ifdef __cplusplus
#ifdef WIN32
#define FFI_PLUGIN_EXPORT extern "C" __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif // WIN32
#include <cstdint>
#include <cstdbool>

#else // __cplusplus - Objective-C or other C platform
#ifdef WIN32
#define FFI_PLUGIN_EXPORT extern
#else
#define FFI_PLUGIN_EXPORT extern __attribute__((visibility("default"))) __attribute__((used))
#endif
#include <stdint.h>
#include <stdbool.h>
#endif
