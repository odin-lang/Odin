package ecdsa

// ASN.1 format ECDSA signatures are`SEQUENCE { r INTEGER, s INTEGER }`
// this implements enough to generate/parse signatures.  Eventually when
// we have a full ASN.1 DER library, these routines will be removed.

@(private="file")
TAG_SEQUENCE :: 0x30
@(private="file")
TAG_INTEGER :: 0x02

@(private,require_results)
parse_asn1_sig :: proc(sig: []byte) -> (r, s: []byte, ok: bool) {
	b := sig
	if len(b) < 8 {
		return nil, nil, false
	}

	// SEQUENCE, 1-byte of length
	if b[0] != TAG_SEQUENCE {
		return nil, nil, false
	}
	b = b[1:]
	if seq_len := len(b); int(b[0]) != seq_len + 1 {
		return nil, nil, false
	}
	b = b[1:]

	// INTEGER (r)
	if b[0] != TAG_INTEGER {
		return nil, nil, false
	}
	b = b[1:]
	r_len := int(b[0])
	if r_len >= 0x80 || len(b) < r_len + 1 {
		return nil, nil, false
	}
	r = b[1:r_len]
	b = b[1+r_len:]

	// INTEGER (s)
	if len(b) < 2 {
		return nil, nil, false
	}
	if b[0] != TAG_INTEGER {
		return nil, nil, false
	}
	b = b[1:]
	s_len := int(b[0])
	if s_len >= 0x80 || len(b) != s_len + 1 {
		return nil, nil, false
	}
	s = b[1:]

	// DER requires a leading 0 iff the sign bit of the leading byte
	// is set to distinguish between positive and negative integers,
	// and the minimal length representation.
	if r, ok = strip_leading_zero(r); !ok {
		return nil, nil, false
	}
	if s, ok = strip_leading_zero(s); !ok {
		return nil, nil, false
	}

	return r, s, true
}

@(private="file",require_results)
strip_leading_zero :: proc(b: []byte) -> ([]byte, bool) {
	switch len(b) {
	case 0:
	case 1:
		// Missing leading zero
		if b[0] & 128 == 128 {
			return nil, false
		}
	case:
		if b[0] == 0 {
			// Sign bit not set
			if b[1] & 128 != 128 {
				return nil, false
			}
		}
		return b[1:], true
	}

	return b, true
}
