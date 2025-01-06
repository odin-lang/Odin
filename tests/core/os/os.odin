package test_core_os

import "core:c/libc"
import win32 "core:sys/windows"
import "core:os"
import "core:slice"
import "core:testing"
import "core:log"

_ :: libc
_ :: win32

@(test)
read_dir :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		link    := win32.utf8_to_wstring(#directory + "dir/alink.txt")
		target  := win32.utf8_to_wstring(#directory + "dir/a.txt")
		sym_err := win32.CreateSymbolicLinkW(link, target, win32.SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)

		if !sym_err {
			log.infof("Unable to create symlink, skipping test. Error: %v", win32.GetLastError())
			return
		}
	} else {
		sym_err := libc.system("ln -s " + #directory + "dir/a.txt " + #directory + "dir/alink.txt")
		if sym_err != 0 {
			log.infof("Unable to create symlink, skipping test. Error: %v", sym_err)
			return
		}
	}
	defer os.remove(#directory + "dir/alink.txt")

	fd, err := os.open(#directory + "/dir")
	testing.expect_value(t, err, nil)
	defer {
		testing.expect_value(t, os.close(fd), nil)
	}

	dir, err2 := os.read_dir(fd, -1)
	testing.expect_value(t, err2, nil)
	defer os.file_info_slice_delete(dir)

	slice.sort_by_key(dir, proc(fi: os.File_Info) -> string { return fi.name })

	testing.expect_value(t, len(dir), 3)

	if len(dir) > 0 {
		testing.expect_value(t, dir[0].name, "alink.txt")
		testing.expect(t, !dir[0].is_dir, "is a directory")
		when ODIN_OS == .Windows {
			testing.expect(t, dir[0].mode & os.File_Mode_Sym_Link != 0, "not a symlink")
		} else {
			testing.expect(t, os.S_ISLNK(auto_cast dir[0].mode), "not a symlink")
		}
	}
	if len(dir) > 1 {
		testing.expect_value(t, dir[1].name, "b.txt")
	}
	if len(dir) > 2 {
		testing.expect_value(t, dir[2].name, "sub")
		testing.expect(t, dir[2].is_dir, "is not a directory")
	}
}
