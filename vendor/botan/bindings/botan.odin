package botan_bindings

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog: Initial creation and testing of the bindings.

    Bindings for the Botan crypto library.
    Created for version 2.18.1, using the provided FFI header within Botan.

    The "botan_" prefix has been stripped from the identifiers to remove redundancy,
    since the package is already named botan.
*/

import "core:c"

FFI_ERROR                           :: #type c.int
FFI_SUCCESS                         :: FFI_ERROR(0)
FFI_INVALID_VERIFIER                :: FFI_ERROR(1)
FFI_ERROR_INVALID_INPUT             :: FFI_ERROR(-1)
FFI_ERROR_BAD_MAC                   :: FFI_ERROR(-2)
FFI_ERROR_INSUFFICIENT_BUFFER_SPACE :: FFI_ERROR(-10)
FFI_ERROR_EXCEPTION_THROWN          :: FFI_ERROR(-20)
FFI_ERROR_OUT_OF_MEMORY             :: FFI_ERROR(-21)
FFI_ERROR_BAD_FLAG                  :: FFI_ERROR(-30)
FFI_ERROR_NULL_POINTER              :: FFI_ERROR(-31)
FFI_ERROR_BAD_PARAMETER             :: FFI_ERROR(-32)
FFI_ERROR_KEY_NOT_SET               :: FFI_ERROR(-33)
FFI_ERROR_INVALID_KEY_LENGTH        :: FFI_ERROR(-34)
FFI_ERROR_NOT_IMPLEMENTED           :: FFI_ERROR(-40)
FFI_ERROR_INVALID_OBJECT            :: FFI_ERROR(-50)
FFI_ERROR_UNKNOWN_ERROR             :: FFI_ERROR(-100)

FFI_HEX_LOWER_CASE              :: 1

CIPHER_INIT_FLAG_MASK_DIRECTION :: 1
CIPHER_INIT_FLAG_ENCRYPT        :: 0
CIPHER_INIT_FLAG_DECRYPT        :: 1

CIPHER_UPDATE_FLAG_FINAL        :: 1 << 0

CHECK_KEY_EXPENSIVE_TESTS       :: 1

PRIVKEY_EXPORT_FLAG_DER         :: 0
PRIVKEY_EXPORT_FLAG_PEM         :: 1

PUBKEY_DER_FORMAT_SIGNATURE     :: 1

FPE_FLAG_FE1_COMPAT_MODE        :: 1

x509_cert_key_constraints :: #type c.int
NO_CONSTRAINTS            :: x509_cert_key_constraints(0)
DIGITAL_SIGNATURE         :: x509_cert_key_constraints(32768)
NON_REPUDIATION           :: x509_cert_key_constraints(16384)
KEY_ENCIPHERMENT          :: x509_cert_key_constraints(8192)
DATA_ENCIPHERMENT         :: x509_cert_key_constraints(4096)
KEY_AGREEMENT             :: x509_cert_key_constraints(2048)
KEY_CERT_SIGN             :: x509_cert_key_constraints(1024)
CRL_SIGN                  :: x509_cert_key_constraints(512)
ENCIPHER_ONLY             :: x509_cert_key_constraints(256)
DECIPHER_ONLY             :: x509_cert_key_constraints(128)

HASH_SHA1           :: "SHA1"
HASH_SHA_224        :: "SHA-224"
HASH_SHA_256        :: "SHA-256"
HASH_SHA_384        :: "SHA-384"
HASH_SHA_512        :: "SHA-512"
HASH_SHA3_224       :: "SHA-3(224)"
HASH_SHA3_256       :: "SHA-3(256)"
HASH_SHA3_384       :: "SHA-3(384)"
HASH_SHA3_512       :: "SHA-3(512)"
HASH_SHAKE_128      :: "SHAKE-128"
HASH_SHAKE_256      :: "SHAKE-256"
HASH_KECCAK_512     :: "Keccak-1600"
HASH_RIPEMD_160     :: "RIPEMD-160"
HASH_WHIRLPOOL      :: "Whirlpool"
HASH_BLAKE2B        :: "BLAKE2b"
HASH_MD4            :: "MD4"
HASH_MD5            :: "MD5"
HASH_TIGER_128      :: "Tiger(16,3)"
HASH_TIGER_160      :: "Tiger(20,3)"
HASH_TIGER_192      :: "Tiger(24,3)"
HASH_GOST           :: "GOST-34.11"
HASH_STREEBOG_256   :: "Streebog-256"
HASH_STREEBOG_512   :: "Streebog-512"
HASH_SM3            :: "SM3"
HASH_SKEIN_512_256  :: "Skein-512(256)"
HASH_SKEIN_512_512  :: "Skein-512(512)"

// Not real values from Botan, only used for context setup within the crypto lib
HASH_SKEIN_512   :: "SKEIN_512"

MAC_HMAC_SHA1    :: "HMAC(SHA1)"
MAC_HMAC_SHA_224 :: "HMAC(SHA-224)"
MAC_HMAC_SHA_256 :: "HMAC(SHA-256)"
MAC_HMAC_SHA_384 :: "HMAC(SHA-384)"
MAC_HMAC_SHA_512 :: "HMAC(SHA-512)"
MAC_HMAC_MD5     :: "HMAC(MD5)"

MAC_SIPHASH_1_3  :: "SipHash(1,3)"
MAC_SIPHASH_2_4  :: "SipHash(2,4)"
MAC_SIPHASH_4_8  :: "SipHash(4,8)"

hash_struct          :: struct{}
hash_t               :: ^hash_struct
rng_struct           :: struct{}
rng_t                :: ^rng_struct
mac_struct           :: struct{}
mac_t                :: ^mac_struct
cipher_struct        :: struct{}
cipher_t             :: ^cipher_struct
block_cipher_struct  :: struct{}
block_cipher_t       :: ^block_cipher_struct
mp_struct            :: struct{}
mp_t                 :: ^mp_struct
privkey_struct       :: struct{}
privkey_t            :: ^privkey_struct
pubkey_struct        :: struct{}
pubkey_t             :: ^pubkey_struct
pk_op_encrypt_struct :: struct{}
pk_op_encrypt_t      :: ^pk_op_encrypt_struct
pk_op_decrypt_struct :: struct{}
pk_op_decrypt_t      :: ^pk_op_decrypt_struct
pk_op_sign_struct    :: struct{}
pk_op_sign_t         :: ^pk_op_sign_struct
pk_op_verify_struct  :: struct{}
pk_op_verify_t       :: ^pk_op_verify_struct
pk_op_ka_struct      :: struct{}
pk_op_ka_t           :: ^pk_op_ka_struct
x509_cert_struct     :: struct{}
x509_cert_t          :: ^x509_cert_struct
x509_crl_struct      :: struct{}
x509_crl_t           :: ^x509_crl_struct
hotp_struct          :: struct{}
hotp_t               :: ^hotp_struct
totp_struct          :: struct{}
totp_t               :: ^totp_struct
fpe_struct           :: struct{}
fpe_t                :: ^fpe_struct

when ODIN_OS == .Windows {
    foreign import botan_lib "botan.lib"
} else when ODIN_OS == .Linux {
    foreign import botan_lib "system:botan-2"
} else when ODIN_OS == .Darwin {
    foreign import botan_lib "system:botan-2"
}

@(default_calling_convention="c")
@(link_prefix="botan_")
foreign botan_lib {
    error_description                   :: proc(err: c.int) -> cstring ---
    ffi_api_version                     :: proc() -> c.int ---
    ffi_supports_api                    :: proc(api_version: c.int) -> c.int ---
    version_string                      :: proc() -> cstring ---
    version_major                       :: proc() -> c.int ---
    version_minor                       :: proc() -> c.int ---
    version_patch                       :: proc() -> c.int ---
    version_datestamp                   :: proc() -> c.int ---

    constant_time_compare               :: proc(x, y: ^c.char, length: c.size_t) -> c.int ---
    same_mem                            :: proc(x, y: ^c.char, length: c.size_t) -> c.int ---
    scrub_mem                           :: proc(mem: rawptr, bytes: c.size_t) -> c.int ---

    hex_encode                          :: proc(x: ^c.char, length: c.size_t, out: ^c.char, flags: c.uint) -> c.int ---
    hex_decode                          :: proc(hex_str: cstring, in_len: c.size_t, out: ^c.char, out_len: c.size_t) -> c.int ---

    base64_encode                       :: proc(x: ^c.char, length: c.size_t, out: ^c.char, out_len: c.size_t) -> c.int ---
    base64_decode                       :: proc(base64_str: cstring, in_len: c.size_t, out: ^c.char, out_len: c.size_t) -> c.int ---

    rng_init                            :: proc(rng: ^rng_t, rng_type: cstring) -> c.int ---
    rng_init_custom                     :: proc(rng_out: ^rng_t, rng_name: cstring, ctx: rawptr, 
                                                get_cb:         proc(ctx: rawptr, out: ^c.char, out_len: c.size_t) -> ^c.int,
                                                add_entropy_cb: proc(ctx: rawptr, input: ^c.char, length: c.size_t) -> ^c.int,
                                                destroy_cb:     proc(ctx: rawptr) -> rawptr) -> c.int ---
    rng_get                             :: proc(rng: rng_t, out: ^c.char, out_len: c.size_t) -> c.int ---
    rng_reseed                          :: proc(rng: rng_t, bits: c.size_t) -> c.int ---
    rng_reseed_from_rng                 :: proc(rng, source_rng: rng_t, bits: c.size_t) -> c.int ---
    rng_add_entropy                     :: proc(rng: rng_t, entropy: ^c.char, entropy_len: c.size_t) -> c.int ---
    rng_destroy                         :: proc(rng: rng_t) -> c.int ---

    hash_init                           :: proc(hash: ^hash_t, hash_name: cstring, flags: c.uint) -> c.int ---
    hash_copy_state                     :: proc(dest: ^hash_t, source: hash_t) -> c.int ---
    hash_output_length                  :: proc(hash: hash_t, output_length: ^c.size_t) -> c.int ---
    hash_block_size                     :: proc(hash: hash_t, block_size: ^c.size_t) -> c.int ---
    hash_update                         :: proc(hash: hash_t, input: ^c.char, input_len: c.size_t) -> c.int ---
    hash_final                          :: proc(hash: hash_t, out: ^c.char) -> c.int ---
    hash_clear                          :: proc(hash: hash_t) -> c.int ---
    hash_destroy                        :: proc(hash: hash_t) -> c.int ---
    hash_name                           :: proc(hash: hash_t, name: ^c.char, name_len: ^c.size_t) -> c.int ---

    mac_init                            :: proc(mac: ^mac_t, hash_name: cstring, flags: c.uint) -> c.int ---
    mac_output_length                   :: proc(mac: mac_t, output_length: ^c.size_t) -> c.int ---
    mac_set_key                         :: proc(mac: mac_t, key: ^c.char, key_len: c.size_t) -> c.int ---
    mac_update                          :: proc(mac: mac_t, buf: ^c.char, length: c.size_t) -> c.int ---
    mac_final                           :: proc(mac: mac_t, out: ^c.char) -> c.int ---
    mac_clear                           :: proc(mac: mac_t) -> c.int ---
    mac_name                            :: proc(mac: mac_t, name: ^c.char, name_len: ^c.size_t) -> c.int ---
    mac_get_keyspec                     :: proc(mac: mac_t, out_minimum_keylength, out_maximum_keylength, out_keylength_modulo: ^c.size_t) -> c.int ---
    mac_destroy                         :: proc(mac: mac_t) -> c.int ---

    cipher_init                         :: proc(cipher: ^cipher_t, name: cstring, flags: c.uint) -> c.int ---
    cipher_name                         :: proc(cipher: cipher_t, name: ^c.char, name_len: ^c.size_t) -> c.int ---
    cipher_output_length                :: proc(cipher: cipher_t, output_length: ^c.size_t) -> c.int ---
    cipher_valid_nonce_length           :: proc(cipher: cipher_t, nl: c.size_t) -> c.int ---
    cipher_get_tag_length               :: proc(cipher: cipher_t, tag_size: ^c.size_t) -> c.int ---
    cipher_get_default_nonce_length     :: proc(cipher: cipher_t, nl: ^c.size_t) -> c.int ---
    cipher_get_update_granularity       :: proc(cipher: cipher_t, ug: ^c.size_t) -> c.int ---
    cipher_query_keylen                 :: proc(cipher: cipher_t, out_minimum_keylength, out_maximum_keylength: ^c.size_t) -> c.int ---
    cipher_get_keyspec                  :: proc(cipher: cipher_t, min_keylen, max_keylen, mod_keylen: ^c.size_t) -> c.int ---
    cipher_set_key                      :: proc(cipher: cipher_t, key: ^c.char, key_len: c.size_t) -> c.int ---
    cipher_reset                        :: proc(cipher: cipher_t) -> c.int ---
    cipher_set_associated_data          :: proc(cipher: cipher_t, ad: ^c.char, ad_len: c.size_t) -> c.int ---
    cipher_start                        :: proc(cipher: cipher_t, nonce: ^c.char, nonce_len: c.size_t) -> c.int ---
    cipher_update                       :: proc(cipher: cipher_t, flags: c.uint, output: ^c.char, output_size: c.size_t, output_written: ^c.size_t, 
                                                input_bytes: ^c.char, input_size: c.size_t, input_consumed: ^c.size_t) -> c.int ---
    cipher_clear                        :: proc(hash: cipher_t) -> c.int ---
    cipher_destroy                      :: proc(cipher: cipher_t) -> c.int ---

    @(deprecated="Use botan.pwdhash")
    pbkdf                               :: proc(pbkdf_algo: cstring, out: ^c.char, out_len: c.size_t, passphrase: cstring, salt: ^c.char,
                                                salt_len, iterations: c.size_t) -> c.int ---
    @(deprecated="Use botan.pwdhash_timed")
    pbkdf_timed                         :: proc(pbkdf_algo: cstring, out: ^c.char, out_len: c.size_t, passphrase: cstring, salt: ^c.char,
                                                salt_len, milliseconds_to_run: c.size_t, out_iterations_used: ^c.size_t) -> c.int ---
    pwdhash                             :: proc(algo: cstring, param1, param2, param3: c.size_t, out: ^c.char, out_len: c.size_t, passphrase: cstring,
                                                passphrase_len: c.size_t, salt: ^c.char, salt_len: c.size_t) -> c.int ---
    pwdhash_timed                       :: proc(algo: cstring, msec: c.uint, param1, param2, param3: c.size_t, out: ^c.char, out_len: c.size_t,
                                                passphrase: cstring, passphrase_len: c.size_t, salt: ^c.char, salt_len: c.size_t) -> c.int ---
    @(deprecated="Use botan.pwdhash")
    scrypt                              :: proc(out: ^c.char, out_len: c.size_t, passphrase: cstring, salt: ^c.char, salt_len, N, r, p: c.size_t) -> c.int ---
    kdf                                 :: proc(kdf_algo: cstring, out: ^c.char, out_len: c.size_t, secret: ^c.char, secret_lent: c.size_t, salt: ^c.char,
                                                salt_len: c.size_t, label: ^c.char, label_len: c.size_t) -> c.int ---

    block_cipher_init                   :: proc(bc: ^block_cipher_t, name: cstring) -> c.int ---
    block_cipher_destroy                :: proc(bc: block_cipher_t) -> c.int ---
    block_cipher_clear                  :: proc(bc: block_cipher_t) -> c.int ---
    block_cipher_set_key                :: proc(bc: block_cipher_t, key: ^c.char, key_len: c.size_t) -> c.int ---
    block_cipher_block_size             :: proc(bc: block_cipher_t) -> c.int ---
    block_cipher_encrypt_blocks         :: proc(bc: block_cipher_t, input, out: ^c.char, blocks: c.size_t) -> c.int ---
    block_cipher_decrypt_blocks         :: proc(bc: block_cipher_t, input, out: ^c.char, blocks: c.size_t) -> c.int ---
    block_cipher_name                   :: proc(bc: block_cipher_t, name: ^c.char, name_len: ^c.size_t) -> c.int ---
    block_cipher_get_keyspec            :: proc(bc: block_cipher_t, out_minimum_keylength, out_maximum_keylength, out_keylength_modulo: ^c.size_t) -> c.int ---
    
    mp_init                             :: proc(mp: ^mp_t) -> c.int ---
    mp_destroy                          :: proc(mp: mp_t) -> c.int ---
    mp_to_hex                           :: proc(mp: mp_t, out: ^c.char) -> c.int ---
    mp_to_str                           :: proc(mp: mp_t, base: c.char, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    mp_clear                            :: proc(mp: mp_t) -> c.int ---
    mp_set_from_int                     :: proc(mp: mp_t, initial_value: c.int) -> c.int ---
    mp_set_from_mp                      :: proc(dest, source: mp_t) -> c.int ---
    mp_set_from_str                     :: proc(dest: mp_t, str: cstring) -> c.int ---
    mp_set_from_radix_str               :: proc(mp: mp_t, str: cstring, radix: c.size_t) -> c.int ---
    mp_num_bits                         :: proc(n: mp_t, bits: ^c.size_t) -> c.int ---
    mp_num_bytes                        :: proc(n: mp_t, bytes: ^c.size_t) -> c.int ---
    mp_to_bin                           :: proc(mp: mp_t, vec: ^c.char) -> c.int ---
    mp_from_bin                         :: proc(mp: mp_t, vec: ^c.char, vec_len: c.size_t) -> c.int ---
    mp_to_uint32                        :: proc(mp: mp_t, val: ^c.uint) -> c.int ---
    mp_is_positive                      :: proc(mp: mp_t) -> c.int ---
    mp_is_negative                      :: proc(mp: mp_t) -> c.int ---
    mp_flip_sign                        :: proc(mp: mp_t) -> c.int ---
    mp_is_zero                          :: proc(mp: mp_t) -> c.int ---
    @(deprecated="Use botan.mp_get_bit(0)")
    mp_is_odd                           :: proc(mp: mp_t) -> c.int ---
    @(deprecated="Use botan.mp_get_bit(0)")
    mp_is_even                          :: proc(mp: mp_t) -> c.int ---
    mp_add_u32                          :: proc(result, x: mp_t, y: c.uint) -> c.int ---
    mp_sub_u32                          :: proc(result, x: mp_t, y: c.uint) -> c.int ---
    mp_add                              :: proc(result, x, y: mp_t) -> c.int ---
    mp_sub                              :: proc(result, x, y: mp_t) -> c.int ---
    mp_mul                              :: proc(result, x, y: mp_t) -> c.int ---
    mp_div                              :: proc(quotient, remainder, x, y: mp_t) -> c.int ---
    mp_mod_mul                          :: proc(result, x, y, mod: mp_t) -> c.int ---
    mp_equal                            :: proc(x, y: mp_t) -> c.int ---
    mp_cmp                              :: proc(result: ^c.int, x, y: mp_t) -> c.int ---
    mp_swap                             :: proc(x, y: mp_t) -> c.int ---
    mp_powmod                           :: proc(out, base, exponent, modulus: mp_t) -> c.int ---
    mp_lshift                           :: proc(out, input: mp_t, shift: c.size_t) -> c.int ---
    mp_rshift                           :: proc(out, input: mp_t, shift: c.size_t) -> c.int ---
    mp_mod_inverse                      :: proc(out, input, modulus: mp_t) -> c.int ---
    mp_rand_bits                        :: proc(rand_out: mp_t, rng: rng_t, bits: c.size_t) -> c.int ---
    mp_rand_range                       :: proc(rand_out: mp_t, rng: rng_t, lower_bound, upper_bound: mp_t) -> c.int ---
    mp_gcd                              :: proc(out, x, y: mp_t) -> c.int ---
    mp_is_prime                         :: proc(n: mp_t, rng: rng_t, test_prob: c.size_t) -> c.int ---
    mp_get_bit                          :: proc(n: mp_t, bit: c.size_t) -> c.int ---
    mp_set_bit                          :: proc(n: mp_t, bit: c.size_t) -> c.int ---
    mp_clear_bit                        :: proc(n: mp_t, bit: c.size_t) -> c.int ---

    bcrypt_generate                     :: proc(out: ^c.char, out_len: ^c.size_t, password: cstring, rng: rng_t, work_factor: c.size_t, flags: c.uint) -> c.int --- 
    bcrypt_is_valid                     :: proc(pass, hash: cstring) -> c.int ---

    privkey_create                      :: proc(key: ^privkey_t, algo_name, algo_params: cstring, rng: rng_t) -> c.int ---
    @(deprecated="Use botan.privkey_create")
    privkey_check_key                   :: proc(key: privkey_t, rng: rng_t, flags: c.uint) -> c.int ---
    @(deprecated="Use botan.privkey_create")
    privkey_create_rsa                  :: proc(key: ^privkey_t, rng: rng_t, bits: c.size_t) -> c.int ---
    @(deprecated="Use botan.privkey_create")
    privkey_create_ecdsa                :: proc(key: ^privkey_t, rng: rng_t, params: cstring) -> c.int ---
    @(deprecated="Use botan.privkey_create")
    privkey_create_ecdh                 :: proc(key: ^privkey_t, rng: rng_t, params: cstring) -> c.int ---
    @(deprecated="Use botan.privkey_create")
    privkey_create_mceliece             :: proc(key: ^privkey_t, rng: rng_t, n, t: c.size_t) -> c.int ---
    @(deprecated="Use botan.privkey_create")
    privkey_create_dh                   :: proc(key: ^privkey_t, rng: rng_t, param: cstring) -> c.int ---
    privkey_create_dsa                  :: proc(key: ^privkey_t, rng: rng_t, pbits, qbits: c.size_t) -> c.int ---
    privkey_create_elgamal              :: proc(key: ^privkey_t, rng: rng_t, pbits, qbits: c.size_t) -> c.int ---
    privkey_load                        :: proc(key: ^privkey_t, rng: rng_t, bits: ^c.char, length: c.size_t, password: cstring) -> c.int ---
    privkey_destroy                     :: proc(key: privkey_t) -> c.int ---
    privkey_export                      :: proc(key: privkey_t, out: ^c.char, out_len: ^c.size_t, flags: c.uint) -> c.int ---
    privkey_algo_name                   :: proc(key: privkey_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    @(deprecated="Use botan.privkey_export_encrypted_pbkdf_{msec,iter}")
    privkey_export_encrypted            :: proc(key: privkey_t, out: ^c.char, out_len: ^c.size_t, rng: rng_t, passphrase, encryption_algo: cstring, flags: c.uint) -> c.int ---
    privkey_export_encrypted_pbkdf_msec :: proc(key: privkey_t, out: ^c.char, out_len: ^c.size_t, rng: rng_t, passphrase: cstring, pbkdf_msec_runtime: c.uint,
                                                pbkdf_iterations_out: ^c.size_t, cipher_algo, pbkdf_algo: cstring, flags: c.uint) -> c.int ---
    privkey_export_encrypted_pbkdf_iter :: proc(key: privkey_t, out: ^c.char, out_len: ^c.size_t, rng: rng_t, passphrase: cstring, pbkdf_iterations: c.size_t,
                                                cipher_algo, pbkdf_algo: cstring, flags: c.uint) -> c.int ---
    pubkey_load                         :: proc(key: ^pubkey_t, bits: ^c.char, length: c.size_t) -> c.int ---
    privkey_export_pubkey               :: proc(out: ^pubkey_t, input: privkey_t) -> c.int ---
    pubkey_export                       :: proc(key: pubkey_t, out: ^c.char, out_len: ^c.size_t, flags: c.uint) -> c.int ---
    pubkey_algo_name                    :: proc(key: pubkey_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    pubkey_check_key                    :: proc(key: pubkey_t, rng: rng_t, flags: c.uint) -> c.int ---
    pubkey_estimated_strength           :: proc(key: pubkey_t, estimate: ^c.size_t) -> c.int ---
    pubkey_fingerprint                  :: proc(key: pubkey_t, hash: cstring, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    pubkey_destroy                      :: proc(key: pubkey_t) -> c.int ---
    pubkey_get_field                    :: proc(output: mp_t, key: pubkey_t, field_name: cstring) -> c.int ---
    privkey_get_field                   :: proc(output: mp_t, key: privkey_t, field_name: cstring) -> c.int ---

    privkey_load_rsa                    :: proc(key: ^privkey_t, p, q, e: mp_t) -> c.int ---
    privkey_load_rsa_pkcs1              :: proc(key: ^privkey_t, bits: ^c.char, length: c.size_t) -> c.int ---
    @(deprecated="Use botan.privkey_get_field")
    privkey_rsa_get_p                   :: proc(p: mp_t, rsa_key: privkey_t) -> c.int ---
    @(deprecated="Use botan.privkey_get_field")
    privkey_rsa_get_q                   :: proc(q: mp_t, rsa_key: privkey_t) -> c.int ---
    @(deprecated="Use botan.privkey_get_field")
    privkey_rsa_get_d                   :: proc(d: mp_t, rsa_key: privkey_t) -> c.int ---
    @(deprecated="Use botan.privkey_get_field")
    privkey_rsa_get_n                   :: proc(n: mp_t, rsa_key: privkey_t) -> c.int ---
    @(deprecated="Use botan.privkey_get_field")
    privkey_rsa_get_e                   :: proc(e: mp_t, rsa_key: privkey_t) -> c.int ---
    privkey_rsa_get_privkey             :: proc(rsa_key: privkey_t, out: ^c.char, out_len: ^c.size_t, flags: c.uint) -> c.int ---
    pubkey_load_rsa                     :: proc(key: ^pubkey_t, n, e: mp_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    pubkey_rsa_get_e                    :: proc(e: mp_t, rsa_key: pubkey_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    pubkey_rsa_get_n                    :: proc(n: mp_t, rsa_key: pubkey_t) -> c.int ---

    privkey_load_dsa                    :: proc(key: ^privkey_t, p, q, g, x: mp_t) -> c.int ---
    pubkey_load_dsa                     :: proc(key: ^pubkey_t, p, q, g, y: mp_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    privkey_dsa_get_x                   :: proc(n: mp_t, key: privkey_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    pubkey_dsa_get_p                    :: proc(p: mp_t, key: pubkey_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    pubkey_dsa_get_q                    :: proc(q: mp_t, key: pubkey_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    pubkey_dsa_get_g                    :: proc(d: mp_t, key: pubkey_t) -> c.int ---
    @(deprecated="Use botan.pubkey_get_field")
    pubkey_dsa_get_y                    :: proc(y: mp_t, key: pubkey_t) -> c.int ---

    privkey_load_dh                     :: proc(key: ^privkey_t, p, g, y: mp_t) -> c.int ---
    pubkey_load_dh                      :: proc(key: ^pubkey_t, p, g, x: mp_t) -> c.int ---

    privkey_load_elgamal                :: proc(key: ^privkey_t, p, g, y: mp_t) -> c.int ---
    pubkey_load_elgamal                 :: proc(key: ^pubkey_t, p, g, x: mp_t) -> c.int ---

    privkey_load_ed25519                :: proc(key: ^privkey_t, privkey: [32]c.char) -> c.int ---
    pubkey_load_ed25519                 :: proc(key: ^pubkey_t, pubkey: [32]c.char) -> c.int ---
    privkey_ed25519_get_privkey         :: proc(key: ^privkey_t, output: [64]c.char) -> c.int ---
    pubkey_ed25519_get_pubkey           :: proc(key: ^pubkey_t, pubkey: [32]c.char) -> c.int ---

    privkey_load_x25519                 :: proc(key: ^privkey_t, privkey: [32]c.char) -> c.int ---
    pubkey_load_x25519                  :: proc(key: ^pubkey_t, pubkey: [32]c.char) -> c.int ---
    privkey_x25519_get_privkey          :: proc(key: ^privkey_t, output: [32]c.char) -> c.int ---
    pubkey_x25519_get_pubkey            :: proc(key: ^pubkey_t, pubkey: [32]c.char) -> c.int ---

    privkey_load_ecdsa                  :: proc(key: ^privkey_t, scalar: mp_t, curve_name: cstring) -> c.int ---
    pubkey_load_ecdsa                   :: proc(key: ^pubkey_t, public_x, public_y: mp_t, curve_name: cstring) -> c.int ---
    pubkey_load_ecdh                    :: proc(key: ^pubkey_t, public_x, public_y: mp_t, curve_name: cstring) -> c.int ---
    privkey_load_ecdh                   :: proc(key: ^privkey_t, scalar: mp_t, curve_name: cstring) -> c.int ---
    pubkey_load_sm2                     :: proc(key: ^pubkey_t, public_x, public_y: mp_t, curve_name: cstring) -> c.int ---
    privkey_load_sm2                    :: proc(key: ^privkey_t, scalar: mp_t, curve_name: cstring) -> c.int ---
    @(deprecated="Use botan.pubkey_load_sm2")
    pubkey_load_sm2_enc                 :: proc(key: ^pubkey_t, public_x, public_y: mp_t, curve_name: cstring) -> c.int ---
    @(deprecated="Use botan.privkey_load_sm2")
    privkey_load_sm2_enc                :: proc(key: ^privkey_t, scalar: mp_t, curve_name: cstring) -> c.int ---
    pubkey_sm2_compute_za               :: proc(out: ^c.char, out_len: ^c.size_t, ident, hash_algo: cstring, key: pubkey_t) -> c.int ---

    pk_op_encrypt_create                :: proc(op: ^pk_op_encrypt_t, key: pubkey_t, padding: cstring, flags: c.uint) -> c.int ---
    pk_op_encrypt_destroy               :: proc(op: pk_op_encrypt_t) -> c.int ---
    pk_op_encrypt_output_length         :: proc(op: pk_op_encrypt_t, ptext_len: c.size_t, ctext_len: ^c.size_t) -> c.int ---
    pk_op_encrypt                       :: proc(op: pk_op_encrypt_t, rng: rng_t, out: ^c.char, out_len: ^c.size_t, plaintext: cstring, plaintext_len: c.size_t) -> c.int ---

    pk_op_decrypt_create                :: proc(op: ^pk_op_decrypt_t, key: privkey_t, padding: cstring, flags: c.uint) -> c.int ---
    pk_op_decrypt_destroy               :: proc(op: pk_op_decrypt_t) -> c.int ---
    pk_op_decrypt_output_length         :: proc(op: pk_op_decrypt_t, ptext_len: c.size_t, ctext_len: ^c.size_t) -> c.int ---
    pk_op_decrypt                       :: proc(op: pk_op_decrypt_t, rng: rng_t, out: ^c.char, out_len: ^c.size_t, ciphertext: cstring, ciphertext_len: c.size_t) -> c.int ---

    pk_op_sign_create                   :: proc(op: ^pk_op_sign_t, key: privkey_t, hash_and_padding: cstring, flags: c.uint) -> c.int ---
    pk_op_sign_destroy                  :: proc(op: pk_op_sign_t) -> c.int ---
    pk_op_sign_output_length            :: proc(op: pk_op_sign_t, olen: ^c.size_t) -> c.int ---
    pk_op_sign_update                   :: proc(op: pk_op_sign_t, input: ^c.char, input_len: c.size_t) -> c.int ---
    pk_op_sign_finish                   :: proc(op: pk_op_sign_t, rng: rng_t, sig: ^c.char, sig_len: ^c.size_t) -> c.int ---

    pk_op_verify_create                 :: proc(op: ^pk_op_verify_t, hash_and_padding: cstring, flags: c.uint) -> c.int ---
    pk_op_verify_destroy                :: proc(op: pk_op_verify_t) -> c.int ---
    pk_op_verify_update                 :: proc(op: pk_op_verify_t, input: ^c.char, input_len: c.size_t) -> c.int ---
    pk_op_verify_finish                 :: proc(op: pk_op_verify_t, sig: ^c.char, sig_len: c.size_t) -> c.int ---

    pk_op_key_agreement_create          :: proc(op: ^pk_op_ka_t, kdf: cstring, flags: c.uint) -> c.int ---
    pk_op_key_agreement_destroy         :: proc(op: pk_op_ka_t) -> c.int ---
    pk_op_key_agreement_export_public   :: proc(key: privkey_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    pk_op_key_agreement_size            :: proc(op: pk_op_ka_t, out_len: ^c.size_t) -> c.int ---
    pk_op_key_agreement                 :: proc(op: pk_op_ka_t, out: ^c.char, out_len: ^c.size_t, other_key: ^c.char, other_key_len: c.size_t, salt: ^c.char,
                                                salt_len: c.size_t) -> c.int ---

    pkcs_hash_id                        :: proc(hash_name: cstring, pkcs_id: ^c.char, pkcs_id_len: ^c.size_t) -> c.int ---

    @(deprecated="Poorly specified, avoid in new code")
    mceies_encrypt                      :: proc(mce_key: pubkey_t, rng: rng_t, aead: cstring, pt: ^c.char, pt_len: c.size_t, ad: ^c.char, ad_len: c.size_t,
                                                ct: ^c.char, ct_len: ^c.size_t) -> c.int ---
    @(deprecated="Poorly specified, avoid in new code")
    mceies_decrypt                      :: proc(mce_key: privkey_t, aead: cstring, ct: ^c.char, ct_len: c.size_t, ad: ^c.char, ad_len: c.size_t, pt: ^c.char,
                                                pt_len: ^c.size_t) -> c.int ---

    x509_cert_load                      :: proc(cert_obj: ^x509_cert_t, cert: ^c.char, cert_len: c.size_t) -> c.int ---
    x509_cert_load_file                 :: proc(cert_obj: ^x509_cert_t, filename: cstring) -> c.int ---
    x509_cert_destroy                   :: proc(cert: x509_cert_t) -> c.int ---
    x509_cert_dup                       :: proc(new_cert: ^x509_cert_t, cert: x509_cert_t) -> c.int ---
    x509_cert_get_time_starts           :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_time_expires          :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_not_before                :: proc(cert: x509_cert_t, time_since_epoch: ^c.ulonglong) -> c.int ---
    x509_cert_not_after                 :: proc(cert: x509_cert_t, time_since_epoch: ^c.ulonglong) -> c.int ---
    x509_cert_get_fingerprint           :: proc(cert: x509_cert_t, hash: cstring, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_serial_number         :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_authority_key_id      :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_subject_key_id        :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_public_key_bits       :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_public_key            :: proc(cert: x509_cert_t, key: ^pubkey_t) -> c.int ---
    x509_cert_get_issuer_dn             :: proc(cert: x509_cert_t, key: ^c.char, index: c.size_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_get_subject_dn            :: proc(cert: x509_cert_t, key: ^c.char, index: c.size_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_to_string                 :: proc(cert: x509_cert_t, out: ^c.char, out_len: ^c.size_t) -> c.int ---
    x509_cert_allowed_usage             :: proc(cert: x509_cert_t, key_usage: c.uint) -> c.int ---
    x509_cert_hostname_match            :: proc(cert: x509_cert_t, hostname: cstring) -> c.int ---
    x509_cert_verify                    :: proc(validation_result: ^c.int, cert: x509_cert_t, intermediates: ^x509_cert_t, intermediates_len: c.size_t, trusted: ^x509_cert_t,
                                                trusted_len: c.size_t, trusted_path: cstring, required_strength: c.size_t, hostname: cstring, reference_time: c.ulonglong) -> c.int ---
    x509_cert_validation_status         :: proc(code: c.int) -> cstring ---
    x509_crl_load_file                  :: proc(crl_obj: ^x509_crl_t, crl_path: cstring) -> c.int ---
    x509_crl_load                       :: proc(crl_obj: ^x509_crl_t, crl_bits: ^c.char, crl_bits_len: c.size_t) -> c.int ---
    x509_crl_destroy                    :: proc(crl: x509_crl_t) -> c.int ---
    x509_is_revoked                     :: proc(crl: x509_crl_t, cert: x509_cert_t) -> c.int ---
    x509_cert_verify_with_crl           :: proc(validation_result: ^c.int, cert: x509_cert_t, intermediates: ^x509_cert_t, intermediates_len: c.size_t, trusted: ^x509_cert_t,
                                                trusted_len: c.size_t, crls: ^x509_crl_t, crls_len: c.size_t, trusted_path: cstring, required_strength: c.size_t, 
                                                hostname: cstring, reference_time: c.ulonglong) -> c.int ---

    key_wrap3394                        :: proc(key: ^c.char, key_len: c.size_t, kek: ^c.char, kek_len: c.size_t, wrapped_key: ^c.char, wrapped_key_len: ^c.size_t) -> c.int ---
    key_unwrap3394                      :: proc(wrapped_key: ^c.char, wrapped_key_len: c.size_t, kek: ^c.char, kek_len: c.size_t, key: ^c.char, key_len: ^c.size_t) -> c.int ---

    hotp_init                           :: proc(hotp: ^hotp_t, key: ^c.char, key_len: c.size_t, hash_algo: cstring, digits: c.size_t) -> c.int ---
    hotp_destroy                        :: proc(hotp: hotp_t) -> c.int ---
    hotp_generate                       :: proc(hotp: hotp_t, hotp_code: ^c.uint, hotp_counter: c.ulonglong) -> c.int ---
    hotp_check                          :: proc(hotp: hotp_t, next_hotp_counter: ^c.ulonglong, hotp_code: c.uint, hotp_counter: c.ulonglong, resync_range: c.size_t) -> c.int ---

    totp_init                           :: proc(totp: ^totp_t, key: ^c.char, key_len: c.size_t, hash_algo: cstring, digits, time_step: c.size_t) -> c.int ---
    totp_destroy                        :: proc(totp: totp_t) -> c.int ---
    totp_generate                       :: proc(totp: totp_t, totp_code: ^c.uint, timestamp: c.ulonglong) -> c.int ---
    totp_check                          :: proc(totp: totp_t, totp_code: ^c.uint, timestamp: c.ulonglong, acceptable_clock_drift: c.size_t) -> c.int ---

    fpe_fe1_init                        :: proc(fpe: ^fpe_t, n: mp_t, key: ^c.char, key_len, rounds: c.size_t, flags: c.uint) -> c.int ---
    fpe_destroy                         :: proc(fpe: fpe_t) -> c.int ---
    fpe_encrypt                         :: proc(fpe: fpe_t, x: mp_t, tweak: ^c.char, tweak_len: c.size_t) -> c.int ---
    fpe_decrypt                         :: proc(fpe: fpe_t, x: mp_t, tweak: ^c.char, tweak_len: c.size_t) -> c.int ---
}