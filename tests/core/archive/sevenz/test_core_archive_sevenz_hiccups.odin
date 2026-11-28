package test_core_archive_sevenz

import "core:archive"
import "core:archive/sevenz"
import "core:bytes"
import "core:compress"
import "core:io"
import "core:strings"
import "core:testing"

@(private="file")
Hiccup_Stream :: struct {
	data:     []u8,
	pos:      i64,
	hiccups:   int,
	pending:   int,
	stall_at:  i64,
	stall_end: i64,
	read_at:   bool,
	seekable:  bool,
}

@(test)
test_read_hiccups :: proc(t: ^testing.T) {
	text := write_text()
	m := Memory_File{seekable = true}
	defer delete(m.data)
	sw: sevenz.Writer
	if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m), sevenz.Writer_Options{solid = false}), nil) {
		return
	}
	testing.expect_value(t, sevenz.write_entry(&sw, "lzma.txt", text), nil)
	testing.expect_value(t, sevenz.write_entry(&sw, "copy.txt", text, sevenz.Entry_Options{method = .Store}), nil)
	testing.expect_value(t, sevenz.commit(&sw), nil)
	sevenz.close(&sw)

	for read_at in ([2]bool{false, true}) {
		for hiccups in ([?]int{0, 3, 100, 101, max(int)}) {
			h := Hiccup_Stream{data = m.data[:], hiccups = hiccups, read_at = read_at, seekable = true}
			a, detect_err := archive.open(hiccup_stream(&h))
			if hiccups > 100 {
				testing.expectf(t, no_progress(detect_err), "read_at %v, %d hiccups: detect %v", read_at, hiccups, detect_err)
			} else {
				testing.expectf(t, detect_err == nil && a.format == .SevenZ, "read_at %v, %d hiccups: detect %v %v", read_at, hiccups, a.format, detect_err)
			}
			if detect_err == nil {
				archive.close(&a)
			}

			h = Hiccup_Stream{data = m.data[:], hiccups = hiccups, read_at = read_at, seekable = true}
			results, open_err := read_all(hiccup_stream(&h), text)
			defer delete(results)
			if hiccups > 100 {
				testing.expectf(t, no_progress(open_err), "read_at %v, %d hiccups: open %v", read_at, hiccups, open_err)
				continue
			}
			testing.expectf(t, open_err == nil && len(results) == 3 && results[0] == nil && results[1] == nil && results[2] == nil, "read_at %v, %d hiccups: %v %v", read_at, hiccups, open_err, results[:])
		}

		stored  := i64(bytes.index(m.data[:], text)) + 100
		windows := [2][2]i64{{40, 48}, {stored, stored + 8}}
		for window, stalled in windows {
			h := Hiccup_Stream{data = m.data[:], stall_at = window[0], stall_end = window[1], read_at = read_at, seekable = true}
			results, open_err := read_all(hiccup_stream(&h), text)
			defer delete(results)
			ok := open_err == nil && len(results) == 3
			if ok {
				ok = no_progress(results[stalled]) && results[1 - stalled] == nil
			}
			testing.expectf(t, ok, "read_at %v, stalled in entry %d: %v %v", read_at, stalled, open_err, results[:])
		}
	}
}

@(test)
test_write_read_hiccups :: proc(t: ^testing.T) {
	text := write_text()
	for hiccups in ([?]int{0, 3, 100, 101, max(int)}) {
		for sized in ([2]bool{false, true}) {
			m := Memory_File{seekable = true}
			defer delete(m.data)
			sw: sevenz.Writer
			if !testing.expect_value(t, sevenz.create(&sw, memory_stream(&m)), nil) {
				continue
			}
			fi := archive.File_Info{path = "a.txt", type = .Regular, size = i64(len(text)) if sized else -1}
			h := Hiccup_Stream{data = text, hiccups = hiccups}
			err := sevenz.write_entry(&sw, fi, hiccup_stream(&h))
			if err == nil {
				err = sevenz.commit(&sw)
			}
			sevenz.close(&sw)
			if hiccups > 100 {
				testing.expectf(t, no_progress(err), "%d hiccups, sized %v: %v", hiccups, sized, err)
				continue
			}
			if !testing.expectf(t, err == nil, "%d hiccups, sized %v: %v", hiccups, sized, err) {
				continue
			}
			back := Hiccup_Stream{data = m.data[:], read_at = true, seekable = true}
			results, open_err := read_all(hiccup_stream(&back), text)
			defer delete(results)
			testing.expectf(t, open_err == nil && len(results) == 2 && results[0] == nil && results[1] == nil, "%d hiccups, sized %v: read back %v %v", hiccups, sized, open_err, results[:])
		}
	}
}

@(private="file")
read_all :: proc(s: io.Stream, want: []u8) -> (results: [dynamic]archive.Error, open_err: archive.Error) {
	r: sevenz.Reader
	sevenz.open(&r, s) or_return
	defer sevenz.close(&r)
	it := sevenz.iterator_create(&r)
	defer sevenz.iterator_destroy(&it)
	for _ in sevenz.iterate(&it) {
		got := strings.builder_make()
		err := sevenz.extract_current(&it, strings.to_writer(&got))
		if err == nil && !bytes.equal(got.buf[:], want) {
			err = archive.SevenZ_Error.Truncated
		}
		append(&results, err)
		strings.builder_destroy(&got)
	}
	_, it_err := sevenz.iterator_error(&it)
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
	case .Read, .Read_At:
		if mode == .Read_At && !h.read_at {
			return 0, .Unsupported
		}
		at := h.pos if mode == .Read else offset
		if h.stall_at > 0 && at >= h.stall_at && at < h.stall_end {
			return 0, nil
		}
		if h.pending < h.hiccups {
			h.pending += 1
			return 0, nil
		}
		h.pending = 0
		if at < 0 {
			return 0, .Invalid_Offset
		}
		if at >= i64(len(h.data)) {
			return 0, .EOF
		}
		end := min(i64(len(h.data)), at + 7)
		if h.stall_at > 0 && at < h.stall_at {
			end = min(end, h.stall_at)
		}
		m := copy(p, h.data[at:end])
		if mode == .Read {
			h.pos += i64(m)
		}
		return i64(m), nil
	case .Seek:
		if !h.seekable {
			return 0, .Unsupported
		}
		target: i64
		switch whence {
		case .Start:   target = offset
		case .Current: target = h.pos + offset
		case .End:     target = i64(len(h.data)) + offset
		case:          return 0, .Invalid_Whence
		}
		if target < 0 {
			return 0, .Invalid_Offset
		}
		h.pos = target
		return target, nil
	case .Size:
		if !h.seekable {
			return 0, .Unsupported
		}
		return i64(len(h.data)), nil
	case .Query:
		modes := io.Stream_Mode_Set{.Read, .Query}
		if h.read_at {
			modes += {.Read_At}
		}
		if h.seekable {
			modes += {.Seek, .Size}
		}
		return io.query_utility(modes)
	}
	return 0, .Unsupported
}
