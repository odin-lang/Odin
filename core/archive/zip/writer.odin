package archive_zip

import "base:runtime"
import "core:archive"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:compress/xz"
import "core:hash"
import "core:io"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"
import "core:time/datetime"
import "core:time/timezone"

create_from_path :: proc(zw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	zw^ = {}
	zw.allocator = allocator
	_check_options(options) or_return
	zw.mode = .Create_Path
	defer if err != nil {
		close_writer(zw)
	}
	zw.path      = strings.clone(path, allocator) or_return
	zw.temp_path = _sibling_path(path, TEMP_SUFFIX, allocator) or_return
	lock, lock_err := _lock_open(path, .Exclusive, false, allocator)
	if lock_err != nil && !_is_not_exist(lock_err) {
		return lock_err
	}
	zw.lock = lock
	zw.file = _lock_open(zw.temp_path, .Exclusive, true, allocator) or_return
	if truncate_err := os.truncate(zw.file, 0); truncate_err != nil {
		return truncate_err
	}
	return _writer_init(zw, os.to_stream(zw.file), options)
}

create_from_stream :: proc(zw: ^Writer, s: io.Stream, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	zw^ = {}
	zw.allocator = allocator
	_check_options(options) or_return
	if err = _writer_init(zw, s, options); err != nil {
		close_writer(zw)
	}
	return
}

create :: proc{create_from_path, create_from_stream}

write_entry_with_info :: proc(zw: ^Writer, fi: archive.File_Info, data: Entry_Data = nil, options: Entry_Options = {}) -> (err: Error) {
	_writer_ready(zw) or_return
	p: Pending_Entry
	_prepare(zw, &p, fi, data, options) or_return
	if zw.mode != .Update_Path && zw.mode != .Update_Stream {
		start := zw.offset
		defer if err != nil && zw.offset != start {
			zw.err = err
		}
		return _write_member(zw, &p, data)
	}
	slot := _slot_reserve(zw, p.type == .Directory) or_return
	defer if err != nil {
		delete(slot.raw_name, zw.allocator)
	}
	_journal_begin(zw) or_return
	start := zw.offset
	defer if err != nil && zw.offset != start {
		zw.err = err
	}
	slot.central = len(zw.central)
	_write_member(zw, &p, data) or_return
	slot.header   = p.header
	slot.data_end = zw.offset
	_slot_link(zw, slot)
	return nil
}

write_entry_simple :: proc(zw: ^Writer, name: string, data: Entry_Data = nil, options: Entry_Options = {}) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.type              = .Regular
	fi.modification_time = time.now()
	switch d in data {
	case []u8:
		fi.size = i64(len(d))
	case io.Reader:
		fi.size = -1
		if size, size_err := io.size(d); size_err == nil && size >= 0 {
			fi.size = size
		}
	}
	return write_entry_with_info(zw, fi, data, options)
}

write_entry :: proc{write_entry_with_info, write_entry_simple}

write_directory :: proc(zw: ^Writer, dir: string, prefix := "", options: Entry_Options = {}) -> (err: Error) {
	_writer_ready(zw) or_return
	_ = _entry_password(zw, options) or_return
	root, root_err := os.get_absolute_path(dir, zw.allocator)
	if root_err != nil {
		return root_err
	}
	defer delete(root, zw.allocator)
	base := strings.trim(prefix, "/")
	if base != "" {
		info, stat_err := os.stat(root, zw.allocator)
		if stat_err != nil {
			return stat_err
		}
		defer os.file_info_delete(info, zw.allocator)
		fi: archive.File_Info
		fi.path              = base
		fi.type              = .Directory
		fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
		fi.modification_time = info.modification_time
		fi.access_time       = info.access_time
		fi.creation_time     = info.creation_time
		write_entry_with_info(zw, fi, nil, options) or_return
	}

	walker := os.walker_create(root)
	defer os.walker_destroy(&walker)
	if !zw.options.deterministic {
		for info in os.walker_walk(&walker) {
			if _, walk_err := os.walker_error(&walker); walk_err != nil {
				return walk_err
			}
			_walk_name(zw, root, base, info.fullpath) or_return
			_write_walked(zw, string(zw.walk_name[:]), info, options) or_return
		}
	} else {
		walked: [dynamic]Walked_Entry
		walked.allocator = zw.allocator
		defer {
			for entry in walked {
				delete(entry.name, zw.allocator)
				os.file_info_delete(entry.info, zw.allocator)
			}
			delete(walked)
		}
		for info in os.walker_walk(&walker) {
			if _, walk_err := os.walker_error(&walker); walk_err != nil {
				return walk_err
			}
			_walk_name(zw, root, base, info.fullpath) or_return
			entry: Walked_Entry
			entry.name = strings.clone(string(zw.walk_name[:]), zw.allocator) or_return
			cloned, clone_err := os.file_info_clone(info, zw.allocator)
			if clone_err != nil {
				delete(entry.name, zw.allocator)
				return clone_err
			}
			entry.info = cloned
			if _, append_err := append(&walked, entry); append_err != nil {
				delete(entry.name, zw.allocator)
				os.file_info_delete(entry.info, zw.allocator)
				return append_err
			}
		}
		slice.sort_by(walked[:], proc(a, b: Walked_Entry) -> bool {
			return a.name < b.name
		})
		for entry in walked {
			_write_walked(zw, entry.name, entry.info, options) or_return
		}
	}
	if _, walk_err := os.walker_error(&walker); walk_err != nil {
		return walk_err
	}
	return nil
}

commit :: proc(zw: ^Writer) -> (err: Error) {
	if zw.committed {
		return nil
	}
	_writer_ready(zw) or_return
	defer if err != nil {
		zw.err = err
	}
	switch zw.mode {
	case .Stream:
		_commit_archive(zw, nil) or_return
	case .Create_Path:
		_commit_archive(zw, nil) or_return
		_publish(zw, &zw.file, &zw.lock) or_return
	case .Update_Stream, .Update_Path:
		_commit_update(zw) or_return
	}
	zw.committed = true
	return nil
}

close_writer :: proc(zw: ^Writer) {
	if zw.active && !zw.committed {
		_abort(zw)
	}
	_remove_held(&zw.temp, zw.temp_path)
	if zw.mode == .Create_Path {
		_remove_held(&zw.file, zw.temp_path)
	}
	for f in ([3]^os.File{zw.file, zw.lock, zw.temp}) {
		if f != nil {
			os.close(f)
		}
	}
	close_reader(&zw.old)
	for slot in zw.slots {
		delete(slot.raw_name, zw.allocator)
	}
	delete(zw.slots)
	delete(zw.heads)
	delete(zw.path, zw.allocator)
	delete(zw.temp_path, zw.allocator)
	delete(zw.journal_path, zw.allocator)
	delete(zw.options.comment, zw.allocator)
	delete(zw.central)
	delete(zw.header)
	delete(zw.name)
	delete(zw.walk_name)
	delete(zw.chunk, zw.allocator)
	delete(zw.cipher_buffer, zw.allocator)
	_secret_delete(zw.password, zw.allocator)
	timezone.region_destroy(zw.zone, zw.allocator)
	zw^ = {}
}

@(private)
_commit_archive :: proc(zw: ^Writer, prefix: []u8) -> (err: Error) {
	_flush(zw) or_return
	if zw.offset < zw.end && zw.file == nil {
		_seek(zw, zw.end) or_return
	}
	central_offset := zw.offset
	central_size   := i64(len(prefix)) + i64(len(zw.central))
	_emit(zw, prefix) or_return
	_emit(zw, zw.central[:]) or_return

	clear(&zw.header)
	_put_end(&zw.header, zw.count, central_offset - zw.base, central_size, zw.offset - zw.base, zw.options.comment) or_return
	_emit(zw, zw.header[:]) or_return

	if zw.file != nil && zw.offset < zw.end {
		if truncate_err := os.truncate(zw.file, zw.offset); truncate_err != nil {
			return truncate_err
		}
		zw.end = zw.offset
	}
	return _flush(zw)
}

@(private)
_put_end :: proc(buf: ^[dynamic]u8, count, central_offset, central_size, end_offset: i64, comment: string) -> (err: runtime.Allocator_Error) {
	_grow(buf, size_of(Zip64_End_Record) + size_of(Zip64_Locator) + size_of(End_Record) + len(comment)) or_return
	if count >= ZIP16_MAX || central_size >= ZIP32_MAX || central_offset >= ZIP32_MAX {
		record := Zip64_End_Record{
			signature         = .Zip64_End,
			record_size       = size_of(Zip64_End_Record) - 12,
			made_by_version   = MADE_BY_VERSION,
			made_by_host      = .Unix,
			version_needed    = 45,
			entries_this_disk = u64le(count),
			entries_total     = u64le(count),
			central_size      = u64le(central_size),
			central_offset    = u64le(central_offset),
		}
		locator := Zip64_Locator{
			signature   = .Zip64_Locator,
			end_offset  = u64le(end_offset),
			total_disks = 1,
		}
		_put_struct(buf, record)
		_put_struct(buf, locator)
	}
	end := End_Record{
		signature         = .End,
		entries_this_disk = u16le(min(count, ZIP16_MAX)),
		entries_total     = u16le(min(count, ZIP16_MAX)),
		central_size      = u32le(min(central_size, ZIP32_MAX)),
		central_offset    = u32le(min(central_offset, ZIP32_MAX)),
		comment_length    = u16le(len(comment)),
	}
	_put_struct(buf, end)
	append(buf, comment)
	return nil
}

@(private)
_publish :: proc(zw: ^Writer, temp, target: ^^os.File) -> (err: Error) {
	when ODIN_OS == .Windows {
		os.close(temp^)
		temp^ = nil
		if target^ != nil {
			os.close(target^)
			target^ = nil
		}
		return _replace(zw.temp_path, zw.path, zw.allocator)
	} else {
		if target^ != nil {
			_copy_mode(target^, temp^, zw.allocator)
		}
		_replace(zw.temp_path, zw.path, zw.allocator) or_return
		_sync_parent(zw.path, zw.allocator)
		os.close(temp^)
		temp^ = nil
		if target^ != nil {
			os.close(target^)
			target^ = nil
		}
		return nil
	}
}

@(private)
_abort :: proc(zw: ^Writer) {
	switch zw.mode {
	case .Stream, .Create_Path:
	case .Update_Stream:
		if zw.end > zw.old_length {
			_restore_stream(zw)
		}
	case .Update_Path:
		_remove_held(&zw.temp, zw.temp_path)
		if zw.journaled && zw.file != nil {
			if os.truncate(zw.file, zw.old_length) == nil && os.sync(zw.file) == nil {
				_journal_remove(zw.journal_path, zw.allocator)
				zw.journaled = false
			}
		}
	}
}

@(private)
_writer_init :: proc(zw: ^Writer, s: io.Stream, options: Writer_Options) -> (err: Error) {
	zw.central.allocator   = zw.allocator
	zw.header.allocator    = zw.allocator
	zw.name.allocator      = zw.allocator
	zw.walk_name.allocator = zw.allocator
	zw.options = options
	zw.options.comment = ""
	zw.options.comment = strings.clone(options.comment, zw.allocator) or_return
	zw.options.password = ""
	zw.password = _secret_clone(options.password, zw.allocator) or_return

	modes := io.query(s)
	if .Write not_in modes {
		return io.Error.Unsupported
	}
	zw.stream = s
	if .Seek in modes {
		if position, seek_err := io.seek(s, 0, .Current); seek_err == nil && position >= 0 {
			zw.seekable = true
			zw.offset   = position
			zw.end      = position
		}
	}
	if !options.deterministic {
		zw.zone, _ = timezone.region_load("local", zw.allocator)
	}
	zw.active = true
	return nil
}

@(private)
_check_options :: proc(options: Writer_Options) -> (err: Error) {
	_, _ = _resolve({method = options.method, level = options.level}, {}) or_return
	if len(options.comment) > ZIP16_MAX {
		return Zip_Error.Field_Too_Long
	}
	return _check_password(options.password, options.deterministic)
}

@(private)
_writer_ready :: proc(zw: ^Writer) -> (err: Error) {
	if !zw.active || zw.committed {
		return io.Error.Closed
	}
	return zw.err
}

@(private)
_resolve :: proc "contextless" (defaults, entry: Entry_Options) -> (method: Method, level: int, err: Error) {
	chosen    := defaults.method if defaults.method != .Unknown else .Deflate
	wanted    := entry.method if entry.method != .Unknown else chosen
	requested := entry.level
	if requested == nil && wanted == chosen {
		requested = defaults.level
	}
	#partial switch wanted {
	case .Store:
		return .Store, 0, nil
	case .Deflate, .Deflate64:
		method = .Deflate if wanted == .Deflate else .Deflate64
		level  = clamp(requested.? or_else int(deflate.Deflate_Level.Default), int(deflate.Deflate_Level.Stored), int(deflate.Deflate_Level.Best))
	case .BZip2:
		method = .BZip2
		level  = clamp(requested.? or_else int(bzip2.Level.Default), int(bzip2.Level.Level_1), int(bzip2.Level.Level_9))
	case .LZMA:
		method = .LZMA
		level  = clamp(requested.? or_else int(lzma.Level.Default), int(lzma.Level.Level_0), int(lzma.Level.Level_9))
	case .XZ:
		method = .XZ
		level  = clamp(requested.? or_else int(xz.Level.Default), int(xz.Level.Level_0), int(xz.Level.Level_9))
	case .PPMd_I:
		method = .PPMd
		level  = clamp(requested.? or_else int(ppmd.Level.Default), int(ppmd.Level.Level_0), int(ppmd.Level.Level_9))
	case:
		err = archive.General_Error.Unsupported_Method
	}
	return
}

@(private)
_prepare :: proc(zw: ^Writer, p: ^Pending_Entry, fi: archive.File_Info, data: Entry_Data, options: Entry_Options) -> (err: Error) {
	p.type = .Regular if fi.type == .Unknown else fi.type
	#partial switch p.type {
	case .Regular, .Directory, .Symlink:
	case:
		return archive.General_Error.Unsupported_Entry
	}
	_entry_name(zw, fi.path, p.type == .Directory) or_return
	p.name = zw.name[:]
	if len(fi.comment) > ZIP16_MAX {
		return Zip_Error.Field_Too_Long
	}
	p.comment = fi.comment
	p.method, p.level = _resolve({method = zw.options.method, level = zw.options.level}, options) or_return
	p.password = _entry_password(zw, options) or_return
	if p.type == .Directory {
		p.password = ""
	}

	switch d in data {
	case []u8:
		if p.type != .Regular && len(d) > 0 {
			return archive.General_Error.Incompatible_Options
		}
		p.size = i64(len(d))
	case io.Reader:
		if p.type != .Regular {
			return archive.General_Error.Incompatible_Options
		}
		p.size = fi.size
		if p.size < 0 {
			p.size = -1
			if size, size_err := io.size(d); size_err == nil && size >= 0 {
				p.size = size
			}
		}
	}
	if p.type == .Symlink {
		if len(fi.link_target) == 0 {
			return archive.General_Error.Incompatible_Options
		}
		if len(fi.link_target) > LINK_TARGET_MAX {
			return Zip_Error.Field_Too_Long
		}
		p.link_target = fi.link_target
		p.size        = i64(len(fi.link_target))
	}
	if p.type != .Regular || p.size == 0 {
		p.method = .Store
		p.level  = 0
	}

	mode := fi.unix_mode
	if mode == 0 {
		switch {
		case fi.dos_attributes != 0:
			mode = archive.unix_mode_from_dos(fi.dos_attributes | (archive.DOS_DIRECTORY if p.type == .Directory else 0))
		case p.type == .Directory:
			mode = 0o755
		case p.type == .Symlink:
			mode = 0o777
		case:
			mode = 0o644
		}
	}
	mode = mode & archive.UNIX_PERMISSION_MASK | archive.unix_type_bits(p.type)
	attributes := fi.dos_attributes & 0xFF
	if attributes == 0 {
		attributes = archive.dos_attributes_from_unix(mode, p.type)
	}
	if p.type == .Directory {
		attributes |= archive.DOS_DIRECTORY
	}
	p.external = mode << 16 | attributes

	mtime, atime, ctime := fi.modification_time, fi.access_time, fi.creation_time
	if zw.options.deterministic {
		mtime = time.unix(DOS_EPOCH, 0)
		atime = {}
		ctime = {}
	}
	p.dos_time, p.dos_date = _dos_time(mtime, zw.zone)
	seconds := time.time_to_unix(mtime)
	if seconds >= i64(min(i32)) && seconds <= i64(max(i32)) {
		p.unix_time     = i32(seconds)
		p.has_unix_time = true
	}
	if atime != {} && ctime != {} {
		p.ntfs     = {_filetime(mtime), _filetime(atime), _filetime(ctime)}
		p.has_ntfs = p.ntfs[0] != 0 && p.ntfs[1] != 0 && p.ntfs[2] != 0
	}
	if !zw.options.deterministic && fi.uid >= 0 && fi.gid >= 0 && (fi.uid > 0 || fi.gid > 0) {
		p.uid       = fi.uid
		p.gid       = fi.gid
		p.has_owner = true
	}
	p.utf8 = !_is_ascii(p.name) || !_is_ascii(transmute([]u8)p.comment)
	return nil
}

@(private)
_entry_name :: proc(zw: ^Writer, path: string, directory: bool) -> (err: Error) {
	clear(&zw.name)
	name := path
	when ODIN_OS == .Windows {
		if len(name) >= 2 && name[1] == ':' {
			name = name[2:]
		}
	}
	append(&zw.name, name) or_return
	when ODIN_OS == .Windows {
		for &c in zw.name {
			if c == '\\' {
				c = '/'
			}
		}
	}
	start := 0
	for start < len(zw.name) {
		if zw.name[start] == '/' {
			start += 1
		} else if zw.name[start] == '.' && start + 1 < len(zw.name) && zw.name[start + 1] == '/' {
			start += 2
		} else {
			break
		}
	}
	stop := len(zw.name)
	for stop > start && zw.name[stop - 1] == '/' {
		stop -= 1
	}
	cleaned := string(zw.name[start:stop])
	if cleaned == "" || cleaned == "." || strings.index_byte(cleaned, 0) >= 0 {
		return Zip_Error.Invalid_Name
	}
	rest := cleaned
	for part in strings.split_iterator(&rest, "/") {
		if part == ".." {
			return archive.General_Error.Unsafe_Path
		}
	}
	n := copy(zw.name[:], zw.name[start:stop])
	resize(&zw.name, n)
	if directory {
		append(&zw.name, '/') or_return
	}
	if len(zw.name) > ZIP16_MAX {
		return Zip_Error.Field_Too_Long
	}
	return nil
}

@(private)
_walk_name :: proc(zw: ^Writer, root, base, fullpath: string) -> (err: Error) {
	if !strings.has_prefix(fullpath, root) {
		return Zip_Error.Invalid_Name
	}
	rel := fullpath[len(root):]
	for len(rel) > 0 && (rel[0] == '/' || rel[0] == os.Path_Separator) {
		rel = rel[1:]
	}
	clear(&zw.walk_name)
	if base != "" {
		append(&zw.walk_name, base) or_return
		append(&zw.walk_name, '/') or_return
	}
	start := len(zw.walk_name)
	append(&zw.walk_name, rel) or_return
	for &c in zw.walk_name[start:] {
		if c == os.Path_Separator {
			c = '/'
		}
	}
	return nil
}

@(private)
_write_walked :: proc(zw: ^Writer, name: string, info: os.File_Info, options: Entry_Options) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
	fi.modification_time = info.modification_time
	fi.access_time       = info.access_time
	fi.creation_time     = info.creation_time
	#partial switch info.type {
	case .Directory:
		fi.type = .Directory
		return write_entry_with_info(zw, fi, nil, options)
	case .Symlink:
		target, link_err := os.read_link(info.fullpath, zw.allocator)
		if link_err != nil {
			return link_err
		}
		defer delete(target, zw.allocator)
		fi.type        = .Symlink
		fi.link_target = target
		return write_entry_with_info(zw, fi, nil, options)
	case .Regular:
		f, open_err := os.open(info.fullpath)
		if open_err != nil {
			return open_err
		}
		defer os.close(f)
		fi.type = .Regular
		fi.size = info.size
		return write_entry_with_info(zw, fi, os.to_reader(f), options)
	}
	return nil
}

@(private)
_write_member :: proc(zw: ^Writer, p: ^Pending_Entry, data: Entry_Data) -> (err: Error) {
	if p.type == .Symlink {
		return _write_one_shot(zw, p, transmute([]u8)p.link_target)
	}
	switch d in data {
	case []u8:
		if p.method == .Store || p.size <= ONE_SHOT_MAX {
			return _write_one_shot(zw, p, d)
		}
	case io.Reader:
		if p.size >= 0 && p.size <= ONE_SHOT_MAX {
			buffer: [dynamic]u8
			buffer.allocator = zw.allocator
			defer delete(buffer)
			_read_all(zw, d, p.size, &buffer) or_return
			return _write_one_shot(zw, p, buffer[:])
		}
	case:
		return _write_one_shot(zw, p, nil)
	}
	return _write_streamed(zw, p, data)
}

@(private)
_write_one_shot :: proc(zw: ^Writer, p: ^Pending_Entry, input: []u8) -> (err: Error) {
	p.size = i64(len(input))
	p.crc  = hash.crc32(input)
	head: [16]u8
	head_len := 0
	payload  := input
	packed: [dynamic]u8
	packed.allocator = zw.allocator
	defer delete(packed)
	if p.method != .Store {
		head_len = _compress(zw, p, input, &packed, head[:]) or_return
		if i64(head_len) + i64(len(packed)) < p.size {
			payload = packed[:]
		} else {
			head_len = 0
			p.method = .Store
			p.level  = 0
		}
	}
	p.compressed  = i64(head_len) + i64(len(payload))
	if p.password != "" {
		p.compressed += AES_OVERHEAD
	}
	p.header      = zw.offset
	p.offset      = zw.offset - zw.base
	p.local_zip64 = p.size >= ZIP32_MAX || p.compressed >= ZIP32_MAX
	p.final       = true
	_set_flags(p)
	_local_header(p, &zw.header) or_return
	cipher: Cipher
	defer _cipher_destroy(&cipher)
	_emit(zw, zw.header[:]) or_return
	_encrypt_begin(zw, &cipher, p.password) or_return
	_encrypt_emit(zw, &cipher, head[:head_len]) or_return
	_encrypt_emit(zw, &cipher, payload) or_return
	_encrypt_end(zw, &cipher) or_return
	_progress(zw, p, p.size, p.compressed) or_return
	return _add_central(zw, p)
}

@(private)
_write_streamed :: proc(zw: ^Writer, p: ^Pending_Entry, data: Entry_Data) -> (err: Error) {
	source: Source
	switch d in data {
	case []u8:
		source.data       = d
		source.rewindable = true
	case io.Reader:
		source.reader = d
		if .Seek in io.query(d) {
			if position, seek_err := io.seek(d, 0, .Current); seek_err == nil {
				source.start      = position
				source.rewindable = true
			}
		}
	}
	expected := p.size
	p.header      = zw.offset
	p.offset      = zw.offset - zw.base
	p.local_zip64 = expected < 0 || expected >= ZIP64_LOCAL_LIMIT
	if !zw.seekable {
		p.flags += {.Data_Descriptor}
	}
	_set_flags(p)
	_local_header(p, &zw.header) or_return
	_emit(zw, zw.header[:]) or_return
	data_start := zw.offset

	cipher: Cipher
	defer _cipher_destroy(&cipher)
	chunk := _chunk(zw) or_return
	sink  := Member_Sink{writer = zw}
	if p.password != "" {
		_encrypt_begin(zw, &cipher, p.password) or_return
		sink.cipher = &cipher
	}
	encoder: Encoder
	defer _encoder_destroy(&encoder)
	_encoder_init(&encoder, zw, p, expected, _sink_writer(&sink)) or_return

	crc:      u32
	total:    i64
	reported: i64
	interval := i64(compress.progress_interval(zw.options.options))
	for {
		n, read_err := _source_read(&source, chunk)
		if n > 0 {
			crc    = hash.crc32(chunk[:n], crc)
			total += i64(n)
			if expected >= 0 && total > expected {
				return Zip_Error.Size_Mismatch
			}
			_encoder_write(&encoder, chunk[:n]) or_return
			if total - reported >= interval {
				_progress(zw, p, total, sink.count) or_return
				reported = total
			}
		}
		if read_err == .EOF {
			break
		}
		if read_err != nil {
			return read_err
		}
	}
	if expected >= 0 && total != expected {
		return Zip_Error.Size_Mismatch
	}
	_encoder_finish(&encoder) or_return
	p.size       = total
	p.crc        = crc
	p.compressed = sink.count
	if p.method != .Store && p.compressed >= p.size && zw.seekable && source.rewindable {
		_rewrite_stored(zw, p, &source, data_start, chunk, &cipher) or_return
	}
	if p.password != "" {
		_encrypt_end(zw, &cipher) or_return
		p.compressed += AES_OVERHEAD
	}
	if !p.local_zip64 && (p.size >= ZIP32_MAX || p.compressed >= ZIP32_MAX) {
		return Zip_Error.Too_Large
	}
	p.final = true
	_set_flags(p)
	if zw.seekable {
		_patch_local(zw, p) or_return
	} else {
		_write_descriptor(zw, p) or_return
	}
	_progress(zw, p, p.size, p.compressed) or_return
	return _add_central(zw, p)
}

@(private)
_rewrite_stored :: proc(zw: ^Writer, p: ^Pending_Entry, source: ^Source, data_start: i64, chunk: []u8, cipher: ^Cipher) -> (err: Error) {
	_seek(zw, data_start) or_return
	_encrypt_begin(zw, cipher, p.password) or_return
	if source.reader.procedure != nil {
		if _, seek_err := io.seek(source.reader, source.start, .Start); seek_err != nil {
			return seek_err
		}
	}
	source.position = 0
	crc:   u32
	total: i64
	for {
		n, read_err := _source_read(source, chunk)
		if n > 0 {
			crc    = hash.crc32(chunk[:n], crc)
			total += i64(n)
			if total > p.size {
				return Zip_Error.Size_Mismatch
			}
			_encrypt_emit(zw, cipher, chunk[:n]) or_return
		}
		if read_err == .EOF {
			break
		}
		if read_err != nil {
			return read_err
		}
	}
	if total != p.size {
		return Zip_Error.Size_Mismatch
	}
	if crc != p.crc {
		return Zip_Error.CRC_Mismatch
	}
	p.method     = .Store
	p.level      = 0
	p.compressed = p.size
	return nil
}

@(private)
_read_all :: proc(zw: ^Writer, r: io.Reader, size: i64, out: ^[dynamic]u8) -> (err: Error) {
	if size > i64(max(int)) {
		return runtime.Allocator_Error.Out_Of_Memory
	}
	if size >= 0 {
		non_zero_resize(out, int(size)) or_return
		if _, read_err := io.read_full(r, out[:]); read_err != nil {
			if read_err == .EOF || read_err == .Unexpected_EOF {
				return Zip_Error.Size_Mismatch
			}
			return read_err
		}
		probe: [1]u8
		n, probe_err := io.read(r, probe[:])
		if n > 0 {
			return Zip_Error.Size_Mismatch
		}
		if probe_err != nil && probe_err != .EOF {
			return probe_err
		}
		return nil
	}
	chunk := _chunk(zw) or_return
	source := Source{reader = r}
	for {
		n, read_err := _source_read(&source, chunk)
		append(out, ..chunk[:n]) or_return
		if read_err == .EOF {
			return nil
		}
		if read_err != nil {
			return read_err
		}
	}
}

@(private)
_source_read :: proc(source: ^Source, chunk: []u8) -> (n: int, err: io.Error) {
	if source.reader.procedure == nil {
		if source.position >= len(source.data) {
			return 0, .EOF
		}
		n = copy(chunk, source.data[source.position:])
		source.position += n
		return n, nil
	}
	for _ in 0..<128 {
		n, err = io.read(source.reader, chunk)
		if n > 0 || err != nil {
			return
		}
	}
	return 0, .No_Progress
}

@(private)
_chunk :: proc(zw: ^Writer) -> (chunk: []u8, err: Error) {
	if zw.chunk == nil {
		zw.chunk = make([]u8, WRITE_CHUNK_SIZE, zw.allocator) or_return
	}
	return zw.chunk, nil
}

@(private)
_compress :: proc(zw: ^Writer, p: ^Pending_Entry, input: []u8, packed: ^[dynamic]u8, head: []u8) -> (head_len: int, err: Error) {
	#partial switch p.method {
	case .Deflate:
		deflate.deflate_raw_to_dynamic(packed, input, deflate.Deflate_Level(p.level), _codec_options(zw), zw.allocator) or_return
	case .Deflate64:
		deflate.deflate64_raw_to_dynamic(packed, input, deflate.Deflate_Level(p.level), _codec_options(zw), zw.allocator) or_return
	case .BZip2:
		bzip2.compress_to_dynamic(packed, input, bzip2.Level(p.level), _codec_options(zw), zw.allocator) or_return
	case .LZMA:
		options := lzma.level_options(lzma.Level(p.level))
		options.end_marker = true
		props   := lzma.compress_raw_to_dynamic(packed, input, options, zw.allocator) or_return
		encoded := lzma.encode_properties(props)
		head[0] = LZMA_SDK_VERSION[0]
		head[1] = LZMA_SDK_VERSION[1]
		head[2] = lzma.PROPERTIES_SIZE
		head[3] = 0
		head_len = 4 + copy(head[4:], encoded[:])
	case .XZ:
		xz.compress_to_dynamic(packed, input, xz.Level(p.level), {}, zw.allocator) or_return
	case .PPMd:
		props   := ppmd.level_properties(.I, ppmd.Level(p.level), len(input))
		encoded := ppmd.encode_properties_zip(props) or_return
		ppmd.compress_to_dynamic(packed, input, props, true, _codec_options(zw), zw.allocator) or_return
		head_len = copy(head, encoded[:])
	}
	return
}

@(private)
_codec_options :: proc "contextless" (zw: ^Writer) -> (options: compress.Options) {
	options = zw.options.options
	options.progress      = nil
	options.progress_data = nil
	return
}

@(private)
_encoder_init :: proc(e: ^Encoder, zw: ^Writer, p: ^Pending_Entry, size: i64, w: io.Writer) -> (err: Error) {
	e.method = p.method
	e.w      = w
	options := _codec_options(zw)
	#partial switch p.method {
	case .Deflate:
		deflate.deflate_writer_init(&e.deflate, w, .Raw, deflate.Deflate_Level(p.level), options, zw.allocator) or_return
	case .Deflate64:
		deflate.deflate_writer_init(&e.deflate, w, .Raw64, deflate.Deflate_Level(p.level), options, zw.allocator) or_return
	case .BZip2:
		bzip2.writer_init(&e.bzip2, w, bzip2.Level(p.level), options, zw.allocator) or_return
	case .LZMA:
		lzma_options := lzma.level_options(lzma.Level(p.level))
		lzma_options.end_marker = true
		props   := lzma.writer_init_raw(&e.lzma, w, lzma_options, size, options, zw.allocator) or_return
		encoded := lzma.encode_properties(props)
		head    := [4 + lzma.PROPERTIES_SIZE]u8{0 = LZMA_SDK_VERSION[0], 1 = LZMA_SDK_VERSION[1], 2 = lzma.PROPERTIES_SIZE}
		copy(head[4:], encoded[:])
		if _, write_err := io.write_full(w, head[:]); write_err != nil {
			return write_err
		}
	case .PPMd:
		input_size := int(size) if size >= 0 && size <= i64(max(int)) else -1
		props   := ppmd.level_properties(.I, ppmd.Level(p.level), input_size)
		encoded := ppmd.encode_properties_zip(props) or_return
		if _, write_err := io.write_full(w, encoded[:]); write_err != nil {
			return write_err
		}
		ppmd.writer_init(&e.ppmd, w, props, true, options, zw.allocator) or_return
	case .XZ:
		xz.writer_init(&e.xz, w, xz.Level(p.level), {}, options, zw.allocator) or_return
	}
	return nil
}

@(private)
_encoder_write :: proc(e: ^Encoder, data: []u8) -> (err: Error) {
	#partial switch e.method {
	case .Store:
		if _, write_err := io.write_full(e.w, data); write_err != nil {
			return write_err
		}
	case .Deflate, .Deflate64:
		_ = deflate.deflate_writer_write(&e.deflate, data) or_return
	case .BZip2:
		_ = bzip2.writer_write(&e.bzip2, data) or_return
	case .LZMA:
		_ = lzma.writer_write(&e.lzma, data) or_return
	case .PPMd:
		_ = ppmd.writer_write(&e.ppmd, data) or_return
	case .XZ:
		_ = xz.writer_write(&e.xz, data) or_return
	}
	return nil
}

@(private)
_encoder_finish :: proc(e: ^Encoder) -> (err: Error) {
	#partial switch e.method {
	case .Deflate, .Deflate64:
		deflate.deflate_writer_finish(&e.deflate) or_return
	case .BZip2:
		bzip2.writer_finish(&e.bzip2) or_return
	case .LZMA:
		lzma.writer_finish(&e.lzma) or_return
	case .PPMd:
		ppmd.writer_finish(&e.ppmd) or_return
	case .XZ:
		xz.writer_finish(&e.xz) or_return
	}
	return nil
}

@(private)
_encoder_destroy :: proc(e: ^Encoder) {
	deflate.deflate_writer_destroy(&e.deflate)
	bzip2.writer_destroy(&e.bzip2)
	lzma.writer_destroy(&e.lzma)
	ppmd.writer_destroy(&e.ppmd)
	xz.writer_destroy(&e.xz)
}

@(private)
_sink_writer :: proc(sink: ^Member_Sink) -> (w: io.Writer) {
	w.data      = sink
	w.procedure = _sink_proc
	return
}

@(private)
_sink_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	sink := (^Member_Sink)(stream_data)
	#partial switch mode {
	case .Write:
		zw := sink.writer
		if sink.cipher != nil {
			written, write_err := _encrypt_write(zw, sink.cipher, p)
			sink.count += i64(written)
			return i64(written), write_err
		}
		written, write_err := io.write_full(zw.stream, p)
		sink.count += i64(written)
		zw.offset  += i64(written)
		zw.end      = max(zw.end, zw.offset)
		return i64(written), write_err
	case .Flush:
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Flush, .Query})
	}
	return 0, .Unsupported
}

@(private)
_set_flags :: proc "contextless" (p: ^Pending_Entry) {
	p.flags &= {.Data_Descriptor}
	if p.utf8 {
		p.flags += {.UTF8}
	}
	if p.password != "" {
		p.flags += {.Encrypted}
	}
	#partial switch p.method {
	case .Deflate, .Deflate64:
		switch {
		case p.level >= 9: p.flags += {.Option_1}
		case p.level == 2: p.flags += {.Option_2}
		case p.level <= 1: p.flags += {.Option_1, .Option_2}
		}
	case .LZMA:
		p.flags += {.Option_1}
	}
}

@(private)
_version_needed :: proc "contextless" (p: ^Pending_Entry) -> (version: int) {
	version = 10
	if p.type == .Directory {
		version = 20
	}
	#partial switch p.method {
	case .Deflate:     version = max(version, 20)
	case .Deflate64:   version = max(version, 21)
	case .BZip2:       version = max(version, 46)
	case .LZMA, .PPMd, .XZ: version = max(version, 63)
	}
	if p.local_zip64 || p.offset >= ZIP32_MAX || p.size >= ZIP32_MAX || p.compressed >= ZIP32_MAX {
		version = max(version, 45)
	}
	if p.password != "" {
		version = max(version, AES_VERSION_NEEDED)
	}
	return
}

@(private)
_header_method :: proc "contextless" (p: ^Pending_Entry) -> Method {
	return .AES if p.password != "" else p.method
}

@(private)
_header_crc :: proc "contextless" (p: ^Pending_Entry) -> u32 {
	return 0 if p.password != "" else p.crc
}

@(private)
_put_aes_extra :: proc(buf: ^[dynamic]u8, p: ^Pending_Entry) {
	_put_u16(buf, u16(Extra_ID.AES))
	_put_u16(buf, AES_EXTRA_SIZE)
	_put_u16(buf, AES_VERSION)
	append(buf, 'A', 'E', AES_STRENGTH)
	_put_u16(buf, u16(p.method))
}

@(private)
_local_header :: proc(p: ^Pending_Entry, buf: ^[dynamic]u8) -> (err: runtime.Allocator_Error) {
	extra_length := 0
	if p.local_zip64 {
		extra_length += 4 + 16
	}
	if p.has_unix_time {
		extra_length += 4 + 5
	}
	if p.has_owner {
		extra_length += 4 + _owner_size(p)
	}
	if p.password != "" {
		extra_length += 4 + AES_EXTRA_SIZE
	}
	clear(buf)
	_grow(buf, size_of(Local_Header) + len(p.name) + extra_length) or_return

	known  := p.final && .Data_Descriptor not_in p.flags
	header := Local_Header{
		signature      = .Local,
		version_needed = u16le(_version_needed(p)),
		flags          = p.flags,
		method         = _header_method(p),
		dos_time       = u16le(p.dos_time),
		dos_date       = u16le(p.dos_date),
		name_length    = u16le(len(p.name)),
		extra_length   = u16le(extra_length),
	}
	if known {
		header.crc32 = u32le(_header_crc(p))
		if !p.local_zip64 {
			header.compressed_size   = u32le(p.compressed)
			header.uncompressed_size = u32le(p.size)
		}
	}
	if p.local_zip64 {
		header.compressed_size   = ZIP32_MAX
		header.uncompressed_size = ZIP32_MAX
	}
	_put_struct(buf, header)
	append(buf, ..p.name)
	if p.local_zip64 {
		_put_u16(buf, u16(Extra_ID.Zip64))
		_put_u16(buf, 16)
		_put_u64(buf, u64(p.size) if known else 0)
		_put_u64(buf, u64(p.compressed) if known else 0)
	}
	if p.has_unix_time {
		_put_timestamp(buf, p)
	}
	if p.has_owner {
		_put_owner(buf, p)
	}
	if p.password != "" {
		_put_aes_extra(buf, p)
	}
	return nil
}

@(private)
_patch_local :: proc(zw: ^Writer, p: ^Pending_Entry) -> (err: Error) {
	_local_header(p, &zw.header) or_return
	if _, seek_err := io.seek(zw.stream, p.header, .Start); seek_err != nil {
		return seek_err
	}
	if _, write_err := io.write_full(zw.stream, zw.header[:]); write_err != nil {
		return write_err
	}
	if _, seek_err := io.seek(zw.stream, zw.offset, .Start); seek_err != nil {
		return seek_err
	}
	return nil
}

@(private)
_write_descriptor :: proc(zw: ^Writer, p: ^Pending_Entry) -> (err: Error) {
	clear(&zw.header)
	_grow(&zw.header, 24) or_return
	_put_u32(&zw.header, u32(Signature.Descriptor))
	_put_u32(&zw.header, _header_crc(p))
	if p.local_zip64 {
		_put_u64(&zw.header, u64(p.compressed))
		_put_u64(&zw.header, u64(p.size))
	} else {
		_put_u32(&zw.header, u32(p.compressed))
		_put_u32(&zw.header, u32(p.size))
	}
	return _emit(zw, zw.header[:])
}

@(private)
_add_central :: proc(zw: ^Writer, p: ^Pending_Entry) -> (err: Error) {
	zip64_length := 0
	if p.size >= ZIP32_MAX {
		zip64_length += 8
	}
	if p.compressed >= ZIP32_MAX {
		zip64_length += 8
	}
	if p.offset >= ZIP32_MAX {
		zip64_length += 8
	}
	extra_length := 0
	if zip64_length > 0 {
		extra_length += 4 + zip64_length
	}
	if p.has_unix_time {
		extra_length += 4 + 5
	}
	if p.has_ntfs {
		extra_length += 4 + 32
	}
	if p.has_owner {
		extra_length += 4 + _owner_size(p)
	}
	if p.password != "" {
		extra_length += 4 + AES_EXTRA_SIZE
	}
	buf := &zw.central
	_grow(buf, size_of(Central_Header) + len(p.name) + extra_length + len(p.comment)) or_return

	header := Central_Header{
		signature           = .Central,
		made_by_version     = MADE_BY_VERSION,
		made_by_host        = .Unix,
		version_needed      = u16le(_version_needed(p)),
		flags               = p.flags,
		method              = _header_method(p),
		dos_time            = u16le(p.dos_time),
		dos_date            = u16le(p.dos_date),
		crc32               = u32le(_header_crc(p)),
		compressed_size     = u32le(min(p.compressed, ZIP32_MAX)),
		uncompressed_size   = u32le(min(p.size, ZIP32_MAX)),
		name_length         = u16le(len(p.name)),
		extra_length        = u16le(extra_length),
		comment_length      = u16le(len(p.comment)),
		external_attributes = u32le(p.external),
		local_header_offset = u32le(min(p.offset, ZIP32_MAX)),
	}
	_put_struct(buf, header)
	append(buf, ..p.name)
	if zip64_length > 0 {
		_put_u16(buf, u16(Extra_ID.Zip64))
		_put_u16(buf, u16(zip64_length))
		if p.size >= ZIP32_MAX {
			_put_u64(buf, u64(p.size))
		}
		if p.compressed >= ZIP32_MAX {
			_put_u64(buf, u64(p.compressed))
		}
		if p.offset >= ZIP32_MAX {
			_put_u64(buf, u64(p.offset))
		}
	}
	if p.has_unix_time {
		_put_timestamp(buf, p)
	}
	if p.has_ntfs {
		_put_u16(buf, u16(Extra_ID.NTFS))
		_put_u16(buf, 32)
		_put_u32(buf, 0)
		_put_u16(buf, 1)
		_put_u16(buf, 24)
		for t in p.ntfs {
			_put_u64(buf, t)
		}
	}
	if p.has_owner {
		_put_owner(buf, p)
	}
	if p.password != "" {
		_put_aes_extra(buf, p)
	}
	append(buf, p.comment)
	zw.count      += 1
	zw.archive_in += p.size
	return nil
}

@(private)
_owner_size :: proc "contextless" (p: ^Pending_Entry) -> int {
	uid_size := 4 if u64(p.uid) <= u64(max(u32)) else 8
	gid_size := 4 if u64(p.gid) <= u64(max(u32)) else 8
	return 3 + uid_size + gid_size
}

@(private)
_put_owner :: proc(buf: ^[dynamic]u8, p: ^Pending_Entry) {
	_put_u16(buf, u16(Extra_ID.Unix))
	_put_u16(buf, u16(_owner_size(p)))
	append(buf, 1)
	for id in ([2]i64{p.uid, p.gid}) {
		size := 4 if u64(id) <= u64(max(u32)) else 8
		append(buf, u8(size))
		for i in 0..<size {
			append(buf, u8(u64(id) >> (8 * uint(i))))
		}
	}
}

@(private)
_put_timestamp :: proc(buf: ^[dynamic]u8, p: ^Pending_Entry) {
	_put_u16(buf, u16(Extra_ID.Timestamp))
	_put_u16(buf, 5)
	append(buf, 1)
	_put_u32(buf, u32(p.unix_time))
}

@(private)
_put_struct :: proc(buf: ^[dynamic]u8, value: $T) {
	value := value
	append(buf, ..([^]u8)(&value)[:size_of(T)])
}

@(private)
_put_u16 :: proc(buf: ^[dynamic]u8, v: u16) {
	append(buf, u8(v), u8(v >> 8))
}

@(private)
_put_u32 :: proc(buf: ^[dynamic]u8, v: u32) {
	append(buf, u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24))
}

@(private)
_put_u64 :: proc(buf: ^[dynamic]u8, v: u64) {
	_put_u32(buf, u32(v))
	_put_u32(buf, u32(v >> 32))
}

@(private)
_grow :: proc(buf: ^[dynamic]u8, extra: int) -> (err: runtime.Allocator_Error) {
	need := len(buf) + extra
	if need <= cap(buf) {
		return nil
	}
	return reserve(buf, max(need, 2 * cap(buf)))
}

@(private)
_emit :: proc(zw: ^Writer, p: []u8) -> (err: Error) {
	n, write_err := io.write_full(zw.stream, p)
	zw.offset += i64(n)
	zw.end     = max(zw.end, zw.offset)
	if write_err != nil {
		zw.err = write_err
		return write_err
	}
	return nil
}

@(private)
_seek :: proc(zw: ^Writer, offset: i64) -> (err: Error) {
	if _, seek_err := io.seek(zw.stream, offset, .Start); seek_err != nil {
		return seek_err
	}
	zw.offset = offset
	return nil
}

@(private)
_flush :: proc(zw: ^Writer) -> (err: Error) {
	flush_err := io.flush(zw.stream)
	if flush_err != nil && flush_err != .Unsupported && flush_err != .Empty {
		return flush_err
	}
	return nil
}

@(private)
_progress :: proc(zw: ^Writer, p: ^Pending_Entry, bytes_in, bytes_out: i64) -> (err: Error) {
	options := zw.options.options
	if options.progress == nil {
		return nil
	}
	progress := compress.Progress{
		bytes_in         = bytes_in,
		bytes_out        = bytes_out,
		total_in         = p.size,
		total_out        = p.compressed if p.final else -1,
		member           = string(p.name),
		member_index     = int(zw.count),
		member_count     = -1,
		archive_in       = zw.archive_in + bytes_in,
		archive_total_in = -1,
	}
	if options.progress(progress, options.progress_data) {
		return compress.Error(compress.General_Error.Canceled)
	}
	return nil
}

@(private)
_dos_time :: proc(t: time.Time, zone: ^datetime.TZ_Region) -> (dos_time, dos_date: u16) {
	local := t
	if zone != nil {
		if utc, utc_ok := time.time_to_datetime(t); utc_ok {
			if wall, wall_ok := timezone.datetime_to_tz(utc, zone); wall_ok {
				wall.tz = nil
				if converted, converted_ok := time.datetime_to_time(wall); converted_ok {
					local = converted
				}
			}
		}
	}
	year, month, day     := time.date(local)
	hour, minute, second := time.clock_from_time(local)
	switch {
	case year < 1980:
		return 0, 1 << 5 | 1
	case year > 2107:
		return 23 << 11 | 59 << 5 | 29, 127 << 9 | 12 << 5 | 31
	}
	dos_date = u16(year - 1980) << 9 | u16(month) << 5 | u16(day)
	dos_time = u16(hour) << 11 | u16(minute) << 5 | u16(second / 2)
	return
}

@(private)
_filetime :: proc "contextless" (t: time.Time) -> (filetime: u64) {
	ticks := time.time_to_unix_nano(t) / 100 + NTFS_EPOCH_DELTA
	return u64(ticks) if ticks > 0 else 0
}

@(private)
_is_ascii :: proc "contextless" (b: []u8) -> bool {
	for c in b {
		if c >= 0x80 {
			return false
		}
	}
	return true
}
