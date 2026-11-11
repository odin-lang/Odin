package test_core_fmt

import "base:runtime"
import "core:bufio"
import "core:fmt"
import "core:io"
import "core:strings"
import "core:testing"

// `wprint*` stage their output for writers that are not a `strings.Builder` and write it out at the end.
// A plain stream must get the same output and count as a `strings.Builder`, in the same order.

@(private="file")
Recorder :: struct {
	buf:    [dynamic]byte,
	limit:  int, // bytes accepted in total, or -1 for all of them
	writes: int,
}

@(private="file")
recorder_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Recorder)(stream_data)
	#partial switch mode {
	case .Write:
		r.writes += 1
		k := len(p)
		if r.limit >= 0 {
			k = min(k, r.limit-len(r.buf))
		}
		append(&r.buf, ..p[:k])
		if k < len(p) {
			return i64(k), .Short_Write
		}
		return i64(k), nil
	case .Flush:
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Flush, .Query})
	}
	return 0, .Unsupported
}

@(private="file")
Staged :: struct {
	a, b: int,
}

// Writes through `fi.writer`, formats a field with `fmt_value`, and nests a flushing `wprintf`
@(private="file")
staged_formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
	s := arg.(Staged)
	io.write_string(fi.writer, "S<", &fi.n)
	fmt.fmt_value(fi, s.a, 'v')
	fi.n += fmt.wprintf(fi.writer, "|%d|", s.b)
	io.write_byte(fi.writer, '>', &fi.n)
	return true
}

@(private="file")
g_user_formatters: map[typeid]fmt.User_Formatter

@(private="file", init)
register_staged_formatter :: proc "contextless" () {
	context = runtime.default_context()
	fmt.set_user_formatters(&g_user_formatters)
	fmt.register_user_formatter(typeid_of(Staged), staged_formatter)
}

@(private="file", fini)
delete_user_formatters :: proc "contextless" () {
	context = runtime.default_context()
	delete(g_user_formatters)
}

@(private="file")
check_staged :: proc(t: ^testing.T, format: string, args: ..any, loc := #caller_location) {
	want := fmt.tprintf(format, ..args)

	r := Recorder{limit = -1}
	defer delete(r.buf)
	n := fmt.wprintf(io.Stream{procedure = recorder_proc, data = &r}, format, ..args)

	testing.expectf(t, string(r.buf[:]) == want, "(%q): got %q, want %q", format, string(r.buf[:]), want, loc = loc)
	testing.expectf(t, n == len(want), "(%q): counted %v bytes of %v", format, n, len(want), loc = loc)
}

@(test)
test_fmt_stage_matches_builder :: proc(t: ^testing.T) {
	long := strings.repeat("y", 3000, context.temp_allocator)
	ints := make([]int, 600, context.temp_allocator)
	for &v, i in ints {
		v = i
	}

	check_staged(t, "%d %s %v", 1, "two", 3.5)
	check_staged(t, "%v", ints)
	check_staged(t, "%s|%v|%s", long, Staged{1, 2}, long)
	check_staged(t, "%v %v", []Staged{{3, 4}, {5, 6}}, ints)
	check_staged(t, "")

	r := Recorder{limit = -1}
	defer delete(r.buf)
	w := io.Stream{procedure = recorder_proc, data = &r}

	n := fmt.wprint(w, 1, "a", Staged{7, 8}, sep="--")
	testing.expect_value(t, string(r.buf[:]), "1--a--S<7|8|>")
	testing.expect_value(t, n, len(r.buf))

	clear(&r.buf)
	n = fmt.wprintln(w, ints)
	testing.expect_value(t, string(r.buf[:]), fmt.tprintln(ints))
	testing.expect_value(t, n, len(r.buf))

	// One write per stage-full of output, not one per piece
	clear(&r.buf)
	r.writes = 0
	n = fmt.wprintf(w, "%v", ints)
	testing.expectf(t, r.writes <= n/1024 + 1, "%v writes for %v bytes", r.writes, n)
}

// A writer that stops accepting keeps a prefix of the output, and the count is what it kept
@(test)
test_fmt_stage_short_writer :: proc(t: ^testing.T) {
	long := strings.repeat("z", 1500, context.temp_allocator)
	want := fmt.tprintf("%s %v %s", long, Staged{1, 2}, long)

	for limit in ([]int{0, 1, 5, 1023, 1024, 1025, 1508, 2000, 3000}) {
		r := Recorder{limit = limit}
		n := fmt.wprintf(io.Stream{procedure = recorder_proc, data = &r}, "%s %v %s", long, Staged{1, 2}, long)
		testing.expectf(t, string(r.buf[:]) == want[:min(limit, len(want))], "limit %v: got %v bytes", limit, len(r.buf))
		testing.expectf(t, n == len(r.buf), "limit %v: counted %v of %v", limit, n, len(r.buf))
		delete(r.buf)
	}
}

// A caller's `bufio.Writer` is written to directly, and nothing more goes in once it has failed
@(test)
test_fmt_stage_caller_bufio :: proc(t: ^testing.T) {
	r := Recorder{limit = 8}
	defer delete(r.buf)

	buf: [4]byte
	b: bufio.Writer
	bufio.writer_init_with_buf(&b, io.Stream{procedure = recorder_proc, data = &r}, buf[:])
	w := bufio.writer_to_writer(&b)

	n := fmt.wprintf(w, "%d", 12, flush=false)
	testing.expect_value(t, n, 2)
	testing.expect_value(t, bufio.writer_buffered(&b), 2)
	testing.expect_value(t, len(r.buf), 0)

	n = fmt.wprintf(w, "%s", "abcdefghij")
	testing.expect_value(t, n, 6)
	testing.expect_value(t, string(r.buf[:]), "12abcdef")

	n = fmt.wprintf(w, "%d", 3)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, string(r.buf[:]), "12abcdef")
}

@(private="file")
stuck_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	#partial switch mode {
	case .Write, .Flush:
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Flush, .Query})
	}
	return 0, .Unsupported
}

// A writer that takes nothing without an error loses the output instead of stalling
@(test)
test_fmt_stage_stuck_writer :: proc(t: ^testing.T) {
	long := strings.repeat("w", 3000, context.temp_allocator)
	w := io.Stream{procedure = stuck_proc}
	testing.expect_value(t, fmt.wprintf(w, "%s", long), 0)
	testing.expect_value(t, fmt.wprintf(w, "%d", 5), 0)
}
