#+build linux
package linux

/// Low 8 bits of the exit code
/// Only retrieve the exit code if WIFEXITED(s) = true
WEXITSTATUS :: #force_inline proc "contextless" (s: u32) -> u32 {
	return (s & 0xff00) >> 8
}

/// Termination signal
/// Only retrieve the code if WIFSIGNALED(s) = true
WTERMSIG :: #force_inline proc "contextless" (s: u32) -> u32 {
	return s & 0x7f
}

/// The signal that stopped the child
/// Only retrieve if WIFSTOPPED(s) = true
WSTOPSIG :: #force_inline proc "contextless" (s: u32) -> u32 {
	return WEXITSTATUS(s)
}

/// Check if the process terminated normally (via exit.2)
WIFEXITED :: #force_inline proc "contextless" (s: u32) -> bool {
	return WTERMSIG(s) == 0
}

/// Check if the process signaled
WIFSIGNALED :: #force_inline proc "contextless" (s: u32) -> bool {
	return cast(i8)(((s) & 0x7f) + 1) >> 1 > 0
}

/// Check if the process has stopped
WIFSTOPPED :: #force_inline proc "contextless" (s: u32) -> bool {
	return (s & 0xff) == 0x7f
}

/// Check if the process is continued by the tracee
WIFCONTINUED :: #force_inline proc "contextless" (s: u32) -> bool {
	return s == 0xffff
}

/// Check if the process dumped core
WCOREDUMP :: #force_inline proc "contextless" (s: u32) -> bool {
	return s & 0x80 == 0x80
}

@private _sigmask :: proc "contextless" (sig: Signal) -> (uint) {
	return 1 << ((cast(uint)(sig) - 1) % (8*size_of(uint)))
}
@private _sigword :: proc "contextless" (sig: Signal) -> (uint) {
	return (cast(uint)sig - 1) / (8*size_of(uint))
}

// TODO: sigaddset etc


/// Iterate the results of getdents
/// Only iterates as much data as loaded in the buffer
/// In case you need to iterate *all* files in a directory
/// consider using dirent_get_iterate
///
/// Example of using dirent_iterate_buf
///   // Get dirents into a buffer
///   buf: [128]u8
///   sys.getdents(dirfd, buf[:])
///   // Print the names of the files
///   for dir in sys.dirent_iterate_buf(buf[:], &offs) {
///       name := sys.dirent_name(dir)
///       fmt.println(name)
///   }
/// This function doesn't automatically make a request
/// for the buffer to be refilled
dirent_iterate_buf :: proc "contextless" (buf: []u8, offs: ^int) -> (d: ^Dirent, cont: bool) {
	// Stopped iterating when there's no space left
	if offs^ >= len(buf) {
		return nil, false
	}
	// Retrieve dirent form the current offset
	dirent := cast(^Dirent) &buf[offs^]
	// Add the stride of dirent struct to the current offset
	offs^ += cast(int) dirent.reclen
	return dirent, true
}

/// Obtain the name of dirent as a string
/// The lifetime of the string is bound to the lifetime of the provided dirent structure
dirent_name :: proc "contextless" (dirent: ^Dirent) -> string #no_bounds_check {
	str := ([^]u8)(&dirent.name)
	// Dirents are aligned to 8 bytes, so there is guaranteed to be a null
	// terminator in the last 8 bytes.
	str_size := int(dirent.reclen) - cast(int)offset_of(Dirent, name)

	trunc := min(str_size, 8)
	str_size -= trunc
	for _ in 0..<trunc {
		str_size += 1
		if str[str_size] == 0 {
			break
		}
	}
	return string(str[:str_size])
}

/// Constructor for the `futex_op` argument of a FUTEX_WAKE_OP call
futex_op :: proc "contextless" (arg_op: Futex_Arg_Op, cmp_op: Futex_Cmp_Op, op_arg: u32, cmp_arg: u32) -> u32 {
	arg_op := cast(u32) arg_op
	cmp_op := cast(u32) cmp_op
	return (arg_op << 28) | (cmp_op << 24) | ((op_arg & 0xfff) << 12) | (cmp_arg & 0xfff)
}

/// Helper function for constructing the config for caches
perf_cache_config :: #force_inline proc "contextless" (id: Perf_Hardware_Cache_Id,
	op: Perf_Hardware_Cache_Op_Id,
	res: Perf_Hardware_Cache_Result_Id) -> u64 {
	return u64(id) | (u64(op) << 8) | (u64(res) << 16)
}
