#pragma once

namespace atomic_dex
{
    inline const char*       g_dex_api{DEX_API};
    // g_dex_rpc must be an absolute URL (scheme + host + port); DEX_RPC/DEX_RPCPORT
    // are bare values (e.g. "127.0.0.1" / "7783"). web::http::client::http_client
    // throws std::invalid_argument("URI must contain a hostname") if constructed
    // from the bare host with no scheme, since cpprestsdk parses it as a relative URI.
    inline const std::string g_dex_rpc{"http://" DEX_RPC ":" DEX_RPCPORT};
    inline const int64_t     g_dex_rpcport{std::stoi(DEX_RPCPORT)};
    inline const std::string g_primary_dex_coin{DEX_PRIMARY_COIN};
    inline const std::string g_second_primary_dex_coin{DEX_SECOND_PRIMARY_COIN};
    inline const std::vector<std::string> g_default_coins{
        g_primary_dex_coin,
        g_second_primary_dex_coin
    };
    inline const std::vector<std::string> g_faucet_coins{
        "DOC",
        "MARTY",
        "ZOMBIE",
        "IRISTEST",
    };
    inline const std::vector<std::string> g_vote_coins{
    };
    inline const std::vector<std::string> g_wallet_only_coins{
        "ARRR-BEP20",
        "RBTC",
        "NVC",
        "PAXG-ERC20",
        "USDT-ERC20",
        "XPM",
        "ATOM"
    };
}
