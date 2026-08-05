#ifndef LIBWALLY_CORE_BIP32_H
#define LIBWALLY_CORE_BIP32_H

#include "wally_core.h"

#ifdef __cplusplus
extern "C" {
#endif

#define BIP32_ENTROPY_LEN_128 16
#define BIP32_ENTROPY_LEN_256 32
#define BIP32_ENTROPY_LEN_512 64

#define BIP32_SERIALIZED_LEN 78

#define BIP32_INITIAL_HARDENED_CHILD 0x80000000

#define BIP32_FLAG_KEY_PRIVATE 0x0

#define BIP32_FLAG_KEY_PUBLIC 0x1

#define BIP32_FLAG_SKIP_HASH 0x2

#define BIP32_FLAG_KEY_TWEAK_SUM 0x4

#define BIP32_VER_MAIN_PUBLIC 0x0488B21E
#define BIP32_VER_MAIN_PRIVATE 0x0488ADE4
#define BIP32_VER_TEST_PUBLIC 0x043587CF
#define BIP32_VER_TEST_PRIVATE 0x04358394

#ifdef SWIG
struct ext_key;
#else

struct ext_key {
  unsigned char chain_code[32];

  unsigned char parent160[20];

  uint8_t depth;
  unsigned char pad1[10];

  unsigned char priv_key[33];

  uint32_t child_num;

  unsigned char hash160[20];

  uint32_t version;
  unsigned char pad2[3];

  unsigned char pub_key[33];
#ifdef BUILD_ELEMENTS
  unsigned char pub_key_tweak_sum[32];
#endif
};
#endif

#ifndef SWIG_PYTHON

WALLY_CORE_API int bip32_key_free(const struct ext_key *hdkey);
#endif

#ifndef SWIG
WALLY_CORE_API int
bip32_key_init(uint32_t version, uint32_t depth, uint32_t child_num,
               const unsigned char *chain_code, size_t chain_code_len,
               const unsigned char *pub_key, size_t pub_key_len,
               const unsigned char *priv_key, size_t priv_key_len,
               const unsigned char *hash160, size_t hash160_len,
               const unsigned char *parent160, size_t parent160_len,
               struct ext_key *output);
#endif

WALLY_CORE_API int
bip32_key_init_alloc(uint32_t version, uint32_t depth, uint32_t child_num,
                     const unsigned char *chain_code, size_t chain_code_len,
                     const unsigned char *pub_key, size_t pub_key_len,
                     const unsigned char *priv_key, size_t priv_key_len,
                     const unsigned char *hash160, size_t hash160_len,
                     const unsigned char *parent160, size_t parent160_len,
                     struct ext_key **output);

#ifndef SWIG

WALLY_CORE_API int bip32_key_from_seed(const unsigned char *bytes,
                                       size_t bytes_len, uint32_t version,
                                       uint32_t flags, struct ext_key *output);
#endif

WALLY_CORE_API int bip32_key_from_seed_alloc(const unsigned char *bytes,
                                             size_t bytes_len, uint32_t version,
                                             uint32_t flags,
                                             struct ext_key **output);

WALLY_CORE_API int bip32_key_serialize(const struct ext_key *hdkey,
                                       uint32_t flags, unsigned char *bytes_out,
                                       size_t len);

#ifndef SWIG

WALLY_CORE_API int bip32_key_unserialize(const unsigned char *bytes,
                                         size_t bytes_len,
                                         struct ext_key *output);
#endif

WALLY_CORE_API int bip32_key_unserialize_alloc(const unsigned char *bytes,
                                               size_t bytes_len,
                                               struct ext_key **output);

#ifndef SWIG

WALLY_CORE_API int bip32_key_from_parent(const struct ext_key *hdkey,
                                         uint32_t child_num, uint32_t flags,
                                         struct ext_key *output);
#endif

WALLY_CORE_API int bip32_key_from_parent_alloc(const struct ext_key *hdkey,
                                               uint32_t child_num,
                                               uint32_t flags,
                                               struct ext_key **output);

#ifndef SWIG

WALLY_CORE_API int bip32_key_from_parent_path(const struct ext_key *hdkey,
                                              const uint32_t *child_path,
                                              size_t child_path_len,
                                              uint32_t flags,
                                              struct ext_key *output);
#endif

WALLY_CORE_API int bip32_key_from_parent_path_alloc(const struct ext_key *hdkey,
                                                    const uint32_t *child_path,
                                                    size_t child_path_len,
                                                    uint32_t flags,
                                                    struct ext_key **output);

#ifdef BUILD_ELEMENTS
#ifndef SWIG

WALLY_CORE_API int bip32_key_with_tweak_from_parent_path(
    const struct ext_key *hdkey, const uint32_t *child_path,
    size_t child_path_len, uint32_t flags, struct ext_key *output);
#endif

WALLY_CORE_API int bip32_key_with_tweak_from_parent_path_alloc(
    const struct ext_key *hdkey, const uint32_t *child_path,
    size_t child_path_len, uint32_t flags, struct ext_key **output);
#endif

WALLY_CORE_API int bip32_key_to_base58(const struct ext_key *hdkey,
                                       uint32_t flags, char **output);

#ifndef SWIG

WALLY_CORE_API int bip32_key_from_base58(const char *base58,
                                         struct ext_key *output);
#endif

WALLY_CORE_API int bip32_key_from_base58_alloc(const char *base58,
                                               struct ext_key **output);

WALLY_CORE_API int bip32_key_strip_private_key(struct ext_key *hdkey);

WALLY_CORE_API int bip32_key_get_fingerprint(struct ext_key *hdkey,
                                             unsigned char *bytes_out,
                                             size_t len);

#ifdef __cplusplus
}
#endif

#endif
