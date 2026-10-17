// Tests that `os.args` holds the arguments of the Windows command line in UTF-8, split
// with the rules of the C runtime, with and without it.
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

// Each command line is passed as is, with the executable as the application name.
CASES := [?]Case{
	{`x ñandú 字 "a b"`,                {"x", "ñandú", "字", "a b"}},
	{`"x y"z a`,                         {"x yz", "a"}},
	{` x`,                               {"", "x"}},
	{"x\t a\t\"b\tc\"  ",               {"x", "a", "b\tc"}},
	{`C:\dir\x.exe a\\\\"b c"\\`,        {`C:\dir\x.exe`, `a\\b c\\`}},
	{`x a\b a\\b "a\\" "a\"b" a\\\"b`,   {"x", `a\b`, `a\\b`, `a\`, `a"b`, `a\"b`}},
	{`x "a""b" "" c""d """a"""`,         {"x", `a"b`, "", "cd", `"a"`}},
	{`x "unterminated a`,                {"x", "unterminated a"}},
}

CASE_ENV :: "TEST_ISSUE_7442_CASE"

main :: proc() {
	if index, found := os.lookup_env(CASE_ENV, context.allocator); found {
		i, _ := strconv.parse_int(index)
		os.exit(check_args(i))
	}

	exe, exe_err := os.get_executable_path(context.allocator)
	assert(exe_err == nil)
	exe_w := win32.utf8_to_wstring(exe, context.allocator)

	failed := false
	for c, i in CASES {
		assert(os.set_env(CASE_ENV, fmt.tprint(i)) == nil)
		command_line_w := win32.utf8_to_wstring(c.command_line, context.allocator)
		startup_info := win32.STARTUPINFOW{cb = size_of(win32.STARTUPINFOW)}
		process_info: win32.PROCESS_INFORMATION
		assert(bool(win32.CreateProcessW(exe_w, command_line_w, nil, nil, false, 0, nil, nil, &startup_info, &process_info)))
		win32.WaitForSingleObject(process_info.hProcess, win32.INFINITE)
		exit_code: win32.DWORD
		assert(bool(win32.GetExitCodeProcess(process_info.hProcess, &exit_code)))
		win32.CloseHandle(process_info.hThread)
		win32.CloseHandle(process_info.hProcess)
		failed ||= exit_code != 0
	}
	if failed {
		os.exit(1)
	}
}

check_args :: proc(index: int) -> int {
	c := CASES[index]
	if !slice.equal(os.args, c.args) {
		fmt.eprintfln("%q: os.args is %q, expected %q", c.command_line, os.args, c.args)
		return 1
	}

	info, info_err := os.current_process_info({.Command_Line, .Command_Args}, context.allocator)
	if info_err != nil || !slice.equal(info.command_args, c.args) {
		fmt.eprintfln("%q: command_args is %q (%v), expected %q", c.command_line, info.command_args, info_err, c.args)
		return 1
	}

	if !ODIN_NO_CRT {
		// The C runtime converts its `argv` to the ANSI code page, which keeps ASCII.
		ascii := true
		for b in transmute([]byte)c.command_line {
			ascii &&= b < 0x80
		}
		crt_args := make([]string, len(runtime.args__), context.allocator)
		for arg, i in runtime.args__ {
			crt_args[i] = string(arg)
		}
		if ascii && !slice.equal(crt_args, c.args) {
			fmt.eprintfln("%q: the C runtime splits it as %q, expected %q", c.command_line, crt_args, c.args)
			return 1
		}
	}
	return 0
}
