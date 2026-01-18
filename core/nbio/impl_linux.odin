#+private file
package nbio

import "base:intrinsics"

import "core:container/pool"
import "core:container/queue"
import "core:mem"
import "core:net"
import "core:slice"
import "core:strings"
import "core:sys/linux"
import "core:sys/linux/uring"
import "core:time"

@(private="package")
_FULLY_SUPPORTED :: true

@(private="package")
_Event_Loop :: struct {
	ring:      uring.Ring,
	// Ready to be submitted to kernel, if kernel is full.
	unqueued:  queue.Queue(^Operation),
	// Ready to run callbacks, mainly next tick, some other ops that error outside the kernel.
	completed: queue.Queue(^Operation),
	wake:      ^Operation,
}

@(private="package")
_Handle :: linux.Fd

@(private="package")
_CWD :: linux.AT_FDCWD

@(private="package")
MAX_RW :: mem.Gigabyte

@(private="package")
_Operation :: struct {
	removal: ^Operation,
	sqe:     ^linux.IO_Uring_SQE,
	expires: linux.Time_Spec,
}

@(private="package")
_Accept :: struct {
	sockaddr:     linux.Sock_Addr_Any,
	sockaddr_len: i32,
}

@(private="package")
_Close :: struct {}

@(private="package")
_Dial :: struct {
	sockaddr: linux.Sock_Addr_Any,
}

@(private="package")
_Read :: struct {}

@(private="package")
_Write :: struct {}

@(private="package")
_Send :: struct {
	endpoint:   linux.Sock_Addr_Any,
	msghdr:     linux.Msg_Hdr,
	small_bufs: [1][]byte,
}

@(private="package")
_Recv :: struct {
	addr_out:   linux.Sock_Addr_Any,
	msghdr:     linux.Msg_Hdr,
	small_bufs: [1][]byte,
}

@(private="package")
_Timeout :: struct {
	expires: linux.Time_Spec,
}

@(private="package")
_Poll :: struct {}

@(private="package")
_Remove :: struct {
	target: ^Operation,
}

@(private="package")
_Link_Timeout :: struct {
	target:  ^Operation,
	expires: linux.Time_Spec,
}

@(private="package")
_Send_File :: struct {
	len:    int,
	pipe:   Handle,

	splice: ^Operation,
}

@(private="package")
_Splice :: struct {
	off:     int,
	len:     int,
	file:    Handle,
	pipe:    Handle,

	written: int,

	sendfile: ^Operation,
}

@(private="package")
_Open :: struct {
	cpath: cstring,
}

@(private="package")
_Stat :: struct {
	buf: linux.Statx,
}

@(private="package")
_init :: proc(l: ^Event_Loop, alloc: mem.Allocator) -> (err: General_Error) {
	params := uring.DEFAULT_PARAMS
	params.flags += {.SUBMIT_ALL, .COOP_TASKRUN, .SINGLE_ISSUER}

	uerr := uring.init(&l.ring, &params, QUEUE_SIZE)
	if uerr != nil {
		err = General_Error(uerr)
		return
	}
	defer if err != nil { uring.destroy(&l.ring) }

	if perr := queue.init(&l.unqueued, allocator = alloc); perr != nil {
		err = .Allocation_Failed
		return
	}
	defer if err != nil { queue.destroy(&l.unqueued) }

	if perr := queue.init(&l.completed, allocator = alloc); perr != nil {
		err = .Allocation_Failed
		return
	}
	defer if err != nil { queue.destroy(&l.completed) }

	set_up_wake_up(l) or_return

	return

	set_up_wake_up :: proc(l: ^Event_Loop) -> General_Error {
		wakefd, wakefd_err := linux.eventfd(0, {.SEMAPHORE, .CLOEXEC, .NONBLOCK})
		if wakefd_err != nil {
			return General_Error(wakefd_err)
		}

		op, alloc_err := new(Operation, l.allocator)
		if alloc_err != nil {
			linux.close(wakefd)
			return .Allocation_Failed
		}

		l.wake             = op
		l.wake.detached    = true
		l.wake.l           = l
		l.wake.type        = .Read
		l.wake.cb          = wake_up_callback
		l.wake.read.handle = wakefd
		l.wake.read.buf    = ([^]byte)(&l.wake.user_data)[:8]
		_exec(l.wake)

		return nil
	}

	wake_up_callback :: proc(op: ^Operation) {
		assert(op.type == .Read)
		assert(op == op.l.wake)
		assert(op.read.err == nil)
		assert(op.read.read == 8)
		value := intrinsics.unaligned_load((^u64)(&op.user_data))
		assert(value > 0)
		debug(int(value), "wake_up calls handled")

		op.read.read = 0
		op.user_data = {}
		_exec(op)
	}
}

@(private="package")
_destroy :: proc(l: ^Event_Loop) {
	linux.close(l.wake.read.handle)
	free(l.wake, l.allocator)

	queue.destroy(&l.unqueued)
	queue.destroy(&l.completed)
	uring.destroy(&l.ring)
}

@(private="package")
__tick :: proc(l: ^Event_Loop, timeout: time.Duration) -> General_Error {
	debug("tick")

	// Execute completed operations, mostly next tick ops, also some other ops that may error before
	// adding it to the Uring.
	n := queue.len(l.completed)
	if n > 0 {
		l.now = time.now()
		for _ in 0 ..< n {
			completed := queue.pop_front(&l.completed)
			if completed._impl.removal == nil {
				completed.cb(completed)
			} else if completed._impl.removal != (^Operation)(REMOVED) {
				completed._impl.removal._remove.target = nil
			}
			if !completed.detached {
				pool.put(&l.operation_pool, completed)
			}
		}
	}

	err := _flush_submissions(l, timeout)
	if err != nil { return General_Error(err) }

	l.now = time.now()

	err = _flush_completions(l, false)
	if err != nil { return General_Error(err) }

	return nil

	_flush_completions :: proc(l: ^Event_Loop, wait: bool) -> linux.Errno {
		wait := wait
		cqes: [128]linux.IO_Uring_CQE = ---
		for {
			completed, err := uring.copy_cqes(&l.ring, cqes[:], 1 if wait else 0)
			if err == .EINTR {
				continue
			} else if err != nil {
				return err
			}

			_flush_unqueued(l)

			if completed > 0 {
				debug(int(completed), "operations returned from uring")
			}

			for cqe in cqes[:completed] {
				assert(cqe.user_data != 0)
				op, is_timeout := unpack_operation(cqe.user_data)
				if is_timeout {
					link_timeout_callback(op, cqe.res)
				} else {
					handle_completed(op, cqe.res)
				}
			}

			if completed < len(cqes) { break }

			debug("more events ready than our results buffer handles, getting more")
			wait = false
		}

		return nil
	}

	_flush_submissions :: proc(l: ^Event_Loop, timeout: time.Duration) -> linux.Errno {
		for {
			ts: linux.Time_Spec
			ts.time_nsec = uint(timeout)
			_, err := uring.submit(&l.ring, 0 if timeout == 0 else 1, nil if timeout < 0 else &ts)
			#partial switch err {
			case .NONE, .ETIME:
			case .EINTR:
				warn("uring interrupted")
				continue
			case .ENOMEM:
				// It's full, wait for at least one operation to complete and try again.
				warn("could not flush submissions, ENOMEM, waiting for operations to complete before continuing")
				ferr := _flush_completions(l, true)
				if ferr != nil { return ferr }
				continue
			case:
				return err
			}

			break
		}

		return nil
	}

	_flush_unqueued :: proc(l: ^Event_Loop) {
		n := queue.len(l.unqueued)
		for _ in 0..<n {
			unqueued := queue.pop_front(&l.unqueued)

			if unqueued._impl.removal != nil {
				debug(unqueued.type, "was removed and has not been on the ring yet")
				if unqueued._impl.removal != (^Operation)(REMOVED) {
					// Set the removal target to nil to indicate we've already done it.
					unqueued._impl.removal._remove.target = nil
				}
				if !unqueued.detached {
					pool.put(&l.operation_pool, unqueued)
				}
				continue
			} else if unqueued.type == ._Remove {
				if unqueued._remove.target == nil {
					// If the removal was set to nil by the branch above, we don't need to do anything.
					debug("removal target was nil, skipping remove")
					if !unqueued.detached {
						pool.put(&l.operation_pool, unqueued)
					}
					continue
				} else {
					debug("removal was added to ring later")
					enqueue(unqueued, uring.async_cancel(
						&unqueued.l.ring,
						u64(uintptr(unqueued._remove.target)),
						u64(uintptr(unqueued)),
					))
					continue
				}
			}
			_exec(unqueued)
		}
	}
}

@(private="package")
_exec :: proc(op: ^Operation) {
	assert(op.l == &_tls_event_loop)
	switch op.type {
	case .Accept:        accept_exec(op)
	case .Dial:          dial_exec(op)
	case .Read:          read_exec(op)
	case .Write:         write_exec(op)
	case .Recv:          recv_exec(op)
	case .Send:          send_exec(op)
	case .Poll:          poll_exec(op)
	case .Close:         close_exec(op)
	case .Timeout:       timeout_exec(op)
	case .Send_File:     sendfile_exec(op)
	case .Open:          open_exec(op)
	case .Stat:          stat_exec(op)
	case ._Splice:
		// This is only reachable when the queue was full the last tick.
		// And if that's the case, it would still be full for the real sendfile (splice B) and will be enqueued there.
		// So it is safe to do nothing here.
	case ._Remove:       unreachable()
	case ._Link_Timeout: unreachable()
	case .None:          unreachable()
	}
}

@(private="package")
_open_sync :: proc(l: ^Event_Loop, path: string, dir: Handle, mode: File_Flags, perm: Permissions) -> (handle: Handle, err: FS_Error) {
	if path == "" {
		err = .Invalid_Argument
		return
	}

	cpath, cerr := strings.clone_to_cstring(path, l.allocator)
	if cerr != nil {
		err = .Allocation_Failed
		return
	}
	defer delete(cpath, l.allocator)

	sys_flags := linux.Open_Flags{.NOCTTY, .CLOEXEC, .NONBLOCK}

	if .Write in mode {
		if .Read in mode {
			sys_flags += {.RDWR}
		} else {
			sys_flags += {.WRONLY}
		}
	}

	if .Append      in mode { sys_flags += {.APPEND} }
	if .Create      in mode { sys_flags += {.CREAT} }
	if .Excl        in mode { sys_flags += {.EXCL} }
	if .Sync        in mode { sys_flags += {.DSYNC} }
	if .Trunc       in mode { sys_flags += {.TRUNC} }
	// if .Inheritable in mode { sys_flags -= {.CLOEXEC} }

	errno: linux.Errno
	handle, errno = linux.openat(dir, cpath, sys_flags, transmute(linux.Mode)perm)
	if errno != nil {
		err = FS_Error(errno)
	}

	return
}

@(private="package")
_create_socket :: proc(
	_: ^Event_Loop,
	family: Address_Family,
	protocol: Socket_Protocol,
) -> (
	socket: Any_Socket,
	err: Create_Socket_Error,
) {
	socket = net.create_socket(family, protocol) or_return
	// NOTE: this doesn't seem needed with io uring.
	// defer if err != nil { net.close(socket) }
	// net.set_blocking(socket, false) or_return
	return
}

@(private="package")
_listen :: proc(socket: TCP_Socket, backlog := 1000) -> Listen_Error {
	err := linux.listen(linux.Fd(socket), i32(backlog))
	if err != nil {
		return net._listen_error(err)
	}
	return nil
}

@(private="package")
_remove :: proc(target: ^Operation) {
	target := target
	assert(target != nil)

	if target._impl.removal != nil {
		return
	}

	op := _prep(target.l, proc(_: ^Operation) {}, ._Remove)
	op._remove.target = target

	target._impl.removal = op

	enqueue(op, uring.async_cancel(
		&op.l.ring,
		u64(uintptr(target)),
		u64(uintptr(op)),
	))
}

@(private="package")
_associate_handle :: proc(handle: uintptr, l: ^Event_Loop) -> (Handle, Association_Error) {
	// Works by default.
	return Handle(handle), nil
}

@(private="package")
_associate_socket :: proc(socket: Any_Socket, l: ^Event_Loop) -> Association_Error {
	// Works by default.
	return nil
}

@(private="package")
_wake_up :: proc(l: ^Event_Loop) {
	assert(l != &_tls_event_loop)
	one: u64 = 1
	// Called from another thread, in which we can't use the uring.
	n, err := linux.write(l.wake.read.handle, ([^]byte)(&one)[:size_of(one)])
	// Shouldn't fail.
	assert(err == nil)
	assert(n == 8)
}

@(private="package")
_yield :: proc() {
	linux.sched_yield()
}

// Start file private.

// The size of the IO Uring queues.
QUEUE_SIZE :: #config(ODIN_NBIO_QUEUE_SIZE, 2048)
#assert(QUEUE_SIZE <= uring.MAX_ENTRIES)

#assert(size_of(Operation) <= 384) // Just so we see when we make it bigger.
#assert(size_of(Specifics) <= 288) // Just so we see when we make it bigger.

REMOVED :: rawptr(max(uintptr)-1)

handle_completed :: proc(op: ^Operation, res: i32) {
	debug("handling", op.type, "result", int(res))

	switch op.type {
	case .Accept:
		accept_callback(op, res)
	case .Dial:
		dial_callback(op, res)
	case .Timeout:
		timeout_callback(op, res)
	case .Write:
		if !write_callback(op, res) { return }
	case .Read:
		if !read_callback(op, res) { return }
	case .Close:
		close_callback(op, res)
	case .Poll:
		poll_callback(op, res)
	case .Send:
		if !send_callback(op, res) { return }
		maybe_callback(op)
		if len(op.send.bufs) > 1 { delete(op.send.bufs, op.l.allocator) }
		cleanup(op)
		return
	case .Recv:
		if !recv_callback(op, res) { return }
		maybe_callback(op)
		if len(op.recv.bufs) > 1 { delete(op.recv.bufs, op.l.allocator) }
		cleanup(op)
		return
	case .Open:
		open_callback(op, res)
	case .Stat:
		stat_callback(op, res)
	case .Send_File:
		if !sendfile_callback(op, res) { return }
	case ._Splice:
		if !splice_callback(op, res) { return }
	case ._Remove:
		if !remove_callback(op, res) { return }
	case ._Link_Timeout:
		unreachable()
	case .None:
		fallthrough
	case:
		panic("corrupted operation")
	}

	maybe_callback(op)
	cleanup(op)

	maybe_callback :: proc(op: ^Operation) {
		if op._impl.removal == nil {
			debug("done, calling back", op.type)
			op.cb(op)
		} else if op._impl.removal == (^Operation)(REMOVED) {
			debug("done but was cancelled by remove", op.type)
		} else {
			debug("done but has removal pending", op.type)
			// If the remove callback sees their target is nil, they know it is done already.
			op._impl.removal._remove.target = nil
		}
	}

	cleanup :: proc(op: ^Operation) {
		if !op.detached {
			pool.put(&op.l.operation_pool, op)
		}
	}
}

enqueue :: proc(op: ^Operation, sqe: ^linux.IO_Uring_SQE, ok: bool) {
	assert(uintptr(op) & LINK_TIMEOUT_MASK == 0)
	debug("enqueue", op.type)
	if !ok {
		warn("queueing for next tick because the ring is full, queue size may need increasing")
		pok, _ := queue.push_back(&op.l.unqueued, op)
		ensure(pok, "unqueued queue allocation failure")
		return
	}

	op._impl.sqe = sqe
}

LINK_TIMEOUT_MASK :: 1

link_timeout :: proc(target: ^Operation, expires: time.Time) {
	if expires == {} {
		return
	}

	// If the last op was queued because kernel is full, return.
	if target._impl.sqe == nil {
		assert(queue.len(target.l.unqueued) > 0 && queue.back_ptr(&target.l.unqueued)^ == target)
		return
	}

	target._impl.sqe.flags += {.IO_LINK}
	target._impl.expires = ns_to_time_spec(expires._nsec)

	// Tag the pointer as a timeout.
	p := uintptr(target)
	assert(p & LINK_TIMEOUT_MASK == 0)
	p |= LINK_TIMEOUT_MASK

	_, ok := uring.link_timeout(
		&target.l.ring,
		u64(p),
		&target._impl.expires,
		{.ABS, .REALTIME},
	)
	// If the target wasn't queued, the link timeout should not need to be queued, because uring
	// leaves one spot specifically for a link.
	assert(ok)
}

link_timeout_callback :: proc(op: ^Operation, res: i32) {
	err := linux.Errno(-res)
	if err != nil && err != .ETIME && err != .ECANCELED {
		panic("unexpected nbio.link_timeout() error")
	}
}

unpack_operation :: #force_inline proc(user_data: u64) -> (op: ^Operation, timed_out: bool) {
	p := uintptr(user_data)
	return (^Operation)(p &~ LINK_TIMEOUT_MASK), bool(p & LINK_TIMEOUT_MASK)
}

@(require_results)
remove_callback :: proc(op: ^Operation, res: i32) -> bool {
	assert(op.type == ._Remove)
	err := linux.Errno(-res)

	target := op._remove.target
	if target == nil {
		debug("remove target nil, already handled")
		return true
	}

	assert(target.type != .None)
	assert(target._impl.removal == op)

	if err == .ENOENT {
		debug("remove ENOENT, trying again")

		enqueue(op, uring.async_cancel(
			&op.l.ring,
			u64(uintptr(target)),
			u64(uintptr(op)),
		))

		return false
	} else if err == .EALREADY {
		debug("remove is accepted and will be tried")
	} else if err != nil {
		assert(false, "unexpected nbio.remove() error")
	}

	// Set to sentinel so nothing references the operation that will be reused.
	target._impl.removal = (^Operation)(REMOVED)
	return true
}

accept_exec :: proc(op: ^Operation) {
	assert(op.type == .Accept)
	op.accept._impl.sockaddr_len = size_of(op.accept._impl.sockaddr)
	enqueue(op, uring.accept(
		&op.l.ring,
		u64(uintptr(op)),
		linux.Fd(op.accept.socket),
		&op.accept._impl.sockaddr,
		&op.accept._impl.sockaddr_len,
		{},
	))
	link_timeout(op, op.accept.expires)
}

accept_callback :: proc(op: ^Operation, res: i32) {
	assert(op.type == .Accept)
	if res < 0 {
		errno := linux.Errno(-res)
		#partial switch errno {
		case .ECANCELED:
			op.accept.err = .Timeout
		case:
			op.accept.err = net._accept_error(errno)
		}

		return
	}

	op.accept.client = TCP_Socket(res)
	// net.set_blocking(net.TCP_Socket(op.accept.client), false)
	op.accept.client_endpoint = sockaddr_storage_to_endpoint(&op.accept._impl.sockaddr)
}

dial_exec :: proc(op: ^Operation) {
	assert(op.type == .Dial)
	if op.dial.socket == {} {
		if op.dial.endpoint.port == 0 {
			op.dial.err = .Port_Required
			queue.push_back(&op.l.completed, op)
			return
		}

		sock, err := create_socket(net.family_from_endpoint(op.dial.endpoint), .TCP)
		if err != nil {
			op.dial.err = err
			queue.push_back(&op.l.completed, op)
			return
		}

		op.dial.socket = sock.(TCP_Socket)
		op.dial._impl.sockaddr = endpoint_to_sockaddr(op.dial.endpoint)
	}

	enqueue(op, uring.connect(
		&op.l.ring,
		u64(uintptr(op)),
		linux.Fd(op.dial.socket),
		&op.dial._impl.sockaddr,
	))
	link_timeout(op, op.dial.expires)
}

dial_callback :: proc(op: ^Operation, res: i32) {
	assert(op.type == .Dial)
	errno := linux.Errno(-res)
	if errno != nil {
		#partial switch errno {
		case .ECANCELED:
			op.dial.err = Dial_Error.Timeout
		case:
			op.dial.err = net._dial_error(errno)
		}
		close(op.dial.socket)
	}
}

timeout_exec :: proc(op: ^Operation) {
	assert(op.type == .Timeout)
	if op.timeout.duration <= 0 {
		queue.push_back(&op.l.completed, op)
		return
	}

	expires := time.time_add(op.l.now, op.timeout.duration)
	op.timeout._impl.expires = ns_to_time_spec(expires._nsec)

	enqueue(op, uring.timeout(
		&op.l.ring,
		u64(uintptr(op)),
		&op.timeout._impl.expires,
		0,
		{.ABS, .REALTIME},
	))
}

timeout_callback :: proc(op: ^Operation, res: i32) {
	if res < 0 {
		errno := linux.Errno(-res)
		#partial switch errno {
		case .ETIME, .ECANCELED: // OK.
		case:
			debug("unexpected timeout error:", int(errno))
			panic("unexpected timeout error")
		}
	}
}

close_exec :: proc(op: ^Operation) {
	assert(op.type == .Close)

	fd: linux.Fd
	switch closable in op.close.subject {
	case Handle:     fd = linux.Fd(closable)
	case TCP_Socket: fd = linux.Fd(closable)
	case UDP_Socket: fd = linux.Fd(closable)
	case:            op.close.err = .Invalid_Argument; return
	}

	enqueue(op, uring.close(
		&op.l.ring,
		u64(uintptr(op)),
		fd,
	))
}

close_callback :: proc(op: ^Operation, res: i32) {
	assert(op.type == .Close)
	op.close.err = FS_Error(linux.Errno(-res))
}

recv_exec :: proc(op: ^Operation) {
	assert(op.type == .Recv)

	if op.recv.err != nil {
		queue.push_back(&op.l.completed, op)
		return
	}

	bufs    := slice.advance_slices(op.recv.bufs, op.recv.received)
	bufs, _  = constraint_bufs_to_max_rw(bufs)
	op.recv._impl.msghdr.iov = transmute([]linux.IO_Vec)bufs

	sock: linux.Fd
	switch socket in op.recv.socket {
	case TCP_Socket:
		sock = linux.Fd(socket)
	case UDP_Socket:
		sock = linux.Fd(socket)
		op.recv._impl.msghdr.name    = &op.recv._impl.addr_out
		op.recv._impl.msghdr.namelen = size_of(op.recv._impl.addr_out)
	}

	enqueue(op, uring.recvmsg(
		&op.l.ring,
		u64(uintptr(op)),
		linux.Fd(sock),
		&op.recv._impl.msghdr,
		{.NOSIGNAL},
	))
	link_timeout(op, op.recv.expires)
}

@(require_results)
recv_callback :: proc(op: ^Operation, res: i32) -> bool {
	assert(op.type == .Recv)

	if res < 0 {
		errno := linux.Errno(-res)
		switch sock in op.recv.socket {
		case TCP_Socket:
			#partial switch errno {
			case .ECANCELED:
				op.recv.err = TCP_Recv_Error.Timeout
			case:
				op.recv.err = net._tcp_recv_error(errno)
			}
		case UDP_Socket:
			#partial switch errno {
			case .ECANCELED:
				op.recv.err = UDP_Recv_Error.Timeout
			case:
				op.recv.err = net._udp_recv_error(errno)
			}
		}

		return true
	}

	op.recv.received += int(res)

	switch sock in op.recv.socket {
	case TCP_Socket:
		if res == 0 {
			// Connection closed.
			return true
		}

		if op.recv.all {
			total: int
			for buf in op.recv.bufs {
				total += len(buf)
			}

			if op.recv.received < total {
				recv_exec(op)
				return false
			}
		}

	case UDP_Socket:
		op.recv.source = sockaddr_storage_to_endpoint(&op.recv._impl.addr_out)
	}

	return true
}

send_exec :: proc(op: ^Operation) {
	assert(op.type == .Send)

	if op.send.err != nil {
		queue.push_back(&op.l.completed, op)
		return
	}

	bufs    := slice.advance_slices(op.send.bufs, op.send.sent)
	bufs, _  = constraint_bufs_to_max_rw(bufs)
	op.send._impl.msghdr.iov = transmute([]linux.IO_Vec)bufs

	sock: linux.Fd
	switch socket in op.send.socket {
	case TCP_Socket:
		sock = linux.Fd(socket)
	case UDP_Socket:
		sock = linux.Fd(socket)
		op.send._impl.endpoint       = endpoint_to_sockaddr(op.send.endpoint)
		op.send._impl.msghdr.name    = &op.send._impl.endpoint
		op.send._impl.msghdr.namelen = size_of(op.send._impl.endpoint)
	}

	enqueue(op, uring.sendmsg(
		&op.l.ring,
		u64(uintptr(op)),
		sock,
		&op.send._impl.msghdr,
		{.NOSIGNAL},
	))
	link_timeout(op, op.send.expires)
}

@(require_results)
send_callback :: proc(op: ^Operation, res: i32) -> bool {
	assert(op.type == .Send)
	if res < 0 {
		errno := linux.Errno(-res)
		switch sock in op.send.socket {
		case TCP_Socket:
			#partial switch errno {
			case .ECANCELED:
				op.send.err = TCP_Send_Error.Timeout
			case:
				op.send.err = net._tcp_send_error(errno)
			}
		case UDP_Socket:
			#partial switch errno {
			case .ECANCELED:
				op.send.err = UDP_Send_Error.Timeout
			case:
				op.send.err = net._udp_send_error(errno)
			}
		case: panic("corrupted socket")
		}

		return true
	}

	op.send.sent += int(res)

	if op.send.all {
		total: int
		for buf in op.send.bufs {
			total += len(buf)
		}

		if op.send.sent < total {
			assert(res > 0)
			send_exec(op)
			return false
		}
	}

	return true
}

write_exec :: proc(op: ^Operation) {
	assert(op.type == .Write)

	buf := op.write.buf[op.write.written:]
	buf  = buf[:min(MAX_RW, len(buf))]

	enqueue(op, uring.write(
		&op.l.ring,
		u64(uintptr(op)),
		op.write.handle,
		buf,
		u64(op.write.offset) + u64(op.write.written),
	))
	link_timeout(op, op.write.expires)
}

@(require_results)
write_callback :: proc(op: ^Operation, res: i32) -> bool {
	if res < 0 {
		errno := linux.Errno(-res)
		op.write.err = FS_Error(errno)
		return true
	}

	op.write.written += int(res)

	if op.write.all && op.write.written < len(op.write.buf) {
		write_exec(op)
		return false
	}

	return true
}

read_exec :: proc(op: ^Operation) {
	assert(op.type == .Read)

	buf := op.read.buf[op.read.read:]
	buf  = buf[:min(MAX_RW, len(buf))]

	enqueue(op, uring.read(
		&op.l.ring,
		u64(uintptr(op)),
		op.read.handle,
		buf,
		u64(op.read.offset) + u64(op.read.read),
	))
	link_timeout(op, op.read.expires)
}

@(require_results)
read_callback :: proc(op: ^Operation, res: i32) -> bool {
	if res < 0 {
		errno := linux.Errno(-res)
		op.read.err = FS_Error(errno)
		return true
	} else if res == 0 {
		if op.read.read == 0 {
			op.read.err = .EOF
		}
		return true
	}

	op.read.read += int(res)

	if op.read.all && op.read.read < len(op.read.buf) {
		read_exec(op)
		return false
	}

	return true
}

poll_exec :: proc(op: ^Operation) {
	assert(op.type == .Poll)

	events: linux.Fd_Poll_Events
	switch op.poll.event {
	case .Receive: events = { .IN }
	case .Send:    events = { .OUT }
	}

	fd: linux.Fd
	switch sock in op.poll.socket {
	case TCP_Socket: fd = linux.Fd(sock)
	case UDP_Socket: fd = linux.Fd(sock)
	}

	enqueue(op, uring.poll_add(
		&op.l.ring,
		u64(uintptr(op)),
		fd,
		events,
		{},
	))
	link_timeout(op, op.poll.expires)
}

poll_callback :: proc(op: ^Operation, res: i32) {
	if res < 0 {
		errno := linux.Errno(-res)
		#partial switch errno {
		case .NONE: // no-op
		case .ECANCELED:
			op.poll.result = .Timeout
		case .EINVAL, .EFAULT, .EBADF:
			op.poll.result = .Invalid_Argument
		case:
			op.poll.result = .Error
		}

		return
	}

	op.poll.result = .Ready
}

/*
`sendfile` is implemented with 2 splices over a pipe.

Splice A: from file to pipe
Splice B: from pipe to socket (optionally linked to a timeout)

The splices are hard-linked which means A completes before B.
B could get an `EWOULDBLOCK`, which is when the remote end has not read enough of the socket data yet.
In that case we enqueue a poll on the socket and continue when that completes.
A shouldn't get `EWOULDBLOCK`, but as a cautionary measure we handle it.

The timeout is either linked to the splice B op, or the poll op, either of these is also always in progress in the kernel.
*/
sendfile_exec :: proc(op: ^Operation, splice := true) {
	assert(op.type == .Send_File)

	splice_done := !splice
	if splice_op := op.sendfile._impl.splice; splice && splice_op != nil {
		splice_done = splice_op._splice.written == splice_op._splice.len
	}

	debug("sendfile_exec")

	if op.sendfile._impl.splice == nil {
		// First stat for the file size.
		if op.sendfile.nbytes == SEND_ENTIRE_FILE {
			debug("sendfile SEND_ENTIRE_FILE, doing stat")

			stat_poly(op.sendfile.file, op, proc(stat_op: ^Operation, sendfile_op: ^Operation) {
				if stat_op.stat.err != nil {
					sendfile_op.sendfile.err = stat_op.stat.err
				} else if stat_op.stat.type != .Regular {
					sendfile_op.sendfile.err = FS_Error.Invalid_Argument
				} else {
					sendfile_op.sendfile.nbytes = int(i64(stat_op.stat.size) - i64(sendfile_op.sendfile.offset))
					if sendfile_op.sendfile.nbytes <= 0 {
						sendfile_op.sendfile.err = FS_Error.Invalid_Argument
					}
				}

				if sendfile_op.sendfile.err != nil {
					handle_completed(sendfile_op, 0)
					return
				}

				sendfile_exec(sendfile_op)
			})
			return
		}

		debug("sendfile setting up")

		rw: [2]linux.Fd
		err := linux.pipe2(&rw, {.NONBLOCK, .CLOEXEC})
		if err != nil {
			op.sendfile.err = FS_Error(err)
			queue.push_back(&op.l.completed, op)
			return
		}

		splice_op := _prep(op.l, proc(_: ^Operation) { debug("sendfile splice helper callback") }, ._Splice)
		splice_op._splice.sendfile = op
		splice_op._splice.file     = op.sendfile.file
		splice_op._splice.pipe     = rw[1]
		splice_op._splice.off      = op.sendfile.offset
		splice_op._splice.len      = op.sendfile.nbytes

		op.sendfile._impl.splice = splice_op
		op.sendfile._impl.pipe   = rw[0]
		op.sendfile._impl.len    = op.sendfile.nbytes 
	}

	splice_op: ^Operation
	if !splice_done {
		splice_op = op.sendfile._impl.splice
		enqueue(splice_op, uring.splice(
			&splice_op.l.ring,
			u64(uintptr(splice_op)),
			splice_op._splice.file,
			i64(splice_op._splice.off) + i64(splice_op._splice.written),
			splice_op._splice.pipe,
			-1,
			u32(min(splice_op._splice.len - splice_op._splice.written, MAX_RW)),
			{.NONBLOCK},
		))
	}

	b, b_added := uring.splice(
		&op.l.ring,
		u64(uintptr(op)),
		op.sendfile._impl.pipe,
		-1,
		linux.Fd(op.sendfile.socket),
		-1,
		u32(min(op.sendfile._impl.len - op.sendfile.sent, MAX_RW)),
		{.NONBLOCK},
	)
	if !splice_done && b_added {
		assert(splice_op._impl.sqe != nil) // if b was added successfully, a should've been too.
		// Makes sure splice A (file to pipe) completes before splice B (pipe to socket).
		splice_op._impl.sqe.flags += {.IO_HARDLINK}
	}
	enqueue(op, b, b_added)

	link_timeout(op, op.sendfile.expires)
}

@(require_results)
splice_callback :: proc(op: ^Operation, res: i32) -> bool {
	assert(op.type == ._Splice)

	if res < 0 {
		errno := linux.Errno(-res)
		#partial switch errno {
		case .EAGAIN:
			// Splice A (from file to pipe) would block, this means the buffer is full and it first needs
			// to be sent over the socket by splice B (from pipe to socket).
			// So we don't do anything here, once a splice B completes a new splice A will be created.

		case:
			// Splice A (from file to pipe) error, we need to close the pipes, cancel the pending splice B,
			// and call the callback with the error.

			debug("sendfile helper splice error, closing pipe")

			close(op._splice.pipe)

			// This is nil if this is a cancel originating from the sendfile.
			// This is not nil if it is an actual error that happened on this splice.
			sendfile_op := op._splice.sendfile
			if sendfile_op != nil {
				debug("sendfile helper splice error, cancelling main sendfile")
				assert(sendfile_op.type == .Send_File)

				sendfile_op.sendfile._impl.splice = nil
				sendfile_op.sendfile.err = FS_Error(errno)
			}
		}

		return true
	}

	op._splice.written += int(res)

	sendfile_op := op._splice.sendfile
	if sendfile_op != nil {
		if op._splice.written < sendfile_op.sendfile.nbytes {
			return false
		}

		sendfile_op.sendfile._impl.splice = nil
	}

	assert(op._splice.pipe > 0)
	close(op._splice.pipe)

	debug("sendfile helper splice completely done")
	return true
}

@(require_results)
sendfile_callback :: proc(op: ^Operation, res: i32) -> bool {
	assert(op.type == .Send_File)

	if op.sendfile.err == nil && res < 0 {
		errno := linux.Errno(-res)
		#partial switch errno {
		case .EAGAIN:
			// Splice B (from pipe to socket) would block. We are waiting on the remote to read more
			// of our buffer before we can send more to it.
			// We use a poll to find out when this is.

			debug("sendfile needs to poll")

			poll_op := poll_poly(op.sendfile.socket, .Send, op, proc(poll_op: ^Operation, sendfile_op: ^Operation) {
				#partial switch poll_op.poll.result {
				case .Ready:
					// Do not enqueue a splice right away, we know there is at least one splice call worth of data in the kernel buffer.
					sendfile_exec(sendfile_op, splice=false)
					return

				case .Timeout:
					sendfile_op.sendfile.err = TCP_Send_Error.Timeout
				case:
					sendfile_op.sendfile.err = TCP_Send_Error.Unknown
				}

				debug("sendfile poll error")
				handle_completed(sendfile_op, 0)
			})

			link_timeout(poll_op, op.sendfile.expires)
			return false

		case .ECANCELED:
			op.sendfile.err = TCP_Send_Error.Timeout
		case:
			op.sendfile.err = net._tcp_send_error(errno)
		}
	}

	if op.sendfile.err != nil {
		debug("sendfile error")

		if op.sendfile._impl.pipe > 0 {
			close(op.sendfile._impl.pipe)
		}

		splice_op := op.sendfile._impl.splice
		if splice_op != nil {
			assert(splice_op.type == ._Splice)
			splice_op._splice.sendfile = nil
			_remove(splice_op)
		}

		return true
	}

	op.sendfile.sent += int(res)
	if op.sendfile.sent < op.sendfile._impl.len {
		debug("sendfile not completely done yet")
		sendfile_exec(op)
		if op.sendfile.progress_updates { op.cb(op) }
		return false
	}

	debug("sendfile completely done")
	return true
}

open_exec :: proc(op: ^Operation) {
	assert(op.type == .Open)

	sys_flags := linux.Open_Flags{.NOCTTY, .CLOEXEC, .NONBLOCK}

	if .Write in op.open.mode {
		if .Read in op.open.mode {
			sys_flags += {.RDWR}
		} else {
			sys_flags += {.WRONLY}
		}
	}

	if .Append      in op.open.mode { sys_flags += {.APPEND} }
	if .Create      in op.open.mode { sys_flags += {.CREAT} }
	if .Excl        in op.open.mode { sys_flags += {.EXCL} }
	if .Sync        in op.open.mode { sys_flags += {.DSYNC} }
	if .Trunc       in op.open.mode { sys_flags += {.TRUNC} }
	// if .Inheritable in op.open.mode { sys_flags -= {.CLOEXEC} }

	cpath, err := strings.clone_to_cstring(op.open.path, op.l.allocator)
	if err != nil {
		op.open.err = .Allocation_Failed
		queue.push_back(&op.l.completed, op)
		return
	}
	op.open._impl.cpath = cpath

	enqueue(op, uring.openat(
		&op.l.ring,
		u64(uintptr(op)),
		linux.Fd(op.open.dir),
		op.open._impl.cpath,
		transmute(linux.Mode)op.open.perm,
		sys_flags,
	))
}

open_callback :: proc(op: ^Operation, res: i32) {
	assert(op.type == .Open)

	delete(op.open._impl.cpath, op.l.allocator)
	
	if res < 0 {
		errno := linux.Errno(-res)
		op.open.err = FS_Error(errno)
		return
	}

	op.open.handle = Handle(res)
}

stat_exec :: proc(op: ^Operation) {
	assert(op.type == .Stat)

	enqueue(op, uring.statx(
		&op.l.ring,
		u64(uintptr(op)),
		op.stat.handle,
		"",
		{.EMPTY_PATH},
		{.TYPE, .SIZE},
		&op.stat._impl.buf,
	))
}

stat_callback :: proc(op: ^Operation, res: i32) {
	assert(op.type == .Stat)

	if res < 0 {
		errno := linux.Errno(-res)
		op.stat.err = FS_Error(errno)
		return
	}

	type := File_Type.Regular
	switch op.stat._impl.buf.mode & linux.S_IFMT {
	case linux.S_IFBLK, linux.S_IFCHR: type = .Device
	case linux.S_IFDIR:                type = .Directory
	case linux.S_IFIFO:                type = .Pipe_Or_Socket
	case linux.S_IFLNK:                type = .Symlink
	case linux.S_IFREG:                type = .Regular
	case linux.S_IFSOCK:               type = .Pipe_Or_Socket
	}

	op.stat.type = type
	op.stat.size = i64(op.stat._impl.buf.size)
}

@(require_results)
sockaddr_storage_to_endpoint :: proc(addr: ^linux.Sock_Addr_Any) -> (ep: Endpoint) {
	#partial switch addr.family {
	case .INET:
		return Endpoint {
			address = IP4_Address(addr.sin_addr),
			port    = int(addr.sin_port),
		}
	case .INET6:
		return Endpoint {
			address = IP6_Address(transmute([8]u16be)addr.sin6_addr),
			port    = int(addr.sin6_port),
		}
	case:
		return {}
	}
}

@(require_results)
endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: linux.Sock_Addr_Any) {
	switch a in ep.address {
	case IP4_Address:
		sockaddr.sin_family = .INET
		sockaddr.sin_port = u16be(ep.port)
		sockaddr.sin_addr = cast([4]u8)a
		return
	case IP6_Address:
		sockaddr.sin6_family = .INET6
		sockaddr.sin6_port = u16be(ep.port)
		sockaddr.sin6_addr = transmute([16]u8)a
		return
	}

	unreachable()
}

@(require_results)
ns_to_time_spec :: proc(nsec: i64) -> linux.Time_Spec {
	NANOSECONDS_PER_SECOND :: 1e9
	return {
		time_sec  = uint(nsec / NANOSECONDS_PER_SECOND),
		time_nsec = uint(nsec % NANOSECONDS_PER_SECOND),
	}
}
