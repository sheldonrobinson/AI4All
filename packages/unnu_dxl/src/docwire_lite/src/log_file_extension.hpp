#ifndef DOCWIRE_LOG_FILE_EXTENSION_H
#define DOCWIRE_LOG_FILE_EXTENSION_H

#include "file_extension.hpp"
#include "log.h"

namespace docwire
{

/**
* @brief Logs the file extension to a record stream.
*
* @param log_stream The record stream to log to.
*/
inline log_record_stream& operator<<(log_record_stream& log_stream, const file_extension& ext)
{
	log_stream << docwire_log_streamable_obj(ext, ext.string());
	return log_stream;
}

} // namespace docwire

#endif // DOCWIRE_LOG_FILE_EXTENSION_H