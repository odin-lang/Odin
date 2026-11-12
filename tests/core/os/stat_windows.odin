#+build windows
package tests_core_os

import "core:fmt"
import "core:os"
import win32 "core:sys/windows"
import "core:testing"

@(test)
test_stat_junction :: proc(t: ^testing.T) {
	root, root_err := os.make_directory_temp("", "odin-stat-junction-*", context.temp_allocator)
	if !testing.expect_value(t, root_err, nil) {
		return
	}
	defer os.remove_all(root)
	target, _ := os.join_path({root, "target"}, context.temp_allocator)
	link,   _ := os.join_path({root, "link"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory(target), nil)
	testing.expect_value(t, os.make_directory(link), nil)
	if !make_junction(link, target) {
		testing.fail_now(t, "could not create a directory junction")
	}

	lfi, lerr := os.lstat(link, context.allocator)
	testing.expect_value(t, lerr, nil)
	testing.expect_value(t, lfi.type, os.File_Type.Symlink)
	testing.expect_value(t, lfi.name, "link")
	os.file_info_delete(lfi, context.allocator)

	sfi, serr := os.stat(link, context.allocator)
	testing.expect_value(t, serr, nil)
	testing.expect_value(t, sfi.type, os.File_Type.Directory)
	testing.expect_value(t, sfi.name, "link")
	os.file_info_delete(sfi, context.allocator)
}

make_junction :: proc(link, target: string) -> bool {
	substitute := win32.utf8_to_utf16(fmt.tprintf(`\??\%s`, target), context.temp_allocator)
	if len(substitute) == 0 {
		return false
	}

	buffer: [win32.MAXIMUM_REPARSE_DATA_BUFFER_SIZE]u8
	header_size  := size_of(win32.REPARSE_DATA_BUFFER)
	names_offset := header_size + int(offset_of(win32.MOUNT_POINT_REPARSE_BUFFER, PathBuffer))
	names_size   := (len(substitute) + 2) * size_of(u16)
	if names_offset + names_size > len(buffer) {
		return false
	}

	header      := (^win32.REPARSE_DATA_BUFFER)(&buffer[0])
	mount_point := (^win32.MOUNT_POINT_REPARSE_BUFFER)(&buffer[header_size])
	names       := ([^]u16)(&buffer[names_offset])
	copy(names[:len(substitute)], substitute)
	mount_point.SubstituteNameOffset = 0
	mount_point.SubstituteNameLength = u16(len(substitute) * size_of(u16))
	mount_point.PrintNameOffset      = u16((len(substitute) + 1) * size_of(u16))
	mount_point.PrintNameLength      = 0
	header.ReparseTag        = win32.IO_REPARSE_TAG_MOUNT_POINT
	header.ReparseDataLength = u16(names_offset - header_size + names_size)

	handle := win32.CreateFileW(
		win32.utf8_to_wstring(link, context.temp_allocator),
		win32.GENERIC_WRITE,
		0,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_FLAG_BACKUP_SEMANTICS | win32.FILE_FLAG_OPEN_REPARSE_POINT,
		nil,
	)
	if handle == win32.INVALID_HANDLE_VALUE {
		return false
	}
	defer win32.CloseHandle(handle)

	returned: win32.DWORD
	return bool(win32.DeviceIoControl(handle, win32.FSCTL_SET_REPARSE_POINT, &buffer[0], win32.DWORD(names_offset + names_size), nil, 0, &returned, nil))
}
