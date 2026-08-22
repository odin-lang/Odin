package hash

rotl32 :: #force_inline proc "contextless" (x: u32, r: u8) -> u32 {
	return (x << r) | (x >> (32 - r))
}

rotl64 :: #force_inline proc "contextless" (x: u64, r: u8) -> u64 {
	return (x << r) | (x >> (64 - r))
}

fmix32 :: #force_inline proc "contextless" (h: u32) -> u32 {
	h := h
	h ~= (h >> 16)
	h *= 0x85ebca6b
	h ~= (h >> 13)
	h *= 0xc2b2ae35
	h ~= (h >> 16)
	return h
}

fmix64 :: #force_inline proc "contextless" (h: u64) -> u64 {
	h := h
	h ~= h >> 33
	h *= 0xff51afd7ed558ccd
	h ~= h >> 33
	h *= 0xc4ceb9fe1a85ec53
	h ~= h >> 33
	return h
}

// See https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp#L94
@(optimization_mode="favor_size")
murmur3_x86_32 :: proc "contextless" (data: []u8, seed: u32 = 0) -> u32 #no_bounds_check {
	len : uint = len(data)
	nblocks : uint = len / 4
	h1 : u32 = seed

	c1 :: 0xcc9e2d51
	c2 :: 0x1b873593

	// BODY
	for i : uint = 0; i < nblocks; i += 1 {
		k1 : u32 = (transmute([]u32)data)[i]

		k1 *= c1
		k1 = rotl32(k1, 15)
		k1 *= c2

		h1 ~= k1
		h1 = rotl32(h1, 13)
		h1 = h1 * 5 + 0xe6546b64
	}

	// TAIL
	k1 : u32 = 0
	switch(len & 3) {
	case 3: k1 ~= u32(data[nblocks*4+2]) << 16; fallthrough
	case 2: k1 ~= u32(data[nblocks*4+1]) <<  8; fallthrough
	case 1:
		k1 ~= u32(data[nblocks*4])
		k1 *= c1
		k1 = rotl32(k1, 15)
		k1 *= c2
		h1 ~= k1
	}

	// END
	h1 ~= u32(len)

	h1 = fmix32(h1)
	return h1
}

// See https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp#L150
@(optimization_mode="favor_size")
murmur3_x86_128 :: proc "contextless" (data: []u8, seed: u32 = 0) -> u128 #no_bounds_check {
	len : uint = len(data)
	nblocks : uint = len / 16

	h1 : u32 = seed
	h2 : u32 = seed
	h3 : u32 = seed
	h4 : u32 = seed

	c1 :: 0x239b961b
	c2 :: 0xab0e9789
	c3 :: 0x38b34ae5
	c4 :: 0xa1e38b93

	// BODY
	for i : uint = 0; i < nblocks; i += 1 {
		k1 : u32 = (transmute([]u32)data)[4*i+0]
		k2 : u32 = (transmute([]u32)data)[4*i+1]
		k3 : u32 = (transmute([]u32)data)[4*i+2]
		k4 : u32 = (transmute([]u32)data)[4*i+3]

		k1 *= c1
		k1 = rotl32(k1, 15)
		k1 *= c2
		h1 ~= k1

		h1 = rotl32(h1, 19)
		h1 += h2
		h1 = h1 * 5 + 0x561ccd1b


		k2 *= c2
		k2 = rotl32(k2, 16)
		k2 *= c3
		h2 ~= k2

		h2 = rotl32(h2, 17)
		h2 += h3
		h2 = h2 * 5 + 0x0bcaa747


		k3 *= c3
		k3 = rotl32(k3, 17)
		k3 *= c4
		h3 ~= k3

		h3 = rotl32(h3, 15)
		h3 += h4
		h3 = h3 * 5 + 0x96cd1c35


		k4 *= c4
		k4 = rotl32(k4, 18)
		k4 *= c1
		h4 ~= k4

		h4 = rotl32(h4, 13)
		h4 += h1
		h4 = h4 * 5 + 0x32ac3b17
	}

	// TAIL
	k1 : u32 = 0
	k2 : u32 = 0
	k3 : u32 = 0
	k4 : u32 = 0
	switch(len & 15) {
	case 15: k4 ~= u32(data[nblocks*16+14]) << 16; fallthrough
	case 14: k4 ~= u32(data[nblocks*16+13]) <<  8; fallthrough
	case 13:
		k4 ~= u32(data[nblocks*16+12])
		k4 *= c4
		k4 = rotl32(k4, 18)
		k4 *= c1
		h4 ~= k4
		fallthrough
	case 12: k3 ~= u32(data[nblocks*16+11]) << 24; fallthrough
	case 11: k3 ~= u32(data[nblocks*16+10]) << 16; fallthrough
	case 10: k3 ~= u32(data[nblocks*16+9])  <<  8; fallthrough
	case 9:
		k3 ~= u32(data[nblocks*16+8])
		k3 *= c3
		k3 = rotl32(k3, 17)
		k3 *= c4
		h3 ~= k3
		fallthrough
	case 8: k2 ~= u32(data[nblocks*16+7]) << 24; fallthrough
	case 7: k2 ~= u32(data[nblocks*16+6]) << 16; fallthrough
	case 6: k2 ~= u32(data[nblocks*16+5]) <<  8; fallthrough
	case 5:
		k2 ~= u32(data[nblocks*16+4])
		k2 *= c2
		k2 = rotl32(k2, 16)
		k2 *= c3
		h2 ~= k2
		fallthrough
	case 4: k1 ~= u32(data[nblocks*16+3]) << 24; fallthrough
	case 3: k1 ~= u32(data[nblocks*16+2]) << 16; fallthrough
	case 2: k1 ~= u32(data[nblocks*16+1]) <<  8; fallthrough
	case 1:
		k1 ~= u32(data[nblocks*16+0])
		k1 *= c1
		k1 = rotl32(k1, 15)
		k1 *= c2
		h1 ~= k1
	}

	// END
	h1 ~= u32(len)
	h2 ~= u32(len)
	h3 ~= u32(len)
	h4 ~= u32(len)

	h1 += h2
	h1 += h3
	h1 += h4
	h2 += h1
	h3 += h1
	h4 += h1

	h1 = fmix32(h1)
	h2 = fmix32(h2)
	h3 = fmix32(h3)
	h4 = fmix32(h4)

	h1 += h2
	h1 += h3
	h1 += h4
	h2 += h1
	h3 += h1
	h4 += h1

	return u128(h1) << 96 | u128(h2) << 64 | u128(h3) << 32 | u128(h4)
}

// See https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp#L255
@(optimization_mode="favor_size")
murmur3_x64_128 :: proc "contextless" (data: []u8, seed: u32 = 0) -> u128 #no_bounds_check {
	len : uint = len(data)
	nblocks : uint = len / 16

	h1 : u64 = u64(seed)
	h2 : u64 = u64(seed)

	c1 :: 0x87c37b91114253d5
	c2 :: 0x4cf5ad432745937f

	// BODY
	for i : uint = 0; i < nblocks; i += 1 {
		k1 : u64 = (transmute([]u64)data)[2*i+0]
		k2 : u64 = (transmute([]u64)data)[2*i+1]

		k1 *= c1
		k1 = rotl64(k1, 31)
		k1 *= c2
		h1 ~= k1

		h1 = rotl64(h1, 27)
		h1 += h2
		h1 = h1 * 5 + 0x52dce729


		k2 *= c2
		k2 = rotl64(k2, 33)
		k2 *= c1
		h2 ~= k2

		h2 = rotl64(h2, 31)
		h2 += h1
		h2 = h2 * 5 + 0x38495ab5
	}

	// TAIL
	k1 : u64 = 0
	k2 : u64 = 0
	switch(len & 15) {
	case 15: k2 ~= u64(data[nblocks*16+14]) << 48; fallthrough
	case 14: k2 ~= u64(data[nblocks*16+13]) << 40; fallthrough
	case 13: k2 ~= u64(data[nblocks*16+12]) << 32; fallthrough
	case 12: k2 ~= u64(data[nblocks*16+11]) << 24; fallthrough
	case 11: k2 ~= u64(data[nblocks*16+10]) << 16; fallthrough
	case 10: k2 ~= u64(data[nblocks*16+9])  <<  8; fallthrough
	case 9:
		k2 ~= u64(data[nblocks*16+8])
		k2 *= c2
		k2 = rotl64(k2, 33)
		k2 *= c1
		h2 ~= k2
		fallthrough
	case 8: k1 ~= u64(data[nblocks*16+7]) << 56; fallthrough
	case 7: k1 ~= u64(data[nblocks*16+6]) << 48; fallthrough
	case 6: k1 ~= u64(data[nblocks*16+5]) << 40; fallthrough
	case 5: k1 ~= u64(data[nblocks*16+4]) << 32; fallthrough
	case 4: k1 ~= u64(data[nblocks*16+3]) << 24; fallthrough
	case 3: k1 ~= u64(data[nblocks*16+2]) << 16; fallthrough
	case 2: k1 ~= u64(data[nblocks*16+1]) <<  8; fallthrough
	case 1:
		k1 ~= u64(data[nblocks*16+0])
		k1 *= c1
		k1 = rotl64(k1, 31)
		k1 *= c2
		h1 ~= k1
	}
	// END
	h1 ~= u64(len)
	h2 ~= u64(len)

	h1 += h2
	h2 += h1

	h1 = fmix64(h1)
	h2 = fmix64(h2)

	h1 += h2
	h2 += h1

	return u128(h1) << 64 | u128(h2)
}
