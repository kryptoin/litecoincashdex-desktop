##! Dependancies
include(FetchContent)

# Option to skip fetching external internet content for local builds
option(AD_SKIP_FETCHCONTENT "Skip FetchContent downloads and use local stubs" ON)

# Persist FetchContent downloads outside the (frequently wiped) build dir so
# network fetches happen once and are reused on subsequent builds.
set(FETCHCONTENT_BASE_DIR "${CMAKE_SOURCE_DIR}/.fetchcontent-cache" CACHE PATH "Persistent FetchContent base directory (survives build-dir wipes)" FORCE)

if (WIN32)
    find_package(ZLIB)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Override option" FORCE)
endif ()

find_package(EnTT REQUIRED)
find_package(fmt REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(range-v3 REQUIRED)
find_package(date REQUIRED)
find_package(doctest REQUIRED)
find_package(spdlog REQUIRED)
find_package(cpprestsdk REQUIRED)

if (APPLE)
    get_target_property(ACTUAL_VAR cpprestsdk::cpprest INTERFACE_LINK_LIBRARIES)
    message("Property of cpprestsdk::cpprest: ${ACTUAL_VAR}")
    set(NEW_INTERFACES "")
    foreach (CUR_LIB ${ACTUAL_VAR})
        #message(STATUS "CUR_LIB-> ${CUR_LIB}")
        if (CUR_LIB MATCHES "MacOSX")
            message(STATUS "NEED TO BE SKIPPED -> ${CUR_LIB}")
        else ()
            list(APPEND NEW_INTERFACES ${CUR_LIB})
            #message("KK-> ${NEW_INTERFACES}")
        endif ()
    endforeach ()
    set_target_properties(cpprestsdk::cpprest PROPERTIES INTERFACE_LINK_LIBRARIES "${NEW_INTERFACES}")
    get_target_property(KK_VAR cpprestsdk::cpprest INTERFACE_LINK_LIBRARIES)
    message("Property of cpprestsdk::cpprest: ${KK_VAR}")
endif ()
#find_package(absl CONFIG REQUIRED)
# Prefer FindBoost module over BoostConfig to allow using locally installed Boost variants
if(NOT DEFINED Boost_NO_BOOST_CMAKE)
    set(Boost_NO_BOOST_CMAKE ON CACHE BOOL "Prefer FindBoost module over BoostConfig" FORCE)
endif()
# Try to locate Boost; if not found, create IMPORTED interface targets as a fallback
find_package(Boost COMPONENTS filesystem random system thread QUIET)
if (NOT Boost_FOUND)
    message(WARNING "Boost not found by find_package; creating fallback IMPORTED interface targets. Build may fail at link time if Boost libraries are required.")
    # try to locate boost headers
    find_path(BOOST_INCLUDE_DIR boost/config.hpp HINTS /opt/anaconda3/include /usr/local/include /opt/homebrew/include /usr/include)
    if (NOT BOOST_INCLUDE_DIR)
        message(WARNING "Could not locate Boost headers; consider installing Boost via Homebrew or Anaconda.")
    endif()
    foreach(comp IN ITEMS filesystem random system thread)
        if (NOT TARGET Boost::${comp})
            add_library(Boost::${comp} INTERFACE IMPORTED)
            if (BOOST_INCLUDE_DIR)
                set_target_properties(Boost::${comp} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${BOOST_INCLUDE_DIR}")
            endif()
        endif()
    endforeach()
endif()
add_library(komodo-taskflow INTERFACE)
if (CONAN_ENABLED)
    find_package(Taskflow REQUIRED)
    target_link_libraries(komodo-taskflow INTERFACE Taskflow::Taskflow)
endif ()
add_library(komodo-taskflow::taskflow ALIAS komodo-taskflow)
if (CONAN_ENABLED)
    if (NOT TARGET Boost::filesystem)
        add_library(Boost::filesystem INTERFACE IMPORTED)
        if (WIN32)
            target_link_libraries(Boost::filesystem INTERFACE
                    CONAN_LIB::Boost_libboost_filesystem
                    CONAN_LIB::Boost_libboost_system
                    Boost::Boost)
        else ()

            target_link_libraries(Boost::filesystem INTERFACE
                    CONAN_LIB::Boost_boost_filesystem
                    CONAN_LIB::Boost_boost_system
                    Boost::Boost)
        endif ()
    endif ()

    if (NOT TARGET Boost::random)
        add_library(Boost::random INTERFACE IMPORTED)
        if (WIN32)
            target_link_libraries(Boost::random INTERFACE CONAN_LIB::Boost_libboost_random)
        else ()
            target_link_libraries(Boost::random INTERFACE CONAN_LIB::Boost_boost_random)
        endif ()
    endif ()
endif ()

add_library(komodo-date INTERFACE)
if (CONAN_ENABLED)
    target_link_libraries(komodo-date INTERFACE date::date)
else ()
    target_link_libraries(komodo-date INTERFACE date::date-tz)
endif ()
add_library(komodo-date::date ALIAS komodo-date)

find_package(Qt5 5.15 COMPONENTS Core Quick LinguistTools Svg Charts Widgets REQUIRED)
find_package(Qt5WebEngine QUIET)
find_package(Qt5WebEngineCore QUIET)
find_package(Qt5WebEngineWidgets QUIET)

#find_package(Qt5)

set(BUILD_TESTING OFF CACHE BOOL "Override option" FORCE)
#set(REPROC++ ON CACHE BOOL "" FORCE)

FetchContent_Declare(
        doom_st
        URL https://github.com/KomodoPlatform/strong_type/archive/1.0.2.tar.gz
)

FetchContent_Declare(
        doom_meta
        URL https://github.com/KomodoPlatform/meta/archive/master.zip
)

#FetchContent_Declare(
#        reproc
#        URL https://github.com/KomodoPlatform/reproc/archive/v14.2.1.zip
#)

set(EXPECTED_ENABLE_TESTS OFF CACHE BOOL "Override option" FORCE)

FetchContent_Declare(
        expected
        URL https://github.com/KomodoPlatform/expected/archive/patch-1.zip
)

FetchContent_Declare(
        refl-cpp
        URL https://github.com/KomodoPlatform/refl-cpp/archive/v0.6.5.zip
)

set(ATOMICDEX_VENDOR_DIR ${CMAKE_SOURCE_DIR}/vendor)

# strong_type (doom_st): header-only, vendored at vendor/strong_type/include.
if (EXISTS "${ATOMICDEX_VENDOR_DIR}/strong_type/include")
    if (NOT TARGET strong_type)
        add_library(strong_type INTERFACE)
        target_include_directories(strong_type INTERFACE ${ATOMICDEX_VENDOR_DIR}/strong_type/include)
    endif()
    if (NOT TARGET doom_st)
        add_library(doom_st INTERFACE)
        target_link_libraries(doom_st INTERFACE strong_type)
    endif()
    message(STATUS "Using vendored strong_type (vendor/strong_type)")
elseif (NOT AD_SKIP_FETCHCONTENT)
    FetchContent_MakeAvailable(doom_st)
else()
    if (NOT TARGET doom_st)
        add_library(doom_st INTERFACE)
    endif()
    if (NOT TARGET strong_type)
        add_library(strong_type INTERFACE)
    endif()
endif()

# meta (doom_meta): header-only, vendored at vendor/meta/include.
if (EXISTS "${ATOMICDEX_VENDOR_DIR}/meta/include")
    if (NOT TARGET doom_meta)
        add_library(doom_meta INTERFACE)
        target_include_directories(doom_meta INTERFACE ${ATOMICDEX_VENDOR_DIR}/meta/include)
    endif()
    if (NOT TARGET doom::meta)
        add_library(doom::meta ALIAS doom_meta)
    endif()
    message(STATUS "Using vendored meta (vendor/meta)")
elseif (NOT AD_SKIP_FETCHCONTENT)
    FetchContent_MakeAvailable(doom_meta)
    if (NOT TARGET doom::meta)
        add_library(doom::meta ALIAS doom_meta)
    endif()
else()
    if (NOT TARGET doom_meta)
        add_library(doom_meta INTERFACE)
    endif()
    if (NOT TARGET doom::meta)
        add_library(doom::meta ALIAS doom_meta)
    endif()
endif()

# refl-cpp: header-only (single refl.hpp), vendored at vendor/refl-cpp.
if (EXISTS "${ATOMICDEX_VENDOR_DIR}/refl-cpp/refl.hpp")
    if (NOT TARGET refl-cpp)
        add_library(refl-cpp INTERFACE)
        target_include_directories(refl-cpp INTERFACE ${ATOMICDEX_VENDOR_DIR}/refl-cpp)
    endif()
    if (NOT TARGET antara::refl-cpp)
        add_library(antara::refl-cpp ALIAS refl-cpp)
    endif()
    message(STATUS "Using vendored refl-cpp (vendor/refl-cpp)")
elseif (NOT AD_SKIP_FETCHCONTENT)
    FetchContent_MakeAvailable(refl-cpp)
    if (NOT TARGET refl-cpp)
        add_library(refl-cpp INTERFACE)
        target_include_directories(refl-cpp INTERFACE ${refl-cpp_SOURCE_DIR})
    endif()
    if (NOT TARGET antara::refl-cpp)
        add_library(antara::refl-cpp ALIAS refl-cpp)
    endif()
else()
    if (NOT TARGET refl-cpp)
        add_library(refl-cpp INTERFACE)
    endif()
    if (NOT TARGET antara::refl-cpp)
        add_library(antara::refl-cpp ALIAS refl-cpp)
    endif()
endif()

# expected (tl/expected): header-only, vendored at vendor/expected/include.
if (EXISTS "${ATOMICDEX_VENDOR_DIR}/expected/include")
    if (NOT TARGET expected)
        add_library(expected INTERFACE)
        target_include_directories(expected INTERFACE ${ATOMICDEX_VENDOR_DIR}/expected/include)
    endif()
    message(STATUS "Using vendored expected (vendor/expected)")
elseif (NOT AD_SKIP_FETCHCONTENT)
    FetchContent_GetProperties(expected)
    if (NOT expected_POPULATED)
        FetchContent_Populate(expected)
        add_subdirectory(${expected_SOURCE_DIR} ${expected_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif ()
else()
    if (NOT TARGET expected)
        add_library(expected INTERFACE)
    endif()
endif()

add_library(doctest INTERFACE)
target_link_libraries(doctest INTERFACE doctest::doctest)

add_library(antara_entt INTERFACE)
target_link_libraries(antara_entt INTERFACE EnTT::EnTT)
add_library(antara::entt ALIAS antara_entt)

#FetchContent_GetProperties(reproc)
#if (NOT reproc_POPULATED)
 #   FetchContent_Populate(reproc)
 #   add_subdirectory(${reproc_SOURCE_DIR} ${reproc_BINARY_DIR} EXCLUDE_FROM_ALL)
#endif ()


##! Sodium
add_library(komodo-sodium INTERFACE)
if (CONAN_ENABLED)
    find_package(libsodium REQUIRED)
else ()
    if (TARGET sodium::sodium)
        target_link_libraries(komodo-sodium INTERFACE sodium::sodium)
    elseif (TARGET unofficial-sodium::sodium)
        target_link_libraries(komodo-sodium INTERFACE unofficial-sodium::sodium)
    else ()
        find_package(PkgConfig QUIET)
        if (PkgConfig_FOUND)
            pkg_check_modules(SODIUM QUIET IMPORTED_TARGET libsodium)
            if (SODIUM_FOUND)
                target_link_libraries(komodo-sodium INTERFACE PkgConfig::SODIUM)
            else ()
                find_package(unofficial-sodium CONFIG REQUIRED)
                target_link_libraries(komodo-sodium INTERFACE unofficial-sodium::sodium)
            endif ()
        else ()
            find_package(unofficial-sodium CONFIG REQUIRED)
            target_link_libraries(komodo-sodium INTERFACE unofficial-sodium::sodium)
        endif ()
    endif ()
endif ()
add_library(komodo-sodium::sodium ALIAS komodo-sodium)


## Unofficial BTC
add_library(unofficial-bitcoin INTERFACE)
if (WIN32)
    #target_link_directories(unofficial-	bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally)
    target_link_libraries(unofficial-bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally/wally.lib)
    target_include_directories(unofficial-bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally)
else ()
    # Try to find wally in the custom installation directory first
    set(WALLY_INSTALL_DIR "${PROJECT_SOURCE_DIR}/wally-install")
    if (EXISTS "${WALLY_INSTALL_DIR}")
        find_library(unofficial-wally wallycore HINTS "${WALLY_INSTALL_DIR}/lib")
        find_library(unofficial-secp secp256k1 HINTS "${WALLY_INSTALL_DIR}/lib")
        find_path(unofficial-wally-headers wally_core.h HINTS "${WALLY_INSTALL_DIR}/include")
        if (unofficial-wally AND unofficial-secp AND unofficial-wally-headers)
            target_link_libraries(unofficial-bitcoin INTERFACE ${unofficial-wally} ${unofficial-secp})
            target_include_directories(unofficial-bitcoin INTERFACE ${unofficial-wally-headers})
            message(STATUS "Found wally in custom install -> ${unofficial-wally} ${unofficial-wally-headers}")
        else ()
            # Fallback to system search
            find_library(unofficial-secp secp256k1)
            find_library(unofficial-wally wallycore)
            if (unofficial-wally AND unofficial-secp)
                find_path(unofficial-wally-headers wally_core.h)
                target_link_libraries(unofficial-bitcoin INTERFACE ${unofficial-wally} ${unofficial-secp})
                target_include_directories(unofficial-bitcoin INTERFACE ${unofficial-wally-headers})
                message(STATUS "Found wally from system -> ${unofficial-wally} ${unofficial-wally-headers}")
            else ()
                # Fallback to local headers if system libraries not found
                message(STATUS "System wallycore not found, using local headers")
                target_include_directories(unofficial-bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally)
                if (unofficial-secp)
                    target_link_libraries(unofficial-bitcoin INTERFACE ${unofficial-secp})
                endif ()
            endif ()
        endif ()
    else ()
        # Fallback to system search if custom install doesn't exist
        find_library(unofficial-secp secp256k1)
        find_library(unofficial-wally wallycore)
        if (unofficial-wally AND unofficial-secp)
            find_path(unofficial-wally-headers wally_core.h)
            target_link_libraries(unofficial-bitcoin INTERFACE ${unofficial-wally} ${unofficial-secp})
            target_include_directories(unofficial-bitcoin INTERFACE ${unofficial-wally-headers})
            message(STATUS "Found wally from system -> ${unofficial-wally} ${unofficial-wally-headers}")
        else ()
            # Fallback to local headers if system libraries not found
            message(STATUS "System wallycore not found, using local headers")
            target_include_directories(unofficial-bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally)
            if (unofficial-secp)
                target_link_libraries(unofficial-bitcoin INTERFACE ${unofficial-secp})
            endif ()
        endif ()
    endif ()
endif ()
add_library(unofficial-btc::bitcoin ALIAS unofficial-bitcoin)