package test_core_archive_zip

import "core:archive"
import "core:archive/zip"
import "core:bytes"
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
	zw: zip.Writer
	if !testing.expect_value(t, zip.create(&zw, memory_stream(&m)), nil) {
		return
	}
	testing.expect_value(t, zip.write_entry(&zw, "deflated.txt", text), nil)
	testing.expect_value(t, zip.write_entry(&zw, "stored.txt", text, zip.Entry_Options{method = .Store}), nil)
	testing.expect_value(t, zip.commit(&zw), nil)
	zip.close(&zw)
	padding := write_random(70_000, 0x5a11)
	defer delete(padding)
	s := Memory_File{seekable = true}
	defer delete(s.data)
	sw: zip.Writer
	if !testing.expect_value(t, zip.create(&sw, memory_stream(&s)), nil) {
		return
	}
	testing.expect_value(t, zip.write_entry(&sw, "stored.txt", text, zip.Entry_Options{method = .Store}), nil)
	testing.expect_value(t, zip.write_entry(&sw, "padding.bin", padding, zip.Entry_Options{method = .Store}), nil)
	testing.expect_value(t, zip.commit(&sw), nil)
	zip.close(&sw)
	stall_at  := i64(bytes.index(s.data[:], text)) + 100
	stall_end := stall_at + 8

	for read_at in ([2]bool{false, true}) {
		for hiccups in ([?]int{0, 3, 100, 101, max(int)}) {
			h := Hiccup_Stream{data = m.data[:], hiccups = hiccups, read_at = read_at, seekable = true}
			a, detect_err := archive.open(hiccup_stream(&h))
			if hiccups > 100 {
				testing.expectf(t, detect_err == io.Error.No_Progress, "read_at %v, %d hiccups: detect %v", read_at, hiccups, detect_err)
			} else {
				testing.expectf(t, detect_err == nil && a.format == .Zip, "read_at %v, %d hiccups: detect %v %v", read_at, hiccups, a.format, detect_err)
			}
			if detect_err == nil {
				archive.close(&a)
			}

			h = Hiccup_Stream{data = m.data[:], hiccups = hiccups, read_at = read_at, seekable = true}
			r: zip.Reader
			err := zip.open(&r, hiccup_stream(&h))
			if hiccups > 100 {
				testing.expectf(t, err == io.Error.No_Progress, "read_at %v, %d hiccups: open %v", read_at, hiccups, err)
				if err == nil {
					zip.close(&r)
				}
				continue
			}
			if !testing.expectf(t, err == nil, "read_at %v, %d hiccups: open %v", read_at, hiccups, err) {
				continue
			}
			it := zip.iterator_create(&r)
			count := 0
			for fi in zip.iterate(&it) {
				out := strings.builder_make()
				extract_err := zip.extract_current(&it, strings.to_writer(&out))
				testing.expectf(t, extract_err == nil && bytes.equal(out.buf[:], text), "read_at %v, %d hiccups, %s: %v", read_at, hiccups, fi.path, extract_err)
				strings.builder_destroy(&out)
				count += 1
			}
			testing.expectf(t, count == 2, "read_at %v, %d hiccups: %d entries", read_at, hiccups, count)
			zip.iterator_destroy(&it)
			zip.close(&r)
		}

		h := Hiccup_Stream{data = s.data[:], stall_at = stall_at, stall_end = stall_end, read_at = read_at, seekable = true}
		r: zip.Reader
		if open_err := zip.open(&r, hiccup_stream(&h)); !testing.expectf(t, open_err == nil, "read_at %v, stalled: open %v", read_at, open_err) {
			continue
		}
		it := zip.iterator_create(&r)
		results: [dynamic]archive.Error
		defer delete(results)
		for _ in zip.iterate(&it) {
			out := strings.builder_make()
			append(&results, zip.extract_current(&it, strings.to_writer(&out)))
			strings.builder_destroy(&out)
		}
		testing.expectf(t, len(results) == 2 && results[0] == io.Error.No_Progress && results[1] == nil, "read_at %v, stalled: %v", read_at, results[:])
		zip.iterator_destroy(&it)
		zip.close(&r)
	}
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
