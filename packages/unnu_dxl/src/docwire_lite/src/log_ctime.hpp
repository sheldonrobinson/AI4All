#ifndef DOCWIRE_LOG_CTIME_H
#define DOCWIRE_LOG_CTIME_H

#include <ctime>
#include "log.h"
#include <sstream>

namespace docwire
{

inline log_record_stream& operator<<(log_record_stream& log_stream, const tm& time)
{
    std::ostringstream date_stream;
    date_stream << std::put_time(&time, "%Y-%m-%d %H:%M:%S");
    log_stream << date_stream.str();
    return log_stream;
}

} // namespace docwire

#endif // DOCWIRE_LOG_CTIME_H