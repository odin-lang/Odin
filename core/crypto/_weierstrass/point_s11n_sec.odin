package _weierstrass

@(require) import "core:mem"

@(private)
SEC_PREFIX_IDENTITY        :: 0x00
@(private)
SEC_PREFIX_COMPRESSED_EVEN :: 0x02
@(private)
SEC_PREFIX_COMPRESSED_ODD  :: 0x03
SEC_PREFIX_UNCOMPRESSED    :: 0x04

@(require_results)
pt_set_sec_bytes :: proc "contextless" (p: ^$T, b: []byte) -> bool {
	when T == Point_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	b_len := len(b)
	if b_len < 1 {
		return false
	}

	switch b[0] {
	case SEC_PREFIX_IDENTITY:
		if b_len != 1 {
			return false
		}
		pt_identity(p)
		return true
	case SEC_PREFIX_COMPRESSED_EVEN, SEC_PREFIX_COMPRESSED_ODD:
		if b_len != 1 + FE_SZ {
			return false
		}
		y_is_odd := b[0] - SEC_PREFIX_COMPRESSED_EVEN
		return pt_set_x_bytes(p, b[1:], int(y_is_odd))
	case SEC_PREFIX_UNCOMPRESSED:
		if b_len != 1 + 2 * FE_SZ {
			return false
		}
		x, y := b[1:1+FE_SZ], b[1+FE_SZ:]
		return pt_set_xy_bytes(p, x, y)
	case:
		return false
	}
}

@(require_results)
pt_sec_bytes :: proc "contextless" (b: []byte, p: ^$T, compressed: bool) -> bool {
	when T == Point_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	b_len := len(b)
	if pt_is_identity(p) == 1 {
		if b_len != 1 {
			return false
		}
		b[0] = SEC_PREFIX_IDENTITY
		return true
	}

	x, y: []byte
	y_: [FE_SZ]byte
	switch compressed {
	case true:
		if b_len != 1 + FE_SZ {
			return false
		}
		x, y = b[1:], y_[:]
	case false:
		if b_len != 1 + 2 * FE_SZ {
			return false
		}
		b[0]= SEC_PREFIX_UNCOMPRESSED
		x, y = b[1:1+FE_SZ], b[1+FE_SZ:]
	}
	if !pt_bytes(x, y, p) {
		return false
	}
	if compressed {
		// Instead of calling pt_is_y_odd, just serializing
		// y into a temp buffer and checking the parity saves
		// 1 redundant rescale call.
		y_is_odd := byte(y[FE_SZ-1] & 1)
		b[0] = SEC_PREFIX_COMPRESSED_EVEN + y_is_odd
		mem.zero_explicit(&y_, size_of(y_))
	}

	return true
}
