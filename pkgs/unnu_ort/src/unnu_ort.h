#ifndef _UNNU_ORT_H
#define _UNNU_ORT_H

#ifdef __cplusplus
	#ifdef WIN32
		#define FFI_PLUGIN_EXPORT extern "C" __declspec(dllexport)
	#else
		#define FFI_PLUGIN_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
	#endif
#else
	#define FFI_PLUGIN_EXPORT extern
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

typedef enum UnnuOrtOperationType : uint8_t {
	UNNU_ORT_CNER,
	UNNU_ORT_EMBEDDING,
	UNNU_ORT_TOKENIZE,
} UnnuOrtOperationType_t;

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_ort_init();

FFI_PLUGIN_EXPORT void unnu_ort_destroy();

FFI_PLUGIN_EXPORT void unnu_ort_cner(UnnuOrtOperationType_t type, const char* text, int length);


#endif // _UNNU_ORT_H