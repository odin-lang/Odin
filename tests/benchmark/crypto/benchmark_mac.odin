package benchmark_core_crypto

import "base:runtime"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto/hmac"
import "core:crypto/kmac"
import "core:crypto/poly1305"

@(private = "file")
ITERS :: 10000
@(private = "file")
SIZES := []int{64, 1024, 65536}
@(private = "file")
KMAC_KEY_SIZES := []int{128, 256}

@(test)
benchmark_crypto_mac :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "MAC")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Time", "Throughput")

	{
		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = sz,
				setup = setup_sized_buf,
				bench = do_bench_hmac_sha_256,
				teardown = teardown_sized_buf,
			}

			err := time.benchmark(options, context.allocator)
			testing.expect(t, err == nil)

			time_per_iter := options.duration / ITERS
			table.aligned_row_of_values(
				&tbl,
				.Right,
				"HMAC-SHA256",
				table.format(&tbl, "%d", sz),
				table.format(&tbl, "%8M", time_per_iter),
				table.format(&tbl, "%5.3f MiB/s", options.megabytes_per_second),
			)
		}
	}

	table.row(&tbl)

	for key_sz, i in KMAC_KEY_SIZES {
		if i > 0 {
			table.row(&tbl)
		}

		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = sz,
				processed = key_sz, // Pls ignore.
				setup = setup_sized_buf,
				bench = do_bench_kmac,
				teardown = teardown_sized_buf,
			}

			err := time.benchmark(options, context.allocator)
			testing.expect(t, err == nil)

			time_per_iter := options.duration / ITERS
			table.aligned_row_of_values(
				&tbl,
				.Right,
				table.format(&tbl, "KMAC%d", key_sz),
				table.format(&tbl, "%d", sz),
				table.format(&tbl, "%8M", time_per_iter),
				table.format(&tbl, "%5.3f MiB/s", options.megabytes_per_second),
			)
		}
	}

	table.row(&tbl)

	{
		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = sz,
				setup = setup_sized_buf,
				bench = do_bench_poly1305,
				teardown = teardown_sized_buf,
			}

			err := time.benchmark(options, context.allocator)
			testing.expect(t, err == nil)

			time_per_iter := options.duration / ITERS
			table.aligned_row_of_values(
				&tbl,
				.Right,
				"poly1305",
				table.format(&tbl, "%d", sz),
				table.format(&tbl, "%8M", time_per_iter),
				table.format(&tbl, "%5.3f MiB/s", options.megabytes_per_second),
			)
		}
	}

	log_table(&tbl)
}

@(private = "file")
do_bench_hmac_sha_256 :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	key := [32]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}

	tag: [32]byte = ---
	for _ in 0 ..= options.rounds {
		hmac.sum(.SHA256, tag[:], buf, key[:])
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes

	return
}

@(private = "file")
do_bench_kmac :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	buf := options.input
	key := [kmac.MIN_KEY_SIZE_256]byte {
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
		0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef,
	}
	sec_strength := options.processed

	tag: [32]byte = ---
	for _ in 0 ..= options.rounds {
		kmac.sum(sec_strength, tag[:sec_strength/8], buf, key[:], nil)
	}
	options.count = options.rounds
	options.processed = options.rounds * options.bytes

	return
}

@(private = "file")
do_bench_poly1305 :: proc(
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

	return
}
