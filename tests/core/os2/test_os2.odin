package test_os2

import "core:fmt"
import "core:os/os2"
import "core:sys/unix"
import "core:testing"
import "core:intrinsics"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect_value :: proc(t: ^testing.T, value, expected: $T, loc := #caller_location) where intrinsics.type_is_comparable(T) {
		fmt.printf("[%v] ", loc)
		TEST_count += 1
		ok := value == expected
		if !ok {
			fmt.printf("expected %v, got %v", expected, value)
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
	t: testing.T
	file_test(&t)
	path_test(&t)
	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
}

@private
_expect_no_error :: proc(t: ^testing.T, e: os2.Error, loc := #caller_location) {
	expect(t, e == nil, "unexpected error", loc)
}


F_OK :: 0 // Test for file existance
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

	fd, err = os2.open("write.txt", {.Write, .Create, .Trunc}, 0o664)
	_expect_no_error(t, err)
	expect(t, fd != os2.INVALID_HANDLE, "unexpected handle")

	s1 := "hello"
	b1 := transmute([]u8)s1

	n: int
	n, err = os2.write_at(fd, b1, 10)
	_expect_no_error(t, err)
	expect_value(t, n, 5)

	s2 := "abcdefghij"
	b2 := transmute([]u8)s2

	n, err = os2.write(fd, b2)
	_expect_no_error(t, err)
	expect_value(t, n, 10)

	_expect_no_error(t, os2.sync(fd))
	_expect_no_error(t, os2.close(fd))

	fd, err = os2.open("write.txt")
	_expect_no_error(t, err)

	buf: [32]u8
	
	n, err = os2.read(fd, buf[:])
	_expect_no_error(t, err)
	expect_value(t, n, 15)
	expect_value(t, string(buf[:n]), "abcdefghijhello")

	n, err = os2.read_at(fd, buf[0:2], 1)
	_expect_no_error(t, err)
	expect_value(t, n, 2)
	expect_value(t, string(buf[0:2]), "bc")

	_expect_no_error(t, os2.close(fd))
}

@test
path_test :: proc(t: ^testing.T) {
	err: os2.Error
	if os2.exists("a") {
		err = os2.remove_all("a")
		_expect_no_error(t, err)
	}
	
	err = os2.mkdir_all("a/b/c/d", 0)
	_expect_no_error(t, err)

	expect(t, os2.exists("a"), "directory does not exist")

	fd: os2.Handle
	fd, err = os2.create("a/b/c/file.txt", 0o644)
	_expect_no_error(t, err)

	err = os2.close(fd)
	_expect_no_error(t, err)

	expect(t, unix.sys_access("a/b/c/file.txt", X_OK) < 0, "unexpected exec permission")

	err = os2.rename("a/b/c/file.txt", "a/b/file.txt")
	_expect_no_error(t, err)

	expect(t, unix.sys_access("a/b/c/file.txt", F_OK) < 0, "unexpected exec permission")

	err = os2.symlink("b/c/d", "a/symlink_to_d")
	_expect_no_error(t, err)
	
	symlink: string
	symlink, err = os2.read_link("a/symlink_to_d")
	_expect_no_error(t, err)
	expect_value(t, symlink, "b/c/d")

	fd, err = os2.create("a/symlink_to_d/shnt.txt", 0o744)
	_expect_no_error(t, err)

	err = os2.close(fd)
	_expect_no_error(t, err)

	expect_value(t, unix.sys_access("a/b/c/d/shnt.txt", X_OK | R_OK | W_OK), 0)
	
	err = os2.remove_all("a")
	_expect_no_error(t, err)

	expect(t, !os2.exists("a"), "directory a exists")
}
