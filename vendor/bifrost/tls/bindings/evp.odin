// Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package bifrost_tls

import "core:c"

// Intentionally empty. Linking is handled in link.odin to avoid duplicate
// declarations across generated binding files.


@(default_calling_convention="c")
foreign lib {
	// EVP_PKEY_new creates a new, empty public-key object and returns it or NULL
	// on allocation failure.
	EVP_PKEY_new :: proc() -> ^EVP_PKEY ---

	// EVP_PKEY_free frees all data referenced by |pkey| and then frees |pkey|
	// itself.
	EVP_PKEY_free :: proc(pkey: ^EVP_PKEY) ---

	// EVP_PKEY_up_ref increments the reference count of |pkey| and returns one. It
	// does not mutate |pkey| for thread-safety purposes and may be used
	// concurrently.
	EVP_PKEY_up_ref :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_is_opaque returns one if |pkey| is opaque. Opaque keys are backed by
	// custom implementations which do not expose key material and parameters. It is
	// an error to attempt to duplicate, export, or compare an opaque key.
	EVP_PKEY_is_opaque :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_cmp compares |a| and |b| and returns one if their public keys are
	// equal and zero otherwise.
	//
	// WARNING: this differs from the traditional return value of a "cmp" function.
	EVP_PKEY_cmp :: proc(a: ^EVP_PKEY, b: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_copy_parameters sets the parameters of |to| to equal the parameters
	// of |from|. It returns one on success and zero on error.
	EVP_PKEY_copy_parameters :: proc(to: ^EVP_PKEY, from: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_missing_parameters returns one if |pkey| is missing needed
	// parameters or zero if not, or if the algorithm doesn't take parameters.
	EVP_PKEY_missing_parameters :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_cmp_parameters compares the parameters of |a| and |b|. It returns
	// one if they match and zero otherwise. In algorithms that do not use
	// parameters, this function returns one; null parameters are vacuously equal.
	//
	// WARNING: this differs from the traditional return value of a "cmp" function.
	EVP_PKEY_cmp_parameters :: proc(a: ^EVP_PKEY, b: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_size returns the maximum size, in bytes, of a signature signed by
	// |pkey|. For an RSA key, this returns the number of bytes needed to represent
	// the modulus. For an EC key, this returns the maximum size of a DER-encoded
	// ECDSA signature.
	EVP_PKEY_size :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_bits returns the "size", in bits, of |pkey|. For an RSA key, this
	// returns the bit length of the modulus. For an EC key, this returns the bit
	// length of the group order.
	EVP_PKEY_bits :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_has_public returns one if |pkey| has a public key, or zero
	// otherwise.
	EVP_PKEY_has_public :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_has_private returns one if |pkey| has a private key, or zero
	// otherwise.
	EVP_PKEY_has_private :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_id returns the type of |pkey|, which is one of the |EVP_PKEY_*|
	// values above. These type values generally correspond to the algorithm OID,
	// but not the parameters, of a SubjectPublicKeyInfo (RFC 5280) or
	// PrivateKeyInfo (RFC 5208) AlgorithmIdentifier. Algorithm parameters can be
	// inspected with algorithm-specific accessors, e.g.
	// |EVP_PKEY_get_ec_curve_nid|.
	EVP_PKEY_id :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_pkey_rsa implements RSA keys (RFC 8017), encoded as rsaEncryption (RFC
	// 3279, Section 2.3.1). The rsaEncryption encoding is confusingly named: these
	// keys are used for all RSA operations, including signing. The |EVP_PKEY_id|
	// value is |EVP_PKEY_RSA|.
	//
	// WARNING: This |EVP_PKEY_ALG| accepts all RSA key sizes supported by
	// BoringSSL. When parsing RSA keys, callers should check the size is within
	// their desired bounds with |EVP_PKEY_bits|. RSA public key operations scale
	// quadratically and RSA private key operations scale cubicly, so key sizes may
	// be a DoS vector.
	EVP_pkey_rsa :: proc() -> ^EVP_PKEY_ALG ---

	// EVP_pkey_ec_* implement EC keys, encoded as id-ecPublicKey (RFC 5480,
	// Section 2.1.1). The id-ecPublicKey encoding is confusingly named: it is also
	// used for private keys (RFC 5915). The |EVP_PKEY_id| value is |EVP_PKEY_EC|.
	//
	// Each function only supports the specified curve, but curves are not reflected
	// in |EVP_PKEY_id|. The curve can be inspected with
	// |EVP_PKEY_get_ec_curve_nid|.
	EVP_pkey_ec_p224 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_ec_p256 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_ec_p384 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_ec_p521 :: proc() -> ^EVP_PKEY_ALG ---

	// EVP_pkey_x25519 implements X25519 keys (RFC 7748), encoded as in RFC 8410.
	// The |EVP_PKEY_id| value is |EVP_PKEY_X25519|.
	EVP_pkey_x25519 :: proc() -> ^EVP_PKEY_ALG ---

	// EVP_pkey_ed25519 implements Ed25519 keys (RFC 8032), encoded as in RFC 8410.
	// The |EVP_PKEY_id| value is |EVP_PKEY_ED25519|.
	EVP_pkey_ed25519 :: proc() -> ^EVP_PKEY_ALG ---

	// EVP_pkey_ml_dsa_* implement ML-DSA keys, encoded as in
	// draft-ietf-lamps-dilithium-certificates. The |EVP_PKEY_id| values are
	// |EVP_PKEY_ML_DSA_*|. In the private key representation, only the "seed" form
	// is serialized or parsed.
	//
	// To configure OpenSSL to output the standard "seed" form, configure the
	// "ml-dsa.output_formats" provider parameter so that "seed-only" is first. This
	// can be done programmatically with OpenSSL's
	// |OSSL_PROVIDER_add_conf_parameter| function, or by passing "-provparam" to
	// the command-line tool.
	EVP_pkey_ml_dsa_44 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_ml_dsa_65 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_ml_dsa_87 :: proc() -> ^EVP_PKEY_ALG ---

	// EVP_pkey_dsa implements DSA keys, encoded as in RFC 3279, Section 2.3.2. The
	// |EVP_PKEY_id| value is |EVP_PKEY_DSA|. This |EVP_PKEY_ALG| accepts all DSA
	// parameters supported by BoringSSL.
	//
	// Keys of this type are not usable with any operations, though the underlying
	// |DSA| object can be extracted with |EVP_PKEY_get0_DSA|. This key type is
	// deprecated and only implemented for compatibility with legacy applications.
	//
	// TODO(crbug.com/42290364): We didn't wire up |EVP_PKEY_sign| and
	// |EVP_PKEY_verify| just so it was auditable which callers used DSA. Once DSA
	// is removed from the default SPKI and PKCS#8 parser and DSA users explicitly
	// request |EVP_pkey_dsa|, we could change that.
	EVP_pkey_dsa :: proc() -> ^EVP_PKEY_ALG ---

	// EVP_pkey_rsa_pss_* implements RSASSA-PSS keys, encoded as id-RSASSA-PSS
	// (RFC 4055, Section 3.1). The |EVP_PKEY_id| value is |EVP_PKEY_RSA_PSS|. Each
	// |EVP_PKEY_ALG| only accepts keys whose parameters specify:
	//
	//  - A hashAlgorithm of the specified hash
	//  - A maskGenAlgorithm of MGF1 with the specified hash
	//  - A minimum saltLength of the specified hash's digest length
	//  - A trailerField of one (must be omitted in the encoding)
	//
	// Keys of this type will only be usable with RSASSA-PSS with matching signature
	// parameters.
	//
	// This algorithm type is not recommended. The id-RSASSA-PSS key type is not
	// widely implemented. Using it negates any compatibility benefits of using RSA.
	// More modern algorithms like ECDSA are more performant and more compatible
	// than id-RSASSA-PSS keys. This key type also adds significant complexity to a
	// system. It has a wide range of possible parameter sets, so any uses must
	// ensure all components not only support id-RSASSA-PSS, but also the specific
	// parameters chosen.
	//
	// Note the id-RSASSA-PSS key type is distinct from the RSASSA-PSS signature
	// algorithm. The widely implemented id-rsaEncryption key type (|EVP_pkey_rsa|
	// and |EVP_PKEY_RSA|) also supports RSASSA-PSS signatures.
	//
	// WARNING: Any |EVP_PKEY|s produced by this algorithm will return a non-NULL
	// |RSA| object through |EVP_PKEY_get1_RSA| and |EVP_PKEY_get0_RSA|. This is
	// dangerous as existing code may assume a non-NULL return implies the more
	// common id-rsaEncryption key. Additionally, the operations on the underlying
	// |RSA| object will not capture the RSA-PSS constraints, so callers risk
	// misusing the key by calling these functions. Callers using this algorithm
	// must use |EVP_PKEY_id| to distinguish |EVP_PKEY_RSA| and |EVP_PKEY_RSA_PSS|.
	//
	// WARNING: BoringSSL does not currently implement |RSA_get0_pss_params| with
	// these keys. Callers that require this functionality should contact the
	// BoringSSL team.
	EVP_pkey_rsa_pss_sha256 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_rsa_pss_sha384 :: proc() -> ^EVP_PKEY_ALG ---
	EVP_pkey_rsa_pss_sha512 :: proc() -> ^EVP_PKEY_ALG ---

	// Getting and setting concrete key types.
	//
	// The following functions get and set the underlying key representation in an
	// |EVP_PKEY| object. The |set1| functions take an additional reference to the
	// underlying key and return one on success or zero if |key| is NULL. The
	// |assign| functions adopt the caller's reference and return one on success or
	// zero if |key| is NULL. The |get1| functions return a fresh reference to the
	// underlying object or NULL if |pkey| is not of the correct type. The |get0|
	// functions behave the same but return a non-owning pointer.
	//
	// The |get0| and |get1| functions take |const| pointers and are thus
	// non-mutating for thread-safety purposes, but mutating functions on the
	// returned lower-level objects are considered to also mutate the |EVP_PKEY| and
	// may not be called concurrently with other operations on the |EVP_PKEY|.
	//
	// WARNING: Matching OpenSSL, the RSA functions behave non-uniformly.
	// |EVP_PKEY_set1_RSA| and |EVP_PKEY_assign_RSA| construct an |EVP_PKEY_RSA|
	// key, while the |EVP_PKEY_get0_RSA| and |EVP_PKEY_get1_RSA| will return
	// non-NULL for both |EVP_PKEY_RSA| and |EVP_PKEY_RSA_PSS|.
	//
	// This means callers risk misusing a key if they assume a non-NULL return from
	// |EVP_PKEY_get0_RSA| or |EVP_PKEY_get1_RSA| implies |EVP_PKEY_RSA|. Prefer
	// |EVP_PKEY_id| to check the type of a key. To reduce this risk, BoringSSL does
	// not make |EVP_PKEY_RSA_PSS| available by default, only when callers opt in
	// via |EVP_pkey_rsa_pss_sha256|. This differs from upstream OpenSSL, where
	// callers are exposed to |EVP_PKEY_RSA_PSS| by default.
	EVP_PKEY_set1_RSA      :: proc(pkey: ^EVP_PKEY, key: ^RSA) -> i32 ---
	EVP_PKEY_assign_RSA    :: proc(pkey: ^EVP_PKEY, key: ^RSA) -> i32 ---
	EVP_PKEY_get0_RSA      :: proc(pkey: ^EVP_PKEY) -> ^RSA ---
	EVP_PKEY_get1_RSA      :: proc(pkey: ^EVP_PKEY) -> ^RSA ---
	EVP_PKEY_set1_DSA      :: proc(pkey: ^EVP_PKEY, key: ^DSA) -> i32 ---
	EVP_PKEY_assign_DSA    :: proc(pkey: ^EVP_PKEY, key: ^DSA) -> i32 ---
	EVP_PKEY_get0_DSA      :: proc(pkey: ^EVP_PKEY) -> ^DSA ---
	EVP_PKEY_get1_DSA      :: proc(pkey: ^EVP_PKEY) -> ^DSA ---
	EVP_PKEY_set1_EC_KEY   :: proc(pkey: ^EVP_PKEY, key: ^EC_KEY) -> i32 ---
	EVP_PKEY_assign_EC_KEY :: proc(pkey: ^EVP_PKEY, key: ^EC_KEY) -> i32 ---
	EVP_PKEY_get0_EC_KEY   :: proc(pkey: ^EVP_PKEY) -> ^EC_KEY ---
	EVP_PKEY_get1_EC_KEY   :: proc(pkey: ^EVP_PKEY) -> ^EC_KEY ---
	EVP_PKEY_set1_DH       :: proc(pkey: ^EVP_PKEY, key: ^DH) -> i32 ---
	EVP_PKEY_assign_DH     :: proc(pkey: ^EVP_PKEY, key: ^DH) -> i32 ---
	EVP_PKEY_get0_DH       :: proc(pkey: ^EVP_PKEY) -> ^DH ---
	EVP_PKEY_get1_DH       :: proc(pkey: ^EVP_PKEY) -> ^DH ---

	// EVP_PKEY_from_subject_public_key_info decodes a DER-encoded
	// SubjectPublicKeyInfo structure (RFC 5280) from |in|. It returns a
	// newly-allocated |EVP_PKEY| or NULL on error. Only the |num_algs| algorithms
	// in |algs| will be considered when parsing.
	EVP_PKEY_from_subject_public_key_info :: proc(_in: ^u8, len: c.size_t, algs: ^^EVP_PKEY_ALG, num_algs: c.size_t) -> ^EVP_PKEY ---

	// EVP_parse_public_key decodes a DER-encoded SubjectPublicKeyInfo structure
	// (RFC 5280) from |cbs| and advances |cbs|. It returns a newly-allocated
	// |EVP_PKEY| or NULL on error.
	//
	// Prefer |EVP_PKEY_from_subject_public_key_info| instead. This function has
	// several pitfalls:
	//
	// Callers are expected to handle trailing data returned from |cbs|, making more
	// common cases error-prone.
	//
	// There is also no way to pass in supported algorithms. This function instead
	// supports some default set of algorithms. Future versions of BoringSSL may add
	// to this list, based on the needs of the other callers. Conversely, some
	// algorithms may be intentionally omitted, if they cause too much risk to
	// existing callers.
	//
	// This means callers must check the type of the parsed public key to ensure it
	// is suitable and validate other desired key properties such as RSA modulus
	// size or EC curve.
	EVP_parse_public_key :: proc(cbs: ^CBS) -> ^EVP_PKEY ---

	// EVP_marshal_public_key marshals |key| as a DER-encoded SubjectPublicKeyInfo
	// structure (RFC 5280) and appends the result to |cbb|. It returns one on
	// success and zero on error.
	EVP_marshal_public_key :: proc(cbb: ^CBB, key: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_from_private_key_info decodes a DER-encoded PrivateKeyInfo structure
	// (RFC 5208) from |in|. It returns a newly-allocated |EVP_PKEY| or NULL on
	// error. Only the |num_algs| algorithms in |algs| will be considered when
	// parsing.
	//
	// A PrivateKeyInfo ends with an optional set of attributes. These are silently
	// ignored.
	EVP_PKEY_from_private_key_info :: proc(_in: ^u8, len: c.size_t, algs: ^^EVP_PKEY_ALG, num_algs: c.size_t) -> ^EVP_PKEY ---

	// EVP_parse_private_key decodes a DER-encoded PrivateKeyInfo structure (RFC
	// 5208) from |cbs| and advances |cbs|. It returns a newly-allocated |EVP_PKEY|
	// or NULL on error.
	//
	// Prefer |EVP_PKEY_from_private_key_info| instead. This function has
	// several pitfalls:
	//
	// Callers are expected to handle trailing data returned from |cbs|, making more
	// common cases error-prone.
	//
	// There is also no way to pass in supported algorithms. This function instead
	// supports some default set of algorithms. Future versions of BoringSSL may add
	// to this list, based on the needs of the other callers. Conversely, some
	// algorithms may be intentionally omitted, if they cause too much risk to
	// existing callers.
	//
	// This means the caller must check the type of the parsed private key to ensure
	// it is suitable and validate other desired key properties such as RSA modulus
	// size or EC curve. In particular, RSA private key operations scale cubicly, so
	// applications accepting RSA private keys from external sources may need to
	// bound key sizes (use |EVP_PKEY_bits| or |RSA_bits|) to avoid a DoS vector.
	//
	// A PrivateKeyInfo ends with an optional set of attributes. These are silently
	// ignored.
	EVP_parse_private_key :: proc(cbs: ^CBS) -> ^EVP_PKEY ---

	// EVP_marshal_private_key marshals |key| as a DER-encoded PrivateKeyInfo
	// structure (RFC 5208) and appends the result to |cbb|. It returns one on
	// success and zero on error.
	EVP_marshal_private_key :: proc(cbb: ^CBB, key: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_from_raw_private_key interprets |in| as a raw private key of type
	// |alg| and returns a newly-allocated |EVP_PKEY|, or nullptr on error.
	EVP_PKEY_from_raw_private_key :: proc(alg: ^EVP_PKEY_ALG, _in: ^u8, len: c.size_t) -> ^EVP_PKEY ---

	// EVP_PKEY_from_private_seed interprets |in| as a private seed of type |alg|
	// and returns a newly-allocated |EVP_PKEY|, or nullptr on error.
	EVP_PKEY_from_private_seed :: proc(alg: ^EVP_PKEY_ALG, _in: ^u8, len: c.size_t) -> ^EVP_PKEY ---

	// EVP_PKEY_from_raw_public_key interprets |in| as a raw public key of type
	// |alg| and returns a newly-allocated |EVP_PKEY|, or nullptr on error.
	EVP_PKEY_from_raw_public_key :: proc(alg: ^EVP_PKEY_ALG, _in: ^u8, len: c.size_t) -> ^EVP_PKEY ---

	// EVP_PKEY_get_raw_private_key outputs the private key for |pkey| in raw form.
	// If |out| is NULL, it sets |*out_len| to the size of the raw private key.
	// Otherwise, it writes at most |*out_len| bytes to |out| and sets |*out_len| to
	// the number of bytes written.
	//
	// It returns one on success and zero if |pkey| has no private key, the key
	// type does not support this format, or the buffer is too small.
	EVP_PKEY_get_raw_private_key :: proc(pkey: ^EVP_PKEY, out: ^u8, out_len: ^c.size_t) -> i32 ---

	// EVP_PKEY_get_private_seed outputs the private key for |pkey| as a private
	// seed. If |out| is NULL, it sets |*out_len| to the size of the seed.
	// Otherwise, it writes at most |*out_len| bytes to |out| and sets
	// |*out_len| to the number of bytes written.
	//
	// It returns one on success and zero if |pkey| has no private key, the key
	// type does not support this format, or the buffer is too small.
	EVP_PKEY_get_private_seed :: proc(pkey: ^EVP_PKEY, out: ^u8, out_len: ^c.size_t) -> i32 ---

	// EVP_PKEY_get_raw_public_key outputs the public key for |pkey| in raw form.
	// If |out| is NULL, it sets |*out_len| to the size of the raw public key.
	// Otherwise, it writes at most |*out_len| bytes to |out| and sets |*out_len| to
	// the number of bytes written.
	//
	// It returns one on success and zero if |pkey| has no public key, the key
	// type does not support this format, or the buffer is too small.
	EVP_PKEY_get_raw_public_key :: proc(pkey: ^EVP_PKEY, out: ^u8, out_len: ^c.size_t) -> i32 ---

	// EVP_DigestSignInit sets up |ctx| for a signing operation with |type| and
	// |pkey|. The |ctx| argument must have been initialised with
	// |EVP_MD_CTX_init|. If |pctx| is not NULL, the |EVP_PKEY_CTX| of the signing
	// operation will be written to |*pctx|; this can be used to set alternative
	// signing options.
	//
	// For single-shot signing algorithms which do not use a pre-hash, such as
	// Ed25519, |type| should be NULL. The |EVP_MD_CTX| itself is unused but is
	// present so the API is uniform. See |EVP_DigestSign|.
	//
	// This function does not mutate |pkey| for thread-safety purposes and may be
	// used concurrently with other non-mutating functions on |pkey|.
	//
	// It returns one on success, or zero on error.
	EVP_DigestSignInit :: proc(ctx: ^EVP_MD_CTX, pctx: ^^EVP_PKEY_CTX, type: ^EVP_MD, e: ^ENGINE, pkey: ^EVP_PKEY) -> i32 ---

	// EVP_DigestSignUpdate appends |len| bytes from |data| to the data which will
	// be signed in |EVP_DigestSignFinal|. It returns one.
	//
	// This function performs a streaming signing operation and will fail for
	// signature algorithms which do not support this. Use |EVP_DigestSign| for a
	// single-shot operation.
	EVP_DigestSignUpdate :: proc(ctx: ^EVP_MD_CTX, data: rawptr, len: c.size_t) -> i32 ---

	// EVP_DigestSignFinal signs the data that has been included by one or more
	// calls to |EVP_DigestSignUpdate|. If |out_sig| is NULL then |*out_sig_len| is
	// set to the maximum number of output bytes. Otherwise, on entry,
	// |*out_sig_len| must contain the length of the |out_sig| buffer. If the call
	// is successful, the signature is written to |out_sig| and |*out_sig_len| is
	// set to its length.
	//
	// This function performs a streaming signing operation and will fail for
	// signature algorithms which do not support this. Use |EVP_DigestSign| for a
	// single-shot operation.
	//
	// It returns one on success, or zero on error.
	EVP_DigestSignFinal :: proc(ctx: ^EVP_MD_CTX, out_sig: ^u8, out_sig_len: ^c.size_t) -> i32 ---

	// EVP_DigestSign signs |data_len| bytes from |data| using |ctx|. If |out_sig|
	// is NULL then |*out_sig_len| is set to the maximum number of output
	// bytes. Otherwise, on entry, |*out_sig_len| must contain the length of the
	// |out_sig| buffer. If the call is successful, the signature is written to
	// |out_sig| and |*out_sig_len| is set to its length.
	//
	// It returns one on success and zero on error.
	EVP_DigestSign :: proc(ctx: ^EVP_MD_CTX, out_sig: ^u8, out_sig_len: ^c.size_t, data: ^u8, data_len: c.size_t) -> i32 ---

	// EVP_DigestVerifyInit sets up |ctx| for a signature verification operation
	// with |type| and |pkey|. The |ctx| argument must have been initialised with
	// |EVP_MD_CTX_init|. If |pctx| is not NULL, the |EVP_PKEY_CTX| of the signing
	// operation will be written to |*pctx|; this can be used to set alternative
	// signing options.
	//
	// For single-shot signing algorithms which do not use a pre-hash, such as
	// Ed25519, |type| should be NULL. The |EVP_MD_CTX| itself is unused but is
	// present so the API is uniform. See |EVP_DigestVerify|.
	//
	// This function does not mutate |pkey| for thread-safety purposes and may be
	// used concurrently with other non-mutating functions on |pkey|.
	//
	// It returns one on success, or zero on error.
	EVP_DigestVerifyInit :: proc(ctx: ^EVP_MD_CTX, pctx: ^^EVP_PKEY_CTX, type: ^EVP_MD, e: ^ENGINE, pkey: ^EVP_PKEY) -> i32 ---

	// EVP_DigestVerifyUpdate appends |len| bytes from |data| to the data which
	// will be verified by |EVP_DigestVerifyFinal|. It returns one.
	//
	// This function performs streaming signature verification and will fail for
	// signature algorithms which do not support this. Use |EVP_DigestVerify| for a
	// single-shot verification.
	EVP_DigestVerifyUpdate :: proc(ctx: ^EVP_MD_CTX, data: rawptr, len: c.size_t) -> i32 ---

	// EVP_DigestVerifyFinal verifies that |sig_len| bytes of |sig| are a valid
	// signature for the data that has been included by one or more calls to
	// |EVP_DigestVerifyUpdate|. It returns one on success and zero otherwise.
	//
	// This function performs streaming signature verification and will fail for
	// signature algorithms which do not support this. Use |EVP_DigestVerify| for a
	// single-shot verification.
	EVP_DigestVerifyFinal :: proc(ctx: ^EVP_MD_CTX, sig: ^u8, sig_len: c.size_t) -> i32 ---

	// EVP_DigestVerify verifies that |sig_len| bytes from |sig| are a valid
	// signature for |data|. It returns one on success or zero on error.
	EVP_DigestVerify :: proc(ctx: ^EVP_MD_CTX, sig: ^u8, sig_len: c.size_t, data: ^u8, len: c.size_t) -> i32 ---

	// EVP_SignInit_ex configures |ctx|, which must already have been initialised,
	// for a fresh signing operation using the hash function |type|. It returns one
	// on success and zero otherwise.
	//
	// (In order to initialise |ctx|, either obtain it initialised with
	// |EVP_MD_CTX_create|, or use |EVP_MD_CTX_init|.)
	EVP_SignInit_ex :: proc(ctx: ^EVP_MD_CTX, type: ^EVP_MD, impl: ^ENGINE) -> i32 ---

	// EVP_SignInit is a deprecated version of |EVP_SignInit_ex|.
	//
	// TODO(fork): remove.
	EVP_SignInit :: proc(ctx: ^EVP_MD_CTX, type: ^EVP_MD) -> i32 ---

	// EVP_SignUpdate appends |len| bytes from |data| to the data which will be
	// signed in |EVP_SignFinal|.
	EVP_SignUpdate :: proc(ctx: ^EVP_MD_CTX, data: rawptr, len: c.size_t) -> i32 ---

	// EVP_SignFinal signs the data that has been included by one or more calls to
	// |EVP_SignUpdate|, using the key |pkey|, and writes it to |sig|. On entry,
	// |sig| must point to at least |EVP_PKEY_size(pkey)| bytes of space. The
	// actual size of the signature is written to |*out_sig_len|.
	//
	// It returns one on success and zero otherwise.
	//
	// It does not modify |ctx|, thus it's possible to continue to use |ctx| in
	// order to sign a longer message. It also does not mutate |pkey| for
	// thread-safety purposes and may be used concurrently with other non-mutating
	// functions on |pkey|.
	EVP_SignFinal :: proc(ctx: ^EVP_MD_CTX, sig: ^u8, out_sig_len: ^u32, pkey: ^EVP_PKEY) -> i32 ---

	// EVP_VerifyInit_ex configures |ctx|, which must already have been
	// initialised, for a fresh signature verification operation using the hash
	// function |type|. It returns one on success and zero otherwise.
	//
	// (In order to initialise |ctx|, either obtain it initialised with
	// |EVP_MD_CTX_create|, or use |EVP_MD_CTX_init|.)
	EVP_VerifyInit_ex :: proc(ctx: ^EVP_MD_CTX, type: ^EVP_MD, impl: ^ENGINE) -> i32 ---

	// EVP_VerifyInit is a deprecated version of |EVP_VerifyInit_ex|.
	//
	// TODO(fork): remove.
	EVP_VerifyInit :: proc(ctx: ^EVP_MD_CTX, type: ^EVP_MD) -> i32 ---

	// EVP_VerifyUpdate appends |len| bytes from |data| to the data which will be
	// signed in |EVP_VerifyFinal|.
	EVP_VerifyUpdate :: proc(ctx: ^EVP_MD_CTX, data: rawptr, len: c.size_t) -> i32 ---

	// EVP_VerifyFinal verifies that |sig_len| bytes of |sig| are a valid
	// signature, by |pkey|, for the data that has been included by one or more
	// calls to |EVP_VerifyUpdate|.
	//
	// It returns one on success and zero otherwise.
	//
	// It does not modify |ctx|, thus it's possible to continue to use |ctx| in
	// order to verify a longer message. It also does not mutate |pkey| for
	// thread-safety purposes and may be used concurrently with other non-mutating
	// functions on |pkey|.
	EVP_VerifyFinal :: proc(ctx: ^EVP_MD_CTX, sig: ^u8, sig_len: c.size_t, pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_print_public prints a textual representation of the public key in
	// |pkey| to |out|. Returns one on success or zero otherwise.
	EVP_PKEY_print_public :: proc(out: ^BIO, pkey: ^EVP_PKEY, indent: i32, pctx: ^ASN1_PCTX) -> i32 ---

	// EVP_PKEY_print_private prints a textual representation of the private key in
	// |pkey| to |out|. Returns one on success or zero otherwise.
	EVP_PKEY_print_private :: proc(out: ^BIO, pkey: ^EVP_PKEY, indent: i32, pctx: ^ASN1_PCTX) -> i32 ---

	// EVP_PKEY_print_params prints a textual representation of the parameters in
	// |pkey| to |out|. Returns one on success or zero otherwise.
	EVP_PKEY_print_params :: proc(out: ^BIO, pkey: ^EVP_PKEY, indent: i32, pctx: ^ASN1_PCTX) -> i32 ---

	// PKCS5_PBKDF2_HMAC computes |iterations| iterations of PBKDF2 of |password|
	// and |salt|, using |digest|, and outputs |key_len| bytes to |out_key|. It
	// returns one on success and zero on allocation failure or if iterations is 0.
	PKCS5_PBKDF2_HMAC :: proc(password: cstring, password_len: c.size_t, salt: ^u8, salt_len: c.size_t, iterations: u32, digest: ^EVP_MD, key_len: c.size_t, out_key: ^u8) -> i32 ---

	// PKCS5_PBKDF2_HMAC_SHA1 is the same as PKCS5_PBKDF2_HMAC, but with |digest|
	// fixed to |EVP_sha1|.
	PKCS5_PBKDF2_HMAC_SHA1 :: proc(password: cstring, password_len: c.size_t, salt: ^u8, salt_len: c.size_t, iterations: u32, key_len: c.size_t, out_key: ^u8) -> i32 ---

	// EVP_PBE_scrypt expands |password| into a secret key of length |key_len| using
	// scrypt, as described in RFC 7914, and writes the result to |out_key|. It
	// returns one on success and zero on allocation failure, if the memory required
	// for the operation exceeds |max_mem|, or if any of the parameters are invalid
	// as described below.
	//
	// |N|, |r|, and |p| are as described in RFC 7914 section 6. They determine the
	// cost of the operation. If |max_mem| is zero, a default limit of 32MiB will be
	// used.
	//
	// The parameters are considered invalid under any of the following conditions:
	// - |r| or |p| are zero
	// - |p| > (2^30 - 1) / |r|
	// - |N| is not a power of two
	// - |N| > 2^32
	// - |N| > 2^(128 * |r| / 8)
	EVP_PBE_scrypt :: proc(password: cstring, password_len: c.size_t, salt: ^u8, salt_len: c.size_t, N: u64, r: u64, p: u64, max_mem: c.size_t, out_key: ^u8, key_len: c.size_t) -> i32 ---

	// EVP_PKEY_CTX_new allocates a fresh |EVP_PKEY_CTX| for use with |pkey|. It
	// returns the context or NULL on error.
	EVP_PKEY_CTX_new :: proc(pkey: ^EVP_PKEY, e: ^ENGINE) -> ^EVP_PKEY_CTX ---

	// EVP_PKEY_CTX_new_id allocates a fresh |EVP_PKEY_CTX| for a key of type |id|
	// (e.g. |EVP_PKEY_HMAC|). This can be used for key generation where
	// |EVP_PKEY_CTX_new| can't be used because there isn't an |EVP_PKEY| to pass
	// it. It returns the context or NULL on error.
	EVP_PKEY_CTX_new_id :: proc(id: i32, e: ^ENGINE) -> ^EVP_PKEY_CTX ---

	// EVP_PKEY_CTX_free frees |ctx| and the data it owns.
	EVP_PKEY_CTX_free :: proc(ctx: ^EVP_PKEY_CTX) ---

	// EVP_PKEY_CTX_dup allocates a fresh |EVP_PKEY_CTX| and sets it equal to the
	// state of |ctx|. It returns the fresh |EVP_PKEY_CTX| or NULL on error.
	EVP_PKEY_CTX_dup :: proc(ctx: ^EVP_PKEY_CTX) -> ^EVP_PKEY_CTX ---

	// EVP_PKEY_CTX_get0_pkey returns the |EVP_PKEY| associated with |ctx|.
	EVP_PKEY_CTX_get0_pkey :: proc(ctx: ^EVP_PKEY_CTX) -> ^EVP_PKEY ---

	// EVP_PKEY_sign_init initialises an |EVP_PKEY_CTX| for a signing operation. It
	// should be called before |EVP_PKEY_sign|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_sign_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_sign signs |digest_len| bytes from |digest| using |ctx|. If |sig| is
	// NULL, the maximum size of the signature is written to |out_sig_len|.
	// Otherwise, |*sig_len| must contain the number of bytes of space available at
	// |sig|. If sufficient, the signature will be written to |sig| and |*sig_len|
	// updated with the true length. This function will fail for signature
	// algorithms like Ed25519 that do not support signing pre-hashed inputs.
	//
	// WARNING: |digest| must be the output of some hash function on the data to be
	// signed. Passing unhashed inputs will not result in a secure signature scheme.
	// Use |EVP_DigestSignInit| to sign an unhashed input.
	//
	// WARNING: Setting |sig| to NULL only gives the maximum size of the
	// signature. The actual signature may be smaller.
	//
	// It returns one on success or zero on error. (Note: this differs from
	// OpenSSL, which can also return negative values to indicate an error. )
	EVP_PKEY_sign :: proc(ctx: ^EVP_PKEY_CTX, sig: ^u8, sig_len: ^c.size_t, digest: ^u8, digest_len: c.size_t) -> i32 ---

	// EVP_PKEY_verify_init initialises an |EVP_PKEY_CTX| for a signature
	// verification operation. It should be called before |EVP_PKEY_verify|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_verify_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_verify verifies that |sig_len| bytes from |sig| are a valid
	// signature for |digest|. This function will fail for signature
	// algorithms like Ed25519 that do not support signing pre-hashed inputs.
	//
	// WARNING: |digest| must be the output of some hash function on the data to be
	// verified. Passing unhashed inputs will not result in a secure signature
	// scheme. Use |EVP_DigestVerifyInit| to verify a signature given the unhashed
	// input.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_verify :: proc(ctx: ^EVP_PKEY_CTX, sig: ^u8, sig_len: c.size_t, digest: ^u8, digest_len: c.size_t) -> i32 ---

	// EVP_PKEY_encrypt_init initialises an |EVP_PKEY_CTX| for an encryption
	// operation. It should be called before |EVP_PKEY_encrypt|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_encrypt_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_encrypt encrypts |in_len| bytes from |in|. If |out| is NULL, the
	// maximum size of the ciphertext is written to |out_len|. Otherwise, |*out_len|
	// must contain the number of bytes of space available at |out|. If sufficient,
	// the ciphertext will be written to |out| and |*out_len| updated with the true
	// length.
	//
	// WARNING: Setting |out| to NULL only gives the maximum size of the
	// ciphertext. The actual ciphertext may be smaller.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_encrypt :: proc(ctx: ^EVP_PKEY_CTX, out: ^u8, out_len: ^c.size_t, _in: ^u8, in_len: c.size_t) -> i32 ---

	// EVP_PKEY_decrypt_init initialises an |EVP_PKEY_CTX| for a decryption
	// operation. It should be called before |EVP_PKEY_decrypt|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_decrypt_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_decrypt decrypts |in_len| bytes from |in|. If |out| is NULL, the
	// maximum size of the plaintext is written to |out_len|. Otherwise, |*out_len|
	// must contain the number of bytes of space available at |out|. If sufficient,
	// the ciphertext will be written to |out| and |*out_len| updated with the true
	// length.
	//
	// WARNING: Setting |out| to NULL only gives the maximum size of the
	// plaintext. The actual plaintext may be smaller.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_decrypt :: proc(ctx: ^EVP_PKEY_CTX, out: ^u8, out_len: ^c.size_t, _in: ^u8, in_len: c.size_t) -> i32 ---

	// EVP_PKEY_verify_recover_init initialises an |EVP_PKEY_CTX| for a public-key
	// decryption operation. It should be called before |EVP_PKEY_verify_recover|.
	//
	// Public-key decryption is a very obscure operation that is only implemented
	// by RSA keys. It is effectively a signature verification operation that
	// returns the signed message directly. It is almost certainly not what you
	// want.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_verify_recover_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_verify_recover decrypts |sig_len| bytes from |sig|. If |out| is
	// NULL, the maximum size of the plaintext is written to |out_len|. Otherwise,
	// |*out_len| must contain the number of bytes of space available at |out|. If
	// sufficient, the ciphertext will be written to |out| and |*out_len| updated
	// with the true length.
	//
	// WARNING: Setting |out| to NULL only gives the maximum size of the
	// plaintext. The actual plaintext may be smaller.
	//
	// See the warning about this operation in |EVP_PKEY_verify_recover_init|. It
	// is probably not what you want.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_verify_recover :: proc(ctx: ^EVP_PKEY_CTX, out: ^u8, out_len: ^c.size_t, sig: ^u8, siglen: c.size_t) -> i32 ---

	// EVP_PKEY_derive_init initialises an |EVP_PKEY_CTX| for a key derivation
	// operation. It should be called before |EVP_PKEY_derive_set_peer| and
	// |EVP_PKEY_derive|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_derive_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_derive_set_peer sets the peer's key to be used for key derivation
	// by |ctx| to |peer|. It should be called after |EVP_PKEY_derive_init|. (For
	// example, this is used to set the peer's key in (EC)DH.) It returns one on
	// success and zero on error.
	EVP_PKEY_derive_set_peer :: proc(ctx: ^EVP_PKEY_CTX, peer: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_derive derives a shared key from |ctx|. If |key| is non-NULL then,
	// on entry, |out_key_len| must contain the amount of space at |key|. If
	// sufficient then the shared key will be written to |key| and |*out_key_len|
	// will be set to the length. If |key| is NULL then |out_key_len| will be set to
	// the maximum length.
	//
	// WARNING: Setting |out| to NULL only gives the maximum size of the key. The
	// actual key may be smaller.
	//
	// It returns one on success and zero on error.
	EVP_PKEY_derive :: proc(ctx: ^EVP_PKEY_CTX, key: ^u8, out_key_len: ^c.size_t) -> i32 ---

	// EVP_PKEY_keygen_init initialises an |EVP_PKEY_CTX| for a key generation
	// operation. It should be called before |EVP_PKEY_keygen|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_keygen_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_keygen performs a key generation operation using the values from
	// |ctx|. If |*out_pkey| is non-NULL, it overwrites |*out_pkey| with the
	// resulting key. Otherwise, it sets |*out_pkey| to a newly-allocated |EVP_PKEY|
	// containing the result. It returns one on success or zero on error.
	EVP_PKEY_keygen :: proc(ctx: ^EVP_PKEY_CTX, out_pkey: ^^EVP_PKEY) -> i32 ---

	// EVP_PKEY_paramgen_init initialises an |EVP_PKEY_CTX| for a parameter
	// generation operation. It should be called before |EVP_PKEY_paramgen|.
	//
	// It returns one on success or zero on error.
	EVP_PKEY_paramgen_init :: proc(ctx: ^EVP_PKEY_CTX) -> i32 ---

	// EVP_PKEY_paramgen performs a parameter generation using the values from
	// |ctx|. If |*out_pkey| is non-NULL, it overwrites |*out_pkey| with the
	// resulting parameters, but no key. Otherwise, it sets |*out_pkey| to a
	// newly-allocated |EVP_PKEY| containing the result. It returns one on success
	// or zero on error.
	EVP_PKEY_paramgen :: proc(ctx: ^EVP_PKEY_CTX, out_pkey: ^^EVP_PKEY) -> i32 ---

	// EVP_PKEY_CTX_set_signature_md sets |md| as the digest to be used in a
	// signature operation. It returns one on success or zero on error.
	EVP_PKEY_CTX_set_signature_md :: proc(ctx: ^EVP_PKEY_CTX, md: ^EVP_MD) -> i32 ---

	// EVP_PKEY_CTX_get_signature_md sets |*out_md| to the digest to be used in a
	// signature operation. It returns one on success or zero on error.
	EVP_PKEY_CTX_get_signature_md :: proc(ctx: ^EVP_PKEY_CTX, out_md: ^^EVP_MD) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_padding sets the padding type to use. It should be one
	// of the |RSA_*_PADDING| values. Returns one on success or zero on error. By
	// default, the padding is |RSA_PKCS1_PADDING|.
	EVP_PKEY_CTX_set_rsa_padding :: proc(ctx: ^EVP_PKEY_CTX, padding: i32) -> i32 ---

	// EVP_PKEY_CTX_get_rsa_padding sets |*out_padding| to the current padding
	// value, which is one of the |RSA_*_PADDING| values. Returns one on success or
	// zero on error.
	EVP_PKEY_CTX_get_rsa_padding :: proc(ctx: ^EVP_PKEY_CTX, out_padding: ^i32) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_pss_saltlen sets the length of the salt in a PSS-padded
	// signature. A value of |RSA_PSS_SALTLEN_DIGEST| causes the salt to be the same
	// length as the digest in the signature. A value of |RSA_PSS_SALTLEN_AUTO|
	// causes the salt to be the maximum length that will fit when signing and
	// recovered from the signature when verifying. Otherwise the value gives the
	// size of the salt in bytes.
	//
	// If unsure, use |RSA_PSS_SALTLEN_DIGEST|, which is the default. Note this
	// differs from OpenSSL, which defaults to |RSA_PSS_SALTLEN_AUTO|.
	//
	// Returns one on success or zero on error.
	EVP_PKEY_CTX_set_rsa_pss_saltlen :: proc(ctx: ^EVP_PKEY_CTX, salt_len: i32) -> i32 ---

	// EVP_PKEY_CTX_get_rsa_pss_saltlen sets |*out_salt_len| to the salt length of
	// a PSS-padded signature. See the documentation for
	// |EVP_PKEY_CTX_set_rsa_pss_saltlen| for details of the special values that it
	// can take.
	//
	// Returns one on success or zero on error.
	EVP_PKEY_CTX_get_rsa_pss_saltlen :: proc(ctx: ^EVP_PKEY_CTX, out_salt_len: ^i32) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_keygen_bits sets the size of the desired RSA modulus,
	// in bits, for key generation. Returns one on success or zero on
	// error.
	EVP_PKEY_CTX_set_rsa_keygen_bits :: proc(ctx: ^EVP_PKEY_CTX, bits: i32) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_keygen_pubexp sets |e| as the public exponent for key
	// generation. Returns one on success or zero on error. On success, |ctx| takes
	// ownership of |e|. The library will then call |BN_free| on |e| when |ctx| is
	// destroyed.
	EVP_PKEY_CTX_set_rsa_keygen_pubexp :: proc(ctx: ^EVP_PKEY_CTX, e: ^BIGNUM) -> i32 ---

	// EVP_PKEY_CTX_get_rsa_oaep_md sets |*out_md| to the digest function used in
	// OAEP padding. Returns one on success or zero on error.
	EVP_PKEY_CTX_get_rsa_oaep_md :: proc(ctx: ^EVP_PKEY_CTX, out_md: ^^EVP_MD) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_mgf1_md sets |md| as the digest used in MGF1. Returns
	// one on success or zero on error.
	//
	// If unset, the default is the signing hash for |RSA_PKCS1_PSS_PADDING| and the
	// OAEP hash for |RSA_PKCS1_OAEP_PADDING|. Callers are recommended to use this
	// default and not call this function.
	EVP_PKEY_CTX_set_rsa_mgf1_md :: proc(ctx: ^EVP_PKEY_CTX, md: ^EVP_MD) -> i32 ---

	// EVP_PKEY_CTX_get_rsa_mgf1_md sets |*out_md| to the digest function used in
	// MGF1. Returns one on success or zero on error.
	EVP_PKEY_CTX_get_rsa_mgf1_md :: proc(ctx: ^EVP_PKEY_CTX, out_md: ^^EVP_MD) -> i32 ---

	// EVP_PKEY_CTX_get0_rsa_oaep_label sets |*out_label| to point to the internal
	// buffer containing the OAEP label (which may be NULL) and returns the length
	// of the label or a negative value on error.
	//
	// WARNING: the return value differs from the usual return value convention.
	EVP_PKEY_CTX_get0_rsa_oaep_label :: proc(ctx: ^EVP_PKEY_CTX, out_label: ^^u8) -> i32 ---

	// EVP_PKEY_get_ec_curve_nid returns |pkey|'s curve as a NID constant, such as
	// |NID_X9_62_prime256v1|, or |NID_undef| if |pkey| is not an EC key.
	EVP_PKEY_get_ec_curve_nid :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_get_ec_point_conv_form returns |pkey|'s point conversion form as a
	// |POINT_CONVERSION_*| constant, or zero if |pkey| is not an EC key.
	EVP_PKEY_get_ec_point_conv_form :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_CTX_set_ec_paramgen_curve_nid sets the curve used for
	// |EVP_PKEY_keygen| or |EVP_PKEY_paramgen| operations to |nid|. It returns one
	// on success and zero on error.
	EVP_PKEY_CTX_set_ec_paramgen_curve_nid :: proc(ctx: ^EVP_PKEY_CTX, nid: i32) -> i32 ---

	// EVP_PKEY_CTX_set_dh_pad configures configures whether |ctx|, which must be an
	// |EVP_PKEY_derive| operation, configures the handling of leading zeros in the
	// Diffie-Hellman shared secret. If |pad| is zero, leading zeros are removed
	// from the secret. If |pad| is non-zero, the fixed-width shared secret is used
	// unmodified, as in PKCS #3. If this function is not called, the default is to
	// remove leading zeros.
	//
	// WARNING: The behavior when |pad| is zero leaks information about the shared
	// secret. This may result in side channel attacks such as
	// https://raccoon-attack.com/, particularly when the same private key is used
	// for multiple operations.
	EVP_PKEY_CTX_set_dh_pad :: proc(ctx: ^EVP_PKEY_CTX, pad: i32) -> i32 ---

	// EVP_PKEY_CTX_set_mldsa_44_context sets the context for an ML-DSA signing or
	// verification operation.
	EVP_PKEY_CTX_set_mldsa_44_context :: proc(ctx: ^EVP_PKEY_CTX, _context: ^u8, context_len: c.size_t) -> i32 ---

	// EVP_PKEY_CTX_set_mldsa_65_context sets the context for an ML-DSA signing or
	// verification operation.
	EVP_PKEY_CTX_set_mldsa_65_context :: proc(ctx: ^EVP_PKEY_CTX, _context: ^u8, context_len: c.size_t) -> i32 ---

	// EVP_PKEY_CTX_set_mldsa_87_context sets the context for an ML-DSA signing or
	// verification operation.
	EVP_PKEY_CTX_set_mldsa_87_context :: proc(ctx: ^EVP_PKEY_CTX, _context: ^u8, context_len: c.size_t) -> i32 ---

	// EVP_PKEY_get0 returns NULL. This function is provided for compatibility with
	// OpenSSL but does not return anything. Use the typed |EVP_PKEY_get0_*|
	// functions instead.
	EVP_PKEY_get0 :: proc(pkey: ^EVP_PKEY) -> rawptr ---

	// OpenSSL_add_all_algorithms does nothing.
	OpenSSL_add_all_algorithms :: proc() ---

	// OPENSSL_add_all_algorithms_conf does nothing.
	OPENSSL_add_all_algorithms_conf :: proc() ---

	// OpenSSL_add_all_ciphers does nothing.
	OpenSSL_add_all_ciphers :: proc() ---

	// OpenSSL_add_all_digests does nothing.
	OpenSSL_add_all_digests :: proc() ---

	// EVP_cleanup does nothing.
	EVP_cleanup              :: proc() ---
	EVP_CIPHER_do_all_sorted :: proc(callback: proc "c" (cipher: ^EVP_CIPHER, name: cstring, unused: cstring, arg: rawptr), arg: rawptr) ---
	EVP_MD_do_all_sorted     :: proc(callback: proc "c" (cipher: ^EVP_MD, name: cstring, unused: cstring, arg: rawptr), arg: rawptr) ---
	EVP_MD_do_all            :: proc(callback: proc "c" (cipher: ^EVP_MD, name: cstring, unused: cstring, arg: rawptr), arg: rawptr) ---

	// i2d_PrivateKey marshals a private key from |key| to type-specific format, as
	// described in |i2d_SAMPLE|.
	//
	// RSA keys are serialized as a DER-encoded RSAPublicKey (RFC 8017) structure.
	// EC keys are serialized as a DER-encoded ECPrivateKey (RFC 5915) structure.
	//
	// Use |RSA_marshal_private_key| or |EC_KEY_marshal_private_key| instead.
	i2d_PrivateKey :: proc(key: ^EVP_PKEY, outp: ^^u8) -> i32 ---

	// i2d_PublicKey marshals a public key from |key| to a type-specific format, as
	// described in |i2d_SAMPLE|.
	//
	// RSA keys are serialized as a DER-encoded RSAPublicKey (RFC 8017) structure.
	// EC keys are serialized as an EC point per SEC 1.
	//
	// Use |RSA_marshal_public_key| or |EC_POINT_point2cbb| instead.
	i2d_PublicKey :: proc(key: ^EVP_PKEY, outp: ^^u8) -> i32 ---

	// d2i_PrivateKey parses a DER-encoded private key from |len| bytes at |*inp|,
	// as described in |d2i_SAMPLE|. The private key must have type |type|,
	// otherwise it will be rejected.
	//
	// This function tries to detect one of several formats. Instead, use
	// |EVP_parse_private_key| for a PrivateKeyInfo, |RSA_parse_private_key| for an
	// RSAPrivateKey, and |EC_parse_private_key| for an ECPrivateKey.
	d2i_PrivateKey :: proc(type: i32, out: ^^EVP_PKEY, inp: ^^u8, len: c.long) -> ^EVP_PKEY ---

	// d2i_AutoPrivateKey acts the same as |d2i_PrivateKey|, but detects the type
	// of the private key.
	//
	// This function tries to detect one of several formats. Instead, use
	// |EVP_parse_private_key| for a PrivateKeyInfo, |RSA_parse_private_key| for an
	// RSAPrivateKey, and |EC_parse_private_key| for an ECPrivateKey.
	d2i_AutoPrivateKey :: proc(out: ^^EVP_PKEY, inp: ^^u8, len: c.long) -> ^EVP_PKEY ---

	// d2i_PublicKey parses a public key from |len| bytes at |*inp| in a type-
	// specific format specified by |type|, as described in |d2i_SAMPLE|.
	//
	// The only supported value for |type| is |EVP_PKEY_RSA|, which parses a
	// DER-encoded RSAPublicKey (RFC 8017) structure. Parsing EC keys is not
	// supported by this function.
	//
	// Use |RSA_parse_public_key| instead.
	d2i_PublicKey :: proc(type: i32, out: ^^EVP_PKEY, inp: ^^u8, len: c.long) -> ^EVP_PKEY ---

	// EVP_PKEY_CTX_set_ec_param_enc returns one if |encoding| is
	// |OPENSSL_EC_NAMED_CURVE| or zero with an error otherwise.
	EVP_PKEY_CTX_set_ec_param_enc :: proc(ctx: ^EVP_PKEY_CTX, encoding: i32) -> i32 ---

	// EVP_PKEY_set_type sets the type of |pkey| to |type|. It returns one if
	// successful or zero if the |type| argument is not one of the |EVP_PKEY_*|
	// values supported for use with this function. If |pkey| is NULL, it simply
	// reports whether the type is known.
	//
	// There are very few cases where this function is useful. Changing |pkey|'s
	// type clears any previously stored keys, so there is no benefit to loading a
	// key and then changing its type. Although |pkey| is left with a type
	// configured, it has no key, and functions which set a key, such as
	// |EVP_PKEY_set1_RSA|, will configure a type anyway. If writing unit tests that
	// are only sensitive to the type of a key, it is preferable to construct a real
	// key, so that tests are more representative of production code.
	//
	// The only API pattern which requires this function is
	// |EVP_PKEY_set1_tls_encodedpoint| with X25519, which requires a half-empty
	// |EVP_PKEY| that was first configured with |EVP_PKEY_X25519|. Currently, all
	// other values of |type| will result in an error.
	EVP_PKEY_set_type :: proc(pkey: ^EVP_PKEY, type: i32) -> i32 ---

	// EVP_PKEY_set1_tls_encodedpoint replaces |pkey| with a public key encoded by
	// |in|. It returns one on success and zero on error.
	//
	// If |pkey| is an EC key, the format is an X9.62 point and |pkey| must already
	// have an EC group configured. If it is an X25519 key, it is the 32-byte X25519
	// public key representation. This function is not supported for other key types
	// and will fail.
	EVP_PKEY_set1_tls_encodedpoint :: proc(pkey: ^EVP_PKEY, _in: ^u8, len: c.size_t) -> i32 ---

	// EVP_PKEY_get1_tls_encodedpoint sets |*out_ptr| to a newly-allocated buffer
	// containing the raw encoded public key for |pkey|. The caller must call
	// |OPENSSL_free| to release this buffer. The function returns the length of the
	// buffer on success and zero on error.
	//
	// If |pkey| is an EC key, the format is an X9.62 point with uncompressed
	// coordinates. If it is an X25519 key, it is the 32-byte X25519 public key
	// representation. This function is not supported for other key types and will
	// fail.
	EVP_PKEY_get1_tls_encodedpoint :: proc(pkey: ^EVP_PKEY, out_ptr: ^^u8) -> c.size_t ---

	// EVP_PKEY_base_id calls |EVP_PKEY_id|.
	EVP_PKEY_base_id :: proc(pkey: ^EVP_PKEY) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_pss_keygen_md returns 0.
	EVP_PKEY_CTX_set_rsa_pss_keygen_md :: proc(ctx: ^EVP_PKEY_CTX, md: ^EVP_MD) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_pss_keygen_saltlen returns 0.
	EVP_PKEY_CTX_set_rsa_pss_keygen_saltlen :: proc(ctx: ^EVP_PKEY_CTX, salt_len: i32) -> i32 ---

	// EVP_PKEY_CTX_set_rsa_pss_keygen_mgf1_md returns 0.
	EVP_PKEY_CTX_set_rsa_pss_keygen_mgf1_md :: proc(ctx: ^EVP_PKEY_CTX, md: ^EVP_MD) -> i32 ---

	// i2d_PUBKEY marshals |pkey| as a DER-encoded SubjectPublicKeyInfo, as
	// described in |i2d_SAMPLE|.
	//
	// Use |EVP_marshal_public_key| instead.
	i2d_PUBKEY :: proc(pkey: ^EVP_PKEY, outp: ^^u8) -> i32 ---

	// d2i_PUBKEY parses a DER-encoded SubjectPublicKeyInfo from |len| bytes at
	// |*inp|, as described in |d2i_SAMPLE|.
	//
	// Use |EVP_parse_public_key| instead.
	d2i_PUBKEY :: proc(out: ^^EVP_PKEY, inp: ^^u8, len: c.long) -> ^EVP_PKEY ---

	// i2d_RSA_PUBKEY marshals |rsa| as a DER-encoded SubjectPublicKeyInfo
	// structure, as described in |i2d_SAMPLE|.
	//
	// Use |EVP_marshal_public_key| instead.
	i2d_RSA_PUBKEY :: proc(rsa: ^RSA, outp: ^^u8) -> i32 ---

	// d2i_RSA_PUBKEY parses an RSA public key as a DER-encoded SubjectPublicKeyInfo
	// from |len| bytes at |*inp|, as described in |d2i_SAMPLE|.
	// SubjectPublicKeyInfo structures containing other key types are rejected.
	//
	// Use |EVP_parse_public_key| instead.
	d2i_RSA_PUBKEY :: proc(out: ^^RSA, inp: ^^u8, len: c.long) -> ^RSA ---

	// i2d_DSA_PUBKEY marshals |dsa| as a DER-encoded SubjectPublicKeyInfo, as
	// described in |i2d_SAMPLE|.
	//
	// Use |EVP_marshal_public_key| instead.
	i2d_DSA_PUBKEY :: proc(dsa: ^DSA, outp: ^^u8) -> i32 ---

	// d2i_DSA_PUBKEY parses a DSA public key as a DER-encoded SubjectPublicKeyInfo
	// from |len| bytes at |*inp|, as described in |d2i_SAMPLE|.
	// SubjectPublicKeyInfo structures containing other key types are rejected.
	//
	// Use |EVP_parse_public_key| instead.
	d2i_DSA_PUBKEY :: proc(out: ^^DSA, inp: ^^u8, len: c.long) -> ^DSA ---

	// i2d_EC_PUBKEY marshals |ec_key| as a DER-encoded SubjectPublicKeyInfo, as
	// described in |i2d_SAMPLE|.
	//
	// Use |EVP_marshal_public_key| instead.
	i2d_EC_PUBKEY :: proc(ec_key: ^EC_KEY, outp: ^^u8) -> i32 ---

	// d2i_EC_PUBKEY parses an EC public key as a DER-encoded SubjectPublicKeyInfo
	// from |len| bytes at |*inp|, as described in |d2i_SAMPLE|.
	// SubjectPublicKeyInfo structures containing other key types are rejected.
	//
	// Use |EVP_parse_public_key| instead.
	d2i_EC_PUBKEY :: proc(out: ^^EC_KEY, inp: ^^u8, len: c.long) -> ^EC_KEY ---

	// EVP_PKEY_CTX_set_dsa_paramgen_bits returns zero.
	EVP_PKEY_CTX_set_dsa_paramgen_bits :: proc(ctx: ^EVP_PKEY_CTX, nbits: i32) -> i32 ---

	// EVP_PKEY_CTX_set_dsa_paramgen_q_bits returns zero.
	EVP_PKEY_CTX_set_dsa_paramgen_q_bits :: proc(ctx: ^EVP_PKEY_CTX, qbits: i32) -> i32 ---

	// EVP_PKEY_assign sets the underlying key of |pkey| to |key|, which must be of
	// the given type. If successful, it returns one. If the |type| argument
	// is not one of |EVP_PKEY_RSA|, |EVP_PKEY_DSA|, or |EVP_PKEY_EC| values or if
	// |key| is NULL, it returns zero. This function may not be used with other
	// |EVP_PKEY_*| types.
	//
	// Use the |EVP_PKEY_assign_*| functions instead.
	EVP_PKEY_assign :: proc(pkey: ^EVP_PKEY, type: i32, key: rawptr) -> i32 ---

	// EVP_PKEY_type returns |nid|.
	EVP_PKEY_type :: proc(nid: i32) -> i32 ---

	// EVP_PKEY_new_raw_private_key interprets |in| as a raw private key of type
	// |type|, which must be an |EVP_PKEY_*| constant, such as |EVP_PKEY_X25519|,
	// and returns a newly-allocated |EVP_PKEY|, or nullptr on error.
	//
	// Prefer |EVP_PKEY_from_raw_private_key|, which allows dead code elimination to
	// discard algorithms that aren't reachable from the caller.
	EVP_PKEY_new_raw_private_key :: proc(type: i32, unused: ^ENGINE, _in: ^u8, len: c.size_t) -> ^EVP_PKEY ---

	// EVP_PKEY_new_raw_public_key interprets |in| as a raw public key of type
	// |type|, which must be an |EVP_PKEY_*| constant, such as |EVP_PKEY_X25519|,
	// and returns a newly-allocated |EVP_PKEY|, or nullptr on error.
	//
	// Prefer |EVP_PKEY_from_raw_private_key|, which allows dead code elimination to
	// discard algorithms that aren't reachable from the caller.
	EVP_PKEY_new_raw_public_key :: proc(type: i32, unused: ^ENGINE, _in: ^u8, len: c.size_t) -> ^EVP_PKEY ---
}

