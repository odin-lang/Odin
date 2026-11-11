package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lzma"
import legacy "core:compress/pkzip-legacy"
import "core:compress/ppmd"
import "core:hash"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time/timezone"
import "core:unicode/utf8"

open_from_bytes :: proc(r: ^Reader, data: []u8, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	_init(r, options, allocator)
	defer if err != nil {
		close(r)
	}
	r.store = {data = data, size = i64(len(data)), memory = true}
	return _load(r)
}

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

close :: proc{close_reader, close_writer}

close_reader :: proc(r: ^Reader) {
	if r.owns_dir {
		delete(r.directory, r.allocator)
	}
	delete(r.records, r.allocator)
	delete(r.names, r.allocator)
	delete(r.index, r.allocator)
	delete(r.raw_comment, r.allocator)
	delete(r.comment, r.allocator)
	if r.file != nil {
		os.close(r.file)
	}
	timezone.region_destroy(r.zone, r.allocator)
	r^ = {}
}

info :: proc(r: ^Reader) -> (info: archive.Archive_Info) {
	info.format       = .Zip
	info.member_count = len(r.records)
	info.comment      = r.comment
	info.compression  = .Unknown
	return
}

iterator_create :: proc(r: ^Reader) -> (it: Iterator) {
	it.reader = r
	it.index  = -1
	it.local_buf.allocator = r.allocator
	it.err_path.allocator  = r.allocator
	return
}

iterator_destroy :: proc(it: ^Iterator) {
	_member_destroy(&it.member)
	delete(it.local_buf)
	delete(it.err_path)
	it^ = {}
}

iterate :: proc(it: ^Iterator) -> (fi: archive.File_Info, index: int, ok: bool) {
	r := it.reader
	if r == nil || it.err != nil {
		return {}, -1, false
	}
	_member_destroy(&it.member)
	if it.index + 1 >= len(r.records) {
		it.index = len(r.records)
		it.entry = {}
		return {}, -1, false
	}
	it.index += 1
	_entry(r, it.index, &it.entry, &it.local_buf)
	return _info(r, it.index, &it.entry), it.index, true
}

@(require_results)
iterator_error :: proc(it: ^Iterator) -> (path: string, err: Error) {
	return string(it.err_path[:]), it.err
}

current_entry :: proc(it: ^Iterator) -> (entry: ^Entry) {
	if !_has_current(it) {
		return nil
	}
	return &it.entry
}

extract_current :: proc(it: ^Iterator, w: io.Writer) -> (err: Error) {
	if !_has_current(it) {
		return archive.General_Error.No_Current_Member
	}
	return _extract(it.reader, it.index, w)
}

open_current :: proc(it: ^Iterator) -> (reader: io.Reader, err: Error) {
	if !_has_current(it) {
		return {}, archive.General_Error.No_Current_Member
	}
	_member_destroy(&it.member)
	_member_init(&it.member, it.reader, it.index, it.reader.allocator) or_return
	return _member_stream(&it.member), nil
}

read_link :: proc(it: ^Iterator, allocator := context.allocator) -> (target: string, err: Error) {
	if !_has_current(it) {
		return "", archive.General_Error.No_Current_Member
	}
	return _read_link(it.reader, it.index, allocator)
}

find :: proc(r: ^Reader, path: string) -> (fi: archive.File_Info, handle: archive.Handle, ok: bool, err: Error) {
	want := archive.clean_member_path(path)
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
	index := r.index[lo].index
	entry: Entry
	local_buf: [dynamic]u8
	local_buf.allocator = r.allocator
	defer delete(local_buf)
	_entry(r, index, &entry, &local_buf)
	fi = _info(r, index, &entry)
	return fi, fi.handle, true, nil
}

extract :: proc(r: ^Reader, handle: archive.Handle, w: io.Writer) -> (err: Error) {
	index := _handle_index(r, handle) or_return
	return _extract(r, index, w)
}

open_member :: proc(r: ^Reader, handle: archive.Handle, allocator := context.allocator) -> (reader: io.Reader, err: Error) {
	index := _handle_index(r, handle) or_return
	m := new(Member, allocator) or_return
	if err = _member_init(m, r, index, allocator); err != nil {
		free(m, allocator)
		return
	}
	m.owned = true
	return _member_stream(m), nil
}

close_member :: proc(reader: io.Reader) {
	io.destroy(reader)
}

@(init, private)
_register :: proc "contextless" () {
	archive.register(.Zip, {
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
	r.allocator = allocator
	r.options   = options
	r.zone, _   = timezone.region_load("local", allocator)
}

@(private)
_load :: proc(r: ^Reader) -> (err: Error) {
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
	defer if err != nil {
		delete(records)
		delete(names)
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

	r.records = records[:]
	r.names   = names[:]
	r.index   = make([]Name_Index, len(r.records), r.allocator) or_return
	for &e, i in r.index {
		rec := &r.records[i]
		e = {archive.clean_member_path(string(r.names[rec.path:][:rec.path_length])), i}
	}
	slice.sort_by(r.index, proc(a, b: Name_Index) -> bool {
		if a.path != b.path {
			return a.path < b.path
		}
		return a.index < b.index
	})
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
	done := 0
	for done < len(p) {
		n, read_err := io.read_at(s.stream, p[done:], offset + i64(done))
		done += n
		if done == len(p) {
			break
		}
		if read_err == .EOF || read_err == .Unexpected_EOF || (read_err == nil && n == 0) {
			return Zip_Error.Truncated
		}
		if read_err != nil {
			return read_err
		}
	}
	return nil
}

@(private)
_has_current :: #force_inline proc "contextless" (it: ^Iterator) -> bool {
	return it.reader != nil && it.index >= 0 && it.index < len(it.reader.records)
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
_entry :: proc(r: ^Reader, index: int, entry: ^Entry, buf: ^[dynamic]u8) {
	rec := &r.records[index]
	entry^ = {}
	entry.central, entry.name, entry.central_extra, entry.comment, _, _ = parse_central(r.directory, rec.central)
	entry.header_offset = rec.local_offset
	entry.data_offset   = -1
	local, local_extra, data_offset, err := _local(r, rec, buf)
	if err == nil {
		entry.local       = local
		entry.has_local   = true
		entry.local_extra = local_extra
		entry.data_offset = data_offset
	}
}

@(private)
_info :: proc(r: ^Reader, index: int, entry: ^Entry) -> (fi: archive.File_Info) {
	rec := &r.records[index]
	fi.path            = string(r.names[rec.path:][:rec.path_length])
	fi.raw_path        = entry.name
	fi.comment         = string(r.names[rec.comment:][:rec.comment_length])
	fi.size            = rec.size
	fi.compressed_size = rec.compressed_size
	fill_info(&fi, entry.central, entry.name, entry.central_extra, entry.local_extra, r.zone)
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
_check_supported :: proc(header: Central_Header) -> (method: Method, err: Error) {
	method = header.method
	if method == .AES || header.flags & ENCRYPTED_FLAGS != {} {
		return method, archive.General_Error.Encrypted
	}
	if !method_supported(method) {
		return method, archive.General_Error.Unsupported_Method
	}
	return
}

@(private)
_expected_size :: #force_inline proc "contextless" (size: i64) -> int {
	return int(size) if size <= i64(max(int)) else -1
}

@(private)
_extract :: proc(r: ^Reader, index: int, w: io.Writer) -> (err: Error) {
	rec := &r.records[index]
	header, _, _ := _central(r, index)
	method := _check_supported(header) or_return
	_, _, data_offset := _local(r, rec, nil) or_return

	#partial switch method {
	case .Store, .Deflate, .Deflate64:
	case:
		buffer: [dynamic]u8
		buffer.allocator = r.allocator
		defer delete(buffer)
		_decode(r, rec, method, header.flags, u32(header.crc32), data_offset, &buffer) or_return
		if _, write_err := io.write_full(w, buffer[:]); write_err != nil {
			return write_err
		}
		return nil
	}

	cw := Check_Writer{w = w}
	out := _check_writer(&cw)
	if method == .Store {
		if rec.compressed_size != rec.size {
			return Zip_Error.Size_Mismatch
		}
		_copy(r, data_offset, rec.size, out) or_return
	} else {
		section := Section{store = &r.store, offset = data_offset, end = data_offset + rec.compressed_size}
		input: []u8
		ctx:   compress.Context
		if r.store.memory {
			input = r.store.data[data_offset:][:rec.compressed_size]
			ctx   = compress.init_context_from_slice(&input)
		} else {
			ctx = compress.init_context_from_stream(_section_stream(&section), nil, -1, nil, r.allocator)
		}
		defer compress.destroy_context(&ctx)
		if method == .Deflate {
			deflate.inflate_raw_to_writer(out, &ctx, _expected_size(rec.size), r.options, r.allocator) or_return
		} else {
			deflate.inflate64_raw_to_writer(out, &ctx, _expected_size(rec.size), r.options, r.allocator) or_return
		}
	}
	if cw.count != rec.size {
		return Zip_Error.Size_Mismatch
	}
	if cw.crc != u32(header.crc32) {
		return Zip_Error.CRC_Mismatch
	}
	return nil
}

@(private)
_copy :: proc(r: ^Reader, offset, count: i64, w: io.Writer) -> (err: Error) {
	if r.store.memory {
		if _, write_err := io.write_full(w, r.store.data[offset:][:count]); write_err != nil {
			return write_err
		}
		return nil
	}
	if count == 0 {
		return nil
	}
	buf := make([]u8, int(min(count, COPY_CHUNK_SIZE)), r.allocator) or_return
	defer delete(buf, r.allocator)
	offset, count := offset, count
	for count > 0 {
		n := int(min(count, i64(len(buf))))
		_store_read(&r.store, buf[:n], offset) or_return
		if _, write_err := io.write_full(w, buf[:n]); write_err != nil {
			return write_err
		}
		offset += i64(n)
		count  -= i64(n)
	}
	return nil
}

@(private)
_decode :: proc(r: ^Reader, rec: ^Record, method: Method, flags: Flags, crc: u32, data_offset: i64, out: ^[dynamic]u8) -> (err: Error) {
	input: []u8
	owned: []u8
	defer delete(owned, r.allocator)
	if r.store.memory {
		input = r.store.data[data_offset:][:rec.compressed_size]
	} else {
		if rec.compressed_size > i64(max(int)) {
			return runtime.Allocator_Error.Out_Of_Memory
		}
		owned = make([]u8, int(rec.compressed_size), r.allocator) or_return
		_store_read(&r.store, owned, data_offset) or_return
		input = owned
	}

	expected := _expected_size(rec.size)
	limit    := compress.output_limit(r.options)
	decode_err: compress.Error
	#partial switch method {
	case .Shrink:
		decode_err = legacy.unshrink_from_bytes(out, input, expected, limit, r.allocator)
	case .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4:
		decode_err = legacy.expand_from_bytes(out, input, int(method) - 1, expected, limit, r.allocator)
	case .Implode:
		options: legacy.Implode_Options
		if .Option_1 in flags {
			options += {.Large_Window}
		}
		if .Option_2 in flags {
			options += {.Literal_Tree}
		}
		decode_err = legacy.explode_from_bytes(out, input, options, expected, limit, r.allocator)
	case .BZip2:
		decode_err = bzip2.decompress_from_bytes(out, input, expected, r.options, r.allocator)
	case .LZMA:
		if len(input) < 4 {
			return Zip_Error.Truncated
		}
		props_size := int(_u16(input, 2))
		if props_size < lzma.PROPERTIES_SIZE || 4 + props_size > len(input) {
			return Zip_Error.Truncated
		}
		props, props_err := lzma.decode_properties(input[4:][:props_size])
		if props_err != nil {
			return props_err
		}
		decode_err = lzma.decompress_raw_from_bytes(out, input[4 + props_size:], props, expected, limit, r.allocator)
	case .PPMd:
		if len(input) < ppmd.PROPERTIES_ZIP_SIZE {
			return Zip_Error.Truncated
		}
		props, props_err := ppmd.decode_properties_zip(input[:ppmd.PROPERTIES_ZIP_SIZE])
		if props_err != nil {
			return props_err
		}
		decode_err = ppmd.decompress_from_bytes(out, input[ppmd.PROPERTIES_ZIP_SIZE:], props, expected, r.options, r.allocator)
	case:
		return archive.General_Error.Unsupported_Method
	}
	if decode_err != nil {
		return decode_err
	}
	if i64(len(out)) != rec.size {
		return Zip_Error.Size_Mismatch
	}
	if hash.crc32(out[:]) != crc {
		return Zip_Error.CRC_Mismatch
	}
	return nil
}

@(private)
_read_link :: proc(r: ^Reader, index: int, allocator: runtime.Allocator) -> (target: string, err: Error) {
	header, name, extra := _central(r, index)
	fi: archive.File_Info
	fill_info(&fi, header, name, extra, nil, r.zone)
	if fi.type != .Symlink {
		return "", nil
	}
	b := strings.builder_make_len_cap(0, int(min(r.records[index].size, 4096)), allocator) or_return
	if err = _extract(r, index, strings.to_writer(&b)); err != nil {
		strings.builder_destroy(&b)
		return "", err
	}
	return strings.to_string(b), nil
}

@(private)
_member_init :: proc(m: ^Member, r: ^Reader, index: int, allocator: runtime.Allocator) -> (err: Error) {
	m^ = {}
	m.reader    = r
	m.allocator = allocator
	rec := &r.records[index]
	header, _, _ := _central(r, index)
	method := _check_supported(header) or_return
	_, _, data_offset := _local(r, rec, nil) or_return
	m.size     = rec.size
	m.expected = u32(header.crc32)
	m.section  = {store = &r.store, offset = data_offset, end = data_offset + rec.compressed_size}

	#partial switch method {
	case .Store:
		if rec.compressed_size != rec.size {
			return Zip_Error.Size_Mismatch
		}
		m.mode = .Store
	case .Deflate, .Deflate64:
		m.mode = .Inflate
		if r.store.memory {
			m.input = r.store.data[data_offset:][:rec.compressed_size]
			m.ctx   = compress.init_context_from_slice(&m.input)
		} else {
			m.ctx = compress.init_context_from_stream(_section_stream(&m.section), nil, -1, nil, allocator)
		}
		format := deflate.Inflate_Format.Raw64 if method == .Deflate64 else .Raw
		if init_err := deflate.inflate_reader_init(&m.inflate, &m.ctx, format, _expected_size(rec.size), r.options, allocator); init_err != nil {
			deflate.inflate_reader_destroy(&m.inflate)
			compress.destroy_context(&m.ctx)
			return init_err
		}
	case:
		m.mode = .Buffer
		m.buffer.allocator = allocator
		if decode_err := _decode(r, rec, method, header.flags, u32(header.crc32), data_offset, &m.buffer); decode_err != nil {
			delete(m.buffer)
			return decode_err
		}
	}
	m.active = true
	return nil
}

@(private)
_member_destroy :: proc(m: ^Member) {
	if !m.active {
		return
	}
	switch m.mode {
	case .Store:
	case .Inflate:
		deflate.inflate_reader_destroy(&m.inflate)
		compress.destroy_context(&m.ctx)
	case .Buffer:
		delete(m.buffer)
	}
	m^ = {}
}

@(private)
_member_read :: proc(m: ^Member, p: []u8) -> (n: int, err: Error) {
	if m.err != nil {
		return 0, m.err
	}
	switch m.mode {
	case .Buffer:
		if m.pos >= len(m.buffer) {
			return 0, io.Error.EOF
		}
		n = copy(p, m.buffer[m.pos:])
		m.pos += n
		return n, nil
	case .Store:
		remaining := m.section.end - m.section.offset
		if remaining <= 0 {
			return 0, _member_finish(m)
		}
		want := int(min(i64(len(p)), remaining))
		if read_err := _store_read(m.section.store, p[:want], m.section.offset); read_err != nil {
			m.err = read_err
			return 0, read_err
		}
		m.section.offset += i64(want)
		n = want
	case .Inflate:
		inflate_err: compress.Error
		n, inflate_err = deflate.inflate_reader_read(&m.inflate, p)
		if inflate_err != nil {
			if io_err, is_io := inflate_err.(io.Error); is_io && io_err == .EOF {
				return 0, _member_finish(m)
			}
			m.err = inflate_err
			return 0, inflate_err
		}
	}
	m.crc       = hash.crc32(p[:n], m.crc)
	m.produced += i64(n)
	if m.produced > m.size {
		m.err = Zip_Error.Size_Mismatch
		return 0, m.err
	}
	return n, nil
}

@(private)
_member_finish :: proc(m: ^Member) -> (err: Error) {
	if m.produced != m.size {
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
		remaining := s.end - s.offset
		if remaining <= 0 {
			return 0, .EOF
		}
		want := int(min(i64(len(p)), remaining))
		if read_err := _store_read(s.store, p[:want], s.offset); read_err != nil {
			return 0, _io_error(read_err)
		}
		s.offset += i64(want)
		return i64(want), nil
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
	return open_member((^Reader)(a.state), handle, a.allocator)
}
