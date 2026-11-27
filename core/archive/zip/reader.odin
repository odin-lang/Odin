package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lzma"
import legacy "core:compress/pkzip-legacy"
import "core:compress/ppmd"
import "core:compress/xz"
import "core:hash"
import "core:io"
import "core:slice"
import "core:strings"
import "core:time/timezone"
import "core:unicode/utf8"

/*
Opens a zip archive held in memory

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- data: The archive's bytes; they must stay valid until `close`
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)

Returns:
- err: A `Zip_Error` for a malformed archive, or `nil`
*/
open_from_bytes :: proc(r: ^Reader, data: []u8, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
	r.store = {data = data, size = i64(len(data)), memory = true}
	return _load(r)
}

/*
Opens a zip archive from a stream

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- s: The archive; it must read at an offset or seek, report its size, and stay open until `close`,
  which leaves it open
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)

Returns:
- err: `General_Error.Not_Seekable`, a `Zip_Error` for a malformed archive, or `nil`
*/
open_from_stream :: proc(r: ^Reader, s: io.Stream, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
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
	if r.owns_dir {
		delete(r.directory, r.allocator)
	}
	delete(r.records, r.allocator)
	delete(r.order, r.allocator)
	delete(r.names, r.allocator)
	delete(r.index, r.allocator)
	delete(r.raw_comment, r.allocator)
	delete(r.comment, r.allocator)
	io.close(r.file)
	timezone.region_destroy(r.zone, r.allocator)
	r^ = {}
}

/*
Summarizes an archive

Inputs:
- r: An open reader

Returns:
- info: Its format, member count and comment; `compression` is `.Unknown`, as it varies by member
*/
info :: proc(r: ^Reader) -> (info: archive.Archive_Info) {
	info.format       = .Zip
	info.member_count = len(r.records)
	info.comment      = r.comment
	info.compression  = .Unknown
	return
}

/*
Creates an iterator over an archive's members, in storage order

Inputs:
- r: An open reader

Returns:
- it: The iterator; destroy it with `iterator_destroy`
*/
iterator_create :: proc(r: ^Reader) -> (it: Iterator) {
	it.reader   = r
	it.position = -1
	it.index    = -1
	it.local_buf.allocator = r.allocator
	return
}

/*
Destroys an iterator, along with the reader `open_current` returned

Inputs:
- it: The iterator
*/
iterator_destroy :: proc(it: ^Iterator) {
	_member_destroy(&it.member)
	delete(it.local_buf)
	it^ = {}
}

/*
Moves to the next member

Inputs:
- it: The iterator

Returns:
- fi: The member's info; its strings last until `close`
- index: The member's index, as in `fi.handle`: its position in the central directory
- ok: `false` after the last member
*/
iterate :: proc(it: ^Iterator) -> (fi: archive.File_Info, index: int, ok: bool) {
	r := it.reader
	if r == nil {
		return {}, -1, false
	}
	_member_destroy(&it.member)
	if it.position + 1 >= len(r.order) {
		it.position = len(r.order)
		it.index    = len(r.records)
		it.entry    = {}
		return {}, -1, false
	}
	it.position += 1
	it.index     = r.order[it.position]
	return _entry(r, it.index, &it.entry, &it.local_buf), it.index, true
}

/*
Tells why iteration stopped

Inputs:
- it: The iterator

Returns:
- path: Always empty
- err: Always `nil`: the directory was read at open
*/
@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	return "", nil
}

/*
Returns the current member's format details, for what `File_Info` leaves out

Inputs:
- it: The iterator, on the member `iterate` returned last

Returns:
- entry: The member's flags, method and host, its name and comment as stored, its extra fields
  and its offsets; `nil` if `iterate` hasn't returned a member. It lasts until the next `iterate`
*/
current_entry :: proc(it: ^Iterator) -> (entry: ^Entry) {
	if !_has_current(it) {
		return nil
	}
	return &it.entry
}

/*
Writes the current member's data to a writer, decompressed and checked

Inputs:
- it: The iterator, on the member `iterate` returned last
- w: Where the member's data is written
- options: The member's password, if encrypted (default: {})

Returns:
- err: `General_Error.No_Current_Member` if `iterate` hasn't returned a member, or the member's
  error, or `nil`
*/
extract_current :: proc(it: ^Iterator, w: io.Writer, options := archive.Read_Options{}) -> (err: Error) {
	if !_has_current(it) {
		return archive.General_Error.No_Current_Member
	}
	data_offset := _current_data_offset(it) or_return
	return _extract(it.reader, it.index, data_offset, w, options.password)
}

/*
Opens the current member's data as a reader, which decompresses as it is read

Inputs:
- it: The iterator, on the member `iterate` returned last
- options: The member's password, if encrypted (default: {})

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
	data_offset := _current_data_offset(it) or_return
	_member_init(&it.member, it.reader, it.index, data_offset, options.password, it.reader.allocator) or_return
	return _member_stream(&it.member), nil
}

/*
Reads the current member's link target, which zip stores as the member's data

*Allocates Using Provided Allocator*

Inputs:
- it: The iterator, on the member `iterate` returned last
- options: The member's password, if encrypted (default: {})
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
	return _read_link(it.reader, it.index, allocator, options.password)
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
- err: Always `nil`: the directory was read at open
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
	index := r.order[r.index[lo].position]
	entry: Entry
	local_buf: [dynamic]u8
	local_buf.allocator = r.allocator
	defer delete(local_buf)
	fi = _entry(r, index, &entry, &local_buf)
	return fi, fi.handle, true, nil
}

/*
Writes a member's data to a writer, decompressed and checked

Inputs:
- r: An open reader
- handle: The member, from `File_Info.handle` or `find`
- w: Where the member's data is written
- options: The member's password, if encrypted (default: {})

Returns:
- err: `General_Error.Not_Found` for a stale handle, the member's error, or `nil`
*/
extract :: proc(r: ^Reader, handle: archive.Handle, w: io.Writer, options := archive.Read_Options{}) -> (err: Error) {
	index := _handle_index(r, handle) or_return
	_, _, data_offset := _local(r, &r.records[index], nil) or_return
	return _extract(r, index, data_offset, w, options.password)
}

/*
Opens a member's data as a reader, which decompresses as it is read

*Allocates Using Provided Allocator*

Inputs:
- r: An open reader
- handle: The member, from `File_Info.handle` or `find`
- options: The member's password, if encrypted (default: {})
- allocator: (default: context.allocator)

Returns:
- reader: The member's reader; close it with `close_member`
- err: `General_Error.Not_Found` for a stale handle, the member's error, or `nil`
*/
open_member :: proc(r: ^Reader, handle: archive.Handle, options := archive.Read_Options{}, allocator := context.allocator) -> (reader: io.Reader, err: Error) {
	index := _handle_index(r, handle) or_return
	_, _, data_offset := _local(r, &r.records[index], nil) or_return
	m := new(Member, allocator) or_return
	if err = _member_init(m, r, index, data_offset, options.password, allocator); err != nil {
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
	archive._register(.Zip, procs)
}

@(private)
_init :: proc(r: ^Reader, options: compress.Options, allocator: runtime.Allocator) {
	r^ = {}
	r.allocator = allocator
	r.options   = options
	r.zone, _   = timezone.region_load("local", allocator)
}

@(private)
_load :: proc(r: ^Reader) -> (err: Error) {
	if r.options.progress_interval < 0 {
		return archive.General_Error.Incompatible_Options
	}
	end := _read_end(r) or_return
	r.zip64 = end.zip64
	central_start := end.central_offset + r.base
	if end.central_size > 0 && r.base != 0 && !_signature_at(r, central_start, .Central) && _signature_at(r, end.central_offset, .Central) {
		r.base        = 0
		central_start = end.central_offset
	}
	if end.central_size > i64(max(int)) {
		return runtime.Allocator_Error.Out_Of_Memory
	}
	r.dir_start = central_start
	if r.store.memory {
		r.directory = r.store.data[central_start:][:end.central_size]
	} else {
		r.directory = make([]u8, int(end.central_size), r.allocator) or_return
		r.owns_dir  = true
		_store_read(&r.store, r.directory, central_start) or_return
	}
	_parse_directory(r, end) or_return

	comment: [dynamic]u8
	comment.allocator = r.allocator
	if err = append_text(&comment, r.raw_comment, utf8.valid_string(string(r.raw_comment))); err != nil {
		delete(comment)
		return
	}
	r.comment    = string(comment[:])
	r.generation = 1
	return
}

@(private)
_read_end :: proc(r: ^Reader) -> (end: Directory_End, err: Error) {
	size := r.store.size
	if size < size_of(End_Record) {
		return end, Zip_Error.End_Not_Found
	}
	tail_size  := min(size, END_SEARCH_MAX)
	tail_start := size - tail_size
	tail:  []u8
	owned: []u8
	defer delete(owned, r.allocator)
	if r.store.memory {
		tail = r.store.data[tail_start:]
	} else {
		owned = make([]u8, int(tail_size), r.allocator) or_return
		_store_read(&r.store, owned, tail_start) or_return
		tail = owned
	}

	pos, found := find_end(tail)
	if !found {
		return end, Zip_Error.End_Not_Found
	}
	record, _ := parse_end(tail[pos:])
	comment_length := min(int(record.comment_length), len(tail) - pos - size_of(End_Record))
	r.raw_comment = slice.clone(tail[pos + size_of(End_Record):][:comment_length], r.allocator) or_return

	end.end_offset     = tail_start + i64(pos)
	end.entry_count    = i64(record.entries_total)
	end.central_size   = i64(record.central_size)
	end.central_offset = i64(record.central_offset)
	directory_end     := end.end_offset

	locator:     Zip64_Locator
	has_locator: bool
	if pos >= size_of(Zip64_Locator) {
		locator, has_locator = parse_zip64_locator(tail[pos - size_of(Zip64_Locator):pos])
	}
	if has_locator {
		if locator.disk != 0 || locator.total_disks > 1 {
			return end, Zip_Error.Split_Archive
		}
		zip64, zip64_offset := _read_zip64_end(r, i64(locator.end_offset), end.end_offset - size_of(Zip64_Locator)) or_return
		if zip64.disk != 0 || zip64.central_disk != 0 {
			return end, Zip_Error.Split_Archive
		}
		if u64(zip64.entries_total) > u64(max(i64)) || u64(zip64.central_size) > u64(max(i64)) || u64(zip64.central_offset) > u64(max(i64)) {
			return end, Zip_Error.Invalid_Zip64_End
		}
		end.entry_count    = i64(zip64.entries_total)
		end.central_size   = i64(zip64.central_size)
		end.central_offset = i64(zip64.central_offset)
		end.zip64          = true
		directory_end      = zip64_offset
	} else {
		if record.disk != 0 || record.central_disk != 0 {
			return end, Zip_Error.Split_Archive
		}
		if record.central_offset == 0xFFFF_FFFF {
			end.central_offset = directory_end - end.central_size
		}
	}
	if end.central_size > directory_end || end.central_offset < 0 {
		return end, Zip_Error.Invalid_End
	}
	r.base = directory_end - end.central_size - end.central_offset
	if r.base < 0 {
		return end, Zip_Error.Invalid_End
	}
	end.records_offset = directory_end
	return
}

@(private)
_read_zip64_end :: proc(r: ^Reader, offset, locator_offset: i64) -> (record: Zip64_End_Record, record_offset: i64, err: Error) {
	buf: [size_of(Zip64_End_Record)]u8
	for candidate in ([2]i64{offset, locator_offset - size_of(Zip64_End_Record)}) {
		if candidate < 0 || candidate + size_of(Zip64_End_Record) > locator_offset {
			continue
		}
		if _store_read(&r.store, buf[:], candidate) != nil {
			continue
		}
		if found, ok := parse_zip64_end(buf[:]); ok {
			return found, candidate, nil
		}
	}
	return {}, 0, Zip_Error.Invalid_Zip64_End
}

@(private)
_parse_directory :: proc(r: ^Reader, end: Directory_End) -> (err: Error) {
	records: [dynamic]Record
	records.allocator = r.allocator
	names: [dynamic]u8
	names.allocator = r.allocator
	order: []int
	defer if err != nil {
		delete(records)
		delete(names)
		delete(order, r.allocator)
	}
	reserve(&records, int(min(end.entry_count, i64(len(r.directory) / size_of(Central_Header))))) or_return

	offset := 0
	for offset < len(r.directory) {
		header, name, extra, comment, next, parse_err := parse_central(r.directory, offset)
		if parse_err != nil {
			return parse_err
		}
		size       := i64(header.uncompressed_size)
		compressed := i64(header.compressed_size)
		local      := i64(header.local_header_offset)
		disk       := u32(header.start_disk)
		if size == 0xFFFF_FFFF || compressed == 0xFFFF_FFFF || local == 0xFFFF_FFFF || disk == 0xFFFF {
			data, found := find_extra(extra, .Zip64)
			if !found || !apply_zip64(data, &size, &compressed, &local, &disk) {
				return Zip_Error.Invalid_Extra_Field
			}
		}
		if disk != 0 {
			return Zip_Error.Split_Archive
		}
		rec := Record{
			central         = offset,
			local_offset    = local + r.base,
			compressed_size = compressed,
			size            = size,
			path            = len(names),
		}
		decode_name(&names, name, header.flags, header.made_by_host, extra) or_return
		rec.path_length = len(names) - rec.path
		rec.comment     = len(names)
		append_text(&names, comment, name_is_utf8(comment, header.flags, header.made_by_host)) or_return
		rec.comment_length = len(names) - rec.comment
		append(&records, rec) or_return
		offset = next
	}

	count := i64(len(records))
	if count != end.entry_count && (end.zip64 || (count & 0xFFFF != end.entry_count && end.entry_count != 0xFFFF)) {
		return Zip_Error.Invalid_Central_Directory
	}
	order = _member_ends(records[:], end, r.base, r.allocator) or_return

	r.records = records[:]
	r.order   = order
	r.names   = names[:]
	r.index   = make([]Name_Index, len(r.records), r.allocator) or_return
	for &e, position in r.index {
		rec := &r.records[r.order[position]]
		e = {archive._clean_member_path(string(r.names[rec.path:][:rec.path_length])), position}
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
_member_ends :: proc(records: []Record, end: Directory_End, base: i64, allocator: runtime.Allocator) -> (order: []int, err: runtime.Allocator_Error) {
	spans := make([]Member_Span, len(records), allocator) or_return
	defer delete(spans, allocator)
	for &span, i in spans {
		span = {records[i].local_offset, i}
	}
	slice.sort_by(spans, proc(a, b: Member_Span) -> bool {
		if a.offset != b.offset {
			return a.offset < b.offset
		}
		return a.index < b.index
	})

	central_start := end.central_offset + base
	central_end   := central_start + end.central_size
	for span, k in spans {
		boundary := end.records_offset
		if span.offset < central_start {
			boundary = min(boundary, central_start)
		} else if span.offset < central_end {
			boundary = span.offset
		}
		if k + 1 < len(spans) {
			boundary = min(boundary, spans[k + 1].offset)
		}
		if k > 0 && spans[k - 1].offset == span.offset {
			boundary = span.offset
		}
		records[span.index].end = boundary
	}
	order = make([]int, len(spans), allocator) or_return
	for span, k in spans {
		order[k] = span.index
	}
	return
}

@(private)
_signature_at :: proc(r: ^Reader, offset: i64, signature: Signature) -> bool {
	buf: [4]u8
	if _store_read(&r.store, buf[:], offset) != nil {
		return false
	}
	return _signature(buf[:], 0) == signature
}

@(private)
_store_read :: proc(s: ^Store, p: []u8, offset: i64) -> (err: Error) {
	if offset < 0 || offset > s.size || i64(len(p)) > s.size - offset {
		return Zip_Error.Truncated
	}
	if s.memory {
		copy(p, s.data[offset:][:len(p)])
		return nil
	}
	return _read_at_full(s.stream, p, offset)
}

@(private)
_has_current :: #force_inline proc "contextless" (it: ^Iterator) -> bool {
	return it.reader != nil && it.index >= 0 && it.index < len(it.reader.records)
}

@(private)
_current_data_offset :: proc(it: ^Iterator) -> (data_offset: i64, err: Error) {
	if it.entry.has_local {
		return it.entry.data_offset, nil
	}
	r := it.reader
	_, _, data_offset = _local(r, &r.records[it.index], nil) or_return
	return
}

@(private)
_handle_index :: proc(r: ^Reader, handle: archive.Handle) -> (index: int, err: Error) {
	if handle.generation != r.generation || handle.index < 0 || handle.index >= len(r.records) {
		return -1, archive.General_Error.Not_Found
	}
	return handle.index, nil
}

@(private)
_central :: proc(r: ^Reader, index: int) -> (header: Central_Header, name, extra: []u8) {
	header, name, extra, _, _, _ = parse_central(r.directory, r.records[index].central)
	return
}

@(private)
_entry :: proc(r: ^Reader, index: int, entry: ^Entry, buf: ^[dynamic]u8) -> (fi: archive.File_Info) {
	rec := &r.records[index]
	central: Central_Header
	entry^ = {}
	central, entry.name, entry.central_extra, entry.comment, _, _ = parse_central(r.directory, rec.central)
	entry.flags         = central.flags
	entry.method        = central.method
	entry.host          = central.made_by_host
	entry.header_offset = rec.local_offset
	entry.data_offset   = -1
	_, local_extra, data_offset, err := _local(r, rec, buf)
	if err == nil {
		entry.has_local   = true
		entry.local_extra = local_extra
		entry.data_offset = data_offset
	}

	fi.path            = archive._clean_member_path(string(r.names[rec.path:][:rec.path_length]))
	fi.raw_path        = entry.name
	fi.comment         = string(r.names[rec.comment:][:rec.comment_length])
	fi.size            = rec.size
	fi.compressed_size = rec.compressed_size
	fill_info(&fi, central, entry.name, entry.central_extra, entry.local_extra, r.zone)
	fi.extended_metadata = len(entry.central_extra) > 0 || len(entry.local_extra) > 0 || len(entry.comment) > 0
	fi.handle = {index, r.generation}
	return
}

@(private)
_local :: proc(r: ^Reader, rec: ^Record, buf: ^[dynamic]u8) -> (header: Local_Header, extra: []u8, data_offset: i64, err: Error) {
	fixed: [size_of(Local_Header)]u8
	_store_read(&r.store, fixed[:], rec.local_offset) or_return
	ok: bool
	header, ok = parse_local(fixed[:])
	if !ok {
		return {}, nil, -1, Zip_Error.Invalid_Local_Header
	}
	n := i64(header.name_length)
	m := i64(header.extra_length)
	data_offset = rec.local_offset + size_of(Local_Header) + n + m
	if data_offset > r.store.size || rec.compressed_size > r.store.size - data_offset {
		return {}, nil, -1, Zip_Error.Truncated
	}
	if data_offset > rec.end || rec.compressed_size > rec.end - data_offset {
		return {}, nil, -1, Zip_Error.Overlapping_Member
	}
	if !(_local_matches(r, rec, header) or_return) {
		return {}, nil, -1, Zip_Error.Local_Header_Mismatch
	}
	if buf == nil || m == 0 {
		return
	}
	extra_offset := rec.local_offset + size_of(Local_Header) + n
	if r.store.memory {
		extra = r.store.data[extra_offset:][:m]
		return
	}
	resize(buf, int(m)) or_return
	_store_read(&r.store, buf[:], extra_offset) or_return
	extra = buf[:]
	return
}

@(private)
_local_matches :: proc(r: ^Reader, rec: ^Record, local: Local_Header) -> (matches: bool, err: Error) {
	central, name, _, _, _, _ := parse_central(r.directory, rec.central)
	if local.method != central.method || local.flags & ENCRYPTED_FLAGS != central.flags & ENCRYPTED_FLAGS {
		return false, nil
	}
	if .Masked_Headers in central.flags {
		return true, nil
	}
	if int(local.name_length) != len(name) {
		return false, nil
	}
	if .Data_Descriptor not_in local.flags {
		if local.crc32 != 0 && local.crc32 != central.crc32 {
			return false, nil
		}
		if !_local_size_matches(local.compressed_size, rec.compressed_size) || !_local_size_matches(local.uncompressed_size, rec.size) {
			return false, nil
		}
	}
	name_offset := rec.local_offset + size_of(Local_Header)
	if r.store.memory {
		return string(r.store.data[name_offset:][:len(name)]) == string(name), nil
	}
	chunk: [256]u8
	for done := 0; done < len(name); {
		part := chunk[:min(len(chunk), len(name) - done)]
		_store_read(&r.store, part, name_offset + i64(done)) or_return
		if string(part) != string(name[done:][:len(part)]) {
			return false, nil
		}
		done += len(part)
	}
	return true, nil
}

@(private)
_local_size_matches :: #force_inline proc "contextless" (local: u32le, size: i64) -> bool {
	return local == 0 || local == 0xFFFF_FFFF || i64(local) == size
}

@(private)
_expected_size :: #force_inline proc "contextless" (size: i64) -> int {
	return int(size) if size <= i64(max(int)) else -1
}

@(private)
_extract :: proc(r: ^Reader, index: int, data_offset: i64, w: io.Writer, password: string) -> (err: Error) {
	rec := &r.records[index]
	header, _, extra := _central(r, index)
	cipher: Cipher
	defer _cipher_destroy(&cipher)
	method, section, check_crc := _member_payload(r, rec, header, extra, data_offset, password, &cipher) or_return
	crc: Maybe(u32)
	if check_crc {
		crc = u32(header.crc32)
	}
	if err = _extract_payload(r, index, data_offset, w, method, header.flags, crc, &section); err != nil {
		return _cipher_error(&section, err)
	}
	return _cipher_finish(&section)
}

@(private)
_extract_payload :: proc(r: ^Reader, index: int, data_offset: i64, w: io.Writer, method: Method, flags: Flags, crc: Maybe(u32), section: ^Section) -> (err: Error) {
	rec := &r.records[index]
	rp := _read_progress(r, index, data_offset)
	rp.head = section.offset - data_offset

	#partial switch method {
	case .Store, .Deflate, .Deflate64, .BZip2, .PPMd, .LZMA, .XZ, .Shrink, .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4, .Implode:
	case:
		return archive.General_Error.Unsupported_Method
	}

	cw := Check_Writer{w = w, limit = rec.size}
	out := _check_writer(&cw)
	if method == .Store {
		_store_check(r, rec, section) or_return
		_copy(r, &rp, section, rec.size, out) or_return
	} else {
		props: ppmd.Properties
		lzma_props: lzma.Properties
		#partial switch method {
		case .PPMd:
			props   = _ppmd_properties(section) or_return
			rp.head = section.offset - data_offset
		case .LZMA:
			lzma_props = _lzma_properties(section) or_return
			rp.head    = section.offset - data_offset
		}
		input: []u8
		ctx := _section_context(r, section, &input, r.allocator) or_return
		defer compress.destroy_context(&ctx)
		options  := _decode_options(r, &rp)
		expected := _expected_size(rec.size)
		decode_err: compress.Error
		#partial switch method {
		case .Deflate:
			decode_err = deflate.decompress_raw_to_writer(out, &ctx, expected, options, r.allocator)
		case .Deflate64:
			decode_err = deflate.decompress_raw64_to_writer(out, &ctx, expected, options, r.allocator)
		case .BZip2:
			decode_err = bzip2.decompress_to_writer(out, &ctx, expected, options, r.allocator)
		case .PPMd:
			decode_err = ppmd.decompress_to_writer(out, &ctx, props, expected, options, r.allocator)
		case .LZMA:
			decode_err = lzma.decompress_raw_to_writer(out, &ctx, lzma_props, expected, options, r.allocator)
		case .XZ:
			decode_err = xz.decompress_to_writer(out, &ctx, {}, expected, options, r.allocator)
		case .Shrink:
			decode_err = legacy.unshrink_to_writer(out, &ctx, expected, options, r.allocator)
		case .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4:
			decode_err = legacy.expand_to_writer(out, &ctx, int(method) - 1, expected, options, r.allocator)
		case .Implode:
			decode_err = legacy.explode_to_writer(out, &ctx, _implode_options(flags), expected, options, r.allocator)
		}
		if decode_err != nil {
			if cw.over || decode_err == compress.General_Error.Size_Mismatch {
				return Zip_Error.Size_Mismatch
			}
			return decode_err
		}
		if _unread(section, &ctx) != 0 {
			return Zip_Error.Size_Mismatch
		}
	}
	if cw.count != rec.size {
		return Zip_Error.Size_Mismatch
	}
	if expected, ok := crc.?; ok && cw.crc != expected {
		return Zip_Error.CRC_Mismatch
	}
	return nil
}

@(private)
_store_check :: proc(r: ^Reader, rec: ^Record, section: ^Section) -> (err: Error) {
	if section.end - section.offset != rec.size {
		return Zip_Error.Size_Mismatch
	}
	if r.options.max_output_size > 0 && rec.size > i64(r.options.max_output_size) {
		return compress.Error(compress.General_Error.Output_Too_Short)
	}
	return nil
}

@(private)
_ppmd_properties :: proc(section: ^Section) -> (props: ppmd.Properties, err: Error) {
	head: [ppmd.PROPERTIES_ZIP_SIZE]u8
	_section_read_full(section, head[:]) or_return
	decoded, props_err := ppmd.decode_properties_zip(head[:])
	if props_err != nil {
		return {}, props_err
	}
	return decoded, nil
}

@(private)
_lzma_properties :: proc(section: ^Section) -> (props: lzma.Properties, err: Error) {
	head: [4]u8
	_section_read_full(section, head[:]) or_return
	props_size := int(_u16(head[:], 2))
	if props_size < lzma.PROPERTIES_SIZE || i64(props_size) > section.end - section.offset {
		return {}, Zip_Error.Truncated
	}
	raw: [64]u8
	if props_size > len(raw) {
		return {}, Zip_Error.Truncated
	}
	_section_read_full(section, raw[:props_size]) or_return
	decoded, props_err := lzma.decode_properties(raw[:lzma.PROPERTIES_SIZE])
	if props_err != nil {
		return {}, props_err
	}
	return decoded, nil
}

@(private)
_section_context :: proc(r: ^Reader, section: ^Section, input: ^[]u8, allocator: runtime.Allocator) -> (ctx: compress.Context, err: runtime.Allocator_Error) {
	if r.store.memory && section.cipher == nil {
		input^ = r.store.data[section.offset:section.end]
		return compress.init_context_from_slice(input), nil
	}
	return compress.init_context_from_stream(_section_stream(section), nil, nil, allocator)
}

@(private)
_unread :: proc(section: ^Section, ctx: ^compress.Context) -> (count: i64) {
	count = i64(len(ctx.window))
	if !compress.is_memory_context(ctx) {
		count += section.end - section.offset
	}
	return
}

@(private)
_read_progress :: proc(r: ^Reader, index: int, data_offset: i64) -> (rp: Read_Progress) {
	return {reader = r, index = index, data_offset = data_offset, next = i64(compress.progress_interval(r.options))}
}

@(private)
_decode_options :: proc(r: ^Reader, rp: ^Read_Progress) -> (options: compress.Options) {
	options = r.options
	if options.progress != nil {
		options.progress      = _codec_progress
		options.progress_data = rp
	}
	return
}

@(private)
_codec_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	rp := (^Read_Progress)(user_data)
	return _member_progress(rp, rp.head + progress.bytes_in, progress.bytes_out) != nil
}

@(private)
_member_progress :: proc(rp: ^Read_Progress, bytes_in, bytes_out: i64) -> (err: Error) {
	r := rp.reader
	options := r.options
	if options.progress == nil {
		return nil
	}
	rec := &r.records[rp.index]
	if bytes_out < rp.next && (bytes_out != rec.size || rp.next == max(i64)) {
		return nil
	}
	interval := i64(compress.progress_interval(options))
	switch {
	case bytes_out >= rec.size:
		rp.next = max(i64)
	case interval < max(i64) - bytes_out:
		rp.next = bytes_out + interval
	case:
		rp.next = max(i64)
	}
	progress := compress.Progress{
		bytes_in         = bytes_in,
		bytes_out        = bytes_out,
		total_in         = rec.compressed_size,
		total_out        = rec.size,
		member           = string(r.names[rec.path:][:rec.path_length]),
		member_index     = rp.index,
		member_count     = len(r.records),
		archive_in       = rp.data_offset + bytes_in,
		archive_total_in = r.store.size,
	}
	if options.progress(progress, options.progress_data) {
		return compress.Error(compress.General_Error.Canceled)
	}
	return nil
}

@(private)
_write_out :: proc(rp: ^Read_Progress, w: io.Writer, data: []u8, bytes_in: i64) -> (err: Error) {
	options := rp.reader.options
	step := len(data)
	if options.progress != nil {
		step = max(compress.progress_interval(options), 1)
	}
	done := 0
	for done < len(data) {
		n := min(len(data) - done, step)
		if _, write_err := io.write_full(w, data[done:][:n]); write_err != nil {
			return write_err
		}
		done += n
		_member_progress(rp, bytes_in if bytes_in >= 0 else i64(done), i64(done)) or_return
	}
	return nil
}

@(private)
_copy :: proc(r: ^Reader, rp: ^Read_Progress, section: ^Section, count: i64, w: io.Writer) -> (err: Error) {
	if r.store.memory && section.cipher == nil {
		return _write_out(rp, w, r.store.data[section.offset:][:count], -1)
	}
	if count == 0 {
		return nil
	}
	buf := make([]u8, int(min(count, COPY_CHUNK_SIZE)), r.allocator) or_return
	defer delete(buf, r.allocator)
	done: i64
	for done < count {
		n := int(min(count - done, i64(len(buf))))
		_section_read_full(section, buf[:n]) or_return
		if _, write_err := io.write_full(w, buf[:n]); write_err != nil {
			return write_err
		}
		done += i64(n)
		_member_progress(rp, rp.head + done, done) or_return
	}
	return nil
}

@(private)
_implode_options :: proc "contextless" (flags: Flags) -> (options: legacy.Implode_Options) {
	if .Option_1 in flags {
		options += {.Large_Window}
	}
	if .Option_2 in flags {
		options += {.Literal_Tree}
	}
	return
}

@(private)
_read_link :: proc(r: ^Reader, index: int, allocator: runtime.Allocator, password: string) -> (target: string, err: Error) {
	header, name, extra := _central(r, index)
	fi: archive.File_Info
	fill_info(&fi, header, name, extra, nil, r.zone)
	if fi.type != .Symlink {
		return "", nil
	}
	if r.records[index].size > archive.LINK_TARGET_MAX {
		return "", archive.General_Error.Limit_Exceeded
	}
	_, _, data_offset := _local(r, &r.records[index], nil) or_return
	b := strings.builder_make_len_cap(0, int(r.records[index].size), allocator) or_return
	if err = _extract(r, index, data_offset, strings.to_writer(&b), password); err != nil {
		strings.builder_destroy(&b)
		return "", err
	}
	return strings.to_string(b), nil
}

@(private)
_member_init :: proc(m: ^Member, r: ^Reader, index: int, data_offset: i64, password: string, allocator: runtime.Allocator) -> (err: Error) {
	m^ = {}
	m.reader    = r
	m.allocator = allocator
	rec := &r.records[index]
	header, _, extra := _central(r, index)
	defer if err != nil {
		_cipher_destroy(&m.cipher)
	}
	method, section, check_crc := _member_payload(r, rec, header, extra, data_offset, password, &m.cipher) or_return
	m.section  = section
	m.size     = rec.size
	if check_crc {
		m.expected = u32(header.crc32)
	}
	m.progress      = _read_progress(r, index, data_offset)
	m.progress.head = m.section.offset - data_offset

	#partial switch method {
	case .Store:
		_store_check(r, rec, &m.section) or_return
		m.mode = .Store
	case .Deflate, .Deflate64, .BZip2, .PPMd, .LZMA, .XZ, .Shrink, .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4, .Implode:
		props: ppmd.Properties
		lzma_props: lzma.Properties
		#partial switch method {
		case .PPMd:
			props           = _ppmd_properties(&m.section) or_return
			m.progress.head = m.section.offset - data_offset
		case .LZMA:
			lzma_props      = _lzma_properties(&m.section) or_return
			m.progress.head = m.section.offset - data_offset
		}
		m.ctx = _section_context(r, &m.section, &m.input, allocator) or_return
		options  := _decode_options(r, &m.progress)
		expected := _expected_size(rec.size)
		init_err: compress.Error
		#partial switch method {
		case .Deflate, .Deflate64:
			m.mode = .Inflate
			format := deflate.Format.Raw64 if method == .Deflate64 else .Raw
			if init_err = deflate.reader_init(&m.inflate, &m.ctx, format, expected, options, allocator); init_err != nil {
				deflate.reader_destroy(&m.inflate)
			}
		case .BZip2:
			m.mode = .BZip2
			if init_err = bzip2.reader_init(&m.bzip2, &m.ctx, expected, options, allocator); init_err != nil {
				bzip2.reader_destroy(&m.bzip2)
			}
		case .PPMd:
			m.mode = .PPMd
			if init_err = ppmd.reader_init(&m.ppmd, &m.ctx, props, expected, options, allocator); init_err != nil {
				ppmd.reader_destroy(&m.ppmd)
			}
		case .LZMA:
			m.mode = .LZMA
			if init_err = lzma.reader_init_raw(&m.lzma, &m.ctx, lzma_props, expected, options, allocator); init_err != nil {
				lzma.reader_destroy(&m.lzma)
			}
		case .XZ:
			m.mode = .XZ
			if init_err = xz.reader_init(&m.xz, &m.ctx, {}, expected, options, allocator); init_err != nil {
				xz.reader_destroy(&m.xz)
			}
		case .Shrink:
			m.mode = .Legacy
			if init_err = legacy.reader_init_unshrink(&m.legacy, &m.ctx, expected, options, allocator); init_err != nil {
				legacy.reader_destroy(&m.legacy)
			}
		case .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4:
			m.mode = .Legacy
			if init_err = legacy.reader_init_expand(&m.legacy, &m.ctx, int(method) - 1, expected, options, allocator); init_err != nil {
				legacy.reader_destroy(&m.legacy)
			}
		case .Implode:
			m.mode = .Legacy
			if init_err = legacy.reader_init_explode(&m.legacy, &m.ctx, _implode_options(header.flags), expected, options, allocator); init_err != nil {
				legacy.reader_destroy(&m.legacy)
			}
		}
		if init_err != nil {
			compress.destroy_context(&m.ctx)
			return init_err
		}
	case:
		return archive.General_Error.Unsupported_Method
	}
	m.active = true
	return nil
}

@(private)
_member_destroy :: proc(m: ^Member) {
	_cipher_destroy(&m.cipher)
	if !m.active {
		return
	}
	switch m.mode {
	case .Store:
	case .Inflate:
		deflate.reader_destroy(&m.inflate)
		compress.destroy_context(&m.ctx)
	case .BZip2:
		bzip2.reader_destroy(&m.bzip2)
		compress.destroy_context(&m.ctx)
	case .PPMd:
		ppmd.reader_destroy(&m.ppmd)
		compress.destroy_context(&m.ctx)
	case .LZMA:
		lzma.reader_destroy(&m.lzma)
		compress.destroy_context(&m.ctx)
	case .XZ:
		xz.reader_destroy(&m.xz)
		compress.destroy_context(&m.ctx)
	case .Legacy:
		legacy.reader_destroy(&m.legacy)
		compress.destroy_context(&m.ctx)
	}
	m^ = {}
}

@(private)
_member_read :: proc(m: ^Member, p: []u8) -> (n: int, err: Error) {
	if m.err != nil {
		return 0, m.err
	}
	switch m.mode {
	case .Store:
		remaining := m.section.end - m.section.offset
		if remaining <= 0 {
			return 0, _member_finish(m)
		}
		want := int(min(i64(len(p)), remaining))
		if s := &m.section; s.store.memory && s.cipher == nil {
			m.crc = hash.crc32_copy(p, s.store.data[s.offset:][:want], m.crc)
			s.offset += i64(want)
		} else {
			if read_err := _section_read_full(s, p[:want]); read_err != nil {
				m.err = _cipher_error(s, read_err)
				return 0, m.err
			}
			m.crc = hash.crc32(p[:want], m.crc)
		}
		n = want
	case .Inflate, .BZip2, .PPMd, .LZMA, .XZ, .Legacy:
		codec_err: compress.Error
		#partial switch m.mode {
		case .Inflate:
			n, codec_err = deflate.reader_read(&m.inflate, p)
		case .BZip2:
			n, codec_err = bzip2.reader_read(&m.bzip2, p)
		case .PPMd:
			n, codec_err = ppmd.reader_read(&m.ppmd, p)
		case .LZMA:
			n, codec_err = lzma.reader_read(&m.lzma, p)
		case .XZ:
			n, codec_err = xz.reader_read(&m.xz, p)
		case .Legacy:
			n, codec_err = legacy.reader_read(&m.legacy, p)
		}
		if codec_err != nil {
			if io_err, is_io := codec_err.(io.Error); is_io && io_err == .EOF {
				return 0, _member_finish(m)
			}
			if codec_err == compress.General_Error.Size_Mismatch {
				m.err = _cipher_error(&m.section, Zip_Error.Size_Mismatch)
				return 0, m.err
			}
			m.err = _cipher_error(&m.section, codec_err)
			return 0, m.err
		}
		m.crc = hash.crc32(p[:n], m.crc)
	}
	m.produced += i64(n)
	if m.produced > m.size {
		m.err = _cipher_error(&m.section, Zip_Error.Size_Mismatch)
		return 0, m.err
	}
	if m.mode == .Store && n > 0 {
		m.err = _member_progress(&m.progress, m.produced, m.produced)
	}
	return n, nil
}

@(private)
_member_finish :: proc(m: ^Member) -> (err: Error) {
	if auth_err := _cipher_finish(&m.section); auth_err != nil {
		m.err = auth_err
	} else if m.produced != m.size || _unread(&m.section, &m.ctx) != 0 {
		m.err = Zip_Error.Size_Mismatch
	} else if expected, ok := m.expected.?; ok && expected != m.crc {
		m.err = Zip_Error.CRC_Mismatch
	} else {
		m.err = io.Error.EOF
	}
	return m.err
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
_io_error :: proc(err: Error) -> (result: io.Error) {
	if err == nil {
		return nil
	}
	if io_err, is_io := err.(io.Error); is_io {
		return io_err
	}
	if zip_err, is_zip := err.(Zip_Error); is_zip && zip_err == .Truncated {
		return .Unexpected_EOF
	}
	return .Unknown
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
		if s.end - s.offset <= 0 {
			return 0, .EOF
		}
		got, read_err := _section_read(s, p)
		if read_err != nil {
			return 0, _io_error(read_err)
		}
		return i64(got), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@(private)
_check_writer :: proc(cw: ^Check_Writer) -> (w: io.Writer) {
	w.data      = cw
	w.procedure = _check_writer_proc
	return
}

@(private)
_check_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	cw := (^Check_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		if i64(len(p)) > cw.limit - cw.count {
			cw.over = true
			return 0, .Short_Write
		}
		written: int
		written, err = io.write_full(cw.w, p)
		cw.crc    = hash.crc32(p[:written], cw.crc)
		cw.count += i64(written)
		return i64(written), err
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

@(private)
_archive_detect :: proc(head: []u8) -> bool {
	if len(head) < 4 {
		return false
	}
	#partial switch _signature(head, 0) {
	case .Local, .End:
		return true
	case .Spanned, .Descriptor:
		return len(head) >= 8 && _signature(head, 4) == .Local
	}
	return false
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
