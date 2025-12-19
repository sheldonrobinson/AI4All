#include <vector>
#include <numeric>
#include <libconfig.h++>
#include <dlib/dir_nav.h>
#include <hashpp.h>
#include <yaml-cpp/yaml.h>
#include <cpuinfo.h>

#include "unnu_aux.h"

void unnu_aux_free_text(UnnuTextStruct_t* ptr) {
	if (ptr != nullptr) {
		if (ptr->length > 0) free(ptr->text);
        free(ptr);
	}
}

void unnu_aux_update_corpora(const char* path) {
	if (dlib::file_exists(path)) {
		std::string filepath(path);
		YAML::Node yamlfile = YAML::LoadFile(filepath);
		std::set<std::string> filelist;
		YAML::Node node;
		if (yamlfile["kbase"].IsDefined() && yamlfile["kbase"].IsScalar()) {
			node["kbase"] = yamlfile["kbase"].as<std::string>();
		}
		if (yamlfile["links"].IsDefined() && yamlfile["links"].IsSequence()) {
			YAML::Node remotes = yamlfile["links"];
			int n_remote = remotes.size();
			std::set<std::string> links;
			for (std::size_t i = 0; i < n_remote; i++) {
				links.insert(remotes[i].as<std::string>());
			}
			std::vector<std::string> ww(links.begin(), links.end());
			node["links"] = ww;
		}
		if (yamlfile["entries"].IsDefined() && yamlfile["entries"].IsSequence()) {
			YAML::Node entries = yamlfile["entries"];
			int n_entries = entries.size();
			for (std::size_t i = 0; i < n_entries; i++) {
				filelist.insert(entries[i].as<std::string>());
			}
			std::vector<std::string> vv(filelist.begin(), filelist.end());
			node["entries"] = vv;

			std::set<std::string> files;
			for (auto it = filelist.cbegin(), end = filelist.cend(); it != end; it++) {
				auto _file = *it;
				if (dlib::file_exists(_file)) {
					files.insert(_file);
				}
				else if (dlib::directory_exists(_file)) {
					auto _directory = dlib::directory::directory(_file);
					std::vector < dlib::file> _files = _directory.get_files();
					for (auto itdlib = _files.cbegin(), end = _files.cend(); itdlib != end; itdlib++) {
						dlib::file f = *itdlib;
						files.insert(f.full_name());
					}
				}
			}
			std::vector<std::string> uu(files.begin(), files.end());
			node["local"] = uu;
		}
		if (node.IsDefined() && !node.IsNull()) {
			std::ofstream fout(path);
			fout << node;
		}
	}
}

UnnuTextStruct_t* unnu_aux_hash(const char* path) {
	if (dlib::file_exists(path)) {

		auto hash = hashpp::get::getFileHash(hashpp::ALGORITHMS::SHA2_256, path);
		std::string val = hash.getString();

		UnnuTextStruct_t* ret = (UnnuTextStruct_t*)malloc(sizeof(UnnuTextStruct_t));
		int len = val.length();
		ret->length = len;
		ret->text = (char*)calloc(len + 1, sizeof(char));
		std::memcpy(ret->text, val.c_str(), len);
		ret->text[len] = '\0';
		return ret;

	}
	else if (dlib::directory_exists(path)) {
		auto _directory = dlib::directory::directory(path);
		std::vector < dlib::file> _files = _directory.get_files();

		std::vector<std::string> v2(_files.size());
		// Incrementing all elements of vector by 1
		std::transform(_files.begin(), _files.end(), v2.begin(),
			[](dlib::file f) {
				return f.full_name();
			});

		// create a FilePathsContainer object andset its algorithm and some paths
		hashpp::FilePathsContainer paths(hashpp::ALGORITHMS::SHA2_256, v2);

		// get the hashes of each file via get::getFilesHashes
		// and store them in a hashCollection object
		hashpp::hashCollection hashes = hashpp::get::getFilesHashes(paths);

		std::vector<std::string> sha256s = hashes["SHA2 - 256"];

		std::string a = std::reduce(sha256s.begin(), sha256s.end(), std::string());

		auto hash = hashpp::get::getHash(hashpp::ALGORITHMS::SHA2_256, a);
		std::string val = hash.getString();

		UnnuTextStruct_t* ret = (UnnuTextStruct_t*)malloc(sizeof(UnnuTextStruct_t));
		int len = val.length();
		ret->length = len;
		ret->text = (char*)calloc(len + 1, sizeof(char));
		std::memcpy(ret->text, val.c_str(), len);
		ret->text[len] = '\0';
		return ret;
	}
	else {
		UnnuTextStruct_t* ret = (UnnuTextStruct_t*)malloc(sizeof(UnnuTextStruct_t));
		ret->length = 0;
		ret->text = nullptr;
		return ret;
	}

}

UnnuAuxConfigSetting_t* _populate(const libconfig::Setting& settings, std::vector<std::string> fields, UnnuAuxConfigSetting_t* _result) {
	// UnnuAuxConfigSetting_t* _result = (UnnuAuxConfigSetting_t*) malloc(sizeof(UnnuAuxConfigSetting_t));
	libconfig::Setting::Type _type = settings.getType();
	switch (_type) {
	case libconfig::Setting::TypeList:
	{
		std::vector<UnnuAuxConfigSetting_t*> _settings;
		for (libconfig::Setting const& setting : settings) {
			if (setting.isGroup()) {
				std::vector<UnnuAuxConfigSetting_t*> _fields;
				for (std::string field : fields) {
					try {
						std::string tmp;
						if (setting.lookupValue(field, tmp)) {
							UnnuAuxConfigSetting_t* _setting = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
							int nchars_field = field.length();
							_setting->name = (char*)calloc(nchars_field + 1, sizeof(char));
							std::memcpy(_setting->name, field.c_str(), nchars_field);
							_setting->name[nchars_field] = '\0';
							_setting->n_name = nchars_field;
							int field_len = tmp.length();
							_setting->value.sval = (char*)calloc(field_len + 1, sizeof(char));
							std::memcpy(_setting->value.sval, tmp.c_str(), field_len);
							_setting->value.sval[field_len] = '\0';
							_setting->length = field_len;
							_setting->type = UNNU_AUX_CONFIG_STRING;
							_fields.push_back(_setting);
						}
					}
					catch (const libconfig::SettingNotFoundException& nfex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "No setting found for %s : %s\n", nfex.getPath(), nfex.what());
#endif
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					}
				}

				UnnuAuxConfigSetting_t* _value = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
				_value->name = nullptr;
				_value->n_name = 0;
				_value->type = !_fields.empty() ? UNNU_AUX_CONFIG_LIST : UNNU_AUX_CONFIG_NONE;
				if (!_fields.empty()) {
					_value->value.list = (UnnuAuxConfigList*)malloc(sizeof(UnnuAuxConfigList));
					_value->length = 1;
					int nelements = _fields.size();
					_value->value.list->elements = (UnnuAuxConfigSetting_t**)calloc(nelements, sizeof(UnnuAuxConfigSetting_t*));
					_value->value.list->count = nelements;
					std::memcpy(_value->value.list->elements, _fields.data(), nelements * sizeof(UnnuAuxConfigSetting_t*));
					_settings.push_back(_value);
				}
			}
		}
		_result->type = !_settings.empty() ? UNNU_AUX_CONFIG_LIST : UNNU_AUX_CONFIG_NONE;
		if (!_settings.empty()) {
			_result->value.list = (UnnuAuxConfigList*)malloc(sizeof(UnnuAuxConfigList));
			_result->length = 1;
			int nelements = _settings.size();
			_result->value.list->elements = (UnnuAuxConfigSetting_t**)calloc(nelements, sizeof(UnnuAuxConfigSetting_t*));
			_result->value.list->count = nelements;
			std::memcpy(_result->value.list->elements, _settings.data(), nelements * sizeof(UnnuAuxConfigSetting_t*));
		}
		else {
			_result->length = 0;
		}

	}
	break;
	case libconfig::Setting::TypeGroup:
	{
		std::vector<UnnuAuxConfigSetting_t*> _fields;
		for (std::string field : fields) {
			try {
				std::string tmp;
				if (settings.lookupValue(field, tmp)) {
					UnnuAuxConfigSetting_t* _setting = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
					int nchars_field = field.length();
					_setting->name = (char*)calloc(nchars_field + 1, sizeof(char));
					std::memcpy(_setting->name, field.c_str(), nchars_field);
					_setting->name[nchars_field] = '\0';
					_setting->n_name = nchars_field;
					int field_len = tmp.length();
					_setting->value.sval = (char*)calloc(field_len + 1, sizeof(char));
					std::memcpy(_setting->value.sval, tmp.c_str(), field_len);
					_setting->value.sval[field_len] = '\0';
					_setting->length = field_len;
					_setting->type = UNNU_AUX_CONFIG_STRING;
					_fields.push_back(_setting);
				}
			}
			catch (const libconfig::SettingNotFoundException& nfex)
			{
				// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
				fprintf(stderr, "No setting found for %s : %s\n", nfex.getPath(), nfex.what());
#endif
			}
			catch (const libconfig::SettingTypeException& stex)
			{
				// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
				fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
			}
		}
		_result->type = !_fields.empty() ? UNNU_AUX_CONFIG_LIST : UNNU_AUX_CONFIG_NONE;
		if (!_fields.empty()) {
			_result->value.list = (UnnuAuxConfigList*)malloc(sizeof(UnnuAuxConfigList));
			_result->length = 1;
			int nelements = _fields.size();
			_result->value.list->elements = (UnnuAuxConfigSetting_t**)calloc(nelements, sizeof(UnnuAuxConfigSetting_t*));
			_result->value.list->count = nelements;
			std::memcpy(_result->value.list->elements, _fields.data(), nelements * sizeof(UnnuAuxConfigSetting_t*));
		}
		else {
			_result->length = 0;
		}
	}
	break;
	case libconfig::Setting::TypeArray:
		if (settings.getLength() == 1) {
			switch (settings[0].getType()) {
			case libconfig::Setting::TypeString:
				_result->type = UNNU_AUX_CONFIG_STRING;
				try {
					auto _string = settings.operator const char* ();
					int nchars = strlen(_string);
					_result->value.sval = (char*)calloc(nchars + 1, sizeof(char));
					std::memcpy(_result->value.sval, _string, nchars);
					_result->value.sval[nchars] = '\0';
					_result->length = nchars;
				}
				catch (const libconfig::SettingTypeException& stex)
				{
					// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
					fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					_result->type = UNNU_AUX_CONFIG_NONE;
					_result->length = 0;
				}
				break;
			case libconfig::Setting::TypeFloat:
				_result->type = UNNU_AUX_CONFIG_FLOAT;
				try {
					_result->value.fval = settings.operator float();
					_result->length = 1;
				}
				catch (const libconfig::SettingTypeException& stex)
				{
					// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
					fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					_result->type = UNNU_AUX_CONFIG_NONE;
					_result->length = 0;
				}
				break;
			case libconfig::Setting::TypeInt:
				_result->type = UNNU_AUX_CONFIG_INT;
				try {
					_result->value.ival = settings.operator int();
					_result->length = 1;
				}
				catch (const libconfig::SettingTypeException& stex)
				{
					// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
					fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					_result->type = UNNU_AUX_CONFIG_NONE;
					_result->length = 0;
				}
				break;
			case libconfig::Setting::TypeBoolean:
				_result->type = UNNU_AUX_CONFIG_BOOL;
				try {
					_result->value.bval = settings.operator bool() ? 1 : 0;
					_result->length = 1;
				}
				catch (const libconfig::SettingTypeException& stex)
				{
					// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
					fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					_result->type = UNNU_AUX_CONFIG_NONE;
					_result->length = 0;
				}
				break;
			case libconfig::Setting::TypeInt64:
				_result->type = UNNU_AUX_CONFIG_LONG;
				try {
					_result->value.lval = settings.operator long();
					_result->length = 1;
				}
				catch (const libconfig::SettingTypeException& stex)
				{
					// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
					fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					_result->type = UNNU_AUX_CONFIG_NONE;
					_result->length = 0;
				}
				break;
			case libconfig::Setting::TypeNone:
				_result->type = UNNU_AUX_CONFIG_NONE;
				_result->length = 0;
				break;
			default:
				_result->type = UNNU_AUX_CONFIG_NONE;
				_result->length = 0;
				break;
			}

		}
		else if (settings.getLength() == fields.size()) { // using the fields are property names
			int idx = 0;
			std::vector<UnnuAuxConfigSetting_t*> _fields;
			for (libconfig::Setting const& setting : settings) {
				std::string field = fields[idx];
				UnnuAuxConfigSetting_t* _setting = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
				int nchars_field = field.length();
				_setting->name = (char*)calloc(nchars_field + 1, sizeof(char));
				std::memcpy(_setting->name, field.c_str(), nchars_field);
				_setting->name[nchars_field] = '\0';
				_setting->n_name = nchars_field;

				switch (setting.getType()) {
				case libconfig::Setting::TypeString:
				{
					_setting->type = UNNU_AUX_CONFIG_STRING;
					try {
						auto _string = setting.operator const char* ();
						int nchars = strlen(_string);
						_setting->value.sval = (char*)calloc(nchars + 1, sizeof(char));
						std::memcpy(_setting->value.sval, _string, nchars);
						_setting->value.sval[nchars] = '\0';
						_setting->length = nchars;
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
						_setting->type = UNNU_AUX_CONFIG_NONE;
						_setting->length = 0;
					}
				}
				break;
				case libconfig::Setting::TypeFloat:
				{
					_setting->type = UNNU_AUX_CONFIG_FLOAT;
					try {
						_setting->value.fval = settings.operator float();
						_setting->length = 1;
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
						_setting->type = UNNU_AUX_CONFIG_NONE;
						_setting->length = 0;
					}
				}
				break;
				case libconfig::Setting::TypeInt:
					_setting->type = UNNU_AUX_CONFIG_INT;
					try {
						_setting->value.ival = settings.operator int();
						_setting->length = 1;
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
						_setting->type = UNNU_AUX_CONFIG_NONE;
						_setting->length = 0;
					}
					break;
				case libconfig::Setting::TypeBoolean:
					_setting->type = UNNU_AUX_CONFIG_BOOL;
					try {
						_setting->value.bval = settings.operator bool() ? 1 : 0;
						_setting->length = 1;
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
						_setting->type = UNNU_AUX_CONFIG_NONE;
						_setting->length = 0;
					}
					break;
				case libconfig::Setting::TypeInt64:
					_setting->type = UNNU_AUX_CONFIG_LONG;
					try {
						_setting->value.lval = settings.operator long();
						_setting->length = 1;
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
						_setting->type = UNNU_AUX_CONFIG_NONE;
						_setting->length = 0;
					}
					break;
				default:
					_setting->type = UNNU_AUX_CONFIG_NONE;
					_setting->length = 0;
					break;
				}
				_fields.push_back(_setting);
				idx++;
			}
			_result->type = !_fields.empty() ? UNNU_AUX_CONFIG_LIST : UNNU_AUX_CONFIG_NONE;
			if (!_fields.empty()) {
				_result->value.list = (UnnuAuxConfigList*)malloc(sizeof(UnnuAuxConfigList));
				_result->length = 1;
				int nelements = _fields.size();
				_result->value.list->elements = (UnnuAuxConfigSetting_t**)calloc(nelements, sizeof(UnnuAuxConfigSetting_t*));
				_result->value.list->count = nelements;
				std::memcpy(_result->value.list->elements, _fields.data(), nelements * sizeof(UnnuAuxConfigSetting_t*));
			}
			else {
				_result->length = 0;
			}
		}
		else if (settings.getLength() > 0) {
			int length = settings.getLength();
			_result->length = length;
			switch (settings[0].getType()) {
			case libconfig::Setting::TypeString:
			{
				_result->type = UNNU_AUX_CONFIG_STR_ARRAY;
				char** _strings = (char**)malloc(length * sizeof(char*));
				int idx = 0;
				for (libconfig::Setting const& setting : settings) {
					try {
						auto _string = setting.operator const char* ();
						int nchars = strlen(_string);
						_strings[idx] = (char*)calloc(nchars + 1, sizeof(char));
						std::memcpy(_strings[idx], _string, nchars);
						_strings[idx][nchars] = '\0';
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
						_strings[idx][0] = '\0';

					}
					idx++;
				}
				_result->value.object = (void*)_strings;
			}
			break;
			case libconfig::Setting::TypeFloat:
			{
				_result->type = UNNU_AUX_CONFIG_FLOAT;
				float* _values = (float*)malloc(length * sizeof(float));
				int idx = 0;
				for (libconfig::Setting const& setting : settings) {
					try {
						_values[idx] = settings.operator float();
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					}
					idx++;
				}
				_result->value.object = (void*)_values;

			}
			break;
			case libconfig::Setting::TypeInt:
			{
				_result->type = UNNU_AUX_CONFIG_INT;
				int* _values = (int*)malloc(length * sizeof(int));
				int idx = 0;
				for (libconfig::Setting const& setting : settings) {
					try {
						_values[idx] = settings.operator int();
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					}
					idx++;
				}
				_result->value.object = (void*)_values;

			}
			break;
			case libconfig::Setting::TypeBoolean:
			{
				_result->type = UNNU_AUX_CONFIG_BOOL;
				int8_t* _values = (int8_t*)malloc(length * sizeof(int8_t));
				int idx = 0;
				for (libconfig::Setting const& setting : settings) {
					try {
						_values[idx] = settings.operator bool() ? 1 : 0;
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					}
					idx++;
				}
				_result->value.object = (void*)_values;

			}
			case libconfig::Setting::TypeInt64:
			{
				_result->type = UNNU_AUX_CONFIG_LONG;
				int64_t* _values = (int64_t*)malloc(length * sizeof(int64_t));
				int idx = 0;
				for (libconfig::Setting const& setting : settings) {
					try {
						_values[idx] = settings.operator long();
					}
					catch (const libconfig::SettingTypeException& stex)
					{
						// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
						fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
					}
					idx++;
				}
				_result->value.object = (void*)_values;
			}
			break;
			}
		}

		break;
	case libconfig::Setting::TypeString:
		_result->type = UNNU_AUX_CONFIG_STRING;
		try {
			auto _string = settings.operator const char* ();
			int nchars = strlen(_string);
			_result->value.sval = (char*)calloc(nchars + 1, sizeof(char));
			std::memcpy(_result->value.sval, _string, nchars);
			_result->value.sval[nchars] = '\0';
			_result->length = nchars;
		}
		catch (const libconfig::SettingTypeException& stex)
		{
			// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
			_result->type = UNNU_AUX_CONFIG_NONE;
			_result->length = 0;
		}
		break;
	case libconfig::Setting::TypeFloat:
		_result->type = UNNU_AUX_CONFIG_FLOAT;
		try {
			_result->value.fval = settings.operator float();
			_result->length = 1;
		}
		catch (const libconfig::SettingTypeException& stex)
		{
			// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
			_result->type = UNNU_AUX_CONFIG_NONE;
			_result->length = 0;
		}
		break;
	case libconfig::Setting::TypeInt:
		_result->type = UNNU_AUX_CONFIG_INT;
		try {
			_result->value.ival = settings.operator int();
			_result->length = 1;
		}
		catch (const libconfig::SettingTypeException& stex)
		{
			// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
			_result->type = UNNU_AUX_CONFIG_NONE;
			_result->length = 0;
		}
		break;
	case libconfig::Setting::TypeBoolean:
		_result->type = UNNU_AUX_CONFIG_BOOL;
		try {
			_result->value.bval = settings.operator bool() ? 1 : 0;
			_result->length = 1;
		}
		catch (const libconfig::SettingTypeException& stex)
		{
			// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
			_result->type = UNNU_AUX_CONFIG_NONE;
			_result->length = 0;
		}
		break;
	case libconfig::Setting::TypeInt64:
		_result->type = UNNU_AUX_CONFIG_LONG;
		try {
			_result->value.lval = settings.operator long();
			_result->length = 1;
		}
		catch (const libconfig::SettingTypeException& stex)
		{
			// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "Error reading %s : %s\n", stex.getPath(), stex.what());
#endif
			_result->type = UNNU_AUX_CONFIG_NONE;
			_result->length = 0;
		}
		break;
	case libconfig::Setting::TypeNone:
		_result->type = UNNU_AUX_CONFIG_NONE;
		_result->length = 0;
		break;
	default:
		_result->type = UNNU_AUX_CONFIG_NONE;
		_result->length = 0;
		break;
	}
	return _result;
}


UnnuAuxConfig_t* unnu_aux_load_config(const char* filepath) {
	UnnuAuxConfig_t* configuration = (UnnuAuxConfig_t*)malloc(sizeof(UnnuAuxConfig_t));
	configuration->root = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));

	int slen = strlen("appconfig");
	configuration->root->name = (char*)calloc(slen + 1, sizeof(char));
	memcpy(configuration->root->name, "appconfig", slen);
	configuration->root->name[slen] = '\0';
	configuration->root->n_name = slen;
	configuration->root->attributes = nullptr;

	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
		return configuration;
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
		return configuration;
	}

	const libconfig::Setting& root = cfg.getRoot();

	UnnuAuxConfigSetting_t* _models = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
	int idx_models = -1;
	UnnuAuxConfigSetting_t* _corpora = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
	int idx_corpora = -1;
	UnnuAuxConfigSetting_t* _profiles = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
	int idx_profiles = -1;
	UnnuAuxConfigSetting_t* _conversations = (UnnuAuxConfigSetting_t*)malloc(sizeof(UnnuAuxConfigSetting_t));
	int idx_conversations = -1;
	int n_sections = 0;

	try
	{
		int nchars_models = strlen("models");
		_models->name = (char*)calloc(nchars_models + 1, sizeof(char));
		std::memcpy(_models->name, "models", nchars_models);
		_models->name[nchars_models] = '\0';
		_models->n_name = nchars_models;

		const libconfig::Setting& models = root["models"];
		std::vector<std::string> fields = { "uri", "id", "type","location", "path", "sha" };

		_populate(models, fields, _models);
		idx_models = n_sections;
		n_sections++;
	}
	catch (const libconfig::SettingNotFoundException& nfex)
	{
		// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "No setting in found at %s.\n", nfex.getPath());
#endif
	}

	try
	{
		int nchars_corpora = strlen("corpora");
		_corpora->name = (char*)calloc(nchars_corpora + 1, sizeof(char));
		std::memcpy(_corpora->name, "corpora", nchars_corpora);
		_corpora->name[nchars_corpora] = '\0';
		_corpora->n_name = nchars_corpora;

		const libconfig::Setting& corpora = root["corpora"];
		std::vector<std::string> fields = { "uri", "id", "path", "kbase", "sha" };
		_populate(corpora, fields, _corpora);

		idx_corpora = n_sections;
		n_sections++;

	}
	catch (const libconfig::SettingNotFoundException& nfex)
	{
		// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "No setting in found at %s.\n", nfex.getPath());
#endif
	}

	try
	{
		int nchars_profiles = strlen("profiles");
		_profiles->name = (char*)calloc(nchars_profiles + 1, sizeof(char));
		std::memcpy(_profiles->name, "profiles", nchars_profiles);
		_profiles->name[nchars_profiles] = '\0';
		_profiles->n_name = nchars_profiles;

		const libconfig::Setting& profiles = root["profiles"];
		std::vector<std::string> fields = { "uri", "id", "name", "prompt", "model", "corpus" };
		_populate(profiles, fields, _profiles);

		idx_profiles = n_sections;
		n_sections++;
	}
	catch (const libconfig::SettingNotFoundException& nfex)
	{
		// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "No setting in found at %s.\n", nfex.getPath());
#endif
	}

	try
	{
		int nchars_conversations = strlen("conversations");
		_conversations->name = (char*)calloc(nchars_conversations + 1, sizeof(char));
		std::memcpy(_conversations->name, "conversations", nchars_conversations);
		_conversations->name[nchars_conversations] = '\0';
		_conversations->n_name = nchars_conversations;

		const libconfig::Setting& conversations = root["conversations"];
		std::vector<std::string> fields = { "uri", "id", "id", "summary", "profile", "attachments" };
		_populate(conversations, fields, _conversations);

		idx_conversations = n_sections;
		n_sections++;

	}
	catch (const libconfig::SettingNotFoundException& nfex)
	{
		// Ignore.
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "No setting in found at %s.\n", nfex.getPath());
#endif
	}

	configuration->root->type = n_sections > 0 ? UNNU_AUX_CONFIG_LIST : UNNU_AUX_CONFIG_NONE;
	if (n_sections > 0) {
		configuration->root->value.list = (UnnuAuxConfigList*)malloc(sizeof(UnnuAuxConfigList));
		configuration->root->value.list->elements = (UnnuAuxConfigSetting_t**)calloc(n_sections, sizeof(UnnuAuxConfigSetting_t*));
		configuration->root->value.list->count = n_sections;
	}
	else {
		configuration->root->length = 0;
	}

	if (idx_models != -1) {
		configuration->root->value.list->elements[idx_models] = _models;
	}
	if (idx_corpora != -1) {
		configuration->root->value.list->elements[idx_corpora] = _corpora;
	}
	if (idx_profiles != -1) {
		configuration->root->value.list->elements[idx_profiles] = _profiles;
	}
	if (idx_conversations != -1) {
		configuration->root->value.list->elements[idx_conversations] = _conversations;
	}
	return configuration;
}

void unnu_aux_free_setting(UnnuAuxConfigSetting_t* setting) {
    if(setting != nullptr){
		UnnuAuxConfigSetting_t _val = *setting;
#if defined(_DEBUG) || defined(DEBUG)
    if (_val.n_name > 0)  fprintf(stderr, "unnu_aux_free_setting freeing name %s.\n", _val.name);
#endif
        if (_val.n_name > 0) { free(_val.name); }
        switch (_val.type) {
        case UnnuAuxConfigValueType::UNNU_AUX_CONFIG_LIST:
            if (_val.value.list != nullptr) {
				UnnuAuxConfigList_t _list = *(_val.value.list);
                for (int i = 0, n = _list.count; i < n; i++) {
                    unnu_aux_free_setting(_list.elements[i]);
                }
                free(_val.value.list);
            }
            break;
        case UnnuAuxConfigValueType::UNNU_AUX_CONFIG_STR_ARRAY:
            if (_val.value.object != nullptr) {
				// void* _value = (void*)_val.value.object;
                //for (int i = 0, n = setting->length; i < n; i++) {
                //    free(_values[i]);
                //}
                free(_val.value.object);
            }
            break;
        case UnnuAuxConfigValueType::UNNU_AUX_CONFIG_STRING:
#if defined(_DEBUG) || defined(DEBUG)
        if (_val.length > 0) fprintf(stderr, "unnu_aux_free_setting freeing string %s.\n", setting->value.sval);
#endif
			if (_val.value.sval != nullptr) {
				if (_val.length > 0) (_val.value.sval);
			}
            break;
        default:
            break;
        }
		free(setting);
    }
}

void unnu_aux_free_config(UnnuAuxConfig_t* config) {
	if (config != nullptr) {
		UnnuAuxConfig_t _config = *config;
		if (_config.root != nullptr) {
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "freeing config %s.\n", config->root->name);
#endif
			UnnuAuxConfigSetting_t _root = *(_config.root);
			if (_root.n_name > 0) free(_root.name);
			if (_root.attributes != nullptr) {
				UnnuAuxConfig_t _attr_root = *(_root.attributes);
				if (_attr_root.root != nullptr) {
					UnnuAuxConfigSetting_t _attr_root_setting = *(_attr_root.root);
					if (_attr_root_setting.type == UnnuAuxConfigValueType::UNNU_AUX_CONFIG_LIST && _attr_root_setting.value.list != nullptr) {
						UnnuAuxConfigList_t _attr_list = *(_attr_root_setting.value.list);
						for (int i = 0, n = _attr_list.count; i < n; i++) {
							unnu_aux_free_setting(_attr_list.elements[i]);
						}
						free(_attr_root_setting.value.list);
					}
					free(_attr_root.root);
				}
				free(_root.attributes);
			}
			

			switch (_root.type) {
			case UnnuAuxConfigValueType::UNNU_AUX_CONFIG_LIST:
				if (_root.value.list != nullptr) {
					UnnuAuxConfigList_t _list = *(_root.value.list);
					for (int i = 0, n = _list.count; i < n; i++) {
						unnu_aux_free_setting(_list.elements[i]);
					}
					free(_root.value.list);
				}
				break;
			case UnnuAuxConfigValueType::UNNU_AUX_CONFIG_STRING:
#if defined(_DEBUG) || defined(DEBUG)
				if (_root.length > 0) fprintf(stderr, "unnu_aux_free_config freeing string %s.\n", _root.value.sval);
#endif
				if (_root.value.sval != nullptr) {
					if (_root.length > 0) free(_root.value.sval);
				}
				break;

			}
			free(_config.root);
		}
		free(config);
	}
}


void unnu_aux_upsert_model_settings(const char* filepath, UnnuAuxModelSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("models")) {
		root.add("models", libconfig::Setting::TypeList);
	}

	libconfig::Setting& models = root["models"];
	int n_models = models.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_models; idx++) {
		libconfig::Setting& model = models[idx];
		std::string uri;
		model.lookupValue("uri", uri);
		if (strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		models.remove(idx);
	}
	// Create the new model entry.
	libconfig::Setting& model = models.add(libconfig::Setting::TypeGroup);
	model.add("uri", libconfig::Setting::TypeString) = config.uri;
	if (config.n_id > 0) {
		model.add("id", libconfig::Setting::TypeString) = config.id;
	}
	if (config.n_type > 0) {
		model.add("type", libconfig::Setting::TypeString) = config.type;
	}
	if (config.n_location > 0) {
		model.add("location", libconfig::Setting::TypeString) = config.location;
	}
	if (config.n_path > 0) {
		model.add("path", libconfig::Setting::TypeString) = config.path;
	}
	if (config.n_sha > 0) {
		model.add("sha", libconfig::Setting::TypeString) = config.sha;
	}

	// Write out the updated configuration.
	try
	{
		cfg.writeFile(filepath);

	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
	}

}

void unnu_aux_upsert_corpus_settings(const char* filepath, UnnuAuxCorpusSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("corpora")) {
		root.add("corpora", libconfig::Setting::TypeList);
	}

	libconfig::Setting& corpora = root["corpora"];
	int n_corpora = corpora.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_corpora; idx++) {
		libconfig::Setting& corpus = corpora[idx];
		std::string uri;
		if (corpus.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		corpora.remove(idx);
	}
	// Create the new model entry.
	libconfig::Setting& corpus = corpora.add(libconfig::Setting::TypeGroup);
	corpus.add("uri", libconfig::Setting::TypeString) = config.uri;
	if (config.n_id > 0) {
		corpus.add("id", libconfig::Setting::TypeString) = config.id;
	}
	if (config.n_path > 0) {
		corpus.add("path", libconfig::Setting::TypeString) = config.path;
	}
	if (config.n_kbase > 0) {
		corpus.add("kbase", libconfig::Setting::TypeString) = config.kbase;
	}
	if (config.n_sha > 0) {
		corpus.add("sha", libconfig::Setting::TypeString) = config.sha;
	}
	// Write out the updated configuration.
	try
	{
		cfg.writeFile(filepath);

	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
	}
}

void unnu_aux_upsert_profile_settings(const char* filepath, UnnuAuxProfileSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("profiles")) {
		root.add("profiles", libconfig::Setting::TypeList);
	}

	libconfig::Setting& profiles = root["profiles"];
	int n_profiles = profiles.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_profiles; idx++) {
		libconfig::Setting& profile = profiles[idx];
		std::string uri;
		if (profile.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		profiles.remove(idx);
	}
	// Create the new model entry.
	libconfig::Setting& profile = profiles.add(libconfig::Setting::TypeGroup);
	profile.add("uri", libconfig::Setting::TypeString) = config.uri;
	if (config.n_id > 0) {
		profile.add("id", libconfig::Setting::TypeString) = config.id;
	}
	if (config.n_name > 0) {
		profile.add("name", libconfig::Setting::TypeString) = config.name;
	}
	if (config.n_prompt > 0) {
		profile.add("prompt", libconfig::Setting::TypeString) = config.prompt;
	}
	if (config.n_corpus_id > 0) {
		profile.add("corpus", libconfig::Setting::TypeString) = config.corpus_id;
	}
	if (config.n_model_id > 0) {
		profile.add("model", libconfig::Setting::TypeString) = config.model_id;
	}

	// Write out the updated configuration.
	try
	{
		cfg.writeFile(filepath);

	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
	}
}

void unnu_aux_upsert_conversation_settings(const char* filepath, UnnuAuxConversationSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("conversations")) {
		root.add("conversations", libconfig::Setting::TypeList);
	}

	libconfig::Setting& conversations = root["conversations"];
	int n_conversations = conversations.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_conversations; idx++) {
		libconfig::Setting& conversation = conversations[idx];
		std::string uri;
		if (conversation.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		conversations.remove(idx);
	}
	// Create the new model entry.
	libconfig::Setting& conversation = conversations.add(libconfig::Setting::TypeGroup);
	conversation.add("uri", libconfig::Setting::TypeString) = config.uri;
	if (config.n_id > 0) {
		conversation.add("id", libconfig::Setting::TypeString) = config.id;
	}
	if (config.n_summary > 0) {
		conversation.add("summary", libconfig::Setting::TypeString) = config.summary;
	}
	if (config.n_profile_id > 0) {
		conversation.add("profile", libconfig::Setting::TypeString) = config.profile_id;
	}


	// Write out the updated configuration.
	try
	{
		cfg.writeFile(filepath);

	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
	}
}

void unnu_aux_delete_model_settings(const char* filepath, UnnuAuxModelSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
		return;
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
		return;
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("models")) {
		return;
	}

	libconfig::Setting& models = root["model"];
	int n_models = models.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_models; idx++) {
		libconfig::Setting& model = models[idx];
		std::string uri;
		if (model.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		models.remove(idx);
		// Write out the updated configuration.
		try
		{
			cfg.writeFile(filepath);

		}
		catch (const libconfig::FileIOException& fioex)
		{
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
		}
	}
}
void unnu_aux_delete_corpus_settings(const char* filepath, UnnuAuxCorpusSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
		return;
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
		return;
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("corpora")) {
		return;
	}

	libconfig::Setting& corpora = root["corpora"];
	int n_corpora = corpora.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_corpora; idx++) {
		libconfig::Setting& corpus = corpora[idx];
		std::string uri;
		if (corpus.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		corpora.remove(idx);
		// Write out the updated configuration.
		try
		{
			cfg.writeFile(filepath);

		}
		catch (const libconfig::FileIOException& fioex)
		{
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
		}
	}
}
void unnu_aux_delete_profile_settings(const char* filepath, UnnuAuxProfileSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
		return;
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
		return;
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("profiles")) {
		return;
	}

	libconfig::Setting& profiles = root["profiles"];
	int n_profiles = profiles.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_profiles; idx++) {
		libconfig::Setting& profile = profiles[idx];
		std::string uri;
		if (profile.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		profiles.remove(idx);
		// Write out the updated configuration.
		try
		{
			cfg.writeFile(filepath);

		}
		catch (const libconfig::FileIOException& fioex)
		{
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
		}
	}
}

void unnu_aux_delete_conversation_settings(const char* filepath, UnnuAuxConversationSettings_t config) {
	libconfig::Config cfg;
	// Read the file. If there is an error, report it and exit.
	try
	{
		cfg.readFile(filepath);
	}
	catch (const libconfig::FileIOException& fioex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "I/O error while reading config file: %s - %s\n", filepath, fioex.what());
#endif
		return;
	}
	catch (const libconfig::ParseException& pex)
	{
#if defined(_DEBUG) || defined(DEBUG)
		fprintf(stderr, "Parse error at %s:%i - %s\n", pex.getFile(), pex.getLine(), pex.getError());
#endif
		return;
	}

	libconfig::Setting& root = cfg.getRoot();
	if (!root.exists("conversations")) {
		return;
	}

	libconfig::Setting& conversations = root["conversations"];
	int n_conversations = conversations.getLength();
	int idx = 0;
	bool found = false;
	for (idx = 0; idx < n_conversations; idx++) {
		libconfig::Setting& conversation = conversations[idx];
		std::string uri;
		if (conversation.lookupValue("uri", uri) && strcmp(uri.c_str(), config.uri) == 0) {
			found = true;
			break;
		}
	}

	if (found) {
		conversations.remove(idx);
		// Write out the updated configuration.
		try
		{
			cfg.writeFile(filepath);

		}
		catch (const libconfig::FileIOException& fioex)
		{
#if defined(_DEBUG) || defined(DEBUG)
			fprintf(stderr, "I/O error while writing file: %s - %s\n", filepath, fioex.what());
#endif
		}
	}
}

int32_t unnu_aux_check_min_hw_specs() {

	if (cpuinfo_initialize()) {
		int32_t res = 0;
#if CPUINFO_ARCH_X86 || CPUINFO_ARCH_X86_64
		int32_t F16C_FLAG = 1 << 0;
		int32_t SSE4_2_FLAG = 1 << 1;
		int32_t BMI2_FLAG = 1 << 2;
		int32_t AVX_FLAG = 1 << 3;
		int32_t AVX2_FLAG = 1 << 4;
		int32_t FMA_FLAG = 1 << 5;
		
		if(!cpuinfo_has_x86_f16c()){
			res |= F16C_FLAG;
		}
		if(!cpuinfo_has_x86_sse4_2()){
			res |= SSE4_2_FLAG;
		}
		if(!cpuinfo_has_x86_bmi2()){
			res |= BMI2_FLAG;
		}
		
		if(!cpuinfo_has_x86_avx()){
			res |= AVX_FLAG;
		}
		if(!cpuinfo_has_x86_avx2()){
			res |= AVX2_FLAG;
		}
		if(!cpuinfo_has_x86_fma3()){
			res |= FMA_FLAG;
		} 
#endif
#if CPUINFO_ARCH_ARM || CPUINFO_ARCH_ARM64
#endif
#if CPUINFO_ARCH_RISCV32 || CPUINFO_ARCH_RISCV64
#endif
		return res;		
	} 
	return -1;
}
