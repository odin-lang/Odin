package tests_core_os_os2

import os "core:os/os2"
import    "core:testing"

@(test)
test_clone :: proc(t: ^testing.T) {
	joined, err := os.join_path({#directory, "file.odin"}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	f: ^os.File
	f, err = os.open(joined)
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
