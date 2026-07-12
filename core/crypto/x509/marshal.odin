package x509

import "core:encoding/asn1"
import "core:time"

// Distinguished-name attribute types the DN builder knows by name.
DN_Attribute_Type :: enum {
	Common_Name,         // CN, 2.5.4.3
	Country,             // C,  2.5.4.6
	Locality,            // L,  2.5.4.7
	State_Or_Province,   // ST, 2.5.4.8
	Organization,        // O,  2.5.4.10
	Organizational_Unit, // OU, 2.5.4.11
	Serial_Number,       // 2.5.4.5
}

// DN_Attribute is one relative distinguished name: a type and its value.
// Values are emitted as UTF8String, except Country and Serial_Number which
// are PrintableString (X.520), the policy RFC 5280 section 4.1.2.4 advises.
DN_Attribute :: struct {
	type:  DN_Attribute_Type,
	value: string,
}

@(rodata, private)
_OID_AT_CN := []byte{0x55, 0x04, 0x03}
@(rodata, private)
_OID_AT_C := []byte{0x55, 0x04, 0x06}
@(rodata, private)
_OID_AT_L := []byte{0x55, 0x04, 0x07}
@(rodata, private)
_OID_AT_ST := []byte{0x55, 0x04, 0x08}
@(rodata, private)
_OID_AT_O := []byte{0x55, 0x04, 0x0A}
@(rodata, private)
_OID_AT_OU := []byte{0x55, 0x04, 0x0B}
@(rodata, private)
_OID_AT_SERIAL := []byte{0x55, 0x04, 0x05}

// marshal_dn encodes `attrs` as a DER Name (RDNSequence): one single-valued
// RelativeDistinguishedName per attribute, in the given order. The returned
// slice is the caller's to free; the attribute value bytes are copied into
// it, so `attrs` need not outlive the call.
@(require_results)
marshal_dn :: proc(attrs: []DN_Attribute, allocator := context.allocator) -> (der: []byte, err: Error) {
	n := len(attrs)
	// Value-tree scaffolding, freed once the bytes are produced. Pre-sized so
	// the sub-slices handed to set()/sequence() never move before the encode.
	rdns, e1 := make([]asn1.Value, n, allocator) // one SET per attribute
	if e1 != nil {
		return nil, .Allocation_Failed
	}
	defer delete(rdns, allocator)
	atvs, e2 := make([]asn1.Value, n, allocator) // the AttributeTypeAndValue SEQUENCE
	if e2 != nil {
		return nil, .Allocation_Failed
	}
	defer delete(atvs, allocator)
	pairs, e3 := make([]asn1.Value, 2 * n, allocator) // {type OID, value} per attribute
	if e3 != nil {
		return nil, .Allocation_Failed
	}
	defer delete(pairs, allocator)

	for a, i in attrs {
		pairs[2 * i] = asn1.object_identifier(_dn_oid(a.type))
		pairs[2 * i + 1] = asn1.primitive(_dn_string_tag(a.type), transmute([]byte)a.value)
		atvs[i] = asn1.sequence(pairs[2 * i:2 * i + 2])
		rdns[i] = asn1.set(atvs[i:i + 1])
	}

	out, merr := asn1.marshal(asn1.sequence(rdns), allocator)
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

@(private)
_dn_oid :: proc(type: DN_Attribute_Type) -> []byte {
	switch type {
	case .Common_Name:
		return _OID_AT_CN
	case .Country:
		return _OID_AT_C
	case .Locality:
		return _OID_AT_L
	case .State_Or_Province:
		return _OID_AT_ST
	case .Organization:
		return _OID_AT_O
	case .Organizational_Unit:
		return _OID_AT_OU
	case .Serial_Number:
		return _OID_AT_SERIAL
	}
	return nil
}

@(private)
_dn_string_tag :: proc(type: DN_Attribute_Type) -> asn1.Tag {
	#partial switch type {
	case .Country, .Serial_Number:
		return asn1.universal(.Printable_String)
	}
	return asn1.universal(.UTF8_String)
}

@(rodata, private)
_DER_INT_ZERO := []byte{0x00}

// marshal_csr_info encodes the CertificationRequestInfo, the to-be-signed
// portion of a PKCS#10 CSR (RFC 2986): version v1, the subject DN, the subject
// public key, and the attributes set. Sign the returned bytes and pass them
// with the signature to marshal_csr. The slice is the caller's to free;
// `subject`, `key`, and `extensions` need not outlive the call.
//
// `extensions` is a list of pre-encoded Extension DER (from the marshal_ext_*
// helpers); when non-empty it is requested via a single PKCS#9
// extensionRequest attribute (the standard way a CSR asks the CA to place
// extensions, SANs, key usage in the issued certificate). Pass nil for the
// empty attributes set.
@(require_results)
marshal_csr_info :: proc(subject: []DN_Attribute, key: Public_Key, extensions: [][]byte = nil, allocator := context.allocator) -> (cri_der: []byte, err: Error) {
	dn := marshal_dn(subject, allocator) or_return
	defer delete(dn, allocator)
	spki := marshal_spki(key, allocator) or_return
	defer delete(spki, allocator)
	attrs := _marshal_csr_attributes(extensions, allocator) or_return
	defer delete(attrs, allocator)

	// CertificationRequestInfo ::= SEQUENCE { version, subject, subjectPKInfo, [0] attributes }
	out, merr := asn1.marshal(
		asn1.sequence(
			{
				asn1.integer_raw(_DER_INT_ZERO), // version v1 (0)
				asn1.raw(dn), // subject Name
				asn1.raw(spki), // subjectPublicKeyInfo
				asn1.raw(attrs), // attributes [0]
			},
		),
		allocator,
	)
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// _marshal_csr_attributes encodes the CertificationRequestInfo attributes
// field, [0] IMPLICIT SET OF Attribute. With no extensions it is the empty
// set (A0 00); otherwise it carries a single PKCS#9 extensionRequest attribute
//   Attribute ::= SEQUENCE { type extensionRequest, values SET { Extensions } }
// whose value is the Extensions SEQUENCE OF Extension built from `extensions`.
@(private, require_results)
_marshal_csr_attributes :: proc(extensions: [][]byte, allocator := context.allocator) -> (der: []byte, err: Error) {
	out: []byte
	merr: asn1.Error
	if len(extensions) == 0 {
		out, merr = asn1.marshal(asn1.context_explicit(0, {}), allocator)
	} else {
		// Pre-sized scaffolding for the Extensions SEQUENCE OF, kept alive
		// (never resized) through the marshal below.
		ext_raws, e := make([]asn1.Value, len(extensions), allocator)
		if e != nil {
			return nil, .Allocation_Failed
		}
		defer delete(ext_raws, allocator)
		for ext, i in extensions {
			ext_raws[i] = asn1.raw(ext)
		}
		out, merr = asn1.marshal(
			asn1.context_explicit(
				0,
				{asn1.sequence({asn1.object_identifier(_OID_EXT_REQUEST), asn1.set({asn1.sequence(ext_raws[:])})})},
			),
			allocator,
		)
	}
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// marshal_csr wraps a (separately signed) CertificationRequestInfo into a
// complete PKCS#10 CertificationRequest. `signature` is the raw signature
// value over `cri_der`, a DER ECDSA-Sig-Value for ECDSA, the 64-byte value
// for Ed25519, and `signature_algorithm` selects the matching
// AlgorithmIdentifier. The slice is the caller's to free.
@(require_results)
marshal_csr :: proc(cri_der: []byte, signature_algorithm: Signature_Algorithm, signature: []byte, allocator := context.allocator) -> (csr_der: []byte, err: Error) {
	// CertificationRequest ::= SEQUENCE { CRI, signatureAlgorithm, signature BIT STRING }
	return _marshal_signed(cri_der, signature_algorithm, signature, allocator)
}

// _marshal_signed wraps an already-encoded body (a CertificationRequestInfo
// or a TBSCertificate) with its signature algorithm and signature BIT STRING:
//   SEQUENCE { body, AlgorithmIdentifier, BIT STRING signature }
// the common shape of PKCS#10 CSRs and X.509 certificates.
@(private, require_results)
_marshal_signed :: proc(body_der: []byte, signature_algorithm: Signature_Algorithm, signature: []byte, allocator := context.allocator) -> (der: []byte, err: Error) {
	oid, null_params, ok := _sig_alg_identifier(signature_algorithm)
	if !ok {
		return nil, .Unsupported_Algorithm
	}
	out: []byte
	merr: asn1.Error
	if null_params {
		out, merr = asn1.marshal(
			asn1.sequence(
				{
					asn1.raw(body_der),
					asn1.sequence({asn1.object_identifier(oid), asn1.null()}),
					asn1.bit_string_octets(signature),
				},
			),
			allocator,
		)
	} else {
		out, merr = asn1.marshal(
			asn1.sequence(
				{asn1.raw(body_der), asn1.sequence({asn1.object_identifier(oid)}), asn1.bit_string_octets(signature)},
			),
			allocator,
		)
	}
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// _marshal_alg_id encodes a standalone AlgorithmIdentifier (NULL params for
// RSA PKCS#1, absent for ECDSA/EdDSA) for embedding in a TBSCertificate.
@(private, require_results)
_marshal_alg_id :: proc(signature_algorithm: Signature_Algorithm, allocator := context.allocator) -> (der: []byte, err: Error) {
	oid, null_params, ok := _sig_alg_identifier(signature_algorithm)
	if !ok {
		return nil, .Unsupported_Algorithm
	}
	out: []byte
	merr: asn1.Error
	if null_params {
		out, merr = asn1.marshal(asn1.sequence({asn1.object_identifier(oid), asn1.null()}), allocator)
	} else {
		out, merr = asn1.marshal(asn1.sequence({asn1.object_identifier(oid)}), allocator)
	}
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// Maps a signature algorithm to its AlgorithmIdentifier OID and whether the
// parameters field is an explicit NULL (RSA PKCS#1) or absent (ECDSA, EdDSA).
@(private)
_sig_alg_identifier :: proc(alg: Signature_Algorithm) -> (oid: []byte, null_params: bool, ok: bool) {
	#partial switch alg {
	case .RSA_SHA256:
		return _OID_SIG_RSA_SHA256, true, true
	case .RSA_SHA384:
		return _OID_SIG_RSA_SHA384, true, true
	case .RSA_SHA512:
		return _OID_SIG_RSA_SHA512, true, true
	case .ECDSA_SHA256:
		return _OID_SIG_ECDSA_SHA256, false, true
	case .ECDSA_SHA384:
		return _OID_SIG_ECDSA_SHA384, false, true
	case .ECDSA_SHA512:
		return _OID_SIG_ECDSA_SHA512, false, true
	case .Ed25519:
		return _OID_ED25519, false, true
	}
	return nil, false, false
}

@(rodata, private)
_DER_INT_V3 := []byte{0x02} // Version v3 (value 2)

// _marshal_extensions_field encodes the TBSCertificate extensions field:
//   [3] EXPLICIT Extensions, Extensions ::= SEQUENCE OF Extension
// from a list of pre-encoded Extension DER, or nil when there are none (the
// field is OPTIONAL, so an empty list omits it entirely).
@(private, require_results)
_marshal_extensions_field :: proc(extensions: [][]byte, allocator := context.allocator) -> (der: []byte, err: Error) {
	if len(extensions) == 0 {
		return nil, .None
	}
	raws, merr := make([]asn1.Value, len(extensions), allocator)
	if merr != nil {
		return nil, .Allocation_Failed
	}
	defer delete(raws, allocator)
	for e, i in extensions {
		raws[i] = asn1.raw(e)
	}
	out, ferr := asn1.marshal(asn1.context_explicit(3, {asn1.sequence(raws[:])}), allocator)
	if ferr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// TBS_Certificate gathers the fields of a TBSCertificate to encode. `issuer`
// and `subject` are RDNSequences; `serial` is the serialNumber's unsigned
// magnitude; `extensions` is a list of pre-encoded Extension DER (from the
// marshal_ext_* helpers), embedded in order.
TBS_Certificate :: struct {
	serial:              []byte,
	signature_algorithm: Signature_Algorithm,
	issuer:              []DN_Attribute,
	not_before:          time.Time,
	not_after:           time.Time,
	subject:             []DN_Attribute,
	public_key:          Public_Key,
	extensions:          [][]byte,
}

// marshal_tbs_certificate encodes a v3 TBSCertificate (RFC 5280 section 4.1),
// the to-be-signed portion of a certificate. Sign the returned bytes and pass
// them with the signature to marshal_certificate. The slice is the caller's to
// free; the inputs need not outlive the call.
@(require_results)
marshal_tbs_certificate :: proc(tbs: TBS_Certificate, allocator := context.allocator) -> (der: []byte, err: Error) {
	issuer_dn := marshal_dn(tbs.issuer, allocator) or_return
	defer delete(issuer_dn, allocator)
	subject_dn := marshal_dn(tbs.subject, allocator) or_return
	defer delete(subject_dn, allocator)
	spki := marshal_spki(tbs.public_key, allocator) or_return
	defer delete(spki, allocator)
	sig_alg := _marshal_alg_id(tbs.signature_algorithm, allocator) or_return
	defer delete(sig_alg, allocator)
	ext_field := _marshal_extensions_field(tbs.extensions, allocator) or_return
	defer delete(ext_field, allocator)

	// raw() splices the independently-marshalled pieces in place; raw(nil) for
	// an absent extensions field contributes nothing.
	out, merr := asn1.marshal(
		asn1.sequence(
			{
				asn1.context_explicit(0, {asn1.integer_raw(_DER_INT_V3)}), // version [0] EXPLICIT v3
				asn1.integer_unsigned(tbs.serial), // serialNumber
				asn1.raw(sig_alg), // signature AlgorithmIdentifier
				asn1.raw(issuer_dn), // issuer
				asn1.sequence({asn1.time(tbs.not_before), asn1.time(tbs.not_after)}), // validity
				asn1.raw(subject_dn), // subject
				asn1.raw(spki), // subjectPublicKeyInfo
				asn1.raw(ext_field), // extensions [3] (absent when empty)
			},
		),
		allocator,
	)
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// marshal_certificate wraps a (separately signed) TBSCertificate into a
// complete X.509 Certificate. `signature_algorithm` must match the one inside
// the TBS (RFC 5280 section 4.1.1.2). The slice is the caller's to free.
@(require_results)
marshal_certificate :: proc(tbs_der: []byte, signature_algorithm: Signature_Algorithm, signature: []byte, allocator := context.allocator) -> (der: []byte, err: Error) {
	return _marshal_signed(tbs_der, signature_algorithm, signature, allocator)
}

// Public_Key holds the subject public-key material to encode into a
// SubjectPublicKeyInfo, mirroring the fields parse() extracts onto a
// Certificate: rsa_n/rsa_e (unsigned magnitudes) for RSA; ec_point for
// ECDSA (the uncompressed point 0x04||X||Y) and Ed25519 (the 32-byte key).
Public_Key :: struct {
	algorithm: Public_Key_Algorithm,
	rsa_n:     []byte,
	rsa_e:     []byte,
	ec_point:  []byte,
}

// marshal_spki encodes `key` as a DER SubjectPublicKeyInfo, the inverse of
// the SPKI decoding in parse(); the returned slice is the caller's to free.
// Unknown / unsupported key algorithms yield .Unsupported_Algorithm.
@(require_results)
marshal_spki :: proc(key: Public_Key, allocator := context.allocator) -> (der: []byte, err: Error) {
	out: []byte
	merr: asn1.Error
	switch key.algorithm {
	case .RSA:
		// SEQUENCE { SEQUENCE { OID rsaEncryption, NULL }, BIT STRING { RSAPublicKey } }
		out, merr = asn1.marshal(
			asn1.sequence(
				{
					asn1.sequence({asn1.object_identifier(_OID_KEY_RSA), asn1.null()}),
					asn1.bit_string_wrap({asn1.sequence({asn1.integer_unsigned(key.rsa_n), asn1.integer_unsigned(key.rsa_e)})}),
				},
			),
			allocator,
		)
	case .ECDSA_P256, .ECDSA_P384, .ECDSA_P521:
		curve_oid: []byte
		#partial switch key.algorithm {
		case .ECDSA_P256:
			curve_oid = _OID_CURVE_P256
		case .ECDSA_P384:
			curve_oid = _OID_CURVE_P384
		case .ECDSA_P521:
			curve_oid = _OID_CURVE_P521
		}
		// SEQUENCE { SEQUENCE { OID ecPublicKey, OID namedCurve }, BIT STRING point }
		out, merr = asn1.marshal(
			asn1.sequence(
				{
					asn1.sequence({asn1.object_identifier(_OID_KEY_EC), asn1.object_identifier(curve_oid)}),
					asn1.bit_string_octets(key.ec_point),
				},
			),
			allocator,
		)
	case .Ed25519:
		// SEQUENCE { SEQUENCE { OID Ed25519 }, BIT STRING key }  (no params, RFC 8410)
		out, merr = asn1.marshal(
			asn1.sequence({asn1.sequence({asn1.object_identifier(_OID_ED25519)}), asn1.bit_string_octets(key.ec_point)}),
			allocator,
		)
	case .Unknown:
		return nil, .Unsupported_Algorithm
	}
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}
