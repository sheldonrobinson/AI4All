#ifndef DOCWIRE_LOG_EXCEPTION_H
#define DOCWIRE_LOG_EXCEPTION_H

#include "log.h"
#include "exception_utils.hpp"

namespace docwire
{

inline log_record_stream& operator<<(log_record_stream& log_stream, const std::exception_ptr eptr)
{
	if (eptr)
		log_stream << begin_complex() <<
            docwire_log_streamable_type_of(eptr) <<
            std::make_pair("diagnostic_message", errors::diagnostic_message(eptr)) <<
            end_complex();
	else
		log_stream << nullptr;
	return log_stream;
}

} // namespace docwire

#endif // DOCWIRE_LOG_EXCEPTION_H