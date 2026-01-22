#+build !darwin
#+build !freebsd
#+build !openbsd
#+build !netbsd
#+build !linux
#+build !windows
#+private
package nbio

import "core:container/avl"
import "core:container/pool"
import "core:container/queue"
import "core:mem"
import "core:slice"
import "core:time"

_FULLY_SUPPORTED :: false

_Event_Loop :: struct {
	completed: queue.Queue(^Operation),
	timeouts:  avl.Tree(^Operation),
}

_Handle :: uintptr

_CWD :: Handle(-100)

MAX_RW :: mem.Gigabyte

_Operation :: struct {
	removed: bool,
}

_Accept :: struct {}

_Close :: struct {}

_Dial :: struct {}

_Recv :: struct {
	small_bufs: [1][]byte,
}

_Send :: struct {
	small_bufs: [1][]byte,
}

_Read :: struct {}

_Write :: struct {}

_Timeout :: struct {
	expires: time.Time,
}

_Poll :: struct {}

_Send_File :: struct {}

_Open :: struct {}

_Stat :: struct {}

_Splice :: struct {}

_Remove :: struct {}

_Link_Timeout :: struct {}

_init :: proc(l: ^Event_Loop, allocator: mem.Allocator) -> (rerr: General_Error) {
	l.completed.data.allocator = allocator

	avl.init_cmp(&l.timeouts, timeouts_cmp, allocator)

	return nil

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

_destroy :: proc(l: ^Event_Loop) {
	queue.destroy(&l.completed)
	avl.destroy(&l.timeouts, false)
}

__tick :: proc(l: ^Event_Loop, timeout: time.Duration) -> General_Error {
	l.now = time.now()

	for op in queue.pop_front_safe(&l.completed) {
		if !op._impl.removed {
			op.cb(op)
		}
		if !op.detached {
			pool.put(&l.operation_pool, op)
		}
	}

	iter := avl.iterator(&l.timeouts, .Forward)
	for node in avl.iterator_next(&iter) {
		op := node.value
		cexpires := time.diff(l.now, op.timeout._impl.expires)

		done := cexpires <= 0
		if done {
			op.cb(op)
			avl.remove_node(&l.timeouts, node)
			if !op.detached {
				pool.put(&l.operation_pool, op)
			}
			continue
		}

		break
	}

	return nil
}

_create_socket :: proc(l: ^Event_Loop, family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Create_Socket_Error) {
	return nil, .Network_Unreachable
}

_listen :: proc(socket: TCP_Socket, backlog := 1000) -> Listen_Error {
	return .Network_Unreachable
}

_exec :: proc(op: ^Operation) {
	switch op.type {
	case .Timeout:
		_, _, err := avl.find_or_insert(&op.l.timeouts, op)
		if err != nil {
			panic("nbio: allocation failure")
		}
		return
	case .Accept:
		op.accept.err = .Network_Unreachable
	case .Close:
		op.close.err = .Unsupported
	case .Dial:
		op.dial.err = Dial_Error.Network_Unreachable
	case .Recv:
		switch _ in op.recv.socket {
		case TCP_Socket: op.recv.err = TCP_Recv_Error.Network_Unreachable
		case UDP_Socket: op.recv.err = UDP_Recv_Error.Network_Unreachable
		case:            op.recv.err = TCP_Recv_Error.Network_Unreachable
		}
	case .Send:
		switch _ in op.send.socket {
		case TCP_Socket: op.send.err = TCP_Send_Error.Network_Unreachable
		case UDP_Socket: op.send.err = UDP_Send_Error.Network_Unreachable
		case:            op.send.err = TCP_Send_Error.Network_Unreachable
		}
	case .Send_File:
		op.sendfile.err = .Network_Unreachable
	case .Read:
		op.read.err = .Unsupported
	case .Write:
		op.write.err = .Unsupported
	case .Poll:
		op.poll.result = .Error
	case .Open:
		op.open.err = .Unsupported
	case .Stat:
		op.stat.err = .Unsupported
	case .None, ._Link_Timeout, ._Remove, ._Splice:
		fallthrough
	case:
		unreachable()
	}

	_, err := queue.push_back(&op.l.completed, op)
	if err != nil {
		panic("nbio: allocation failure")
	}
}

_remove :: proc(target: ^Operation) {
	#partial switch target.type {
	case .Timeout:
		avl.remove_value(&target.l.timeouts, target)
		if !target.detached {
			pool.put(&target.l.operation_pool, target)
		}
	case:
		target._impl.removed = true
	}
}

_open_sync :: proc(l: ^Event_Loop, path: string, dir: Handle, mode: File_Flags, perm: Permissions) -> (handle: Handle, err: FS_Error) {
	return 0, FS_Error.Unsupported
}

_associate_handle :: proc(handle: uintptr, l: ^Event_Loop) -> (Handle, Association_Error) {
	return Handle(handle), nil
}

_associate_socket :: proc(socket: Any_Socket, l: ^Event_Loop) -> Association_Error {
	return nil
}

_wake_up :: proc(l: ^Event_Loop) {
}

_yield :: proc() {
}
