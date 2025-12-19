#ifndef _UNNU_DOCPARSER_PRO_H
#define _UNNU_DOCPARSER_PRO_H

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

typedef enum UnnuDxpDataType : uint8_t {
	UNNU_DXP_BOOL,
	UNNU_DXP_INT,
	UNNU_DXP_FLOAT,
	UNNU_DXP_STRING,
	UNNU_DXP_XML,
	UNNU_DXP_JSON,
	UNNU_DXP_BINARY,
	UNNU_DXP_ERROR
} UnnuDxpDataType_t;

typedef struct UnnuDxpDataValue {
	UnnuDxpDataType_t type;
	union {
		bool boolvalue;
		int intvalue;
		float floatvalue;
		int error;
		char* value;
	} data;
	int length;
} UnnuDxpDataValue_t;

typedef struct UnnuDxpMetaDataEntry {
	char* key;
	int length;
	UnnuDxpDataValue_t value;
} UnnuDxpMetaDataEntry_t;

typedef struct UnnuDxpParseResult {
	UnnuDxpDataType_t type;
	char* buffer;
	int length;
	UnnuDxpMetaDataEntry_t* metadata;
	int num_metadata_entries;

} UnnuDxpParseResult_t;


typedef void (*UnnuDxpResultCallback)(UnnuDxpParseResult_t result);

#ifdef __cplusplus
}
#endif

FFI_PLUGIN_EXPORT void unnu_dxp_parse(const char* filepath);

FFI_PLUGIN_EXPORT void unnu_dxp_set_parse_callback(UnnuDxpResultCallback parse_callback);

FFI_PLUGIN_EXPORT void unnu_dxp_unset_parse_callback();

#endif // _UNNU_DOCPARSER_PRO_H