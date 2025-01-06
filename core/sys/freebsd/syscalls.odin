package sys_freebsd

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "base:intrinsics"
import "core:c"

// FreeBSD 15 syscall numbers
// See: https://alfonsosiciliano.gitlab.io/posts/2023-08-28-freebsd-15-system-calls.html

SYS_read       : uintptr : 3
SYS_write      : uintptr : 4
SYS_open       : uintptr : 5
SYS_close      : uintptr : 6
SYS_getpid     : uintptr : 20
SYS_recvfrom   : uintptr : 29
SYS_accept     : uintptr : 30
SYS_getsockname: uintptr : 32
SYS_fcntl      : uintptr : 92
SYS_fsync      : uintptr : 95
SYS_socket     : uintptr : 97
SYS_connect    : uintptr : 98
SYS_bind       : uintptr : 104
SYS_listen     : uintptr : 106
SYS_sendto     : uintptr : 133
SYS_shutdown   : uintptr : 134
SYS_setsockopt : uintptr : 105
SYS_sysctl     : uintptr : 202
SYS__umtx_op   : uintptr : 454
SYS_pread      : uintptr : 475
SYS_pwrite     : uintptr : 476
SYS_accept4    : uintptr : 541

//
// Odin syscall wrappers
//

// Read input.
//
// The read() function appeared in Version 1 AT&T UNIX.
read :: proc "contextless" (fd: Fd, buf: []u8) -> (int, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_read,
		cast(uintptr)fd,
		cast(uintptr)raw_data(buf),
		cast(uintptr)len(buf))

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Write output.
//
// The write() function appeared in Version 1 AT&T UNIX.
write :: proc "contextless" (fd: Fd, buf: []u8) -> (int, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_pwrite,
		cast(uintptr)fd,
		cast(uintptr)raw_data(buf),
		cast(uintptr)len(buf))

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Open or create a file for reading, writing or executing.
//
// The open() function appeared in Version 1 AT&T UNIX.
// The openat() function was introduced in FreeBSD 8.0.
open :: proc "contextless" (path: string, flags: File_Status_Flags, mode: int = 0o000) -> (Fd, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_open,
		cast(uintptr)raw_data(path),
		cast(uintptr)transmute(c.int)flags,
		cast(uintptr)mode)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(Fd)result, nil
}

// Delete a descriptor.
//
// The open() function appeared in Version 1 AT&T UNIX.
close :: proc "contextless" (fd: Fd) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_close,
		cast(uintptr)fd)

	return cast(Errno)result
}

// Get parent or calling process identification.
//
// The getpid() function appeared in Version 7 AT&T UNIX.
getpid :: proc "contextless" () -> pid_t {
	// This always succeeds.
	result, _ := intrinsics.syscall_bsd(SYS_getpid)
	return cast(pid_t)result
}

// Receive message(s) from a socket.
//
// The recv() function appeared in 4.2BSD.
// The recvmmsg() function appeared in FreeBSD 11.0.
recvfrom :: proc "contextless" (s: Fd, buf: []u8, flags: Recv_Flags, from: ^$T) -> (int, Errno)
where
	intrinsics.type_is_subtype_of(T, Socket_Address_Header)
{
	fromlen: socklen_t = size_of(T)

	result, ok := intrinsics.syscall_bsd(SYS_recvfrom,
		cast(uintptr)s,
		cast(uintptr)raw_data(buf),
		cast(uintptr)len(buf),
		cast(uintptr)flags,
		cast(uintptr)from,
		cast(uintptr)&fromlen)

	// `from.len` will be modified by the syscall, so we shouldn't need to pass
	// `fromlen` back from this API.

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Receive message(s) from a socket.
//
// The recv() function appeared in 4.2BSD.
// The recvmmsg() function appeared in FreeBSD 11.0.
recv :: proc "contextless" (s: Fd, buf: []u8, flags: Recv_Flags) -> (int, Errno) {
	// This is a wrapper over recvfrom().
	result, ok := intrinsics.syscall_bsd(SYS_recvfrom,
		cast(uintptr)s,
		cast(uintptr)raw_data(buf),
		cast(uintptr)len(buf),
		cast(uintptr)flags,
		0,
		0)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Accept a connection on a socket.
//
// The accept() system call appeared in 4.2BSD.
accept_T :: proc "contextless" (s: Fd, sockaddr: ^$T) -> (Fd, Errno)
where
	intrinsics.type_is_subtype_of(T, Socket_Address_Header)
{
	// sockaddr must contain a valid pointer, or this will segfault because
	// we're telling the syscall that there's memory available to write to.
	addrlen: socklen_t = size_of(T)

	result, ok := intrinsics.syscall_bsd(SYS_accept,
		cast(uintptr)s,
		cast(uintptr)sockaddr,
		cast(uintptr)&addrlen)

	if !ok {
		return 0, cast(Errno)result
	}

	sockaddr.len = cast(u8)addrlen

	return cast(Fd)result, nil
}


// Accept a connection on a socket.
//
// The accept() system call appeared in 4.2BSD.
accept_nil :: proc "contextless" (s: Fd) -> (Fd, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_accept,
		cast(uintptr)s,
		cast(uintptr)0,
		cast(uintptr)0)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(Fd)result, nil
}

accept :: proc { accept_T, accept_nil }

// Get socket name.
//
// The getsockname() system call appeared in 4.2BSD.
getsockname :: proc "contextless" (s: Fd, sockaddr: ^$T) -> Errno {
	// sockaddr must contain a valid pointer, or this will segfault because
	// we're telling the syscall that there's memory available to write to.
	addrlen: socklen_t = size_of(T)

	result, ok := intrinsics.syscall_bsd(SYS_getsockname,
		cast(uintptr)s,
		cast(uintptr)sockaddr,
		cast(uintptr)&addrlen)

	if !ok {
		return cast(Errno)result
	}

	return nil
}

// Synchronize changes to a file.
//
// The fsync() system call appeared in 4.2BSD.
fsync :: proc "contextless" (fd: Fd) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fsync,
		cast(uintptr)fd)

	return cast(Errno)result
}

// File control.
//
// The fcntl() system call appeared in 4.2BSD.
// The F_DUP2FD constant first appeared in FreeBSD 7.1.
//
// NOTE: If you know at compile-time what command you're calling, use one of the
// `fcntl_*` procedures instead to preserve type safety.
fcntl :: proc "contextless" (fd: Fd, cmd: File_Control_Command, arg: c.int) -> (int, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)cmd,
		cast(uintptr)arg)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// TODO: Implement more type-safe fcntl commands.

fcntl_dupfd :: proc "contextless" (fd: Fd, newfd: Fd) -> (Fd, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.DUPFD,
		cast(uintptr)newfd)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(Fd)result, nil
}

fcntl_getfd :: proc "contextless" (fd: Fd) -> (bool, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.GETFD)

	if !ok {
		return false, cast(Errno)result
	}

	return result & FD_CLOEXEC > 0, nil
}

fcntl_setfd :: proc "contextless" (fd: Fd, close_on_exec: bool) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.SETFD,
		(close_on_exec ? FD_CLOEXEC : 0))

	return cast(Errno)result
}

fcntl_getfl :: proc "contextless" (fd: Fd) -> (File_Status_Flags, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.GETFL)

	if !ok {
		return nil, cast(Errno)result
	}

	return transmute(File_Status_Flags)cast(c.int)result, nil
}

fcntl_setfl :: proc "contextless" (fd: Fd, flags: File_Status_Flags) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.SETFL,
		cast(uintptr)transmute(c.int)flags)

	return cast(Errno)result
}

fcntl_getown :: proc "contextless" (fd: Fd) -> (pid_t, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.GETOWN)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(pid_t)result, nil
}

fcntl_setown :: proc "contextless" (fd: Fd, pid: pid_t) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.SETOWN,
		cast(uintptr)pid)

	return cast(Errno)result
}

fcntl_getlk :: proc "contextless" (fd: Fd, flock: ^File_Lock) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.GETLK,
		cast(uintptr)flock)

	return cast(Errno)result
}

fcntl_setlk :: proc "contextless" (fd: Fd, flock: ^File_Lock) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.SETLK,
		cast(uintptr)flock)

	return cast(Errno)result
}

fcntl_add_seals :: proc "contextless" (fd: Fd, seals: File_Seals) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.ADD_SEALS,
		cast(uintptr)transmute(c.int)seals)

	return cast(Errno)result
}

fcntl_get_seals :: proc "contextless" (fd: Fd) -> (File_Seals, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_fcntl,
		cast(uintptr)fd,
		cast(uintptr)File_Control_Command.GET_SEALS)

	if !ok {
		return nil, cast(Errno)result
	}

	return transmute(File_Seals)cast(c.int)result, nil
}

//
// End type-safe fcntl commands.
//

// Create an endpoint for communication.
//
// The socket() system call appeared in 4.2BSD.
socket :: proc "contextless" (domain: Protocol_Family, type: Socket_Type, protocol: Protocol) -> (Fd, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_socket,
		cast(uintptr)domain,
		cast(uintptr)type,
		cast(uintptr)protocol)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(Fd)result, nil
}

// Initiate a connection on a socket.
//
// The connect() system call appeared in 4.2BSD.
connect :: proc "contextless" (fd: Fd, sockaddr: ^$T, addrlen: socklen_t) -> Errno
where
	intrinsics.type_is_subtype_of(T, Socket_Address_Header)
{
	result, _ := intrinsics.syscall_bsd(SYS_connect,
		cast(uintptr)fd,
		cast(uintptr)sockaddr,
		cast(uintptr)addrlen)

	return cast(Errno)result
}


// Assign a local protocol address to a socket.
//
// The bind() system call appeared in 4.2BSD.
bind :: proc "contextless" (s: Fd, sockaddr: ^$T, addrlen: socklen_t) -> Errno
where
	intrinsics.type_is_subtype_of(T, Socket_Address_Header)
{
	result, _ := intrinsics.syscall_bsd(SYS_bind,
		cast(uintptr)s,
		cast(uintptr)sockaddr,
		cast(uintptr)addrlen)

	return cast(Errno)result
}

// Listen for connections on a socket.
//
// The listen() system call appeared in 4.2BSD.
listen :: proc "contextless" (s: Fd, backlog: int) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_listen,
		cast(uintptr)s,
		cast(uintptr)backlog)

	return cast(Errno)result
}

// Send message(s) from a socket.
//
// The send() function appeared in 4.2BSD.
// The sendmmsg() function appeared in FreeBSD 11.0.
sendto :: proc "contextless" (s: Fd, msg: []u8, flags: Send_Flags, to: ^$T) -> (int, Errno)
where
	intrinsics.type_is_subtype_of(T, Socket_Address_Header)
{
	result, ok := intrinsics.syscall_bsd(SYS_sendto,
		cast(uintptr)s,
		cast(uintptr)raw_data(msg),
		cast(uintptr)len(msg),
		cast(uintptr)flags,
		cast(uintptr)to,
		cast(uintptr)to.len)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Send message(s) from a socket.
//
// The send() function appeared in 4.2BSD.
// The sendmmsg() function appeared in FreeBSD 11.0.
send :: proc "contextless" (s: Fd, msg: []u8, flags: Send_Flags) -> (int, Errno) {
	// This is a wrapper over sendto().
	result, ok := intrinsics.syscall_bsd(SYS_sendto,
		cast(uintptr)s,
		cast(uintptr)raw_data(msg),
		cast(uintptr)len(msg),
		cast(uintptr)flags,
		0,
		0)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Disable sends and/or receives on a socket.
//
// The shutdown() system call appeared in 4.2BSD.
shutdown :: proc "contextless" (s: Fd, how: Shutdown_Method) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_shutdown,
		cast(uintptr)s,
		cast(uintptr)how)

	return cast(Errno)result
}

// Get and set options on sockets.
//
// The getsockopt() and setsockopt() system calls appeared in 4.2BSD.
setsockopt :: proc "contextless" (s: Fd, level: Valid_Socket_Option_Level, optname: Socket_Option, optval: rawptr, optlen: socklen_t) -> Errno {
	real_level: uintptr
	switch which in level {
	case Protocol_Family:     real_level = cast(uintptr)which
	case Socket_Option_Level: real_level = cast(uintptr)which
	}

	result, _ := intrinsics.syscall_bsd(SYS_setsockopt,
		cast(uintptr)s,
		real_level,
		cast(uintptr)optname,
		cast(uintptr)optval,
		cast(uintptr)optlen)

	return cast(Errno)result
}

// Get or set system information.
//
// The sysctl() function first appeared in 4.4BSD.
sysctl :: proc "contextless" (mib: []MIB_Identifier, oldp: rawptr, oldlenp: ^c.size_t, newp: rawptr, newlen: c.size_t) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS_sysctl,
		cast(uintptr)raw_data(mib),
		cast(uintptr)len(mib),
		cast(uintptr)oldp,
		cast(uintptr)oldlenp,
		cast(uintptr)newp,
		cast(uintptr)newlen)

	return cast(Errno)result
}

// Interface for implementation of userspace threading synchronization primitives.
//
// The _umtx_op() system call is non-standard and is used by the 1:1 Threading
// Library (libthr, -lthr) to implement IEEE Std 1003.1-2001 (“POSIX.1”)
// pthread(3) functionality.
_umtx_op :: proc "contextless" (obj: rawptr, op: Userland_Mutex_Operation, val: c.ulong, uaddr, uaddr2: rawptr) -> Errno {
	result, _ := intrinsics.syscall_bsd(SYS__umtx_op,
		cast(uintptr)obj,
		cast(uintptr)op,
		cast(uintptr)val,
		cast(uintptr)uaddr,
		cast(uintptr)uaddr2)

	return cast(Errno)result
}

// Read input without modifying the file pointer.
//
// The pread() function appeared in AT&T System V Release 4 UNIX.
pread :: proc "contextless" (fd: Fd, buf: []u8, offset: off_t) -> (int, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_pread,
		cast(uintptr)fd,
		cast(uintptr)raw_data(buf),
		cast(uintptr)len(buf),
		cast(uintptr)offset)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Write output without modifying the file pointer.
//
// The pwrite() function appeared in AT&T System V Release 4 UNIX.
//
// BUGS
//
// The pwrite() system call appends the file without changing the file
// offset if O_APPEND is set, contrary to IEEE Std 1003.1-2008 (“POSIX.1”)
// where pwrite() writes into offset regardless of whether O_APPEND is set.
pwrite :: proc "contextless" (fd: Fd, buf: []u8, offset: off_t) -> (int, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_pwrite,
		cast(uintptr)fd,
		cast(uintptr)raw_data(buf),
		cast(uintptr)len(buf),
		cast(uintptr)offset)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(int)result, nil
}

// Accept a connection on a socket.
//
// The accept4() system call appeared in FreeBSD 10.0.
accept4_T :: proc "contextless" (s: Fd, sockaddr: ^$T, flags: Socket_Flags = {}) -> (Fd, Errno)
where
	intrinsics.type_is_subtype_of(T, Socket_Address_Header)
{
	// `sockaddr` must contain a valid pointer, or this will segfault because
	// we're telling the syscall that there's memory available to write to.
	addrlen: u32 = size_of(T)

	result, ok := intrinsics.syscall_bsd(SYS_accept4,
		cast(uintptr)s,
		cast(uintptr)sockaddr,
		cast(uintptr)&addrlen,
		cast(uintptr)transmute(c.int)flags)

	if !ok {
		return 0, cast(Errno)result
	}

	sockaddr.len = cast(u8)addrlen

	return cast(Fd)result, nil
}

// Accept a connection on a socket.
//
// The accept4() system call appeared in FreeBSD 10.0.
accept4_nil :: proc "contextless" (s: Fd, flags: Socket_Flags = {}) -> (Fd, Errno) {
	result, ok := intrinsics.syscall_bsd(SYS_accept4,
		cast(uintptr)s,
		cast(uintptr)0,
		cast(uintptr)0,
		cast(uintptr)transmute(c.int)flags)

	if !ok {
		return 0, cast(Errno)result
	}

	return cast(Fd)result, nil
}

accept4 :: proc { accept4_nil, accept4_T }
