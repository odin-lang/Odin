package archive

import "base:runtime"

TEMP_SUFFIX        :: "-temp"
JOURNAL_SUFFIX     :: "-journal"
JOURNAL_MAGIC      :: "ARCJOURN"
JOURNAL_FIXED_SIZE :: 36
JOURNAL_RANGE_SIZE :: 20
JOURNAL_RANGES_MAX :: 4
JOURNAL_TAIL_MAX   :: 64 * 1024
LOCK_ATTEMPTS      :: 8

Lock_Kind :: enum u8 {
	Shared,
	Exclusive,
}

Range :: struct {
	offset: i64,
	data:   []u8,
}

Journal_Range :: struct {
	offset:   i64,
	length:   i64,
	crc:      u32,
	position: i64,
}

Journal :: struct {
	old_length:  i64,
	check_end:   i64,
	ranges:      [JOURNAL_RANGES_MAX]Journal_Range,
	range_count: int,
}

_ranges_delete :: proc(ranges: []Range, allocator: runtime.Allocator) {
	for r in ranges {
		delete(r.data, allocator)
	}
	delete(ranges, allocator)
}
