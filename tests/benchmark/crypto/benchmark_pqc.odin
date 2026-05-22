package benchmark_core_crypto

import "core:log"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto"
import "core:crypto/mldsa"
import "core:crypto/mlkem"

@(private = "file")
MLKEM_ITERS :: 50000
@(private = "file")
MLDSA_ITERS :: 10000

@(test)
benchmark_crypto_mlkem :: proc(t: ^testing.T) {
	if !crypto.HAS_RAND_BYTES {
		log.warnf("ML-KEM benchmarks skipped, no system entropy source")
		return
	}

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "ML-KEM")
	table.aligned_header_of_values(&tbl, .Right, "Parameters", "Keygen", "Encaps", "Decaps")

	append_tbl := proc(tbl: ^table.Table, algo_name: string, keygen, encaps, decaps: time.Duration) {
		table.aligned_row_of_values(
			tbl,
			.Right,
			algo_name,
			table.format(tbl, "%8M", keygen),
			table.format(tbl, "%8M", encaps),
			table.format(tbl, "%8M", decaps),
		)
	}

	for params in mlkem.Parameters {
		if params == .Invalid {
			continue
		}
		param_name := MLKEM_PARAMS_NAMES[params]

		decaps_key: mlkem.Decapsulation_Key
		start := time.tick_now()
		for _ in 0 ..< MLKEM_ITERS {
			_ = mlkem.decapsulation_key_generate(&decaps_key, params)
		}
		keygen := time.tick_since(start) / MLKEM_ITERS

		encaps_key := make([]byte, mlkem.ENCAPSULATION_KEY_SIZES[params])
		defer delete(encaps_key)
		ciphertext := make([]byte, mlkem.CIPHERTEXT_SIZES[params])
		defer delete(ciphertext)

		mlkem.decapsulation_key_encaps_bytes(&decaps_key, encaps_key)

		bob_shared: [mlkem.SHARED_SECRET_SIZE]byte
		start = time.tick_now()
		for _ in 0 ..< MLKEM_ITERS {
			_ = mlkem.encaps(params, encaps_key, bob_shared[:], ciphertext)
		}
		encaps := time.tick_since(start) / MLKEM_ITERS

		alice_shared: [mlkem.SHARED_SECRET_SIZE]byte
		start = time.tick_now()
		for _ in 0 ..< MLKEM_ITERS {
			_ = mlkem.decaps(&decaps_key, ciphertext, alice_shared[:])
		}
		decaps := time.tick_since(start) / MLKEM_ITERS

		append_tbl(&tbl, param_name, keygen, encaps, decaps)
	}

	log_table(&tbl)
}

@(test)
bench_mldsa :: proc(t: ^testing.T) {
	if !crypto.HAS_RAND_BYTES {
		log.warnf("ML-DSA benchmarks skipped, no system entropy source")
		return
	}

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "ML-DSA")
	table.aligned_header_of_values(&tbl, .Right, "Parameters", "Op", "Time")

	append_tbl := proc(tbl: ^table.Table, algo_name, op: string, t: time.Duration) {
		table.aligned_row_of_values(
			tbl,
			.Right,
			algo_name,
			op,
			table.format(tbl, "%8M", t),
		)
	}

	do_bench := proc(params: mldsa.Parameters) -> (sk, sig, verif: time.Duration) {
		// The time taken is highly seed dependent due to rejection
		// sampling using SHAKE, so we hit up the system entropy source
		// and crank up the iteration count.
		priv_key: mldsa.Private_Key
		start := time.tick_now()
		for _ in  0 ..< MLDSA_ITERS*2 {
			ok := mldsa.private_key_generate(&priv_key, params)
			assert(ok, "private key should generate")
		}
		sk = time.tick_since(start) / (MLDSA_ITERS*2)

		pub_key: mldsa.Public_Key
		mldsa.public_key_set_priv(&pub_key, &priv_key)

		msg_bytes := transmute([]byte)(SIG_MSG)
		sig_bytes := make([]byte, mldsa.SIGNATURE_SIZES[params])
		defer delete(sig_bytes)

		// FIPS defaults to hedged mode with non-deterministic signatures.
		start = time.tick_now()
		for _ in  0 ..< MLDSA_ITERS {
			ok := mldsa.sign(&priv_key, nil, msg_bytes, sig_bytes)
			assert(ok, "signature should succeed")
		}
		sig = time.tick_since(start) / MLDSA_ITERS

		start = time.tick_now()
		for _ in  0 ..< MLDSA_ITERS {
			ok := mldsa.verify(&pub_key, nil, msg_bytes, sig_bytes)
			assert(ok, "signature should validate")
		}
		verif = time.tick_since(start) / MLDSA_ITERS

		return
	}

	for params in mldsa.Parameters {
		if params == .Invalid {
			continue
		}
		param_name := MLDSA_PARAMS_NAMES[params]

		sig, sk, verif := do_bench(params)
		append_tbl(&tbl, param_name, "private_key_generate", sk)
		append_tbl(&tbl, param_name, "sign", sig)
		append_tbl(&tbl, param_name, "verify", verif)

		if params != .ML_DSA_87 {
			table.row(&tbl)
		}
	}

	log_table(&tbl)
}

@(private="file")
MLKEM_PARAMS_NAMES := [mlkem.Parameters]string {
	.Invalid = "invalid",
	.ML_KEM_512 = "ML-KEM-512",
	.ML_KEM_768 = "ML-KEM-768",
	.ML_KEM_1024 = "ML-KEM-1024",
}

@(private="file")
MLDSA_PARAMS_NAMES := [mldsa.Parameters]string {
	.Invalid = "invalid",
	.ML_DSA_44 = "ML-DSA-44",
	.ML_DSA_65 = "ML-DSA-65",
	.ML_DSA_87 = "ML-DSA-87",
}
