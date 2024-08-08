package tests_core_os

import "core:os"
import "core:slice"

import "core:testing"

@(test)
read_dir :: proc(t: ^testing.T) {
	fd, err := os.open(#directory + "/dir")
	testing.expect_value(t, err, nil)
	defer os.close(fd)

	dir, err2 := os.read_dir(fd, -1)
	testing.expect_value(t, err2, nil)
	defer os.file_info_slice_delete(dir)

	slice.sort_by_key(dir, proc(fi: os.File_Info) -> string { return fi.name })

	testing.expect_value(t, len(dir), 3)

	testing.expect_value(t, dir[0].name, "alink.txt")
	testing.expect(t, !dir[0].is_dir, "is a directory")
	when ODIN_OS == .Windows {
		testing.expect(t, dir[0].mode & os.File_Mode_Sym_Link != 0, "not a symlink")
	} else {
		testing.expect(t, os.S_ISLNK(auto_cast dir[0].mode), "not a symlink")
	}

	testing.expect_value(t, dir[1].name, "b.txt")

	testing.expect_value(t, dir[2].name, "sub")
	testing.expect(t, dir[2].is_dir, "is not a directory")
}

