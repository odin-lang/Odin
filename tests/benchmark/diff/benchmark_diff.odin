package benchmark_core_diff

import "core:diff"
import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:strings"
import "core:testing"
import "core:text/table"
import "core:time"

// Each diff is timed this many times, and the fastest run is reported.
RUNS :: 3

@(rodata)
VARIANTS := [?]diff.Options{
	{algorithm = .Myers},
	{algorithm = .Myers,              flags = {.Prune}},
	{algorithm = .Minimal},
	{algorithm = .Histogram},
	{algorithm = .Histogram,          flags = {.Prune}},
	{algorithm = .Ratcliff_Obershelp},
	{algorithm = .Ratcliff_Obershelp, flags = {.Prune}},
	{algorithm = .Myers,              flags = {.Prune, .Compact}},                    // as git --no-indent-heuristic
	{algorithm = .Histogram,          flags = {.Compact}},                            // as git --histogram --no-indent-heuristic
	{algorithm = .Myers,              flags = {.Prune, .Compact, .Indent_Heuristic}}, // as plain git diff, for lines only
}

// Short and common, meaning lines made of them repeat a lot.
@(rodata)
CODE_WORDS := [?]string{"if", "for", "x", "y", "return", "count", "}", "{", "\t", "// note", "foo(bar)", "Value"}

// Enough words for prose to read as text, with plenty repeated.
@(rodata)
PROSE_WORDS := [?]string{
	"the", "a", "of", "and", "to", "in", "is", "that", "it", "was", "for", "on", "are", "with", "as", "they",
	"be", "at", "one", "have", "this", "from", "by", "hot", "word", "but", "what", "some", "we", "can", "out",
	"other", "were", "all", "there", "when", "up", "use", "your", "how", "said", "an", "each", "she", "which",
	"do", "their", "time", "if", "will", "way", "about", "many", "then", "them", "write", "would", "like", "so",
}

Scenario :: struct {
	name:  string,
	a, b:  string,
	token: diff.Token,
}

// Lines that are nearly all different from each other, like most source code.
unique_line :: proc(sb: ^strings.Builder) {
	fmt.sbprintf(sb, "\tvalue_%d := compute(%d, %d)\n", rand.int_max(1_000_000), rand.int_max(1000), rand.int_max(1000))
}

// Lines made of a few common words, which repeat many times over.
repetitive_line :: proc(sb: ^strings.Builder) {
	for _ in 0..<1 + rand.int_max(4) {
		strings.write_string(sb, CODE_WORDS[rand.int_max(len(CODE_WORDS))])
		strings.write_byte(sb, ' ')
	}
	strings.write_byte(sb, '\n')
}

// Two texts of `lines` lines, where about one line in `every` is replaced, inserted or removed.
edited_lines :: proc(lines, every: int, make_line: proc(sb: ^strings.Builder)) -> (a, b: string) {
	sa := strings.builder_make(context.temp_allocator)
	sb := strings.builder_make(context.temp_allocator)
	for _ in 0..<lines {
		start := len(sa.buf)
		make_line(&sa)
		line := string(sa.buf[start:])

		if rand.int_max(every) != 0 {
			strings.write_string(&sb, line)
			continue
		}
		switch rand.int_max(3) {
		case 0: // replaced
			make_line(&sb)
		case 1: // inserted before
			make_line(&sb)
			strings.write_string(&sb, line)
		case 2: // removed
		}
	}
	return strings.to_string(sa), strings.to_string(sb)
}

prose :: proc(sb: ^strings.Builder, words: int) {
	for k in 0..<words {
		strings.write_string(sb, PROSE_WORDS[rand.int_max(len(PROSE_WORDS))])
		strings.write_byte(sb, k % 12 == 11 ? '\n' : ' ')
	}
}

// Prose with about one word in `every` changed.
edited_prose :: proc(words, every: int) -> (a, b: string) {
	sa := strings.builder_make(context.temp_allocator)
	prose(&sa, words)
	a = strings.to_string(sa)

	sb := strings.builder_make(context.temp_allocator)
	for word in strings.split_after(a, " ", context.temp_allocator) {
		if rand.int_max(every) == 0 {
			strings.write_string(&sb, PROSE_WORDS[rand.int_max(len(PROSE_WORDS))])
			strings.write_byte(&sb, ' ')
		} else {
			strings.write_string(&sb, word)
		}
	}
	return a, strings.to_string(sb)
}

lines_scenario :: proc(name: string, lines, every: int, make_line: proc(sb: ^strings.Builder)) -> (sc: Scenario) {
	sc.name, sc.token = name, .Line
	sc.a, sc.b = edited_lines(lines, every, make_line)
	return
}

// Two texts of unique lines made separately, meaning they have nothing in common.
unrelated_scenario :: proc(name: string, lines: int) -> (sc: Scenario) {
	sc.name, sc.token = name, .Line
	sc.a, _ = edited_lines(lines, 1, unique_line)
	sc.b, _ = edited_lines(lines, 1, unique_line)
	return
}

prose_scenario :: proc(name: string, words, every: int, token: diff.Token) -> (sc: Scenario) {
	sc.name, sc.token = name, token
	sc.a, sc.b = edited_prose(words, every)
	return
}

// Times `opts` on `sc`, returning the fastest of `RUNS`, how many tokens changed, and the scratch it needed.
time_diff :: proc(sc: Scenario, opts: diff.Options) -> (fastest: time.Duration, changed, scratch: int) {
	for run in 0..<RUNS {
		watch: time.Stopwatch
		time.stopwatch_start(&watch)
		d, err := diff.diff_text(sc.a, sc.b, context.allocator, context.allocator, token = sc.token, opts = opts)
		time.stopwatch_stop(&watch)
		assert(err == nil)

		elapsed := time.stopwatch_duration(watch)
		if run == 0 || elapsed < fastest {
			fastest = elapsed
		}
		s := diff.stats(d.changes)
		changed = s.deleted + s.inserted
		scratch = diff.scratch_size_text(d.changes.n, d.changes.m, opts)
		diff.text_diff_destroy(d, context.allocator)
	}
	return
}

// The flags as a short list, empty for none.
flags_name :: proc(flags: diff.Option_Flags) -> string {
	sb := strings.builder_make(context.temp_allocator)
	for flag in flags {
		if len(sb.buf) > 0 {
			strings.write_string(&sb, ", ")
		}
		fmt.sbprint(&sb, flag)
	}
	return strings.to_string(sb)
}

report :: proc(title: string, tbl: ^table.Table) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	fmt.sbprintln(&sb, title)
	table.write_plain_table(strings.to_writer(&sb), tbl)
	log.info(strings.to_string(sb))
}

@test
benchmark_algorithms :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	scenarios := [?]Scenario{
		lines_scenario("lines, unique, 0.5% edited",     100_000, 200, unique_line),
		lines_scenario("lines, repetitive, 0.5% edited", 100_000, 200, repetitive_line),
		lines_scenario("lines, unique, 10% edited",       20_000,  10, unique_line),
		unrelated_scenario("lines, nothing in common",     5_000),
		prose_scenario("words, prose, 2% edited",         50_000,  50, .Word),
		prose_scenario("runes, prose, 2% edited",          5_000,  50, .Rune),
	}

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)
	table.aligned_header_of_values(&tbl, .Right, "Input", "Tokens", "Algorithm", "Flags", "Fastest", "Changed", "Scratch")

	for sc in scenarios {
		tokens := diff.token_count(sc.a, sc.token) + diff.token_count(sc.b, sc.token)
		for opts in VARIANTS {
			if .Indent_Heuristic in opts.flags && sc.token != .Line {
				continue // only lines have indentation
			}
			fastest, changed, scratch := time_diff(sc, opts)
			table.aligned_row_of_values(&tbl, .Right,
				sc.name,
				tokens,
				opts.algorithm,
				flags_name(opts.flags),
				fmt.tprintf("%v", fastest),
				changed,
				fmt.tprintf("%.1f MB", f64(scratch) / 1e6),
			)
		}
	}
	report("core:diff algorithms, the fastest of 3 runs each", &tbl)
}

@test
benchmark_generic :: proc(t: ^testing.T) {
	rand.reset(t.seed)

	n := 1_000_000
	a := make([]int, n)
	defer delete(a)
	for &x in a {
		x = rand.int_max(100_000)
	}
	b := make([dynamic]int, 0, n + 1_000)
	defer delete(b)
	append(&b, ..a)
	for _ in 0..<1_000 {
		switch rand.int_max(3) {
		case 0: inject_at(&b, rand.int_max(len(b) + 1), rand.int_max(100_000))
		case 1: ordered_remove(&b, rand.int_max(len(b)))
		case 2: b[rand.int_max(len(b))] = rand.int_max(100_000)
		}
	}

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)
	table.aligned_header_of_values(&tbl, .Right, "Algorithm", "Flags", "Fastest", "Changed", "Scratch")

	for opts in VARIANTS {
		switch {
		case opts.algorithm == .Ratcliff_Obershelp:
			continue // random integers repeat too often for it to be worth timing
		case .Indent_Heuristic in opts.flags:
			continue // only text has indentation
		}

		fastest: time.Duration
		changed: int
		for run in 0..<RUNS {
			watch: time.Stopwatch
			time.stopwatch_start(&watch)
			c, err := diff.diff(a, b[:], context.allocator, context.allocator, opts = opts)
			time.stopwatch_stop(&watch)
			assert(err == nil)

			elapsed := time.stopwatch_duration(watch)
			if run == 0 || elapsed < fastest {
				fastest = elapsed
			}
			s := diff.stats(c)
			changed = s.deleted + s.inserted
			diff.changes_destroy(c, context.allocator)
		}
		table.aligned_row_of_values(&tbl, .Right,
			opts.algorithm,
			flags_name(opts.flags),
			fmt.tprintf("%v", fastest),
			changed,
			fmt.tprintf("%.1f MB", f64(diff.scratch_size(len(a), len(b), opts)) / 1e6),
		)
	}
	report("core:diff over 1M random ints with 1,000 edits, the fastest of 3 runs each", &tbl)
}

@test
benchmark_unified :: proc(t: ^testing.T) {
	rand.reset(t.seed)
	a, b := edited_lines(100_000, 200, unique_line)

	d, err := diff.diff_text(a, b, context.allocator, context.allocator)
	assert(err == nil)
	defer diff.text_diff_destroy(d, context.allocator)

	tbl: table.Table
	table.init(&tbl)
	defer table.destroy(&tbl)
	table.aligned_header_of_values(&tbl, .Right, "Output", "Fastest", "Bytes")

	for emphasis in diff.Emphasis {
		scratch := make([]byte, diff.emphasis_scratch_size(d, emphasis))
		defer delete(scratch)

		for sizing in diff.Sizing {
			fastest: time.Duration
			size: int
			for run in 0..<RUNS {
				watch: time.Stopwatch
				time.stopwatch_start(&watch)
				s, s_err := diff.unified(d, context.allocator, style = diff.STYLE_ANSI, emphasis = emphasis, scratch = scratch, sizing = sizing)
				time.stopwatch_stop(&watch)
				assert(s_err == nil)

				elapsed := time.stopwatch_duration(watch)
				if run == 0 || elapsed < fastest {
					fastest = elapsed
				}
				size = len(s)
				delete(s)
			}
			table.aligned_row_of_values(&tbl, .Right,
				fmt.tprintf("unified, STYLE_ANSI, %v, %v", emphasis, sizing),
				fmt.tprintf("%v", fastest),
				size,
			)
		}
	}
	report("core:diff unified output of 100k lines with 0.5% edited, the fastest of 3 runs each", &tbl)
}
