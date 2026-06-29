package benchmark_core_math

import "base:runtime"

import "core:fmt"
import "core:math/rand"
import "core:log"
import "core:strings"
import "core:testing"
import "core:text/table"
import "core:time"

@(private = "file")
ITERS :: 10000000
@(private = "file")
ITERS_BULK :: 1000

@(private = "file")
SAMPLE_SEED : string : "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"

@(test)
benchmark_rng :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)

	table.caption(&tbl, "RNG")
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Size", "Time", "Throughput")

	context.random_generator = rand.default_random_generator()
	rand.reset_bytes(transmute([]byte)(SAMPLE_SEED))
	_benchmark_u64(t, &tbl, "chacha8rand")
	_benchmark_large(t, &tbl, "chacha8rand")

	table.row(&tbl)

	context.random_generator = rand.pcg_random_generator()
	_benchmark_u64(t, &tbl, "pcg64")
	_benchmark_large(t, &tbl, "pcg64")
	
	table.row(&tbl)

	context.random_generator = rand.xoshiro256_random_generator()
	_benchmark_u64(t, &tbl, "xorshiro256**")
	_benchmark_large(t, &tbl, "xorshiro256**")

	log_table(&tbl)
}

@(private = "file")
_benchmark_u64 :: proc(t: ^testing.T, tbl: ^table.Table, algo_name: string) {
	options := &time.Benchmark_Options{
		rounds = ITERS,
		bytes = 8,
		setup = nil,
		bench = proc(options: ^time.Benchmark_Options, allocator: runtime.Allocator) -> (err: time.Benchmark_Error){
			sum: u64
			for _ in 0 ..= options.rounds {
				sum += rand.uint64()
			}
			options.hash = u128(sum)
			options.count = options.rounds
			options.processed = options.rounds * options.bytes
			return
		},
		teardown = nil,
	}

	err := time.benchmark(options, context.allocator)
	testing.expect(t, err == nil)

	time_per_iter := options.duration / ITERS
	table.aligned_row_of_values(
		tbl,
		.Right,
		algo_name,
		table.format(tbl, "uint64"),
		table.format(tbl, "%8M", time_per_iter),
		table.format(tbl, "%5.3f MiB/s", options.megabytes_per_second),
	)
}

@(private = "file")
_benchmark_large :: proc(t: ^testing.T, tbl: ^table.Table, algo_name: string) {
	options := &time.Benchmark_Options{
		rounds = ITERS_BULK,
		bytes = 1024768,
		setup = nil,
		bench = proc(options: ^time.Benchmark_Options, allocator: runtime.Allocator) -> (err: time.Benchmark_Error){
			n: int
			for _ in 0 ..= options.rounds {
				n += rand.read(options.output)
			}
			options.hash = u128(n)
			options.count = options.rounds
			options.processed = options.rounds * options.bytes
			return
		},
		output = make([]byte, 1024768, context.temp_allocator),
		teardown = nil,
	}

	err := time.benchmark(options, context.allocator)
	testing.expect(t, err == nil)

	time_per_iter := options.duration / ITERS_BULK
	table.aligned_row_of_values(
		tbl,
		.Right,
		algo_name,
		table.format(tbl, "1 MiB"),
		table.format(tbl, "%8M", time_per_iter),
		table.format(tbl, "%5.3f MiB/s", options.megabytes_per_second),
	)
}

@(private)
log_table :: proc(tbl: ^table.Table) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	wr := strings.to_writer(&sb)

	fmt.sbprintln(&sb)
	table.write_plain_table(wr, tbl)

	log.info(strings.to_string(sb))
}
