/*
	An implementation of Yann Collet's [xxhash Fast Hash Algorithm](https://cyan4973.github.io/xxHash/).
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.

	Made available under Odin's BSD-3 license, based on the original C code.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
package xxhash

import "core:intrinsics"
import "core:runtime"
import "core:time"
import "core:fmt"
import "core:testing"

mem_copy :: runtime.mem_copy

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
	Okay = 0,
	Error,
}

@(optimization_mode="speed")
XXH_rotl32 :: #force_inline proc(x, r: u32) -> (res: u32) {
	return ((x << r) | (x >> (32 - r)))
}

@(optimization_mode="speed")
XXH_rotl64 :: #force_inline proc(x, r: u64) -> (res: u64) {
	return ((x << r) | (x >> (64 - r)))
}

@(optimization_mode="speed")
XXH32_read32 :: #force_inline proc(buf: []u8, alignment: Alignment) -> (res: u32) {
	if XXH_FORCE_MEMORY_ACCESS == 2 || alignment == .Aligned {
		#no_bounds_check b := (^u32le)(&buf[0])^
		return u32(b)
	} else {
		b: u32le
		mem_copy(&b, raw_data(buf[:]), 4)
		return u32(b)
	}
}

@(optimization_mode="speed")
XXH64_read64 :: #force_inline proc(buf: []u8, alignment: Alignment) -> (res: u64) {
	if XXH_FORCE_MEMORY_ACCESS == 2 || alignment == .Aligned {
		#no_bounds_check b := (^u64le)(&buf[0])^
		return u64(b)
	} else {
		b: u64le
		mem_copy(&b, raw_data(buf[:]), 8)
		return u64(b)
	}
}


/*
	Benchmarks
*/

setup_xxhash :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	assert(options != nil)

	options.input = make([]u8, options.bytes, allocator)
	return nil if len(options.input) == options.bytes else .Allocation_Error
}

teardown_xxhash :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	assert(options != nil)

	delete(options.input)
	return nil
}

benchmark_xxhash32 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input

	for _ in 0..=options.rounds {
		_ = XXH32(buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

benchmark_xxhash64 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input

	for _ in 0..=options.rounds {
		_ = XXH64(buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

benchmark_print :: proc(name: string, options: ^time.Benchmark_Options) {
	fmt.printf("\t[%v] %v rounds, %v bytes procesed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s\n",
		name,
		options.rounds,
		options.processed,
		time.duration_nanoseconds(options.duration),
		options.rounds_per_second,
		options.megabytes_per_second,
	)
}

@test
benchmark_runner :: proc(t: ^testing.T) {
	fmt.println("Starting benchmarks:")

	options := &time.Benchmark_Options{
		rounds   = 1_000,
		bytes    = 100,
		setup    = setup_xxhash,
		bench    = benchmark_xxhash32,
		teardown = teardown_xxhash,
	}
	err := time.benchmark(options, context.allocator)
	benchmark_print("xxhash32 100 bytes", options)

	options.bytes = 1_000_000
	err = time.benchmark(options, context.allocator)
	benchmark_print("xxhash32 1_000_000 bytes", options)

	options.bytes  = 100
	options.bench = benchmark_xxhash64
	err = time.benchmark(options, context.allocator)
	benchmark_print("xxhash64 100 bytes", options)

	options.bytes = 1_000_000
	err = time.benchmark(options, context.allocator)
	benchmark_print("xxhash64 1_000_000 bytes", options)
}

