#+build wasi
#+private
package runtime

foreign import wasi "wasi_snapshot_preview1"

_HAS_RAND_BYTES :: true

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

	@(private="file")
	proc_exit :: proc(rval: u32) -> ! ---

	@(private ="file")
	random_get :: proc(buf: []u8) -> u16 ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	n: uint
	err := fd_write(1, {data}, &n)
	return int(n), _OS_Errno(err)
}

_rand_bytes :: proc "contextless" (dst: []byte) {
	if errno := random_get(dst); errno != 0 {
		panic_contextless("base/runtime: wasi.random_get failed")
	}
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


_exit :: proc "contextless" (code: int) -> ! {
	proc_exit(u32(code))
}