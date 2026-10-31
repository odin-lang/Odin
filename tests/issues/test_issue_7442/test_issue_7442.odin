// Regression for #7442: on Windows, `os.args` must hold the arguments in UTF-8.
// They are split from the wide command line with the rules of the CRT, with and without the CRT.
#+build windows
package test_issue_7442

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import win32 "core:sys/windows"

Case :: struct {
	command_line: string,
	args:         []string,
}

// Each command line goes to `CreateProcessW` as is, with this executable as the application name.
CASES := [?]Case{
	{`x ñandú 字 😀 "a b"`,                {"x", "ñandú", "字", "😀", "a b"}},
	{`x`,                                  {"x"}},
	{`x a   `,                             {"x", "a"}},
	{` x`,                                 {"", "x"}},
	{"x\t a\t\"b\tc\"  ",                 {"x", "a", "b\tc"}},
	{`"x y"z a`,                           {"x yz", "a"}},
	{`"C:\Program Files\x.exe" a`,         {`C:\Program Files\x.exe`, "a"}},
	{`C:\dir\x.exe a\\\\"b c"\\`,          {`C:\dir\x.exe`, `a\\b c\\`}},
	{`x a\b a\\b "a\\" "a\"b" a\\\"b`,     {"x", `a\b`, `a\\b`, `a\`, `a"b`, `a\"b`}},
	{`x "a""b" "" c""d """a"""`,           {"x", `a"b`, "", "cd", `"a"`}},
	{`x a"b"c d`,                          {"x", "abc", "d"}},
	{`x "unterminated a`,                  {"x", "unterminated a"}},
	{`x "`,                                {"x", ""}},
	{`x \`,                                {"x", `\`}},
}

Surrogate_Case :: struct {
	command_line: []u16,
	args:         []string,
}

// Lone surrogates have no UTF-8 form. Each one becomes U+FFFD.
SURROGATE_CASES := [?]Surrogate_Case{
	{{'x', ' ', 0xd800},                   {"x", "\ufffd"}},
	{{'x', ' ', 0xdc00, 'a'},              {"x", "\ufffda"}},
	{{'x', ' ', 0xdc00, 0xd800},           {"x", "\ufffd\ufffd"}},
	{{'x', ' ', 0xd83d, 0xde00, 0xd83d},   {"x", "😀\ufffd"}},
	{{'x', ' ', 0xd800, ' ', 0x5b57},      {"x", "\ufffd", "字"}},
}

CASE_ENV :: "TEST_ISSUE_7442_CASE"

main :: proc() {
	if value, found := os.lookup_env(CASE_ENV, context.allocator); found {
		index, _ := strconv.parse_int(value)
		os.exit(0 if check_args(index) else 1)
	}

	exe, exe_err := os.get_executable_path(context.allocator)
	assert(exe_err == nil)
	exe_w := win32.utf8_to_wstring(exe, context.allocator)

	failed := false
	for index in 0..<len(CASES)+len(SURROGATE_CASES) {
		env_err := os.set_env(CASE_ENV, fmt.tprint(index))
		assert(env_err == nil)

		command_line, _ := case_at(index)
		startup_info := win32.STARTUPINFOW{cb = size_of(win32.STARTUPINFOW)}
		process_info: win32.PROCESS_INFORMATION
		ok := win32.CreateProcessW(
			exe_w,
			cstring16(raw_data(command_line)),
			nil,
			nil,
			false,
			0,
			nil,
			nil,
			&startup_info,
			&process_info,
		)
		assert(bool(ok))

		win32.WaitForSingleObject(process_info.hProcess, win32.INFINITE)
		exit_code: win32.DWORD
		ok = win32.GetExitCodeProcess(process_info.hProcess, &exit_code)
		assert(bool(ok))
		win32.CloseHandle(process_info.hThread)
		win32.CloseHandle(process_info.hProcess)

		if exit_code != 0 {
			fmt.eprintfln("case %d failed", index)
			failed = true
		}
	}

	if failed {
		os.exit(1)
	}
}

// Returns a writable copy of the command line with a NUL after it. `CreateProcessW` may write to it.
case_at :: proc(index: int) -> (command_line: []u16, args: []string) {
	if index < len(CASES) {
		c := CASES[index]
		return win32.utf8_to_utf16(c.command_line, context.allocator), c.args
	}

	c := SURROGATE_CASES[index-len(CASES)]
	command_line = make([]u16, len(c.command_line)+1)
	copy(command_line, c.command_line)
	return command_line[:len(c.command_line)], c.args
}

check_args :: proc(index: int) -> (ok: bool) {
	_, args := case_at(index)
	ok = true

	if rt_args, is_wide := runtime.args__.([]cstring16); !is_wide || len(rt_args) != len(args) {
		fmt.eprintfln("case %d: runtime.args__ should hold %d UTF-16 arguments", index, len(args))
		ok = false
	}

	if !slice.equal(os.args, args) {
		fmt.eprintfln("case %d: os.args is %q, expected %q", index, os.args, args)
		ok = false
	}

	for arg in os.args {
		if ([^]byte)(raw_data(arg))[len(arg)] != 0 {
			fmt.eprintfln("case %d: %q is not followed by a NUL", index, arg)
			ok = false
		}
	}
	return
}
