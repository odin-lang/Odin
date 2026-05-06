package benchmark_core_crypto

import "core:log"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto"
import "core:crypto/mlkem"

@(private = "file")
MLKEM_ITERS :: 50000

@(test)
benchmark_crypto_mlkem :: proc(t: ^testing.T) {
	if !crypto.HAS_RAND_BYTES {
		log.warnf("ML-KEM benchmarks skipped, no system entropy source")
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

@(private="file")
MLKEM_PARAMS_NAMES := [mlkem.Parameters]string {
	.Invalid = "invalid",
	.ML_KEM_512 = "ML-KEM-512",
	.ML_KEM_768 = "ML-KEM-768",
	.ML_KEM_1024 = "ML-KEM-1024",
}
