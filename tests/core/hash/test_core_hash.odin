package test_core_hash

import "core:hash/xxhash"
import "core:hash"
import "core:time"
import "core:testing"
import "core:fmt"
import "core:log"
import "core:math/rand"
import "base:intrinsics"

@test
test_xxhash_zero_fixed :: proc(t: ^testing.T) {
	many_zeroes := make([]u8, 16 * 1024 * 1024)
	defer delete(many_zeroes)

	// All at once.
	for i, v in ZERO_VECTORS {
		b := many_zeroes[:i]

		xxh32    := xxhash.XXH32(b)
		xxh64    := xxhash.XXH64(b)
		xxh3_64  := xxhash.XXH3_64(b)
		xxh3_128 := xxhash.XXH3_128(b)

		testing.expectf(t, xxh32    == v.xxh_32,   "[   XXH32(%03d) ] Expected: %08x, got: %08x", i, v.xxh_32,   xxh32)
		testing.expectf(t, xxh64    == v.xxh_64,   "[   XXH64(%03d) ] Expected: %16x, got: %16x", i, v.xxh_64,   xxh64)
		testing.expectf(t, xxh3_64  == v.xxh3_64,  "[XXH3_64(%03d)  ] Expected: %16x, got: %16x", i, v.xxh3_64,  xxh3_64)
		testing.expectf(t, xxh3_128 == v.xxh3_128, "[XXH3_128(%03d) ] Expected: %32x, got: %32x", i, v.xxh3_128, xxh3_128)
	}
}

@(test)
test_xxhash_zero_streamed_random_updates :: proc(t: ^testing.T) {
	many_zeroes := make([]u8, 16 * 1024 * 1024)
	defer delete(many_zeroes)

	// Streamed
	for i, v in ZERO_VECTORS {
		b := many_zeroes[:i]

		xxh_32_state, xxh_32_err := xxhash.XXH32_create_state()
		defer xxhash.XXH32_destroy_state(xxh_32_state)
		testing.expect(t, xxh_32_err == nil, "Problem initializing XXH_32 state")

		xxh_64_state, xxh_64_err := xxhash.XXH64_create_state()
		defer xxhash.XXH64_destroy_state(xxh_64_state)
		testing.expect(t, xxh_64_err == nil, "Problem initializing XXH_64 state")

		xxh3_64_state, xxh3_64_err := xxhash.XXH3_create_state()
		defer xxhash.XXH3_destroy_state(xxh3_64_state)
		testing.expect(t, xxh3_64_err == nil, "Problem initializing XXH3_64 state")

		xxh3_128_state, xxh3_128_err := xxhash.XXH3_create_state()
		defer xxhash.XXH3_destroy_state(xxh3_128_state)
		testing.expect(t, xxh3_128_err == nil, "Problem initializing XXH3_128 state")

		// XXH3_128_update
		random_seed := rand.create(t.seed)
		for len(b) > 0 {
			update_size := min(len(b), rand.int_max(8192, &random_seed))
			if update_size > 4096 {
				update_size %= 73
			}
			xxhash.XXH32_update   (xxh_32_state,   b[:update_size])
			xxhash.XXH64_update   (xxh_64_state,   b[:update_size])

			xxhash.XXH3_64_update (xxh3_64_state,  b[:update_size])
			xxhash.XXH3_128_update(xxh3_128_state, b[:update_size])

			b = b[update_size:]
		}

		// Now finalize
		xxh32    := xxhash.XXH32_digest(xxh_32_state)
		xxh64    := xxhash.XXH64_digest(xxh_64_state)

		xxh3_64  := xxhash.XXH3_64_digest(xxh3_64_state)
		xxh3_128 := xxhash.XXH3_128_digest(xxh3_128_state)

		xxh32_error     := fmt.tprintf("[   XXH32(%03d) ] Expected: %08x, got: %08x", i,   v.xxh_32,   xxh32)
		xxh64_error     := fmt.tprintf("[   XXH64(%03d) ] Expected: %16x, got: %16x", i,   v.xxh_64,   xxh64)
		xxh3_64_error   := fmt.tprintf("[XXH3_64(%03d)  ] Expected: %16x, got: %16x", i,  v.xxh3_64, xxh3_64)
		xxh3_128_error  := fmt.tprintf("[XXH3_128(%03d) ] Expected: %32x, got: %32x", i, v.xxh3_128, xxh3_128)

		testing.expect(t, xxh32     == v.xxh_32,   xxh32_error)
		testing.expect(t, xxh64     == v.xxh_64,   xxh64_error)
		testing.expect(t, xxh3_64   == v.xxh3_64,  xxh3_64_error)
		testing.expect(t, xxh3_128  == v.xxh3_128, xxh3_128_error)
	}
}

@test
test_xxhash_seeded :: proc(t: ^testing.T) {
	buf := make([]u8, 256)
	defer delete(buf)

	for seed, table in XXHASH_TEST_VECTOR_SEEDED {
		for v, i in table {
			b := buf[:i]

			xxh32    := xxhash.XXH32(b, u32(seed))
			xxh64    := xxhash.XXH64(b, seed)
			xxh3_64  := xxhash.XXH3_64(b, seed)
			xxh3_128 := xxhash.XXH3_128(b, seed)

			testing.expectf(t, xxh32    == v.xxh_32,   "[   XXH32(%03d) ] Expected: %08x, got: %08x", i,   v.xxh_32, xxh32)
			testing.expectf(t, xxh64    == v.xxh_64,   "[   XXH64(%03d) ] Expected: %16x, got: %16x", i,   v.xxh_64, xxh64)
			testing.expectf(t, xxh3_64  == v.xxh3_64,  "[XXH3_64(%03d)  ] Expected: %16x, got: %16x", i, v.xxh3_64, xxh3_64)
			testing.expectf(t, xxh3_128 == v.xxh3_128, "[XXH3_128(%03d) ] Expected: %32x, got: %32x", i, v.xxh3_128, xxh3_128)

			if len(b) > xxhash.XXH3_MIDSIZE_MAX {
				xxh3_state, _ := xxhash.XXH3_create_state()
				xxhash.XXH3_64_reset_with_seed(xxh3_state, seed)
				xxhash.XXH3_64_update(xxh3_state, b)
				xxh3_64_streamed := xxhash.XXH3_64_digest(xxh3_state)
				xxhash.XXH3_destroy_state(xxh3_state)
				testing.expectf(t, xxh3_64_streamed == v.xxh3_64, "[XXH3_64s(%03d) ] Expected: %16x, got: %16x", i, v.xxh3_64, xxh3_64_streamed)

				xxh3_state2, _ := xxhash.XXH3_create_state()
				xxhash.XXH3_128_reset_with_seed(xxh3_state2, seed)
				xxhash.XXH3_128_update(xxh3_state2, b)
				xxh3_128_streamed := xxhash.XXH3_128_digest(xxh3_state2)
				xxhash.XXH3_destroy_state(xxh3_state2)
				testing.expectf(t, xxh3_128_streamed == v.xxh3_128, "[XXH3_128s(%03d) ] Expected: %32x, got: %32x", i, v.xxh3_128, xxh3_128_streamed)
			}
		}
	}
}

@test
test_xxhash_secret :: proc(t: ^testing.T) {
	buf := make([]u8, 256)
	defer delete(buf)

	for secret, table in XXHASH_TEST_VECTOR_SECRET {
		secret_bytes := transmute([]u8)secret
		for v, i in table {
			b := buf[:i]

			xxh3_128 := xxhash.XXH3_128(b, secret_bytes)
			testing.expectf(t, xxh3_128  == v.xxh3_128_secret, "[XXH3_128(%03d)] Expected: %32x, got: %32x", i, v.xxh3_128_secret, xxh3_128)
		}
	}
}

@test
test_crc64_vectors :: proc(t: ^testing.T) {
	vectors := map[string][4]u64 {
		"123456789" = {
			0x6c40df5f0b497347, // ECMA-182,
			0x995dc9bbdf1939fa, // XZ
			0x46a5a9388a5beffe, // ISO 3306
			0xb90956c775a41001, // ISO 3306, input and output inverted
		},
		"This is a test of the emergency broadcast system." = {
			0x344fe1d09c983d13, // ECMA-182
			0x27db187fc15bbc72, // XZ
			0x187184d744afc49e, // ISO 3306
			0xe7fcf1006b503b61, // ISO 3306, input and output inverted
		},
	}
	defer delete(vectors)

	for vector, expected in vectors {
		b := transmute([]u8)vector
		ecma := hash.crc64_ecma_182(b)
		xz   := hash.crc64_xz(b)
		iso  := hash.crc64_iso_3306(b)
		iso2 := hash.crc64_iso_3306_inverse(b)

		testing.expectf(t, ecma == expected[0], "[ CRC-64 ECMA    ] Expected: %016x, got: %016x", expected[0], ecma)
		testing.expectf(t, xz   == expected[1], "[ CRC-64 XZ      ] Expected: %016x, got: %016x", expected[1], xz)
		testing.expectf(t, iso  == expected[2], "[ CRC-64 ISO 3306] Expected: %016x, got: %016x", expected[2], iso)
		testing.expectf(t, iso2 == expected[3], "[~CRC-64 ISO 3306] Expected: %016x, got: %016x", expected[3], iso2)
	}
}

@(test)
test_benchmark_xxh32 :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh32_1MB :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh64 :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh64_1MB :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh3_64 :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh3_64_1MB :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh3_128 :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
}

@(test)
test_benchmark_xxh3_128_1MB :: proc(t: ^testing.T) {
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
	benchmark_print(name, options)
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

benchmark_print :: proc(name: string, options: ^time.Benchmark_Options, loc := #caller_location) {
	log.infof("\n\t[%v] %v rounds, %v bytes processed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s",
		name,
		options.rounds,
		options.processed,
		time.duration_nanoseconds(options.duration),
		options.rounds_per_second,
		options.megabytes_per_second,
		location=loc,
	)
}