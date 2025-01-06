#+build linux, darwin, freebsd, openbsd, netbsd
package tests_core_posix

import "core:log"
import "core:path/filepath"
import "core:strings"
import "core:sync"
import "core:sys/posix"
import "core:testing"
import "core:time"

@(test)
test_arpa_inet :: proc(t: ^testing.T) {

	check :: proc(t: ^testing.T, $af: posix.AF, src: cstring, expect: posix.pton_result, loc := #caller_location) {
		when af == .INET {
			addr: posix.in_addr
			dst: [posix.INET_ADDRSTRLEN]byte
		} else {
			addr: posix.in6_addr
			dst: [posix.INET6_ADDRSTRLEN]byte
		}

		res := posix.inet_pton(af, src, &addr, size_of(addr))
		testing.expect_value(t, res, expect, loc)

		if expect == .SUCCESS {
			back := posix.inet_ntop(af, &addr, raw_data(dst[:]), len(dst))
			testing.expect_value(t, back, src, loc)

			when af == .INET {
				back = posix.inet_ntoa(addr)
				testing.expect_value(t, back, src, loc)
			}
		}
	}

	check(t, .INET,  "127.0.0.1", .SUCCESS)
	check(t, .INET,  "blah",      .INVALID)
	check(t, .INET6, "::1",       .SUCCESS)
	check(t, .INET6, "L",         .INVALID)
	check(t, .UNIX,  "127.0.0.1", .AFNOSUPPORT)
}

@(test)
test_dirent :: proc(t: ^testing.T) {
	test := #load_directory(#directory)
	test_map: map[string]struct{}
	defer delete(test_map)

	test_map[".."] = {}
	test_map["."]  = {}

	for file in test {
		test_map[filepath.base(file.name)] = {}
	}

	{
		list: [^]^posix.dirent
		ret := posix.scandir(#directory, &list)
		testing.expectf(t, ret >= 0, "%v >= 0: %v", ret, posix.strerror(posix.errno()))
		defer posix.free(list)

		entries := list[:ret]
		for entry in entries {
			defer posix.free(entry)

			if entry.d_type != .REG {
				continue
			}

			name := string(cstring(raw_data(entry.d_name[:])))
			testing.expectf(t, name in test_map, "%v in %v", name, test_map)
		}
	}

	{
		dir := posix.opendir(#directory)
		defer posix.closedir(dir)

		for {
			posix.set_errno(.NONE)
			entry := posix.readdir(dir)
			if entry == nil {
				testing.expect_value(t, posix.errno(), posix.Errno.NONE)
				break
			}

			if entry.d_type != .REG {
				continue
			}

			name := string(cstring(raw_data(entry.d_name[:])))
			testing.expectf(t, name in test_map, "%v in %v", name, test_map)
		}
	}
}

@(test)
test_errno :: proc(t: ^testing.T) {
	posix.errno(posix.Errno.ENOMEM)
	testing.expect_value(t, posix.errno(), posix.Errno.ENOMEM)

	res := posix.open("", {})
	testing.expect_value(t, res, -1)
	testing.expect_value(t, posix.errno(), posix.Errno.ENOENT)
}

@(test)
test_fcntl :: proc(t: ^testing.T) {
	res := posix.open(#file, { .WRONLY, .CREAT, .EXCL })
	testing.expect_value(t, res, -1)
	testing.expect_value(t, posix.errno(), posix.Errno.EEXIST)
}

@(test)
test_fnmatch :: proc(t: ^testing.T) {
	testing.expect_value(t, posix.fnmatch("*.odin", #file, {}), 0)
	testing.expect_value(t, posix.fnmatch("*.txt", #file, {}), posix.FNM_NOMATCH)
	testing.expect_value(t, posix.fnmatch("**/*.odin", #file, {}), 0)
}

@(test)
test_glob :: proc(t: ^testing.T) {
	glob: posix.glob_t
	res := posix.glob(#directory + ":)))))))", {}, nil, &glob)
	testing.expect_value(t, res, posix.Glob_Result.NOMATCH)
	posix.globfree(&glob)
}

@(test)
test_langinfo :: proc(t: ^testing.T) {
	locale := posix.setlocale(.TIME, nil)
	testing.expectf(t, locale == "POSIX" || locale == "C", "invalid locale for test: %v", locale)

	day1 := posix.nl_langinfo(.DAY_1)
	testing.expect_value(t, day1, "Sunday")
}

@(test)
test_libgen :: proc(t: ^testing.T) {
	tests := [][3]cstring{
		{ "usr",              ".",          "usr" },
		{ "usr/",             ".",          "usr" },
		{ "",                 ".",          "." },
		{ "/",                "/",          "/" },
		{ "///",              "/",          "/" },
		{ "/usr/",            "/",          "usr" },
		{ "/usr/lib",         "/usr",       "lib" },
		{ "//usr//lib//",     "//usr",      "lib" },
		{ "/home//dwc//test", "/home//dwc", "test" },
	}

	for test in tests {
		// NOTE: dir/basename can change their input so they can't be literals.

		dinput := strings.clone_to_cstring(string(test[0]))
		defer delete(dinput)

		dir := posix.dirname(dinput)
		testing.expectf(t, dir == test[1], "dirname(%q) == %q, expected %q", test[0], dir, test[1])

		binput := strings.clone_to_cstring(string(test[0]))
		defer delete(binput)

		base := posix.basename(binput)
		testing.expectf(t, base == test[2], "basename(%q) == %q, expected %q", test[0], base, test[2])
	}
}

@(test)
test_locale :: proc(t: ^testing.T) {
	lconv := posix.localeconv()
	testing.expect(t, lconv != nil)

	locale := posix.setlocale(.ALL, nil)
	testing.expectf(t, locale == "POSIX" || locale == "C", "%q is not POSIX or C", locale)
}

@(test)
test_monetary :: proc(t: ^testing.T) {
	when ODIN_OS == .Darwin && .Address in ODIN_SANITIZER_FLAGS {
		log.warn("skipping on darwin with -sanitize:address, this fails inside macOS (also from C/clang)")
		return
	}

	value := 123456.789
	buf: [128]byte
	size := posix.strfmon(raw_data(buf[:]), len(buf), "%n", value)
	testing.expectf(t, int(size) != -1, "strfmon failure: %v", posix.strerror(posix.errno()))
	log.debug(string(buf[:size]))
}

@(test)
test_stat :: proc(t: ^testing.T) {
	stat: posix.stat_t
	testing.expect_value(t, posix.stat(#file, &stat), posix.result.OK)
	testing.expect(t, posix.S_ISREG(stat.st_mode))
	testing.expect_value(t, stat.st_mode, posix.mode_t{.IROTH, .IRGRP, .IRUSR, .IWUSR, .IFREG})

	CONTENT := #load(#file)
	testing.expect_value(t, stat.st_size, posix.off_t(len(CONTENT)))
}

@(test)
test_pthreads :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, time.Second)

	NTHREADS :: 3
	thread_ids: [NTHREADS]posix.pthread_t

	@static counter: int

	for &tid in thread_ids {
		posix.pthread_create(&tid, nil, thread_function, nil)
	}

	for tid in thread_ids {
		posix.pthread_join(tid, nil)
	}

	testing.expect_value(t, counter, NTHREADS)

	thread_function :: proc "c" (_: rawptr) -> rawptr {
		sync.atomic_add(&counter, 1)		
		return nil
	}
}

@(test)
open_permissions :: proc(t: ^testing.T) {
	in_mode := posix.mode_t{.IRUSR, .IWUSR, .IROTH, .IRGRP}
	fd := posix.open("test_posix_permissions.txt", {.CREAT, .RDWR}, in_mode)
	testing.expectf(t, fd != -1, "failed to open: %v", posix.strerror())

	defer {
		ret := posix.close(fd)
		testing.expectf(t, ret == .OK, "failed to close: %v", posix.strerror())
		ret2 := posix.remove("test_posix_permissions.txt")
		testing.expectf(t, ret2 == 0, "failed to remove: %v", posix.strerror())
	}

	stat: posix.stat_t
	res := posix.fstat(fd, &stat)
	testing.expectf(t, res == .OK, "failed to stat: %v", posix.strerror())

	stat.st_mode -= posix.S_IFMT
	testing.expect_value(t, stat.st_mode, in_mode)
}
