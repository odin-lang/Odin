package x509

import "core:time"

Error :: enum {
	None, 
	Malformed, // DER-level violation, structural mismatch, or trailing garbage.
	Unsupported_Version, // Certificate version beyond v3.
	Invalid_Validity, // notBefore/notAfter missing or unparseable.
	Invalid_Extension, // A recognized extension's content didn't match its schema.
	Duplicate_Extension, // The same extension OID appeared more than once (RFC 5280 section 4.2 forbids this).
	Hostname_Mismatch, // Hostname verification: no SAN matched.
	No_SAN, // Hostname verification: the certificate has no usable SANs of the queried kind.
	Allocation_Failed, // Allocating the extension/SAN tables failed.

	// --- verification (verify_signature / verify_chain) ---
	Signature_Invalid, // A signature did not verify against the issuer's public key.
	Unsupported_Algorithm, // The signature or public-key algorithm is recognized but not implemented here.
	Not_Yet_Valid, // A certificate's notBefore is in the future relative to the supplied time.
	Expired, // A certificate's notAfter is in the past relative to the supplied time.
	Unknown_Authority, // (no issuer found, failed name chaining, validity, CA constraints, or signature verification).
	Unhandled_Critical_Extension, // Failed to handle a critical extension, automatic rejection
	Incompatible_Usage, // Lacks EKU, or EKU not authorized
}

// Signature_Algorithm covers the PKIX signature algorithms a client
// encounters in practice. RSA_PSS parameters are not interpreted; the
// raw AlgorithmIdentifier is preserved on the Certificate.
Signature_Algorithm :: enum {
	Unknown,
	RSA_SHA1, // obsolete; parsed for identification only
	RSA_SHA256,
	RSA_SHA384,
	RSA_SHA512,
	RSA_PSS,
	ECDSA_SHA256,
	ECDSA_SHA384,
	ECDSA_SHA512,
	Ed25519,
}

// Public_Key_Algorithm identifies the certificate's subject public key
// type. Unknown covers key algorithms (or EC curves) this package does
// not decode; the SubjectPublicKeyInfo bytes remain available in
// raw_spki.
Public_Key_Algorithm :: enum {
	Unknown,
	RSA,
	ECDSA_P256,
	ECDSA_P384,
	ECDSA_P521,
	Ed25519,
}

// Key_Usage bits per RFC 5280 section 4.2.1.3 
Key_Usage_Bit :: enum u16 {
	Digital_Signature  = 0,
	Content_Commitment = 1,
	Key_Encipherment   = 2,
	Data_Encipherment  = 3,
	Key_Agreement      = 4,
	Key_Cert_Sign      = 5,
	CRL_Sign           = 6,
	Encipher_Only      = 7,
	Decipher_Only      = 8,
}
// Key_Usage is the decoded KeyUsage extension bit set.
Key_Usage :: bit_set[Key_Usage_Bit;u16]

// Extended key usage purposes (RFC 5280 section 4.2.1.12) recognized by name;
// unrecognized purposes set `eku_has_unknown`.
EKU_Bit :: enum u8 {
	Server_Auth,
	Client_Auth,
	Code_Signing,
	Email_Protection,
	Time_Stamping,
	OCSP_Signing,
	Any,
}
// Ext_Key_Usage is the decoded set of recognized ExtKeyUsage purposes;
// unrecognized purposes set Certificate.eku_has_unknown.
Ext_Key_Usage :: bit_set[EKU_Bit;u8]

// Extension is one raw entry from the TBS extensions list. `oid` is
// the OID content octets; `value` the extnValue OCTET STRING content.
Extension :: struct {
	oid:      []byte,
	critical: bool,
	value:    []byte,
}

// Certificate is a parsed X.509 v3 certificate. 
// Byte-slice fields are views into the input DER (which must outlive the Certificate)
// The dns_names / ip_addresses / extensions slices are *allocated* (their elements still view the DER) and released by destroy.
Certificate :: struct {
	// Raw views into the input DER.
	raw:                     []byte, // the whole Certificate element
	raw_tbs:                 []byte, // TBSCertificate, header included, the signed bytes
	raw_issuer:              []byte, // issuer Name element (RFC 5280 binary comparison)
	raw_subject:             []byte, // subject Name element
	raw_spki:                []byte, // SubjectPublicKeyInfo element; hash for tls-server-end-point / SPKI pinning
	version:                 int, // 1, 2, or 3
	// Certificate serial number as the raw DER INTEGER content (minimal two's-complement). 
	// It is an opaque identifier, compare and display by these bytes. A positive serial whose top
	// bit is set carries a leading 0x00 sign octet (as openssl shows it); a serial of 0 is the single octet {0x00}. RFC 5280 requires
	// serials to be positive and <= 20 octets, but non-conformant (negative, zero, or over-long) serials are preserved
	serial:                  []byte,
	signature_algorithm:     Signature_Algorithm,
	signature_oid:           []byte, // OID content octets
	signature:               []byte, // signatureValue payload (whole octets)

	// Validity bounds. time.Time is i64 nanoseconds and tops out near year 2262; X.509 dates beyond that (notably the RFC 5280
	// "99991231235959Z" no-expiration sentinel) saturate to that bound at parse time, so they compare as "effectively never expires"
	// rather than overflowing. See asn1's _time_from_unix.
	not_before:              time.Time,
	not_after:               time.Time,
	public_key_algorithm:    Public_Key_Algorithm,
	// RSA: modulus and exponent magnitudes.
	rsa_n:                   []byte,
	rsa_e:                   []byte,
	// ECDSA: the uncompressed point (0x04 || X || Y); Ed25519: the 32-byte key.
	ec_point:                []byte,

	// BasicConstraints (basic_constraints_valid reports presence).
	basic_constraints_valid: bool,
	is_ca:                   bool,
	max_path_len:            int, // -1 when absent
	has_key_usage:           bool,
	key_usage:               Key_Usage,
	has_ext_key_usage:       bool,
	ext_key_usage:           Ext_Key_Usage,
	eku_has_unknown:         bool,
	subject_key_id:          []byte,
	authority_key_id:        []byte,

	dns_names:               []string, // ALLOCATED
	ip_addresses:            [][]byte, // ALLOCATED

	// Every extension, in order, including ones this package does not interpret. 
	extensions:              []Extension, // ALLOCATED

	// True if a critical extension other than the ones interpreted
	// here was present. RFC 5280 requires a relying party to reject
	// such a certificate at validation time; parsing still succeeds so
	// the caller can inspect. 
	//
	// The specific unhandled OIDs are recoverable by walking `extensions` 
	// for entries with `critical = true` whose OID is none of the handled 
	// ones (_OID_EXT_*).
	unhandled_critical:      bool,
}

destroy :: proc(cert: ^Certificate, allocator := context.allocator) {
	delete(cert.dns_names, allocator)
	delete(cert.ip_addresses, allocator)
	delete(cert.extensions, allocator)
	cert^ = {}
}

// PKIX object identifiers as DER content octets, for direct comparison against asn1.read_oid results. 
@(rodata, private)
_OID_SIG_RSA_SHA1 := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x05} // sha1WithRSAEncryption (1.2.840.113549.1.1.5)
@(rodata, private)
_OID_SIG_RSA_SHA256 := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B} // sha256WithRSAEncryption (1.2.840.113549.1.1.11)
@(rodata, private)
_OID_SIG_RSA_SHA384 := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0C} // sha384WithRSAEncryption (1.2.840.113549.1.1.12)
@(rodata, private)
_OID_SIG_RSA_SHA512 := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0D} // sha512WithRSAEncryption (1.2.840.113549.1.1.13)
@(rodata, private)
_OID_SIG_RSA_PSS := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0A} // id-RSASSA-PSS (1.2.840.113549.1.1.10)
@(rodata, private)
_OID_SIG_ECDSA_SHA256 := []byte{0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x02} // ecdsa-with-SHA256 (1.2.840.10045.4.3.2)
@(rodata, private)
_OID_SIG_ECDSA_SHA384 := []byte{0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x03} // ecdsa-with-SHA384 (1.2.840.10045.4.3.3)
@(rodata, private)
_OID_SIG_ECDSA_SHA512 := []byte{0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x04} // ecdsa-with-SHA512 (1.2.840.10045.4.3.4)
@(rodata, private)
_OID_ED25519 := []byte{0x2B, 0x65, 0x70} // id-Ed25519 (1.3.101.112), RFC 8410

@(rodata, private)
_OID_KEY_RSA := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01} // rsaEncryption (1.2.840.113549.1.1.1)
@(rodata, private)
_OID_KEY_EC := []byte{0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01} // id-ecPublicKey (1.2.840.10045.2.1)

@(rodata, private)
_OID_CURVE_P256 := []byte{0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07} // secp256r1 (1.2.840.10045.3.1.7)
@(rodata, private)
_OID_CURVE_P384 := []byte{0x2B, 0x81, 0x04, 0x00, 0x22} // secp384r1 (1.3.132.0.34)
@(rodata, private)
_OID_CURVE_P521 := []byte{0x2B, 0x81, 0x04, 0x00, 0x23} // secp521r1 (1.3.132.0.35)

@(rodata, private)
_OID_EXT_SUBJECT_KEY_ID := []byte{0x55, 0x1D, 0x0E} // id-ce-subjectKeyIdentifier (2.5.29.14)
@(rodata, private)
_OID_EXT_KEY_USAGE := []byte{0x55, 0x1D, 0x0F} // id-ce-keyUsage (2.5.29.15)
@(rodata, private)
_OID_EXT_SAN := []byte{0x55, 0x1D, 0x11} // id-ce-subjectAltName (2.5.29.17)
@(rodata, private)
_OID_EXT_BASIC_CONSTRAINTS := []byte{0x55, 0x1D, 0x13} // id-ce-basicConstraints (2.5.29.19)
@(rodata, private)
_OID_EXT_NAME_CONSTRAINTS := []byte{0x55, 0x1D, 0x1E} // id-ce-nameConstraints (2.5.29.30)
@(rodata, private)
_OID_EXT_AUTHORITY_KEY_ID := []byte{0x55, 0x1D, 0x23} // id-ce-authorityKeyIdentifier (2.5.29.35)
@(rodata, private)
_OID_EXT_EXT_KEY_USAGE := []byte{0x55, 0x1D, 0x25} // id-ce-extKeyUsage (2.5.29.37)

@(rodata, private)
_OID_EKU_ANY := []byte{0x55, 0x1D, 0x25, 0x00} // anyExtendedKeyUsage (2.5.29.37.0)
@(rodata, private)
_OID_EKU_SERVER_AUTH := []byte{0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01} // id-kp-serverAuth (1.3.6.1.5.5.7.3.1)
@(rodata, private)
_OID_EKU_CLIENT_AUTH := []byte{0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x02} // id-kp-clientAuth (1.3.6.1.5.5.7.3.2)
@(rodata, private)
_OID_EKU_CODE_SIGNING := []byte{0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x03} // id-kp-codeSigning (1.3.6.1.5.5.7.3.3)
@(rodata, private)
_OID_EKU_EMAIL_PROTECTION := []byte{0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x04} // id-kp-emailProtection (1.3.6.1.5.5.7.3.4)
@(rodata, private)
_OID_EKU_TIME_STAMPING := []byte{0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x08} // id-kp-timeStamping (1.3.6.1.5.5.7.3.8)
@(rodata, private)
_OID_EKU_OCSP_SIGNING := []byte{0x2B, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x09} // id-kp-OCSPSigning (1.3.6.1.5.5.7.3.9)
