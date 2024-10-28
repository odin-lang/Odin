package benchmark_core_crypto

import "base:runtime"
import "core:crypto"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto/aead"

@(private = "file")
ITERS :: 10000
@(private = "file")
SIZES := []int{64, 1024, 65536}

@(test)
benchmark_crypto_aead :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "AEAD")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Time", "Throughput")

	for algo, i in aead.Algorithm {
		if algo == .Invalid {
			continue
		}
		if i > 1 {
			table.row(&tbl)
		}

		algo_name := aead.ALGORITHM_NAMES[algo]
		key_sz := aead.KEY_SIZES[algo]

		key := make([]byte, key_sz, context.temp_allocator)
		crypto.rand_bytes(key)

		// TODO: Benchmark all available imlementations?
		ctx: aead.Context
		aead.init(&ctx, algo, key)

		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = aead.IV_SIZES[algo] + sz,
				setup = setup_sized_buf,
				bench = do_bench_aead,
				teardown = teardown_sized_buf,
			}
			context.user_ptr = &ctx

			err := time.benchmark(options, context.allocator)
			testing.expect(t, err == nil)

			time_per_iter := options.duration / ITERS
			table.aligned_row_of_values(
				&tbl,
				.Right,
				algo_name,
				table.format(&tbl, "%d", sz),
				table.format(&tbl, "%8M", time_per_iter),
				table.format(&tbl, "%5.3f MiB/s", options.megabytes_per_second),
			)
		}
	}

	log_table(&tbl)
}

@(private = "file")
do_bench_aead :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	tag_: [aead.MAX_TAG_SIZE]byte

	ctx := (^aead.Context)(context.user_ptr)
	iv_sz := aead.iv_size(ctx)

	iv := options.input[:iv_sz]
	buf := options.input[iv_sz:]
	tag := tag_[:aead.tag_size(ctx)]

	for _ in 0 ..= options.rounds {
		aead.seal_ctx(ctx, buf, tag, iv, nil, buf)
	}
	options.count = options.rounds
	options.processed = options.rounds * (options.bytes - iv_sz)

	return
}
