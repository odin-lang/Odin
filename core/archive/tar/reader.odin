package archive_tar

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/xz"
import "core:io"
import "core:slice"
import "core:strings"
import "core:time"

/*
Opens a tar archive held in memory, plain or compressed with gzip, bzip2, LZ4, LZMA or XZ

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- data: The archive's bytes; they must stay valid until `close`
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)

Returns:
- err: `General_Error.Unknown_Format` if `data` starts with neither a tar header nor a compressed
  stream, the decoder's error, or `nil`
*/
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
	case .Plain:
		r.compression = .Store
		r.source      = .Memory
		r.data        = data
	case .Gzip:
		_start_decoder(r, .Deflate) or_return
	case .BZip2:
		_start_decoder(r, .BZip2) or_return
	case .LZ4:
		_start_decoder(r, .LZ4) or_return
	case .LZMA:
		_start_decoder(r, .LZMA) or_return
	case .XZ:
		_start_decoder(r, .XZ) or_return
	}
	return
}

/*
Opens a tar archive from a stream, plain or compressed with gzip, bzip2, LZ4, LZMA or XZ

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- s: The archive; it must read, and stay open until `close`, which leaves it open. If it can't
  seek, the members can be read only once, in order
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)

Returns:
- err: An error reading `s`, `General_Error.Unknown_Format` if `s` starts with neither a tar
  header nor a compressed stream, the decoder's error, or `nil`
*/
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
	n, head_err := io.read_full(s, r.head[:])
	if head_err == .EOF || head_err == .Unexpected_EOF {
		head_err = nil
	} else if head_err != nil && n == 0 {
		return head_err
	}
	r.prefix = {prefix = r.head[:n], stream = s, err = head_err}
	sniffed := _sniff(r.head[:n])
	switch sniffed {
	case .Unknown:
		return archive.General_Error.Unknown_Format
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
		_start_decoder(r, .Deflate) or_return
	case .BZip2:
		_start_decoder(r, .BZip2) or_return
	case .LZ4:
		_start_decoder(r, .LZ4) or_return
	case .LZMA:
		_start_decoder(r, .LZMA) or_return
	case .XZ:
		_start_decoder(r, .XZ) or_return
	}
	return
}

// Closes a reader or a writer
close :: proc{close_reader, close_writer}

/*
Closes a reader and frees its memory

Inputs:
- r: The reader; a stream given to `open_from_stream` is left open
*/
close_reader :: proc(r: ^Reader) {
	if r.source == .Decoder {
		_destroy_decoder(r)
	}
	compress.destroy_context(&r.ctx)
	delete(r.buf, r.allocator)
	delete(r.local_buf)
	delete(r.global_buf)
	for &value in r.globals {
		delete(value)
	}
	delete(r.path_buf)
	delete(r.long_name)
	delete(r.long_link)
	delete(r.label)
	delete(r.sparse_map)
	delete(r.fail_path)
	io.close(r.file)
	r^ = {}
}

/*
Summarizes an archive

Inputs:
- r: An open reader

Returns:
- info: Its format, compression, and volume label as the comment; `member_count` is -1 until a
  read has reached the end
*/
info :: proc(r: ^Reader) -> (info: archive.Archive_Info) {
	info.format       = .Tar
	info.member_count = r.member_count if r.ended else -1
	info.compression  = r.compression
	info.comment      = string(r.label[:])
	return
}

/*
Creates an iterator over an archive's members, in storage order

NOTE: The reader has one position, which its iterators, `find`, `extract` and `open_member`
share; creating an iterator rewinds it.

Inputs:
- r: An open reader

Returns:
- it: The iterator; destroy it with `iterator_destroy`. If the rewind fails, as on a stream that
  can't seek, `iterate` returns `false` and `iterator_error` tells why
*/
iterator_create :: proc(r: ^Reader) -> (it: Iterator) {
	it.reader = r
	it.err_path.allocator = r.allocator
	if r.index >= 0 {
		it.err = _rewind(r)
	}
	return
}

/*
Destroys an iterator

Inputs:
- it: The iterator
*/
iterator_destroy :: proc(it: ^Iterator) {
	delete(it.err_path)
	it^ = {}
}

/*
Moves to the next member

Inputs:
- it: The iterator

Returns:
- fi: The member's info; its strings last until the reader moves to another member, so keep them
  with `file_info_clone`
- index: The member's index, as in `fi.handle`
- ok: `false` after the last member or on an error; `iterator_error` tells which
*/
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

/*
Tells why iteration stopped

Inputs:
- it: The iterator

Returns:
- path: The path of the member the error is about, if any
- err: The error that stopped iteration, `nil` if it reached the end
*/
@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	return string(it.err_path[:]), it.err
}

/*
Writes the current member's data to a writer; a sparse file's holes are written as zeros

The data is read once: what this or `open_current`'s reader has read is gone.

Inputs:
- it: The iterator, on the member `iterate` returned last
- w: Where the member's data is written

Returns:
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
extract_current :: proc(it: ^Iterator, w: io.Writer) -> (err: Error) {
	return _extract(it.reader, w)
}

/*
Opens the current member's data as a reader, which decompresses as it is read

The data is read once: what this reader or `extract_current` has read is gone.

Inputs:
- it: The iterator, on the member `iterate` returned last

Returns:
- reader: The member's reader; it reads at the reader's position and lasts until that moves to
  another member
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
open_current :: proc(it: ^Iterator) -> (reader: io.Reader, err: Error) {
	return _open_current(it.reader)
}

/*
Reads the current member's link target, which tar stores in the header

*Allocates Using Provided Allocator*

Inputs:
- it: The iterator, on the member `iterate` returned last
- allocator: (default: context.allocator)

Returns:
- target: The target stored with the member: a symlink's or a hard link's; `delete` it
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, an allocator
  error, or `nil`
*/
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

/*
Returns the current member's raw header, for what `File_Info` leaves out

Inputs:
- it: The iterator, on the member `iterate` returned last

Returns:
- entry: The member's header block, with its pax records; `nil` if `iterate` hasn't returned a
  member. It lasts until the reader moves to another member
*/
current_entry :: proc(it: ^Iterator) -> (entry: ^Entry) {
	if !it.reader.has_current {
		return nil
	}
	return &it.reader.header
}

/*
Splits the first pax record off a block of them, such as `Entry.local_records`

Inputs:
- records: The records; advanced past the first one when `ok`

Returns:
- key: The record's key, a slice of `records`
- value: The record's value, a slice of `records`
- ok: `false` at the end or on a malformed record
*/
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

/*
Finds a member by path, moving the reader's position to it

NOTE: The search starts at the current member and goes forward, then rewinds and goes on up to
where it started. Of several members with the path, it finds the next one. Searching forward
first saves decompressing a compressed archive again from the start, and works on a pipe.

Inputs:
- r: An open reader
- path: The member's path, ignoring a leading `./` or trailing `/`

Returns:
- fi: The member's info; its strings last as long as those from `iterate`
- handle: The member, for `extract` and `open_member`
- ok: `false` if no member has the path
- err: An error reading the archive, `General_Error.Not_Seekable` if a stream needs a rewind it
  can't do, or `nil`
*/
find :: proc(r: ^Reader, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	want := archive._clean_member_path(path)
	if r.has_current && r.current.path == want {
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
		if info.path == want {
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
		if info.path == want {
			return info, info.handle, true, nil
		}
	}
	return {}, {}, false, broken
}

/*
Writes a member's data to a writer, moving the reader's position to it

Going back to an earlier member rewinds the reader.

Inputs:
- r: An open reader
- handle: The member, from `File_Info.handle` or `find`
- w: Where the member's data is written

Returns:
- err: `General_Error.Not_Found` for a handle past the last member, `General_Error.Not_Seekable`
  if a stream needs a rewind it can't do, the member's error, or `nil`
*/
extract :: proc(r: ^Reader, handle: archive.Handle, w: io.Writer) -> (err: Error) {
	_seek_member(r, handle.index) or_return
	return _extract(r, w)
}

/*
Opens a member's data as a reader, moving the reader's position to it

Going back to an earlier member rewinds the reader.

Inputs:
- r: An open reader
- handle: The member, from `File_Info.handle` or `find`

Returns:
- reader: The member's reader; it reads at the reader's position and lasts until that moves to
  another member. It needs no `close_member`
- err: `General_Error.Not_Found` for a handle past the last member, `General_Error.Not_Seekable`
  if a stream needs a rewind it can't do, the member's error, or `nil`
*/
open_member :: proc(r: ^Reader, handle: archive.Handle) -> (reader: io.Reader, err: Error) {
	_seek_member(r, handle.index) or_return
	return _open_current(r)
}

@(init, private)
_register :: proc "contextless" () {
	archive._register(.Tar, {
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
	r.long_name.allocator  = allocator
	r.long_link.allocator  = allocator
	r.label.allocator      = allocator
	r.sparse_map.allocator = allocator
	r.fail_path.allocator  = allocator
}

@(private)
_memory :: #force_inline proc "contextless" (r: ^Reader) -> bool {
	return r.source == .Memory
}

@(private)
_start_decoder :: proc(r: ^Reader, method: archive.Method) -> (err: Error) {
	if r.input.procedure == nil {
		r.ctx = compress.init_context_from_slice(&r.input_data)
	} else {
		r.ctx = compress.init_context_from_stream(_prefix_stream(r), nil, nil, r.allocator) or_return
	}
	r.compression = method
	r.source      = .Decoder
	decoder_err: compress.Error
	#partial switch method {
	case .Deflate:
		decoder_err = deflate.reader_init(&r.inflate, &r.ctx, .Gzip, -1, r.options, r.allocator)
	case .BZip2:
		decoder_err = bzip2.reader_init(&r.bzip2_reader, &r.ctx, -1, r.options, r.allocator)
	case .LZ4:
		decoder_err = lz4.frame_reader_init(&r.lz4_reader, &r.ctx, -1, r.options, nil, r.allocator)
	case .LZMA:
		decoder_err = lzma.reader_init(&r.lzma_reader, &r.ctx, -1, r.options, r.allocator)
	case .XZ:
		decoder_err = xz.reader_init(&r.xz_reader, &r.ctx, {}, -1, r.options, r.allocator)
	case:
		panic("archive/tar: no stream decoder for this method")
	}
	if decoder_err != nil {
		return decoder_err
	}
	if r.buf == nil {
		r.buf = make([]u8, BUFFER_SIZE, r.allocator) or_return
	}
	r.pos, r.end, r.offset = 0, 0, 0
	return
}

@(private)
_decoder_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: compress.Error) {
	#partial switch r.compression {
	case .Deflate:
		return deflate.reader_read(&r.inflate, p)
	case .BZip2:
		return bzip2.reader_read(&r.bzip2_reader, p)
	case .LZ4:
		return lz4.frame_reader_read(&r.lz4_reader, p)
	case .LZMA:
		return lzma.reader_read(&r.lzma_reader, p)
	case .XZ:
		return xz.reader_read(&r.xz_reader, p)
	}
	panic("archive/tar: no stream decoder for this method")
}

@(private)
_destroy_decoder :: proc(r: ^Reader) {
	#partial switch r.compression {
	case .Deflate:
		deflate.reader_destroy(&r.inflate)
	case .BZip2:
		bzip2.reader_destroy(&r.bzip2_reader)
	case .LZ4:
		lz4.frame_reader_destroy(&r.lz4_reader)
	case .LZMA:
		lzma.reader_destroy(&r.lzma_reader)
	case .XZ:
		xz.reader_destroy(&r.xz_reader)
	}
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
	if len(p) == 0 {
		return 0, false, nil
	}
	got: int
	read_err: Error
	for _ in 0..=100 {
		if r.source == .Decoder {
			decoder_err: compress.Error
			got, decoder_err = _decoder_read(r, p)
			if io_err, is_io := decoder_err.(io.Error); is_io && io_err == .EOF {
				return got, true, nil
			}
			read_err = decoder_err
		} else {
			stream_err: io.Error
			got, stream_err = io.read(r.stream, p)
			if stream_err == .EOF {
				return got, true, nil
			}
			read_err = stream_err
		}
		if got > 0 || read_err != nil {
			break
		}
	}
	if read_err != nil {
		if got > 0 {
			r.pending = read_err
			return got, false, nil
		}
		return 0, false, read_err
	}
	if got == 0 {
		return 0, false, io.Error.No_Progress
	}
	return got, false, nil
}

@(private)
_drain :: proc(r: ^Reader) -> (err: Error) {
	r.pos, r.end = 0, 0
	for {
		_, eof := _source_read(r, r.buf) or_return
		if eof {
			return
		}
	}
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
		if count > max(i64) - r.input_start - r.offset {
			return Tar_Error.Truncated
		}
		if r.input_size >= 0 && count > r.input_size - r.input_start - r.offset {
			return Tar_Error.Truncated
		}
		target := r.offset + count
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
	case .Memory:
		r.pos = 0
	case .Stream:
		if !r.seekable {
			return archive.General_Error.Not_Seekable
		}
		if _, seek_err := io.seek(r.input, r.input_start, .Start); seek_err != nil {
			return seek_err
		}
		r.pos, r.end, r.offset = 0, 0, 0
	case .Decoder:
		if r.input.procedure != nil {
			if !r.seekable {
				return archive.General_Error.Not_Seekable
			}
			if _, seek_err := io.seek(r.input, r.input_start, .Start); seek_err != nil {
				return seek_err
			}
			r.prefix = {stream = r.input}
		}
		_destroy_decoder(r)
		compress.destroy_context(&r.ctx)
		_start_decoder(r, r.compression) or_return
	}
	r.index       = -1
	r.remaining   = 0
	r.padding     = 0
	r.ended       = false
	r.has_current = false
	r.unsupported = nil
	r.broken      = nil
	r.pending     = nil
	_clear_member(r)
	r.global_set = {}
	r.gnu_sparse = false
	clear(&r.fail_path)
	return
}

@(private)
_clear_member :: proc(r: ^Reader) {
	clear(&r.local_buf)
	clear(&r.global_buf)
	clear(&r.long_name)
	clear(&r.long_link)
	clear(&r.sparse_map)
	r.has_long     = {}
	r.sparse       = false
	r.sparse_index = 0
	r.sparse_pos   = 0
	r.data_size    = 0
}

@(private)
_seek_member :: proc(r: ^Reader, index: int) -> (err: Error) {
	if index < 0 {
		return archive.General_Error.Not_Found
	}
	if r.has_current && r.index == index && r.remaining == r.data_size && r.sparse_pos == 0 {
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
	_clear_member(r)
	for {
		block, eof := _next_block(r) or_return
		if eof || _all_zero(block) {
			if r.source == .Decoder {
				_drain(r) or_return
			}
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
		if size < 0 || size > MEMBER_SIZE_MAX {
			return {}, false, Tar_Error.Invalid_Size
		}
		switch typeflag {
		case 'x', 'g':
			_read_records(r, typeflag, size) or_return
			continue
		case 'L', 'K':
			_read_long(r, typeflag, size) or_return
			continue
		case 'V':
			_read_label(r, size) or_return
			continue
		}
		fi = _make_info(r, typeflag, size) or_return
		return fi, true, nil
	}
}

@(private)
_held :: proc "contextless" (r: ^Reader) -> i64 {
	held := i64(len(r.local_buf) + len(r.global_buf) + len(r.long_name) + len(r.long_link))
	return held + i64(len(r.sparse_map)) * size_of(Sparse_Region)
}

@(private)
_record_limit :: proc "contextless" (r: ^Reader) -> i64 {
	return min(i64(HEADER_RECORD_MAX), i64(compress.memory_limit(r.options)))
}

@(private)
_read_long :: proc(r: ^Reader, typeflag: u8, size: i64) -> (err: Error) {
	kind := Long_Kind.Name if typeflag == 'L' else .Link
	buf  := &r.long_name if kind == .Name else &r.long_link
	if _held(r) - i64(len(buf)) + size > _record_limit(r) {
		return Tar_Error.Header_Too_Large
	}
	resize(buf, int(size)) or_return
	_read_exact(r, buf[:]) or_return
	_skip(r, _padding(size)) or_return
	r.has_long += {kind}
	return
}

@(private)
_read_label :: proc(r: ^Reader, size: i64) -> (err: Error) {
	if !r.has_label {
		append(&r.label, _field(r.header.block[0:100])) or_return
		r.has_label = true
	}
	return _skip(r, size + _padding(size))
}

@(private)
_read_records :: proc(r: ^Reader, typeflag: u8, size: i64) -> (err: Error) {
	if _held(r) + size > _record_limit(r) {
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
		case "path", "linkpath", "uname", "gname", "GNU.sparse.name":
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

	if .Name in r.has_long {
		fi.path = _field(r.long_name[:])
	} else {
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
	}
	fi.link_target = _field(h[157:257])
	if .Link in r.has_long {
		fi.link_target = _field(r.long_link[:])
	}

	mode  := _parse_number(h[100:108]) or_return
	fi.uid = _parse_number(h[108:116]) or_return
	fi.gid = _parse_number(h[116:124]) or_return
	if mode < 0 || fi.uid < 0 || fi.gid < 0 {
		return {}, Tar_Error.Invalid_Number
	}
	mtime := _parse_number(h[136:148]) or_return
	fi.modification_time = _unix_time(mtime, 0)
	if format != .V7 {
		fi.user  = _field(h[265:297])
		fi.group = _field(h[297:329])
		major := _parse_number(h[329:337]) or_return
		minor := _parse_number(h[337:345]) or_return
		if major < 0 || minor < 0 || major > i64(max(u32)) || minor > i64(max(u32)) {
			return {}, Tar_Error.Invalid_Number
		}
		fi.device = {u32(major), u32(minor)}
	}
	if format == .GNU {
		if atime, atime_err := _parse_number(h[345:357]); atime_err == nil && atime != 0 {
			fi.access_time = _unix_time(atime, 0)
		}
	}

	r.header.global_records = r.global_buf[:]
	r.header.local_records  = r.local_buf[:]
	data_size := size
	base      := fi
	for slot in r.global_set {
		_apply_record(&fi, &data_size, base, size, GLOBAL_KEYS[slot], string(r.globals[slot][:]))
	}
	_apply_records(&fi, &data_size, base, size, r.local_buf[:]) or_return
	fi.extended_metadata = len(r.local_buf) > 0 || len(r.global_buf) > 0
	if data_size < 0 || data_size > MEMBER_SIZE_MAX {
		return {}, Tar_Error.Invalid_Size
	}

	switch typeflag {
	case '0', 0, '7', 'S', 'M':
		fi.type = .Regular
		if (typeflag == '0' || typeflag == 0) && strings.has_suffix(fi.path, "/") {
			fi.type = .Directory
		}
	case '1':      fi.type = .Hard_Link
	case '2':      fi.type = .Symlink
	case '3':      fi.type = .Character_Device
	case '4':      fi.type = .Block_Device
	case '5', 'D': fi.type = .Directory
	case '6':      fi.type = .Named_Pipe
	case:          fi.type = .Unknown
	}
	hidden := i64(0)
	switch typeflag {
	case '1', '2', '3', '4', '5', '6':
		data_size = 0
	case 'D':
		hidden    = data_size
		data_size = 0
	}

	stored    := data_size
	physical  := data_size
	sparse    := false
	unsparsed := r.gnu_sparse
	if typeflag == 'S' {
		real_size := _gnu_sparse(r) or_return
		_check_sparse(r, real_size, physical) or_return
		data_size, sparse = real_size, true
	} else if fi.type == .Regular && !unsparsed {
		keys      := _pax_sparse_keys(r)
		version_1 := keys.major == "1" && keys.minor == "0"
		version_0 := (keys.major == "" && keys.minor == "") || (keys.major == "0" && (keys.minor == "0" || keys.minor == "1"))
		version_0  = version_0 && (keys.has_map || keys.has_pairs)
		if version_1 {
			real_size := _sparse_number(keys.size) or_return
			used      := _read_sparse_map(r, stored) or_return
			physical   = stored - used
			_check_sparse(r, real_size, physical) or_return
			data_size  = real_size
		} else if version_0 {
			real_size := _sparse_number(keys.size) or_return
			blocks    := _sparse_number(keys.numblocks) or_return
			if keys.has_map {
				_parse_sparse_map(r, keys.sparse_map) or_return
			} else {
				_collect_sparse_pairs(r) or_return
			}
			if i64(len(r.sparse_map)) != blocks {
				return {}, Tar_Error.Invalid_Sparse_Map
			}
			_check_sparse(r, real_size, physical) or_return
			data_size = real_size
		}
		if version_1 || version_0 {
			sparse = true
			if keys.name != "" {
				fi.path = keys.name
			}
		} else if keys.has_keys {
			unsparsed = true
		}
	}

	fi.raw_path = transmute([]u8)fi.path
	fi.path     = archive._clean_member_path(fi.path)

	fi.size            = data_size
	fi.compressed_size = stored if r.compression == .Store else -1
	fi.method          = .Store
	fi.unix_mode       = u32(mode & archive.UNIX_PERMISSION_MASK) | archive._unix_type_bits(fi.type)
	fi.dos_attributes  = archive._dos_attributes_from_unix(fi.unix_mode, fi.type)
	fi.supported       = true
	r.unsupported      = nil
	if unsparsed || typeflag == 'M' {
		fi.supported  = false
		r.unsupported = Tar_Error.Unsupported_GNU_Extension
	} else if fi.type == .Unknown {
		fi.supported  = false
		r.unsupported = archive.General_Error.Unsupported_Entry
	}

	r.index       += 1
	fi.handle      = {index = r.index}
	r.sparse       = sparse
	r.sparse_index = 0
	r.sparse_pos   = 0
	r.remaining    = physical
	r.padding      = _padding(physical) + hidden + _padding(hidden)
	r.data_size    = physical
	r.current      = fi
	r.has_current  = true
	return
}

@(private)
_gnu_sparse :: proc(r: ^Reader) -> (real_size: i64, err: Error) {
	h := r.header.block[:]
	_gnu_sparse_entries(r, h[386:482], SPARSE_IN_HEADER) or_return
	extended := h[482] != 0
	number_err: Error
	real_size, number_err = _parse_number(h[483:495])
	if number_err != nil {
		return 0, Tar_Error.Invalid_Sparse_Map
	}
	for extended {
		block, eof := _next_block(r) or_return
		if eof {
			return 0, Tar_Error.Truncated
		}
		_gnu_sparse_entries(r, block[:SPARSE_IN_BLOCK * 24], SPARSE_IN_BLOCK) or_return
		extended = block[SPARSE_IN_BLOCK * 24] != 0
	}
	return
}

@(private)
_gnu_sparse_entries :: proc(r: ^Reader, entries: []u8, count: int) -> (err: Error) {
	for i in 0..<count {
		entry := entries[i * 24:][:24]
		if entry[0] == 0 {
			break
		}
		offset, offset_err := _parse_number(entry[0:12])
		size,   size_err   := _parse_number(entry[12:24])
		if offset_err != nil || size_err != nil {
			return Tar_Error.Invalid_Sparse_Map
		}
		_add_region(r, offset, size) or_return
	}
	return
}

@(private)
_pax_sparse_keys :: proc(r: ^Reader) -> (keys: Pax_Sparse) {
	PREFIX :: "GNU.sparse."
	rest := r.local_buf[:]
	for len(rest) > 0 && !_all_zero(rest) {
		key, value, next, ok := _next_record(rest)
		if !ok {
			break
		}
		rest = next
		if !strings.has_prefix(key, PREFIX) {
			continue
		}
		keys.has_keys = true
		switch key[len(PREFIX):] {
		case "major":            keys.major = value
		case "minor":            keys.minor = value
		case "name":             keys.name = value
		case "size", "realsize": keys.size = value
		case "numblocks":        keys.numblocks = value
		case "map":
			keys.sparse_map = value
			keys.has_map    = true
		case "offset", "numbytes":
			keys.has_pairs = true
		}
	}
	return
}

@(private)
_sparse_number :: proc "contextless" (s: string) -> (value: i64, err: Error) {
	ok: bool
	if value, ok = _parse_decimal(s); !ok {
		return 0, Tar_Error.Invalid_Sparse_Map
	}
	return
}

@(private)
_parse_sparse_map :: proc(r: ^Reader, s: string) -> (err: Error) {
	if s == "" {
		return
	}
	rest    := s
	count   := 0
	pending := i64(0)
	for {
		comma := strings.index_byte(rest, ',')
		part  := rest if comma < 0 else rest[:comma]
		value := _sparse_number(part) or_return
		if count % 2 == 0 {
			pending = value
		} else {
			_add_region(r, pending, value) or_return
		}
		count += 1
		if comma < 0 {
			break
		}
		rest = rest[comma + 1:]
	}
	if count % 2 != 0 {
		return Tar_Error.Invalid_Sparse_Map
	}
	return
}

@(private)
_collect_sparse_pairs :: proc(r: ^Reader) -> (err: Error) {
	rest    := r.local_buf[:]
	offset  := true
	pending := i64(0)
	for len(rest) > 0 && !_all_zero(rest) {
		key, value, next, ok := _next_record(rest)
		if !ok {
			break
		}
		rest = next
		switch key {
		case "GNU.sparse.offset":
			if !offset {
				return Tar_Error.Invalid_Sparse_Map
			}
			pending = _sparse_number(value) or_return
			offset  = false
		case "GNU.sparse.numbytes":
			if offset {
				return Tar_Error.Invalid_Sparse_Map
			}
			size := _sparse_number(value) or_return
			_add_region(r, pending, size) or_return
			offset = true
		}
	}
	if !offset {
		return Tar_Error.Invalid_Sparse_Map
	}
	return
}

@(private)
_read_sparse_map :: proc(r: ^Reader, stored: i64) -> (used: i64, err: Error) {
	block:   [BLOCK_SIZE]u8
	count   := i64(-1)
	numbers := i64(0)
	value   := i64(0)
	digits  := 0
	pending := i64(0)
	for {
		if stored - used < BLOCK_SIZE {
			return 0, Tar_Error.Invalid_Sparse_Map
		}
		_read_exact(r, block[:]) or_return
		used += BLOCK_SIZE
		for c in block {
			switch c {
			case '0'..='9':
				if value > (max(i64) - i64(c - '0')) / 10 {
					return 0, Tar_Error.Invalid_Sparse_Map
				}
				value   = value * 10 + i64(c - '0')
				digits += 1
			case '\n':
				if digits == 0 {
					return 0, Tar_Error.Invalid_Sparse_Map
				}
				if count < 0 {
					count = value
				} else if numbers % 2 == 0 {
					pending  = value
					numbers += 1
				} else {
					_add_region(r, pending, value) or_return
					numbers += 1
				}
				value, digits = 0, 0
				if numbers % 2 == 0 && numbers / 2 == count {
					return used, nil
				}
			case:
				return 0, Tar_Error.Invalid_Sparse_Map
			}
		}
	}
}

@(private)
_add_region :: proc(r: ^Reader, offset, size: i64) -> (err: Error) {
	if offset < 0 || size < 0 {
		return Tar_Error.Invalid_Sparse_Map
	}
	if _held(r) + size_of(Sparse_Region) > _record_limit(r) {
		return Tar_Error.Header_Too_Large
	}
	append(&r.sparse_map, Sparse_Region{offset, size}) or_return
	return
}

@(private)
_check_sparse :: proc "contextless" (r: ^Reader, real_size, physical: i64) -> (err: Error) {
	if real_size < 0 || real_size > MEMBER_SIZE_MAX {
		return Tar_Error.Invalid_Sparse_Map
	}
	end   := i64(0)
	total := i64(0)
	for region in r.sparse_map {
		if region.offset < end || region.offset > real_size || region.size > real_size - region.offset {
			return Tar_Error.Invalid_Sparse_Map
		}
		end    = region.offset + region.size
		total += region.size
	}
	if total != physical {
		return Tar_Error.Invalid_Sparse_Map
	}
	return
}

@(private)
_apply_records :: proc(fi: ^archive.File_Info, size: ^i64, base: archive.File_Info, base_size: i64, records: []u8) -> (err: Error) {
	rest := records
	for len(rest) > 0 && !_all_zero(rest) {
		key, value, next, ok := _next_record(rest)
		if !ok {
			return Tar_Error.Invalid_Pax_Record
		}
		rest = next
		_apply_record(fi, size, base, base_size, key, value)
	}
	return
}

@(private)
_apply_record :: proc(fi: ^archive.File_Info, size: ^i64, base: archive.File_Info, base_size: i64, key, value: string) {
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
	}
}

@(private)
_parse_number :: proc "contextless" (field: []u8) -> (value: i64, err: Error) {
	ok: bool
	if len(field) > 0 && field[0] & 0x80 != 0 {
		value, ok = _parse_base256(field)
	} else {
		value, ok = _parse_octal(field)
	}
	if !ok {
		return 0, Tar_Error.Invalid_Number
	}
	return
}

@(private)
_parse_base256 :: proc "contextless" (field: []u8) -> (value: i64, ok: bool) {
	negative := field[0] & 0x40 != 0
	fill     := u8(0xff) if negative else 0
	first    := field[0] & 0x7f | (0x80 if negative else 0)
	extra    := len(field) - 8
	bits     := u64(0)
	if extra < 0 && negative {
		bits = max(u64)
	}
	for b, i in field {
		c := first if i == 0 else b
		if i < extra {
			if c != fill {
				return 0, false
			}
			continue
		}
		bits = bits << 8 | u64(c)
	}
	value = i64(bits)
	if (value < 0) != negative {
		return 0, false
	}
	return value, true
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
	switch {
	case seconds > max(i64) / 1e9: return {max(i64)}
	case seconds < min(i64) / 1e9: return {min(i64)}
	}
	whole := seconds * 1e9
	switch {
	case nanoseconds > 0 && whole > max(i64) - nanoseconds: return {max(i64)}
	case nanoseconds < 0 && whole < min(i64) - nanoseconds: return {min(i64)}
	}
	return {whole + nanoseconds}
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
	if !r.sparse {
		return _extract_data(r, w, r.remaining)
	}
	for r.sparse_pos < r.current.size {
		in_data, until := _sparse_step(r)
		count := until - r.sparse_pos
		if in_data {
			_extract_data(r, w, count) or_return
		} else {
			_write_zeros(w, count) or_return
		}
		r.sparse_pos += count
	}
	return
}

@(private)
_extract_data :: proc(r: ^Reader, w: io.Writer, count: i64) -> (err: Error) {
	count := count
	if _memory(r) {
		n := min(count, i64(len(r.data) - r.pos))
		if n > 0 {
			if _, write_err := io.write_full(w, r.data[r.pos:][:n]); write_err != nil {
				return write_err
			}
			r.pos       += int(n)
			r.remaining -= n
			count       -= n
		}
		if count > 0 {
			return Tar_Error.Truncated
		}
		return
	}
	for count > 0 {
		if r.pos == r.end {
			available := _fill(r, 1) or_return
			if available == 0 {
				return Tar_Error.Truncated
			}
		}
		n := min(count, i64(r.end - r.pos))
		if _, write_err := io.write_full(w, r.buf[r.pos:][:n]); write_err != nil {
			return write_err
		}
		r.pos       += int(n)
		r.offset    += n
		r.remaining -= n
		count       -= n
	}
	return
}

@(private)
_sparse_step :: proc "contextless" (r: ^Reader) -> (in_data: bool, until: i64) {
	for r.sparse_index < len(r.sparse_map) {
		region := r.sparse_map[r.sparse_index]
		if region.offset + region.size > r.sparse_pos {
			if region.offset <= r.sparse_pos {
				return true, region.offset + region.size
			}
			return false, region.offset
		}
		r.sparse_index += 1
	}
	return false, r.current.size
}

@(private)
_write_zeros :: proc(w: io.Writer, count: i64) -> (err: Error) {
	zero: [ZERO_CHUNK_SIZE]u8
	count := count
	for count > 0 {
		n := min(count, ZERO_CHUNK_SIZE)
		if _, write_err := io.write_full(w, zero[:n]); write_err != nil {
			return write_err
		}
		count -= n
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
	if !r.sparse {
		return _read_data(r, p)
	}
	if r.sparse_pos >= r.current.size {
		return 0, io.Error.EOF
	}
	if len(p) == 0 {
		return 0, nil
	}
	in_data, until := _sparse_step(r)
	count := int(min(i64(len(p)), until - r.sparse_pos))
	if in_data {
		n = _read_data(r, p[:count]) or_return
	} else {
		slice.zero(p[:count])
		n = count
	}
	r.sparse_pos += i64(n)
	return
}

@(private)
_read_data :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
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
_archive_open_bytes :: proc(a: ^archive.Archive, data: []u8, options: compress.Options, _: archive.Read_Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_bytes(r, data, options, a.allocator); err != nil {
		free(r, a.allocator)
		return
	}
	a.state = r
	return
}

@(private)
_archive_open_stream :: proc(a: ^archive.Archive, s: io.Stream, options: compress.Options, _: archive.Read_Options) -> (err: Error) {
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
_archive_extract_current :: proc(it: ^archive.Iterator, w: io.Writer, _: archive.Read_Options) -> Error {
	return extract_current((^Iterator)(it.state), w)
}

@(private)
_archive_open_current :: proc(it: ^archive.Iterator, _: archive.Read_Options) -> (reader: io.Reader, err: Error) {
	return open_current((^Iterator)(it.state))
}

@(private)
_archive_read_link :: proc(it: ^archive.Iterator, _: archive.Read_Options, allocator: runtime.Allocator) -> (target: string, err: Error) {
	return read_link((^Iterator)(it.state), allocator)
}

@(private)
_archive_find :: proc(a: ^archive.Archive, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	return find((^Reader)(a.state), path)
}

@(private)
_archive_extract :: proc(a: ^archive.Archive, handle: archive.Handle, w: io.Writer, _: archive.Read_Options) -> Error {
	return extract((^Reader)(a.state), handle, w)
}

@(private)
_archive_open_member :: proc(a: ^archive.Archive, handle: archive.Handle, _: archive.Read_Options) -> (reader: io.Reader, err: Error) {
	return open_member((^Reader)(a.state), handle)
}
