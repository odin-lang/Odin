package benchmark_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:testing"
import "core:time"

import "core:crypto/aes"
import "core:crypto/chacha20"
import "core:crypto/chacha20poly1305"
import "core:crypto/ed25519"
import "core:crypto/poly1305"
import "core:crypto/x25519"

// Cryptographic primitive benchmarks.

@(test)
benchmark_crypto :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	str: strings.Builder
	strings.builder_init(&str, context.allocator)
	defer {
		log.info(strings.to_string(str))
		strings.builder_destroy(&str)
	}

	{
		name := "AES256-CTR 64 bytes"
		options := &time.Benchmark_Options {
			rounds = 1_000,
			bytes = 64,
			setup = _setup_sized_buf,
			bench = _benchmark_aes256_ctr,
			teardown = _teardown_sized_buf,
		}

		err := time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "AES256-CTR 1024 bytes"
		options.bytes = 1024
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "AES256-CTR 65536 bytes"
		options.bytes = 65536
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)
	}
	{
		name := "ChaCha20 64 bytes"
		options := &time.Benchmark_Options {
			rounds = 1_000,
			bytes = 64,
			setup = _setup_sized_buf,
			bench = _benchmark_chacha20,
			teardown = _teardown_sized_buf,
		}

		err := time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "ChaCha20 1024 bytes"
		options.bytes = 1024
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "ChaCha20 65536 bytes"
		options.bytes = 65536
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)
	}
	{
		name := "Poly1305 64 zero bytes"
		options := &time.Benchmark_Options {
			rounds = 1_000,
			bytes = 64,
			setup = _setup_sized_buf,
			bench = _benchmark_poly1305,
			teardown = _teardown_sized_buf,
		}

		err := time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "Poly1305 1024 zero bytes"
		options.bytes = 1024
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)
	}
	{
		name := "chacha20poly1305 64 bytes"
		options := &time.Benchmark_Options {
			rounds = 1_000,
			bytes = 64,
			setup = _setup_sized_buf,
			bench = _benchmark_chacha20poly1305,
			teardown = _teardown_sized_buf,
		}

		err := time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "chacha20poly1305 1024 bytes"
		options.bytes = 1024
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "chacha20poly1305 65536 bytes"
		options.bytes = 65536
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)
	}
	{
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
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "AES256-GCM 1024 bytes"
		options.bytes = 1024
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)

		name = "AES256-GCM 65536 bytes"
		options.bytes = 65536
		err = time.benchmark(options, context.allocator)
		testing.expect(t, err == nil, name)
		benchmark_print(&str, name, options)
	}
	{
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
		fmt.sbprintfln(&str,
			"ed25519.private_key_set_bytes: ~%f us/op",
			time.duration_microseconds(elapsed) / iters,
		)

		pub_bytes := priv_key._pub_key._b[:] // "I know what I am doing"
		pub_key: ed25519.Public_Key
		start = time.now()
		for i := 0; i < iters; i = i + 1 {
			ok := ed25519.public_key_set_bytes(&pub_key, pub_bytes[:])
			assert(ok, "public key should deserialize")
		}
		elapsed = time.since(start)
		fmt.sbprintfln(&str,
			"ed25519.public_key_set_bytes: ~%f us/op",
			time.duration_microseconds(elapsed) / iters,
		)

		msg := "Got a job for you, 621."
		sig_bytes: [ed25519.SIGNATURE_SIZE]byte
		msg_bytes := transmute([]byte)(msg)
		start = time.now()
		for i := 0; i < iters; i = i + 1 {
			ed25519.sign(&priv_key, msg_bytes, sig_bytes[:])
		}
		elapsed = time.since(start)
		fmt.sbprintfln(&str,
		    "ed25519.sign: ~%f us/op",
		    time.duration_microseconds(elapsed) / iters,
		)

		start = time.now()
		for i := 0; i < iters; i = i + 1 {
			ok := ed25519.verify(&pub_key, msg_bytes, sig_bytes[:])
			assert(ok, "signature should validate")
		}
		elapsed = time.since(start)
		fmt.sbprintfln(&str,
			"ed25519.verify: ~%f us/op",
			time.duration_microseconds(elapsed) / iters,
		)
	}
	{
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

		fmt.sbprintfln(&str,
			"x25519.scalarmult: ~%f us/op",
			time.duration_microseconds(elapsed) / iters,
		)
	}
}

@(private)
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

@(private)
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

@(private)
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
	iv := [chacha20.IV_SIZE]byte {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
	}

	ctx: chacha20.Context = ---
	chacha20.init(&ctx, key[:], iv[:])

	for _ in 0 ..= options.rounds {
		chacha20.xor_bytes(&ctx, buf, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

@(private)
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

@(private)
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
	iv := [chacha20.IV_SIZE]byte {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
	}

	ctx: chacha20poly1305.Context = ---
	chacha20poly1305.init(&ctx, key[:]) // Basically 0 overhead.

	tag: [chacha20poly1305.TAG_SIZE]byte = ---

	for _ in 0 ..= options.rounds {
		chacha20poly1305.seal(&ctx, buf, tag[:], iv[:], nil, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

@(private)
_benchmark_aes256_ctr :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	key := [aes.KEY_SIZE_256]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	iv := [aes.CTR_IV_SIZE]byte {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	}

	ctx: aes.Context_CTR = ---
	aes.init_ctr(&ctx, key[:], iv[:])

	for _ in 0 ..= options.rounds {
		aes.xor_bytes_ctr(&ctx, buf, buf)
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
	iv: [aes.GCM_IV_SIZE]byte
	tag: [aes.GCM_TAG_SIZE]byte = ---

	ctx := (^aes.Context_GCM)(context.user_ptr)

	for _ in 0 ..= options.rounds {
		aes.seal_gcm(ctx, buf, tag[:], iv[:], nil, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes
	return nil
}

@(private)
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
