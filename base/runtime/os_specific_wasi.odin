#+build wasi
#+private
package runtime

foreign import wasi "wasi_snapshot_preview1"

_HAS_RAND_BYTES :: true

ciovec_t :: struct {
	buf:     [^]u8,
	buf_len: u32,
}

@(default_calling_convention="contextless")
foreign wasi {
	fd_write :: proc(
		fd: i32,
		iovs: [^]ciovec_t,
		iovs_len: u32,
		n: ^u32,
	) -> u16 ---

	@(private="file")
	args_sizes_get :: proc(
		num_of_args:  ^u32,
		size_of_args: ^u32,
	) -> u16 ---

	@(private="file")
	args_get :: proc(
		argv:     [^]cstring,
		argv_buf: [^]byte,
	) -> u16 ---

	@(private="file")
	proc_exit :: proc(rval: u32) -> ! ---

	@(private ="file")
	random_get :: proc(buf: [^]u8, buf_len: u32) -> u16 ---

	@(private="file")
	clock_time_get :: proc(id: u32, precision: u64, time: ^u64) -> u16 ---
}

@(private="file")
CLOCK_MONOTONIC :: 1

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	iov := ciovec_t{raw_data(data), u32(len(data))}
	n: u32
	err := fd_write(2, &iov, 1, &n)
	return int(n), _OS_Errno(err)
}

_rand_bytes :: proc "contextless" (dst: []byte) {
	if errno := random_get(raw_data(dst), u32(len(dst))); errno != 0 {
		panic_contextless("base/runtime: wasi.random_get failed")
	}
}

_read_cycle_counter :: proc "contextless" () -> i64 {
	ns: u64
	if clock_time_get(CLOCK_MONOTONIC, 0, &ns) != 0 {
		return 0
	}
	return i64(ns)
}

_wasi_setup_args :: proc() {
	num_of_args, size_of_args: u32
	if errno := args_sizes_get(&num_of_args, &size_of_args); errno != 0 {
		return
	}

	args, err := make([]cstring, num_of_args)
	if err != nil {
		return
	}

	args_buf: []byte
	if args_buf, err = make([]byte, size_of_args); err != nil {
		delete(args)
		return
	}

	if errno := args_get(raw_data(args), raw_data(args_buf)); errno != 0 {
		delete(args)
		delete(args_buf)
		return
	}
	args__ = args
}


_exit :: proc "contextless" (code: int) -> ! {
	proc_exit(u32(code))
}