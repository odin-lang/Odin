package uring

import "core:sys/linux"

// Do not perform any I/O. This is useful for testing the performance of the uring implementation itself.
nop :: proc(ring: ^Ring, user_data: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .NOP
	sqe.user_data = user_data

	ok = true
	return
}

// Vectored read operation, see also readv(2).
readv :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, iovs: []linux.IO_Vec, off: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .READV
	sqe.fd = fd
	sqe.addr = cast(u64)uintptr(raw_data(iovs))
	sqe.len = u32(len(iovs))
	sqe.off = off
	sqe.user_data = user_data

	ok = true
	return
}

// Vectored write operation, see also writev(2).
writev :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, iovs: []linux.IO_Vec, off: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .WRITEV
	sqe.fd = fd
	sqe.addr = cast(u64)uintptr(raw_data(iovs))
	sqe.len = u32(len(iovs))
	sqe.off = off
	sqe.user_data = user_data

	ok = true
	return
}

read_fixed :: proc() {
	unimplemented()
}

write_fixed :: proc() {
	unimplemented()
}

/*
File sync. See also fsync(2).

Optionally off and len can be used to specify a range within the file to be synced rather than syncing the entire file, which is the default behavior.

Note that, while I/O is initiated in the order in which it appears in the submission queue, completions are unordered.
For example, an application which places a write I/O followed by an fsync in the submission queue cannot expect the fsync to apply to the write.
The two operations execute in parallel, so the fsync may complete before the write is issued to the storage.
The same is also true for previously issued writes that have not completed prior to the fsync.
To enforce ordering one may utilize linked SQEs,
IOSQE_IO_DRAIN or wait for the arrival of CQEs of requests which have to be ordered before a given request before submitting its SQE.
*/
fsync :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, flags: linux.IO_Uring_Fsync_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .FSYNC
	sqe.fsync_flags = flags
	sqe.fd = fd
	sqe.user_data = user_data

	ok = true
	return
}

/*
Poll the fd specified in the submission queue entry for the events specified in the poll_events field.

Unlike poll or epoll without EPOLLONESHOT, by default this interface always works in one shot mode.
That is, once the poll operation is completed, it will have to be resubmitted.

If IORING_POLL_ADD_MULTI is set in the SQE len field, then the poll will work in multi shot mode instead.
That means it'll repatedly trigger when the requested event becomes true, and hence multiple CQEs can be generated from this single SQE.
The CQE flags field will have IORING_CQE_F_MORE set on completion if the application should expect further CQE entries from the original request.
If this flag isn't set on completion, then the poll request has been terminated and no further events will be generated.
This mode is available since 5.13.

This command works like an async poll(2) and the completion event result is the returned mask of events.

Without IORING_POLL_ADD_MULTI and the initial poll operation with IORING_POLL_ADD_MULTI the operation is level triggered,
i.e. if there is data ready or events pending etc.
at the time of submission a corresponding CQE will be posted.
Potential further completions beyond the first caused by a IORING_POLL_ADD_MULTI are edge triggered.
*/
poll_add :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, events: linux.Fd_Poll_Events, flags: linux.IO_Uring_Poll_Add_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .POLL_ADD
	sqe.fd = fd
	sqe.poll_events = events
	sqe.poll_flags = flags
	sqe.user_data = user_data

	ok = true
	return
}

/*
Remove an existing poll request.

If found, the res field of the struct io_uring_cqe will contain 0.
If not found, res will contain -ENOENT, or -EALREADY if the poll request was in the process of completing already.
*/
poll_remove :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, events: linux.Fd_Poll_Events) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .POLL_REMOVE
	sqe.fd = fd
	sqe.poll_events = events
	sqe.user_data = user_data

	ok = true
	return
}

/*
Update the events of an existing poll request.

The request will update an existing poll request with the mask of events passed in with this request.
The lookup is based on the user_data field of the original SQE submitted.

Updating an existing poll is available since 5.13.
*/
poll_update_events :: proc(ring: ^Ring, user_data: u64, orig_user_data: u64, fd: linux.Fd, events: linux.Fd_Poll_Events) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .POLL_REMOVE
	sqe.fd = fd
	sqe.addr = orig_user_data
	sqe.poll_events = events
	sqe.user_data = user_data
	sqe.poll_flags = {.UPDATE_EVENTS}

	ok = true
	return
}

/*
Update the user data of an existing poll request.

The request will update the user_data of an existing poll request based on the value passed.

Updating an existing poll is available since 5.13.
*/
poll_update_user_data :: proc(ring: ^Ring, user_data: u64, orig_user_data: u64, new_user_data: u64, fd: linux.Fd) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .POLL_REMOVE
	sqe.fd = fd
	sqe.off = orig_user_data
	sqe.addr = new_user_data
	sqe.user_data = user_data
	sqe.poll_flags = {.UPDATE_USER_DATA}

	ok = true
	return
}

/*
Add, remove or modify entries in the interest list of epoll(7).

See epoll_ctl(2) for details of the system call.

Available since 5.6.
*/
epoll_ctl :: proc(ring: ^Ring, user_data: u64, epfd: linux.Fd, op: linux.EPoll_Ctl_Opcode, fd: linux.Fd, event: ^linux.EPoll_Event) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .EPOLL_CTL
	sqe.fd = epfd
	sqe.off = u64(fd)
	sqe.epoll_ctl_op = op
	sqe.addr = cast(u64)uintptr(event)
	sqe.user_data = user_data

	ok = true
	return
}

sync_file_range :: proc() {
	unimplemented()
}

/*
Issue the equivalent of a sendmsg(2) system call.

See also sendmsg(2) for the general description of the related system call.

poll_first: if set, uring will assume the socket is currently full and attempting to send data will be unsuccessful.
For this case, uring will arm internal poll and trigger a send of the data when there is enough space available.
This initial send attempt can be wasteful for the case where the socket is expected to be full, setting this flag will
bypass the initial send attempt and go straight to arming poll.
If poll does indicate that data can be sent, the operation will proceed.

Available since 5.3.
*/
sendmsg :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, msghdr: ^linux.Msg_Hdr, flags: linux.Socket_Msg, poll_first := false) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .SENDMSG
	sqe.fd = fd
	sqe.addr = cast(u64)uintptr(msghdr)
	sqe.msg_flags = flags
	sqe.user_data = user_data
	sqe.sq_send_recv_flags = {.RECVSEND_POLL_FIRST} if poll_first else {}

	ok = true
	return
}

/*
Works just like sendmsg, but receives instead of sends.

poll_first: If set, uring will assume the socket is currently empty and attempting to receive data will be unsuccessful.
For this case, uring will arm internal poll and trigger a receive of the data when the socket has data to be read.
This initial receive attempt can be wasteful for the case where the socket is expected to be empty, setting this flag will bypass the initial receive attempt and go straight to arming poll.
If poll does indicate that data is ready to be received, the operation will proceed.

Available since 5.3.
*/
recvmsg :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, msghdr: ^linux.Msg_Hdr, flags: linux.Socket_Msg, poll_first := false) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .RECVMSG
	sqe.fd = fd
	sqe.addr = cast(u64)uintptr(msghdr)
	sqe.msg_flags = flags
	sqe.user_data = user_data
	sqe.sq_send_recv_flags = {.RECVSEND_POLL_FIRST} if poll_first else {}

	ok = true
	return
}

/*
Issue the equivalent of a send(2) system call.

See also send(2) for the general description of the related system call.

poll_first: If set, uring will assume the socket is currently full and attempting to send data will be unsuccessful.
For this case, uring will arm internal poll and trigger a send of the data when there is enough space available.
This initial send attempt can be wasteful for the case where the socket is expected to be full, setting this flag will bypass the initial send attempt and go straight to arming poll.
If poll does indicate that data can be sent, the operation will proceed.

Available since 5.6.
*/
send :: proc(ring: ^Ring, user_data: u64, sockfd: linux.Fd, buf: []byte, flags: linux.Socket_Msg, poll_first := false) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .SEND
	sqe.fd = sockfd
	sqe.addr = cast(u64)uintptr(raw_data(buf))
	sqe.len = u32(len(buf))
	sqe.msg_flags = flags
	sqe.user_data = user_data
	sqe.sq_send_recv_flags = {.RECVSEND_POLL_FIRST} if poll_first else {}

	ok = true
	return
}

sendto :: proc(ring: ^Ring, user_data: u64, sockfd: linux.Fd, buf: []byte, flags: linux.Socket_Msg, dest: ^$T, poll_first := false) -> (sqe: ^linux.IO_Uring_SQE, ok: bool)
	where T == linux.Sock_Addr_In || T == linux.Sock_Addr_In6 || T == linux.Sock_Addr_Un || T == linux.Sock_Addr_Any {

	sqe = send(ring, user_data, sockfd, buf, flags, poll_first) or_return
	sqe.addr2 = u64(uintptr(dest))
	sqe.addr_len = u16(size_of(T))

	ok = true
	return
}

/*
Works just like send, but receives instead of sends.

poll_first: If set, uring will assume the socket is currently empty and attempting to receive data will be unsuccessful.
For this case, uring will arm internal poll and trigger a receive of the data when the socket has data to be read.
This initial receive attempt can be wasteful for the case where the socket is expected to be empty, setting this flag will bypass the initial receive attempt and go straight to arming poll.
If poll does indicate that data is ready to be received, the operation will proceed.

Available since 5.6.
*/
recv :: proc(ring: ^Ring, user_data: u64, sockfd: linux.Fd, buf: []byte, flags: linux.Socket_Msg, poll_first := false) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .RECV
	sqe.fd = sockfd
	sqe.addr = cast(u64)uintptr(raw_data(buf))
	sqe.len = cast(u32)uintptr(len(buf))
	sqe.msg_flags = flags
	sqe.user_data = user_data
	sqe.sq_send_recv_flags = {.RECVSEND_POLL_FIRST} if poll_first else {}

	ok = true
	return
}

/*
Register a timeout operation.

The timeout will complete when either the timeout expires, or after the specified number of
events complete (if `count` is greater than `0`).

`flags` may be `0` for a relative timeout, or `IORING_TIMEOUT_ABS` for an absolute timeout.

The completion event result will be `-ETIME` if the timeout completed through expiration,
`0` if the timeout completed after the specified number of events, or `-ECANCELED` if the
timeout was removed before it expired.

uring timeouts use the `CLOCK.MONOTONIC` clock source.
*/
timeout :: proc(ring: ^Ring, user_data: u64, ts: ^linux.Time_Spec, count: u32, flags: linux.IO_Uring_Timeout_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .TIMEOUT
	sqe.fd = -1
	sqe.addr = cast(u64)uintptr(ts)
	sqe.len = 1
	sqe.off = u64(count)
	sqe.timeout_flags = flags
	sqe.user_data = user_data

	ok = true
	return
}

/*
Rmove an existing timeout operation.

The timeout is identified by it's `user_data`.

The completion event result will be `0` if the timeout was found and cancelled successfully,
`-EBUSY` if the timeout was found but expiration was already in progress, or
`-ENOENT` if the timeout was not found.
*/
timeout_remove :: proc(ring: ^Ring, user_data: u64, timeout_user_data: u64, flags: linux.IO_Uring_Timeout_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .TIMEOUT_REMOVE
	sqe.fd = -1
	sqe.addr = timeout_user_data
	sqe.timeout_flags = flags
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of an accept4(2) system call.

See also accept4(2) for the general description of the related system call.

If the file_index field is set to a positive number, the file won't be installed into the normal file table as usual
but will be placed into the fixed file table at index file_index - 1.
In this case, instead of returning a file descriptor, the result will contain either 0 on success or an error.
If the index points to a valid empty slot, the installation is guaranteed to not fail.
If there is already a file in the slot, it will be replaced, similar to IORING_OP_FILES_UPDATE.
Please note that only uring has access to such files and no other syscall can use them. See IOSQE_FIXED_FILE and IORING_REGISTER_FILES.

Available since 5.5.
*/
accept :: proc(ring: ^Ring, user_data: u64, sockfd: linux.Fd, addr: ^$T, addr_len: ^i32, flags: linux.Socket_FD_Flags, file_index: u32 = 0) -> (sqe: ^linux.IO_Uring_SQE, ok: bool)
where T == linux.Sock_Addr_In || T == linux.Sock_Addr_In6 || T == linux.Sock_Addr_Un || T == linux.Sock_Addr_Any {

	sqe = get_sqe(ring) or_return
	sqe.opcode = .ACCEPT
	sqe.fd = sockfd
	sqe.addr = cast(u64)uintptr(addr)
	sqe.off = cast(u64)uintptr(addr_len)
	sqe.accept_flags = flags
	sqe.user_data = user_data
	sqe.file_index = file_index

	ok = true
	return
}

/*
Attempt to cancel an already issued request.

The request is identified by it's user data.

The cancelation request will complete with one of the following results codes.

If found, the res field of the cqe will contain 0.
If not found, res will contain -ENOENT.

If found and attempted canceled, the res field will contain -EALREADY.
In this case, the request may or may not terminate.
In general, requests that are interruptible (like socket IO) will get canceled, while disk IO requests cannot be canceled if already started.

Available since 5.5.
*/
async_cancel :: proc(ring: ^Ring, orig_user_data: u64, user_data: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .ASYNC_CANCEL
	sqe.addr = orig_user_data
	sqe.user_data = user_data

	ok = true
	return
}

/*
Adds a link timeout operation.

You need to set linux.IOSQE_IO_LINK to flags of the target operation
and then call this method right after the target operation.
See https://lwn.net/Articles/803932/ for detail.

If the dependent request finishes before the linked timeout, the timeout
is canceled. If the timeout finishes before the dependent request, the
dependent request will be canceled.

The completion event result of the link_timeout will be
`-ETIME` if the timeout finishes before the dependent request
(in this case, the completion event result of the dependent request will
be `-ECANCELED`), or
`-EALREADY` if the dependent request finishes before the linked timeout.

Available since 5.5.
*/
link_timeout :: proc(ring: ^Ring, user_data: u64, ts: ^linux.Time_Spec, flags: linux.IO_Uring_Timeout_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring, 0) or_return
	sqe.opcode = .LINK_TIMEOUT
	sqe.fd = -1
	sqe.addr = cast(u64)uintptr(ts)
	sqe.len = 1
	sqe.timeout_flags = flags
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of a connect(2) system call.

See also connect(2) for the general description of the related system call.

Available since 5.5.
*/
connect :: proc(ring: ^Ring, user_data: u64, sockfd: linux.Fd, addr: ^$T) -> (sqe: ^linux.IO_Uring_SQE, ok: bool)
where T == linux.Sock_Addr_In || T == linux.Sock_Addr_In6 || T == linux.Sock_Addr_Un || T == linux.Sock_Addr_Any {

	sqe = get_sqe(ring) or_return
	sqe.opcode = .CONNECT
	sqe.fd = sockfd
	sqe.addr = cast(u64)uintptr(addr)
	sqe.off = size_of(T)
	sqe.user_data = user_data

	ok = true
	return
}

fallocate :: proc() {
	unimplemented()
}

fadvise :: proc() {
	unimplemented()
}

/*
Issue the equivalent of a madvise(2) system call.

See also madvise(2) for the general description of the related system call.

Available since 5.6.
*/
madvise :: proc(ring: ^Ring, user_data: u64, addr: rawptr, size: u32, advise: linux.MAdvice) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .MADVISE
	sqe.addr = u64(uintptr(addr))
	sqe.len = size
	sqe.fadvise_advice = cast(u32)transmute(int)advise
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of a openat(2) system call.

See also openat(2) for the general description of the related system call.

Available since 5.6.

If the file_index is set to a positive number,
the file won't be installed into the normal file table as usual but will be placed into the fixed file table at index file_index - 1.
In this case, instead of returning a file descriptor, the result will contain either 0 on success or an error.
If the index points to a valid empty slot, the installation is guaranteed to not fail.
If there is already a file in the slot, it will be replaced, similar to IORING_OP_FILES_UPDATE.
Please note that only uring has access to such files and no other syscall can use them.
See IOSQE_FIXED_FILE and IORING_REGISTER_FILES.

Available since 5.15.
*/
openat :: proc(ring: ^Ring, user_data: u64, dirfd: linux.Fd, path: cstring, mode: linux.Mode, flags: linux.Open_Flags, file_index: u32 = 0) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .OPENAT
	sqe.fd = dirfd
	sqe.addr = cast(u64)transmute(uintptr)path
	sqe.len = transmute(u32)mode
	sqe.open_flags = flags
	sqe.user_data = user_data
	sqe.file_index = file_index

	ok = true
	return
}

openat2 :: proc() {
	unimplemented()
}

/*
Issue the equivalent of a close(2) system call.

See also close(2) for the general description of the related system call.

Available since 5.6.

If the file_index field is set to a positive number, this command can be used to close files that were
direct opened through IORING_OP_OPENAT, IORING_OP_OPENAT2, or IORING_OP_ACCEPT using the uring specific direct descriptors.
Note that only one of the descriptor fields may be set.
The direct close feature is available since the 5.15 kernel, where direct descriptors were introduced.
*/
close :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, file_index: u32 = 0) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .CLOSE
	sqe.fd = fd
	sqe.user_data = user_data
	sqe.file_index = file_index

	ok = true
	return
}

/*
Issue the equivalent of a statx(2) system call.

See also statx(2) for the general description of the related system call.

Available since 5.6.
*/
statx :: proc(ring: ^Ring, user_data: u64, dirfd: linux.Fd, pathname: cstring, flags: linux.FD_Flags, mask: linux.Statx_Mask, buf: ^linux.Statx) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .STATX
	sqe.fd = dirfd
	sqe.addr = cast(u64)transmute(uintptr)pathname
	sqe.statx_flags = flags
	sqe.statx_mask = mask
	sqe.statx = buf
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of a pread(2) system call.

If offset is set to -1 , the offset will use (and advance) the file position, like the read(2) system calls.
These are non-vectored versions of the IORING_OP_READV and IORING_OP_WRITEV opcodes.
See also read(2) for the general description of the related system call.

Available since 5.6.
*/
read :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, buf: []u8, offset: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .READ
	sqe.fd = fd
	sqe.addr = cast(u64)uintptr(raw_data(buf))
	sqe.len = u32(len(buf))
	sqe.off = offset
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of a pwrite(2) system call.

If offset is set to -1 , the offset will use (and advance) the file position, like the read(2) system calls.
These are non-vectored versions of the IORING_OP_READV and IORING_OP_WRITEV opcodes.
See also write(2) for the general description of the related system call.

Available since 5.6.
*/
write :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, buf: []u8, offset: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .WRITE
	sqe.fd = fd
	sqe.addr = cast(u64)uintptr(raw_data(buf))
	sqe.len = u32(len(buf))
	sqe.off = offset
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of a splice(2) system call.

A sentinel value of -1 is used to pass the equivalent of a NULL for the offsets to splice(2).

Please note that one of the file descriptors must refer to a pipe.
See also splice(2) for the general description of the related system call.

Available since 5.7.

*/
splice :: proc(ring: ^Ring, user_data: u64, fd_in: linux.Fd, off_in: i64, fd_out: linux.Fd, off_out: i64, len: u32, flags: linux.IO_Uring_Splice_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .SPLICE
	sqe.splice_fd_in = fd_in
	sqe.splice_off_in = cast(u64)off_in
	sqe.fd = fd_out
	sqe.off = cast(u64)off_out
	sqe.len = len
	sqe.splice_flags = flags
	sqe.user_data = user_data

	ok = true
	return
}

/*
Issue the equivalent of a tee(2) system call.

Please note that both of the file descriptors must refer to a pipe.
See also tee(2) for the general description of the related system call.

Available since 5.8.
*/
tee :: proc(ring: ^Ring, user_data: u64, fd_in: linux.Fd, fd_out: linux.Fd, len: u32, flags: linux.IO_Uring_Splice_Flags) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .TEE
	sqe.splice_fd_in = fd_in
	sqe.fd = fd_out
	sqe.len = len
	sqe.splice_flags = flags
	sqe.user_data = user_data

	ok = true
	return
}

/*
This command is an alternative to using IORING_REGISTER_FILES_UPDATE which then works in an async fashion, like the rest of the uring commands.

Note that the array of file descriptors pointed to in addr must remain valid until this operation has completed.

Available since 5.6.
*/
files_update :: proc(ring: ^Ring, user_data: u64, fds: []linux.Fd, off: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .FILES_UPDATE
	sqe.addr = cast(u64)uintptr(raw_data(fds))
	sqe.len = cast(u32)len(fds)
	sqe.off = off
	sqe.user_data = user_data

	ok = true
	return
}

provide_buffers :: proc() {
	unimplemented()
}

remove_buffers :: proc() {
	unimplemented()
}

/*
Issue the equivalent of a shutdown(2) system call.

Available since 5.11.
*/
shutdown :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, how: linux.Shutdown_How) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .SHUTDOWN
	sqe.fd = fd
	sqe.shutdown_how = how
	sqe.user_data = user_data

	ok = true
	return
}

renameat :: proc() {
	unimplemented()
}

unlinkat :: proc() {
	unimplemented()
}

mkdirat :: proc() {
	unimplemented()
}

symlinkat :: proc() {
	unimplemented()
}

linkat :: proc() {
	unimplemented()
}

msg_ring :: proc() {
	unimplemented()
}

/*
Issue the equivalent of a socket(2) system call.

See also socket(2) for the general description of the related system call.

Available since 5.19.

If the file_index field is set to a positive number, the file won't be installed into the normal file
table as usual but will be placed into the fixed file table at index file_index - 1.
In this case, instead of returning a file descriptor, the result will contain either 0 on success or an error.
If the index points to a valid empty slot, the installation is guaranteed to not fail.
If there is already a file in the slot, it will be replaced, similar to IORING_OP_FILES_UPDATE.
Please note that only uring has access to such files and no other syscall can use them.
See IOSQE_FIXED_FILE and IORING_REGISTER_FILES.
*/
socket :: proc(ring: ^Ring, user_data: u64, domain: linux.Address_Family, socktype: linux.Socket_Type, protocol: linux.Protocol, file_index: u32 = 0) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .SOCKET
	sqe.user_data = user_data
	sqe.fd = cast(linux.Fd)domain
	sqe.off = cast(u64)socktype
	sqe.len = cast(u32)protocol
	sqe.rw_flags = {}
	sqe.file_index = file_index

	ok = true
	return
}

uring_cmd :: proc() {
	unimplemented()
}

send_zc :: proc() {
	unimplemented()
}

sendmsg_zc :: proc() {
	unimplemented()
}

waitid :: proc() {
	unimplemented()
}

setxattr :: proc() {
	unimplemented()
}

getxattr :: proc() {
	unimplemented()
}

fsetxattr :: proc() {
	unimplemented()
}

fgetxattr :: proc() {
	unimplemented()
}

/*
Issues the equivalent of the bind(2) system call.

Available since 6.11.
*/
bind :: proc(ring: ^Ring, user_data: u64, sock: linux.Fd, addr: ^$T) -> (sqe: linux.IO_Uring_SQE, ok: bool)
	where
	T == linux.Sock_Addr_In ||
	T == linux.Sock_Addr_In6 ||
	T == linux.Sock_Addr_Un ||
	T == linux.Sock_Addr_Any
{
	sqe = get_sqe(ring) or_return
	sqe.opcode = .BIND
	sqe.user_data = user_data
	sqe.fd = sock
	sqe.addr = cast(u64)uintptr(addr)
	sqe.addr2 = size_of(T)

	ok = true
	return
}

/*
Issues the equivalent of the listen(2) system call.

fd must contain the file descriptor of the socket and addr must contain the backlog parameter, i.e. the maximum amount of pending queued connections.

Available since 6.11.
*/
listen :: proc(ring: ^Ring, user_data: u64, fd: linux.Fd, backlog: u64) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sqe = get_sqe(ring) or_return
	sqe.opcode = .LISTEN
	sqe.user_data = user_data
	sqe.fd = fd
	sqe.addr = backlog

	ok = true
	return
}

ftruncate :: proc() {
	unimplemented()
}

read_multishot :: proc() {
	unimplemented()
}

futex_wait :: proc() {
	unimplemented()
}

futex_wake :: proc() {
	unimplemented()
}

futex_waitv :: proc() {
	unimplemented()
}

fixed_fd_install :: proc() {
	unimplemented()
}

fixed_file :: proc() {
	unimplemented()
}
