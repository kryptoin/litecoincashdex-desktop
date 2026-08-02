set(_vcpkg_toolchain_file "${CMAKE_CURRENT_SOURCE_DIR}/ci_tools_atomic_dex/vcpkg-repo/scripts/buildsystems/vcpkg.cmake")
if (EXISTS "${_vcpkg_toolchain_file}")
    message(STATUS "VCPKG package manager enabled")
    set(VCPKG_OVERLAY_PORTS "${CMAKE_CURRENT_SOURCE_DIR}/ci_tools_atomic_dex/vcpkg-custom-ports/ports" CACHE STRING "")
    set(_VCPKG_INSTALLED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ci_tools_atomic_dex/vcpkg-repo/installed")
    set(CMAKE_TOOLCHAIN_FILE
            "${_vcpkg_toolchain_file}"
            CACHE STRING "")
    if (WIN32)
        set(VCPKG_TARGET_TRIPLET "x64-windows" CACHE STRING "")
    endif ()

    if (APPLE)
        set(VCPKG_APPLOCAL_DEPS OFF CACHE BOOL "")
    endif ()
else ()
    message(STATUS "Skipping vcpkg toolchain because ${_vcpkg_toolchain_file} was not found; using Homebrew/system packages instead")
endif ()