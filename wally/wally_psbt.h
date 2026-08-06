#ifndef LIBWALLY_CORE_PSBT_H
#define LIBWALLY_CORE_PSBT_H

#include "wally_core.h"
#include "wally_transaction.h"

#ifdef __cplusplus
extern "C" {
#endif

#define WALLY_PSBT_GLOBAL_UNSIGNED_TX 0x00
#define WALLY_PSBT_IN_BIP32_DERIVATION 0x06
#define WALLY_PSBT_IN_FINAL_SCRIPTSIG 0x07
#define WALLY_PSBT_IN_FINAL_SCRIPTWITNESS 0x08
#define WALLY_PSBT_IN_NON_WITNESS_UTXO 0x00
#define WALLY_PSBT_IN_PARTIAL_SIG 0x02
#define WALLY_PSBT_IN_REDEEM_SCRIPT 0x04
#define WALLY_PSBT_IN_SIGHASH_TYPE 0x03
#define WALLY_PSBT_IN_WITNESS_SCRIPT 0x05
#define WALLY_PSBT_IN_WITNESS_UTXO 0x01
#define WALLY_PSBT_OUT_BIP32_DERIVATION 0x02
#define WALLY_PSBT_OUT_REDEEM_SCRIPT 0x00
#define WALLY_PSBT_OUT_WITNESS_SCRIPT 0x01
#define WALLY_PSBT_SEPARATOR 0x00

#ifdef SWIG
struct wally_key_origin_info;
struct wally_keypath_map;
struct wally_partial_sigs_map;
struct wally_unknowns_map;
struct wally_psbt_input;
struct wally_psbt_output;
struct wally_psbt;
#else

struct wally_key_origin_info {
  unsigned char fingerprint[FINGERPRINT_LEN];
  uint32_t *path;
  size_t path_len;
};

struct wally_keypath_item {
  unsigned char pubkey[EC_PUBLIC_KEY_UNCOMPRESSED_LEN];
  struct wally_key_origin_info origin;
};

struct wally_keypath_map {
  struct wally_keypath_item *items;
  size_t num_items;
  size_t items_allocation_len;
};

struct wally_partial_sigs_item {
  unsigned char pubkey[EC_PUBLIC_KEY_UNCOMPRESSED_LEN];
  unsigned char *sig;
  size_t sig_len;
};

struct wally_partial_sigs_map {
  struct wally_partial_sigs_item *items;
  size_t num_items;
  size_t items_allocation_len;
};

struct wally_unknowns_item {
  unsigned char *key;
  size_t key_len;
  unsigned char *value;
  size_t value_len;
};

struct wally_unknowns_map {
  struct wally_unknowns_item *items;
  size_t num_items;
  size_t items_allocation_len;
};

struct wally_psbt_input {
  struct wally_tx *non_witness_utxo;
  struct wally_tx_output *witness_utxo;
  unsigned char *redeem_script;
  size_t redeem_script_len;
  unsigned char *witness_script;
  size_t witness_script_len;
  unsigned char *final_script_sig;
  size_t final_script_sig_len;
  struct wally_tx_witness_stack *final_witness;
  struct wally_keypath_map *keypaths;
  struct wally_partial_sigs_map *partial_sigs;
  struct wally_unknowns_map *unknowns;
  uint32_t sighash_type;
};

struct wally_psbt_output {
  unsigned char *redeem_script;
  size_t redeem_script_len;
  unsigned char *witness_script;
  size_t witness_script_len;
  struct wally_keypath_map *keypaths;
  struct wally_unknowns_map *unknowns;
};

struct wally_psbt {
  struct wally_tx *tx;
  struct wally_psbt_input *inputs;
  size_t num_inputs;
  size_t inputs_allocation_len;
  struct wally_psbt_output *outputs;
  size_t num_outputs;
  size_t outputs_allocation_len;
  struct wally_unknowns_map *unknowns;
};
#endif

WALLY_CORE_API int
wally_keypath_map_init_alloc(size_t alloc_len,
                             struct wally_keypath_map **output);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_keypath_map_free(struct wally_keypath_map *keypaths);
#endif

WALLY_CORE_API int
wally_add_new_keypath(struct wally_keypath_map *keypaths, unsigned char *pubkey,
                      size_t pubkey_len, unsigned char *fingerprint,
                      size_t fingerprint_len, uint32_t *path, size_t path_len);

WALLY_CORE_API int
wally_partial_sigs_map_init_alloc(size_t alloc_len,
                                  struct wally_partial_sigs_map **output);

#ifndef SWIG_PYTHON

WALLY_CORE_API int
wally_partial_sigs_map_free(struct wally_partial_sigs_map *sigs);
#endif

WALLY_CORE_API int
wally_add_new_partial_sig(struct wally_partial_sigs_map *sigs,
                          unsigned char *pubkey, size_t pubkey_len,
                          unsigned char *sig, size_t sig_len);

WALLY_CORE_API int
wally_unknowns_map_init_alloc(size_t alloc_len,
                              struct wally_unknowns_map **output);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_unknowns_map_free(struct wally_unknowns_map *unknowns);
#endif

WALLY_CORE_API int wally_add_new_unknown(struct wally_unknowns_map *unknowns,
                                         unsigned char *key, size_t key_len,
                                         unsigned char *value,
                                         size_t value_len);

WALLY_CORE_API int wally_psbt_input_init_alloc(
    struct wally_tx *non_witness_utxo, struct wally_tx_output *witness_utxo,
    unsigned char *redeem_script, size_t redeem_script_len,
    unsigned char *witness_script, size_t witness_script_len,
    unsigned char *final_script_sig, size_t final_script_sig_len,
    struct wally_tx_witness_stack *final_witness,
    struct wally_keypath_map *keypaths,
    struct wally_partial_sigs_map *partial_sigs,
    struct wally_unknowns_map *unknowns, uint32_t sighash_type,
    struct wally_psbt_input **output);

WALLY_CORE_API int
wally_psbt_input_set_non_witness_utxo(struct wally_psbt_input *input,
                                      struct wally_tx *non_witness_utxo);

WALLY_CORE_API int
wally_psbt_input_set_witness_utxo(struct wally_psbt_input *input,
                                  struct wally_tx_output *witness_utxo);

WALLY_CORE_API int
wally_psbt_input_set_redeem_script(struct wally_psbt_input *input,
                                   unsigned char *redeem_script,
                                   size_t redeem_script_len);

WALLY_CORE_API int
wally_psbt_input_set_witness_script(struct wally_psbt_input *input,
                                    unsigned char *witness_script,
                                    size_t witness_script_len);

WALLY_CORE_API int
wally_psbt_input_set_final_script_sig(struct wally_psbt_input *input,
                                      unsigned char *final_script_sig,
                                      size_t final_script_sig_len);

WALLY_CORE_API int wally_psbt_input_set_final_witness(
    struct wally_psbt_input *input,
    struct wally_tx_witness_stack *final_witness);

WALLY_CORE_API int
wally_psbt_input_set_keypaths(struct wally_psbt_input *input,
                              struct wally_keypath_map *keypaths);

WALLY_CORE_API int
wally_psbt_input_set_partial_sigs(struct wally_psbt_input *input,
                                  struct wally_partial_sigs_map *partial_sigs);

WALLY_CORE_API int
wally_psbt_input_set_unknowns(struct wally_psbt_input *input,
                              struct wally_unknowns_map *unknowns);

WALLY_CORE_API int
wally_psbt_input_set_sighash_type(struct wally_psbt_input *input,
                                  uint32_t sighash_type);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_psbt_input_free(struct wally_psbt_input *input);
#endif

WALLY_CORE_API int wally_psbt_output_init_alloc(
    unsigned char *redeem_script, size_t redeem_script_len,
    unsigned char *witness_script, size_t witness_script_len,
    struct wally_keypath_map *keypaths, struct wally_unknowns_map *unknowns,
    struct wally_psbt_output **output);

WALLY_CORE_API int
wally_psbt_output_set_redeem_script(struct wally_psbt_output *output,
                                    unsigned char *redeem_script,
                                    size_t redeem_script_len);

WALLY_CORE_API int
wally_psbt_output_set_witness_script(struct wally_psbt_output *output,
                                     unsigned char *witness_script,
                                     size_t witness_script_len);

WALLY_CORE_API int
wally_psbt_output_set_keypaths(struct wally_psbt_output *output,
                               struct wally_keypath_map *keypaths);

WALLY_CORE_API int
wally_psbt_output_set_unknowns(struct wally_psbt_output *output,
                               struct wally_unknowns_map *unknowns);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_psbt_output_free(struct wally_psbt_output *output);
#endif

WALLY_CORE_API int wally_psbt_init_alloc(size_t inputs_allocation_len,
                                         size_t outputs_allocation_len,
                                         size_t global_unknowns_allocation_len,
                                         struct wally_psbt **output);

#ifndef SWIG_PYTHON

WALLY_CORE_API int wally_psbt_free(struct wally_psbt *psbt);
#endif

WALLY_CORE_API int wally_psbt_set_global_tx(struct wally_psbt *psbt,
                                            struct wally_tx *tx);

WALLY_CORE_API int wally_psbt_from_bytes(const unsigned char *bytes,
                                         size_t bytes_len,
                                         struct wally_psbt **output);

WALLY_CORE_API int wally_psbt_get_length(const struct wally_psbt *psbt,
                                         size_t *len);

WALLY_CORE_API int wally_psbt_to_bytes(const struct wally_psbt *psbt,
                                       unsigned char *bytes_out,
                                       size_t bytes_len, size_t *bytes_written);

WALLY_CORE_API int wally_psbt_from_base64(const char *string,
                                          struct wally_psbt **output);

WALLY_CORE_API int wally_psbt_to_base64(struct wally_psbt *psbt, char **output);

WALLY_CORE_API int wally_combine_psbts(const struct wally_psbt *psbts,
                                       size_t psbts_len,
                                       struct wally_psbt **output);

WALLY_CORE_API int wally_sign_psbt(struct wally_psbt *psbt,
                                   const unsigned char *key, size_t key_len);

WALLY_CORE_API int wally_finalize_psbt(struct wally_psbt *psbt);

WALLY_CORE_API int wally_extract_psbt(struct wally_psbt *psbt,
                                      struct wally_tx **output);

#ifdef __cplusplus
}
#endif

#endif
