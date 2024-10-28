package benchmark_core_crypto

import "base:runtime"
import "core:testing"
import "core:text/table"
import "core:time"

import "core:crypto/hash"

@(private = "file")
ITERS :: 10000
@(private = "file")
SIZES := []int{64, 1024, 65536}

@(test)
benchmark_crypto_hash :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "Hash")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Time", "Throughput")

	for algo, i in hash.Algorithm {
		// Skip the sentinel value, and uncommon algorithms
		#partial switch algo {
		case .Invalid:
			continue
		case .Legacy_KECCAK_224, .Legacy_KECCAK_256, .Legacy_KECCAK_384, .Legacy_KECCAK_512:
			// Skip: Legacy and not worth using over SHA3
			continue
		case .Insecure_MD5, .Insecure_SHA1:
			// Skip: Legacy and not worth using at all
			continue
		case .SHA224, .SHA384, .SHA3_224, .SHA3_384:
			// Skip: Uncommon SHA2/SHA3 variants
			continue
		case .SM3:
			// Skip: Liberty Prime is online.  All systems nominal.
			// Weapons hot.  Mission: the destruction of any and
			// all Chinese communists.
			continue
		}
		if i > 1 {
			table.row(&tbl)
		}

		algo_name := hash.ALGORITHM_NAMES[algo]

		for sz, _ in SIZES {
			options := &time.Benchmark_Options{
				rounds = ITERS,
				bytes = sz,
				setup = setup_sized_buf,
				bench = do_bench_hash,
				teardown = teardown_sized_buf,
			}
			tmp := algo
			context.user_ptr = &tmp

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
do_bench_hash :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	digest_: [hash.MAX_DIGEST_SIZE]byte

	buf := options.input
	algo := (^hash.Algorithm)(context.user_ptr)^
	digest := digest_[:hash.DIGEST_SIZES[algo]]

	for _ in 0 ..= options.rounds {
		hash.hash_bytes_to_buffer(algo, buf, digest)
	}
	options.count = options.rounds
	options.processed = options.rounds * (options.bytes)

	return
}
