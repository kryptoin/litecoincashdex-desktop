#pragma once

#include <nlohmann/json.hpp>

#include "atomicdex/utilities/cpprestsdk.utilities.hpp"

namespace atomic_dex::coinpaprika::api
{
    struct ticker_request
    {
        std::string id;
        std::string quotes{"USD"};
    };

    struct ticker_infos
    {
        std::string       last_price{"0.00"};
        std::string       change_24h{"0.00"};
        std::string       volume24_h{"0.00"};
        nlohmann::json    sparkline_7_d{nlohmann::json::array()};
    };

    void from_json(const nlohmann::json& j, ticker_infos& x);

    ENTT_API pplx::task<web::http::http_response> async_ticker(ticker_request&& request);
} // namespace atomic_dex::coinpaprika::api

namespace atomic_dex
{
    using t_coinpaprika_ticker_request = coinpaprika::api::ticker_request;
    using t_coinpaprika_ticker_infos   = coinpaprika::api::ticker_infos;
} // namespace atomic_dex