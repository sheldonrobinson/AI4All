#ifndef _UNNU_DOCPARSER_LITE_H
#define _UNNU_DOCPARSER_LITE_H

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

typedef enum UnnuDxlDataType : uint8_t {
	UNNU_DXL_BOOL,
	UNNU_DXL_INT,
	UNNU_DXL_FLOAT,
	UNNU_DXL_STRING,
	UNNU_DXL_XML,
	UNNU_DXL_JSON,
	UNNU_DXL_BINARY,
	UNNU_DXL_ERROR
} UnnuDxlDataType_t;

typedef union UnnuDxlValue {
	bool boolvalue;
	int intvalue;
	float floatvalue;
	int error;
	char* value;
} UnnuDxlValue_t;

typedef struct UnnuDxlDataValue {
	UnnuDxlDataType_t type;
	UnnuDxlValue_t data;
	int length;
} UnnuDxlDataValue_t;

typedef struct UnnuDxlMetaDataEntry {
	char* key;
	int length;
	UnnuDxlDataValue_t value;
} UnnuDxlMetaDataEntry_t;

typedef struct UnnuDxlParseResult {
	UnnuDxlDataType_t type;
	char* buffer;
	int length;
	UnnuDxlMetaDataEntry_t* metadata;
	int num_metadata_entries;

} UnnuDxlParseResult_t;


typedef void (*UnnuDxlResultCallback)(UnnuDxlParseResult_t* result);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_dxl_parse(const char* filepath);

FFI_PLUGIN_EXPORT void unnu_dxl_set_parse_callback(UnnuDxlResultCallback parse_callback);

FFI_PLUGIN_EXPORT void unnu_dxl_free_result(UnnuDxlParseResult_t* result);

FFI_PLUGIN_EXPORT void unnu_dxl_unset_parse_callback();


#endif // _UNNU_DOCPARSER_LITE_H

