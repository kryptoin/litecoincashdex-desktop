#pragma once

#include <string>

#include <nlohmann/json_fwd.hpp>

namespace atomic_dex::kdf
{
    struct fraction
    {
        std::string denom;
        std::string numer;
    };

    ENTT_API void from_json(const nlohmann::json& j,  kdf::fraction& fraction);
}