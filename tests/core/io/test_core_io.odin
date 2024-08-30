package test_core_io

import "core:bufio"
import "core:bytes"
import "core:io"
import "core:log"
import "core:os"
import "core:os/os2"
import "core:strings"
import "core:testing"

Passed_Tests :: distinct io.Stream_Mode_Set

_test_stream :: proc(
	t: ^testing.T,
	stream: io.Stream,
	buffer: []u8,
	
	reading_consumes: bool = false,
	resets_on_empty: bool = false,
	do_destroy: bool = true,

	loc := #caller_location
) -> (passed: Passed_Tests, ok: bool) {
	// We only test what the stream reports to support.

	mode_set := io.query(stream)

	// Can't feature-test anything if Query isn't supported.
	testing.expectf(t, .Query in mode_set, "stream does not support .Query: %v", mode_set, loc = loc) or_return

	passed += { .Query }

	size := i64(len(buffer))

	// Do some basic Seek sanity testing.
	if .Seek in mode_set {
		pos, err := io.seek(stream, 0, io.Seek_From(-1))
		testing.expectf(t, err == .Invalid_Whence,
			"Seek(-1) didn't fail with Invalid_Whence: %v, %v", pos, err, loc = loc) or_return

		pos, err = io.seek(stream, 0, .Start)
		testing.expectf(t, pos == 0 && err == nil,
			"Seek Start isn't 0: %v, %v", pos, err, loc = loc) or_return

		pos, err = io.seek(stream, 0, .Current)
		testing.expectf(t, pos == 0 && err == nil,
			"Seek Current isn't 0 at the start: %v, %v", pos, err, loc = loc) or_return

		pos, err = io.seek(stream, -1, .Start)
		testing.expectf(t, err == .Invalid_Offset,
			"Seek Start-1 wasn't Invalid_Offset: %v, %v", pos, err, loc = loc) or_return

		pos, err = io.seek(stream, -1, .Current)
		testing.expectf(t, err == .Invalid_Offset,
			"Seek Current-1 wasn't Invalid_Offset: %v, %v", pos, err, loc = loc) or_return

		pos, err = io.seek(stream, 0, .End)
		testing.expectf(t, pos == size && err == nil,
			"Seek End+0 failed: %v != size<%i>, %v", pos, size, err, loc = loc) or_return

		pos, err = io.seek(stream, 0, .Current)
		testing.expectf(t, pos == size && err == nil,
			"Seek Current isn't size<%v> at the End: %v, %v", size, pos, err, loc = loc) or_return

		// Seeking past the End is accepted throughout the API.
		//
		// It's _reading_ past the End which is erroneous.
		pos, err = io.seek(stream, 1, .End)
		testing.expectf(t, pos == size+1 && err == nil,
			"Seek End+1 failed: %v, %v", pos, err, loc = loc) or_return

		// Reset our position for future tests.
		pos, err = io.seek(stream, 0, .Start)
		testing.expectf(t, pos == 0 && err == nil,
			"Seek Start reset failed: %v, %v", pos, err, loc = loc) or_return

		passed += { .Seek }
	}

	// Test Size.
	if .Size in mode_set {
		api_size, size_err := io.size(stream)
		testing.expectf(t, api_size == size,
			"Size reports %v for its size; expected %v", api_size, size, loc = loc) or_return
		testing.expectf(t, size_err == nil,
			"Size expected no error: %v", size_err, loc = loc) or_return

		// Ensure Size does not move the underlying pointer from the start.
		//
		// Some implementations may use seeking to determine file sizes.
		if .Seek in mode_set {
			pos, seek_err := io.seek(stream, 0, .Current)
			testing.expectf(t, pos == 0 && seek_err == nil,
				"Size+Seek Current isn't 0 after getting size: %v, %v", pos, seek_err, loc = loc) or_return
		}

		passed += { .Size }
	}

	// Test Read_At.
	if .Read_At in mode_set {
		// Test reading into an empty buffer.
		{
			nil_slice: []u8
			bytes_read, err := io.read_at(stream, nil_slice, 0)
			testing.expectf(t, bytes_read == 0 && err == nil,
				"Read_At into empty slice failed: bytes_read<%v>, %v", bytes_read, err, loc = loc) or_return
		}

		read_buf, alloc_err := make([]u8, size)
		testing.expect_value(t, alloc_err, nil, loc = loc) or_return
		defer delete(read_buf)

		for start in 0..<size {
			for end in 1+start..<size {
				subsize := end - start
				bytes_read, err := io.read_at(stream, read_buf[:subsize], start)
				testing.expectf(t, i64(bytes_read) == subsize && err == nil,
					"Read_At(%i) of %v bytes failed: %v, %v", start, subsize, bytes_read, err, loc = loc) or_return
				testing.expectf(t, bytes.compare(read_buf[:subsize], buffer[start:end]) == 0,
					"Read_At buffer compare failed: read_buf<%v> != buffer<%v>", read_buf, buffer, loc = loc) or_return
			}
		}

		// Test empty streams and EOF.
		one_buf: [1]u8
		bytes_read, err := io.read_at(stream, one_buf[:], size)
		testing.expectf(t, err == .EOF,
			"Read_At at end of stream failed: %v, %v", bytes_read, err, loc = loc) or_return

		// Make sure size is still sane.
		if .Size in mode_set {
			api_size, size_err := io.size(stream)
			testing.expectf(t, api_size == size,
				"Read_At+Size reports %v for its size after Read_At tests; expected %v", api_size, size, loc = loc) or_return
			testing.expectf(t, size_err == nil,
				"Read_At+Size expected no error: %v", size_err, loc = loc) or_return
		}

		// Ensure Read_At does not move the underlying pointer from the start.
		if .Seek in mode_set {
			pos, seek_err := io.seek(stream, 0, .Current)
			testing.expectf(t, pos == 0 && seek_err == nil,
				"Read_At+Seek Current isn't 0 after reading: %v, %v", pos, seek_err, loc = loc) or_return
		}

		passed += { .Read_At }
	}

	// Test Read.
	if .Read in mode_set {
		// Test reading into an empty buffer.
		{
			nil_slice: []u8
			bytes_read, err := io.read(stream, nil_slice)
			testing.expectf(t, bytes_read == 0 && err == nil,
				"Read into empty slice failed: bytes_read<%v>, %v", bytes_read, err, loc = loc) or_return
		}

		if size > 0 {
			read_buf, alloc_err := make([]u8, size)
			testing.expectf(t, alloc_err == nil, "allocation failed", loc = loc) or_return
			defer delete(read_buf)

			bytes_read, err := io.read(stream, read_buf[:1])
			testing.expectf(t, bytes_read == 1 && err == nil,
				"Read 1 byte at start failed: %v, %v", bytes_read, err, loc = loc) or_return
			testing.expectf(t, read_buf[0] == buffer[0],
				"Read of first byte failed: read_buf[0]<%v> != buffer[0]<%v>", read_buf[0], buffer[0], loc = loc) or_return

			// Test rolling back the stream one byte then reading it again.
			if .Seek in mode_set {
				pos, seek_err := io.seek(stream, -1, .Current)
				testing.expectf(t, pos == 0 && err == nil,
					"Read+Seek Current-1 reset to 0 failed: %v, %v", pos, seek_err, loc = loc) or_return

				bytes_read, err = io.read(stream, read_buf[:1])
				testing.expectf(t, bytes_read == 1 && err == nil,
					"Read 1 byte at start after Seek reset failed: %v, %v", bytes_read, err, loc = loc) or_return
				testing.expectf(t, read_buf[0] == buffer[0] ,
					"re-Read of first byte failed: read_buf[0]<%v> != buffer[0]<%v>", read_buf[0], buffer[0], loc = loc) or_return
			}

			// Make sure size is still sane.
			if .Size in mode_set {
				api_size, size_err := io.size(stream)
				expected_api_size := size - 1 if reading_consumes else size

				testing.expectf(t, api_size == expected_api_size,
					"Read+Size reports %v for its size after Read tests; expected %v", api_size, expected_api_size, loc = loc) or_return
				testing.expectf(t, size_err == nil,
					"Read+Size expected no error: %v", size_err, loc = loc) or_return
			}

			// Read the rest.
			if size > 1 {
				bytes_read, err = io.read(stream, read_buf[1:])
				testing.expectf(t, i64(bytes_read) == size - 1 && err == nil,
					"Read rest of stream failed: %v != %v, %v", bytes_read, size-1, err, loc = loc) or_return
				testing.expectf(t, bytes.compare(read_buf, buffer) == 0,
					"Read buffer compare failed: read_buf<%v> != buffer<%v>", read_buf, buffer, loc = loc) or_return
			}
		}

		// Test empty streams and EOF.
		one_buf: [1]u8
		bytes_read, err := io.read(stream, one_buf[:])
		testing.expectf(t, err == .EOF,
			"Read at end of stream failed: %v, %v", bytes_read, err, loc = loc) or_return

		if !resets_on_empty && .Size in mode_set {
			// Make sure size is still sane.
			api_size, size_err := io.size(stream)
			testing.expectf(t, api_size == size,
				"Read+Size reports %v for its size after Read tests; expected %v", api_size, size, loc = loc) or_return
			testing.expectf(t, size_err == nil,
				"Read+Size expected no error: %v", size_err, loc = loc) or_return
		}

		passed += { .Read }
	}

	// Test Write_At.
	if .Write_At in mode_set {
		// Test writing from an empty buffer.
		{
			nil_slice: []u8
			bytes_written, err := io.write_at(stream, nil_slice, 0)
			testing.expectf(t, bytes_written == 0 && err == nil,
				"Write_At from empty slice failed: bytes_written<%v>, %v", bytes_written, err, loc = loc) or_return
		}

		// Ensure Write_At does not move the underlying pointer from the start.
		starting_offset : i64 = -1
		if .Seek in mode_set {
			pos, seek_err := io.seek(stream, 0, .Current)
			testing.expectf(t, pos >= 0 && seek_err == nil,
				"Write_At+Seek Current failed: %v, %v", pos, seek_err, loc = loc) or_return
			starting_offset = pos
		}

		if size > 0 {
			write_buf, write_buf_alloc_err := make([]u8, size)
			testing.expectf(t, write_buf_alloc_err == nil, "allocation failed", loc = loc) or_return
			defer delete(write_buf)

			for i in 0..<size {
				write_buf[i] = buffer[i] ~ 0xAA
			}

			bytes_written, write_err := io.write_at(stream, write_buf[:], 0)
			testing.expectf(t, i64(bytes_written) == size && write_err == nil,
				"Write_At failed: bytes_written<%v> != size<%v>: %v", bytes_written, size, write_err, loc = loc) or_return

			// Test reading what we've written.
			if .Read_At in mode_set {
				read_buf, read_buf_alloc_err := make([]u8, size)
				testing.expectf(t, read_buf_alloc_err == nil, "allocation failed", loc = loc) or_return
				defer delete(read_buf)
				bytes_read, read_err := io.read_at(stream, read_buf[:], 0)
				testing.expectf(t, i64(bytes_read) == size && read_err == nil,
					"Write_At+Read_At failed: bytes_read<%i> != size<%i>, %v", bytes_read, size, read_err, loc = loc) or_return
				testing.expectf(t, bytes.compare(read_buf, write_buf) == 0,
					"Write_At+Read_At buffer compare failed: write_buf<%v> != read_buf<%v>", write_buf, read_buf, loc = loc) or_return
			}
		} else {
			// Expect that it should be okay to write a single byte to an empty stream.
			x_buf: [1]u8 = { 'Z' }

			bytes_written, write_err := io.write_at(stream, x_buf[:], 0)
			testing.expectf(t, i64(bytes_written) == 1 && write_err == nil,
				"Write_At(0) with 'Z' on empty stream failed: bytes_written<%v>, %v", bytes_written, write_err, loc = loc) or_return

			// Test reading what we've written.
			if .Read_At in mode_set {
				x_buf[0] = 0
				bytes_read, read_err := io.read_at(stream, x_buf[:], 0)
				testing.expectf(t, i64(bytes_read) == 1 && read_err == nil,
					"Write_At(0)+Read_At(0) failed expectation: bytes_read<%v> != 1, %q != 'Z', %v", bytes_read, x_buf[0], read_err, loc = loc) or_return
			}
		}

		// Ensure Write_At does not move the underlying pointer from the start.
		if starting_offset != -1 && .Seek in mode_set {
			pos, seek_err := io.seek(stream, 0, .Current)
			testing.expectf(t, pos == starting_offset && seek_err == nil,
				"Write_At+Seek Current isn't %v after writing: %v, %v", starting_offset, pos, seek_err, loc = loc) or_return
		}

		passed += { .Write_At }
	}

	// Test Write.
	if .Write in mode_set {
		// Test writing from an empty buffer.
		{
			nil_slice: []u8
			bytes_written, err := io.write(stream, nil_slice)
			testing.expectf(t, bytes_written == 0 && err == nil,
				"Write from empty slice failed: bytes_written<%v>, %v", bytes_written, err, loc = loc) or_return
		}

		write_buf, write_buf_alloc_err := make([]u8, size)
		testing.expectf(t, write_buf_alloc_err == nil, "allocation failed", loc = loc) or_return
		defer delete(write_buf)

		for i in 0..<size {
			write_buf[i] = buffer[i] ~ 0xAA
		}

		pos: i64 = -1
		before_write_size: i64 = -1

		// Do a Seek sanity check after past tests.
		if .Seek in mode_set {
			seek_err: io.Error
			pos, seek_err = io.seek(stream, 0, .Current)
			testing.expectf(t, seek_err == nil,
				"Write+Seek(Current) failed: pos<%i>, %v", pos, seek_err) or_return
		}

		// Get the Size before writing.
		if .Size in mode_set {
			size_err: io.Error
			before_write_size, size_err = io.size(stream)
			testing.expectf(t, size_err == nil,
				"Write+Size failed: %v", size_err, loc = loc) or_return
		}

		bytes_written, write_err := io.write(stream, write_buf[:])
		testing.expectf(t, i64(bytes_written) == size && write_err == nil,
			"Write %i bytes failed: %i, %v", size, bytes_written, write_err, loc = loc) or_return

		// Size sanity check, part 2.
		if before_write_size >= 0 && .Size in mode_set {
			after_write_size, size_err := io.size(stream)
			testing.expectf(t, size_err == nil,
				"Write+Size.part_2 failed: %v", size_err, loc = loc) or_return
			testing.expectf(t, after_write_size == before_write_size + size,
				"Write+Size.part_2 failed: %v != %v + %v", after_write_size, before_write_size, size, loc = loc) or_return
		}

		// Test reading what we've written directly with Read_At.
		if pos >= 0 && .Read_At in mode_set {
			read_buf, read_buf_alloc_err := make([]u8, size)
			testing.expectf(t, read_buf_alloc_err == nil, "allocation failed", loc = loc) or_return
			defer delete(read_buf)

			bytes_read, read_err := io.read_at(stream, read_buf[:], pos)
			testing.expectf(t, i64(bytes_read) == size && read_err == nil,
				"Write+Read_At(%i) failed: bytes_read<%i> != size<%i>, %v", pos, bytes_read, size, read_err, loc = loc) or_return
			testing.expectf(t, bytes.compare(read_buf, write_buf) == 0,
				"Write+Read_At buffer compare failed: read_buf<%v> != write_buf<%v>", read_buf, write_buf, loc = loc) or_return
		}

		// Test resetting the pointer and reading what we've written with Read.
		if .Read in mode_set && .Seek in mode_set {
			seek_err: io.Error
			pos, seek_err = io.seek(stream, 0, .Start)
			testing.expectf(t, pos == 0 && seek_err == nil,
				"Write+Read+Seek(Start) failed: pos<%i>, %v", pos, seek_err) or_return

			read_buf, read_buf_alloc_err := make([]u8, size)
			testing.expectf(t, read_buf_alloc_err == nil, "allocation failed", loc = loc) or_return
			defer delete(read_buf)

			bytes_read, read_err := io.read(stream, read_buf[:])
			testing.expectf(t, i64(bytes_read) == size && read_err == nil,
				"Write+Read failed: bytes_read<%i> != size<%i>, %v", bytes_read, size, read_err, loc = loc) or_return
			testing.expectf(t, bytes.compare(read_buf, write_buf) == 0,
				"Write+Readbuffer compare failed: read_buf<%v> != write_buf<%v>", read_buf, write_buf, loc = loc) or_return
		}

		passed += { .Write }
	}

	// Test the other modes.
	if .Flush in mode_set {
		err := io.flush(stream)
		testing.expectf(t, err == nil, "stream failed to Flush: %v", err, loc = loc) or_return
		passed += { .Flush }
	}

	if .Close in mode_set {
		close_err := io.close(stream)
		testing.expectf(t, close_err == nil, "stream failed to Close: %v", close_err, loc = loc) or_return
		passed += { .Close }
	}

	if do_destroy && .Destroy in mode_set {
		err := io.destroy(stream)
		testing.expectf(t, err == nil, "stream failed to Destroy: %v", err, loc = loc) or_return
		passed += { .Destroy }
	}

	ok = true
	return
}



@test
test_bytes_reader :: proc(t: ^testing.T) {
	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	br: bytes.Reader

	results: Passed_Tests
	ok: bool

	for end in 0..<i64(len(buf)) {
		results, ok =_test_stream(t, bytes.reader_init(&br, buf[:end]), buf[:end])
		if !ok {
			log.debugf("buffer[:%i] := %v", end, buf[:end])
			return
		}
	}

	log.debugf("%#v", results)
}

@test
test_bytes_buffer_stream :: proc(t: ^testing.T) {
	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	results: Passed_Tests
	ok: bool

	for end in 0..<i64(len(buf)) {
		bb: bytes.Buffer
		// Mind that `bytes.buffer_init` copies the entire underlying slice.
		bytes.buffer_init(&bb, buf[:end])

		// `bytes.Buffer` has a behavior of decreasing its size with each read
		// until it eventually clears the underlying buffer when it runs out of
		// data to read.
		results, ok = _test_stream(t, bytes.buffer_to_stream(&bb), buf[:end],
			reading_consumes = true, resets_on_empty = true)
		if !ok {
			log.debugf("buffer[:%i] := %v", end, buf[:end])
			return
		}
	}

	log.debugf("%#v", results)
}

@test
test_limited_reader :: proc(t: ^testing.T) {
	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	br: bytes.Reader
	bs := bytes.reader_init(&br, buf[:])

	lr: io.Limited_Reader

	results: Passed_Tests
	ok: bool

	for end in 0..<i64(len(buf)) {
		pos, seek_err := io.seek(bs, 0, .Start)
		if !testing.expectf(t, pos == 0 && seek_err == nil,
			"Pre-test Seek reset failed: pos<%v>, %v", pos, seek_err) {
			return
		}

		results, ok = _test_stream(t, io.limited_reader_init(&lr, bs, end), buf[:end])
		if !ok {
			log.debugf("buffer[:%i] := %v", end, buf[:end])
			return
		}
	}

	log.debugf("%#v", results)
}

@test
test_section_reader :: proc(t: ^testing.T) {
	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	br: bytes.Reader
	bs := bytes.reader_init(&br, buf[:])

	sr: io.Section_Reader

	results: Passed_Tests
	ok: bool

	for start in 0..<i64(len(buf)) {
		for end in start..<i64(len(buf)) {
			results, ok = _test_stream(t, io.section_reader_init(&sr, bs, start, end-start), buf[start:end])
			if !ok {
				log.debugf("buffer[%i:%i] := %v", start, end, buf[start:end])
				return
			}
		}
	}

	log.debugf("%#v", results)
}

@test
test_string_builder_stream :: proc(t: ^testing.T) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	// String builders do not support reading, so we'll have to set up a few
	// things outside the main test.

	buf: [32]u8
	expected_buf: [64]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
		expected_buf[i] = 'A' + i
		strings.write_byte(&sb, 'A' + i)
	}
	for i in 32..<u8(len(expected_buf)) {
		expected_buf[i] = ('A' + i-len(buf)) ~ 0xAA
	}

	results, _ := _test_stream(t, strings.to_stream(&sb), buf[:],
		do_destroy = false)

	testing.expectf(t, bytes.compare(sb.buf[:], expected_buf[:]) == 0, "string builder stream failed:\nbuilder<%q>\n!=\nbuffer <%q>", sb.buf[:], expected_buf[:])

	log.debugf("%#v", results)
}

@test
test_os_file_stream :: proc(t: ^testing.T) {
	defer if !testing.failed(t) {
		testing.expect_value(t, os.remove(TEMPORARY_FILENAME), nil)
	}

	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	TEMPORARY_FILENAME :: "test_core_io_os_file_stream"

	fd, open_err := os.open(TEMPORARY_FILENAME, os.O_RDWR | os.O_CREATE | os.O_TRUNC, 0o644)
	if !testing.expectf(t, open_err == nil, "error on opening %q: %v", TEMPORARY_FILENAME, open_err) {
		return
	}
	
	stream := os.stream_from_handle(fd)

	bytes_written, write_err := io.write(stream, buf[:])
	if !testing.expectf(t, bytes_written == len(buf) && write_err == nil,
		"failed to Write initial buffer: bytes_written<%v> != len_buf<%v>, %v", bytes_written, len(buf), write_err) {
		return
	}

	flush_err := io.flush(stream)
	if !testing.expectf(t, flush_err == nil,
		"failed to Flush initial buffer: %v", write_err) {
		return
	}

	results, _ := _test_stream(t, stream, buf[:])

	log.debugf("%#v", results)
}

@test
test_os2_file_stream :: proc(t: ^testing.T) {
	defer if !testing.failed(t) {
		testing.expect_value(t, os2.remove(TEMPORARY_FILENAME), nil)
	}

	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	TEMPORARY_FILENAME :: "test_core_io_os2_file_stream"

	fd, open_err := os2.open(TEMPORARY_FILENAME, {.Read, .Write, .Create, .Trunc})
	if !testing.expectf(t, open_err == nil, "error on opening %q: %v", TEMPORARY_FILENAME, open_err) {
		return
	}

	stream := os2.to_stream(fd)

	bytes_written, write_err := io.write(stream, buf[:])
	if !testing.expectf(t, bytes_written == len(buf) && write_err == nil,
		"failed to Write initial buffer: bytes_written<%v> != len_buf<%v>, %v", bytes_written, len(buf), write_err) {
		return
	}

	flush_err := io.flush(stream)
	if !testing.expectf(t, flush_err == nil,
		"failed to Flush initial buffer: %v", write_err) {
		return
	}

	// os2 file stream proc close and destroy are the same.
	results, _ := _test_stream(t, stream, buf[:], do_destroy = false)

	log.debugf("%#v", results)
}

@test
test_bufio_buffered_writer :: proc(t: ^testing.T) {
	// Using a strings.Builder as the backing stream.

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	buf: [32]u8
	expected_buf: [64]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
		expected_buf[i] = 'A' + i
		strings.write_byte(&sb, 'A' + i)
	}
	for i in 32..<u8(len(expected_buf)) {
		expected_buf[i] = ('A' + i-len(buf)) ~ 0xAA
	}

	writer: bufio.Writer
	bufio.writer_init(&writer, strings.to_stream(&sb))
	defer bufio.writer_destroy(&writer)

	results, _ := _test_stream(t, bufio.writer_to_stream(&writer), buf[:],
		do_destroy = false)

	testing.expectf(t, bytes.compare(sb.buf[:], expected_buf[:]) == 0, "bufio buffered string builder stream failed:\nbuilder<%q>\n!=\nbuffer <%q>", sb.buf[:], expected_buf[:])

	log.debugf("%#v", results)
}

@test
test_bufio_buffered_reader :: proc(t: ^testing.T) {
	// Using a bytes.Reader as the backing stream.

	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	results: Passed_Tests
	ok: bool

	for end in 0..<i64(len(buf)) {
		br: bytes.Reader
		bs := bytes.reader_init(&br, buf[:end])

		reader: bufio.Reader
		bufio.reader_init(&reader, bs)
		defer bufio.reader_destroy(&reader)

		results, ok = _test_stream(t, bufio.reader_to_stream(&reader), buf[:end])
		if !ok {
			log.debugf("buffer[:%i] := %v", end, buf[:end])
			return
		}
	}

	log.debugf("%#v", results)
}

@test
test_bufio_buffered_read_writer :: proc(t: ^testing.T) {
	// Using an os2.File as the backing stream for both reader & writer.

	defer if !testing.failed(t) {
		testing.expect_value(t, os2.remove(TEMPORARY_FILENAME), nil)
	}

	buf: [32]u8
	for i in 0..<u8(len(buf)) {
		buf[i] = 'A' + i
	}

	TEMPORARY_FILENAME :: "test_core_io_bufio_read_writer_os2_file_stream"

	fd, open_err := os2.open(TEMPORARY_FILENAME, {.Read, .Write, .Create, .Trunc})
	if !testing.expectf(t, open_err == nil, "error on opening %q: %v", TEMPORARY_FILENAME, open_err) {
		return
	}
	defer testing.expect_value(t, os2.close(fd), nil)

	stream := os2.to_stream(fd)

	bytes_written, write_err := io.write(stream, buf[:])
	if !testing.expectf(t, bytes_written == len(buf) && write_err == nil,
		"failed to Write initial buffer: bytes_written<%v> != len_buf<%v>, %v", bytes_written, len(buf), write_err) {
		return
	}

	flush_err := io.flush(stream)
	if !testing.expectf(t, flush_err == nil,
		"failed to Flush initial buffer: %v", write_err) {
		return
	}

	// bufio.Read_Writer isn't capable of seeking, so we have to reset the os2
	// stream back to the start here.
	pos, seek_err := io.seek(stream, 0, .Start)
	if !testing.expectf(t, pos == 0 && seek_err == nil,
		"Pre-test Seek reset failed: pos<%v>, %v", pos, seek_err) {
		return
	}

	reader: bufio.Reader
	writer: bufio.Writer
	read_writer: bufio.Read_Writer

	bufio.reader_init(&reader, stream)
	defer bufio.reader_destroy(&reader)
	bufio.writer_init(&writer, stream)
	defer bufio.writer_destroy(&writer)

	bufio.read_writer_init(&read_writer, &reader, &writer)

	// os2 file stream proc close and destroy are the same.
	results, _ := _test_stream(t, bufio.read_writer_to_stream(&read_writer), buf[:], do_destroy = false)

	log.debugf("%#v", results)
}
