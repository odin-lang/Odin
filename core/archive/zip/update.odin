package archive_zip

import "core:archive"
import "core:archive/transaction"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"

update_from_path :: proc(zw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	zw^ = {}
	zw.allocator = allocator
	_check_options(options) or_return
	zw.mode = .Update_Path
	defer if err != nil {
		close_writer(zw)
	}
	zw.path         = strings.clone(path, allocator) or_return
	zw.temp_path    = transaction.sibling_path(path, transaction.TEMP_SUFFIX, allocator) or_return
	zw.journal_path = transaction.sibling_path(path, transaction.JOURNAL_SUFFIX, allocator) or_return
	zw.file = transaction.lock_open(path, .Exclusive, false, allocator) or_return
	transaction.recover(zw.file, zw.journal_path, allocator) or_return
	transaction.clear_stale(zw.temp_path, allocator) or_return
	return _update_init(zw, os.to_stream(zw.file), options)
}

update_from_stream :: proc(zw: ^Writer, s: io.Stream, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	zw^ = {}
	zw.allocator = allocator
	_check_options(options) or_return
	zw.mode = .Update_Stream
	if err = _update_init(zw, s, options); err != nil {
		close_writer(zw)
	}
	return
}

update :: proc{update_from_path, update_from_stream}

remove_entry :: proc(zw: ^Writer, path: string) -> (err: Error) {
	_writer_ready(zw) or_return
	if zw.mode != .Update_Path {
		return archive.General_Error.Incompatible_Options
	}
	want := archive.clean_member_path(path)
	head, found := zw.heads[want]
	if !found {
		return archive.General_Error.Not_Found
	}
	delete_key(&zw.heads, want)
	for i := head; i >= 0; i = zw.slots[i].next {
		zw.slots[i].removed = true
	}
	zw.modified = true
	return nil
}

rename_entry :: proc(zw: ^Writer, old_path, new_path: string) -> (err: Error) {
	_writer_ready(zw) or_return
	if zw.mode != .Update_Path {
		return archive.General_Error.Incompatible_Options
	}
	want := archive.clean_member_path(old_path)
	head, found := zw.heads[want]
	if !found {
		return archive.General_Error.Not_Found
	}
	_entry_name(zw, new_path, false) or_return
	target := archive.clean_member_path(string(zw.name[:]))
	if target == want {
		return nil
	}
	if target in zw.heads {
		return archive.General_Error.Exists
	}

	count := 0
	for i := head; i >= 0; i = zw.slots[i].next {
		count += 1
	}
	names := make([][]u8, count, zw.allocator) or_return
	defer delete(names, zw.allocator)
	made := 0
	defer if err != nil {
		for name in names[:made] {
			delete(name, zw.allocator)
		}
	}
	for i := head; i >= 0; i = zw.slots[i].next {
		_entry_name(zw, new_path, zw.slots[i].directory) or_return
		names[made] = slice.clone(zw.name[:], zw.allocator) or_return
		made += 1
	}
	reserve(&zw.heads, len(zw.heads) + 1) or_return

	delete_key(&zw.heads, want)
	k := 0
	for i := head; i >= 0; i = zw.slots[i].next {
		slot := &zw.slots[i]
		delete(slot.raw_name, zw.allocator)
		slot.raw_name = names[k]
		slot.name     = archive.clean_member_path(string(slot.raw_name))
		slot.renamed  = true
		k += 1
	}
	zw.heads[zw.slots[head].name] = head
	zw.modified = true
	return nil
}

@(private)
_update_init :: proc(zw: ^Writer, s: io.Stream, options: Writer_Options) -> (err: Error) {
	modes := io.query(s)
	if .Write not_in modes || .Seek not_in modes {
		return archive.General_Error.Not_Seekable
	}
	open_from_stream(&zw.old, s, options.options, zw.allocator) or_return
	_writer_init(zw, s, options) or_return
	if !zw.seekable {
		return archive.General_Error.Not_Seekable
	}
	zw.old_length = zw.old.store.size
	_seek(zw, zw.old_length) or_return
	zw.end       = zw.old_length
	zw.base      = zw.old.base
	zw.count     = i64(len(zw.old.records))
	zw.old_count = zw.count
	if options.comment == "" {
		delete(zw.options.comment, zw.allocator)
		zw.options.comment = ""
		zw.options.comment = strings.clone(string(zw.old.raw_comment), zw.allocator) or_return
	} else {
		zw.comment_set = options.comment != string(zw.old.raw_comment)
	}

	reserve(&zw.slots, len(zw.old.records)) or_return
	reserve(&zw.heads, len(zw.old.records)) or_return
	for index in zw.old.order {
		rec := &zw.old.records[index]
		header, name, extra := _central(&zw.old, index)
		fi: archive.File_Info
		fill_info(&fi, header, name, extra, nil, nil)
		_slot_link(zw, Update_Slot{
			central   = rec.central,
			record    = index,
			header    = rec.local_offset,
			name      = archive.clean_member_path(string(zw.old.names[rec.path:][:rec.path_length])),
			next      = -1,
			old       = true,
			directory = fi.type == .Directory,
		})
	}
	return nil
}

@(private)
_slot_reserve :: proc(zw: ^Writer, directory: bool) -> (slot: Update_Slot, err: Error) {
	if archive.clean_member_path(string(zw.name[:])) in zw.heads {
		return {}, archive.General_Error.Exists
	}
	reserve(&zw.slots, len(zw.slots) + 1) or_return
	reserve(&zw.heads, len(zw.heads) + 1) or_return
	slot.raw_name  = slice.clone(zw.name[:], zw.allocator) or_return
	slot.name      = archive.clean_member_path(string(slot.raw_name))
	slot.record    = -1
	slot.next      = -1
	slot.directory = directory
	return slot, nil
}

@(private)
_slot_link :: proc(zw: ^Writer, slot: Update_Slot) {
	slot := slot
	index := len(zw.slots)
	if head, found := zw.heads[slot.name]; found {
		slot.next = head
	}
	append(&zw.slots, slot)
	zw.heads[slot.name] = index
}

@(private)
_journal_begin :: proc(zw: ^Writer) -> (err: Error) {
	if zw.mode != .Update_Path || zw.journaled {
		return nil
	}
	transaction.journal_write(zw.journal_path, zw.file, zw.old_length, zw.old_length, nil, zw.allocator) or_return
	zw.journaled = true
	return nil
}

@(private)
_commit_update :: proc(zw: ^Writer) -> (err: Error) {
	if zw.modified {
		return _commit_rewrite(zw)
	}
	if zw.count != zw.old_count || zw.comment_set {
		_check_old_extents(zw) or_return
		_journal_begin(zw) or_return
		_commit_archive(zw, zw.old.directory) or_return
	}
	if zw.journaled {
		transaction.journal_remove(zw.journal_path, zw.allocator) or_return
		zw.journaled = false
	}
	if zw.mode == .Update_Path {
		os.close(zw.file)
		zw.file = nil
	}
	return nil
}

@(private)
_check_old_extents :: proc(zw: ^Writer) -> (err: Error) {
	r     := &zw.old
	size  := r.store.size
	slack := i64(size_of(Local_Header)) + 2 * i64(max(u16))
	for rec in r.records {
		if rec.local_offset <= size - slack && rec.compressed_size <= size - slack - rec.local_offset {
			continue
		}
		fixed: [size_of(Local_Header)]u8
		_store_read(&r.store, fixed[:], rec.local_offset) or_return
		header, ok := parse_local(fixed[:])
		if !ok {
			continue
		}
		data_offset := rec.local_offset + size_of(Local_Header) + i64(header.name_length) + i64(header.extra_length)
		if data_offset > size || rec.compressed_size > size - data_offset {
			return Zip_Error.Truncated
		}
	}
	return nil
}

@(private)
_restore_stream :: proc(zw: ^Writer) {
	clear(&zw.central)
	zw.count = zw.old_count
	delete(zw.options.comment, zw.allocator)
	zw.options.comment = ""
	comment, clone_err := strings.clone(string(zw.old.raw_comment), zw.allocator)
	if clone_err != nil {
		return
	}
	zw.options.comment = comment
	_commit_archive(zw, zw.old.directory)
}

@(private)
_commit_rewrite :: proc(zw: ^Writer) -> (err: Error) {
	zw.temp = transaction.lock_open(zw.temp_path, .Exclusive, true, zw.allocator) or_return
	if truncate_err := os.truncate(zw.temp, 0); truncate_err != nil {
		return truncate_err
	}
	out   := os.to_stream(zw.temp)
	chunk := _chunk(zw) or_return
	central: [dynamic]u8
	central.allocator = zw.allocator
	defer delete(central)

	prefix   := _rewrite_prefix(zw)
	base     := zw.base
	position := prefix
	_copy_range(zw.stream, 0, prefix, out, chunk) or_return
	count: i64
	for &slot in zw.slots {
		if slot.removed {
			continue
		}
		header, name, extra, comment, size, compressed := _slot_central(zw, &slot) or_return
		written := _copy_member(zw, &slot, out, chunk) or_return
		_put_moved_central(zw, &central, &slot, header, name, extra, comment, size, compressed, position - base) or_return
		position += written
		count    += 1
	}
	clear(&zw.header)
	_put_end(&zw.header, count, position - base, i64(len(central)), position + i64(len(central)) - base, zw.options.comment) or_return
	if _, write_err := io.write_full(out, central[:]); write_err != nil {
		return write_err
	}
	if _, write_err := io.write_full(out, zw.header[:]); write_err != nil {
		return write_err
	}
	if sync_err := os.sync(zw.temp); sync_err != nil {
		return sync_err
	}

	if zw.journaled {
		if truncate_err := os.truncate(zw.file, zw.old_length); truncate_err != nil {
			return truncate_err
		}
		if sync_err := os.sync(zw.file); sync_err != nil {
			return sync_err
		}
		transaction.journal_remove(zw.journal_path, zw.allocator) or_return
		zw.journaled = false
	}
	return transaction.publish(zw.temp_path, zw.path, &zw.temp, &zw.file, zw.allocator)
}

@(private)
_rewrite_prefix :: proc(zw: ^Writer) -> (prefix: i64) {
	if zw.base > 0 {
		return zw.base
	}
	prefix = zw.old.dir_start
	for rec in zw.old.records {
		prefix = min(prefix, rec.local_offset)
	}
	return clamp(prefix, 0, zw.old_length)
}

@(private)
_slot_central :: proc(zw: ^Writer, slot: ^Update_Slot) -> (header: Central_Header, name, extra, comment: []u8, size, compressed: i64, err: Error) {
	directory := zw.old.directory if slot.old else zw.central[:]
	parse_err: Zip_Error
	header, name, extra, comment, _, parse_err = parse_central(directory, slot.central)
	if parse_err != nil {
		err = parse_err
		return
	}
	if slot.old {
		rec := &zw.old.records[slot.record]
		return header, name, extra, comment, rec.size, rec.compressed_size, nil
	}
	size       = i64(header.uncompressed_size)
	compressed = i64(header.compressed_size)
	offset    := i64(header.local_header_offset)
	disk      := u32(header.start_disk)
	if size == ZIP32_MAX || compressed == ZIP32_MAX || offset == ZIP32_MAX || disk == ZIP16_MAX {
		data, found := find_extra(extra, .Zip64)
		if !found || !apply_zip64(data, &size, &compressed, &offset, &disk) {
			err = Zip_Error.Invalid_Extra_Field
		}
	}
	return
}

@(private)
_copy_member :: proc(zw: ^Writer, slot: ^Update_Slot, out: io.Stream, chunk: []u8) -> (written: i64, err: Error) {
	fixed: [size_of(Local_Header)]u8
	_read_at_full(zw.stream, fixed[:], slot.header) or_return
	local, ok := parse_local(fixed[:])
	if !ok {
		return 0, Zip_Error.Invalid_Local_Header
	}
	n := i64(local.name_length)
	m := i64(local.extra_length)
	data_offset := slot.header + size_of(Local_Header) + n + m
	data_end    := slot.data_end
	if slot.old {
		rec := &zw.old.records[slot.record]
		_, _, checked := _local(&zw.old, rec, nil) or_return
		data_end = checked + rec.compressed_size
		if .Data_Descriptor in local.flags {
			data_end += _descriptor_length(zw, slot, data_end)
		}
	}
	if !slot.renamed {
		_copy_range(zw.stream, slot.header, data_end - slot.header, out, chunk) or_return
		return data_end - slot.header, nil
	}

	extra := make([]u8, int(m), zw.allocator) or_return
	defer delete(extra, zw.allocator)
	_read_at_full(zw.stream, extra, slot.header + size_of(Local_Header) + n) or_return
	clear(&zw.header)
	_grow(&zw.header, size_of(Local_Header) + len(slot.raw_name) + len(extra)) or_return
	_put_struct(&zw.header, local)
	append(&zw.header, ..slot.raw_name)
	kept := 0
	rest := extra
	for id, data in next_extra(&rest) {
		if id == .Unicode_Path {
			continue
		}
		_put_u16(&zw.header, u16(id))
		_put_u16(&zw.header, u16(len(data)))
		append(&zw.header, ..data)
		kept += 4 + len(data)
	}
	append(&zw.header, ..rest)
	kept += len(rest)
	patched := (^Local_Header)(raw_data(zw.header))
	patched.name_length  = u16le(len(slot.raw_name))
	patched.extra_length = u16le(kept)
	if !_is_ascii(slot.raw_name) {
		patched.flags += {.UTF8}
	}
	if _, write_err := io.write_full(out, zw.header[:]); write_err != nil {
		return 0, write_err
	}
	_copy_range(zw.stream, data_offset, data_end - data_offset, out, chunk) or_return
	return i64(len(zw.header)) + data_end - data_offset, nil
}

@(private)
_descriptor_length :: proc(zw: ^Writer, slot: ^Update_Slot, data_end: i64) -> (length: i64) {
	rec   := &zw.old.records[slot.record]
	avail := min(i64(24), rec.end - data_end)
	if avail <= 0 {
		return 0
	}
	buf: [24]u8
	if _read_at_full(zw.stream, buf[:avail], data_end) != nil {
		return 0
	}
	header, _, _ := _central(&zw.old, slot.record)
	Layout :: struct {
		signed: bool,
		wide:   bool,
	}
	for layout in ([4]Layout{{true, false}, {true, true}, {false, false}, {false, true}}) {
		start := 4 if layout.signed else 0
		size  := start + 4 + (16 if layout.wide else 8)
		if i64(size) > avail {
			continue
		}
		if layout.signed && _signature(buf[:], 0) != .Descriptor {
			continue
		}
		if _u32(buf[:], start) != u32(header.crc32) {
			continue
		}
		compressed, uncompressed: u64
		if layout.wide {
			compressed, uncompressed = _u64(buf[:], start + 4), _u64(buf[:], start + 12)
		} else {
			compressed, uncompressed = u64(_u32(buf[:], start + 4)), u64(_u32(buf[:], start + 8))
		}
		if compressed == u64(rec.compressed_size) && uncompressed == u64(rec.size) {
			return i64(size)
		}
	}
	return avail
}

@(private)
_put_moved_central :: proc(zw: ^Writer, buf: ^[dynamic]u8, slot: ^Update_Slot, header: Central_Header, name, extra, comment: []u8, size, compressed, offset: i64) -> (err: Error) {
	moved        := header
	stored_name  := slot.raw_name if slot.renamed else name
	stored_text  := comment
	if slot.renamed && !_is_ascii(stored_name) && .UTF8 not_in moved.flags {
		moved.flags += {.UTF8}
		if slot.old && !_is_ascii(stored_text) {
			rec := &zw.old.records[slot.record]
			stored_text = zw.old.names[rec.comment:][:rec.comment_length]
		}
	}
	zip64_length := 0
	if size >= ZIP32_MAX {
		zip64_length += 8
	}
	if compressed >= ZIP32_MAX {
		zip64_length += 8
	}
	if offset >= ZIP32_MAX {
		zip64_length += 8
	}
	kept := 0
	rest := extra
	for id, data in next_extra(&rest) {
		if id != .Zip64 && !(slot.renamed && id == .Unicode_Path) {
			kept += 4 + len(data)
		}
	}
	kept += len(rest)
	extra_length := kept
	if zip64_length > 0 {
		extra_length += 4 + zip64_length
	}
	if extra_length > ZIP16_MAX || len(stored_text) > ZIP16_MAX {
		return Zip_Error.Field_Too_Long
	}
	_grow(buf, size_of(Central_Header) + len(stored_name) + extra_length + len(stored_text)) or_return

	moved.name_length         = u16le(len(stored_name))
	moved.extra_length        = u16le(extra_length)
	moved.comment_length      = u16le(len(stored_text))
	moved.compressed_size     = u32le(min(compressed, ZIP32_MAX))
	moved.uncompressed_size   = u32le(min(size, ZIP32_MAX))
	moved.local_header_offset = u32le(min(offset, ZIP32_MAX))
	moved.start_disk          = 0
	if zip64_length > 0 {
		moved.version_needed = max(moved.version_needed, 45)
	}
	_put_struct(buf, moved)
	append(buf, ..stored_name)
	if zip64_length > 0 {
		_put_u16(buf, u16(Extra_ID.Zip64))
		_put_u16(buf, u16(zip64_length))
		if size >= ZIP32_MAX {
			_put_u64(buf, u64(size))
		}
		if compressed >= ZIP32_MAX {
			_put_u64(buf, u64(compressed))
		}
		if offset >= ZIP32_MAX {
			_put_u64(buf, u64(offset))
		}
	}
	rest = extra
	for id, data in next_extra(&rest) {
		if id == .Zip64 || (slot.renamed && id == .Unicode_Path) {
			continue
		}
		_put_u16(buf, u16(id))
		_put_u16(buf, u16(len(data)))
		append(buf, ..data)
	}
	append(buf, ..rest)
	append(buf, ..stored_text)
	return nil
}

@(private)
_copy_range :: proc(src: io.Stream, from, count: i64, dst: io.Stream, chunk: []u8) -> (err: Error) {
	done: i64
	for done < count {
		n := int(min(count - done, i64(len(chunk))))
		_read_at_full(src, chunk[:n], from + done) or_return
		if _, write_err := io.write_full(dst, chunk[:n]); write_err != nil {
			return write_err
		}
		done += i64(n)
	}
	return nil
}

@(private)
_read_at_full :: proc(s: io.Stream, p: []u8, offset: i64) -> (err: Error) {
	done := 0
	for done < len(p) {
		n, read_err := io.read_at(s, p[done:], offset + i64(done))
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
