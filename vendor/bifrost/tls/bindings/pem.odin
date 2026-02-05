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


PEM_BUFSIZE             :: 1024
PEM_STRING_X509_OLD     :: "X509 CERTIFICATE"
PEM_STRING_X509         :: "CERTIFICATE"
PEM_STRING_X509_PAIR    :: "CERTIFICATE PAIR"
PEM_STRING_X509_TRUSTED :: "TRUSTED CERTIFICATE"
PEM_STRING_X509_REQ_OLD :: "NEW CERTIFICATE REQUEST"
PEM_STRING_X509_REQ     :: "CERTIFICATE REQUEST"
PEM_STRING_X509_CRL     :: "X509 CRL"
PEM_STRING_EVP_PKEY     :: "ANY PRIVATE KEY"
PEM_STRING_PUBLIC       :: "PUBLIC KEY"
PEM_STRING_RSA          :: "RSA PRIVATE KEY"
PEM_STRING_RSA_PUBLIC   :: "RSA PUBLIC KEY"
PEM_STRING_DSA          :: "DSA PRIVATE KEY"
PEM_STRING_DSA_PUBLIC   :: "DSA PUBLIC KEY"
PEM_STRING_EC           :: "EC PRIVATE KEY"
PEM_STRING_PKCS7        :: "PKCS7"
PEM_STRING_PKCS7_SIGNED :: "PKCS #7 SIGNED DATA"
PEM_STRING_PKCS8        :: "ENCRYPTED PRIVATE KEY"
PEM_STRING_PKCS8INF     :: "PRIVATE KEY"
PEM_STRING_DHPARAMS     :: "DH PARAMETERS"
PEM_STRING_SSL_SESSION  :: "SSL SESSION PARAMETERS"
PEM_STRING_DSAPARAMS    :: "DSA PARAMETERS"
PEM_STRING_ECDSA_PUBLIC :: "ECDSA PUBLIC KEY"
PEM_STRING_ECPRIVATEKEY :: "EC PRIVATE KEY"
PEM_STRING_CMS          :: "CMS"

// enc_type is one off
PEM_TYPE_ENCRYPTED :: 10
PEM_TYPE_MIC_ONLY  :: 20
PEM_TYPE_MIC_CLEAR :: 30
PEM_TYPE_CLEAR     :: 40

// "userdata": new with OpenSSL 0.9.4
pem_password_cb :: proc "c" (buf: cstring, size: i32, rwflag: i32, userdata: rawptr) -> i32

@(default_calling_convention="c")
foreign lib {
	// PEM_read_bio reads from |bp|, until the next PEM block. If one is found, it
	// returns one and sets |*name|, |*header|, and |*data| to newly-allocated
	// buffers containing the PEM type, the header block, and the decoded data,
	// respectively. |*name| and |*header| are NUL-terminated C strings, while
	// |*data| has |*len| bytes. The caller must release each of |*name|, |*header|,
	// and |*data| with |OPENSSL_free| when done. If no PEM block is found, this
	// function returns zero and pushes |PEM_R_NO_START_LINE| to the error queue. If
	// one is found, but there is an error decoding it, it returns zero and pushes
	// some other error to the error queue.
	PEM_read_bio :: proc(bp: ^BIO, name: ^cstring, header: ^cstring, data: ^^u8, len: ^c.long) -> i32 ---

	// PEM_write_bio writes a PEM block to |bp|, containing |len| bytes from |data|
	// as data. |name| and |hdr| are NUL-terminated C strings containing the PEM
	// type and header block, respectively. This function returns zero on error and
	// the number of bytes written on success.
	PEM_write_bio      :: proc(bp: ^BIO, name: cstring, hdr: cstring, data: ^u8, len: c.long) -> i32 ---
	PEM_bytes_read_bio :: proc(pdata: ^^u8, plen: ^c.long, pnm: ^cstring, name: cstring, bp: ^BIO, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_ASN1_read_bio  :: proc(d2i: ^d2i_of_void, name: cstring, bp: ^BIO, x: ^rawptr, cb: ^pem_password_cb, u: rawptr) -> rawptr ---
	PEM_ASN1_write_bio :: proc(i2d: ^i2d_of_void, name: cstring, bp: ^BIO, x: rawptr, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---

	// PEM_X509_INFO_read_bio reads PEM blocks from |bp| and decodes any
	// certificates, CRLs, and private keys found. It returns a
	// |STACK_OF(X509_INFO)| structure containing the results, or NULL on error.
	//
	// If |sk| is NULL, the result on success will be a newly-allocated
	// |STACK_OF(X509_INFO)| structure which should be released with
	// |sk_X509_INFO_pop_free| and |X509_INFO_free| when done.
	//
	// If |sk| is non-NULL, it appends the results to |sk| instead and returns |sk|
	// on success. In this case, the caller retains ownership of |sk| in both
	// success and failure.
	//
	// This function will decrypt any encrypted certificates in |bp|, using |cb|,
	// but it will not decrypt encrypted private keys. Encrypted private keys are
	// instead represented as placeholder |X509_INFO| objects with an empty |x_pkey|
	// field. This allows this function to be used with inputs with unencrypted
	// certificates, but encrypted passwords, without knowing the password. However,
	// it also means that this function cannot be used to decrypt the private key
	// when the password is known.
	//
	// WARNING: If the input contains "TRUSTED CERTIFICATE" PEM blocks, this
	// function parses auxiliary properties as in |d2i_X509_AUX|. Passing untrusted
	// input to this function allows an attacker to influence those properties. See
	// |d2i_X509_AUX| for details.
	PEM_X509_INFO_read_bio :: proc(bp: ^BIO, sk: ^stack_st_X509_INFO, cb: ^pem_password_cb, u: rawptr) -> ^stack_st_X509_INFO ---

	// PEM_X509_INFO_read behaves like |PEM_X509_INFO_read_bio| but reads from a
	// |FILE|.
	PEM_X509_INFO_read :: proc(fp: ^FILE, sk: ^stack_st_X509_INFO, cb: ^pem_password_cb, u: rawptr) -> ^stack_st_X509_INFO ---
	PEM_read           :: proc(fp: ^FILE, name: ^cstring, header: ^cstring, data: ^^u8, len: ^c.long) -> i32 ---
	PEM_write          :: proc(fp: ^FILE, name: cstring, hdr: cstring, data: ^u8, len: c.long) -> i32 ---
	PEM_ASN1_read      :: proc(d2i: ^d2i_of_void, name: cstring, fp: ^FILE, x: ^rawptr, cb: ^pem_password_cb, u: rawptr) -> rawptr ---
	PEM_ASN1_write     :: proc(i2d: ^i2d_of_void, name: cstring, fp: ^FILE, x: rawptr, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, callback: ^pem_password_cb, u: rawptr) -> i32 ---

	// PEM_def_callback treats |userdata| as a string and copies it into |buf|,
	// assuming its |size| is sufficient. Returns the length of the string, or -1 on
	// error. Error cases the buffer being too small, or |buf| and |userdata| being
	// NULL. Note that this is different from OpenSSL, which prompts for a password.
	PEM_def_callback                  :: proc(buf: cstring, size: i32, rwflag: i32, userdata: rawptr) -> i32 ---
	PEM_write_bio_X509                :: proc(bp: ^BIO, x: ^X509) -> i32 ---
	PEM_read_X509                     :: proc(fp: ^FILE, x: ^^X509, cb: ^pem_password_cb, u: rawptr) -> ^X509 ---
	PEM_write_X509                    :: proc(fp: ^FILE, x: ^X509) -> i32 ---
	PEM_read_bio_X509                 :: proc(bp: ^BIO, x: ^^X509, cb: ^pem_password_cb, u: rawptr) -> ^X509 ---
	PEM_write_X509_AUX                :: proc(fp: ^FILE, x: ^X509) -> i32 ---
	PEM_write_bio_X509_AUX            :: proc(bp: ^BIO, x: ^X509) -> i32 ---
	PEM_read_bio_X509_AUX             :: proc(bp: ^BIO, x: ^^X509, cb: ^pem_password_cb, u: rawptr) -> ^X509 ---
	PEM_read_X509_AUX                 :: proc(fp: ^FILE, x: ^^X509, cb: ^pem_password_cb, u: rawptr) -> ^X509 ---
	PEM_write_X509_REQ                :: proc(fp: ^FILE, x: ^X509_REQ) -> i32 ---
	PEM_read_bio_X509_REQ             :: proc(bp: ^BIO, x: ^^X509_REQ, cb: ^pem_password_cb, u: rawptr) -> ^X509_REQ ---
	PEM_read_X509_REQ                 :: proc(fp: ^FILE, x: ^^X509_REQ, cb: ^pem_password_cb, u: rawptr) -> ^X509_REQ ---
	PEM_write_bio_X509_REQ            :: proc(bp: ^BIO, x: ^X509_REQ) -> i32 ---
	PEM_write_bio_X509_REQ_NEW        :: proc(bp: ^BIO, x: ^X509_REQ) -> i32 ---
	PEM_write_X509_REQ_NEW            :: proc(fp: ^FILE, x: ^X509_REQ) -> i32 ---
	PEM_write_X509_CRL                :: proc(fp: ^FILE, x: ^X509_CRL) -> i32 ---
	PEM_write_bio_X509_CRL            :: proc(bp: ^BIO, x: ^X509_CRL) -> i32 ---
	PEM_read_bio_X509_CRL             :: proc(bp: ^BIO, x: ^^X509_CRL, cb: ^pem_password_cb, u: rawptr) -> ^X509_CRL ---
	PEM_read_X509_CRL                 :: proc(fp: ^FILE, x: ^^X509_CRL, cb: ^pem_password_cb, u: rawptr) -> ^X509_CRL ---
	PEM_write_PKCS7                   :: proc(fp: ^FILE, x: ^PKCS7) -> i32 ---
	PEM_write_bio_PKCS7               :: proc(bp: ^BIO, x: ^PKCS7) -> i32 ---
	PEM_read_bio_PKCS7                :: proc(bp: ^BIO, x: ^^PKCS7, cb: ^pem_password_cb, u: rawptr) -> ^PKCS7 ---
	PEM_read_PKCS7                    :: proc(fp: ^FILE, x: ^^PKCS7, cb: ^pem_password_cb, u: rawptr) -> ^PKCS7 ---
	PEM_read_PKCS8                    :: proc(fp: ^FILE, x: ^^X509_SIG, cb: ^pem_password_cb, u: rawptr) -> ^X509_SIG ---
	PEM_read_bio_PKCS8                :: proc(bp: ^BIO, x: ^^X509_SIG, cb: ^pem_password_cb, u: rawptr) -> ^X509_SIG ---
	PEM_write_bio_PKCS8               :: proc(bp: ^BIO, x: ^X509_SIG) -> i32 ---
	PEM_write_PKCS8                   :: proc(fp: ^FILE, x: ^X509_SIG) -> i32 ---
	PEM_write_bio_PKCS8_PRIV_KEY_INFO :: proc(bp: ^BIO, x: ^PKCS8_PRIV_KEY_INFO) -> i32 ---
	PEM_read_PKCS8_PRIV_KEY_INFO      :: proc(fp: ^FILE, x: ^^PKCS8_PRIV_KEY_INFO, cb: ^pem_password_cb, u: rawptr) -> ^PKCS8_PRIV_KEY_INFO ---
	PEM_write_PKCS8_PRIV_KEY_INFO     :: proc(fp: ^FILE, x: ^PKCS8_PRIV_KEY_INFO) -> i32 ---
	PEM_read_bio_PKCS8_PRIV_KEY_INFO  :: proc(bp: ^BIO, x: ^^PKCS8_PRIV_KEY_INFO, cb: ^pem_password_cb, u: rawptr) -> ^PKCS8_PRIV_KEY_INFO ---
	PEM_write_RSAPrivateKey           :: proc(fp: ^FILE, x: ^RSA, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_write_bio_RSAPrivateKey       :: proc(bp: ^BIO, x: ^RSA, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_read_bio_RSAPrivateKey        :: proc(bp: ^BIO, x: ^^RSA, cb: ^pem_password_cb, u: rawptr) -> ^RSA ---
	PEM_read_RSAPrivateKey            :: proc(fp: ^FILE, x: ^^RSA, cb: ^pem_password_cb, u: rawptr) -> ^RSA ---
	PEM_write_RSAPublicKey            :: proc(fp: ^FILE, x: ^RSA) -> i32 ---
	PEM_write_bio_RSAPublicKey        :: proc(bp: ^BIO, x: ^RSA) -> i32 ---
	PEM_read_bio_RSAPublicKey         :: proc(bp: ^BIO, x: ^^RSA, cb: ^pem_password_cb, u: rawptr) -> ^RSA ---
	PEM_read_RSAPublicKey             :: proc(fp: ^FILE, x: ^^RSA, cb: ^pem_password_cb, u: rawptr) -> ^RSA ---
	PEM_read_RSA_PUBKEY               :: proc(fp: ^FILE, x: ^^RSA, cb: ^pem_password_cb, u: rawptr) -> ^RSA ---
	PEM_read_bio_RSA_PUBKEY           :: proc(bp: ^BIO, x: ^^RSA, cb: ^pem_password_cb, u: rawptr) -> ^RSA ---
	PEM_write_bio_RSA_PUBKEY          :: proc(bp: ^BIO, x: ^RSA) -> i32 ---
	PEM_write_RSA_PUBKEY              :: proc(fp: ^FILE, x: ^RSA) -> i32 ---
	PEM_write_DSAPrivateKey           :: proc(fp: ^FILE, x: ^DSA, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_read_DSAPrivateKey            :: proc(fp: ^FILE, x: ^^DSA, cb: ^pem_password_cb, u: rawptr) -> ^DSA ---
	PEM_read_bio_DSAPrivateKey        :: proc(bp: ^BIO, x: ^^DSA, cb: ^pem_password_cb, u: rawptr) -> ^DSA ---
	PEM_write_bio_DSAPrivateKey       :: proc(bp: ^BIO, x: ^DSA, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_write_bio_DSA_PUBKEY          :: proc(bp: ^BIO, x: ^DSA) -> i32 ---
	PEM_read_DSA_PUBKEY               :: proc(fp: ^FILE, x: ^^DSA, cb: ^pem_password_cb, u: rawptr) -> ^DSA ---
	PEM_write_DSA_PUBKEY              :: proc(fp: ^FILE, x: ^DSA) -> i32 ---
	PEM_read_bio_DSA_PUBKEY           :: proc(bp: ^BIO, x: ^^DSA, cb: ^pem_password_cb, u: rawptr) -> ^DSA ---
	PEM_read_bio_DSAparams            :: proc(bp: ^BIO, x: ^^DSA, cb: ^pem_password_cb, u: rawptr) -> ^DSA ---
	PEM_read_DSAparams                :: proc(fp: ^FILE, x: ^^DSA, cb: ^pem_password_cb, u: rawptr) -> ^DSA ---
	PEM_write_bio_DSAparams           :: proc(bp: ^BIO, x: ^DSA) -> i32 ---
	PEM_write_DSAparams               :: proc(fp: ^FILE, x: ^DSA) -> i32 ---
	PEM_write_bio_ECPrivateKey        :: proc(bp: ^BIO, x: ^EC_KEY, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_read_bio_ECPrivateKey         :: proc(bp: ^BIO, x: ^^EC_KEY, cb: ^pem_password_cb, u: rawptr) -> ^EC_KEY ---
	PEM_read_ECPrivateKey             :: proc(fp: ^FILE, x: ^^EC_KEY, cb: ^pem_password_cb, u: rawptr) -> ^EC_KEY ---
	PEM_write_ECPrivateKey            :: proc(fp: ^FILE, x: ^EC_KEY, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_read_EC_PUBKEY                :: proc(fp: ^FILE, x: ^^EC_KEY, cb: ^pem_password_cb, u: rawptr) -> ^EC_KEY ---
	PEM_read_bio_EC_PUBKEY            :: proc(bp: ^BIO, x: ^^EC_KEY, cb: ^pem_password_cb, u: rawptr) -> ^EC_KEY ---
	PEM_write_bio_EC_PUBKEY           :: proc(bp: ^BIO, x: ^EC_KEY) -> i32 ---
	PEM_write_EC_PUBKEY               :: proc(fp: ^FILE, x: ^EC_KEY) -> i32 ---
	PEM_write_DHparams                :: proc(fp: ^FILE, x: ^DH) -> i32 ---
	PEM_read_DHparams                 :: proc(fp: ^FILE, x: ^^DH, cb: ^pem_password_cb, u: rawptr) -> ^DH ---
	PEM_read_bio_DHparams             :: proc(bp: ^BIO, x: ^^DH, cb: ^pem_password_cb, u: rawptr) -> ^DH ---
	PEM_write_bio_DHparams            :: proc(bp: ^BIO, x: ^DH) -> i32 ---
	PEM_write_PrivateKey              :: proc(fp: ^FILE, x: ^EVP_PKEY, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_write_bio_PrivateKey          :: proc(bp: ^BIO, x: ^EVP_PKEY, enc: ^EVP_CIPHER, pass: ^u8, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_read_bio_PrivateKey           :: proc(bp: ^BIO, x: ^^EVP_PKEY, cb: ^pem_password_cb, u: rawptr) -> ^EVP_PKEY ---
	PEM_read_PrivateKey               :: proc(fp: ^FILE, x: ^^EVP_PKEY, cb: ^pem_password_cb, u: rawptr) -> ^EVP_PKEY ---
	PEM_write_PUBKEY                  :: proc(fp: ^FILE, x: ^EVP_PKEY) -> i32 ---
	PEM_read_PUBKEY                   :: proc(fp: ^FILE, x: ^^EVP_PKEY, cb: ^pem_password_cb, u: rawptr) -> ^EVP_PKEY ---
	PEM_read_bio_PUBKEY               :: proc(bp: ^BIO, x: ^^EVP_PKEY, cb: ^pem_password_cb, u: rawptr) -> ^EVP_PKEY ---
	PEM_write_bio_PUBKEY              :: proc(bp: ^BIO, x: ^EVP_PKEY) -> i32 ---
	PEM_write_bio_PKCS8PrivateKey_nid :: proc(bp: ^BIO, x: ^EVP_PKEY, nid: i32, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_write_bio_PKCS8PrivateKey     :: proc(bp: ^BIO, x: ^EVP_PKEY, enc: ^EVP_CIPHER, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	i2d_PKCS8PrivateKey_bio           :: proc(bp: ^BIO, x: ^EVP_PKEY, enc: ^EVP_CIPHER, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	i2d_PKCS8PrivateKey_nid_bio       :: proc(bp: ^BIO, x: ^EVP_PKEY, nid: i32, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	d2i_PKCS8PrivateKey_bio           :: proc(bp: ^BIO, x: ^^EVP_PKEY, cb: ^pem_password_cb, u: rawptr) -> ^EVP_PKEY ---
	i2d_PKCS8PrivateKey_fp            :: proc(fp: ^FILE, x: ^EVP_PKEY, enc: ^EVP_CIPHER, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	i2d_PKCS8PrivateKey_nid_fp        :: proc(fp: ^FILE, x: ^EVP_PKEY, nid: i32, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	PEM_write_PKCS8PrivateKey_nid     :: proc(fp: ^FILE, x: ^EVP_PKEY, nid: i32, pass: cstring, pass_len: i32, cb: ^pem_password_cb, u: rawptr) -> i32 ---
	d2i_PKCS8PrivateKey_fp            :: proc(fp: ^FILE, x: ^^EVP_PKEY, cb: ^pem_password_cb, u: rawptr) -> ^EVP_PKEY ---
	PEM_write_PKCS8PrivateKey         :: proc(fp: ^FILE, x: ^EVP_PKEY, enc: ^EVP_CIPHER, pass: cstring, pass_len: i32, cd: ^pem_password_cb, u: rawptr) -> i32 ---
}

PEM_R_BAD_BASE64_DECODE             :: 100
PEM_R_BAD_DECRYPT                   :: 101
PEM_R_BAD_END_LINE                  :: 102
PEM_R_BAD_IV_CHARS                  :: 103
PEM_R_BAD_PASSWORD_READ             :: 104
PEM_R_CIPHER_IS_NULL                :: 105
PEM_R_ERROR_CONVERTING_PRIVATE_KEY  :: 106
PEM_R_NOT_DEK_INFO                  :: 107
PEM_R_NOT_ENCRYPTED                 :: 108
PEM_R_NOT_PROC_TYPE                 :: 109
PEM_R_NO_START_LINE                 :: 110
PEM_R_READ_KEY                      :: 111
PEM_R_SHORT_HEADER                  :: 112
PEM_R_UNSUPPORTED_CIPHER            :: 113
PEM_R_UNSUPPORTED_ENCRYPTION        :: 114
PEM_R_UNSUPPORTED_PROC_TYPE_VERSION :: 115

