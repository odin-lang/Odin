#+build wasi
#+private
package runtime

foreign import wasi "wasi_snapshot_preview1"

@(default_calling_convention="contextless")
foreign wasi {
	fd_write :: proc(
		fd: i32,
		iovs: [][]byte,
		n: ^uint,
	) -> u16 ---

	@(private="file")
	args_sizes_get :: proc(
		num_of_args:  ^uint,
		size_of_args: ^uint,
	) -> u16 ---

	@(private="file")
	args_get :: proc(
		argv:     [^]cstring,
		argv_buf: [^]byte,
	) -> u16 ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	n: uint
	err := fd_write(1, {data}, &n)
	return int(n), _OS_Errno(err)
}

_wasi_setup_args :: proc() {
	num_of_args, size_of_args: uint
	if errno := args_sizes_get(&num_of_args, &size_of_args); errno != 0 {
		return
	}

	err: Allocator_Error
	if args__, err = make([]cstring, num_of_args); err != nil {
		return
	}

	args_buf: []byte
	if args_buf, err = make([]byte, size_of_args); err != nil {
		delete(args__)
		return
	}

	if errno := args_get(raw_data(args__), raw_data(args_buf)); errno != 0 {
		delete(args__)
		delete(args_buf)
	}
}
