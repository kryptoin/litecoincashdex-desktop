<p align="center">
  <img width="260" alt="Litecoin Cash DEX Wallet" src="docs/images/litecoincashdex-wallet.png">
</p>

## What is Litecoin Cash DEX Wallet?

Litecoin Cash DEX Wallet is a secure, non-custodial desktop wallet and decentralized exchange built for Litecoin Cash (LCC) and peer-to-peer atomic swaps. It combines the security and control of a self-custodial wallet with the functionality of a decentralized trading platform, allowing users to hold, manage, and exchange LCC and supported digital assets directly from their desktop. Powered by the Komodo DeFi Framework, the wallet enables peer-to-peer, trustless trading through atomic swaps, allowing participants to exchange assets directly without relying on a centralized exchange or giving up custody of their funds.

## Building on macOS (Apple Silicon)

> Status — 2026-08-23: Builds and runs on arm64 (Apple Silicon). The KDF daemon ships as a
> Universal2 binary (arm64 + x86_64) and is auto-downloaded then ad-hoc signed. Recent
> fixes cover KDF daemon startup/teardown, ERC-20/BEP-20 transaction-history timeouts, and
> the Pro view chart infinite-spinner.

The repository provides two Apple Silicon build paths, both driven by the same
`build-macos-apple-silicon.sh` (which targets **any** Apple Silicon Mac — M1, M2, M3, …):

- **`apple-silicon` branch** — the original M1 Apple Silicon support.
- **`m2` branch** — M2 (and later) support. It fixes a Qt version mismatch that crashed
  QtWebEngine's GPU thread on M2 (a base-anaconda Qt pair such as `qt-main` 5.15.2 +
  `qt-webengine` 5.15.9 against a 5.15.15 build) and adds the `--refresh-coins` flag plus a
  `cleanup-m2.sh` helper.

The build script:

- Installs the required Homebrew dependencies if missing (`boost`, `fmt`, `spdlog`,
  `cpprestsdk`, `libsodium`, `secp256k1`, `openssl`, `howard-hinnant-date`, `entt`,
  `taskflow`).
- Clones the `vendor/coins` submodule (GLEECBTC/coins, a fork of jl777/coins) if absent, so
  the bundled coin list / electrum registry is available at build time. Pass `--refresh-coins`
  to force a fresh fetch of the latest weekly changes.
- Picks a single, **aligned** Qt 5.15 env (see Prerequisites) to avoid the mixed-Qt-version
  crash described above.
- Configures with CMake + Ninja into `build-macos-apple-silicon/`.
- Downloads the KDF daemon (`mm2_cheetah`) and copies it into the app bundle.
- Ad-hoc signs the KDF binary and the whole app bundle. There is **no Apple Developer
  certificate** in this flow, so the app is ad-hoc signed only — launch it from the build
  output (or clear the Gatekeeper quarantine) rather than distributing the bundle.

### Prerequisites

- Anaconda3 at `/opt/anaconda3` with a **single aligned** Qt 5.15 env. A mismatched pair
  (e.g. base env `qt-main` 5.15.2 + `qt-webengine` 5.15.9) crashes QtWebEngine's GPU thread
  at runtime. Create the aligned env:
  ```bash
  conda create -p /opt/anaconda3/envs/qt51515 -c conda-forge \
      "qt-main=5.15.15" "qt-webengine=5.15.15"
  ```
- Homebrew (the script installs the native libraries listed above).

### Build

**M1 (apple-silicon branch):**

```bash
git checkout apple-silicon
./build-macos-apple-silicon.sh
```

**M2 and later (m2 branch):**

```bash
git checkout m2
./build-macos-apple-silicon.sh --refresh-coins   # re-fetch latest coin list
```

To force a fully clean rebuild on `m2` (drops the libwally install, wally build tree, and
optional `vendor/coins`):

```bash
./cleanup-m2.sh --reset-coins
./build-macos-apple-silicon.sh --refresh-coins
```

The finished app bundle is written to:

```
build-macos-apple-silicon/bin/litecoincashdex.app
```

### Packaging (DMG)

`package-macos.sh` turns the built `.app` into a self-contained, signed DMG:

```bash
timeout 600 ./package-macos.sh --qt-deploy --native-deps --verify --dmg
```

This bundles the aligned Qt frameworks, strips stale absolute rpaths, ad-hoc signs the app
(`--identifier com.litecoincash.dex`), and writes `dist/LitecoinCashDEX-macOS-arm64.dmg`.
For a Developer-ID signed / notarized build, pass `--sign` and/or `--notarize` with
`MACOS_SIGNING_IDENTITY` set.

### Running the tests

A `doctest` suite is built as `litecoincashdex_tests`. Use `run-tests.sh`, which runs the
tests from a scratch working directory:

```bash
./run-tests.sh            # offline unit tests (default)
./run-tests.sh --build    # rebuild the test target first
./run-tests.sh --network  # also run live-network API tests
```


## Contributors / Thanks

<div align="center">
	<table>
	  <tr>
	    <td align="center">
	        <a href="https://github.com/Milerius"><img src="https://avatars1.githubusercontent.com/u/21139416?s=400&u=12e0a99353ae95365801542b85e2fd69abd44a81&v=4" width="100px;" alt="Milerius"/><br /><sub><b>Milerius</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=Milerius" title="Lead Back-End Dev / Code">✍️💻</a>
	    </td>
		<td align="center">
		    <a href="https://github.com/SylEze"><img src="https://avatars1.githubusercontent.com/u/14373103?s=460&u=b303a2d2261008814800c2d7809efc6af685a460&v=4"width="100px;" alt="syl"/><br /><sub><b>syl</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=SylEze" title="Frontend and Back-End Dev / Code">✍️💻</a>
		</td>
	    <td align="center">
	        <a href="https://github.com/naezith"><img src="https://avatars2.githubusercontent.com/u/6732486?s=400&u=5d242e560be002ad4af597dd284eb3242ab28016&v=4" width="100px;" alt="naezith"/><br /><sub><b>naezith</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=naezith" title="Front-End Dev / Code">✍️💻</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/ssakone"><img src="https://avatars.githubusercontent.com/u/39985611?v=4" width="100px;" alt="ssakone"/><br /><sub><b>ssakone</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=ssakone" title="Front-End Dev / Code">✍️💻</a>
	    </td>
	  </tr>
	  <tr>
	    <td align="center">
	        <a href="https://github.com/tonymorony"><img src="https://avatars3.githubusercontent.com/u/24797699?s=400&u=335984bcb93856f260ac6d139b18f0c596306e08&v=4" width="100px;" alt="Anton TonyL Lysakov"/><br /><sub><b>Anton "TonyL" Lysakov</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=tonymorony" title="Lead QA / CI">🛠💻</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/ca333"><img src="https://avatars3.githubusercontent.com/u/10762374?s=60&v=4" width="100px;" alt="ca333"/><br /><sub><b>ca333</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=ca333" title="Chief Technology Officer">:penguin: :guardsman:</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/smk762"><img src="https://i.imgur.com/gAD7BxX.jpg" width="100px;" alt="smk762"/><br /><sub><b>smk762</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=smk762" title="QA Engineer">🛠:wolf:</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/cipig"><img src="https://avatars0.githubusercontent.com/u/32116761?s=60&v=4" width="100px;" alt="cipig"/><br /><sub><b>cipig</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=cipig" title="System Administrator">✍️💻</a>
	    </td>
	  </tr>
	  <tr>
	    <td align="center">
	        <a href="https://github.com/SirSevenG"><img src="https://avatars1.githubusercontent.com/u/44422309?s=60&v=4" width="100px;" alt="SirSevenG"/><br /><sub><b>SirSevenG</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=SirSevenG" title="QA Engineer">🛠💻</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/dathbezumniy"><img src="https://avatars2.githubusercontent.com/u/11756768?s=60&v=4" width="100px;" alt="dathbezumniy"/><br /><sub><b>dathbezumniy</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=dathbezumniy" title="Junior QA Engineer">🛠💻</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/BloodyNora"><img src="https://avatars2.githubusercontent.com/u/4005813?s=60&v=4" width="100px;" alt="BloodyNora"/><br /><sub><b>BloodyNora</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=BloodyNora" title="IT allrounder">🛠💻</a>
	    </td>
	    <td align="center">
	        <a href="https://github.com/zatJUM"><img src="https://avatars3.githubusercontent.com/u/45312760?s=60&v=4" width="100px;" alt="zatJUM"/><br /><sub><b>zatJUM</b></sub></a><br /><a href="https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/commits?author=zatJUM" title="Community Dev">:heart:💻</a>
	    </td>
	  </tr>
	</table>
</div>


## License

For details please refer to our [license](https://github.com/ShorelineCrypto/cheetahdex-wallet-desktop/blob/master/LICENSE).

This is experimental alpha software - use at your own risk!

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
