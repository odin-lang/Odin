#+build windows
#+private
package runtime

foreign import bcrypt "system:Bcrypt.lib"
foreign import kernel32 "system:Kernel32.lib"

_HAS_RAND_BYTES :: true

@(private="file")
@(default_calling_convention="system")
foreign kernel32 {
	// NOTE(bill): The types are not using the standard names (e.g. DWORD and LPVOID) to just minimizing the dependency

	// stderr_write
	GetStdHandle         :: proc(which: u32) -> rawptr ---
	SetHandleInformation :: proc(hObject: rawptr, dwMask: u32, dwFlags: u32) -> b32 ---
	WriteFile            :: proc(hFile: rawptr, lpBuffer: rawptr, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: ^u32, lpOverlapped: rawptr) -> b32 ---
	GetLastError         :: proc() -> u32 ---

	ExitProcess          :: proc(code: u32) -> ! ---

	GetCommandLineW      :: proc() -> [^]u16 ---
}

@(private="file")
@(default_calling_convention="system")
foreign bcrypt {
	BCryptGenRandom :: proc(hAlgorithm: rawptr, pBuffer: [^]u8, cbBuffer: u32, dwFlags: u32) -> i32 ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (n: int, err: _OS_Errno) #no_bounds_check {
	if len(data) == 0 {
		return 0, 0
	}

	STD_ERROR_HANDLE :: ~u32(0) -12 + 1
	HANDLE_FLAG_INHERIT :: 0x00000001
	MAX_RW :: 1<<30

	h := GetStdHandle(STD_ERROR_HANDLE)
	when size_of(uintptr) == 8 {
		SetHandleInformation(h, HANDLE_FLAG_INHERIT, 0)
	}

	single_write_length: u32
	total_write: i64
	length := i64(len(data))

	for total_write < length {
		remaining := length - total_write
		to_write := u32(min(i32(remaining), MAX_RW))

		e := WriteFile(h, &data[total_write], to_write, &single_write_length, nil)
		if single_write_length <= 0 || !e {
			err = _OS_Errno(GetLastError())
			n = int(total_write)
			return
		}
		total_write += i64(single_write_length)
	}
	n = int(total_write)
	return
}

_rand_bytes :: proc "contextless" (dst: []byte) {
	ensure_contextless(u64(len(dst)) <= u64(max(u32)), "base/runtime: oversized rand_bytes request")

	BCRYPT_USE_SYSTEM_PREFERRED_RNG :: 0x00000002

	ERROR_INVALID_HANDLE :: 6
	ERROR_INVALID_PARAMETER :: 87

	ret := BCryptGenRandom(nil, raw_data(dst), u32(len(dst)), BCRYPT_USE_SYSTEM_PREFERRED_RNG)
	switch ret {
	case 0:
	case ERROR_INVALID_HANDLE:
		// The handle to the first parameter is invalid.
		// This should not happen here, since we explicitly pass nil to it
		panic_contextless("base/runtime: BCryptGenRandom Invalid handle for hAlgorithm")
	case ERROR_INVALID_PARAMETER:
		// One of the parameters was invalid
		panic_contextless("base/runtime: BCryptGenRandom Invalid parameter")
	case:
		// Unknown error
		panic_contextless("base/runtime: BCryptGenRandom failed")
	}
}

_exit :: proc "contextless" (code: int) -> ! {
	ExitProcess(u32(code))
}

_windows_split_command_line :: proc "contextless" (cmd_line: [^]u16, argv: [^]cstring16, text: [^]u16) -> (argc, text_len: int) {
	put :: #force_inline proc "contextless" (text: [^]u16, text_len: ^int, c: u16) {
		if text != nil {
			text[text_len^] = c
		}
		text_len^ += 1
	}

	if cmd_line == nil {
		return
	}

	i := 0

	if argv != nil {
		argv[0] = cstring16(text)
	}
	argc = 1
	for in_quotes := false; cmd_line[i] != 0; i += 1 {
		c := cmd_line[i]
		if !in_quotes && (c == ' ' || c == '\t') {
			break
		}
		if c == '"' {
			in_quotes = !in_quotes
		} else {
			put(text, &text_len, c)
		}
	}
	put(text, &text_len, 0)

	in_quotes := false
	for {
		for cmd_line[i] == ' ' || cmd_line[i] == '\t' {
			i += 1
		}
		if cmd_line[i] == 0 {
			return
		}

		if argv != nil {
			argv[argc] = cstring16(text[text_len:])
		}
		argc += 1

		for {
			copy_char   := true
			backslashes := 0
			for cmd_line[i] == '\\' {
				backslashes += 1
				i += 1
			}
			if cmd_line[i] == '"' {
				if backslashes%2 == 0 {
					if in_quotes && cmd_line[i+1] == '"' {
						i += 1
					} else {
						copy_char = false
						in_quotes = !in_quotes
					}
				}
				backslashes /= 2
			}
			for _ in 0..<backslashes {
				put(text, &text_len, '\\')
			}

			c := cmd_line[i]
			if c == 0 || (!in_quotes && (c == ' ' || c == '\t')) {
				break
			}
			if copy_char {
				put(text, &text_len, c)
			}
			i += 1
		}
		put(text, &text_len, 0)
	}
}

when ODIN_NO_CRT {
	@(private="file")
	windows_args_block: [^]byte

	_windows_setup_args :: proc "contextless" () {
		cmd_line := GetCommandLineW()
		if cmd_line == nil {
			return
		}

		argc, text_len := _windows_split_command_line(cmd_line, nil, nil)

		header_len := argc*size_of(cstring16)
		block := ([^]byte)(heap_alloc(header_len + text_len*size_of(u16), zero_memory=false))
		if block == nil {
			return
		}

		argv := ([^]cstring16)(block)
		text := ([^]u16)(&block[header_len])
		_windows_split_command_line(cmd_line, argv, text)

		windows_args_block = block
		args__ = argv[:argc]
	}

	@(fini, private="file")
	windows_delete_args :: proc "contextless" () {
		if windows_args_block != nil {
			heap_free(windows_args_block)
		}
	}
}