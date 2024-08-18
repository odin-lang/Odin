//+build wasm32, wasm64p32
package runtime

@(private="file")
ti_int :: struct #raw_union {
	using s: struct { lo, hi: u64 },
	all: i128,
}

@(private="file")
ti_uint :: struct #raw_union {
	using s: struct { lo, hi: u64 },
	all: u128,
}

@(link_name="__ashlti3", linkage="strong")
__ashlti3 :: proc "contextless" (la, ha: u64, b_: u32) -> i128 {
	bits_in_dword :: size_of(u32)*8
	b := u32(b_)
	
	input, result: ti_int
	input.lo, input.hi = la, ha
	if b & bits_in_dword != 0 {
		result.lo = 0
		result.hi = input.lo << (b-bits_in_dword)
	} else {
		if b == 0 {
			return input.all
		}
		result.lo = input.lo<<b
		result.hi = (input.hi<<b) | (input.lo>>(bits_in_dword-b))
	}
	return result.all
}


@(link_name="__multi3", linkage="strong")
__multi3 :: proc "contextless" (la, ha, lb, hb: u64) -> i128 {
	x, y, r: ti_int

	x.lo, x.hi = la, ha
	y.lo, y.hi = lb, hb
	r.all = i128(x.lo * y.lo) // TODO this is incorrect
	r.hi += x.hi*y.lo + x.lo*y.hi
	return r.all
}

@(link_name="__udivti3", linkage="strong")
udivti3 :: proc "c" (la, ha, lb, hb: u64) -> u128 {
	a, b: ti_uint
	a.lo, a.hi = la, ha
	b.lo, b.hi = lb, hb
	return udivmodti4(a.all, b.all, nil)
}

@(link_name="__lshrti3", linkage="strong")
__lshrti3 :: proc "c" (la, ha: u64, b: u32) -> i128 {
	bits :: size_of(u32)*8

	input, result: ti_int
	input.lo = la
	input.hi = ha

	if b & bits != 0 {
		result.hi = 0
		result.lo = input.hi >> (b - bits)
	} else if b == 0 {
		return input.all
	} else {
		result.hi = input.hi >> b
		result.lo = (input.hi << (bits - b)) | (input.lo >> b)
	}

	return result.all
}
