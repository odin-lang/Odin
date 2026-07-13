package benchmark_core_crypto

import "base:runtime"
import "core:log"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto"
import "core:crypto/rsa"

// RSA key generation is time consuming and high variance, so it takes
// an unreasonable amount of time to get a semi-sensible value, so this
// is skipped by default.
RSA_BENCH_KEYGEN: bool : #config(ODIN_BENCHMARK_RSA_KEYGEN, false)

@(private = "file")
KEYGEN_ITERS :: 100
@(private = "file")
SIGN_ITERS :: 5000
@(private = "file")
ENCRYPT_ITERS :: 5000

@(test)
benchmark_crypto_rsa :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "RSA")
	table.aligned_header_of_values(&tbl, .Right, "Operation", "Avg. Time")

	if RSA_BENCH_KEYGEN {
		bench_keygen_2048(&tbl)
		table.row_of_values(&tbl)
	}
	bench_pkcs1_2048(&tbl)
	table.row_of_values(&tbl)
	bench_pss_2048(&tbl)
	table.row_of_values(&tbl)
	bench_oaep_2048(&tbl)

	log_table(&tbl)
}

@(private="file")
bench_keygen_2048 :: proc(tbl: ^table.Table) {
	if !crypto.HAS_RAND_BYTES {
		log.warnf("rsa: keygen benchmarks skipped, no system entropy source")
	}

	priv_key: rsa.Private_Key
	start := time.tick_now()
	for _ in 0 ..< KEYGEN_ITERS {
		ok := rsa.private_key_generate(&priv_key, 2048)
		assert(ok, "keygen should succeed")
	}
	taken := time.tick_since(start) / KEYGEN_ITERS

	append_tbl(tbl, "Keygen/2048", taken)
}

@(private="file")
bench_pkcs1_2048 :: proc(tbl: ^table.Table) {
	priv_key: rsa.Private_Key
	_ = rsa.private_key_set_insecure_test(&priv_key)

	msg_bytes := transmute([]byte)(SIG_MSG)
	sig_bytes: [2048 >> 3]byte

	start := time.tick_now()
	for _ in 0 ..< SIGN_ITERS {
		ok := rsa.sign_pkcs1(&priv_key, .SHA256, msg_bytes, sig_bytes[:])
		assert(ok, "signing should succeed")
	}
	taken := time.tick_since(start) / SIGN_ITERS

	append_tbl(tbl, "PKCS1/2048/SHA256/sign", taken)

	start = time.tick_now()
	for _ in 0 ..< KEYGEN_ITERS {
		ok := rsa.verify_pkcs1(&priv_key._pub_key, .SHA256, msg_bytes, sig_bytes[:])
		assert(ok, "verify should succeed")
	}
	taken = time.tick_since(start) / SIGN_ITERS

	append_tbl(tbl, "PKCS1/2048/SHA256/verify", taken)
}

@(private="file")
bench_pss_2048 :: proc(tbl: ^table.Table) {
	priv_key: rsa.Private_Key
	_ = rsa.private_key_set_insecure_test(&priv_key)

	msg_bytes := transmute([]byte)(SIG_MSG)
	sig_bytes: [2048 >> 3]byte

	start := time.tick_now()
	for _ in 0 ..< SIGN_ITERS {
		ok := rsa.sign_pss(&priv_key, .SHA256, 32, msg_bytes, sig_bytes[:])
		assert(ok, "signing should succeed")
	}
	taken := time.tick_since(start) / SIGN_ITERS

	append_tbl(tbl, "PSS/2048/SHA256/sign", taken)

	start = time.tick_now()
	for _ in 0 ..< KEYGEN_ITERS {
		ok := rsa.verify_pss(&priv_key._pub_key, .SHA256, 32, msg_bytes, sig_bytes[:])
		assert(ok, "verify should succeed")
	}
	taken = time.tick_since(start) / SIGN_ITERS

	append_tbl(tbl, "PSS/2048/SHA256/verify", taken)
}

@(private="file")
bench_oaep_2048 :: proc(tbl: ^table.Table) {
	if !crypto.HAS_RAND_BYTES {
		log.info("rand_bytes not supported - skipping")
		return
	}

	priv_key: rsa.Private_Key
	_ = rsa.private_key_set_insecure_test(&priv_key)

	msg_bytes := transmute([]byte)(SIG_MSG)
	ciphertext_bytes: [2048 >> 3]byte
	buf: [32]byte

	start := time.tick_now()
	for _ in 0 ..< SIGN_ITERS {
		ok := rsa.encrypt_oaep(&priv_key._pub_key, .SHA256, msg_bytes, ciphertext_bytes[:])
		assert(ok, "encryption should succeed")
	}
	taken := time.tick_since(start) / ENCRYPT_ITERS

	append_tbl(tbl, "OAEP/2048/SHA256/encrypt", taken)

	start = time.tick_now()
	for _ in 0 ..< KEYGEN_ITERS {
		_, ok := rsa.decrypt_oaep(&priv_key, .SHA256, ciphertext_bytes[:], buf[:])
		assert(ok, "decrypt should succeed")
	}
	taken = time.tick_since(start) / ENCRYPT_ITERS

	append_tbl(tbl, "OAEP/2048/SHA256/decrypt", taken)
}

@(private="file")
append_tbl :: proc(tbl: ^table.Table, op_name: string, avg_time: time.Duration) {
	table.aligned_row_of_values(
		tbl,
		.Right,
		op_name,
		table.format(tbl, "%8M", avg_time),
	)
}
