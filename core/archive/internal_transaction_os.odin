#+build !js
package archive

import "base:runtime"
import "core:encoding/endian"
import "core:hash"
import "core:io"
import "core:os"
import "core:strings"

Disk :: struct {
	target:       ^os.File,
	temp:         ^os.File,
	path:         string,
	temp_path:    string,
	journal_path: string,
	allocator:    runtime.Allocator,
	no_sync:      bool,
}

_open_view :: proc(path: string, allocator: runtime.Allocator) -> (s: io.Stream, length: i64, ranges: []Range, err: Error) {
	f := _lock_open(path, .Shared, false, allocator) or_return
	defer if err != nil {
		os.close(f)
	}
	length = os.file_size(f) or_return
	journal_path := strings.concatenate({path, JOURNAL_SUFFIX}, allocator) or_return
	defer delete(journal_path, allocator)
	j, _, valid := _journal_check(journal_path, f, length) or_return
	if valid {
		length = j.old_length
		ranges = _journal_ranges(journal_path, &j, allocator) or_return
	}
	return os.to_stream(f), length, ranges, nil
}

_disk_create :: proc(d: ^Disk, path: string, no_sync: bool, allocator: runtime.Allocator) -> (s: io.Stream, err: Error) {
	_disk_paths(d, path, allocator) or_return
	d.no_sync = no_sync
	target, lock_err := _lock_open(path, .Exclusive, false, allocator)
	if lock_err != nil && !_is_not_exist(lock_err) {
		return {}, lock_err
	}
	d.target = target
	return _disk_rewrite(d)
}

_disk_update :: proc(d: ^Disk, path: string, allocator: runtime.Allocator) -> (s: io.Stream, err: Error) {
	_disk_paths(d, path, allocator) or_return
	d.target = _lock_open(path, .Exclusive, false, allocator) or_return
	_recover(d.target, d.journal_path, allocator) or_return
	_clear_stale(d.temp_path, allocator) or_return
	return os.to_stream(d.target), nil
}

_disk_rewrite :: proc(d: ^Disk) -> (s: io.Stream, err: Error) {
	d.temp = _lock_open(d.temp_path, .Exclusive, true, d.allocator) or_return
	os.truncate(d.temp, 0) or_return
	return os.to_stream(d.temp), nil
}

_disk_journal :: proc(d: ^Disk, old_length, check_end: i64, ranges: []Range) -> (err: Error) {
	if len(ranges) > JOURNAL_RANGES_MAX || check_end < 0 || check_end > old_length {
		return General_Error.Incompatible_Options
	}
	floor := i64(0)
	for r in ranges {
		if r.offset < 0 || i64(len(r.data)) > old_length - r.offset {
			return General_Error.Incompatible_Options
		}
		if r.offset < check_end {
			floor = max(floor, min(r.offset + i64(len(r.data)), check_end))
		}
	}
	tail := min(check_end - floor, JOURNAL_TAIL_MAX)
	crc  := _file_crc(d.target, check_end - tail, tail) or_return

	record: [JOURNAL_FIXED_SIZE + JOURNAL_RANGES_MAX * JOURNAL_RANGE_SIZE + 4]u8
	copy(record[:8], JOURNAL_MAGIC)
	endian.unchecked_put_u64le(record[8:], u64(old_length))
	endian.unchecked_put_u64le(record[16:], u64(check_end))
	endian.unchecked_put_u32le(record[24:], u32(tail))
	endian.unchecked_put_u32le(record[28:], crc)
	endian.unchecked_put_u32le(record[32:], u32(len(ranges)))
	at := JOURNAL_FIXED_SIZE
	for r in ranges {
		endian.unchecked_put_u64le(record[at:], u64(r.offset))
		endian.unchecked_put_u64le(record[at + 8:], u64(len(r.data)))
		endian.unchecked_put_u32le(record[at + 16:], hash.crc32(r.data))
		at += JOURNAL_RANGE_SIZE
	}
	endian.unchecked_put_u32le(record[at:], hash.crc32(record[:at]))
	at += 4

	f := os.open(d.journal_path, {.Write, .Create, .Trunc}, os.Permissions_Default_File) or_return
	write_err := _write_all(f, record[:at])
	for r in ranges {
		if write_err != nil {
			break
		}
		write_err = _write_all(f, r.data)
	}
	sync_err := os.sync(f) if write_err == nil else nil
	os.close(f)
	if write_err != nil {
		os.remove(d.journal_path)
		return write_err
	}
	if sync_err != nil {
		os.remove(d.journal_path)
		return sync_err
	}
	_sync_parent(d.journal_path)
	return nil
}

_disk_restore :: proc(d: ^Disk, old_length: i64, ranges: []Range) -> (err: Error) {
	_restore(d.target, old_length, ranges) or_return
	return _journal_remove(d.journal_path)
}

_disk_truncate :: proc(d: ^Disk, length: i64) -> (err: Error) {
	f := d.temp if d.temp != nil else d.target
	os.truncate(f, length) or_return
	if d.no_sync {
		return nil
	}
	return os.sync(f)
}

_disk_settle :: proc(d: ^Disk) -> (err: Error) {
	os.sync(d.target) or_return
	return _journal_remove(d.journal_path)
}

_disk_publish :: proc(d: ^Disk) -> (err: Error) {
	if d.temp == nil {
		return nil
	}
	if !d.no_sync {
		os.sync(d.temp) or_return
	}
	when ODIN_OS == .Windows {
		_close_held(d)
		return _replace(d.temp_path, d.path, !d.no_sync, d.allocator)
	} else {
		if d.target != nil {
			_copy_mode(d.target, d.temp, d.allocator)
		}
		_replace(d.temp_path, d.path, d.allocator) or_return
		if !d.no_sync {
			_sync_parent(d.path)
		}
		_close_held(d)
		return nil
	}
}

_disk_close :: proc(d: ^Disk) {
	_remove_held(&d.temp, d.temp_path)
	os.close(d.target)
	delete(d.path, d.allocator)
	delete(d.temp_path, d.allocator)
	delete(d.journal_path, d.allocator)
	d^ = {}
}

@(private)
_disk_paths :: proc(d: ^Disk, path: string, allocator: runtime.Allocator) -> (err: runtime.Allocator_Error) {
	d.allocator    = allocator
	d.path         = strings.clone(path, allocator) or_return
	d.temp_path    = strings.concatenate({path, TEMP_SUFFIX}, allocator) or_return
	d.journal_path = strings.concatenate({path, JOURNAL_SUFFIX}, allocator) or_return
	return nil
}

@(private)
_close_held :: proc(d: ^Disk) {
	os.close(d.temp)
	os.close(d.target)
	d.temp   = nil
	d.target = nil
}

@(private)
_is_not_exist :: proc(err: Error) -> bool {
	os_err, is_os := err.(os.Error)
	if !is_os {
		return false
	}
	general, is_general := os_err.(os.General_Error)
	return is_general && general == .Not_Exist
}

@(private)
_lock_open :: proc(path: string, kind: Lock_Kind, create: bool, allocator: runtime.Allocator) -> (f: ^os.File, err: Error) {
	for _ in 0..<LOCK_ATTEMPTS {
		f = _os_lock_open(path, kind, create, allocator) or_return
		if kind == .Shared {
			return f, nil
		}
		same, same_err := _same_file(f, path, allocator)
		if same_err == nil && same {
			return f, nil
		}
		os.close(f)
		f = nil
		if same_err != nil && !_is_not_exist(same_err) {
			return nil, same_err
		}
	}
	return nil, General_Error.Busy
}

@(private)
_copy_mode :: proc(from, to: ^os.File, allocator: runtime.Allocator) {
	info, stat_err := os.fstat(from, allocator)
	if stat_err != nil {
		return
	}
	defer os.file_info_delete(info, allocator)
	_ = os.fchmod(to, info.mode)
}

@(private)
_remove_held :: proc(f: ^^os.File, path: string) {
	if f^ == nil {
		return
	}
	when ODIN_OS == .Windows {
		os.close(f^)
		f^ = nil
		os.remove(path)
	} else {
		os.remove(path)
		os.close(f^)
		f^ = nil
	}
}

@(private)
_clear_stale :: proc(path: string, allocator: runtime.Allocator) -> (err: Error) {
	f, open_err := _lock_open(path, .Exclusive, false, allocator)
	if open_err != nil {
		if _is_not_exist(open_err) {
			return nil
		}
		return open_err
	}
	_remove_held(&f, path)
	return nil
}

@(private)
_sync_parent :: proc(path: string) {
	when ODIN_OS != .Windows {
		parent := os.dir(path)
		if parent == "" {
			parent = "."
		}
		d, open_err := os.open(parent, {.Read})
		if open_err != nil {
			return
		}
		os.sync(d)
		os.close(d)
	}
}

@(private)
_journal_check :: proc(path: string, target: ^os.File, size: i64) -> (j: Journal, present, valid: bool, err: Error) {
	f, open_err := os.open(path, {.Read})
	if open_err != nil {
		if open_err == .Not_Exist {
			return {}, false, false, nil
		}
		return {}, false, false, open_err
	}
	defer os.close(f)
	present = true
	journal_size, size_err := os.file_size(f)
	if size_err != nil {
		return {}, true, false, size_err
	}

	record: [JOURNAL_FIXED_SIZE + JOURNAL_RANGES_MAX * JOURNAL_RANGE_SIZE + 4]u8
	if journal_size < JOURNAL_FIXED_SIZE + 4 {
		return
	}
	if _read_full(f, record[:JOURNAL_FIXED_SIZE], 0) != nil || string(record[:8]) != JOURNAL_MAGIC {
		return
	}
	count := endian.unchecked_get_u32le(record[32:])
	if count > JOURNAL_RANGES_MAX {
		return
	}
	table := JOURNAL_FIXED_SIZE + int(count) * JOURNAL_RANGE_SIZE
	if journal_size < i64(table) + 4 || _read_full(f, record[JOURNAL_FIXED_SIZE:table + 4], JOURNAL_FIXED_SIZE) != nil {
		return
	}
	if endian.unchecked_get_u32le(record[table:]) != hash.crc32(record[:table]) {
		return
	}

	old_length := endian.unchecked_get_u64le(record[8:])
	check_end  := endian.unchecked_get_u64le(record[16:])
	tail       := i64(endian.unchecked_get_u32le(record[24:]))
	if old_length > u64(max(i64)) || check_end > old_length || check_end > u64(size) || tail > i64(check_end) || tail > JOURNAL_TAIL_MAX {
		return
	}
	j.old_length  = i64(old_length)
	j.check_end   = i64(check_end)
	j.range_count = int(count)
	position := i64(table) + 4
	for k in 0..<j.range_count {
		at := JOURNAL_FIXED_SIZE + k * JOURNAL_RANGE_SIZE
		offset := endian.unchecked_get_u64le(record[at:])
		length := endian.unchecked_get_u64le(record[at + 8:])
		if offset > old_length || length > old_length - offset {
			return
		}
		r := &j.ranges[k]
		r.offset   = i64(offset)
		r.length   = i64(length)
		r.crc      = endian.unchecked_get_u32le(record[at + 16:])
		r.position = position
		if r.offset < j.check_end && r.offset + r.length > j.check_end - tail {
			return
		}
		if r.length > journal_size - position {
			return
		}
		position += r.length
	}
	if position != journal_size {
		return
	}

	crc, crc_err := _file_crc(target, j.check_end - tail, tail)
	if crc_err != nil {
		return {}, true, false, crc_err
	}
	if crc != endian.unchecked_get_u32le(record[28:]) {
		return {}, true, false, nil
	}
	for k in 0..<j.range_count {
		r := &j.ranges[k]
		data_crc, data_err := _file_crc(f, r.position, r.length)
		if data_err != nil {
			return {}, true, false, data_err
		}
		if data_crc != r.crc {
			return {}, true, false, nil
		}
	}
	return j, true, true, nil
}

@(private)
_journal_remove :: proc(path: string) -> (err: Error) {
	if remove_err := os.remove(path); remove_err != nil && remove_err != .Not_Exist {
		return remove_err
	}
	_sync_parent(path)
	return nil
}

@(private)
_journal_ranges :: proc(path: string, j: ^Journal, allocator: runtime.Allocator) -> (ranges: []Range, err: Error) {
	if j.range_count == 0 {
		return nil, nil
	}
	f := os.open(path, {.Read}) or_return
	defer os.close(f)
	ranges = make([]Range, j.range_count, allocator) or_return
	defer if err != nil {
		_ranges_delete(ranges, allocator)
		ranges = nil
	}
	for k in 0..<j.range_count {
		r := &j.ranges[k]
		ranges[k].offset = r.offset
		ranges[k].data   = make([]u8, int(r.length), allocator) or_return
		_read_full(f, ranges[k].data, r.position) or_return
		if hash.crc32(ranges[k].data) != r.crc {
			return nil, io.Error.Unexpected_EOF
		}
	}
	return
}

@(private)
_restore :: proc(target: ^os.File, old_length: i64, ranges: []Range) -> (err: Error) {
	size := os.file_size(target) or_return
	if size != old_length {
		os.truncate(target, old_length) or_return
	}
	for r in ranges {
		written := 0
		for written < len(r.data) {
			n, write_err := os.write_at(target, r.data[written:], r.offset + i64(written))
			written += n
			if write_err != nil {
				return write_err
			}
			if n == 0 {
				return io.Error.Short_Write
			}
		}
	}
	return os.sync(target)
}

@(private)
_recover :: proc(target: ^os.File, journal_path: string, allocator: runtime.Allocator) -> (err: Error) {
	size := os.file_size(target) or_return
	j, present, valid := _journal_check(journal_path, target, size) or_return
	if !present {
		return nil
	}
	if valid && (j.range_count > 0 || j.old_length < size) {
		ranges := _journal_ranges(journal_path, &j, allocator) or_return
		defer _ranges_delete(ranges, allocator)
		_restore(target, j.old_length, ranges) or_return
	}
	return _journal_remove(journal_path)
}

@(private)
_same_file :: proc(f: ^os.File, path: string, allocator: runtime.Allocator) -> (same: bool, err: Error) {
	when ODIN_OS == .Windows {
		return true, nil
	} else {
		held, held_err := os.fstat(f, allocator)
		if held_err != nil {
			return false, held_err
		}
		defer os.file_info_delete(held, allocator)
		named, named_err := os.stat(path, allocator)
		if named_err != nil {
			return false, named_err
		}
		defer os.file_info_delete(named, allocator)
		return held.inode == named.inode && held.device == named.device, nil
	}
}

@(private)
_file_crc :: proc(f: ^os.File, offset, length: i64) -> (crc: u32, err: Error) {
	buf: [4096]u8
	done: i64
	for done < length {
		n := int(min(length - done, i64(len(buf))))
		got, read_err := os.read_at(f, buf[:n], offset + done)
		if got > 0 {
			crc   = hash.crc32(buf[:got], crc)
			done += i64(got)
		}
		if done < length && (read_err != nil || got == 0) {
			if read_err == nil || read_err == io.Error.EOF {
				return 0, io.Error.Unexpected_EOF
			}
			return 0, read_err
		}
	}
	return crc, nil
}

@(private)
_read_full :: proc(f: ^os.File, p: []u8, offset: i64) -> (err: Error) {
	done := 0
	for done < len(p) {
		n, read_err := os.read_at(f, p[done:], offset + i64(done))
		done += n
		if done == len(p) {
			break
		}
		if read_err != nil && read_err != io.Error.EOF {
			return read_err
		}
		if n == 0 {
			return io.Error.Unexpected_EOF
		}
	}
	return nil
}

@(private)
_write_all :: proc(f: ^os.File, p: []u8) -> (err: Error) {
	written := 0
	for written < len(p) {
		n, write_err := os.write(f, p[written:])
		written += n
		if write_err != nil {
			return write_err
		}
		if n == 0 {
			return io.Error.Short_Write
		}
	}
	return nil
}
