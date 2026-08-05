#ifndef LIBWALLY_CORE_BIP38_H
#define LIBWALLY_CORE_BIP38_H

#include "wally_core.h"

#ifdef __cplusplus
extern "C" {
#endif

#define BIP38_KEY_MAINNET 0

#define BIP38_KEY_TESTNET 111

#define BIP38_KEY_COMPRESSED 256

#define BIP38_KEY_EC_MULT 512

#define BIP38_KEY_QUICK_CHECK 1024

#define BIP38_KEY_RAW_MODE 2048

#define BIP38_KEY_SWAP_ORDER 4096

#define BIP38_SERIALIZED_LEN 39

WALLY_CORE_API int bip38_raw_from_private_key(
    const unsigned char *bytes, size_t bytes_len, const unsigned char *pass,
    size_t pass_len, uint32_t flags, unsigned char *bytes_out, size_t len);

WALLY_CORE_API int bip38_from_private_key(const unsigned char *bytes,
                                          size_t bytes_len,
                                          const unsigned char *pass,
                                          size_t pass_len, uint32_t flags,
                                          char **output);

WALLY_CORE_API int
bip38_raw_to_private_key(const unsigned char *bytes, size_t bytes_len,
                         const unsigned char *pass, size_t pass_len,
                         uint32_t flags, unsigned char *bytes_out, size_t len);

WALLY_CORE_API int bip38_to_private_key(const char *bip38,
                                        const unsigned char *pass,
                                        size_t pass_len, uint32_t flags,
                                        unsigned char *bytes_out, size_t len);

WALLY_CORE_API int bip38_raw_get_flags(const unsigned char *bytes,
                                       size_t bytes_len, size_t *written);

WALLY_CORE_API int bip38_get_flags(const char *bip38, size_t *written);

#ifdef __cplusplus
}
#endif

#endif
