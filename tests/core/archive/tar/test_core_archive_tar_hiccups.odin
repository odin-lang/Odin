package test_core_archive_tar

import "core:archive"
import "core:archive/tar"
import "core:compress"
import "core:io"
import "core:strings"
import "core:testing"

@(private="file")
Hiccup_Stream :: struct {
	data:     []u8,
	pos:      i64,
	hiccups:  int,
	pending:  int,
	stall_at: i64,
}

@(test)
test_read_hiccups :: proc(t: ^testing.T) {
	text := strings.repeat("Empty reads between every chunk of this member. ", 120, context.temp_allocator)
	for compression in ([2]archive.Method{.Store, .Deflate}) {
		out := strings.builder_make()
		defer strings.builder_destroy(&out)
		tw: tar.Writer
		if !testing.expect_value(t, tar.create(&tw, strings.to_writer(&out), {compression = compression}), nil) {
			continue
		}
		testing.expect_value(t, tar.write_entry(&tw, "a.txt", transmute([]u8)text), nil)
		testing.expect_value(t, tar.write_entry(&tw, "b.txt", transmute([]u8)text), nil)
		testing.expect_value(t, tar.commit(&tw), nil)
		tar.close(&tw)

		for hiccups in ([?]int{0, 3, 100, 101, max(int)}) {
			h := Hiccup_Stream{data = out.buf[:], hiccups = hiccups}
			results, open_err := read_all(hiccup_stream(&h), text)
			defer delete(results)
			if hiccups > 100 {
				testing.expectf(t, no_progress(open_err), "%v, %d hiccups: open %v", compression, hiccups, open_err)
				continue
			}
			testing.expectf(t, open_err == nil && len(results) == 3 && results[0] == nil && results[1] == nil && results[2] == nil, "%v, %d hiccups: %v %v", compression, hiccups, open_err, results[:])
		}

		h := Hiccup_Stream{data = out.buf[:], stall_at = i64(len(out.buf)) / 2}
		results, open_err := read_all(hiccup_stream(&h), text)
		defer delete(results)
		stalled := false
		for err in results {
			stalled ||= no_progress(err)
		}
		testing.expectf(t, open_err == nil && stalled, "%v, stalled: %v %v", compression, open_err, results[:])
	}
}

@(private="file")
read_all :: proc(s: io.Stream, want: string) -> (results: [dynamic]archive.Error, open_err: archive.Error) {
	r: tar.Reader
	tar.open(&r, s) or_return
	defer tar.close(&r)
	it := tar.iterator_create(&r)
	defer tar.iterator_destroy(&it)
	for _ in tar.iterate(&it) {
		got := strings.builder_make()
		err := tar.extract_current(&it, strings.to_writer(&got))
		if err == nil && strings.to_string(got) != want {
			err = archive.Tar_Error.Truncated
		}
		append(&results, err)
		strings.builder_destroy(&got)
	}
	_, it_err := tar.iterator_error(&it)
	append(&results, it_err)
	return
}

@(private="file")
no_progress :: proc(err: archive.Error) -> bool {
	#partial switch e in err {
	case io.Error:
		return e == .No_Progress
	case compress.Error:
		if inner, ok := e.(io.Error); ok {
			return inner == .No_Progress
		}
	}
	return false
}

@(private="file")
hiccup_stream :: proc(h: ^Hiccup_Stream) -> io.Stream {
	return {procedure = hiccup_stream_proc, data = h}
}

@(private="file")
hiccup_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	h := (^Hiccup_Stream)(stream_data)
	#partial switch mode {
	case .Read:
		if h.stall_at > 0 && h.pos >= h.stall_at {
			return 0, nil
		}
		if h.pending < h.hiccups {
			h.pending += 1
			return 0, nil
		}
		h.pending = 0
		if h.pos >= i64(len(h.data)) {
			return 0, .EOF
		}
		end := min(i64(len(h.data)), h.pos + 7)
		if h.stall_at > 0 {
			end = min(end, h.stall_at)
		}
		m := copy(p, h.data[h.pos:end])
		h.pos += i64(m)
		return i64(m), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}
