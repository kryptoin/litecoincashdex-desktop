#ifndef LIBWALLY_CORE_CRYPTO_H
#define LIBWALLY_CORE_CRYPTO_H

#include "wally_core.h"

#ifdef __cplusplus
extern "C" {
#endif

WALLY_CORE_API int wally_scrypt(const unsigned char *pass, size_t pass_len,
                                const unsigned char *salt, size_t salt_len,
                                uint32_t cost, uint32_t block_size,
                                uint32_t parallelism, unsigned char *bytes_out,
                                size_t len);

#define AES_BLOCK_LEN 16

#define AES_KEY_LEN_128 16

#define AES_KEY_LEN_192 24

#define AES_KEY_LEN_256 32

#define AES_FLAG_ENCRYPT 1

#define AES_FLAG_DECRYPT 2

WALLY_CORE_API int wally_aes(const unsigned char *key, size_t key_len,
                             const unsigned char *bytes, size_t bytes_len,
                             uint32_t flags, unsigned char *bytes_out,
                             size_t len);

WALLY_CORE_API int wally_aes_cbc(const unsigned char *key, size_t key_len,
                                 const unsigned char *iv, size_t iv_len,
                                 const unsigned char *bytes, size_t bytes_len,
                                 uint32_t flags, unsigned char *bytes_out,
                                 size_t len, size_t *written);

#define SHA256_LEN 32

#define SHA512_LEN 64

WALLY_CORE_API int wally_sha256(const unsigned char *bytes, size_t bytes_len,
                                unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_sha256_midstate(const unsigned char *bytes,
                                         size_t bytes_len,
                                         unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_sha256d(const unsigned char *bytes, size_t bytes_len,
                                 unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_sha512(const unsigned char *bytes, size_t bytes_len,
                                unsigned char *bytes_out, size_t len);

#define HASH160_LEN 20

WALLY_CORE_API int wally_hash160(const unsigned char *bytes, size_t bytes_len,
                                 unsigned char *bytes_out, size_t len);

#define HMAC_SHA256_LEN 32

#define HMAC_SHA512_LEN 64

WALLY_CORE_API int wally_hmac_sha256(const unsigned char *key, size_t key_len,
                                     const unsigned char *bytes,
                                     size_t bytes_len, unsigned char *bytes_out,
                                     size_t len);

WALLY_CORE_API int wally_hmac_sha512(const unsigned char *key, size_t key_len,
                                     const unsigned char *bytes,
                                     size_t bytes_len, unsigned char *bytes_out,
                                     size_t len);

#define PBKDF2_HMAC_SHA256_LEN 32

#define PBKDF2_HMAC_SHA512_LEN 64

WALLY_CORE_API int
wally_pbkdf2_hmac_sha256(const unsigned char *pass, size_t pass_len,
                         const unsigned char *salt, size_t salt_len,
                         uint32_t flags, uint32_t cost,
                         unsigned char *bytes_out, size_t len);

WALLY_CORE_API int
wally_pbkdf2_hmac_sha512(const unsigned char *pass, size_t pass_len,
                         const unsigned char *salt, size_t salt_len,
                         uint32_t flags, uint32_t cost,
                         unsigned char *bytes_out, size_t len);

#define EC_PRIVATE_KEY_LEN 32

#define EC_PUBLIC_KEY_LEN 33

#define EC_PUBLIC_KEY_UNCOMPRESSED_LEN 65

#define EC_MESSAGE_HASH_LEN 32

#define EC_SIGNATURE_LEN 64

#define EC_SIGNATURE_RECOVERABLE_LEN 65

#define EC_SIGNATURE_DER_MAX_LEN 72

#define EC_SIGNATURE_DER_MAX_LOW_R_LEN 71

#define EC_FLAG_ECDSA 0x1

#define EC_FLAG_SCHNORR 0x2

#define EC_FLAG_GRIND_R 0x4

#define EC_FLAG_RECOVERABLE 0x8

WALLY_CORE_API int wally_ec_private_key_verify(const unsigned char *priv_key,
                                               size_t priv_key_len);

WALLY_CORE_API int wally_ec_public_key_verify(const unsigned char *pub_key,
                                              size_t pub_key_len);

WALLY_CORE_API int
wally_ec_public_key_from_private_key(const unsigned char *priv_key,
                                     size_t priv_key_len,
                                     unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_ec_public_key_decompress(const unsigned char *pub_key,
                                                  size_t pub_key_len,
                                                  unsigned char *bytes_out,
                                                  size_t len);

WALLY_CORE_API int wally_ec_public_key_negate(const unsigned char *pub_key,
                                              size_t pub_key_len,
                                              unsigned char *bytes_out,
                                              size_t len);

WALLY_CORE_API int
wally_ec_sig_from_bytes(const unsigned char *priv_key, size_t priv_key_len,
                        const unsigned char *bytes, size_t bytes_len,
                        uint32_t flags, unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_ec_sig_normalize(const unsigned char *sig,
                                          size_t sig_len,
                                          unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_ec_sig_to_der(const unsigned char *sig, size_t sig_len,
                                       unsigned char *bytes_out, size_t len,
                                       size_t *written);

WALLY_CORE_API int wally_ec_sig_from_der(const unsigned char *bytes,
                                         size_t bytes_len,
                                         unsigned char *bytes_out, size_t len);

WALLY_CORE_API int
wally_ec_sig_verify(const unsigned char *pub_key, size_t pub_key_len,
                    const unsigned char *bytes, size_t bytes_len,
                    uint32_t flags, const unsigned char *sig, size_t sig_len);

WALLY_CORE_API int
wally_ec_sig_to_public_key(const unsigned char *bytes, size_t bytes_len,
                           const unsigned char *sig, size_t sig_len,
                           unsigned char *bytes_out, size_t len);

#define BITCOIN_MESSAGE_MAX_LEN (64 * 1024 - 64)

#define BITCOIN_MESSAGE_FLAG_HASH 1

WALLY_CORE_API int wally_format_bitcoin_message(const unsigned char *bytes,
                                                size_t bytes_len,
                                                uint32_t flags,
                                                unsigned char *bytes_out,
                                                size_t len, size_t *written);

WALLY_CORE_API int wally_ecdh(const unsigned char *pub_key, size_t pub_key_len,
                              const unsigned char *bytes, size_t bytes_len,
                              unsigned char *bytes_out, size_t len);

#ifdef __cplusplus
}
#endif

#endif
