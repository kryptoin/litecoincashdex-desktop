//
// Bundled-asset sanity checks for the packaged app.
//
// The .app bundle shipped by package-macos.sh carries assets/config/<version>-coins.json
// into Contents/Resources/assets. These checks fail fast if that bundled data is ever
// dropped, corrupted, or stripped of the coinpaprika_id fields the price/chart fallbacks
// depend on -- catching a broken DMG before it reaches users.
#include "atomicdex/pch.hpp"

#include <fstream>

#include <doctest/doctest.h>

#include <nlohmann/json.hpp>

#include <antara/gaming/core/real.path.hpp>
#include "atomicdex/config/coins.cfg.hpp"
#include "atomicdex/version/version.hpp"

TEST_CASE("bundled coins config is present and parseable")
{
    const std::filesystem::path coins_path = ag::core::assets_real_path() / "config" / (std::string(atomic_dex::get_raw_version()) + "-coins.json");
    INFO("bundled coins path: {}", coins_path.string());
    REQUIRE(std::filesystem::exists(coins_path));

    nlohmann::json j;
    REQUIRE_NOTHROW(j = nlohmann::json::parse(std::ifstream(coins_path)));
    REQUIRE(j.is_object());
    REQUIRE(j.size() > 0);
}

TEST_CASE("bundled coins config keeps the core coin set")
{
    const std::filesystem::path coins_path = ag::core::assets_real_path() / "config" / (std::string(atomic_dex::get_raw_version()) + "-coins.json");
    REQUIRE(std::filesystem::exists(coins_path));

    nlohmann::json j = nlohmann::json::parse(std::ifstream(coins_path));
    for (const std::string& wanted: {"KMD", "MAZA", "AVN", "CAS"})
    {
        INFO("expected coin present: {}", wanted);
        CHECK(j.contains(wanted));
    }
}

TEST_CASE("bundled coins config keeps coinpaprika ids for thinly traded coins")
{
    const std::filesystem::path coins_path = ag::core::assets_real_path() / "config" / (std::string(atomic_dex::get_raw_version()) + "-coins.json");
    REQUIRE(std::filesystem::exists(coins_path));

    nlohmann::json j = nlohmann::json::parse(std::ifstream(coins_path));
    // These coins are absent from the komodo registry; the portfolio price and
    // Wallet chart fallbacks rely on their coinpaprika_id being shipped.
    for (const std::string& wanted: {"MAZA", "AVN", "CAS"})
    {
        INFO("coin present: {}", wanted);
        REQUIRE(j.contains(wanted));
        const auto& coin = j.at(wanted);
        INFO("{} has coinpaprika_id non-empty", wanted);
        CHECK(coin.contains("coinpaprika_id"));
        if (coin.contains("coinpaprika_id"))
        {
            CHECK_FALSE(coin.at("coinpaprika_id").get<std::string>().empty());
        }
    }
}

TEST_CASE("bundled coins config parses into coin_config_t")
{
    const std::filesystem::path coins_path = ag::core::assets_real_path() / "config" / (std::string(atomic_dex::get_raw_version()) + "-coins.json");
    REQUIRE(std::filesystem::exists(coins_path));

    nlohmann::json j = nlohmann::json::parse(std::ifstream(coins_path));
    CHECK_NOTHROW(j.get<std::unordered_map<std::string, atomic_dex::coin_config_t>>());
}