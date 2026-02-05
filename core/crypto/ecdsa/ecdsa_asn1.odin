package ecdsa

import secec "core:crypto/_weierstrass"

// ASN.1 format ECDSA signatures are`SEQUENCE { r INTEGER, s INTEGER }`
// this implements enough to generate/parse signatures.  Eventually when
// we have a full ASN.1 DER library, these routines will be removed.

@(private="file")
TAG_SEQUENCE :: 0x30
@(private="file")
TAG_INTEGER :: 0x02

@(private,require_results)
generate_asn1_sig :: proc(r, s: ^$T, allocator := context.allocator) -> []byte {
	when T == secec.Scalar_p256r1 {
		SC_SZ :: secec.SC_SIZE_P256R1
	} else when T == secec.Scalar_p384r1 {
		SC_SZ :: secec.SC_SIZE_P384R1
	} else {
		#panic("crypto/ecdsa: invalid curve")
	}

	INT_TLP :: 3 // tag, tength, (optional) leading zero-byte
	encode_uint :: proc(b: []byte) -> []byte {
		b := b

		// DER requires minimal encoding.
		off := INT_TLP
		for v in b[off:] {
			if v != 0 {
				break
			}
			off += 1
		}
		// If the sign big is set, add a leading zero.
		if b[off] & 0x80 == 0x80 {
			off -= 1
			b[off] = 0
		}

		// Encode the length (up to 127 octets, adequate for ECDSA).
		l := len(b[off:])
		off -= 1
		b[off] = byte(l)

		// Encode the tag
		off -= 1
		b[off] = TAG_INTEGER

		return b[off:]
	}

	r_buf, s_buf: [INT_TLP+SC_SZ]byte = ---, ---
	secec.sc_bytes(r_buf[INT_TLP:], r)
	secec.sc_bytes(s_buf[INT_TLP:], s)

	r_bytes, s_bytes := encode_uint(r_buf[:]), encode_uint(s_buf[:])
	seq_len := len(r_bytes) + len(s_bytes)

	// WARNING: If secp521r1 support is added, this needs to support
	// long-form length encoding.
	ensure(seq_len <= 127, "BUG: crypto/ecdsa: signature length too large")
	b := make([]byte, seq_len + 2, allocator)
	b[0] = TAG_SEQUENCE
	b[1] = byte(seq_len)
	copy(b[2:], r_bytes)
	copy(b[2+len(r_bytes):], s_bytes)

	return b
}

@(private,require_results)
parse_asn1_sig :: proc(sig: []byte) -> (r, s: []byte, ok: bool) {
	read_seq :: proc(b: []byte) -> (v: []byte, rest: []byte, ok: bool) {
		b_len := len(b)
		if b_len < 3 {
			return nil, nil, false
		}
		if b[0] != TAG_SEQUENCE {
			return nil, nil, false
		}
		seq_len, off: int
		if b[1] & 0x80 == 0x80 {
			if b[1] != 0x81 || b_len < 4 { // 2-length octets is sufficient for ecdsa.
				return nil, nil, false
			}
			if b[2] & 0x80 == 0x80 || b[3] & 0x80 == 80 {
				return nil, nil, false
			}
			seq_len = int(b[2]) * 127 + int(b[3])
			off = 4
		} else {
			seq_len = int(b[1])
			off = 2
		}
		if b_len - off < seq_len {
			return nil, nil, false
		}
		return b[off:off+seq_len], b[off+seq_len:], true
	}

	read_int :: proc(b: []byte) -> (v: []byte, rest: []byte, ok: bool) {
		b_len := len(b)
		if b_len < 3 {
			return nil, nil, false
		}
		if b[0] != TAG_INTEGER {
			return nil, nil, false
		}
		v_len := int(b[1])
		if v_len > 0x80 || b_len - 2 < v_len { // 127-bytes max.
			return nil, nil, false
		}

		return b[2:2+v_len], b[2+v_len:], true
	}

	// SEQUENCE
	seq_bytes, rest: []byte
	seq_bytes, rest, ok = read_seq(sig)
	if !ok {
		return nil, nil, false
	}
	if len(rest) != 0 {
		return nil, nil, false
	}

	// INTEGER (r)
	r, rest, ok = read_int(seq_bytes)
	if !ok {
		return nil, nil, false
	}

	// INTEGER (s)
	s, rest, ok = read_int(rest)
	if !ok {
		return nil, nil, false
	}
	if len(rest) != 0 {
		return nil, nil, false
	}

	// DER requires a leading 0 iff the sign bit of the leading byte
	// is set to distinguish between positive and negative integers,
	// and the minimal length representation.  `r` and `s` are always
	// going to be unsigned, so we validate malformed DER and strip
	// the leading 0 as needed.
	fixup_der_uint :: proc(b: []byte) -> ([]byte, bool) {
		switch len(b) {
		case 0:
			// 0 length is invalid
			return nil, false
		case 1:
			// Missing leading zero
			if b[0] & 0x80 == 0x80 {
				return nil, false
			}
		case:
			if b[0] == 0 {
				// Sign bit not set
				if b[1] & 0x80 != 0x80 {
					return nil, false
				}
				return b[1:], true
			} else if b[0] & 0x80 == 0x80 {
				// Missing leading zero
				return nil, false
			}
		}

		return b, true
	}

	if r, ok = fixup_der_uint(r); !ok {
		return nil, nil, false
	}
	if s, ok = fixup_der_uint(s); !ok {
		return nil, nil, false
	}

	return r, s, true
}
