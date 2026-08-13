//
// Regression test for the ERC-20 / BEP-20 infinite-spinner fix.
//
// The etherscan/qtum proxy http clients must carry an explicit timeout.
// Without one, a slow or unreachable proxy left the ETH/BEP-20 wallet views
// stuck on an infinite spinner (see kdf.hpp g_proxy_http_client_cfg).
//

#include "atomicdex/pch.hpp"

//! Deps
#include <doctest/doctest.h>

#include <chrono>

//! Project Headers
#include "atomicdex/api/kdf/kdf.hpp"

TEST_CASE("atomic_dex::kdf proxy http clients have an explicit timeout")
{
    CHECK(::atomic_dex::kdf::g_proxy_http_client_cfg.timeout() == std::chrono::seconds(30));
}
