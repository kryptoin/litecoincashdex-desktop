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

#include <fstream>
#include <iostream>

//! PCH Headers
#include "atomicdex/pch.hpp"

//! Project Headers
#include "atomicdex/utilities/kill.hpp"

namespace atomic_dex
{
    ENTT_API void
    kill_executable(const char* exec_name)
    {
#if defined(__APPLE__) || defined(__linux__)
        std::string cmd_line_check = "pgrep -f " + std::string(exec_name);
        std::string response = execute(cmd_line_check);
        if (response != "")
        {
            // Send SIGKILL so the process (and the RPC port it holds) is
            // guaranteed to be released; a plain SIGTERM is not always honored
            // promptly by the daemon and would leave port 7783 occupied.
            // killall matches only the short process name, which can miss the
            // daemon on macOS; pkill -f matches the full binary path and is the
            // reliable way to stop a leftover KDF.
            execute("pkill -9 -f " + std::string(exec_name));
            std::string cmd_line = "killall -9 " + std::string(exec_name);
            std::string response = execute(cmd_line);
        }
#else
        std::string cmd_line = "taskkill /F /IM " + std::string(exec_name) + ".exe /T";
        std::string response = execute(cmd_line);
#endif
    }

    std::string
    execute(const std::string& command)
    {
        //! Write the redirected output to the system temp dir, never to the
        //! current working directory. When the app is launched from Finder /
        //! LaunchServices the CWD is "/", which is not writable, so a CWD-relative
        //! temp.txt made the redirect silently fail and callers (kill_executable)
        //! would then see an empty response and skip the kill — leaving a stale
        //! KDF daemon holding port 7783 and hanging login.
        const std::filesystem::path temp_path = std::filesystem::temp_directory_path() / "atomicdex_execute.txt";
        system((command + " > '" + temp_path.string() + "' 2>/dev/null").c_str());

        std::ifstream ifs(temp_path.string());
        std::string ret{ std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>() };
        ifs.close(); // must close the inout stream so the file can be cleaned up
        std::error_code ec;
        std::filesystem::remove(temp_path, ec);
        return ret;
    }
} // namespace atomic_dex
