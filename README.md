<p align="center">
  <img width="260" alt="Litecoin Cash DEX Wallet" src="docs/images/litecoincashdex-wallet.png">
</p>

## What is Litecoin Cash DEX Wallet?

Litecoin Cash DEX Wallet is a secure non-custodial desktop wallet and decentralized exchange focused on Litecoin Cash and peer-to-peer atomic swaps.

Store your assets, manage balances, and trade directly from your own wallet without giving up control of your funds.

## Building on macOS (Apple Silicon)

> Status — 2026-08-05: The app compiles and the Qt/QML UI loads cleanly on arm64.
> The KDF daemon now ships as a Universal2 binary (arm64 + x86_64). A diagnostics run
> is pending to confirm end-to-end wallet operation.

The recommended build path on Apple Silicon uses the Anaconda3 Qt build and Homebrew
for native libraries.

### Prerequisites

- Anaconda3 at `/opt/anaconda3` with Qt 5.15 installed:
  ```bash
  conda install -p /opt/anaconda3 qt=5.15.9 cmake ninja
  ```
- Homebrew packages (installed automatically by the script):
  `boost`, `fmt`, `spdlog`, `cpprestsdk`, `libsodium`, `secp256k1`, `openssl`,
  `howard-hinnant-date`, `entt`, `taskflow`

### Build

```bash
./build-macos-anaconda.sh
```

The script wipes and recreates `build-macos-anaconda3/`, configures with CMake + Ninja,
and places the finished app bundle at:

```
build-macos-anaconda3/bin/litecoincashdex.app
```

> Note: After every build the KDF daemon must be copied into the bundle manually
> because the build script wipes the output directory:
> ```bash
> cp assets/tools/kdf/mm2_cheetah \
>    build-macos-anaconda3/bin/litecoincashdex.app/Contents/Resources/assets/tools/kdf/mm2_cheetah
> chmod +x build-macos-anaconda3/bin/litecoincashdex.app/Contents/Resources/assets/tools/kdf/mm2_cheetah
> ```

### Known issues

| # | Description | Blocking? |
|---|---|---|
| 1 | SSL price-feed errors at startup (cpprestsdk Boost.ASIO SSL context) | No |
| 2 | `coins.json` missing `protocol` field — coin UI metadata incomplete | No |

See [`docs/agent-handoff.md`](docs/agent-handoff.md) and [`docs/qt.md`](docs/qt.md)
for full diagnostics and source locations.

---

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
