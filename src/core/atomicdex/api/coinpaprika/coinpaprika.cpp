//
// Created by opencode on 14/08/2026.
//

//! Deps
#include <boost/algorithm/string/replace.hpp>

//! Project Headers
#include "atomicdex/api/coinpaprika/coinpaprika.hpp"

namespace
{
    constexpr const char* g_coinpaprika_endpoint = "https://api.coinpaprika.com";
    web::http::client::http_client_config g_coinpaprika_cfg{[]()
                                                            {
                                                                web::http::client::http_client_config cfg;
                                                                cfg.set_validate_certificates(false);
                                                                cfg.set_timeout(std::chrono::seconds(30));
                                                                return cfg;
                                                            }()};
    t_http_client_ptr&
    coinpaprika_client()
    {
        // Build client lazily so SSL/TLS context is initialized after app prerequisites.
        static t_http_client_ptr client = std::make_unique<web::http::client::http_client>(FROM_STD_STR(g_coinpaprika_endpoint), g_coinpaprika_cfg);
        return client;
    }
} // namespace

namespace atomic_dex::coinpaprika::api
{
    void
    from_json(const nlohmann::json& j, ticker_infos& x)
    {
        if (j.contains("quotes") && j.at("quotes").is_object())
        {
            const auto& quotes = j.at("quotes");
            if (quotes.contains("USD") && quotes.at("USD").is_object())
            {
                const auto& usd = quotes.at("USD");
                if (usd.contains("price") && !usd.at("price").is_null())
                {
                    x.last_price = std::to_string(usd.at("price").get<double>());
                }
                else
                {
                    x.last_price = "0";
                }
                boost::algorithm::replace_all(x.last_price, ",", ".");
                if (usd.contains("volume_24h") && !usd.at("volume_24h").is_null())
                {
                    x.volume24_h = std::to_string(usd.at("volume_24h").get<double>());
                }
                else
                {
                    x.volume24_h = "0";
                }
                boost::algorithm::replace_all(x.volume24_h, ",", ".");
                if (usd.contains("percent_change_24h") && !usd.at("percent_change_24h").is_null())
                {
                    std::ostringstream ss;
                    ss << std::setprecision(2) << usd.at("percent_change_24h").get<double>();
                    x.change_24h = ss.str();
                }
                else
                {
                    x.change_24h = "0";
                }
                boost::algorithm::replace_all(x.change_24h, ",", ".");
            }
        }
    }

    pplx::task<web::http::http_response>
    async_ticker(ticker_request&& request)
    {
        web::http::http_request req;
        req.set_method(web::http::methods::GET);
        std::string url = "/v1/tickers/" + request.id + "?quotes=" + request.quotes;
        SPDLOG_INFO("url: {}", TO_STD_STR(coinpaprika_client()->base_uri().to_string()) + url);
        req.set_request_uri(FROM_STD_STR(url));
        return coinpaprika_client()->request(req);
    }
} // namespace atomic_dex::coinpaprika::api