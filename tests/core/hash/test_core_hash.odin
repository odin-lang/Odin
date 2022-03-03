package test_core_hash

import "core:hash/xxhash"
import "core:hash"
import "core:time"
import "core:testing"
import "core:fmt"
import "core:os"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.println(" FAIL:", message)
			return
		}
		fmt.println(" PASS")
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}
	test_benchmark_runner(&t)
	test_xxhash_vectors(&t)
	test_crc64_vectors(&t)
	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
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

benchmark_print :: proc(name: string, options: ^time.Benchmark_Options) {
	fmt.printf("\t[%v] %v rounds, %v bytes processed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s\n",
		name,
		options.rounds,
		options.processed,
		time.duration_nanoseconds(options.duration),
		options.rounds_per_second,
		options.megabytes_per_second,
	)
}

@test
test_benchmark_runner :: proc(t: ^testing.T) {
	fmt.println("Starting benchmarks:")

	name    := "XXH32 100 zero bytes"
	options := &time.Benchmark_Options{
		rounds   = 1_000,
		bytes    = 100,
		setup    = setup_xxhash,
		bench    = benchmark_xxh32,
		teardown = teardown_xxhash,
	}

	err  := time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x85f6413c, name)
	benchmark_print(name, options)

	name = "XXH32 1 MiB zero bytes"
	options.bytes = 1_048_576
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x9430f97f, name)
	benchmark_print(name, options)

	name = "XXH64 100 zero bytes"
	options.bytes  = 100
	options.bench = benchmark_xxh64
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x17bb1103c92c502f, name)
	benchmark_print(name, options)

	name = "XXH64 1 MiB zero bytes"
	options.bytes = 1_048_576
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x87d2a1b6e1163ef1, name)
	benchmark_print(name, options)

	name = "XXH3_64 100 zero bytes"
	options.bytes  = 100
	options.bench = benchmark_xxh3_64
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x801fedc74ccd608c, name)
	benchmark_print(name, options)

	name = "XXH3_64 1 MiB zero bytes"
	options.bytes = 1_048_576
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x918780b90550bf34, name)
	benchmark_print(name, options)

	name = "XXH3_128 100 zero bytes"
	options.bytes  = 100
	options.bench = benchmark_xxh3_128
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0x6ba30a4e9dffe1ff801fedc74ccd608c, name)
	benchmark_print(name, options)

	name = "XXH3_128 1 MiB zero bytes"
	options.bytes = 1_048_576
	err = time.benchmark(options, context.allocator)
	expect(t, err == nil, name)
	expect(t, options.hash == 0xb6ef17a3448492b6918780b90550bf34, name)
	benchmark_print(name, options)
}

@test
test_xxhash_vectors :: proc(t: ^testing.T) {
	fmt.println("Verifying against XXHASH_TEST_VECTOR_SEEDED:")

	buf := make([]u8, 256)
	defer delete(buf)

	for seed, table in XXHASH_TEST_VECTOR_SEEDED {
		fmt.printf("\tSeed: %v\n", seed)

		for v, i in table {
			b := buf[:i]

			xxh32    := xxhash.XXH32(b, u32(seed))
			xxh64    := xxhash.XXH64(b, seed)
			xxh3_64  := xxhash.XXH3_64(b, seed)
			xxh3_128 := xxhash.XXH3_128(b, seed)

			xxh32_error     := fmt.tprintf("[   XXH32(%03d) ] Expected: %08x. Got: %08x.", i,   v.xxh_32, xxh32)
			xxh64_error     := fmt.tprintf("[   XXH64(%03d) ] Expected: %16x. Got: %16x.", i,   v.xxh_64, xxh64)

			xxh3_64_error   := fmt.tprintf("[XXH3_64(%03d)  ] Expected: %16x. Got: %16x.", i, v.xxh3_64, xxh3_64)
			xxh3_128_error  := fmt.tprintf("[XXH3_128(%03d) ] Expected: %32x. Got: %32x.", i, v.xxh3_128, xxh3_128)

			expect(t, xxh32     == v.xxh_32,   xxh32_error)
			expect(t, xxh64     == v.xxh_64,   xxh64_error)
			expect(t, xxh3_64   == v.xxh3_64,  xxh3_64_error)
			expect(t, xxh3_128  == v.xxh3_128, xxh3_128_error)

			if len(b) > xxhash.XXH3_MIDSIZE_MAX {
				fmt.printf("XXH3 - size: %v\n", len(b))

				xxh3_state, _ := xxhash.XXH3_create_state()
				xxhash.XXH3_64_reset_with_seed(xxh3_state, seed)
				xxhash.XXH3_64_update(xxh3_state, b)
				xxh3_64_streamed := xxhash.XXH3_64_digest(xxh3_state)
				xxhash.XXH3_destroy_state(xxh3_state)
				xxh3_64s_error  := fmt.tprintf("[XXH3_64s(%03d) ] Expected: %16x. Got: %16x.", i, v.xxh3_64, xxh3_64_streamed)
				expect(t, xxh3_64_streamed == v.xxh3_64, xxh3_64s_error)

				xxh3_state2, _ := xxhash.XXH3_create_state()
				xxhash.XXH3_128_reset_with_seed(xxh3_state2, seed)
				xxhash.XXH3_128_update(xxh3_state2, b)
				xxh3_128_streamed := xxhash.XXH3_128_digest(xxh3_state2)
				xxhash.XXH3_destroy_state(xxh3_state2)
				xxh3_128s_error  := fmt.tprintf("[XXH3_128s(%03d) ] Expected: %32x. Got: %32x.", i, v.xxh3_128, xxh3_128_streamed)
				expect(t, xxh3_128_streamed == v.xxh3_128, xxh3_128s_error)
			}
		}
	}

	fmt.println("Verifying against XXHASH_TEST_VECTOR_SECRET:")
	for secret, table in XXHASH_TEST_VECTOR_SECRET {
		fmt.printf("\tSecret:\n\t\t\"%v\"\n", secret)

		secret_bytes := transmute([]u8)secret

		for v, i in table {
			b := buf[:i]

			xxh3_128 := xxhash.XXH3_128(b, secret_bytes)
			xxh3_128_error := fmt.tprintf("[XXH3_128(%03d)] Expected: %32x. Got: %32x.", i, v.xxh3_128_secret, xxh3_128)

			expect(t, xxh3_128  == v.xxh3_128_secret, xxh3_128_error)
		}
	}
}

@test
test_crc64_vectors :: proc(t: ^testing.T) {
	fmt.println("Verifying CRC-64:")

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

	for vector, expected in vectors {
		fmt.println("\tVector:", vector)
		b := transmute([]u8)vector
		ecma := hash.crc64_ecma_182(b)
		xz   := hash.crc64_xz(b)
		iso  := hash.crc64_iso_3306(b)
		iso2 := hash.crc64_iso_3306_inverse(b)

		ecma_error := fmt.tprintf("[ CRC-64 ECMA    ] Expected: %016x. Got: %016x.", expected[0], ecma)
		xz_error   := fmt.tprintf("[ CRC-64 XZ      ] Expected: %016x. Got: %016x.", expected[1], xz)
		iso_error  := fmt.tprintf("[ CRC-64 ISO 3306] Expected: %016x. Got: %016x.", expected[2], iso)
		iso2_error := fmt.tprintf("[~CRC-64 ISO 3306] Expected: %016x. Got: %016x.", expected[3], iso2)

		expect(t, ecma == expected[0], ecma_error)
		expect(t, xz   == expected[1], xz_error)
		expect(t, iso  == expected[2], iso_error)
		expect(t, iso2 == expected[3], iso2_error)
	}
}