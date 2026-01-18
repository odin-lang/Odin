#+build darwin, freebsd, openbsd, netbsd
#+private file
package nbio

import    "core:c"
import    "core:container/pool"
import    "core:container/queue"
import    "core:mem"
import    "core:net"
import    "core:slice"
import    "core:strings"
import    "core:sys/posix"
import    "core:time"
import kq "core:sys/kqueue"
import sa "core:container/small_array"

@(private="package")
_FULLY_SUPPORTED :: true

@(private="package")
_Event_Loop :: struct {
	// kqueue does not permit multiple {ident, filter} pairs in the kqueue.
	// We have to keep record of what we currently have in the kqueue, and if we get an operation
	// that would be the same (ident, filter) pair we need to bundle the operations under one kevent.
	submitted: map[Queue_Identifier]^Operation,
	// Holds all events we want to flush. Flushing is done each tick at which point this is emptied.
	pending:   sa.Small_Array(QUEUE_SIZE, kq.KEvent),
	// Holds what should be in `pending` but didn't fit.
	// When `pending`is flushed these are moved to `pending`.
	overflow:  queue.Queue(kq.KEvent),
	// Contains all operations that were immediately completed in `exec`.
	// These ops did not block so can call back next tick.
	completed: queue.Queue(^Operation),
	kqueue:    kq.KQ,
}

@(private="package")
_Handle :: posix.FD

@(private="package")
_CWD :: posix.AT_FDCWD

@(private="package")
MAX_RW :: mem.Gigabyte

@(private="package")
_Operation :: struct {
	// Linked list of operations that are bundled (same {ident, filter} pair) with this one.
	next:   ^Operation,
	prev:   ^Operation,

	flags:  Operation_Flags,
	result: i64,
}

@(private="package")
_Accept :: struct {}

@(private="package")
_Close :: struct {}

@(private="package")
_Dial :: struct {}

@(private="package")
_Recv :: struct {
	small_bufs: [1][]byte,
}

@(private="package")
_Send :: struct {
	small_bufs: [1][]byte,
}

@(private="package")
_Read :: struct {}

@(private="package")
_Write :: struct {}

@(private="package")
_Timeout :: struct {}

@(private="package")
_Poll :: struct {}

@(private="package")
_Send_File :: struct {
	mapping: []byte, // `mmap`'d buffer (if native `sendfile` is not supported).
}

@(private="package")
_Open :: struct {}

@(private="package")
_Stat :: struct {}

@(private="package")
_Splice :: struct {}

@(private="package")
_Remove :: struct {}

@(private="package")
_Link_Timeout :: struct {}

@(private="package")
_init :: proc(l: ^Event_Loop, allocator: mem.Allocator) -> (rerr: General_Error) {
	l.submitted.allocator = allocator
	l.overflow.data.allocator = allocator
	l.completed.data.allocator = allocator

	kqueue, err := kq.kqueue()
	if err != nil {
		return General_Error(posix.errno())
	}

	l.kqueue = kqueue

	sa.append(&l.pending, kq.KEvent{
		ident  = IDENT_WAKE_UP,
		filter = .User,
		flags  = {.Add, .Enable, .Clear},
	})

	return nil
}

@(private="package")
_destroy :: proc(l: ^Event_Loop) {
	delete(l.submitted)
	queue.destroy(&l.overflow)
	queue.destroy(&l.completed)
	posix.close(l.kqueue)
}

@(private="package")
__tick :: proc(l: ^Event_Loop, timeout: time.Duration) -> General_Error {
	debug("tick")

	if n := queue.len(l.completed); n > 0 {
		l.now = time.now()
		debug("processing", n, "already completed")

		for _ in 0 ..< n {
			op := queue.pop_front(&l.completed)
			handle_completed(op)
		}

		if pool.num_outstanding(&l.operation_pool) == 0 { return nil }
	}

	if NBIO_DEBUG {
		npending := sa.len(l.pending)
		if npending > 0 {
			debug("queueing", npending, "new events, there are", int(len(l.submitted)), "events pending")
		} else {
			debug("there are", int(len(l.submitted)), "events pending")
		}
	}

	ts_backing: posix.timespec
	ts_pointer: ^posix.timespec // nil means forever.
	if queue.len(l.completed) == 0 && len(l.submitted) > 0 {
		if timeout >= 0 {
			debug("timeout", timeout)
			ts_backing = {tv_sec=posix.time_t(timeout/time.Second), tv_nsec=c.long(timeout%time.Second)}
			ts_pointer = &ts_backing
		} else {
			debug("timeout forever")
		}
	} else {
		debug("timeout 0, there is completed work pending")
		ts_pointer = &ts_backing
	}

	for {
		results_buf: [128]kq.KEvent
		results := kevent(l, results_buf[:], ts_pointer) or_return

		sa.clear(&l.pending)
		for overflow in queue.pop_front_safe(&l.overflow) {
			sa.append(&l.pending, overflow) or_break
		}

		l.now = time.now()

		handle_results(l, results)

		if len(results) < len(results_buf) {
			break
		}

		debug("more events ready than our results buffer handles, getting more")

		// No timeout for the next call.
		ts_backing = {}
		ts_pointer = &ts_backing
	}


	return nil

	kevent :: proc(l: ^Event_Loop, buf: []kq.KEvent, ts: ^posix.timespec) -> ([]kq.KEvent, General_Error) {
		for {
			new_events, err := kq.kevent(l.kqueue, sa.slice(&l.pending), buf, ts)
			#partial switch err {
			case nil:
				assert(new_events >= 0)
				return buf[:new_events], nil
			case .EINTR:
				warn("kevent interrupted")
			case:
				warn("kevent error")
				warn(string(posix.strerror(err)))
				return nil, General_Error(err)
			}
		}
	}

	is_internal_timeout :: proc(filter: kq.Filter, op: ^Operation) -> bool {
		// A `.Timeout` that `.Has_Timeout` is a `remove()`'d timeout.
		return filter == .Timer && (op.type != .Timeout || .Has_Timeout in op._impl.flags) 
	}

	handle_results :: proc(l: ^Event_Loop, results: []kq.KEvent) {
		if len(results) > 0 {
			debug(len(results), "events completed")
		}

		// Mark all operations that have an event returned as not `.For_Kernel`.
		// We have to do this right away, or we may process an operation as if we think the kernel is responsible.
		for &event in results {
			if ODIN_OS != .Darwin {
				// On the BSDs, a `.Delete` that results in an `.Error` does not keep the `.Delete` flag in the result.
				// We only have `udata == nil` when we do a delete, so we can add it back here to keep consistent.
				if .Error in event.flags && event.udata == nil {
					event.flags += {.Delete}
				}
			}

			if .Delete in event.flags {
				continue
			}

			if event.filter == .User && event.ident == IDENT_WAKE_UP {
				continue
			}

			op := cast(^Operation)event.udata
			assert(op != nil)
			assert(op.type != .None)

			if is_internal_timeout(event.filter, op) {
				continue
			}

			_, del := delete_key(&l.submitted, Queue_Identifier{ ident = event.ident, filter = event.filter })
			assert(del != nil)

			for next := op; next != nil; next = next._impl.next {
				assert(.For_Kernel in next._impl.flags)
				next._impl.flags -= {.For_Kernel}
			}
		}

		// If we get a timeout and an actual result, ignore the timeout.
		// We have to do this after the previous loop so we know if the target op of a timeout was also completed.
		// We have to do this before the next loop so we handle timeouts before their target ops. Otherwise the target could already be done.
		for &event in results {
			if .Delete in event.flags {
				continue
			}

			if event.filter == .User && event.ident == IDENT_WAKE_UP {
				continue
			}

			op := cast(^Operation)event.udata
			if is_internal_timeout(event.filter, op) {
				// If the actual event has also been returned this tick, we need to ignore the timeout to not get a uaf.
				if .For_Kernel not_in op._impl.flags {
					assert(.Has_Timeout in op._impl.flags)
					op._impl.flags -= {.Has_Timeout}

					event.filter = kq.Filter(FILTER_IGNORE)
					debug(op.type, "timed out but was also completed this tick, ignoring timeout")
				}

			}
		}

		for event in results {
			if event.filter == kq.Filter(FILTER_IGNORE) {
				// Previous loop told us to ignore.
				continue
			}

			if event.filter == .User && event.ident == IDENT_WAKE_UP {
				debug("woken up")
				continue
			}

			if .Delete in event.flags {
				assert(.Error in event.flags)
				// Seems to happen when you delete at the same time or just after a close.
				debug("delete error", int(event.data))
				if err := posix.Errno(event.data); err != .ENOENT && err != .EBADF {
					warn("unexpected delete error")
					warn(string(posix.strerror(err)))
				}
				continue
			}

			op := cast(^Operation)event.udata
			assert(op != nil)
			assert(op.type != .None)

			// Timeout result that is a non-timeout op, meaning the operation timed out.
			// Because of the previous loop we are sure that the target op is not also in this tick's results.
			if is_internal_timeout(event.filter, op) {
				debug("got timeout for", op.type)

				assert(.Error not_in event.flags)

				assert(.Has_Timeout in op._impl.flags)
				op._impl.flags -= {.Has_Timeout}

				// Remove the actual operation.
				timeout_and_delete(op)
				handle_completed(op)
				continue
			}

			// Weird loop, but we need to get the next ptr before handle_completed(curr), curr is freed in handle_completed.
			for curr, next := op, op._impl.next; curr != nil; curr, next = next, next == nil ? nil : next._impl.next {
				if .Error in event.flags { curr._impl.flags += {.Error} }
				if .EOF   in event.flags { curr._impl.flags += {.EOF} }
				curr._impl.result = event.data
				handle_completed(curr)
			}
		}
	}
}

@(private="package")
_create_socket :: proc(l: ^Event_Loop, family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Create_Socket_Error) {
	socket = net.create_socket(family, protocol) or_return

	berr := net.set_blocking(socket, false)
	// This shouldn't be able to fail.
	assert(berr == nil)

	return
}

@(private="package")
_listen :: proc(socket: TCP_Socket, backlog := 1000) -> Listen_Error {
	if res := posix.listen(posix.FD(socket), i32(backlog)); res != .OK {
		return posix_listen_error()
	}
	return nil
}

@(private="package")
_exec :: proc(op: ^Operation) {
	assert(op.l == &_tls_event_loop)

	debug("exec", op.type)

	result: Op_Result
	switch op.type {
	case .Accept:
		result = accept_exec(op)
	case .Close:
		// no-op
	case .Timeout:
		result = timeout_exec(op)
	case .Dial:
		result = dial_exec(op)
	case .Recv:
		result = recv_exec(op)
	case .Send:
		result = send_exec(op)
	case .Send_File:
		result = sendfile_exec(op)
	case .Read:
		result = read_exec(op)
	case .Write:
		result = write_exec(op)
	case .Poll:
		result = poll_exec(op)
		assert(result == .Pending)
	case .Open:
		open_exec(op)
	case .Stat:
		stat_exec(op)
	case .None, ._Link_Timeout, ._Remove, ._Splice:
		fallthrough
	case:
		unreachable()
	}

	switch result {
	case .Pending:
		// no-op, in kernel.
		debug(op.type, "pending")
	case .Done:
		debug(op.type, "done immediately")
		op._impl.flags += {.Done}
		_, err := queue.push_back(&op.l.completed, op) // Got result, handle it next tick.
		ensure(err == nil, "allocation failure")
	}
}

@(private="package")
_remove :: proc(target: ^Operation) {
	assert(target != nil)

	debug("remove", target.type)

	if .Removed in target._impl.flags {
		debug("already removed")
		return
	}

	target._impl.flags += {.Removed, .Has_Timeout}
	link_timeout(target, target.l.now)
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

	sys_flags := posix.O_Flags{.NOCTTY, .CLOEXEC, .NONBLOCK}

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

	handle = posix.openat(dir, cpath, sys_flags, transmute(posix.mode_t)posix._mode_t(transmute(u32)perm))
	if handle < 0 {
		err = FS_Error(posix.errno())
	}

	return
}

@(private="package")
_associate_handle :: proc(handle: uintptr, l: ^Event_Loop) -> (Handle, Association_Error) {
	flags_ := posix.fcntl(posix.FD(handle), .GETFL)
	if flags_ < 0 {
		#partial switch errno := posix.errno(); errno {
		case .EBADF: return -1, .Invalid_Handle
		case:        return -1, Association_Error(errno)
		}
	}
	flags := transmute(posix.O_Flags)(flags_)

	if .NONBLOCK in flags {
		return Handle(handle), nil
	}

	if posix.fcntl(posix.FD(handle), .SETFL, flags) < 0 {
		#partial switch errno := posix.errno(); errno {
		case .EBADF: return -1, .Invalid_Handle
		case:        return -1, Association_Error(errno)
		}
	}

	return Handle(handle), nil
}

@(private="package")
_associate_socket :: proc(socket: Any_Socket, l: ^Event_Loop) -> Association_Error {
	if err := net.set_blocking(socket, false); err != nil {
		switch err {
		case .None:                unreachable()
		case .Network_Unreachable: return .Network_Unreachable
		case .Invalid_Argument:    return .Invalid_Handle
		case .Unknown:             fallthrough
		case:                      return Association_Error(net.last_platform_error())
		}
	}

	return nil
}

@(private="package")
_wake_up :: proc(l: ^Event_Loop) {
	// TODO: only if we are sleeping (like Windows).
	ev := [1]kq.KEvent{
		{
			ident  = IDENT_WAKE_UP,
			filter = .User,
			flags  = {},
			fflags = {
				user = {.Trigger},
			},
		},
	}
	t: posix.timespec
	n, err := kq.kevent(l.kqueue, ev[:], nil, &t)
	assert(err == nil)
	assert(n == 0)
}

@(private="package")
_yield :: proc() {
	posix.sched_yield()
}

// Start file private.

// Max operations that can be enqueued per tick.
QUEUE_SIZE :: #config(ODIN_NBIO_QUEUE_SIZE, 256)

FILTER_IGNORE :: kq.Filter(max(kq._Filter_Backing))

IDENT_WAKE_UP :: 69

Op_Result :: enum {
	Done,
	Pending,
}

Operation_Flag :: enum {
	Done,
	Removed,
	Has_Timeout,
	For_Kernel,
	EOF,
	Error,
}
Operation_Flags :: bit_set[Operation_Flag]

// Operations in the kqueue are uniquely identified using these 2 fields. You may not have more
// than one operation with the same identity submitted.
// So we need to keep track of the operations we have submitted, and if we add another, link it to a previously
// added operation.
Queue_Identifier :: struct {
	filter: kq.Filter,
	ident:  uintptr,
}

handle_completed :: proc(op: ^Operation) {
	debug("handling", op.type)

	result: Op_Result
	#partial switch op.type {
	case .Accept:
		result = accept_exec(op)
	case .Dial:
		result = dial_exec(op)
	case .Send:
		if send_exec(op) == .Done {
			maybe_callback(op)
			bufs_destroy(op.send.bufs, op.l.allocator)
			cleanup(op)
		}
		return
	case .Recv:
		if recv_exec(op) == .Done {
			maybe_callback(op)
			bufs_destroy(op.recv.bufs, op.l.allocator)
			cleanup(op)
		}
		return
	case .Send_File:
		result = sendfile_exec(op)
	case .Read:
		result = read_exec(op)
	case .Write:
		result = write_exec(op)
	case .Poll:
		result = poll_exec(op)
	case .Open:
		open_exec(op)
	case .Close:
		close_exec(op)
	case .Timeout, .Stat:
		// no-op
	case:
		unimplemented()
	}

	if result == .Done {
		maybe_callback(op)
		cleanup(op)
	}

	maybe_callback :: proc(op: ^Operation) {
		if .Removed not_in op._impl.flags {
			debug("done", op.type, "calling back")
			op.cb(op)
		} else {
			debug("done but removed", op.type)
		}
	}

	bufs_destroy :: proc(bufs: [][]byte, allocator: mem.Allocator) {
		if len(bufs) > 1 {
			delete(bufs, allocator)
		}
	} 

	cleanup :: proc(op: ^Operation) {
		if .Has_Timeout in op._impl.flags {
			remove_link_timeout(op)
		}
		if !op.detached {
			pool.put(&op.l.operation_pool, op)
		}
	}
}

@(require_results)
accept_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Accept)

	defer if op.accept.err != nil && op.accept.client > 0 {
		posix.close(posix.FD(op.accept.client))
	}

	if op.accept.err != nil || .Done in op._impl.flags {
		return .Done
	}

	op.accept.client, op.accept.client_endpoint, op.accept.err = net.accept_tcp(op.accept.socket)
	if op.accept.err != nil {
		if op.accept.err == .Would_Block {
			op.accept.err = nil
			add_pending(op, .Read, uintptr(op.accept.socket))
			link_timeout(op, op.accept.expires)
			return .Pending
		}

		return .Done
	}

	if err := net.set_blocking(op.accept.client, false); err != nil {
		op.accept.err = posix_accept_error()
	}

	return .Done
}

@(require_results)
dial_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Dial)

	defer if op.dial.err != nil && op.dial.socket > 0 {
		posix.close(posix.FD(op.dial.socket))
	}

	if op.dial.err != nil || .Done in op._impl.flags {
		return .Done
	}

	if op.dial.socket > 0 {
		// We have already called connect, retrieve potential error number only.
		err: posix.Errno
		size := posix.socklen_t(size_of(err))
		posix.getsockopt(posix.FD(op.dial.socket), posix.SOL_SOCKET, .ERROR, &err, &size)
		if err != nil {
			posix.errno(err)
			op.dial.err = posix_dial_error()
		}
		return .Done
	}

	if op.dial.endpoint.port == 0 {
		op.dial.err = .Port_Required
		return .Done
	}

	family := family_from_endpoint(op.dial.endpoint)
	osocket, socket_err := _create_socket(op.l, family, .TCP)
	if socket_err != nil {
		op.dial.err = socket_err
		return .Done
	}

	op.dial.socket = osocket.(TCP_Socket)

	sockaddr := endpoint_to_sockaddr(op.dial.endpoint)
	if posix.connect(posix.FD(op.dial.socket), (^posix.sockaddr)(&sockaddr), posix.socklen_t(sockaddr.ss_len)) != .OK {
		if posix.errno() == .EINPROGRESS {
			add_pending(op, .Write, uintptr(op.dial.socket))
			link_timeout(op, op.dial.expires)
			return .Pending
		}

		op.dial.err = posix_dial_error()
		return .Done
	}

	return .Done
}

@(require_results)
poll_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Poll)

	if .Error in op._impl.flags {
		#partial switch posix.Errno(op._impl.result) {
		case .EBADF: op.poll.result = .Invalid_Argument
		case:        op.poll.result = .Error
		}
		return .Done
	}

	if op._impl.result != 0 {
		op.poll.result = .Ready
		return .Done
	}

	if op.poll.result != .Ready {
		return .Done
	}

	filter: kq.Filter
	switch op.poll.event {
	case .Receive: filter = .Read
	case .Send:    filter = .Write
	}

	add_pending(op, filter, uintptr(net.any_socket_to_socket(op.poll.socket)))
	link_timeout(op, op.poll.expires)
	return .Pending
}

close_exec :: proc(op: ^Operation) {
	assert(op.type == .Close)

	if op.close.err != nil || op.close.subject == nil {
		return
	}

	fd: posix.FD
	switch subject in op.close.subject {
	case TCP_Socket: fd = posix.FD(subject)
	case UDP_Socket: fd = posix.FD(subject)
	case Handle:     fd = posix.FD(subject)
	case:            op.close.err = .Invalid_Argument; return
	}

	if posix.close(fd) != .OK {
		op.close.err = FS_Error(posix.errno())
	}
}

@(require_results)
send_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Send)

	if op.send.err != nil || .Done in op._impl.flags {
		return .Done
	}

	total: int
	bufs := slice.advance_slices(op.send.bufs, op.send.sent)
	bufs, total = constraint_bufs_to_max_rw(op.send.bufs)

	sock, n := sendv(op.send.socket, bufs, op.send.endpoint)
	if n < 0 {
		if posix.errno() == .EWOULDBLOCK {
			if !op.send.all && op.send.sent > 0 {
				return .Done
			}

			add_pending(op, .Write, uintptr(sock))
			link_timeout(op, op.send.expires)
			return .Pending
		}

		switch _ in op.send.socket {
		case TCP_Socket: op.send.err = posix_tcp_send_error()
		case UDP_Socket: op.send.err = posix_udp_send_error()
		}
		return .Done
	}

	op.send.sent += n

	if op.send.sent < total {
		return send_exec(op)
	}

	return .Done

	sendv :: proc(socket: Any_Socket, bufs: [][]byte, to: net.Endpoint) -> (posix.FD, int) {
		assert(len(bufs) < int(max(i32)))

		msg: posix.msghdr
		msg.msg_iov    = cast([^]posix.iovec)raw_data(bufs)
		msg.msg_iovlen = i32(len(bufs))

		toaddr: posix.sockaddr_storage
		fd: posix.FD
		switch sock in socket {
		case TCP_Socket:
			fd = posix.FD(sock)
		case UDP_Socket:
			fd = posix.FD(sock)
			toaddr = endpoint_to_sockaddr(to)
			msg.msg_name    = &toaddr
			msg.msg_namelen = posix.socklen_t(toaddr.ss_len)
		}

		return fd, posix.sendmsg(fd, &msg, {.NOSIGNAL})
	}
}

@(require_results)
recv_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Recv)

	if op.recv.err != nil || .Done in op._impl.flags {
		return .Done
	}

	total: int
	bufs := slice.advance_slices(op.recv.bufs, op.recv.received)
	bufs, total = constraint_bufs_to_max_rw(op.recv.bufs)

	_, is_tcp := op.recv.socket.(net.TCP_Socket)

	sock, n := recvv(op.recv.socket, bufs, &op.recv.source)
	if n < 0 {
		if posix.errno() == .EWOULDBLOCK {
			if is_tcp && !op.recv.all && op.recv.received > 0 {
				return .Done
			}

			add_pending(op, .Read, uintptr(sock))
			link_timeout(op, op.recv.expires)
			return .Pending
		}

		if is_tcp {
			op.recv.err = posix_tcp_recv_error()
		} else {
			op.recv.err = posix_udp_recv_error()
		}

		return .Done
	}

	assert(is_tcp || op.recv.received == 0)
	op.recv.received += n

	if is_tcp && n != 0 && op.recv.received < total {
		return recv_exec(op)
	}

	return .Done

	recvv :: proc(socket: Any_Socket, bufs: [][]byte, from: ^Endpoint) -> (fd: posix.FD, n: int) {
		assert(len(bufs) < int(max(i32)))

		msg: posix.msghdr
		msg.msg_iov    = cast([^]posix.iovec)raw_data(bufs)
		msg.msg_iovlen = i32(len(bufs))

		udp: bool
		fromaddr: posix.sockaddr_storage
		switch sock in socket {
		case TCP_Socket:
			fd = posix.FD(sock)
		case UDP_Socket:
			fd = posix.FD(sock)
			udp = true
			msg.msg_name    = &fromaddr
			msg.msg_namelen = posix.socklen_t(size_of(fromaddr))
		}

		n = posix.recvmsg(fd, &msg, {.NOSIGNAL})
		if n >= 0 && udp {
			from^ = sockaddr_to_endpoint(&fromaddr)
		}

		return
	}
}

@(require_results)
sendfile_exec :: proc(op: ^Operation) -> (result: Op_Result) {
	assert(op.type == .Send_File)

	defer if result == .Done && op.sendfile._impl.mapping != nil {
		posix.munmap(raw_data(op.sendfile._impl.mapping), len(op.sendfile._impl.mapping))
	}

	if op.sendfile.err != nil || .Done in op._impl.flags {
		return .Done
	}

	when ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {
		// Doesn't have `sendfile`, emulate it with `mmap` + normal `send`.
		return sendfile_exec_emulated(op)
	} else {
		return sendfile_exec_native(op)

		@(require_results)
		sendfile_exec_native :: proc(op: ^Operation) -> Op_Result {
			nbytes := op.sendfile.nbytes
			assert(nbytes != 0)
			if nbytes == SEND_ENTIRE_FILE {
				nbytes = 0 // special value for entire file.

				// If we want progress updates we need nbytes to be the actual size, or the user
				// won't be able to check `sent < nbytes` to know if it's the final callback.
				if op.sendfile.progress_updates {
					stat: posix.stat_t
					if posix.fstat(op.sendfile.file, &stat) != .OK {
						op.sendfile.err = FS_Error(posix.errno())
						return .Done
					}
					op.sendfile.nbytes = int(stat.st_size - posix.off_t(op.sendfile.offset))
				}
			} else {
				nbytes -= op.sendfile.sent
			}

			n, ok := posix_sendfile(op.sendfile.file, op.sendfile.socket, op.sendfile.offset + op.sendfile.sent, nbytes)

			assert(n >= 0)
			op.sendfile.sent += n

			if !ok {
				op.sendfile.err = posix_tcp_send_error()
				if op.sendfile.err == .Would_Block {
					op.sendfile.err = nil
					if op.sendfile.progress_updates { op.cb(op) }
					add_pending(op, .Write, uintptr(op.sendfile.socket))
					link_timeout(op, op.sendfile.expires)
					return .Pending
				}

				return .Done
			}

			assert(op.sendfile.nbytes == SEND_ENTIRE_FILE || op.sendfile.sent == op.sendfile.nbytes)
			return .Done
		}
	}

	@(require_results)
	sendfile_exec_emulated :: proc(op: ^Operation) -> Op_Result {
		if op.sendfile.nbytes == SEND_ENTIRE_FILE {
			stat: posix.stat_t
			if posix.fstat(op.sendfile.file, &stat) != .OK {
				op.sendfile.err = FS_Error(posix.errno())
				return .Done
			}
			op.sendfile.nbytes = int(stat.st_size - posix.off_t(op.sendfile.offset))
		}

		if op.sendfile._impl.mapping == nil {
			addr := posix.mmap(nil, uint(op.sendfile.nbytes), {.READ}, {}, op.sendfile.file, posix.off_t(op.sendfile.offset))
			if addr == posix.MAP_FAILED {
				op.sendfile.err = FS_Error(posix.errno())
				return .Done
			}
			op.sendfile._impl.mapping = ([^]byte)(addr)[:op.sendfile.nbytes]
		}

		n := posix.send(
			posix.FD(op.sendfile.socket),
			raw_data(op.sendfile._impl.mapping)[op.sendfile.sent:],
			uint(min(MAX_RW, op.sendfile.nbytes - op.sendfile.sent)),
			{.NOSIGNAL},
		)
		if n < 0 {
			op.sendfile.err = posix_tcp_send_error()
			if op.sendfile.err == .Would_Block {
				op.sendfile.err = nil
				add_pending(op, .Write, uintptr(op.sendfile.socket))
				link_timeout(op, op.sendfile.expires)
				return .Pending
			}

			return .Done
		}

		op.sendfile.sent += n

		if op.sendfile.sent < op.sendfile.nbytes {
			if op.sendfile.progress_updates { op.cb(op) }
			return sendfile_exec_emulated(op)
		}

		return .Done
	}
}

@(require_results)
read_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Read)

	if op.read.err != nil || .Done in op._impl.flags {
		return .Done
	}

	to_read := op.read.buf[op.read.read:]
	to_read  = to_read[:min(MAX_RW, len(to_read))]

	res := posix.pread(op.read.handle, raw_data(to_read), len(to_read), posix.off_t(op.read.offset) + posix.off_t(op.read.read))
	if res < 0 {
		errno := posix.errno()
		if errno == .EWOULDBLOCK {
			if !op.read.all && op.read.read > 0 {
				return .Done
			}

			add_pending(op, .Read, uintptr(op.read.handle))
			link_timeout(op, op.read.expires)
			return .Pending
		}

		op.read.err = FS_Error(errno)
		return .Done
	} else if res == 0 {
		if op.read.read == 0 {
			op.read.err = .EOF
		}
		return .Done
	}

	op.read.read += res

	if op.read.read < len(op.read.buf) {
		return read_exec(op)
	}

	return .Done
}

@(require_results)
write_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Write)

	if op.write.err != nil || .Done in op._impl.flags {
		return .Done
	}

	to_write := op.write.buf[op.write.written:]
	to_write  = to_write[:min(MAX_RW, len(to_write))]

	res := posix.pwrite(op.write.handle, raw_data(to_write), len(to_write), posix.off_t(op.write.offset) + posix.off_t(op.write.written))
	if res < 0 {
		errno := posix.errno()
		if errno == .EWOULDBLOCK {
			if !op.write.all && op.write.written > 0 {
				return .Done
			}

			add_pending(op, .Write, uintptr(op.write.handle))
			link_timeout(op, op.write.expires)
			return .Pending
		}

		op.write.err = FS_Error(errno)
		return .Done
	}

	op.write.written += res

	if op.write.written < len(op.write.buf) {
		return write_exec(op)
	}

	return .Done
}

timeout_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Timeout)

	if op.timeout.duration <= 0 {
		return .Done
	}

	op.l.submitted[Queue_Identifier{ ident = uintptr(op), filter = .Timer }] = op

	op._impl.flags += {.For_Kernel}

	append_pending(op.l, kq.KEvent {
		ident  = uintptr(op),
		filter = .Timer,
		flags  = {.Add, .Enable, .One_Shot},
		fflags = {
			timer = kq.TIMER_FLAGS_NSECONDS + {.Absolute},
		},
		data  = op.l.now._nsec + i64(op.timeout.duration),
		udata = op,
	})
	return .Pending
}

open_exec :: proc(op: ^Operation) {
	assert(op.type == .Open)

	if op.open.err != nil && op.open.handle > 0 {
		posix.close(op.open.handle)
		return
	}

	if .Done in op._impl.flags {
		return
	}

	op.open.handle, op.open.err = _open_sync(op.l, op.open.path, op.open.dir, op.open.mode, op.open.perm)
}

stat_exec :: proc(op: ^Operation) {
	assert(op.type == .Stat)

	stat: posix.stat_t
	if posix.fstat(op.stat.handle, &stat) != .OK {
		op.stat.err = FS_Error(posix.errno())
		return
	}

	op.stat.type = .Undetermined
	switch {
	case posix.S_ISBLK(stat.st_mode) || posix.S_ISCHR(stat.st_mode):
		op.stat.type = .Device
	case posix.S_ISDIR(stat.st_mode):
		op.stat.type = .Directory
	case posix.S_ISFIFO(stat.st_mode) || posix.S_ISSOCK(stat.st_mode):
		op.stat.type = .Pipe_Or_Socket
	case posix.S_ISLNK(stat.st_mode):
		op.stat.type = .Symlink
	case posix.S_ISREG(stat.st_mode):
		op.stat.type = .Regular
	}

	op.stat.size = i64(stat.st_size)
}

add_pending :: proc(op: ^Operation, filter: kq.Filter, ident: uintptr) {
	debug("adding pending", op.type)
	op._impl.flags += {.For_Kernel}

	_, val, just_inserted, err := map_entry(&op.l.submitted, Queue_Identifier{ ident = ident, filter = filter })
	ensure(err == nil, "allocation failure")
	if just_inserted {
		val^ = op

		append_pending(op.l, kq.KEvent {
			filter = filter,
			ident  = ident,
			flags  = {.Add, .Enable, .One_Shot},
			udata  = op,
		})
	} else {
		debug("already have this operation on the kqueue, bundling it")

		last := val^
		for last._impl.next != nil {
			last = last._impl.next
		}
		last._impl.next = op
		op._impl.prev   = last
	}
}

append_pending :: #force_inline proc(l: ^Event_Loop, ev: kq.KEvent) {
	if !sa.append(&l.pending, ev) {
		warn("queue is full, adding to overflow, should QUEUE_SIZE be increased?")
		_, err := queue.append(&l.overflow, ev)
		ensure(err == nil, "allocation failure")
	}
}

link_timeout :: proc(op: ^Operation, expires: time.Time) {
	if expires == {} {
		return
	}

	debug(op.type, "times out at", expires)

	op._impl.flags += {.Has_Timeout}

	append_pending(op.l, kq.KEvent {
		ident  = uintptr(op),
		filter = .Timer,
		flags  = {.Add, .Enable, .One_Shot},
		fflags = {
			timer = kq.TIMER_FLAGS_NSECONDS + {.Absolute},
		},
		data  = expires._nsec,
		udata = op,
	})
}

remove_link_timeout :: proc(op: ^Operation) {
	debug("removing timeout of", op.type)
	assert(.Has_Timeout in op._impl.flags)

	append_pending(op.l, kq.KEvent {
		ident  = uintptr(op),
		filter = .Timer,
		flags  = {.Delete, .Disable, .One_Shot},
	})
}

timeout_and_delete :: proc(target: ^Operation) {
	filter: kq.Filter
	ident: uintptr
	switch target.type {
	case .Accept:
		target.accept.err = .Timeout
		filter = .Read
		ident = uintptr(target.accept.socket)
	case .Dial:
		target.dial.err = Dial_Error.Timeout
		filter = .Write
		ident = uintptr(target.dial.socket)
	case .Read:
		target.read.err = .Timeout
		filter = .Read
		ident = uintptr(target.read.handle)
	case .Write:
		target.write.err = .Timeout
		filter = .Write
		ident = uintptr(target.write.handle)
	case .Recv:
		switch sock in target.recv.socket {
		case TCP_Socket:
			target.recv.err = TCP_Recv_Error.Timeout
			ident = uintptr(sock)
		case UDP_Socket:
			target.recv.err = UDP_Recv_Error.Timeout
			ident = uintptr(sock)
		}
		filter = .Read
	case .Send:
		switch sock in target.send.socket {
		case TCP_Socket:
			target.send.err = TCP_Send_Error.Timeout
			ident = uintptr(sock)
		case UDP_Socket:
			target.send.err = UDP_Send_Error.Timeout
			ident = uintptr(sock)
		}
		filter = .Write
	case .Send_File:
		target.send.err = TCP_Send_Error.Timeout
		filter = .Write
		ident = uintptr(target.sendfile.socket)
	case .Poll:
		target.poll.result = .Timeout
		ident = uintptr(net.any_socket_to_socket(target.poll.socket))

		switch target.poll.event {
		case .Receive: filter = .Read
		case .Send:    filter = .Write
		}

	case .Timeout:
		ident  = uintptr(target)
		filter = .Timer

	case .Close:
		target.close.err = .Timeout
		return

	case .Open:
		target.open.err = .Timeout	
		return

	case .Stat:
		target.stat.err = .Timeout
		return

	case .None, ._Link_Timeout, ._Remove, ._Splice:
		return
	}

	// If there are other ops linked to this kevent, don't remove it.
	if target._impl.next != nil || target._impl.prev != nil {
		debug("removing target by pulling it out of the linked list, other ops depend on the kevent")
		assert(filter != .Timer)

		if target._impl.next != nil {
			target._impl.next._impl.prev = target._impl.prev
		}

		if target._impl.prev != nil {
			target._impl.prev._impl.next = target._impl.next
		} else {
			debug("target was the head of the list, updating map to point at new head")

			_, vp, _, err := map_entry(&target.l.submitted, Queue_Identifier{ ident = ident, filter = filter })
			ensure(err == nil, "allocation failure")
			assert(vp^ == target)
			vp^ = target._impl.next

			ev := kq.KEvent{
				filter = filter,
				ident  = ident,
				flags  = {.Add, .Enable, .One_Shot},
				udata  = target._impl.next,
			}
			if !sa.append(&target.l.pending, ev) {
				warn("just removed the head operation of a list of multiple, and the queue is full, have to force this update through inefficiently")
				// This has to happen the next time we submit or we could have udata pointing wrong.
				// Very inefficient but probably never hit.

				// Makes kevent return a receipt for our addition, so we don't take any new events from it.
				// This forces .Error to be added and data being 0 means it's added.
				ev.flags += {.Receipt}

				timeout: posix.timespec
				n, err := kq.kevent(target.l.kqueue, ([^]kq.KEvent)(&ev)[:1], ([^]kq.KEvent)(&ev)[:1], &timeout)
				assert(n   == 1)
				assert(err == nil)

				// The receipt flag makes this occur on the event.
				assert(.Error in ev.flags)
				assert(ev.data == 0)
			}
		}

	} else if .For_Kernel in target._impl.flags {
		debug("adding delete event")

		_, dval := delete_key(&target.l.submitted, Queue_Identifier{ ident = ident, filter = filter })
		assert(dval != nil)

		append_pending(target.l, kq.KEvent{
			ident  = ident,
			filter = filter,
			flags  = {.Delete, .Disable, .One_Shot},
		})
	} else {
		debug("remove without delete event, because target is not in kernel")
	}
}

@(require_results)
endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: posix.sockaddr_storage) {
	switch a in ep.address {
	case IP4_Address:
		(^posix.sockaddr_in)(&sockaddr)^ = posix.sockaddr_in {
			sin_port = u16be(ep.port),
			sin_addr = transmute(posix.in_addr)a,
			sin_family = .INET,
			sin_len = size_of(posix.sockaddr_in),
		}
		return
	case IP6_Address:
		(^posix.sockaddr_in6)(&sockaddr)^ = posix.sockaddr_in6 {
			sin6_port = u16be(ep.port),
			sin6_addr = transmute(posix.in6_addr)a,
			sin6_family = .INET6,
			sin6_len = size_of(posix.sockaddr_in6),
		}
		return
	}
	unreachable()
}

@(require_results)
sockaddr_to_endpoint :: proc(native_addr: ^posix.sockaddr_storage) -> (ep: Endpoint) {
	#partial switch native_addr.ss_family {
	case .INET:
		addr := cast(^posix.sockaddr_in)native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = IP4_Address(transmute([4]byte)addr.sin_addr),
			port    = port,
		}
	case .INET6:
		addr := cast(^posix.sockaddr_in6)native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = IP6_Address(transmute([8]u16be)addr.sin6_addr),
			port    = port,
		}
	case:
		panic("native_addr is neither IP4 or IP6 address")
	}
	return
}
