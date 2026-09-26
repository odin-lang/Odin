package x509

import "core:crypto"
import "core:encoding/asn1"

// Private_Key holds the RAW key material to serialize as a PKCS#8
// PrivateKeyInfo (RFC 5208 / 5958). It is the bytes the crypto packages expose,
// which marshal_pkcs8 only assembles into DER:
//   - ECDSA: `private` is the secret scalar (ecdsa.private_key_bytes), `public`
//     (optional) the uncompressed point (ecdsa.public_key_bytes).
//   - Ed25519: `private` is the 32-byte seed (ed25519.private_key_bytes).
//   - RSA: the `rsa_*` CRT components, as big-endian magnitudes, from the
//     rsa.private_key_{n,e,d,p,q,dp,dq,iq} accessors.
Private_Key :: struct {
	algorithm: Public_Key_Algorithm,
	private:   []byte,
	public:    []byte,
	// RSA CRT components (big-endian magnitudes), used when algorithm == RSA.
	rsa_n:     []byte, // modulus
	rsa_e:     []byte, // public exponent
	rsa_d:     []byte, // private exponent
	rsa_p:     []byte, // prime1
	rsa_q:     []byte, // prime2
	rsa_dp:    []byte, // d mod (p-1)
	rsa_dq:    []byte, // d mod (q-1)
	rsa_iq:    []byte, // q^-1 mod p (CRT coefficient)
}

// private_key_clear securely wipes the secret material `key` references.
// The byte buffers are the caller's: this clears their secret contents
// in place (the public modulus / exponent / point are left untouched; only the
// slice headers are dropped). The DER that marshal_pkcs8 returns also holds the
// key, so wipe and free it separately. 
private_key_clear :: proc "contextless" (key: ^Private_Key) {
	crypto.zero_explicit(raw_data(key.private), len(key.private))
	crypto.zero_explicit(raw_data(key.rsa_d), len(key.rsa_d))
	crypto.zero_explicit(raw_data(key.rsa_p), len(key.rsa_p))
	crypto.zero_explicit(raw_data(key.rsa_q), len(key.rsa_q))
	crypto.zero_explicit(raw_data(key.rsa_dp), len(key.rsa_dp))
	crypto.zero_explicit(raw_data(key.rsa_dq), len(key.rsa_dq))
	crypto.zero_explicit(raw_data(key.rsa_iq), len(key.rsa_iq))
	key^ = {}
}

@(rodata, private)
_DER_INT_ONE := []byte{0x01}

// Serializes `key` as a DER PKCS#8 PrivateKeyInfo. The crypto has already
// happened; this only nests the raw bytes. An unknown algorithm yields
// .Unsupported_Algorithm. The returned slice is the caller's to free.
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
	case .RSA:
		// RSAPrivateKey ::= SEQUENCE { version(0, two-prime), n, e, d, p, q,
		//   exponent1(dp), exponent2(dq), coefficient(iq) }  (RFC 8017 A.1.2)
		// PrivateKeyInfo ::= SEQUENCE { version(0), AlgId{rsaEncryption, NULL},
		//   privateKey OCTET STRING { RSAPrivateKey } }
		out, merr = asn1.marshal(
			asn1.sequence(
				{
					asn1.integer_raw(_DER_INT_ZERO),
					asn1.sequence({asn1.object_identifier(_OID_KEY_RSA), asn1.null()}),
					asn1.octet_string_wrap(
						{
							asn1.sequence(
								{
									asn1.integer_raw(_DER_INT_ZERO),
									asn1.integer_unsigned(key.rsa_n),
									asn1.integer_unsigned(key.rsa_e),
									asn1.integer_unsigned(key.rsa_d),
									asn1.integer_unsigned(key.rsa_p),
									asn1.integer_unsigned(key.rsa_q),
									asn1.integer_unsigned(key.rsa_dp),
									asn1.integer_unsigned(key.rsa_dq),
									asn1.integer_unsigned(key.rsa_iq),
								},
							),
						},
					),
				},
			),
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
