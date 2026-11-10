#+build windows
package tests_core_os

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import win32 "core:sys/windows"

// The test program is also the child of these tests: started with
// `CONSOLE_CHILD` as its first argument, it does what the second one says
// and exits before the tests run.
@(private="file")
CONSOLE_CHILD :: "tests-core-os-console-child"

@(init, private="file")
console_child :: proc "contextless" () {
	if len(os.args) < 3 || os.args[1] != CONSOLE_CHILD {
		return
	}
	context = runtime.default_context()
	switch os.args[2] {
	case "report":
		// Whether this process has a console, a window for it, and shares it
		// with its parent.
		pids: [64]win32.DWORD
		count := int(win32.GetConsoleProcessList(&pids[0], len(pids)))
		parent := os.get_ppid()
		shared := false
		for pid in pids[:min(count, len(pids))] {
			if int(pid) == parent {
				shared = true
			}
		}
		fmt.printf("console=%v window=%v shared=%v", count > 0, win32.GetConsoleWindow() != nil, shared)
	case "detached":
		// Leaves its console, then passes on what a child of its own reports.
		win32.FreeConsole()
		_, stdout, _, err := os.process_exec({command = console_child_command("report")}, context.allocator)
		fmt.print(string(stdout))
		if err != nil {
			fmt.printf(" error=%v", err)
		}
	}
	os.exit(0)
}

@(private="file")
console_child_command :: proc(action: string) -> []string {
	exe, _ := os.get_executable_path(context.temp_allocator)
	command := make([]string, 3, context.temp_allocator)
	command[0], command[1], command[2] = exe, CONSOLE_CHILD, action
	return command
}

@(test)
test_process_start_without_console_opens_no_window :: proc(t: ^testing.T) {
	_, stdout, _, err := os.process_exec({command = console_child_command("detached")}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expectf(t, strings.has_prefix(string(stdout), "console=true window=false "), "the child reported %q", stdout)
}

@(test)
test_process_start_shares_the_console :: proc(t: ^testing.T) {
	if pid: win32.DWORD; win32.GetConsoleProcessList(&pid, 1) == 0 {
		// The test runner has no console to share.
		return
	}
	_, stdout, _, err := os.process_exec({command = console_child_command("report")}, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expectf(t, strings.has_suffix(string(stdout), " shared=true"), "the child reported %q", stdout)
}
