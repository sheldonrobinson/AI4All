#ifndef DOCWIRE_LOG_VARIANT_H
#define DOCWIRE_LOG_VARIANT_H

#include "log.h"
#include <variant>

namespace docwire
{

template<typename... Ts>
log_record_stream& operator<<(log_record_stream& log_stream, const std::variant<Ts...>& variant)
{
    std::visit([&](const auto& value)
    {
        log_stream << begin_complex() << docwire_log_streamable_type_of(variant) << std::make_pair("value", value) << end_complex();
    }, variant);
    return log_stream;
}

} // namespace docwire

#endif // DOCWIRE_LOG_VARIANT_H