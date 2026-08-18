package x509

import "core:encoding/asn1"

// Extension encoders. Each returns a complete DER Extension
//   Extension ::= SEQUENCE { extnID OID, critical BOOLEAN DEFAULT FALSE, extnValue OCTET STRING }
// with extnValue carrying the encoded value (the inverse of the matching
// _parse_known_extension branch). The returned slice is allocated;
// a certificate builder splices these into the extensions [3] list via
// asn1.raw. critical=false is omitted per DEFAULT FALSE.

// marshal_ext_basic_constraints encodes id-ce-basicConstraints:
//   BasicConstraints ::= SEQUENCE { cA BOOLEAN DEFAULT FALSE, pathLenConstraint INTEGER OPTIONAL }
// cA is emitted only when `is_ca`; pathLenConstraint only when is_ca and
// `max_path_len` >= 0 (a negative value means "absent").
@(require_results)
marshal_ext_basic_constraints :: proc(is_ca: bool, max_path_len: int, critical: bool, allocator := context.allocator) -> (der: []byte, err: Error) {
	vals: [2]asn1.Value
	path_buf: [8]byte
	n := 0
	if is_ca {
		vals[n] = asn1.boolean(true)
		n += 1
		if max_path_len >= 0 {
			vals[n] = asn1.integer_unsigned(_uint_be(max_path_len, path_buf[:]))
			n += 1
		}
	}
	return _marshal_extension(_OID_EXT_BASIC_CONSTRAINTS, critical, asn1.sequence(vals[:n]), allocator)
}

// marshal_ext_key_usage encodes id-ce-keyUsage as a KeyUsage BIT STRING,
// minimally (trailing zero bits dropped, per DER named bit strings).
@(require_results)
marshal_ext_key_usage :: proc(usage: Key_Usage, critical: bool, allocator := context.allocator) -> (der: []byte, err: Error) {
	hi := -1
	for bit in Key_Usage_Bit {
		if bit in usage {
			hi = int(bit) // bits enumerate ascending, so the last present is the highest
		}
	}
	buf: [3]byte // unused-bits octet + up to 2 payload octets (9 named bits)
	content: []byte
	if hi < 0 {
		content = buf[:1] // no bits set: empty bit string, 0 unused
	} else {
		nbytes := hi / 8 + 1
		buf[0] = byte(nbytes * 8 - (hi + 1)) // unused-bits count
		for bit in Key_Usage_Bit {
			i := int(bit)
			if i <= hi && bit in usage {
				buf[1 + i / 8] |= 0x80 >> uint(i % 8)
			}
		}
		content = buf[:1 + nbytes]
	}
	return _marshal_extension(_OID_EXT_KEY_USAGE, critical, asn1.primitive(asn1.universal(.Bit_String), content), allocator)
}

// marshal_ext_ext_key_usage encodes id-ce-extKeyUsage:
//   ExtKeyUsageSyntax ::= SEQUENCE SIZE (1..MAX) OF KeyPurposeId
// in EKU_Bit order.
@(require_results)
marshal_ext_ext_key_usage :: proc(eku: Ext_Key_Usage, critical: bool, allocator := context.allocator) -> (der: []byte, err: Error) {
	purposes: [7]asn1.Value
	n := 0
	for bit in EKU_Bit {
		if bit in eku {
			purposes[n] = asn1.object_identifier(_eku_oid(bit))
			n += 1
		}
	}
	return _marshal_extension(_OID_EXT_EXT_KEY_USAGE, critical, asn1.sequence(purposes[:n]), allocator)
}

// marshal_ext_san encodes id-ce-subjectAltName:
//   GeneralNames ::= SEQUENCE OF GeneralName
// emitting dNSName [2] IA5String entries (in order) followed by iPAddress [7]
// OCTET STRING entries. IP values are the raw 4- or 16-octet address.
@(require_results)
marshal_ext_san :: proc(dns_names: []string, ip_addresses: [][]byte, critical: bool, allocator := context.allocator) -> (der: []byte, err: Error) {
	n := len(dns_names) + len(ip_addresses)
	names, merr := make([]asn1.Value, n, allocator) // dynamic count: scaffolding, freed below
	if merr != nil {
		return nil, .Allocation_Failed
	}
	defer delete(names, allocator)

	i := 0
	for d in dns_names {
		names[i] = asn1.context_primitive(2, transmute([]byte)d) // [2] IMPLICIT IA5String
		i += 1
	}
	for ip in ip_addresses {
		names[i] = asn1.context_primitive(7, ip) // [7] IMPLICIT OCTET STRING
		i += 1
	}
	return _marshal_extension(_OID_EXT_SAN, critical, asn1.sequence(names[:]), allocator)
}

// _marshal_extension wraps an extension value tree as a complete Extension.
// `value`'s borrowed backing lives in the caller's frame, which is active for
// the duration of this synchronous call, so the encode below sees it intact.
@(private, require_results)
_marshal_extension :: proc(oid: []byte, critical: bool, value: asn1.Value, allocator := context.allocator) -> (der: []byte, err: Error) {
	out: []byte
	merr: asn1.Error
	if critical {
		out, merr = asn1.marshal(
			asn1.sequence({asn1.object_identifier(oid), asn1.boolean(true), asn1.octet_string_wrap({value})}),
			allocator,
		)
	} else {
		out, merr = asn1.marshal(asn1.sequence({asn1.object_identifier(oid), asn1.octet_string_wrap({value})}), allocator)
	}
	if merr != .None {
		return nil, .Allocation_Failed
	}
	return out, .None
}

// _uint_be writes the minimal big-endian magnitude of a non-negative int into
// buf and returns the slice (empty for zero, which integer_unsigned encodes as 0).
@(private)
_uint_be :: proc(v: int, buf: []byte) -> []byte {
	if v <= 0 {
		return buf[:0]
	}
	n := 0
	x := v
	for x > 0 {
		n += 1
		x >>= 8
	}
	for i in 0 ..< n {
		buf[n - 1 - i] = byte(v >> uint(8 * i))
	}
	return buf[:n]
}

@(private)
_eku_oid :: proc(bit: EKU_Bit) -> []byte {
	switch bit {
	case .Server_Auth:
		return _OID_EKU_SERVER_AUTH
	case .Client_Auth:
		return _OID_EKU_CLIENT_AUTH
	case .Code_Signing:
		return _OID_EKU_CODE_SIGNING
	case .Email_Protection:
		return _OID_EKU_EMAIL_PROTECTION
	case .Time_Stamping:
		return _OID_EKU_TIME_STAMPING
	case .OCSP_Signing:
		return _OID_EKU_OCSP_SIGNING
	case .Any:
		return _OID_EKU_ANY
	}
	return nil
}
