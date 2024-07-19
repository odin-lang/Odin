/*
	An implementation of Yann Collet's [xxhash Fast Hash Algorithm](https://cyan4973.github.io/xxHash/).
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.

	Made available under Odin's BSD-3 license, based on the original C code.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
package xxhash

import "base:intrinsics"
import "base:runtime"

mem_copy  :: runtime.mem_copy
byte_swap :: intrinsics.byte_swap

/*
	Version definition
*/
XXH_VERSION_MAJOR   :: 0
XXH_VERSION_MINOR   :: 8
XXH_VERSION_RELEASE :: 1
XXH_VERSION_NUMBER  :: XXH_VERSION_MAJOR * 100 * 100 + XXH_VERSION_MINOR * 100 + XXH_VERSION_RELEASE

/*
	0 - Use memcopy, for platforms where unaligned reads are a problem
	2 - Direct cast, for platforms where unaligned are allowed (default)
*/
XXH_FORCE_MEMORY_ACCESS :: #config(XXH_FORCE_MEMORY_ACCESS, 2)

/*
	`false` - Use this on platforms where unaligned reads are fast
	`true`  - Use this on platforms where unaligned reads are slow
*/
XXH_FORCE_ALIGN_CHECK :: #config(XXH_FORCE_ALIGN_CHECK, false)

Alignment :: enum {
	Aligned,
	Unaligned,
}

Error :: enum {
	None = 0,
	Error,
}

XXH_DISABLE_PREFETCH :: #config(XXH_DISABLE_PREFETCH, true)

/*
	llvm.prefetch fails code generation on Linux.
*/
when !XXH_DISABLE_PREFETCH {
	prefetch_address :: #force_inline proc(address: rawptr) {
		intrinsics.prefetch_read_data(address, /*high*/3)
	}
	prefetch_offset  :: #force_inline proc(address: rawptr, #any_int offset: uintptr) {
		ptr := rawptr(uintptr(address) + offset)
		prefetch_address(ptr)
	}
	prefetch :: proc { prefetch_address, prefetch_offset, }
} else {
	prefetch_address :: #force_inline proc(address: rawptr) {
	}
	prefetch_offset  :: #force_inline proc(address: rawptr, #any_int offset: uintptr) {
	}
}


@(optimization_mode="favor_size")
XXH_rotl32 :: #force_inline proc(x, r: u32) -> (res: u32) {
	return ((x << r) | (x >> (32 - r)))
}

@(optimization_mode="favor_size")
XXH_rotl64 :: #force_inline proc(x, r: u64) -> (res: u64) {
	return ((x << r) | (x >> (64 - r)))
}

@(optimization_mode="favor_size")
XXH32_read32 :: #force_inline proc(buf: []u8, alignment := Alignment.Unaligned) -> (res: u32) {
	if XXH_FORCE_MEMORY_ACCESS == 2 || alignment == .Aligned {
		#no_bounds_check b := (^u32le)(&buf[0])^
		return u32(b)
	} else {
		b: u32le
		mem_copy(&b, raw_data(buf[:]), 4)
		return u32(b)
	}
}

@(optimization_mode="favor_size")
XXH64_read64 :: #force_inline proc(buf: []u8, alignment := Alignment.Unaligned) -> (res: u64) {
	if XXH_FORCE_MEMORY_ACCESS == 2 || alignment == .Aligned {
		#no_bounds_check b := (^u64le)(&buf[0])^
		return u64(b)
	} else {
		b: u64le
		mem_copy(&b, raw_data(buf[:]), 8)
		return u64(b)
	}
}
