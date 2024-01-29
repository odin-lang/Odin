//+build wasm32, wasm64p32
package runtime

@(private="file")
ti_int :: struct #raw_union {
	using s: struct { lo, hi: u64 },
	all: i128,
}

@(link_name="__ashlti3", linkage="strong")
__ashlti3 :: proc "contextless" (a: i128, b_: u32) -> i128 {
	bits_in_dword :: size_of(u32)*8
	b := u32(b_)
	
	input, result: ti_int
	input.all = a
	if b & bits_in_dword != 0 {
		result.lo = 0
		result.hi = input.lo << (b-bits_in_dword)
	} else {
		if b == 0 {
			return a
		}
		result.lo = input.lo<<b
		result.hi = (input.hi<<b) | (input.lo>>(bits_in_dword-b))
	}
	return result.all
}


@(link_name="__multi3", linkage="strong")
__multi3 :: proc "contextless" (a, b: i128) -> i128 {
	x, y, r: ti_int
	
	x.all = a
	y.all = b
	r.all = i128(x.lo * y.lo) // TODO this is incorrect
	r.hi += x.hi*y.lo + x.lo*y.hi
	return r.all
}