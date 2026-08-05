#ifndef WALLY_CORE_H
#define WALLY_CORE_H

#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef WALLY_CORE_API
#if defined(_WIN32)
#ifdef WALLY_CORE_BUILD
#define WALLY_CORE_API __declspec(dllexport)
#else
#define WALLY_CORE_API
#endif
#elif defined(__GNUC__) && defined(WALLY_CORE_BUILD)
#define WALLY_CORE_API __attribute__((visibility("default")))
#else
#define WALLY_CORE_API
#endif
#endif

#define WALLY_OK 0

#define WALLY_ERROR -1

#define WALLY_EINVAL -2

#define WALLY_ENOMEM -3

#define FINGERPRINT_LEN 4

WALLY_CORE_API int wally_init(uint32_t flags);

WALLY_CORE_API int wally_cleanup(uint32_t flags);

#ifndef SWIG

struct secp256k1_context_struct *wally_get_secp_context(void);
#endif

WALLY_CORE_API int wally_bzero(void *bytes, size_t bytes_len);

WALLY_CORE_API int wally_free_string(char *str);

#define WALLY_SECP_RANDOMIZE_LEN 32

WALLY_CORE_API int wally_secp_randomize(const unsigned char *bytes,
                                        size_t bytes_len);

WALLY_CORE_API int wally_hex_from_bytes(const unsigned char *bytes,
                                        size_t bytes_len, char **output);

WALLY_CORE_API int wally_hex_to_bytes(const char *hex, unsigned char *bytes_out,
                                      size_t len, size_t *written);

#define BASE58_FLAG_CHECKSUM 0x1

#define BASE58_CHECKSUM_LEN 4

WALLY_CORE_API int wally_base58_from_bytes(const unsigned char *bytes,
                                           size_t bytes_len, uint32_t flags,
                                           char **output);

WALLY_CORE_API int wally_base58_to_bytes(const char *str_in, uint32_t flags,
                                         unsigned char *bytes_out, size_t len,
                                         size_t *written);

WALLY_CORE_API int wally_base58_get_length(const char *str_in, size_t *written);

#ifndef SWIG

typedef void *(*wally_malloc_t)(size_t size);

typedef void (*wally_free_t)(void *ptr);

typedef void (*wally_bzero_t)(void *ptr, size_t len);

typedef int (*wally_ec_nonce_t)(unsigned char *nonce32,
                                const unsigned char *msg32,
                                const unsigned char *key32,
                                const unsigned char *algo16, void *data,
                                unsigned int attempt);

struct wally_operations {
  wally_malloc_t malloc_fn;
  wally_free_t free_fn;
  wally_bzero_t bzero_fn;
  wally_ec_nonce_t ec_nonce_fn;
};

WALLY_CORE_API int wally_get_operations(struct wally_operations *output);

WALLY_CORE_API int wally_set_operations(const struct wally_operations *ops);

#endif

WALLY_CORE_API int wally_is_elements_build(uint64_t *value_out);

#ifdef __cplusplus
}
#endif

#endif
