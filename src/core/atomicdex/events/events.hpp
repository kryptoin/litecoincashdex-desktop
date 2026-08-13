/******************************************************************************
 * Copyright © 2013-2024 The Komodo Platform Developers.                      *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * Komodo Platform software, including this file may be copied, modified,     *
 * propagated or distributed except according to the terms contained in the   *
 * LICENSE file                                                               *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

#pragma once

#include <entt/core/hashed_string.hpp>
#include <entt/core/type_info.hpp>
#include <entt/core/type_traits.hpp>

#include <atomicdex/config/coins.cfg.hpp>

namespace atomic_dex
{
    using kdf_started               = entt::tag<entt::hashed_string{"kdf_started"}>;
    using post_login                = entt::tag<entt::hashed_string{"post_login"}>;
    using gui_enter_trading         = entt::tag<entt::hashed_string{"gui_enter_trading"}>;
    using gui_leave_trading         = entt::tag<entt::hashed_string{"gui_leave_trading"}>;
    using kdf_initialized           = entt::tag<entt::hashed_string{"kdf_running_and_enabling"}>;
    using default_coins_enabled     = entt::tag<entt::hashed_string{"default_coins_enabled"}>;
    using current_currency_changed  = entt::tag<entt::hashed_string{"update_orders_and_swap_values"}>;
    using force_update_providers    = entt::tag<entt::hashed_string{"force_update_providers"}>;
    using force_update_defi_stats   = entt::tag<entt::hashed_string{"force_update_defi_stats"}>;
    using download_started          = entt::tag<entt::hashed_string{"download_started"}>;
    using download_complete         = entt::tag<entt::hashed_string{"download_complete"}>;
    using download_failed           = entt::tag<entt::hashed_string{"download_failed"}>;

    struct tx_fetch_finished
    {
        bool        with_error{false};
        std::string ticker;
    };

    struct process_swaps_and_orders_finished
    {
        bool after_manual_reset{false};
    };

    struct enabling_z_coin_status
    {
        std::string coin;
        std::string reason;
    };

    struct enabling_coin_failed
    {
        std::string coin;
        std::string reason;
    };

    struct disabling_coin_failed
    {
        std::string coin;
        std::string reason;
    };

    struct endpoint_nonreacheable
    {
        std::string base_uri;
    };

    struct update_portfolio_values
    {
        bool with_update_model{true};
    };

    struct process_orderbook_finished
    {
        bool is_a_reset;
    };

    struct refresh_ohlc_needed
    {
        bool is_a_reset;
    };

    struct start_fetching_new_ohlc_data
    {
        bool is_a_reset;
    };

    struct ticker_balance_updated
    {
        std::vector<std::string> tickers;
    };

    struct fiat_rate_updated
    {
        std::string ticker;
    };

    struct coin_enabled
    {
        std::vector<std::string> tickers;
    };

    //! Event when gecko fetch all the data of this specific coin
    struct coin_fully_initialized
    {
        std::vector<std::string> tickers;
    };

    struct coin_disabled
    {
        std::string ticker;
    };

    struct refresh_orderbook_model_data
    {
        std::string base;
        std::string rel;
    };

    struct coin_cfg_parsed
    {
        std::vector<atomic_dex::coin_config_t> cfg;
    };

    struct fatal_notification
    {
        std::string message;
    };
} // namespace atomic_dex
