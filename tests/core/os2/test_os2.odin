package test_os2

import "core:os"
import "core:fmt"
import "core:mem"
import "core:os/os2"
import "core:testing"
import "core:intrinsics"

// really only want sys_access for more finite testing
when ODIN_OS == .Linux {
	import "core:sys/unix"
}

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect_value :: testing.expect_value
	expect       :: testing.expect
	log          :: testing.log
} else {
	expect_value :: proc(t: ^testing.T, value, expected: $T, loc := #caller_location) where intrinsics.type_is_comparable(T) {
		fmt.printf("[%v] ", loc)
		TEST_count += 1
		ok := value == expected
		if !ok {
			fmt.printf("expected %v, got %v\n", expected, value)
			TEST_fail += 1
			return
		}
		fmt.println(" PASS")
	}

	expect :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.println(message)
			return
		}
		fmt.println(" PASS")
	}
	log :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc()
{
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	
	t: testing.T
	file_test(&t)
	path_test(&t)
	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
	
	os.exit(TEST_fail > 0 ? 1 : 0)
}

@private
_expect_no_error :: proc(t: ^testing.T, e: os2.Error, loc := #caller_location) {
	expect(t, e == nil, "unexpected error", loc)
}


F_OK :: 0 // Test for file existence
X_OK :: 1 // Test for execute permission
W_OK :: 2 // Test for write permission
R_OK :: 4 // Test for read permission

@test
file_test :: proc(t: ^testing.T) {

	/* Things to test:
	 * std_handle,create,open,close,name,seek,read,read_at,read_from,write,write_at,
	 * write_to,file_size,sync,flush,truncate,remove,rename,link,symlink,read_link,
	 * unlink,chdir,chmod,chown,lchown,chtimes,exists,is_file,is_dir
	 */

	stdin := os2.std_handle(.stdin)
	expect_value(t, stdin, 0)
	stdout := os2.std_handle(.stdout)
	expect_value(t, stdout, 1)
	stderr := os2.std_handle(.stderr)
	expect_value(t, stderr, 2)

	fd, err := os2.open("filethatdoesntexist.txt")
	expect(t, err != nil, "missing error")
	expect_value(t, fd, os2.INVALID_HANDLE)

	// NOTE: no executable permissions here
	fd, err = os2.open("file.txt", {.Write, .Create, .Trunc}, 0o664)
	_expect_no_error(t, err)
	expect(t, fd != os2.INVALID_HANDLE, "unexpected handle")

	s := "hello"
	n: int
	n, err = os2.write_at(fd, transmute([]u8)s, 10)
	_expect_no_error(t, err)
	expect_value(t, n, 5)

	s = "abcdefghij"
	n, err = os2.write(fd, transmute([]u8)s)
	_expect_no_error(t, err)
	expect_value(t, n, 10)

	// seek to the "ll" in "hello"
	n64: i64
	n64, err = os2.seek(fd, 12, .Start)
	_expect_no_error(t, err)
	expect_value(t, n64, 12)

	s = "11"
	n, err = os2.write(fd, transmute([]u8)s)
	_expect_no_error(t, err)
	expect_value(t, n, 2)

	// seek to the "e" in "he11o"
	n64, err = os2.seek(fd, -3, .Current)
	_expect_no_error(t, err)
	expect_value(t, n64, 11)

	s = "3"
	n, err = os2.write(fd, transmute([]u8)s)
	_expect_no_error(t, err)
	expect_value(t, n, 1)

	// seek to the "o" in "h311o"
	n64, err = os2.seek(fd, -1, .End)
	_expect_no_error(t, err)
	expect_value(t, n64, 14)

	s = "0"
	n, err = os2.write(fd, transmute([]u8)s)
	_expect_no_error(t, err)
	expect_value(t, n, 1)

	_expect_no_error(t, os2.sync(fd))

	// Add executable permissions to current file (as well as read/write to all)
	err = os2.chmod(fd, 0o766)
	_expect_no_error(t, err)

	when ODIN_OS == .Linux {
		expect(t, unix.sys_access("file.txt", X_OK) == 0, "expected exec permission")
	}

	// NOTE: chown not possible without root user
	//_expect_no_error(t, os2.chown(fd, 0, 0))
	_expect_no_error(t, os2.close(fd))


	fd, err = os2.open("file.txt")
	_expect_no_error(t, err)

	buf: [32]u8

	n, err = os2.read(fd, buf[:])
	_expect_no_error(t, err)
	expect_value(t, n, 15)
	expect_value(t, string(buf[:n]), "abcdefghijh3110")

	n, err = os2.read_at(fd, buf[0:2], 1)
	_expect_no_error(t, err)
	expect_value(t, n, 2)
	expect_value(t, string(buf[0:2]), "bc")

	n64, err = os2.file_size(fd)
	_expect_no_error(t, err)
	expect_value(t, n64, 15)

	_expect_no_error(t, os2.close(fd))

	_expect_no_error(t, os2.remove("file.txt"))
	_expect_no_error(t, os2.mkdir("empty dir", 0o755))
	_expect_no_error(t, os2.remove("empty dir"))
}

@test
path_test :: proc(t: ^testing.T) {
	err: os2.Error
	if os2.exists("a") {
		err = os2.remove_all("a")
		_expect_no_error(t, err)
	}

	err = os2.mkdir_all("a/b/c/d", 0o755)
	_expect_no_error(t, err)

	expect(t, os2.exists("a"), "directory does not exist")

	fd: os2.Handle
	fd, err = os2.create("a/b/c/file.txt", 0o644)
	_expect_no_error(t, err)


	when ODIN_OS == .Linux {
		expect(t, unix.sys_access("a/b/c/file.txt", X_OK) < 0, "unexpected exec permission")
	} else {
		expect(t, os2.exists("a/b/c/file.txt"), "file does not exist")
	}

	err = os2.rename("a/b/c/file.txt", "a/b/file.txt")
	_expect_no_error(t, err)

	when ODIN_OS == .Linux {
		expect(t, unix.sys_access("a/b/c/file.txt", F_OK) < 0, "unexpected file existence")
	} else {
		expect(t, !os2.exists("a/b/c/file.txt"), "unexpected file existence")
	}

	err = os2.symlink("b/c/d", "a/symlink_to_d")
	_expect_no_error(t, err)

	symlink: string
	symlink, err = os2.read_link("a/symlink_to_d")
	_expect_no_error(t, err)
	expect_value(t, symlink, "b/c/d")
	delete(symlink)

	fd, err = os2.create("a/symlink_to_d/shnt.txt", 0o744)
	_expect_no_error(t, err)

	err = os2.close(fd)
	_expect_no_error(t, err)

	when ODIN_OS == .Linux {
		expect_value(t, unix.sys_access("a/b/c/d/shnt.txt", X_OK | R_OK | W_OK), 0)
	} else {
		expect(t, os2.exists("a/b/c/d/shnt.txt"), "file does not exist")
	}

	err = os2.remove_all("a")
	_expect_no_error(t, err)

	expect(t, !os2.exists("a"), "directory a exists")
}
