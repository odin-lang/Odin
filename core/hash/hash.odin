package hash

import "core:mem"
import "base:intrinsics"

@(optimization_mode="favor_size")
adler32 :: proc "contextless" (data: []byte, seed := u32(1)) -> u32 #no_bounds_check {

	ADLER_CONST :: 65521

	buffer := raw_data(data)
	a, b: u64 = u64(seed) & 0xFFFF, u64(seed) >> 16
	buf := data[:]

	for len(buf) != 0 && uintptr(buffer) & 7 != 0 {
		a = (a + u64(buf[0]))
		b = (b + a)
		buffer = buffer[1:]
		buf = buf[1:]
	}

	for len(buf) > 7 {
		count := min(len(buf), 5552)
		for count > 7 {
			a += u64(buf[0]); b += a
			a += u64(buf[1]); b += a
			a += u64(buf[2]); b += a
			a += u64(buf[3]); b += a
			a += u64(buf[4]); b += a
			a += u64(buf[5]); b += a
			a += u64(buf[6]); b += a
			a += u64(buf[7]); b += a

			buf = buf[8:]
			count -= 8
		}
		a %= ADLER_CONST
		b %= ADLER_CONST
	}

	for len(buf) != 0 {
		a = (a + u64(buf[0])) % ADLER_CONST
		b = (b + a) % ADLER_CONST
		buf = buf[1:]
	}
	return (u32(b) << 16) | u32(a)
}

@(optimization_mode="favor_size")
djb2 :: proc "contextless" (data: []byte, seed := u32(5381)) -> u32 {
	hash: u32 = seed
	for b in data {
		hash = (hash << 5) + hash + u32(b) // hash * 33 + u32(b)
	}
	return hash
}

djbx33a :: proc "contextless" (data: []byte, seed := u32(5381)) -> (result: [16]byte) #no_bounds_check {
	state := [4]u32{seed, seed, seed, seed}
	
	s: u32 = 0
	for p in data {
		state[s] = (state[s] << 5) + state[s] + u32(p) // hash * 33 + u32(b)
		s = (s + 1) & 3
	}
	
	
	(^u32le)(&result[0])^  = u32le(state[0])
	(^u32le)(&result[4])^  = u32le(state[1])
	(^u32le)(&result[8])^  = u32le(state[2])
	(^u32le)(&result[12])^ = u32le(state[3])
	return
}

// If you have a choice, prefer fnv32a
@(optimization_mode="favor_size")
fnv32_no_a :: proc "contextless" (data: []byte, seed := u32(0x811c9dc5)) -> u32 {
	h: u32 = seed
	for b in data {
		h = (h * 0x01000193) ~ u32(b)
	}
	return h
}

fnv32 :: fnv32_no_a // NOTE(bill): Not a fan of these aliases but seems necessary
fnv64 :: fnv64_no_a // NOTE(bill): Not a fan of these aliases but seems necessary

// If you have a choice, prefer fnv64a
@(optimization_mode="favor_size")
fnv64_no_a :: proc "contextless" (data: []byte, seed := u64(0xcbf29ce484222325)) -> u64 {
	h: u64 = seed
	for b in data {
		h = (h * 0x100000001b3) ~ u64(b)
	}
	return h
}
@(optimization_mode="favor_size")
fnv32a :: proc "contextless" (data: []byte, seed := u32(0x811c9dc5)) -> u32 {
	h: u32 = seed
	for b in data {
		h = (h ~ u32(b)) * 0x01000193
	}
	return h
}

@(optimization_mode="favor_size")
fnv64a :: proc "contextless" (data: []byte, seed := u64(0xcbf29ce484222325)) -> u64 {
	h: u64 = seed
	for b in data {
		h = (h ~ u64(b)) * 0x100000001b3
	}
	return h
}

@(optimization_mode="favor_size")
jenkins :: proc "contextless" (data: []byte, seed := u32(0)) -> u32 {
	hash: u32 = seed
	for b in data {
		hash += u32(b)
		hash += hash << 10
		hash ~= hash >> 6
	}
	hash += hash << 3
	hash ~= hash >> 11
	hash += hash << 15
	return hash
}

@(optimization_mode="favor_size")
murmur32 :: proc "contextless" (data: []byte, seed := u32(0)) -> u32 {
	c1_32: u32 : 0xcc9e2d51
	c2_32: u32 : 0x1b873593

	h1: u32 = seed
	nblocks := len(data)/4
	p := raw_data(data)
	p1 := p[4*nblocks:]

	for ; p < p1; p = p[4:] {
		k1 := (cast(^u32)p)^

		k1 *= c1_32
		k1 = (k1 << 15) | (k1 >> 17)
		k1 *= c2_32

		h1 ~= k1
		h1 = (h1 << 13) | (h1 >> 19)
		h1 = h1*5 + 0xe6546b64
	}

	tail := data[nblocks*4:]
	k1: u32
	switch len(tail)&3 {
	case 3:
		k1 ~= u32(tail[2]) << 16
		fallthrough
	case 2:
		k1 ~= u32(tail[1]) << 8
		fallthrough
	case 1:
		k1 ~= u32(tail[0])
		k1 *= c1_32
		k1 = (k1 << 15) | (k1 >> 17) 
		k1 *= c2_32
		h1 ~= k1
	}

	h1 ~= u32(len(data))

	h1 ~= h1 >> 16
	h1 *= 0x85ebca6b
	h1 ~= h1 >> 13
	h1 *= 0xc2b2ae35
	h1 ~= h1 >> 16

	return h1
}

// See https://github.com/aappleby/smhasher/blob/master/src/MurmurHash2.cpp#L96
@(optimization_mode="favor_size")
murmur64a :: proc "contextless" (data: []byte, seed := u64(0x9747b28c)) -> u64 {
	m :: 0xc6a4a7935bd1e995
	r :: 47

	h: u64 = seed ~ (u64(len(data)) * m)
	data64 := mem.slice_data_cast([]u64, data)

	for _, i in data64 {
		k := data64[i]

		k *= m
		k ~= k>>r
		k *= m

		h ~= k
		h *= m
	}

	offset := len(data64) * size_of(u64)

	switch len(data)&7 {
	case 7: h ~= u64(data[offset + 6]) << 48; fallthrough
	case 6: h ~= u64(data[offset + 5]) << 40; fallthrough
	case 5: h ~= u64(data[offset + 4]) << 32; fallthrough
	case 4: h ~= u64(data[offset + 3]) << 24; fallthrough
	case 3: h ~= u64(data[offset + 2]) << 16; fallthrough
	case 2: h ~= u64(data[offset + 1]) << 8;  fallthrough
	case 1:
		h ~= u64(data[offset + 0])
		h *= m
	}

	h ~= h>>r
	h *= m
	h ~= h>>r

	return h
}

// See https://github.com/aappleby/smhasher/blob/master/src/MurmurHash2.cpp#L140
@(optimization_mode="favor_size")
murmur64b :: proc "contextless" (data: []byte, seed := u64(0x9747b28c)) -> u64 {
	m :: 0x5bd1e995
	r :: 24

	h1 := u32(seed) ~ u32(len(data))
	h2 := u32(seed) >> 32

	data32 := mem.slice_ptr(cast(^u32)raw_data(data), len(data)/size_of(u32))
	len := len(data)
	i := 0

	for len >= 8 {
		k1, k2: u32
		k1 = data32[i]; i += 1
		k1 *= m
		k1 ~= k1>>r
		k1 *= m
		h1 *= m
		h1 ~= k1
		len -= 4

		k2 = data32[i]; i += 1
		k2 *= m
		k2 ~= k2>>r
		k2 *= m
		h2 *= m
		h2 ~= k2
		len -= 4
	}

	if len >= 4 {
		k1: u32
		k1 = data32[i]; i += 1
		k1 *= m
		k1 ~= k1>>r
		k1 *= m
		h1 *= m
		h1 ~= k1
		len -= 4
	}

	// TODO(bill): Fix this
	#no_bounds_check data8 := mem.slice_to_bytes(data32[i:])[:3]
	switch len {
	case 3:
		h2 ~= u32(data8[2]) << 16
		fallthrough
	case 2:
		h2 ~= u32(data8[1]) << 8
		fallthrough
	case 1:
		h2 ~= u32(data8[0])
		h2 *= m
	}

	h1 ~= h2>>18
	h1 *= m
	h2 ~= h1>>22
	h2 *= m
	h1 ~= h2>>17
	h1 *= m
	h2 ~= h1>>19
	h2 *= m

	return u64(h1)<<32 | u64(h2)
}

@(optimization_mode="favor_size")
sdbm :: proc "contextless" (data: []byte, seed := u32(0)) -> u32 {
	hash: u32 = seed
	for b in data {
		hash = u32(b) + (hash<<6) + (hash<<16) - hash
	}
	return hash
}
