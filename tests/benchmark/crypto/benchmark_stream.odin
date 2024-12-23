package benchmark_core_crypto

import "base:runtime"
import "core:crypto"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto/aes"
import "core:crypto/chacha20"

@(private = "file")
ITERS :: 10000
@(private = "file")
SIZES := []int{64, 1024, 65536}
@(private = "file")
AES_CTR_KEY_SIZES := []int{128, 192, 256}

@(test)
benchmark_crypto_stream :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "Stream Cipher")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Time", "Throughput")

	for key_sz, i in AES_CTR_KEY_SIZES {
		if i > 0 {
			table.row(&tbl)
		}

		key := make([]byte, key_sz/8, context.temp_allocator)
		iv := make([]byte, aes.CTR_IV_SIZE, context.temp_allocator)
		crypto.rand_bytes(key)
		crypto.rand_bytes(iv)

		ctx: aes.Context_CTR
		aes.init_ctr(&ctx, key, iv)

		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = sz,
				setup = setup_sized_buf,
				bench = do_bench_aes_ctr,
				teardown = teardown_sized_buf,
			}
			context.user_ptr = &ctx

			err := time.benchmark(options, context.allocator)
			testing.expect(t, err == nil)

			time_per_iter := options.duration / ITERS
			table.aligned_row_of_values(
				&tbl,
				.Right,
				table.format(&tbl, "AES%d-CTR", key_sz),
				table.format(&tbl, "%d", sz),
				table.format(&tbl, "%8M", time_per_iter),
				table.format(&tbl, "%5.3f MiB/s", options.megabytes_per_second),
			)
		}
	}

	table.row(&tbl)

	{
		key := make([]byte, chacha20.KEY_SIZE, context.temp_allocator)
		iv := make([]byte, chacha20.IV_SIZE, context.temp_allocator)
		crypto.rand_bytes(key)
		crypto.rand_bytes(iv)

		ctx: chacha20.Context
		chacha20.init(&ctx, key, iv)

		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = sz,
				setup = setup_sized_buf,
				bench = do_bench_chacha20,
				teardown = teardown_sized_buf,
			}
			context.user_ptr = &ctx

			err := time.benchmark(options, context.allocator)
			testing.expect(t, err == nil)

			time_per_iter := options.duration / ITERS
			table.aligned_row_of_values(
				&tbl,
				.Right,
				"chacha20",
				table.format(&tbl, "%d", sz),
				table.format(&tbl, "%8M", time_per_iter),
				table.format(&tbl, "%5.3f MiB/s", options.megabytes_per_second),
			)
		}
	}

	log_table(&tbl)
}

@(private = "file")
do_bench_aes_ctr :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	ctx := (^aes.Context_CTR)(context.user_ptr)

	buf := options.input

	for _ in 0 ..= options.rounds {
		aes.xor_bytes_ctr(ctx, buf, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes

	return
}

@(private = "file")
do_bench_chacha20 :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	ctx := (^chacha20.Context)(context.user_ptr)

	buf := options.input

	for _ in 0 ..= options.rounds {
		chacha20.xor_bytes(ctx, buf, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes

	return
}
