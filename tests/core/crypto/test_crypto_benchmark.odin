package test_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:fmt"
import "core:testing"
import "core:time"

import "core:crypto/aes"
import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"
import "core:crypto/ed25519"
import "core:crypto/poly1305"
import "core:crypto/x25519"

import tc "tests:common"

// Cryptographic primitive benchmarks.

@(test)
bench_crypto :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	fmt.println("Starting benchmarks:")

	bench_chacha20(t)
	bench_poly1305(t)
	bench_chacha20poly1305(t)
	bench_aes256_gcm(t)
	bench_ed25519(t)
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

_benchmark_aes256_gcm :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	nonce: [aes.GCM_NONCE_SIZE]byte
	tag: [aes.GCM_TAG_SIZE]byte = ---

	ctx := transmute(^aes.Context_GCM)context.user_ptr

	for _ in 0 ..= options.rounds {
		aes.seal_gcm(ctx, buf, tag[:], nonce[:], nil, buf)
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

bench_aes256_gcm :: proc(t: ^testing.T) {
	name := "AES256-GCM 64 bytes"
	options := &time.Benchmark_Options {
		rounds = 1_000,
		bytes = 64,
		setup = _setup_sized_buf,
		bench = _benchmark_aes256_gcm,
		teardown = _teardown_sized_buf,
	}

	key := [aes.KEY_SIZE_256]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	ctx: aes.Context_GCM
	aes.init_gcm(&ctx, key[:])

	context.user_ptr = &ctx

	err := time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "AES256-GCM 1024 bytes"
	options.bytes = 1024
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)

	name = "AES256-GCM 65536 bytes"
	options.bytes = 65536
	err = time.benchmark(options, context.allocator)
	tc.expect(t, err == nil, name)
	benchmark_print(name, options)
}

bench_ed25519 :: proc(t: ^testing.T) {
	iters :: 10000

	priv_str := "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe"
	priv_bytes, _ := hex.decode(transmute([]byte)(priv_str), context.temp_allocator)
	priv_key: ed25519.Private_Key
	start := time.now()
	for i := 0; i < iters; i = i + 1 {
		ok := ed25519.private_key_set_bytes(&priv_key, priv_bytes)
		assert(ok, "private key should deserialize")
	}
	elapsed := time.since(start)
	tc.log(
		t,
		fmt.tprintf(
			"ed25519.private_key_set_bytes: ~%f us/op",
			time.duration_microseconds(elapsed) / iters,
		),
	)

	pub_bytes := priv_key._pub_key._b[:] // "I know what I am doing"
	pub_key: ed25519.Public_Key
	start = time.now()
	for i := 0; i < iters; i = i + 1 {
		ok := ed25519.public_key_set_bytes(&pub_key, pub_bytes[:])
		assert(ok, "public key should deserialize")
	}
	elapsed = time.since(start)
	tc.log(
		t,
		fmt.tprintf(
			"ed25519.public_key_set_bytes: ~%f us/op",
			time.duration_microseconds(elapsed) / iters,
		),
	)

	msg := "Got a job for you, 621."
	sig_bytes: [ed25519.SIGNATURE_SIZE]byte
	msg_bytes := transmute([]byte)(msg)
	start = time.now()
	for i := 0; i < iters; i = i + 1 {
		ed25519.sign(&priv_key, msg_bytes, sig_bytes[:])
	}
	elapsed = time.since(start)
	tc.log(t, fmt.tprintf("ed25519.sign: ~%f us/op", time.duration_microseconds(elapsed) / iters))

	start = time.now()
	for i := 0; i < iters; i = i + 1 {
		ok := ed25519.verify(&pub_key, msg_bytes, sig_bytes[:])
		assert(ok, "signature should validate")
	}
	elapsed = time.since(start)
	tc.log(
		t,
		fmt.tprintf("ed25519.verify: ~%f us/op", time.duration_microseconds(elapsed) / iters),
	)
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
