#ifndef LIBWALLY_CORE_ADDRESS_H
#define LIBWALLY_CORE_ADDRESS_H

#include "wally_core.h"

#ifdef __cplusplus
extern "C" {
#endif

struct ext_key;

#define WALLY_WIF_FLAG_COMPRESSED 0x0

#define WALLY_WIF_FLAG_UNCOMPRESSED 0x1

#define WALLY_CA_PREFIX_LIQUID 0x0c

#define WALLY_CA_PREFIX_LIQUID_REGTEST 0x04

#define WALLY_NETWORK_BITCOIN_MAINNET 0x01

#define WALLY_NETWORK_BITCOIN_TESTNET 0x02

#define WALLY_NETWORK_LIQUID 0x03

#define WALLY_NETWORK_LIQUID_REGTEST 0x04

#define WALLY_ADDRESS_TYPE_P2PKH 0x01

#define WALLY_ADDRESS_TYPE_P2SH_P2WPKH 0x02

#define WALLY_ADDRESS_TYPE_P2WPKH 0x04

#define WALLY_ADDRESS_VERSION_P2PKH_MAINNET 0x00

#define WALLY_ADDRESS_VERSION_P2PKH_TESTNET 0x6F

#define WALLY_ADDRESS_VERSION_P2PKH_LIQUID 0x39

#define WALLY_ADDRESS_VERSION_P2PKH_LIQUID_REGTEST 0xEB

#define WALLY_ADDRESS_VERSION_P2SH_MAINNET 0x05

#define WALLY_ADDRESS_VERSION_P2SH_TESTNET 0xC4

#define WALLY_ADDRESS_VERSION_P2SH_LIQUID 0x27

#define WALLY_ADDRESS_VERSION_P2SH_LIQUID_REGTEST 0x4B

#define WALLY_ADDRESS_VERSION_WIF_MAINNET 0x80

#define WALLY_ADDRESS_VERSION_WIF_TESTNET 0xEF

WALLY_CORE_API int wally_addr_segwit_from_bytes(const unsigned char *bytes,
                                                size_t bytes_len,
                                                const char *addr_family,
                                                uint32_t flags, char **output);

WALLY_CORE_API int wally_addr_segwit_to_bytes(const char *addr,
                                              const char *addr_family,
                                              uint32_t flags,
                                              unsigned char *bytes_out,
                                              size_t len, size_t *written);

WALLY_CORE_API int wally_address_to_scriptpubkey(const char *addr,
                                                 uint32_t network,
                                                 unsigned char *bytes_out,
                                                 size_t len, size_t *written);

WALLY_CORE_API int
wally_scriptpubkey_to_address(const unsigned char *scriptpubkey,
                              size_t scriptpubkey_len, uint32_t network,
                              char **output);

WALLY_CORE_API int wally_wif_from_bytes(const unsigned char *priv_key,
                                        size_t priv_key_len, uint32_t prefix,
                                        uint32_t flags, char **output);

WALLY_CORE_API int wally_wif_to_bytes(const char *wif, uint32_t prefix,
                                      uint32_t flags, unsigned char *bytes_out,
                                      size_t len);

WALLY_CORE_API int wally_wif_is_uncompressed(const char *wif, size_t *written);

WALLY_CORE_API int wally_wif_to_public_key(const char *wif, uint32_t prefix,
                                           unsigned char *bytes_out, size_t len,
                                           size_t *written);

WALLY_CORE_API int wally_bip32_key_to_address(const struct ext_key *hdkey,
                                              uint32_t flags, uint32_t version,
                                              char **output);

WALLY_CORE_API int wally_bip32_key_to_addr_segwit(const struct ext_key *hdkey,
                                                  const char *addr_family,
                                                  uint32_t flags,
                                                  char **output);

WALLY_CORE_API int wally_wif_to_address(const char *wif, uint32_t prefix,
                                        uint32_t version, char **output);

#ifdef BUILD_ELEMENTS

WALLY_CORE_API int wally_confidential_addr_to_addr(const char *address,
                                                   uint32_t prefix,
                                                   char **output);

WALLY_CORE_API int
wally_confidential_addr_to_ec_public_key(const char *address, uint32_t prefix,
                                         unsigned char *bytes_out, size_t len);

WALLY_CORE_API int
wally_confidential_addr_from_addr(const char *address, uint32_t prefix,
                                  const unsigned char *pub_key,
                                  size_t pub_key_len, char **output);

WALLY_CORE_API int
wally_confidential_addr_to_addr_segwit(const char *address,
                                       const char *confidential_addr_family,
                                       const char *addr_family, char **output);

WALLY_CORE_API int wally_confidential_addr_segwit_to_ec_public_key(
    const char *address, const char *confidential_addr_family,
    unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_confidential_addr_from_addr_segwit(
    const char *address, const char *addr_family,
    const char *confidential_addr_family, const unsigned char *pub_key,
    size_t pub_key_len, char **output);
#endif

#ifdef __cplusplus
}
#endif

#endif
