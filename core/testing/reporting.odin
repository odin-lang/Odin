//+private
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund:   Total rewrite.
*/

import "base:runtime"
import "core:encoding/ansi"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:path/filepath"
import "core:strings"

// Definitions of colors for use in the test runner.
SGR_RESET   :: ansi.CSI + ansi.RESET           + ansi.SGR
SGR_READY   :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR
SGR_RUNNING :: ansi.CSI + ansi.FG_YELLOW       + ansi.SGR
SGR_SUCCESS :: ansi.CSI + ansi.FG_GREEN        + ansi.SGR
SGR_FAILED  :: ansi.CSI + ansi.FG_RED          + ansi.SGR

MAX_PROGRESS_WIDTH :: 100

// More than enough bytes to cover long package names, long test names, dozens
// of ANSI codes, et cetera.
LINE_BUFFER_SIZE :: (MAX_PROGRESS_WIDTH * 8 + 224) * runtime.Byte

PROGRESS_COLUMN_SPACING :: 2

Package_Run :: struct {
	name: string,
	header: string,

	frame_ready: bool,

	redraw_buffer: [LINE_BUFFER_SIZE]byte,
	redraw_string: string,

	last_change_state: Test_State,
	last_change_name: string,

	tests: []Internal_Test,
	test_states: []Test_State,
}

Report :: struct {
	packages: []Package_Run,
	packages_by_name: map[string]^Package_Run,

	pkg_column_len: int,
	test_column_len: int,
	progress_width: int,

	all_tests: []Internal_Test,
	all_test_states: []Test_State,
}

// Organize all tests by package and sort out test state data.
make_report :: proc(internal_tests: []Internal_Test) -> (report: Report, error: runtime.Allocator_Error) {
	assert(len(internal_tests) > 0, "make_report called with no tests")

	packages: [dynamic]Package_Run

	report.all_tests = internal_tests
	report.all_test_states = make([]Test_State, len(internal_tests)) or_return

	// First, figure out what belongs where.
	#no_bounds_check cur_pkg := internal_tests[0].pkg
	pkg_start: int

	// This loop assumes the tests are sorted by package already.
	for it, index in internal_tests {
		if cur_pkg != it.pkg {
			#no_bounds_check { 
				append(&packages, Package_Run {
					name = cur_pkg,
					tests = report.all_tests[pkg_start:index],
					test_states = report.all_test_states[pkg_start:index],
				}) or_return
			}

			when PROGRESS_WIDTH == 0 {
				report.progress_width = max(report.progress_width, index - pkg_start)
			}

			pkg_start = index
			report.pkg_column_len = max(report.pkg_column_len, len(cur_pkg))
			cur_pkg = it.pkg
		}
		report.test_column_len = max(report.test_column_len, len(it.name))
	}

	// Handle the last (or only) package.
	#no_bounds_check {
		append(&packages, Package_Run {
			name = cur_pkg,
			header = cur_pkg,
			tests = report.all_tests[pkg_start:],
			test_states = report.all_test_states[pkg_start:],
		}) or_return
	}
	when PROGRESS_WIDTH == 0 {
		report.progress_width = max(report.progress_width, len(internal_tests) - pkg_start)
	} else {
		report.progress_width = PROGRESS_WIDTH
	}
	report.progress_width = min(report.progress_width, MAX_PROGRESS_WIDTH)

	report.pkg_column_len = PROGRESS_COLUMN_SPACING + max(report.pkg_column_len, len(cur_pkg))

	shrink(&packages) or_return

	for &pkg in packages {
		pkg.header = fmt.aprintf("%- *[1]s[", pkg.name, report.pkg_column_len)
		assert(len(pkg.header) > 0, "Error allocating package header string.")

		// This is safe because the array is done resizing, and it has the same
		// lifetime as the map.
		report.packages_by_name[pkg.name] = &pkg
	}

	// It's okay to discard the dynamic array's allocator information here,
	// because its capacity has been shrunk to its length, it was allocated by
	// the caller's context allocator, and it will be deallocated by the same.
	//
	// `delete_slice` is equivalent to `delete_dynamic_array` in this case.
	report.packages = packages[:]

	return
}

destroy_report :: proc(report: ^Report) {
	for pkg in report.packages {
		delete(pkg.header)
	}

	delete(report.packages)
	delete(report.packages_by_name)
	delete(report.all_test_states)
}

redraw_package :: proc(w: io.Writer, report: Report, pkg: ^Package_Run) {
	if pkg.frame_ready {
		io.write_string(w, pkg.redraw_string)
		return
	}

	// Write the output line here so we can cache it.
	line_builder := strings.builder_from_bytes(pkg.redraw_buffer[:])
	line_writer  := strings.to_writer(&line_builder)

	highest_run_index: int
	failed_count: int
	done_count: int
	#no_bounds_check for i := 0; i < len(pkg.test_states); i += 1 {
		switch pkg.test_states[i] {
		case .Ready:
			continue
		case .Running:
			highest_run_index = max(highest_run_index, i)
		case .Successful:
			done_count += 1
		case .Failed:
			failed_count += 1
			done_count += 1
		}
	}

	start := max(0, highest_run_index - (report.progress_width - 1))
	end   := min(start + report.progress_width, len(pkg.test_states))

	// This variable is to keep track of the last ANSI code emitted, in
	// order to avoid repeating the same code over in a sequence.
	//
	// This should help reduce screen flicker.
	last_state := Test_State(-1)

	io.write_string(line_writer, pkg.header)

	#no_bounds_check for state in pkg.test_states[start:end] {
		switch state {
		case .Ready:
			if last_state != state {
				io.write_string(line_writer, SGR_READY)
				last_state = state
			}
		case .Running:
			if last_state != state {
				io.write_string(line_writer, SGR_RUNNING)
				last_state = state
			}
		case .Successful:
			if last_state != state {
				io.write_string(line_writer, SGR_SUCCESS)
				last_state = state
			}
		case .Failed:
			if last_state != state {
				io.write_string(line_writer, SGR_FAILED)
				last_state = state
			}
		}
		io.write_byte(line_writer, '|')
	}

	for _ in 0 ..< report.progress_width - (end - start) {
		io.write_byte(line_writer, ' ')
	}

	io.write_string(line_writer, SGR_RESET + "] ")

	ticker: string
	if done_count == len(pkg.test_states) {
		ticker = "[package done]"
		if failed_count > 0 {
			ticker = fmt.tprintf("%s (" + SGR_FAILED + "%i" + SGR_RESET + " failed)", ticker, failed_count)
		}
	} else {
		if len(pkg.last_change_name) == 0 {
			#no_bounds_check pkg.last_change_name = pkg.tests[0].name
		}

		switch pkg.last_change_state {
		case .Ready:
			ticker = fmt.tprintf(SGR_READY + "%s" + SGR_RESET, pkg.last_change_name)
		case .Running:
			ticker = fmt.tprintf(SGR_RUNNING + "%s" + SGR_RESET, pkg.last_change_name)
		case .Failed:
			ticker = fmt.tprintf(SGR_FAILED + "%s" + SGR_RESET, pkg.last_change_name)
		case .Successful:
			ticker = fmt.tprintf(SGR_SUCCESS + "%s" + SGR_RESET, pkg.last_change_name)
		}
	}

	if done_count == len(pkg.test_states) {
		fmt.wprintfln(line_writer, "     % 4i :: %s",
			len(pkg.test_states),
			ticker,
		)
	} else {
		fmt.wprintfln(line_writer, "% 4i/% 4i :: %s",
			done_count,
			len(pkg.test_states),
			ticker,
		)
	}

	pkg.redraw_string = strings.to_string(line_builder)
	pkg.frame_ready = true
	io.write_string(w, pkg.redraw_string)
}

redraw_report :: proc(w: io.Writer, report: Report) {
	// If we print a line longer than the user's terminal can handle, it may
	// wrap around, shifting the progress report out of alignment.
	//
	// There are ways to get the current terminal width, and that would be the
	// ideal way to handle this, but it would require system-specific code such
	// as setting STDIN to be non-blocking in order to read the response from
	// the ANSI DSR escape code, or reading environment variables.
	//
	// The DECAWM escape codes control whether or not the terminal will wrap
	// long lines or overwrite the last visible character.
	// This should be fine for now.
	//
	// Note that we only do this for the animated summary; log messages are
	// still perfectly fine to wrap, as they're printed in their own batch,
	// whereas the animation depends on each package being only on one line.
	//
	// Of course, if you resize your terminal while it's printing, things can
	// still break...
	fmt.wprint(w, ansi.CSI + ansi.DECAWM_OFF)
	for &pkg in report.packages {
		redraw_package(w, report, &pkg)
	}
	fmt.wprint(w, ansi.CSI + ansi.DECAWM_ON)
}

needs_to_redraw :: proc(report: Report) -> bool {
	for pkg in report.packages {
		if !pkg.frame_ready {
			return true
		}
	}

	return false
}

draw_status_bar :: proc(w: io.Writer, threads_string: string, total_done_count, total_test_count: int) {
	if total_done_count == total_test_count {
		// All tests are done; print a blank line to maintain the same height
		// of the progress report.
		fmt.wprintln(w)
	} else {
		fmt.wprintfln(w,
			"%s % 4i/% 4i :: total",
			threads_string,
			total_done_count,
			total_test_count)
	}
}

write_memory_report :: proc(w: io.Writer, tracker: ^mem.Tracking_Allocator, pkg, name: string) {
	fmt.wprintf(w,
		"<% 10M/% 10M> <% 10M> (% 5i/% 5i) :: %s.%s",
		tracker.current_memory_allocated,
		tracker.total_memory_allocated,
		tracker.peak_memory_allocated,
		tracker.total_free_count,
		tracker.total_allocation_count,
		pkg,
		name)

	for ptr, entry in tracker.allocation_map {
		fmt.wprintf(w,
			"\n        +++ leak % 10M @ %p [%s:%i:%s()]",
			entry.size,
			ptr,
			filepath.base(entry.location.file_path),
			entry.location.line,
			entry.location.procedure)
		}

	for entry in tracker.bad_free_array {
		fmt.wprintf(w,
			"\n        +++ bad free        @ %p [%s:%i:%s()]",
			entry.memory,
			filepath.base(entry.location.file_path),
			entry.location.line,
			entry.location.procedure)
	}
}
