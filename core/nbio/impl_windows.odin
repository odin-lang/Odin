#+private file
package nbio

import "base:intrinsics"

import "core:container/avl"
import "core:container/pool"
import "core:container/queue"
import "core:mem"
import "core:net"
import "core:slice"
import "core:strings"
import "core:time"
import "core:path/filepath"

import win "core:sys/windows"

@(private="package")
_FULLY_SUPPORTED :: true

@(private="package")
_Event_Loop :: struct {
	iocp:       win.HANDLE,
	allocator:  mem.Allocator,
	timeouts:   avl.Tree(^Operation),
	completed:  queue.Queue(^Operation),
}

@(private="package")
_Handle :: distinct uintptr

@(private="package")
_CWD :: ~_Handle(99)

@(private="package")
MAX_RW :: mem.Gigabyte

@(private="package")
_Operation :: struct {
	over:    win.OVERLAPPED,
	timeout: ^Operation,
}

@(private="package")
_Accept :: struct {
	// Space that gets the local and remote address written into it.
	addrs: [(size_of(win.sockaddr_in6)+16)*2]byte,
}

@(private="package")
_Close :: struct {}

@(private="package")
_Dial :: struct {
	addr: win.SOCKADDR_STORAGE_LH,
}

@(private="package")
_Read :: struct {}

@(private="package")
_Write :: struct {}

@(private="package")
_Send :: struct {
	small_bufs: [1][]byte,
}

@(private="package")
_Recv :: struct {
	source:     win.SOCKADDR_STORAGE_LH,
	source_len: win.INT,
	small_bufs: [1][]byte,
	flags:      win.DWORD,
}

@(private="package")
_Timeout :: struct {
	expires: time.Time,
	target:  ^Operation,
}

@(private="package")
_Poll :: struct {
	wait_handle: win.HANDLE,
}

@(private="package")
_Send_File :: struct {}

@(private="package")
_Remove :: struct {}

@(private="package")
_Link_Timeout :: struct {}

@(private="package")
_Splice :: struct {}

@(private="package")
_Open :: struct {}

@(private="package")
_Stat :: struct {}

@(private="package")
_init :: proc(l: ^Event_Loop, alloc: mem.Allocator) -> (err: General_Error) {
	l.allocator = alloc

	mem_err: mem.Allocator_Error
	if mem_err = queue.init(&l.completed, allocator = alloc); mem_err != nil {
		err = .Allocation_Failed
		return
	}
	defer if err != nil { queue.destroy(&l.completed) }

	avl.init(&l.timeouts, timeouts_cmp, alloc)

	win.ensure_winsock_initialized()

	l.iocp = win.CreateIoCompletionPort(win.INVALID_HANDLE_VALUE, nil, 0, 1)
	if l.iocp == nil {
		err = General_Error(win.GetLastError())
		return
	}

	return

	timeouts_cmp :: #force_inline proc(a, b: ^Operation) -> slice.Ordering {
		switch {
		case a.timeout._impl.expires._nsec < b.timeout._impl.expires._nsec:
			return .Less
		case a.timeout._impl.expires._nsec > b.timeout._impl.expires._nsec:
			return .Greater
		case uintptr(a) < uintptr(b):
			return .Less
		case uintptr(a) > uintptr(b):
			return .Greater
		case:
			assert(a == b)
			return .Equal
		}
	}
}

@(private="package")
_destroy :: proc(l: ^Event_Loop) {
	queue.destroy(&l.completed)
	avl.destroy(&l.timeouts)
	win.CloseHandle(l.iocp)
}

@(private="package")
__tick :: proc(l: ^Event_Loop, timeout: time.Duration) -> (err: General_Error) {
	debug("tick")

	l.now = time.now()
	next_timeout := check_timeouts(l)

	// Prevent infinite loop when callback adds to completed by storing length.
	n := queue.len(l.completed)
	if n > 0 {
		for _ in 0 ..< n {
			op := queue.pop_front(&l.completed)
			handle_completed(op)
		}
	}

	if pool.num_outstanding(&l.operation_pool) == 0 { return nil }

	actual_timeout := win.INFINITE
	if queue.len(l.completed) > 0 {
		actual_timeout = 0
	} else if timeout >= 0 {
		actual_timeout = win.DWORD(timeout / time.Millisecond)
	}
	if nt, ok := next_timeout.?; ok {
		actual_timeout = min(actual_timeout, win.DWORD(nt / time.Millisecond))
	}

	for {
		QUEUE_SIZE :: 256
		events: [QUEUE_SIZE]win.OVERLAPPED_ENTRY
		entries_removed: win.ULONG
		if !win.GetQueuedCompletionStatusEx(l.iocp, &events[0], len(events), &entries_removed, actual_timeout, false) {
			if terr := win.GetLastError(); terr != win.WAIT_TIMEOUT {
				err = General_Error(terr)
				return
			}
		}

		if actual_timeout > 0 {
			// We may have just waited some time, lets update the current time.
			l.now = time.now()
		}

		if entries_removed > 0 {
			debug(int(entries_removed), "operations were completed")
		}

		for event in events[:entries_removed] {
			if event.lpCompletionKey == COMPLETION_KEY_WAKE_UP { continue }
			assert(event.lpOverlapped != nil)
			op := container_of(container_of(event.lpOverlapped, _Operation, "over"), Operation, "_impl")
			handle_completed(op)
		}

		if entries_removed < QUEUE_SIZE {
			break
		}

		// `events` was filled up, get more.
		debug("GetQueuedCompletionStatusEx filled entire events buffer, getting more")
		actual_timeout = 0
	}

	return nil

	check_timeouts :: proc(l: ^Event_Loop) -> (expires: Maybe(time.Duration)) {
		curr := l.now

		if avl.len(&l.timeouts) == 0 {
			return
		}

		debug(avl.len(&l.timeouts), "timeouts", "threshold", curr)

		iter := avl.iterator(&l.timeouts, .Forward)
		for node in avl.iterator_next(&iter) {
			op := node.value
			cexpires := time.diff(curr, op.timeout._impl.expires)

			debug("expires after", cexpires)

			removed := op._impl.timeout == (^Operation)(REMOVED)
			done    := cexpires <= 0
			if removed {
				debug("timeout removed!")
			} else if done {
				debug("timeout done!")
				handle_completed(op)
			}
			if removed || done {
				avl.remove_node(&l.timeouts, node)
				continue
			}

			expires = cexpires
			debug("first timeout in the future is at", op.timeout._impl.expires, "after", cexpires)
			return
		}

		return
	}

	handle_completed :: proc(op: ^Operation) {
		debug("handling", op.type)

		if op._impl.timeout == (^Operation)(REMOVED) {
			debug(op.type, "was removed")

			// Set an error, and call the internal callback.
			// This way resources are cleaned up properly, for example the result socket for dial.
			// If we just do nothing it will be leaked.

			if op._impl.over.Internal == nil {
				// There is no error from the kernel, set one ourselves.
				// This needs to be an NTSTATUS code, not a win32 error number.
				STATUS_REQUEST_ABORTED :: 0xC023000C
				op._impl.over.Internal = (^win.c_ulong)(uintptr(STATUS_REQUEST_ABORTED))
			}
		}

		result := Op_Result.Done
		switch op.type {
		case .Read:
			result = read_callback(op)
		case .Recv:
			result = recv_callback(op)
			if result == .Done {
				maybe_callback(op)
				if len(op.recv.bufs) > 1 {
					delete(op.recv.bufs, op.l.allocator)
				}
				cleanup(op)
				return
			}
		case .Write:
			result = write_callback(op)
		case .Send:
			result = send_callback(op)
			if result == .Done {
				maybe_callback(op)
				if len(op.send.bufs) > 1 {
					delete(op.send.bufs, op.l.allocator)
				}
				cleanup(op)
				return
			}
		case .Send_File:
			result = sendfile_callback(op)
		case .Accept:
			accept_callback(op)
		case .Dial:
			dial_callback(op)
		case .Poll:
			poll_callback(op)
		case .Timeout, .Open, .Stat, .Close:
			// no-op.
		case .None, ._Link_Timeout, ._Remove, ._Splice:
			fallthrough
		case:
			unreachable()
		}

		if result == .Pending {
			assert(op._impl.timeout != (^Operation)(REMOVED))
			debug(op.type, "pending")
			return
		}

		maybe_callback(op)
		cleanup(op)

		maybe_callback :: proc(op: ^Operation) {
			if op._impl.timeout == (^Operation)(REMOVED) {
				debug(op.type, "done but removed")
			} else {
				debug(op.type, "done")
				op.cb(op)

				if op._impl.timeout != nil {
					debug("cancelling timeout of", op.type)
					op._impl.timeout.timeout._impl.target = nil
					_remove(op._impl.timeout)
				}
			}
		}

		cleanup :: proc(op: ^Operation) {
			if !op.detached {
				pool.put(&op.l.operation_pool, op)
			}
		}
	}

}

@(private="package")
_exec :: proc(op: ^Operation) {
	assert(op.l == &_tls_event_loop)

	result: Op_Result
	switch op.type {
	case .Accept:    result = accept_exec(op)
	case .Close:     close_exec(op); result = .Done
	case .Dial:      result = dial_exec(op)
	case .Recv:      result = recv_exec(op)
	case .Send:      result = send_exec(op)
	case .Send_File: result = sendfile_exec(op)
	case .Read:      result = read_exec(op)
	case .Write:     result = write_exec(op)
	case .Timeout:   result = timeout_exec(op)
	case .Poll:      result = poll_exec(op)
	case .Open:      open_exec(op); result = .Done
	case .Stat:      stat_exec(op); result = .Done
	case .None, ._Link_Timeout, ._Remove, ._Splice:
		unreachable()
	}

	switch result {
	case .Pending:
		// no-op, in kernel.
		debug("exec", op.type, "pending")
	case .Done:
		debug("exec", op.type, "done immediately")
		_, err := queue.append(&op.l.completed, op) // Got result, handle it next tick.
		ensure(err == nil, "allocation failure")
	}
}

@(private="package")
_open_sync :: proc(l: ^Event_Loop, name: string, dir: Handle, mode: File_Flags, perm: Permissions) -> (handle: Handle, err: FS_Error) {
	if len(name) == 0 {
		err = .Invalid_Argument
		return
	}

	dir := dir

	is_abs := filepath.is_abs(name)
	is_cwd: bool
	cwd_path: win.wstring
	if !is_abs && dir == CWD {
		is_cwd = true

		cwd_len := win.GetCurrentDirectoryW(0, nil)
		assert(cwd_len > 0)
		cwd_buf, cwd_err := make([]u16, cwd_len, l.allocator)
		if cwd_err != nil { return INVALID_HANDLE, .Allocation_Failed }
		cwd_len = win.GetCurrentDirectoryW(cwd_len, raw_data(cwd_buf))
		assert(int(cwd_len) == len(cwd_buf)-1)
		cwd_path = win.wstring(raw_data(cwd_buf))

		dir = Handle(win.CreateFileW(
			cwd_path,
			win.GENERIC_READ,
			win.FILE_SHARE_READ|win.FILE_SHARE_WRITE,
			nil,
			win.OPEN_EXISTING,
			win.FILE_FLAG_BACKUP_SEMANTICS,
			nil,
		))
		if dir == INVALID_HANDLE {
			err = FS_Error(win.GetLastError())
			return
		}
	}
	defer if is_cwd {
		delete(cwd_path, l.allocator)
		win.CloseHandle(win.HANDLE(dir))
	}

	path, was_alloc := _normalize_path(name, l.allocator)
	defer if was_alloc { delete(path, l.allocator) }

	wpath := win.utf8_to_utf16(path, l.allocator)
	defer delete(wpath, l.allocator)

	if path == "" || wpath == nil {
		return INVALID_HANDLE, .Allocation_Failed
	}

	path_len := len(wpath) * 2
	if path_len > int(max(u16)) {
		err = .Invalid_Argument
		return
	}

	access: u32
	switch mode & {.Read, .Write} {
	case {.Read}:         access = win.FILE_GENERIC_READ
	case {.Write}:        access = win.FILE_GENERIC_WRITE
	case {.Read, .Write}: access = win.FILE_GENERIC_READ | win.FILE_GENERIC_WRITE
	}

	if .Create in mode {
		access |= win.FILE_GENERIC_WRITE
	}
	if .Append in mode {
		access &~= win.FILE_GENERIC_WRITE
		access |= win.FILE_APPEND_DATA
	}
	share_mode := u32(win.FILE_SHARE_READ | win.FILE_SHARE_WRITE)

	create_mode: u32 = win.FILE_OPEN
	switch {
	case mode & {.Create, .Excl} == {.Create, .Excl}:
		create_mode = win.FILE_CREATE
	case mode & {.Create, .Trunc} == {.Create, .Trunc}:
		create_mode = win.FILE_OVERWRITE_IF
	case mode & {.Create} == {.Create}:
		create_mode = win.FILE_OPEN_IF
	case mode & {.Trunc} == {.Trunc}:
		create_mode = win.FILE_OVERWRITE
	}

	attrs: u32 = win.FILE_ATTRIBUTE_NORMAL

	if .Write_User not_in perm {
		attrs = win.FILE_ATTRIBUTE_READONLY
		if create_mode == win.FILE_OVERWRITE_IF {
			// NOTE(bill): Open has just asked to create a file in read-only mode.
			// If the file already exists, to make it akin to a *nix open call,
			// the call preserves the existing permissions.

			h: win.HANDLE
			io_status: win.IO_STATUS_BLOCK
			status := win.NtCreateFile(
				&h,
				access,
				&{
					Length = size_of(win.OBJECT_ATTRIBUTES),
					RootDirectory = is_abs ? nil : win.HANDLE(dir),
					ObjectName = &{
						Length        = u16(path_len),
						MaximumLength = u16(path_len),
						Buffer        = raw_data(wpath),
					},
				},
				&io_status,
				nil,
				win.FILE_ATTRIBUTE_NORMAL,
				share_mode,
				win.FILE_OVERWRITE,
				0,
				nil,
				0,
			)
			syserr := win.System_Error(win.RtlNtStatusToDosError(status))
			#partial switch syserr {
			case .FILE_NOT_FOUND, .BAD_NETPATH, .PATH_NOT_FOUND:
				// File does not exists, create the file
			case .SUCCESS:
				association_err: Association_Error
				handle, association_err = _associate_handle(uintptr(h), l)
				// This shouldn't fail, we just created this file, with correct flags.
				assert(association_err != nil)
				return
			case:
				err = FS_Error(syserr)
				return
			}
		}
	}

	h: win.HANDLE
	io_status: win.IO_STATUS_BLOCK
	status := win.NtCreateFile(
		&h,
		access,
		&{
			Length = size_of(win.OBJECT_ATTRIBUTES),
			RootDirectory = is_abs ? nil : win.HANDLE(dir),
			ObjectName = &{
				Length        = u16(path_len),
				MaximumLength = u16(path_len),
				Buffer        = raw_data(wpath),
			},
		},
		&io_status,
		nil,
		attrs,
		share_mode,
		create_mode,
		0,
		nil,
		0,
	)
	syserr := win.System_Error(win.RtlNtStatusToDosError(status))
	#partial switch syserr {
	case .SUCCESS:
		association_err: Association_Error
		handle, association_err = _associate_handle(uintptr(h), l)
		// This shouldn't fail, we just created this file, with correct flags.
		assert(association_err == nil)
		return
	case:
		err = FS_Error(syserr)
		return
	}

	@(require_results)
	_normalize_path :: proc(path: string, allocator := context.allocator) -> (fixed: string, allocated: bool) {
		// An UNC path or relative, just replace slashes.
		if strings.has_prefix(path, `\\`) || !filepath.is_abs(path) {
			return strings.replace_all(path, `/`, `\`)
		}

		path_buf, err := make([]byte, len(PREFIX)+len(path)+1, allocator)
		if err != nil { return }
		defer if !allocated { delete(path_buf, allocator) }

		PREFIX :: `\??`
		copy(path_buf, PREFIX)
		n := len(path)
		r, w := 0, len(PREFIX)
		for r < n {
			switch {
			case filepath.is_separator(path[r]):
				r += 1
			case path[r] == '.' && (r+1 == n || filepath.is_separator(path[r+1])):
			// \.\
				r += 1
			case r+1 < n && path[r] == '.' && path[r+1] == '.' && (r+2 == n || filepath.is_separator(path[r+2])):
			// Skip \..\ paths
				return path, false
			case:
				path_buf[w] = '\\'
				w += 1
				for r < n && !filepath.is_separator(path[r]) {
					path_buf[w] = path[r]
					r += 1
					w += 1
				}
			}
		}

		// Root directories require a trailing \
		if w == len(`\\?\c:`) {
			path_buf[w] = '\\'
			w += 1
		}

		allocated = true
		fixed = string(path_buf[:w])
		return
	}
}

@(private="package")
_listen :: proc(socket: TCP_Socket, backlog := 1000) -> (err: Listen_Error) {
	if res := win.listen(win.SOCKET(socket), i32(backlog)); res == win.SOCKET_ERROR {
		err = net._listen_error()
	}
	return
}

@(private="package")
_create_socket :: proc(
	l: ^Event_Loop,
	family: Address_Family,
	protocol: Socket_Protocol,
) -> (
	socket: Any_Socket,
	err: Create_Socket_Error,
) {
	socket = net.create_socket(family, protocol) or_return

	association_err := _associate_socket(socket, l)
	// Network unreachable would've happened on creation too.
	// Not possible to associate or invalid handle can't happen because we controlled creation.
	assert(association_err == nil)

	return
}

@(private="package")
_remove :: proc(target: ^Operation) {
	debug("remove", target.type)

	if target._impl.timeout == (^Operation)(REMOVED) {
		return
	}

	if target._impl.timeout != nil {
		_remove(target._impl.timeout)
	}

	target._impl.timeout = (^Operation)(REMOVED)

	switch target.type {
	case .Poll:
		win.UnregisterWaitEx(target.poll._impl.wait_handle, nil)
		target.poll._impl.wait_handle = nil

		ok := win.PostQueuedCompletionStatus(
			target.l.iocp,
			0,
			0,
			&target._impl.over,
		)
		ensure(ok == true, "unexpected PostQueuedCompletionStatus error")
		return

	case .Timeout:
		if avl.remove_value(&target.l.timeouts, target) {
			debug("removed timeout directly")
			if !target.detached {
				pool.put(&target.l.operation_pool, target)
			}
		} else {
			debug("timeout is in completed queue, will be picked up there")
		}
		return

	case .Close, .Open, .Stat:
		// Synchronous ops, picked up in handler.
		return

	case .Accept, .Dial, .Read, .Recv, .Send, .Write, .Send_File:
		if is_pending(target._impl.over) {
			handle := operation_handle(target)
			assert(handle != win.INVALID_HANDLE)
			ok := win.CancelIoEx(handle, &target._impl.over)
			if !ok {
				err := win.System_Error(win.GetLastError())
				#partial switch err {
				case .NOT_FOUND:
					debug("Remove: Cancel", target.type, "NOT_FOUND")
				case .INVALID_HANDLE:
					debug("Remove: Cancel", target.type, "INVALID_HANDLE") // Likely closed already.
				case:
					assert(false, "unexpected CancelIoEx error")
				}
			}
		}

	case ._Remove:
		panic("can't remove a removal")

	case .None, ._Splice, ._Link_Timeout:
		fallthrough
	case:
		unreachable()
	}
}

@(private="package")
_associate_handle :: proc(handle: uintptr, l: ^Event_Loop) -> (Handle, Association_Error) {
	handle_iocp := win.CreateIoCompletionPort(win.HANDLE(handle), l.iocp, 0, 0)
	if handle_iocp != l.iocp {
		return INVALID_HANDLE, .Not_Possible_To_Associate
	}

	cmode: byte
	cmode |= win.FILE_SKIP_COMPLETION_PORT_ON_SUCCESS
	cmode |= win.FILE_SKIP_SET_EVENT_ON_HANDLE
	ok := win.SetFileCompletionNotificationModes(win.HANDLE(handle), cmode)

	// This is an assertion because I don't believe this can happen when we just successfully
	// called `CreateIoCompletionPort`.
	assert(ok == true, "unexpected SetFileCompletionNotificationModes error")

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

	_, err := _associate_handle(uintptr(net.any_socket_to_socket(socket)), l)
	return err
}

@(private="package")
_wake_up :: proc(l: ^Event_Loop) {
	win.PostQueuedCompletionStatus(
		l.iocp,
		0,
		COMPLETION_KEY_WAKE_UP,
		nil,
	)
}

// Start file private.

REMOVED :: rawptr(max(uintptr)-1)

INVALID_HANDLE :: Handle(win.INVALID_HANDLE)

COMPLETION_KEY_WAKE_UP :: 69

Op_Result :: enum {
	Done,
	Pending,
}

operation_handle :: proc(op: ^Operation) -> win.HANDLE {
	switch op.type {
	case .Accept:          return win.HANDLE(uintptr(op.accept.socket))
	case .Close:
		switch fd in op.close.subject {
		case TCP_Socket: return win.HANDLE(uintptr(fd))
		case UDP_Socket: return win.HANDLE(uintptr(fd))
		case Handle:     return win.HANDLE(uintptr(fd))
		case:
			unreachable()
		}
	case .Dial:            return win.HANDLE(uintptr(op.dial.socket))
	case .Read:            return win.HANDLE(op.read.handle)
	case .Write:           return win.HANDLE(op.write.handle)
	case .Recv:            return win.HANDLE(uintptr(net.any_socket_to_socket(op.recv.socket)))
	case .Send:            return win.HANDLE(uintptr(net.any_socket_to_socket(op.send.socket)))
	case .Send_File:       return win.HANDLE(uintptr(net.any_socket_to_socket(op.sendfile.socket)))
	case .Poll:            return win.HANDLE(uintptr(net.any_socket_to_socket(op.poll.socket)))
	case .Stat:            return win.HANDLE(uintptr(op.stat.handle))

	case .Timeout, .Open, ._Splice, ._Link_Timeout, ._Remove, .None:
		return win.INVALID_HANDLE
	case:
		unreachable()
	}
}

close_exec :: proc(op: ^Operation) {
	assert(op.type == .Close)

	switch h in op.close.subject {
	case Handle:
		if !win.CloseHandle(win.HANDLE(h)) {
			op.close.err = FS_Error(win.GetLastError())
		}
	case TCP_Socket:
		if win.closesocket(win.SOCKET(h)) != win.NO_ERROR {
			op.close.err = FS_Error(win.WSAGetLastError())
		}
	case UDP_Socket:
		if win.closesocket(win.SOCKET(h)) != win.NO_ERROR {
			op.close.err = FS_Error(win.WSAGetLastError())
		}
	case:
		op.close.err = .Invalid_Argument
		return
	}
}

@(require_results)
accept_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Accept)
	assert(is_fresh(op._impl.over))

	family := Address_Family.IP4
	{
		ep, err := bound_endpoint(op.accept.socket)
		if err != nil {
			op.accept.err = net._accept_error()
			return .Done
		}

		if _, is_ip6 := ep.address.(IP6_Address); is_ip6 {
			family = .IP6
		}
	}

	client, err := _create_socket(op.l, family, .TCP)
	if err != nil {
		op.accept.err = net._accept_error()
		return .Done
	}


	op.accept.client = client.(TCP_Socket)

	received: win.DWORD
	if !win.AcceptEx(
		win.SOCKET(op.accept.socket),
		win.SOCKET(op.accept.client),
		&op.accept._impl.addrs,
		0,
		size_of(win.sockaddr_in6) + 16,
		size_of(win.sockaddr_in6) + 16,
		&received,
		&op._impl.over,
	) {
		if op._impl.over.Internal == nil {
			op.accept.err = net._accept_error()
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.accept.expires)
			return .Pending
		}
	}

	return .Done
}

accept_callback :: proc(op: ^Operation) {
	assert(op.type == .Accept)

	defer if op.accept.err != nil {
		win.closesocket(win.SOCKET(op.accept.client))
	}

	if op.accept.err != nil {
		return
	}

	_, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
		local_addr: ^win.sockaddr
		local_addr_len: win.INT
		remote_addr: ^win.sockaddr
		remote_addr_len: win.INT
		win.GetAcceptExSockaddrs(
			&op.accept._impl.addrs,
			0,
			size_of(win.sockaddr_in6) + 16,
			size_of(win.sockaddr_in6) + 16,
			&local_addr,
			&local_addr_len,
			&remote_addr,
			&remote_addr_len,
		)

		assert(remote_addr_len <= size_of(win.SOCKADDR_STORAGE_LH))
		op.accept.client_endpoint = sockaddr_to_endpoint((^win.SOCKADDR_STORAGE_LH)(remote_addr))

		// enables getsockopt, setsockopt, getsockname, getpeername, etc.
		win.setsockopt(win.SOCKET(op.accept.client), win.SOL_SOCKET, win.SO_UPDATE_ACCEPT_CONTEXT, nil, 0)

	case .OPERATION_ABORTED:
		// This error could also happen when the user calls close on the socket.
		if check_timed_out(op, op.accept.expires) {
			op.accept.err = Accept_Error.Timeout
			return
		}
		fallthrough

	case:
		win.SetLastError(win.DWORD(err))
		op.accept.err = net._accept_error()
	}
}

@(require_results)
dial_exec :: proc(op: ^Operation) -> (result: Op_Result) {
	assert(op.type == .Dial)
	assert(is_fresh(op._impl.over))

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

	sockaddr := endpoint_to_sockaddr({IP6_Any if family == .IP6 else net.IP4_Any, 0})
	res      := win.bind(win.SOCKET(op.dial.socket), &sockaddr, size_of(sockaddr))
	if res < 0 {
		op.dial.err = net._bind_error()
		win.closesocket(win.SOCKET(op.dial.socket))
		return .Done
	}

	op.dial._impl.addr = endpoint_to_sockaddr(op.dial.endpoint)

	connect_ex: win.LPFN_CONNECTEX
	load_socket_fn(win.SOCKET(op.dial.socket), win.WSAID_CONNECTEX, &connect_ex)

	transferred: win.DWORD
	if !connect_ex(
		win.SOCKET(op.dial.socket),
		&op.dial._impl.addr,
		size_of(op.dial._impl.addr),
		nil,
		0,
		&transferred,
		&op._impl.over,
	) {
		if op._impl.over.Internal == nil {
			op.dial.err = net._dial_error()
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.dial.expires)
			return .Pending
		}

		return .Done
	}

	return .Done
}

dial_callback :: proc(op: ^Operation) {
	assert(op.type == .Dial)

	defer if op.dial.err != nil {
		win.closesocket(win.SOCKET(op.dial.socket))
	}

	if op.dial.err != nil {
		return
	}

	_, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
		// enables getsockopt, setsockopt, getsockname, getpeername, etc.
		win.setsockopt(win.SOCKET(op.dial.socket), win.SOL_SOCKET, win.SO_UPDATE_CONNECT_CONTEXT, nil, 0)

	case .OPERATION_ABORTED:
		op.dial.err = Dial_Error.Timeout

	case:
		win.SetLastError(win.DWORD(err))
		op.dial.err = net._dial_error()
	}
}

@(require_results)
read_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Read)
	op._impl.over = {} // Can be called multiple times.

	op._impl.over.OffsetFull = u64(op.read.offset) + u64(op.read.read)

	to_read := op.read.buf[op.read.read:]

	read: win.DWORD
	if !win.ReadFile(
		win.HANDLE(op.read.handle),
		raw_data(to_read),
		win.DWORD(min(len(to_read), MAX_RW)),
		&read,
		&op._impl.over,
	) {
		assert(read == 0)
		if op._impl.over.Internal == nil {
			op.read.err = FS_Error(win.GetLastError())
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.read.expires)
			return .Pending
		}
	}

	assert(uintptr(read) == uintptr(op._impl.over.InternalHigh))
	return .Done
}

@(require_results)
read_callback :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Read)

	if op.read.err != nil {
		return .Done
	}

	n, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
	case .OPERATION_ABORTED:
		// This error could also happen when the user calls close on the handle.
		if check_timed_out(op, op.read.expires) {
			op.read.err = .Timeout
			return .Done
		}
		fallthrough
	case .HANDLE_EOF:
		if op.read.read == 0 {
			op.read.err = .EOF
			return .Done
		}
	case:
		op.read.err = FS_Error(err)
		return .Done
	}

	op.read.read += n
	if op.read.all && op.read.read < len(op.read.buf) {
		switch read_exec(op) {
		case .Done:    return read_callback(op)
		case .Pending: return .Pending
		}
	}

	return .Done
}

@(require_results)
write_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Write)
	op._impl.over = {} // Can be called multiple times.

	op._impl.over.OffsetFull = u64(op.write.offset) + u64(op.write.written)

	to_write := op.write.buf[op.write.written:]

	written: win.DWORD
	if !win.WriteFile(
		win.HANDLE(op.write.handle),
		raw_data(to_write),
		win.DWORD(min(len(to_write), MAX_RW)),
		&written,
		&op._impl.over,
	) {
		assert(written == 0)
		if op._impl.over.Internal == nil {
			op.write.err = FS_Error(win.GetLastError())
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.write.expires)
			return .Pending
		}
	}

	assert(uintptr(written) == uintptr(op._impl.over.InternalHigh))
	return .Done
}

@(require_results)
write_callback :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Write)

	if op.write.err != nil {
		return .Done
	}

	n, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
	case .OPERATION_ABORTED:
		// This error could also happen when the user calls close on the handle.
		if check_timed_out(op, op.write.expires) {
			op.write.err = .Timeout
			return .Done
		}
		fallthrough
	case:
		op.write.err = FS_Error(err)
		return .Done
	}

	op.write.written += n
	if op.write.all && op.write.written < len(op.write.buf) {
		switch write_exec(op) {
		case .Done:    return write_callback(op)
		case .Pending: return .Pending
		}
	}

	return .Done
}

@(require_results)
recv_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Recv)
	op._impl.over = {} // Can be called multiple times.

	if op.recv.err != nil {
		return .Done
	}

	bufs    := slice.advance_slices(op.recv.bufs, op.recv.received)
	bufs, _  = constraint_bufs_to_max_rw(op.recv.bufs)

	win_bufs := ([^]win.WSABUF)(intrinsics.alloca(size_of(win.WSABUF) * len(bufs), align_of(win.WSABUF)))
	for buf, i in bufs {
		assert(i64(len(buf)) < i64(max(u32)))
		win_bufs[i] = {len=u32(len(buf)), buf=raw_data(buf)}
	}

	status: win.c_int
	switch sock in op.recv.socket {
	case TCP_Socket:
		status = win.WSARecv(
			win.SOCKET(sock),
			win_bufs,
			u32(len(bufs)),
			nil,
			&op.recv._impl.flags,
			win.LPWSAOVERLAPPED(&op._impl.over),
			nil,
		)
	case UDP_Socket:
		op.recv._impl.source_len = size_of(op.recv._impl.source)
		status = win.WSARecvFrom(
			win.SOCKET(sock),
			win_bufs,
			u32(len(bufs)),
			nil,
			&op.recv._impl.flags,
			(^win.sockaddr)(&op.recv._impl.source),
			&op.recv._impl.source_len,
			win.LPWSAOVERLAPPED(&op._impl.over),
			nil,
		)
	}

	if status == win.SOCKET_ERROR {
		if op._impl.over.Internal == nil {
			switch _ in op.recv.socket {
			case TCP_Socket: op.recv.err = net._tcp_recv_error()
			case UDP_Socket: op.recv.err = net._udp_recv_error()
			}
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.recv.expires)
			return .Pending
		}
	}

	return .Done
}

@(require_results)
recv_callback :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Recv)

	if op.recv.err != nil {
		return .Done
	}

	n, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
	case .OPERATION_ABORTED:
		// This error could also happen when the user calls close on the socket.
		if check_timed_out(op, op.recv.expires) {
			switch _ in op.recv.socket {
			case TCP_Socket: op.recv.err = net.TCP_Recv_Error.Timeout
			case UDP_Socket: op.recv.err = net.UDP_Recv_Error.Timeout
			}
			return .Done
		}
		fallthrough
	case:
		win.SetLastError(win.DWORD(err))
		switch _ in op.recv.socket {
		case TCP_Socket: op.recv.err = net._tcp_recv_error()
		case UDP_Socket: op.recv.err = net._udp_recv_error()
		}
		return .Done
	}

	op.recv.received += n

	switch sock in op.recv.socket {
	case TCP_Socket:
		if n == 0 {
			// Connection closed.
			return .Done
		}

		if op.recv.all {
			total: int
			for buf in op.recv.bufs {
				total += len(buf)
			}

			if op.recv.received < total {
				switch recv_exec(op) {
				case .Done:    return recv_callback(op)
				case .Pending: return .Pending
				}
			}
		}

	case UDP_Socket:
		assert(op.recv._impl.source_len > 0)
		op.recv.source = sockaddr_to_endpoint(&op.recv._impl.source)
	}

	return .Done
}

@(require_results)
send_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Send)
	op._impl.over = {} // Can be called multiple times.

	if op.send.err != nil {
		return .Done
	}

	bufs    := slice.advance_slices(op.send.bufs, op.send.sent)
	bufs, _  = constraint_bufs_to_max_rw(op.send.bufs)

	win_bufs := ([^]win.WSABUF)(intrinsics.alloca(size_of(win.WSABUF) * len(bufs), align_of(win.WSABUF)))
	for buf, i in bufs {
		assert(i64(len(buf)) < i64(max(u32)))
		win_bufs[i] = {len=u32(len(buf)), buf=raw_data(buf)}
	}

	status: win.c_int
	switch sock in op.send.socket {
	case TCP_Socket:
		status = win.WSASend(
			win.SOCKET(sock),
			win_bufs,
			u32(len(bufs)),
			nil,
			0,
			win.LPWSAOVERLAPPED(&op._impl.over),
			nil,
		)
	case UDP_Socket:
		addr := endpoint_to_sockaddr(op.send.endpoint)
		status = win.WSASendTo(
			win.SOCKET(sock),
			win_bufs,
			u32(len(bufs)),
			nil,
			0,
			(^win.sockaddr)(&addr),
			size_of(addr),
			win.LPWSAOVERLAPPED(&op._impl.over),
			nil,
		)
	}

	if status == win.SOCKET_ERROR {
		if op._impl.over.Internal == nil {
			switch _ in op.send.socket {
			case TCP_Socket: op.send.err = net._tcp_send_error()
			case UDP_Socket: op.send.err = net._udp_send_error()
			}
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.send.expires)
			return .Pending
		}
	}

	return .Done
}

@(require_results)
send_callback :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Send)

	if op.send.err != nil {
		return .Done
	}

	n, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
	case .OPERATION_ABORTED:
		// This error could also happen when the user calls close on the socket.
		if check_timed_out(op, op.send.expires) {
			switch _ in op.send.socket {
			case TCP_Socket: op.send.err = net.TCP_Send_Error.Timeout
			case UDP_Socket: op.send.err = net.UDP_Send_Error.Timeout
			}
			return .Done
		}
		fallthrough
	case:
		win.SetLastError(win.DWORD(err))
		switch _ in op.send.socket {
		case TCP_Socket: op.send.err = net._tcp_send_error()
		case UDP_Socket: op.send.err = net._udp_send_error()
		}
		return .Done
	}

	op.send.sent += n

	if op.send.all {
		total: int
		for buf in op.send.bufs {
			total += len(buf)
		}

		if op.send.sent < total {
			switch send_exec(op) {
			case .Done:    return send_callback(op)
			case .Pending: return .Pending
			}
		}
	}

	return .Done
}

@(require_results)
sendfile_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Send_File)
	op._impl.over = {} // Can be called multiple times.

	if op.sendfile.nbytes == SEND_ENTIRE_FILE {
		type, size, stat_err := stat(op.sendfile.file)
		if stat_err != nil {
			op.sendfile.err = stat_err
			return .Done
		}

		op.sendfile.nbytes = int(size - i64(op.sendfile.offset))
		if type != .Regular || op.sendfile.nbytes <= 0 {
			op.sendfile.err = FS_Error.Invalid_Argument
			return .Done
		}
	}

	op._impl.over.OffsetFull = u64(op.sendfile.offset) + u64(op.sendfile.sent)

	if !win.TransmitFile(
		win.SOCKET(op.sendfile.socket),
		win.HANDLE(op.sendfile.file),
		u32(min(op.sendfile.nbytes - op.sendfile.sent, MAX_RW)),
		0,
		&op._impl.over,
		nil,
		0,
	) {
		if op._impl.over.Internal == nil {
			op.sendfile.err = net._tcp_send_error()
		} else if is_pending(op._impl.over) {
			link_timeout(op, op.sendfile.expires)
			return .Pending
		}
	}

	return .Done
}

@(require_results)
sendfile_callback :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Send_File)

	if op.sendfile.err != nil {
		return .Done
	}

	n, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
	case .OPERATION_ABORTED:
		// This error could also happen when the user calls close on the socket.
		if check_timed_out(op, op.sendfile.expires) {
			op.sendfile.err = TCP_Send_Error.Timeout
			return .Done
		}
		fallthrough
	case:
		win.SetLastError(win.DWORD(err))
		op.sendfile.err = net._tcp_send_error()
		return .Done
	}

	op.sendfile.sent += n
	if op.sendfile.sent < op.sendfile.nbytes {
		switch sendfile_exec(op) {
		case .Done:
			return sendfile_callback(op)
		case .Pending:
			if op.sendfile.progress_updates { op.cb(op) }
			return .Pending
		}
	}

	return .Done
}

@(require_results)
poll_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Poll)

	events: i32 = win.FD_CLOSE
	switch op.poll.event {
	case .Send:    events |= win.FD_WRITE|win.FD_CONNECT
	case .Receive: events |= win.FD_READ|win.FD_ACCEPT
	case:
		op.poll.result = .Invalid_Argument
		return .Done
	}

	op._impl.over.hEvent = win.WSACreateEvent()
	if win.WSAEventSelect(
		win.SOCKET(net.any_socket_to_socket(op.poll.socket)),
		op._impl.over.hEvent,
		events,
	) != 0 {
		#partial switch win.System_Error(win.GetLastError()) {
		case .WSAEINVAL, .WSAENOTSOCK: op.poll.result = .Invalid_Argument
		case:                          op.poll.result = .Error
		}
		return .Done
	}

	timeout := win.INFINITE
	if op.poll.expires != {} {
		diff := max(0, time.diff(op.l.now, op.poll.expires))
		timeout = win.DWORD(diff / time.Millisecond)
	}

	ok := win.RegisterWaitForSingleObject(
		&op.poll._impl.wait_handle,
		op._impl.over.hEvent,
		wait_callback,
		op,
		timeout,
		win.WT_EXECUTEINWAITTHREAD|win.WT_EXECUTEONLYONCE,
	)
	ensure(ok == true, "unexpected RegisterWaitForSingleObject error")

	return .Pending

	wait_callback :: proc "system" (lpParameter: win.PVOID, TimerOrWaitFired: win.BOOLEAN) {
		op := (^Operation)(lpParameter)
		assert_contextless(op.type == .Poll)

		if TimerOrWaitFired {
			op.poll.result = .Timeout
		}

		ok := win.PostQueuedCompletionStatus(
			op.l.iocp,
			0,
			0,
			&op._impl.over,
		)
		ensure_contextless(ok == true, "unexpected PostQueuedCompletionStatus error")
	}
}

poll_callback :: proc(op: ^Operation) {
	assert(op.type == .Poll)

	if op._impl.over.hEvent != nil {
		win.WSACloseEvent(op._impl.over.hEvent)
	}

	if op.poll._impl.wait_handle != nil {
		win.UnregisterWaitEx(op.poll._impl.wait_handle, nil)
	}

	if op.poll.result != nil {
		return
	}

	_, err := get_result(op._impl.over)
	#partial switch err {
	case .SUCCESS:
	case:
		op.poll.result = .Error
	}
}

open_exec :: proc(op: ^Operation) {
	assert(op.type == .Open)
	// No async way of doing this.
	op.open.handle, op.open.err = _open_sync(op.l, op.open.path, op.open.dir, op.open.mode, op.open.perm)
}

stat_exec :: proc(op: ^Operation) {
	assert(op.type == .Stat)
	// No async way of doing this.
	op.stat.type, op.stat.size, op.stat.err = stat(op.stat.handle)
}

@(require_results)
timeout_exec :: proc(op: ^Operation) -> Op_Result {
	assert(op.type == .Timeout)

	if op.timeout.duration <= 0 {
		return .Done
	} else {
		op.timeout._impl.expires = time.time_add(now(), op.timeout.duration)
		node, inserted, alloc_err := avl.find_or_insert(&op.l.timeouts, op)
		assert(alloc_err == nil)
		assert(inserted)
		assert(node != nil)
		return .Pending
	}
}

link_timeout :: proc(op: ^Operation, expires: time.Time) {
	if expires == {} {
		return
	}

	timeout_op := _prep(op.l, internal_timeout_callback, .Timeout)
	timeout_op.timeout._impl.expires = expires
	timeout_op.timeout._impl.target  = op
	op._impl.timeout = timeout_op

	node, inserted, alloc_err := avl.find_or_insert(&op.l.timeouts, timeout_op)
	assert(alloc_err == nil)
	assert(inserted)
	assert(node != nil)
}

internal_timeout_callback :: proc(op: ^Operation) {
	assert(op.type == .Timeout)

	target := op.timeout._impl.target
	assert(target != nil)
	assert(target._impl.timeout == op)
	target._impl.timeout = nil

	#partial switch target.type {
	case .Poll:
		target.poll.result = .Timeout
		target.cb(target)
		_remove(target)
		return
	}

	if is_pending(target._impl.over) {
		handle := operation_handle(target)
		assert(handle != win.INVALID_HANDLE)
		ok := win.CancelIoEx(handle, &target._impl.over)
		if !ok {
			err := win.System_Error(win.GetLastError())
			#partial switch err {
			case .NOT_FOUND:
				debug("Timeout: Cancel", target.type, "NOT_FOUND")
			case .INVALID_HANDLE:
				debug("Timeout: Cancel", target.type, "INVALID_HANDLE")
			case:
				assert(false, "unexpected CancelIoEx error")
			}
		}
	}
}

stat :: proc(handle: Handle) -> (type: File_Type, size: i64, err: FS_Error) {
	info: win.FILE_STANDARD_INFO
	if !win.GetFileInformationByHandleEx(win.HANDLE(handle), .FileStandardInfo, &info, size_of(info)) {
		err = FS_Error(win.GetLastError())
		return
	}

	size = i64(info.EndOfFile)

	if info.Directory {
		type = .Directory
		return
	}

	switch win.GetFileType(win.HANDLE(handle)) {
	case win.FILE_TYPE_PIPE:
		type = .Pipe_Or_Socket
		return
	case win.FILE_TYPE_CHAR:
		type = .Device
		return
	case win.FILE_TYPE_DISK:
		type = .Regular
		// Don't return, might be a symlink.
	case:
		type = .Undetermined
		return
	}


	tag_info: win.FILE_ATTRIBUTE_TAG_INFO
	if !win.GetFileInformationByHandleEx(win.HANDLE(handle), .FileAttributeTagInfo, &tag_info, size_of(tag_info)) {
		return
	}

	if (
		(tag_info.FileAttributes & win.FILE_ATTRIBUTE_REPARSE_POINT != 0) &&
		(
			(tag_info.ReparseTag == win.IO_REPARSE_TAG_SYMLINK) ||
			(tag_info.ReparseTag == win.IO_REPARSE_TAG_MOUNT_POINT)
		)
	) {
		type = .Symlink
	}

	return
}

STATUS_PENDING :: rawptr(uintptr(0x103))

is_pending :: proc(over: win.OVERLAPPED) -> bool {
	return over.Internal == STATUS_PENDING
}

is_fresh :: proc(over: win.OVERLAPPED) -> bool {
	return over.Internal == nil && over.InternalHigh == nil
}

get_result :: proc(over: win.OVERLAPPED) -> (n: int, err: win.System_Error) {
	assert(!is_pending(over))

	n = int(uintptr(over.InternalHigh))

	if over.Internal != nil {
		err = win.System_Error(win.RtlNtStatusToDosError(win.NTSTATUS(uintptr(over.Internal))))
		assert(!is_incomplete(err))
	}
	return
}

is_incomplete :: proc(err: win.System_Error) -> bool {
	#partial switch err {
	case .WSAEWOULDBLOCK, .IO_PENDING, .IO_INCOMPLETE, .WSAEALREADY: return true
	case: return false
	}
}

endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: win.SOCKADDR_STORAGE_LH) {
	switch a in ep.address {
	case IP4_Address:
		(^win.sockaddr_in)(&sockaddr)^ = win.sockaddr_in {
			sin_port   = u16be(win.USHORT(ep.port)),
			sin_addr   = transmute(win.in_addr)a,
			sin_family = u16(win.AF_INET),
		}
		return
	case IP6_Address:
		(^win.sockaddr_in6)(&sockaddr)^ = win.sockaddr_in6 {
			sin6_port   = u16be(win.USHORT(ep.port)),
			sin6_addr   = transmute(win.in6_addr)a,
			sin6_family = u16(win.AF_INET6),
		}
		return
	}
	unreachable()
}

sockaddr_to_endpoint :: proc(native_addr: ^win.SOCKADDR_STORAGE_LH) -> (ep: Endpoint) {
	switch native_addr.ss_family {
	case u16(win.AF_INET):
		addr := cast(^win.sockaddr_in)native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = IP4_Address(transmute([4]byte)addr.sin_addr),
			port    = port,
		}
	case u16(win.AF_INET6):
		addr := cast(^win.sockaddr_in6)native_addr
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

load_socket_fn :: proc(subject: win.SOCKET, guid: win.GUID, fn: ^$T) {
	over: win.OVERLAPPED

	guid := guid
	bytes: u32
	rc := win.WSAIoctl(
		subject,
		win.SIO_GET_EXTENSION_FUNCTION_POINTER,
		&guid,
		size_of(guid),
		fn,
		size_of(fn),
		&bytes,
		// NOTE: I don't think loading a socket fn ever blocks,
		// but I would like to hit an assert if it does, so we do pass it.
		&over,
		nil,
	)
	assert(rc != win.SOCKET_ERROR)
	assert(bytes == size_of(fn^))
}

check_timed_out :: proc(op: ^Operation, expires: time.Time) -> bool {
	return expires != {} && time.diff(op.l.now, expires) <= 0
}
