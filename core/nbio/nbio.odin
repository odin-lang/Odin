package nbio

import "base:intrinsics"

import "core:container/pool"
import "core:container/queue"
import "core:net"
import "core:sync"
import "core:time"

/*
If the package is fully supported on the current target. If it is not it will compile but work
in a matter where things are unimplemented.

Additionally if it is `FULLY_SUPPORTED` it may still return `.Unsupported` in `acquire_thread_event_loop`
If the target does not support the needed syscalls for operating the package.
*/
FULLY_SUPPORTED :: _FULLY_SUPPORTED

/*
An event loop, one per thread, consider the fields private.
Do not copy.
*/
Event_Loop :: struct /* #no_copy */ {
	using impl:  _Event_Loop,
	err:         General_Error,
	refs:        int,
	now:         time.Time,

	// Queue that is used to queue operations from another thread to be executed on this thread.
	// TODO: Better data-structure.
	queue:    queue.Queue(^Operation),
	queue_mu: sync.Mutex,

	operation_pool: pool.Pool(Operation),
}

Handle :: _Handle

// The maximum size of user arguments for an operation, can be increased at the cost of more RAM.
MAX_USER_ARGUMENTS :: #config(NBIO_MAX_USER_ARGUMENTS, 4)
#assert(MAX_USER_ARGUMENTS >= 4)

Operation :: struct {
	cb:              Callback,
	user_data:       [MAX_USER_ARGUMENTS + 1]rawptr,
	detached:        bool,
	type:            Operation_Type,
	using specifics: Specifics,

	_impl:   _Operation `fmt:"-"`,
	using _: struct #raw_union {
		_pool_link: ^Operation,
		l:          ^Event_Loop,
	},
}

Specifics :: struct #raw_union {
	accept:   Accept    `raw_union_tag:"type=.Accept"`,
	close:    Close     `raw_union_tag:"type=.Close"`,
	dial:     Dial      `raw_union_tag:"type=.Dial"`,
	read:     Read      `raw_union_tag:"type=.Read"`,
	recv:     Recv      `raw_union_tag:"type=.Recv"`,
	send:     Send      `raw_union_tag:"type=.Send"`,
	write:    Write     `raw_union_tag:"type=.Write"`,
	timeout:  Timeout   `raw_union_tag:"type=.Timeout"`,
	poll:     Poll      `raw_union_tag:"type=.Poll"`,
	sendfile: Send_File `raw_union_tag:"type=.Send_File"`,
	open:     Open      `raw_union_tag:"type=.Open"`,
	stat:     Stat      `raw_union_tag:"type=.Stat"`,

	_remove:       _Remove       `raw_union_tag:"type=._Remove"`,
	_link_timeout: _Link_Timeout `raw_union_tag:"type=._Link_Timeout"`,
	_splice:       _Splice       `raw_union_tag:"type=._Splice"`,
}

Operation_Type :: enum i32 {
	None,
	Accept,
	Close,
	Dial,
	Read,
	Recv,
	Send,
	Write,
	Timeout,
	Poll,
	Send_File,
	Open,
	Stat,

	_Link_Timeout,
	_Remove,
	_Splice,
}

Callback :: #type proc(op: ^Operation)

/*
Initialize or increment the reference counted event loop for the current thread.
*/
acquire_thread_event_loop :: proc() -> General_Error {
	return _acquire_thread_event_loop()
}

/*
Destroy or decrease the reference counted event loop for the current thread.
*/
release_thread_event_loop :: proc() {
	_release_thread_event_loop()
}

current_thread_event_loop :: proc(loc := #caller_location) -> ^Event_Loop {
	return _current_thread_event_loop(loc)
}

/*
Each time you call this the implementation checks its state
and calls any callbacks which are ready. You would typically call this in a loop.

Blocks for up-to timeout waiting for events if there is nothing to do.
*/
tick :: proc(timeout: time.Duration = NO_TIMEOUT) -> General_Error {
	l := &_tls_event_loop
	if l.refs == 0 { return nil }
	return _tick(l, timeout)
}

/*
Runs the event loop by ticking in a loop until there is no more work to be done.
*/
run :: proc() -> General_Error {
	l := &_tls_event_loop
	if l.refs == 0 { return nil }

	acquire_thread_event_loop()
	defer release_thread_event_loop()

	for num_waiting() > 0 {
		if errno := _tick(l, NO_TIMEOUT); errno != nil {
			return errno
		}
	}
	return nil
}

/*
Runs the event loop by ticking in a loop until there is no more work to be done, or the flag `done` is `true`.
*/
run_until :: proc(done: ^bool) -> General_Error {
	l := &_tls_event_loop
	if l.refs == 0 { return nil }

	acquire_thread_event_loop()
	defer release_thread_event_loop()

	for num_waiting() > 0 && !intrinsics.volatile_load(done) {
		if errno := _tick(l, NO_TIMEOUT); errno != nil {
			return errno
		}
	}
	return nil
}

/*
Returns the number of in-progress operations to be completed on the event loop.
*/
num_waiting :: proc(l: Maybe(^Event_Loop) = nil) -> int {
	l_ := l.? or_else &_tls_event_loop
	if l_.refs == 0 { return 0 }
	return pool.num_outstanding(&l_.operation_pool)
}

/*
Returns the current time (cached at most at the beginning of the current tick).
*/
now :: proc() -> time.Time {
	if _tls_event_loop.now == {} {
		return time.now()
	}
	return _tls_event_loop.now
}

/*
Remove the given operation from the event loop. The callback of it won't be called and resources are freed.

Calling `remove`:
- Cancels the operation if it has not yet completed
- Prevents the callback from being called

Cancellation via `remove` is *final* and silent:
- The callback will never be invoked
- No error is delivered
- The operation must be considered dead after removal

WARN: the operation could have already been (partially or completely) completed.
	  A send with `all` set to true could have sent a portion already.
	  But also, a send that could be completed without blocking could have been completed.
	  You just won't get a callback.

WARN: once an operation's callback is called it can not be removed anymore (use after free).

WARN: needs to be called from the thread of the event loop the target belongs to.

Common use would be to cancel a timeout, remove a polling, or remove an `accept` before calling `close` on it's socket.
*/
remove :: proc(target: ^Operation) {
	if target == nil {
		return
	}

	assert(target.type != .None)

	if target.l != &_tls_event_loop {
		panic("nbio.remove called on different thread")
	}

	_remove(target)
}

/*
Creates a socket for use in `nbio` and relates it to the given event loop.

Inputs:
- family:   Should this be an IP4 or IP6 socket
- protocol: The type of socket (TCP or UDP)
- l:        The event loop to associate it with, defaults to the current thread's loop

Returns:
- socket: The created socket, consider `create_{udp|tcp}_socket` for a typed socket instead of the union
- err:    A network error (`Create_Socket_Error`, or `Set_Blocking_Error`) which happened while opening
*/
create_socket :: proc(
	family:   Address_Family,
	protocol: Socket_Protocol,
	l:        ^Event_Loop = nil,
	loc       := #caller_location,
) -> (
	socket: Any_Socket,
	err:    Create_Socket_Error,
) {
	return _create_socket(l if l != nil else _current_thread_event_loop(loc), family, protocol)
}

/*
Creates a UDP socket for use in `nbio` and relates it to the given event loop.

Inputs:
- family: Should this be an IP4 or IP6 socket
- l:      The event loop to associate it with, defaults to the current thread's loop

Returns:
- socket: The created UDP socket
- err:    A network error (`Create_Socket_Error`, or `Set_Blocking_Error`) which happened while opening
*/
create_udp_socket :: proc(family: Address_Family, l: ^Event_Loop = nil, loc := #caller_location) -> (net.UDP_Socket, Create_Socket_Error) {
	socket, err := create_socket(family, .UDP, l, loc)
	if err != nil {
		return -1, err
	}

	return socket.(UDP_Socket), nil
}

/*
Creates a TCP socket for use in `nbio` and relates it to the given event loop.

Inputs:
- family: Should this be an IP4 or IP6 socket
- l:      The event loop to associate it with, defaults to the current thread's loop

Returns:
- socket: The created TCP socket
- err:    A network error (`Create_Socket_Error`, or `Set_Blocking_Error`) which happened while opening
*/
create_tcp_socket :: proc(family: Address_Family, l: ^Event_Loop = nil, loc := #caller_location) -> (net.TCP_Socket, Create_Socket_Error) {
	socket, err := create_socket(family, .TCP, l, loc)
	if err != nil {
		return -1, err
	}

	return socket.(TCP_Socket), nil
}

/*
Creates a socket, sets non blocking mode, relates it to the given IO, binds the socket to the given endpoint and starts listening.

Inputs:
- endpoint: Where to bind the socket to
- backlog:  The maximum length to which the queue of pending connections may grow, before refusing connections
- l:        The event loop to associate the socket with, defaults to the current thread's loop

Returns:
- socket: The opened, bound and listening socket
- err:    A network error (`Create_Socket_Error`, `Bind_Error`, or `Listen_Error`) that has happened
*/
listen_tcp :: proc(endpoint: Endpoint, backlog := 1000, l: ^Event_Loop = nil, loc := #caller_location) -> (socket: TCP_Socket, err: net.Network_Error) {
	assert(backlog > 0 && backlog < int(max(i32)))
	return _listen_tcp(l if l != nil else _current_thread_event_loop(loc), endpoint, backlog)
}

/*
Opens a file and associates it with the event loop.

Inputs:
- path: path to the file, if not absolute: relative from `dir`
- dir:  directory that `path` is relative from (if it is relative), defaults to the current working directory
- mode: open mode, defaults to read-only
- perm: permissions to use when creating a file, defaults to read+write for everybody
- l:    event loop to associate the file with, defaults to the current thread's

Returns:
- handle: The file handle
- err:    An error if it occurred
*/
open_sync :: proc(path: string, dir: Handle = CWD, mode: File_Flags = {.Read}, perm := Permissions_Default_File, l: ^Event_Loop = nil, loc := #caller_location) -> (handle: Handle, err: FS_Error) {
	return _open_sync(l if l != nil else _current_thread_event_loop(loc), path, dir, mode, perm)
}

Association_Error :: enum {
	None,
	// The given file/handle/socket was not opened in a mode that it can be made non-blocking afterwards.
	//
	// On Windows, this can happen when a file is not opened with the `FILE_FLAG_OVERLAPPED` flag.
	// If using `core:os`, that is set when you specify the `O_NONBLOCK` flag.
	// There is no way to add that after the fact.
	Not_Possible_To_Associate,
	// The given handle is not a valid handle.
	Invalid_Handle,
	// No network connection, or the network stack is not initialized.
	Network_Unreachable,
}

/*
Associate the given OS handle, not opened through this package, with the event loop.

Consider using this package's `open` or `open_sync` directly instead.

The handle returned is for convenience, it is actually still the same handle as given.
Thus you should not close the given handle.

On Windows, this can error when a file is not opened with the `FILE_FLAG_OVERLAPPED` flag.
If using `core:os`, that is set when you specify the `O_NONBLOCK` flag.
There is no way to add that after the fact.
*/
associate_handle :: proc(handle: uintptr, l: ^Event_Loop = nil, loc := #caller_location) -> (Handle, Association_Error) {
	return _associate_handle(handle, l if l != nil else _current_thread_event_loop(loc))
}

/*
Associate the given socket, not created through this package, with the event loop.

Consider using this package's `create_socket` directly instead.
*/
associate_socket :: proc(socket: Any_Socket, l: ^Event_Loop = nil, loc := #caller_location) -> Association_Error {
	return _associate_socket(socket, l if l != nil else _current_thread_event_loop(loc))
}

Read_Entire_File_Error :: struct {
	operation: Operation_Type,
	value:     FS_Error,
}

Read_Entire_File_Callback :: #type proc(user_data: rawptr, data: []byte, err: Read_Entire_File_Error)

/*
Combines multiple operations (open, stat, read, close) into one that reads an entire regular file.

The error contains the `operation` that the error happened on.

Inputs:
- path:      path to the file, if not absolute: relative from `dir`
- user_data: a pointer passed through into the callback
- cb:        the callback to call once completed, called with the user data, file data, and an optional error
- allocator: the allocator to allocate the file's contents onto
- dir:       directory that `path` is relative from (if it is relative), defaults to the current working directory
- l:         event loop to execute the operation on
*/
read_entire_file :: proc(path: string, user_data: rawptr, cb: Read_Entire_File_Callback, allocator := context.allocator, dir := CWD, l: ^Event_Loop = nil, loc := #caller_location) {
	_read_entire_file(l if l != nil else _current_thread_event_loop(loc), path, user_data, cb, allocator, dir)
}

/*
Detach an operation from the package's lifetime management.

By default the operation's lifetime is managed by the package and freed after a callback is called.
Calling this function detaches the operation from this lifetime.
You are expected to call `reattach` to give the package back this operation.
*/
detach :: proc(op: ^Operation) {
	op.detached = true
}

/*
Reattach an operation to the package's lifetime management.
*/
reattach :: proc(op: ^Operation) {
	pool.put(&op.l.operation_pool, op)
}

/*
Execute an operation.

If the operation is attached to another thread's event loop, it is queued to be executed on that event loop,
optionally waking that loop up (from a blocking `tick`) with `trigger_wake_up`.
*/
exec :: proc(op: ^Operation, trigger_wake_up := true) {
	if op.l == &_tls_event_loop {
		_exec(op)
	} else {
		{
			// TODO: Better data-structure.
			sync.guard(&op.l.queue_mu)
			_, err := queue.push_back(&op.l.queue, op)
			if err != nil {
				panic("exec: queueing operation failed due to memory allocation failure")
			}
		}
		if trigger_wake_up {
			wake_up(op.l)
		}
	}
}

/*
Wake up an event loop on another thread which may be blocking for completed operations.

Commonly used with `exec` from a worker thread to have the event loop pick up that work.
Note that by default `exec` already calls this procedure.
*/
wake_up :: proc(l: ^Event_Loop) {
	if l == &_tls_event_loop {
		return
	}
	_wake_up(l)
}
