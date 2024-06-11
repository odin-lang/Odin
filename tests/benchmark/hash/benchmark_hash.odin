package benchmark_core_hash

import "core:fmt"
import "core:hash/xxhash"
import "base:intrinsics"
import "core:strings"
import "core:testing"
import "core:time"

@(test)
benchmark_hash :: proc(t: ^testing.T) {
	str: strings.Builder
	strings.builder_init(&str, context.allocator)
	defer {
		fmt.println(strings.to_string(str))
		strings.builder_destroy(&str)
	}

	{
		name := "XXH32 100 zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 100,
			setup    = setup_xxhash,
			bench    = benchmark_xxh32,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x85f6413c)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH32 1 MiB zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 1_048_576,
			setup    = setup_xxhash,
			bench    = benchmark_xxh32,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x9430f97f)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH64 100 zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 100,
			setup    = setup_xxhash,
			bench    = benchmark_xxh64,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x17bb1103c92c502f)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH64 1 MiB zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 1_048_576,
			setup    = setup_xxhash,
			bench    = benchmark_xxh64,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x87d2a1b6e1163ef1)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH3_64 100 zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 100,
			setup    = setup_xxhash,
			bench    = benchmark_xxh3_64,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x801fedc74ccd608c)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH3_64 1 MiB zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 1_048_576,
			setup    = setup_xxhash,
			bench    = benchmark_xxh3_64,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x918780b90550bf34)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH3_128 100 zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 100,
			setup    = setup_xxhash,
			bench    = benchmark_xxh3_128,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0x6ba30a4e9dffe1ff801fedc74ccd608c)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
	{
		name := "XXH3_128 1 MiB zero bytes"
		options := &time.Benchmark_Options{
			rounds   = 1_000,
			bytes    = 1_048_576,
			setup    = setup_xxhash,
			bench    = benchmark_xxh3_128,
			teardown = teardown_xxhash,
		}
		err := time.benchmark(options, context.allocator)
		testing.expectf(t, err == nil, "%s failed with err %v", name, err)
		hash := u128(0xb6ef17a3448492b6918780b90550bf34)
		testing.expectf(t, options.hash == hash, "%v hash expected to be %v, got %v", name, hash, options.hash)
		benchmark_print(&str, name, options)
	}
}

// Benchmarks

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

benchmark_xxh32 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input

	h: u32
	for _ in 0..=options.rounds {
		h = xxhash.XXH32(buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	options.hash      = u128(h)
	return nil
}

benchmark_xxh64 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input

	h: u64
	for _ in 0..=options.rounds {
		h = xxhash.XXH64(buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	options.hash      = u128(h)
	return nil
}

benchmark_xxh3_64 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input

	h: u64
	for _ in 0..=options.rounds {
		h = xxhash.XXH3_64(buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	options.hash      = u128(h)
	return nil
}

benchmark_xxh3_128 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
	buf := options.input

	h: u128
	for _ in 0..=options.rounds {
		h = xxhash.XXH3_128(buf)
	}
	options.count     = options.rounds
	options.processed = options.rounds * options.bytes
	options.hash      = h
	return nil
}

benchmark_print :: proc(str: ^strings.Builder, name: string, options: ^time.Benchmark_Options, loc := #caller_location) {
	fmt.sbprintfln(str, "[%v] %v rounds, %v bytes processed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s\n",
		name,
		options.rounds,
		options.processed,
		time.duration_nanoseconds(options.duration),
		options.rounds_per_second,
		options.megabytes_per_second,
	)
}