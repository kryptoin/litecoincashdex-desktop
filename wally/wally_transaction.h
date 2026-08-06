#ifndef LIBWALLY_CORE_TRANSACTION_H
#define LIBWALLY_CORE_TRANSACTION_H

#include "wally_core.h"
#include "wally_crypto.h"

#ifdef __cplusplus
extern "C" {
#endif

#define WALLY_BTC_MAX 21000000
#define WALLY_SATOSHI_PER_BTC 100000000
#define WALLY_SIGHASH_ALL 0x01
#define WALLY_SIGHASH_ANYONECANPAY 0x80
#define WALLY_SIGHASH_FORKID 0x40
#define WALLY_SIGHASH_NONE 0x02
#define WALLY_SIGHASH_SINGLE 0x03
#define WALLY_TX_ASSET_CT_ASSET_LEN 33
#define WALLY_TX_ASSET_CT_ASSET_PREFIX_A 10
#define WALLY_TX_ASSET_CT_ASSET_PREFIX_B 11
#define WALLY_TX_ASSET_CT_LEN 33
#define WALLY_TX_ASSET_CT_NONCE_LEN 33
#define WALLY_TX_ASSET_CT_NONCE_PREFIX_A 2
#define WALLY_TX_ASSET_CT_NONCE_PREFIX_B 3
#define WALLY_TX_ASSET_CT_VALUE_LEN 33
#define WALLY_TX_ASSET_CT_VALUE_PREFIX_A 8
#define WALLY_TX_ASSET_CT_VALUE_PREFIX_B 9
#define WALLY_TX_ASSET_CT_VALUE_UNBLIND_LEN 9
#define WALLY_TX_ASSET_TAG_LEN 32
#define WALLY_TX_DUMMY_NULL 0x1
#define WALLY_TX_DUMMY_SIG 0x2
#define WALLY_TX_DUMMY_SIG_LOW_R 0x4
#define WALLY_TX_FLAG_BLINDED_INITIAL_ISSUANCE 0x1
#define WALLY_TX_FLAG_USE_ELEMENTS 0x2
#define WALLY_TX_FLAG_USE_WITNESS 0x1
#define WALLY_TX_INDEX_MASK 0x3fffffff
#define WALLY_TX_IS_COINBASE 8
#define WALLY_TX_IS_ELEMENTS 1
#define WALLY_TX_IS_ISSUANCE 2
#define WALLY_TX_IS_PEGIN 4
#define WALLY_TX_ISSUANCE_FLAG (1 << 31)
#define WALLY_TX_PEGIN_FLAG (1 << 30)
#define WALLY_TX_SEQUENCE_FINAL 0xffffffff
#define WALLY_TX_VERSION_1 1
#define WALLY_TX_VERSION_2 2
#define WALLY_TXHASH_LEN 32

#ifdef SWIG
struct wally_tx_input;
struct wally_tx_output;
struct wally_tx;
#else

struct wally_tx_witness_item {
  unsigned char *witness;
  size_t witness_len;
};

struct wally_tx_witness_stack {
  struct wally_tx_witness_item *items;
  size_t num_items;
  size_t items_allocation_len;
};

struct wally_tx_input {
  unsigned char txhash[WALLY_TXHASH_LEN];
  uint32_t index;
  uint32_t sequence;
  unsigned char *script;
  size_t script_len;
  struct wally_tx_witness_stack *witness;
  uint8_t features;
#ifdef BUILD_ELEMENTS
  unsigned char blinding_nonce[SHA256_LEN];
  unsigned char entropy[SHA256_LEN];
  unsigned char *issuance_amount;
  size_t issuance_amount_len;
  unsigned char *inflation_keys;
  size_t inflation_keys_len;
  unsigned char *issuance_amount_rangeproof;
  size_t issuance_amount_rangeproof_len;
  unsigned char *inflation_keys_rangeproof;
  size_t inflation_keys_rangeproof_len;
  struct wally_tx_witness_stack *pegin_witness;
#endif
};

struct wally_tx_output {
  uint64_t satoshi;
  unsigned char *script;
  size_t script_len;
  uint8_t features;
#ifdef BUILD_ELEMENTS
  unsigned char *asset;
  size_t asset_len;
  unsigned char *value;
  size_t value_len;
  unsigned char *nonce;
  size_t nonce_len;
  unsigned char *surjectionproof;
  size_t surjectionproof_len;
  unsigned char *rangeproof;
  size_t rangeproof_len;
#endif
};

struct wally_tx {
  uint32_t version;
  uint32_t locktime;
  struct wally_tx_input *inputs;
  size_t num_inputs;
  size_t inputs_allocation_len;
  struct wally_tx_output *outputs;
  size_t num_outputs;
  size_t outputs_allocation_len;
};
#endif

WALLY_CORE_API int
wally_tx_witness_stack_init_alloc(size_t allocation_len,
                                  struct wally_tx_witness_stack **output);

WALLY_CORE_API int
wally_tx_witness_stack_add(struct wally_tx_witness_stack *stack,
                           const unsigned char *witness, size_t witness_len);

WALLY_CORE_API int
wally_tx_witness_stack_add_dummy(struct wally_tx_witness_stack *stack,
                                 uint32_t flags);

WALLY_CORE_API int
wally_tx_witness_stack_set(struct wally_tx_witness_stack *stack, size_t index,
                           const unsigned char *witness, size_t witness_len);

WALLY_CORE_API int
wally_tx_witness_stack_set_dummy(struct wally_tx_witness_stack *stack,
                                 size_t index, uint32_t flags);

#ifndef SWIG_PYTHON

WALLY_CORE_API int
wally_tx_witness_stack_free(struct wally_tx_witness_stack *stack);
#endif

WALLY_CORE_API int
wally_tx_input_init_alloc(const unsigned char *txhash, size_t txhash_len,
                          uint32_t index, uint32_t sequence,
                          const unsigned char *script, size_t script_len,
                          const struct wally_tx_witness_stack *witness,
                          struct wally_tx_input **output);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_tx_input_free(struct wally_tx_input *input);
#endif

WALLY_CORE_API int wally_tx_output_init_alloc(uint64_t satoshi,
                                              const unsigned char *script,
                                              size_t script_len,
                                              struct wally_tx_output **output);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_tx_output_free(struct wally_tx_output *output);
#endif

WALLY_CORE_API int wally_tx_init_alloc(uint32_t version, uint32_t locktime,
                                       size_t inputs_allocation_len,
                                       size_t outputs_allocation_len,
                                       struct wally_tx **output);

WALLY_CORE_API int wally_tx_add_input(struct wally_tx *tx,
                                      const struct wally_tx_input *input);

WALLY_CORE_API int
wally_tx_add_raw_input(struct wally_tx *tx, const unsigned char *txhash,
                       size_t txhash_len, uint32_t index, uint32_t sequence,
                       const unsigned char *script, size_t script_len,
                       const struct wally_tx_witness_stack *witness,
                       uint32_t flags);

WALLY_CORE_API int wally_tx_remove_input(struct wally_tx *tx, size_t index);

WALLY_CORE_API int wally_tx_set_input_script(const struct wally_tx *tx,
                                             size_t index,
                                             const unsigned char *script,
                                             size_t script_len);

WALLY_CORE_API int
wally_tx_set_input_witness(const struct wally_tx *tx, size_t index,
                           const struct wally_tx_witness_stack *stack);

WALLY_CORE_API int wally_tx_add_output(struct wally_tx *tx,
                                       const struct wally_tx_output *output);

WALLY_CORE_API int wally_tx_add_raw_output(struct wally_tx *tx,
                                           uint64_t satoshi,
                                           const unsigned char *script,
                                           size_t script_len, uint32_t flags);

WALLY_CORE_API int wally_tx_remove_output(struct wally_tx *tx, size_t index);

WALLY_CORE_API int wally_tx_get_witness_count(const struct wally_tx *tx,
                                              size_t *written);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_tx_free(struct wally_tx *tx);
#endif

WALLY_CORE_API int wally_tx_get_length(const struct wally_tx *tx,
                                       uint32_t flags, size_t *written);

WALLY_CORE_API int wally_tx_from_bytes(const unsigned char *bytes,
                                       size_t bytes_len, uint32_t flags,
                                       struct wally_tx **output);

WALLY_CORE_API int wally_tx_from_hex(const char *hex, uint32_t flags,
                                     struct wally_tx **output);

WALLY_CORE_API int wally_tx_to_bytes(const struct wally_tx *tx, uint32_t flags,
                                     unsigned char *bytes_out, size_t len,
                                     size_t *written);

WALLY_CORE_API int wally_tx_to_hex(const struct wally_tx *tx, uint32_t flags,
                                   char **output);

WALLY_CORE_API int wally_tx_get_weight(const struct wally_tx *tx,
                                       size_t *written);

WALLY_CORE_API int wally_tx_get_vsize(const struct wally_tx *tx,
                                      size_t *written);

WALLY_CORE_API int wally_tx_vsize_from_weight(size_t weight, size_t *written);

WALLY_CORE_API int wally_tx_get_total_output_satoshi(const struct wally_tx *tx,
                                                     uint64_t *value_out);

WALLY_CORE_API int wally_tx_get_btc_signature_hash(
    const struct wally_tx *tx, size_t index, const unsigned char *script,
    size_t script_len, uint64_t satoshi, uint32_t sighash, uint32_t flags,
    unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_tx_get_signature_hash(
    const struct wally_tx *tx, size_t index, const unsigned char *script,
    size_t script_len, const unsigned char *extra, size_t extra_len,
    uint32_t extra_offset, uint64_t satoshi, uint32_t sighash,
    uint32_t tx_sighash, uint32_t flags, unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_tx_is_coinbase(const struct wally_tx *tx,
                                        size_t *written);

#ifdef BUILD_ELEMENTS

WALLY_CORE_API int wally_tx_elements_input_issuance_set(
    struct wally_tx_input *input, const unsigned char *nonce, size_t nonce_len,
    const unsigned char *entropy, size_t entropy_len,
    const unsigned char *issuance_amount, size_t issuance_amount_len,
    const unsigned char *inflation_keys, size_t inflation_keys_len,
    const unsigned char *issuance_amount_rangeproof,
    size_t issuance_amount_rangeproof_len,
    const unsigned char *inflation_keys_rangeproof,
    size_t inflation_keys_rangeproof_len);

#ifndef SWIG_PYTHON

WALLY_CORE_API int
wally_tx_elements_input_issuance_free(struct wally_tx_input *input);
#endif

WALLY_CORE_API int wally_tx_elements_input_init_alloc(
    const unsigned char *txhash, size_t txhash_len, uint32_t index,
    uint32_t sequence, const unsigned char *script, size_t script_len,
    const struct wally_tx_witness_stack *witness, const unsigned char *nonce,
    size_t nonce_len, const unsigned char *entropy, size_t entropy_len,
    const unsigned char *issuance_amount, size_t issuance_amount_len,
    const unsigned char *inflation_keys, size_t inflation_keys_len,
    const unsigned char *issuance_amount_rangeproof,
    size_t issuance_amount_rangeproof_len,
    const unsigned char *inflation_keys_rangeproof,
    size_t inflation_keys_rangeproof_len,
    const struct wally_tx_witness_stack *pegin_witness,
    struct wally_tx_input **output);

WALLY_CORE_API int
wally_tx_elements_input_is_pegin(const struct wally_tx_input *input,
                                 size_t *written);

WALLY_CORE_API int wally_tx_elements_output_commitment_set(
    struct wally_tx_output *input, const unsigned char *asset, size_t asset_len,
    const unsigned char *value, size_t value_len, const unsigned char *nonce,
    size_t nonce_len, const unsigned char *surjectionproof,
    size_t surjectionproof_len, const unsigned char *rangeproof,
    size_t rangeproof_len);

#ifndef SWIG_PYTHON

WALLY_CORE_API int
wally_tx_elements_output_commitment_free(struct wally_tx_output *output);
#endif

WALLY_CORE_API int wally_tx_elements_output_init_alloc(
    const unsigned char *script, size_t script_len, const unsigned char *asset,
    size_t asset_len, const unsigned char *value, size_t value_len,
    const unsigned char *nonce, size_t nonce_len,
    const unsigned char *surjectionproof, size_t surjectionproof_len,
    const unsigned char *rangeproof, size_t rangeproof_len,
    struct wally_tx_output **output);

WALLY_CORE_API int wally_tx_add_elements_raw_input(
    struct wally_tx *tx, const unsigned char *txhash, size_t txhash_len,
    uint32_t index, uint32_t sequence, const unsigned char *script,
    size_t script_len, const struct wally_tx_witness_stack *witness,
    const unsigned char *nonce, size_t nonce_len, const unsigned char *entropy,
    size_t entropy_len, const unsigned char *issuance_amount,
    size_t issuance_amount_len, const unsigned char *inflation_keys,
    size_t inflation_keys_len, const unsigned char *issuance_amount_rangeproof,
    size_t issuance_amount_rangeproof_len,
    const unsigned char *inflation_keys_rangeproof,
    size_t inflation_keys_rangeproof_len,
    const struct wally_tx_witness_stack *pegin_witness, uint32_t flags);

WALLY_CORE_API int wally_tx_add_elements_raw_output(
    struct wally_tx *tx, const unsigned char *script, size_t script_len,
    const unsigned char *asset, size_t asset_len, const unsigned char *value,
    size_t value_len, const unsigned char *nonce, size_t nonce_len,
    const unsigned char *surjectionproof, size_t surjectionproof_len,
    const unsigned char *rangeproof, size_t rangeproof_len, uint32_t flags);

WALLY_CORE_API int wally_tx_is_elements(const struct wally_tx *tx,
                                        size_t *written);

WALLY_CORE_API int
wally_tx_confidential_value_from_satoshi(uint64_t satoshi,
                                         unsigned char *bytes_out, size_t len);

WALLY_CORE_API int
wally_tx_confidential_value_to_satoshi(const unsigned char *value,
                                       size_t value_len, uint64_t *value_out);

WALLY_CORE_API int wally_tx_get_elements_signature_hash(
    const struct wally_tx *tx, size_t index, const unsigned char *script,
    size_t script_len, const unsigned char *value, size_t value_len,
    uint32_t sighash, uint32_t flags, unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_tx_elements_issuance_generate_entropy(
    const unsigned char *txhash, size_t txhash_len, uint32_t index,
    const unsigned char *contract_hash, size_t contract_hash_len,
    unsigned char *bytes_out, size_t len);

WALLY_CORE_API int wally_tx_elements_issuance_calculate_asset(
    const unsigned char *entropy, size_t entropy_len, unsigned char *bytes_out,
    size_t len);

WALLY_CORE_API int wally_tx_elements_issuance_calculate_reissuance_token(
    const unsigned char *entropy, size_t entropy_len, uint32_t flags,
    unsigned char *bytes_out, size_t len);

#endif

#ifdef __cplusplus
}
#endif

#endif
