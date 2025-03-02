#+no-instrumentation
package linux

import "base:intrinsics"


/*
	Read data from file into the buffer
	Returns the number of bytes successfully read, which may be less than the size
	of the buffer even if the termination is successfull.
	Available since Linux 1.0.
	Before Linux 3.14, this operation is not atomic (i.e. not thread safe).
*/
read :: proc "contextless" (fd: Fd, buf: []u8) -> (int, Errno) {
	ret := syscall(SYS_read, fd, raw_data(buf), len(buf))
	return errno_unwrap(ret, int)
}

/*
	Write the data from a buffer into the file
	Returns the number of bytes successfully written, which may be less than the size
	of the buffer, even if the termination is successfull
	When using direct I/O, error doesn't mean the write has failed. Partial data may
	have been written.
	If .Eintr is returned, the write operation has failed due to interrupt. You'll probably
	need to restart this syscall

	Available since Linux 1.0
	Before Linux 3.14 this operation is not atomic (i.e. not thread safe)
*/
write :: proc "contextless" (fd: Fd, buf: []u8) -> (int, Errno) {
	ret := syscall(SYS_write, fd, raw_data(buf), len(buf))
	return errno_unwrap(ret, int)
}

/*
	Open file, get the file descriptor
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
open :: proc "contextless" (name: cstring, flags: Open_Flags, mode: Mode = {}) -> (Fd, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_openat, AT_FDCWD, transmute(uintptr) name, transmute(u32) flags, transmute(u32) mode)
		return errno_unwrap(ret, Fd)
	} else {
		ret := syscall(SYS_open, transmute(uintptr) name, transmute(u32) flags, transmute(u32) mode)
		return errno_unwrap(ret, Fd)
	}
}

/*
	Close the file.
	Available since Linux 1.0.
*/
close :: proc "contextless" (fd: Fd) -> (Errno) {
	ret := syscall(SYS_close, fd)
	return Errno(-ret)
}

/*
	Get file status.

	Returns information about the file in struct pointed to by `stat` parameter.

	Available since Linux 1.0
	For 32-bit systems a different syscall is used that became available since 2.4.
	Not available on ARM64.
*/
stat :: proc "contextless" (filename: cstring, stat: ^Stat) -> (Errno) {
	when size_of(int) == 8 {
		when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
			ret := syscall(SYS_fstatat, AT_FDCWD, cast(rawptr) filename, stat, 0)
			return Errno(-ret)
		} else {
			ret := syscall(SYS_stat, cast(rawptr) filename, stat)
			return Errno(-ret)
		}
	} else {
		ret := syscall(SYS_stat64, cast(rawptr) filename, stat)
		return Errno(-ret)
	}
}

/*
	Get file status from file descriptor.

	Returns information about the file in struct pointed to by `stat` parameter.

	Available since Linux 1.0.
	For 32-bit systems a different syscall is used that became available since 2.4.
*/
fstat :: proc "contextless" (fd: Fd, stat: ^Stat) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_fstat, cast(i32) fd, stat)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fstat64, cast(i32) fd, stat)
		return Errno(-ret)
	}
}

/*
	Get information about the file that's potentially a symbolic link
	The information is returned in a struct pointed to by `stat` parameter.
	The difference with stat, fstat is that if the file is a symbolic link,
	stat and fstat will dereference the link. lstat doesn't dereference symlinks.
	
	Available since Linux 1.0.
	For 32-bit systems a different syscall is used that became available since 2.4.
	Not available on arm64.
*/
lstat :: proc "contextless" (filename: cstring, stat: ^Stat) -> (Errno) {
	when size_of(int) == 8 {
		when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
			return fstatat(AT_FDCWD, filename, stat, {.SYMLINK_NOFOLLOW})
		} else {
			ret := syscall(SYS_lstat, cast(rawptr) filename, stat)
			return Errno(-ret)
		}
	} else {
		ret := syscall(SYS_lstat64, cast(rawptr) filename, stat)
		return Errno(-ret)
	}
}

/*
	Wait on event on a file descriptor.
	Available since Linux 2.2.
*/
poll :: proc "contextless" (fds: []Poll_Fd, timeout: i32) -> (i32, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		seconds := cast(uint) timeout / 1000
		nanoseconds := cast(uint) (timeout % 1000) * 1_000_000
		timeout_spec := Time_Spec{seconds, nanoseconds}
		ret := syscall(SYS_ppoll, raw_data(fds), len(fds), &timeout_spec, 0, 0)
		return errno_unwrap(ret, i32)
	} else {
		ret := syscall(SYS_poll, raw_data(fds), len(fds), timeout)
		return errno_unwrap(ret, i32)
	}
}

/*
	Seek the file stream to specified offset.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 1.2.
*/
lseek :: proc "contextless" (fd: Fd, off: i64, whence: Seek_Whence) -> (i64, Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_lseek, fd, off, whence)
		return errno_unwrap(ret, i64)
	} else {
		result: i64 = ---
		lo, hi := compat64_arg_pair(off)
		ret := syscall(SYS__llseek, fd, hi, lo, &result, whence)
		return result, Errno(-ret)
	}
}

/*
	Map files into memory.
	Available since Linux 1.0.
	On 32-bit platforms since Linux 1.0.
*/
mmap :: proc "contextless" (addr: uintptr, size: uint, prot: Mem_Protection, flags: Map_Flags, fd: Fd = Fd(-1), offset: i64 = 0) -> (rawptr, Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_mmap, addr, size, transmute(i32) prot, transmute(i32) flags, fd, offset)
		return errno_unwrap(ret, rawptr, uintptr)
	} else {
		ret := syscall(SYS_mmap2, addr, size, transmute(i32) prot, transmute(i32) flags, fd, cast(uintptr)(offset/4096))
		return errno_unwrap(ret, rawptr, uintptr)
	}
}

/*
	Protect memory region.
	Available since Linux 1.0.
*/
mprotect :: proc "contextless" (addr: rawptr, size: uint, prot: Mem_Protection) -> (Errno) {
	ret := syscall(SYS_mprotect, addr, size, transmute(i32) prot)
	return Errno(-ret)
}

/*
	Unmap memory.
	Available since Linux 1.0.
*/
munmap :: proc "contextless" (addr: rawptr, size: uint) -> (Errno) {
	ret := syscall(SYS_munmap, addr, size)
	return Errno(-ret)
}

/*
	Extend the data segment size until the address `addr`. Note: you may be
	familiar with sbrk(), which is not actually a syscall, so is not
	implemented here.
	Available since Linux 1.0.
*/
brk :: proc "contextless" (addr: uintptr) -> (Errno) {
	ret := syscall(SYS_brk, addr)
	return Errno(-ret)
}

/*
	Returns from signal handlers on some archs.
*/
rt_sigreturn :: proc "c" () -> ! {
	intrinsics.syscall(uintptr(SYS_rt_sigreturn))
	unreachable()
}

/*
	Alter an action taken by a process.
*/
rt_sigaction :: proc "contextless" (sig: Signal, sigaction: ^Sig_Action($T), old_sigaction: ^Sig_Action) -> Errno {
	// NOTE(jason): It appears that the restorer is required for i386 and amd64
	when ODIN_ARCH == .i386 || ODIN_ARCH == .amd64 {
		sigaction.flags += {.RESTORER}
	}
	if sigaction != nil && sigaction.restorer == nil && .RESTORER in sigaction.flags {
		sigaction.restorer = rt_sigreturn
	}
	ret := syscall(SYS_rt_sigaction, sig, sigaction, old_sigaction, size_of(Sig_Set))
	return Errno(-ret)
}

/*
	Examime and alter blocked signals.
	Available since Linux 2.2.
*/
rt_sigprocmask :: proc "contextless" (mask_kind: Sig_Mask_Kind, new_set: ^Sig_Set, old_set: ^Sig_Set) -> Errno {
	ret := syscall(SYS_rt_sigprocmask, mask_kind, new_set, old_set, size_of(Sig_Set))
	return Errno(-ret)
}

/*
	Control devices. The ioctl syscall is a bit special because
	its argument is usually a pointer to some driver-specific structure.
	The request value is device-specific. Consult your LibC implementation's
	ioctls.h file to learn more. The returned value of ioctl *may* be an error
	code value instead of a memory address depending on the request type.
	Available since Linux 1.0.
*/
ioctl :: proc "contextless" (fd: Fd, request: u32, arg: uintptr) -> (uintptr) {
	ret := syscall(SYS_ioctl, fd, request, arg)
	return uintptr(ret)
}

/*
	Read the file at a specified offset.
	Note, it is not an error to return less bytes than requested.
	Available since Linux 2.2.
*/
pread :: proc "contextless" (fd: Fd, buf: []u8, offset: i64) -> (int, Errno) {
	when ODIN_ARCH == .arm32 {
		ret := syscall(SYS_pread64, fd, raw_data(buf), len(buf), 0, compat64_arg_pair(offset))
	} else {
		ret := syscall(SYS_pread64, fd, raw_data(buf), len(buf), compat64_arg_pair(offset))
	}
	return errno_unwrap(ret, int)
}

/*
	Read the file at a specified offset.
	Note, it is not an error to return less bytes than requested.
	Available since Linux 2.2.
*/
pwrite :: proc "contextless" (fd: Fd, buf: []u8, offset: i64) -> (int, Errno) {
	when ODIN_ARCH == .arm32 {
		ret := syscall(SYS_pwrite64, fd, raw_data(buf), len(buf), 0, compat64_arg_pair(offset))
	} else {
		ret := syscall(SYS_pwrite64, fd, raw_data(buf), len(buf), compat64_arg_pair(offset))
	}
	return errno_unwrap(ret, int)
}

/*
	Read the data from file into multiple buffers.
	Available since Linux 2.0.
*/
readv :: proc "contextless" (fd: Fd, iov: []IO_Vec) -> (int, Errno) {
	ret := syscall(SYS_readv, fd, raw_data(iov), len(iov))
	return errno_unwrap(ret, int)
}

/*
	Write the data from multiple buffers into a file.
	Available since Linux 2.0.
*/
writev :: proc "contextless" (fd: Fd, iov: []IO_Vec) -> (int, Errno) {
	ret := syscall(SYS_writev, fd, raw_data(iov), len(iov))
	return errno_unwrap(ret, int)
}

/*
	Check user permissions for a file.
	If Mode is F_OK, checks whether the file exists.
	Similarly, X_OK, W_OK, R_OK check if the file is executable, writeable, readable respectively.
	Available since Linux 1.0.
	For ARM64 available since Linux 2.6.16.
*/
access :: proc "contextless" (name: cstring, mode: Mode = F_OK) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_faccessat, AT_FDCWD, cast(rawptr) name, transmute(u32) mode)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_access, cast(rawptr) name, transmute(u32) mode)
		return Errno(-ret)
	}
}

/*
	Create a pipe
	Available since Linux 2.6.27
*/
pipe2 :: proc "contextless" (pipes: ^[2]Fd, flags: Open_Flags) -> (Errno) {
	ret := syscall(SYS_pipe2, pipes, transmute(u32) flags)
	return Errno(-ret)
}

/*
	Yield the processor.
	Available since Linux 2.0.
*/
sched_yield :: proc "contextless" () {
	syscall(SYS_sched_yield)
}

/*
	Remap a virtual memory address.
	Available since Linux 2.0.
*/
mremap :: proc "contextless" (old_addr: rawptr, old_size: uint, new_size: uint, flags: MRemap_Flags, new_addr: uintptr = 0) -> (rawptr, Errno) {
	if .FIXED in flags {
		ret := syscall(SYS_mremap, old_addr, old_size, new_size, transmute(i32) flags, new_addr)
		return errno_unwrap(ret, rawptr, rawptr)
	} else {
		ret := syscall(SYS_mremap, old_addr, old_size, new_size, transmute(i32) flags)
		return errno_unwrap(ret, rawptr, rawptr)
	}
}

/*
	Sync file with memory map.
	Available since Linux 2.0.
*/
msync :: proc "contextless" (addr: rawptr, size: uint, flags: MSync_Flags) -> (Errno) {
	ret := syscall(SYS_msync, addr, size, transmute(i32) flags)
	return Errno(-ret)
}

/*
	Determine if pages are resident in memory.
	Available since Linux 2.4.
*/
mincore :: proc "contextless" (addr: rawptr, size: uint, vec: []b8) -> (Errno) {
	ret := syscall(SYS_mincore, addr, size, raw_data(vec))
	return Errno(-ret)
}

/*
	Give advice about use of memory.
	Available since Linux 2.4.
*/
madvise :: proc "contextless" (addr: rawptr, size: uint, advice: MAdvice) -> (Errno) {
	ret := syscall(SYS_madvise, addr, size, advice)
	return Errno(-ret)
}

/*
	Allocate a SystemV shared memory segment.
	Available since Linux 2.0.
*/
shmget :: proc "contextless" (key: Key, size: uint, flags: IPC_Flags) -> (Key, Errno) {
	ret := syscall(SYS_shmget, key, size, transmute(i16) flags)
	return errno_unwrap(ret, Key)
}

/*
	SystemV shared memory segment operations.
	Available since Linux 2.0.
*/
shmat :: proc "contextless" (key: Key, addr: rawptr, flags: IPC_Flags) -> (rawptr, Errno) {
	ret := syscall(SYS_shmat, key, addr, transmute(i16) flags)
	return errno_unwrap(ret, rawptr, uintptr)
}

shmctl_ds :: proc "contextless" (key: Key, cmd: IPC_Cmd, buf: ^Shmid_DS) -> (Errno) {
	ret := syscall(SYS_shmctl, key, cmd, buf)
	return Errno(-ret)
}

shmctl_info :: proc "contextless" (key: Key, cmd: IPC_Cmd, buf: ^Shm_Info) -> (int, Errno) {
	ret := syscall(SYS_shmctl, key, cmd, buf)
	return errno_unwrap(ret, int)
}

/*
	SystemV shared memory control.
	Available since Linux 2.0.
*/
shmctl :: proc {shmctl_ds, shmctl_info}

/*
	Allocate a new file descriptor that refers to the same file as the one provided.
	Available since Linux 1.0.
*/
dup :: proc "contextless" (fd: Fd) -> (Fd, Errno) {
	ret := syscall(SYS_dup, fd)
	return errno_unwrap(ret, Fd)
}

/*
	Adjust an existing file descriptor to point to the same file as `old`.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.27.
*/
dup2 :: proc "contextless" (old: Fd, new: Fd) -> (Fd, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_dup3, old, new, 0)
		return errno_unwrap(ret, Fd)
	} else {
		ret := syscall(SYS_dup2, old, new)
		return errno_unwrap(ret, Fd)
	}
}

/*
	Wait until the next signal is delivered.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
pause :: proc "contextless" () {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		syscall(SYS_ppoll, 0, 0, 0, 0)
	} else {
		syscall(SYS_pause)
	}
}

/*
	High-resolution sleep.
	Available since Linux 2.0.
*/
nanosleep :: proc "contextless" (req: ^Time_Spec, rem: ^Time_Spec) -> (Errno) {
	ret := syscall(SYS_nanosleep, req, rem)
	return Errno(-ret)
}

/*
	Get the value of an internal timer.
	Available since Linux 1.0.
*/
getitimer :: proc "contextless" (which: ITimer_Which, cur: ^ITimer_Val) -> (Errno) {
	ret := syscall(SYS_getitimer, cur)
	return Errno(-ret)
}

/*
	Set an alarm clock for delivery of a signal.
	Available since Linux 1.0.
*/
alarm :: proc "contextless" (seconds: u32) -> u32 {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		new := ITimer_Val { value = { seconds = cast(int) seconds } }
		old := ITimer_Val {}
		syscall(SYS_setitimer, ITimer_Which.REAL, &new, &old)
		return u32(old.value.seconds) + u32(new.value.microseconds)
	} else {
		return cast(u32) syscall(SYS_alarm, seconds)
	}
}

/*
	Set the value of an internal timer.
	Available since Linux 1.0.
*/
setitimer :: proc "contextless" (which: ITimer_Which, new: ^ITimer_Val, old: ^ITimer_Val) -> (Errno) {
	ret := syscall(SYS_getitimer, new, old)
	return Errno(-ret)
}

/*
	Returns the thread group ID of the current process.
	Note that it doesn't return the pid, despite it's name.
	Available since Linux 1.0.
*/
getpid :: proc "contextless" () -> Pid {
	return cast(Pid) syscall(SYS_getpid)
}

/*
	Transfer the data between file descriptors.
	Available since Linux 2.2.
	On 32-bit platforms available since Linux 2.6.
*/
sendfile :: proc "contextless" (out_fd: Fd, in_fd: Fd, offset: ^i64, count: uint) -> (int, Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_sendfile, out_fd, in_fd, offset, count)
		return errno_unwrap(ret, int)
	} else {
		ret := syscall(SYS_sendfile64, out_fd, in_fd, offset, count)
		return errno_unwrap(ret, int)
	}
}

/*
	Create a socket file descriptor.
	Available since Linux 2.0.
*/
socket :: proc "contextless" (domain: Address_Family, socktype: Socket_Type, sockflags: Socket_FD_Flags, protocol: Protocol) -> (Fd, Errno) {
	sock_type_flags: int = cast(int) socktype | transmute(int) sockflags
	ret := syscall(SYS_socket, domain, sock_type_flags, protocol)
	return errno_unwrap(ret, Fd)
}

/*
	Connect the socket to the address.
	Available since Linux 2.0.
*/
connect :: proc "contextless" (sock: Fd, addr: ^$T) -> (Errno)
where
	T == Sock_Addr_In ||
	T == Sock_Addr_In6 ||
	T == Sock_Addr_Un ||
	T == Sock_Addr_Any
{
	ret := syscall(SYS_connect, sock, addr, size_of(T))
	return Errno(-ret)
}

/*
	Accept a pending connection or block until new connection appears.
	Depends on Sock_FD_Flags of the `sock` parameter.
	Available since Linux 2.0.
*/
accept :: proc "contextless" (sock: Fd, addr: ^$T, sockflags: Socket_FD_Flags = {}) -> (Fd, Errno)
where
	T == Sock_Addr_In ||
	T == Sock_Addr_In6 ||
	T == Sock_Addr_Un ||
	T == Sock_Addr_Any
{
	addr_len: i32 = size_of(T)
	ret := syscall(SYS_accept4, sock, addr, &addr_len, transmute(int) sockflags)
	return errno_unwrap(ret, Fd)
}

// TODO(flysand): Rewrite recvfrom and sendto to use default parameters
recvfrom :: proc "contextless" (sock: Fd, buf: []u8, flags: Socket_Msg, addr: ^$T) -> (int, Errno)
where
	T == Sock_Addr_In ||
	T == Sock_Addr_In6 ||
	T == Sock_Addr_Un ||
	T == Sock_Addr_Any
{
	addr_len: i32 = size_of(T)
	ret := syscall(SYS_recvfrom, sock, raw_data(buf), len(buf), transmute(i32) flags, addr, &addr_len)
	return errno_unwrap(ret, int)
}

@private
recv_noaddr :: proc "contextless" (sock: Fd, buf: []u8, flags: Socket_Msg) -> (int, Errno) {
	ret := syscall(SYS_recvfrom, sock, raw_data(buf), len(buf), transmute(i32) flags, cast(rawptr) nil, cast(uintptr) 0)
	return errno_unwrap(ret, int)
}

sendto :: proc "contextless" (sock: Fd, buf: []u8, flags: Socket_Msg, addr: ^$T) -> (int, Errno)
where
	T == Sock_Addr_In ||
	T == Sock_Addr_In6 ||
	T == Sock_Addr_Un ||
	T == Sock_Addr_Any
{
	ret := syscall(SYS_sendto, sock, raw_data(buf), len(buf), transmute(i32) flags, addr, size_of(T))
	return errno_unwrap(ret, int)
}

@private
send_noaddr :: proc "contextless" (sock: Fd, buf: []u8, flags: Socket_Msg) -> (int, Errno) {
	ret := syscall(SYS_sendto, sock, raw_data(buf), len(buf), transmute(i32) flags, cast(rawptr) nil, cast(uintptr) 0)
	return errno_unwrap(ret, int)
}

/*
	Receive a message from a socket.
	Available since Linux 2.0.
*/
recv :: proc {recvfrom, recv_noaddr}

/*
	Send a message through a socket.
	Available since Linux 2.0.
*/
send :: proc {sendto, send_noaddr}

/*
	Send a message on a socket.
	Available since Linux 2.0.
*/
sendmsg :: proc "contextless" (sock: Fd, msghdr: ^Msg_Hdr, flags: Socket_Msg) -> (int, Errno) {
	ret := syscall(SYS_sendmsg, sock, msghdr, transmute(i32) flags)
	return errno_unwrap(ret, int)
}

/*
	Receive a message on a socket.
	Available since Linux 2.0.
*/
recvmsg :: proc "contextless" (sock: Fd, msghdr: ^Msg_Hdr, flags: Socket_Msg) -> (int, Errno) {
	ret := syscall(SYS_recvmsg, sock, msghdr, transmute(i32) flags)
	return errno_unwrap(ret, int)
}

/*
	Shutdown a socket.
	Available since Linux 2.0.
*/
shutdown :: proc "contextless" (sock: Fd, how: Shutdown_How) -> (Errno) {
	ret := syscall(SYS_shutdown, sock, how)
	return Errno(-ret)
}

/*
	Bind a socket to the given local address.
	Available since Linux 2.0.
*/
bind :: proc "contextless" (sock: Fd, addr: ^$T) -> (Errno)
where
	T == Sock_Addr_In ||
	T == Sock_Addr_In6 ||
	T == Sock_Addr_Un ||
	T == Sock_Addr_Any
{
	ret := syscall(SYS_bind, sock, addr, size_of(T))
	return Errno(-ret)
}

/*
	Marks the socket as a socket that listen to connections using accept(2).
	Available since Linux 2.0.
*/
listen :: proc "contextless" (sock: Fd, queue_len: i32) -> (Errno) {
	ret := syscall(SYS_listen, sock, queue_len)
	return Errno(-ret)
}

/*
	Get socket name (aka it's bound address).
	Available since Linux 2.0.
*/
getsockname :: proc "contextless" (sock: Fd, addr: ^Sock_Addr_Any) -> (Errno) {
	addr_len := size_of(Sock_Addr_Any)
	ret := syscall(SYS_getsockname, sock, addr, &addr_len)
	return Errno(-ret)
}

/*
	Get the name of the connected peer socket.
	Available since Linux 2.0.
*/
getpeername :: proc "contextless" (sock: Fd, addr: ^Sock_Addr_Any) -> (Errno) {
	addr_len := size_of(Sock_Addr_Any)
	ret := syscall(SYS_getpeername, sock, addr, &addr_len)
	return Errno(-ret)
}

/*
	Create a pair of connected sockets.
	Available since Linux 2.0.
*/
socketpair :: proc "contextless" (domain: Protocol_Family, type: Socket_Type, proto: Protocol, pair: ^[2]Fd) -> (Errno) {
	ret := syscall(SYS_socketpair, domain, type, proto, pair)
	return Errno(-ret)
}

// TODO(flysand): the parameters are the same, maybe there's a way to make it into a single proc, sacrificing type
// safety slightly
// TODO(flysand): add ability to specify slices
setsockopt_base :: proc "contextless" (sock: Fd, level: int, opt: int, val: $T) -> (Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	val_data := val
	val_size := size_of(intrinsics.type_elem_type(T))
	ret := syscall(SYS_setsockopt, sock, level, opt, val_data, val_size)
	return Errno(-ret)
}

setsockopt_sock :: proc "contextless" (sock: Fd, level: Socket_API_Level_Sock, opt: Socket_Option, val: $T) -> (Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	return setsockopt_base(sock, cast(int) level, cast(int) opt, val) 
}

setsockopt_tcp :: proc "contextless" (sock: Fd, level: Socket_API_Level_TCP, opt: Socket_TCP_Option, val: $T) -> (Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	return setsockopt_base(sock, cast(int) level, cast(int) opt, val)
}

setsockopt_udp :: proc "contextless" (sock: Fd, level: Socket_API_Level_UDP, opt: Socket_UDP_Option, val: $T) -> (Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	return setsockopt_base(sock, cast(int) level, cast(int) opt, val)
}

/*
	Set socket option for a given socket API level.
	Available since Linux 2.0.
*/
setsockopt :: proc {
	setsockopt_sock,
	setsockopt_tcp,
	setsockopt_udp,
	setsockopt_base,
}

getsockopt_base :: proc "contextless" (sock: Fd, level: int, opt: Socket_Option, val: $T) -> (int, Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	val_data := val
	val_size := size_of(T)
	ret := syscall(SYS_getsockopt, sock, level, opt, val_data, cast(rawptr) &val_size)
	return val_size, Errno(-ret)
}

getsockopt_sock :: proc "contextless" (sock: Fd, level: Socket_API_Level_Sock, opt: Socket_Option, val: ^$T) -> (int, Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	return getsockopt_base(sock, cast(int) level, cast(int) opt, val)
}

getsockopt_tcp :: proc "contextless" (sock: Fd, level: Socket_API_Level_TCP, opt: Socket_TCP_Option, val: ^$T) -> (int, Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	return getsockopt_base(sock, cast(int) level, cast(int) opt, val)
}

getsockopt_udp :: proc "contextless" (sock: Fd, level: Socket_API_Level_UDP, opt: Socket_UDP_Option, val: ^$T) -> (int, Errno)
where
	intrinsics.type_is_pointer(T) ||
	intrinsics.type_is_multi_pointer(T)
{
	return getsockopt_base(sock, cast(int) level, cast(int) opt, val)
}

/*
	Get socket option for a given socket API level.
	Available since Linux 2.0.
*/
getsockopt :: proc {
	getsockopt_sock,
	getsockopt_tcp,
	getsockopt_udp,
	getsockopt_base,
}

/*
	Creates a copy of the running process.
	Available since Linux 1.0.
*/
fork :: proc "contextless" () -> (Pid, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_clone, u64(Signal.SIGCHLD), cast(rawptr) nil, cast(rawptr) nil, cast(rawptr) nil, u64(0))
		return errno_unwrap(ret, Pid)
	} else {
		ret := syscall(SYS_fork)
		return errno_unwrap(ret, Pid)
	}
}

/*
	Create a child process and block parent.
	Available since Linux 2.2.
*/
vfork :: proc "contextless" () -> Pid {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return Pid(syscall(SYS_vfork))
	} else {
		return Pid(syscall(SYS_clone, Signal.SIGCHLD))
	}
}

/*
	Replace the current process with another program.
	Available since Linux 1.0.
	On ARM64 available since Linux 3.19.
*/
execve :: proc "contextless" (name: cstring, argv: [^]cstring, envp: [^]cstring) -> (Errno) {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		ret := syscall(SYS_execve, cast(rawptr) name, cast(rawptr) argv, cast(rawptr) envp)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_execveat, AT_FDCWD, cast(rawptr) name, cast(rawptr) argv, cast(rawptr) envp, i32(0))
		return Errno(-ret)
	}
}

/*
	Exit the thread with a given exit code.
	Available since Linux 1.0.
*/
exit :: proc "contextless" (code: i32) -> ! {
	syscall(SYS_exit, code)
	unreachable()
}

/*
	Wait for the process to change state.
	Available since Linux 1.0.
*/
wait4 :: proc "contextless" (pid: Pid, status: ^u32, options: Wait_Options, rusage: ^RUsage) -> (Pid, Errno) {
	ret := syscall(SYS_wait4, pid, status, transmute(u32) options, rusage)
	return errno_unwrap(ret, Pid)
}

/*
	See `wait4` for documentation.
*/
waitpid :: wait4

/*
	Send signal to a process.
	Available since Linux 1.0.
*/
kill :: proc "contextless" (pid: Pid, signal: Signal) -> (Errno) {
	ret := syscall(SYS_kill, pid, signal)
	return Errno(-ret)
}

/*
	Get system information.
	Available since Linux 1.0.
*/
uname :: proc "contextless" (uts_name: ^UTS_Name) -> (Errno) {
	ret := syscall(SYS_uname, uts_name)
	return Errno(-ret)
}

/*
	Get a SystemV semaphore set identifier.
	Available since Linux 2.0.
*/
semget :: proc "contextless" (key: Key, n: i32, flags: IPC_Flags) -> (Key, Errno) {
	ret := syscall(SYS_semget, key, n, transmute(i16) flags)
	return errno_unwrap(ret, Key)
}

/*
	SystemV semaphore operations.
	Available since Linux 2.0.
*/
semop :: proc "contextless" (key: Key, ops: []Sem_Buf) -> (Errno) {
	when ODIN_ARCH != .i386 {
		ret := syscall(SYS_semop, key, raw_data(ops), len(ops))
		return Errno(-ret)
	} else {
		// Note(flysand): Max time limit, let's not worry about nanoseconds...
		max_timespec := Time_Spec {
			time_sec = max(uint),
			time_nsec = 0,
		}
		ret := syscall(SYS_semtimedop_time64, key, raw_data(ops), len(ops), &max_timespec)
		return Errno(-ret)
	}
}

semctl3 :: proc "contextless" (key: Key, semnum: i32, cmd: IPC_Cmd) -> (int, Errno) {
	ret := syscall(SYS_semctl, key, semnum, cmd)
	return errno_unwrap(ret, int)
}

semctl4 :: proc "contextless" (key: Key, semnum: i32, cmd: IPC_Cmd, semun: ^Sem_Un) -> (int, Errno) {
	ret := syscall(SYS_semctl, key, semnum, cmd, semun)
	return errno_unwrap(ret, int)
}

/*
	SystemV semaphore control operations.
	Available since Linux 2.0.
*/
semctl :: proc {semctl3, semctl4}

/*
	SystemV shared memory operations.
	Available since Linux 2.0.
*/
shmdt :: proc "contextless" (shmaddr: rawptr) -> (Errno) {
	ret := syscall(SYS_shmdt, shmaddr)
	return Errno(-ret)
}

/*
	Get SystemV message queue identifier.
	Available since Linux 2.0.
*/
msgget :: proc "contextless" (key: Key, flags: IPC_Flags) -> (Key, Errno) {
	ret := syscall(SYS_msgget, key, transmute(i16) flags)
	return errno_unwrap(ret, Key)
}

/*
	Send message to a SystemV message queue.
	Available since Linux 2.0.
*/
msgsnd :: proc "contextless" (key: Key, buf: rawptr, size: int, flags: IPC_Flags) -> (Errno) {
	ret := syscall(SYS_msgsnd, key, buf, size, transmute(i16) flags)
	return Errno(-ret)
}

/*
	Receive a message from a SystemV message queue.
	Available since Linux 2.0.
*/
msgrcv :: proc "contextless" (key: Key, buf: rawptr, size: int, type: uint, flags: IPC_Flags) -> (int, Errno) {
	ret := syscall(SYS_msgrcv, key, buf, size, type, transmute(i16) flags)
	return errno_unwrap(ret, int)
}

/*
	SystemV message control operations.
	Available since Linux 2.0.
*/
msgctl :: proc "contextless" (key: Key, cmd: IPC_Cmd, buf: ^Msqid_DS) -> (int, Errno) {
	ret := syscall(SYS_msgctl, key, cmd, buf)
	return errno_unwrap(ret, int)
}

fcntl_dupfd :: proc "contextless" (fd: Fd, cmd: FCntl_Command_DUPFD, newfd: Fd) -> (Fd, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, newfd)
	return errno_unwrap(ret, Fd)
}

fcntl_dupfd_cloexec :: proc "contextless" (fd: Fd, cmd: FCntl_Command_DUPFD_CLOEXEC, newfd: Fd) -> (Fd, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, newfd)
	return errno_unwrap(ret, Fd)
}

fcntl_getfd :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETFD) -> (Fd, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return errno_unwrap(ret, Fd)
}

fcntl_setfd :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETFD, newfd: Fd) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, newfd)
	return Errno(-ret)
}

fcntl_getfl :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETFL) -> (Open_Flags, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return errno_unwrap(u32(ret), Open_Flags, Open_Flags)
}

fcntl_setfl :: proc "contextless" (fd: Fd, cmd:  FCntl_Command_SETFL, flags: Open_Flags) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, transmute(u32) flags)
	return Errno(-ret)
}

fcntl_setlk :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETLK, lock: ^FLock) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_fcntl64, fd, cmd, lock)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fcntl, fd, cmd, lock)
		return Errno(-ret)
	}
}

fcntl_setlkw :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETLKW, lock: ^FLock) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_fcntl64, fd, cmd, lock)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fcntl, fd, cmd, lock)
		return Errno(-ret)
	}
}

fcntl_getlk :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETLK, lock: ^FLock) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_fcntl64, fd, cmd, lock)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fcntl, fd, cmd, lock)
		return Errno(-ret)
	}
}

fcntl_getown_ex :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETOWN_EX, owner: ^F_Owner) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, owner)
	return Errno(-ret)
}

fcntl_setown_ex :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETOWN_EX, owner: ^F_Owner) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, owner)
	return Errno(-ret)
}

fcntl_getsig :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETSIG) -> (Signal, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return errno_unwrap(ret, Signal)
}

fcntl_setsig :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETSIG, sig: Signal) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, sig)
	return Errno(-ret)
}

fcntl_setlease :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETLEASE, lease: FD_Lease) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, lease)
	return Errno(-ret)
}

fcntl_getlease :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETLEASE) -> (FD_Lease, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return errno_unwrap(ret, FD_Lease)
}

fcntl_notify :: proc "contextless" (fd: Fd, cmd: FCntl_Command_NOTIFY, notifications: FD_Notifications) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return Errno(-ret)
}

fcntl_setpipe_sz :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SETPIPE_SZ, sz: i32) -> (i32, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, sz)
	return errno_unwrap(ret, i32)
}

fcntl_getpipe_sz :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GETPIPE_SZ) -> (i32, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return errno_unwrap(ret, i32)
}

fcntl_add_seals :: proc "contextless" (fd: Fd, cmd: FCntl_Command_ADD_SEALS, seal: Seal) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, transmute(i32) seal)
	return Errno(-ret)
}

fcntl_get_seals :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GET_SEALS) -> (Seal, Errno) {
	ret := syscall(SYS_fcntl, fd, cmd)
	return errno_unwrap(i32(ret), Seal, Seal)
}

fcntl_get_rw_hint :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GET_RW_HINT, hint: ^RW_Hint) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, hint)
	return Errno(-ret)
}

fcntl_set_rw_hint :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SET_RW_HINT, hint: ^RW_Hint) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, hint)
	return Errno(-ret)
}

fcntl_get_file_rw_hint :: proc "contextless" (fd: Fd, cmd: FCntl_Command_GET_FILE_RW_HINT, hint: ^RW_Hint) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, hint)
	return Errno(-ret)
}

fcntl_set_file_rw_hint :: proc "contextless" (fd: Fd, cmd: FCntl_Command_SET_FILE_RW_HINT, hint: ^RW_Hint) -> (Errno) {
	ret := syscall(SYS_fcntl, fd, cmd, hint)
	return Errno(-ret)
}

fcntl :: proc {
	fcntl_dupfd,
	fcntl_dupfd_cloexec,
	fcntl_getfd,
	fcntl_setfd,
	fcntl_getfl,
	fcntl_setfl,
	fcntl_setlk,
	fcntl_setlkw,
	fcntl_getlk,
	fcntl_getown_ex,
	fcntl_setown_ex,
	fcntl_getsig,
	fcntl_setsig,
	fcntl_setlease,
	fcntl_getlease,
	fcntl_notify,
	fcntl_setpipe_sz,
	fcntl_getpipe_sz,
	fcntl_add_seals,
	fcntl_get_seals,
	fcntl_get_rw_hint,
	fcntl_set_rw_hint,
	fcntl_get_file_rw_hint,
	fcntl_set_file_rw_hint,
}

/*
	Apply or remove advisory lock on an open file.
	Available since Linux 2.0.
*/
flock :: proc "contextless" (fd: Fd, operation: FLock_Op) -> (Errno) {
	ret := syscall(SYS_flock, fd, transmute(i32) operation)
	return Errno(-ret)
}

/*
	Sync state of the file with the storage device.
	Available since Linux 1.0.
*/
fsync :: proc "contextless" (fd: Fd) -> (Errno) {
	ret := syscall(SYS_fsync, fd)
	return Errno(-ret)
}

/*
	Synchronize the state of the file with the storage device. Similar to `fsync`,
	except does not flush the metadata.
	Available since Linux 2.0.
*/
fdatasync :: proc "contextless" (fd: Fd) -> (Errno) {
	ret := syscall(SYS_fdatasync, fd)
	return Errno(-ret)
}

/*
	Truncate a file to specified length.
	Available since Linux 1.0.
	On 32-bit architectures available since Linux 2.4.
*/
truncate :: proc "contextless" (name: cstring, length: i64) -> (Errno) {
	when ODIN_ARCH == .arm32 {
		ret := syscall(SYS_truncate64, cast(rawptr) name, 0, compat64_arg_pair(length))
		return Errno(-ret)
	} else when size_of(int) == 4 {
		ret := syscall(SYS_truncate64, cast(rawptr) name, compat64_arg_pair(length))
		return Errno(-ret)
	} else {
		ret := syscall(SYS_truncate, cast(rawptr) name, compat64_arg_pair(length))
		return Errno(-ret)
	}
}

/*
	Truncate a file specified by file descriptor to specified length.
	On 32-bit architectures available since 2.4.
*/
ftruncate :: proc "contextless" (fd: Fd, length: i64) -> (Errno) {
	when ODIN_ARCH == .arm32 {
		ret := syscall(SYS_ftruncate64, fd, 0, compat64_arg_pair(length))
		return Errno(-ret)
	} else when size_of(int) == 4 {
		ret := syscall(SYS_ftruncate64, fd, compat64_arg_pair(length))
		return Errno(-ret)
	} else {
		ret := syscall(SYS_ftruncate, fd, compat64_arg_pair(length))
		return Errno(-ret)
	}
}

/*
	Retrieve the contents of the directory specified by dirfd.
	Returns the number of bytes written.
	Available since Linux 2.4.
*/
getdents :: proc "contextless" (dirfd: Fd, buf: []u8) -> (int, Errno) {
	ret := syscall(SYS_getdents64, dirfd, raw_data(buf), len(buf))
	return errno_unwrap(ret, int)
}

/*
	Get current working directory.
	Available since Linux 1.0.
*/
getcwd :: proc "contextless" (buf: []u8) -> (int, Errno) {
	ret := syscall(SYS_getcwd, raw_data(buf), len(buf))
	return errno_unwrap(ret, int)
}

/*
	Change working directory to the directory specified by path.
	Available since Linux 1.0.
*/
chdir :: proc "contextless" (path: cstring) -> (Errno) {
	ret := syscall(SYS_chdir, cast(rawptr) path)
	return Errno(-ret)
}

/*
	Change working directory to the directory specified by dirfd.
	Available since Linux 1.0.
*/
fchdir :: proc "contextless" (fd: Fd) -> (Errno) {
	ret := syscall(SYS_fchdir, fd)
	return Errno(-ret)
}

/*
	Rename (move) the file.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
rename :: proc "contextless" (old: cstring, new: cstring) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_renameat, AT_FDCWD, cast(rawptr) old, AT_FDCWD, cast(rawptr) new)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_rename, cast(rawptr) old, cast(rawptr) new)
		return Errno(-ret)
	}
}

/*
	Creates a directory.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
mkdir :: proc "contextless" (name: cstring, mode: Mode) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_mkdirat, AT_FDCWD, cast(rawptr) name, transmute(u32) mode)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_mkdir, cast(rawptr) name, transmute(u32) mode)
		return Errno(-ret)
	}
}

/*
	Remove a directory specified by name.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
rmdir :: proc "contextless" (name: cstring) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_unlinkat, AT_FDCWD, cast(rawptr) name, transmute(i32) FD_Flags{.REMOVEDIR})
		return Errno(-ret)
	} else {
		ret := syscall(SYS_rmdir, cast(rawptr) name)
		return Errno(-ret)
	}
}

/*
	Create a file.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
creat :: proc "contextless" (name: cstring, mode: Mode) -> (Fd, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return openat(AT_FDCWD, name, {.CREAT, .WRONLY,.TRUNC}, mode)
	} else {
		ret := syscall(SYS_creat, cast(rawptr) name, transmute(u32) mode)
		return errno_unwrap(ret, Fd)
	}
}

/*
	Create a hard link on a file.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
link :: proc "contextless" (target: cstring, linkpath: cstring) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_linkat, AT_FDCWD, cast(rawptr) target, AT_FDCWD, cast(rawptr) linkpath, 0)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_link, cast(rawptr) target, cast(rawptr) linkpath)
		return Errno(-ret)
	}
}

/*
	Delete a name, and possible a file it refers to.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
unlink :: proc "contextless" (name: cstring) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_unlinkat, AT_FDCWD, cast(rawptr) name, 0)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_unlink, cast(rawptr) name)
		return Errno(-ret)
	}
}

/*
	Create a symbolic link.
	Available since Linux 1.0.
	On arm64 available since Linux 2.6.16.
*/
symlink :: proc "contextless" (target: cstring, linkpath: cstring) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_symlinkat, cast(rawptr) target, AT_FDCWD, cast(rawptr) linkpath)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_symlink, cast(rawptr) target, cast(rawptr) linkpath)
		return Errno(-ret)
	}
}

/*
	Read the value of a symbolic link.
	Available since Linux 1.0.
	On arm64 available since Linux 2.6.16.
*/
readlink :: proc "contextless" (name: cstring, buf: []u8) -> (int, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_readlinkat, AT_FDCWD, cast(rawptr) name, raw_data(buf), len(buf))
		return errno_unwrap(ret, int)
	} else {
		ret := syscall(SYS_readlink, cast(rawptr) name, raw_data(buf), len(buf))
		return errno_unwrap(ret, int)
	}
}

/*
	Change file permissions.
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
chmod :: proc "contextless" (name: cstring, mode: Mode) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_fchmodat, AT_FDCWD, cast(rawptr) name, transmute(u32) mode)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_chmod, cast(rawptr) name, transmute(u32) mode)
		return Errno(-ret)
	}
}

/*
	Change file permissions through a file descriptor.
	Available since Linux 1.0.
*/
fchmod :: proc "contextless" (fd: Fd, mode: Mode) -> (Errno) {
	ret := syscall(SYS_fchmod, fd, transmute(u32) mode)
	return Errno(-ret)
}

/*
	Change ownership of a file.
	Available since Linux 2.2.
	On 32-bit architectures available since Linux 2.4.
	On ARM64 available since Linux 2.6.16.
*/
chown :: proc "contextless" (name: cstring, uid: Uid, gid: Gid) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_chown32, cast(rawptr) name, uid, gid)
		return Errno(-ret)
	} else when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_fchownat, AT_FDCWD, cast(rawptr) name, uid, gid, 0)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_chown, cast(rawptr) name, uid, gid)
		return Errno(-ret)
	}
}

/*
	Change ownership of a file by file descriptor.
	Available since Linux 1.0.
	On 32-bit architecvtures available since Linux 2.4.
*/
fchown :: proc "contextless" (fd: Fd, uid: Uid, gid: Gid) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_fchown32, fd, uid, gid)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fchown, fd, uid, gid)
		return Errno(-ret)
	}
}

/*
	Change ownership of a file. Unlike chown, if a file is a symlink dooesn't dereference it.
	Available since Linux 1.0.
	On 32-bit architectures available since Linux 2.4.
	On ARM64 available since Linux 2.6.16.
*/
lchown :: proc "contextless" (name: cstring, uid: Uid, gid: Gid) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_lchown32, cast(rawptr) name, uid, gid)
		return Errno(-ret)
	} else when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_fchownat, AT_FDCWD, cast(rawptr) name, uid, gid, transmute(i32) FD_Flags{.SYMLINK_NOFOLLOW})
		return Errno(-ret)
	} else {
		ret := syscall(SYS_lchown, cast(rawptr) name, uid, gid)
		return Errno(-ret)
	}
}

/*
	Set file mode creation mask.
	Available since Linux 1.0.
*/
umask :: proc "contextless" (mask: Mode) -> Mode {
	ret := syscall(SYS_umask, transmute(u32) mask)
	return transmute(Mode) cast(u32) ret
}

/*
	Get current time.
	Available since Linux 1.0.
*/
gettimeofday :: proc "contextless" (tv: ^Time_Val) -> (Errno) {
	ret := syscall(SYS_gettimeofday, tv)
	return Errno(-ret)
}

/*
	Get limits on resources.
	Available since Linux 1.0.
*/
getrlimit :: proc "contextless" (kind: RLimit_Kind, resource: ^RLimit) -> (Errno) {
	ret := syscall(SYS_getrlimit, kind, resource)
	return Errno(-ret)
}

/*
	Get resource usage.
	Available since Linux 1.0.
*/
getrusage :: proc "contextless" (who: RUsage_Who, rusage: ^RUsage) -> (Errno) {
	ret := syscall(SYS_getrusage, who, rusage)
	return Errno(-ret)
}

/*
	Get information about the system.
	Available since Linux 1.0.
*/
sysinfo :: proc "contextless" (sysinfo: ^Sys_Info) -> (Errno) {
	ret := syscall(SYS_sysinfo, sysinfo)
	return Errno(-ret)
}

/*
	Get current process times.
	Available since Linux 1.0.
*/
times :: proc "contextless" (tms: ^Tms) -> (Errno) {
	ret := syscall(SYS_times, cast(rawptr) tms)
	return Errno(-ret)
}

ptrace_traceme :: proc "contextless" (rq: PTrace_Traceme_Type) -> (Errno) {
	ret := syscall(SYS_ptrace, rq)
	return Errno(-ret)
}

ptrace_peek :: proc "contextless" (rq: PTrace_Peek_Type, pid: Pid, addr: uintptr) -> (uint, Errno) {
	res: uint = ---
	ret := syscall(SYS_ptrace, rq, pid, addr, &res)
	return res, Errno(-ret)
}

ptrace_poke :: proc "contextless" (rq: PTrace_Poke_Type, pid: Pid, addr: uintptr, data: uint) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, addr, data)
	return Errno(-ret)
}

ptrace_getregs :: proc "contextless" (rq: PTrace_Getregs_Type, pid: Pid, buf: ^User_Regs) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, buf)
	return Errno(-ret)
}

ptrace_getfpregs :: proc "contextless" (rq: PTrace_Getfpregs_Type, pid: Pid, buf: ^User_FP_Regs) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, buf)
	return Errno(-ret)
}

ptrace_getfpxregs :: proc "contextless" (rq: PTrace_Getfpxregs_Type, pid: Pid, buf: ^User_FPX_Regs) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, buf)
	return Errno(-ret)
}

ptrace_setregs :: proc "contextless" (rq: PTrace_Setregs_Type, pid: Pid, buf: ^User_Regs) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, buf)
	return Errno(-ret)
}

ptrace_setfpregs :: proc "contextless" (rq: PTrace_Setfpregs_Type, pid: Pid, buf: ^User_FP_Regs) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, buf)
	return Errno(-ret)
}

ptrace_setfpxregs :: proc "contextless" (rq: PTrace_Setfpxregs_Type, pid: Pid, buf: ^User_FPX_Regs) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, buf)
	return Errno(-ret)
}

ptrace_getregset :: proc "contextless" (rq: PTrace_Getregset_Type, pid: Pid, note: PTrace_Note_Type, buf: ^IO_Vec) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, note, buf)
	return Errno(-ret)
}

ptrace_setregset :: proc "contextless" (rq: PTrace_Setregset_Type, pid: Pid, note: PTrace_Note_Type, buf: ^IO_Vec) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, note, buf)
	return Errno(-ret)
}

ptrace_getsiginfo :: proc "contextless" (rq: PTrace_Getsiginfo_Type, pid: Pid, si: ^Sig_Info) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, si, rawptr(nil))
	return Errno(-ret)
}

ptrace_peeksiginfo :: proc "contextless" (rq: PTrace_Peeksiginfo_Type, pid: Pid, si: ^Sig_Info) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, si, rawptr(nil))
	return Errno(-ret)
}

ptrace_getsigmask :: proc "contextless" (rq: PTrace_Getsigmask_Type, pid: Pid, sigmask: ^Sig_Set) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, size_of(Sig_Set), sigmask)
	return Errno(-ret)
}

ptrace_setsigmask :: proc "contextless" (rq: PTrace_Setsigmask_Type, pid: Pid, sigmask: ^Sig_Set) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, size_of(Sig_Set), sigmask)
	return Errno(-ret)
}

ptrace_setoptions :: proc "contextless" (rq: PTrace_Setoptions_Type, pid: Pid, options: PTrace_Options) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, transmute(u32) options)
	return Errno(-ret)
}

ptrace_geteventmsg :: proc "contextless" (rq: PTrace_Geteventmsg_Type, pid: Pid, msg: ^uint) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, msg, rawptr(nil))
	return Errno(-ret)
}

ptrace_cont :: proc "contextless" (rq: PTrace_Cont_Type, pid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, rawptr(nil), sig)
	return Errno(-ret)
}

ptrace_singlestep :: proc "contextless" (rq: PTrace_Singlestep_Type, pid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, rawptr(nil), sig)
	return Errno(-ret)
}

ptrace_syscall :: proc "contextless" (rq: PTrace_Syscall_Type, pid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, rawptr(nil), sig)
	return Errno(-ret)
}

ptrace_sysemu :: proc "contextless" (rq: PTrace_Sysemu_Type, pid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, rawptr(nil), sig)
	return Errno(-ret)
}

ptrace_sysemu_singlestep :: proc "contextless" (rq: PTrace_Sysemu_Singlestep_Type, pid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, rawptr(nil), sig)
	return Errno(-ret)
}

ptrace_listen :: proc "contextless" (rq: PTrace_Listen_Type, pid: Pid) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, rawptr(nil))
	return Errno(-ret)
}

ptrace_interrupt :: proc "contextless" (rq: PTrace_Interrupt_Type, pid: Pid) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, rawptr(nil))
	return Errno(-ret)
}

ptrace_attach :: proc "contextless" (rq: PTrace_Attach_Type, pid: Pid) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, rawptr(nil))
	return Errno(-ret)
}

ptrace_seize :: proc "contextless" (rq: PTrace_Seize_Type, pid: Pid, opt: PTrace_Options) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, transmute(u32) opt, rawptr(nil))
	return Errno(-ret)
}

// TODO(flysand): ptrace_seccomp_get_filter

ptrace_detach :: proc "contextless" (rq: PTrace_Detach_Type, pid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_ptrace, rq, pid, 0, sig)
	return Errno(-ret)
}

// TODO(flysand): ptrace_get_thread_area
// TODO(flysand): ptrace_set_thread_area
// TODO(flysand): ptrace_get_syscall_info

/*
	Trace process.
*/
ptrace :: proc {
	ptrace_traceme,
	ptrace_peek,
	ptrace_poke,
	ptrace_getregs,
	ptrace_getfpregs,
	ptrace_getfpxregs,
	ptrace_setregs,
	ptrace_setfpregs,
	ptrace_setfpxregs,
	ptrace_getregset,
	ptrace_setregset,
	ptrace_getsiginfo,
	ptrace_peeksiginfo,
	ptrace_getsigmask,
	ptrace_setsigmask,
	ptrace_setoptions,
	ptrace_geteventmsg,
	ptrace_cont,
	ptrace_singlestep,
	ptrace_syscall,
	ptrace_sysemu,
	ptrace_sysemu_singlestep,
	ptrace_listen,
	ptrace_interrupt,
	ptrace_attach,
	ptrace_seize,
	ptrace_detach,
}

/*
	Get real user ID.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
getuid :: proc "contextless" () -> Uid {
	when size_of(int) == 8 {
		return cast(Uid) syscall(SYS_getuid)
	} else {
		return cast(Uid) syscall(SYS_getuid32)
	}
}

/*
	Read or clear kernel message ring buffer.
	Available since Linux 1.0.
*/
syslog :: proc "contextless" (act: Syslog_Action, buf: []u8) -> (int, Errno) {
	ret := syscall(SYS_syslog, act, raw_data(buf), len(buf))
	return errno_unwrap(ret, int)
}

/*
	Get real group ID.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
getgid :: proc "contextless" () -> Gid {
	when size_of(int) == 8 {
		return cast(Gid) syscall(SYS_getgid)
	} else {
		return cast(Gid) syscall(SYS_getgid32)
	}
}

/*
	Set effective User ID.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
@(require_results)
setuid :: proc "contextless" (uid: Uid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setuid, uid)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setuid32, uid)
		return Errno(-ret)
	}
}

/*
	Set effective group id.
	If the process is privileged also sets real group id.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
@(require_results)
setgid :: proc "contextless" (gid: Gid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setgid, gid)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setgid32, gid)
		return Errno(-ret)
	}
}

/*
	Get effective user ID.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
geteuid :: proc "contextless" () -> Uid {
	when size_of(int) == 8 {
		return cast(Uid) syscall(SYS_geteuid)
	} else {
		return cast(Uid) syscall(SYS_geteuid32)
	}
}

/*
	Get effective group ID.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
getegid :: proc "contextless" () -> Gid {
	when size_of(int) == 8 {
		return cast(Gid) syscall(SYS_getegid)
	} else {
		return cast(Gid) syscall(SYS_getegid32)
	}
}

/*
	Set process group.
	Available since Linux 1.0.
*/
setpgid :: proc "contextless" (pid: Pid, pgid: Pid) -> (Errno) {
	ret := syscall(SYS_setpgid, pid, pgid)
	return Errno(-ret)
}

/*
	Get the parent process ID.
	Available since Linux 1.0.
*/
getppid :: proc "contextless" () -> Pid {
	return cast(Pid) syscall(SYS_getppid)
}

/*
	Get process group.
	Available since Linux 1.0.
*/
getpgrp :: proc "contextless" () -> (Pid, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_getpgid, 0)
		return errno_unwrap(ret, Pid)
	} else {
		ret := syscall(SYS_getpgrp)
		return errno_unwrap(ret, Pid)
	}
}

/*
	Create a session and set the process group ID.
	Available since Linux 2.0.
*/
setsid :: proc "contextless" () -> (Pid, Errno) {
	ret := syscall(SYS_setsid)
	return errno_unwrap(ret, Pid)
}

/*
	Set real and/or effective user id.
	If any of the arguments is -1, the corresponding id is not changed.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
@(require_results)
setreuid :: proc "contextless" (real: Uid, effective: Uid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setreuid, real, effective)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setreuid32, real, effective)
		return Errno(-ret)
	}
}

/*
	Set real and/or effective group id.
	If any of the arguments is -1, the corresponding id is not changed.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
@(require_results)
setregid :: proc "contextless" (real: Gid, effective: Gid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setregid, real, effective)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setregid32, real, effective)
		return Errno(-ret)
	}
}

/*
	Get supplementary group IDs.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
getgroups :: proc "contextless" (gids: []Gid) -> (int, Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_getgroups, len(gids), raw_data(gids))
		return errno_unwrap(ret, int)
	} else {
		ret := syscall(SYS_getgroups32, len(gids), raw_data(gids))
		return errno_unwrap(ret, int)
	}
}

/*
	Set supplementary group IDs.
	Available since Linux 1.0.
	On 32-bit platforms available since Linux 2.4.
*/
setgroups :: proc "contextless" (gids: []Gid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setgroups, len(gids), raw_data(gids))
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setgroups32, len(gids), raw_data(gids))
		return Errno(-ret)
	}
}

/*
	Set real, effective and/or saved user id.
	If any of the arguments is -1, the corresponding id is not changed.
	Available since Linux 2.2.
	On 32-bit platforms available since Linux 2.4.
*/
@(require_results)
setresuid :: proc "contextless" (real: Uid, effective: Uid, saved: Uid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setresuid, real, effective, saved)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setresuid32, real, effective, saved)
		return Errno(-ret)
	}
}

/*
	Get real, effective and saved user id.
	Available since Linux 2.2.
	On 32-bit platforms available since Linux 2.4.
*/
getresuid :: proc "contextless" (real: ^Uid, effective: ^Uid, saved: ^Uid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_getresuid, cast(rawptr) real, cast(rawptr) effective, cast(rawptr) saved)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_getresuid32, cast(rawptr) real, cast(rawptr) effective, cast(rawptr) saved)
		return Errno(-ret)
	}
}

/*
	Set real, effective and/or saved group id.
	If any of the arguments is -1, the corresponding id is not changed.
	Available since Linux 2.2.
	On 32-bit platforms available since Linux 2.4.
*/
@(require_results)
setresgid :: proc "contextless" (real: Gid, effective: Gid, saved: Uid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_setresgid, real, effective, saved)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_setresgid32, real, effective, saved)
		return Errno(-ret)
	}
}

/*
	Get real, effective and saved group id.
	Available since Linux 2.2.
	On 32-bit platforms available since Linux 2.4.
*/
getresgid :: proc "contextless" (real: ^Gid, effective: ^Gid, saved: ^Gid) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_getresgid, cast(rawptr) real, cast(rawptr) effective, cast(rawptr) saved)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_getresgid32, cast(rawptr) real, cast(rawptr) effective, cast(rawptr) saved)
		return Errno(-ret)
	}
}

/*
	Get process group.
	Available since Linux 1.0.
*/
getpgid :: proc "contextless" (pid: Pid) -> (Pid, Errno) {
	ret := syscall(SYS_getpgid, pid)
	return errno_unwrap(ret, Pid)
}

/*
	Get session ID of the calling process.
	Available since Linux 2.0.
*/
getsid :: proc "contextless" (pid: Pid) -> (Pid, Errno) {
	ret := syscall(SYS_getsid, pid)
	return errno_unwrap(ret, Pid)
}

// TODO(flysand): capget

// TODO(flysand): capset

/*
	Examine pending signals.
	Available since Linux 2.2.
*/
rt_sigpending :: proc "contextless" (sigs: ^Sig_Set) -> Errno {
	ret := syscall(SYS_rt_sigpending, sigs, size_of(Sig_Set))
	return Errno(-ret)
}

/*
	Synchronously wait for queued signals.
	Available since Linux 2.2.
*/
rt_sigtimedwait :: proc "contextless" (sigs: ^Sig_Set, info: ^Sig_Info, time_sus: ^Time_Spec) -> (Signal, Errno) {
	ret := syscall(SYS_rt_sigtimedwait, sigs, info, time_sus, size_of(Sig_Set))
	return errno_unwrap(ret, Signal)
}

/*
	Send signal information to a process.
	Available since Linux 2.2.
*/
rt_sigqueueinfo :: proc "contextless" (pid: Pid, sig: Signal, si: ^Sig_Info) -> (Errno) {
	ret := syscall(SYS_rt_sigqueueinfo, pid, sig, si)
	return Errno(-ret)
}

/*
	Replace the signal mask for a value with the new mask until a signal is received.
	Available since Linux 2.2.
*/
rt_sigsuspend :: proc "contextless" (sigset: ^Sig_Set) -> Errno {
	ret := syscall(SYS_rt_sigsuspend, sigset, size_of(Sig_Set))
	return Errno(-ret)
}

/*
	Set or get signal stack context.
	Available since Linux 2.2.
*/
sigaltstack :: proc "contextless" (stack: ^Sig_Stack, old_stack: ^Sig_Stack) -> (Errno) {
	ret := syscall(SYS_sigaltstack, stack, old_stack)
	return Errno(-ret)
}

/*
	Create a special or ordinary file.
	
	`mode` parameter contains both the the file mode and the type of the node to create.
	 ->  Add one of S_IFSOCK, S_IFBLK, S_IFFIFO, S_IFCHR to mode.
	 
	Available since Linux 1.0.
	On ARM64 available since Linux 2.6.16.
*/
mknod :: proc "contextless" (name: cstring, mode: Mode, dev: Dev) -> (Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_mknodat, AT_FDCWD, cast(rawptr) name, transmute(u32) mode, cast(uint) dev)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_mknod, cast(rawptr) name, transmute(u32) mode, cast(uint) dev)
		return Errno(-ret)
	}
}

/*
	Set the process execution domain.
	Available since Linux 1.2.
*/
personality :: proc "contextless" (personality: uint) -> (uint, Errno) {
	ret := syscall(SYS_personality, personality)
	return errno_unwrap(ret, uint)
}

// TODO(flysand): ustat

/*
	Query information about filesystem.
	
	Available since Linux 1.0.
	For 32-bit systems a different syscall is used that became available since 2.6.
*/
statfs :: proc "contextless" (path: cstring, statfs: ^Stat_FS) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_statfs, transmute(uintptr) path, statfs)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_statfs64, cast(rawptr) path, size_of(Stat_FS), statfs)
		return Errno(-ret)
	}
}

/*
	Query information about filesystem by file descriptor.
	
	Available since Linux 1.0.
	For 32-bit systems a different syscall is used that became available since 2.6.
*/
fstatfs :: proc "contextless" (fd: Fd, statfs: ^Stat_FS) -> (Errno) {
	when size_of(int) == 8 {
		ret := syscall(SYS_fstatfs, fd, statfs)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fstatfs64, fd, size_of(Stat_FS), statfs)
		return Errno(-ret)
	}
}

// TODO(flysand): sysfs

/*
	Get priority on user, process group or process.
	Available since Linux 1.0.
*/
getpriority :: proc "contextless" (which: Priority_Which, who: i32) -> (i32, Errno) {
	ret := syscall(SYS_getpriority, which, who)
	prio, err := errno_unwrap(ret, i32)
	// NOTE(flysand): getpriority will return `20 - priority` to avoid returning
	// negative priorities as errors
	prio = 20 - prio
	return prio, err
}

/*
	Set priority on user, process group or process.
	Available since Linux 1.0.
*/
setpriority :: proc "contextless" (which: Priority_Which, who: i32, prio: i32) -> (Errno) {
	ret := syscall(SYS_setpriority, which, who, prio)
	return Errno(-ret)
}

// TODO(flysand): sched_setparam

// TODO(flysand): sched_getparam

// TODO(flysand): sched_setscheduler

// TODO(flysand): sched_getscheduler

// TODO(flysand): sched_get_priority_max

// TODO(flysand): sched_get_priority_min

// TODO(flysand): sched_rr_get_interval

/*
	Lock and memory.
	Available since Linux 2.0.
	If flags specified, available since Linux 4.4.
*/
mlock :: proc "contextless" (addr: rawptr, size: uint, flags: MLock_Flags = {}) -> (Errno) {
	// Pretty darn recent syscall, better call simpler version if we can
	if flags > {} {
		ret := syscall(SYS_mlock2, addr, size, transmute(i32) flags)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_mlock, addr, size)
		return Errno(-ret)
	}
}

/*
	Unlock memory.
	Available since Linux 2.0.
*/
munlock :: proc "contextless" (addr: rawptr, size: uint) -> (Errno) {
	ret := syscall(SYS_munlock, addr, size)
	return Errno(-ret)
}

/*
	Lock all memory.
	Available since Linux 2.0.
*/
mlockall :: proc "contextless" (flags: MLock_Flags = {}) -> (Errno) {
	ret := syscall(SYS_mlockall, transmute(i32) flags)
	return Errno(-ret)
}

/*
	Unlock all memory.
	Available since Linux 2.0.
*/
munlockall :: proc "contextless" () -> (Errno) {
	ret := syscall(SYS_munlockall)
	return Errno(-ret)
}

// TODO(flysand): vhangup

// TODO(flysand): modify_ldt

// TODO(flysand): pivot_root

// TODO(flysand): _sysctl

// TODO(flysand): prctl

// TODO(flysand): arch_prctl

// TODO(flysand): adj_timex

/*
	Set limits on resources.
	Available since Linux 1.0.
*/
setrlimit :: proc "contextless" (kind: RLimit_Kind, resource: ^RLimit) -> (Errno) {
	ret := syscall(SYS_setrlimit, kind, resource)
	return Errno(-ret)
}

// TODO(flysand): sync

// TODO(flysand): acct

// TODO(flysand): settimeofday

// TODO(flysand): mount

// TODO(flysand): umount2

// TODO(flysand): swapon

// TODO(flysand): swapoff

// TODO(flysand): reboot

/*
	Set hostname.
	Note: to get the host name, use `uname` syscall.
	Available since Linux 1.0.
*/
sethostname :: proc "contextless" (hostname: string) -> (Errno) {
	ret := syscall(SYS_sethostname, raw_data(hostname), len(hostname))
	return Errno(-ret)
}

/*
	Set domain name.
	Note: to get the domain name, use `uname` syscall.
	Available since Linux 2.2.
*/
setdomainname :: proc "contextless" (name: string) -> (Errno) {
	ret := syscall(SYS_setdomainname, raw_data(name), len(name))
	return Errno(-ret)
}

// TODO(flysand): iopl

// TODO(flysand): ioperm

// TODO(flysand): init_module

// TODO(flysand): delete_module

// TODO(flysand): quotactl

// TODO(flysand): nfsservctl

// TODO(flysand): getpmsg

// TODO(flysand): putpmsg

// TODO(flysand): afs_syscall

// TODO(flysand): tuxcall

// TODO(flysand): security

/*
	Returns the thread ID of the current process
	This is what the kernel calls "pid".
	Let me insert a tiny rant here, this terminology is confusing:
	sometimes pid refers to a thread, and other times it refers
	to a thread group (process group?)
	Anyway, this syscall is available since Linux 1.0
*/
gettid :: proc "contextless" () -> Pid {
	return cast(Pid) syscall(SYS_gettid)
}

// TODO(flysand): readahead

// TODO(flysand): setxattr

// TODO(flysand): lsetxattr

// TODO(flysand): fsetxattr

// TODO(flysand): getxattr

// TODO(flysand): lgetxattr

// TODO(flysand): fgetxattr

// TODO(flysand): listxattr

// TODO(flysand): llistxattr

// TODO(flysand): flistxattr

// TODO(flysand): removexattr

// TODO(flysand): lremovexattr

// TODO(flysand): fremovexattr

/*
	Get current time in seconds.
	Available since Linux 1.0.
*/
time :: proc "contextless" (tloc: ^uint) -> (Errno) {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		ret := syscall(SYS_time, tloc)
		return Errno(-ret)
	} else {
		ts: Time_Spec
		ret := syscall(SYS_clock_gettime, Clock_Id.REALTIME, &ts)
		tloc^ = ts.time_sec
		return Errno(-ret)
	}
}

/*
	Wait on a futex until it's signaled.
*/
futex_wait :: proc "contextless" (futex: ^Futex, op: Futex_Wait_Type, flags: Futex_Flags, val: u32, timeout: ^Time_Spec = nil) -> (Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, val, timeout)
	return Errno(-ret)
}

/*
	Wake up other threads on a futex
	n_wakeup specifies the number of processes to wakeup. Specify max(i32) to wake up all processes waiting
*/
futex_wake :: proc "contextless" (futex: ^Futex, op: Futex_Wake_Type, flags: Futex_Flags, n_wakeup: i32) -> (int, Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, n_wakeup)
	return errno_unwrap(ret, int)
}

// NOTE(flysand): futex_fd is racy, so not implemented

/*
	Requeues processes waiting on futex `futex` to wait on futex `requeue_futex`
	`requeue_threshold` specifies the maximum amount of waiters to wake up, the rest of the waiters will be requeued
	`requeue_max` specifies the maximum amount of waiters that are required at `requeue_futex`
	The operation blocks until the `requeue_max` requirement is satisfied
	If the value of the mutex is not equal to `val`, fails with EAGAIN before any further checks
	Returns the total number of waiters that have been woken up plus the number of waiters requeued.
*/
futex_cmp_requeue :: proc "contextless" (futex: ^Futex, op: Futex_Cmp_Requeue_Type, flags: Futex_Flags, requeue_threshold: u32,
	requeue_max: i32, requeue_futex: ^Futex, val: i32) -> (int, Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, requeue_threshold, requeue_max, requeue_futex, val)
	return errno_unwrap(ret, int)
}

/*
	See `futex_cmp_requeue`, this function does the same thing but doesn't check the value of the futex.
	Returns the total number of waiters that have been woken up.
*/
futex_requeue :: proc "contextless" (futex: ^Futex, op: Futex_Requeue_Type, flags: Futex_Flags, requeue_threshold: u32,
	requeue_max: i32, requeue_futex: ^Futex) -> (int, Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, requeue_threshold, requeue_max, requeue_futex)
	return errno_unwrap(ret, int)
}

/*
	Okay, for this one, see the man pages, the description for it is pretty long and very specific. It's sole.
	purpose is to allow implementing conditional values sync primitive, it seems like.
*/
futex_wake_op :: proc "contextless" (futex: ^Futex, op: Futex_Wake_Op_Type, flags: Futex_Flags, wakeup: i32,
	dst_wakeup, dst: ^Futex, futex_op: u32) -> (int, Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, wakeup, dst_wakeup, dst, futex_op)
	return errno_unwrap(ret, int)
}

/*
	Same as wait, but mask specifies bits that must be equal for the mutex to wake up.
*/
futex_wait_bitset :: proc "contextless" (futex: ^Futex, op: Futex_Wait_Bitset_Type, flags: Futex_Flags, val: u32,
	timeout: ^Time_Spec, mask: u32) -> (int, Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, val, timeout, 0, mask)
	return errno_unwrap(ret, int)
}

/*
	Wake up on bitset.
*/
futex_wake_bitset :: proc "contextless" (futex: ^Futex, op: Futex_Wake_Bitset_Type, flags: Futex_Flags, n_wakeup: u32, mask: u32) -> (int, Errno) {
	futex_flags := cast(u32) op + transmute(u32) flags
	ret := syscall(SYS_futex, futex, futex_flags, n_wakeup, 0, 0, mask)
	return errno_unwrap(ret, int)
}

// TODO(flysand): Priority inheritance (PI) futicees

futex :: proc{
	futex_wait,
	futex_wake,
	futex_cmp_requeue,
	futex_requeue,
	futex_wake_op,
	futex_wait_bitset,
	futex_wake_bitset,
}

// TODO(flysand): sched_setaffinity

// TODO(flysand): sched_getaffinity

// TODO(flysand): set_thread_area

// TODO(flysand): io_setup

// TODO(flysand): io_destroy

// TODO(flysand): io_getevents

// TODO(flysand): io_submit

// TODO(flysand): io_cancel

// TODO(flysand): get_thread_area

// TODO(flysand): lookup_dcookie

/*
	Open an epoll file descriptor.
	
	The `size` argument is ignored but must be greater than zero.
	
	Available since Linux 2.6.
*/
epoll_create :: proc(size: i32 = 1) -> (Fd, Errno) {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		ret := syscall(SYS_epoll_create, i32(1))
		return errno_unwrap(ret, Fd)
	} else {
		ret := syscall(SYS_epoll_create1, i32(0))
		return errno_unwrap(ret, Fd)
	}
}

// TODO(flysand): remap_file_pages

/*
	Set the address of the futex that's gonna be waken when.
	current thread terminates.
	Available since Linux 2.6.
*/
set_tid_address :: proc "contextless" (tidptr: ^u32) {
	syscall(SYS_set_tid_address, tidptr)
}

// TODO(flysand): semtimedop

// TODO(flysand): fadvise64

/*
	Create POSIX per-process timer.
	Available since Linux 2.6.
*/
timer_create :: proc "contextless" (clock_id: Clock_Id, sigevent: ^Sig_Event, timer: ^Timer) -> (Errno) {
	ret := syscall(SYS_timer_create, clock_id, sigevent, timer)
	return Errno(-ret)
}

/*
	Get the state of the POSIX per-process timer.
	Available since Linux 2.6.
*/
timer_gettime :: proc "contextless" (timer: Timer, curr_value: ^ITimer_Spec) -> (Errno) {
	ret := syscall(SYS_timer_gettime, timer, curr_value)
	return Errno(-ret)
}

/*
	Arm/disarm the state of the POSIX per-process timer.
	Available since Linux 2.6.
*/
timer_settime :: proc "contextless" (timer: Timer, flags: ITimer_Flags, #no_alias new_value, old_value: ^ITimer_Spec) -> (Errno) {
	ret := syscall(SYS_timer_settime, timer, transmute(u32) flags, new_value, old_value)
	return Errno(-ret)
}

/*
	Get overrun count of the POSIX per-process timer.
	Available since Linux 2.6.
*/
timer_getoverrun :: proc "contextless" (timer: Timer) -> (int, Errno) {
	ret := syscall(SYS_timer_getoverrun, timer)
	return errno_unwrap(ret, int)
}

/*
	Delete a POSIX per-process timer.
	Available since Linux 2.6.
*/
timer_delete :: proc "contextless" (timer: Timer) -> (Errno) {
	ret := syscall(SYS_timer_delete, timer)
	return Errno(-ret)
}

/*
	Set the time of the specified clock.
	Available since Linux 2.6.
*/
clock_settime :: proc "contextless" (clock: Clock_Id, ts: ^Time_Spec) -> (Errno) {
	ret := syscall(SYS_clock_settime, clock, ts)
	return Errno(-ret)
}

/*
	Retrieve the time of the specified clock.
	Available since Linux 2.6.
*/
clock_gettime :: proc "contextless" (clock: Clock_Id) -> (ts: Time_Spec, err: Errno) {
	ret := syscall(SYS_clock_gettime, clock, &ts)
	err = Errno(-ret)
	return
}


/*
	Finds the resolution of the specified clock.
	Available since Linux 2.6.
*/
clock_getres :: proc "contextless" (clock: Clock_Id) -> (res: Time_Spec, err: Errno) {
	ret := syscall(SYS_clock_getres, clock, &res)
	err = Errno(-ret)
	return
}

/*
	Sleep for an interval specified with nanosecond precision.
	Available since Linux 2.6.
*/
clock_nanosleep :: proc "contextless" (clock: Clock_Id, flags: ITimer_Flags, request: ^Time_Spec, remain: ^Time_Spec) -> (Errno) {
	ret := syscall(SYS_clock_nanosleep, clock, transmute(u32) flags, request, remain)
	return Errno(-ret)
}

/*
	Exit the thread group.
	Available since Linux 2.6.
*/
exit_group :: proc "contextless" (code: i32) -> ! {
	syscall(SYS_exit_group, code)
	unreachable()
}

/*
	Wait for an I/O event on an epoll file descriptor.
	
	`timeout` is specified in milliseconds.
	
	Available since Linux 2.6.
*/
epoll_wait :: proc(epfd: Fd, events: [^]EPoll_Event, count: i32, timeout: i32) -> (i32, Errno) {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		ret := syscall(SYS_epoll_wait, epfd, events, count, timeout)
		return errno_unwrap(ret, i32)
	} else {
		// Convert milliseconds to nanosecond timespec
		timeout_ns := Time_Spec {
			time_sec = uint(timeout * 1000),
			time_nsec = 0,
		}
		ret := syscall(SYS_epoll_pwait, epfd, events, count, &timeout_ns, rawptr(nil))
		return errno_unwrap(ret, i32)
	}
}

/*
	Control interface for an epoll file descriptor.
	Available since Linux 2.6.
*/
epoll_ctl :: proc(epfd: Fd, op: EPoll_Ctl_Opcode, fd: Fd, event: ^EPoll_Event) -> (Errno) {
	ret := syscall(SYS_epoll_ctl, epfd, op, fd, event)
	return Errno(-ret)
}

/*
	Send a signal to a specific thread in a thread group.
	Available since Linux 2.6.
*/
tgkill :: proc "contextless" (tgid, tid: Pid, sig: Signal) -> (Errno) {
	ret := syscall(SYS_tgkill, tgid, tid, sig)
	return Errno(-ret)
}

// TODO(flysand): utimes

// TODO(flysand): vserver

// TODO(flysand): mbind

// TODO(flysand): set_mempolicy

// TODO(flysand): get_mempolicy

// TODO(flysand): mq_open

// TODO(flysand): mq_unlink

// TODO(flysand): mq_timedsend

// TODO(flysand): mq_timedreceive

// TODO(flysand): mq_notify

// TODO(flysand): mq_getsetattr

// TODO(flysand): kexec_load

/*
	Wait on process, process group or pid file descriptor.
	Available since Linux 2.6.10.
*/
waitid :: proc "contextless" (id_type: Id_Type, id: Id, sig_info: ^Sig_Info, options: Wait_Options, rusage: ^RUsage) -> (Errno) {
	ret := syscall(SYS_waitid, id_type, id, sig_info, transmute(i32) options, rusage)
	return Errno(-ret)
}

// TODO(flysand): add_key

// TODO(flysand): request_key

// TODO(flysand): keyctl

// TODO(flysand): ioprio_set

// TODO(flysand): ioprio_get

inotify_init :: proc "contextless" () -> (Fd, Errno) {
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		ret := syscall(SYS_inotify_init1, 0)
		return errno_unwrap(ret, Fd)
	} else {
		ret := syscall(SYS_inotify_init)
		return errno_unwrap(ret, Fd)
	}
}

inotify_init1 :: proc "contextless" (flags: Inotify_Init_Flags) -> (Fd, Errno) {
	ret := syscall(SYS_inotify_init1, transmute(i32)flags)
	return errno_unwrap(ret, Fd)
}

inotify_add_watch :: proc "contextless" (fd: Fd, pathname: cstring, mask: Inotify_Event_Mask) -> (Wd, Errno) {
	ret := syscall(SYS_inotify_add_watch, fd, transmute(uintptr) pathname, transmute(u32) mask)
	return errno_unwrap(ret, Wd)
}

inotify_rm_watch :: proc "contextless" (fd: Fd, wd: Wd) -> (Errno) {
	ret := syscall(SYS_inotify_rm_watch, fd, wd)
	return Errno(-ret)
}

// TODO(flysand): migrate_pages

/*
	Open file at the specified file descriptor.
	Available since Linux 2.6.16.
*/
openat :: proc "contextless" (fd: Fd, name: cstring, flags: Open_Flags, mode: Mode = {}) -> (Fd, Errno) {
	ret := syscall(SYS_openat, fd, transmute(uintptr) name, transmute(u32) flags, transmute(u32) mode)
	return errno_unwrap(ret, Fd)
}

/*
	Create a directory relative to specified dirfd.
	Available since Linux 2.6.16.
*/
mkdirat :: proc "contextless" (dirfd: Fd, name: cstring, mode: Mode) -> (Errno) {
	ret := syscall(SYS_mkdirat, dirfd, cast(rawptr) name, transmute(u32) mode)
	return Errno(-ret)
}

/*
	Create a special or ordinary file wrt given directory specified by dirfd.
	Available since Linux 2.6.16.
*/
mknodat :: proc "contextless" (dirfd: Fd, name: cstring, mode: Mode, dev: Dev) -> (Errno) {
	ret := syscall(SYS_mknodat, dirfd, cast(rawptr) name, transmute(u32) mode, cast(uint) dev)
	return Errno(-ret)
}

/*
	Change the ownership of the file specified relative to directory.
	Available since Linux 2.6.16.
*/
fchownat :: proc "contextless" (dirfd: Fd, name: cstring, uid: Uid, gid: Gid) -> (Errno) {
	ret := syscall(SYS_fchownat, dirfd, cast(rawptr) name, uid, gid)
	return Errno(-ret)
}

/*
	Get information about a file at a specific directory.
	Available since Linux 2.6.16.
*/
fstatat :: proc "contextless" (dirfd: Fd, name: cstring, stat: ^Stat, flags: FD_Flags) -> (Errno) {
	when size_of(int) == 4 {
		ret := syscall(SYS_fstatat64, dirfd, cast(rawptr) name, stat, transmute(i32) flags)
		return Errno(-ret)
	} else when ODIN_ARCH == .amd64 {
		ret := syscall(SYS_newfstatat, dirfd, cast(rawptr) name, stat, transmute(i32) flags)
		return Errno(-ret)
	} else {
		ret := syscall(SYS_fstatat, dirfd, cast(rawptr) name, stat, transmute(i32) flags)
		return Errno(-ret)
	}
}

/*
	Remove a directory entry relative to a directory file descriptor.
	Available since Linux 2.6.16.
*/
unlinkat :: proc "contextless" (dirfd: Fd, name: cstring, flags: FD_Flags) -> (Errno) {
	ret := syscall(SYS_unlinkat, dirfd, cast(rawptr) name, transmute(i32) flags)
	return Errno(-ret)
}

/*
	Rename the file with names relative to the specified dirfd's.
	Available since Linux 2.6.16.
*/
renameat :: proc "contextless" (oldfd: Fd, old: cstring, newfd: Fd, new: cstring) -> (Errno) {
	ret := syscall(SYS_renameat, oldfd, cast(rawptr) old, newfd, cast(rawptr) new)
	return Errno(-ret)
}

/*
	Creates a hard link on a file relative to specified dirfd.
	Available since Linux 2.6.16.
*/
linkat :: proc "contextless" (target_dirfd: Fd, oldpath: cstring, link_dirfd: Fd, link: cstring, flags: FD_Flags) -> (Errno) {
	ret := syscall(SYS_linkat, target_dirfd, cast(rawptr) oldpath, link_dirfd, cast(rawptr) link, transmute(i32) flags)
	return Errno(-ret)
}

/*
	Create a symbolic link at specified dirfd.
	Available since Linux 2.6.16.
*/
symlinkat :: proc "contextless" (target: cstring, dirfd: Fd, linkpath: cstring) -> (Errno) {
	ret := syscall(SYS_symlinkat, cast(rawptr) target, dirfd, cast(rawptr) linkpath)
	return Errno(-ret)
}

/*
	Read the value of a symbolic link at given dirfd.
	Available since Linux 2.6.16.
*/
readlinkat :: proc "contextless" (dirfd: Fd, name: cstring, buf: []u8) -> (int, Errno) {
	ret := syscall(SYS_readlinkat, dirfd, cast(rawptr) name, raw_data(buf), len(buf))
	return errno_unwrap(ret, int)
}

/*
	Change the file mode at a specified file descriptor.
	Available since Linux 2.6.16.
*/
fchmodat :: proc "contextless" (dirfd: Fd, name: cstring, mode: Mode, flags: FD_Flags) -> (Errno) {
	ret := syscall(SYS_fchmodat, cast(rawptr) name, transmute(u32) mode, transmute(i32) flags)
	return Errno(-ret)
}

/*
	Checks the user permissions for a file at specified dirfd.
	Available since Linux 2.6.16.
*/
faccessat :: proc "contextless" (dirfd: Fd, name: cstring, mode: Mode = F_OK) -> (Errno) {
	ret := syscall(SYS_faccessat, dirfd, cast(rawptr) name, transmute(u32) mode)
	return Errno(-ret)
}

/*
	Wait for events on a file descriptor.
	Available since Linux 2.6.16.
*/
ppoll :: proc "contextless" (fds: []Poll_Fd, timeout: ^Time_Spec, sigmask: ^Sig_Set) -> (i32, Errno) {
	ret := syscall(SYS_ppoll, raw_data(fds), len(fds), timeout, sigmask, size_of(Sig_Set))
	return errno_unwrap(ret, i32)
}

// TODO(flysand): unshare

// TODO(flysand): set_robust_list

// TODO(flysand): get_robust_list

/*
	Transfer the data between file descriptors.
	Available since Linux 2.6.17.
*/
splice :: proc "contextless" (fd_in: Fd, off_in: ^i64, fd_out: Fd, off_out: ^i64, len: uint, flags: Splice_Flags) -> (int, Errno) {
	ret := syscall(SYS_splice, fd_in, off_in, fd_out, off_out, len, transmute(u32) flags)
	return errno_unwrap(ret, int)
}

/*
	Transfer the data between file descriptors.
	Available since Linux 2.6.16.
*/
tee :: proc "contextless" (fd_in: Fd, fd_out: Fd, len: uint, flags: Splice_Flags) -> (int, Errno) {
	ret := syscall(SYS_tee, fd_in, fd_out, len, transmute(u32) flags)
	return errno_unwrap(ret, int)
}

// TODO(flysand): sync_file_range

// TODO(flysand): vmsplice

// TODO(flysand): move_pages

/*
	Change file timestamps with nanosecond precision.
	**utimes** must point to an array of two `Time_Spec`'s. The "utime" is the
	last access time, the second is last modification time.
	Available since Linux 2.6.22.
*/
utimensat :: proc "contextless" (dirfd: Fd, name: cstring, utimes: [^]Time_Spec, flags: FD_Flags) -> (Errno) {
	ret := syscall(SYS_utimensat, dirfd, cast(rawptr) name, utimes, transmute(i32) flags)
	return Errno(-ret)
}

/*
	Wait for an I/O event on an epoll file descriptor.
	Available since Linux 2.6.
*/
epoll_pwait :: proc(epfd: Fd, events: [^]EPoll_Event, count: i32, timeout: i32, sigmask: ^Sig_Set) -> (i32, Errno) {
	ret := syscall(SYS_epoll_pwait, epfd, events, count, timeout, sigmask)
	return errno_unwrap(ret, i32)
}

// TODO(flysand): signalfd

// TODO(flysand): timerfd_create

// TODO(flysand): eventfd

// TODO(flysand): fallocate

// TODO(flysand): timerfd_settime

// TODO(flysand): timerfd_gettime

// TODO(flysand): accept4

// TODO(flysand): signalfd4

// TODO(flysand): eventfd2

epoll_create1 :: proc(flags: EPoll_Flags) -> (Fd, Errno) {
	ret := syscall(SYS_epoll_create1, transmute(i32) flags)
	return errno_unwrap(ret, Fd)
}

/*
	Adjust an existing file descriptor to point to the same file as `old`.
	In addition to dup2 allows to pass O_CLOEXEC flag.
	Available since Linux 2.6.27.
*/
dup3 :: proc "contextless" (old: Fd, new: Fd, flags: Open_Flags) -> (Fd, Errno) {
	ret := syscall(SYS_dup3, old, new, transmute(i32) flags)
	return errno_unwrap(ret, Fd)
}

// TODO(flysand): inotify_init1

// TODO(flysand): preadv

// TODO(flysand): pwritev

/// Send signal information to a thread
/// Available since Linux 2.2
rt_tgsigqueueinfo :: proc "contextless" (tgid: Pid, pid: Pid, sig: Signal, si: ^Sig_Info) -> (Errno) {
	ret := syscall(SYS_rt_tgsigqueueinfo, tgid, pid, sig, si)
	return Errno(-ret)
}

/*
	Set up performance monitoring.
	Available since Linux 2.6.31.
*/
perf_event_open :: proc "contextless" (attr: ^Perf_Event_Attr, pid: Pid, cpu: int, group_fd: Fd, flags: Perf_Flags = {}) -> (Fd, Errno) {
	ret := syscall(SYS_perf_event_open, attr, pid, cpu, group_fd, transmute(uint) flags)
	return errno_unwrap(ret, Fd)
}

/*
	Receive multiple messages from a socket.
	Available since Linux 2.6.33.
*/
recvmmsg :: proc "contextless" (sock: Fd, msg_vec: []MMsg_Hdr, flags: Socket_Msg) -> (int, Errno) {
	ret := syscall(SYS_recvmmsg, sock, raw_data(msg_vec), len(msg_vec), transmute(i32) flags)
	return errno_unwrap(ret, int)
}

// TODO(flysand): fanotify_init

// TODO(flysand): fanotify_mark

// TODO(flysand): prlimit64

// TODO(flysand): name_to_handle_at

// TODO(flysand): open_by_handle_at

// TODO(flysand): clock_adjtime

// TODO(flysand): syncfs

/*
	Send multiple messages on a socket.
	Available since Linux 3.0.
*/
sendmmsg :: proc "contextless" (sock: Fd, msg_vec: []MMsg_Hdr, flags: Socket_Msg) -> (int, Errno) {
	ret := syscall(SYS_sendmmsg, sock, raw_data(msg_vec), len(msg_vec), transmute(i32) flags)
	return errno_unwrap(ret, int)
}

// TODO(flysand): setns

// TODO(flysand): getcpu

// TODO(flysand): process_vm_readv

// TODO(flysand): process_vm_writev

// TODO(flysand): kcmp

// TODO(flysand): finit_module

// TODO(flysand): sched_setattr

// TODO(flysand): sched_getattr

/*
	Rename the file with names relative to the specified dirfd's with other options.
	Available since Linux 3.15.
*/
renameat2 :: proc "contextless" (oldfd: Fd, old: cstring, newfd: Fd, new: cstring, flags: Rename_Flags) -> (Errno) {
	ret := syscall(SYS_renameat2, oldfd, cast(rawptr) old, newfd, cast(rawptr) new, transmute(u32) flags)
	return Errno(-ret)
}

// TODO(flysand): seccomp

getrandom :: proc "contextless" (buf: []u8, flags: Get_Random_Flags) -> (int, Errno) {
	ret := syscall(SYS_getrandom, raw_data(buf), len(buf), transmute(i32) flags)
	return errno_unwrap(ret, int)
}

// TODO(flysand): memfd_create

// TODO(flysand): kexec_file_load

// TODO(flysand): bpf

/*
	Execute program relative to a directory file descriptor.
	Available since Linux 3.19.
*/
execveat :: proc "contextless" (dirfd: Fd, name: cstring, argv: [^]cstring, envp: [^]cstring, flags: Execveat_Flags = {}) -> (Errno) {
	ret := syscall(SYS_execveat, dirfd, cast(rawptr) name, cast(rawptr) argv, cast(rawptr) envp, transmute(i32) flags)
	return Errno(-ret)
}

// TODO(flysand): userfaultfd

// TODO(flysand): membarrier

// TODO(flysand): mlock2

// TODO(flysand): copy_file_range

// TODO(flysand): preadv2

// TODO(flysand): pwritev2

// TODO(flysand): pkey_mprotect

// TODO(flysand): pkey_alloc

// TODO(flysand): pkey_free

/*
	Query extended information about the file

	The file can be specified as:
	- absolute pathname: `dir` parameter is ignored
	- relatvie pathname: `dir` parameter specifies the base directory's fd
	- file descriptor:   `AT_EMPTY_PATH` is passed in flags, pathname is empty, `dir` specifies the file descriptor

	Available since Linux 4.11
*/
statx :: proc "contextless" (dir: Fd, pathname: cstring, flags: FD_Flags, mask: Statx_Mask, statx: ^Statx) -> (Errno) {
	ret := syscall(SYS_statx, dir, transmute(uintptr) pathname, transmute(i32) flags, transmute(u32) mask, statx)
	return Errno(-ret)
}

// TODO(flysand): io_pgetevents

// TODO(flysand): rseq

// TODO(flysand): pidfd_send_signal

// TODO(flysand): io_uring_setup

// TODO(flysand): io_uring_enter

// TODO(flysand): io_uring_register

// TODO(flysand): open_tree

// TODO(flysand): move_mount

// TODO(flysand): fsopen

// TODO(flysand): fsconfig

// TODO(flysand): fsmount

// TODO(flysand): fspick

/*
	Creates a new PID file descriptor.
	The process identified by `pid` must be a pid group leader.
	The returned `pidfd` has `CLOEXEC` semantics.
	Available since Linux 5.3.
*/
pidfd_open :: proc "contextless" (pid: Pid, flags: Pid_FD_Flags) -> (Pid_FD, Errno) {
	ret := syscall(SYS_pidfd_open, pid, transmute(i32) flags)
	return errno_unwrap(ret, Pid_FD)
}

// TODO(flysand): clone3 (probably not this PR)

/*
	Close the range of files as an atomic operation.
	The range of file descriptors is inclusive, and may contain invalid file descriptors.
	Available since Linux 5.9.
*/
close_range :: proc "contextless" (lo: Fd, hi: Fd, flags: Close_Range_Flags) -> (Errno) {
	ret := syscall(SYS_close_range, lo, hi, transmute(u32) flags)
	return Errno(-ret)
}

// TODO(flysand): openat2

/*
	Get a file descriptor from another process.
	- `fd` refers to a file descriptor number to get.
	- `flags` must be zero.
	Available since Linux 5.3.
*/
pidfd_getfd :: proc "contextless" (pidfd: Pid_FD, fd: Fd, flags: i32 = 0) -> (Fd, Errno) {
	ret := syscall(SYS_pidfd_getfd, pidfd, fd, flags)
	return errno_unwrap(ret, Fd)
}

/*
	Checks the user permissions for a file at specified dirfd (with flags).
	Available since Linux 5.8.
*/
faccessat2 :: proc "contextless" (dirfd: Fd, name: cstring, mode: Mode = F_OK, flags: FD_Flags = FD_Flags{}) -> (Errno) {
	ret := syscall(SYS_faccessat2, dirfd, cast(rawptr) name, transmute(u32) mode, transmute(i32) flags)
	return Errno(-ret)
}

// TODO(flysand): process_madvise

/*
	Wait for an I/O event on an epoll file descriptor.
	Available since Linux 2.6.
*/
epoll_pwait2 :: proc(epfd: Fd, events: [^]EPoll_Event, count: i32, timeout: ^Time_Spec, sigmask: ^Sig_Set) -> (i32, Errno) {
	ret := syscall(SYS_epoll_pwait2, epfd, events, count, timeout, sigmask)
	return errno_unwrap(ret, i32)
}

// TODO(flysand): mount_setattr

// TODO(flysand): quotactl_fd

// TODO(flysand): landlock_create_ruleset

// TODO(flysand): landlock_add_rule

// TODO(flysand): landlock_restrict_self

// TODO(flysand): memfd_secret

// TODO(flysand): process_mrelease

// TODO(flysand): futex_waitv

// TODO(flysand): set_mempolicy_home_node

// TODO(flysand): cachestat

// TODO(flysand): fchmodat2

// TODO(flysand): map_shadow_stack

when ODIN_ARCH == .riscv64 {
	/*
		Probe for RISC-V Hardware Support.
		Available since Linux 6.4.

		TODO: cpu_set_t

		See: https://docs.kernel.org/arch/riscv/hwprobe.html
	*/
	riscv_hwprobe :: proc "contextless" (pairs: [^]RISCV_HWProbe, pair_count: uint, cpu_count: uint, cpus: rawptr /* cpu_set_t */, flags: RISCV_HWProbe_Flags) -> Errno {
		ret := syscall(SYS_riscv_hwprobe, pairs, pair_count, cpu_count, cpus, transmute(u32)flags)
		return Errno(-ret)
	}
}
