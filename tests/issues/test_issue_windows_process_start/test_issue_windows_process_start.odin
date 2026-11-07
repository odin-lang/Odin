// Regression test for `os.process_start` on Windows:
// - each argument must reach the child as given, including empty ones and ones holding a tab;
// - starting a process must not leak its thread handle.
#+build windows
package test_issue_windows_process_start

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import win32 "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="system")
foreign kernel32 {
	GetProcessHandleCount :: proc(hProcess: win32.HANDLE, pdwHandleCount: ^win32.DWORD) -> win32.BOOL ---
}

CHILD_ENV :: "TEST_ISSUE_WINDOWS_PROCESS_START_CHILD"

ARGS := [?]string{"", "a", "", "b c", "d\te", "f\ng", "h\vi", `j\`, `"`, `k\"l`, ""}

RUNS :: 50

main :: proc() {
	if _, found := os.lookup_env(CHILD_ENV, context.allocator); found {
		// Each argument, followed by a NUL.
		for arg in os.args[1:] {
			fmt.print(arg, "\x00", sep = "")
		}
		os.exit(0)
	}

	exe, exe_err := os.get_executable_path(context.allocator)
	assert(exe_err == nil)
	env, env_err := os.environ(context.allocator)
	assert(env_err == nil)

	command := make([dynamic]string)
	append(&command, exe)
	append(&command, ..ARGS[:])

	desc := os.Process_Desc{
		command = command[:],
		env     = slice.concatenate([][]string{env, {CHILD_ENV + "=1"}}),
	}

	failed := false

	got := run(desc)
	if !slice.equal(got, ARGS[:]) {
		fmt.eprintfln("the child got %d arguments %q, expected %d %q", len(got), got, len(ARGS), ARGS)
		failed = true
	}

	before, after: win32.DWORD
	assert(bool(GetProcessHandleCount(win32.GetCurrentProcess(), &before)))
	for _ in 0..<RUNS {
		run(desc)
	}
	assert(bool(GetProcessHandleCount(win32.GetCurrentProcess(), &after)))
	// One leaked handle per run would add RUNS.
	if after > before + RUNS/2 {
		fmt.eprintfln("%d handles before %d runs, %d after", before, RUNS, after)
		failed = true
	}

	if failed {
		os.exit(1)
	}
}

run :: proc(desc: os.Process_Desc) -> []string {
	state, stdout, stderr, err := os.process_exec(desc, context.allocator)
	if err != nil || !state.success || len(stderr) != 0 {
		fmt.eprintfln("the child failed: %v %v %q", err, state, stderr)
		os.exit(1)
	}
	args := strings.split(string(stdout), "\x00")
	return args[:len(args)-1]
}
