package benchmark_core_text_regex

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:mem"
import "core:testing"
import "core:text/regex"
import "core:time"
import "core:unicode/utf8"

randomize_ascii :: proc(data: []u8) {
	for i in 0..<len(data) {
		data[i] = ' ' + cast(u8)rand.int_max(0x7F - ' ')
	}
}

randomize_unicode :: proc(data: []u8) {
	for i := 0; i < len(data); /**/ {
		check_rune_loop: for {
			r := cast(rune)rand.int_max(utf8.MAX_RUNE)
			if !utf8.valid_rune(r) {
				continue
			}
			if utf8.rune_size(r) > len(data) - i {
				continue
			}

			r_data, size := utf8.encode_rune(r)
			for j in 0..<size {
				data[i+j] = r_data[j]
			}

			i += size
			break check_rune_loop
		}
	}
}

sizes := [?]int {
	2 * mem.Kilobyte,
	32 * mem.Kilobyte,
	64 * mem.Kilobyte,
	256 * mem.Kilobyte,
	0.50 * mem.Megabyte,
	1.00 * mem.Megabyte,
	2.00 * mem.Megabyte,
}

@test
expensive_for_backtrackers :: proc(t: ^testing.T) {
	counts := [?]int {
		8,
		16,
		32,
		64,
	}

	report: string

	for count in counts {
		data := make([]u8, count)
		pattern := make([]u8, 2 * count + count)
		defer {
			delete(data)
			delete(pattern)
		}
		for i in 0..<2 * count {
			pattern[i] = 'a' if i & 1 == 0 else '?'
		}
		for i in 2 * count..<2 * count + count {
			pattern[i] = 'a'
		}
		for i in 0..<count {
			data[i] = 'a'
		}

		rex, err := regex.create(cast(string)pattern)
		if !testing.expect_value(t, err, nil) {
			return
		}
		defer regex.destroy(rex)

		str := cast(string)data

		log.debug(rex, str)

		start := time.now()
		capture, ok := regex.match(rex, str)
		done := time.since(start)
		defer regex.destroy(capture)

		if !testing.expect_value(t, ok, true) {
			continue
		}
		testing.expect_value(t, capture.pos[0], [2]int{0, count})

		rate := cast(int)(cast(f64)(count / 2) / (cast(f64)done / 1e9))
		report = fmt.tprintf("%s\n        +++ [%i : %v : %M/s] Matched `a?^%ia^%i` against `a^%i`.", report, count, done, rate, count, count, count)
	}
	log.info(report)
}

@test
global_capture_end_word :: proc(t: ^testing.T) {
	EXPR :: `Hellope World!`

	rex, err := regex.create(EXPR, { .Global })
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer regex.destroy(rex)

	report := fmt.tprintf("Matching %q over a block of random ASCII text.", EXPR)

	for size in sizes {
		data := make([]u8, size)
		defer delete(data)
		randomize_ascii(data[:])

		for r, i in EXPR {
			data[len(data) - len(EXPR) + i] = cast(u8)r
		}

		str := cast(string)data

		start := time.now()
		capture, ok := regex.match(rex, str)
		done := time.since(start)
		defer regex.destroy(capture)

		if !testing.expect_value(t, ok, true) {
			continue
		}
		testing.expect_value(t, capture.pos[0], [2]int{size - len(EXPR), size})

		rate := cast(int)(cast(f64)size / (cast(f64)done / 1e9))
		report = fmt.tprintf("%s\n        +++ [%M : %v : %M/s]", report, size, done, rate)
	}
	log.info(report)
}

@test
global_capture_end_word_unicode :: proc(t: ^testing.T) {
	EXPR :: `こにちは`
	needle := string(EXPR)

	rex, err := regex.create(EXPR, { .Global, .Unicode })
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer regex.destroy(rex)

	report := fmt.tprintf("Matching %q over a block of random Unicode text.", EXPR)

	for size in sizes {
		data := make([]u8, size)
		defer delete(data)
		randomize_unicode(data[:size - len(needle)])

		for i := 0; i < len(needle); i += 1 {
			data[len(data) - len(needle) + i] = needle[i]
		}

		str := cast(string)data

		start := time.now()
		capture, ok := regex.match(rex, str)
		done := time.since(start)
		defer regex.destroy(capture)

		if !testing.expect_value(t, ok, true) {
			continue
		}
		testing.expect_value(t, capture.groups[0], needle)

		rate := cast(int)(cast(f64)size / (cast(f64)done / 1e9))
		report = fmt.tprintf("%s\n        +++ [%M : %v : %M/s]", report, size, done, rate)
	}
	log.info(report)
}


@test
alternations :: proc(t: ^testing.T) {
	EXPR :: `a(?:bb|cc|dd|ee|ff)`

	rex, err := regex.create(EXPR, { .No_Capture, .Global })
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer regex.destroy(rex)

	report := fmt.tprintf("Matching %q over a text block of only `a`s.", EXPR)

	for size in sizes {
		data := make([]u8, size)
		defer delete(data)
		for i in 0..<size {
			data[i] = 'a'
		}

		str := cast(string)data

		start := time.now()
		_, ok := regex.match(rex, str)
		done := time.since(start)

		testing.expect_value(t, ok, false)

		rate := cast(int)(cast(f64)size / (cast(f64)done / 1e9))
		report = fmt.tprintf("%s\n        +++ [%M : %v : %M/s]", report, size, done, rate)
	}
	log.info(report)
}

@test
classes :: proc(t: ^testing.T) {
	EXPR :: `[\w\d]+`
	NEEDLE :: "0123456789abcdef"

	rex, err := regex.create(EXPR, { .Global })
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer regex.destroy(rex)

	report := fmt.tprintf("Matching %q over a string of spaces with %q at the end.", EXPR, NEEDLE)

	for size in sizes {
		data := make([]u8, size)
		defer delete(data)

		for i in 0..<size {
			data[i] = ' '
		}

		for r, i in NEEDLE {
			data[len(data) - len(NEEDLE) + i] = cast(u8)r
		}

		str := cast(string)data

		start := time.now()
		capture, ok := regex.match(rex, str)
		done := time.since(start)
		defer regex.destroy(capture)

		if !testing.expect_value(t, ok, true) {
			continue
		}
		testing.expect_value(t, capture.pos[0], [2]int{size - len(NEEDLE), size})

		rate := cast(int)(cast(f64)size / (cast(f64)done / 1e9))
		report = fmt.tprintf("%s\n        +++ [%M : %v : %M/s]", report, size, done, rate)
	}
	log.info(report)
}
