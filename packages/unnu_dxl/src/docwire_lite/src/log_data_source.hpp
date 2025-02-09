#ifndef DOCWIRE_LOG_DATA_SOURCE_H
#define DOCWIRE_LOG_DATA_SOURCE_H

#include "data_source.h"
#include "log.h"
#include "log_file_extension.hpp" // IWYU pragma: keep

namespace docwire
{

inline log_record_stream& operator<<(log_record_stream& log_stream, const data_source& data)
{
	log_stream << docwire_log_streamable_obj(data, data.path(), data.file_extension());
	return log_stream;
}

} // namespace docwire

#endif // DOCWIRE_LOG_DATA_SOURCE_H