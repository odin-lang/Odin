package benchmark_core_crypto

import "core:crypto"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:text/table"
import "core:time"

@(private)
log_table :: #force_inline proc(tbl: ^table.Table) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	wr := strings.to_writer(&sb)

	fmt.sbprintln(&sb)
	table.write_plain_table(wr, tbl)

	log.info(strings.to_string(sb))
}

@(private)
setup_sized_buf :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	assert(options != nil)

	options.input = make([]u8, options.bytes, allocator)
	if len(options.input) > 0 {
		crypto.rand_bytes(options.input)
	}
	return nil if len(options.input) == options.bytes else .Allocation_Error
}

@(private)
teardown_sized_buf :: proc(
	options: ^time.Benchmark_Options,
	allocator := context.allocator,
) -> (
	err: time.Benchmark_Error,
) {
	assert(options != nil)

	delete(options.input)
	return nil
}
