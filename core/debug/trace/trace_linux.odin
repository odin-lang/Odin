#+vet explicit-allocators
#+private file
package debug_trace

@require import "base:intrinsics"
@require import "base:runtime"

@require import "core:c"
@require import "core:os"
@require import "core:strconv"
@require import "core:strings"

when !INSTRUMENTATION_MODE {

foreign import lib "system:c"

@(private="package")
_Capture_Entry :: rawptr

@(private="package")
_capture :: #force_no_inline proc(buf: Capture, skip: int) -> (n: int) {
	foreign lib {
		backtrace :: proc(buffer: [^]rawptr, size: c.int) -> c.int ---
	}

	skip := skip
	skip += 2 // This function + caller.

	#assert(intrinsics.type_base_type(intrinsics.type_elem_type(Capture)) == rawptr)
	// In order to omit `skip` frames, we alloca a temp buffer with `skip` extra slots.
	bigger_buf := ([^]Capture_Entry)(intrinsics.alloca((skip + len(buf)) * size_of(Capture_Entry), align_of(Capture_Entry)))[:len(buf)+2]
	_n         := int(backtrace(([^]rawptr)(raw_data(bigger_buf)), i32(len(bigger_buf))))
	if _n > skip {
		copy(buf, bigger_buf[skip:])
		return _n-skip
	}

	return 0
}

@(private="package")
_locations_destroy :: proc(locations: []Location, allocator: runtime.Allocator) {
	for location in locations {
		if location.file_path != OOM_MARKER { delete(location.file_path, allocator) }
		if location.procedure != OOM_MARKER { delete(location.procedure, allocator) }
	}
	delete(locations, allocator)
}

@(private="package")
_resolve :: proc(bt: Capture, allocator, temp_allocator: runtime.Allocator) -> (locations: []Location, err: Resolve_Error) {
	foreign lib {
		backtrace_symbols :: proc(buffer: [^]rawptr, size: c.int) -> [^]cstring ---
		@(link_name="free")
		backtrace_free :: proc(ptr: rawptr) ---
	}

	#assert(intrinsics.type_base_type(intrinsics.type_elem_type(Capture)) == rawptr)
	msgs := backtrace_symbols(([^]rawptr)(raw_data(bt)), i32(len(bt)))[:len(bt)]
	defer backtrace_free(raw_data(msgs))

	{
		mem_err: runtime.Allocator_Error
		locations, mem_err = make([]Location, len(bt), allocator)
		if mem_err != nil {
			return nil, .Allocator_Error
		}
	}

	defer if err != nil {
		_locations_destroy(locations, allocator)
	}

	// Debug info is needed.
	when !ODIN_DEBUG {
		return fallback_to_unresolved(locations, msgs, allocator)
	}

	i := 0

	command := make([dynamic]string, temp_allocator)
	defer delete(command)

	if _, err := append(&command, SYMBOLIZER_PROGRAM, "--functions", "--exe", ""); err != nil {
		return fallback_to_unresolved(locations, msgs, allocator)
	}

	COMMAND_EXE_POS   :: 3
	COMMAND_START_LEN :: 4

	for msg in msgs {
		exe, addr := parse_address(msg) or_return
		if command[COMMAND_EXE_POS] == "" {
			command[COMMAND_EXE_POS] = exe
		} else if command[COMMAND_EXE_POS] != exe {
			i += exec_and_fill(command[:], locations[i:], msgs[i:], allocator, temp_allocator) or_return

			command[COMMAND_EXE_POS] = exe
			resize(&command, COMMAND_START_LEN)
		}

		if _, err := append(&command, addr); err != nil {
			return fallback_to_unresolved(locations, msgs, allocator)
		}
	}

	if len(command) > COMMAND_START_LEN {
		i += exec_and_fill(command[:], locations[i:], msgs[i:], allocator, temp_allocator) or_return
	}

	return

	clone_or_oom_marker :: proc(s: string, allocator: runtime.Allocator) -> string {
		clone, err := strings.clone(s, allocator)
		if err != nil {
			return OOM_MARKER
		}

		return clone
	}

	fallback_to_unresolved :: proc(locations: []Location, msgs: []cstring, allocator: runtime.Allocator) -> ([]Location, Resolve_Error) {
		for msg, i in msgs {
			exe, address, parse_err := parse_address(msg)
			if parse_err != nil {
				locations[i] = Location {
					procedure = clone_or_oom_marker(string(msg), allocator),
				}
				continue
			}

			locations[i] = Location {
				file_path = clone_or_oom_marker(exe,     allocator),
				procedure = clone_or_oom_marker(address, allocator),
			}
		}

		return locations, nil
	}

	// Parses the exe and address out of a backtrace line.
	// Example: .../main(+0x20) [0x100000] -> .../main, +0x20, nil
	parse_address :: proc(cmsg: cstring) -> (string, string, Resolve_Error) {
		msg := string(cmsg)
		close_idx := strings.last_index_byte(msg, ')')
		if close_idx < 1 { return "", "", .Parse_Address_Failed }

		open_idx := strings.last_index_byte(msg[:close_idx], '(')
		if open_idx < 0 { return "", "", .Parse_Address_Failed }

		return msg[:open_idx], msg[open_idx+1:close_idx], nil
	}

	exec_and_fill :: proc(command: []string, locations: []Location, msgs: []cstring, allocator, temp_allocator: runtime.Allocator) -> (filled: int, err: Resolve_Error) {
		state, stdout, stderr, perr := os.process_exec({command = command}, temp_allocator)
		defer delete(stdout, temp_allocator)
		defer delete(stderr, temp_allocator)

		if perr != nil || !state.success { return 0, .Resolve_Failed }

		count := len(command)-COMMAND_START_LEN

		sstdout := string(stdout)
		for i in 0..<count {
			exe, address, parse_err := parse_address(msgs[i])
			assert(parse_err == nil)

			procedure := process_line(strings.split_lines_iterator(&sstdout)) or_return
			if procedure == "" || procedure == "??" {
				procedure = address
			}

			location        := process_line(strings.split_lines_iterator(&sstdout)) or_return
			file_path, line := split_location(location)
			if file_path == "" || strings.starts_with(file_path, "??") {
				file_path = exe
			}

			locations[i] = {
				procedure = clone_or_oom_marker(procedure, allocator),
				file_path = clone_or_oom_marker(file_path, allocator),
				line      = line,
			}
		}

		return count, nil
	}

	split_location :: proc(location: string) -> (file_path: string, line: i32) {
		file_path = location

		colon_idx := strings.last_index_byte(location, ':')
		if colon_idx > 0 {
			line_str := location[colon_idx+1:]
			if line_int, ok := strconv.parse_i64_of_base(line_str, 10); ok {
				file_path = location[:colon_idx]
				line      = i32(line_int)
			}
		}

		return
	}

	process_line :: proc(line: string, ok: bool) -> (string, Resolve_Error) {
		if !ok        { return "", .Resolve_Aborted }
		if line == "" { return "", .Resolve_Failed  }
		return strings.trim_right_space(line), nil
	}
}
} // INSTRUMENTATION_MODE
