#ifndef _UNNU_RAG_LITE_H
#define _UNNU_RAG_LITE_H

#ifdef __cplusplus
	#ifdef WIN32
		#define FFI_PLUGIN_EXPORT extern "C" __declspec(dllexport)
	#else
		#define FFI_PLUGIN_EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
	#endif // WIN32
	#include <cstdint>
	#include <cstdbool>
	
#else // __cplusplus - Objective-C or other C platform
	#define FFI_PLUGIN_EXPORT extern
	#include <stdint.h>
	#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C"
{
#endif


typedef enum UnnuRaglResultType : uint8_t {
	UNNU_RAGL_QUERY,
	UNNU_RAGL_EMBEDDING,
	UNNU_RAGL_FINISH,
	UNNU_RAGL_ERROR
} UnnuRaglResultType_t;

typedef struct  UnnuRaglFragment {
	char* text;
	int length;
} UnnuRaglFragment_t;

typedef struct  UnnuRaglResult {
	UnnuRaglResultType_t type;
	char* text;
	int length;
	UnnuRaglFragment_t* fragments;
	int64_t count;
} UnnuRaglResult_t;

typedef void (*UnnuRaglResponseCallback)(UnnuRaglResult_t* response);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_rag_lite_open_kb(char* db_path, int* errorCode);

FFI_PLUGIN_EXPORT void unnu_rag_lite_open_memory(char* mem_id, int* errorCode);

FFI_PLUGIN_EXPORT void unnu_rag_lite_closeall_kb();
// FFI_PLUGIN_EXPORT void unnu_rag_lite_close_kb(char* tag);

FFI_PLUGIN_EXPORT void unnu_rag_lite_init(const char* path);

FFI_PLUGIN_EXPORT void unnu_rag_lite_query(const char* text);

FFI_PLUGIN_EXPORT void unnu_rag_lite_embed(const char* text);

FFI_PLUGIN_EXPORT void unnu_set_ragl_result_callback(UnnuRaglResponseCallback callback);

FFI_PLUGIN_EXPORT void unnu_unset_ragl_result_callback();

FFI_PLUGIN_EXPORT void unnu_rag_lite_destroy();

#endif // _UNNU_RAG_LITE_H
