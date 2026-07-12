package x509

import "core:encoding/asn1"

// Private_Key holds the RAW key material to serialize as a PKCS#8
// PrivateKeyInfo (RFC 5208 / 5958). It is the bytes the crypto packages expose
// (ecdsa.private_key_bytes / public_key_bytes, ed25519.private_key_bytes),
// which marshal_pkcs8 only assembles into DER. For ECDSA, `private` is the
// secret scalar and `public` (optional) the uncompressed point; for Ed25519,
// `private` is the 32-byte seed and `public` is ignored.
Private_Key :: struct {
	algorithm: Public_Key_Algorithm,
	private:   []byte,
	public:    []byte,
}

@(rodata, private)
_DER_INT_ONE := []byte{0x01}

// Serializes `key` as a DER PKCS#8 PrivateKeyInfo. The crypto has already
// happened; this only nests the raw bytes. RSA and unknown algorithms
// yield .Unsupported_Algorithm (RSA is out of scope here). The returned
// slice is the caller's to free.
@(require_results)
marshal_pkcs8 :: proc(key: Private_Key, allocator := context.allocator) -> (der: []byte, err: Error) {
	out: []byte
	merr: asn1.Error
	switch key.algorithm {
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
		// ECPrivateKey ::= SEQUENCE { version(1), privateKey OCTET STRING, [1] publicKey BIT STRING OPTIONAL }
		// (parameters [0] is omitted: the curve is in privateKeyAlgorithm.)
		ec_fields: [3]asn1.Value
		pub_wrap: [1]asn1.Value // stable backing for the [1] EXPLICIT child
		n := 0
		ec_fields[n] = asn1.integer_raw(_DER_INT_ONE)
		n += 1
		ec_fields[n] = asn1.octet_string(key.private)
		n += 1
		if len(key.public) > 0 {
			pub_wrap[0] = asn1.bit_string_octets(key.public)
			ec_fields[n] = asn1.context_explicit(1, pub_wrap[:])
			n += 1
		}
		// PrivateKeyInfo ::= SEQUENCE { version(0), AlgId{ecPublicKey, curve},
		//                               privateKey OCTET STRING { ECPrivateKey } }
		out, merr = asn1.marshal(
			asn1.sequence(
				{
					asn1.integer_raw(_DER_INT_ZERO),
					asn1.sequence({asn1.object_identifier(_OID_KEY_EC), asn1.object_identifier(curve_oid)}),
					asn1.octet_string_wrap({asn1.sequence(ec_fields[:n])}),
				},
			),
			allocator,
		)
	case .Ed25519:
		// PrivateKeyInfo ::= SEQUENCE { version(0), AlgId{Ed25519},
		//   privateKey OCTET STRING { CurvePrivateKey ::= OCTET STRING seed } }
		out, merr = asn1.marshal(
			asn1.sequence(
				{
					asn1.integer_raw(_DER_INT_ZERO),
					asn1.sequence({asn1.object_identifier(_OID_ED25519)}),
					asn1.octet_string_wrap({asn1.octet_string(key.private)}),
				},
			),
			allocator,
		)
	case .RSA, .Unknown:
		return nil, .Unsupported_Algorithm
	}
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}
