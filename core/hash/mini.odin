package hash

ginger_hash8 :: proc "contextless" (x: u8) -> u8 {
	h := x * 251
	h += ~(x << 3)
	h ~= (x >> 1)
	h += ~(x << 7)
	h ~= (x >> 6)
	h += (x << 2)
	return h
}


ginger_hash16 :: proc "contextless" (x: u16) -> u16 {
	z := (x << 8) | (x >> 8)
	h := z
	h += ~(z << 5)
	h ~= (z >> 2)
	h += ~(z << 13)
	h ~= (z >> 10)
	h += ~(z << 4)
	h = (h << 10) | (h >> 10)
	return h
}


ginger8 :: proc "contextless" (data: []byte) -> u8 {
	h := ginger_hash8(0)
	for b in data {
		h ~= ginger_hash8(b)
	}
	return h
}

ginger16 :: proc "contextless" (data: []byte) -> u16 {
	h := ginger_hash16(0)
	for b in data {
		h ~= ginger_hash16(u16(b))
	}
	return h
}


@(private)
sxm_hash_uint_generic :: #force_inline proc "contextless" (x: $T) -> T {
	bits :: size_of(x) << 3
	shift :: bits >> 1
	mul :: 0x4ff55ba64bb740e135db2be3690a61d3 % (1 << bits)
	o := T(x)
	o = (o ~ o >> shift) * mul
	o = (o ~ o >> shift) * mul
	o = (o ~ o >> shift) * mul
	o = (o ~ o >> shift) * mul
	return o
}

sxm_hash8 :: proc "contextless" (x: u8) -> u8 {
	return sxm_hash_uint_generic(x)
}

sxm_hash16 :: proc "contextless" (x: u16) -> u16 {
	return sxm_hash_uint_generic(x)
}

sxm_hash32 :: proc "contextless" (x: u32) -> u32 {
	return sxm_hash_uint_generic(x)
}

sxm_hash64 :: proc "contextless" (x: u64) -> u64 {
	return sxm_hash_uint_generic(x)
}

sxm_hash128 :: proc "contextless" (x: u128) -> u128 {
	return sxm_hash_uint_generic(x)
}

sxm_hash_uint :: proc {
	sxm_hash8,
	sxm_hash16,
	sxm_hash32,
	sxm_hash64,
	sxm_hash128,
}

sxm_hash_slice_u8 :: proc "contextless" (data: []byte) -> u64 {
	h := sxm_hash_uint(u64(1))
	for b in data {
		h ~= sxm_hash_uint(u64(b) ~ h)
	}
	return h
}

sxm_hash_string :: proc "contextless" (data: string) -> u64 {
	return sxm_hash_slice_u8(transmute([]u8)data)
}
