//
// Created by Sztergbaum Roman on 24/03/2021.
//

//! Skipped: the komodolive endpoint (http://95.216.160.96:8080) used by this test is
//! no longer reachable, and the test also depends on a local 0.4.2-coins.json asset
//! that is not shipped with this project. Re-enable once a working endpoint and the
//! coins config asset are available.
#include <doctest/doctest.h>

TEST_CASE("generate all coinpaprika possibilities" * doctest::skip())
{
}
