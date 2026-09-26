package ecdsa

import "core:encoding/asn1"
import secec "core:crypto/_weierstrass"

// ASN.1 ECDSA signatures are `SEQUENCE { r INTEGER, s INTEGER }`. These thin
// wrappers over core:encoding/asn1 generate/parse that structure the DER
// minimal-encoding rules.

@(private, require_results)
generate_asn1_sig :: proc(r, s: ^$T, allocator := context.allocator) -> []byte {
	when T == secec.Scalar_p256r1 {
		SC_SZ :: secec.SC_SIZE_P256R1
	} else when T == secec.Scalar_p384r1 {
		SC_SZ :: secec.SC_SIZE_P384R1
	} else {
		#panic("crypto/ecdsa: invalid curve")
	}

	r_buf, s_buf: [SC_SZ]byte = ---, ---
	secec.sc_bytes(r_buf[:], r)
	secec.sc_bytes(s_buf[:], s)

	sig, err := asn1.marshal(
		asn1.sequence({asn1.integer_unsigned(r_buf[:]), asn1.integer_unsigned(s_buf[:])}),
		allocator,
	)
	if err != .None {
		return nil
	}
	return sig
}

@(private, require_results)
parse_asn1_sig :: proc(sig: []byte) -> (r, s: []byte, ok: bool) {
	cur: asn1.Cursor
	asn1.cursor_init(&cur, sig)
	seq, e0 := asn1.read_sequence(&cur)
	if e0 != .None || asn1.done(&cur) != .None {
		return nil, nil, false
	}

	// r and s are unsigned; read_unsigned_integer_bytes validates the INTEGER
	// and strips the DER sign octet, returning the magnitude as a view of sig.
	rb, e1 := asn1.read_unsigned_integer_bytes(&seq)
	sb, e2 := asn1.read_unsigned_integer_bytes(&seq)
	if e1 != .None || e2 != .None || asn1.done(&seq) != .None {
		return nil, nil, false
	}
	return rb, sb, true
}
