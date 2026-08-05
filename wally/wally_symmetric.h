#ifndef LIBWALLY_CORE_SYMMETRIC_H
#define LIBWALLY_CORE_SYMMETRIC_H

#include "wally_core.h"

#ifdef __cplusplus
extern "C" {
#endif

#define SYMMETRIC_KEY_LEN 32

WALLY_CORE_API int wally_symmetric_key_from_seed(const unsigned char *bytes,
                                                 size_t bytes_len,
                                                 unsigned char *bytes_out,
                                                 size_t len);

WALLY_CORE_API int
wally_symmetric_key_from_parent(const unsigned char *bytes, size_t bytes_len,
                                unsigned char version,
                                const unsigned char *label, size_t label_len,
                                unsigned char *bytes_out, size_t len);

#ifdef __cplusplus
}
#endif

#endif
