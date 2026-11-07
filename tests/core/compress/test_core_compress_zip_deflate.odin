package test_core_compress

import "core:compress"
import "core:compress/deflate"
import "core:hash"
import "core:os"
import "core:testing"

@test
zip_deflate_test_reference :: proc(t: ^testing.T) {
	path := TEST_SUITE_PATH_ZIP + "/deflate.zip"
	file, file_err := os.read_entire_file(path, context.allocator)
	testing.expectf(t, file_err == nil, "couldn't read %v: %v", path, file_err)
	if file_err != nil {
		return
	}
	defer delete(file)

	members, ok := legacy_members(file)
	testing.expect(t, ok, "malformed deflate.zip")

	found := [2]int{}
	for m in members {
		output: [dynamic]u8
		defer delete(output)

		err: compress.Error
		switch u16(m.method) {
		case 8:
			found[0] += 1
			err = deflate.inflate_raw(&output, m.data, m.unpacked)
		case 9:
			found[1] += 1
			err = deflate.inflate64_raw(&output, m.data, m.unpacked)
		case:
			continue
		}
		testing.expectf(t, err == nil, "%v: %v", m.name, err)
		testing.expectf(t, len(output) == m.unpacked, "%v: size %v, expected %v", m.name, len(output), m.unpacked)
		testing.expectf(t, hash.crc32(output[:]) == m.crc, "%v: CRC mismatch", m.name)
	}
	testing.expectf(t, found[0] >= 20, "expected at least 20 Deflated members, found %v", found[0])
	testing.expectf(t, found[1] >= 10, "expected at least 10 Deflate64 members, found %v", found[1])
}
