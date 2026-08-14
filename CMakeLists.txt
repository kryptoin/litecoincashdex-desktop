cmake_minimum_required(VERSION 3.18)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

include(project.metadata)           ##> generate_dex_project_metafiles()
generate_dex_project_metafiles()

include(build_type)
include(compiler_prerequisites)
include(vcpkg_prerequisites)
include(qt_prerequisites)
include(cfg_hash)

project(${DEX_PROJECT_NAME} LANGUAGES CXX VERSION 0.9.7)
message(STATUS "${PROJECT_NAME} is version ${PROJECT_VERSION}")

include(cmake_default_options)
include(ipo_prerequisites)

##! Options
option(WITH_HOTRELOAD "Enable to use qml Hot reload" OFF)

# Option to skip external FetchContent downloads (mm2, deps) for local builds
option(AD_SKIP_FETCHCONTENT "Skip FetchContent downloads and use local stubs" ON)

if (NOT WITH_HOTRELOAD)
    message(STATUS "Hot Reload is not active; using local SortFilterProxyModel stub (no remote fetch)")
    # Provide a local INTERFACE target for SortFilterProxyModel to avoid FetchContent and remote git operations.
    # This keeps local development builds simple. Replace with FetchContent when network/external deps are desired.
    if (NOT TARGET SortFilterProxyModel)
        add_library(SortFilterProxyModel INTERFACE)
        target_compile_definitions(SortFilterProxyModel INTERFACE SFPM_FALLBACK=1)
    endif()
endif()

##! Antara
include(antara)
##! Calling this macros provided by the sdk will if you are on Apple init the environment for this OS (std::filesystem).
init_antara_env()


##! We include the module from CMake for fetching dependencies
include(FetchContent)

if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(LINUX TRUE)
endif ()

if (UNIX AND NOT APPLE)
    message("Forcing stdlib C++")
    #set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++ -lc++abi")
    #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif ()

##! We fetch our dependencies
if (APPLE)
    if (NOT AD_SKIP_FETCHCONTENT)
        # KDF v3.0 is now a library, not a binary. Skip FetchContent for now.
        message(STATUS "KDF v3.0 is library-only; skipping FetchContent")
    else()
        message(STATUS "AD_SKIP_FETCHCONTENT=ON: skipping kdf/mm2 FetchContent; ensure assets/tools/kdf/ contains mm2 if required")
    endif()
elseif (UNIX AND NOT APPLE)
    # KDF v3.0 is now a library, not a binary. Skip FetchContent for now.
    message(STATUS "KDF v3.0 is library-only; skipping FetchContent")
else ()
    # KDF v3.0 is now a library, not a binary. Skip FetchContent for now.
    message(STATUS "KDF v3.0 is library-only; skipping FetchContent")
endif ()

#FetchContent_Declare(qmaterial URL https://github.com/KomodoPlatform/Qaterial/archive/last-clang-working-2.zip)

FetchContent_Declare(
        qmaterial
        GIT_REPOSITORY https://github.com/KomodoPlatform/Qaterial.git
        GIT_TAG 53669824261ae07bc0e8c2abb4b55431f65b2055
)

# Coin metadata comes from the vendor/coins git submodule (GLEECBTC/coins, a fork
# of jl777/coins that is actively maintained and ships utils/coins_config_tcp.json).
# This is checked out via `git submodule update --init --recursive`, not FetchContent.
set(jl777-coins_SOURCE_DIR ${CMAKE_SOURCE_DIR}/vendor/coins)
if (NOT EXISTS ${jl777-coins_SOURCE_DIR}/utils/coins_config_tcp.json)
    message(FATAL_ERROR "vendor/coins submodule is missing or not initialized. Run: git submodule update --init --recursive")
endif()
if (NOT TARGET jl777-coins)
    add_library(jl777-coins INTERFACE)
endif()

if (NOT AD_SKIP_FETCHCONTENT)
    FetchContent_MakeAvailable(qmaterial)
    message(STATUS "KDF v3.0 is library-only; skipping FetchContent_MakeAvailable for kdf")
else()
    message(STATUS "AD_SKIP_FETCHCONTENT=ON: skipping FetchContent_MakeAvailable for kdf, qmaterial")
    if (NOT TARGET qmaterial)
        add_library(qmaterial INTERFACE)
    endif()
    # kdf is intentionally skipped; expect mm2 to be provided in assets/tools/kdf
endif()

##! Configure our needs.
if (UNIX)
    # vendor/coins is a required submodule (see FATAL_ERROR check above); no placeholder
    # fallback here by design (plan.md Phase 6: build fails on invalid/missing metadata).
    configure_file(${jl777-coins_SOURCE_DIR}/utils/coins_config_tcp.json ${CMAKE_CURRENT_SOURCE_DIR}/assets/config/${PROJECT_VERSION}-coins.json COPYONLY)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf/coins COPYONLY)
    if (NOT AD_SKIP_FETCHCONTENT)
        if (EXISTS ${kdf_SOURCE_DIR}/mm2)
            configure_file(${kdf_SOURCE_DIR}/mm2 ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf/${DEX_API} COPYONLY)
        else()
            message(STATUS "KDF mm2 binary not found in kdf_SOURCE_DIR; skipping mm2 copy")
            if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf)
                file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf)
            endif()
        endif()
    else()
        # If skipping fetch, do not attempt to copy mm2 from kdf_SOURCE_DIR; rely on local assets/tools/kdf
        if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf)
            file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf)
        endif()
        message(STATUS "AD_SKIP_FETCHCONTENT=ON: expecting mm2 in ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/kdf/${DEX_API}")
    endif()
    if (EXISTS ${jl777-coins_SOURCE_DIR}/icons)
        file(COPY ${jl777-coins_SOURCE_DIR}/icons/ DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/atomic_defi_design/assets/images/coins/)
    else()
        message(STATUS "vendor/coins: icons directory not found; skipping coin icons copy")
    endif()
else ()
    configure_file(${jl777-coins_SOURCE_DIR}/utils/coins_config_tcp.json ${CMAKE_BINARY_DIR}/bin/assets/config/${PROJECT_VERSION}-coins.json COPYONLY)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_BINARY_DIR}/bin/assets/tools/kdf/coins COPYONLY)
    configure_file(${kdf_SOURCE_DIR}/mm2.exe ${CMAKE_BINARY_DIR}/bin/assets/tools/kdf/${DEX_API}.exe COPYONLY)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ci_tools_atomic_dex/windows_misc/msvcp140.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/kdf/msvcp140.dll COPYONLY)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/ci_tools_atomic_dex/windows_misc/vcruntime140.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/kdf/vcruntime140.dll COPYONLY)
endif ()


add_subdirectory(vendor/antara-gaming_sdk/modules)

##! Osx bundle icon
set(ICON)
configure_icon_osx(${CMAKE_CURRENT_SOURCE_DIR}/cmake/install/macos/dex-logo.icns ICON dex-logo.icns)
##! End antara

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

add_subdirectory(src)

# Adds Qaterial hot reload to main executable
if (WITH_HOTRELOAD)
    FetchContent_Declare(
            qaterial_hotreload
            GIT_REPOSITORY https://github.com/KomodoPlatform/QaterialHotReload
            GIT_TAG ecffec6bd01d9a13561689283bc2a6a927957f64
    )
    set(QATERIALHOTRELOAD_ENABLE_HOTRELOAD_APP OFF CACHE BOOL "")
    FetchContent_MakeAvailable(qaterial_hotreload)
    target_link_libraries(${PROJECT_NAME} PUBLIC Qaterial::HotReload)
    target_compile_definitions(${PROJECT_NAME} PUBLIC ATOMICDEX_HOT_RELOAD)
endif ()

add_library(antara_qrcode STATIC)
target_sources(antara_qrcode PRIVATE vendor/qrcode/QrCode.cpp)
target_include_directories(antara_qrcode PUBLIC vendor/qrcode)
target_link_libraries(antara_qrcode PUBLIC antara::default_settings)

# Link against libwally-core
set(WALLY_ROOT ${CMAKE_SOURCE_DIR}/libwally-core-install)
if (EXISTS ${WALLY_ROOT})
    message(STATUS "Using libwally-core from ${WALLY_ROOT}")
    target_include_directories(${PROJECT_NAME} PRIVATE ${WALLY_ROOT}/include)
    target_link_directories(${PROJECT_NAME} PRIVATE ${WALLY_ROOT}/lib)
    target_link_libraries(${PROJECT_NAME} PRIVATE wallycore)
    if (TARGET ${PROJECT_NAME}_tests)
        target_include_directories(${PROJECT_NAME}_tests PRIVATE ${WALLY_ROOT}/include)
        target_link_directories(${PROJECT_NAME}_tests PRIVATE ${WALLY_ROOT}/lib)
        target_link_libraries(${PROJECT_NAME}_tests PRIVATE wallycore)
    endif()
else()
    message(WARNING "libwally-core not found at ${WALLY_ROOT}")
endif()
