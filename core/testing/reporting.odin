#+private
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Feoramund:   Total rewrite.
*/

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:path/filepath"
import "core:strings"
import "core:terminal"
import "core:terminal/ansi"

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
	render_package(report, pkg)
	io.write_string(w, pkg.redraw_string)
}

render_package :: proc(report: Report, pkg: ^Package_Run) {
	if pkg.frame_ready {
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
				io.write_string(line_writer, ansi.sgr(ansi.FG_BRIGHT_BLACK))
				last_state = state
			}
		case .Running:
			if last_state != state {
				io.write_string(line_writer, ansi.sgr(ansi.FG_YELLOW))
				last_state = state
			}
		case .Successful:
			if last_state != state {
				io.write_string(line_writer, ansi.sgr(ansi.FG_GREEN))
				last_state = state
			}
		case .Failed:
			if last_state != state {
				io.write_string(line_writer, ansi.sgr(ansi.FG_RED))
				last_state = state
			}
		}
		io.write_byte(line_writer, '|')
	}

	for _ in 0 ..< report.progress_width - (end - start) {
		io.write_byte(line_writer, ' ')
	}

	io.write_string(line_writer, ansi.sgr(ansi.RESET))
	io.write_string(line_writer, "] ")

	ticker: string
	if done_count == len(pkg.test_states) {
		ticker = "[package done]"
		if failed_count > 0 {
			ticker = fmt.tprintf("%s (%s%i%s failed)",
				ticker,
				ansi.sgr(ansi.FG_RED),
				failed_count,
				ansi.sgr(ansi.RESET),
			)
		}
	} else {
		if len(pkg.last_change_name) == 0 {
			#no_bounds_check pkg.last_change_name = pkg.tests[0].name
		}

		switch pkg.last_change_state {
		case .Ready:
			ticker = ansi.color(pkg.last_change_name, ansi.FG_BRIGHT_BLACK)
		case .Running:
			ticker = ansi.color(pkg.last_change_name, ansi.FG_YELLOW)
		case .Failed:
			ticker = ansi.color(pkg.last_change_name, ansi.FG_RED)
		case .Successful:
			ticker = ansi.color(pkg.last_change_name, ansi.FG_GREEN)
		}
	}

	if done_count == len(pkg.test_states) {
		fmt.wprintfln(line_writer, "     % 4i :: %s%s",
			len(pkg.test_states),
			ticker,
			ansi.clear_to_end_of_line(),
		)
	} else {
		fmt.wprintfln(line_writer, "% 4i/% 4i :: %s%s",
			done_count,
			len(pkg.test_states),
			ticker,
			ansi.clear_to_end_of_line(),
		)
	}

	pkg.redraw_string = strings.to_string(line_builder)
	pkg.frame_ready = true
}

package_done :: proc(pkg: ^Package_Run) -> bool {
	for state in pkg.test_states {
		if state <= .Running {
			return false
		}
	}
	return true
}

redraw_report :: proc(w: io.Writer, report: Report, fit_to_terminal: bool) -> (lines: int) {
	// If we print a line longer than the user's terminal can handle, it may
	// wrap around, shifting the progress report out of alignment.
	//
	// The DECAWM escape codes control whether or not the terminal will wrap
	// long lines or overwrite the last visible character.
	// The Windows 10 console host ignores them, so long lines still wrap there.
	//
	// Note that we only do this for the animated summary; log messages are
	// still perfectly fine to wrap, as they're printed after the final report,
	// whereas the animation depends on each package being only on one line.
	//
	// With `fit_to_terminal`, and when its height is known, the report is
	// also kept within the terminal's height. The cursor can't move above
	// the top row, so a taller report would scroll on every redraw. When the
	// packages don't fit, unfinished packages take priority for the free
	// lines, all in their usual order, and a "+N more packages" line counts
	// the rest. Unless the run was interrupted, the runner draws the final
	// report in full, as nothing redraws it afterwards.
	//
	// Of course, if you resize your terminal while it's printing, things can
	// still break...
	fmt.wprint(w, ansi.disable_auto_wrap())
	defer fmt.wprint(w, ansi.enable_auto_wrap())

	max_lines := len(report.packages)
	if fit_to_terminal {
		if _, rows, ok := terminal.get_terminal_size(); ok {
			max_lines = rows - 2
		}
	}

	if len(report.packages) <= max_lines {
		for &pkg in report.packages {
			redraw_package(w, report, &pkg)
		}
		return len(report.packages)
	}

	slots := max(max_lines - 1, 0)
	unfinished := 0
	for &pkg in report.packages {
		if !package_done(&pkg) {
			unfinished += 1
		}
	}
	show_unfinished := min(unfinished, slots)
	show_done := slots - show_unfinished

	for &pkg in report.packages {
		if package_done(&pkg) {
			if show_done > 0 {
				redraw_package(w, report, &pkg)
				show_done -= 1
				continue
			}
		} else if show_unfinished > 0 {
			redraw_package(w, report, &pkg)
			show_unfinished -= 1
			continue
		}
		render_package(report, &pkg)
	}

	hidden := len(report.packages) - slots
	fmt.wprintfln(w, "+%i more package%s%s", hidden, "" if hidden == 1 else "s", ansi.clear_to_end_of_line())
	return slots + 1
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
		fmt.wprintln(w, ansi.clear_to_end_of_line())
	} else {
		fmt.wprintfln(w,
			"%s % 4i/% 4i :: total%s",
			threads_string,
			total_done_count,
			total_test_count,
			ansi.clear_to_end_of_line())
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
