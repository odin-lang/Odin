// Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
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

import "core:c/libc"
import "core:c"

package bifrost_tls

// BoringSSL static libraries (vendored, Linux-only for now).
@(private) LIBSSL_PATH    :: "../../boringssl/lib/libssl.a"
@(private) LIBCRYPTO_PATH :: "../../boringssl/lib/libcrypto.a"

when !#exists(LIBSSL_PATH) {
	#panic("Could not find BoringSSL at \"" + LIBSSL_PATH + "\", build it via `" + ODIN_ROOT + "vendor/boringssl/build_boringssl.sh\"`")
}
when !#exists(LIBCRYPTO_PATH) {
	#panic("Could not find BoringSSL at \"" + LIBCRYPTO_PATH + "\", build it via `" + ODIN_ROOT + "vendor/boringssl/build_boringssl.sh\"`")
}

foreign import ssl {
	LIBSSL_PATH,
}
foreign import crypto {
	LIBCRYPTO_PATH,
}


stack_st_X509          :: struct {}
sk_X509_free_func      :: proc "c" (^X509)
sk_X509_copy_func      :: proc "c" (^X509) -> ^X509
sk_X509_cmp_func       :: proc "c" (^^X509, ^^X509) -> i32
sk_X509_delete_if_func :: proc "c" (^X509, rawptr) -> i32

@(default_calling_convention="c")
foreign lib {
	// X509_up_ref adds one to the reference count of |x509| and returns one.
	X509_up_ref :: proc(x509: ^X509) -> i32 ---

	// X509_chain_up_ref returns a newly-allocated |STACK_OF(X509)| containing a
	// shallow copy of |chain|, or NULL on error. That is, the return value has the
	// same contents as |chain|, and each |X509|'s reference count is incremented by
	// one.
	X509_chain_up_ref :: proc(chain: ^stack_st_X509) -> ^stack_st_X509 ---

	// X509_dup returns a newly-allocated copy of |x509|, or NULL on error. This
	// function works by serializing the structure, so auxiliary properties (see
	// |i2d_X509_AUX|) are not preserved. Additionally, if |x509| is incomplete,
	// this function may fail.
	X509_dup :: proc(x509: ^X509) -> ^X509 ---

	// X509_free decrements |x509|'s reference count and, if zero, releases memory
	// associated with |x509|.
	X509_free :: proc(x509: ^X509) ---

	// d2i_X509 parses up to |len| bytes from |*inp| as a DER-encoded X.509
	// Certificate (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_X509 :: proc(out: ^^X509, inp: ^^u8, len: c.long) -> ^X509 ---

	// X509_parse_with_algorithms parses an X.509 structure from |buf| and returns a
	// fresh X509 or NULL on error. There must not be any trailing data in |buf|.
	// The returned structure (if any) increment's |buf|'s reference count and
	// retains a reference to it.
	//
	// Only the |num_algs| algorithms from |algs| will be considered when parsing
	// the certificate's public key. If the certificate uses a different algorithm,
	// it will still be parsed, but |X509_get0_pubkey| will return NULL.
	X509_parse_with_algorithms :: proc(buf: ^CRYPTO_BUFFER, algs: ^^EVP_PKEY_ALG, num_algs: c.size_t) -> ^X509 ---

	// X509_parse_from_buffer behaves like |X509_parse_with_algorithms| but uses a
	// default algorithm list.
	X509_parse_from_buffer :: proc(buf: ^CRYPTO_BUFFER) -> ^X509 ---

	// i2d_X509 marshals |x509| as a DER-encoded X.509 Certificate (RFC 5280), as
	// described in |i2d_SAMPLE|.
	i2d_X509 :: proc(x509: ^X509, outp: ^^u8) -> i32 ---
}

// X509_VERSION_* are X.509 version numbers. Note the numerical values of all
// defined X.509 versions are one less than the named version.
X509_VERSION_1 :: 0
X509_VERSION_2 :: 1
X509_VERSION_3 :: 2

@(default_calling_convention="c")
foreign lib {
	// X509_get_version returns the numerical value of |x509|'s version, which will
	// be one of the |X509_VERSION_*| constants.
	X509_get_version :: proc(x509: ^X509) -> c.long ---

	// X509_get0_serialNumber returns |x509|'s serial number.
	X509_get0_serialNumber :: proc(x509: ^X509) -> ^ASN1_INTEGER ---

	// X509_get0_notBefore returns |x509|'s notBefore time.
	X509_get0_notBefore :: proc(x509: ^X509) -> ^ASN1_TIME ---

	// X509_get0_notAfter returns |x509|'s notAfter time.
	X509_get0_notAfter :: proc(x509: ^X509) -> ^ASN1_TIME ---

	// X509_get_issuer_name returns |x509|'s issuer.
	X509_get_issuer_name :: proc(x509: ^X509) -> ^X509_NAME ---

	// X509_get_subject_name returns |x509|'s subject.
	X509_get_subject_name :: proc(x509: ^X509) -> ^X509_NAME ---

	// X509_get_X509_PUBKEY returns the public key of |x509|. Note this function is
	// not const-correct for legacy reasons. Callers should not modify the returned
	// object.
	X509_get_X509_PUBKEY :: proc(x509: ^X509) -> ^X509_PUBKEY ---

	// X509_get0_pubkey returns |x509|'s public key as an |EVP_PKEY|, or NULL if the
	// public key was unsupported or could not be decoded. The |EVP_PKEY| is cached
	// in |x509|, so callers must not mutate the result.
	X509_get0_pubkey :: proc(x509: ^X509) -> ^EVP_PKEY ---

	// X509_get_pubkey behaves like |X509_get0_pubkey| but increments the reference
	// count on the |EVP_PKEY|. The caller must release the result with
	// |EVP_PKEY_free| when done. The |EVP_PKEY| is cached in |x509|, so callers
	// must not mutate the result.
	X509_get_pubkey :: proc(x509: ^X509) -> ^EVP_PKEY ---

	// X509_get0_pubkey_bitstr returns the BIT STRING portion of |x509|'s public
	// key. Note this does not contain the AlgorithmIdentifier portion.
	//
	// WARNING: This function returns a non-const pointer for OpenSSL compatibility,
	// but the caller must not modify the resulting object. Doing so will break
	// internal invariants in |x509|.
	X509_get0_pubkey_bitstr :: proc(x509: ^X509) -> ^ASN1_BIT_STRING ---

	// X509_check_private_key returns one if |x509|'s public key matches |pkey| and
	// zero otherwise.
	X509_check_private_key :: proc(x509: ^X509, pkey: ^EVP_PKEY) -> i32 ---

	// X509_get0_uids sets |*out_issuer_uid| to a non-owning pointer to the
	// issuerUID field of |x509|, or NULL if |x509| has no issuerUID. It similarly
	// outputs |x509|'s subjectUID field to |*out_subject_uid|.
	//
	// Callers may pass NULL to either |out_issuer_uid| or |out_subject_uid| to
	// ignore the corresponding field.
	X509_get0_uids :: proc(x509: ^X509, out_issuer_uid: ^^ASN1_BIT_STRING, out_subject_uid: ^^ASN1_BIT_STRING) ---
}

// The following bits are returned from |X509_get_extension_flags|.

// EXFLAG_BCONS indicates the certificate has a basic constraints extension.
EXFLAG_BCONS :: 0x1

// EXFLAG_KUSAGE indicates the certificate has a key usage extension.
EXFLAG_KUSAGE :: 0x2

// EXFLAG_XKUSAGE indicates the certificate has an extended key usage extension.
EXFLAG_XKUSAGE :: 0x4

// EXFLAG_CA indicates the certificate has a basic constraints extension with
// the CA bit set.
EXFLAG_CA :: 0x10

// EXFLAG_SI indicates the certificate is self-issued, i.e. its subject and
// issuer names match.
EXFLAG_SI :: 0x20

// EXFLAG_V1 indicates an X.509v1 certificate.
EXFLAG_V1 :: 0x40

// EXFLAG_INVALID indicates an error processing some extension. The certificate
// should not be accepted. Note the lack of this bit does not imply all
// extensions are valid, only those used to compute extension flags.
EXFLAG_INVALID :: 0x80

// EXFLAG_SET is an internal bit that indicates extension flags were computed.
EXFLAG_SET :: 0x100

// EXFLAG_CRITICAL indicates an unsupported critical extension. The certificate
// should not be accepted.
EXFLAG_CRITICAL :: 0x200

// EXFLAG_SS indicates the certificate is likely self-signed. That is, if it is
// self-issued, its authority key identifier (if any) matches itself, and its
// key usage extension (if any) allows certificate signatures. The signature
// itself is not checked in computing this bit.
EXFLAG_SS :: 0x2000

@(default_calling_convention="c")
foreign lib {
	// X509_get_extension_flags decodes a set of extensions from |x509| and returns
	// a collection of |EXFLAG_*| bits which reflect |x509|. If there was an error
	// in computing this bitmask, the result will include the |EXFLAG_INVALID| bit.
	X509_get_extension_flags :: proc(x509: ^X509) -> u32 ---

	// X509_get_pathlen returns path length constraint from the basic constraints
	// extension in |x509|. (See RFC 5280, section 4.2.1.9.) It returns -1 if the
	// constraint is not present, or if some extension in |x509| was invalid.
	//
	// TODO(crbug.com/boringssl/381): Decoding an |X509| object will not check for
	// invalid extensions. To detect the error case, call
	// |X509_get_extension_flags| and check the |EXFLAG_INVALID| bit.
	X509_get_pathlen :: proc(x509: ^X509) -> c.long ---
}

// X509v3_KU_* are key usage bits returned from |X509_get_key_usage|.
X509v3_KU_DIGITAL_SIGNATURE :: 0x0080
X509v3_KU_NON_REPUDIATION   :: 0x0040
X509v3_KU_KEY_ENCIPHERMENT  :: 0x0020
X509v3_KU_DATA_ENCIPHERMENT :: 0x0010
X509v3_KU_KEY_AGREEMENT     :: 0x0008
X509v3_KU_KEY_CERT_SIGN     :: 0x0004
X509v3_KU_CRL_SIGN          :: 0x0002
X509v3_KU_ENCIPHER_ONLY     :: 0x0001
X509v3_KU_DECIPHER_ONLY     :: 0x8000

@(default_calling_convention="c")
foreign lib {
	// X509_get_key_usage returns a bitmask of key usages (see Section 4.2.1.3 of
	// RFC 5280) which |x509| is valid for. This function only reports the first 16
	// bits, in a little-endian byte order, but big-endian bit order. That is, bits
	// 0 though 7 are reported at 1<<7 through 1<<0, and bits 8 through 15 are
	// reported at 1<<15 through 1<<8.
	//
	// Instead of depending on this bit order, callers should compare against the
	// |X509v3_KU_*| constants.
	//
	// If |x509| has no key usage extension, all key usages are valid and this
	// function returns |UINT32_MAX|. If there was an error processing |x509|'s
	// extensions, or if the first 16 bits in the key usage extension were all zero,
	// this function returns zero.
	X509_get_key_usage :: proc(x509: ^X509) -> u32 ---
}

// XKU_* are extended key usage bits returned from
// |X509_get_extended_key_usage|.
XKU_SSL_SERVER :: 0x1
XKU_SSL_CLIENT :: 0x2
XKU_SMIME      :: 0x4
XKU_CODE_SIGN  :: 0x8
XKU_SGC        :: 0x10
XKU_OCSP_SIGN  :: 0x20
XKU_TIMESTAMP  :: 0x40
XKU_DVCS       :: 0x80
XKU_ANYEKU     :: 0x100

@(default_calling_convention="c")
foreign lib {
	// X509_get_extended_key_usage returns a bitmask of extended key usages (see
	// Section 4.2.1.12 of RFC 5280) which |x509| is valid for. The result will be
	// a combination of |XKU_*| constants. If checking an extended key usage not
	// defined above, callers should extract the extended key usage extension
	// separately, e.g. via |X509_get_ext_d2i|.
	//
	// If |x509| has no extended key usage extension, all extended key usages are
	// valid and this function returns |UINT32_MAX|. If there was an error
	// processing |x509|'s extensions, or if |x509|'s extended key usage extension
	// contained no recognized usages, this function returns zero.
	X509_get_extended_key_usage :: proc(x509: ^X509) -> u32 ---

	// X509_get0_subject_key_id returns |x509|'s subject key identifier, if present.
	// (See RFC 5280, section 4.2.1.2.) It returns NULL if the extension is not
	// present or if some extension in |x509| was invalid.
	//
	// TODO(crbug.com/boringssl/381): Decoding an |X509| object will not check for
	// invalid extensions. To detect the error case, call
	// |X509_get_extension_flags| and check the |EXFLAG_INVALID| bit.
	X509_get0_subject_key_id :: proc(x509: ^X509) -> ^ASN1_OCTET_STRING ---

	// X509_get0_authority_key_id returns keyIdentifier of |x509|'s authority key
	// identifier, if the extension and field are present. (See RFC 5280,
	// section 4.2.1.1.) It returns NULL if the extension is not present, if it is
	// present but lacks a keyIdentifier field, or if some extension in |x509| was
	// invalid.
	//
	// TODO(crbug.com/boringssl/381): Decoding an |X509| object will not check for
	// invalid extensions. To detect the error case, call
	// |X509_get_extension_flags| and check the |EXFLAG_INVALID| bit.
	X509_get0_authority_key_id :: proc(x509: ^X509) -> ^ASN1_OCTET_STRING ---
}

sk_GENERAL_NAME_cmp_func       :: proc "c" (^^GENERAL_NAME, ^^GENERAL_NAME) -> i32
sk_GENERAL_NAME_copy_func      :: proc "c" (^GENERAL_NAME) -> ^GENERAL_NAME
sk_GENERAL_NAME_delete_if_func :: proc "c" (^GENERAL_NAME, rawptr) -> i32
stack_st_GENERAL_NAME          :: struct {}
sk_GENERAL_NAME_free_func      :: proc "c" (^GENERAL_NAME)
GENERAL_NAMES                  :: stack_st_GENERAL_NAME

@(default_calling_convention="c")
foreign lib {
	// X509_get0_authority_issuer returns the authorityCertIssuer of |x509|'s
	// authority key identifier, if the extension and field are present. (See
	// RFC 5280, section 4.2.1.1.) It returns NULL if the extension is not present,
	// if it is present but lacks a authorityCertIssuer field, or if some extension
	// in |x509| was invalid.
	//
	// TODO(crbug.com/boringssl/381): Decoding an |X509| object will not check for
	// invalid extensions. To detect the error case, call
	// |X509_get_extension_flags| and check the |EXFLAG_INVALID| bit.
	X509_get0_authority_issuer :: proc(x509: ^X509) -> ^GENERAL_NAMES ---

	// X509_get0_authority_serial returns the authorityCertSerialNumber of |x509|'s
	// authority key identifier, if the extension and field are present. (See
	// RFC 5280, section 4.2.1.1.) It returns NULL if the extension is not present,
	// if it is present but lacks a authorityCertSerialNumber field, or if some
	// extension in |x509| was invalid.
	//
	// TODO(crbug.com/boringssl/381): Decoding an |X509| object will not check for
	// invalid extensions. To detect the error case, call
	// |X509_get_extension_flags| and check the |EXFLAG_INVALID| bit.
	X509_get0_authority_serial :: proc(x509: ^X509) -> ^ASN1_INTEGER ---

	// X509_get0_extensions returns |x509|'s extension list, or NULL if |x509| omits
	// it.
	X509_get0_extensions :: proc(x509: ^X509) -> ^stack_st_X509_EXTENSION ---
}

stack_st_X509_EXTENSION :: struct {}

@(default_calling_convention="c")
foreign lib {
	// X509_get_ext_count returns the number of extensions in |x|.
	X509_get_ext_count :: proc(x: ^X509) -> i32 ---

	// X509_get_ext_by_NID behaves like |X509v3_get_ext_by_NID| but searches for
	// extensions in |x|.
	X509_get_ext_by_NID :: proc(x: ^X509, nid: i32, lastpos: i32) -> i32 ---

	// X509_get_ext_by_OBJ behaves like |X509v3_get_ext_by_OBJ| but searches for
	// extensions in |x|.
	X509_get_ext_by_OBJ :: proc(x: ^X509, obj: ^ASN1_OBJECT, lastpos: i32) -> i32 ---

	// X509_get_ext_by_critical behaves like |X509v3_get_ext_by_critical| but
	// searches for extensions in |x|.
	X509_get_ext_by_critical :: proc(x: ^X509, crit: i32, lastpos: i32) -> i32 ---

	// X509_get_ext returns the extension in |x| at index |loc|, or NULL if |loc| is
	// out of bounds. This function returns a non-const pointer for OpenSSL
	// compatibility, but callers should not mutate the result.
	X509_get_ext :: proc(x: ^X509, loc: i32) -> ^X509_EXTENSION ---

	// X509_get_ext_d2i behaves like |X509V3_get_d2i| but looks for the extension in
	// |x509|'s extension list.
	//
	// WARNING: This function is difficult to use correctly. See the documentation
	// for |X509V3_get_d2i| for details.
	X509_get_ext_d2i :: proc(x509: ^X509, nid: i32, out_critical: ^i32, out_idx: ^i32) -> rawptr ---

	// X509_get0_tbs_sigalg returns the signature algorithm in |x509|'s
	// TBSCertificate. For the outer signature algorithm, see |X509_get0_signature|.
	//
	// Certificates with mismatched signature algorithms will successfully parse,
	// but they will be rejected when verifying.
	X509_get0_tbs_sigalg :: proc(x509: ^X509) -> ^X509_ALGOR ---

	// X509_get0_signature sets |*out_sig| and |*out_alg| to the signature and
	// signature algorithm of |x509|, respectively. Either output pointer may be
	// NULL to ignore the value.
	//
	// This function outputs the outer signature algorithm. For the one in the
	// TBSCertificate, see |X509_get0_tbs_sigalg|. Certificates with mismatched
	// signature algorithms will successfully parse, but they will be rejected when
	// verifying.
	X509_get0_signature :: proc(out_sig: ^^ASN1_BIT_STRING, out_alg: ^^X509_ALGOR, x509: ^X509) ---

	// X509_get_signature_nid returns the NID corresponding to |x509|'s signature
	// algorithm, or |NID_undef| if the signature algorithm does not correspond to
	// a known NID.
	X509_get_signature_nid :: proc(x509: ^X509) -> i32 ---

	// i2d_X509_tbs serializes the TBSCertificate portion of |x509|, as described in
	// |i2d_SAMPLE|.
	//
	// This function preserves the original encoding of the TBSCertificate and may
	// not reflect modifications made to |x509|. It may be used to manually verify
	// the signature of an existing certificate. To generate certificates, use
	// |i2d_re_X509_tbs| instead.
	i2d_X509_tbs :: proc(x509: ^X509, outp: ^^u8) -> i32 ---

	// X509_verify checks that |x509| has a valid signature by |pkey|. It returns
	// one if the signature is valid and zero otherwise. Note this function only
	// checks the signature itself and does not perform a full certificate
	// validation.
	X509_verify :: proc(x509: ^X509, pkey: ^EVP_PKEY) -> i32 ---

	// X509_get1_email returns a newly-allocated list of NUL-terminated strings
	// containing all email addresses in |x509|'s subject and all rfc822name names
	// in |x509|'s subject alternative names. Email addresses which contain embedded
	// NUL bytes are skipped.
	//
	// On error, or if there are no such email addresses, it returns NULL. When
	// done, the caller must release the result with |X509_email_free|.
	X509_get1_email :: proc(x509: ^X509) -> ^stack_st_OPENSSL_STRING ---

	// X509_get1_ocsp returns a newly-allocated list of NUL-terminated strings
	// containing all OCSP URIs in |x509|. That is, it collects all URI
	// AccessDescriptions with an accessMethod of id-ad-ocsp in |x509|'s authority
	// information access extension. URIs which contain embedded NUL bytes are
	// skipped.
	//
	// On error, or if there are no such URIs, it returns NULL. When done, the
	// caller must release the result with |X509_email_free|.
	X509_get1_ocsp :: proc(x509: ^X509) -> ^stack_st_OPENSSL_STRING ---

	// X509_email_free releases memory associated with |sk|, including |sk| itself.
	// Each |OPENSSL_STRING| in |sk| must be a NUL-terminated string allocated with
	// |OPENSSL_malloc|. If |sk| is NULL, no action is taken.
	X509_email_free :: proc(sk: ^stack_st_OPENSSL_STRING) ---

	// X509_cmp compares |a| and |b| and returns zero if they are equal, a negative
	// number if |b| sorts after |a| and a negative number if |a| sorts after |b|.
	// The sort order implemented by this function is arbitrary and does not
	// reflect properties of the certificate such as expiry. Applications should not
	// rely on the order itself.
	//
	// TODO(https://crbug.com/boringssl/355): This function works by comparing a
	// cached hash of the encoded certificate. If |a| or |b| could not be
	// serialized, the current behavior is to compare all unencodable certificates
	// as equal. This function should only be used with |X509| objects that were
	// parsed from bytes and never mutated.
	X509_cmp :: proc(a: ^X509, b: ^X509) -> i32 ---

	// X509_new returns a newly-allocated, empty |X509| object, or NULL on error.
	// This produces an incomplete certificate which may be filled in to issue a new
	// certificate.
	X509_new :: proc() -> ^X509 ---

	// X509_set_version sets |x509|'s version to |version|, which should be one of
	// the |X509V_VERSION_*| constants. It returns one on success and zero on error.
	//
	// If unsure, use |X509_VERSION_3|.
	X509_set_version :: proc(x509: ^X509, version: c.long) -> i32 ---

	// X509_set_serialNumber sets |x509|'s serial number to |serial|. It returns one
	// on success and zero on error.
	X509_set_serialNumber :: proc(x509: ^X509, serial: ^ASN1_INTEGER) -> i32 ---

	// X509_set1_notBefore sets |x509|'s notBefore time to |tm|. It returns one on
	// success and zero on error.
	X509_set1_notBefore :: proc(x509: ^X509, tm: ^ASN1_TIME) -> i32 ---

	// X509_set1_notAfter sets |x509|'s notAfter time to |tm|. it returns one on
	// success and zero on error.
	X509_set1_notAfter :: proc(x509: ^X509, tm: ^ASN1_TIME) -> i32 ---

	// X509_getm_notBefore returns a mutable pointer to |x509|'s notBefore time.
	X509_getm_notBefore :: proc(x509: ^X509) -> ^ASN1_TIME ---

	// X509_getm_notAfter returns a mutable pointer to |x509|'s notAfter time.
	X509_getm_notAfter :: proc(x: ^X509) -> ^ASN1_TIME ---

	// X509_set_issuer_name sets |x509|'s issuer to a copy of |name|. It returns one
	// on success and zero on error.
	X509_set_issuer_name :: proc(x509: ^X509, name: ^X509_NAME) -> i32 ---

	// X509_set_subject_name sets |x509|'s subject to a copy of |name|. It returns
	// one on success and zero on error.
	X509_set_subject_name :: proc(x509: ^X509, name: ^X509_NAME) -> i32 ---

	// X509_set_pubkey sets |x509|'s public key to |pkey|. It returns one on success
	// and zero on error. This function does not take ownership of |pkey| and
	// internally copies and updates reference counts as needed.
	X509_set_pubkey :: proc(x509: ^X509, pkey: ^EVP_PKEY) -> i32 ---

	// X509_delete_ext removes the extension in |x| at index |loc| and returns the
	// removed extension, or NULL if |loc| was out of bounds. If non-NULL, the
	// caller must release the result with |X509_EXTENSION_free|.
	X509_delete_ext :: proc(x: ^X509, loc: i32) -> ^X509_EXTENSION ---

	// X509_add_ext adds a copy of |ex| to |x|. It returns one on success and zero
	// on failure. The caller retains ownership of |ex| and can release it
	// independently of |x|.
	//
	// The new extension is inserted at index |loc|, shifting extensions to the
	// right. If |loc| is -1 or out of bounds, the new extension is appended to the
	// list.
	X509_add_ext :: proc(x: ^X509, ex: ^X509_EXTENSION, loc: i32) -> i32 ---

	// X509_add1_ext_i2d behaves like |X509V3_add1_i2d| but adds the extension to
	// |x|'s extension list.
	//
	// WARNING: This function may return zero or -1 on error. The caller must also
	// ensure |value|'s type matches |nid|. See the documentation for
	// |X509V3_add1_i2d| for details.
	X509_add1_ext_i2d :: proc(x: ^X509, nid: i32, value: rawptr, crit: i32, flags: c.ulong) -> i32 ---

	// X509_sign signs |x509| with |pkey| and replaces the signature algorithm and
	// signature fields. It returns the length of the signature on success and zero
	// on error. This function uses digest algorithm |md|, or |pkey|'s default if
	// NULL. Other signing parameters use |pkey|'s defaults. To customize them, use
	// |X509_sign_ctx|.
	X509_sign :: proc(x509: ^X509, pkey: ^EVP_PKEY, md: ^EVP_MD) -> i32 ---

	// X509_sign_ctx signs |x509| with |ctx| and replaces the signature algorithm
	// and signature fields. It returns the length of the signature on success and
	// zero on error. The signature algorithm and parameters come from |ctx|, which
	// must have been initialized with |EVP_DigestSignInit|. The caller should
	// configure the corresponding |EVP_PKEY_CTX| before calling this function.
	//
	// On success or failure, this function mutates |ctx| and resets it to the empty
	// state. Caller should not rely on its contents after the function returns.
	X509_sign_ctx :: proc(x509: ^X509, ctx: ^EVP_MD_CTX) -> i32 ---

	// i2d_re_X509_tbs serializes the TBSCertificate portion of |x509|, as described
	// in |i2d_SAMPLE|.
	//
	// This function re-encodes the TBSCertificate and may not reflect |x509|'s
	// original encoding. It may be used to manually generate a signature for a new
	// certificate. To verify certificates, use |i2d_X509_tbs| instead.
	//
	// Unlike |i2d_X509_tbs|, this function is not |const| and thus may not be to
	// use concurrently with other functions that access |x509|. It mutates |x509|
	// by dropping the cached encoding. This function is intended to be used during
	// certificate construction, where |x509| is still single-threaded and being
	// mutated.
	i2d_re_X509_tbs :: proc(x509: ^X509, outp: ^^u8) -> i32 ---

	// X509_set1_signature_algo sets |x509|'s signature algorithm to |algo| and
	// returns one on success or zero on error. It updates both the signature field
	// of the TBSCertificate structure, and the signatureAlgorithm field of the
	// Certificate.
	X509_set1_signature_algo :: proc(x509: ^X509, algo: ^X509_ALGOR) -> i32 ---

	// X509_set1_signature_value sets |x509|'s signature to a copy of the |sig_len|
	// bytes pointed by |sig|. It returns one on success and zero on error.
	//
	// Due to a specification error, X.509 certificates store signatures in ASN.1
	// BIT STRINGs, but signature algorithms return byte strings rather than bit
	// strings. This function creates a BIT STRING containing a whole number of
	// bytes, with the bit order matching the DER encoding. This matches the
	// encoding used by all X.509 signature algorithms.
	X509_set1_signature_value :: proc(x509: ^X509, sig: ^u8, sig_len: c.size_t) -> i32 ---

	// i2d_X509_AUX marshals |x509| as a DER-encoded X.509 Certificate (RFC 5280),
	// followed optionally by a separate, OpenSSL-specific structure with auxiliary
	// properties. It behaves as described in |i2d_SAMPLE|.
	//
	// Unlike similarly-named functions, this function does not output a single
	// ASN.1 element. Directly embedding the output in a larger ASN.1 structure will
	// not behave correctly.
	i2d_X509_AUX :: proc(x509: ^X509, outp: ^^u8) -> i32 ---

	// d2i_X509_AUX parses up to |length| bytes from |*inp| as a DER-encoded X.509
	// Certificate (RFC 5280), followed optionally by a separate, OpenSSL-specific
	// structure with auxiliary properties. It behaves as described in |d2i_SAMPLE|.
	//
	// WARNING: Passing untrusted input to this function allows an attacker to
	// control auxiliary properties. This can allow unexpected influence over the
	// application if the certificate is used in a context that reads auxiliary
	// properties. This includes PKCS#12 serialization, trusted certificates in
	// |X509_STORE|, and callers of |X509_alias_get0| or |X509_keyid_get0|.
	//
	// Unlike similarly-named functions, this function does not parse a single
	// ASN.1 element. Trying to parse data directly embedded in a larger ASN.1
	// structure will not behave correctly.
	d2i_X509_AUX :: proc(x509: ^^X509, inp: ^^u8, length: c.long) -> ^X509 ---

	// X509_alias_set1 sets |x509|'s alias to |len| bytes from |name|. If |name| is
	// NULL, the alias is cleared instead. Aliases are not part of the certificate
	// itself and will not be serialized by |i2d_X509|. If |x509| is serialized in
	// a PKCS#12 structure, the friendlyName attribute (RFC 2985) will contain this
	// alias.
	X509_alias_set1 :: proc(x509: ^X509, name: ^u8, len: ossl_ssize_t) -> i32 ---

	// X509_keyid_set1 sets |x509|'s key ID to |len| bytes from |id|. If |id| is
	// NULL, the key ID is cleared instead. Key IDs are not part of the certificate
	// itself and will not be serialized by |i2d_X509|.
	X509_keyid_set1 :: proc(x509: ^X509, id: ^u8, len: ossl_ssize_t) -> i32 ---

	// X509_alias_get0 looks up |x509|'s alias. If found, it sets |*out_len| to the
	// alias's length and returns a pointer to a buffer containing the contents. If
	// not found, it outputs the empty string by returning NULL and setting
	// |*out_len| to zero.
	//
	// If |x509| was parsed from a PKCS#12 structure (see
	// |PKCS12_get_key_and_certs|), the alias will reflect the friendlyName
	// attribute (RFC 2985).
	//
	// WARNING: In OpenSSL, this function did not set |*out_len| when the alias was
	// missing. Callers that target both OpenSSL and BoringSSL should set the value
	// to zero before calling this function.
	X509_alias_get0 :: proc(x509: ^X509, out_len: ^i32) -> ^u8 ---

	// X509_keyid_get0 looks up |x509|'s key ID. If found, it sets |*out_len| to the
	// key ID's length and returns a pointer to a buffer containing the contents. If
	// not found, it outputs the empty string by returning NULL and setting
	// |*out_len| to zero.
	//
	// WARNING: In OpenSSL, this function did not set |*out_len| when the alias was
	// missing. Callers that target both OpenSSL and BoringSSL should set the value
	// to zero before calling this function.
	X509_keyid_get0 :: proc(x509: ^X509, out_len: ^i32) -> ^u8 ---

	// X509_add1_trust_object configures |x509| as a valid trust anchor for |obj|.
	// It returns one on success and zero on error. |obj| should be a certificate
	// usage OID associated with an |X509_TRUST_*| constant.
	//
	// See |X509_VERIFY_PARAM_set_trust| for details on how this value is evaluated.
	// Note this only takes effect if |x509| was configured as a trusted certificate
	// via |X509_STORE|.
	X509_add1_trust_object :: proc(x509: ^X509, obj: ^ASN1_OBJECT) -> i32 ---

	// X509_add1_reject_object configures |x509| as distrusted for |obj|. It returns
	// one on success and zero on error. |obj| should be a certificate usage OID
	// associated with an |X509_TRUST_*| constant.
	//
	// See |X509_VERIFY_PARAM_set_trust| for details on how this value is evaluated.
	// Note this only takes effect if |x509| was configured as a trusted certificate
	// via |X509_STORE|.
	X509_add1_reject_object :: proc(x509: ^X509, obj: ^ASN1_OBJECT) -> i32 ---

	// X509_trust_clear clears the list of OIDs for which |x509| is trusted. See
	// also |X509_add1_trust_object|.
	X509_trust_clear :: proc(x509: ^X509) ---

	// X509_reject_clear clears the list of OIDs for which |x509| is distrusted. See
	// also |X509_add1_reject_object|.
	X509_reject_clear :: proc(x509: ^X509) ---
}

sk_X509_CRL_cmp_func           :: proc "c" (^^X509_CRL, ^^X509_CRL) -> i32
sk_X509_CRL_copy_func          :: proc "c" (^X509_CRL) -> ^X509_CRL
sk_X509_CRL_delete_if_func     :: proc "c" (^X509_CRL, rawptr) -> i32
stack_st_X509_CRL              :: struct {}
sk_X509_CRL_free_func          :: proc "c" (^X509_CRL)
sk_X509_REVOKED_cmp_func       :: proc "c" (^^X509_REVOKED, ^^X509_REVOKED) -> i32
sk_X509_REVOKED_copy_func      :: proc "c" (^X509_REVOKED) -> ^X509_REVOKED
sk_X509_REVOKED_delete_if_func :: proc "c" (^X509_REVOKED, rawptr) -> i32
stack_st_X509_REVOKED          :: struct {}
sk_X509_REVOKED_free_func      :: proc "c" (^X509_REVOKED)

@(default_calling_convention="c")
foreign lib {
	// X509_CRL_up_ref adds one to the reference count of |crl| and returns one.
	X509_CRL_up_ref :: proc(crl: ^X509_CRL) -> i32 ---

	// X509_CRL_dup returns a newly-allocated copy of |crl|, or NULL on error. This
	// function works by serializing the structure, so if |crl| is incomplete, it
	// may fail.
	X509_CRL_dup :: proc(crl: ^X509_CRL) -> ^X509_CRL ---

	// X509_CRL_free decrements |crl|'s reference count and, if zero, releases
	// memory associated with |crl|.
	X509_CRL_free :: proc(crl: ^X509_CRL) ---

	// d2i_X509_CRL parses up to |len| bytes from |*inp| as a DER-encoded X.509
	// CertificateList (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_X509_CRL :: proc(out: ^^X509_CRL, inp: ^^u8, len: c.long) -> ^X509_CRL ---

	// i2d_X509_CRL marshals |crl| as a X.509 CertificateList (RFC 5280), as
	// described in |i2d_SAMPLE|.
	i2d_X509_CRL :: proc(crl: ^X509_CRL, outp: ^^u8) -> i32 ---

	// X509_CRL_match compares |a| and |b| and returns zero if they are equal, a
	// negative number if |b| sorts after |a| and a negative number if |a| sorts
	// after |b|. The sort order implemented by this function is arbitrary and does
	// not reflect properties of the CRL such as expiry. Applications should not
	// rely on the order itself.
	//
	// TODO(https://crbug.com/boringssl/355): This function works by comparing a
	// cached hash of the encoded CRL. This cached hash is computed when the CRL is
	// parsed, but not when mutating or issuing CRLs. This function should only be
	// used with |X509_CRL| objects that were parsed from bytes and never mutated.
	X509_CRL_match :: proc(a: ^X509_CRL, b: ^X509_CRL) -> i32 ---
}

X509_CRL_VERSION_1 :: 0
X509_CRL_VERSION_2 :: 1

@(default_calling_convention="c")
foreign lib {
	// X509_CRL_get_version returns the numerical value of |crl|'s version, which
	// will be one of the |X509_CRL_VERSION_*| constants.
	X509_CRL_get_version :: proc(crl: ^X509_CRL) -> c.long ---

	// X509_CRL_get0_lastUpdate returns |crl|'s thisUpdate time. The OpenSSL API
	// refers to this field as lastUpdate.
	X509_CRL_get0_lastUpdate :: proc(crl: ^X509_CRL) -> ^ASN1_TIME ---

	// X509_CRL_get0_nextUpdate returns |crl|'s nextUpdate time, or NULL if |crl|
	// has none.
	X509_CRL_get0_nextUpdate :: proc(crl: ^X509_CRL) -> ^ASN1_TIME ---

	// X509_CRL_get_issuer returns |crl|'s issuer name. Note this function is not
	// const-correct for legacy reasons.
	X509_CRL_get_issuer :: proc(crl: ^X509_CRL) -> ^X509_NAME ---

	// X509_CRL_get0_by_serial finds the entry in |crl| whose serial number is
	// |serial|. If found, it sets |*out| to the entry and returns one. If not
	// found, it returns zero.
	//
	// On success, |*out| continues to be owned by |crl|. It is an error to free or
	// otherwise modify |*out|.
	//
	// TODO(crbug.com/boringssl/600): Ideally |crl| would be const. It is broadly
	// thread-safe, but changes the order of entries in |crl|. It cannot be called
	// concurrently with |i2d_X509_CRL|.
	X509_CRL_get0_by_serial :: proc(crl: ^X509_CRL, out: ^^X509_REVOKED, serial: ^ASN1_INTEGER) -> i32 ---

	// X509_CRL_get0_by_cert behaves like |X509_CRL_get0_by_serial|, except it looks
	// for the entry that matches |x509|.
	X509_CRL_get0_by_cert :: proc(crl: ^X509_CRL, out: ^^X509_REVOKED, x509: ^X509) -> i32 ---

	// X509_CRL_get_REVOKED returns the list of revoked certificates in |crl|, or
	// NULL if |crl| omits it.
	//
	// TODO(davidben): This function was originally a macro, without clear const
	// semantics. It should take a const input and give const output, but the latter
	// would break existing callers. For now, we match upstream.
	X509_CRL_get_REVOKED :: proc(crl: ^X509_CRL) -> ^stack_st_X509_REVOKED ---

	// X509_CRL_get0_extensions returns |crl|'s extension list, or NULL if |crl|
	// omits it. A CRL can have extensions on individual entries, which is
	// |X509_REVOKED_get0_extensions|, or on the overall CRL, which is this
	// function.
	X509_CRL_get0_extensions :: proc(crl: ^X509_CRL) -> ^stack_st_X509_EXTENSION ---

	// X509_CRL_get_ext_count returns the number of extensions in |x|.
	X509_CRL_get_ext_count :: proc(x: ^X509_CRL) -> i32 ---

	// X509_CRL_get_ext_by_NID behaves like |X509v3_get_ext_by_NID| but searches for
	// extensions in |x|.
	X509_CRL_get_ext_by_NID :: proc(x: ^X509_CRL, nid: i32, lastpos: i32) -> i32 ---

	// X509_CRL_get_ext_by_OBJ behaves like |X509v3_get_ext_by_OBJ| but searches for
	// extensions in |x|.
	X509_CRL_get_ext_by_OBJ :: proc(x: ^X509_CRL, obj: ^ASN1_OBJECT, lastpos: i32) -> i32 ---

	// X509_CRL_get_ext_by_critical behaves like |X509v3_get_ext_by_critical| but
	// searches for extensions in |x|.
	X509_CRL_get_ext_by_critical :: proc(x: ^X509_CRL, crit: i32, lastpos: i32) -> i32 ---

	// X509_CRL_get_ext returns the extension in |x| at index |loc|, or NULL if
	// |loc| is out of bounds. This function returns a non-const pointer for OpenSSL
	// compatibility, but callers should not mutate the result.
	X509_CRL_get_ext :: proc(x: ^X509_CRL, loc: i32) -> ^X509_EXTENSION ---

	// X509_CRL_get_ext_d2i behaves like |X509V3_get_d2i| but looks for the
	// extension in |crl|'s extension list.
	//
	// WARNING: This function is difficult to use correctly. See the documentation
	// for |X509V3_get_d2i| for details.
	X509_CRL_get_ext_d2i :: proc(crl: ^X509_CRL, nid: i32, out_critical: ^i32, out_idx: ^i32) -> rawptr ---

	// X509_CRL_get0_signature sets |*out_sig| and |*out_alg| to the signature and
	// signature algorithm of |crl|, respectively. Either output pointer may be NULL
	// to ignore the value.
	//
	// This function outputs the outer signature algorithm, not the one in the
	// TBSCertList. CRLs with mismatched signature algorithms will successfully
	// parse, but they will be rejected when verifying.
	X509_CRL_get0_signature :: proc(crl: ^X509_CRL, out_sig: ^^ASN1_BIT_STRING, out_alg: ^^X509_ALGOR) ---

	// X509_CRL_get_signature_nid returns the NID corresponding to |crl|'s signature
	// algorithm, or |NID_undef| if the signature algorithm does not correspond to
	// a known NID.
	X509_CRL_get_signature_nid :: proc(crl: ^X509_CRL) -> i32 ---

	// i2d_X509_CRL_tbs serializes the TBSCertList portion of |crl|, as described in
	// |i2d_SAMPLE|.
	//
	// This function preserves the original encoding of the TBSCertList and may not
	// reflect modifications made to |crl|. It may be used to manually verify the
	// signature of an existing CRL. To generate CRLs, use |i2d_re_X509_CRL_tbs|
	// instead.
	i2d_X509_CRL_tbs :: proc(crl: ^X509_CRL, outp: ^^u8) -> i32 ---

	// X509_CRL_verify checks that |crl| has a valid signature by |pkey|. It returns
	// one if the signature is valid and zero otherwise.
	X509_CRL_verify :: proc(crl: ^X509_CRL, pkey: ^EVP_PKEY) -> i32 ---

	// X509_CRL_new returns a newly-allocated, empty |X509_CRL| object, or NULL on
	// error. This object may be filled in and then signed to construct a CRL.
	X509_CRL_new :: proc() -> ^X509_CRL ---

	// X509_CRL_set_version sets |crl|'s version to |version|, which should be one
	// of the |X509_CRL_VERSION_*| constants. It returns one on success and zero on
	// error.
	//
	// If unsure, use |X509_CRL_VERSION_2|. Note that, unlike certificates, CRL
	// versions are only defined up to v2. Callers should not use |X509_VERSION_3|.
	X509_CRL_set_version :: proc(crl: ^X509_CRL, version: c.long) -> i32 ---

	// X509_CRL_set_issuer_name sets |crl|'s issuer to a copy of |name|. It returns
	// one on success and zero on error.
	X509_CRL_set_issuer_name :: proc(crl: ^X509_CRL, name: ^X509_NAME) -> i32 ---

	// X509_CRL_set1_lastUpdate sets |crl|'s thisUpdate time to |tm|. It returns one
	// on success and zero on error. The OpenSSL API refers to this field as
	// lastUpdate.
	X509_CRL_set1_lastUpdate :: proc(crl: ^X509_CRL, tm: ^ASN1_TIME) -> i32 ---

	// X509_CRL_set1_nextUpdate sets |crl|'s nextUpdate time to |tm|. It returns one
	// on success and zero on error.
	X509_CRL_set1_nextUpdate :: proc(crl: ^X509_CRL, tm: ^ASN1_TIME) -> i32 ---

	// X509_CRL_add0_revoked adds |rev| to |crl|. On success, it takes ownership of
	// |rev| and returns one. On error, it returns zero. If this function fails, the
	// caller retains ownership of |rev| and must release it when done.
	X509_CRL_add0_revoked :: proc(crl: ^X509_CRL, rev: ^X509_REVOKED) -> i32 ---

	// X509_CRL_sort sorts the entries in |crl| by serial number. It returns one on
	// success and zero on error.
	X509_CRL_sort :: proc(crl: ^X509_CRL) -> i32 ---

	// X509_CRL_delete_ext removes the extension in |x| at index |loc| and returns
	// the removed extension, or NULL if |loc| was out of bounds. If non-NULL, the
	// caller must release the result with |X509_EXTENSION_free|.
	X509_CRL_delete_ext :: proc(x: ^X509_CRL, loc: i32) -> ^X509_EXTENSION ---

	// X509_CRL_add_ext adds a copy of |ex| to |x|. It returns one on success and
	// zero on failure. The caller retains ownership of |ex| and can release it
	// independently of |x|.
	//
	// The new extension is inserted at index |loc|, shifting extensions to the
	// right. If |loc| is -1 or out of bounds, the new extension is appended to the
	// list.
	X509_CRL_add_ext :: proc(x: ^X509_CRL, ex: ^X509_EXTENSION, loc: i32) -> i32 ---

	// X509_CRL_add1_ext_i2d behaves like |X509V3_add1_i2d| but adds the extension
	// to |x|'s extension list.
	//
	// WARNING: This function may return zero or -1 on error. The caller must also
	// ensure |value|'s type matches |nid|. See the documentation for
	// |X509V3_add1_i2d| for details.
	X509_CRL_add1_ext_i2d :: proc(x: ^X509_CRL, nid: i32, value: rawptr, crit: i32, flags: c.ulong) -> i32 ---

	// X509_CRL_sign signs |crl| with |pkey| and replaces the signature algorithm
	// and signature fields. It returns the length of the signature on success and
	// zero on error. This function uses digest algorithm |md|, or |pkey|'s default
	// if NULL. Other signing parameters use |pkey|'s defaults. To customize them,
	// use |X509_CRL_sign_ctx|.
	X509_CRL_sign :: proc(crl: ^X509_CRL, pkey: ^EVP_PKEY, md: ^EVP_MD) -> i32 ---

	// X509_CRL_sign_ctx signs |crl| with |ctx| and replaces the signature algorithm
	// and signature fields. It returns the length of the signature on success and
	// zero on error. The signature algorithm and parameters come from |ctx|, which
	// must have been initialized with |EVP_DigestSignInit|. The caller should
	// configure the corresponding |EVP_PKEY_CTX| before calling this function.
	//
	// On success or failure, this function mutates |ctx| and resets it to the empty
	// state. Caller should not rely on its contents after the function returns.
	X509_CRL_sign_ctx :: proc(crl: ^X509_CRL, ctx: ^EVP_MD_CTX) -> i32 ---

	// i2d_re_X509_CRL_tbs serializes the TBSCertList portion of |crl|, as described
	// in |i2d_SAMPLE|.
	//
	// This function re-encodes the TBSCertList and may not reflect |crl|'s original
	// encoding. It may be used to manually generate a signature for a new CRL. To
	// verify CRLs, use |i2d_X509_CRL_tbs| instead.
	i2d_re_X509_CRL_tbs :: proc(crl: ^X509_CRL, outp: ^^u8) -> i32 ---

	// X509_CRL_set1_signature_algo sets |crl|'s signature algorithm to |algo| and
	// returns one on success or zero on error. It updates both the signature field
	// of the TBSCertList structure, and the signatureAlgorithm field of the CRL.
	X509_CRL_set1_signature_algo :: proc(crl: ^X509_CRL, algo: ^X509_ALGOR) -> i32 ---

	// X509_CRL_set1_signature_value sets |crl|'s signature to a copy of the
	// |sig_len| bytes pointed by |sig|. It returns one on success and zero on
	// error.
	//
	// Due to a specification error, X.509 CRLs store signatures in ASN.1 BIT
	// STRINGs, but signature algorithms return byte strings rather than bit
	// strings. This function creates a BIT STRING containing a whole number of
	// bytes, with the bit order matching the DER encoding. This matches the
	// encoding used by all X.509 signature algorithms.
	X509_CRL_set1_signature_value :: proc(crl: ^X509_CRL, sig: ^u8, sig_len: c.size_t) -> i32 ---

	// X509_REVOKED_new returns a newly-allocated, empty |X509_REVOKED| object, or
	// NULL on allocation error.
	X509_REVOKED_new :: proc() -> ^X509_REVOKED ---

	// X509_REVOKED_free releases memory associated with |rev|.
	X509_REVOKED_free :: proc(rev: ^X509_REVOKED) ---

	// d2i_X509_REVOKED parses up to |len| bytes from |*inp| as a DER-encoded X.509
	// CRL entry, as described in |d2i_SAMPLE|.
	d2i_X509_REVOKED :: proc(out: ^^X509_REVOKED, inp: ^^u8, len: c.long) -> ^X509_REVOKED ---

	// i2d_X509_REVOKED marshals |alg| as a DER-encoded X.509 CRL entry, as
	// described in |i2d_SAMPLE|.
	i2d_X509_REVOKED :: proc(alg: ^X509_REVOKED, outp: ^^u8) -> i32 ---

	// X509_REVOKED_dup returns a newly-allocated copy of |rev|, or NULL on error.
	// This function works by serializing the structure, so if |rev| is incomplete,
	// it may fail.
	X509_REVOKED_dup :: proc(rev: ^X509_REVOKED) -> ^X509_REVOKED ---

	// X509_REVOKED_get0_serialNumber returns the serial number of the certificate
	// revoked by |revoked|.
	X509_REVOKED_get0_serialNumber :: proc(revoked: ^X509_REVOKED) -> ^ASN1_INTEGER ---

	// X509_REVOKED_set_serialNumber sets |revoked|'s serial number to |serial|. It
	// returns one on success or zero on error.
	X509_REVOKED_set_serialNumber :: proc(revoked: ^X509_REVOKED, serial: ^ASN1_INTEGER) -> i32 ---

	// X509_REVOKED_get0_revocationDate returns the revocation time of the
	// certificate revoked by |revoked|.
	X509_REVOKED_get0_revocationDate :: proc(revoked: ^X509_REVOKED) -> ^ASN1_TIME ---

	// X509_REVOKED_set_revocationDate sets |revoked|'s revocation time to |tm|. It
	// returns one on success or zero on error.
	X509_REVOKED_set_revocationDate :: proc(revoked: ^X509_REVOKED, tm: ^ASN1_TIME) -> i32 ---

	// X509_REVOKED_get0_extensions returns |r|'s extensions list, or NULL if |r|
	// omits it. A CRL can have extensions on individual entries, which is this
	// function, or on the overall CRL, which is |X509_CRL_get0_extensions|.
	X509_REVOKED_get0_extensions :: proc(r: ^X509_REVOKED) -> ^stack_st_X509_EXTENSION ---

	// X509_REVOKED_get_ext_count returns the number of extensions in |x|.
	X509_REVOKED_get_ext_count :: proc(x: ^X509_REVOKED) -> i32 ---

	// X509_REVOKED_get_ext_by_NID behaves like |X509v3_get_ext_by_NID| but searches
	// for extensions in |x|.
	X509_REVOKED_get_ext_by_NID :: proc(x: ^X509_REVOKED, nid: i32, lastpos: i32) -> i32 ---

	// X509_REVOKED_get_ext_by_OBJ behaves like |X509v3_get_ext_by_OBJ| but searches
	// for extensions in |x|.
	X509_REVOKED_get_ext_by_OBJ :: proc(x: ^X509_REVOKED, obj: ^ASN1_OBJECT, lastpos: i32) -> i32 ---

	// X509_REVOKED_get_ext_by_critical behaves like |X509v3_get_ext_by_critical|
	// but searches for extensions in |x|.
	X509_REVOKED_get_ext_by_critical :: proc(x: ^X509_REVOKED, crit: i32, lastpos: i32) -> i32 ---

	// X509_REVOKED_get_ext returns the extension in |x| at index |loc|, or NULL if
	// |loc| is out of bounds. This function returns a non-const pointer for OpenSSL
	// compatibility, but callers should not mutate the result.
	X509_REVOKED_get_ext :: proc(x: ^X509_REVOKED, loc: i32) -> ^X509_EXTENSION ---

	// X509_REVOKED_delete_ext removes the extension in |x| at index |loc| and
	// returns the removed extension, or NULL if |loc| was out of bounds. If
	// non-NULL, the caller must release the result with |X509_EXTENSION_free|.
	X509_REVOKED_delete_ext :: proc(x: ^X509_REVOKED, loc: i32) -> ^X509_EXTENSION ---

	// X509_REVOKED_add_ext adds a copy of |ex| to |x|. It returns one on success
	// and zero on failure. The caller retains ownership of |ex| and can release it
	// independently of |x|.
	//
	// The new extension is inserted at index |loc|, shifting extensions to the
	// right. If |loc| is -1 or out of bounds, the new extension is appended to the
	// list.
	X509_REVOKED_add_ext :: proc(x: ^X509_REVOKED, ex: ^X509_EXTENSION, loc: i32) -> i32 ---

	// X509_REVOKED_get_ext_d2i behaves like |X509V3_get_d2i| but looks for the
	// extension in |revoked|'s extension list.
	//
	// WARNING: This function is difficult to use correctly. See the documentation
	// for |X509V3_get_d2i| for details.
	X509_REVOKED_get_ext_d2i :: proc(revoked: ^X509_REVOKED, nid: i32, out_critical: ^i32, out_idx: ^i32) -> rawptr ---

	// X509_REVOKED_add1_ext_i2d behaves like |X509V3_add1_i2d| but adds the
	// extension to |x|'s extension list.
	//
	// WARNING: This function may return zero or -1 on error. The caller must also
	// ensure |value|'s type matches |nid|. See the documentation for
	// |X509V3_add1_i2d| for details.
	X509_REVOKED_add1_ext_i2d :: proc(x: ^X509_REVOKED, nid: i32, value: rawptr, crit: i32, flags: c.ulong) -> i32 ---

	// X509_REQ_dup returns a newly-allocated copy of |req|, or NULL on error. This
	// function works by serializing the structure, so if |req| is incomplete, it
	// may fail.
	X509_REQ_dup :: proc(req: ^X509_REQ) -> ^X509_REQ ---

	// X509_REQ_free releases memory associated with |req|.
	X509_REQ_free :: proc(req: ^X509_REQ) ---

	// d2i_X509_REQ parses up to |len| bytes from |*inp| as a DER-encoded
	// CertificateRequest (RFC 2986), as described in |d2i_SAMPLE|.
	d2i_X509_REQ :: proc(out: ^^X509_REQ, inp: ^^u8, len: c.long) -> ^X509_REQ ---

	// i2d_X509_REQ marshals |req| as a CertificateRequest (RFC 2986), as described
	// in |i2d_SAMPLE|.
	i2d_X509_REQ :: proc(req: ^X509_REQ, outp: ^^u8) -> i32 ---
}

// X509_REQ_VERSION_1 is the version constant for |X509_REQ| objects. No other
// versions are defined.
X509_REQ_VERSION_1 :: 0

@(default_calling_convention="c")
foreign lib {
	// X509_REQ_get_version returns the numerical value of |req|'s version. This
	// will always be |X509_REQ_VERSION_1| for valid CSRs. For compatibility,
	// |d2i_X509_REQ| also accepts some invalid version numbers, in which case this
	// function may return other values.
	X509_REQ_get_version :: proc(req: ^X509_REQ) -> c.long ---

	// X509_REQ_get_subject_name returns |req|'s subject name. Note this function is
	// not const-correct for legacy reasons.
	X509_REQ_get_subject_name :: proc(req: ^X509_REQ) -> ^X509_NAME ---

	// X509_REQ_get0_pubkey returns |req|'s public key as an |EVP_PKEY|, or NULL if
	// the public key was unsupported or could not be decoded. The |EVP_PKEY| is
	// cached in |req|, so callers must not mutate the result.
	X509_REQ_get0_pubkey :: proc(req: ^X509_REQ) -> ^EVP_PKEY ---

	// X509_REQ_get_pubkey behaves like |X509_REQ_get0_pubkey| but increments the
	// reference count on the |EVP_PKEY|. The caller must release the result with
	// |EVP_PKEY_free| when done. The |EVP_PKEY| is cached in |req|, so callers must
	// not mutate the result.
	X509_REQ_get_pubkey :: proc(req: ^X509_REQ) -> ^EVP_PKEY ---

	// X509_REQ_check_private_key returns one if |req|'s public key matches |pkey|
	// and zero otherwise.
	X509_REQ_check_private_key :: proc(req: ^X509_REQ, pkey: ^EVP_PKEY) -> i32 ---

	// X509_REQ_get_attr_count returns the number of attributes in |req|.
	X509_REQ_get_attr_count :: proc(req: ^X509_REQ) -> i32 ---

	// X509_REQ_get_attr returns the attribute at index |loc| in |req|, or NULL if
	// out of bounds.
	X509_REQ_get_attr :: proc(req: ^X509_REQ, loc: i32) -> ^X509_ATTRIBUTE ---

	// X509_REQ_get_attr_by_NID returns the index of the attribute in |req| of type
	// |nid|, or a negative number if not found. If found, callers can use
	// |X509_REQ_get_attr| to look up the attribute by index.
	//
	// If |lastpos| is non-negative, it begins searching at |lastpos| + 1. Callers
	// can thus loop over all matching attributes by first passing -1 and then
	// passing the previously-returned value until no match is returned.
	X509_REQ_get_attr_by_NID :: proc(req: ^X509_REQ, nid: i32, lastpos: i32) -> i32 ---

	// X509_REQ_get_attr_by_OBJ behaves like |X509_REQ_get_attr_by_NID| but looks
	// for attributes of type |obj|.
	X509_REQ_get_attr_by_OBJ :: proc(req: ^X509_REQ, obj: ^ASN1_OBJECT, lastpos: i32) -> i32 ---

	// X509_REQ_extension_nid returns one if |nid| is a supported CSR attribute type
	// for carrying extensions and zero otherwise. The supported types are
	// |NID_ext_req| (pkcs-9-at-extensionRequest from RFC 2985) and |NID_ms_ext_req|
	// (a Microsoft szOID_CERT_EXTENSIONS variant).
	X509_REQ_extension_nid :: proc(nid: i32) -> i32 ---

	// X509_REQ_get_extensions decodes the most preferred list of requested
	// extensions in |req| and returns a newly-allocated |STACK_OF(X509_EXTENSION)|
	// containing the result. It returns NULL on error, or if |req| did not request
	// extensions.
	//
	// CSRs do not store extensions directly. Instead there are attribute types
	// which are defined to hold extensions. See |X509_REQ_extension_nid|. This
	// function supports both pkcs-9-at-extensionRequest from RFC 2985 and the
	// Microsoft szOID_CERT_EXTENSIONS variant. If both are present,
	// pkcs-9-at-extensionRequest is preferred.
	X509_REQ_get_extensions :: proc(req: ^X509_REQ) -> ^stack_st_X509_EXTENSION ---

	// X509_REQ_get0_signature sets |*out_sig| and |*out_alg| to the signature and
	// signature algorithm of |req|, respectively. Either output pointer may be NULL
	// to ignore the value.
	X509_REQ_get0_signature :: proc(req: ^X509_REQ, out_sig: ^^ASN1_BIT_STRING, out_alg: ^^X509_ALGOR) ---

	// X509_REQ_get_signature_nid returns the NID corresponding to |req|'s signature
	// algorithm, or |NID_undef| if the signature algorithm does not correspond to
	// a known NID.
	X509_REQ_get_signature_nid :: proc(req: ^X509_REQ) -> i32 ---

	// X509_REQ_verify checks that |req| has a valid signature by |pkey|. It returns
	// one if the signature is valid and zero otherwise.
	X509_REQ_verify :: proc(req: ^X509_REQ, pkey: ^EVP_PKEY) -> i32 ---

	// X509_REQ_get1_email returns a newly-allocated list of NUL-terminated strings
	// containing all email addresses in |req|'s subject and all rfc822name names
	// in |req|'s subject alternative names. The subject alternative names extension
	// is extracted from the result of |X509_REQ_get_extensions|. Email addresses
	// which contain embedded NUL bytes are skipped.
	//
	// On error, or if there are no such email addresses, it returns NULL. When
	// done, the caller must release the result with |X509_email_free|.
	X509_REQ_get1_email :: proc(req: ^X509_REQ) -> ^stack_st_OPENSSL_STRING ---

	// X509_REQ_new returns a newly-allocated, empty |X509_REQ| object, or NULL on
	// error. This object may be filled in and then signed to construct a CSR.
	X509_REQ_new :: proc() -> ^X509_REQ ---

	// X509_REQ_set_version sets |req|'s version to |version|, which should be
	// |X509_REQ_VERSION_1|. It returns one on success and zero on error.
	//
	// The only defined CSR version is |X509_REQ_VERSION_1|, so there is no need to
	// call this function.
	X509_REQ_set_version :: proc(req: ^X509_REQ, version: c.long) -> i32 ---

	// X509_REQ_set_subject_name sets |req|'s subject to a copy of |name|. It
	// returns one on success and zero on error.
	X509_REQ_set_subject_name :: proc(req: ^X509_REQ, name: ^X509_NAME) -> i32 ---

	// X509_REQ_set_pubkey sets |req|'s public key to |pkey|. It returns one on
	// success and zero on error. This function does not take ownership of |pkey|
	// and internally copies and updates reference counts as needed.
	X509_REQ_set_pubkey :: proc(req: ^X509_REQ, pkey: ^EVP_PKEY) -> i32 ---

	// X509_REQ_delete_attr removes the attribute at index |loc| in |req|. It
	// returns the removed attribute to the caller, or NULL if |loc| was out of
	// bounds. If non-NULL, the caller must release the result with
	// |X509_ATTRIBUTE_free| when done. It is also safe, but not necessary, to call
	// |X509_ATTRIBUTE_free| if the result is NULL.
	X509_REQ_delete_attr :: proc(req: ^X509_REQ, loc: i32) -> ^X509_ATTRIBUTE ---

	// X509_REQ_add1_attr appends a copy of |attr| to |req|'s list of attributes. It
	// returns one on success and zero on error.
	X509_REQ_add1_attr :: proc(req: ^X509_REQ, attr: ^X509_ATTRIBUTE) -> i32 ---

	// X509_REQ_add1_attr_by_OBJ appends a new attribute to |req| with type |obj|.
	// It returns one on success and zero on error. The value is determined by
	// |X509_ATTRIBUTE_set1_data|.
	//
	// WARNING: The interpretation of |attrtype|, |data|, and |len| is complex and
	// error-prone. See |X509_ATTRIBUTE_set1_data| for details.
	X509_REQ_add1_attr_by_OBJ :: proc(req: ^X509_REQ, obj: ^ASN1_OBJECT, attrtype: i32, data: ^u8, len: i32) -> i32 ---

	// X509_REQ_add1_attr_by_NID behaves like |X509_REQ_add1_attr_by_OBJ| except the
	// attribute type is determined by |nid|.
	X509_REQ_add1_attr_by_NID :: proc(req: ^X509_REQ, nid: i32, attrtype: i32, data: ^u8, len: i32) -> i32 ---

	// X509_REQ_add1_attr_by_txt behaves like |X509_REQ_add1_attr_by_OBJ| except the
	// attribute type is determined by calling |OBJ_txt2obj| with |attrname|.
	X509_REQ_add1_attr_by_txt :: proc(req: ^X509_REQ, attrname: cstring, attrtype: i32, data: ^u8, len: i32) -> i32 ---

	// X509_REQ_add_extensions_nid adds an attribute to |req| of type |nid|, to
	// request the certificate extensions in |exts|. It returns one on success and
	// zero on error. |nid| should be |NID_ext_req| or |NID_ms_ext_req|.
	X509_REQ_add_extensions_nid :: proc(req: ^X509_REQ, exts: ^stack_st_X509_EXTENSION, nid: i32) -> i32 ---

	// X509_REQ_add_extensions behaves like |X509_REQ_add_extensions_nid|, using the
	// standard |NID_ext_req| for the attribute type.
	X509_REQ_add_extensions :: proc(req: ^X509_REQ, exts: ^stack_st_X509_EXTENSION) -> i32 ---

	// X509_REQ_sign signs |req| with |pkey| and replaces the signature algorithm
	// and signature fields. It returns the length of the signature on success and
	// zero on error. This function uses digest algorithm |md|, or |pkey|'s default
	// if NULL. Other signing parameters use |pkey|'s defaults. To customize them,
	// use |X509_REQ_sign_ctx|.
	X509_REQ_sign :: proc(req: ^X509_REQ, pkey: ^EVP_PKEY, md: ^EVP_MD) -> i32 ---

	// X509_REQ_sign_ctx signs |req| with |ctx| and replaces the signature algorithm
	// and signature fields. It returns the length of the signature on success and
	// zero on error. The signature algorithm and parameters come from |ctx|, which
	// must have been initialized with |EVP_DigestSignInit|. The caller should
	// configure the corresponding |EVP_PKEY_CTX| before calling this function.
	//
	// On success or failure, this function mutates |ctx| and resets it to the empty
	// state. Caller should not rely on its contents after the function returns.
	X509_REQ_sign_ctx :: proc(req: ^X509_REQ, ctx: ^EVP_MD_CTX) -> i32 ---

	// i2d_re_X509_REQ_tbs serializes the CertificationRequestInfo (see RFC 2986)
	// portion of |req|, as described in |i2d_SAMPLE|.
	//
	// This function re-encodes the CertificationRequestInfo and may not reflect
	// |req|'s original encoding. It may be used to manually generate a signature
	// for a new certificate request.
	i2d_re_X509_REQ_tbs :: proc(req: ^X509_REQ, outp: ^^u8) -> i32 ---

	// X509_REQ_set1_signature_algo sets |req|'s signature algorithm to |algo| and
	// returns one on success or zero on error.
	X509_REQ_set1_signature_algo :: proc(req: ^X509_REQ, algo: ^X509_ALGOR) -> i32 ---

	// X509_REQ_set1_signature_value sets |req|'s signature to a copy of the
	// |sig_len| bytes pointed by |sig|. It returns one on success and zero on
	// error.
	//
	// Due to a specification error, PKCS#10 certificate requests store signatures
	// in ASN.1 BIT STRINGs, but signature algorithms return byte strings rather
	// than bit strings. This function creates a BIT STRING containing a whole
	// number of bytes, with the bit order matching the DER encoding. This matches
	// the encoding used by all X.509 signature algorithms.
	X509_REQ_set1_signature_value :: proc(req: ^X509_REQ, sig: ^u8, sig_len: c.size_t) -> i32 ---
}

sk_X509_NAME_ENTRY_delete_if_func :: proc "c" (^X509_NAME_ENTRY, rawptr) -> i32
sk_X509_NAME_ENTRY_free_func      :: proc "c" (^X509_NAME_ENTRY)
stack_st_X509_NAME_ENTRY          :: struct {}
sk_X509_NAME_ENTRY_copy_func      :: proc "c" (^X509_NAME_ENTRY) -> ^X509_NAME_ENTRY
sk_X509_NAME_ENTRY_cmp_func       :: proc "c" (^^X509_NAME_ENTRY, ^^X509_NAME_ENTRY) -> i32
sk_X509_NAME_delete_if_func       :: proc "c" (^X509_NAME, rawptr) -> i32
sk_X509_NAME_copy_func            :: proc "c" (^X509_NAME) -> ^X509_NAME
stack_st_X509_NAME                :: struct {}
sk_X509_NAME_free_func            :: proc "c" (^X509_NAME)
sk_X509_NAME_cmp_func             :: proc "c" (^^X509_NAME, ^^X509_NAME) -> i32

@(default_calling_convention="c")
foreign lib {
	// X509_NAME_new returns a new, empty |X509_NAME|, or NULL on error.
	X509_NAME_new :: proc() -> ^X509_NAME ---

	// X509_NAME_free releases memory associated with |name|.
	X509_NAME_free :: proc(name: ^X509_NAME) ---

	// d2i_X509_NAME parses up to |len| bytes from |*inp| as a DER-encoded X.509
	// Name (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_X509_NAME :: proc(out: ^^X509_NAME, inp: ^^u8, len: c.long) -> ^X509_NAME ---

	// i2d_X509_NAME marshals |in| as a DER-encoded X.509 Name (RFC 5280), as
	// described in |i2d_SAMPLE|.
	i2d_X509_NAME :: proc(_in: ^X509_NAME, outp: ^^u8) -> i32 ---

	// X509_NAME_dup returns a newly-allocated copy of |name|, or NULL on error.
	X509_NAME_dup :: proc(name: ^X509_NAME) -> ^X509_NAME ---

	// X509_NAME_cmp compares |a| and |b|'s canonicalized forms. It returns zero if
	// they are equal, one if |a| sorts after |b|, -1 if |b| sorts after |a|, and -2
	// on error.
	//
	// TODO(https://crbug.com/boringssl/355): The -2 return is very inconvenient to
	// pass to a sorting function. Can we make this infallible? In the meantime,
	// prefer to use this function only for equality checks rather than comparisons.
	// Although even the library itself passes this to a sorting function.
	X509_NAME_cmp :: proc(a: ^X509_NAME, b: ^X509_NAME) -> i32 ---

	// X509_NAME_get0_der marshals |name| as a DER-encoded X.509 Name (RFC 5280). On
	// success, it returns one and sets |*out_der| and |*out_der_len| to a buffer
	// containing the result. Otherwise, it returns zero. |*out_der| is owned by
	// |name| and must not be freed by the caller. It is invalidated after |name| is
	// mutated or freed.
	X509_NAME_get0_der :: proc(name: ^X509_NAME, out_der: ^^u8, out_der_len: ^c.size_t) -> i32 ---

	// X509_NAME_set makes a copy of |name|. On success, it frees |*xn|, sets |*xn|
	// to the copy, and returns one. Otherwise, it returns zero.
	X509_NAME_set :: proc(xn: ^^X509_NAME, name: ^X509_NAME) -> i32 ---

	// X509_NAME_entry_count returns the number of entries in |name|.
	X509_NAME_entry_count :: proc(name: ^X509_NAME) -> i32 ---

	// X509_NAME_get_index_by_NID returns the zero-based index of the first
	// attribute in |name| with type |nid|, or -1 if there is none. |nid| should be
	// one of the |NID_*| constants. If |lastpos| is non-negative, it begins
	// searching at |lastpos+1|. To search all attributes, pass in -1, not zero.
	//
	// Indices from this function refer to |X509_NAME|'s flattened representation.
	X509_NAME_get_index_by_NID :: proc(name: ^X509_NAME, nid: i32, lastpos: i32) -> i32 ---

	// X509_NAME_get_index_by_OBJ behaves like |X509_NAME_get_index_by_NID| but
	// looks for attributes with type |obj|.
	X509_NAME_get_index_by_OBJ :: proc(name: ^X509_NAME, obj: ^ASN1_OBJECT, lastpos: i32) -> i32 ---

	// X509_NAME_get_entry returns the attribute in |name| at index |loc|, or NULL
	// if |loc| is out of range. |loc| is interpreted using |X509_NAME|'s flattened
	// representation. This function returns a non-const pointer for OpenSSL
	// compatibility, but callers should not mutate the result. Doing so will break
	// internal invariants in the library.
	X509_NAME_get_entry :: proc(name: ^X509_NAME, loc: i32) -> ^X509_NAME_ENTRY ---

	// X509_NAME_delete_entry removes and returns the attribute in |name| at index
	// |loc|, or NULL if |loc| is out of range. |loc| is interpreted using
	// |X509_NAME|'s flattened representation. If the attribute is found, the caller
	// is responsible for releasing the result with |X509_NAME_ENTRY_free|.
	//
	// This function will internally update RDN indices (see |X509_NAME_ENTRY_set|)
	// so they continue to be consecutive.
	X509_NAME_delete_entry :: proc(name: ^X509_NAME, loc: i32) -> ^X509_NAME_ENTRY ---

	// X509_NAME_add_entry adds a copy of |entry| to |name| and returns one on
	// success or zero on error. If |loc| is -1, the entry is appended to |name|.
	// Otherwise, it is inserted at index |loc|. If |set| is -1, the entry is added
	// to the previous entry's RDN. If it is 0, the entry becomes a singleton RDN.
	// If 1, it is added to next entry's RDN.
	//
	// This function will internally update RDN indices (see |X509_NAME_ENTRY_set|)
	// so they continue to be consecutive.
	X509_NAME_add_entry :: proc(name: ^X509_NAME, entry: ^X509_NAME_ENTRY, loc: i32, set: i32) -> i32 ---

	// X509_NAME_add_entry_by_OBJ adds a new entry to |name| and returns one on
	// success or zero on error. The entry's attribute type is |obj|. The entry's
	// attribute value is determined by |type|, |bytes|, and |len|, as in
	// |X509_NAME_ENTRY_set_data|. The entry's position is determined by |loc| and
	// |set| as in |X509_NAME_add_entry|.
	X509_NAME_add_entry_by_OBJ :: proc(name: ^X509_NAME, obj: ^ASN1_OBJECT, type: i32, bytes: ^u8, len: ossl_ssize_t, loc: i32, set: i32) -> i32 ---

	// X509_NAME_add_entry_by_NID behaves like |X509_NAME_add_entry_by_OBJ| but sets
	// the entry's attribute type to |nid|, which should be one of the |NID_*|
	// constants.
	X509_NAME_add_entry_by_NID :: proc(name: ^X509_NAME, nid: i32, type: i32, bytes: ^u8, len: ossl_ssize_t, loc: i32, set: i32) -> i32 ---

	// X509_NAME_add_entry_by_txt behaves like |X509_NAME_add_entry_by_OBJ| but sets
	// the entry's attribute type to |field|, which is passed to |OBJ_txt2obj|.
	X509_NAME_add_entry_by_txt :: proc(name: ^X509_NAME, field: cstring, type: i32, bytes: ^u8, len: ossl_ssize_t, loc: i32, set: i32) -> i32 ---

	// X509_NAME_ENTRY_new returns a new, empty |X509_NAME_ENTRY|, or NULL on error.
	X509_NAME_ENTRY_new :: proc() -> ^X509_NAME_ENTRY ---

	// X509_NAME_ENTRY_free releases memory associated with |entry|.
	X509_NAME_ENTRY_free :: proc(entry: ^X509_NAME_ENTRY) ---

	// X509_NAME_ENTRY_dup returns a newly-allocated copy of |entry|, or NULL on
	// error.
	X509_NAME_ENTRY_dup :: proc(entry: ^X509_NAME_ENTRY) -> ^X509_NAME_ENTRY ---

	// X509_NAME_ENTRY_get_object returns |entry|'s attribute type. This function
	// returns a non-const pointer for OpenSSL compatibility, but callers should not
	// mutate the result. Doing so will break internal invariants in the library.
	X509_NAME_ENTRY_get_object :: proc(entry: ^X509_NAME_ENTRY) -> ^ASN1_OBJECT ---

	// X509_NAME_ENTRY_set_object sets |entry|'s attribute type to |obj|. It returns
	// one on success and zero on error.
	X509_NAME_ENTRY_set_object :: proc(entry: ^X509_NAME_ENTRY, obj: ^ASN1_OBJECT) -> i32 ---

	// X509_NAME_ENTRY_get_data returns |entry|'s attribute value, represented as an
	// |ASN1_STRING|. This value may have any ASN.1 type, so callers must check the
	// type before interpreting the contents. This function returns a non-const
	// pointer for OpenSSL compatibility, but callers should not mutate the result.
	// Doing so will break internal invariants in the library.
	//
	// See |ASN1_STRING| for how values are represented in this library. Where a
	// specific |ASN1_STRING| representation exists, that representation is used.
	// Otherwise, the |V_ASN1_OTHER| representation is used. Note that NULL, OBJECT
	// IDENTIFIER, and BOOLEAN attribute values are represented as |V_ASN1_OTHER|,
	// because their usual representation in this library is not
	// |ASN1_STRING|-compatible.
	X509_NAME_ENTRY_get_data :: proc(entry: ^X509_NAME_ENTRY) -> ^ASN1_STRING ---

	// X509_NAME_ENTRY_set_data sets |entry|'s value to |len| bytes from |bytes|. It
	// returns one on success and zero on error. If |len| is -1, |bytes| must be a
	// NUL-terminated C string and the length is determined by |strlen|. |bytes| is
	// converted to an ASN.1 type as follows:
	//
	// If |type| is a |MBSTRING_*| constant, the value is an ASN.1 string. The
	// string is determined by decoding |bytes| in the encoding specified by |type|,
	// and then re-encoding it in a form appropriate for |entry|'s attribute type.
	// See |ASN1_STRING_set_by_NID| for details.
	//
	// Otherwise, the value is an |ASN1_STRING| with type |type| and value |bytes|.
	// See |ASN1_STRING| for how to format ASN.1 types as an |ASN1_STRING|. If
	// |type| is |V_ASN1_UNDEF| the previous |ASN1_STRING| type is reused.
	X509_NAME_ENTRY_set_data :: proc(entry: ^X509_NAME_ENTRY, type: i32, bytes: ^u8, len: ossl_ssize_t) -> i32 ---

	// X509_NAME_ENTRY_set returns the zero-based index of the RDN which contains
	// |entry|. Consecutive entries with the same index are part of the same RDN.
	X509_NAME_ENTRY_set :: proc(entry: ^X509_NAME_ENTRY) -> i32 ---

	// X509_NAME_ENTRY_create_by_OBJ creates a new |X509_NAME_ENTRY| with attribute
	// type |obj|. The attribute value is determined from |type|, |bytes|, and |len|
	// as in |X509_NAME_ENTRY_set_data|. It returns the |X509_NAME_ENTRY| on success
	// and NULL on error.
	//
	// If |out| is non-NULL and |*out| is NULL, it additionally sets |*out| to the
	// result on success. If both |out| and |*out| are non-NULL, it updates the
	// object at |*out| instead of allocating a new one.
	X509_NAME_ENTRY_create_by_OBJ :: proc(out: ^^X509_NAME_ENTRY, obj: ^ASN1_OBJECT, type: i32, bytes: ^u8, len: ossl_ssize_t) -> ^X509_NAME_ENTRY ---

	// X509_NAME_ENTRY_create_by_NID behaves like |X509_NAME_ENTRY_create_by_OBJ|
	// except the attribute type is |nid|, which should be one of the |NID_*|
	// constants.
	X509_NAME_ENTRY_create_by_NID :: proc(out: ^^X509_NAME_ENTRY, nid: i32, type: i32, bytes: ^u8, len: ossl_ssize_t) -> ^X509_NAME_ENTRY ---

	// X509_NAME_ENTRY_create_by_txt behaves like |X509_NAME_ENTRY_create_by_OBJ|
	// except the attribute type is |field|, which is passed to |OBJ_txt2obj|.
	X509_NAME_ENTRY_create_by_txt :: proc(out: ^^X509_NAME_ENTRY, field: cstring, type: i32, bytes: ^u8, len: ossl_ssize_t) -> ^X509_NAME_ENTRY ---

	// X509_PUBKEY_new returns a newly-allocated, empty |X509_PUBKEY| object, or
	// NULL on error.
	X509_PUBKEY_new :: proc() -> ^X509_PUBKEY ---

	// X509_PUBKEY_free releases memory associated with |key|.
	X509_PUBKEY_free :: proc(key: ^X509_PUBKEY) ---

	// d2i_X509_PUBKEY parses up to |len| bytes from |*inp| as a DER-encoded
	// SubjectPublicKeyInfo, as described in |d2i_SAMPLE|.
	d2i_X509_PUBKEY :: proc(out: ^^X509_PUBKEY, inp: ^^u8, len: c.long) -> ^X509_PUBKEY ---

	// i2d_X509_PUBKEY marshals |key| as a DER-encoded SubjectPublicKeyInfo, as
	// described in |i2d_SAMPLE|.
	i2d_X509_PUBKEY :: proc(key: ^X509_PUBKEY, outp: ^^u8) -> i32 ---

	// X509_PUBKEY_set serializes |pkey| into a newly-allocated |X509_PUBKEY|
	// structure. On success, it frees |*x| if non-NULL, then sets |*x| to the new
	// object, and returns one. Otherwise, it returns zero.
	X509_PUBKEY_set :: proc(x: ^^X509_PUBKEY, pkey: ^EVP_PKEY) -> i32 ---

	// X509_PUBKEY_get0 returns |key| as an |EVP_PKEY|, or NULL if |key| either
	// could not be parsed or is an unrecognized algorithm. The |EVP_PKEY| is cached
	// in |key|, so callers must not mutate the result.
	X509_PUBKEY_get0 :: proc(key: ^X509_PUBKEY) -> ^EVP_PKEY ---

	// X509_PUBKEY_get behaves like |X509_PUBKEY_get0| but increments the reference
	// count on the |EVP_PKEY|. The caller must release the result with
	// |EVP_PKEY_free| when done. The |EVP_PKEY| is cached in |key|, so callers must
	// not mutate the result.
	X509_PUBKEY_get :: proc(key: ^X509_PUBKEY) -> ^EVP_PKEY ---

	// X509_PUBKEY_set0_param sets |pub| to a key with AlgorithmIdentifier
	// determined by |obj|, |param_type|, and |param_value|, and an encoded
	// public key of |key|. On success, it gives |pub| ownership of all the other
	// parameters and returns one. Otherwise, it returns zero. |key| must have been
	// allocated by |OPENSSL_malloc|. |obj| and, if applicable, |param_value| must
	// not be freed after a successful call, and must have been allocated in a
	// manner compatible with |ASN1_OBJECT_free| or |ASN1_STRING_free|.
	//
	// |obj|, |param_type|, and |param_value| are interpreted as in
	// |X509_ALGOR_set0|. See |X509_ALGOR_set0| for details.
	X509_PUBKEY_set0_param :: proc(pub: ^X509_PUBKEY, obj: ^ASN1_OBJECT, param_type: i32, param_value: rawptr, key: ^u8, key_len: i32) -> i32 ---

	// X509_PUBKEY_get0_param outputs fields of |pub| and returns one. If |out_obj|
	// is not NULL, it sets |*out_obj| to AlgorithmIdentifier's OID. If |out_key|
	// is not NULL, it sets |*out_key| and |*out_key_len| to the encoded public key.
	// If |out_alg| is not NULL, it sets |*out_alg| to the AlgorithmIdentifier.
	//
	// All pointers outputted by this function are internal to |pub| and must not be
	// freed by the caller. Additionally, although some outputs are non-const,
	// callers must not mutate the resulting objects.
	//
	// Note: X.509 SubjectPublicKeyInfo structures store the encoded public key as a
	// BIT STRING. |*out_key| and |*out_key_len| will silently pad the key with zero
	// bits if |pub| did not contain a whole number of bytes. Use
	// |X509_PUBKEY_get0_public_key| to preserve this information.
	X509_PUBKEY_get0_param :: proc(out_obj: ^^ASN1_OBJECT, out_key: ^^u8, out_key_len: ^i32, out_alg: ^^X509_ALGOR, pub: ^X509_PUBKEY) -> i32 ---

	// X509_PUBKEY_get0_public_key returns |pub|'s encoded public key.
	X509_PUBKEY_get0_public_key :: proc(pub: ^X509_PUBKEY) -> ^ASN1_BIT_STRING ---

	// X509_EXTENSION_new returns a newly-allocated, empty |X509_EXTENSION| object
	// or NULL on error.
	X509_EXTENSION_new :: proc() -> ^X509_EXTENSION ---

	// X509_EXTENSION_free releases memory associated with |ex|.
	X509_EXTENSION_free :: proc(ex: ^X509_EXTENSION) ---

	// d2i_X509_EXTENSION parses up to |len| bytes from |*inp| as a DER-encoded
	// X.509 Extension (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_X509_EXTENSION :: proc(out: ^^X509_EXTENSION, inp: ^^u8, len: c.long) -> ^X509_EXTENSION ---

	// i2d_X509_EXTENSION marshals |ex| as a DER-encoded X.509 Extension (RFC
	// 5280), as described in |i2d_SAMPLE|.
	i2d_X509_EXTENSION :: proc(ex: ^X509_EXTENSION, outp: ^^u8) -> i32 ---

	// X509_EXTENSION_dup returns a newly-allocated copy of |ex|, or NULL on error.
	// This function works by serializing the structure, so if |ex| is incomplete,
	// it may fail.
	X509_EXTENSION_dup :: proc(ex: ^X509_EXTENSION) -> ^X509_EXTENSION ---

	// X509_EXTENSION_create_by_NID creates a new |X509_EXTENSION| with type |nid|,
	// value |data|, and critical bit |crit|. It returns an |X509_EXTENSION| on
	// success, and NULL on error. |nid| should be a |NID_*| constant.
	//
	// If |ex| and |*ex| are both non-NULL, |*ex| is used to hold the result,
	// otherwise a new object is allocated. If |ex| is non-NULL and |*ex| is NULL,
	// the function sets |*ex| to point to the newly allocated result, in addition
	// to returning the result.
	X509_EXTENSION_create_by_NID :: proc(ex: ^^X509_EXTENSION, nid: i32, crit: i32, data: ^ASN1_OCTET_STRING) -> ^X509_EXTENSION ---

	// X509_EXTENSION_create_by_OBJ behaves like |X509_EXTENSION_create_by_NID|, but
	// the extension type is determined by an |ASN1_OBJECT|.
	X509_EXTENSION_create_by_OBJ :: proc(ex: ^^X509_EXTENSION, obj: ^ASN1_OBJECT, crit: i32, data: ^ASN1_OCTET_STRING) -> ^X509_EXTENSION ---

	// X509_EXTENSION_get_object returns |ex|'s extension type. This function
	// returns a non-const pointer for OpenSSL compatibility, but callers should not
	// mutate the result.
	X509_EXTENSION_get_object :: proc(ex: ^X509_EXTENSION) -> ^ASN1_OBJECT ---

	// X509_EXTENSION_get_data returns |ne|'s extension value. This function returns
	// a non-const pointer for OpenSSL compatibility, but callers should not mutate
	// the result.
	X509_EXTENSION_get_data :: proc(ne: ^X509_EXTENSION) -> ^ASN1_OCTET_STRING ---

	// X509_EXTENSION_get_critical returns one if |ex| is critical and zero
	// otherwise.
	X509_EXTENSION_get_critical :: proc(ex: ^X509_EXTENSION) -> i32 ---

	// X509_EXTENSION_set_object sets |ex|'s extension type to |obj|. It returns one
	// on success and zero on error.
	X509_EXTENSION_set_object :: proc(ex: ^X509_EXTENSION, obj: ^ASN1_OBJECT) -> i32 ---

	// X509_EXTENSION_set_critical sets |ex| to critical if |crit| is non-zero and
	// to non-critical if |crit| is zero.
	X509_EXTENSION_set_critical :: proc(ex: ^X509_EXTENSION, crit: i32) -> i32 ---

	// X509_EXTENSION_set_data set's |ex|'s extension value to a copy of |data|. It
	// returns one on success and zero on error.
	X509_EXTENSION_set_data :: proc(ex: ^X509_EXTENSION, data: ^ASN1_OCTET_STRING) -> i32 ---
}

sk_X509_EXTENSION_delete_if_func :: proc "c" (^X509_EXTENSION, rawptr) -> i32
sk_X509_EXTENSION_free_func      :: proc "c" (^X509_EXTENSION)
sk_X509_EXTENSION_copy_func      :: proc "c" (^X509_EXTENSION) -> ^X509_EXTENSION
sk_X509_EXTENSION_cmp_func       :: proc "c" (^^X509_EXTENSION, ^^X509_EXTENSION) -> i32

// Extension lists.
//
// The following functions manipulate lists of extensions. Most of them have
// corresponding functions on the containing |X509|, |X509_CRL|, or
// |X509_REVOKED|.
X509_EXTENSIONS :: stack_st_X509_EXTENSION

@(default_calling_convention="c")
foreign lib {
	// d2i_X509_EXTENSIONS parses up to |len| bytes from |*inp| as a DER-encoded
	// SEQUENCE OF Extension (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_X509_EXTENSIONS :: proc(out: ^^X509_EXTENSIONS, inp: ^^u8, len: c.long) -> ^X509_EXTENSIONS ---

	// i2d_X509_EXTENSIONS marshals |alg| as a DER-encoded SEQUENCE OF Extension
	// (RFC 5280), as described in |i2d_SAMPLE|.
	i2d_X509_EXTENSIONS :: proc(alg: ^X509_EXTENSIONS, outp: ^^u8) -> i32 ---

	// X509v3_get_ext_count returns the number of extensions in |x|.
	X509v3_get_ext_count :: proc(x: ^stack_st_X509_EXTENSION) -> i32 ---

	// X509v3_get_ext_by_NID returns the index of the first extension in |x| with
	// type |nid|, or a negative number if not found. If found, callers can use
	// |X509v3_get_ext| to look up the extension by index.
	//
	// If |lastpos| is non-negative, it begins searching at |lastpos| + 1. Callers
	// can thus loop over all matching extensions by first passing -1 and then
	// passing the previously-returned value until no match is returned.
	X509v3_get_ext_by_NID :: proc(x: ^stack_st_X509_EXTENSION, nid: i32, lastpos: i32) -> i32 ---

	// X509v3_get_ext_by_OBJ behaves like |X509v3_get_ext_by_NID| but looks for
	// extensions matching |obj|.
	X509v3_get_ext_by_OBJ :: proc(x: ^stack_st_X509_EXTENSION, obj: ^ASN1_OBJECT, lastpos: i32) -> i32 ---

	// X509v3_get_ext_by_critical returns the index of the first extension in |x|
	// whose critical bit matches |crit|, or a negative number if no such extension
	// was found.
	//
	// If |lastpos| is non-negative, it begins searching at |lastpos| + 1. Callers
	// can thus loop over all matching extensions by first passing -1 and then
	// passing the previously-returned value until no match is returned.
	X509v3_get_ext_by_critical :: proc(x: ^stack_st_X509_EXTENSION, crit: i32, lastpos: i32) -> i32 ---

	// X509v3_get_ext returns the extension in |x| at index |loc|, or NULL if |loc|
	// is out of bounds. This function returns a non-const pointer for OpenSSL
	// compatibility, but callers should not mutate the result.
	X509v3_get_ext :: proc(x: ^stack_st_X509_EXTENSION, loc: i32) -> ^X509_EXTENSION ---

	// X509v3_delete_ext removes the extension in |x| at index |loc| and returns the
	// removed extension, or NULL if |loc| was out of bounds. If an extension was
	// returned, the caller must release it with |X509_EXTENSION_free|.
	X509v3_delete_ext :: proc(x: ^stack_st_X509_EXTENSION, loc: i32) -> ^X509_EXTENSION ---

	// X509v3_add_ext adds a copy of |ex| to the extension list in |*x|. If |*x| is
	// NULL, it allocates a new |STACK_OF(X509_EXTENSION)| to hold the copy and sets
	// |*x| to the new list. It returns |*x| on success and NULL on error. The
	// caller retains ownership of |ex| and can release it independently of |*x|.
	//
	// The new extension is inserted at index |loc|, shifting extensions to the
	// right. If |loc| is -1 or out of bounds, the new extension is appended to the
	// list.
	X509v3_add_ext :: proc(x: ^^stack_st_X509_EXTENSION, ex: ^X509_EXTENSION, loc: i32) -> ^stack_st_X509_EXTENSION ---

	// X509V3_EXT_d2i decodes |ext| and returns a pointer to a newly-allocated
	// structure, with type dependent on the type of the extension. It returns NULL
	// if |ext| is an unsupported extension or if there was a syntax error in the
	// extension. The caller should cast the return value to the expected type and
	// free the structure when done.
	//
	// WARNING: Casting the return value to the wrong type is a potentially
	// exploitable memory error, so callers must not use this function before
	// checking |ext| is of a known type. See the list at the top of this section
	// for the correct types.
	X509V3_EXT_d2i :: proc(ext: ^X509_EXTENSION) -> rawptr ---

	// X509V3_get_d2i finds and decodes the extension in |extensions| of type |nid|.
	// If found, it decodes it and returns a newly-allocated structure, with type
	// dependent on |nid|. If the extension is not found or on error, it returns
	// NULL. The caller may distinguish these cases using the |out_critical| value.
	//
	// If |out_critical| is not NULL, this function sets |*out_critical| to one if
	// the extension is found and critical, zero if it is found and not critical, -1
	// if it is not found, and -2 if there is an invalid duplicate extension. Note
	// this function may set |*out_critical| to one or zero and still return NULL if
	// the extension is found but has a syntax error.
	//
	// If |out_idx| is not NULL, this function looks for the first occurrence of the
	// extension after |*out_idx|. It then sets |*out_idx| to the index of the
	// extension, or -1 if not found. If |out_idx| is non-NULL, duplicate extensions
	// are not treated as an error. Callers, however, should not rely on this
	// behavior as it may be removed in the future. Duplicate extensions are
	// forbidden in RFC 5280.
	//
	// WARNING: This function is difficult to use correctly. Callers should pass a
	// non-NULL |out_critical| and check both the return value and |*out_critical|
	// to handle errors. If the return value is NULL and |*out_critical| is not -1,
	// there was an error. Otherwise, the function succeeded and but may return NULL
	// for a missing extension. Callers should pass NULL to |out_idx| so that
	// duplicate extensions are handled correctly.
	//
	// Additionally, casting the return value to the wrong type is a potentially
	// exploitable memory error, so callers must ensure the cast and |nid| match.
	// See the list at the top of this section for the correct types.
	X509V3_get_d2i :: proc(extensions: ^stack_st_X509_EXTENSION, nid: i32, out_critical: ^i32, out_idx: ^i32) -> rawptr ---

	// X509V3_EXT_free casts |ext_data| into the type that corresponds to |nid| and
	// releases memory associated with it. It returns one on success and zero if
	// |nid| is not a known extension.
	//
	// WARNING: Casting |ext_data| to the wrong type is a potentially exploitable
	// memory error, so callers must ensure |ext_data|'s type matches |nid|. See the
	// list at the top of this section for the correct types.
	//
	// TODO(davidben): OpenSSL upstream no longer exposes this function. Remove it?
	X509V3_EXT_free :: proc(nid: i32, ext_data: rawptr) -> i32 ---

	// X509V3_EXT_i2d casts |ext_struc| into the type that corresponds to
	// |ext_nid|, serializes it, and returns a newly-allocated |X509_EXTENSION|
	// object containing the serialization, or NULL on error. The |X509_EXTENSION|
	// has OID |ext_nid| and is critical if |crit| is one.
	//
	// WARNING: Casting |ext_struc| to the wrong type is a potentially exploitable
	// memory error, so callers must ensure |ext_struct|'s type matches |ext_nid|.
	// See the list at the top of this section for the correct types.
	X509V3_EXT_i2d :: proc(ext_nid: i32, crit: i32, ext_struc: rawptr) -> ^X509_EXTENSION ---
}

// The following constants control the behavior of |X509V3_add1_i2d| and related
// functions.

// X509V3_ADD_OP_MASK can be ANDed with the flags to determine how duplicate
// extensions are processed.
X509V3_ADD_OP_MASK :: 0xf

// X509V3_ADD_DEFAULT causes the function to fail if the extension was already
// present.
X509V3_ADD_DEFAULT :: 0

// X509V3_ADD_APPEND causes the function to unconditionally appended the new
// extension to to the extensions list, even if there is a duplicate.
X509V3_ADD_APPEND :: 1

// X509V3_ADD_REPLACE causes the function to replace the existing extension, or
// append if it is not present.
X509V3_ADD_REPLACE :: 2

// X509V3_ADD_REPLACE_EXISTING causes the function to replace the existing
// extension and fail if it is not present.
X509V3_ADD_REPLACE_EXISTING :: 3

// X509V3_ADD_KEEP_EXISTING causes the function to succeed without replacing the
// extension if already present.
X509V3_ADD_KEEP_EXISTING :: 4

// X509V3_ADD_DELETE causes the function to remove the matching extension. No
// new extension is added. If there is no matching extension, the function
// fails. The |value| parameter is ignored in this mode.
X509V3_ADD_DELETE :: 5

// X509V3_ADD_SILENT may be ORed into one of the values above to indicate the
// function should not add to the error queue on duplicate or missing extension.
// The function will continue to return zero in those cases, and it will
// continue to return -1 and add to the error queue on other errors.
X509V3_ADD_SILENT :: 0x10

@(default_calling_convention="c")
foreign lib {
	// X509V3_add1_i2d casts |value| to the type that corresponds to |nid|,
	// serializes it, and appends it to the extension list in |*x|. If |*x| is NULL,
	// it will set |*x| to a newly-allocated |STACK_OF(X509_EXTENSION)| as needed.
	// The |crit| parameter determines whether the new extension is critical.
	// |flags| may be some combination of the |X509V3_ADD_*| constants to control
	// the function's behavior on duplicate extension.
	//
	// This function returns one on success, zero if the operation failed due to a
	// missing or duplicate extension, and -1 on other errors.
	//
	// WARNING: Casting |value| to the wrong type is a potentially exploitable
	// memory error, so callers must ensure |value|'s type matches |nid|. See the
	// list at the top of this section for the correct types.
	X509V3_add1_i2d :: proc(x: ^^stack_st_X509_EXTENSION, nid: i32, value: rawptr, crit: i32, flags: c.ulong) -> i32 ---
}

// A BASIC_CONSTRAINTS_st, aka |BASIC_CONSTRAINTS| represents an
// BasicConstraints structure (RFC 5280).
BASIC_CONSTRAINTS_st :: struct {
	ca:      ASN1_BOOLEAN,
	pathlen: ^ASN1_INTEGER,
}

@(default_calling_convention="c")
foreign lib {
	// BASIC_CONSTRAINTS_new returns a newly-allocated, empty |BASIC_CONSTRAINTS|
	// object, or NULL on error.
	BASIC_CONSTRAINTS_new :: proc() -> ^BASIC_CONSTRAINTS ---

	// BASIC_CONSTRAINTS_free releases memory associated with |bcons|.
	BASIC_CONSTRAINTS_free :: proc(bcons: ^BASIC_CONSTRAINTS) ---

	// d2i_BASIC_CONSTRAINTS parses up to |len| bytes from |*inp| as a DER-encoded
	// BasicConstraints (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_BASIC_CONSTRAINTS :: proc(out: ^^BASIC_CONSTRAINTS, inp: ^^u8, len: c.long) -> ^BASIC_CONSTRAINTS ---

	// i2d_BASIC_CONSTRAINTS marshals |bcons| as a DER-encoded BasicConstraints (RFC
	// 5280), as described in |i2d_SAMPLE|.
	i2d_BASIC_CONSTRAINTS :: proc(bcons: ^BASIC_CONSTRAINTS, outp: ^^u8) -> i32 ---
}

// Extended key usage.
//
// The extended key usage extension (RFC 5280, section 4.2.1.12) indicates the
// purposes of the certificate's public key. Such constraints are important to
// avoid cross-protocol attacks.
EXTENDED_KEY_USAGE :: stack_st_ASN1_OBJECT

@(default_calling_convention="c")
foreign lib {
	// EXTENDED_KEY_USAGE_new returns a newly-allocated, empty |EXTENDED_KEY_USAGE|
	// object, or NULL on error.
	EXTENDED_KEY_USAGE_new :: proc() -> ^EXTENDED_KEY_USAGE ---

	// EXTENDED_KEY_USAGE_free releases memory associated with |eku|.
	EXTENDED_KEY_USAGE_free :: proc(eku: ^EXTENDED_KEY_USAGE) ---

	// d2i_EXTENDED_KEY_USAGE parses up to |len| bytes from |*inp| as a DER-encoded
	// ExtKeyUsageSyntax (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_EXTENDED_KEY_USAGE :: proc(out: ^^EXTENDED_KEY_USAGE, inp: ^^u8, len: c.long) -> ^EXTENDED_KEY_USAGE ---

	// i2d_EXTENDED_KEY_USAGE marshals |eku| as a DER-encoded ExtKeyUsageSyntax (RFC
	// 5280), as described in |i2d_SAMPLE|.
	i2d_EXTENDED_KEY_USAGE :: proc(eku: ^EXTENDED_KEY_USAGE, outp: ^^u8) -> i32 ---
}

// General names.
//
// A |GENERAL_NAME| represents an X.509 GeneralName structure, defined in RFC
// 5280, Section 4.2.1.6. General names are distinct from names (|X509_NAME|). A
// general name is a CHOICE type which may contain one of several name types,
// most commonly a DNS name or an IP address. General names most commonly appear
// in the subject alternative name (SAN) extension, though they are also used in
// other extensions.
//
// Many extensions contain a SEQUENCE OF GeneralName, or GeneralNames, so
// |STACK_OF(GENERAL_NAME)| is defined and aliased to |GENERAL_NAMES|.
otherName_st :: struct {
	type_id: ^ASN1_OBJECT,
	value:   ^ASN1_TYPE,
}

// General names.
//
// A |GENERAL_NAME| represents an X.509 GeneralName structure, defined in RFC
// 5280, Section 4.2.1.6. General names are distinct from names (|X509_NAME|). A
// general name is a CHOICE type which may contain one of several name types,
// most commonly a DNS name or an IP address. General names most commonly appear
// in the subject alternative name (SAN) extension, though they are also used in
// other extensions.
//
// Many extensions contain a SEQUENCE OF GeneralName, or GeneralNames, so
// |STACK_OF(GENERAL_NAME)| is defined and aliased to |GENERAL_NAMES|.
OTHERNAME :: otherName_st

EDIPartyName_st :: struct {
	nameAssigner: ^ASN1_STRING,
	partyName:    ^ASN1_STRING,
}

EDIPARTYNAME :: EDIPartyName_st

// GEN_* are constants for the |type| field of |GENERAL_NAME|, defined below.
GEN_OTHERNAME :: 0
GEN_EMAIL     :: 1
GEN_DNS       :: 2
GEN_X400      :: 3
GEN_DIRNAME   :: 4
GEN_EDIPARTY  :: 5
GEN_URI       :: 6
GEN_IPADD     :: 7
GEN_RID       :: 8

// A GENERAL_NAME_st, aka |GENERAL_NAME|, represents an X.509 GeneralName. The
// |type| field determines which member of |d| is active. A |GENERAL_NAME| may
// also be empty, in which case |type| is -1 and |d| is NULL. Empty
// |GENERAL_NAME|s are invalid and will never be returned from the parser, but
// may be created temporarily, e.g. by |GENERAL_NAME_new|.
//
// WARNING: |type| and |d| must be kept consistent. An inconsistency will result
// in a potentially exploitable memory error.
GENERAL_NAME_st :: struct {
	type: i32,

	d: struct #raw_union {
		ptr:                       cstring,
		otherName:                 ^OTHERNAME,
		rfc822Name:                ^ASN1_IA5STRING,
		dNSName:                   ^ASN1_IA5STRING,
		x400Address:               ^ASN1_STRING,
		directoryName:             ^X509_NAME,
		ediPartyName:              ^EDIPARTYNAME,
		uniformResourceIdentifier: ^ASN1_IA5STRING,
		iPAddress:                 ^ASN1_OCTET_STRING,
		registeredID:              ^ASN1_OBJECT,

		// Old names
		ip:   ^ASN1_OCTET_STRING, // iPAddress
		dirn: ^X509_NAME,         // dirn
		ia5:  ^ASN1_IA5STRING,    // rfc822Name, dNSName, uniformResourceIdentifier
		rid:  ^ASN1_OBJECT,       // registeredID
	},
}

@(default_calling_convention="c")
foreign lib {
	// GENERAL_NAME_new returns a new, empty |GENERAL_NAME|, or NULL on error.
	GENERAL_NAME_new :: proc() -> ^GENERAL_NAME ---

	// GENERAL_NAME_free releases memory associated with |gen|.
	GENERAL_NAME_free :: proc(gen: ^GENERAL_NAME) ---

	// d2i_GENERAL_NAME parses up to |len| bytes from |*inp| as a DER-encoded X.509
	// GeneralName (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_GENERAL_NAME :: proc(out: ^^GENERAL_NAME, inp: ^^u8, len: c.long) -> ^GENERAL_NAME ---

	// i2d_GENERAL_NAME marshals |in| as a DER-encoded X.509 GeneralName (RFC 5280),
	// as described in |i2d_SAMPLE|.
	i2d_GENERAL_NAME :: proc(_in: ^GENERAL_NAME, outp: ^^u8) -> i32 ---

	// GENERAL_NAME_dup returns a newly-allocated copy of |gen|, or NULL on error.
	// This function works by serializing the structure, so it will fail if |gen| is
	// empty.
	GENERAL_NAME_dup :: proc(gen: ^GENERAL_NAME) -> ^GENERAL_NAME ---

	// GENERAL_NAMES_new returns a new, empty |GENERAL_NAMES|, or NULL on error.
	GENERAL_NAMES_new :: proc() -> ^GENERAL_NAMES ---

	// GENERAL_NAMES_free releases memory associated with |gens|.
	GENERAL_NAMES_free :: proc(gens: ^GENERAL_NAMES) ---

	// d2i_GENERAL_NAMES parses up to |len| bytes from |*inp| as a DER-encoded
	// SEQUENCE OF GeneralName, as described in |d2i_SAMPLE|.
	d2i_GENERAL_NAMES :: proc(out: ^^GENERAL_NAMES, inp: ^^u8, len: c.long) -> ^GENERAL_NAMES ---

	// i2d_GENERAL_NAMES marshals |in| as a DER-encoded SEQUENCE OF GeneralName, as
	// described in |i2d_SAMPLE|.
	i2d_GENERAL_NAMES :: proc(_in: ^GENERAL_NAMES, outp: ^^u8) -> i32 ---

	// OTHERNAME_new returns a new, empty |OTHERNAME|, or NULL on error.
	OTHERNAME_new :: proc() -> ^OTHERNAME ---

	// OTHERNAME_free releases memory associated with |name|.
	OTHERNAME_free :: proc(name: ^OTHERNAME) ---

	// EDIPARTYNAME_new returns a new, empty |EDIPARTYNAME|, or NULL on error.
	// EDIPartyName is rarely used in practice, so callers are unlikely to need this
	// function.
	EDIPARTYNAME_new :: proc() -> ^EDIPARTYNAME ---

	// EDIPARTYNAME_free releases memory associated with |name|. EDIPartyName is
	// rarely used in practice, so callers are unlikely to need this function.
	EDIPARTYNAME_free :: proc(name: ^EDIPARTYNAME) ---

	// GENERAL_NAME_set0_value set |gen|'s type and value to |type| and |value|.
	// |type| must be a |GEN_*| constant and |value| must be an object of the
	// corresponding type. |gen| takes ownership of |value|, so |value| must have
	// been an allocated object.
	//
	// WARNING: |gen| must be empty (typically as returned from |GENERAL_NAME_new|)
	// before calling this function. If |gen| already contained a value, the
	// previous contents will be leaked.
	GENERAL_NAME_set0_value :: proc(gen: ^GENERAL_NAME, type: i32, value: rawptr) ---

	// GENERAL_NAME_get0_value returns the in-memory representation of |gen|'s
	// contents and, |out_type| is not NULL, sets |*out_type| to the type of |gen|,
	// which will be a |GEN_*| constant. If |gen| is incomplete, the return value
	// will be NULL and the type will be -1.
	//
	// WARNING: Casting the result of this function to the wrong type is a
	// potentially exploitable memory error. Callers must check |gen|'s type, either
	// via |*out_type| or checking |gen->type| directly, before inspecting the
	// result.
	//
	// WARNING: This function is not const-correct. The return value should be
	// const. Callers should not mutate the returned object.
	GENERAL_NAME_get0_value :: proc(gen: ^GENERAL_NAME, out_type: ^i32) -> rawptr ---

	// GENERAL_NAME_set0_othername sets |gen| to be an OtherName with type |oid| and
	// value |value|. On success, it returns one and takes ownership of |oid| and
	// |value|, which must be created in a way compatible with |ASN1_OBJECT_free|
	// and |ASN1_TYPE_free|, respectively. On allocation failure, it returns zero.
	// In the failure case, the caller retains ownership of |oid| and |value| and
	// must release them when done.
	//
	// WARNING: |gen| must be empty (typically as returned from |GENERAL_NAME_new|)
	// before calling this function. If |gen| already contained a value, the
	// previously contents will be leaked.
	GENERAL_NAME_set0_othername :: proc(gen: ^GENERAL_NAME, oid: ^ASN1_OBJECT, value: ^ASN1_TYPE) -> i32 ---

	// GENERAL_NAME_get0_otherName, if |gen| is an OtherName, sets |*out_oid| and
	// |*out_value| to the OtherName's type-id and value, respectively, and returns
	// one. If |gen| is not an OtherName, it returns zero and leaves |*out_oid| and
	// |*out_value| unmodified. Either of |out_oid| or |out_value| may be NULL to
	// ignore the value.
	//
	// WARNING: This function is not const-correct. |out_oid| and |out_value| are
	// not const, but callers should not mutate the resulting objects.
	GENERAL_NAME_get0_otherName :: proc(gen: ^GENERAL_NAME, out_oid: ^^ASN1_OBJECT, out_value: ^^ASN1_TYPE) -> i32 ---
}

// A AUTHORITY_KEYID_st, aka |AUTHORITY_KEYID|, represents an
// AuthorityKeyIdentifier structure (RFC 5280).
AUTHORITY_KEYID_st :: struct {
	keyid:  ^ASN1_OCTET_STRING,
	issuer: ^GENERAL_NAMES,
	serial: ^ASN1_INTEGER,
}

@(default_calling_convention="c")
foreign lib {
	// AUTHORITY_KEYID_new returns a newly-allocated, empty |AUTHORITY_KEYID|
	// object, or NULL on error.
	AUTHORITY_KEYID_new :: proc() -> ^AUTHORITY_KEYID ---

	// AUTHORITY_KEYID_free releases memory associated with |akid|.
	AUTHORITY_KEYID_free :: proc(akid: ^AUTHORITY_KEYID) ---

	// d2i_AUTHORITY_KEYID parses up to |len| bytes from |*inp| as a DER-encoded
	// AuthorityKeyIdentifier (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_AUTHORITY_KEYID :: proc(out: ^^AUTHORITY_KEYID, inp: ^^u8, len: c.long) -> ^AUTHORITY_KEYID ---

	// i2d_AUTHORITY_KEYID marshals |akid| as a DER-encoded AuthorityKeyIdentifier
	// (RFC 5280), as described in |i2d_SAMPLE|.
	i2d_AUTHORITY_KEYID :: proc(akid: ^AUTHORITY_KEYID, outp: ^^u8) -> i32 ---
}

// A GENERAL_SUBTREE represents a GeneralSubtree structure (RFC 5280).
GENERAL_SUBTREE_st :: struct {
	base:    ^GENERAL_NAME,
	minimum: ^ASN1_INTEGER,
	maximum: ^ASN1_INTEGER,
}

// A GENERAL_SUBTREE represents a GeneralSubtree structure (RFC 5280).
GENERAL_SUBTREE                   :: GENERAL_SUBTREE_st
sk_GENERAL_SUBTREE_delete_if_func :: proc "c" (^GENERAL_SUBTREE, rawptr) -> i32
stack_st_GENERAL_SUBTREE          :: struct {}
sk_GENERAL_SUBTREE_free_func      :: proc "c" (^GENERAL_SUBTREE)
sk_GENERAL_SUBTREE_copy_func      :: proc "c" (^GENERAL_SUBTREE) -> ^GENERAL_SUBTREE
sk_GENERAL_SUBTREE_cmp_func       :: proc "c" (^^GENERAL_SUBTREE, ^^GENERAL_SUBTREE) -> i32

@(default_calling_convention="c")
foreign lib {
	// GENERAL_SUBTREE_new returns a newly-allocated, empty |GENERAL_SUBTREE|
	// object, or NULL on error.
	GENERAL_SUBTREE_new :: proc() -> ^GENERAL_SUBTREE ---

	// GENERAL_SUBTREE_free releases memory associated with |subtree|.
	GENERAL_SUBTREE_free :: proc(subtree: ^GENERAL_SUBTREE) ---
}

// A NAME_CONSTRAINTS_st, aka |NAME_CONSTRAINTS|, represents a NameConstraints
// structure (RFC 5280).
NAME_CONSTRAINTS_st :: struct {
	permittedSubtrees: ^stack_st_GENERAL_SUBTREE,
	excludedSubtrees:  ^stack_st_GENERAL_SUBTREE,
}

@(default_calling_convention="c")
foreign lib {
	// NAME_CONSTRAINTS_new returns a newly-allocated, empty |NAME_CONSTRAINTS|
	// object, or NULL on error.
	NAME_CONSTRAINTS_new :: proc() -> ^NAME_CONSTRAINTS ---

	// NAME_CONSTRAINTS_free releases memory associated with |ncons|.
	NAME_CONSTRAINTS_free :: proc(ncons: ^NAME_CONSTRAINTS) ---
}

// An ACCESS_DESCRIPTION represents an AccessDescription structure (RFC 5280).
ACCESS_DESCRIPTION_st :: struct {
	method:   ^ASN1_OBJECT,
	location: ^GENERAL_NAME,
}

// An ACCESS_DESCRIPTION represents an AccessDescription structure (RFC 5280).
ACCESS_DESCRIPTION                   :: ACCESS_DESCRIPTION_st
sk_ACCESS_DESCRIPTION_delete_if_func :: proc "c" (^ACCESS_DESCRIPTION, rawptr) -> i32
sk_ACCESS_DESCRIPTION_copy_func      :: proc "c" (^ACCESS_DESCRIPTION) -> ^ACCESS_DESCRIPTION
sk_ACCESS_DESCRIPTION_free_func      :: proc "c" (^ACCESS_DESCRIPTION)
sk_ACCESS_DESCRIPTION_cmp_func       :: proc "c" (^^ACCESS_DESCRIPTION, ^^ACCESS_DESCRIPTION) -> i32
stack_st_ACCESS_DESCRIPTION          :: struct {}

@(default_calling_convention="c")
foreign lib {
	// ACCESS_DESCRIPTION_new returns a newly-allocated, empty |ACCESS_DESCRIPTION|
	// object, or NULL on error.
	ACCESS_DESCRIPTION_new :: proc() -> ^ACCESS_DESCRIPTION ---

	// ACCESS_DESCRIPTION_free releases memory associated with |desc|.
	ACCESS_DESCRIPTION_free :: proc(desc: ^ACCESS_DESCRIPTION) ---
}

AUTHORITY_INFO_ACCESS :: stack_st_ACCESS_DESCRIPTION

@(default_calling_convention="c")
foreign lib {
	// AUTHORITY_INFO_ACCESS_new returns a newly-allocated, empty
	// |AUTHORITY_INFO_ACCESS| object, or NULL on error.
	AUTHORITY_INFO_ACCESS_new :: proc() -> ^AUTHORITY_INFO_ACCESS ---

	// AUTHORITY_INFO_ACCESS_free releases memory associated with |aia|.
	AUTHORITY_INFO_ACCESS_free :: proc(aia: ^AUTHORITY_INFO_ACCESS) ---

	// d2i_AUTHORITY_INFO_ACCESS parses up to |len| bytes from |*inp| as a
	// DER-encoded AuthorityInfoAccessSyntax (RFC 5280), as described in
	// |d2i_SAMPLE|.
	d2i_AUTHORITY_INFO_ACCESS :: proc(out: ^^AUTHORITY_INFO_ACCESS, inp: ^^u8, len: c.long) -> ^AUTHORITY_INFO_ACCESS ---

	// i2d_AUTHORITY_INFO_ACCESS marshals |aia| as a DER-encoded
	// AuthorityInfoAccessSyntax (RFC 5280), as described in |i2d_SAMPLE|.
	i2d_AUTHORITY_INFO_ACCESS :: proc(aia: ^AUTHORITY_INFO_ACCESS, outp: ^^u8) -> i32 ---
}

// A DIST_POINT_NAME represents a DistributionPointName structure (RFC 5280).
// The |name| field contains the CHOICE value and is determined by |type|. If
// |type| is zero, |name| must be a |fullname|. If |type| is one, |name| must be
// a |relativename|.
//
// WARNING: |type| and |name| must be kept consistent. An inconsistency will
// result in a potentially exploitable memory error.
DIST_POINT_NAME_st :: struct {
	type: i32,

	name: struct #raw_union {
		fullname:     ^GENERAL_NAMES,
		relativename: ^stack_st_X509_NAME_ENTRY,
	},

	// If relativename then this contains the full distribution point name
	dpname: ^X509_NAME,
}

// A DIST_POINT_NAME represents a DistributionPointName structure (RFC 5280).
// The |name| field contains the CHOICE value and is determined by |type|. If
// |type| is zero, |name| must be a |fullname|. If |type| is one, |name| must be
// a |relativename|.
//
// WARNING: |type| and |name| must be kept consistent. An inconsistency will
// result in a potentially exploitable memory error.
DIST_POINT_NAME :: DIST_POINT_NAME_st

@(default_calling_convention="c")
foreign lib {
	// DIST_POINT_NAME_new returns a newly-allocated, empty |DIST_POINT_NAME|
	// object, or NULL on error.
	DIST_POINT_NAME_new :: proc() -> ^DIST_POINT_NAME ---

	// DIST_POINT_NAME_free releases memory associated with |name|.
	DIST_POINT_NAME_free :: proc(name: ^DIST_POINT_NAME) ---
}

// A DIST_POINT_st, aka |DIST_POINT|, represents a DistributionPoint structure
// (RFC 5280).
DIST_POINT_st :: struct {
	distpoint: ^DIST_POINT_NAME,
	reasons:   ^ASN1_BIT_STRING,
	CRLissuer: ^GENERAL_NAMES,
}

sk_DIST_POINT_cmp_func       :: proc "c" (^^DIST_POINT, ^^DIST_POINT) -> i32
sk_DIST_POINT_free_func      :: proc "c" (^DIST_POINT)
stack_st_DIST_POINT          :: struct {}
sk_DIST_POINT_copy_func      :: proc "c" (^DIST_POINT) -> ^DIST_POINT
sk_DIST_POINT_delete_if_func :: proc "c" (^DIST_POINT, rawptr) -> i32

@(default_calling_convention="c")
foreign lib {
	// DIST_POINT_new returns a newly-allocated, empty |DIST_POINT| object, or NULL
	// on error.
	DIST_POINT_new :: proc() -> ^DIST_POINT ---

	// DIST_POINT_free releases memory associated with |dp|.
	DIST_POINT_free :: proc(dp: ^DIST_POINT) ---
}

CRL_DIST_POINTS :: stack_st_DIST_POINT

@(default_calling_convention="c")
foreign lib {
	// CRL_DIST_POINTS_new returns a newly-allocated, empty |CRL_DIST_POINTS|
	// object, or NULL on error.
	CRL_DIST_POINTS_new :: proc() -> ^CRL_DIST_POINTS ---

	// CRL_DIST_POINTS_free releases memory associated with |crldp|.
	CRL_DIST_POINTS_free :: proc(crldp: ^CRL_DIST_POINTS) ---

	// d2i_CRL_DIST_POINTS parses up to |len| bytes from |*inp| as a DER-encoded
	// CRLDistributionPoints (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_CRL_DIST_POINTS :: proc(out: ^^CRL_DIST_POINTS, inp: ^^u8, len: c.long) -> ^CRL_DIST_POINTS ---

	// i2d_CRL_DIST_POINTS marshals |crldp| as a DER-encoded CRLDistributionPoints
	// (RFC 5280), as described in |i2d_SAMPLE|.
	i2d_CRL_DIST_POINTS :: proc(crldp: ^CRL_DIST_POINTS, outp: ^^u8) -> i32 ---
}

// A ISSUING_DIST_POINT_st, aka |ISSUING_DIST_POINT|, represents a
// IssuingDistributionPoint structure (RFC 5280).
ISSUING_DIST_POINT_st :: struct {
	distpoint:       ^DIST_POINT_NAME,
	onlyuser:        ASN1_BOOLEAN,
	onlyCA:          ASN1_BOOLEAN,
	onlysomereasons: ^ASN1_BIT_STRING,
	indirectCRL:     ASN1_BOOLEAN,
	onlyattr:        ASN1_BOOLEAN,
}

@(default_calling_convention="c")
foreign lib {
	// ISSUING_DIST_POINT_new returns a newly-allocated, empty |ISSUING_DIST_POINT|
	// object, or NULL on error.
	ISSUING_DIST_POINT_new :: proc() -> ^ISSUING_DIST_POINT ---

	// ISSUING_DIST_POINT_free releases memory associated with |idp|.
	ISSUING_DIST_POINT_free :: proc(idp: ^ISSUING_DIST_POINT) ---

	// d2i_ISSUING_DIST_POINT parses up to |len| bytes from |*inp| as a DER-encoded
	// IssuingDistributionPoint (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_ISSUING_DIST_POINT :: proc(out: ^^ISSUING_DIST_POINT, inp: ^^u8, len: c.long) -> ^ISSUING_DIST_POINT ---

	// i2d_ISSUING_DIST_POINT marshals |idp| as a DER-encoded
	// IssuingDistributionPoint (RFC 5280), as described in |i2d_SAMPLE|.
	i2d_ISSUING_DIST_POINT :: proc(idp: ^ISSUING_DIST_POINT, outp: ^^u8) -> i32 ---
}

// A NOTICEREF represents a NoticeReference structure (RFC 5280).
NOTICEREF_st :: struct {
	organization: ^ASN1_STRING,
	noticenos:    ^stack_st_ASN1_INTEGER,
}

// A NOTICEREF represents a NoticeReference structure (RFC 5280).
NOTICEREF :: NOTICEREF_st

@(default_calling_convention="c")
foreign lib {
	// NOTICEREF_new returns a newly-allocated, empty |NOTICEREF| object, or NULL
	// on error.
	NOTICEREF_new :: proc() -> ^NOTICEREF ---

	// NOTICEREF_free releases memory associated with |ref|.
	NOTICEREF_free :: proc(ref: ^NOTICEREF) ---
}

// A USERNOTICE represents a UserNotice structure (RFC 5280).
USERNOTICE_st :: struct {
	noticeref: ^NOTICEREF,
	exptext:   ^ASN1_STRING,
}

// A USERNOTICE represents a UserNotice structure (RFC 5280).
USERNOTICE :: USERNOTICE_st

@(default_calling_convention="c")
foreign lib {
	// USERNOTICE_new returns a newly-allocated, empty |USERNOTICE| object, or NULL
	// on error.
	USERNOTICE_new :: proc() -> ^USERNOTICE ---

	// USERNOTICE_free releases memory associated with |notice|.
	USERNOTICE_free :: proc(notice: ^USERNOTICE) ---
}

// A POLICYQUALINFO represents a PolicyQualifierInfo structure (RFC 5280). |d|
// contains the qualifier field of the PolicyQualifierInfo. Its type is
// determined by |pqualid|. If |pqualid| is |NID_id_qt_cps|, |d| must be
// |cpsuri|. If |pqualid| is |NID_id_qt_unotice|, |d| must be |usernotice|.
// Otherwise, |d| must be |other|.
//
// WARNING: |pqualid| and |d| must be kept consistent. An inconsistency will
// result in a potentially exploitable memory error.
POLICYQUALINFO_st :: struct {
	pqualid: ^ASN1_OBJECT,

	d: struct #raw_union {
		cpsuri:     ^ASN1_IA5STRING,
		usernotice: ^USERNOTICE,
		other:      ^ASN1_TYPE,
	},
}

// A POLICYQUALINFO represents a PolicyQualifierInfo structure (RFC 5280). |d|
// contains the qualifier field of the PolicyQualifierInfo. Its type is
// determined by |pqualid|. If |pqualid| is |NID_id_qt_cps|, |d| must be
// |cpsuri|. If |pqualid| is |NID_id_qt_unotice|, |d| must be |usernotice|.
// Otherwise, |d| must be |other|.
//
// WARNING: |pqualid| and |d| must be kept consistent. An inconsistency will
// result in a potentially exploitable memory error.
POLICYQUALINFO                   :: POLICYQUALINFO_st
sk_POLICYQUALINFO_copy_func      :: proc "c" (^POLICYQUALINFO) -> ^POLICYQUALINFO
stack_st_POLICYQUALINFO          :: struct {}
sk_POLICYQUALINFO_free_func      :: proc "c" (^POLICYQUALINFO)
sk_POLICYQUALINFO_cmp_func       :: proc "c" (^^POLICYQUALINFO, ^^POLICYQUALINFO) -> i32
sk_POLICYQUALINFO_delete_if_func :: proc "c" (^POLICYQUALINFO, rawptr) -> i32

@(default_calling_convention="c")
foreign lib {
	// POLICYQUALINFO_new returns a newly-allocated, empty |POLICYQUALINFO| object,
	// or NULL on error.
	POLICYQUALINFO_new :: proc() -> ^POLICYQUALINFO ---

	// POLICYQUALINFO_free releases memory associated with |info|.
	POLICYQUALINFO_free :: proc(info: ^POLICYQUALINFO) ---
}

// A POLICYINFO represents a PolicyInformation structure (RFC 5280).
POLICYINFO_st :: struct {
	policyid:   ^ASN1_OBJECT,
	qualifiers: ^stack_st_POLICYQUALINFO,
}

// A POLICYINFO represents a PolicyInformation structure (RFC 5280).
POLICYINFO                   :: POLICYINFO_st
sk_POLICYINFO_copy_func      :: proc "c" (^POLICYINFO) -> ^POLICYINFO
sk_POLICYINFO_free_func      :: proc "c" (^POLICYINFO)
sk_POLICYINFO_cmp_func       :: proc "c" (^^POLICYINFO, ^^POLICYINFO) -> i32
stack_st_POLICYINFO          :: struct {}
sk_POLICYINFO_delete_if_func :: proc "c" (^POLICYINFO, rawptr) -> i32

@(default_calling_convention="c")
foreign lib {
	// POLICYINFO_new returns a newly-allocated, empty |POLICYINFO| object, or NULL
	// on error.
	POLICYINFO_new :: proc() -> ^POLICYINFO ---

	// POLICYINFO_free releases memory associated with |info|.
	POLICYINFO_free :: proc(info: ^POLICYINFO) ---
}

CERTIFICATEPOLICIES :: stack_st_POLICYINFO

@(default_calling_convention="c")
foreign lib {
	// CERTIFICATEPOLICIES_new returns a newly-allocated, empty
	// |CERTIFICATEPOLICIES| object, or NULL on error.
	CERTIFICATEPOLICIES_new :: proc() -> ^CERTIFICATEPOLICIES ---

	// CERTIFICATEPOLICIES_free releases memory associated with |policies|.
	CERTIFICATEPOLICIES_free :: proc(policies: ^CERTIFICATEPOLICIES) ---

	// d2i_CERTIFICATEPOLICIES parses up to |len| bytes from |*inp| as a DER-encoded
	// CertificatePolicies (RFC 5280), as described in |d2i_SAMPLE|.
	d2i_CERTIFICATEPOLICIES :: proc(out: ^^CERTIFICATEPOLICIES, inp: ^^u8, len: c.long) -> ^CERTIFICATEPOLICIES ---

	// i2d_CERTIFICATEPOLICIES marshals |policies| as a DER-encoded
	// CertificatePolicies (RFC 5280), as described in |i2d_SAMPLE|.
	i2d_CERTIFICATEPOLICIES :: proc(policies: ^CERTIFICATEPOLICIES, outp: ^^u8) -> i32 ---
}

// A POLICY_MAPPING represents an individual element of a PolicyMappings
// structure (RFC 5280).
POLICY_MAPPING_st :: struct {
	issuerDomainPolicy:  ^ASN1_OBJECT,
	subjectDomainPolicy: ^ASN1_OBJECT,
}

// A POLICY_MAPPING represents an individual element of a PolicyMappings
// structure (RFC 5280).
POLICY_MAPPING                   :: POLICY_MAPPING_st
sk_POLICY_MAPPING_delete_if_func :: proc "c" (^POLICY_MAPPING, rawptr) -> i32
sk_POLICY_MAPPING_copy_func      :: proc "c" (^POLICY_MAPPING) -> ^POLICY_MAPPING
sk_POLICY_MAPPING_free_func      :: proc "c" (^POLICY_MAPPING)
sk_POLICY_MAPPING_cmp_func       :: proc "c" (^^POLICY_MAPPING, ^^POLICY_MAPPING) -> i32
stack_st_POLICY_MAPPING          :: struct {}

@(default_calling_convention="c")
foreign lib {
	// POLICY_MAPPING_new returns a newly-allocated, empty |POLICY_MAPPING| object,
	// or NULL on error.
	POLICY_MAPPING_new :: proc() -> ^POLICY_MAPPING ---

	// POLICY_MAPPING_free releases memory associated with |mapping|.
	POLICY_MAPPING_free :: proc(mapping: ^POLICY_MAPPING) ---
}

POLICY_MAPPINGS :: stack_st_POLICY_MAPPING

// A POLICY_CONSTRAINTS represents a PolicyConstraints structure (RFC 5280).
POLICY_CONSTRAINTS_st :: struct {
	requireExplicitPolicy: ^ASN1_INTEGER,
	inhibitPolicyMapping:  ^ASN1_INTEGER,
}

// A POLICY_CONSTRAINTS represents a PolicyConstraints structure (RFC 5280).
POLICY_CONSTRAINTS :: POLICY_CONSTRAINTS_st

@(default_calling_convention="c")
foreign lib {
	// POLICY_CONSTRAINTS_new returns a newly-allocated, empty |POLICY_CONSTRAINTS|
	// object, or NULL on error.
	POLICY_CONSTRAINTS_new :: proc() -> ^POLICY_CONSTRAINTS ---

	// POLICY_CONSTRAINTS_free releases memory associated with |pcons|.
	POLICY_CONSTRAINTS_free :: proc(pcons: ^POLICY_CONSTRAINTS) ---
}

sk_X509_ALGOR_cmp_func       :: proc "c" (^^X509_ALGOR, ^^X509_ALGOR) -> i32
sk_X509_ALGOR_copy_func      :: proc "c" (^X509_ALGOR) -> ^X509_ALGOR
sk_X509_ALGOR_delete_if_func :: proc "c" (^X509_ALGOR, rawptr) -> i32
stack_st_X509_ALGOR          :: struct {}
sk_X509_ALGOR_free_func      :: proc "c" (^X509_ALGOR)

@(default_calling_convention="c")
foreign lib {
	// X509_ALGOR_new returns a newly-allocated, empty |X509_ALGOR| object, or NULL
	// on error.
	X509_ALGOR_new :: proc() -> ^X509_ALGOR ---

	// X509_ALGOR_dup returns a newly-allocated copy of |alg|, or NULL on error.
	// This function works by serializing the structure, so if |alg| is incomplete,
	// it may fail.
	X509_ALGOR_dup :: proc(alg: ^X509_ALGOR) -> ^X509_ALGOR ---

	// X509_ALGOR_copy sets |dst| to a copy of the contents of |src|. It returns one
	// on success and zero on error.
	X509_ALGOR_copy :: proc(dst: ^X509_ALGOR, src: ^X509_ALGOR) -> i32 ---

	// X509_ALGOR_free releases memory associated with |alg|.
	X509_ALGOR_free :: proc(alg: ^X509_ALGOR) ---

	// d2i_X509_ALGOR parses up to |len| bytes from |*inp| as a DER-encoded
	// AlgorithmIdentifier, as described in |d2i_SAMPLE|.
	d2i_X509_ALGOR :: proc(out: ^^X509_ALGOR, inp: ^^u8, len: c.long) -> ^X509_ALGOR ---

	// i2d_X509_ALGOR marshals |alg| as a DER-encoded AlgorithmIdentifier, as
	// described in |i2d_SAMPLE|.
	i2d_X509_ALGOR :: proc(alg: ^X509_ALGOR, outp: ^^u8) -> i32 ---

	// X509_ALGOR_set0 sets |alg| to an AlgorithmIdentifier with algorithm |obj| and
	// parameter determined by |param_type| and |param_value|. It returns one on
	// success and zero on error. This function takes ownership of |obj| and
	// |param_value| on success.
	//
	// If |param_type| is |V_ASN1_UNDEF|, the parameter is omitted. If |param_type|
	// is zero, the parameter is left unchanged. Otherwise, |param_type| and
	// |param_value| are interpreted as in |ASN1_TYPE_set|.
	//
	// Note omitting the parameter (|V_ASN1_UNDEF|) and encoding an explicit NULL
	// value (|V_ASN1_NULL|) are different. Some algorithms require one and some the
	// other. Consult the relevant specification before calling this function. The
	// correct parameter for an RSASSA-PKCS1-v1_5 signature is |V_ASN1_NULL|. The
	// correct one for an ECDSA or Ed25519 signature is |V_ASN1_UNDEF|.
	X509_ALGOR_set0 :: proc(alg: ^X509_ALGOR, obj: ^ASN1_OBJECT, param_type: i32, param_value: rawptr) -> i32 ---

	// X509_ALGOR_get0 sets |*out_obj| to the |alg|'s algorithm. If |alg|'s
	// parameter is omitted, it sets |*out_param_type| and |*out_param_value| to
	// |V_ASN1_UNDEF| and NULL. Otherwise, it sets |*out_param_type| and
	// |*out_param_value| to the parameter, using the same representation as
	// |ASN1_TYPE_set0|. See |ASN1_TYPE_set0| and |ASN1_TYPE| for details.
	//
	// Callers that require the parameter in serialized form should, after checking
	// for |V_ASN1_UNDEF|, use |ASN1_TYPE_set1| and |d2i_ASN1_TYPE|, rather than
	// inspecting |*out_param_value|.
	//
	// Each of |out_obj|, |out_param_type|, and |out_param_value| may be NULL to
	// ignore the output. If |out_param_type| is NULL, |out_param_value| is ignored.
	//
	// WARNING: If |*out_param_type| is set to |V_ASN1_UNDEF|, OpenSSL and older
	// revisions of BoringSSL leave |*out_param_value| unset rather than setting it
	// to NULL. Callers that support both OpenSSL and BoringSSL should not assume
	// |*out_param_value| is uniformly initialized.
	X509_ALGOR_get0 :: proc(out_obj: ^^ASN1_OBJECT, out_param_type: ^i32, out_param_value: ^rawptr, alg: ^X509_ALGOR) ---

	// X509_ALGOR_set_md sets |alg| to the hash function |md|. Note this
	// AlgorithmIdentifier represents the hash function itself, not a signature
	// algorithm that uses |md|. It returns one on success and zero on error.
	//
	// Due to historical specification mistakes (see Section 2.1 of RFC 4055), the
	// parameters field is sometimes omitted and sometimes a NULL value. When used
	// in RSASSA-PSS and RSAES-OAEP, it should be a NULL value. In other contexts,
	// the parameters should be omitted. This function assumes the caller is
	// constructing a RSASSA-PSS or RSAES-OAEP AlgorithmIdentifier and includes a
	// NULL parameter. This differs from OpenSSL's behavior.
	//
	// TODO(davidben): Rename this function, or perhaps just add a bespoke API for
	// constructing PSS and move on.
	X509_ALGOR_set_md :: proc(alg: ^X509_ALGOR, md: ^EVP_MD) -> i32 ---

	// X509_ALGOR_cmp returns zero if |a| and |b| are equal, and some non-zero value
	// otherwise. Note this function can only be used for equality checks, not an
	// ordering.
	X509_ALGOR_cmp :: proc(a: ^X509_ALGOR, b: ^X509_ALGOR) -> i32 ---
}

sk_X509_ATTRIBUTE_cmp_func       :: proc "c" (^^X509_ATTRIBUTE, ^^X509_ATTRIBUTE) -> i32
sk_X509_ATTRIBUTE_copy_func      :: proc "c" (^X509_ATTRIBUTE) -> ^X509_ATTRIBUTE
sk_X509_ATTRIBUTE_delete_if_func :: proc "c" (^X509_ATTRIBUTE, rawptr) -> i32
stack_st_X509_ATTRIBUTE          :: struct {}
sk_X509_ATTRIBUTE_free_func      :: proc "c" (^X509_ATTRIBUTE)

@(default_calling_convention="c")
foreign lib {
	// X509_ATTRIBUTE_new returns a newly-allocated, empty |X509_ATTRIBUTE| object,
	// or NULL on error. |X509_ATTRIBUTE_set1_*| may be used to finish initializing
	// it.
	X509_ATTRIBUTE_new :: proc() -> ^X509_ATTRIBUTE ---

	// X509_ATTRIBUTE_dup returns a newly-allocated copy of |attr|, or NULL on
	// error. This function works by serializing the structure, so if |attr| is
	// incomplete, it may fail.
	X509_ATTRIBUTE_dup :: proc(attr: ^X509_ATTRIBUTE) -> ^X509_ATTRIBUTE ---

	// X509_ATTRIBUTE_free releases memory associated with |attr|.
	X509_ATTRIBUTE_free :: proc(attr: ^X509_ATTRIBUTE) ---

	// d2i_X509_ATTRIBUTE parses up to |len| bytes from |*inp| as a DER-encoded
	// Attribute (RFC 2986), as described in |d2i_SAMPLE|.
	d2i_X509_ATTRIBUTE :: proc(out: ^^X509_ATTRIBUTE, inp: ^^u8, len: c.long) -> ^X509_ATTRIBUTE ---

	// i2d_X509_ATTRIBUTE marshals |alg| as a DER-encoded Attribute (RFC 2986), as
	// described in |i2d_SAMPLE|.
	i2d_X509_ATTRIBUTE :: proc(alg: ^X509_ATTRIBUTE, outp: ^^u8) -> i32 ---

	// X509_ATTRIBUTE_create returns a newly-allocated |X509_ATTRIBUTE|, or NULL on
	// error. The attribute has type |nid| and contains a single value determined by
	// |attrtype| and |value|, which are interpreted as in |ASN1_TYPE_set|. Note
	// this function takes ownership of |value|.
	X509_ATTRIBUTE_create :: proc(nid: i32, attrtype: i32, value: rawptr) -> ^X509_ATTRIBUTE ---

	// X509_ATTRIBUTE_create_by_NID returns a newly-allocated |X509_ATTRIBUTE| of
	// type |nid|, or NULL on error. The value is determined as in
	// |X509_ATTRIBUTE_set1_data|.
	//
	// If |attr| is non-NULL, the resulting |X509_ATTRIBUTE| is also written to
	// |*attr|. If |*attr| was non-NULL when the function was called, |*attr| is
	// reused instead of creating a new object.
	//
	// WARNING: The interpretation of |attrtype|, |data|, and |len| is complex and
	// error-prone. See |X509_ATTRIBUTE_set1_data| for details.
	//
	// WARNING: The object reuse form is deprecated and may be removed in the
	// future. It also currently incorrectly appends to the reused object's value
	// set rather than overwriting it.
	X509_ATTRIBUTE_create_by_NID :: proc(attr: ^^X509_ATTRIBUTE, nid: i32, attrtype: i32, data: rawptr, len: i32) -> ^X509_ATTRIBUTE ---

	// X509_ATTRIBUTE_create_by_OBJ behaves like |X509_ATTRIBUTE_create_by_NID|
	// except the attribute's type is determined by |obj|.
	X509_ATTRIBUTE_create_by_OBJ :: proc(attr: ^^X509_ATTRIBUTE, obj: ^ASN1_OBJECT, attrtype: i32, data: rawptr, len: i32) -> ^X509_ATTRIBUTE ---

	// X509_ATTRIBUTE_create_by_txt behaves like |X509_ATTRIBUTE_create_by_NID|
	// except the attribute's type is determined by calling |OBJ_txt2obj| with
	// |attrname|.
	X509_ATTRIBUTE_create_by_txt :: proc(attr: ^^X509_ATTRIBUTE, attrname: cstring, type: i32, bytes: ^u8, len: i32) -> ^X509_ATTRIBUTE ---

	// X509_ATTRIBUTE_set1_object sets |attr|'s type to |obj|. It returns one on
	// success and zero on error.
	X509_ATTRIBUTE_set1_object :: proc(attr: ^X509_ATTRIBUTE, obj: ^ASN1_OBJECT) -> i32 ---

	// X509_ATTRIBUTE_set1_data appends a value to |attr|'s value set and returns
	// one on success or zero on error. The value is determined as follows:
	//
	// If |attrtype| is zero, this function returns one and does nothing. This form
	// may be used when calling |X509_ATTRIBUTE_create_by_*| to create an attribute
	// with an empty value set. Such attributes are invalid, but OpenSSL supports
	// creating them.
	//
	// Otherwise, if |attrtype| is a |MBSTRING_*| constant, the value is an ASN.1
	// string. The string is determined by decoding |len| bytes from |data| in the
	// encoding specified by |attrtype|, and then re-encoding it in a form
	// appropriate for |attr|'s type. If |len| is -1, |strlen(data)| is used
	// instead. See |ASN1_STRING_set_by_NID| for details.
	//
	// Otherwise, if |len| is not -1, the value is an ASN.1 string. |attrtype| is an
	// |ASN1_STRING| type value and the |len| bytes from |data| are copied as the
	// type-specific representation of |ASN1_STRING|. See |ASN1_STRING| for details.
	//
	// Otherwise, if |len| is -1, the value is constructed by passing |attrtype| and
	// |data| to |ASN1_TYPE_set1|. That is, |attrtype| is an |ASN1_TYPE| type value,
	// and |data| is cast to the corresponding pointer type.
	//
	// WARNING: Despite the name, this function appends to |attr|'s value set,
	// rather than overwriting it. To overwrite the value set, create a new
	// |X509_ATTRIBUTE| with |X509_ATTRIBUTE_new|.
	//
	// WARNING: If using the |MBSTRING_*| form, pass a length rather than relying on
	// |strlen|. In particular, |strlen| will not behave correctly if the input is
	// |MBSTRING_BMP| or |MBSTRING_UNIV|.
	//
	// WARNING: This function currently misinterprets |V_ASN1_OTHER| as an
	// |MBSTRING_*| constant. This matches OpenSSL but means it is impossible to
	// construct a value with a non-universal tag.
	X509_ATTRIBUTE_set1_data :: proc(attr: ^X509_ATTRIBUTE, attrtype: i32, data: rawptr, len: i32) -> i32 ---

	// X509_ATTRIBUTE_get0_data returns the |idx|th value of |attr| in a
	// type-specific representation to |attrtype|, or NULL if out of bounds or the
	// type does not match. |attrtype| is one of the type values in |ASN1_TYPE|. On
	// match, the return value uses the same representation as |ASN1_TYPE_set0|. See
	// |ASN1_TYPE| for details.
	X509_ATTRIBUTE_get0_data :: proc(attr: ^X509_ATTRIBUTE, idx: i32, attrtype: i32, unused: rawptr) -> rawptr ---

	// X509_ATTRIBUTE_count returns the number of values in |attr|.
	X509_ATTRIBUTE_count :: proc(attr: ^X509_ATTRIBUTE) -> i32 ---

	// X509_ATTRIBUTE_get0_object returns the type of |attr|.
	X509_ATTRIBUTE_get0_object :: proc(attr: ^X509_ATTRIBUTE) -> ^ASN1_OBJECT ---

	// X509_ATTRIBUTE_get0_type returns the |idx|th value in |attr|, or NULL if out
	// of bounds. Note this function returns one of |attr|'s values, not the type.
	X509_ATTRIBUTE_get0_type :: proc(attr: ^X509_ATTRIBUTE, idx: i32) -> ^ASN1_TYPE ---

	// X509_STORE_new returns a newly-allocated |X509_STORE|, or NULL on error.
	X509_STORE_new :: proc() -> ^X509_STORE ---

	// X509_STORE_up_ref adds one to the reference count of |store| and returns one.
	// Although |store| is not const, this function's use of |store| is thread-safe.
	X509_STORE_up_ref :: proc(store: ^X509_STORE) -> i32 ---

	// X509_STORE_free releases memory associated with |store|.
	X509_STORE_free :: proc(store: ^X509_STORE) ---

	// X509_STORE_add_cert adds |x509| to |store| as a trusted certificate. It
	// returns one on success and zero on error. This function internally increments
	// |x509|'s reference count, so the caller retains ownership of |x509|.
	//
	// Certificates configured by this function are still subject to the checks
	// described in |X509_VERIFY_PARAM_set_trust|.
	//
	// Although |store| is not const, this function's use of |store| is thread-safe.
	// However, if this function is called concurrently with |X509_verify_cert|, it
	// is a race condition whether |x509| is available for issuer lookups.
	// Moreover, the result may differ for each issuer lookup performed by a single
	// |X509_verify_cert| call.
	X509_STORE_add_cert :: proc(store: ^X509_STORE, x509: ^X509) -> i32 ---

	// X509_STORE_add_crl adds |crl| to |store|. It returns one on success and zero
	// on error. This function internally increments |crl|'s reference count, so the
	// caller retains ownership of |crl|. CRLs added in this way are candidates for
	// CRL lookup when |X509_V_FLAG_CRL_CHECK| is set.
	//
	// Although |store| is not const, this function's use of |store| is thread-safe.
	// However, if this function is called concurrently with |X509_verify_cert|, it
	// is a race condition whether |crl| is available for CRL checks. Moreover, the
	// result may differ for each CRL check performed by a single
	// |X509_verify_cert| call.
	//
	// Note there are no supported APIs to remove CRLs from |store| once inserted.
	// To vary the set of CRLs over time, callers should either create a new
	// |X509_STORE| or configure CRLs on a per-verification basis with
	// |X509_STORE_CTX_set0_crls|.
	X509_STORE_add_crl :: proc(store: ^X509_STORE, crl: ^X509_CRL) -> i32 ---

	// X509_STORE_get0_param returns |store|'s verification parameters. This object
	// is mutable and may be modified by the caller. For an individual certificate
	// verification operation, |X509_STORE_CTX_init| initializes the
	// |X509_STORE_CTX|'s parameters with these parameters.
	//
	// WARNING: |X509_STORE_CTX_init| applies some default parameters (as in
	// |X509_VERIFY_PARAM_inherit|) after copying |store|'s parameters. This means
	// it is impossible to leave some parameters unset at |store|. They must be
	// explicitly unset after creating the |X509_STORE_CTX|.
	//
	// As of writing these late defaults are a depth limit (see
	// |X509_VERIFY_PARAM_set_depth|) and the |X509_V_FLAG_TRUSTED_FIRST| flag. This
	// warning does not apply if the parameters were set in |store|.
	//
	// TODO(crbug.com/boringssl/441): This behavior is very surprising. Can we
	// remove this notion of late defaults? The unsettable value at |X509_STORE| is
	// -1, which rejects everything but explicitly-trusted self-signed certificates.
	// |X509_V_FLAG_TRUSTED_FIRST| is mostly a workaround for poor path-building.
	X509_STORE_get0_param :: proc(store: ^X509_STORE) -> ^X509_VERIFY_PARAM ---

	// X509_STORE_set1_param copies verification parameters from |param| as in
	// |X509_VERIFY_PARAM_set1|. It returns one on success and zero on error.
	X509_STORE_set1_param :: proc(store: ^X509_STORE, param: ^X509_VERIFY_PARAM) -> i32 ---

	// X509_STORE_set_flags enables all values in |flags| in |store|'s verification
	// flags. |flags| should be a combination of |X509_V_FLAG_*| constants.
	//
	// WARNING: These flags will be combined with default flags when copied to an
	// |X509_STORE_CTX|. This means it is impossible to unset those defaults from
	// the |X509_STORE|. See discussion in |X509_STORE_get0_param|.
	X509_STORE_set_flags :: proc(store: ^X509_STORE, flags: c.ulong) -> i32 ---

	// X509_STORE_set_depth configures |store| to, by default, limit certificate
	// chains to |depth| intermediate certificates. This count excludes both the
	// target certificate and the trust anchor (root certificate).
	X509_STORE_set_depth :: proc(store: ^X509_STORE, depth: i32) -> i32 ---

	// X509_STORE_set_purpose configures the purpose check for |store|. See
	// |X509_VERIFY_PARAM_set_purpose| for details.
	X509_STORE_set_purpose :: proc(store: ^X509_STORE, purpose: i32) -> i32 ---

	// X509_STORE_set_trust configures the trust check for |store|. See
	// |X509_VERIFY_PARAM_set_trust| for details.
	X509_STORE_set_trust :: proc(store: ^X509_STORE, trust: i32) -> i32 ---
}

// The following constants indicate the type of an |X509_OBJECT|.
X509_LU_NONE :: 0
X509_LU_X509 :: 1
X509_LU_CRL  :: 2
X509_LU_PKEY :: 3

sk_X509_OBJECT_delete_if_func :: proc "c" (^X509_OBJECT, rawptr) -> i32
sk_X509_OBJECT_copy_func      :: proc "c" (^X509_OBJECT) -> ^X509_OBJECT
sk_X509_OBJECT_free_func      :: proc "c" (^X509_OBJECT)
sk_X509_OBJECT_cmp_func       :: proc "c" (^^X509_OBJECT, ^^X509_OBJECT) -> i32
stack_st_X509_OBJECT          :: struct {}

@(default_calling_convention="c")
foreign lib {
	// X509_OBJECT_new returns a newly-allocated, empty |X509_OBJECT| or NULL on
	// error.
	X509_OBJECT_new :: proc() -> ^X509_OBJECT ---

	// X509_OBJECT_free releases memory associated with |obj|.
	X509_OBJECT_free :: proc(obj: ^X509_OBJECT) ---

	// X509_OBJECT_get_type returns the type of |obj|, which will be one of the
	// |X509_LU_*| constants.
	X509_OBJECT_get_type :: proc(obj: ^X509_OBJECT) -> i32 ---

	// X509_OBJECT_get0_X509 returns |obj| as a certificate, or NULL if |obj| is not
	// a certificate.
	X509_OBJECT_get0_X509 :: proc(obj: ^X509_OBJECT) -> ^X509 ---

	// X509_STORE_get1_objects returns a newly-allocated stack containing the
	// contents of |store|, or NULL on error. The caller must release the result
	// with |sk_X509_OBJECT_pop_free| and |X509_OBJECT_free| when done.
	//
	// The result will include all certificates and CRLs added via
	// |X509_STORE_add_cert| and |X509_STORE_add_crl|, as well as any cached objects
	// added by |X509_LOOKUP_add_dir|. The last of these may change over time, as
	// different objects are loaded from the filesystem. Callers should not depend
	// on this caching behavior. The objects are returned in no particular order.
	X509_STORE_get1_objects :: proc(store: ^X509_STORE) -> ^stack_st_X509_OBJECT ---

	// X509_STORE_CTX_new returns a newly-allocated, empty |X509_STORE_CTX|, or NULL
	// on error.
	X509_STORE_CTX_new :: proc() -> ^X509_STORE_CTX ---

	// X509_STORE_CTX_free releases memory associated with |ctx|.
	X509_STORE_CTX_free :: proc(ctx: ^X509_STORE_CTX) ---

	// X509_STORE_CTX_init initializes |ctx| to verify |x509|, using trusted
	// certificates and parameters in |store|. It returns one on success and zero on
	// error. |chain| is a list of untrusted intermediate certificates to use in
	// verification.
	//
	// |ctx| stores pointers to |store|, |x509|, and |chain|. Each of these objects
	// must outlive |ctx| and may not be mutated for the duration of the certificate
	// verification.
	X509_STORE_CTX_init :: proc(ctx: ^X509_STORE_CTX, store: ^X509_STORE, x509: ^X509, chain: ^stack_st_X509) -> i32 ---

	// X509_verify_cert performs certificate verification with |ctx|, which must
	// have been initialized with |X509_STORE_CTX_init|. It returns one on success
	// and zero on error. On success, |X509_STORE_CTX_get0_chain| or
	// |X509_STORE_CTX_get1_chain| may be used to return the verified certificate
	// chain. On error, |X509_STORE_CTX_get_error| may be used to return additional
	// error information.
	//
	// WARNING: Most failure conditions from this function do not use the error
	// queue. Use |X509_STORE_CTX_get_error| to determine the cause of the error.
	X509_verify_cert :: proc(ctx: ^X509_STORE_CTX) -> i32 ---

	// X509_STORE_CTX_get0_chain, after a successful |X509_verify_cert| call,
	// returns the verified certificate chain. The chain begins with the leaf and
	// ends with trust anchor.
	//
	// At other points, such as after a failed verification or during the deprecated
	// verification callback, it returns the partial chain built so far. Callers
	// should avoid relying on this as this exposes unstable library implementation
	// details.
	X509_STORE_CTX_get0_chain :: proc(ctx: ^X509_STORE_CTX) -> ^stack_st_X509 ---

	// X509_STORE_CTX_get1_chain behaves like |X509_STORE_CTX_get0_chain| but
	// returns a newly-allocated |STACK_OF(X509)| containing the completed chain,
	// with each certificate's reference count incremented. Callers must free the
	// result with |sk_X509_pop_free| and |X509_free| when done.
	X509_STORE_CTX_get1_chain :: proc(ctx: ^X509_STORE_CTX) -> ^stack_st_X509 ---
}

// The following values are possible outputs of |X509_STORE_CTX_get_error|.
X509_V_OK                                     :: 0
X509_V_ERR_UNSPECIFIED                        :: 1
X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT          :: 2
X509_V_ERR_UNABLE_TO_GET_CRL                  :: 3
X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE   :: 4
X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE    :: 5
X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY :: 6
X509_V_ERR_CERT_SIGNATURE_FAILURE             :: 7
X509_V_ERR_CRL_SIGNATURE_FAILURE              :: 8
X509_V_ERR_CERT_NOT_YET_VALID                 :: 9
X509_V_ERR_CERT_HAS_EXPIRED                   :: 10
X509_V_ERR_CRL_NOT_YET_VALID                  :: 11
X509_V_ERR_CRL_HAS_EXPIRED                    :: 12
X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD     :: 13
X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD      :: 14
X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD     :: 15
X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD     :: 16
X509_V_ERR_OUT_OF_MEM                         :: 17
X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT        :: 18
X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN          :: 19
X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY  :: 20
X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE    :: 21
X509_V_ERR_CERT_CHAIN_TOO_LONG                :: 22
X509_V_ERR_CERT_REVOKED                       :: 23
X509_V_ERR_INVALID_CA                         :: 24
X509_V_ERR_PATH_LENGTH_EXCEEDED               :: 25
X509_V_ERR_INVALID_PURPOSE                    :: 26
X509_V_ERR_CERT_UNTRUSTED                     :: 27
X509_V_ERR_CERT_REJECTED                      :: 28
X509_V_ERR_SUBJECT_ISSUER_MISMATCH            :: 29
X509_V_ERR_AKID_SKID_MISMATCH                 :: 30
X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH        :: 31
X509_V_ERR_KEYUSAGE_NO_CERTSIGN               :: 32
X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER           :: 33
X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION       :: 34
X509_V_ERR_KEYUSAGE_NO_CRL_SIGN               :: 35
X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION   :: 36
X509_V_ERR_INVALID_NON_CA                     :: 37
X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED         :: 38
X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE      :: 39
X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED     :: 40
X509_V_ERR_INVALID_EXTENSION                  :: 41
X509_V_ERR_INVALID_POLICY_EXTENSION           :: 42
X509_V_ERR_NO_EXPLICIT_POLICY                 :: 43
X509_V_ERR_DIFFERENT_CRL_SCOPE                :: 44
X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE      :: 45
X509_V_ERR_UNNESTED_RESOURCE                  :: 46
X509_V_ERR_PERMITTED_VIOLATION                :: 47
X509_V_ERR_EXCLUDED_VIOLATION                 :: 48
X509_V_ERR_SUBTREE_MINMAX                     :: 49
X509_V_ERR_APPLICATION_VERIFICATION           :: 50
X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE        :: 51
X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX      :: 52
X509_V_ERR_UNSUPPORTED_NAME_SYNTAX            :: 53
X509_V_ERR_CRL_PATH_VALIDATION_ERROR          :: 54
X509_V_ERR_HOSTNAME_MISMATCH                  :: 62
X509_V_ERR_EMAIL_MISMATCH                     :: 63
X509_V_ERR_IP_ADDRESS_MISMATCH                :: 64
X509_V_ERR_INVALID_CALL                       :: 65
X509_V_ERR_STORE_LOOKUP                       :: 66
X509_V_ERR_NAME_CONSTRAINTS_WITHOUT_SANS      :: 67

@(default_calling_convention="c")
foreign lib {
	// X509_STORE_CTX_get_error, after |X509_verify_cert| returns, returns
	// |X509_V_OK| if verification succeeded or an |X509_V_ERR_*| describing why
	// verification failed. This will be consistent with |X509_verify_cert|'s return
	// value, unless the caller used the deprecated verification callback (see
	// |X509_STORE_CTX_set_verify_cb|) in a way that breaks |ctx|'s invariants.
	//
	// If called during the deprecated verification callback when |ok| is zero, it
	// returns the current error under consideration.
	X509_STORE_CTX_get_error :: proc(ctx: ^X509_STORE_CTX) -> i32 ---

	// X509_STORE_CTX_set_error sets |ctx|'s error to |err|, which should be
	// |X509_V_OK| or an |X509_V_ERR_*| constant. It is not expected to be called in
	// typical |X509_STORE_CTX| usage, but may be used in callback APIs where
	// applications synthesize |X509_STORE_CTX| error conditions. See also
	// |X509_STORE_CTX_set_verify_cb| and |SSL_CTX_set_cert_verify_callback|.
	X509_STORE_CTX_set_error :: proc(ctx: ^X509_STORE_CTX, err: i32) ---

	// X509_verify_cert_error_string returns |err| as a human-readable string, where
	// |err| should be one of the |X509_V_*| values. If |err| is unknown, it returns
	// a default description.
	X509_verify_cert_error_string :: proc(err: c.long) -> cstring ---

	// X509_STORE_CTX_get_error_depth returns the depth at which the error returned
	// by |X509_STORE_CTX_get_error| occurred. This is zero-indexed integer into the
	// certificate chain. Zero indicates the target certificate, one its issuer, and
	// so on.
	X509_STORE_CTX_get_error_depth :: proc(ctx: ^X509_STORE_CTX) -> i32 ---

	// X509_STORE_CTX_get_current_cert returns the certificate which caused the
	// error returned by |X509_STORE_CTX_get_error|.
	X509_STORE_CTX_get_current_cert :: proc(ctx: ^X509_STORE_CTX) -> ^X509 ---

	// X509_STORE_CTX_get0_current_crl returns the CRL which caused the error
	// returned by |X509_STORE_CTX_get_error|.
	X509_STORE_CTX_get0_current_crl :: proc(ctx: ^X509_STORE_CTX) -> ^X509_CRL ---

	// X509_STORE_CTX_get0_store returns the |X509_STORE| that |ctx| uses.
	X509_STORE_CTX_get0_store :: proc(ctx: ^X509_STORE_CTX) -> ^X509_STORE ---

	// X509_STORE_CTX_get0_cert returns the leaf certificate that |ctx| is
	// verifying.
	X509_STORE_CTX_get0_cert :: proc(ctx: ^X509_STORE_CTX) -> ^X509 ---

	// X509_STORE_CTX_get0_untrusted returns the stack of untrusted intermediates
	// used by |ctx| for certificate verification.
	X509_STORE_CTX_get0_untrusted :: proc(ctx: ^X509_STORE_CTX) -> ^stack_st_X509 ---

	// X509_STORE_CTX_set0_trusted_stack configures |ctx| to trust the certificates
	// in |sk|. |sk| must remain valid for the duration of |ctx|. Calling this
	// function causes |ctx| to ignore any certificates configured in the
	// |X509_STORE|. Certificates in |sk| are still subject to the check described
	// in |X509_VERIFY_PARAM_set_trust|.
	//
	// WARNING: This function differs from most |set0| functions in that it does not
	// take ownership of its input. The caller is required to ensure the lifetimes
	// are consistent.
	X509_STORE_CTX_set0_trusted_stack :: proc(ctx: ^X509_STORE_CTX, sk: ^stack_st_X509) ---

	// X509_STORE_CTX_set0_crls configures |ctx| to consider the CRLs in |sk| as
	// candidates for CRL lookup. |sk| must remain valid for the duration of |ctx|.
	// These CRLs are considered in addition to CRLs found in |X509_STORE|.
	//
	// WARNING: This function differs from most |set0| functions in that it does not
	// take ownership of its input. The caller is required to ensure the lifetimes
	// are consistent.
	X509_STORE_CTX_set0_crls :: proc(ctx: ^X509_STORE_CTX, sk: ^stack_st_X509_CRL) ---

	// X509_STORE_CTX_set_default looks up the set of parameters named |name| and
	// applies those default verification parameters for |ctx|. As in
	// |X509_VERIFY_PARAM_inherit|, only unset parameters are changed. This function
	// returns one on success and zero on error.
	//
	// The supported values of |name| are:
	// - "default" is an internal value which configures some late defaults. See the
	//   discussion in |X509_STORE_get0_param|.
	// - "pkcs7" configures default trust and purpose checks for PKCS#7 signatures.
	// - "smime_sign" configures trust and purpose checks for S/MIME signatures.
	// - "ssl_client" configures trust and purpose checks for TLS clients.
	// - "ssl_server" configures trust and purpose checks for TLS servers.
	//
	// TODO(crbug.com/boringssl/441): Make "default" a no-op.
	X509_STORE_CTX_set_default :: proc(ctx: ^X509_STORE_CTX, name: cstring) -> i32 ---

	// X509_STORE_CTX_get0_param returns |ctx|'s verification parameters. This
	// object is mutable and may be modified by the caller.
	X509_STORE_CTX_get0_param :: proc(ctx: ^X509_STORE_CTX) -> ^X509_VERIFY_PARAM ---

	// X509_STORE_CTX_set0_param returns |ctx|'s verification parameters to |param|
	// and takes ownership of |param|. After this function returns, the caller
	// should not free |param|.
	//
	// WARNING: This function discards any values which were previously applied in
	// |ctx|, including the "default" parameters applied late in
	// |X509_STORE_CTX_init|. These late defaults are not applied to parameters
	// created standalone by |X509_VERIFY_PARAM_new|.
	//
	// TODO(crbug.com/boringssl/441): This behavior is very surprising. Should we
	// re-apply the late defaults in |param|, or somehow avoid this notion of late
	// defaults altogether?
	X509_STORE_CTX_set0_param :: proc(ctx: ^X509_STORE_CTX, param: ^X509_VERIFY_PARAM) ---

	// X509_STORE_CTX_set_flags enables all values in |flags| in |ctx|'s
	// verification flags. |flags| should be a combination of |X509_V_FLAG_*|
	// constants.
	X509_STORE_CTX_set_flags :: proc(ctx: ^X509_STORE_CTX, flags: c.ulong) ---

	// X509_STORE_CTX_set_time configures certificate verification to use |t|
	// instead of the current time. |flags| is ignored and should be zero.
	X509_STORE_CTX_set_time :: proc(ctx: ^X509_STORE_CTX, flags: c.ulong, t: libc.time_t) ---

	// X509_STORE_CTX_set_time_posix configures certificate verification to use |t|
	// instead of the current time. |t| is interpreted as a POSIX timestamp in
	// seconds. |flags| is ignored and should be zero.
	X509_STORE_CTX_set_time_posix :: proc(ctx: ^X509_STORE_CTX, flags: c.ulong, t: i64) ---

	// X509_STORE_CTX_set_depth configures |ctx| to, by default, limit certificate
	// chains to |depth| intermediate certificates. This count excludes both the
	// target certificate and the trust anchor (root certificate).
	X509_STORE_CTX_set_depth :: proc(ctx: ^X509_STORE_CTX, depth: i32) ---

	// X509_STORE_CTX_set_purpose simultaneously configures |ctx|'s purpose and
	// trust checks, if unset. It returns one on success and zero if |purpose| is
	// not a valid purpose value. |purpose| should be an |X509_PURPOSE_*| constant.
	// If so, it configures |ctx| with a purpose check of |purpose| and a trust
	// check of |purpose|'s corresponding trust value. If either the purpose or
	// trust check had already been specified for |ctx|, that corresponding
	// modification is silently dropped.
	//
	// See |X509_VERIFY_PARAM_set_purpose| and |X509_VERIFY_PARAM_set_trust| for
	// details on the purpose and trust checks, respectively.
	//
	// If |purpose| is |X509_PURPOSE_ANY|, this function returns an error because it
	// has no corresponding |X509_TRUST_*| value. It is not possible to set
	// |X509_PURPOSE_ANY| with this function, only |X509_VERIFY_PARAM_set_purpose|.
	//
	// WARNING: Unlike similarly named functions in this header, this function
	// silently does not behave the same as |X509_VERIFY_PARAM_set_purpose|. Callers
	// may use |X509_VERIFY_PARAM_set_purpose| with |X509_STORE_CTX_get0_param| to
	// avoid this difference.
	X509_STORE_CTX_set_purpose :: proc(ctx: ^X509_STORE_CTX, purpose: i32) -> i32 ---

	// X509_STORE_CTX_set_trust configures |ctx|'s trust check, if unset. It returns
	// one on success and zero if |trust| is not a valid trust value. |trust| should
	// be an |X509_TRUST_*| constant. If so, it configures |ctx| with a trust check
	// of |trust|. If the trust check had already been specified for |ctx|, it
	// silently does nothing.
	//
	// See |X509_VERIFY_PARAM_set_trust| for details on the purpose and trust check.
	//
	// WARNING: Unlike similarly named functions in this header, this function
	// does not behave the same as |X509_VERIFY_PARAM_set_trust|. Callers may use
	// |X509_VERIFY_PARAM_set_trust| with |X509_STORE_CTX_get0_param| to avoid this
	// difference.
	X509_STORE_CTX_set_trust :: proc(ctx: ^X509_STORE_CTX, trust: i32) -> i32 ---

	// X509_VERIFY_PARAM_new returns a newly-allocated |X509_VERIFY_PARAM|, or NULL
	// on error.
	X509_VERIFY_PARAM_new :: proc() -> ^X509_VERIFY_PARAM ---

	// X509_VERIFY_PARAM_free releases memory associated with |param|.
	X509_VERIFY_PARAM_free :: proc(param: ^X509_VERIFY_PARAM) ---

	// X509_VERIFY_PARAM_inherit applies |from| as the default values for |to|. That
	// is, for each parameter that is unset in |to|, it copies the value in |from|.
	// This function returns one on success and zero on error.
	X509_VERIFY_PARAM_inherit :: proc(to: ^X509_VERIFY_PARAM, from: ^X509_VERIFY_PARAM) -> i32 ---

	// X509_VERIFY_PARAM_set1 copies parameters from |from| to |to|. If a parameter
	// is unset in |from|, the existing value in |to| is preserved. This function
	// returns one on success and zero on error.
	X509_VERIFY_PARAM_set1 :: proc(to: ^X509_VERIFY_PARAM, from: ^X509_VERIFY_PARAM) -> i32 ---
}

// X509_V_FLAG_* are flags for |X509_VERIFY_PARAM_set_flags| and
// |X509_VERIFY_PARAM_clear_flags|.

// X509_V_FLAG_CB_ISSUER_CHECK causes the deprecated verify callback (see
// |X509_STORE_CTX_set_verify_cb|) to be called for errors while matching
// subject and issuer certificates.
X509_V_FLAG_CB_ISSUER_CHECK :: 0x1

// X509_V_FLAG_USE_CHECK_TIME is an internal flag used to track whether
// |X509_STORE_CTX_set_time| has been used. If cleared, the system time is
// restored.
X509_V_FLAG_USE_CHECK_TIME :: 0x2

// X509_V_FLAG_CRL_CHECK enables CRL lookup and checking for the leaf.
X509_V_FLAG_CRL_CHECK :: 0x4

// X509_V_FLAG_CRL_CHECK_ALL enables CRL lookup and checking for the entire
// certificate chain. |X509_V_FLAG_CRL_CHECK| must be set for this flag to take
// effect.
X509_V_FLAG_CRL_CHECK_ALL :: 0x8

// X509_V_FLAG_IGNORE_CRITICAL ignores unhandled critical extensions. Do not use
// this option. Critical extensions ensure the verifier does not bypass
// unrecognized security restrictions in certificates.
X509_V_FLAG_IGNORE_CRITICAL :: 0x10

// X509_V_FLAG_X509_STRICT does nothing. Its functionality has been enabled by
// default.
X509_V_FLAG_X509_STRICT :: 0x00

// X509_V_FLAG_ALLOW_PROXY_CERTS does nothing. Proxy certificate support has
// been removed.
X509_V_FLAG_ALLOW_PROXY_CERTS :: 0x40

// X509_V_FLAG_POLICY_CHECK does nothing. Policy checking is always enabled.
X509_V_FLAG_POLICY_CHECK :: 0x80

// X509_V_FLAG_EXPLICIT_POLICY requires some policy OID to be asserted by the
// final certificate chain. See initial-explicit-policy from RFC 5280,
// section 6.1.1.
X509_V_FLAG_EXPLICIT_POLICY :: 0x100

// X509_V_FLAG_INHIBIT_ANY inhibits the anyPolicy OID. See
// initial-any-policy-inhibit from RFC 5280, section 6.1.1.
X509_V_FLAG_INHIBIT_ANY :: 0x200

// X509_V_FLAG_INHIBIT_MAP inhibits policy mapping. See
// initial-policy-mapping-inhibit from RFC 5280, section 6.1.1.
X509_V_FLAG_INHIBIT_MAP :: 0x400

// X509_V_FLAG_NOTIFY_POLICY does nothing. Its functionality has been removed.
X509_V_FLAG_NOTIFY_POLICY :: 0x800

// X509_V_FLAG_EXTENDED_CRL_SUPPORT causes all verifications to fail. Extended
// CRL features have been removed.
X509_V_FLAG_EXTENDED_CRL_SUPPORT :: 0x1000

// X509_V_FLAG_USE_DELTAS causes all verifications to fail. Delta CRL support
// has been removed.
X509_V_FLAG_USE_DELTAS :: 0x2000

// X509_V_FLAG_CHECK_SS_SIGNATURE checks the redundant signature on self-signed
// trust anchors. This check provides no security benefit and only wastes CPU.
X509_V_FLAG_CHECK_SS_SIGNATURE :: 0x4000

// X509_V_FLAG_TRUSTED_FIRST, during path-building, checks for a match in the
// trust store before considering an untrusted intermediate. This flag is
// enabled by default.
X509_V_FLAG_TRUSTED_FIRST :: 0x8000

// X509_V_FLAG_PARTIAL_CHAIN treats all trusted certificates as trust anchors,
// independent of the |X509_VERIFY_PARAM_set_trust| setting.
X509_V_FLAG_PARTIAL_CHAIN :: 0x80000

// X509_V_FLAG_NO_ALT_CHAINS disables building alternative chains if the initial
// one was rejected.
X509_V_FLAG_NO_ALT_CHAINS :: 0x100000

// X509_V_FLAG_NO_CHECK_TIME disables all time checks in certificate
// verification.
X509_V_FLAG_NO_CHECK_TIME :: 0x200000

@(default_calling_convention="c")
foreign lib {
	// X509_VERIFY_PARAM_set_flags enables all values in |flags| in |param|'s
	// verification flags and returns one. |flags| should be a combination of
	// |X509_V_FLAG_*| constants.
	X509_VERIFY_PARAM_set_flags :: proc(param: ^X509_VERIFY_PARAM, flags: c.ulong) -> i32 ---

	// X509_VERIFY_PARAM_clear_flags disables all values in |flags| in |param|'s
	// verification flags and returns one. |flags| should be a combination of
	// |X509_V_FLAG_*| constants.
	X509_VERIFY_PARAM_clear_flags :: proc(param: ^X509_VERIFY_PARAM, flags: c.ulong) -> i32 ---

	// X509_VERIFY_PARAM_get_flags returns |param|'s verification flags.
	X509_VERIFY_PARAM_get_flags :: proc(param: ^X509_VERIFY_PARAM) -> c.ulong ---

	// X509_VERIFY_PARAM_set_depth configures |param| to limit certificate chains to
	// |depth| intermediate certificates. This count excludes both the target
	// certificate and the trust anchor (root certificate).
	X509_VERIFY_PARAM_set_depth :: proc(param: ^X509_VERIFY_PARAM, depth: i32) ---

	// X509_VERIFY_PARAM_get_depth returns the maximum depth configured in |param|.
	// See |X509_VERIFY_PARAM_set_depth|.
	X509_VERIFY_PARAM_get_depth :: proc(param: ^X509_VERIFY_PARAM) -> i32 ---

	// X509_VERIFY_PARAM_set_time configures certificate verification to use |t|
	// instead of the current time.
	X509_VERIFY_PARAM_set_time :: proc(param: ^X509_VERIFY_PARAM, t: libc.time_t) ---

	// X509_VERIFY_PARAM_set_time_posix configures certificate verification to use
	// |t| instead of the current time. |t| is interpreted as a POSIX timestamp in
	// seconds.
	X509_VERIFY_PARAM_set_time_posix :: proc(param: ^X509_VERIFY_PARAM, t: i64) ---

	// X509_VERIFY_PARAM_add0_policy adds |policy| to the user-initial-policy-set
	// (see Section 6.1.1 of RFC 5280). On success, it takes ownership of
	// |policy| and returns one. Otherwise, it returns zero and the caller retains
	// owneship of |policy|.
	X509_VERIFY_PARAM_add0_policy :: proc(param: ^X509_VERIFY_PARAM, policy: ^ASN1_OBJECT) -> i32 ---

	// X509_VERIFY_PARAM_set1_policies sets the user-initial-policy-set (see
	// Section 6.1.1 of RFC 5280) to a copy of |policies|. It returns one on success
	// and zero on error.
	X509_VERIFY_PARAM_set1_policies :: proc(param: ^X509_VERIFY_PARAM, policies: ^stack_st_ASN1_OBJECT) -> i32 ---

	// X509_VERIFY_PARAM_set1_host configures |param| to check for the DNS name
	// specified by |name|. It returns one on success and zero on error.
	//
	// By default, both subject alternative names and the subject's common name
	// attribute are checked. The latter has long been deprecated, so callers should
	// call |X509_VERIFY_PARAM_set_hostflags| with
	// |X509_CHECK_FLAG_NEVER_CHECK_SUBJECT| to use the standard behavior.
	// https://crbug.com/boringssl/464 tracks fixing the default.
	X509_VERIFY_PARAM_set1_host :: proc(param: ^X509_VERIFY_PARAM, name: cstring, name_len: c.size_t) -> i32 ---

	// X509_VERIFY_PARAM_add1_host adds |name| to the list of names checked by
	// |param|. If any configured DNS name matches the certificate, verification
	// succeeds. It returns one on success and zero on error.
	//
	// By default, both subject alternative names and the subject's common name
	// attribute are checked. The latter has long been deprecated, so callers should
	// call |X509_VERIFY_PARAM_set_hostflags| with
	// |X509_CHECK_FLAG_NEVER_CHECK_SUBJECT| to use the standard behavior.
	// https://crbug.com/boringssl/464 tracks fixing the default.
	X509_VERIFY_PARAM_add1_host :: proc(param: ^X509_VERIFY_PARAM, name: cstring, name_len: c.size_t) -> i32 ---
}

// X509_CHECK_FLAG_NO_WILDCARDS disables wildcard matching for DNS names.
X509_CHECK_FLAG_NO_WILDCARDS :: 0x2

// X509_CHECK_FLAG_NEVER_CHECK_SUBJECT disables the subject fallback, normally
// enabled when subjectAltNames is missing.
X509_CHECK_FLAG_NEVER_CHECK_SUBJECT :: 0x20

@(default_calling_convention="c")
foreign lib {
	// X509_VERIFY_PARAM_set_hostflags sets the name-checking flags on |param| to
	// |flags|. |flags| should be a combination of |X509_CHECK_FLAG_*| constants.
	X509_VERIFY_PARAM_set_hostflags :: proc(param: ^X509_VERIFY_PARAM, flags: u32) ---

	// X509_VERIFY_PARAM_set1_email configures |param| to check for the email
	// address specified by |email|. It returns one on success and zero on error.
	//
	// By default, both subject alternative names and the subject's email address
	// attribute are checked. The |X509_CHECK_FLAG_NEVER_CHECK_SUBJECT| flag may be
	// used to change this behavior.
	X509_VERIFY_PARAM_set1_email :: proc(param: ^X509_VERIFY_PARAM, email: cstring, email_len: c.size_t) -> i32 ---

	// X509_VERIFY_PARAM_set1_ip configures |param| to check for the IP address
	// specified by |ip|. It returns one on success and zero on error. The IP
	// address is specified in its binary representation. |ip_len| must be 4 for an
	// IPv4 address and 16 for an IPv6 address.
	X509_VERIFY_PARAM_set1_ip :: proc(param: ^X509_VERIFY_PARAM, ip: ^u8, ip_len: c.size_t) -> i32 ---

	// X509_VERIFY_PARAM_set1_ip_asc decodes |ipasc| as the ASCII representation of
	// an IPv4 or IPv6 address, and configures |param| to check for it. It returns
	// one on success and zero on error.
	X509_VERIFY_PARAM_set1_ip_asc :: proc(param: ^X509_VERIFY_PARAM, ipasc: cstring) -> i32 ---
}

// X509_PURPOSE_SSL_CLIENT validates TLS client certificates. It checks for the
// id-kp-clientAuth EKU and one of digitalSignature or keyAgreement key usages.
// The TLS library is expected to check for the key usage specific to the
// negotiated TLS parameters.
X509_PURPOSE_SSL_CLIENT :: 1

// X509_PURPOSE_SSL_SERVER validates TLS server certificates. It checks for the
// id-kp-clientAuth EKU and one of digitalSignature, keyAgreement, or
// keyEncipherment key usages. The TLS library is expected to check for the key
// usage specific to the negotiated TLS parameters.
X509_PURPOSE_SSL_SERVER :: 2

// X509_PURPOSE_NS_SSL_SERVER is a legacy mode. It behaves like
// |X509_PURPOSE_SSL_SERVER|, but only accepts the keyEncipherment key usage,
// used by SSL 2.0 and RSA key exchange. Do not use this.
X509_PURPOSE_NS_SSL_SERVER :: 3

// X509_PURPOSE_SMIME_SIGN validates S/MIME signing certificates. It checks for
// the id-kp-emailProtection EKU and one of digitalSignature or nonRepudiation
// key usages.
X509_PURPOSE_SMIME_SIGN :: 4

// X509_PURPOSE_SMIME_ENCRYPT validates S/MIME encryption certificates. It
// checks for the id-kp-emailProtection EKU and keyEncipherment key usage.
X509_PURPOSE_SMIME_ENCRYPT :: 5

// X509_PURPOSE_CRL_SIGN validates indirect CRL signers. It checks for the
// cRLSign key usage. BoringSSL does not support indirect CRLs and does not use
// this mode.
X509_PURPOSE_CRL_SIGN :: 6

// X509_PURPOSE_ANY performs no EKU or key usage checks. Such checks are the
// responsibility of the caller.
X509_PURPOSE_ANY :: 7

// X509_PURPOSE_OCSP_HELPER performs no EKU or key usage checks. It was
// historically used in OpenSSL's OCSP implementation, which left those checks
// to the OCSP implementation itself.
X509_PURPOSE_OCSP_HELPER :: 8

// X509_PURPOSE_TIMESTAMP_SIGN validates Time Stamping Authority (RFC 3161)
// certificates. It checks for the id-kp-timeStamping EKU and one of
// digitalSignature or nonRepudiation key usages. It additionally checks that
// the EKU extension is critical and that no other EKUs or key usages are
// asserted.
X509_PURPOSE_TIMESTAMP_SIGN :: 9

@(default_calling_convention="c")
foreign lib {
	// X509_VERIFY_PARAM_set_purpose configures |param| to validate certificates for
	// a specified purpose. It returns one on success and zero if |purpose| is not a
	// valid purpose type. |purpose| should be one of the |X509_PURPOSE_*| values.
	//
	// This option controls checking the extended key usage (EKU) and key usage
	// extensions. These extensions specify how a certificate's public key may be
	// used and are important to avoid cross-protocol attacks, particularly in PKIs
	// that may issue certificates for multiple protocols, or for protocols that use
	// keys in multiple ways. If not configured, these security checks are the
	// caller's responsibility.
	//
	// This library applies the EKU checks to all untrusted intermediates. Although
	// not defined in RFC 5280, this matches widely-deployed practice. It also does
	// not accept anyExtendedKeyUsage.
	//
	// Many purpose values have a corresponding trust value, which is not configured
	// by this function.  See |X509_VERIFY_PARAM_set_trust| for details. Callers
	// that wish to configure both should either call both functions, or use
	// |X509_STORE_CTX_set_purpose|.
	//
	// It is currently not possible to configure custom EKU OIDs or key usage bits.
	// Contact the BoringSSL maintainers if your application needs to do so. OpenSSL
	// had an |X509_PURPOSE_add| API, but it was not thread-safe and relied on
	// global mutable state, so we removed it.
	//
	// TODO(davidben): This function additionally configures checking the legacy
	// Netscape certificate type extension. Remove this.
	X509_VERIFY_PARAM_set_purpose :: proc(param: ^X509_VERIFY_PARAM, purpose: i32) -> i32 ---
}

// X509_TRUST_COMPAT evaluates trust using only the self-signed fallback. Trust
// and distrust OIDs are ignored.
X509_TRUST_COMPAT :: 1

// X509_TRUST_SSL_CLIENT evaluates trust with the |NID_client_auth| OID, for
// validating TLS client certificates.
X509_TRUST_SSL_CLIENT :: 2

// X509_TRUST_SSL_SERVER evaluates trust with the |NID_server_auth| OID, for
// validating TLS server certificates.
X509_TRUST_SSL_SERVER :: 3

// X509_TRUST_EMAIL evaluates trust with the |NID_email_protect| OID, for
// validating S/MIME email certificates.
X509_TRUST_EMAIL :: 4

// X509_TRUST_OBJECT_SIGN evaluates trust with the |NID_code_sign| OID, for
// validating code signing certificates.
X509_TRUST_OBJECT_SIGN :: 5

// X509_TRUST_TSA evaluates trust with the |NID_time_stamp| OID, for validating
// Time Stamping Authority (RFC 3161) certificates.
X509_TRUST_TSA :: 8

@(default_calling_convention="c")
foreign lib {
	// X509_VERIFY_PARAM_set_trust configures which certificates from |X509_STORE|
	// are trust anchors. It returns one on success and zero if |trust| is not a
	// valid trust value. |trust| should be one of the |X509_TRUST_*| constants.
	// This function allows applications to vary trust anchors when the same set of
	// trusted certificates is used in multiple contexts.
	//
	// Two properties determine whether a certificate is a trust anchor:
	//
	// - Whether it is trusted or distrusted for some OID, via auxiliary information
	//   configured by |X509_add1_trust_object| or |X509_add1_reject_object|.
	//
	// - Whether it is "self-signed". That is, whether |X509_get_extension_flags|
	//   includes |EXFLAG_SS|. The signature itself is not checked.
	//
	// When this function is called, |trust| determines the OID to check in the
	// first case. If the certificate is not explicitly trusted or distrusted for
	// any OID, it is trusted if self-signed instead.
	//
	// If unset, the default behavior is to check for the |NID_anyExtendedKeyUsage|
	// OID. If the certificate is not explicitly trusted or distrusted for this OID,
	// it is trusted if self-signed instead. Note this slightly differs from the
	// above.
	//
	// If the |X509_V_FLAG_PARTIAL_CHAIN| is set, every certificate from
	// |X509_STORE| is a trust anchor, unless it was explicitly distrusted for the
	// OID.
	//
	// It is currently not possible to configure custom trust OIDs. Contact the
	// BoringSSL maintainers if your application needs to do so. OpenSSL had an
	// |X509_TRUST_add| API, but it was not thread-safe and relied on global mutable
	// state, so we removed it.
	X509_VERIFY_PARAM_set_trust :: proc(param: ^X509_VERIFY_PARAM, trust: i32) -> i32 ---

	// X509_STORE_load_locations configures |store| to load data from filepaths
	// |file| and |dir|. It returns one on success and zero on error. Either of
	// |file| or |dir| may be NULL, but at least one must be non-NULL.
	//
	// If |file| is non-NULL, it loads CRLs and trusted certificates in PEM format
	// from the file at |file|, and them to |store|, as in |X509_load_cert_crl_file|
	// with |X509_FILETYPE_PEM|.
	//
	// If |dir| is non-NULL, it configures |store| to load CRLs and trusted
	// certificates from the directory at |dir| in PEM format, as in
	// |X509_LOOKUP_add_dir| with |X509_FILETYPE_PEM|.
	X509_STORE_load_locations :: proc(store: ^X509_STORE, file: cstring, dir: cstring) -> i32 ---

	// X509_STORE_add_lookup returns an |X509_LOOKUP| associated with |store| with
	// type |method|, or NULL on error. The result is owned by |store|, so callers
	// are not expected to free it. This may be used with |X509_LOOKUP_add_dir| or
	// |X509_LOOKUP_load_file|, depending on |method|, to configure |store|.
	//
	// A single |X509_LOOKUP| may be configured with multiple paths, and an
	// |X509_STORE| only contains one |X509_LOOKUP| of each type, so there is no
	// need to call this function multiple times for a single type. Calling it
	// multiple times will return the previous |X509_LOOKUP| of that type.
	X509_STORE_add_lookup :: proc(store: ^X509_STORE, method: ^X509_LOOKUP_METHOD) -> ^X509_LOOKUP ---

	// X509_LOOKUP_hash_dir creates |X509_LOOKUP|s that may be used with
	// |X509_LOOKUP_add_dir|.
	X509_LOOKUP_hash_dir :: proc() -> ^X509_LOOKUP_METHOD ---

	// X509_LOOKUP_file creates |X509_LOOKUP|s that may be used with
	// |X509_LOOKUP_load_file|.
	//
	// Although this is modeled as an |X509_LOOKUP|, this function is redundant. It
	// has the same effect as loading a certificate or CRL from the filesystem, in
	// the caller's desired format, and then adding it with |X509_STORE_add_cert|
	// and |X509_STORE_add_crl|.
	X509_LOOKUP_file :: proc() -> ^X509_LOOKUP_METHOD ---
}

// The following constants are used to specify the format of files in an
// |X509_LOOKUP|.
X509_FILETYPE_PEM     :: 1
X509_FILETYPE_ASN1    :: 2
X509_FILETYPE_DEFAULT :: 3

@(default_calling_convention="c")
foreign lib {
	// X509_LOOKUP_load_file calls |X509_load_cert_crl_file|. |lookup| must have
	// been constructed with |X509_LOOKUP_file|.
	//
	// If |type| is |X509_FILETYPE_DEFAULT|, it ignores |file| and instead uses some
	// default system path with |X509_FILETYPE_PEM|. See also
	// |X509_STORE_set_default_paths|.
	X509_LOOKUP_load_file :: proc(lookup: ^X509_LOOKUP, file: cstring, type: i32) -> i32 ---

	// X509_LOOKUP_add_dir configures |lookup| to load CRLs and trusted certificates
	// from the directories in |path|. It returns one on success and zero on error.
	// |lookup| must have been constructed with |X509_LOOKUP_hash_dir|.
	//
	// WARNING: |path| is interpreted as a colon-separated (semicolon-separated on
	// Windows) list of paths. It is not possible to configure a path containing the
	// separator character. https://crbug.com/boringssl/691 tracks removing this
	// behavior.
	//
	// |type| should be one of the |X509_FILETYPE_*| constants and determines the
	// format of the files. If |type| is |X509_FILETYPE_DEFAULT|, |path| is ignored
	// and some default system path is used with |X509_FILETYPE_PEM|. See also
	// |X509_STORE_set_default_paths|.
	//
	// Trusted certificates should be named HASH.N and CRLs should be
	// named HASH.rN. HASH is |X509_NAME_hash| of the certificate subject and CRL
	// issuer, respectively, in hexadecimal. N is in decimal and counts hash
	// collisions consecutively, starting from zero. For example, "002c0b4f.0" and
	// "002c0b4f.r0".
	//
	// WARNING: Objects from |path| are loaded on demand, but cached in memory on
	// the |X509_STORE|. If a CA is removed from the directory, existing
	// |X509_STORE|s will continue to trust it. Cache entries are not evicted for
	// the lifetime of the |X509_STORE|.
	//
	// WARNING: This mechanism is also not well-suited for CRL updates.
	// |X509_STORE|s rely on this cache and never load the same CRL file twice. CRL
	// updates must use a new file, with an incremented suffix, to be reflected in
	// existing |X509_STORE|s. However, this means each CRL update will use
	// additional storage and memory. Instead, configure inputs that vary per
	// verification, such as CRLs, on each |X509_STORE_CTX| separately, using
	// functions like |X509_STORE_CTX_set0_crl|.
	X509_LOOKUP_add_dir :: proc(lookup: ^X509_LOOKUP, path: cstring, type: i32) -> i32 ---
}

// X509_L_* are commands for |X509_LOOKUP_ctrl|.
X509_L_FILE_LOAD :: 1
X509_L_ADD_DIR   :: 2

@(default_calling_convention="c")
foreign lib {
	// X509_LOOKUP_ctrl implements commands on |lookup|. |cmd| specifies the
	// command. The other arguments specify the operation in a command-specific way.
	// Use |X509_LOOKUP_load_file| or |X509_LOOKUP_add_dir| instead.
	X509_LOOKUP_ctrl :: proc(lookup: ^X509_LOOKUP, cmd: i32, argc: cstring, argl: c.long, ret: ^cstring) -> i32 ---

	// X509_load_cert_file loads trusted certificates from |file| and adds them to
	// |lookup|'s |X509_STORE|. It returns one on success and zero on error.
	//
	// If |type| is |X509_FILETYPE_ASN1|, it loads a single DER-encoded certificate.
	// If |type| is |X509_FILETYPE_PEM|, it loads a sequence of PEM-encoded
	// certificates. |type| may not be |X509_FILETYPE_DEFAULT|.
	X509_load_cert_file :: proc(lookup: ^X509_LOOKUP, file: cstring, type: i32) -> i32 ---

	// X509_load_crl_file loads CRLs from |file| and add them it to |lookup|'s
	// |X509_STORE|. It returns one on success and zero on error.
	//
	// If |type| is |X509_FILETYPE_ASN1|, it loads a single DER-encoded CRL. If
	// |type| is |X509_FILETYPE_PEM|, it loads a sequence of PEM-encoded CRLs.
	// |type| may not be |X509_FILETYPE_DEFAULT|.
	X509_load_crl_file :: proc(lookup: ^X509_LOOKUP, file: cstring, type: i32) -> i32 ---

	// X509_load_cert_crl_file loads CRLs and trusted certificates from |file| and
	// adds them to |lookup|'s |X509_STORE|. It returns one on success and zero on
	// error.
	//
	// If |type| is |X509_FILETYPE_ASN1|, it loads a single DER-encoded certificate.
	// This function cannot be used to load a DER-encoded CRL. If |type| is
	// |X509_FILETYPE_PEM|, it loads a sequence of PEM-encoded certificates and
	// CRLs. |type| may not be |X509_FILETYPE_DEFAULT|.
	X509_load_cert_crl_file :: proc(lookup: ^X509_LOOKUP, file: cstring, type: i32) -> i32 ---

	// X509_NAME_hash returns a hash of |name|, or zero on error. This is the new
	// hash used by |X509_LOOKUP_add_dir|.
	//
	// This hash is specific to the |X509_LOOKUP_add_dir| filesystem format and is
	// not suitable for general-purpose X.509 name processing. It is very short, so
	// there will be hash collisions. It also depends on an OpenSSL-specific
	// canonicalization process.
	X509_NAME_hash :: proc(name: ^X509_NAME) -> u32 ---

	// X509_NAME_hash_old returns a hash of |name|, or zero on error. This is the
	// legacy hash used by |X509_LOOKUP_add_dir|, which is still supported for
	// compatibility.
	//
	// This hash is specific to the |X509_LOOKUP_add_dir| filesystem format and is
	// not suitable for general-purpose X.509 name processing. It is very short, so
	// there will be hash collisions.
	X509_NAME_hash_old :: proc(name: ^X509_NAME) -> u32 ---

	// X509_STORE_set_default_paths configures |store| to read from some "default"
	// filesystem paths. It returns one on success and zero on error. The filesystem
	// paths are determined by a combination of hardcoded paths and the SSL_CERT_DIR
	// and SSL_CERT_FILE environment variables.
	//
	// Using this function is not recommended. In OpenSSL, these defaults are
	// determined by OpenSSL's install prefix. There is no corresponding concept for
	// BoringSSL. Future versions of BoringSSL may change or remove this
	// functionality.
	X509_STORE_set_default_paths :: proc(store: ^X509_STORE) -> i32 ---

	// The following functions return filesystem paths used to determine the above
	// "default" paths, when the corresponding environment variables are not set.
	//
	// Using these functions is not recommended. In OpenSSL, these defaults are
	// determined by OpenSSL's install prefix. There is no corresponding concept for
	// BoringSSL. Future versions of BoringSSL may change or remove this
	// functionality.
	X509_get_default_cert_area   :: proc() -> cstring ---
	X509_get_default_cert_dir    :: proc() -> cstring ---
	X509_get_default_cert_file   :: proc() -> cstring ---
	X509_get_default_private_dir :: proc() -> cstring ---

	// X509_get_default_cert_dir_env returns "SSL_CERT_DIR", an environment variable
	// used to determine the above "default" paths.
	X509_get_default_cert_dir_env :: proc() -> cstring ---

	// X509_get_default_cert_file_env returns "SSL_CERT_FILE", an environment
	// variable used to determine the above "default" paths.
	X509_get_default_cert_file_env :: proc() -> cstring ---
}

// A Netscape_spki_st, or |NETSCAPE_SPKI|, represents a
// SignedPublicKeyAndChallenge structure. Although this structure contains a
// |spkac| field of type |NETSCAPE_SPKAC|, these are misnamed. The SPKAC is the
// entire structure, not the signed portion.
Netscape_spki_st :: struct {
	spkac:     ^NETSCAPE_SPKAC,
	sig_algor: ^X509_ALGOR,
	signature: ^ASN1_BIT_STRING,
}

@(default_calling_convention="c")
foreign lib {
	// NETSCAPE_SPKI_new returns a newly-allocated, empty |NETSCAPE_SPKI| object, or
	// NULL on error.
	NETSCAPE_SPKI_new :: proc() -> ^NETSCAPE_SPKI ---

	// NETSCAPE_SPKI_free releases memory associated with |spki|.
	NETSCAPE_SPKI_free :: proc(spki: ^NETSCAPE_SPKI) ---

	// d2i_NETSCAPE_SPKI parses up to |len| bytes from |*inp| as a DER-encoded
	// SignedPublicKeyAndChallenge structure, as described in |d2i_SAMPLE|.
	d2i_NETSCAPE_SPKI :: proc(out: ^^NETSCAPE_SPKI, inp: ^^u8, len: c.long) -> ^NETSCAPE_SPKI ---

	// i2d_NETSCAPE_SPKI marshals |spki| as a DER-encoded
	// SignedPublicKeyAndChallenge structure, as described in |i2d_SAMPLE|.
	i2d_NETSCAPE_SPKI :: proc(spki: ^NETSCAPE_SPKI, outp: ^^u8) -> i32 ---

	// NETSCAPE_SPKI_verify checks that |spki| has a valid signature by |pkey|. It
	// returns one if the signature is valid and zero otherwise.
	NETSCAPE_SPKI_verify :: proc(spki: ^NETSCAPE_SPKI, pkey: ^EVP_PKEY) -> i32 ---

	// NETSCAPE_SPKI_b64_decode decodes |len| bytes from |str| as a base64-encoded
	// SignedPublicKeyAndChallenge structure. It returns a newly-allocated
	// |NETSCAPE_SPKI| structure with the result, or NULL on error. If |len| is 0 or
	// negative, the length is calculated with |strlen| and |str| must be a
	// NUL-terminated C string.
	NETSCAPE_SPKI_b64_decode :: proc(str: cstring, len: ossl_ssize_t) -> ^NETSCAPE_SPKI ---

	// NETSCAPE_SPKI_b64_encode encodes |spki| as a base64-encoded
	// SignedPublicKeyAndChallenge structure. It returns a newly-allocated
	// NUL-terminated C string with the result, or NULL on error. The caller must
	// release the memory with |OPENSSL_free| when done.
	NETSCAPE_SPKI_b64_encode :: proc(spki: ^NETSCAPE_SPKI) -> cstring ---

	// NETSCAPE_SPKI_get_pubkey decodes and returns the public key in |spki| as an
	// |EVP_PKEY|, or NULL on error. The caller takes ownership of the resulting
	// pointer and must call |EVP_PKEY_free| when done.
	NETSCAPE_SPKI_get_pubkey :: proc(spki: ^NETSCAPE_SPKI) -> ^EVP_PKEY ---

	// NETSCAPE_SPKI_set_pubkey sets |spki|'s public key to |pkey|. It returns one
	// on success or zero on error. This function does not take ownership of |pkey|,
	// so the caller may continue to manage its lifetime independently of |spki|.
	NETSCAPE_SPKI_set_pubkey :: proc(spki: ^NETSCAPE_SPKI, pkey: ^EVP_PKEY) -> i32 ---

	// NETSCAPE_SPKI_sign signs |spki| with |pkey| and replaces the signature
	// algorithm and signature fields. It returns the length of the signature on
	// success and zero on error. This function uses digest algorithm |md|, or
	// |pkey|'s default if NULL. Other signing parameters use |pkey|'s defaults.
	NETSCAPE_SPKI_sign :: proc(spki: ^NETSCAPE_SPKI, pkey: ^EVP_PKEY, md: ^EVP_MD) -> i32 ---
}

// A Netscape_spkac_st, or |NETSCAPE_SPKAC|, represents a PublicKeyAndChallenge
// structure. This type is misnamed. The full SPKAC includes the signature,
// which is represented with the |NETSCAPE_SPKI| type.
Netscape_spkac_st :: struct {
	pubkey:    ^X509_PUBKEY,
	challenge: ^ASN1_IA5STRING,
}

@(default_calling_convention="c")
foreign lib {
	// NETSCAPE_SPKAC_new returns a newly-allocated, empty |NETSCAPE_SPKAC| object,
	// or NULL on error.
	NETSCAPE_SPKAC_new :: proc() -> ^NETSCAPE_SPKAC ---

	// NETSCAPE_SPKAC_free releases memory associated with |spkac|.
	NETSCAPE_SPKAC_free :: proc(spkac: ^NETSCAPE_SPKAC) ---

	// d2i_NETSCAPE_SPKAC parses up to |len| bytes from |*inp| as a DER-encoded
	// PublicKeyAndChallenge structure, as described in |d2i_SAMPLE|.
	d2i_NETSCAPE_SPKAC :: proc(out: ^^NETSCAPE_SPKAC, inp: ^^u8, len: c.long) -> ^NETSCAPE_SPKAC ---

	// i2d_NETSCAPE_SPKAC marshals |spkac| as a DER-encoded PublicKeyAndChallenge
	// structure, as described in |i2d_SAMPLE|.
	i2d_NETSCAPE_SPKAC :: proc(spkac: ^NETSCAPE_SPKAC, outp: ^^u8) -> i32 ---
}

// An rsa_pss_params_st, aka |RSA_PSS_PARAMS|, represents a parsed
// RSASSA-PSS-params structure, as defined in (RFC 4055).
rsa_pss_params_st :: struct {
	hashAlgorithm:    ^X509_ALGOR,
	maskGenAlgorithm: ^X509_ALGOR,
	saltLength:       ^ASN1_INTEGER,
	trailerField:     ^ASN1_INTEGER,

	// OpenSSL caches the MGF hash on |RSA_PSS_PARAMS| in some cases. None of the
	// cases apply to BoringSSL, so this is always NULL, but Node expects the
	// field to be present.
	maskHash: ^X509_ALGOR,
}

@(default_calling_convention="c")
foreign lib {
	// RSA_PSS_PARAMS_new returns a new, empty |RSA_PSS_PARAMS|, or NULL on error.
	RSA_PSS_PARAMS_new :: proc() -> ^RSA_PSS_PARAMS ---

	// RSA_PSS_PARAMS_free releases memory associated with |params|.
	RSA_PSS_PARAMS_free :: proc(params: ^RSA_PSS_PARAMS) ---

	// d2i_RSA_PSS_PARAMS parses up to |len| bytes from |*inp| as a DER-encoded
	// RSASSA-PSS-params (RFC 4055), as described in |d2i_SAMPLE|.
	d2i_RSA_PSS_PARAMS :: proc(out: ^^RSA_PSS_PARAMS, inp: ^^u8, len: c.long) -> ^RSA_PSS_PARAMS ---

	// i2d_RSA_PSS_PARAMS marshals |in| as a DER-encoded RSASSA-PSS-params (RFC
	// 4055), as described in |i2d_SAMPLE|.
	i2d_RSA_PSS_PARAMS :: proc(_in: ^RSA_PSS_PARAMS, outp: ^^u8) -> i32 ---

	// PKCS8_PRIV_KEY_INFO_new returns a newly-allocated, empty
	// |PKCS8_PRIV_KEY_INFO| object, or NULL on error.
	PKCS8_PRIV_KEY_INFO_new :: proc() -> ^PKCS8_PRIV_KEY_INFO ---

	// PKCS8_PRIV_KEY_INFO_free releases memory associated with |key|.
	PKCS8_PRIV_KEY_INFO_free :: proc(key: ^PKCS8_PRIV_KEY_INFO) ---

	// d2i_PKCS8_PRIV_KEY_INFO parses up to |len| bytes from |*inp| as a DER-encoded
	// PrivateKeyInfo, as described in |d2i_SAMPLE|.
	d2i_PKCS8_PRIV_KEY_INFO :: proc(out: ^^PKCS8_PRIV_KEY_INFO, inp: ^^u8, len: c.long) -> ^PKCS8_PRIV_KEY_INFO ---

	// i2d_PKCS8_PRIV_KEY_INFO marshals |key| as a DER-encoded PrivateKeyInfo, as
	// described in |i2d_SAMPLE|.
	i2d_PKCS8_PRIV_KEY_INFO :: proc(key: ^PKCS8_PRIV_KEY_INFO, outp: ^^u8) -> i32 ---

	// EVP_PKCS82PKEY returns |p8| as a newly-allocated |EVP_PKEY|, or NULL if the
	// key was unsupported or could not be decoded. The caller must release the
	// result with |EVP_PKEY_free| when done.
	//
	// Use |EVP_parse_private_key| instead.
	EVP_PKCS82PKEY :: proc(p8: ^PKCS8_PRIV_KEY_INFO) -> ^EVP_PKEY ---

	// EVP_PKEY2PKCS8 encodes |pkey| as a PKCS#8 PrivateKeyInfo (RFC 5208),
	// represented as a newly-allocated |PKCS8_PRIV_KEY_INFO|, or NULL on error. The
	// caller must release the result with |PKCS8_PRIV_KEY_INFO_free| when done.
	//
	// Use |EVP_marshal_private_key| instead.
	EVP_PKEY2PKCS8 :: proc(pkey: ^EVP_PKEY) -> ^PKCS8_PRIV_KEY_INFO ---

	// X509_SIG_new returns a newly-allocated, empty |X509_SIG| object, or NULL on
	// error.
	X509_SIG_new :: proc() -> ^X509_SIG ---

	// X509_SIG_free releases memory associated with |key|.
	X509_SIG_free :: proc(key: ^X509_SIG) ---

	// d2i_X509_SIG parses up to |len| bytes from |*inp| as a DER-encoded algorithm
	// and octet string pair, as described in |d2i_SAMPLE|.
	d2i_X509_SIG :: proc(out: ^^X509_SIG, inp: ^^u8, len: c.long) -> ^X509_SIG ---

	// i2d_X509_SIG marshals |sig| as a DER-encoded algorithm
	// and octet string pair, as described in |i2d_SAMPLE|.
	i2d_X509_SIG :: proc(sig: ^X509_SIG, outp: ^^u8) -> i32 ---

	// X509_SIG_get0 sets |*out_alg| and |*out_digest| to non-owning pointers to
	// |sig|'s algorithm and digest fields, respectively. Either |out_alg| and
	// |out_digest| may be NULL to skip those fields.
	X509_SIG_get0 :: proc(sig: ^X509_SIG, out_alg: ^^X509_ALGOR, out_digest: ^^ASN1_OCTET_STRING) ---

	// X509_SIG_getm behaves like |X509_SIG_get0| but returns mutable pointers.
	X509_SIG_getm :: proc(sig: ^X509_SIG, out_alg: ^^X509_ALGOR, out_digest: ^^ASN1_OCTET_STRING) ---
}

// Printing functions.
//
// The following functions output human-readable representations of
// X.509-related structures. They should only be used for debugging or logging
// and not parsed programmatically. In many cases, the outputs are ambiguous, so
// attempting to parse them can lead to string injection vulnerabilities.

// The following flags control |X509_print_ex| and |X509_REQ_print_ex|. These
// flags co-exist with |X509V3_EXT_*|, so avoid collisions when adding new ones.

// X509_FLAG_COMPAT disables all flags. It additionally causes names to be
// printed with a 16-byte indent.
X509_FLAG_COMPAT :: 0

// X509_FLAG_NO_HEADER skips a header identifying the type of object printed.
X509_FLAG_NO_HEADER :: 1

// X509_FLAG_NO_VERSION skips printing the X.509 version number.
X509_FLAG_NO_VERSION :: (1<<1)

// X509_FLAG_NO_SERIAL skips printing the serial number. It is ignored in
// |X509_REQ_print_fp|.
X509_FLAG_NO_SERIAL :: (1<<2)

// X509_FLAG_NO_SIGNAME skips printing the signature algorithm in the
// TBSCertificate. It is ignored in |X509_REQ_print_fp|.
X509_FLAG_NO_SIGNAME :: (1<<3)

// X509_FLAG_NO_ISSUER skips printing the issuer.
X509_FLAG_NO_ISSUER :: (1<<4)

// X509_FLAG_NO_VALIDITY skips printing the notBefore and notAfter times. It is
// ignored in |X509_REQ_print_fp|.
X509_FLAG_NO_VALIDITY :: (1<<5)

// X509_FLAG_NO_SUBJECT skips printing the subject.
X509_FLAG_NO_SUBJECT :: (1<<6)

// X509_FLAG_NO_PUBKEY skips printing the public key.
X509_FLAG_NO_PUBKEY :: (1<<7)

// X509_FLAG_NO_EXTENSIONS skips printing the extension list. It is ignored in
// |X509_REQ_print_fp|. CSRs instead have attributes, which is controlled by
// |X509_FLAG_NO_ATTRIBUTES|.
X509_FLAG_NO_EXTENSIONS :: (1<<8)

// X509_FLAG_NO_SIGDUMP skips printing the signature and outer signature
// algorithm.
X509_FLAG_NO_SIGDUMP :: (1<<9)

// X509_FLAG_NO_AUX skips printing auxiliary properties. (See |d2i_X509_AUX| and
// related functions.)
X509_FLAG_NO_AUX :: (1<<10)

// X509_FLAG_NO_ATTRIBUTES skips printing CSR attributes. It does nothing for
// certificates and CRLs.
X509_FLAG_NO_ATTRIBUTES :: (1<<11)

// X509_FLAG_NO_IDS skips printing the issuerUniqueID and subjectUniqueID in a
// certificate. It is ignored in |X509_REQ_print_fp|.
X509_FLAG_NO_IDS :: (1<<12)

// The following flags control |X509_print_ex|, |X509_REQ_print_ex|,
// |X509V3_EXT_print|, and |X509V3_extensions_print|. These flags coexist with
// |X509_FLAG_*|, so avoid collisions when adding new ones.

// X509V3_EXT_UNKNOWN_MASK is a mask that determines how unknown extensions are
// processed.
X509V3_EXT_UNKNOWN_MASK :: (0xf<<16)

// X509V3_EXT_DEFAULT causes unknown extensions or syntax errors to return
// failure.
X509V3_EXT_DEFAULT :: 0

// X509V3_EXT_ERROR_UNKNOWN causes unknown extensions or syntax errors to print
// as "<Not Supported>" or "<Parse Error>", respectively.
X509V3_EXT_ERROR_UNKNOWN :: (1<<16)

// X509V3_EXT_PARSE_UNKNOWN is deprecated and behaves like
// |X509V3_EXT_DUMP_UNKNOWN|.
X509V3_EXT_PARSE_UNKNOWN :: (2<<16)

// X509V3_EXT_DUMP_UNKNOWN causes unknown extensions to be displayed as a
// hexdump.
X509V3_EXT_DUMP_UNKNOWN :: (3<<16)

@(default_calling_convention="c")
foreign lib {
	// X509_print_ex writes a human-readable representation of |x| to |bp|. It
	// returns one on success and zero on error. |nmflags| is the flags parameter
	// for |X509_NAME_print_ex| when printing the subject and issuer. |cflag| should
	// be some combination of the |X509_FLAG_*| and |X509V3_EXT_*| constants.
	X509_print_ex :: proc(bp: ^BIO, x: ^X509, nmflag: c.ulong, cflag: c.ulong) -> i32 ---

	// X509_print_ex_fp behaves like |X509_print_ex| but writes to |fp|.
	X509_print_ex_fp :: proc(fp: ^FILE, x: ^X509, nmflag: c.ulong, cflag: c.ulong) -> i32 ---

	// X509_print calls |X509_print_ex| with |XN_FLAG_COMPAT| and |X509_FLAG_COMPAT|
	// flags.
	X509_print :: proc(bp: ^BIO, x: ^X509) -> i32 ---

	// X509_print_fp behaves like |X509_print| but writes to |fp|.
	X509_print_fp :: proc(fp: ^FILE, x: ^X509) -> i32 ---

	// X509_CRL_print writes a human-readable representation of |x| to |bp|. It
	// returns one on success and zero on error.
	X509_CRL_print :: proc(bp: ^BIO, x: ^X509_CRL) -> i32 ---

	// X509_CRL_print_fp behaves like |X509_CRL_print| but writes to |fp|.
	X509_CRL_print_fp :: proc(fp: ^FILE, x: ^X509_CRL) -> i32 ---

	// X509_REQ_print_ex writes a human-readable representation of |x| to |bp|. It
	// returns one on success and zero on error. |nmflags| is the flags parameter
	// for |X509_NAME_print_ex|, when printing the subject. |cflag| should be some
	// combination of the |X509_FLAG_*| and |X509V3_EXT_*| constants.
	X509_REQ_print_ex :: proc(bp: ^BIO, x: ^X509_REQ, nmflag: c.ulong, cflag: c.ulong) -> i32 ---

	// X509_REQ_print calls |X509_REQ_print_ex| with |XN_FLAG_COMPAT| and
	// |X509_FLAG_COMPAT| flags.
	X509_REQ_print :: proc(bp: ^BIO, req: ^X509_REQ) -> i32 ---

	// X509_REQ_print_fp behaves like |X509_REQ_print| but writes to |fp|.
	X509_REQ_print_fp :: proc(fp: ^FILE, req: ^X509_REQ) -> i32 ---
}

// The following flags are control |X509_NAME_print_ex|. They must not collide
// with |ASN1_STRFLGS_*|.
//
// TODO(davidben): This is far, far too many options and most of them are
// useless. Trim this down.

// XN_FLAG_COMPAT prints with |X509_NAME_print|'s format and return value
// convention.
XN_FLAG_COMPAT :: 0

// XN_FLAG_SEP_MASK determines the separators to use between attributes.
XN_FLAG_SEP_MASK :: (0xf<<16)

// XN_FLAG_SEP_COMMA_PLUS separates RDNs with "," and attributes within an RDN
// with "+", as in RFC 2253.
XN_FLAG_SEP_COMMA_PLUS :: (1<<16)

// XN_FLAG_SEP_CPLUS_SPC behaves like |XN_FLAG_SEP_COMMA_PLUS| but adds spaces
// between the separators.
XN_FLAG_SEP_CPLUS_SPC :: (2<<16)

// XN_FLAG_SEP_SPLUS_SPC separates RDNs with "; " and attributes within an RDN
// with " + ".
XN_FLAG_SEP_SPLUS_SPC :: (3<<16)

// XN_FLAG_SEP_MULTILINE prints each attribute on one line.
XN_FLAG_SEP_MULTILINE :: (4<<16)

// XN_FLAG_DN_REV prints RDNs in reverse, from least significant to most
// significant, as RFC 2253.
XN_FLAG_DN_REV :: (1<<20)

// XN_FLAG_FN_MASK determines how attribute types are displayed.
XN_FLAG_FN_MASK :: (0x3<<21)

// XN_FLAG_FN_SN uses the attribute type's short name, when available.
XN_FLAG_FN_SN :: 0

// XN_FLAG_SPC_EQ wraps the "=" operator with spaces when printing attributes.
XN_FLAG_SPC_EQ :: (1<<23)

// XN_FLAG_DUMP_UNKNOWN_FIELDS causes unknown attribute types to be printed in
// hex, as in RFC 2253.
XN_FLAG_DUMP_UNKNOWN_FIELDS :: (1<<24)

@(default_calling_convention="c")
foreign lib {
	// X509_NAME_print_ex writes a human-readable representation of |nm| to |out|.
	// Each line of output is indented by |indent| spaces. It returns the number of
	// bytes written on success, and -1 on error. If |out| is NULL, it returns the
	// number of bytes it would have written but does not write anything. |flags|
	// should be some combination of |XN_FLAG_*| and |ASN1_STRFLGS_*| values and
	// determines the output. If unsure, use |XN_FLAG_RFC2253|.
	//
	// If |flags| is |XN_FLAG_COMPAT|, or zero, this function calls
	// |X509_NAME_print| instead. In that case, it returns one on success, rather
	// than the output length.
	X509_NAME_print_ex :: proc(out: ^BIO, nm: ^X509_NAME, indent: i32, flags: c.ulong) -> i32 ---

	// X509_NAME_print prints a human-readable representation of |name| to |bp|. It
	// returns one on success and zero on error. |obase| is ignored.
	//
	// This function outputs a legacy format that does not correctly handle string
	// encodings and other cases. Prefer |X509_NAME_print_ex| if printing a name for
	// debugging purposes.
	X509_NAME_print :: proc(bp: ^BIO, name: ^X509_NAME, obase: i32) -> i32 ---

	// X509_NAME_oneline writes a human-readable representation to |name| to a
	// buffer as a NUL-terminated C string.
	//
	// If |buf| is NULL, returns a newly-allocated buffer containing the result on
	// success, or NULL on error. The buffer must be released with |OPENSSL_free|
	// when done.
	//
	// If |buf| is non-NULL, at most |size| bytes of output are written to |buf|
	// instead. |size| includes the trailing NUL. The function then returns |buf| on
	// success or NULL on error. If the output does not fit in |size| bytes, the
	// output is silently truncated at an attribute boundary.
	//
	// This function outputs a legacy format that does not correctly handle string
	// encodings and other cases. Prefer |X509_NAME_print_ex| if printing a name for
	// debugging purposes.
	X509_NAME_oneline :: proc(name: ^X509_NAME, buf: cstring, size: i32) -> cstring ---

	// X509_NAME_print_ex_fp behaves like |X509_NAME_print_ex| but writes to |fp|.
	X509_NAME_print_ex_fp :: proc(fp: ^FILE, nm: ^X509_NAME, indent: i32, flags: c.ulong) -> i32 ---

	// X509_signature_dump writes a human-readable representation of |sig| to |bio|,
	// indented with |indent| spaces. It returns one on success and zero on error.
	X509_signature_dump :: proc(bio: ^BIO, sig: ^ASN1_STRING, indent: i32) -> i32 ---

	// X509_signature_print writes a human-readable representation of |alg| and
	// |sig| to |bio|. It returns one on success and zero on error.
	X509_signature_print :: proc(bio: ^BIO, alg: ^X509_ALGOR, sig: ^ASN1_STRING) -> i32 ---

	// X509V3_EXT_print prints a human-readable representation of |ext| to out. It
	// returns one on success and zero on error. The output is indented by |indent|
	// spaces. |flag| is one of the |X509V3_EXT_*| constants and controls printing
	// of unknown extensions and syntax errors.
	//
	// WARNING: Although some applications programmatically parse the output of this
	// function to process X.509 extensions, this is not safe. In many cases, the
	// outputs are ambiguous to attempting to parse them can lead to string
	// injection vulnerabilities. These functions should only be used for debugging
	// or logging.
	X509V3_EXT_print :: proc(out: ^BIO, ext: ^X509_EXTENSION, flag: c.ulong, indent: i32) -> i32 ---

	// X509V3_EXT_print_fp behaves like |X509V3_EXT_print| but writes to a |FILE|
	// instead of a |BIO|.
	X509V3_EXT_print_fp :: proc(out: ^FILE, ext: ^X509_EXTENSION, flag: i32, indent: i32) -> i32 ---

	// X509V3_extensions_print prints |title|, followed by a human-readable
	// representation of |exts| to |out|. It returns one on success and zero on
	// error. The output is indented by |indent| spaces. |flag| is one of the
	// |X509V3_EXT_*| constants and controls printing of unknown extensions and
	// syntax errors.
	X509V3_extensions_print :: proc(out: ^BIO, title: cstring, exts: ^stack_st_X509_EXTENSION, flag: c.ulong, indent: i32) -> i32 ---

	// GENERAL_NAME_print prints a human-readable representation of |gen| to |out|.
	// It returns one on success and zero on error.
	//
	// TODO(davidben): Actually, it just returns one and doesn't check for I/O or
	// allocation errors. But it should return zero on error.
	GENERAL_NAME_print :: proc(out: ^BIO, gen: ^GENERAL_NAME) -> i32 ---

	// X509_pubkey_digest hashes the contents of the BIT STRING in |x509|'s
	// subjectPublicKeyInfo field with |md| and writes the result to |out|.
	// |EVP_MD_CTX_size| bytes are written, which is at most |EVP_MAX_MD_SIZE|. If
	// |out_len| is not NULL, |*out_len| is set to the number of bytes written. This
	// function returns one on success and zero on error.
	//
	// This hash omits the BIT STRING tag, length, and number of unused bits. It
	// also omits the AlgorithmIdentifier which describes the key type. It
	// corresponds to the OCSP KeyHash definition and is not suitable for other
	// purposes.
	X509_pubkey_digest :: proc(x509: ^X509, md: ^EVP_MD, out: ^u8, out_len: ^u32) -> i32 ---

	// X509_digest hashes |x509|'s DER encoding with |md| and writes the result to
	// |out|. |EVP_MD_CTX_size| bytes are written, which is at most
	// |EVP_MAX_MD_SIZE|. If |out_len| is not NULL, |*out_len| is set to the number
	// of bytes written. This function returns one on success and zero on error.
	// Note this digest covers the entire certificate, not just the signed portion.
	X509_digest :: proc(x509: ^X509, md: ^EVP_MD, out: ^u8, out_len: ^u32) -> i32 ---

	// X509_CRL_digest hashes |crl|'s DER encoding with |md| and writes the result
	// to |out|. |EVP_MD_CTX_size| bytes are written, which is at most
	// |EVP_MAX_MD_SIZE|. If |out_len| is not NULL, |*out_len| is set to the number
	// of bytes written. This function returns one on success and zero on error.
	// Note this digest covers the entire CRL, not just the signed portion.
	X509_CRL_digest :: proc(crl: ^X509_CRL, md: ^EVP_MD, out: ^u8, out_len: ^u32) -> i32 ---

	// X509_REQ_digest hashes |req|'s DER encoding with |md| and writes the result
	// to |out|. |EVP_MD_CTX_size| bytes are written, which is at most
	// |EVP_MAX_MD_SIZE|. If |out_len| is not NULL, |*out_len| is set to the number
	// of bytes written. This function returns one on success and zero on error.
	// Note this digest covers the entire certificate request, not just the signed
	// portion.
	X509_REQ_digest :: proc(req: ^X509_REQ, md: ^EVP_MD, out: ^u8, out_len: ^u32) -> i32 ---

	// X509_NAME_digest hashes |name|'s DER encoding with |md| and writes the result
	// to |out|. |EVP_MD_CTX_size| bytes are written, which is at most
	// |EVP_MAX_MD_SIZE|. If |out_len| is not NULL, |*out_len| is set to the number
	// of bytes written. This function returns one on success and zero on error.
	X509_NAME_digest :: proc(name: ^X509_NAME, md: ^EVP_MD, out: ^u8, out_len: ^u32) -> i32 ---

	// The following functions behave like the corresponding unsuffixed |d2i_*|
	// functions, but read the result from |bp| instead. Callers using these
	// functions with memory |BIO|s to parse structures already in memory should use
	// |d2i_*| instead.
	d2i_X509_bio                :: proc(bp: ^BIO, x509: ^^X509) -> ^X509 ---
	d2i_X509_CRL_bio            :: proc(bp: ^BIO, crl: ^^X509_CRL) -> ^X509_CRL ---
	d2i_X509_REQ_bio            :: proc(bp: ^BIO, req: ^^X509_REQ) -> ^X509_REQ ---
	d2i_RSAPrivateKey_bio       :: proc(bp: ^BIO, rsa: ^^RSA) -> ^RSA ---
	d2i_RSAPublicKey_bio        :: proc(bp: ^BIO, rsa: ^^RSA) -> ^RSA ---
	d2i_RSA_PUBKEY_bio          :: proc(bp: ^BIO, rsa: ^^RSA) -> ^RSA ---
	d2i_DSA_PUBKEY_bio          :: proc(bp: ^BIO, dsa: ^^DSA) -> ^DSA ---
	d2i_DSAPrivateKey_bio       :: proc(bp: ^BIO, dsa: ^^DSA) -> ^DSA ---
	d2i_EC_PUBKEY_bio           :: proc(bp: ^BIO, eckey: ^^EC_KEY) -> ^EC_KEY ---
	d2i_ECPrivateKey_bio        :: proc(bp: ^BIO, eckey: ^^EC_KEY) -> ^EC_KEY ---
	d2i_PKCS8_bio               :: proc(bp: ^BIO, p8: ^^X509_SIG) -> ^X509_SIG ---
	d2i_PKCS8_PRIV_KEY_INFO_bio :: proc(bp: ^BIO, p8inf: ^^PKCS8_PRIV_KEY_INFO) -> ^PKCS8_PRIV_KEY_INFO ---
	d2i_PUBKEY_bio              :: proc(bp: ^BIO, a: ^^EVP_PKEY) -> ^EVP_PKEY ---
	d2i_DHparams_bio            :: proc(bp: ^BIO, dh: ^^DH) -> ^DH ---

	// d2i_PrivateKey_bio behaves like |d2i_AutoPrivateKey|, but reads from |bp|
	// instead.
	d2i_PrivateKey_bio :: proc(bp: ^BIO, a: ^^EVP_PKEY) -> ^EVP_PKEY ---

	// The following functions behave like the corresponding unsuffixed |i2d_*|
	// functions, but write the result to |bp|. They return one on success and zero
	// on error. Callers using them with memory |BIO|s to encode structures to
	// memory should use |i2d_*| directly instead.
	i2d_X509_bio                :: proc(bp: ^BIO, x509: ^X509) -> i32 ---
	i2d_X509_CRL_bio            :: proc(bp: ^BIO, crl: ^X509_CRL) -> i32 ---
	i2d_X509_REQ_bio            :: proc(bp: ^BIO, req: ^X509_REQ) -> i32 ---
	i2d_RSAPrivateKey_bio       :: proc(bp: ^BIO, rsa: ^RSA) -> i32 ---
	i2d_RSAPublicKey_bio        :: proc(bp: ^BIO, rsa: ^RSA) -> i32 ---
	i2d_RSA_PUBKEY_bio          :: proc(bp: ^BIO, rsa: ^RSA) -> i32 ---
	i2d_DSA_PUBKEY_bio          :: proc(bp: ^BIO, dsa: ^DSA) -> i32 ---
	i2d_DSAPrivateKey_bio       :: proc(bp: ^BIO, dsa: ^DSA) -> i32 ---
	i2d_EC_PUBKEY_bio           :: proc(bp: ^BIO, eckey: ^EC_KEY) -> i32 ---
	i2d_ECPrivateKey_bio        :: proc(bp: ^BIO, eckey: ^EC_KEY) -> i32 ---
	i2d_PKCS8_bio               :: proc(bp: ^BIO, p8: ^X509_SIG) -> i32 ---
	i2d_PKCS8_PRIV_KEY_INFO_bio :: proc(bp: ^BIO, p8inf: ^PKCS8_PRIV_KEY_INFO) -> i32 ---
	i2d_PrivateKey_bio          :: proc(bp: ^BIO, pkey: ^EVP_PKEY) -> i32 ---
	i2d_PUBKEY_bio              :: proc(bp: ^BIO, pkey: ^EVP_PKEY) -> i32 ---
	i2d_DHparams_bio            :: proc(bp: ^BIO, dh: ^DH) -> i32 ---

	// i2d_PKCS8PrivateKeyInfo_bio encodes |key| as a PKCS#8 PrivateKeyInfo
	// structure (see |EVP_marshal_private_key|) and writes the result to |bp|. It
	// returns one on success and zero on error.
	i2d_PKCS8PrivateKeyInfo_bio :: proc(bp: ^BIO, key: ^EVP_PKEY) -> i32 ---

	// The following functions behave like the corresponding |d2i_*_bio| functions,
	// but read from |fp| instead.
	d2i_X509_fp                :: proc(fp: ^FILE, x509: ^^X509) -> ^X509 ---
	d2i_X509_CRL_fp            :: proc(fp: ^FILE, crl: ^^X509_CRL) -> ^X509_CRL ---
	d2i_X509_REQ_fp            :: proc(fp: ^FILE, req: ^^X509_REQ) -> ^X509_REQ ---
	d2i_RSAPrivateKey_fp       :: proc(fp: ^FILE, rsa: ^^RSA) -> ^RSA ---
	d2i_RSAPublicKey_fp        :: proc(fp: ^FILE, rsa: ^^RSA) -> ^RSA ---
	d2i_RSA_PUBKEY_fp          :: proc(fp: ^FILE, rsa: ^^RSA) -> ^RSA ---
	d2i_DSA_PUBKEY_fp          :: proc(fp: ^FILE, dsa: ^^DSA) -> ^DSA ---
	d2i_DSAPrivateKey_fp       :: proc(fp: ^FILE, dsa: ^^DSA) -> ^DSA ---
	d2i_EC_PUBKEY_fp           :: proc(fp: ^FILE, eckey: ^^EC_KEY) -> ^EC_KEY ---
	d2i_ECPrivateKey_fp        :: proc(fp: ^FILE, eckey: ^^EC_KEY) -> ^EC_KEY ---
	d2i_PKCS8_fp               :: proc(fp: ^FILE, p8: ^^X509_SIG) -> ^X509_SIG ---
	d2i_PKCS8_PRIV_KEY_INFO_fp :: proc(fp: ^FILE, p8inf: ^^PKCS8_PRIV_KEY_INFO) -> ^PKCS8_PRIV_KEY_INFO ---
	d2i_PrivateKey_fp          :: proc(fp: ^FILE, a: ^^EVP_PKEY) -> ^EVP_PKEY ---
	d2i_PUBKEY_fp              :: proc(fp: ^FILE, a: ^^EVP_PKEY) -> ^EVP_PKEY ---

	// The following functions behave like the corresponding |i2d_*_bio| functions,
	// but write to |fp| instead.
	i2d_X509_fp                :: proc(fp: ^FILE, x509: ^X509) -> i32 ---
	i2d_X509_CRL_fp            :: proc(fp: ^FILE, crl: ^X509_CRL) -> i32 ---
	i2d_X509_REQ_fp            :: proc(fp: ^FILE, req: ^X509_REQ) -> i32 ---
	i2d_RSAPrivateKey_fp       :: proc(fp: ^FILE, rsa: ^RSA) -> i32 ---
	i2d_RSAPublicKey_fp        :: proc(fp: ^FILE, rsa: ^RSA) -> i32 ---
	i2d_RSA_PUBKEY_fp          :: proc(fp: ^FILE, rsa: ^RSA) -> i32 ---
	i2d_DSA_PUBKEY_fp          :: proc(fp: ^FILE, dsa: ^DSA) -> i32 ---
	i2d_DSAPrivateKey_fp       :: proc(fp: ^FILE, dsa: ^DSA) -> i32 ---
	i2d_EC_PUBKEY_fp           :: proc(fp: ^FILE, eckey: ^EC_KEY) -> i32 ---
	i2d_ECPrivateKey_fp        :: proc(fp: ^FILE, eckey: ^EC_KEY) -> i32 ---
	i2d_PKCS8_fp               :: proc(fp: ^FILE, p8: ^X509_SIG) -> i32 ---
	i2d_PKCS8_PRIV_KEY_INFO_fp :: proc(fp: ^FILE, p8inf: ^PKCS8_PRIV_KEY_INFO) -> i32 ---
	i2d_PKCS8PrivateKeyInfo_fp :: proc(fp: ^FILE, key: ^EVP_PKEY) -> i32 ---
	i2d_PrivateKey_fp          :: proc(fp: ^FILE, pkey: ^EVP_PKEY) -> i32 ---
	i2d_PUBKEY_fp              :: proc(fp: ^FILE, pkey: ^EVP_PKEY) -> i32 ---

	// X509_find_by_issuer_and_serial returns the first |X509| in |sk| whose issuer
	// and serial are |name| and |serial|, respectively. If no match is found, it
	// returns NULL.
	X509_find_by_issuer_and_serial :: proc(sk: ^stack_st_X509, name: ^X509_NAME, serial: ^ASN1_INTEGER) -> ^X509 ---

	// X509_find_by_subject returns the first |X509| in |sk| whose subject is
	// |name|. If no match is found, it returns NULL.
	X509_find_by_subject :: proc(sk: ^stack_st_X509, name: ^X509_NAME) -> ^X509 ---

	// X509_cmp_time compares |s| against |*t|. On success, it returns a negative
	// number if |s| <= |*t| and a positive number if |s| > |*t|. On error, it
	// returns zero. If |t| is NULL, it uses the current time instead of |*t|.
	//
	// WARNING: Unlike most comparison functions, this function returns zero on
	// error, not equality.
	X509_cmp_time :: proc(s: ^ASN1_TIME, t: ^libc.time_t) -> i32 ---

	// X509_cmp_time_posix compares |s| against |t|. On success, it returns a
	// negative number if |s| <= |t| and a positive number if |s| > |t|. On error,
	// it returns zero.
	//
	// WARNING: Unlike most comparison functions, this function returns zero on
	// error, not equality.
	X509_cmp_time_posix :: proc(s: ^ASN1_TIME, t: i64) -> i32 ---

	// X509_cmp_current_time behaves like |X509_cmp_time| but compares |s| against
	// the current time.
	X509_cmp_current_time :: proc(s: ^ASN1_TIME) -> i32 ---

	// X509_time_adj calls |X509_time_adj_ex| with |offset_day| equal to zero.
	X509_time_adj :: proc(s: ^ASN1_TIME, offset_sec: c.long, t: ^libc.time_t) -> ^ASN1_TIME ---

	// X509_time_adj_ex behaves like |ASN1_TIME_adj|, but adds an offset to |*t|. If
	// |t| is NULL, it uses the current time instead of |*t|.
	X509_time_adj_ex :: proc(s: ^ASN1_TIME, offset_day: i32, offset_sec: c.long, t: ^libc.time_t) -> ^ASN1_TIME ---

	// X509_gmtime_adj behaves like |X509_time_adj_ex| but adds |offset_sec| to the
	// current time.
	X509_gmtime_adj :: proc(s: ^ASN1_TIME, offset_sec: c.long) -> ^ASN1_TIME ---

	// X509_issuer_name_cmp behaves like |X509_NAME_cmp|, but compares |a| and |b|'s
	// issuer names.
	X509_issuer_name_cmp :: proc(a: ^X509, b: ^X509) -> i32 ---

	// X509_subject_name_cmp behaves like |X509_NAME_cmp|, but compares |a| and
	// |b|'s subject names.
	X509_subject_name_cmp :: proc(a: ^X509, b: ^X509) -> i32 ---

	// X509_CRL_cmp behaves like |X509_NAME_cmp|, but compares |a| and |b|'s
	// issuer names.
	//
	// WARNING: This function is misnamed. It does not compare other parts of the
	// CRL, only the issuer fields using |X509_NAME_cmp|.
	X509_CRL_cmp :: proc(a: ^X509_CRL, b: ^X509_CRL) -> i32 ---

	// X509_issuer_name_hash returns the hash of |x509|'s issuer name with
	// |X509_NAME_hash|.
	//
	// This hash is specific to the |X509_LOOKUP_add_dir| filesystem format and is
	// not suitable for general-purpose X.509 name processing. It is very short, so
	// there will be hash collisions. It also depends on an OpenSSL-specific
	// canonicalization process.
	X509_issuer_name_hash :: proc(x509: ^X509) -> u32 ---

	// X509_subject_name_hash returns the hash of |x509|'s subject name with
	// |X509_NAME_hash|.
	//
	// This hash is specific to the |X509_LOOKUP_add_dir| filesystem format and is
	// not suitable for general-purpose X.509 name processing. It is very short, so
	// there will be hash collisions. It also depends on an OpenSSL-specific
	// canonicalization process.
	X509_subject_name_hash :: proc(x509: ^X509) -> u32 ---

	// X509_issuer_name_hash_old returns the hash of |x509|'s issuer name with
	// |X509_NAME_hash_old|.
	//
	// This hash is specific to the |X509_LOOKUP_add_dir| filesystem format and is
	// not suitable for general-purpose X.509 name processing. It is very short, so
	// there will be hash collisions.
	X509_issuer_name_hash_old :: proc(x509: ^X509) -> u32 ---

	// X509_subject_name_hash_old returns the hash of |x509|'s usjbect name with
	// |X509_NAME_hash_old|.
	//
	// This hash is specific to the |X509_LOOKUP_add_dir| filesystem format and is
	// not suitable for general-purpose X.509 name processing. It is very short, so
	// there will be hash collisions.
	X509_subject_name_hash_old :: proc(x509: ^X509) -> u32 ---

	// ex_data functions.
	//
	// See |ex_data.h| for details.
	X509_get_ex_new_index           :: proc(argl: c.long, argp: rawptr, unused: ^CRYPTO_EX_unused, dup_unused: ^CRYPTO_EX_dup, free_func: ^CRYPTO_EX_free) -> i32 ---
	X509_set_ex_data                :: proc(r: ^X509, idx: i32, arg: rawptr) -> i32 ---
	X509_get_ex_data                :: proc(r: ^X509, idx: i32) -> rawptr ---
	X509_STORE_CTX_get_ex_new_index :: proc(argl: c.long, argp: rawptr, unused: ^CRYPTO_EX_unused, dup_unused: ^CRYPTO_EX_dup, free_func: ^CRYPTO_EX_free) -> i32 ---
	X509_STORE_CTX_set_ex_data      :: proc(ctx: ^X509_STORE_CTX, idx: i32, data: rawptr) -> i32 ---
	X509_STORE_CTX_get_ex_data      :: proc(ctx: ^X509_STORE_CTX, idx: i32) -> rawptr ---

	// ASN1_digest serializes |data| with |i2d| and then hashes the result with
	// |type|. On success, it returns one, writes the digest to |md|, and sets
	// |*len| to the digest length if non-NULL. On error, it returns zero.
	//
	// |EVP_MD_CTX_size| bytes are written, which is at most |EVP_MAX_MD_SIZE|. The
	// buffer must have sufficient space for this output.
	ASN1_digest :: proc(i2d: ^i2d_of_void, type: ^EVP_MD, data: cstring, md: ^u8, len: ^u32) -> i32 ---

	// ASN1_item_digest serializes |data| with |it| and then hashes the result with
	// |type|. On success, it returns one, writes the digest to |md|, and sets
	// |*len| to the digest length if non-NULL. On error, it returns zero.
	//
	// |EVP_MD_CTX_size| bytes are written, which is at most |EVP_MAX_MD_SIZE|. The
	// buffer must have sufficient space for this output.
	//
	// WARNING: |data| must be a pointer with the same type as |it|'s corresponding
	// C type. Using the wrong type is a potentially exploitable memory error.
	ASN1_item_digest :: proc(it: ^ASN1_ITEM, type: ^EVP_MD, data: rawptr, md: ^u8, len: ^u32) -> i32 ---

	// ASN1_item_verify serializes |data| with |it| and then verifies |signature| is
	// a valid signature for the result with |algor1| and |pkey|. It returns one on
	// success and zero on error. The signature and algorithm are interpreted as in
	// X.509.
	//
	// WARNING: |data| must be a pointer with the same type as |it|'s corresponding
	// C type. Using the wrong type is a potentially exploitable memory error.
	ASN1_item_verify :: proc(it: ^ASN1_ITEM, algor1: ^X509_ALGOR, signature: ^ASN1_BIT_STRING, data: rawptr, pkey: ^EVP_PKEY) -> i32 ---

	// ASN1_item_sign serializes |data| with |it| and then signs the result with
	// the private key |pkey|. It returns the length of the signature on success and
	// zero on error. On success, it writes the signature to |signature| and the
	// signature algorithm to each of |algor1| and |algor2|. Either of |algor1| or
	// |algor2| may be NULL to ignore them. This function uses digest algorithm
	// |md|, or |pkey|'s default if NULL. Other signing parameters use |pkey|'s
	// defaults. To customize them, use |ASN1_item_sign_ctx|.
	//
	// |algor1| and |algor2| may point into part of |asn| and will be updated before
	// |asn| is serialized.
	//
	// WARNING: |data| must be a pointer with the same type as |it|'s corresponding
	// C type. Using the wrong type is a potentially exploitable memory error.
	ASN1_item_sign :: proc(it: ^ASN1_ITEM, algor1: ^X509_ALGOR, algor2: ^X509_ALGOR, signature: ^ASN1_BIT_STRING, data: rawptr, pkey: ^EVP_PKEY, type: ^EVP_MD) -> i32 ---

	// ASN1_item_sign_ctx behaves like |ASN1_item_sign| except the signature is
	// signed with |ctx|, |ctx|, which must have been initialized with
	// |EVP_DigestSignInit|. The caller should configure the corresponding
	// |EVP_PKEY_CTX| with any additional parameters before calling this function.
	//
	// On success or failure, this function mutates |ctx| and resets it to the empty
	// state. Caller should not rely on its contents after the function returns.
	//
	// |algor1| and |algor2| may point into part of |asn| and will be updated before
	// |asn| is serialized.
	//
	// WARNING: |data| must be a pointer with the same type as |it|'s corresponding
	// C type. Using the wrong type is a potentially exploitable memory error.
	ASN1_item_sign_ctx :: proc(it: ^ASN1_ITEM, algor1: ^X509_ALGOR, algor2: ^X509_ALGOR, signature: ^ASN1_BIT_STRING, asn: rawptr, ctx: ^EVP_MD_CTX) -> i32 ---

	// X509_supported_extension returns one if |ex| is a critical X.509 certificate
	// extension, supported by |X509_verify_cert|, and zero otherwise.
	//
	// Note this function only reports certificate extensions (as opposed to CRL or
	// CRL extensions), and only extensions that are expected to be marked critical.
	// Additionally, |X509_verify_cert| checks for unsupported critical extensions
	// internally, so most callers will not need to call this function separately.
	X509_supported_extension :: proc(ex: ^X509_EXTENSION) -> i32 ---

	// X509_check_ca returns one if |x509| may be considered a CA certificate,
	// according to basic constraints and key usage extensions. Otherwise, it
	// returns zero. If |x509| is an X509v1 certificate, and thus has no extensions,
	// it is considered eligible.
	//
	// This function returning one does not indicate that |x509| is trusted, only
	// that it is eligible to be a CA.
	X509_check_ca :: proc(x509: ^X509) -> i32 ---

	// X509_check_issued checks if |issuer| and |subject|'s name, authority key
	// identifier, and key usage fields allow |issuer| to have issued |subject|. It
	// returns |X509_V_OK| on success and an |X509_V_ERR_*| value otherwise.
	//
	// This function does not check the signature on |subject|. Rather, it is
	// intended to prune the set of possible issuer certificates during
	// path-building.
	X509_check_issued :: proc(issuer: ^X509, subject: ^X509) -> i32 ---

	// NAME_CONSTRAINTS_check checks if |x509| satisfies name constraints in |nc|.
	// It returns |X509_V_OK| on success and some |X509_V_ERR_*| constant on error.
	NAME_CONSTRAINTS_check :: proc(x509: ^X509, nc: ^NAME_CONSTRAINTS) -> i32 ---

	// X509_check_host checks if |x509| matches the DNS name |chk|. It returns one
	// on match, zero on mismatch, or a negative number on error. |flags| should be
	// some combination of |X509_CHECK_FLAG_*| and modifies the behavior. On match,
	// if |out_peername| is non-NULL, it additionally sets |*out_peername| to a
	// newly-allocated, NUL-terminated string containing the DNS name or wildcard in
	// the certificate which matched. The caller must then free |*out_peername| with
	// |OPENSSL_free| when done.
	//
	// By default, both subject alternative names and the subject's common name
	// attribute are checked. The latter has long been deprecated, so callers should
	// include |X509_CHECK_FLAG_NEVER_CHECK_SUBJECT| in |flags| to use the standard
	// behavior. https://crbug.com/boringssl/464 tracks fixing the default.
	//
	// This function does not check if |x509| is a trusted certificate, only if,
	// were it trusted, it would match |chk|.
	//
	// WARNING: This function differs from the usual calling convention and may
	// return either 0 or a negative number on error.
	//
	// TODO(davidben): Make the error case also return zero.
	X509_check_host :: proc(x509: ^X509, chk: cstring, chklen: c.size_t, flags: u32, out_peername: ^cstring) -> i32 ---

	// X509_check_email checks if |x509| matches the email address |chk|. It returns
	// one on match, zero on mismatch, or a negative number on error. |flags| should
	// be some combination of |X509_CHECK_FLAG_*| and modifies the behavior.
	//
	// By default, both subject alternative names and the subject's email address
	// attribute are checked. The |X509_CHECK_FLAG_NEVER_CHECK_SUBJECT| flag may be
	// used to change this behavior.
	//
	// This function does not check if |x509| is a trusted certificate, only if,
	// were it trusted, it would match |chk|.
	//
	// WARNING: This function differs from the usual calling convention and may
	// return either 0 or a negative number on error.
	//
	// TODO(davidben): Make the error case also return zero.
	X509_check_email :: proc(x509: ^X509, chk: cstring, chklen: c.size_t, flags: u32) -> i32 ---

	// X509_check_ip checks if |x509| matches the IP address |chk|. The IP address
	// is represented in byte form and should be 4 bytes for an IPv4 address and 16
	// bytes for an IPv6 address. It returns one on match, zero on mismatch, or a
	// negative number on error. |flags| should be some combination of
	// |X509_CHECK_FLAG_*| and modifies the behavior.
	//
	// This function does not check if |x509| is a trusted certificate, only if,
	// were it trusted, it would match |chk|.
	//
	// WARNING: This function differs from the usual calling convention and may
	// return either 0 or a negative number on error.
	//
	// TODO(davidben): Make the error case also return zero.
	X509_check_ip :: proc(x509: ^X509, chk: ^u8, chklen: c.size_t, flags: u32) -> i32 ---

	// X509_check_ip_asc behaves like |X509_check_ip| except the IP address is
	// specified in textual form in |ipasc|.
	//
	// WARNING: This function differs from the usual calling convention and may
	// return either 0 or a negative number on error.
	//
	// TODO(davidben): Make the error case also return zero.
	X509_check_ip_asc :: proc(x509: ^X509, ipasc: cstring, flags: u32) -> i32 ---

	// X509_STORE_CTX_get1_issuer looks up a candidate trusted issuer for |x509| out
	// of |ctx|'s |X509_STORE|, based on the criteria in |X509_check_issued|. If one
	// was found, it returns one and sets |*out_issuer| to the issuer. The caller
	// must release |*out_issuer| with |X509_free| when done. If none was found, it
	// returns zero and leaves |*out_issuer| unchanged.
	//
	// This function only searches for trusted issuers. It does not consider
	// untrusted intermediates passed in to |X509_STORE_CTX_init|.
	X509_STORE_CTX_get1_issuer :: proc(out_issuer: ^^X509, ctx: ^X509_STORE_CTX, x509: ^X509) -> i32 ---

	// X509_check_purpose performs checks if |x509|'s basic constraints, key usage,
	// and extended key usage extensions for the specified purpose. |purpose| should
	// be one of |X509_PURPOSE_*| constants. See |X509_VERIFY_PARAM_set_purpose| for
	// details. It returns one if |x509|'s extensions are consistent with |purpose|
	// and zero otherwise. If |ca| is non-zero, |x509| is checked as a CA
	// certificate. Otherwise, it is checked as an end-entity certificate.
	//
	// If |purpose| is -1, this function performs no purpose checks, but it parses
	// some extensions in |x509| and may return zero on syntax error. Historically,
	// callers primarily used this function to trigger this parsing, but this is no
	// longer necessary. Functions acting on |X509| will internally parse as needed.
	X509_check_purpose :: proc(x509: ^X509, purpose: i32, ca: i32) -> i32 ---
}

X509_TRUST_TRUSTED   :: 1
X509_TRUST_REJECTED  :: 2
X509_TRUST_UNTRUSTED :: 3

@(default_calling_convention="c")
foreign lib {
	// X509_check_trust checks if |x509| is a valid trust anchor for trust type
	// |id|. See |X509_VERIFY_PARAM_set_trust| for details. It returns
	// |X509_TRUST_TRUSTED| if |x509| is a trust anchor, |X509_TRUST_REJECTED| if it
	// was distrusted, and |X509_TRUST_UNTRUSTED| otherwise. |id| should be one of
	// the |X509_TRUST_*| constants, or zero to indicate the default behavior.
	// |flags| should be zero and is ignored.
	X509_check_trust :: proc(x509: ^X509, id: i32, flags: i32) -> i32 ---

	// X509_STORE_CTX_get1_certs returns a newly-allocated stack containing all
	// trusted certificates in |ctx|'s |X509_STORE| whose subject matches |name|, or
	// NULL on error. The caller must release the result with |sk_X509_pop_free| and
	// |X509_free| when done.
	X509_STORE_CTX_get1_certs :: proc(ctx: ^X509_STORE_CTX, name: ^X509_NAME) -> ^stack_st_X509 ---

	// X509_STORE_CTX_get1_crls returns a newly-allocated stack containing all
	// CRLs in |ctx|'s |X509_STORE| whose subject matches |name|, or NULL on error.
	// The caller must release the result with |sk_X509_CRL_pop_free| and
	// |X509_CRL_free| when done.
	X509_STORE_CTX_get1_crls :: proc(ctx: ^X509_STORE_CTX, name: ^X509_NAME) -> ^stack_st_X509_CRL ---

	// X509_STORE_CTX_get_by_subject looks up an object of type |type| in |ctx|'s
	// |X509_STORE| that matches |name|. |type| should be one of the |X509_LU_*|
	// constants to indicate the type of object. If a match was found, it stores the
	// result in |ret| and returns one. Otherwise, it returns zero. If multiple
	// objects match, this function outputs an arbitrary one.
	//
	// WARNING: |ret| must be in the empty state, as returned by |X509_OBJECT_new|.
	// Otherwise, the object currently in |ret| will be leaked when overwritten.
	// https://crbug.com/boringssl/685 tracks fixing this.
	//
	// WARNING: Multiple trusted certificates or CRLs may share a name. In this
	// case, this function returns an arbitrary match. Use
	// |X509_STORE_CTX_get1_certs| or |X509_STORE_CTX_get1_crls| instead.
	X509_STORE_CTX_get_by_subject :: proc(ctx: ^X509_STORE_CTX, type: i32, name: ^X509_NAME, ret: ^X509_OBJECT) -> i32 ---
}

// X.509 information.
//
// |X509_INFO| is the return type for |PEM_X509_INFO_read_bio|, defined in
// <openssl/pem.h>. It is used to store a certificate, CRL, or private key. This
// type is defined in this header for OpenSSL compatibility.
private_key_st :: struct {
	dec_pkey: ^EVP_PKEY,
}

X509_info_st :: struct {
	x509:       ^X509,
	crl:        ^X509_CRL,
	x_pkey:     ^X509_PKEY,
	enc_cipher: EVP_CIPHER_INFO,
	enc_len:    i32,
	enc_data:   cstring,
}

sk_X509_INFO_delete_if_func :: proc "c" (^X509_INFO, rawptr) -> i32
sk_X509_INFO_cmp_func       :: proc "c" (^^X509_INFO, ^^X509_INFO) -> i32
stack_st_X509_INFO          :: struct {}
sk_X509_INFO_free_func      :: proc "c" (^X509_INFO)
sk_X509_INFO_copy_func      :: proc "c" (^X509_INFO) -> ^X509_INFO

@(default_calling_convention="c")
foreign lib {
	// X509_INFO_free releases memory associated with |info|.
	X509_INFO_free :: proc(info: ^X509_INFO) ---
}

// The following function pointer types are used in |X509V3_EXT_METHOD|.
X509V3_EXT_NEW  :: proc "c" () -> rawptr
X509V3_EXT_FREE :: proc "c" (ext: rawptr)
X509V3_EXT_D2I  :: proc "c" (ext: rawptr, inp: ^^u8, len: c.long) -> rawptr
X509V3_EXT_I2D  :: proc "c" (ext: rawptr, outp: ^^u8) -> i32
X509V3_EXT_I2V  :: proc "c" (method: ^X509V3_EXT_METHOD, ext: rawptr, extlist: ^stack_st_CONF_VALUE) -> ^stack_st_CONF_VALUE
X509V3_EXT_V2I  :: proc "c" (method: ^X509V3_EXT_METHOD, ctx: ^X509V3_CTX, values: ^stack_st_CONF_VALUE) -> rawptr
X509V3_EXT_I2S  :: proc "c" (method: ^X509V3_EXT_METHOD, ext: rawptr) -> cstring
X509V3_EXT_S2I  :: proc "c" (method: ^X509V3_EXT_METHOD, ctx: ^X509V3_CTX, str: cstring) -> rawptr
X509V3_EXT_I2R  :: proc "c" (method: ^X509V3_EXT_METHOD, ext: rawptr, out: ^BIO, indent: i32) -> i32
X509V3_EXT_R2I  :: proc "c" (method: ^X509V3_EXT_METHOD, ctx: ^X509V3_CTX, str: cstring) -> rawptr

// A v3_ext_method, aka |X509V3_EXT_METHOD|, is a deprecated type which defines
// a custom extension.
v3_ext_method :: struct {
	// ext_nid is the NID of the extension.
	ext_nid: i32,

	// ext_flags is a combination of |X509V3_EXT_*| constants.
	ext_flags: i32,

	// it determines how values of this extension are allocated, released, parsed,
	// and marshalled. This must be non-NULL.
	it: ^ASN1_ITEM_EXP,

	// The following functions are ignored in favor of |it|. They are retained in
	// the struct only for source compatibility with existing struct definitions.
	ext_new:  X509V3_EXT_NEW,
	ext_free: X509V3_EXT_FREE,
	d2i:      X509V3_EXT_D2I,
	i2d:      X509V3_EXT_I2D,

	// The following functions are used for string extensions.
	i2s: X509V3_EXT_I2S,
	s2i: X509V3_EXT_S2I,

	// The following functions are used for multi-valued extensions.
	i2v: X509V3_EXT_I2V,
	v2i: X509V3_EXT_V2I,

	// The following functions are used for "raw" extensions, which implement
	// custom printing behavior.
	i2r:      X509V3_EXT_I2R,
	r2i:      X509V3_EXT_R2I,
	usr_data: rawptr, // Any extension specific data
}

// X509V3_EXT_MULTILINE causes the result of an |X509V3_EXT_METHOD|'s |i2v|
// function to be printed on separate lines, rather than separated by commas.
X509V3_EXT_MULTILINE :: 0x4

@(default_calling_convention="c")
foreign lib {
	// X509V3_EXT_get returns the |X509V3_EXT_METHOD| corresponding to |ext|'s
	// extension type, or NULL if none was registered.
	X509V3_EXT_get :: proc(ext: ^X509_EXTENSION) -> ^X509V3_EXT_METHOD ---

	// X509V3_EXT_get_nid returns the |X509V3_EXT_METHOD| corresponding to |nid|, or
	// NULL if none was registered.
	X509V3_EXT_get_nid :: proc(nid: i32) -> ^X509V3_EXT_METHOD ---

	// X509V3_EXT_add registers |ext| as a custom extension for the extension type
	// |ext->ext_nid|. |ext| must be valid for the remainder of the address space's
	// lifetime. It returns one on success and zero on error.
	//
	// WARNING: This function modifies global state. If other code in the same
	// address space also registers an extension with type |ext->ext_nid|, the two
	// registrations will conflict. Which registration takes effect is undefined. If
	// the two registrations use incompatible in-memory representations, code
	// expecting the other registration will then cast a type to the wrong type,
	// resulting in a potentially exploitable memory error. This conflict can also
	// occur if BoringSSL later adds support for |ext->ext_nid|, with a different
	// in-memory representation than the one expected by |ext|.
	//
	// This function, additionally, is not thread-safe and cannot be called
	// concurrently with any other BoringSSL function.
	//
	// As a result, it is impossible to safely use this function. Registering a
	// custom extension has no impact on certificate verification so, instead,
	// callers should simply handle the custom extension with the byte-based
	// |X509_EXTENSION| APIs directly. Registering |ext| with the library has little
	// practical value.
	X509V3_EXT_add :: proc(ext: ^X509V3_EXT_METHOD) -> i32 ---

	// X509V3_EXT_add_alias registers a custom extension with NID |nid_to|. The
	// corresponding ASN.1 type is copied from |nid_from|. It returns one on success
	// and zero on error.
	//
	// WARNING: Do not use this function. See |X509V3_EXT_add|.
	X509V3_EXT_add_alias :: proc(nid_to: i32, nid_from: i32) -> i32 ---
}

// v3_ext_ctx, aka |X509V3_CTX|, contains additional context information for
// constructing extensions. Some string formats reference additional values in
// these objects. It must be initialized with |X509V3_set_ctx| or
// |X509V3_set_ctx_test| before use.
v3_ext_ctx :: struct {
	flags:        i32,
	issuer_cert:  ^X509,
	subject_cert: ^X509,
	subject_req:  ^X509_REQ,
	crl:          ^X509_CRL,
	db:           ^CONF,
}

X509V3_CTX_TEST :: 0x1

@(default_calling_convention="c")
foreign lib {
	// X509V3_set_ctx initializes |ctx| with the specified objects. Some string
	// formats will reference fields in these objects. Each object may be NULL to
	// omit it, in which case those formats cannot be used. |flags| should be zero,
	// unless called via |X509V3_set_ctx_test|.
	//
	// |issuer|, |subject|, |req|, and |crl|, if non-NULL, must outlive |ctx|.
	X509V3_set_ctx :: proc(ctx: ^X509V3_CTX, issuer: ^X509, subject: ^X509, req: ^X509_REQ, crl: ^X509_CRL, flags: i32) ---

	// X509V3_set_nconf sets |ctx| to use |conf| as the config database. |ctx| must
	// have previously been initialized by |X509V3_set_ctx| or
	// |X509V3_set_ctx_test|. Some string formats will reference sections in |conf|.
	// |conf| may be NULL, in which case these formats cannot be used. If non-NULL,
	// |conf| must outlive |ctx|.
	X509V3_set_nconf :: proc(ctx: ^X509V3_CTX, conf: ^CONF) ---

	// X509V3_EXT_nconf constructs an extension of type specified by |name|, and
	// value specified by |value|. It returns a newly-allocated |X509_EXTENSION|
	// object on success, or NULL on error. |conf| and |ctx| specify additional
	// information referenced by some formats. Either |conf| or |ctx| may be NULL,
	// in which case features which use it will be disabled.
	//
	// If non-NULL, |ctx| must be initialized with |X509V3_set_ctx| or
	// |X509V3_set_ctx_test|.
	//
	// Both |conf| and |ctx| provide a |CONF| object. When |ctx| is non-NULL, most
	// features use the |ctx| copy, configured with |X509V3_set_ctx|, but some use
	// |conf|. Callers should ensure the two match to avoid surprisingly behavior.
	X509V3_EXT_nconf :: proc(conf: ^CONF, ctx: ^X509V3_CTX, name: cstring, value: cstring) -> ^X509_EXTENSION ---

	// X509V3_EXT_nconf_nid behaves like |X509V3_EXT_nconf|, except the extension
	// type is specified as a NID.
	X509V3_EXT_nconf_nid :: proc(conf: ^CONF, ctx: ^X509V3_CTX, ext_nid: i32, value: cstring) -> ^X509_EXTENSION ---

	// X509V3_EXT_conf_nid calls |X509V3_EXT_nconf_nid|. |conf| must be NULL.
	X509V3_EXT_conf_nid :: proc(conf: ^CRYPTO_MUST_BE_NULL, ctx: ^X509V3_CTX, ext_nid: i32, value: cstring) -> ^X509_EXTENSION ---

	// X509V3_EXT_add_nconf_sk looks up the section named |section| in |conf|. For
	// each |CONF_VALUE| in the section, it constructs an extension as in
	// |X509V3_EXT_nconf|, taking |name| and |value| from the |CONF_VALUE|. Each new
	// extension is appended to |*sk|. If |*sk| is non-NULL, and at least one
	// extension is added, it sets |*sk| to a newly-allocated
	// |STACK_OF(X509_EXTENSION)|. It returns one on success and zero on error.
	X509V3_EXT_add_nconf_sk :: proc(conf: ^CONF, ctx: ^X509V3_CTX, section: cstring, sk: ^^stack_st_X509_EXTENSION) -> i32 ---

	// X509V3_EXT_add_nconf adds extensions to |cert| as in
	// |X509V3_EXT_add_nconf_sk|. It returns one on success and zero on error.
	X509V3_EXT_add_nconf :: proc(conf: ^CONF, ctx: ^X509V3_CTX, section: cstring, cert: ^X509) -> i32 ---

	// X509V3_EXT_REQ_add_nconf adds extensions to |req| as in
	// |X509V3_EXT_add_nconf_sk|. It returns one on success and zero on error.
	X509V3_EXT_REQ_add_nconf :: proc(conf: ^CONF, ctx: ^X509V3_CTX, section: cstring, req: ^X509_REQ) -> i32 ---

	// X509V3_EXT_CRL_add_nconf adds extensions to |crl| as in
	// |X509V3_EXT_add_nconf_sk|. It returns one on success and zero on error.
	X509V3_EXT_CRL_add_nconf :: proc(conf: ^CONF, ctx: ^X509V3_CTX, section: cstring, crl: ^X509_CRL) -> i32 ---

	// i2s_ASN1_OCTET_STRING returns a human-readable representation of |oct| as a
	// newly-allocated, NUL-terminated string, or NULL on error. |method| is
	// ignored. The caller must release the result with |OPENSSL_free| when done.
	i2s_ASN1_OCTET_STRING :: proc(method: ^X509V3_EXT_METHOD, oct: ^ASN1_OCTET_STRING) -> cstring ---

	// s2i_ASN1_OCTET_STRING decodes |str| as a hexadecimal byte string, with
	// optional colon separators between bytes. It returns a newly-allocated
	// |ASN1_OCTET_STRING| with the result on success, or NULL on error. |method|
	// and |ctx| are ignored.
	s2i_ASN1_OCTET_STRING :: proc(method: ^X509V3_EXT_METHOD, ctx: ^X509V3_CTX, str: cstring) -> ^ASN1_OCTET_STRING ---

	// i2s_ASN1_INTEGER returns a human-readable representation of |aint| as a
	// newly-allocated, NUL-terminated string, or NULL on error. |method| is
	// ignored. The caller must release the result with |OPENSSL_free| when done.
	i2s_ASN1_INTEGER :: proc(method: ^X509V3_EXT_METHOD, aint: ^ASN1_INTEGER) -> cstring ---

	// s2i_ASN1_INTEGER decodes |value| as the ASCII representation of an integer,
	// and returns a newly-allocated |ASN1_INTEGER| containing the result, or NULL
	// on error. |method| is ignored. If |value| begins with "0x" or "0X", the input
	// is decoded in hexadecimal, otherwise decimal.
	s2i_ASN1_INTEGER :: proc(method: ^X509V3_EXT_METHOD, value: cstring) -> ^ASN1_INTEGER ---

	// i2s_ASN1_ENUMERATED returns a human-readable representation of |aint| as a
	// newly-allocated, NUL-terminated string, or NULL on error. |method| is
	// ignored. The caller must release the result with |OPENSSL_free| when done.
	i2s_ASN1_ENUMERATED :: proc(method: ^X509V3_EXT_METHOD, aint: ^ASN1_ENUMERATED) -> cstring ---

	// X509V3_conf_free releases memory associated with |CONF_VALUE|.
	X509V3_conf_free :: proc(val: ^CONF_VALUE) ---

	// i2v_GENERAL_NAME serializes |gen| as a |CONF_VALUE|. If |ret| is non-NULL, it
	// appends the value to |ret| and returns |ret| on success or NULL on error. If
	// it returns NULL, the caller is still responsible for freeing |ret|. If |ret|
	// is NULL, it returns a newly-allocated |STACK_OF(CONF_VALUE)| containing the
	// result. |method| is ignored. When done, the caller should release the result
	// with |sk_CONF_VALUE_pop_free| and |X509V3_conf_free|.
	//
	// Do not use this function. This is an internal implementation detail of the
	// human-readable print functions. If extracting a SAN list from a certificate,
	// look at |gen| directly.
	i2v_GENERAL_NAME :: proc(method: ^X509V3_EXT_METHOD, gen: ^GENERAL_NAME, ret: ^stack_st_CONF_VALUE) -> ^stack_st_CONF_VALUE ---

	// i2v_GENERAL_NAMES serializes |gen| as a list of |CONF_VALUE|s. If |ret| is
	// non-NULL, it appends the values to |ret| and returns |ret| on success or NULL
	// on error. If it returns NULL, the caller is still responsible for freeing
	// |ret|. If |ret| is NULL, it returns a newly-allocated |STACK_OF(CONF_VALUE)|
	// containing the results. |method| is ignored.
	//
	// Do not use this function. This is an internal implementation detail of the
	// human-readable print functions. If extracting a SAN list from a certificate,
	// look at |gen| directly.
	i2v_GENERAL_NAMES :: proc(method: ^X509V3_EXT_METHOD, gen: ^GENERAL_NAMES, extlist: ^stack_st_CONF_VALUE) -> ^stack_st_CONF_VALUE ---

	// a2i_IPADDRESS decodes |ipasc| as the textual representation of an IPv4 or
	// IPv6 address. On success, it returns a newly-allocated |ASN1_OCTET_STRING|
	// containing the decoded IP address. IPv4 addresses are represented as 4-byte
	// strings and IPv6 addresses as 16-byte strings. On failure, it returns NULL.
	a2i_IPADDRESS :: proc(ipasc: cstring) -> ^ASN1_OCTET_STRING ---

	// a2i_IPADDRESS_NC decodes |ipasc| as the textual representation of an IPv4 or
	// IPv6 address range. On success, it returns a newly-allocated
	// |ASN1_OCTET_STRING| containing the decoded IP address, followed by the
	// decoded mask. IPv4 ranges are represented as 8-byte strings and IPv6 ranges
	// as 32-byte strings. On failure, it returns NULL.
	//
	// The text format decoded by this function is not the standard CIDR notiation.
	// Instead, the mask after the "/" is represented as another IP address. For
	// example, "192.168.0.0/16" would be written "192.168.0.0/255.255.0.0".
	a2i_IPADDRESS_NC :: proc(ipasc: cstring) -> ^ASN1_OCTET_STRING ---

	// X509_get_notBefore returns |x509|'s notBefore time. Note this function is not
	// const-correct for legacy reasons. Use |X509_get0_notBefore| or
	// |X509_getm_notBefore| instead.
	X509_get_notBefore :: proc(x509: ^X509) -> ^ASN1_TIME ---

	// X509_get_notAfter returns |x509|'s notAfter time. Note this function is not
	// const-correct for legacy reasons. Use |X509_get0_notAfter| or
	// |X509_getm_notAfter| instead.
	X509_get_notAfter :: proc(x509: ^X509) -> ^ASN1_TIME ---

	// X509_set_notBefore calls |X509_set1_notBefore|. Use |X509_set1_notBefore|
	// instead.
	X509_set_notBefore :: proc(x509: ^X509, tm: ^ASN1_TIME) -> i32 ---

	// X509_set_notAfter calls |X509_set1_notAfter|. Use |X509_set1_notAfter|
	// instead.
	X509_set_notAfter :: proc(x509: ^X509, tm: ^ASN1_TIME) -> i32 ---

	// X509_CRL_get_lastUpdate returns a mutable pointer to |crl|'s thisUpdate time.
	// The OpenSSL API refers to this field as lastUpdate.
	//
	// Use |X509_CRL_get0_lastUpdate| or |X509_CRL_set1_lastUpdate| instead.
	X509_CRL_get_lastUpdate :: proc(crl: ^X509_CRL) -> ^ASN1_TIME ---

	// X509_CRL_get_nextUpdate returns a mutable pointer to |crl|'s nextUpdate time,
	// or NULL if |crl| has none. Use |X509_CRL_get0_nextUpdate| or
	// |X509_CRL_set1_nextUpdate| instead.
	X509_CRL_get_nextUpdate :: proc(crl: ^X509_CRL) -> ^ASN1_TIME ---
}

// The following symbols are deprecated aliases to |X509_CRL_set1_*|.
X509_CRL_set_lastUpdate :: X509_CRL_set1_lastUpdate
X509_CRL_set_nextUpdate :: X509_CRL_set1_nextUpdate

@(default_calling_convention="c")
foreign lib {
	// X509_get_serialNumber returns a mutable pointer to |x509|'s serial number.
	// Prefer |X509_get0_serialNumber|.
	X509_get_serialNumber :: proc(x509: ^X509) -> ^ASN1_INTEGER ---

	// X509_NAME_get_text_by_OBJ finds the first attribute with type |obj| in
	// |name|. If found, it writes the value's UTF-8 representation to |buf|.
	// followed by a NUL byte, and returns the number of bytes in the output,
	// excluding the NUL byte. This is unlike OpenSSL which returns the raw
	// ASN1_STRING data. The UTF-8 encoding of the |ASN1_STRING| may not contain a 0
	// codepoint.
	//
	// This function writes at most |len| bytes, including the NUL byte.  If |buf|
	// is NULL, it writes nothing and returns the number of bytes in the
	// output, excluding the NUL byte that would be required for the full UTF-8
	// output.
	//
	// This function may return -1 if an error occurs for any reason, including the
	// value not being a recognized string type, |len| being of insufficient size to
	// hold the full UTF-8 encoding and NUL byte, memory allocation failures, an
	// object with type |obj| not existing in |name|, or if the UTF-8 encoding of
	// the string contains a zero byte.
	X509_NAME_get_text_by_OBJ :: proc(name: ^X509_NAME, obj: ^ASN1_OBJECT, buf: cstring, len: i32) -> i32 ---

	// X509_NAME_get_text_by_NID behaves like |X509_NAME_get_text_by_OBJ| except it
	// finds an attribute of type |nid|, which should be one of the |NID_*|
	// constants.
	X509_NAME_get_text_by_NID :: proc(name: ^X509_NAME, nid: i32, buf: cstring, len: i32) -> i32 ---

	// X509_STORE_CTX_get0_parent_ctx returns NULL.
	X509_STORE_CTX_get0_parent_ctx :: proc(ctx: ^X509_STORE_CTX) -> ^X509_STORE_CTX ---

	// X509_OBJECT_free_contents sets |obj| to the empty object, freeing any values
	// that were previously there.
	//
	// TODO(davidben): Unexport this function after rust-openssl is fixed to no
	// longer call it.
	X509_OBJECT_free_contents :: proc(obj: ^X509_OBJECT) ---

	// X509_LOOKUP_free releases memory associated with |ctx|. This function should
	// never be used outside the library. No function in the public API hands
	// ownership of an |X509_LOOKUP| to the caller.
	//
	// TODO(davidben): Unexport this function after rust-openssl is fixed to no
	// longer call it.
	X509_LOOKUP_free :: proc(ctx: ^X509_LOOKUP) ---

	// X509_STORE_CTX_cleanup resets |ctx| to the empty state.
	//
	// This function is a remnant of when |X509_STORE_CTX| was stack-allocated and
	// should not be used. If releasing |ctx|, call |X509_STORE_CTX_free|. If
	// reusing |ctx| for a new verification, release the old one and create a new
	// one.
	X509_STORE_CTX_cleanup :: proc(ctx: ^X509_STORE_CTX) ---

	// X509V3_add_standard_extensions returns one.
	X509V3_add_standard_extensions :: proc() -> i32 ---
}

// The following symbols are legacy aliases for |X509_STORE_CTX| functions.
X509_STORE_get_by_subject :: X509_STORE_CTX_get_by_subject
X509_STORE_get1_certs     :: X509_STORE_CTX_get1_certs
X509_STORE_get1_crls      :: X509_STORE_CTX_get1_crls

@(default_calling_convention="c")
foreign lib {
	// X509_STORE_CTX_get_chain is a legacy alias for |X509_STORE_CTX_get0_chain|.
	X509_STORE_CTX_get_chain :: proc(ctx: ^X509_STORE_CTX) -> ^stack_st_X509 ---

	// X509_STORE_CTX_trusted_stack is a deprecated alias for
	// |X509_STORE_CTX_set0_trusted_stack|.
	X509_STORE_CTX_trusted_stack :: proc(ctx: ^X509_STORE_CTX, sk: ^stack_st_X509) ---
}

X509_STORE_CTX_verify_cb :: proc "c" (i32, ^X509_STORE_CTX) -> i32

@(default_calling_convention="c")
foreign lib {
	// X509_STORE_CTX_set_verify_cb configures a callback function for |ctx| that is
	// called multiple times during |X509_verify_cert|. The callback returns zero to
	// fail verification and one to proceed. Typically, it will return |ok|, which
	// preserves the default behavior. Returning one when |ok| is zero will proceed
	// past some error. The callback may inspect |ctx| and the error queue to
	// attempt to determine the current stage of certificate verification, but this
	// is often unreliable. When synthesizing an error, callbacks should use
	// |X509_STORE_CTX_set_error| to set a corresponding error.
	//
	// WARNING: Do not use this function. It is extremely fragile and unpredictable.
	// This callback exposes implementation details of certificate verification,
	// which change as the library evolves. Attempting to use it for security checks
	// can introduce vulnerabilities if making incorrect assumptions about when the
	// callback is called. Some errors, when suppressed, may implicitly suppress
	// other errors due to internal implementation details. Additionally, overriding
	// |ok| may leave |ctx| in an inconsistent state and break invariants.
	//
	// Instead, customize certificate verification by configuring options on the
	// |X509_STORE_CTX| before verification, or applying additional checks after
	// |X509_verify_cert| completes successfully.
	X509_STORE_CTX_set_verify_cb :: proc(ctx: ^X509_STORE_CTX, verify_cb: proc "c" (ok: i32, ctx: ^X509_STORE_CTX) -> i32) ---

	// X509_STORE_set_verify_cb acts like |X509_STORE_CTX_set_verify_cb| but sets
	// the verify callback for any |X509_STORE_CTX| created from this |X509_STORE|
	//
	// Do not use this function. See |X509_STORE_CTX_set_verify_cb| for details.
	X509_STORE_set_verify_cb :: proc(store: ^X509_STORE, verify_cb: X509_STORE_CTX_verify_cb) ---

	// X509_STORE_CTX_set_chain configures |ctx| to use |sk| for untrusted
	// intermediate certificates to use in verification. This function is redundant
	// with the |chain| parameter of |X509_STORE_CTX_init|. Use the parameter
	// instead.
	//
	// WARNING: Despite the similar name, this function is unrelated to
	// |X509_STORE_CTX_get0_chain|.
	//
	// WARNING: This function saves a pointer to |sk| without copying or
	// incrementing reference counts. |sk| must outlive |ctx| and may not be mutated
	// for the duration of the certificate verification.
	X509_STORE_CTX_set_chain :: proc(ctx: ^X509_STORE_CTX, sk: ^stack_st_X509) ---
}

// The following flags do nothing. The corresponding non-standard options have
// been removed.
X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT    :: 0
X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS   :: 0
X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS :: 0

// X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS does nothing, but is necessary in
// OpenSSL to enable standard wildcard matching. In BoringSSL, this behavior is
// always enabled.
X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS :: 0

@(default_calling_convention="c")
foreign lib {
	// X509_STORE_get0_objects returns a non-owning pointer of |store|'s internal
	// object list. Although this function is not const, callers must not modify
	// the result of this function.
	//
	// WARNING: This function is not thread-safe. If |store| is shared across
	// multiple threads, callers cannot safely inspect the result of this function,
	// because another thread may have concurrently added to it. In particular,
	// |X509_LOOKUP_add_dir| treats this list as a cache and may add to it in the
	// course of certificate verification. This API additionally prevents fixing
	// some quadratic worst-case behavior in |X509_STORE| and may be removed in the
	// future. Use |X509_STORE_get1_objects| instead.
	X509_STORE_get0_objects :: proc(store: ^X509_STORE) -> ^stack_st_X509_OBJECT ---

	// X509_PURPOSE_get_by_sname returns the |X509_PURPOSE_*| constant corresponding
	// a short name |sname|, or -1 if |sname| was not recognized.
	//
	// Use |X509_PURPOSE_*| constants directly instead. The short names used by this
	// function look like "sslserver" or "smimeencrypt", so they do not make
	// especially good APIs.
	//
	// This function differs from OpenSSL, which returns an "index" to be passed to
	// |X509_PURPOSE_get0|, followed by |X509_PURPOSE_get_id|, to finally obtain an
	// |X509_PURPOSE_*| value suitable for use with |X509_VERIFY_PARAM_set_purpose|.
	X509_PURPOSE_get_by_sname :: proc(sname: cstring) -> i32 ---

	// X509_PURPOSE_get0 returns the |X509_PURPOSE| object corresponding to |id|,
	// which should be one of the |X509_PURPOSE_*| constants, or NULL if none
	// exists.
	//
	// This function differs from OpenSSL, which takes an "index", returned from
	// |X509_PURPOSE_get_by_sname|. In BoringSSL, indices and |X509_PURPOSE_*| IDs
	// are the same.
	X509_PURPOSE_get0 :: proc(id: i32) -> ^X509_PURPOSE ---

	// X509_PURPOSE_get_id returns |purpose|'s ID. This will be one of the
	// |X509_PURPOSE_*| constants.
	X509_PURPOSE_get_id :: proc(purpose: ^X509_PURPOSE) -> i32 ---
}

// The following constants are values for the legacy Netscape certificate type
// X.509 extension, a precursor to extended key usage. These values correspond
// to the DER encoding of the first byte of the BIT STRING. That is, 0x80 is
// bit zero and 0x01 is bit seven.
//
// TODO(davidben): These constants are only used by OpenVPN, which deprecated
// the feature in 2017. The documentation says it was removed, but they did not
// actually remove it. See if OpenVPN will accept a patch to finish this.
NS_SSL_CLIENT :: 0x80
NS_SSL_SERVER :: 0x40
NS_SMIME      :: 0x20
NS_OBJSIGN    :: 0x10
NS_SSL_CA     :: 0x04
NS_SMIME_CA   :: 0x02
NS_OBJSIGN_CA :: 0x01
NS_ANY_CA     :: (NS_SSL_CA|NS_SMIME_CA|NS_OBJSIGN_CA)

// Private structures.
X509_algor_st :: struct {
	algorithm: ^ASN1_OBJECT,
	parameter: ^ASN1_TYPE,
}

X509_R_AKID_MISMATCH                :: 100
X509_R_BAD_PKCS7_VERSION            :: 101
X509_R_BAD_X509_FILETYPE            :: 102
X509_R_BASE64_DECODE_ERROR          :: 103
X509_R_CANT_CHECK_DH_KEY            :: 104
X509_R_CERT_ALREADY_IN_HASH_TABLE   :: 105
X509_R_CRL_ALREADY_DELTA            :: 106
X509_R_CRL_VERIFY_FAILURE           :: 107
X509_R_IDP_MISMATCH                 :: 108
X509_R_INVALID_BIT_STRING_BITS_LEFT :: 109
X509_R_INVALID_DIRECTORY            :: 110
X509_R_INVALID_FIELD_NAME           :: 111
X509_R_INVALID_PSS_PARAMETERS       :: 112
X509_R_INVALID_TRUST                :: 113
X509_R_ISSUER_MISMATCH              :: 114
X509_R_KEY_TYPE_MISMATCH            :: 115
X509_R_KEY_VALUES_MISMATCH          :: 116
X509_R_LOADING_CERT_DIR             :: 117
X509_R_LOADING_DEFAULTS             :: 118
X509_R_NEWER_CRL_NOT_NEWER          :: 119
X509_R_NOT_PKCS7_SIGNED_DATA        :: 120
X509_R_NO_CERTIFICATES_INCLUDED     :: 121
X509_R_NO_CERT_SET_FOR_US_TO_VERIFY :: 122
X509_R_NO_CRLS_INCLUDED             :: 123
X509_R_NO_CRL_NUMBER                :: 124
X509_R_PUBLIC_KEY_DECODE_ERROR      :: 125
X509_R_PUBLIC_KEY_ENCODE_ERROR      :: 126
X509_R_SHOULD_RETRY                 :: 127
X509_R_UNKNOWN_KEY_TYPE             :: 128
X509_R_UNKNOWN_NID                  :: 129
X509_R_UNKNOWN_PURPOSE_ID           :: 130
X509_R_UNKNOWN_TRUST_ID             :: 131
X509_R_UNSUPPORTED_ALGORITHM        :: 132
X509_R_WRONG_LOOKUP_TYPE            :: 133
X509_R_WRONG_TYPE                   :: 134
X509_R_NAME_TOO_LONG                :: 135
X509_R_INVALID_PARAMETER            :: 136
X509_R_SIGNATURE_ALGORITHM_MISMATCH :: 137
X509_R_DELTA_CRL_WITHOUT_CRL_NUMBER :: 138
X509_R_INVALID_FIELD_FOR_VERSION    :: 139
X509_R_INVALID_VERSION              :: 140
X509_R_NO_CERTIFICATE_FOUND         :: 141
X509_R_NO_CERTIFICATE_OR_CRL_FOUND  :: 142
X509_R_NO_CRL_FOUND                 :: 143
X509_R_INVALID_POLICY_EXTENSION     :: 144

