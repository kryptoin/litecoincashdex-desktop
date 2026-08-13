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

//! Skipped: DEX_CHECKSUM_API_URL is a placeholder (https://example.com/checksum)
//! defined in project.metadata.cmake — there is no real checksum server for this
//! project, so a meaningful release checksum can never be fetched. Re-enable once a
//! real checksum endpoint is configured.
#include <doctest/doctest.h>

#include "atomicdex/api/checksum/checksum.api.hpp"

TEST_CASE("Fetch checksum and check its value" * doctest::skip())
{
    atomic_dex::checksum::api::get_latest_checksum()
        .then([](std::string checksum)
        {
            CHECK_FALSE(checksum.empty());
        })
        .then(&handle_exception_pplx_task)
        .wait();
}
