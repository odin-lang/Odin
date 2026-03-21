package benchmark_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:log"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto"
import "core:crypto/ecdh"
import "core:crypto/ecdsa"
import "core:crypto/ed25519"
import "core:crypto/hash"

@(private = "file")
ECDH_ITERS :: 10000
@(private = "file")
DSA_ITERS :: 10000
@(private = "file")
MSG : string : "Got a job for you, 621."

@(test)
benchmark_crypto_ecc :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	bench_ecdh()
	bench_dsa()
}

@(private="file")
bench_ecdh :: proc() {
	if !crypto.HAS_RAND_BYTES {
		log.warnf("ECDH benchmarks skipped, no system entropy source")
	}

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

	for algo in ecdh.Curve {
		if algo == .Invalid {
			continue
		}
		algo_name := ecdh.CURVE_NAMES[algo]

		priv_key_alice: ecdh.Private_Key
		start := time.tick_now()
		for _ in 0 ..< ECDH_ITERS {
			_ = ecdh.private_key_generate(&priv_key_alice, algo)
		}
		bp := time.tick_since(start) / ECDH_ITERS

		pub_key_alice: ecdh.Public_Key
		ecdh.public_key_set_priv(&pub_key_alice, &priv_key_alice)

		priv_key_bob: ecdh.Private_Key
		_ = ecdh.private_key_generate(&priv_key_bob, algo)
		ss := make([]byte, ecdh.SHARED_SECRET_SIZES[algo], context.temp_allocator)
		start = time.tick_now()
		for _ in 0 ..< ECDH_ITERS {
			_ = ecdh.ecdh(&priv_key_bob, &pub_key_alice, ss)
		}
		sc := time.tick_since(start) / ECDH_ITERS

		append_tbl(&tbl, algo_name, bp, sc)
	}

	log_table(&tbl)
}

@(private="file")
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

	table.row(&tbl)

	sk, sig, verif = bench_ecdsa(.SECP256R1, .SHA256)
	append_tbl(&tbl, "secp256r1/SHA256/RFC6979", "private_key_set_bytes", sk)
	append_tbl(&tbl, "secp256r1/SHA256/RFC6979", "sign", sig)
	append_tbl(&tbl, "secp256r1/SHA256/RFC6979", "verify", verif)

	table.row(&tbl)

	sk, sig, verif = bench_ecdsa(.SECP384R1, .SHA384)
	append_tbl(&tbl, "secp384r1/SHA384/RFC6979", "private_key_set_bytes", sk)
	append_tbl(&tbl, "secp384r1/SHA384/RFC6979", "sign", sig)
	append_tbl(&tbl, "secp384r1/SHA384/RFC6979", "verify", verif)

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

	sig_bytes: [ed25519.SIGNATURE_SIZE]byte
	msg_bytes := transmute([]byte)(MSG)
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

@(private="file")
bench_ecdsa :: proc(curve: ecdsa.Curve, hash: hash.Algorithm) -> (sk, sig, verif: time.Duration) {
	priv_bytes := make([]byte, ecdsa.PRIVATE_KEY_SIZES[curve], context.temp_allocator)
	crypto.set(raw_data(priv_bytes), 0x69, len(priv_bytes))
	priv_key: ecdsa.Private_Key
	start := time.tick_now()
	for _ in  0 ..< DSA_ITERS {
		ok := ecdsa.private_key_set_bytes(&priv_key, curve, priv_bytes)
		assert(ok, "private key should deserialize")
	}
	sk = time.tick_since(start) / DSA_ITERS

	pub_key: ecdsa.Public_Key
	ecdsa.public_key_set_priv(&pub_key, &priv_key)

	sig_bytes := make([]byte, ecdsa.RAW_SIGNATURE_SIZES[curve], context.temp_allocator)
	msg_bytes := transmute([]byte)(MSG)
	start = time.tick_now()
	for _ in  0 ..< DSA_ITERS {
		ok := ecdsa.sign_raw(&priv_key, hash, msg_bytes, sig_bytes, true)
		assert(ok, "signing should succeed")
	}
	sig = time.tick_since(start) / DSA_ITERS

	start = time.tick_now()
	for _ in  0 ..< DSA_ITERS {
		ok := ecdsa.verify_raw(&pub_key, hash, msg_bytes, sig_bytes)
		assert(ok, "signature should validate")
	}
	verif = time.tick_since(start) / DSA_ITERS

	return
}
