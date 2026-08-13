//! STD Headers
#include <random>

#if defined(_WIN32) || defined(WIN32)
# define _UNICODE
# define UNICODE
# include <Windows.h>
#endif

//! Qt Headers
#include <QCryptographicHash>
#include <QString>
#include <QFile>


//! Project Headers
#include "atomicdex/utilities/global.utilities.hpp"
#include "atomicdex/version/version.hpp"
#include "atomicdex/utilities/qt.utilities.hpp"

#include <antara/gaming/core/real.path.hpp>

namespace
{
    std::string
    dex_sha256(const std::string& str)
    {
        QString res = QString(QCryptographicHash::hash((str.c_str()), QCryptographicHash::Keccak_256).toHex());
        return res.toStdString();
    }
} // namespace

namespace atomic_dex::utils
{
    std::string
    get_formated_float(t_float_50 value)
    {
        std::stringstream ss;
        ss.precision(8);
        ss << std::fixed << value;
        return ss.str();
    }

    std::string
    format_float(t_float_50 value)
    {
        std::string result = value.str(8, std::ios_base::fixed);
        boost::trim_right_if(result, boost::is_any_of("0"));
        boost::trim_right_if(result, boost::is_any_of("."));
        return result;
    }

    std::string
    adjust_precision(const std::string& current)
    {
        std::string       result;
        std::stringstream ss;
        t_float_50        current_f(safe_float(current));

        return format_float(current_f);
    }

    bool
    create_if_doesnt_exist(const std::filesystem::path& path)
    {
        if (not std::filesystem::exists(path))
        {
            LOG_PATH("creating directory {}", path);
            //SPDLOG_INFO("creating directory {}", path.string());
            std::filesystem::create_directories(path);
            return true;
        }
        return false;
    }

    bool
    ensure_directory_exists(const std::filesystem::path& path)
    {
        if (not std::filesystem::exists(path))
        {
            LOG_PATH("creating directory {}", path);
            std::error_code ec;
            std::filesystem::create_directories(path, ec);
            return !ec;
        }
        return true;
    }

    double
    determine_balance_factor(bool with_pin_cfg)
    {
        if (not with_pin_cfg)
        {
            return 1.0;
        }

        std::random_device               rd;
        std::mt19937                     gen(rd());
        std::uniform_real_distribution<> distr(0.01, 0.05);
        return distr(gen);
    }

    std::filesystem::path
    get_atomic_dex_data_folder()
    {
        std::filesystem::path appdata_path;
#if defined(_WIN32) || defined(WIN32)
        std::wstring out = _wgetenv(L"APPDATA");
        appdata_path = std::filesystem::path(out) / DEX_APPDATA_FOLDER;
#elif defined(__APPLE__)
        appdata_path = std::filesystem::path(std::getenv("HOME")) / "Library" / "Application Support" / DEX_APPDATA_FOLDER;
#else
        appdata_path = std::filesystem::path(std::getenv("HOME")) / (std::string(".") + std::string(DEX_APPDATA_FOLDER));
#endif
        return appdata_path;
    }

    std::string
    u8string(const std::filesystem::path& p)
    {
        auto res = p.u8string();

        auto functor = [](auto&& r) {
          if constexpr (std::is_same_v<std::remove_cvref_t<decltype(r)>, std::string>)
          {
              return r;
          }
          else
          {
              return std::string(r.begin(), r.end());
          }
        };
        return functor(res);
    }

    std::filesystem::path
    get_atomic_dex_addressbook_folder()
    {
        const auto fs_addr_book_path = get_atomic_dex_data_folder() / "addressbook";
        create_if_doesnt_exist(fs_addr_book_path);
        return fs_addr_book_path;
    }

    std::filesystem::path
    get_runtime_coins_path()
    {
        const auto fs_coins_path = get_atomic_dex_data_folder() / "custom_coins_icons";
        create_if_doesnt_exist(fs_coins_path);
        return fs_coins_path;
    }

    std::filesystem::path
    get_atomic_dex_logs_folder()
    {
        const auto fs_logs_path = get_atomic_dex_data_folder() / "logs";
        create_if_doesnt_exist(fs_logs_path);
        return fs_logs_path;
    }

    ENTT_API std::filesystem::path
    get_atomic_dex_current_log_file()
    {
        using namespace std::chrono;
        using namespace date;
        static auto              timestamp = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        static date::sys_seconds tp{seconds{timestamp}};
        static std::string       s        = date::format("%Y-%m-%d-%H-%M-%S", tp);
        static const std::filesystem::path    log_path = get_atomic_dex_logs_folder() / (s + ".log");
        return log_path;
    }

    std::filesystem::path
    get_kdf_atomic_dex_current_log_file()
    {
        using namespace std::chrono;
        using namespace date;
        static auto              timestamp = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
        static date::sys_seconds tp{seconds{timestamp}};
        static std::string       s        = date::format("%Y-%m-%d-%H-%M-%S", tp);
        static const std::filesystem::path    log_path = get_atomic_dex_logs_folder() / (s + ".kdf.log");
        return log_path;
    }

    std::filesystem::path
    get_atomic_dex_config_folder()
    {
        const auto fs_cfg_path = get_atomic_dex_data_folder() / "config";
        create_if_doesnt_exist(fs_cfg_path);
        return fs_cfg_path;
    }

    bool
    ensure_wallet_coins_config(const std::filesystem::path& wallet_cfg_path)
    {
        if (std::filesystem::exists(wallet_cfg_path))
        {
            return true;
        }

        const std::filesystem::path cfg_path = ag::core::assets_real_path() / "config";
        const std::string           filename = std::string(atomic_dex::get_raw_version()) + "-coins.json";
        const std::filesystem::path source   = cfg_path / filename;

        try
        {
            if (std::filesystem::exists(source))
            {
                std::filesystem::copy(source, wallet_cfg_path);
                SPDLOG_INFO("Successfully copied default coins config: {} -> {}", source.string(), wallet_cfg_path.string());
                return true;
            }

            SPDLOG_WARN("Default coins config {} not found, writing minimal fallback to {}", source.string(), wallet_cfg_path.string());

            //! Minimal schema-valid dict consumed by coin_config_t. Contains only the
            //! default coins; a full list is normally generated from the jl777-coins
            //! utils/coins_config_tcp.json asset.
            const nlohmann::json fallback = nlohmann::json::object(
                {{atomic_dex::g_primary_dex_coin,
                  {{"coin", atomic_dex::g_primary_dex_coin}, {"name", atomic_dex::g_primary_dex_coin}, {"type", "UTXO"}, {"active", true}, {"explorer_url", ""}}},
                 {atomic_dex::g_second_primary_dex_coin,
                  {{"coin", atomic_dex::g_second_primary_dex_coin},
                   {"name", atomic_dex::g_second_primary_dex_coin},
                   {"type", "UTXO"},
                   {"active", true},
                   {"explorer_url", ""}}}});

            QFile file;
            file.setFileName(std_path_to_qstring(wallet_cfg_path));
            if (file.open(QIODevice::WriteOnly | QIODevice::Text))
            {
                file.write(QString::fromStdString(fallback.dump(4)).toUtf8());
                file.close();
                SPDLOG_INFO("Successfully wrote fallback coins config: {}", wallet_cfg_path.string());
                return true;
            }
            SPDLOG_ERROR("Cannot write fallback coins config to {}", wallet_cfg_path.string());
            return false;
        }
        catch (const std::exception& error)
        {
            SPDLOG_ERROR("Cannot prepare coins config {}: {}", wallet_cfg_path.string(), error.what());
            return false;
        }
    }

    std::filesystem::path
    get_atomic_dex_export_folder()
    {
        const auto fs_export_folder = get_atomic_dex_data_folder() / "exports";
        create_if_doesnt_exist(fs_export_folder);
        return fs_export_folder;
    }

    std::filesystem::path
    get_atomic_dex_current_export_recent_swaps_file()
    {
        return get_atomic_dex_export_folder() / ("swap-export.json");
    }

    void
    to_eth_checksum(std::string& address)
    {
        address                = address.substr(2);
        auto hex_str           = dex_sha256(address);
        auto final_eth_address = std::string("0x");

        for (std::string::size_type i = 0; i < address.size(); i++)
        {
            std::string actual(1, hex_str[i]);
            try
            {
                auto value = std::stoi(actual, nullptr, 16);
                if (value >= 8)
                {
                    final_eth_address += toupper(address[i]);
                }
                else
                {
                    final_eth_address += address[i];
                }
            }
            catch (const std::invalid_argument& e)
            {
                final_eth_address += address[i];
            }
        }
        address = final_eth_address;
    }

    std::filesystem::path
    get_current_configs_path()
    {
        const auto fs_raw_kdf_shared_folder = get_atomic_dex_data_folder() / get_raw_version() / "configs";
        create_if_doesnt_exist(fs_raw_kdf_shared_folder);
        return fs_raw_kdf_shared_folder;
    }

    std::string
    extract_large_float(const std::string& current)
    {
        if (auto pos = current.find('.'); pos != std::string::npos)
        {
            return current.substr(0, pos + 9);
        }
        return current;
    }

    std::filesystem::path
    get_themes_path()
    {
        std::filesystem::path theme_path = get_atomic_dex_data_folder() / "themes";
        create_if_doesnt_exist(theme_path);
        return theme_path;
    }

    std::filesystem::path
    get_logo_path()
    {
        std::filesystem::path logo_path = get_atomic_dex_data_folder() / "logo";
        create_if_doesnt_exist(logo_path);
        return logo_path;
    }

    int8_t
    get_index_str(std::vector<std::string> vec, std::string val)
    { 
        auto it = find(vec.begin(), vec.end(), val); 
        if (it != vec.end())  
        { 
            int index = it - vec.begin(); 
            return index;
        } 
        else {
            return -1;
        } 
    } 
    std::string
    retrieve_main_ticker(const std::string& ticker, bool segwit_only, bool exclude_segwit)
    {
        bool is_segwit = ticker.find("-segwit") != std::string::npos;
        if (exclude_segwit && is_segwit)
        {
            return ticker;
        }
        auto pos = ticker.find("-");
        if (segwit_only && is_segwit)
        {
            return ticker.substr(0, pos);
        }
        if (pos != std::string::npos)
        {
            return ticker.substr(0, pos);
        }
        return ticker;
    }

    std::vector<std::string>
    coin_cfg_to_ticker_cfg(std::vector<coin_config_t> in)
    {
        std::vector<std::string> out;
        out.reserve(in.size());

        for (auto&& coin : in)
        {
            out.push_back(coin.ticker);
        }
        return out;
    }

    nlohmann::json
    read_json_file(std::filesystem::path filepath)
    {
        nlohmann::json valid_json_data;

        if (std::filesystem::exists(filepath))
        {
            QFile ifs;
#if defined(_WIN32) || defined(WIN32)
            ifs.setFileName(QString::fromStdWString(filepath.wstring()));
#else
            ifs.setFileName(QString::fromStdString(filepath.string()));
#endif
            ifs.open(QIODevice::ReadOnly | QIODevice::Text);
            std::string json_str = QString(ifs.readAll()).toUtf8().constData();
            if (nlohmann::json::accept(json_str))
            {
                valid_json_data = nlohmann::json::parse(json_str);
            }
            ifs.close();
        }
        return valid_json_data;
    }

    void json_keys(nlohmann::json j)
    {
        for (auto& [key, val] : j.items())
        {
            SPDLOG_DEBUG("key: {}, value: {}", key, val);
        }
    }
} // namespace atomic_dex::utils
