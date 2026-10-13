package tests_core_os

import "core:os"
import "core:testing"

@(test)
test_clone :: proc(t: ^testing.T) {
	joined, j_err := os.join_path({#directory, "file.odin"}, context.temp_allocator)
	testing.expect_value(t, j_err, nil)
	f, err := os.open(joined)
	testing.expect_value(t, err, nil)
	testing.expect(t, f != nil)

	clone: ^os.File
	clone, err = os.clone(f)
	testing.expect_value(t, err, nil)
	testing.expect(t, clone != nil)

	testing.expect_value(t, os.name(clone), os.name(f))
	testing.expect(t, os.fd(clone) != os.fd(f))

	os.close(f)

	buf: [128]byte
	n: int
	n, err = os.read(clone, buf[:])
	testing.expect_value(t, err, nil)
	testing.expect(t, n > 13)
	testing.expect_value(t, string(buf[:13]), "package tests")

	os.close(clone)
}

@(test)
test_open_create_default_permissions :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		// Windows derives the permissions from file attributes, not `perm`
		return
	}

	dir, dir_err := os.make_directory_temp("", "test_open_perm_*", context.temp_allocator)
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	defer os.remove_all(dir)

	opened, _ := os.join_path({dir, "opened"}, context.temp_allocator)
	created, _ := os.join_path({dir, "created"}, context.temp_allocator)

	f, err := os.open(opened, {.Write, .Create})
	testing.expect_value(t, err, nil)
	os.close(f)

	f, err = os.create(created)
	testing.expect_value(t, err, nil)
	os.close(f)

	opened_fi, opened_err := os.stat(opened, context.temp_allocator)
	testing.expect_value(t, opened_err, nil)
	created_fi, created_err := os.stat(created, context.temp_allocator)
	testing.expect_value(t, created_err, nil)

	// A file created by `open` without an explicit `perm` is a regular file, not executable
	testing.expect_value(t, opened_fi.mode & os.Permissions_Execute_All, os.Permissions{})
	testing.expect_value(t, opened_fi.mode, created_fi.mode)
}
