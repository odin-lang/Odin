package tests_core_os_os2

import os "core:os/os2"
import    "core:log"
import    "core:path/filepath"
import    "core:slice"
import    "core:testing"

@(test)
test_read_dir :: proc(t: ^testing.T) {
	path := filepath.join({#directory, "../dir"})
	defer delete(path)

	fis, err := os.read_all_directory_by_path(path, context.allocator)
	defer os.file_info_slice_delete(fis, context.allocator)

	slice.sort_by_key(fis, proc(fi: os.File_Info) -> string { return fi.name })

	if err == .Unsupported {
		log.warn("os2 directory functionality is unsupported, skipping test")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 2)

	testing.expect_value(t, fis[0].name, "b.txt")
	testing.expect_value(t, fis[0].type, os.File_Type.Regular)

	testing.expect_value(t, fis[1].name, "sub")
	testing.expect_value(t, fis[1].type, os.File_Type.Directory)
}
