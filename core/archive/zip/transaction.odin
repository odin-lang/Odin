#+private
package archive_zip

import "base:runtime"
import "core:archive"
import "core:encoding/endian"
import "core:hash"
import "core:io"
import "core:os"
import "core:strings"

JOURNAL_SUFFIX   :: "-journal"
TEMP_SUFFIX      :: "-temp"
JOURNAL_MAGIC    :: "ZIPJOURN"
JOURNAL_SIZE     :: 28
JOURNAL_TAIL_MAX :: 64 * 1024
LOCK_ATTEMPTS    :: 8

Lock_Kind :: enum u8 {
	Shared,
	Exclusive,
}

_sibling_path :: proc(path, suffix: string, allocator: runtime.Allocator) -> (sibling: string, err: runtime.Allocator_Error) {
	return strings.concatenate({path, suffix}, allocator)
}

_is_not_exist :: proc(err: Error) -> bool {
	os_err, is_os := err.(os.Error)
	if !is_os {
		return false
	}
	general, is_general := os_err.(os.General_Error)
	return is_general && general == .Not_Exist
}

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
	return nil, archive.General_Error.Busy
}

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

_copy_mode :: proc(from, to: ^os.File, allocator: runtime.Allocator) {
	info, stat_err := os.fstat(from, allocator)
	if stat_err != nil {
		return
	}
	defer os.file_info_delete(info, allocator)
	_ = os.fchmod(to, info.mode)
}

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
				return 0, Zip_Error.Truncated
			}
			return 0, read_err
		}
	}
	return crc, nil
}

_journal_write :: proc(path: string, target: ^os.File, old_length: i64, allocator: runtime.Allocator) -> (err: Error) {
	tail := min(old_length, JOURNAL_TAIL_MAX)
	crc  := _file_crc(target, old_length - tail, tail) or_return
	record: [JOURNAL_SIZE]u8
	copy(record[:8], JOURNAL_MAGIC)
	endian.unchecked_put_u64le(record[8:], u64(old_length))
	endian.unchecked_put_u32le(record[16:], u32(tail))
	endian.unchecked_put_u32le(record[20:], crc)
	endian.unchecked_put_u32le(record[24:], hash.crc32(record[:24]))

	f := os.open(path, {.Write, .Create, .Trunc}, os.Permissions_Default_File) or_return
	written, write_err := os.write(f, record[:])
	if write_err == nil && written != len(record) {
		write_err = io.Error.Short_Write
	}
	sync_err := os.sync(f) if write_err == nil else nil
	os.close(f)
	if write_err != nil {
		os.remove(path)
		return write_err
	}
	if sync_err != nil {
		os.remove(path)
		return sync_err
	}
	_sync_parent(path, allocator)
	return nil
}

_journal_check :: proc(path: string, target: ^os.File, size: i64) -> (old_length: i64, present, valid: bool, err: Error) {
	f, open_err := os.open(path, {.Read})
	if open_err != nil {
		if open_err == .Not_Exist {
			return 0, false, false, nil
		}
		return 0, false, false, open_err
	}
	defer os.close(f)
	present = true
	record: [JOURNAL_SIZE + 1]u8
	got := 0
	for got < len(record) {
		n, read_err := os.read(f, record[got:])
		got += n
		if read_err != nil || n == 0 {
			break
		}
	}
	if got != JOURNAL_SIZE || string(record[:8]) != JOURNAL_MAGIC || endian.unchecked_get_u32le(record[24:]) != hash.crc32(record[:24]) {
		return
	}
	old  := endian.unchecked_get_u64le(record[8:])
	tail := i64(endian.unchecked_get_u32le(record[16:]))
	if old > u64(size) || tail > i64(old) || tail > JOURNAL_TAIL_MAX {
		return
	}
	old_length = i64(old)
	crc, crc_err := _file_crc(target, old_length - tail, tail)
	if crc_err != nil {
		return 0, true, false, crc_err
	}
	if crc != endian.unchecked_get_u32le(record[20:]) {
		return 0, true, false, nil
	}
	return old_length, true, true, nil
}

_journal_remove :: proc(path: string, allocator: runtime.Allocator) -> (err: Error) {
	if remove_err := os.remove(path); remove_err != nil && remove_err != .Not_Exist {
		return remove_err
	}
	_sync_parent(path, allocator)
	return nil
}

_recover :: proc(target: ^os.File, journal_path: string, allocator: runtime.Allocator) -> (err: Error) {
	size := os.file_size(target) or_return
	old_length, present, valid := _journal_check(journal_path, target, size) or_return
	if !present {
		return nil
	}
	if valid && old_length < size {
		os.truncate(target, old_length) or_return
		os.sync(target) or_return
	}
	return _journal_remove(journal_path, allocator)
}

_journal_limit :: proc(path: string, target: ^os.File, size: i64, allocator: runtime.Allocator) -> (limit: i64, err: Error) {
	journal_path := _sibling_path(path, JOURNAL_SUFFIX, allocator) or_return
	defer delete(journal_path, allocator)
	old_length, _, valid := _journal_check(journal_path, target, size) or_return
	if valid {
		return old_length, nil
	}
	return size, nil
}

_sync_parent :: proc(path: string, allocator: runtime.Allocator) {
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
