#ifndef LIBWALLY_CORE_BIP39_H
#define LIBWALLY_CORE_BIP39_H

#include "wally_core.h"

#ifdef __cplusplus
extern "C" {
#endif

struct words;

#define BIP39_ENTROPY_LEN_128 16
#define BIP39_ENTROPY_LEN_160 20
#define BIP39_ENTROPY_LEN_192 24
#define BIP39_ENTROPY_LEN_224 28
#define BIP39_ENTROPY_LEN_256 32
#define BIP39_ENTROPY_LEN_288 36
#define BIP39_ENTROPY_LEN_320 40

#define BIP39_SEED_LEN_512 64

#define BIP39_WORDLIST_LEN 2048

WALLY_CORE_API int bip39_get_languages(char **output);

WALLY_CORE_API int bip39_get_wordlist(const char *lang, struct words **output);

WALLY_CORE_API int bip39_get_word(const struct words *w, size_t index,
                                  char **output);

WALLY_CORE_API int bip39_mnemonic_from_bytes(const struct words *w,
                                             const unsigned char *bytes,
                                             size_t bytes_len, char **output);

WALLY_CORE_API int bip39_mnemonic_to_bytes(const struct words *w,
                                           const char *mnemonic,
                                           unsigned char *bytes_out, size_t len,
                                           size_t *written);

WALLY_CORE_API int bip39_mnemonic_validate(const struct words *w,
                                           const char *mnemonic);

WALLY_CORE_API int bip39_mnemonic_to_seed(const char *mnemonic,
                                          const char *passphrase,
                                          unsigned char *bytes_out, size_t len,
                                          size_t *written);

#ifdef __cplusplus
}
#endif

#endif
