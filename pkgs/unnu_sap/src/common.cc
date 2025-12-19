#include <filesystem>
#include "common.h"

void unnu_sap_text_free(UnnuSapTextStruct_t* ptr) {
	if (ptr != nullptr) {
		if(ptr->length > 0) free(ptr->text);
	}
	free(ptr);
}

void unnu_sap_audio_sample_free(UnnuAudioSample_t* audio){
	if (audio != nullptr) {
		if(audio->num_samples > 0) free(audio->samples);
	}
	free(audio);
}

static std::string get_lang_code_as_string(unnu_lang_code_t code){
	switch (code) {
		case LANG_EN: return "en"; // English
		case LANG_FR: return "fr"; // French
    	case LANG_ES: return "es"; // Spanish
		case LANG_DE: return "de"; // German)
		case LANG_IT: return "it"; // Italian
		case LANG_NL: return "nl"; // Dutch
		case LANG_PT: return "pt"; // Portugese
		case LANG_ZH: return "zh"; // Chinese
		case LANG_UNKNOWN: return "en";// Fallback for unsupported locales
		default: return "en";
    }
}

static std::pair<std::string, std::string> get_locale_as_canonical_pair(unnu_locale_code_t code){
	switch (code) {
		case LOCALE_EN_US: return std::pair("en_US","en"); // English (United States
		case LOCALE_EN_GB: return std::pair("en_GB","en"); // English (United Kingdom)
		case LOCALE_FR_FR: return std::pair("fr_FR","fr"); // French (France)
		case LOCALE_ES_ES: return std::pair("es_ES","es"); // Spanish (Spain)
		case LOCALE_DE_DE: return std::pair("de_De","de"); // German (Germany)
		case LOCALE_IT_IT: return std::pair("it_IT","it"); // Italian (Italy)
		case LOCALE_NL_NL: return std::pair("nl_NL","nl"); // Dutuch (Netherlands)
		case LOCALE_PT_PT: return std::pair("pt_PT","pt"); // Portugese (Portugal)
		case LOCALE_PT_BR: return std::pair("pt_BR","pt"); // Portugese (Brazil)
		case LOCALE_ZH_CN: return std::pair("zh_CN","zh"); // Chinese (China)
		case LOCALE_UNKNOWN: return std::pair("en_US","en"); // Fallback for unsupported locales
		default: return std::pair("en_US","en");;
    }
}

UnnuSapTextStruct* unnu_sap_get_asr_model_path(unnu_lang_code_t code, const char* model_dirpath) {
	std::filesystem::path model_dir(model_dirpath);
	auto& langcode = get_lang_code_as_string(code);
	if (std::filesystem::exists(model_dir/langcode)) {
		model_dir /= langcode;
	} else if(!std::filesystem::exists(model_dir)){
		model_dir.clear();
	}
	std::string modeldirectory = model_dir.generic_string();
	UnnuSapTextStruct* t = (UnnuSapTextStruct*)malloc(sizeof(UnnuSapTextStruct));
	auto len = strlen(modeldirectory.c_str());
	t->length = len;
	t->text = (char*)std::calloc(len + 1, sizeof(char));
	if (len > 0) {
		std::memcpy(t->text, modeldirectory.c_str(), len);
	}
	t->text[len] = '\0';
	return t;
}

UnnuSapTextStruct* unnu_sap_get_tts_model_path(unnu_locale_code_t code, const char* model_dirpath){
	auto& pair =  get_locale_as_canonical_pair(code);
	std::filesystem::path model_dir(model_dirpath);
	if (std::filesystem::exists(model_dir/pair.first)) {
		model_dir /= pair.first;
	} else if (std::filesystem::exists(model_dir/pair.second)) {
		model_dir /= pair.second;
	} else if(!std::filesystem::exists(model_dir)) {
		model_dir.clear();
	}

	std::string modeldirectory = model_dir.generic_string();
	UnnuSapTextStruct* t = (UnnuSapTextStruct*)malloc(sizeof(UnnuSapTextStruct));
	auto len = strlen(modeldirectory.c_str());
	t->length = len;
	t->text = (char*)std::calloc(len + 1, sizeof(char));
	if (len > 0) {
		std::memcpy(t->text, modeldirectory.c_str(), len);
	}
	t->text[len] = '\0';
	return t;
}
