package tests_core_os

import "core:fmt"
import "core:os"
import "core:log"
import "core:testing"
import "core:slice"
import "core:strings"

@(test)
test_executable :: proc(t: ^testing.T) {
	path, err := os.get_executable_path(context.allocator)
	defer delete(path)

	log.infof("executable path: %q", path)

	// NOTE: some sanity checks that should always be the case, at least in the CI.

	testing.expect_value(t, err, nil)
	testing.expect(t, len(path) > 0)
	testing.expect(t, os.is_absolute_path(path))
	_, filename := os.split_path(os.args[0])
	testing.expectf(t, strings.contains(path, filename), "expected the executable path to contain the base of os.args[0] which is %q", filename)
}

posix_to_dos_path :: proc(path: string) -> string {
	if len(path) == 0 {
		return path
	}
	path := path
	path, _ = strings.replace_all(path, `/`, `\`, context.temp_allocator)
	if path[0] == '\\' {
		path = strings.concatenate({"C:", path}, context.temp_allocator)
	}
	return path
}

@(test)
test_clean_path :: proc(t: ^testing.T) {
	Test_Case :: struct{
		path:     string,
		expected: string,
	}

	when ODIN_OS == .Windows {
		test_cases := [?]Test_Case {
			{`W:/odin\examples\demo/demo.odin`,    `W:\odin\examples\demo\demo.odin`},
			{`\\server\share\path\file.ext`,       `\\server\share\path\file.ext`},
			{`//server\share/path\file.ext`,       `\\server\share\path\file.ext`},
			{`/\192.168.0.10\share/path\file.ext`, `\\192.168.0.10\share\path\file.ext`},
			{`\\?\C:/Users/Foo/path\file.ext`,     `\\?\C:\Users\Foo\path\file.ext`},
			{`\\?\\localhost\share\file.ext`,      `\\?\\localhost\share\file.ext`},
			{`//?\/192.168.0.10\share\file.ext`,   `\\?\\192.168.0.10\share\file.ext`},
			{`\\.\PhysicalDrive3`,                 `\\.\PhysicalDrive3`},
			{`/\./PhysicalDrive3`,                 `\\.\PhysicalDrive3`},
			{`C:\a\..\..`,                         `C:\`},
			{`C:\a\..`,                            `C:\`},
			{`C:\あ/a/..`,                          `C:\あ`},
			{`C:\あ/a/../あ`,                       `C:\あ\あ`},
		}
	} else {
		test_cases := [?]Test_Case {
			{`../../foo/../../`,      `../../..`},
			{`../../foo/..`,          `../..`},
			{`../../foo`,             `../../foo`},
			{`../..`,                 `../..`},
			{`.././foo`,              `../foo`},
			{`..`,                    `..`},
			{`.`,                     `.`},
			{`.foo`,                  `.foo`},
			{`/../../foo/../../`,     `/`},
			{`/../`,                  `/`},
			{`/..`,                   `/`},
			{`/`,                     `/`},
			{`//home/foo/bar/../../`, `/home`},
			{`/a/../..`,              `/`},
			{`/a/../`,                `/`},
			{`/a/あ`,                 `/a/あ`},
			{`/a/あ/..`,              `/a`},
			{`/あ/a/..`,              `/あ`},
			{`/あ/a/../あ`,           `/あ/あ`},
			{`/home/../`,             `/`},
			{`/home/..`,              `/`},
			{`/home/foo/../../usr`,   `/usr`},
			{`/home/foo/../..`,       `/`},
			{`/home/foo/../`,         `/home`},
			{``,                      `.`},
			{`a/..`,                  `.`},
			{`a`,                     `a`},
			{`abc//.//../foo`,        `foo`},
			{`foo`,                   `foo`},
			{`home/foo/bar/../../`,   `home`},
		}
	}

	for tc in test_cases {
		joined, err := os.clean_path(tc.path, context.temp_allocator)
		testing.expectf(t, joined == tc.expected && err == nil, "expected clean_path(%q) -> %q; got: %q, %v", tc.path, tc.expected, joined, err)
	}
}

@(test)
test_is_absolute_path :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		testing.expect(t, os.is_absolute_path(`C:\Windows`))
	} else {
		testing.expect(t, os.is_absolute_path("/home"))
	}
	testing.expect(t, !os.is_absolute_path("home"))
}

@(test)
test_get_relative_path :: proc(t: ^testing.T) {
	Test_Case :: struct {
		base, target: string,
		expected: string,
	}

	Fail_Case :: struct {
		base, target: string,
	}

	test_cases := [?]Test_Case {
		{"",                   "foo",              "foo"},
		{".",                  "foo",              "foo"},
		{"/",                  "/",                "."},
		{"/",                  "/home/alice/bert", "home/alice/bert"},
		{"/a",                 "/b",               "../b"},
		{"/あ",                "/あ/a",            "a"},
		{"/a",                 "/a/あ",            "あ"},
		{"/あ",                "/い",              "../い"},
		{"/a",                 "/usr",             "../usr"},
		{"/home",              "/",                ".."},
		{"/home",              "/home/alice/bert", "alice/bert"},
		{"/home/foo",          "/",                "../.."},
		{"/home/foo",          "/home",            ".."},
		{"/home/foo",          "/home/alice/bert", "../alice/bert"},
		{"/home/foo",          "/home/foo",        "."},
		{"/home/foo",          "/home/foo/bar",    "bar"},
		{"/home/foo/bar",      "/home",            "../.."},
		{"/home/foo/bar",      "/home/alice/bert", "../../alice/bert"},
		{"/home/foo/bar/bert", "/home/alice/bert", "../../../alice/bert"},
		{"/www",               "/mount",           "../mount"},
		{"foo",                ".",                ".."},
		{"foo",                "bar",              "../bar"},
		{"foo",                "bar",              "../bar"},
		{"foo",                "../bar",           "../../bar"},
		{"foo",                "foo",              "."},
		{"foo",                "foo/bar",          "bar"},
		{"home/foo/bar",       "home/alice/bert",  "../../alice/bert"},
	}

	fail_cases := [?]Fail_Case {
		{"", "/home"},
		{"/home", ""},
		{"..", ""},
	}

	when ODIN_OS == .Windows {
		for &tc in test_cases {
			tc.base = posix_to_dos_path(tc.base)
			tc.target = posix_to_dos_path(tc.target)
			// Make one part all capitals to test case-insensitivity.
			tc.target = strings.to_upper(tc.target, context.temp_allocator)
			tc.expected = posix_to_dos_path(tc.expected)
		}
		for &tc in fail_cases {
			tc.base = posix_to_dos_path(tc.base)
			tc.target = posix_to_dos_path(tc.target)
		}
	}

	for tc in test_cases {
		result, err := os.get_relative_path(tc.base, tc.target, context.temp_allocator)
		joined, err2 := os.join_path({tc.base, result}, context.temp_allocator)

		when ODIN_OS == .Windows {
			passed          := strings.equal_fold(result, tc.expected) && err == nil
			join_guaranteed := strings.equal_fold(joined, tc.target) && err2 == nil
		} else {
			passed          := result == tc.expected && err == nil
			join_guaranteed := joined == tc.target && err2 == nil
		}
		testing.expectf(t, passed, "expected get_relative_path(%q, %q) -> %q; got %q, %v", tc.base, tc.target, tc.expected, result, err)
		testing.expectf(t, join_guaranteed, "join_path({{%q, %q}}) guarantee of get_relative_path(%q, %q) failed; got %q, %v instead", tc.base, result, tc.base, tc.target, joined, err2)
	}

	for tc in fail_cases {
		result, err := os.get_relative_path(tc.base, tc.target, context.temp_allocator)
		testing.expectf(t, result == "" && err != nil, "expected get_relative_path(%q, %q) to fail, got %q, %v", tc.base, tc.target, result, err)
	}
}

@(test)
test_split_path :: proc(t: ^testing.T) {
	Test_Case :: struct {
		path: string,
		dir, filename: string,
	}

	test_cases := [?]Test_Case {
		{ "",                     "",          "" },
		{ "/",                    "/",         "" },
		{ "/a",                   "/",         "a" },
		{ "readme.txt",           "",          "readme.txt" },
		{ "/readme.txt",          "/",         "readme.txt" },
		{ "/var/readme.txt",      "/var",      "readme.txt" },
		{ "/home/foo/bar.tar.gz", "/home/foo", "bar.tar.gz" },
	}

	when ODIN_OS == .Windows {
		for &tc in test_cases {
			tc.path = posix_to_dos_path(tc.path)
			tc.dir = posix_to_dos_path(tc.dir)
			tc.filename = posix_to_dos_path(tc.filename)
		}
	}

	for tc in test_cases {
		dir, filename := os.split_path(tc.path)
		testing.expectf(t, dir == tc.dir && filename == tc.filename, "expected split_path(%q) -> %q, %q; got: %q, %q", tc.path, tc.dir, tc.filename, dir, filename)
	}
}

@(test)
test_join_path :: proc(t: ^testing.T) {
	Test_Case :: struct {
		elems: []string,
		expected: string,
	}

	test_cases := [?]Test_Case {
		{ {""                            }, ""          },
		{ {"/"                           }, "/"         },
		{ {"home"                        }, "home"      },
		{ {"home", ""                    }, "home"      },
		{ {"/home", ""                   }, "/home"     },
		{ {"", "home"                    }, "home"      },
		{ {"", "/home"                   }, "/home"     },
		{ {"", "/home", "", "foo"        }, "/home/foo" },
		{ {"", "home", "", "", "foo", "" }, "home/foo"  },
	}

	when ODIN_OS == .Windows {
		for &tc in test_cases {
			for &elem in tc.elems {
				elem = posix_to_dos_path(elem)
			}
			tc.expected = posix_to_dos_path(tc.expected)
		}
	}

	for tc in test_cases {
		result, err := os.join_path(tc.elems, context.temp_allocator)
		testing.expectf(t, result == tc.expected && err == nil, "expected join_path(%v) -> %q; got: %q, %v", tc.elems, tc.expected, result, err)
	}
}

@(test)
test_split_filename :: proc(t: ^testing.T) {
	Test_Case :: struct {
		filename: string,
		base, ext: string,
	}

	test_cases := [?]Test_Case {
		{"",             "",         ""},
		{"a",            "a",        ""},
		{".",            ".",        ""},
		{".a",           ".a",       ""},
		{".foo",         ".foo",     ""},
		{".foo.txt",     ".foo",     "txt"},
		{"a.b",          "a",        "b"},
		{"foo",          "foo",      ""},
		{"readme.txt",   "readme",   "txt"},
		{"pkg.tar.gz",   "pkg.tar",  "gz"},
		// Assert API ignores directory hierarchies:
		{"dir/FILE.TXT", "dir/FILE", "TXT"},
	}

	for tc in test_cases {
		base, ext := os.split_filename(tc.filename)
		testing.expectf(t, base == tc.base && ext == tc.ext, "expected split_filename(%q) -> %q, %q; got: %q, %q", tc.filename, tc.base, tc.ext, base, ext)
	}
}

@(test)
test_split_filename_all :: proc(t: ^testing.T) {
	Test_Case :: struct {
		filename: string,
		base, ext: string,
	}

	test_cases := [?]Test_Case {
		{"",             "",         ""},
		{"a",            "a",        ""},
		{".",            ".",        ""},
		{".a",           ".a",       ""},
		{".foo",         ".foo",     ""},
		{".foo.txt",     ".foo",     "txt"},
		{"a.b",          "a",        "b"},
		{"foo",          "foo",      ""},
		{"readme.txt",   "readme",   "txt"},
		{"pkg.tar.gz",   "pkg",      "tar.gz"},
		// Assert API ignores directory hierarchies:
		{"dir/FILE.TXT", "dir/FILE", "TXT"},
	}

	for tc in test_cases {
		base, ext := os.split_filename_all(tc.filename)
		testing.expectf(t, base == tc.base && ext == tc.ext, "expected split_filename_all(%q) -> %q, %q; got: %q, %q", tc.filename, tc.base, tc.ext, base, ext)
	}
}

@(test)
test_join_filename :: proc(t: ^testing.T) {
	Test_Case :: struct {
		base, ext: string,
		expected: string,
	}

	test_cases := [?]Test_Case {
		{"",        "",       ""},
		{"",        "foo",    "foo"},
		{"foo",     "",       "foo"},
		{"readme",  "txt",    "readme.txt"},
		{"pkg.tar", "gz",     "pkg.tar.gz"},
		{"pkg",     "tar.gz", "pkg.tar.gz"},
		// Assert API ignores directory hierarchies:
		{"dir/FILE", "TXT", "dir/FILE.TXT"},
	}

	for tc in test_cases {
		result, err := os.join_filename(tc.base, tc.ext, context.temp_allocator)
		testing.expectf(t, result == tc.expected && err == nil, "expected join_filename(%q, %q) -> %q; got: %q, %v", tc.base, tc.ext, tc.expected, result, err)
	}
}

Glob_Test :: struct {
	pattern: string,
	matches: []string,
	err:     os.Error,
}

glob_tests := []Glob_Test{
	{
		pattern = ODIN_ROOT + "tests/core/os/*/*.txt",
		matches = {
			ODIN_ROOT + "tests/core/os/dir/b.txt",
		},
		err     = {},
	},
	{
		pattern = ODIN_ROOT + "tests/core/os/*.odin",
		matches = {
			ODIN_ROOT + "tests/core/os/dir.odin",
			ODIN_ROOT + "tests/core/os/file.odin",
			ODIN_ROOT + "tests/core/os/path.odin",
			ODIN_ROOT + "tests/core/os/process.odin",
		},
		err     = {},
	},
}

@(test)
test_glob :: proc(t: ^testing.T) {
	compare_matches :: proc(t: ^testing.T, pattern: string, globbed, expected: []string) {
		glob_fold   := make([]string, len(globbed), context.temp_allocator)
		expect_fold := make([]string, len(globbed), context.temp_allocator)

		for glob, i in globbed {
			// If `glob` returned a path in response to a pattern,
			// then `match` should consider that path a match, too,
			// irrespective of `/` versus `\` presence.
			no_match_msg := fmt.tprintf("Expected os.match(%q, %q) to be `true`, got `false`", pattern, glob)
			match, _ := os.match(pattern, glob)

			f, _ := strings.replace_all(glob, `\`, `/`, context.temp_allocator)
			glob_fold[i] = f
			testing.expect(t, match, no_match_msg)
		}

		for exp, i in expected {
			f, _ := strings.replace_all(exp, `\`, `/`, context.temp_allocator)
			expect_fold[i] = f
		}

		slice.sort(glob_fold)
		slice.sort(expect_fold)

		not_equal_msg := fmt.tprintf("Expected os.glob(%q) to return %v, got %v", pattern, glob_fold, expect_fold)
		testing.expect(t, slice.equal(glob_fold, expect_fold), not_equal_msg)
	}

	for glob in glob_tests {
		globbed, err := os.glob(glob.pattern, context.allocator)
		defer {
			for file in globbed {
				delete(file)
			}
			delete(globbed)
		}
		testing.expect_value(t, err, glob.err)
		compare_matches(t, glob.pattern, globbed, glob.matches)
	}
}


// TODO: merge this and `test_split_list`
@(test)
test_split_path_list :: proc(t: ^testing.T) {
	Test_Case :: struct {
		path_list: string,
		expected: []string,
	}

	when ODIN_OS != .Windows {
		test_cases := [?]Test_Case {
			{``, {}},
			{`/bin:`, {`/bin`, ``}},
			{`/usr/local/bin`, {`/usr/local/bin`}},
			{`/usr/local/bin:/usr/bin`, {`/usr/local/bin`, `/usr/bin`}},
			{`"/extra bin":/bin`, {`/extra bin`, `/bin`}},
			{`"/extra:bin":/bin`, {`/extra:bin`, `/bin`}},
		}
	} else {
		test_cases := [?]Test_Case {
			{``, {}},
			{`C:\bin;`, {`C:\bin`, ``}},
			{`C:\usr\local\bin`, {`C:\usr\local\bin`}},
			{`C:\usr\local\bin;C:\usr\bin`, {`C:\usr\local\bin`, `C:\usr\bin`}},
			{`"C:\extra bin";C:\bin`, {`C:\extra bin`, `C:\bin`}},
			{`"C:\extra;bin";C:\bin`, {`C:\extra;bin`, `C:\bin`}},
		}
	}

	for tc in test_cases {
		result, err := os.split_path_list(tc.path_list, context.temp_allocator)
		if testing.expectf(t, len(result) == len(tc.expected), "expected split_path_list(%q) -> %v; got %v, %v", tc.path_list, tc.expected, result, err) {
			ok := true
			for entry, i in result {
				if entry != tc.expected[i] {
					ok = false
					break
				}
			}
			testing.expectf(t, ok, "expected split_path_list(%q) -> %v; got %v, %v", tc.path_list, tc.expected, result, err)
		}
	}
}

@(test)
test_split_list :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		test_split_list_windows(t)
	} else {
		test_split_list_unix(t)
	}
}

test_split_list_windows :: proc(t: ^testing.T) {
	Datum :: struct {
		i: int,
		v: string,
		e: [3]string,
	}
	@static data := []Datum{
		{ 0, "C:\\Odin;C:\\Visual Studio;\"C:\\Some Other\"",
			[3]string{"C:\\Odin", "C:\\Visual Studio", "C:\\Some Other"} }, // Issue #1537
		{ 1, "a;;b", [3]string{"a", "", "b"} },
		{ 2, "a;b;", [3]string{"a", "b", ""} },
		{ 3, ";a;b", [3]string{"", "a", "b"} },
		{ 4, ";;", [3]string{"", "", ""} },
		{ 5, "\"a;b\"c;d;\"f\"", [3]string{"a;bc", "d", "f"} },
		{ 6, "\"a;b;c\";d\";e\";f", [3]string{"a;b;c", "d;e", "f"} },
	}

	for d, i in data {
		assert(i == d.i, fmt.tprintf("wrong data index: i %d != d.i %d\n", i, d.i))
		r, err := os.split_path_list(d.v, context.allocator)
		testing.expectf(t, err == nil, "Expected err to be nil, got %v", err)
		defer delete_split(r)
		testing.expect(t, len(r) == len(d.e), fmt.tprintf("i:%d %s(%s) len(r) %d != len(d.e) %d", i, #procedure, d.v, len(r), len(d.e)))
		if len(r) == len(d.e) {
			for _, j in r {
				testing.expect(t, r[j] == d.e[j], fmt.tprintf("i:%d %s(%v) -> %v[%d] != %v", i, #procedure, d.v, r[j], j, d.e[j]))
			}
		}
	}

	{
		v := ""
		r, err := os.split_path_list(v, context.allocator)
		testing.expectf(t, err == nil, "Expected err to be nil, got %v", err)
		defer delete_split(r)
		testing.expect(t, r == nil, fmt.tprintf("%s(%s) -> %v != nil", #procedure, v, r))
	}
	{
		v := "a"
		r, err := os.split_path_list(v, context.allocator)
		testing.expectf(t, err == nil, "Expected err to be nil, got %v", err)
		defer delete_split(r)
		testing.expect(t, len(r) == 1, fmt.tprintf("%s(%s) len(r) %d != 1", #procedure, v, len(r)))
		if len(r) == 1 {
			testing.expect(t, r[0] == "a", fmt.tprintf("%s(%v) -> %v[0] != a", #procedure, v, r[0]))
		}
	}
}

test_split_list_unix :: proc(t: ^testing.T) {
	Datum :: struct {
		v: string,
		e: [3]string,
	}
	@static data := []Datum{
		{ "/opt/butler:/home/fancykillerpanda/Projects/Odin/Odin:/usr/local/sbin",
			[3]string{"/opt/butler", "/home/fancykillerpanda/Projects/Odin/Odin", "/usr/local/sbin"} }, // Issue #1537
		{ "a::b", [3]string{"a", "", "b"} },
		{ "a:b:", [3]string{"a", "b", ""} },
		{ ":a:b", [3]string{"", "a", "b"} },
		{ "::", [3]string{"", "", ""} },
		{ "\"a:b\"c:d:\"f\"", [3]string{"a:bc", "d", "f"} },
		{ "\"a:b:c\":d\":e\":f", [3]string{"a:b:c", "d:e", "f"} },
	}

	for d in data {
		r, err := os.split_path_list(d.v, context.allocator)
		testing.expectf(t, err == nil, "Expected err to be nil, got %v", err)
		defer delete_split(r)
		testing.expectf(t, len(r) == len(d.e), "%s len(r) %d != len(d.e) %d", d.v, len(r), len(d.e))
		if len(r) == len(d.e) {
			for _, j in r {
				testing.expectf(t, r[j] == d.e[j], "%v -> %v[%d] != %v", d.v, r[j], j, d.e[j])
			}
		}
	}

	{
		v := ""
		r, err := os.split_path_list(v, context.allocator)
		testing.expectf(t, err == nil, "Expected err to be nil, got %v", err)
		testing.expectf(t, r == nil, "'%s' -> '%v' != nil", v, r)
	}
	{
		v := "a"
		r, err := os.split_path_list(v, context.allocator)
		testing.expectf(t, err == nil, "Expected err to be nil, got %v", err)
		defer delete_split(r)
		testing.expectf(t, len(r) == 1, "'%s' len(r) %d != 1", v, len(r))
		if len(r) == 1 {
			testing.expectf(t, r[0] == "a", "'%v' -> %v[0] != a", v, r[0])
		}
	}
}

@(private)
delete_split :: proc(s: []string) {
	for part in s {
		delete(part)
	}
	delete(s)
}