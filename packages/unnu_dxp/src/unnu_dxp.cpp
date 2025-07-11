#include <float.h>
#include <time.h>
#include <queue>
#include <atomic>
#include <thread>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sstream>
#include <filesystem>
#include <iostream>

#include "log.h"
#include "content_type.h"
#include "decompress_archives.h"
#include "parsing_chain.h"
#include "input.h"
#include "output.h"
#include "plain_text_exporter.h"

#include "unnu_dxp.h"


enum class OutputType { plain_text, html, csv, metadata };

UnnuDxpResultCallback result_cb = nullptr;

using namespace docwire;


void _input(std::string& text) {
	if (result_cb != nullptr) {
		UnnuDxpParseResult_t result;
		result.type = UNNU_DXP_STRING;
		result.num_metadata_entries = 0;
		result.length = text.length();
		result.buffer = (char*)std::calloc(result.length + 1, sizeof(char));
		std::memcpy(result.buffer, text.c_str(), result.length + 1);

		result_cb(result);
	}
}


void unnu_dxp_parse(const char* filepath) {
	set_log_verbosity(severity_level::error);
	set_log_stream(&std::cerr);
	std::ostringstream oss;
	auto chain = (std::filesystem::path{ filepath } | DecompressArchives());
	chain |= content_type::detector{};
	chain |= PlainTextExporter();
	chain |= oss;
	auto result = oss.rdbuf()->str();
	if (!result.empty()) {
		_input(result);
	}
	
}


void unnu_dxp_set_parse_callback(UnnuDxpResultCallback parse_callback){
	result_cb = parse_callback;
}

void unnu_dxp_unset_parse_callback(){
	result_cb = nullptr;
}