package archive_sevenz

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/filters"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:crypto/aes"
import "core:hash"
import "core:io"
import "core:slice"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

/*
Opens a 7z archive held in memory

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- data: The archive's bytes; they must stay valid until `close`
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)
- read_options: The default password, which an encrypted header needs, and the key-derivation
  limit (default: {})

Returns:
- err: A `SevenZ_Error` for a malformed archive, `General_Error.Encrypted` or
  `General_Error.Wrong_Password` for an encrypted header, or `nil`
*/
open_from_bytes :: proc(r: ^Reader, data: []u8, options := compress.Options{}, allocator := context.allocator, read_options := archive.Read_Options{}) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
	_read_options(r, read_options) or_return
	r.store = {data = data, size = i64(len(data)), memory = true}
	return _load(r)
}

/*
Opens a 7z archive from a stream

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- s: The archive; it must read at an offset or seek, report its size, and stay open until `close`,
  which leaves it open
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)
- read_options: The default password, which an encrypted header needs, and the key-derivation
  limit (default: {})

Returns:
- err: `General_Error.Not_Seekable`, a `SevenZ_Error` for a malformed archive,
  `General_Error.Encrypted` or `General_Error.Wrong_Password` for an encrypted header, or `nil`
*/
open_from_stream :: proc(r: ^Reader, s: io.Stream, options := compress.Options{}, allocator := context.allocator, read_options := archive.Read_Options{}) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
	_read_options(r, read_options) or_return
	modes := io.query(s)
	if .Read_At not_in modes && (.Seek not_in modes || .Read not_in modes) {
		return archive.General_Error.Not_Seekable
	}
	size, size_err := io.size(s)
	if size_err != nil {
		return archive.General_Error.Not_Seekable
	}
	r.store = {stream = s, size = size}
	return _load(r)
}

// Closes a reader or a writer
close :: proc{close_reader, close_writer}

/*
Closes a reader and frees its memory

Inputs:
- r: The reader; a stream given to `open_from_stream` is left open
*/
close_reader :: proc(r: ^Reader) {
	if r.owns_header {
		delete(r.header, r.allocator)
	}
	_streams_destroy(&r.streams)
	delete(r.items, r.allocator)
	delete(r.names, r.allocator)
	delete(r.index, r.allocator)
	_key_cache_destroy(&r.keys)
	archive._secret_delete(transmute([]u8)r.password, r.allocator)
	archive._ranges_delete(r.journal, r.allocator)
	io.close(r.file)
	r^ = {}
}

/*
Summarizes an archive

Inputs:
- r: An open reader

Returns:
- info: Its format and member count, and the method all folders share, else `.Unknown`
*/
info :: proc(r: ^Reader) -> (info: archive.Archive_Info) {
	info.format       = .SevenZ
	info.member_count = len(r.items)
	info.compression  = .Unknown
	for f, i in r.streams.folders {
		if i == 0 {
			info.compression = f.method
		} else if f.method != info.compression {
			info.compression = .Unknown
			break
		}
	}
	return
}

/*
Creates an iterator over an archive's members, in storage order

Reading members in this order decodes each solid folder once.

Inputs:
- r: An open reader

Returns:
- it: The iterator; destroy it with `iterator_destroy`
*/
iterator_create :: proc(r: ^Reader) -> (it: Iterator) {
	it.reader = r
	it.index  = -1
	return
}

/*
Destroys an iterator, along with the reader `open_current` returned

Inputs:
- it: The iterator
*/
iterator_destroy :: proc(it: ^Iterator) {
	_member_destroy(&it.member)
	_decoder_destroy(&it.decoder)
	it^ = {}
}

/*
Moves to the next member

Inputs:
- it: The iterator

Returns:
- fi: The member's info; its strings last until `close`
- index: The member's index, as in `fi.handle`
- ok: `false` after the last member
*/
iterate :: proc(it: ^Iterator) -> (fi: archive.File_Info, index: int, ok: bool) {
	r := it.reader
	if r == nil {
		return {}, -1, false
	}
	_member_destroy(&it.member)
	if it.index + 1 >= len(r.items) {
		it.index = len(r.items)
		return {}, -1, false
	}
	it.index += 1
	return _info(r, it.index), it.index, true
}

/*
Tells why iteration stopped

Inputs:
- it: The iterator

Returns:
- path: Always empty
- err: Always `nil`: the header was read at open
*/
@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	return "", nil
}

/*
Returns the current member's entry in the archive header, for what `File_Info` leaves out

Inputs:
- it: The iterator, on the member `iterate` returned last

Returns:
- entry: The member's entry from the archive header, which lasts until `close`; `nil` if
  `iterate` hasn't returned a member
*/
current_entry :: proc(it: ^Iterator) -> (entry: ^Entry) {
	if !_has_current(it) {
		return nil
	}
	return &it.reader.items[it.index]
}

/*
Writes the current member's data to a writer, decompressed and checked

Inputs:
- it: The iterator, on the member `iterate` returned last
- w: Where the member's data is written
- options: The member's password, if encrypted; else the one given at open (default: {})

Returns:
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
extract_current :: proc(it: ^Iterator, w: io.Writer, options := archive.Read_Options{}) -> (err: Error) {
	if !_has_current(it) {
		return archive.General_Error.No_Current_Member
	}
	_member_destroy(&it.member)
	password := _password(it.reader, options)
	d := _iterator_decoder(it, password) or_return
	return _extract(it.reader, it.index, d, w, password)
}

/*
Opens the current member's data as a reader, which decompresses as it is read

Inputs:
- it: The iterator, on the member `iterate` returned last
- options: The member's password, if encrypted; else the one given at open (default: {})

Returns:
- reader: The member's reader; it belongs to the iterator and lasts until the next `iterate` or
  `open_current`
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
open_current :: proc(it: ^Iterator, options := archive.Read_Options{}) -> (reader: io.Reader, err: Error) {
	if !_has_current(it) {
		return {}, archive.General_Error.No_Current_Member
	}
	_member_destroy(&it.member)
	password := _password(it.reader, options)
	d := _iterator_decoder(it, password) or_return
	_member_init(&it.member, it.reader, it.index, d, it.reader.allocator, password) or_return
	return _member_stream(&it.member), nil
}

/*
Reads the current member's link target, which 7z stores as the member's data

*Allocates Using Provided Allocator*

Inputs:
- it: The iterator, on the member `iterate` returned last
- options: The member's password, if encrypted; else the one given at open (default: {})
- allocator: (default: context.allocator)

Returns:
- target: The symlink's target, empty for other members; `delete` it
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member,
  `General_Error.Limit_Exceeded` past `archive.LINK_TARGET_MAX`, the member's error, or `nil`
*/
read_link :: proc(it: ^Iterator, options := archive.Read_Options{}, allocator := context.allocator) -> (target: string, err: Error) {
	if !_has_current(it) {
		return "", archive.General_Error.No_Current_Member
	}
	_member_destroy(&it.member)
	fi := _info(it.reader, it.index)
	if fi.type != .Symlink {
		return "", nil
	}
	if fi.size > archive.LINK_TARGET_MAX {
		return "", archive.General_Error.Limit_Exceeded
	}
	password := _password(it.reader, options)
	d := _iterator_decoder(it, password) or_return
	return _read_link(it.reader, it.index, d, allocator, password)
}

/*
Finds a member by path

NOTE: Of several members with the path, the first in storage order is found.

Inputs:
- r: An open reader
- path: The member's path, ignoring a leading `./` or trailing `/`

Returns:
- fi: The member's info; its strings last until `close`
- handle: The member, for `extract` and `open_member`
- ok: `false` if no member has the path
- err: Always `nil`: the header was read at open
*/
find :: proc(r: ^Reader, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	want := archive._clean_member_path(path)
	lo, hi := 0, len(r.index)
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if r.index[mid].path < want {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	if lo >= len(r.index) || r.index[lo].path != want {
		return {}, {}, false, nil
	}
	fi = _info(r, r.index[lo].position)
	return fi, fi.handle, true, nil
}

/*
Writes a member's data to a writer, decompressed and checked

In a solid folder, the folder is decoded from its start up to the member.

Inputs:
- r: An open reader
- handle: The member, from `File_Info.handle` or `find`
- w: Where the member's data is written
- options: The member's password, if encrypted; else the one given at open (default: {})

Returns:
- err: `General_Error.Not_Found` for a stale handle, the member's error, or `nil`
*/
extract :: proc(r: ^Reader, handle: archive.Handle, w: io.Writer, options := archive.Read_Options{}) -> (err: Error) {
	index := _handle_index(r, handle) or_return
	return _extract(r, index, nil, w, _password(r, options))
}

/*
Opens a member's data as a reader, which decompresses as it is read

In a solid folder, the folder is decoded from its start up to the member.

*Allocates Using Provided Allocator*

Inputs:
- r: An open reader
- handle: The member, from `File_Info.handle` or `find`
- options: The member's password, if encrypted; else the one given at open (default: {})
- allocator: (default: context.allocator)

Returns:
- reader: The member's reader; close it with `close_member`
- err: `General_Error.Not_Found` for a stale handle, the member's error, or `nil`
*/
open_member :: proc(r: ^Reader, handle: archive.Handle, options := archive.Read_Options{}, allocator := context.allocator) -> (reader: io.Reader, err: Error) {
	index := _handle_index(r, handle) or_return
	m := new(Member, allocator) or_return
	if err = _member_init(m, r, index, nil, allocator, _password(r, options)); err != nil {
		free(m, allocator)
		return
	}
	m.owned = true
	return _member_stream(m), nil
}

/*
Closes a reader from `open_member` and frees it

Inputs:
- reader: The member's reader
*/
close_member :: proc(reader: io.Reader) {
	io.destroy(reader)
}

@(init, private)
_register :: proc "contextless" () {
	procs := archive.Format_Procs{
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
	}
	when ODIN_OS != .JS {
		procs.open_path = _archive_open_path
	}
	archive._register(.SevenZ, procs)
}

@(private)
_init :: proc(r: ^Reader, options: compress.Options, allocator: runtime.Allocator) {
	r^ = {}
	r.allocator = allocator
	r.options   = options
	r.keys.allocator = allocator
	_streams_init(&r.streams, allocator)
}

@(private)
_read_options :: proc(r: ^Reader, read_options: archive.Read_Options) -> (err: Error) {
	if read_options.max_key_derivations < 0 {
		return archive.General_Error.Incompatible_Options
	}
	r.keys.limit = read_options.max_key_derivations if read_options.max_key_derivations > 0 else KDF_LIMIT_DEFAULT
	r.password = archive._secret_clone(read_options.password, r.allocator) or_return
	return
}

@(private)
_password :: proc "contextless" (r: ^Reader, options: archive.Read_Options) -> (password: string) {
	return options.password if options.password != "" else r.password
}

@(private)
_load :: proc(r: ^Reader) -> (err: Error) {
	options := r.options
	if options.progress_interval < 0 || options.max_memory < 0 || options.max_output_size < 0 || options.chunk_size < 0 {
		return archive.General_Error.Incompatible_Options
	}
	start := _find_start(r) or_return
	next_offset := _u64(start[:], 12)
	next_size   := _u64(start[:], 20)
	next_crc    := _u32(start[:], 28)
	r.generation = 1
	if next_size == 0 {
		return nil
	}
	if next_size > u64(_header_limit(options)) {
		return SevenZ_Error.Header_Too_Large
	}
	offset := r.base + SIGNATURE_HEADER_SIZE + i64(next_offset)
	r.header_start = offset
	if r.store.memory {
		r.header = r.store.data[offset:][:next_size]
	} else {
		r.header      = make([]u8, int(next_size), r.allocator) or_return
		r.owns_header = true
		_store_read(&r.store, r.header, offset) or_return
	}
	if hash.crc32(r.header) != next_crc {
		return SevenZ_Error.Header_CRC_Mismatch
	}
	depth := 0
	for {
		p := Parser{data = r.header}
		id := _parse_number(&p) or_return
		if id == u64(Property_ID.Header) {
			_parse_header(r, &p) or_return
			if p.pos != len(p.data) {
				return SevenZ_Error.Invalid_Header
			}
			return _build_index(r)
		}
		if id != u64(Property_ID.Encoded_Header) {
			return SevenZ_Error.Invalid_Header
		}
		if depth >= HEADER_DEPTH_MAX {
			return SevenZ_Error.Header_Too_Deep
		}
		depth += 1
		decoded := _decode_header(r, &p) or_return
		if r.owns_header {
			delete(r.header, r.allocator)
		}
		r.header      = decoded
		r.owns_header = true
	}
}

@(private)
_find_start :: proc(r: ^Reader) -> (start: [SIGNATURE_HEADER_SIZE]u8, err: Error) {
	if r.store.size < SIGNATURE_HEADER_SIZE {
		return start, SevenZ_Error.Invalid_Signature
	}
	_store_read(&r.store, start[:], 0) or_return
	if _archive_detect(start[:]) {
		return start, _check_start(start[:], r.store.size)
	}
	if !_is_executable(start[:]) {
		return start, SevenZ_Error.Invalid_Signature
	}
	window := make([]u8, SFX_CHUNK_SIZE + SIGNATURE_HEADER_SIZE - 1, r.allocator) or_return
	defer delete(window, r.allocator)
	limit := min(r.store.size - SIGNATURE_HEADER_SIZE + 1, SFX_SEARCH_MAX)
	for chunk := i64(1); chunk < limit; chunk += SFX_CHUNK_SIZE {
		count := min(SFX_CHUNK_SIZE, limit - chunk)
		data  := window[:count + SIGNATURE_HEADER_SIZE - 1]
		_store_read(&r.store, data, chunk) or_return
		for i in 0..<count {
			candidate := data[i:][:SIGNATURE_HEADER_SIZE]
			if candidate[0] == '7' && _archive_detect(candidate) && _check_start(candidate, r.store.size - chunk - i) == nil {
				r.base = chunk + i
				copy(start[:], candidate)
				return start, nil
			}
		}
	}
	return start, SevenZ_Error.Invalid_Signature
}

@(private)
_check_start :: proc(start: []u8, room: i64) -> (err: Error) {
	if start[6] != VERSION_MAJOR {
		return SevenZ_Error.Unsupported_Version
	}
	if hash.crc32(start[12:]) != _u32(start, 8) {
		return SevenZ_Error.Header_CRC_Mismatch
	}
	next_offset := _u64(start, 12)
	next_size   := _u64(start, 20)
	if next_size == 0 {
		if next_offset != 0 || _u32(start, 28) != 0 {
			return SevenZ_Error.Invalid_Header
		}
		return nil
	}
	available := u64(room - SIGNATURE_HEADER_SIZE)
	if next_offset > available || next_size > available - next_offset {
		return SevenZ_Error.Truncated
	}
	return nil
}

@(private)
_is_executable :: proc(head: []u8) -> bool {
	if head[0] == 'M' && head[1] == 'Z' {
		return true
	}
	magics := EXECUTABLE_MAGICS
	return slice.contains(magics[:], _u32(head, 0))
}

@(private)
_header_limit :: proc "contextless" (options: compress.Options) -> (limit: i64) {
	return min(HEADER_SIZE_MAX, i64(compress.memory_limit(options)))
}

@(private)
_decode_header :: proc(r: ^Reader, p: ^Parser) -> (data: []u8, err: Error) {
	streams: Streams
	_streams_init(&streams, r.allocator)
	defer _streams_destroy(&streams)
	_parse_streams_info(r, p, &streams) or_return
	if len(streams.folders) != 1 {
		return nil, SevenZ_Error.Invalid_Header
	}
	f := &streams.folders[0]
	if f.unpack_size > _header_limit(r.options) {
		return nil, SevenZ_Error.Header_Too_Large
	}
	if f.unpack_size == 0 {
		return nil, SevenZ_Error.Invalid_Header
	}
	data = make([]u8, int(f.unpack_size), r.allocator) or_return
	d: Folder_Decoder
	defer _decoder_destroy(&d)
	if err = _decoder_init(&d, &r.store, &streams, 0, r.options, r.allocator, &r.keys, r.password); err == nil {
		_, err = _decoder_read(&d, data)
		if err == nil {
			err = d.err
		}
	}
	if err != nil {
		delete(data, r.allocator)
		return nil, err
	}
	return
}

@(private)
_parse_header :: proc(r: ^Reader, p: ^Parser) -> (err: Error) {
	id := _parse_number(p) or_return
	if id == u64(Property_ID.Archive_Properties) {
		for {
			kind := _parse_number(p) or_return
			if kind == 0 {
				break
			}
			_skip_property(p) or_return
		}
		id = _parse_number(p) or_return
	}
	if id == u64(Property_ID.Additional_Streams) {
		return SevenZ_Error.Invalid_Header
	}
	if id == u64(Property_ID.Main_Streams) {
		_parse_streams_info(r, p, &r.streams) or_return
		id = _parse_number(p) or_return
	}
	if id == u64(Property_ID.Files_Info) {
		_parse_files(r, p) or_return
		for {
			id = _parse_number(p) or_return
			if id == u64(Property_ID.End) {
				break
			}
			_skip_property(p) or_return
		}
	}
	if id != u64(Property_ID.End) {
		return SevenZ_Error.Invalid_Header
	}
	return _assign_streams(r)
}

@(private)
_parse_streams_info :: proc(r: ^Reader, p: ^Parser, s: ^Streams) -> (err: Error) {
	id := _parse_number(p) or_return
	if id == u64(Property_ID.Pack_Info) {
		_parse_pack_info(r, p, s) or_return
		id = _parse_number(p) or_return
	}
	if id == u64(Property_ID.Unpack_Info) {
		_parse_unpack_info(p, s) or_return
		id = _parse_number(p) or_return
	}
	_assign_packs(s) or_return
	if id == u64(Property_ID.Substreams_Info) {
		_parse_substreams(p, s) or_return
		id = _parse_number(p) or_return
	} else {
		for &f in s.folders {
			f.stream_count = 1
			append(&s.sub_sizes, f.unpack_size) or_return
			append(&s.sub_crcs, f.crc) or_return
		}
	}
	if id != u64(Property_ID.End) {
		return SevenZ_Error.Invalid_Header
	}
	return
}

@(private)
_parse_pack_info :: proc(r: ^Reader, p: ^Parser, s: ^Streams) -> (err: Error) {
	pack_pos := _parse_number(p) or_return
	count    := _parse_count(p) or_return
	_wait_id(p, .Size) or_return
	if pack_pos > u64(r.store.size - r.base - SIGNATURE_HEADER_SIZE) {
		return SevenZ_Error.Truncated
	}
	position := r.base + SIGNATURE_HEADER_SIZE + i64(pack_pos)
	for _ in 0..<count {
		size := _parse_size(p) or_return
		if size > r.store.size - position {
			return SevenZ_Error.Truncated
		}
		append(&s.pack_offsets, position) or_return
		append(&s.pack_sizes, size) or_return
		position += size
	}
	if position > r.header_start {
		return SevenZ_Error.Invalid_Header
	}
	for {
		id := _parse_number(p) or_return
		switch id {
		case u64(Property_ID.End):
			return
		case u64(Property_ID.CRC):
			_parse_digests(p, count, nil) or_return
		case:
			_skip_property(p) or_return
		}
	}
}

@(private)
_parse_unpack_info :: proc(p: ^Parser, s: ^Streams) -> (err: Error) {
	_wait_id(p, .Folder) or_return
	count := _parse_count(p) or_return
	if external := _parse_u8(p) or_return; external != 0 {
		return SevenZ_Error.Invalid_Header
	}
	for _ in 0..<count {
		_parse_folder(p, s) or_return
	}
	_wait_id(p, .Coders_Unpack_Size) or_return
	for &f in s.folders {
		for k in 0..<f.coder_count {
			c := &s.coders[f.first_coder + k]
			if k == f.unpack_coder {
				c.unpack_size = _parse_size(p) or_return
				continue
			}
			value := _parse_number(p) or_return
			c.unpack_size = -1
			if value <= u64(max(i64)) {
				c.unpack_size = i64(value)
			}
		}
		f.unpack_size = s.coders[f.first_coder + f.unpack_coder].unpack_size
	}
	has_crcs := false
	for {
		id := _parse_number(p) or_return
		switch id {
		case u64(Property_ID.End):
			return
		case u64(Property_ID.CRC):
			if has_crcs {
				return SevenZ_Error.Invalid_Header
			}
			has_crcs = true
			crcs: [dynamic]Maybe(u32)
			crcs.allocator = s.folders.allocator
			defer delete(crcs)
			_parse_digests(p, len(s.folders), &crcs) or_return
			for &f, i in s.folders {
				f.crc = crcs[i]
			}
		case:
			_skip_property(p) or_return
		}
	}
}

@(private)
_parse_folder :: proc(p: ^Parser, s: ^Streams) -> (err: Error) {
	f := Folder{
		first_coder  = len(s.coders),
		first_bind   = len(s.bind_pairs),
		first_packed = len(s.packed),
	}
	coder_count := _parse_count(p, FOLDER_CODERS_MAX) or_return
	if coder_count == 0 {
		return SevenZ_Error.Invalid_Folder
	}
	in_total := 0
	for _ in 0..<coder_count {
		main := _parse_u8(p) or_return
		if main & 0xC0 != 0 || int(main & 0x0F) > CODER_ID_SIZE_MAX {
			return SevenZ_Error.Invalid_Folder
		}
		id := u64(0)
		for _ in 0..<int(main & 0x0F) {
			b := _parse_u8(p) or_return
			id = id << 8 | u64(b)
		}
		in_streams := 1
		if main & 0x10 != 0 {
			in_streams = _parse_index(p, FOLDER_STREAMS_MAX + 1) or_return
			if out_streams := _parse_number(p) or_return; out_streams != 1 {
				return SevenZ_Error.Invalid_Folder
			}
		}
		properties: []u8
		if main & 0x20 != 0 {
			size := _parse_count(p) or_return
			properties = _parse_bytes(p, size) or_return
		}
		append(&s.coders, Coder{id = id, kind = _coder_kind(id), in_streams = in_streams, first_in = in_total, properties = properties}) or_return
		in_total += in_streams
		if in_total > FOLDER_STREAMS_MAX {
			return SevenZ_Error.Invalid_Folder
		}
	}
	bind_count := coder_count - 1
	if in_total < bind_count {
		return SevenZ_Error.Invalid_Folder
	}
	used_in:  [FOLDER_STREAMS_MAX]bool
	used_out: [FOLDER_CODERS_MAX]bool
	for _ in 0..<bind_count {
		in_index  := _parse_index(p, in_total) or_return
		out_index := _parse_index(p, coder_count) or_return
		if used_in[in_index] || used_out[out_index] {
			return SevenZ_Error.Invalid_Folder
		}
		used_in[in_index]   = true
		used_out[out_index] = true
		append(&s.bind_pairs, Bind_Pair{in_index, out_index}) or_return
	}
	packed_count := in_total - bind_count
	if packed_count == 1 {
		for i in 0..<in_total {
			if !used_in[i] {
				append(&s.packed, i) or_return
				break
			}
		}
	} else {
		for _ in 0..<packed_count {
			index := _parse_index(p, in_total) or_return
			if used_in[index] {
				return SevenZ_Error.Invalid_Folder
			}
			used_in[index] = true
			append(&s.packed, index) or_return
		}
	}
	f.coder_count  = coder_count
	f.bind_count   = bind_count
	f.packed_count = packed_count
	f.unpack_coder = -1
	for i in 0..<coder_count {
		if !used_out[i] {
			f.unpack_coder = i
			break
		}
	}
	_classify(s, &f)
	if packed_count == 0 {
		f.supported = false
	}
	append(&s.folders, f) or_return
	return
}

@(private)
_classify :: proc(s: ^Streams, f: ^Folder) {
	coders := s.coders[f.first_coder:][:f.coder_count]
	binds  := s.bind_pairs[f.first_bind:][:f.bind_count]
	f.supported = true
	for c in coders {
		#partial switch c.kind {
		case .Unsupported:
			f.supported = false
		case .AES:
			f.encrypted = true
		case .Delta:
			f.filters += {.Delta}
		case .Branch:
			f.filters += {_branch_filter(c.id)}
		case .BCJ2:
			f.filters += {.BCJ2}
		case .Swap2:
			f.filters += {.Swap2}
		case .Swap4:
			f.filters += {.Swap4}
		}
	}
	f.method = .Store
	index := f.unpack_coder
	for _ in 0..<f.coder_count {
		c := &coders[index]
		#partial switch c.kind {
		case .Copy, .LZMA, .LZMA2, .PPMd, .Deflate, .Deflate64, .BZip2, .Unsupported:
			f.method    = _method(c.kind)
			f.method_id = c.id
			return
		}
		next := -1
		for b in binds {
			if b.in_index == c.first_in {
				next = b.out_index
				break
			}
		}
		if next < 0 {
			return
		}
		index = next
	}
}

@(private)
_assign_packs :: proc(s: ^Streams) -> (err: Error) {
	next := 0
	for &f in s.folders {
		if f.packed_count > len(s.pack_sizes) - next {
			return SevenZ_Error.Invalid_Header
		}
		f.first_pack = next
		for k in 0..<f.packed_count {
			f.pack_size += s.pack_sizes[next + k]
		}
		next += f.packed_count
	}
	return
}

@(private)
_parse_substreams :: proc(p: ^Parser, s: ^Streams) -> (err: Error) {
	for &f in s.folders {
		f.stream_count = 1
	}
	id := _parse_number(p) or_return
	if id == u64(Property_ID.Num_Unpack_Stream) {
		total := 0
		for &f in s.folders {
			f.stream_count = _parse_count(p) or_return
			total += f.stream_count
			if total > len(p.data) {
				return SevenZ_Error.Invalid_Header
			}
		}
		id = _parse_number(p) or_return
	}
	for id != u64(Property_ID.Size) && id != u64(Property_ID.CRC) && id != u64(Property_ID.End) {
		_skip_property(p) or_return
		id = _parse_number(p) or_return
	}
	if id == u64(Property_ID.Size) {
		for &f in s.folders {
			if f.stream_count == 0 {
				continue
			}
			sum := i64(0)
			for _ in 1..<f.stream_count {
				size := _parse_size(p) or_return
				if size > f.unpack_size - sum {
					return SevenZ_Error.Size_Mismatch
				}
				sum += size
				append(&s.sub_sizes, size) or_return
			}
			append(&s.sub_sizes, f.unpack_size - sum) or_return
		}
		id = _parse_number(p) or_return
	} else {
		for &f in s.folders {
			if f.stream_count > 1 {
				return SevenZ_Error.Invalid_Header
			}
			if f.stream_count == 1 {
				append(&s.sub_sizes, f.unpack_size) or_return
			}
		}
	}
	digest_count := 0
	for f in s.folders {
		if f.stream_count != 1 || f.crc == nil {
			digest_count += f.stream_count
		}
	}
	crcs: [dynamic]Maybe(u32)
	crcs.allocator = s.folders.allocator
	defer delete(crcs)
	for id != u64(Property_ID.End) {
		if id == u64(Property_ID.CRC) {
			clear(&crcs)
			_parse_digests(p, digest_count, &crcs) or_return
		} else {
			_skip_property(p) or_return
		}
		id = _parse_number(p) or_return
	}
	k := 0
	for f in s.folders {
		if f.stream_count == 1 && f.crc != nil {
			append(&s.sub_crcs, f.crc) or_return
			continue
		}
		for _ in 0..<f.stream_count {
			crc: Maybe(u32)
			if k < len(crcs) {
				crc = crcs[k]
			}
			k += 1
			append(&s.sub_crcs, crc) or_return
		}
	}
	return
}

@(private)
_parse_files :: proc(r: ^Reader, p: ^Parser) -> (err: Error) {
	count := _parse_count(p) or_return
	r.items = make([]Entry, count, r.allocator) or_return
	items := r.items
	empty_stream, empty_file, anti, names: []u8
	empty_count := 0
	seen: bit_set[Property_ID]
	for {
		kind := _parse_number(p) or_return
		if kind == 0 {
			break
		}
		size := _parse_count(p) or_return
		q := Parser{data = _parse_bytes(p, size) or_return}
		if kind > u64(Property_ID.Dummy) {
			continue
		}
		id := Property_ID(kind)
		#partial switch id {
		case .Empty_Stream, .Empty_File, .Name, .Creation_Time, .Modification_Time, .Attributes:
			if id in seen || (id == .Empty_Stream && .Empty_File in seen) {
				return SevenZ_Error.Invalid_Header
			}
			seen += {id}
		case .Anti, .Access_Time, .Start_Position:
		case:
			continue
		}
		#partial switch id {
		case .Empty_Stream:
			empty_stream = _parse_bits(&q, count) or_return
			empty_count  = 0
			for i in 0..<count {
				if _bit(empty_stream, i) {
					empty_count += 1
				}
			}
			empty_file, anti = nil, nil
		case .Empty_File:
			empty_file = _parse_bits(&q, empty_count) or_return
		case .Anti:
			anti = _parse_bits(&q, empty_count) or_return
		case .Name:
			if external := _parse_u8(&q) or_return; external != 0 {
				return SevenZ_Error.Invalid_Header
			}
			names = q.data[q.pos:]
			q.pos = len(q.data)
		case:
			_parse_item_values(&q, items, id) or_return
		}
		if q.pos != len(q.data) {
			return SevenZ_Error.Invalid_Header
		}
	}
	empty := 0
	for &item, i in items {
		item.folder     = -1
		item.has_stream = !(empty_stream != nil && _bit(empty_stream, i))
		if !item.has_stream {
			item.is_directory = !(empty_file != nil && _bit(empty_file, empty))
			item.is_anti      = anti != nil && _bit(anti, empty)
			empty += 1
		}
	}
	return _parse_names(r, names, .Name in seen)
}

@(private)
_parse_item_values :: proc(q: ^Parser, items: []Entry, kind: Property_ID) -> (err: Error) {
	all := _parse_u8(q) or_return
	defined: []u8
	if all == 0 {
		defined = _parse_bits(q, len(items)) or_return
	}
	if external := _parse_u8(q) or_return; external != 0 {
		return SevenZ_Error.Invalid_Header
	}
	for &item, i in items {
		if all == 0 && !_bit(defined, i) {
			#partial switch kind {
			case .Access_Time:    item.access_time    = nil
			case .Start_Position: item.start_position = nil
			}
			continue
		}
		if kind == .Attributes {
			item.attributes = _parse_u32(q) or_return
			continue
		}
		value := _parse_u64(q) or_return
		#partial switch kind {
		case .Creation_Time:     item.creation_time     = value
		case .Access_Time:       item.access_time       = value
		case .Modification_Time: item.modification_time = value
		case .Start_Position:    item.start_position    = value
		}
	}
	return
}

@(private)
_parse_names :: proc(r: ^Reader, raw: []u8, present: bool) -> (err: Error) {
	if present && (len(raw) % 2 != 0 || (len(r.items) == 0 && len(raw) != 0)) {
		return SevenZ_Error.Invalid_Header
	}
	starts := make([]int, len(r.items) + 1, r.allocator) or_return
	defer delete(starts, r.allocator)
	names: [dynamic]u8
	names.allocator = r.allocator
	defer if err != nil {
		delete(names)
	}
	pos := 0
	for &item, i in r.items {
		starts[i] = len(names)
		if !present {
			continue
		}
		end := pos
		for end + 1 < len(raw) && (raw[end] != 0 || raw[end + 1] != 0) {
			end += 2
		}
		if end + 1 >= len(raw) {
			return SevenZ_Error.Invalid_Header
		}
		item.raw_path = raw[pos:end]
		_append_utf16(&names, raw[pos:end]) or_return
		pos = end + 2
	}
	if present && pos != len(raw) {
		return SevenZ_Error.Invalid_Header
	}
	starts[len(r.items)] = len(names)
	r.names = names[:]
	for &item, i in r.items {
		item.path = string(r.names[starts[i]:starts[i + 1]])
	}
	return
}

@(private)
_append_utf16 :: proc(out: ^[dynamic]u8, raw: []u8) -> (err: runtime.Allocator_Error) {
	i := 0
	for i + 1 < len(raw) {
		c := rune(u16(raw[i]) | u16(raw[i + 1]) << 8)
		i += 2
		switch {
		case c >= 0xD800 && c < 0xDC00:
			low := rune(-1)
			if i + 1 < len(raw) {
				low = rune(u16(raw[i]) | u16(raw[i + 1]) << 8)
			}
			if low >= 0xDC00 && low < 0xE000 {
				c  = 0x10000 + (c - 0xD800) << 10 + (low - 0xDC00)
				i += 2
			} else {
				c = utf8.RUNE_ERROR
			}
		case c >= 0xDC00 && c < 0xE000:
			c = utf8.RUNE_ERROR
		case c >= ESCAPE_FIRST && c <= ESCAPE_LAST:
			append(out, u8(c - ESCAPE_BASE)) or_return
			continue
		}
		bytes, n := utf8.encode_rune(c)
		append(out, ..bytes[:n]) or_return
	}
	return
}

@(private)
_assign_streams :: proc(r: ^Reader) -> (err: Error) {
	s := &r.streams
	next_folder, current, left, stream := 0, -1, 0, 0
	offset := i64(0)
	for &item in r.items {
		if !item.has_stream {
			continue
		}
		for left == 0 {
			if next_folder >= len(s.folders) {
				return SevenZ_Error.Invalid_Header
			}
			current      = next_folder
			left         = s.folders[current].stream_count
			next_folder += 1
			offset       = 0
		}
		if stream >= len(s.sub_sizes) {
			return SevenZ_Error.Invalid_Header
		}
		item.folder        = current
		item.folder_offset = offset
		item.size          = s.sub_sizes[stream]
		item.crc           = s.sub_crcs[stream]
		offset += item.size
		stream += 1
		left   -= 1
	}
	if stream != len(s.sub_sizes) {
		return SevenZ_Error.Invalid_Header
	}
	return
}

@(private)
_build_index :: proc(r: ^Reader) -> (err: Error) {
	r.index = make([]Name_Index, len(r.items), r.allocator) or_return
	for &e, i in r.index {
		e = {archive._clean_member_path(r.items[i].path), i}
	}
	slice.sort_by(r.index, proc(a, b: Name_Index) -> bool {
		if a.path != b.path {
			return a.path < b.path
		}
		return a.position < b.position
	})
	return
}

@(private)
_streams_init :: proc(s: ^Streams, allocator: runtime.Allocator) {
	s^ = {}
	s.pack_offsets.allocator = allocator
	s.pack_sizes.allocator   = allocator
	s.coders.allocator       = allocator
	s.bind_pairs.allocator   = allocator
	s.packed.allocator       = allocator
	s.folders.allocator      = allocator
	s.sub_sizes.allocator    = allocator
	s.sub_crcs.allocator     = allocator
}

@(private)
_streams_destroy :: proc(s: ^Streams) {
	delete(s.pack_offsets)
	delete(s.pack_sizes)
	delete(s.coders)
	delete(s.bind_pairs)
	delete(s.packed)
	delete(s.folders)
	delete(s.sub_sizes)
	delete(s.sub_crcs)
	s^ = {}
}

@(private)
_coder_kind :: proc "contextless" (id: u64) -> (kind: Coder_Kind) {
	#partial switch Method_ID(id) {
	case .Copy:      return .Copy
	case .LZMA:      return .LZMA
	case .LZMA2:     return .LZMA2
	case .PPMd:      return .PPMd
	case .Deflate:   return .Deflate
	case .Deflate64: return .Deflate64
	case .BZip2:     return .BZip2
	case .Delta:     return .Delta
	case .BCJ2:      return .BCJ2
	case .Swap2:     return .Swap2
	case .Swap4:     return .Swap4
	case .AES:       return .AES
	case .X86, .BCJ_X86, .PPC, .BCJ_PPC, .IA64, .BCJ_IA64, .ARM, .BCJ_ARM, .ARMT, .BCJ_ARMT, .SPARC, .BCJ_SPARC, .ARM64, .RISCV:
		return .Branch
	}
	return .Unsupported
}

@(private)
_branch_arch :: proc "contextless" (id: u64) -> (arch: filters.Branch_Arch) {
	#partial switch Method_ID(id) {
	case .PPC, .BCJ_PPC:     return .PowerPC
	case .IA64, .BCJ_IA64:   return .IA64
	case .ARM, .BCJ_ARM:     return .ARM
	case .ARMT, .BCJ_ARMT:   return .ARM_Thumb
	case .SPARC, .BCJ_SPARC: return .SPARC
	case .ARM64:             return .ARM64
	case .RISCV:             return .RISCV
	}
	return .X86
}

@(private)
_branch_filter :: proc "contextless" (id: u64) -> (filter: archive.Filter) {
	switch _branch_arch(id) {
	case .X86:       return .BCJ_X86
	case .PowerPC:   return .BCJ_PPC
	case .IA64:      return .BCJ_IA64
	case .ARM:       return .BCJ_ARM
	case .ARM_Thumb: return .BCJ_ARMT
	case .SPARC:     return .BCJ_SPARC
	case .ARM64:     return .BCJ_ARM64
	case .RISCV:     return .BCJ_RISCV
	}
	return .BCJ_X86
}

@(private)
_method :: proc "contextless" (kind: Coder_Kind) -> (method: archive.Method) {
	#partial switch kind {
	case .Copy:      return .Store
	case .LZMA:      return .LZMA
	case .LZMA2:     return .LZMA2
	case .PPMd:      return .PPMd_H
	case .Deflate:   return .Deflate
	case .Deflate64: return .Deflate64
	case .BZip2:     return .BZip2
	}
	return .Unknown
}

@(private)
_wait_id :: proc(p: ^Parser, id: Property_ID) -> (err: Error) {
	for {
		got := _parse_number(p) or_return
		if got == u64(id) {
			return
		}
		if got == u64(Property_ID.End) {
			return SevenZ_Error.Invalid_Header
		}
		_skip_property(p) or_return
	}
}

@(private)
_skip_property :: proc(p: ^Parser) -> (err: Error) {
	size := _parse_count(p) or_return
	p.pos += size
	return
}

@(private)
_parse_digests :: proc(p: ^Parser, count: int, out: ^[dynamic]Maybe(u32)) -> (err: Error) {
	all := _parse_u8(p) or_return
	defined: []u8
	if all == 0 {
		defined = _parse_bits(p, count) or_return
	}
	for i in 0..<count {
		crc: Maybe(u32)
		if all != 0 || _bit(defined, i) {
			crc = _parse_u32(p) or_return
		}
		if out != nil {
			append(out, crc) or_return
		}
	}
	return
}

@(private)
_parse_u8 :: proc(p: ^Parser) -> (value: u8, err: Error) {
	if p.pos >= len(p.data) {
		return 0, SevenZ_Error.Invalid_Header
	}
	value  = p.data[p.pos]
	p.pos += 1
	return
}

@(private)
_parse_number :: proc(p: ^Parser) -> (value: u64, err: Error) {
	first := _parse_u8(p) or_return
	mask  := u8(0x80)
	for i in 0..<8 {
		if first & mask == 0 {
			value |= u64(first & (mask - 1)) << (8 * uint(i))
			return
		}
		b := _parse_u8(p) or_return
		value |= u64(b) << (8 * uint(i))
		mask >>= 1
	}
	return
}

@(private)
_parse_count :: proc(p: ^Parser, limit := max(int)) -> (count: int, err: Error) {
	value := _parse_number(p) or_return
	if value > u64(min(limit, len(p.data) - p.pos)) {
		return 0, SevenZ_Error.Invalid_Header
	}
	return int(value), nil
}

@(private)
_parse_index :: proc(p: ^Parser, limit: int) -> (index: int, err: Error) {
	value := _parse_number(p) or_return
	if value >= u64(limit) {
		return 0, SevenZ_Error.Invalid_Folder
	}
	return int(value), nil
}

@(private)
_parse_size :: proc(p: ^Parser) -> (size: i64, err: Error) {
	value := _parse_number(p) or_return
	if value > u64(max(i64)) {
		return 0, SevenZ_Error.Invalid_Header
	}
	return i64(value), nil
}

@(private)
_parse_bytes :: proc(p: ^Parser, count: int) -> (data: []u8, err: Error) {
	if count < 0 || count > len(p.data) - p.pos {
		return nil, SevenZ_Error.Invalid_Header
	}
	data   = p.data[p.pos:][:count]
	p.pos += count
	return
}

@(private)
_parse_bits :: proc(p: ^Parser, count: int) -> (bits: []u8, err: Error) {
	return _parse_bytes(p, (count + 7) / 8)
}

@(private)
_parse_u32 :: proc(p: ^Parser) -> (value: u32, err: Error) {
	data := _parse_bytes(p, 4) or_return
	return _u32(data, 0), nil
}

@(private)
_parse_u64 :: proc(p: ^Parser) -> (value: u64, err: Error) {
	data := _parse_bytes(p, 8) or_return
	return _u64(data, 0), nil
}

@(private)
_bit :: #force_inline proc "contextless" (bits: []u8, i: int) -> bool {
	return bits[i >> 3] & (0x80 >> uint(i & 7)) != 0
}

@(private)
_u32 :: #force_inline proc "contextless" (data: []u8, pos: int) -> (value: u32) {
	for i in 0..<4 {
		value |= u32(data[pos + i]) << (8 * uint(i))
	}
	return
}

@(private)
_u64 :: #force_inline proc "contextless" (data: []u8, pos: int) -> (value: u64) {
	for i in 0..<8 {
		value |= u64(data[pos + i]) << (8 * uint(i))
	}
	return
}

@(private)
_store_read :: proc(s: ^Store, p: []u8, offset: i64) -> (err: Error) {
	if offset < 0 || offset > s.size || i64(len(p)) > s.size - offset {
		return SevenZ_Error.Truncated
	}
	if len(s.patches) == 0 {
		return _store_read_raw(s, p, offset)
	}
	position := offset
	end      := offset + i64(len(p))
	for position < end {
		next    := end
		covered := false
		for patch in s.patches {
			low  := patch.offset
			high := low + i64(len(patch.data))
			if position >= low && position < high {
				n := min(high, end) - position
				copy(p[position - offset:][:n], patch.data[position - low:][:n])
				position += n
				covered   = true
				break
			}
			if low > position && low < next {
				next = low
			}
		}
		if !covered {
			_store_read_raw(s, p[position - offset:next - offset], position) or_return
			position = next
		}
	}
	return nil
}

@(private)
_store_read_raw :: proc(s: ^Store, p: []u8, offset: i64) -> (err: Error) {
	if s.memory {
		copy(p, s.data[offset:][:len(p)])
		return nil
	}
	return _read_at_full(s.stream, p, offset)
}

@(private)
_has_current :: #force_inline proc "contextless" (it: ^Iterator) -> bool {
	return it.reader != nil && it.index >= 0 && it.index < len(it.reader.items)
}

@(private)
_handle_index :: proc(r: ^Reader, handle: archive.Handle) -> (index: int, err: Error) {
	if handle.generation != r.generation || handle.index < 0 || handle.index >= len(r.items) {
		return -1, archive.General_Error.Not_Found
	}
	return handle.index, nil
}

@(private)
_compressed_size :: proc(r: ^Reader, item: ^Entry) -> (size: i64) {
	if !item.has_stream {
		return 0
	}
	f := &r.streams.folders[item.folder]
	return f.pack_size if f.stream_count == 1 else -1
}

@(private)
_info :: proc(r: ^Reader, index: int) -> (fi: archive.File_Info) {
	item := &r.items[index]
	fi.path            = archive._clean_member_path(item.path)
	fi.raw_path        = item.raw_path
	fi.size            = item.size
	fi.compressed_size = _compressed_size(r, item)
	fi.crc32           = item.crc
	fi.method          = .Store
	fi.supported       = true
	if item.has_stream {
		f := &r.streams.folders[item.folder]
		fi.method    = f.method
		fi.method_id = f.method_id
		fi.filters   = f.filters
		fi.encrypted = f.encrypted
		fi.supported = f.supported
	}
	attributes, has_attributes := item.attributes.?
	has_unix := has_attributes && attributes & UNIX_EXTENSION != 0
	unix := attributes >> 16 if has_unix else 0
	fi.type = .Regular
	switch {
	case item.is_anti:
		fi.type = .Anti
	case item.is_directory:
		fi.type = .Directory
	case has_unix:
		switch unix & archive.UNIX_TYPE_MASK {
		case archive.UNIX_SYMLINK:          fi.type = .Symlink
		case archive.UNIX_NAMED_PIPE:       fi.type = .Named_Pipe
		case archive.UNIX_CHARACTER_DEVICE: fi.type = .Character_Device
		case archive.UNIX_BLOCK_DEVICE:     fi.type = .Block_Device
		}
	}
	if has_unix {
		fi.unix_mode = (unix & archive.UNIX_PERMISSION_MASK) | archive._unix_type_bits(fi.type)
	} else {
		dos := attributes if has_attributes else 0
		if fi.type == .Directory {
			dos |= archive.DOS_DIRECTORY
		} else {
			dos &~= archive.DOS_DIRECTORY
		}
		fi.unix_mode = archive._unix_mode_from_dos(dos)
	}
	if has_attributes {
		fi.dos_attributes = attributes & 0xFFFF &~ UNIX_EXTENSION
	} else {
		fi.dos_attributes = archive._dos_attributes_from_unix(fi.unix_mode, fi.type)
	}
	fi.creation_time     = _time(item.creation_time)
	fi.access_time       = _time(item.access_time)
	fi.modification_time = _time(item.modification_time)
	fi.handle            = {index, r.generation}
	return
}

@(private)
_time :: proc "contextless" (filetime: Maybe(u64)) -> (t: time.Time) {
	value, ok := filetime.?
	if !ok || value == 0 || value > u64(max(i64)) {
		return
	}
	delta := i64(value) - NTFS_EPOCH_DELTA
	if delta > max(i64) / 100 || delta < min(i64) / 100 {
		return
	}
	return time.Time{_nsec = delta * 100}
}

@(private)
_iterator_decoder :: proc(it: ^Iterator, password: string) -> (d: ^Folder_Decoder, err: Error) {
	r := it.reader
	item := &r.items[it.index]
	if !item.has_stream {
		return nil, nil
	}
	d = &it.decoder
	rekey := r.streams.folders[item.folder].encrypted && d.password != password
	if d.active && d.folder == item.folder && d.err != nil && !rekey {
		return nil, d.err
	}
	if !d.active || d.folder != item.folder || d.position > item.folder_offset || rekey {
		_decoder_destroy(d)
		_decoder_init(d, &r.store, &r.streams, item.folder, r.options, r.allocator, &r.keys, password) or_return
	}
	_decoder_skip(d, item.folder_offset) or_return
	return
}

@(private)
_extract :: proc(r: ^Reader, index: int, borrowed: ^Folder_Decoder, w: io.Writer, password: string) -> (err: Error) {
	m: Member
	_member_init(&m, r, index, borrowed, r.allocator, password) or_return
	defer _member_destroy(&m)
	buf: []u8
	if m.decoder != nil {
		buf = m.decoder.scratch
	}
	for {
		n, read_err := _member_read(&m, buf)
		if read_err != nil {
			if _is_eof(read_err) {
				return nil
			}
			return read_err
		}
		if _, write_err := io.write_full(w, buf[:n]); write_err != nil {
			return write_err
		}
	}
}

@(private)
_read_link :: proc(r: ^Reader, index: int, borrowed: ^Folder_Decoder, allocator: runtime.Allocator, password: string) -> (target: string, err: Error) {
	b := strings.builder_make_len_cap(0, int(r.items[index].size), allocator) or_return
	if err = _extract(r, index, borrowed, strings.to_writer(&b), password); err != nil {
		strings.builder_destroy(&b)
		return "", err
	}
	return strings.to_string(b), nil
}

@(private)
_member_init :: proc(m: ^Member, r: ^Reader, index: int, borrowed: ^Folder_Decoder, allocator: runtime.Allocator, password: string) -> (err: Error) {
	m^ = {}
	item := &r.items[index]
	if r.options.max_output_size > 0 && item.size > i64(r.options.max_output_size) {
		return compress.Error(compress.General_Error.Output_Too_Short)
	}
	m.reader    = r
	m.allocator = allocator
	m.index     = index
	m.size      = item.size
	m.expected  = item.crc
	m.next      = i64(compress.progress_interval(r.options))
	if item.has_stream {
		m.decoder = borrowed
		if m.decoder == nil {
			_decoder_init(&m.own, &r.store, &r.streams, item.folder, r.options, allocator, &r.keys, password) or_return
			if err = _decoder_skip(&m.own, item.folder_offset); err != nil {
				_decoder_destroy(&m.own)
				return
			}
			m.decoder = &m.own
		}
		m.start_in = m.decoder.packed_in if m.decoder.position > 0 else 0
	}
	m.active = true
	return
}

@(private)
_member_destroy :: proc(m: ^Member) {
	if !m.active {
		return
	}
	if m.decoder == &m.own {
		_decoder_destroy(&m.own)
	}
	m^ = {}
}

@(private)
_member_read :: proc(m: ^Member, p: []u8) -> (n: int, err: Error) {
	if m.err != nil {
		return 0, m.err
	}
	if !m.active {
		return 0, archive.General_Error.No_Current_Member
	}
	remaining := m.size - m.produced
	if remaining <= 0 {
		return 0, _member_finish(m)
	}
	if len(p) == 0 {
		return 0, nil
	}
	want := int(min(i64(len(p)), remaining))
	if n, err = _decoder_read(m.decoder, p[:want], &m.crc); err != nil {
		if _is_eof(err) {
			err = _folder_error(m.decoder, SevenZ_Error.Size_Mismatch)
		}
		m.err = err
		return 0, err
	}
	m.produced += i64(n)
	m.err       = _member_progress(m)
	return
}

@(private)
_member_finish :: proc(m: ^Member) -> (err: Error) {
	if d := m.decoder; d != nil && d.err != nil {
		m.err = d.err
		return m.err
	}
	if expected, ok := m.expected.?; ok && expected != m.crc {
		m.err = _folder_error(m.decoder, SevenZ_Error.CRC_Mismatch)
		return m.err
	}
	if progress_err := _member_progress(m); progress_err != nil {
		m.err = progress_err
		return m.err
	}
	m.err = io.Error.EOF
	return m.err
}

@(private)
_member_progress :: proc(m: ^Member) -> (err: Error) {
	r := m.reader
	options := r.options
	if options.progress == nil {
		return nil
	}
	bytes_out := m.produced
	if bytes_out < m.next && (bytes_out != m.size || m.next == max(i64)) {
		return nil
	}
	interval := i64(compress.progress_interval(options))
	switch {
	case bytes_out >= m.size:
		m.next = max(i64)
	case interval < max(i64) - bytes_out:
		m.next = bytes_out + interval
	case:
		m.next = max(i64)
	}
	item := &r.items[m.index]
	progress := compress.Progress{
		bytes_out        = bytes_out,
		total_in         = _compressed_size(r, item),
		total_out        = m.size,
		member           = item.path,
		member_index     = m.index,
		member_count     = len(r.items),
		archive_total_in = r.store.size,
	}
	if d := m.decoder; d != nil {
		f := &r.streams.folders[d.folder]
		packed_in := d.packed_in
		if d.position == f.unpack_size {
			packed_in = f.pack_size
		}
		progress.bytes_in   = packed_in - m.start_in
		progress.archive_in = r.streams.pack_offsets[f.first_pack] + packed_in
	}
	if options.progress(progress, options.progress_data) {
		return compress.Error(compress.General_Error.Canceled)
	}
	return nil
}

@(private)
_member_stream :: proc(m: ^Member) -> (s: io.Stream) {
	s.data      = m
	s.procedure = _member_stream_proc
	return
}

@(private)
_member_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	m := (^Member)(stream_data)
	#partial switch mode {
	case .Read:
		got, read_err := _member_read(m, p)
		return i64(got), _io_error(read_err)
	case .Size:
		return m.size, nil
	case .Close:
		return 0, nil
	case .Destroy:
		owned, allocator := m.owned, m.allocator
		_member_destroy(m)
		if owned {
			free(m, allocator)
		}
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Size, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private)
_decoder_init :: proc(d: ^Folder_Decoder, store: ^Store, streams: ^Streams, folder: int, options: compress.Options, allocator: runtime.Allocator, keys: ^Key_Cache, password: string) -> (err: Error) {
	d^ = {}
	f := &streams.folders[folder]
	if !f.supported {
		return archive.General_Error.Unsupported_Method
	}
	if f.encrypted && password == "" {
		return archive.General_Error.Encrypted
	}
	for c in streams.coders[f.first_coder:][:f.coder_count] {
		if c.unpack_size < 0 {
			return SevenZ_Error.Size_Mismatch
		}
	}
	_folder_memory(streams, f, options) or_return
	d.store     = store
	d.streams   = streams
	d.folder    = folder
	d.allocator = allocator
	d.fast      = store.memory && options.progress == nil
	d.options   = options
	d.options.max_output_size = 0
	d.options.buffer          = nil
	d.options.progress        = nil
	d.options.progress_data   = nil
	d.active    = true
	d.keys      = keys
	defer if err != nil {
		_decoder_destroy(d)
	}
	if f.encrypted {
		d.password = archive._secret_clone(password, allocator) or_return
	}
	d.nodes    = make([]Node, f.coder_count, allocator) or_return
	d.sections = make([]Section, f.packed_count, allocator) or_return
	d.scratch  = make([]u8, COPY_CHUNK_SIZE, allocator) or_return
	built := 0
	d.root = _node_build(d, f.unpack_coder, &built) or_return
	if built != f.coder_count {
		return SevenZ_Error.Invalid_Folder
	}
	return
}

@(private)
_decoder_destroy :: proc(d: ^Folder_Decoder) {
	if !d.active {
		return
	}
	for &node in d.nodes {
		if node.active {
			#partial switch node.kind {
			case .LZMA, .LZMA2:        lzma.reader_destroy(&node.lzma)
			case .PPMd:                ppmd.reader_destroy(&node.ppmd)
			case .Deflate, .Deflate64: deflate.reader_destroy(&node.inflate)
			case .BZip2:               bzip2.reader_destroy(&node.bzip2)
			}
		}
		if node.has_ctx {
			compress.destroy_context(&node.ctx)
		}
		filters.reader_destroy(&node.filter)
		filters.bcj2_reader_destroy(&node.bcj2)
		if node.keyed {
			_aes_destroy(&node)
			archive._secret_delete(node.buffer, d.allocator)
		} else {
			delete(node.buffer, d.allocator)
		}
	}
	delete(d.nodes, d.allocator)
	delete(d.sections, d.allocator)
	if d.password != "" {
		archive._secret_delete(transmute([]u8)d.password, d.allocator)
	}
	delete(d.scratch, d.allocator)
	d^ = {}
}

@(private)
_decoder_read :: proc(d: ^Folder_Decoder, p: []u8, crc: ^u32 = nil) -> (n: int, err: Error) {
	if d.err != nil {
		return 0, d.err
	}
	f := &d.streams.folders[d.folder]
	remaining := f.unpack_size - d.position
	if remaining <= 0 {
		return 0, io.Error.EOF
	}
	want   := int(min(i64(len(p)), remaining))
	stalls := 0
	for n < want && d.err == nil {
		got, read_err := _node_read(d.root, p[n:want], crc)
		n += got
		if read_err != nil {
			if d.err == nil {
				d.err = read_err
			}
			break
		}
		if got > 0 {
			stalls = 0
		} else {
			stalls += 1
			if stalls > ZERO_READS_MAX {
				d.err = io.Error.No_Progress
			}
		}
	}
	d.position += i64(n)
	if expected, ok := f.crc.?; ok {
		d.crc = hash.crc32(p[:n], d.crc)
		if d.err == nil && d.position == f.unpack_size && expected != d.crc {
			d.err = SevenZ_Error.CRC_Mismatch
		}
	}
	d.err = _folder_error(d, d.err)
	if n > 0 || d.err == nil {
		return n, nil
	}
	return 0, d.err
}

@(private)
_decoder_skip :: proc(d: ^Folder_Decoder, target: i64) -> (err: Error) {
	for d.position < target {
		want := int(min(target - d.position, i64(len(d.scratch))))
		_, err = _decoder_read(d, d.scratch[:want])
		if err != nil {
			if _is_eof(err) {
				err = _folder_error(d, SevenZ_Error.Size_Mismatch)
			}
			return
		}
	}
	return
}

@(private)
_folder_memory :: proc(s: ^Streams, f: ^Folder, options: compress.Options) -> (err: Error) {
	limit := u64(compress.memory_limit(options))
	total := u64(0)
	for &c in s.coders[f.first_coder:][:f.coder_count] {
		need := u64(CODER_MEMORY)
		size := u64(max(c.unpack_size, 0))
		#partial switch c.kind {
		case .LZMA:
			props, props_err := lzma.decode_properties(c.properties)
			if props_err != nil {
				return props_err
			}
			need += _lzma_memory(props.dict_size, props.lc + props.lp, size, options)
		case .LZMA2:
			if len(c.properties) < 1 {
				return SevenZ_Error.Invalid_Folder
			}
			dict, dict_err := lzma.lzma2_dict_size(c.properties[0])
			if dict_err != nil {
				return dict_err
			}
			need += _lzma_memory(dict, lzma.LZMA2_LCLP_MAX, size, options)
		case .PPMd:
			props, props_err := ppmd.decode_properties_7z(c.properties)
			if props_err != nil {
				return props_err
			}
			need += u64(props.mem_size)
		case .Deflate:
			need += DEFLATE_MEMORY
		case .Deflate64:
			need += DEFLATE64_MEMORY
		case .BZip2:
			need += BZIP2_MEMORY
		case .Branch, .Delta, .Swap2, .Swap4, .AES:
			need += FILTER_BUFFER_SIZE
		case .BCJ2:
			chunk := u64(_bcj2_chunk(c.unpack_size))
			need += chunk + 3 * min(u64(filters.BCJ2_SIDE_BUFFER_SIZE), max(chunk / 8, 8))
		}
		total = _add(total, need)
		if total > limit {
			return compress.Error(compress.General_Error.Memory_Limit_Exceeded)
		}
	}
	return
}

@(private)
_lzma_memory :: proc "contextless" (dict_size: u32, lclp: u8, size: u64, options: compress.Options) -> (need: u64) {
	dict := u64(max(dict_size, lzma.DICT_SIZE_MIN))
	window := size
	if size > dict {
		step := u64(options.chunk_size if options.chunk_size > 0 else lzma.CHUNK_SIZE)
		window = dict + max(step, dict / 4)
	}
	return window + 2 * u64(LZMA_BASE_PROBS + LZMA_LITERAL_PROBS << uint(lclp))
}

@(private)
_add :: #force_inline proc "contextless" (a, b: u64) -> u64 {
	return a + b if b <= max(u64) - a else max(u64)
}

@(private)
_node_build :: proc(d: ^Folder_Decoder, index: int, built: ^int) -> (node: ^Node, err: Error) {
	s := d.streams
	f := &s.folders[d.folder]
	node = &d.nodes[index]
	if node.decoder != nil {
		return nil, SevenZ_Error.Invalid_Folder
	}
	coder := &s.coders[f.first_coder + index]
	want := 4 if coder.kind == .BCJ2 else 1
	if coder.in_streams != want {
		return nil, SevenZ_Error.Invalid_Folder
	}
	node.decoder = d
	node.kind    = coder.kind
	node.id      = coder.id
	node.size    = coder.unpack_size
	built^ += 1
	binds  := s.bind_pairs[f.first_bind:][:f.bind_count]
	packed := s.packed[f.first_packed:][:f.packed_count]
	for k in 0..<coder.in_streams {
		in_index := coder.first_in + k
		child := -1
		for b in binds {
			if b.in_index == in_index {
				child = b.out_index
				break
			}
		}
		if child >= 0 {
			input := _node_build(d, child, built) or_return
			node.inputs[k]      = _node_stream(input)
			node.input_sizes[k] = input.size
			continue
		}
		slot := -1
		for p, j in packed {
			if p == in_index {
				slot = j
				break
			}
		}
		if slot < 0 {
			return nil, SevenZ_Error.Invalid_Folder
		}
		pack := f.first_pack + slot
		section := &d.sections[slot]
		section^ = {decoder = d, offset = s.pack_offsets[pack], end = s.pack_offsets[pack] + s.pack_sizes[pack]}
		node.inputs[k]      = _section_stream(section)
		node.input_sizes[k] = s.pack_sizes[pack]
		node.sections[k]    = section
	}
	_node_start(node, coder.properties) or_return
	return
}

@(private)
_node_start :: proc(node: ^Node, properties: []u8) -> (err: Error) {
	d := node.decoder
	expected := int(node.size) if node.size <= i64(max(int)) else -1
	options  := d.options
	options.max_output_size = max(expected, 0)
	#partial switch node.kind {
	case .Copy, .Deflate, .Deflate64, .BZip2, .Swap2, .Swap4, .BCJ2:
		if len(properties) != 0 {
			return SevenZ_Error.Invalid_Folder
		}
	case .LZMA2:
		if len(properties) != 1 {
			return SevenZ_Error.Invalid_Folder
		}
	case .PPMd:
		if len(properties) != ppmd.PROPERTIES_7Z_SIZE {
			return SevenZ_Error.Invalid_Folder
		}
	case .Branch:
		arch := _branch_arch(node.id)
		if len(properties) != 0 && (len(properties) != 4 || (arch != .ARM64 && arch != .RISCV)) {
			return SevenZ_Error.Invalid_Folder
		}
	}
	codec_err: compress.Error
	#partial switch node.kind {
	case .LZMA:
		props, props_err := lzma.decode_properties(properties)
		if props_err != nil {
			return props_err
		}
		_node_context(node) or_return
		node.active = true
		codec_err = lzma.reader_init_raw(&node.lzma, &node.ctx, props, expected, options, d.allocator)
	case .LZMA2:
		dict, dict_err := lzma.lzma2_dict_size(properties[0])
		if dict_err != nil {
			return dict_err
		}
		_node_context(node) or_return
		node.active = true
		codec_err = lzma.reader_init_lzma2(&node.lzma, &node.ctx, dict, expected, options, d.allocator)
	case .PPMd:
		props, props_err := ppmd.decode_properties_7z(properties)
		if props_err != nil {
			return props_err
		}
		_node_context(node) or_return
		node.active = true
		codec_err = ppmd.reader_init(&node.ppmd, &node.ctx, props, expected, options, d.allocator)
	case .Deflate, .Deflate64:
		format := deflate.Format.Raw64 if node.kind == .Deflate64 else .Raw
		_node_context(node) or_return
		node.active = true
		codec_err = deflate.reader_init(&node.inflate, &node.ctx, format, expected, options, d.allocator)
	case .BZip2:
		_node_context(node) or_return
		node.active = true
		codec_err = bzip2.reader_init(&node.bzip2, &node.ctx, expected, options, d.allocator)
	case .Branch:
		start := u32(0)
		if len(properties) == 4 {
			start = _u32(properties, 0)
		}
		_filter_start(node, filters.Branch_Filter{arch = _branch_arch(node.id), start_offset = start}) or_return
	case .Delta:
		if len(properties) != 1 {
			return SevenZ_Error.Invalid_Folder
		}
		_filter_start(node, filters.Delta_Filter{distance = int(properties[0]) + 1}) or_return
	case .Swap2:
		_filter_start(node, filters.Swap_Filter.Swap2) or_return
	case .Swap4:
		_filter_start(node, filters.Swap_Filter.Swap4) or_return
	case .AES:
		_aes_start(node, properties) or_return
	case .BCJ2:
		bcj2_options := _filter_options(d)
		bcj2_options.chunk_size = _bcj2_chunk(node.size)
		codec_err = filters.bcj2_reader_init(&node.bcj2, node.inputs[0], node.inputs[1], node.inputs[2], node.inputs[3], bcj2_options, d.allocator)
	case .Copy:
	case:
		return archive.General_Error.Unsupported_Method
	}
	if codec_err != nil {
		return _folder_error(d, codec_err)
	}
	return
}

@(private)
_filter_options :: proc "contextless" (d: ^Folder_Decoder) -> (options: compress.Options) {
	options = d.options
	options.chunk_size = FILTER_BUFFER_SIZE
	return
}

@(private)
_bcj2_chunk :: proc "contextless" (size: i64) -> (chunk: int) {
	return int(clamp(size, i64(filters.FILTER_BUFFER_MIN), i64(FILTER_BUFFER_SIZE)))
}

@(private)
_filter_start :: proc(node: ^Node, filter: filters.Filter) -> (err: Error) {
	d := node.decoder
	filter_err := filters.reader_init(&node.filter, node.inputs[0], filter, .Decode, _filter_options(d), d.allocator)
	if filter_err == compress.General_Error.Incompatible_Options {
		return SevenZ_Error.Invalid_Folder
	}
	if filter_err != nil {
		return filter_err
	}
	return nil
}

@(private)
_node_context :: proc(node: ^Node) -> (err: Error) {
	d := node.decoder
	if section := node.sections[0]; d.fast && section != nil {
		node.slice = d.store.data[section.offset:section.end]
		node.ctx   = compress.init_context_from_slice(&node.slice)
	} else {
		node.ctx = compress.init_context_from_stream(node.inputs[0], nil, nil, d.allocator) or_return
	}
	node.has_ctx = true
	return
}

@(private)
_node_read :: proc(node: ^Node, p: []u8, crc: ^u32 = nil) -> (n: int, err: Error) {
	crc := crc
	if node.err != nil {
		if node.decoder.err == nil {
			node.decoder.err = node.err
		}
		return 0, node.err
	}
	remaining := node.size - node.produced
	if remaining <= 0 {
		return 0, io.Error.EOF
	}
	if len(p) == 0 {
		return 0, nil
	}
	buf := p[:int(min(i64(len(p)), remaining))]
	codec_err: compress.Error
	#partial switch node.kind {
	case .Copy:
		if s, d := node.sections[0], node.decoder; crc != nil && s != nil && d.store.memory {
			n = int(min(i64(len(buf)), s.end - s.offset))
			crc^ = hash.crc32_copy(buf, d.store.data[s.offset:][:n], crc^)
			crc  = nil
			s.offset    += i64(n)
			d.packed_in += i64(n)
			if n == 0 {
				err = io.Error.EOF
			}
			break
		}
		got, read_err := io.read(node.inputs[0], buf)
		n = got
		if read_err != nil && !(read_err == .EOF && got > 0) {
			err = read_err
		}
	case .LZMA, .LZMA2:
		n, codec_err = lzma.reader_read(&node.lzma, buf)
	case .PPMd:
		n, codec_err = ppmd.reader_read(&node.ppmd, buf)
	case .Deflate, .Deflate64:
		n, codec_err = deflate.reader_read(&node.inflate, buf)
	case .BZip2:
		n, codec_err = bzip2.reader_read(&node.bzip2, buf)
	case .Branch, .Delta, .Swap2, .Swap4:
		n, codec_err = filters.reader_read(&node.filter, buf)
	case .AES:
		n, err = _filter_read(node, buf)
	case .BCJ2:
		n, codec_err = filters.bcj2_reader_read(&node.bcj2, buf)
	case:
		err = archive.General_Error.Unsupported_Method
	}
	if codec_err != nil {
		switch {
		case codec_err == compress.General_Error.Size_Mismatch:
			err = SevenZ_Error.Size_Mismatch
		case:
			if io_err, is_io := codec_err.(io.Error); is_io && io_err == .EOF {
				err = io.Error.EOF
			} else {
				err = codec_err
			}
		}
	}
	if err != nil {
		if _is_eof(err) {
			err = SevenZ_Error.Size_Mismatch
		}
		node.err = err
		if n == 0 {
			if node.decoder.err == nil {
				node.decoder.err = err
			}
			return 0, err
		}
		err = nil
	}
	if crc != nil {
		crc^ = hash.crc32(buf[:n], crc^)
	}
	node.produced += i64(n)
	if node.produced == node.size && node.err == nil {
		if end_err := _node_end(node); end_err != nil {
			node.err = end_err
			if node.decoder.err == nil {
				node.decoder.err = end_err
			}
		}
	}
	return
}

@(private)
_node_end :: proc(node: ^Node) -> (err: Error) {
	probe: [1]u8
	n: int
	end_err: compress.Error
	#partial switch node.kind {
	case .LZMA, .LZMA2:
		n, end_err = lzma.reader_read(&node.lzma, probe[:])
	case .PPMd:
		n, end_err = ppmd.reader_read(&node.ppmd, probe[:])
	case .Deflate, .Deflate64:
		n, end_err = deflate.reader_read(&node.inflate, probe[:])
	case .BZip2:
		n, end_err = bzip2.reader_read(&node.bzip2, probe[:])
	case .Branch, .Delta, .Swap2, .Swap4:
		n, end_err = filters.reader_read(&node.filter, probe[:])
	case .BCJ2:
		n, end_err = filters.bcj2_reader_read(&node.bcj2, probe[:])
	case .Copy:
		if node.input_sizes[0] != node.size {
			return SevenZ_Error.Size_Mismatch
		}
		return nil
	case:
		return nil
	}
	if n > 0 || end_err == compress.General_Error.Size_Mismatch {
		return SevenZ_Error.Size_Mismatch
	}
	if io_err, is_io := end_err.(io.Error); end_err != nil && !(is_io && io_err == .EOF) {
		return end_err
	}
	if node.has_ctx && _node_unread(node) != 0 {
		return SevenZ_Error.Size_Mismatch
	}
	return nil
}

@(private)
_node_unread :: proc(node: ^Node) -> (count: i64) {
	count = i64(len(node.ctx.window))
	switch {
	case compress.is_memory_context(&node.ctx):
	case node.sections[0] != nil:
		count += node.sections[0].end - node.sections[0].offset
	case:
		input := (^Node)(node.inputs[0].data)
		count += input.size - input.produced
	}
	return
}

@(private)
_filter_read :: proc(node: ^Node, p: []u8) -> (n: int, err: Error) {
	for node.start == node.ready {
		if node.eof && node.ready == node.end {
			return 0, io.Error.EOF
		}
		_filter_fill(node) or_return
	}
	n = copy(p, node.buffer[node.start:node.ready])
	node.start += n
	return
}

@(private)
_filter_fill :: proc(node: ^Node) -> (err: Error) {
	if node.ready > 0 {
		node.end   = copy(node.buffer, node.buffer[node.ready:node.end])
		node.start = 0
		node.ready = 0
	}
	stalls := 0
	for !node.eof && node.end < len(node.buffer) {
		got, read_err := io.read(node.inputs[0], node.buffer[node.end:])
		node.end += got
		if read_err == .EOF {
			node.eof = true
			break
		}
		if read_err != nil {
			return read_err
		}
		if got > 0 {
			stalls = 0
			continue
		}
		stalls += 1
		if stalls > ZERO_READS_MAX {
			return io.Error.No_Progress
		}
	}
	data := node.buffer[:node.end]
	node.ready = len(data) &~ (aes.BLOCK_SIZE - 1)
	_cbc_decrypt(&node.cipher, &node.iv, data[:node.ready])
	if node.eof && node.ready != node.end {
		return SevenZ_Error.Size_Mismatch
	}
	return
}

@(private)
_folder_error :: proc(d: ^Folder_Decoder, err: Error) -> Error {
	if err == nil || d == nil || !d.streams.folders[d.folder].encrypted {
		return err
	}
	return _password_error(err)
}

@(private)
_node_stream :: proc(node: ^Node) -> (s: io.Stream) {
	s.data      = node
	s.procedure = _node_stream_proc
	return
}

@(private)
_node_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	node := (^Node)(stream_data)
	#partial switch mode {
	case .Read:
		got, read_err := _node_read(node, p)
		return i64(got), _io_error(read_err)
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@(private)
_section_stream :: proc(s: ^Section) -> (stream: io.Stream) {
	stream.data      = s
	stream.procedure = _section_stream_proc
	return
}

@(private)
_section_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	s := (^Section)(stream_data)
	#partial switch mode {
	case .Read:
		remaining := s.end - s.offset
		if remaining <= 0 {
			return 0, .EOF
		}
		if len(p) == 0 {
			return 0, nil
		}
		want := int(min(i64(len(p)), remaining))
		if read_err := _store_read(s.decoder.store, p[:want], s.offset); read_err != nil {
			if s.decoder.err == nil {
				s.decoder.err = read_err
			}
			return 0, _io_error(read_err)
		}
		s.offset           += i64(want)
		s.decoder.packed_in += i64(want)
		return i64(want), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@(private)
_is_eof :: proc(err: Error) -> bool {
	if io_err, is_io := err.(io.Error); is_io {
		return io_err == .EOF
	}
	if codec_err, is_codec := err.(compress.Error); is_codec {
		if io_err, is_io := codec_err.(io.Error); is_io {
			return io_err == .EOF
		}
	}
	return false
}

@(private)
_io_error :: proc(err: Error) -> (result: io.Error) {
	if err == nil {
		return nil
	}
	if io_err, is_io := err.(io.Error); is_io {
		return io_err
	}
	if sevenz_err, is_sevenz := err.(SevenZ_Error); is_sevenz && sevenz_err == .Truncated {
		return .Unexpected_EOF
	}
	return .Unknown
}

@(private)
_archive_detect :: proc(head: []u8) -> bool {
	signature := SIGNATURE
	return len(head) >= len(signature) && slice.equal(head[:len(signature)], signature[:])
}

@(private)
_archive_open_bytes :: proc(a: ^archive.Archive, data: []u8, options: compress.Options, read_options: archive.Read_Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_bytes(r, data, options, a.allocator, read_options); err != nil {
		free(r, a.allocator)
		return
	}
	a.state = r
	return
}

@(private)
_archive_open_stream :: proc(a: ^archive.Archive, s: io.Stream, options: compress.Options, read_options: archive.Read_Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_stream(r, s, options, a.allocator, read_options); err != nil {
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
_archive_extract_current :: proc(it: ^archive.Iterator, w: io.Writer, options: archive.Read_Options) -> Error {
	return extract_current((^Iterator)(it.state), w, options)
}

@(private)
_archive_open_current :: proc(it: ^archive.Iterator, options: archive.Read_Options) -> (reader: io.Reader, err: Error) {
	return open_current((^Iterator)(it.state), options)
}

@(private)
_archive_read_link :: proc(it: ^archive.Iterator, options: archive.Read_Options, allocator: runtime.Allocator) -> (target: string, err: Error) {
	return read_link((^Iterator)(it.state), options, allocator)
}

@(private)
_archive_find :: proc(a: ^archive.Archive, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	return find((^Reader)(a.state), path)
}

@(private)
_archive_extract :: proc(a: ^archive.Archive, handle: archive.Handle, w: io.Writer, options: archive.Read_Options) -> Error {
	return extract((^Reader)(a.state), handle, w, options)
}

@(private)
_archive_open_member :: proc(a: ^archive.Archive, handle: archive.Handle, options: archive.Read_Options) -> (reader: io.Reader, err: Error) {
	return open_member((^Reader)(a.state), handle, options, a.allocator)
}
