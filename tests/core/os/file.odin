package tests_core_os

import "core:io"
import "core:math/rand"
import "core:os"
import "core:strings"
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
test_temp_names_ignore_context_random_generator :: proc(t: ^testing.T) {
	rand.reset(u64(7547))
	first, first_err := os.make_directory_temp("", "odin-temp-name-*", context.temp_allocator)
	if first_err != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	testing.expect_value(t, os.remove(first), nil)

	rand.reset(u64(7547))
	second, second_err := os.make_directory_temp("", "odin-temp-name-*", context.temp_allocator)
	if second_err != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	defer os.remove(second)

	testing.expect(t, first != second)
}

READ_AT_LARGE :: #config(ODIN_TEST_READ_AT_LARGE, false)

@(private="file")
make_read_at_file :: proc(t: ^testing.T, data: []byte) -> (f: ^os.File, name: string) {
	err: os.Error
	f, err = os.create_temp_file("", "odin-read-at-*")
	if err != nil {
		testing.fail_now(t, "could not create temporary file")
	}
	name = strings.clone(os.name(f), context.temp_allocator)

	n, write_err := os.write(f, data)
	testing.expect_value(t, n, len(data))
	testing.expect_value(t, write_err, nil)
	return
}

@(test)
test_read_at_past_end :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i)
	}

	f, name := make_read_at_file(t, data[:])
	defer os.remove(name)
	defer os.close(f)

	pos, seek_err := os.seek(f, 7, .Start)
	testing.expect_value(t, pos, 7)
	testing.expect_value(t, seek_err, nil)

	buf: [64]byte
	n, err := os.read_at(f, buf[:16], 10)
	testing.expect_value(t, n, 16)
	testing.expect_value(t, err, nil)
	testing.expect(t, string(buf[:16]) == string(data[10:26]))

	n, err = os.read_at(f, buf[:], 50)
	testing.expect_value(t, n, 50)
	testing.expect_value(t, err, io.Error.EOF)
	testing.expect(t, string(buf[:50]) == string(data[50:]))

	n, err = os.read_at(f, buf[:], 36)
	testing.expect_value(t, n, 64)
	testing.expect_value(t, err, nil)
	testing.expect(t, string(buf[:]) == string(data[36:]))

	n, err = os.read_at(f, buf[:16], 100)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)

	n, err = os.read_at(f, buf[:16], 200)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)

	n, err = os.read_at(f, buf[:0], 200)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, nil)

	pos, seek_err = os.seek(f, 0, .Current)
	testing.expect_value(t, pos, 7)
	testing.expect_value(t, seek_err, nil)
}

@(test)
test_read_full_at :: proc(t: ^testing.T) {
	data: [100]byte
	for i in 0..<len(data) {
		data[i] = byte(i) ~ 0x5a
	}

	f, name := make_read_at_file(t, data[:])
	defer os.remove(name)
	defer os.close(f)

	buf: [64]byte
	n, err := os.read_full_at(f, buf[:16], 30)
	testing.expect_value(t, n, 16)
	testing.expect_value(t, err, nil)
	testing.expect(t, string(buf[:16]) == string(data[30:46]))

	n, err = os.read_full_at(f, buf[:], 36)
	testing.expect_value(t, n, 64)
	testing.expect_value(t, err, nil)
	testing.expect(t, string(buf[:]) == string(data[36:]))

	n, err = os.read_full_at(f, buf[:], 50)
	testing.expect_value(t, n, 50)
	testing.expect_value(t, err, io.Error.EOF)
	testing.expect(t, string(buf[:50]) == string(data[50:]))

	n, err = os.read_full_at(f, buf[:16], 100)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)

	n, err = os.read_full_at(f, buf[:0], 100)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, nil)
}

@(test)
test_read_at_large :: proc(t: ^testing.T) {
	when !READ_AT_LARGE {
		return
	}

	SIZE    :: (1 << 30) + 4096
	MARKER  :: "read_at past 1 GiB"
	MARK_AT :: SIZE - 100

	f, name := make_read_at_file(t, nil)
	defer os.remove(name)
	defer os.close(f)

	testing.expect_value(t, os.truncate(f, SIZE), nil)
	n, err := os.write_at(f, transmute([]byte)string(MARKER), MARK_AT)
	testing.expect_value(t, n, len(MARKER))
	testing.expect_value(t, err, nil)

	buf, alloc_err := make([]byte, SIZE + 16)
	if alloc_err != nil {
		testing.fail_now(t, "could not allocate the read buffer")
	}
	defer delete(buf)

	n, err = os.read_at(f, buf[:SIZE], 0)
	testing.expect_value(t, n, SIZE)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(buf[MARK_AT:][:len(MARKER)]), MARKER)

	n, err = os.read_at(f, buf, 0)
	testing.expect_value(t, n, SIZE)
	testing.expect_value(t, err, io.Error.EOF)
}
