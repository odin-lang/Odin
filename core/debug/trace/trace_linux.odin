#+vet explicit-allocators
#+private file
package debug_trace

@require import "base:intrinsics"
@require import "base:runtime"

@require import "core:c"
@require import "core:strings"
@require import "core:sys/posix"

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
_locations_destroy :: proc(locations: []Resolved_Location, allocator: runtime.Allocator) {
	for entry in locations {
		if entry.location.file_path != OOM_MARKER { delete(entry.location.file_path, allocator) }
		if entry.location.procedure != OOM_MARKER { delete(entry.location.procedure, allocator) }
	}
	delete(locations, allocator)
}

@(private="package")
_resolve :: proc(bt: Capture, allocator, temp_allocator: runtime.Allocator) -> (locations: []Resolved_Location, alloc_err: runtime.Allocator_Error) {
	foreign lib {
		backtrace_symbols :: proc(buffer: [^]rawptr, size: c.int) -> [^]cstring ---
		@(link_name="free")
		backtrace_free :: proc(ptr: rawptr) ---
	}

	#assert(intrinsics.type_base_type(intrinsics.type_elem_type(Capture)) == rawptr)
	msgs := backtrace_symbols(([^]rawptr)(raw_data(bt)), i32(len(bt)))[:len(bt)]
	defer backtrace_free(raw_data(msgs))

	locations = make([]Resolved_Location, len(bt), allocator) or_return

	// Debug info is needed.
	when !ODIN_DEBUG {
		fill_unresolved(locations, msgs, .None, allocator)
		return
	}

	i := 0

	command := make([dynamic]string, temp_allocator)
	defer delete(command)

	if _, err := append(&command, SYMBOLIZER_PROGRAM, "--functions", "--exe", ""); err != nil {
		fill_unresolved(locations, msgs, .Resolve_Aborted, allocator)
		return
	}

	COMMAND_EXE_POS   :: 3
	COMMAND_START_LEN :: 4

	for msg, j in msgs {
		exe, addr, parse_err := parse_address(msg)

		if parse_err == nil {
			if command[COMMAND_EXE_POS] == "" {
				command[COMMAND_EXE_POS] = exe
			} else if command[COMMAND_EXE_POS] != exe {
				i += exec_and_fill(command[:], locations[i:], msgs[i:], allocator, temp_allocator)

				command[COMMAND_EXE_POS] = exe
				resize(&command, COMMAND_START_LEN)
			}

			if append(&command, addr) == 1 {
				continue
			}
		}

		// Parse/append failure:
		// execute existing command and mark current location as aborted

		if len(command) > COMMAND_START_LEN {
			i += exec_and_fill(command[:], locations[i:], msgs[i:], allocator, temp_allocator)
		}
		command[COMMAND_EXE_POS] = ""
		resize(&command, COMMAND_START_LEN)

		fill_unresolved(locations[j:j+1], msgs[j:j+1], .Resolve_Aborted, allocator)
		i = j+1
	}

	if len(command) > COMMAND_START_LEN {
		i += exec_and_fill(command[:], locations[i:], msgs[i:], allocator, temp_allocator)
	}

	return

	clone_or_oom_marker :: proc(s: string, allocator: runtime.Allocator) -> string {
		clone, err := strings.clone(s, allocator)
		if err != nil {
			return OOM_MARKER
		}

		return clone
	}

	fill_unresolved :: proc(locations: []Resolved_Location, msgs: []cstring, err: Resolve_Error, allocator: runtime.Allocator) {
		for msg, i in msgs {
			exe, address, parse_err := parse_address(msg)
			if parse_err != nil {
				locations[i] = Resolved_Location {
					location = Location{
						procedure = clone_or_oom_marker(string(msg), allocator),
					},
					error = parse_err,
				}
				continue
			}

			locations[i] = Resolved_Location {
				location = Location{
					file_path = clone_or_oom_marker(exe,     allocator),
					procedure = clone_or_oom_marker(address, allocator),
				},
				error = err,
			}
		}
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

	exec_and_fill :: proc(command: []string, locations: []Resolved_Location, msgs: []cstring, allocator, temp_allocator: runtime.Allocator) -> (filled: int) {
		stdout, exec_errno, success := exec_symbolizer(command, temp_allocator)
		defer delete(stdout, temp_allocator)

		count := len(command)-COMMAND_START_LEN

		// `SYMBOLIZER_PROGRAM` does not exist, lets fall back to unresolved info.
		if exec_errno == .ENOENT || !success {
			fill_unresolved(locations, msgs, .Resolve_Aborted, allocator)
			return count
		}

		sstdout := string(stdout)
		for i in 0..<count {
			exe, address, parse_err := parse_address(msgs[i])
			assert(parse_err == nil)

			procedure, proc_err := process_line(strings.split_lines_iterator(&sstdout))
			location, loc_err := process_line(strings.split_lines_iterator(&sstdout))
			if proc_err != nil || loc_err != nil {
				fill_unresolved(locations[i:], msgs[i:], .Resolve_Aborted, allocator)
				break
			}
			if procedure == "" || procedure == "??" {
				procedure = address
			}

			file_path, line := split_location(location)
			if file_path == "" || strings.starts_with(file_path, "??") {
				file_path = exe
			}

			locations[i] = Resolved_Location {
				location = Location{
					procedure = clone_or_oom_marker(procedure, allocator),
					file_path = clone_or_oom_marker(file_path, allocator),
					line      = line,
				},
			}
		}

		return count
	}

	split_location :: proc(location: string) -> (file_path: string, line: i32) {
		file_path = location

		colon_idx := strings.last_index_byte(location, ':')
		if colon_idx > 0 {
			line_str := location[colon_idx+1:]
			if line_int, ok := parse_line_number(line_str); ok {
				file_path = location[:colon_idx]
				line      = i32(line_int)
			}
		}

		return

		parse_line_number :: proc(s: string) -> (n: i64, ok: bool) {
			if len(s) == 0 { return }
			for c in s {
				if c < '0' || c > '9' { return }
				n = n*10 + i64(c-'0')
			}
			return n, true
		}
	}

	process_line :: proc(line: string, ok: bool) -> (string, Resolve_Error) {
		if !ok || line == "" { return "", .Resolve_Aborted }
		return strings.trim_right_space(line), nil
	}

	exec_symbolizer :: proc(command: []string, allocator: runtime.Allocator) -> (stdout: []byte, exec_errno: posix.Errno, ok: bool) {
		cargs, cargs_err := make([]cstring, len(command)+1, allocator)
		if cargs_err != nil {
			return
		}
		defer delete(cargs, allocator)

		args_size := 0
		for arg in command {
			args_size += len(arg)+1
		}
		args, args_err := make([]byte, args_size, allocator)
		if args_err != nil {
			return
		}
		defer delete(args, allocator)

		offset := 0
		for arg, i in command {
			cargs[i] = cstring(&args[offset])
			copy(args[offset:], arg)
			offset += len(arg)+1
		}

		READ, WRITE :: 0, 1
		stdout_pipe, exec_pipe: [2]posix.FD
		if posix.pipe(&stdout_pipe) != .OK {
			return
		}
		if posix.pipe(&exec_pipe) != .OK {
			posix.close(stdout_pipe[READ])
			posix.close(stdout_pipe[WRITE])
			return
		}
		if posix.fcntl(exec_pipe[WRITE], .SETFD, i32(posix.FD_CLOEXEC)) == -1 {
			posix.close(stdout_pipe[READ])
			posix.close(stdout_pipe[WRITE])
			posix.close(exec_pipe[READ])
			posix.close(exec_pipe[WRITE])
			return
		}

		pid := posix.fork()
		if pid == -1 {
			posix.close(stdout_pipe[READ])
			posix.close(stdout_pipe[WRITE])
			posix.close(exec_pipe[READ])
			posix.close(exec_pipe[WRITE])
			return
		}

		if pid == 0 {
			abort :: proc(exec_fd: posix.FD) -> ! {
				errno := posix.errno()
				posix.write(exec_fd, ([^]byte)(&errno), size_of(errno))
				posix._exit(126)
			}

			posix.close(stdout_pipe[READ])
			posix.close(exec_pipe[READ])
			if posix.dup2(stdout_pipe[WRITE], posix.STDOUT_FILENO) == -1 {
				abort(exec_pipe[WRITE])
			}

			dev_null := posix.open("/dev/null", {.WRONLY})
			if dev_null == -1 || posix.dup2(dev_null, posix.STDERR_FILENO) == -1 {
				abort(exec_pipe[WRITE])
			}
			if dev_null != posix.STDERR_FILENO {
				posix.close(dev_null)
			}
			if stdout_pipe[WRITE] != posix.STDOUT_FILENO {
				posix.close(stdout_pipe[WRITE])
			}

			posix.execvp(cargs[0], raw_data(cargs))
			abort(exec_pipe[WRITE])
		}

		posix.close(stdout_pipe[WRITE])
		posix.close(exec_pipe[WRITE])

		output: [dynamic]byte
		output.allocator = allocator
		read_ok := true
		buf: [1024]byte
		for {
			n := posix.read(stdout_pipe[READ], raw_data(buf[:]), len(buf))
			if n > 0 {
				if _, err := append(&output, ..buf[:n]); err != nil {
					read_ok = false
				}
			} else if n == -1 && posix.errno() == .EINTR {
				continue
			} else {
				read_ok = read_ok && n == 0
				break
			}
		}
		posix.close(stdout_pipe[READ])

		exec_errno = .NONE
		for {
			n := posix.read(exec_pipe[READ], ([^]byte)(&exec_errno), size_of(exec_errno))
			if n == -1 && posix.errno() == .EINTR {
				continue
			}
			read_ok = read_ok && (n == 0 || n == size_of(exec_errno))
			break
		}
		posix.close(exec_pipe[READ])

		status: c.int
		for {
			if posix.waitpid(pid, &status, {}) == -1 {
				if posix.errno() == .EINTR {
					continue
				}
				read_ok = false
			}
			break
		}

		stdout = output[:]
		ok = read_ok && exec_errno == nil && posix.WIFEXITED(status) && posix.WEXITSTATUS(status) == 0
		return
	}

}
} // INSTRUMENTATION_MODE
