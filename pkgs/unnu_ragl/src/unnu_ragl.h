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
	char* ref_id;
	int reflen;
	char* text;
	int length;
	UnnuRaglFragment_t** fragments;
	int64_t count;
} UnnuRaglResult_t;

typedef struct  UnnuRagEmbdVec {
	UnnuRaglResultType_t type;
	char* ref_id;
	int reflen;
	char* text;
	int length;
	float* values;
	int64_t count;
} UnnuRagEmbdVec_t;

typedef void (*UnnuRaglResponseCallback)(UnnuRaglResult_t* response);

typedef void (*UnnuRaglEmbeddingCallback)(UnnuRagEmbdVec_t* embedding);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_rag_lite_open_kb(char* db_path, int* errorCode);

// FFI_PLUGIN_EXPORT void unnu_rag_lite_open_memory(char* mem_id, int* errorCode);

FFI_PLUGIN_EXPORT void unnu_rag_lite_closeall_kb();
// FFI_PLUGIN_EXPORT void unnu_rag_lite_close_kb(char* tag);

FFI_PLUGIN_EXPORT void unnu_rag_lite_init(const char* path);

FFI_PLUGIN_EXPORT void unnu_rag_lite_query(const char* text);

FFI_PLUGIN_EXPORT void unnu_rag_lite_retrieve(const char* uri);

FFI_PLUGIN_EXPORT void unnu_rag_lite_mapping(const char* uri, const char* document_id);

FFI_PLUGIN_EXPORT void unnu_rag_lite_delete(const char* document_id, const char* uri);

FFI_PLUGIN_EXPORT void unnu_rag_lite_embed(const char* text);

FFI_PLUGIN_EXPORT void unnu_rag_lite_update_dims(int32_t sz);

FFI_PLUGIN_EXPORT void unnu_rag_lite_result_limit(int32_t sz);

FFI_PLUGIN_EXPORT void unnu_rag_lite_enable_paragraph_chunking(int8_t val);

FFI_PLUGIN_EXPORT void unnu_rag_lite_set_chunk_size(int32_t val);

FFI_PLUGIN_EXPORT void unnu_rag_lite_set_pooling_type(int32_t val);

FFI_PLUGIN_EXPORT void unnu_set_ragl_result_callback(UnnuRaglResponseCallback callback);

FFI_PLUGIN_EXPORT void unnu_set_ragl_embedding_callback(UnnuRaglEmbeddingCallback callback);

FFI_PLUGIN_EXPORT void unnu_ragl_free_result(UnnuRaglResult_t* result);

FFI_PLUGIN_EXPORT void unnu_ragl_free_embedvector(UnnuRagEmbdVec_t* vec);

FFI_PLUGIN_EXPORT void unnu_unset_ragl_result_callback();

FFI_PLUGIN_EXPORT void unnu_unset_ragl_embedding_callback();

FFI_PLUGIN_EXPORT void unnu_rag_lite_destroy();

#endif // _UNNU_RAG_LITE_H
