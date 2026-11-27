#+build wasm32, wasm64p32
#+build !bedrock
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
__ashlti3 :: proc "contextless" (a: i128, b: u32) -> i128 {
	bits :: 64
	
	input: ti_int = ---
	result: ti_int = ---
	input.all = a
	if b & bits != 0 {
		result.lo = 0
		result.hi = input.lo << (b-bits)
	} else {
		if b == 0 {
			return a
		}
		result.lo = input.lo<<b
		result.hi = (input.hi<<b) | (input.lo>>(bits-b))
	}
	return result.all
}

__ashlti3_unsigned :: proc "contextless" (a: u128, b: u32) -> u128 {
	return cast(u128)__ashlti3(cast(i128)a, b)
}

@(link_name="__mulddi3", linkage="strong")
__mulddi3 :: proc "contextless" (a, b: u64) -> i128 {
	r: ti_int
	bits :: 32

	mask :: ~u64(0) >> bits
	r.lo = (a & mask) * (b & mask)
	t := r.lo >> bits
	r.lo &= mask
	t += (a >> bits) * (b & mask)
	r.lo += (t & mask) << bits
	r.hi = t >> bits
	t = r.lo >> bits
	r.lo &= mask
	t += (b >> bits) * (a & mask)
	r.lo += (t & mask) << bits
	r.hi += t >> bits
	r.hi += (a >> bits) * (b >> bits)
	return r.all
}

@(link_name="__multi3", linkage="strong")
__multi3 :: proc "contextless" (a, b: i128) -> i128 {
	x, y, r: ti_int

	x.all = a
	y.all = b
	r.all = __mulddi3(x.lo, y.lo)
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
__lshrti3 :: proc "c" (a: i128, b: u32) -> i128 {
	bits :: 64

	input, result: ti_int
	input.all = a
	if b & bits != 0 {
		result.hi = 0
		result.lo = input.hi >> (b - bits)
	} else if b == 0 {
		return a
	} else {
		result.hi = input.hi >> b
		result.lo = (input.hi << (bits - b)) | (input.lo >> b)
	}

	return result.all
}

@(link_name="__ashrti3", linkage="strong")
__ashrti3 :: proc "c" (a: i128, b: u32) -> i128 {
	bits :: 64

	input, result: ti_int
	input.all = a
	hi := i64(input.hi)
	if b & bits != 0 {
		result.hi = u64(hi >> (bits - 1))
		result.lo = u64(hi >> (b - bits))
	} else if b == 0 {
		return a
	} else {
		result.hi = u64(hi >> b)
		result.lo = (input.hi << (bits - b)) | (input.lo >> b)
	}

	return result.all
}

@(link_name="__muloti4", linkage="strong")
__muloti4 :: proc "c" (a, b: i128, overflow: ^i32) -> i128 {
	sa, sb := a >> 127, b >> 127
	ua, ub := u128((a ~ sa) - sa), u128((b ~ sb) - sb)
	product := ua * ub
	limit   := u128(max(i128)) + u128(sa != sb)
	overflow^ = i32(ua != 0 && (product / ua != ub || product > limit))
	return i128(u128(a) * u128(b))
}
