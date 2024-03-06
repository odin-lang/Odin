package test_core_crypto

import "core:encoding/hex"
import "core:fmt"
import "core:testing"
import "core:time"

import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"
import "core:crypto/poly1305"
import "core:crypto/x25519"

import tc "tests:common"

// Cryptographic primitive benchmarks.

@(test)
bench_crypto :: proc(t: ^testing.T) {
	fmt.println("Starting benchmarks:")

	bench_chacha20(t)
	bench_poly1305(t)
	bench_chacha20poly1305(t)
	bench_x25519(t)
}

_setup_sized_buf :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	assert(options != nil)

	options.input = make([]u8, options.bytes, allocator)
	return nil if len(options.input) == options.bytes else .Allocation_Error
}

_teardown_sized_buf :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	assert(options != nil)

	delete(options.input)
	return nil
}

_benchmark_chacha20 :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	key := [chacha20.KEY_SIZE]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	nonce := [chacha20.NONCE_SIZE]byte {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
	}

	ctx: chacha20.Context = ---
	chacha20.init(&ctx, key[:], nonce[:])

	for _ in 0 ..= options.rounds {
		chacha20.xor_bytes(&ctx, buf, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

_benchmark_poly1305 :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	key := [poly1305.KEY_SIZE]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}

	tag: [poly1305.TAG_SIZE]byte = ---
	for _ in 0 ..= options.rounds {
		poly1305.sum(tag[:], buf, key[:])
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes
	//options.hash      = u128(h)
	return nil
}

_benchmark_chacha20poly1305 :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	key := [chacha20.KEY_SIZE]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	nonce := [chacha20.NONCE_SIZE]byte {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
	}

	tag: [chacha20poly1305.TAG_SIZE]byte = ---

	for _ in 0 ..= options.rounds {
		chacha20poly1305.encrypt(buf, tag[:], key[:], nonce[:], nil, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

benchmark_print :: proc(name: string, options: ^time.Benchmark_Options) {
	fmt.printf(
		"\t[%v] %v rounds, %v bytes processed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s\n",
		name,
		options.rounds,
		options.processed,
		time.duration_nanoseconds(options.duration),
		options.rounds_per_second,
		options.megabytes_per_second,
	)
}

bench_chacha20 :: proc(t: ^testing.T) {
	name := "ChaCha20 64 bytes"
	options := &time.Benchmark_Options {
		rounds = 1_000,
		bytes = 64,
		setup = _setup_sized_buf,
		bench = _benchmark_chacha20,
		teardown = _teardown_sized_buf,
	}

	err := time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "ChaCha20 1024 bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "ChaCha20 65536 bytes"
	options.bytes = 65536
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_poly1305 :: proc(t: ^testing.T) {
	name := "Poly1305 64 zero bytes"
	options := &time.Benchmark_Options {
		rounds = 1_000,
		bytes = 64,
		setup = _setup_sized_buf,
		bench = _benchmark_poly1305,
		teardown = _teardown_sized_buf,
	}

	err := time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "Poly1305 1024 zero bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_chacha20poly1305 :: proc(t: ^testing.T) {
	name := "chacha20poly1305 64 bytes"
	options := &time.Benchmark_Options {
		rounds = 1_000,
		bytes = 64,
		setup = _setup_sized_buf,
		bench = _benchmark_chacha20poly1305,
		teardown = _teardown_sized_buf,
	}

	err := time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "chacha20poly1305 1024 bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "chacha20poly1305 65536 bytes"
	options.bytes = 65536
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_x25519 :: proc(t: ^testing.T) {
	point_str := "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
	scalar_str := "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe"

	point, _ := hex.decode(transmute([]byte)(point_str), context.temp_allocator)
	scalar, _ := hex.decode(transmute([]byte)(scalar_str), context.temp_allocator)
	out: [x25519.POINT_SIZE]byte = ---

	iters :: 10000
	start := time.now()
	for i := 0; i < iters; i = i + 1 {
		x25519.scalarmult(out[:], scalar[:], point[:])
	}
	elapsed := time.since(start)

	tc.log(
		t,
		fmt.tprintf("x25519.scalarmult: ~%f us/op", time.duration_microseconds(elapsed) / iters),
	)
}
