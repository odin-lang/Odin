package benchmark_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto/ed25519"
import "core:crypto/x25519"
import "core:crypto/x448"

@(private = "file")
ECDH_ITERS :: 10000
@(private = "file")
DSA_ITERS :: 10000

@(test)
benchmark_crypto_ecc :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	bench_ecdh()
	bench_dsa()
}

@(private = "file")
bench_ecdh :: proc() {
	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "ECDH")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Scalar-Basepoint", "Scalar-Point")

	append_tbl := proc(tbl: ^table.Table, algo_name: string, bp, sc: time.Duration) {
		table.aligned_row_of_values(
			tbl,
			.Right,
			algo_name,
			table.format(tbl, "%8M", bp),
			table.format(tbl, "%8M", sc),
		)
	}

	scalar_bp, scalar := bench_x25519()
	append_tbl(&tbl, "X25519", scalar_bp, scalar)

	scalar_bp, scalar = bench_x448()
	append_tbl(&tbl, "X448", scalar_bp, scalar)

	log_table(&tbl)
}

@(private = "file")
bench_x25519 :: proc() -> (bp, sc: time.Duration) {
	point_str := "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
	scalar_str := "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe"

	point, _ := hex.decode(transmute([]byte)(point_str), context.temp_allocator)
	scalar, _ := hex.decode(transmute([]byte)(scalar_str), context.temp_allocator)
	out: [x25519.POINT_SIZE]byte = ---

	start := time.tick_now()
	for _ in 0 ..< ECDH_ITERS {
		x25519.scalarmult_basepoint(out[:], scalar[:])
	}
	bp = time.tick_since(start) / ECDH_ITERS

	start = time.tick_now()
	for _ in 0 ..< ECDH_ITERS {
		x25519.scalarmult(out[:], scalar[:], point[:])
	}
	sc = time.tick_since(start) / ECDH_ITERS

	return
}

@(private = "file")
bench_x448 :: proc() -> (bp, sc: time.Duration) {
	point_str := "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
	scalar_str := "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe"

	point, _ := hex.decode(transmute([]byte)(point_str), context.temp_allocator)
	scalar, _ := hex.decode(transmute([]byte)(scalar_str), context.temp_allocator)
	out: [x448.POINT_SIZE]byte = ---

	start := time.tick_now()
	for _ in 0 ..< ECDH_ITERS {
		x448.scalarmult_basepoint(out[:], scalar[:])
	}
	bp = time.tick_since(start) / ECDH_ITERS

	start = time.tick_now()
	for _ in 0 ..< ECDH_ITERS {
		x448.scalarmult(out[:], scalar[:], point[:])
	}
	sc = time.tick_since(start) / ECDH_ITERS

	return
}

@(private = "file")
bench_dsa :: proc() {
	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "ECDSA/EdDSA")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Op", "Time")

	append_tbl := proc(tbl: ^table.Table, algo_name, op: string, t: time.Duration) {
		table.aligned_row_of_values(
			tbl,
			.Right,
			algo_name,
			op,
			table.format(tbl, "%8M", t),
		)
	}

	sk, sig, verif := bench_ed25519()
	append_tbl(&tbl, "ed25519", "private_key_set_bytes", sk)
	append_tbl(&tbl, "ed25519", "sign", sig)
	append_tbl(&tbl, "ed25519", "verify", verif)

	log_table(&tbl)
}

@(private = "file")
bench_ed25519 :: proc() -> (sk, sig, verif: time.Duration) {
	priv_str := "cafebabecafebabecafebabecafebabecafebabecafebabecafebabecafebabe"
	priv_bytes, _ := hex.decode(transmute([]byte)(priv_str), context.temp_allocator)
	priv_key: ed25519.Private_Key
	start := time.tick_now()
	for _ in  0 ..< DSA_ITERS {
		ok := ed25519.private_key_set_bytes(&priv_key, priv_bytes)
		assert(ok, "private key should deserialize")
	}
	sk = time.tick_since(start) / DSA_ITERS

	pub_bytes := priv_key._pub_key._b[:] // "I know what I am doing"
	pub_key: ed25519.Public_Key
	ok := ed25519.public_key_set_bytes(&pub_key, pub_bytes[:])
	assert(ok, "public key should deserialize")

	msg := "Got a job for you, 621."
	sig_bytes: [ed25519.SIGNATURE_SIZE]byte
	msg_bytes := transmute([]byte)(msg)
	start = time.tick_now()
	for _ in  0 ..< DSA_ITERS {
		ed25519.sign(&priv_key, msg_bytes, sig_bytes[:])
	}
	sig = time.tick_since(start) / DSA_ITERS

	start = time.tick_now()
	for _ in  0 ..< DSA_ITERS {
		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes[:])
		assert(ok, "signature should validate")
	}
	verif = time.tick_since(start) / DSA_ITERS

	return
}
