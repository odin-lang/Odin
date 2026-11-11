package tar

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:io"
import "core:os"
import "core:strings"
import "core:time"

open_from_bytes :: proc(r: ^Reader, data: []u8, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
	r.input_data = data
	r.input_size = i64(len(data))
	r.seekable   = true
	sniffed := _sniff(data[:min(len(data), HEAD_SIZE)])
	switch sniffed {
	case .Unknown:
		return archive.General_Error.Unknown_Format
	case .XZ:
		r.compression = .XZ
		return archive.General_Error.Unsupported_Method
	case .Plain:
		r.compression = .Store
		r.source      = .Memory
		r.data        = data
	case .Gzip:
		r.compression = .Deflate
		_start_gzip(r) or_return
	case .BZip2, .LZ4, .LZMA:
		_decode_whole(r, sniffed) or_return
	}
	return
}

open_from_stream :: proc(r: ^Reader, s: io.Stream, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
	r.input      = s
	r.input_size = -1
	if start, seek_err := io.seek(s, 0, .Current); seek_err == nil {
		r.seekable    = true
		r.input_start = start
		if size, size_err := io.size(s); size_err == nil {
			r.input_size = size
		}
	}
	n := 0
	head_err: io.Error
	for n < len(r.head) {
		got, read_err := io.read(s, r.head[n:])
		n += got
		if read_err == .EOF || (read_err == nil && got == 0) {
			break
		}
		if read_err != nil {
			if n == 0 {
				return read_err
			}
			head_err = read_err
			break
		}
	}
	r.prefix = {prefix = r.head[:n], stream = s, err = head_err}
	sniffed := _sniff(r.head[:n])
	switch sniffed {
	case .Unknown:
		return archive.General_Error.Unknown_Format
	case .XZ:
		r.compression = .XZ
		return archive.General_Error.Unsupported_Method
	case .Plain:
		r.compression = .Store
		r.source      = .Stream
		r.stream      = s
		if head_err != nil {
			r.pending = head_err
		}
		r.buf         = make([]u8, BUFFER_SIZE, r.allocator) or_return
		copy(r.buf, r.head[:n])
		r.end = n
	case .Gzip:
		r.compression = .Deflate
		_start_gzip(r) or_return
	case .BZip2, .LZ4, .LZMA:
		_decode_whole(r, sniffed) or_return
	}
	return
}

open_from_path :: proc(r: ^Reader, path: string, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	f, open_err := os.open(path)
	if open_err != nil {
		return open_err
	}
	if err = open_from_stream(r, os.to_stream(f), options, allocator); err != nil {
		os.close(f)
		return
	}
	r.file = f
	return
}

open :: proc{open_from_path, open_from_bytes, open_from_stream}

close :: proc(r: ^Reader) {
	if r.source == .Gzip {
		deflate.inflate_reader_destroy(&r.inflate)
	}
	compress.destroy_context(&r.ctx)
	delete(r.decoded)
	delete(r.buf, r.allocator)
	delete(r.local_buf)
	delete(r.global_buf)
	for &value in r.globals {
		delete(value)
	}
	delete(r.path_buf)
	delete(r.fail_path)
	if r.file != nil {
		os.close(r.file)
	}
	r^ = {}
}

info :: proc(r: ^Reader) -> (info: archive.Archive_Info) {
	info.format       = .Tar
	info.member_count = r.member_count if r.ended else -1
	info.compression  = r.compression
	return
}

iterator_create :: proc(r: ^Reader) -> (it: Iterator) {
	it.reader = r
	it.err_path.allocator = r.allocator
	if r.index >= 0 {
		it.err = _rewind(r)
	}
	return
}

iterator_destroy :: proc(it: ^Iterator) {
	delete(it.err_path)
	it^ = {}
}

iterate :: proc(it: ^Iterator) -> (fi: archive.File_Info, index: int, ok: bool) {
	r := it.reader
	if r == nil || it.err != nil {
		return {}, -1, false
	}
	info, more, err := _next(r)
	if err != nil {
		it.err = err
		clear(&it.err_path)
		append(&it.err_path, ..r.fail_path[:])
		return {}, -1, false
	}
	if !more {
		return {}, -1, false
	}
	return info, r.index, true
}

@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	return string(it.err_path[:]), it.err
}

extract_current :: proc(it: ^Iterator, w: io.Writer) -> (err: Error) {
	return _extract(it.reader, w)
}

open_current :: proc(it: ^Iterator) -> (reader: io.Reader, err: Error) {
	return _open_current(it.reader)
}

read_link :: proc(it: ^Iterator, allocator := context.allocator) -> (target: string, err: Error) {
	r := it.reader
	if !r.has_current {
		return "", archive.General_Error.No_Current_Member
	}
	clone_err: runtime.Allocator_Error
	target, clone_err = strings.clone(r.current.link_target, allocator)
	if clone_err != nil {
		return "", clone_err
	}
	return
}

current_header :: proc(it: ^Iterator) -> (header: ^Header) {
	return &it.reader.header
}

next_record :: proc(records: ^[]u8) -> (key, value: string, ok: bool) {
	if len(records) == 0 || _all_zero(records^) {
		return
	}
	rest: []u8
	key, value, rest, ok = _next_record(records^)
	if ok {
		records^ = rest
	}
	return
}

find :: proc(r: ^Reader, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	want := archive.clean_member_path(path)
	if r.has_current && archive.clean_member_path(r.current.path) == want {
		return r.current, r.current.handle, true, nil
	}
	start  := r.index
	broken := r.broken
	for broken == nil {
		info, more, next_err := _next(r)
		if next_err != nil {
			broken = next_err
			break
		}
		if !more {
			break
		}
		if archive.clean_member_path(info.path) == want {
			return info, info.handle, true, nil
		}
	}
	if start < 0 {
		return {}, {}, false, broken
	}
	_rewind(r) or_return
	for r.index < start {
		info, more := _next(r) or_return
		if !more {
			break
		}
		if archive.clean_member_path(info.path) == want {
			return info, info.handle, true, nil
		}
	}
	return {}, {}, false, broken
}

extract :: proc(r: ^Reader, handle: archive.Handle, w: io.Writer) -> (err: Error) {
	_seek_member(r, handle.index) or_return
	return _extract(r, w)
}

open_member :: proc(r: ^Reader, handle: archive.Handle) -> (reader: io.Reader, err: Error) {
	_seek_member(r, handle.index) or_return
	return _open_current(r)
}

@(init, private)
_register :: proc "contextless" () {
	archive.register(.Tar, {
		detect           = _archive_detect,
		open_bytes       = _archive_open_bytes,
		open_stream      = _archive_open_stream,
		close            = _archive_close,
		info             = _archive_info,
		iterator_create  = _archive_iterator_create,
		iterator_destroy = _archive_iterator_destroy,
		iterate          = _archive_iterate,
		iterator_error   = _archive_iterator_error,
		extract_current  = _archive_extract_current,
		open_current     = _archive_open_current,
		read_link        = _archive_read_link,
		find             = _archive_find,
		extract          = _archive_extract,
		open_member      = _archive_open_member,
	})
}

@(private)
_init :: proc(r: ^Reader, options: compress.Options, allocator: runtime.Allocator) {
	r^ = {}
	r.allocator            = allocator
	r.options              = options
	r.index                = -1
	r.local_buf.allocator  = allocator
	r.global_buf.allocator = allocator
	for &value in r.globals {
		value.allocator = allocator
	}
	r.path_buf.allocator   = allocator
	r.fail_path.allocator  = allocator
	r.decoded.allocator    = allocator
}

@(private)
_memory :: #force_inline proc "contextless" (r: ^Reader) -> bool {
	return r.source == .Memory || r.source == .Decoded
}

@(private)
_start_gzip :: proc(r: ^Reader) -> (err: Error) {
	if r.input.procedure == nil {
		r.ctx = compress.init_context_from_slice(&r.input_data)
	} else {
		r.ctx = compress.init_context_from_stream(_prefix_stream(r), nil, -1, nil, r.allocator)
	}
	inflate_err := deflate.inflate_reader_init(&r.inflate, &r.ctx, .Gzip, -1, r.options, r.allocator)
	r.source = .Gzip
	if inflate_err != nil {
		return inflate_err
	}
	if r.buf == nil {
		r.buf = make([]u8, BUFFER_SIZE, r.allocator) or_return
	}
	r.pos, r.end, r.offset = 0, 0, 0
	return
}

@(private)
_decode_whole :: proc(r: ^Reader, sniffed: Sniffed) -> (err: Error) {
	limit := compress.output_limit(r.options)
	decode_err: compress.Error
	if r.input.procedure == nil {
		#partial switch sniffed {
		case .BZip2:
			r.compression = .BZip2
			decode_err = bzip2.decompress_from_bytes(&r.decoded, r.input_data, -1, r.options, r.allocator)
		case .LZ4:
			r.compression = .LZ4
			decode_err = lz4.decompress_frame_from_bytes(&r.decoded, r.input_data, -1, r.options, nil, r.allocator)
		case .LZMA:
			r.compression = .LZMA
			decode_err = lzma.decompress_from_bytes(&r.decoded, r.input_data, -1, limit, r.allocator)
		}
	} else {
		r.ctx = compress.init_context_from_stream(_prefix_stream(r), &r.decoded, -1, nil, r.allocator)
		defer compress.destroy_context(&r.ctx)
		#partial switch sniffed {
		case .BZip2:
			r.compression = .BZip2
			decode_err = bzip2.decompress_from_context(&r.ctx, -1, r.options, r.allocator)
		case .LZ4:
			r.compression = .LZ4
			decode_err = lz4.decompress_frame_from_context(&r.ctx, -1, r.options, nil, r.allocator)
		case .LZMA:
			r.compression = .LZMA
			decode_err = lzma.decompress_from_context(&r.ctx, -1, limit, r.allocator)
		}
	}
	if decode_err != nil {
		return decode_err
	}
	r.source = .Decoded
	r.data   = r.decoded[:]
	r.pos    = 0
	return
}

@(private)
_prefix_stream :: proc(r: ^Reader) -> (s: io.Stream) {
	s.data      = &r.prefix
	s.procedure = _prefix_stream_proc
	return
}

@(private)
_prefix_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	s := (^Prefix_Stream)(stream_data)
	#partial switch mode {
	case .Read:
		if s.pos < len(s.prefix) {
			copied := copy(p, s.prefix[s.pos:])
			s.pos += copied
			return i64(copied), nil
		}
		if s.err != nil {
			return 0, s.err
		}
		got, read_err := io.read(s.stream, p)
		return i64(got), read_err
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@(private)
_source_read :: proc(r: ^Reader, p: []u8) -> (n: int, eof: bool, err: Error) {
	if r.pending != nil {
		return 0, false, r.pending
	}
	got: int
	read_err: Error
	if r.source == .Gzip {
		inflate_err: compress.Error
		got, inflate_err = deflate.inflate_reader_read(&r.inflate, p)
		if io_err, is_io := inflate_err.(io.Error); is_io && io_err == .EOF {
			return got, true, nil
		}
		read_err = inflate_err
	} else {
		stream_err: io.Error
		got, stream_err = io.read(r.stream, p)
		if stream_err == .EOF {
			return got, true, nil
		}
		read_err = stream_err
	}
	if read_err != nil {
		if got > 0 {
			r.pending = read_err
			return got, false, nil
		}
		return 0, false, read_err
	}
	return got, got == 0 && len(p) > 0, nil
}

@(private)
_fill :: proc(r: ^Reader, need: int) -> (available: int, err: Error) {
	if r.end - r.pos >= need {
		return r.end - r.pos, nil
	}
	if r.pos > 0 {
		copy(r.buf, r.buf[r.pos:r.end])
		r.end -= r.pos
		r.pos  = 0
	}
	for r.end < need {
		got, eof := _source_read(r, r.buf[r.end:]) or_return
		r.end += got
		if eof {
			break
		}
	}
	return r.end - r.pos, nil
}

@(private)
_next_block :: proc(r: ^Reader) -> (block: []u8, eof: bool, err: Error) {
	if _memory(r) {
		left := len(r.data) - r.pos
		if left == 0 {
			return nil, true, nil
		}
		if left < BLOCK_SIZE {
			return nil, false, Tar_Error.Truncated
		}
		block  = r.data[r.pos:][:BLOCK_SIZE]
		r.pos += BLOCK_SIZE
		return
	}
	available := _fill(r, BLOCK_SIZE) or_return
	if available == 0 {
		return nil, true, nil
	}
	if available < BLOCK_SIZE {
		return nil, false, Tar_Error.Truncated
	}
	block     = r.buf[r.pos:][:BLOCK_SIZE]
	r.pos    += BLOCK_SIZE
	r.offset += BLOCK_SIZE
	return
}

@(private)
_read_exact :: proc(r: ^Reader, dst: []u8) -> (err: Error) {
	if _memory(r) {
		if len(r.data) - r.pos < len(dst) {
			return Tar_Error.Truncated
		}
		copy(dst, r.data[r.pos:])
		r.pos += len(dst)
		return
	}
	n := copy(dst, r.buf[r.pos:r.end])
	r.pos    += n
	r.offset += i64(n)
	for n < len(dst) {
		got, eof := _source_read(r, dst[n:]) or_return
		n        += got
		r.offset += i64(got)
		if eof && n < len(dst) {
			return Tar_Error.Truncated
		}
	}
	return
}

@(private)
_skip :: proc(r: ^Reader, count: i64) -> (err: Error) {
	count := count
	if count <= 0 {
		return
	}
	if _memory(r) {
		if i64(len(r.data) - r.pos) < count {
			return Tar_Error.Truncated
		}
		r.pos += int(count)
		return
	}
	buffered := min(count, i64(r.end - r.pos))
	r.pos    += int(buffered)
	r.offset += buffered
	count    -= buffered
	if count == 0 {
		return
	}
	if r.source == .Stream && r.seekable {
		target := r.offset + count
		if r.input_size >= 0 && r.input_start + target > r.input_size {
			return Tar_Error.Truncated
		}
		if _, seek_err := io.seek(r.input, r.input_start + target, .Start); seek_err != nil {
			return seek_err
		}
		r.offset       = target
		r.pos, r.end   = 0, 0
		return
	}
	r.pos, r.end = 0, 0
	for count > 0 {
		chunk := r.buf[:min(i64(len(r.buf)), count)]
		got, eof := _source_read(r, chunk) or_return
		count    -= i64(got)
		r.offset += i64(got)
		if eof && count > 0 {
			return Tar_Error.Truncated
		}
	}
	return
}

@(private)
_rewind :: proc(r: ^Reader) -> (err: Error) {
	switch r.source {
	case .Memory, .Decoded:
		r.pos = 0
	case .Stream:
		if !r.seekable {
			return archive.General_Error.Not_Seekable
		}
		if _, seek_err := io.seek(r.input, r.input_start, .Start); seek_err != nil {
			return seek_err
		}
		r.pos, r.end, r.offset = 0, 0, 0
	case .Gzip:
		if r.input.procedure != nil {
			if !r.seekable {
				return archive.General_Error.Not_Seekable
			}
			if _, seek_err := io.seek(r.input, r.input_start, .Start); seek_err != nil {
				return seek_err
			}
			r.prefix = {stream = r.input}
		}
		deflate.inflate_reader_destroy(&r.inflate)
		compress.destroy_context(&r.ctx)
		_start_gzip(r) or_return
	}
	r.index       = -1
	r.remaining   = 0
	r.padding     = 0
	r.ended       = false
	r.has_current = false
	r.unsupported = nil
	r.broken      = nil
	r.pending     = nil
	clear(&r.local_buf)
	clear(&r.global_buf)
	r.global_set = {}
	r.gnu_sparse = false
	clear(&r.fail_path)
	return
}

@(private)
_seek_member :: proc(r: ^Reader, index: int) -> (err: Error) {
	if index < 0 {
		return archive.General_Error.Not_Found
	}
	if r.has_current && r.index == index && r.remaining == r.current.size {
		return
	}
	if index <= r.index {
		_rewind(r) or_return
	}
	for r.index < index {
		_, more := _next(r) or_return
		if !more {
			return archive.General_Error.Not_Found
		}
	}
	return
}

@(private)
_next :: proc(r: ^Reader) -> (fi: archive.File_Info, ok: bool, err: Error) {
	if r.broken != nil {
		return {}, false, r.broken
	}
	fi, ok, err = _next_member(r)
	if err != nil {
		r.broken      = err
		r.has_current = false
		return {}, false, err
	}
	return
}

@(private)
_next_member :: proc(r: ^Reader) -> (fi: archive.File_Info, ok: bool, err: Error) {
	if r.ended {
		return
	}
	clear(&r.fail_path)
	if r.has_current {
		if err = _skip(r, r.remaining + r.padding); err != nil {
			append(&r.fail_path, r.current.path)
			return
		}
		r.remaining, r.padding = 0, 0
		r.has_current = false
		r.unsupported = nil
	}
	clear(&r.local_buf)
	clear(&r.global_buf)
	for {
		block, eof := _next_block(r) or_return
		if eof || _all_zero(block) {
			r.ended        = true
			r.member_count = r.index + 1
			return
		}
		copy(r.header.block[:], block)
		h := r.header.block[:]
		if !_checksum_ok(h) {
			return {}, false, Tar_Error.Invalid_Checksum
		}
		defer if err != nil {
			append(&r.fail_path, _field(h[0:100]))
		}
		typeflag := h[156]
		size     := _parse_number(h[124:136]) or_return
		switch typeflag {
		case 'x', 'g':
			_read_records(r, typeflag, size) or_return
			continue
		case 'L', 'K', 'S', 'D', 'M', 'V', 'N':
			return {}, false, Tar_Error.Unsupported_GNU_Extension
		}
		fi = _make_info(r, typeflag, size) or_return
		return fi, true, nil
	}
}

@(private)
_read_records :: proc(r: ^Reader, typeflag: u8, size: i64) -> (err: Error) {
	limit := min(i64(HEADER_RECORD_MAX), i64(compress.memory_limit(r.options)))
	if i64(len(r.local_buf) + len(r.global_buf)) + size > limit {
		return Tar_Error.Header_Too_Large
	}
	buf   := &r.local_buf if typeflag == 'x' else &r.global_buf
	start := len(buf)
	resize(buf, start + int(size)) or_return
	_read_exact(r, buf[start:]) or_return
	_skip(r, _padding(size)) or_return
	_validate_records(buf[start:]) or_return
	if typeflag == 'g' {
		_update_globals(r, buf[start:]) or_return
	}
	return
}

@(private)
_update_globals :: proc(r: ^Reader, records: []u8) -> (err: Error) {
	rest := records
	for len(rest) > 0 && !_all_zero(rest) {
		key, value, next, _ := _next_record(rest)
		rest = next
		if strings.has_prefix(key, "GNU.sparse.") {
			r.gnu_sparse = true
			continue
		}
		for name, slot in GLOBAL_KEYS {
			if name != key {
				continue
			}
			clear(&r.globals[slot])
			if value == "" {
				r.global_set -= {slot}
			} else {
				append(&r.globals[slot], value) or_return
				r.global_set += {slot}
			}
			break
		}
	}
	return
}

@(private)
_validate_records :: proc(records: []u8) -> (err: Error) {
	rest := records
	for len(rest) > 0 && !_all_zero(rest) {
		key, value, next, ok := _next_record(rest)
		if !ok {
			return Tar_Error.Invalid_Pax_Record
		}
		rest = next
		switch key {
		case "path", "linkpath", "uname", "gname":
			if strings.index_byte(value, 0) >= 0 {
				return Tar_Error.Invalid_Pax_Record
			}
		case "size", "uid", "gid":
			if _, number_ok := _parse_decimal(value); !number_ok && value != "" {
				return Tar_Error.Invalid_Pax_Record
			}
		case "mtime", "atime", "ctime":
			if _, time_ok := _parse_pax_time(value); !time_ok && value != "" {
				return Tar_Error.Invalid_Pax_Record
			}
		}
	}
	return
}

@(private)
_next_record :: proc "contextless" (data: []u8) -> (key, value: string, rest: []u8, ok: bool) {
	length := 0
	digits := 0
	for digits < len(data) && data[digits] >= '0' && data[digits] <= '9' {
		length = length * 10 + int(data[digits] - '0')
		digits += 1
		if length > len(data) {
			return
		}
	}
	if digits == 0 || digits >= len(data) || data[digits] != ' ' || length <= digits + 1 || length > len(data) {
		return
	}
	record := data[:length]
	if record[length - 1] != '\n' {
		return
	}
	body := record[digits + 1:length - 1]
	equals := -1
	for c, i in body {
		if c == '=' {
			equals = i
			break
		}
	}
	if equals < 1 {
		return
	}
	return string(body[:equals]), string(body[equals + 1:]), data[length:], true
}

@(private)
_make_info :: proc(r: ^Reader, typeflag: u8, size: i64) -> (fi: archive.File_Info, err: Error) {
	h      := r.header.block[:]
	format := _header_format(h)
	r.header.format   = format
	r.header.typeflag = typeflag

	name   := _field(h[0:100])
	prefix := ""
	#partial switch format {
	case .Ustar: prefix = _field(h[345:500])
	case .Star:  prefix = _field(h[345:476])
	}
	fi.path = name
	if prefix != "" {
		clear(&r.path_buf)
		append(&r.path_buf, prefix) or_return
		append(&r.path_buf, '/') or_return
		append(&r.path_buf, name) or_return
		fi.path = string(r.path_buf[:])
	}
	fi.link_target = _field(h[157:257])

	mode  := _parse_number(h[100:108]) or_return
	fi.uid = _parse_number(h[108:116]) or_return
	fi.gid = _parse_number(h[116:124]) or_return
	mtime := _parse_number(h[136:148]) or_return
	fi.modification_time = _unix_time(mtime, 0)
	if format != .V7 {
		fi.user  = _field(h[265:297])
		fi.group = _field(h[297:329])
		major := _parse_number(h[329:337]) or_return
		minor := _parse_number(h[337:345]) or_return
		if major > i64(max(u32)) || minor > i64(max(u32)) {
			return {}, Tar_Error.Invalid_Number
		}
		fi.device = {u32(major), u32(minor)}
	}

	r.header.global_records = r.global_buf[:]
	r.header.local_records  = r.local_buf[:]
	data_size := size
	sparse    := r.gnu_sparse
	base      := fi
	for slot in r.global_set {
		_apply_record(&fi, &data_size, &sparse, base, size, GLOBAL_KEYS[slot], string(r.globals[slot][:]))
	}
	_apply_records(&fi, &data_size, &sparse, base, size, r.local_buf[:]) or_return
	fi.extended_metadata = len(r.local_buf) > 0 || len(r.global_buf) > 0
	if data_size < 0 {
		return {}, Tar_Error.Invalid_Size
	}

	switch typeflag {
	case '0', 0, '7':
		fi.type = .Regular
		if typeflag != '7' && strings.has_suffix(fi.path, "/") {
			fi.type = .Directory
		}
	case '1': fi.type = .Hard_Link
	case '2': fi.type = .Symlink
	case '3': fi.type = .Character_Device
	case '4': fi.type = .Block_Device
	case '5': fi.type = .Directory
	case '6': fi.type = .Named_Pipe
	case:     fi.type = .Unknown
	}
	switch typeflag {
	case '1', '2', '3', '4', '5', '6':
		data_size = 0
	}

	fi.raw_path = transmute([]u8)fi.path
	if len(fi.path) > 1 {
		fi.path = strings.trim_right(fi.path, "/")
		if fi.path == "" {
			fi.path = "/"
		}
	}

	fi.size            = data_size
	fi.compressed_size = data_size if r.compression == .Store else -1
	fi.method          = .Store
	fi.unix_mode       = u32(mode & archive.UNIX_PERMISSION_MASK) | archive.unix_type_bits(fi.type)
	fi.dos_attributes  = archive.dos_attributes_from_unix(fi.unix_mode, fi.type)
	fi.supported       = true
	r.unsupported      = nil
	if sparse {
		fi.supported  = false
		r.unsupported = Tar_Error.Unsupported_GNU_Extension
	} else if fi.type == .Unknown {
		fi.supported  = false
		r.unsupported = archive.General_Error.Unsupported_Entry
	}

	r.index      += 1
	fi.handle     = {index = r.index}
	r.remaining   = data_size
	r.padding     = _padding(data_size)
	r.current     = fi
	r.has_current = true
	return
}

@(private)
_apply_records :: proc(fi: ^archive.File_Info, size: ^i64, sparse: ^bool, base: archive.File_Info, base_size: i64, records: []u8) -> (err: Error) {
	rest := records
	for len(rest) > 0 && !_all_zero(rest) {
		key, value, next, ok := _next_record(rest)
		if !ok {
			return Tar_Error.Invalid_Pax_Record
		}
		rest = next
		_apply_record(fi, size, sparse, base, base_size, key, value)
	}
	return
}

@(private)
_apply_record :: proc(fi: ^archive.File_Info, size: ^i64, sparse: ^bool, base: archive.File_Info, base_size: i64, key, value: string) {
	switch key {
	case "path":
		fi.path = value if value != "" else base.path
	case "linkpath":
		fi.link_target = value if value != "" else base.link_target
	case "uname":
		fi.user = value if value != "" else base.user
	case "gname":
		fi.group = value if value != "" else base.group
	case "comment":
		fi.comment = value
	case "size":
		size^ = base_size
		if value != "" {
			size^, _ = _parse_decimal(value)
		}
	case "uid":
		fi.uid = base.uid
		if value != "" {
			fi.uid, _ = _parse_decimal(value)
		}
	case "gid":
		fi.gid = base.gid
		if value != "" {
			fi.gid, _ = _parse_decimal(value)
		}
	case "mtime":
		fi.modification_time = base.modification_time
		if value != "" {
			fi.modification_time, _ = _parse_pax_time(value)
		}
	case "atime":
		fi.access_time, _ = _parse_pax_time(value)
	case "LIBARCHIVE.creationtime":
		fi.creation_time, _ = _parse_pax_time(value)
	case:
		if strings.has_prefix(key, "GNU.sparse.") {
			sparse^ = true
		}
	}
}

@(private)
_parse_number :: proc "contextless" (field: []u8) -> (value: i64, err: Error) {
	if len(field) > 0 && field[0] & 0x80 != 0 {
		return 0, Tar_Error.Unsupported_GNU_Extension
	}
	ok: bool
	value, ok = _parse_octal(field)
	if !ok {
		return 0, Tar_Error.Invalid_Number
	}
	return
}

@(private)
_parse_decimal :: proc "contextless" (s: string) -> (value: i64, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	for c in transmute([]u8)s {
		if c < '0' || c > '9' {
			return 0, false
		}
		if value > (max(i64) - i64(c - '0')) / 10 {
			return 0, false
		}
		value = value * 10 + i64(c - '0')
	}
	return value, true
}

@(private)
_parse_pax_time :: proc "contextless" (s: string) -> (t: time.Time, ok: bool) {
	s := s
	negative := false
	if len(s) > 0 && s[0] == '-' {
		negative = true
		s = s[1:]
	}
	whole    := s
	fraction := ""
	for c, i in transmute([]u8)s {
		if c == '.' {
			whole    = s[:i]
			fraction = s[i + 1:]
			break
		}
	}
	seconds := _parse_decimal(whole) or_return
	nanoseconds: i64
	scale := i64(100_000_000)
	for c in transmute([]u8)fraction {
		if c < '0' || c > '9' {
			return {}, false
		}
		nanoseconds += i64(c - '0') * scale
		scale /= 10
	}
	if negative {
		seconds     = -seconds
		nanoseconds = -nanoseconds
	}
	return _unix_time(seconds, nanoseconds), true
}

@(private)
_unix_time :: proc "contextless" (seconds, nanoseconds: i64) -> (t: time.Time) {
	LIMIT :: max(i64) / 1_000_000_000 - 1
	switch {
	case seconds > LIMIT:  return time.unix(LIMIT, 0)
	case seconds < -LIMIT: return time.unix(-LIMIT, 0)
	}
	return time.unix(seconds, nanoseconds)
}

@(private)
_header_format :: proc "contextless" (h: []u8) -> (format: Header_Format) {
	magic := string(h[257:265])
	switch {
	case magic == "ustar  \x00":
		return .GNU
	case magic[:6] == "ustar\x00":
		return .Star if string(h[508:512]) == "tar\x00" else .Ustar
	}
	return .V7
}

@(private)
_field :: proc "contextless" (b: []u8) -> string {
	for c, i in b {
		if c == 0 {
			return string(b[:i])
		}
	}
	return string(b)
}

@(private)
_padding :: #force_inline proc "contextless" (size: i64) -> i64 {
	return (BLOCK_SIZE - size % BLOCK_SIZE) % BLOCK_SIZE
}

@(private)
_extract :: proc(r: ^Reader, w: io.Writer) -> (err: Error) {
	if !r.has_current {
		return archive.General_Error.No_Current_Member
	}
	if r.unsupported != nil {
		return r.unsupported
	}
	if _memory(r) {
		count := min(r.remaining, i64(len(r.data) - r.pos))
		if count > 0 {
			if _, write_err := io.write_full(w, r.data[r.pos:][:count]); write_err != nil {
				return write_err
			}
			r.pos       += int(count)
			r.remaining -= count
		}
		if r.remaining > 0 {
			return Tar_Error.Truncated
		}
		return
	}
	for r.remaining > 0 {
		if r.pos == r.end {
			available := _fill(r, 1) or_return
			if available == 0 {
				return Tar_Error.Truncated
			}
		}
		count := min(r.remaining, i64(r.end - r.pos))
		if _, write_err := io.write_full(w, r.buf[r.pos:][:count]); write_err != nil {
			return write_err
		}
		r.pos       += int(count)
		r.offset    += count
		r.remaining -= count
	}
	return
}

@(private)
_open_current :: proc(r: ^Reader) -> (reader: io.Reader, err: Error) {
	if !r.has_current {
		return {}, archive.General_Error.No_Current_Member
	}
	if r.unsupported != nil {
		return {}, r.unsupported
	}
	reader.data      = r
	reader.procedure = _member_stream_proc
	return
}

@(private)
_read_member :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	if r.remaining == 0 {
		return 0, io.Error.EOF
	}
	want := int(min(i64(len(p)), r.remaining))
	if _memory(r) {
		count := min(want, len(r.data) - r.pos)
		if count == 0 {
			return 0, Tar_Error.Truncated
		}
		copy(p, r.data[r.pos:][:count])
		r.pos       += count
		r.remaining -= i64(count)
		return count, nil
	}
	if r.pos < r.end {
		count := min(want, r.end - r.pos)
		copy(p, r.buf[r.pos:][:count])
		r.pos       += count
		r.offset    += i64(count)
		r.remaining -= i64(count)
		return count, nil
	}
	got, eof := _source_read(r, p[:want]) or_return
	if got == 0 && eof {
		return 0, Tar_Error.Truncated
	}
	r.offset    += i64(got)
	r.remaining -= i64(got)
	return got, nil
}

@(private)
_member_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		got, read_err := _read_member(r, p)
		n = i64(got)
		if read_err != nil {
			if io_err, is_io := read_err.(io.Error); is_io {
				err = io_err
			} else if tar_err, is_tar := read_err.(Tar_Error); is_tar && tar_err == .Truncated {
				err = .Unexpected_EOF
			} else {
				err = .Unknown
			}
		}
		return
	case .Size:
		return r.current.size, nil
	case .Query:
		return io.query_utility({.Read, .Size, .Query})
	}
	return 0, .Unsupported
}

@(private)
_archive_detect :: proc(head: []u8) -> bool {
	return _sniff(head) != .Unknown
}

@(private)
_archive_open_bytes :: proc(a: ^archive.Archive, data: []u8, options: compress.Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_bytes(r, data, options, a.allocator); err != nil {
		free(r, a.allocator)
		return
	}
	a.state = r
	return
}

@(private)
_archive_open_stream :: proc(a: ^archive.Archive, s: io.Stream, options: compress.Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_stream(r, s, options, a.allocator); err != nil {
		free(r, a.allocator)
		return
	}
	a.state = r
	return
}

@(private)
_archive_close :: proc(a: ^archive.Archive) {
	r := (^Reader)(a.state)
	close(r)
	free(r, a.allocator)
}

@(private)
_archive_info :: proc(a: ^archive.Archive) -> archive.Archive_Info {
	return info((^Reader)(a.state))
}

@(private)
_archive_iterator_create :: proc(it: ^archive.Iterator) -> (err: Error) {
	t := new(Iterator, it.archive.allocator) or_return
	t^ = iterator_create((^Reader)(it.archive.state))
	it.state = t
	return
}

@(private)
_archive_iterator_destroy :: proc(it: ^archive.Iterator) {
	t := (^Iterator)(it.state)
	if t == nil {
		return
	}
	iterator_destroy(t)
	free(t, it.archive.allocator)
}

@(private)
_archive_iterate :: proc(it: ^archive.Iterator) -> (fi: archive.File_Info, index: int, ok: bool) {
	return iterate((^Iterator)(it.state))
}

@(private)
_archive_iterator_error :: proc(it: ^archive.Iterator) -> (path: string, err: Error) {
	return iterator_error((^Iterator)(it.state))
}

@(private)
_archive_extract_current :: proc(it: ^archive.Iterator, w: io.Writer) -> Error {
	return extract_current((^Iterator)(it.state), w)
}

@(private)
_archive_open_current :: proc(it: ^archive.Iterator) -> (reader: io.Reader, err: Error) {
	return open_current((^Iterator)(it.state))
}

@(private)
_archive_read_link :: proc(it: ^archive.Iterator, allocator: runtime.Allocator) -> (target: string, err: Error) {
	return read_link((^Iterator)(it.state), allocator)
}

@(private)
_archive_find :: proc(a: ^archive.Archive, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	return find((^Reader)(a.state), path)
}

@(private)
_archive_extract :: proc(a: ^archive.Archive, handle: archive.Handle, w: io.Writer) -> Error {
	return extract((^Reader)(a.state), handle, w)
}

@(private)
_archive_open_member :: proc(a: ^archive.Archive, handle: archive.Handle) -> (reader: io.Reader, err: Error) {
	return open_member((^Reader)(a.state), handle)
}
