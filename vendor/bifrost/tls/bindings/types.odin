package bifrost_tls_bindings
import "core:c"
foreign import lib {
	LIBSSL_PATH,
	LIBCRYPTO_PATH,
	"system:stdc++",
	"system:gcc_s",
}

@(private) LIBSSL_PATH    :: "../../../boringssl/lib/libssl.a"
@(private) LIBCRYPTO_PATH :: "../../../boringssl/lib/libcrypto.a"

__time_t :: c.long
__suseconds_t :: c.long
ASN1_BOOLEAN :: c.int
ossl_ssize_t :: distinct int
FILE :: struct {}

// Opaque forward declarations required by the bindings.
ASN1_BIT_STRING :: struct {}
ASN1_ENUMERATED :: struct {}
ASN1_IA5STRING :: struct {}
ASN1_INTEGER :: struct {}
ASN1_ITEM :: struct {}
ASN1_ITEM_EXP :: struct {}
ASN1_OBJECT :: struct {}
ASN1_OCTET_STRING :: struct {}
ASN1_PCTX :: struct {}
ASN1_STRING :: struct {}
ASN1_TIME :: struct {}
ASN1_TYPE :: struct {}
AUTHORITY_KEYID :: struct {}
BASIC_CONSTRAINTS :: struct {}
BIGNUM :: struct {}
BIO :: struct {}
BIO_METHOD :: struct {}
BUF_MEM :: struct {}
CBB :: struct {}
CBS :: struct {}
CONF :: struct {}
CONF_VALUE :: struct {}
CRYPTO_BUFFER :: struct {}
CRYPTO_BUFFER_POOL :: struct {}
CRYPTO_MUST_BE_NULL :: struct {}
CRYPTO_THREADID :: struct {}
DH :: struct {}
DIST_POINT :: struct {}
DSA :: struct {}
EC_KEY :: struct {}
ENGINE :: struct {}
EVP_CIPHER :: struct {}
EVP_CIPHER_INFO :: struct {}
EVP_HPKE_KEY :: struct {}
EVP_MD :: struct {}
EVP_MD_CTX :: struct {}
EVP_PKEY :: struct {}
EVP_PKEY_ALG :: struct {}
EVP_PKEY_CTX :: struct {}
GENERAL_NAME :: struct {}
ISSUING_DIST_POINT :: struct {}
NAME_CONSTRAINTS :: struct {}
NETSCAPE_SPKAC :: struct {}
NETSCAPE_SPKI :: struct {}
OPENSSL_INIT_SETTINGS :: struct {}
PKCS7 :: struct {}
PKCS8_PRIV_KEY_INFO :: struct {}
RSA :: struct {}
RSA_PSS_PARAMS :: struct {}
SRTP_PROTECTION_PROFILE :: struct {}
SSL :: struct {}
SSL_CIPHER :: struct {}
SSL_CLIENT_HELLO :: struct {}
SSL_CREDENTIAL :: struct {}
SSL_CTX :: struct {}
SSL_ECH_KEYS :: struct {}
SSL_METHOD :: struct {}
SSL_PRIVATE_KEY_METHOD :: struct {}
SSL_QUIC_METHOD :: struct {}
SSL_SESSION :: struct {}
SSL_TICKET_AEAD_METHOD :: struct {}
X509 :: struct {}
X509V3_CTX :: struct {}
X509V3_EXT_METHOD :: struct {}
X509_ALGOR :: struct {}
X509_ATTRIBUTE :: struct {}
X509_CRL :: struct {}
X509_EXTENSION :: struct {}
X509_INFO :: struct {}
X509_LOOKUP :: struct {}
X509_LOOKUP_METHOD :: struct {}
X509_NAME :: struct {}
X509_NAME_ENTRY :: struct {}
X509_OBJECT :: struct {}
X509_PKEY :: struct {}
X509_PUBKEY :: struct {}
X509_PURPOSE :: struct {}
X509_REQ :: struct {}
X509_REVOKED :: struct {}
X509_SIG :: struct {}
X509_STORE :: struct {}
X509_STORE_CTX :: struct {}
X509_VERIFY_PARAM :: struct {}
stack_st_ASN1_INTEGER :: struct {}
stack_st_ASN1_OBJECT :: struct {}
stack_st_CONF_VALUE :: struct {}
stack_st_CRYPTO_BUFFER :: struct {}

// Function pointer typedefs used by the bindings.
CRYPTO_EX_dup :: proc "c" () -> rawptr
CRYPTO_EX_free :: proc "c" ()
CRYPTO_EX_unused :: proc "c" ()
d2i_of_void :: proc "c" () -> rawptr
i2d_of_void :: proc "c" () -> i32
