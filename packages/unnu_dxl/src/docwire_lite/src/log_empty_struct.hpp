#ifndef DOCWIRE_LOG_EMPTY_STRUCT_H
#define DOCWIRE_LOG_EMPTY_STRUCT_H

#include "log.h"
#include <type_traits>

namespace docwire
{

template <typename T>
concept EmptyStruct = std::is_empty_v<T>;

template <EmptyStruct T>
log_record_stream& operator<<(log_record_stream& log_stream, const T& variant)
{
    log_stream << "<empty_struct>";
    return log_stream;
}

} // namespace docwire

#endif // DOCWIRE_LOG_EMPTY_STRUCT_H