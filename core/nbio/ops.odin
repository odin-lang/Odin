package nbio

import "base:intrinsics"

import "core:container/pool"
import "core:time"
import "core:slice"

NO_TIMEOUT: time.Duration: -1 

Accept :: struct {
	// Socket to accept an incoming connection on.
	socket:  TCP_Socket,
	// When this operation expires and should be timed out.
	expires: time.Time,

	// The connection that was accepted.
	client: TCP_Socket,
	// The connection's remote origin.
	client_endpoint: Endpoint,
	// An error, if it occurred.
	err: Accept_Error,

	// Implementation specifics, private.
	_impl: _Accept `fmt:"-"`,
}

/*
Retrieves and preps an operation to do an accept without executing it.

Executing can then be done with the `exec` procedure.

The timeout is calculated from the time when this procedure was called, not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- socket:  A bound and listening socket *associated with the event loop*
- cb:      The callback to be called when the operation finishes, `Operation.accept` will contain results
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_accept :: #force_inline proc(
	socket: TCP_Socket,
	cb: Callback,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := _prep(l, cb, .Accept)
	op.accept.socket  = socket
	if timeout > 0 {
		op.accept.expires = time.time_add(now(), timeout)
	}
	return op
}

/*
Using the given socket, accepts the next incoming connection, calling the callback when that happens.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `accept_poly`, `accept_poly2`, and `accept_poly3`.

Inputs:
- socket:  A bound and listening socket *associated with the event loop*
- cb:      The callback to be called when the operation finishes, `Operation.accept` will contain results
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
accept :: #force_inline proc(
	socket: TCP_Socket,
	cb: Callback,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	res := prep_accept(socket, cb, timeout, l)
	exec(res)
	return res
}

/*
Using the given socket, accepts the next incoming connection, calling the callback when that happens.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  A bound and listening socket *associated with the event loop*
- p:       User data, the callback will receive this as it's second argument
- cb:      The callback to be called when the operation finishes, `Operation.accept` will contain results
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
accept_poly :: #force_inline proc(
	socket: TCP_Socket,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_accept(socket, _poly_cb(C, T), timeout, l)
	_put_user_data(op, cb, p)
	exec(op)
	return op
}

/*
Using the given socket, accepts the next incoming connection, calling the callback when that happens.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  A bound and listening socket *associated with the event loop*
- p:       User data, the callback will receive this as it's second argument
- p2:      User data, the callback will receive this as it's third argument
- cb:      The callback to be called when the operation finishes, `Operation.accept` will contain results
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
accept_poly2 :: #force_inline proc(
	socket: TCP_Socket,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_accept(socket, _poly_cb2(C, T, T2), timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)
	return op
}

/*
Using the given socket, accepts the next incoming connection, calling the callback when that happens.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  A bound and listening socket *associated with the event loop*
- p:       User data, the callback will receive this as it's second argument
- p2:      User data, the callback will receive this as it's third argument
- p3:      User data, the callback will receive this as it's fourth argument
- cb:      The callback to be called when the operation finishes, `Operation.accept` will contain results
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
accept_poly3 :: #force_inline proc(
	socket: TCP_Socket,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_accept(socket, _poly_cb3(C, T, T2, T3), timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)
	return op
}

/*
A union of closable types that can be passed to `close`.
*/
Closable :: union {
	TCP_Socket,
	UDP_Socket,
	Handle,
}

Close :: struct {
	// The subject to close.
	subject: Closable,

	// An error, if it occurred.
	err: FS_Error,

	// Implementation specifics, private.
	_impl:   _Close `fmt:"-"`,
}

@(private)
empty_callback :: proc(_: ^Operation) {}

/*
Retrieves and preps an operation to do a close without executing it.

Executing can then be done with the `exec` procedure.

Closing something that has IO in progress may or may not cancel it, and may or may not call the callback.
For consistent behavior first call `remove` on in progress IO.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- subject: The subject (socket or file) to close
- cb:      The optional callback to be called when the operation finishes, `Operation.close` will contain results 
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_close :: #force_inline proc(subject: Closable, cb: Callback = empty_callback, l: ^Event_Loop = nil) -> ^Operation {
	op := _prep(l, cb, .Close)
	op.close.subject = subject
	return op
}

/*
Closes the given subject (file or socket).

Closing something that has IO in progress may or may not cancel it, and may or may not call the callback.
For consistent behavior first call `remove` on in progress IO.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `close_poly`, `close_poly2`, and `close_poly3`.

Inputs:
- subject: The subject (socket or file) to close
- cb:      The optional callback to be called when the operation finishes, `Operation.close` will contain results 
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
close :: #force_inline proc(subject: Closable, cb: Callback = empty_callback, l: ^Event_Loop = nil) -> ^Operation {
	op := prep_close(subject, cb, l)
	exec(op)
	return op
}

/*
Closes the given subject (file or socket).

Closing something that has IO in progress may or may not cancel it, and may or may not call the callback.
For consistent behavior first call `remove` on in progress IO.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- subject: The subject (socket or file) to close
- p:       User data, the callback will receive this as it's second argument
- cb:      The optional callback to be called when the operation finishes, `Operation.close` will contain results 
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
close_poly :: #force_inline proc(subject: Closable, p: $T, cb: $C/proc(op: ^Operation, p: T), l: ^Event_Loop = nil) -> ^Operation
where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_close(subject, _poly_cb(C, T), l)
	_put_user_data(op, cb, p)
	exec(op)
	return op
}

/*
Closes the given subject (file or socket).

Closing something that has IO in progress may or may not cancel it, and may or may not call the callback.
For consistent behavior first call `remove` on in progress IO.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- subject: The subject (socket or file) to close
- p:       User data, the callback will receive this as it's second argument
- p2:      User data, the callback will receive this as it's third argument
- cb:      The optional callback to be called when the operation finishes, `Operation.close` will contain results 
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
close_poly2 :: #force_inline proc(subject: Closable, p: $T, p2: $T2, cb: $C/proc(op: ^Operation, p: T, p2: T2), l: ^Event_Loop = nil) -> ^Operation
where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_close(subject, _poly_cb2(C, T, T2), l)
	_put_user_data2(op, cb, p, p2)
	exec(op)
	return op
}

/*
Closes the given subject (file or socket).

Closing something that has IO in progress may or may not cancel it, and may or may not call the callback.
For consistent behavior first call `remove` on in progress IO.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- subject: The subject (socket or file) to close
- p:       User data, the callback will receive this as it's second argument
- p2:      User data, the callback will receive this as it's third argument
- p3:      User data, the callback will receive this as it's fourth argument
- cb:      The optional callback to be called when the operation finishes, `Operation.close` will contain results 
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
close_poly3 :: #force_inline proc(subject: Closable, p: $T, p2: $T2, p3: $T3, cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3), l: ^Event_Loop = nil) -> ^Operation
where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_close(subject, _poly_cb3(C, T, T2, T3), l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)
	return op
}

Dial :: struct {
	// The endpoint to connect to.
	endpoint: Endpoint,
	// When this operation expires and should be timed out.
	expires:  time.Time,

	// Errors that can be returned: `Create_Socket_Error`, or `Dial_Error`.
	err:      Network_Error,
	// The socket to communicate with the connected server.
	socket:   TCP_Socket,

	// Implementation specifics, private.
	_impl:    _Dial `fmt:"-"`,
}

/*
Retrieves and preps an operation to do a dial operation without executing it.

Executing can then be done with the `exec` procedure.

The timeout is calculated from the time when this procedure was called, not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- endpoint: The endpoint to connect to
- cb:       The callback to be called when the operation finishes, `Operation.dial` will contain results
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_dial :: #force_inline proc(
	endpoint: Endpoint,
	cb: Callback,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := _prep(l, cb, .Dial)
	if timeout > 0 {
		op.dial.expires = time.time_add(now(), timeout)
	}
	op.dial.endpoint = endpoint
	return op
}

/*
Dials the given endpoint.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `dial_poly`, `dial_poly2`, and `dial_poly3`.

Inputs:
- endpoint: The endpoint to connect to
- cb:       The callback to be called when the operation finishes, `Operation.dial` will contain results
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
dial :: #force_inline proc(
	endpoint: Endpoint,
	cb: Callback,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	res := prep_dial(endpoint, cb, timeout, l)
	exec(res)
	return res
}

/*
Dials the given endpoint.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- endpoint: The endpoint to connect to
- p:        User data, the callback will receive this as it's second argument
- cb:       The callback to be called when the operation finishes, `Operation.dial` will contain results
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
dial_poly :: #force_inline proc(
	endpoint: Endpoint,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_dial(endpoint, _poly_cb(C, T), timeout, l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Dials the given endpoint.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- endpoint: The endpoint to connect to
- p:        User data, the callback will receive this as it's second argument
- p2:       User data, the callback will receive this as it's third argument
- cb:       The callback to be called when the operation finishes, `Operation.dial` will contain results
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
dial_poly2 :: #force_inline proc(
	endpoint: Endpoint,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_dial(endpoint, _poly_cb2(C, T, T2), timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Dials the given endpoint.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- endpoint: The endpoint to connect to
- p:        User data, the callback will receive this as it's second argument
- p2:       User data, the callback will receive this as it's third argument
- p3:       User data, the callback will receive this as it's fourth argument
- cb:       The callback to be called when the operation finishes, `Operation.dial` will contain results
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
dial_poly3 :: #force_inline proc(
	endpoint: Endpoint,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_dial(endpoint, _poly_cb3(C, T, T2, T3), timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

Recv :: struct {
	// The socket to receive from.
	socket:   Any_Socket,
	// The buffers to receive data into.
	// The outer slice is copied internally, but the backing data must remain alive.
	// It is safe to access `bufs` during the callback.
	bufs:     [][]byte,
	// If true, the operation waits until all buffers are filled (TCP only).
	all:      bool,
	// When this operation expires and should be timed out.
	expires:  time.Time,

	// The source endpoint data was received from (UDP only).
	source:   Endpoint,
	
	// An error, if it occurred.
	// If `received == 0` and `err == nil`, the connection was closed by the peer.
	err:      Recv_Error,
	// The number of bytes received.
	received: int,

	// Implementation specifics, private.
	_impl:    _Recv `fmt:"-"`,
}

/*
Retrieves and preps an operation to do a receive without executing it.

Executing can then be done with the `exec` procedure.

To avoid ambiguity between a closed connection and a 0-byte read, the provided buffers must have a total capacity greater than 0.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

The timeout is calculated from the time when this procedure was called, not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- socket:  The socket to receive from
- bufs:    Buffers to fill with received data
- cb:      The callback to be called when the operation finishes, `Operation.recv` will contain results
- all:     If true, waits until all buffers are full before completing (TCP only, ignored for UDP)
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_recv :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	cb: Callback,
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	assert(socket != nil)

	// If we accepted `bufs` that total 0 it would be ambiguous if the result of `received == 0 && err == nil` means connection closed or received 0 bytes.
	assert(len(bufs) > 0)
	assert(slice.any_of_proc(bufs, proc(buf: []byte) -> bool { return len(buf) > 0 }))

	op := _prep(l, cb, .Recv)
	op.recv.socket  = socket
	op.recv.bufs    = bufs
	op.recv.all     = all
	if timeout > 0 {
		op.recv.expires = time.time_add(now(), timeout)
	}

	if err := bufs_init(&op.recv._impl.bufs, &op.recv.bufs, op.l.allocator); err != nil {
		switch _ in op.recv.socket {
		case TCP_Socket: op.recv.err = TCP_Recv_Error.Insufficient_Resources
		case UDP_Socket: op.recv.err = UDP_Recv_Error.Insufficient_Resources
		case:            unreachable()
		}
	}

	return op
}

/*
Receives data from the socket.

If the operation completes with 0 bytes received and no error, it indicates the connection was closed by the peer.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `recv_poly`, `recv_poly2`, and `recv_poly3`.

Inputs:
- socket:  The socket to receive from
- bufs:    Buffers to fill with received data
- cb:      The callback to be called when the operation finishes, `Operation.recv` will contain results
- all:     If true, waits until all buffers are full before completing (TCP only, ignored for UDP)
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
recv :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	cb: Callback,
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation {
	op := prep_recv(socket, bufs, cb, all, timeout, l)
	exec(op)
	return op
}

/*
Receives data from the socket.

If the operation completes with 0 bytes received and no error, it indicates the connection was closed by the peer.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  The socket to receive from
- bufs:    Buffers to fill with received data
- p:       User data, the callback will receive this as it's second argument
- cb:      The callback to be called when the operation finishes, `Operation.recv` will contain results
- all:     If true, waits until all buffers are full before completing (TCP only, ignored for UDP)
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
recv_poly :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_recv(socket, bufs, _poly_cb(C, T), all, timeout, l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Receives data from the socket.

If the operation completes with 0 bytes received and no error, it indicates the connection was closed by the peer.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  The socket to receive from
- bufs:    Buffers to fill with received data
- p:       User data, the callback will receive this as it's second argument
- p2:      User data, the callback will receive this as it's third argument
- cb:      The callback to be called when the operation finishes, `Operation.recv` will contain results
- all:     If true, waits until all buffers are full before completing (TCP only, ignored for UDP)
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
recv_poly2 :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_recv(socket, bufs, _poly_cb2(C, T, T2), all, timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Receives data from the socket.

If the operation completes with 0 bytes received and no error, it indicates the connection was closed by the peer.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  The socket to receive from
- bufs:    Buffers to fill with received data
- p:       User data, the callback will receive this as it's second argument
- p2:      User data, the callback will receive this as it's third argument
- p3:      User data, the callback will receive this as it's fourth argument
- cb:      The callback to be called when the operation finishes, `Operation.recv` will contain results
- all:     If true, waits until all buffers are full before completing (TCP only, ignored for UDP)
- timeout: Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
recv_poly3 :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_recv(socket, bufs, _poly_cb3(C, T, T2, T3), all, timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

Send :: struct {
	// The socket to send to.
	socket:   Any_Socket,
	// The buffers to send.
	// The outer slice is copied internally, but the backing data must remain alive.
	// It is safe to access `bufs` during the callback.
	bufs:     [][]byte `fmt:"-"`,
	// The destination endpoint to send to (UDP only).
	endpoint: Endpoint,
	// If true, the operation ensures all data is sent before completing.
	all:      bool,
	// When this operation expires and should be timed out.
	expires:  time.Time,

	// An error, if it occurred.
	err:      Send_Error,
	// The number of bytes sent.
	sent:     int,

	// Implementation specifics, private.
	_impl:    _Send `fmt:"-"`,
}

/*
Retrieves and preps an operation to do a send without executing it.

Executing can then be done with the `exec` procedure.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

The timeout is calculated from the time when this procedure was called, not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- socket:   The socket to send to
- bufs:     Buffers containing the data to send
- cb:       The callback to be called when the operation finishes, `Operation.send` will contain results
- endpoint: The destination endpoint (UDP only, ignored for TCP)
- all:      If true, the operation ensures all data is sent before completing
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_send :: proc(
	socket: Any_Socket,
	bufs: [][]byte,
	cb: Callback,
	endpoint: Endpoint = {},
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	assert(socket != nil)
	op := _prep(l, cb, .Send)
	op.send.socket   = socket
	op.send.bufs     = bufs
	op.send.endpoint = endpoint
	op.send.all      = all
	if timeout > 0 {
		op.send.expires = time.time_add(now(), timeout)
	}

	if err := bufs_init(&op.send._impl.bufs, &op.send.bufs, op.l.allocator); err != nil {
		switch _ in op.send.socket {
		case TCP_Socket: op.send.err = TCP_Send_Error.Insufficient_Resources
		case UDP_Socket: op.send.err = UDP_Send_Error.Insufficient_Resources
		case:            unreachable()
		}
	}

	return op
}

/*
Sends data to the socket.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `send_poly`, `send_poly2`, and `send_poly3`.

Inputs:
- socket:   The socket to send to
- bufs:     Buffers containing the data to send
- cb:       The callback to be called when the operation finishes, `Operation.send` will contain results
- endpoint: The destination endpoint (UDP only, ignored for TCP)
- all:      If true, the operation ensures all data is sent before completing
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
send :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	cb: Callback,
	endpoint: Endpoint = {},
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_send(socket, bufs, cb, endpoint, all, timeout, l)
	exec(op)
	return op
}

/*
Sends data to the socket.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:   The socket to send to
- bufs:     Buffers containing the data to send
- p:        User data, the callback will receive this as it's second argument
- cb:       The callback to be called when the operation finishes, `Operation.send` will contain results
- endpoint: The destination endpoint (UDP only, ignored for TCP)
- all:      If true, the operation ensures all data is sent before completing
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
send_poly :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	endpoint: Endpoint = {},
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_send(socket, bufs, _poly_cb(C, T), endpoint, all, timeout, l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Sends data to the socket.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:   The socket to send to
- bufs:     Buffers containing the data to send
- p:        User data, the callback will receive this as it's second argument
- p2:       User data, the callback will receive this as it's third argument
- cb:       The callback to be called when the operation finishes, `Operation.send` will contain results
- endpoint: The destination endpoint (UDP only, ignored for TCP)
- all:      If true, the operation ensures all data is sent before completing
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
send_poly2 :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	endpoint: Endpoint = {},
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_send(socket, bufs, _poly_cb2(C, T, T2), endpoint, all, timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Sends data to the socket.

The `bufs` slice itself is copied into the operation, so it can be temporary (e.g. on the stack), but the underlying memory of the buffers must remain valid until the callback is fired.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:   The socket to send to
- bufs:     Buffers containing the data to send
- p:        User data, the callback will receive this as it's second argument
- p2:       User data, the callback will receive this as it's third argument
- p3:       User data, the callback will receive this as it's fourth argument
- cb:       The callback to be called when the operation finishes, `Operation.send` will contain results
- endpoint: The destination endpoint (UDP only, ignored for TCP)
- all:      If true, the operation ensures all data is sent before completing
- timeout:  Optional timeout for the operation, the callback will get a `.Timeout` error after that duration
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
send_poly3 :: #force_inline proc(
	socket: Any_Socket,
	bufs: [][]byte,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	endpoint: Endpoint = {},
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_send(socket, bufs, _poly_cb3(C, T, T2, T3), endpoint, all, timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

Read :: struct {
	// Handle to read from.
	handle:  Handle,
	// Buffer to read data into.
	buf:     []byte `fmt:"v,read"`,
	// Offset to read from.
	offset:	 int,
	// Whether to read until the buffer is full or an error occurs.
	all:   	 bool,
	// When this operation expires and should be timed out.
	expires: time.Time,

	// Error, if it occurred.
	err:     FS_Error,
	// Number of bytes read.
	read:  	 int,

	// Implementation specifics, private.
	_impl:  _Read `fmt:"-"`,
}

/*
Retrieves and preps a positional read operation without executing it.

This is a pread-style operation: the read starts at the given offset and does
not modify the handle's current file position.

Executing can then be done with the `exec` procedure.

The timeout is calculated from the time when this procedure was called,
not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- handle:  Handle to read from
- offset:  Offset to read from
- buf:     Buffer to read data into (must not be empty)
- cb:      The callback to be called when the operation finishes, `Operation.read` will contain results
- all:     Whether to read until the buffer is full or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_read :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	cb: Callback,
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	assert(len(buf) > 0)
	op := _prep(l, cb, .Read)
	op.read.handle  = handle
	op.read.buf     = buf
	op.read.offset  = offset
	op.read.all     = all
	if timeout > 0 {
		op.read.expires = time.time_add(now(), timeout)
	}
	return op
}

/*
Reads data from a handle at a specific offset.

This is a pread-style operation: the read starts at the given offset and does
not modify the handle's current file position.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `read_poly`, `read_poly2`, and `read_poly3`.

Inputs:
- handle:  Handle to read from
- offset:  Offset to read from
- buf:     Buffer to read data into (must not be empty)
- cb:      The callback to be called when the operation finishes, `Operation.read` will contain results
- all:     Whether to read until the buffer is full or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
read :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	cb: Callback,
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_read(handle, offset, buf, cb, all, timeout, l)
	exec(op)
	return op
}

/*
Reads data from a handle at a specific offset.

This is a pread-style operation: the read starts at the given offset and does
not modify the handle's current file position.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle:  Handle to read from
- offset:  Offset to read from
- buf:     Buffer to read data into (must not be empty)
- p:       User data, the callback will receive this as its second argument
- cb:      The callback to be called when the operation finishes, `Operation.read` will contain results
- all:     Whether to read until the buffer is full or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
read_poly :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_read(handle, offset, buf, _poly_cb(C, T), all=all, timeout=timeout, l=l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Reads data from a handle at a specific offset.

This is a pread-style operation: the read starts at the given offset and does
not modify the handle's current file position.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle:  Handle to read from
- offset:  Offset to read from
- buf:     Buffer to read data into (must not be empty)
- p:       User data, the callback will receive this as its second argument
- p2:      User data, the callback will receive this as its third argument
- cb:      The callback to be called when the operation finishes, `Operation.read` will contain results
- all:     Whether to read until the buffer is full or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
read_poly2 :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_read(handle, offset, buf, _poly_cb2(C, T, T2), all, timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Reads data from a handle at a specific offset.

This is a pread-style operation: the read starts at the given offset and does
not modify the handle's current file position.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle:  Handle to read from
- offset:  Offset to read from
- buf:     Buffer to read data into (must not be empty)
- p:       User data, the callback will receive this as its second argument
- p2:      User data, the callback will receive this as its third argument
- p3:      User data, the callback will receive this as its fourth argument
- cb:      The callback to be called when the operation finishes, `Operation.read` will contain results
- all:     Whether to read until the buffer is full or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
read_poly3 :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	all := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_read(handle, offset, buf, _poly_cb3(C, T, T2, T3), all, timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

Write :: struct {
	// Handle to write to.
	handle:  Handle,
	// Buffer containing data to write.
	buf:     []byte,
	// Offset to write to.
	offset:  int,
	// Whether to write until the buffer is fully written or an error occurs.
	all:     bool,
	// When this operation expires and should be timed out.
	expires: time.Time,

	// Error, if it occurred.
	err:     FS_Error,
	// Number of bytes written.
	written: int,

	// Implementation specifics, private.
	_impl:   _Write `fmt:"-"`,
}

/*
Retrieves and preps a positional write operation without executing it.

This is a pwrite-style operation: the write starts at the given offset and does
not modify the handle's current file position.

Executing can then be done with the `exec` procedure.

The timeout is calculated from the time when this procedure was called,
not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- handle:  Handle to write to
- offset:  Offset to write to
- buf:     Buffer containing data to write (must not be empty)
- cb:      The callback to be called when the operation finishes, `Operation.write` will contain results
- all:     Whether to write until the entire buffer is written or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_write :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	cb: Callback,
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	assert(len(buf) > 0)
	op := _prep(l, cb, .Write)
	op.write.handle  = handle
	op.write.buf     = buf
	op.write.offset  = offset
	op.write.all     = all
	if timeout > 0 {
		op.write.expires = time.time_add(now(), timeout)
	}
	return op
}

/*
Writes data to a handle at a specific offset.

This is a pwrite-style operation: the write starts at the given offset and does
not modify the handle's current file position.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `write_poly`, `write_poly2`, and `write_poly3`.

Inputs:
- handle:  Handle to write to
- offset:  Offset to write to
- buf:     Buffer containing data to write (must not be empty)
- cb:      The callback to be called when the operation finishes, `Operation.write` will contain results
- all:     Whether to write until the entire buffer is written or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
write :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	cb: Callback,
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_write(handle, offset, buf, cb, all, timeout, l)
	exec(op)
	return op
}

/*
Writes data to a handle at a specific offset.

This is a pwrite-style operation: the write starts at the given offset and does
not modify the handle's current file position.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle:  Handle to write to
- offset:  Offset to write to
- buf:     Buffer containing data to write (must not be empty)
- p:       User data, the callback will receive this as its second argument
- cb:      The callback to be called when the operation finishes, `Operation.write` will contain results
- all:     Whether to write until the entire buffer is written or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
write_poly :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_write(handle, offset, buf, _poly_cb(C, T), all=all, timeout=timeout, l=l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Writes data to a handle at a specific offset.

This is a pwrite-style operation: the write starts at the given offset and does
not modify the handle's current file position.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle:  Handle to write to
- offset:  Offset to write to
- buf:     Buffer containing data to write (must not be empty)
- p:       User data, the callback will receive this as its second argument
- p2:      User data, the callback will receive this as its third argument
- cb:      The callback to be called when the operation finishes, `Operation.write` will contain results
- all:     Whether to write until the entire buffer is written or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
write_poly2 :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_write(handle, offset, buf, _poly_cb2(C, T, T2), all, timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Writes data to a handle at a specific offset.

This is a pwrite-style operation: the write starts at the given offset and does
not modify the handle's current file position.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle:  Handle to write to
- offset:  Offset to write to
- buf:     Buffer containing data to write (must not be empty)
- p:       User data, the callback will receive this as its second argument
- p2:      User data, the callback will receive this as its third argument
- p3:      User data, the callback will receive this as its fourth argument
- cb:      The callback to be called when the operation finishes, `Operation.write` will contain results
- all:     Whether to write until the entire buffer is written or an error occurs
- timeout: Optional timeout for the operation
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
write_poly3 :: #force_inline proc(
	handle: Handle,
	offset: int,
	buf: []byte,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	all := true,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_write(handle, offset, buf, _poly_cb3(C, T, T2, T3), all, timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

Timeout :: struct {
	// Duration after which the timeout expires.
	duration: time.Duration,

	// Implementation specifics, private.
	_impl:    _Timeout `fmt:"-"`,
}

/*
Retrieves and preps a timeout operation without executing it.

Executing can then be done with the `exec` procedure.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- duration: Duration to wait before the operation completes
- cb:       The callback to be called when the operation finishes
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_timeout :: #force_inline proc(
	duration: time.Duration,
	cb: Callback,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := _prep(l, cb, .Timeout)
	op.timeout.duration = duration
	return op
}

/*
Schedules a timeout that completes after the given duration.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `timeout_poly`, `timeout_poly2`, and `timeout_poly3`.

Inputs:
- duration: Duration to wait before the operation completes
- cb:       The callback to be called when the operation finishes
- l:        Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
timeout :: #force_inline proc(
	duration: time.Duration,
	cb: Callback,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_timeout(duration, cb, l)
	exec(op)
	return op
}

/*
Schedules a timeout that completes after the given duration.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- dur: Duration to wait before the operation completes
- p:   User data, the callback will receive this as its second argument
- cb:  The callback to be called when the operation finishes
- l:   Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
timeout_poly :: #force_inline proc(
	dur: time.Duration,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	l: ^Event_Loop = nil,
) -> ^Operation
	where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_timeout(dur, _poly_cb(C, T), l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Schedules a timeout that completes after the given duration.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- dur: Duration to wait before the operation completes
- p:   User data, the callback will receive this as its second argument
- p2:  User data, the callback will receive this as its third argument
- cb:  The callback to be called when the operation finishes
- l:   Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
timeout_poly2 :: #force_inline proc(
	dur: time.Duration,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	l: ^Event_Loop = nil,
) -> ^Operation
	where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_timeout(dur, _poly_cb2(C, T, T2), l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Schedules a timeout that completes after the given duration.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- dur: Duration to wait before the operation completes
- p:   User data, the callback will receive this as its second argument
- p2:  User data, the callback will receive this as its third argument
- p3:  User data, the callback will receive this as its fourth argument
- cb:  The callback to be called when the operation finishes
- l:   Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
timeout_poly3 :: #force_inline proc(
	dur: time.Duration,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	l: ^Event_Loop = nil,
) -> ^Operation
	where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_timeout(dur, _poly_cb3(C, T, T2, T3), l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

/*
Retrieves and preps an operation that completes on the next event loop tick.

This is equivalent to `prep_timeout(0, ...)`.
*/
prep_next_tick :: #force_inline proc(cb: Callback, l: ^Event_Loop = nil) -> ^Operation {
	return prep_timeout(0, cb, l)
}

/*
Schedules an operation that completes on the next event loop tick.

This is equivalent to `timeout(0, ...)`.
*/
next_tick :: #force_inline proc(cb: Callback, l: ^Event_Loop = nil) -> ^Operation {
	return timeout(0, cb, l)
}

/*
Schedules an operation that completes on the next event loop tick.

This is equivalent to `timeout_poly(0, ...)`.
*/
next_tick_poly :: #force_inline proc(p: $T, cb: $C/proc(op: ^Operation, p: T), l: ^Event_Loop = nil) -> ^Operation
	where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	return timeout_poly(0, p, cb, l)
}

/*
Schedules an operation that completes on the next event loop tick.

This is equivalent to `timeout_poly2(0, ...)`.
*/
next_tick_poly2 :: #force_inline proc(p: $T, p2: $T2, cb: $C/proc(op: ^Operation, p: T, p2: T2), l: ^Event_Loop = nil) -> ^Operation
	where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	return timeout_poly2(0, p, p2, cb, l)
}

/*
Schedules an operation that completes on the next event loop tick.

This is equivalent to `timeout_poly3(0, ...)`.
*/
next_tick_poly3 :: #force_inline proc(p: $T, p2: $T2, p3: $T3, cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3), l: ^Event_Loop = nil) -> ^Operation
	where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	return timeout_poly3(0, p, p2, p3, cb, l)
}

Poll_Result :: enum i32 {
	// The requested event is ready.
	Ready,             
    // The operation timed out before the event became ready.
	Timeout,
	// The socket was invalid.
	Invalid_Argument,
    // An unspecified error occurred.
	Error,
}

Poll_Event :: enum {
	// The subject is ready to be received from.
	Receive,
	// The subject is ready to be sent to.
	Send,
}

Poll :: struct {
	// Socket to poll.
	socket:  Any_Socket,
	// Event to poll for.
	event:   Poll_Event,
	// When this operation expires and should be timed out.
	expires: time.Time,

	// Result of the poll.
	result:  Poll_Result,

	// Implementation specifics, private.
	_impl:  _Poll `fmt:"-"`,
}

/*
Retrieves and preps an operation to poll a socket without executing it.

Executing can then be done with the `exec` procedure.

The timeout is calculated from the time when this procedure was called,
not from when it's executed.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- socket:  Socket to poll that is *associated with the event loop*
- event:   Event to poll for
- cb:      The callback to be called when the operation finishes, `Operation.poll` will contain results
- timeout: Optional timeout for the operation, the callback will receive a `.Timeout` result after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_poll :: #force_inline proc(
	socket: Any_Socket,
	event: Poll_Event,
	cb: Callback,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := _prep(l, cb, .Poll)
	op.poll.socket = socket
	op.poll.event  = event
	if timeout > 0 {
		op.poll.expires = time.time_add(now(), timeout)
	}
	return op
}

/*
Poll a socket for readiness.

NOTE: this is provided to help with "legacy" APIs that require polling behavior.
If you can avoid it and use the other procs in this package, do so.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `poll_poly`, `poll_poly2`, and `poll_poly3`.

Inputs:
- socket:  Socket to poll that is *associated with the event loop*
- event:   Event to poll for
- cb:      The callback to be called when the operation finishes, `Operation.poll` will contain results
- timeout: Optional timeout for the operation, the callback will receive a `.Timeout` result after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
poll :: #force_inline proc(
	socket: Any_Socket,
	event: Poll_Event,
	cb: Callback,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_poll(socket, event, cb, timeout, l)
	exec(op)
	return op
}

/*
Poll a socket for readiness.

NOTE: this is provided to help with "legacy" APIs that require polling behavior.
If you can avoid it and use the other procs in this package, do so.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  Socket to poll that is *associated with the event loop*
- event:   Event to poll for
- p:       User data, the callback will receive this as its second argument
- cb:      The callback to be called when the operation finishes, `Operation.poll` will contain results
- timeout: Optional timeout for the operation, the callback will receive a `.Timeout` result after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
poll_poly :: #force_inline proc(
	socket: Any_Socket,
	event: Poll_Event,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_poll(socket, event, _poly_cb(C, T), timeout, l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Poll a socket for readiness.

NOTE: this is provided to help with "legacy" APIs that require polling behavior.
If you can avoid it and use the other procs in this package, do so.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  Socket to poll that is *associated with the event loop*
- event:   Event to poll for
- p:       User data, the callback will receive this as its second argument
- p2:      User data, the callback will receive this as its third argument
- cb:      The callback to be called when the operation finishes, `Operation.poll` will contain results
- timeout: Optional timeout for the operation, the callback will receive a `.Timeout` result after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
poll_poly2 :: #force_inline proc(
	socket: Any_Socket,
	event: Poll_Event,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_poll(socket, event, _poly_cb2(C, T, T2), timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Poll a socket for readiness.

NOTE: this is provided to help with "legacy" APIs that require polling behavior.
If you can avoid it and use the other procs in this package, do so.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:  Socket to poll that is *associated with the event loop*
- event:   Event to poll for
- p:       User data, the callback will receive this as its second argument
- p2:      User data, the callback will receive this as its third argument
- p3:      User data, the callback will receive this as its fourth argument
- cb:      The callback to be called when the operation finishes, `Operation.poll` will contain results
- timeout: Optional timeout for the operation, the callback will receive a `.Timeout` result after that duration
- l:       Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
poll_poly3 :: #force_inline proc(
	socket: Any_Socket,
	event: Poll_Event,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_poll(socket, event, _poly_cb3(C, T, T2, T3), timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

SEND_ENTIRE_FILE :: -1

Send_File_Error :: union #shared_nil {
	FS_Error,
	TCP_Send_Error,
}

Send_File :: struct {
	// The TCP socket to send the file over.
	socket:           TCP_Socket,
	// The handle of the regular file to send.
	file:             Handle,
	// When this operation expires and should be timed out.
	expires:          time.Time,
	// The starting offset within the file.
	offset:           int,
	// Number of bytes to send. If set to SEND_ENTIRE_FILE, the file size is retrieved 
	// automatically and this field is updated to reflect the full size.
	nbytes:           int,
	// If true, the callback is triggered periodically as data is sent. 
	// The callback will continue to be called until `sent == nbytes` or an error occurs.
	progress_updates: bool,

	// Total number of bytes (so far if `progress_updates` is true).
	sent:             int,
	// An error, if it occurred. Can be a filesystem or networking error.
	err:              Send_File_Error,

	// Implementation specifics, private.
	_impl:            _Send_File `fmt:"-"`,
}

/*
Retrieves and preps an operation to send a file over a socket without executing it.

Executing can then be done with the `exec` procedure.

This uses high-performance zero-copy system calls where available. 
Note: This is emulated on NetBSD and OpenBSD (stat -> mmap -> send) as they lack a native sendfile implementation.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- socket:           The destination TCP socket
- file:             The source file handle
- cb:               The callback to be called when data is sent (if `progress_updates` is true) or the operation completes
- offset:           Byte offset to start reading from the file
- nbytes:           Total bytes to send (use SEND_ENTIRE_FILE for the whole file)
- progress_updates: If true, the callback fires multiple times to report progress, `sent == nbytes` means te operation completed
- timeout:          Optional timeout for the operation
- l:                Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the final callback is called
*/
prep_sendfile :: #force_inline proc(
	socket: TCP_Socket,
	file: Handle,
	cb: Callback,
	offset: int = 0,
	nbytes: int = SEND_ENTIRE_FILE,
	progress_updates := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	assert(offset >= 0)
	assert(nbytes == SEND_ENTIRE_FILE || nbytes > 0)
	op := _prep(l, cb, .Send_File)
	op.sendfile.socket = socket
	op.sendfile.file   = file
	if timeout > 0 {
		op.sendfile.expires = time.time_add(now(), timeout)
	}
	op.sendfile.offset = offset
	op.sendfile.nbytes = nbytes
	op.sendfile.progress_updates = progress_updates
	return op
}

/*
Sends a file over a TCP socket.

This uses high-performance zero-copy system calls where available. 
Note: This is emulated on NetBSD and OpenBSD (stat -> mmap -> send) as they lack a native sendfile implementation.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `sendfile_poly`, `sendfile_poly2`, and `sendfile_poly3`.

Inputs:
- socket:           The destination TCP socket
- file:             The source file handle
- cb:               The callback to be called when data is sent (if `progress_updates` is true) or the operation completes
- offset:           Byte offset to start reading from the file
- nbytes:           Total bytes to send (use SEND_ENTIRE_FILE for the whole file)
- progress_updates: If true, the callback fires multiple times to report progress, `sent == nbytes` means te operation completed
- timeout:          Optional timeout for the operation
- l:                Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the final callback is called
*/
sendfile :: #force_inline proc(
	socket: TCP_Socket,
	file: Handle,
	cb: Callback,
	offset: int = 0,
	nbytes: int = SEND_ENTIRE_FILE,
	progress_updates := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_sendfile(socket, file, cb, offset, nbytes, progress_updates, timeout, l)
	exec(op)
	return op
}

/*
Sends a file over a TCP socket.

This uses high-performance zero-copy system calls where available. 
Note: This is emulated on NetBSD and OpenBSD (stat -> mmap -> send) as they lack a native sendfile implementation.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:           The destination TCP socket
- file:             The source file handle
- p:                User data, the callback will receive this as it's second argument
- cb:               The callback to be called when data is sent (if `progress_updates` is true) or the operation completes
- offset:           Byte offset to start reading from the file
- nbytes:           Total bytes to send (use SEND_ENTIRE_FILE for the whole file)
- progress_updates: If true, the callback fires multiple times to report progress, `sent == nbytes` means te operation completed
- timeout:          Optional timeout for the operation
- l:                Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the final callback is called
*/
sendfile_poly :: #force_inline proc(
	socket: TCP_Socket,
	file: Handle,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	offset: int = 0,
	nbytes: int = SEND_ENTIRE_FILE,
	progress_updates := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_sendfile(socket, file, _poly_cb(C, T), offset, nbytes, progress_updates, timeout, l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Sends a file over a TCP socket.

This uses high-performance zero-copy system calls where available. 
Note: This is emulated on NetBSD and OpenBSD (stat -> mmap -> send) as they lack a native sendfile implementation.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:           The destination TCP socket
- file:             The source file handle
- p:                User data, the callback will receive this as it's second argument
- p2:               User data, the callback will receive this as it's third argument
- cb:               The callback to be called when data is sent (if `progress_updates` is true) or the operation completes
- offset:           Byte offset to start reading from the file
- nbytes:           Total bytes to send (use SEND_ENTIRE_FILE for the whole file)
- progress_updates: If true, the callback fires multiple times to report progress, `sent == nbytes` means te operation completed
- timeout:          Optional timeout for the operation
- l:                Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the final callback is called
*/
sendfile_poly2 :: #force_inline proc(
	socket: TCP_Socket,
	file: Handle,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	offset: int = 0,
	nbytes: int = SEND_ENTIRE_FILE,
	progress_updates := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_sendfile(socket, file, _poly_cb2(C, T, T2), offset, nbytes, progress_updates, timeout, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Sends a file over a TCP socket.

This uses high-performance zero-copy system calls where available. 
Note: This is emulated on NetBSD and OpenBSD (stat -> mmap -> send) as they lack a native sendfile implementation.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- socket:           The destination TCP socket
- file:             The source file handle
- p:                User data, the callback will receive this as it's second argument
- p2:               User data, the callback will receive this as it's third argument
- p3:               User data, the callback will receive this as it's fourth argument
- cb:               The callback to be called when data is sent (if `progress_updates` is true) or the operation completes
- offset:           Byte offset to start reading from the file
- nbytes:           Total bytes to send (use SEND_ENTIRE_FILE for the whole file)
- progress_updates: If true, the callback fires multiple times to report progress, `sent == nbytes` means te operation completed
- timeout:          Optional timeout for the operation
- l:                Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the final callback is called
*/
sendfile_poly3 :: #force_inline proc(
	socket: TCP_Socket,
	file: Handle,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	offset: int = 0,
	nbytes: int = SEND_ENTIRE_FILE,
	progress_updates := false,
	timeout: time.Duration = NO_TIMEOUT,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_sendfile(socket, file, _poly_cb3(C, T, T2, T3), offset, nbytes, progress_updates, timeout, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

/*
File permission bit-set.

This type represents POSIX-style file permissions, split into user, group,
and other categories, each with read, write, and execute flags.
*/
Permissions :: distinct bit_set[Permission_Flag; u32]

Permission_Flag :: enum u32 {
	Execute_Other = 0,
	Write_Other   = 1,
	Read_Other    = 2,

	Execute_Group = 3,
	Write_Group   = 4,
	Read_Group    = 5,

	Execute_User  = 6,
	Write_User    = 7,
	Read_User     = 8,
}

// Convenience permission sets.
Permissions_Execute_All :: Permissions{.Execute_User, .Execute_Group, .Execute_Other}
Permissions_Write_All   :: Permissions{.Write_User,   .Write_Group,   .Write_Other}
Permissions_Read_All    :: Permissions{.Read_User,    .Read_Group,    .Read_Other}

// Read and write permissions for user, group, and others.
Permissions_Read_Write_All :: Permissions_Read_All + Permissions_Write_All

// Read, write, and execute permissions for user, group, and others.
Permissions_All :: Permissions_Read_All + Permissions_Write_All + Permissions_Execute_All

// Default permissions used when creating a file (read and write for everyone).
Permissions_Default_File :: Permissions_Read_All + Permissions_Write_All

// Default permissions used when creating a directory (read, write, and execute for everyone).
Permissions_Default_Directory :: Permissions_Read_All + Permissions_Write_All + Permissions_Execute_All

File_Flags :: bit_set[File_Flag; int]

File_Flag :: enum {
    // Open for reading.
	Read,
	// Open for writing.
	Write,
	// Append writes to the end of the file.
	Append,  
	// Create the file if it does not exist.
	Create,  
	// Fail if the file already exists (used with Create).
	Excl,    
	Sync,
	// Truncate the file on open.
	Trunc,
}

Open :: struct {
	// Base directory the path is relative to.
	dir:  Handle,
	// Path to the file.
	path: string,
	// File open mode flags.
	mode: File_Flags,
	// Permissions used if the file is created.
	perm: Permissions,

	// The opened file handle.
	handle: Handle,
	// An error, if it occurred.
	err:    FS_Error,

	// Implementation specifics, private.
	_impl: _Open `fmt:"-"`,
}

// Sentinel handle representing the current/present working directory.
CWD :: _CWD

/*
Retrieves and preps an operation to open a file without executing it.

Executing can then be done with the `exec` procedure.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- path: Path to the file, if not absolute: relative from `dir`
- cb:   The callback to be called when the operation finishes, `Operation.open` will contain results
- mode: File open mode flags, defaults to read-only
- perm: Permissions to use when creating a file, defaults to read+write for everybody
- dir:  Directory that `path` is relative from (if it is relative), defaults to the current working directory
- l:    Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_open :: #force_inline proc(
	path: string,
	cb: Callback,
	mode: File_Flags = {.Read},
	perm: Permissions = Permissions_Default_File,
	dir: Handle = CWD,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := _prep(l, cb, .Open)
	op.open.path = path
	op.open.mode = mode
	op.open.perm = perm
	op.open.dir  = dir
	return op
}

/*
Opens a file and associates it with the event loop.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `open_poly`, `open_poly2`, and `open_poly3`.

Inputs:
- path:  Path to the file, if not absolute: relative from `dir`
- cb:    The callback to be called when the operation finishes, `Operation.open` will contain results
- mode:  File open mode flags, defaults to read-only
- perm:  Permissions to use when creating a file, defaults to read+write for everybody
- dir:   Directory that `path` is relative from (if it is relative), defaults to the current working directory
- l:     Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
open :: #force_inline proc(
	path: string,
	cb: Callback,
	mode: File_Flags = {.Read},
	perm: Permissions = Permissions_Default_File,
	dir: Handle = CWD,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_open(path, cb, mode, perm, dir, l)
	exec(op)
	return op
}

/*
Opens a file and associates it with the event loop.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- path: Path to the file, if not absolute: relative from `dir`
- p:    User data, the callback will receive this as its second argument
- cb:   The callback to be called when the operation finishes, `Operation.open` will contain results
- mode: File open mode flags, defaults to read-only
- perm: Permissions to use when creating a file, defaults to read+write for everybody
- dir:  Directory that `path` is relative from (if it is relative), defaults to the current working directory
- l:    Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
open_poly :: #force_inline proc(
	path: string,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	mode: File_Flags = {.Read},
	perm: Permissions = Permissions_Default_File,
	dir: Handle = CWD,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_open(path, _poly_cb(C, T), mode, perm, dir, l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Opens a file and associates it with the event loop.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- path: Path to the file, if not absolute: relative from `dir`
- p:    User data, the callback will receive this as its second argument
- p2:   User data, the callback will receive this as its third argument
- cb:   The callback to be called when the operation finishes, `Operation.open` will contain results
- mode: File open mode flags, defaults to read-only
- perm: Permissions to use when creating a file, defaults to read+write for everybody
- dir:  Directory that `path` is relative from (if it is relative), defaults to the current working directory
- l:    Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
open_poly2 :: #force_inline proc(
	path: string,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	mode: File_Flags = {.Read},
	perm: Permissions = Permissions_Default_File,
	dir: Handle = CWD,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_open(path, _poly_cb2(C, T, T2), mode, perm, dir, l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Asynchronously opens a file and associates it with the event loop.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- path: Path to the file, if not absolute: relative from `dir`
- p:    User data, the callback will receive this as its second argument
- p2:   User data, the callback will receive this as its third argument
- p3:   User data, the callback will receive this as its fourth argument
- cb:   The callback to be called when the operation finishes, `Operation.open` will contain results
- mode: File open mode flags, defaults to read-only
- perm: Permissions to use when creating a file, defaults to read+write for everybody
- dir:  Directory that `path` is relative from (if it is relative), defaults to the current working directory
- l:    Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
open_poly3 :: #force_inline proc(
	path: string,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	mode: File_Flags = {.Read},
	perm: Permissions = Permissions_Default_File,
	dir: Handle = CWD,
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_open(path, _poly_cb3(C, T, T2, T3), mode, perm, dir, l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

File_Type :: enum {
    // File type could not be determined.
	Undetermined,
    // Regular file.
	Regular,
    // Directory.
	Directory,
    // Symbolic link.
	Symlink,
	// Pipe or socket.
	Pipe_Or_Socket,
    // Character or block device.
	Device,
}

Stat :: struct {
	// Handle to stat.
	handle: Handle,

	// The type of the file.
	type:   File_Type,
	// Size of the file in bytes.
	size:   i64        `fmt:"M"`,

	// An error, if it occurred.
	err:    FS_Error,

	// Implementation specifics, private.
	_impl:  _Stat `fmt:"-"`,
}

/*
Retrieves and preps an operation to stat a handle without executing it.

Executing can then be done with the `exec` procedure.

Any user data can be set on the returned operation's `user_data` field.

Inputs:
- handle: Handle to retrieve stat
- cb:     The callback to be called when the operation finishes, `Operation.stat` will contain results
- l:      Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
prep_stat :: #force_inline proc(
	handle: Handle,
	cb: Callback,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := _prep(l, cb, .Stat)
	op.stat.handle = handle
	return op
}

/*
Stats a handle.

Any user data can be set on the returned operation's `user_data` field.
Polymorphic variants for type safe user data are available under `stat_poly`, `stat_poly2`, and `stat_poly3`.

Inputs:
- handle: Handle to retrieve status information for
- cb:     The callback to be called when the operation finishes, `Operation.stat` will contain results
- l:      Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
stat :: #force_inline proc(
	handle: Handle,
	cb: Callback,
	l: ^Event_Loop = nil,
) -> ^Operation {
	op := prep_stat(handle, cb, l)
	exec(op)
	return op
}

/*
Stats a handle.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle: Handle to retrieve status information for
- p:      User data, the callback will receive this as its second argument
- cb:     The callback to be called when the operation finishes, `Operation.stat` will contain results
- l:      Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
stat_poly :: #force_inline proc(
	handle: Handle,
	p: $T,
	cb: $C/proc(op: ^Operation, p: T),
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_stat(handle, _poly_cb(C, T), l)
	_put_user_data(op, cb, p)
	exec(op)

	return op
}

/*
Stats a handle.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle: Handle to retrieve status information for
- p:      User data, the callback will receive this as its second argument
- p2:     User data, the callback will receive this as its third argument
- cb:     The callback to be called when the operation finishes, `Operation.stat` will contain results
- l:      Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
stat_poly2 :: #force_inline proc(
	handle: Handle,
	p: $T, p2: $T2,
	cb: $C/proc(op: ^Operation, p: T, p2: T2),
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_stat(handle, _poly_cb2(C, T, T2), l)
	_put_user_data2(op, cb, p, p2)
	exec(op)

	return op
}

/*
Stats a handle.

This procedure uses polymorphism for type safe user data up to a certain size.

Inputs:
- handle: Handle to retrieve status information for
- p:      User data, the callback will receive this as its second argument
- p2:     User data, the callback will receive this as its third argument
- p3:     User data, the callback will receive this as its fourth argument
- cb:     The callback to be called when the operation finishes, `Operation.stat` will contain results
- l:      Event loop to associate the operation with, defaults to the current thread's loop

Returns: A non-nil pointer to the operation, alive until the callback is called
*/
stat_poly3 :: #force_inline proc(
	handle: Handle,
	p: $T, p2: $T2, p3: $T3,
	cb: $C/proc(op: ^Operation, p: T, p2: T2, p3: T3),
	l: ^Event_Loop = nil,
) -> ^Operation where size_of(T) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {

	op := prep_stat(handle, _poly_cb3(C, T, T2, T3), l)
	_put_user_data3(op, cb, p, p2, p3)
	exec(op)

	return op
}

_prep :: proc(l: ^Event_Loop, cb: Callback, type: Operation_Type) -> ^Operation {
	assert(cb != nil)
	assert(type != .None)
	l := l
	if l == nil { l = _current_thread_event_loop() }
	operation := pool.get(&l.operation_pool)
	operation.l = l
	operation.type = type
	operation.cb = cb
	return operation
}

_poly_cb :: #force_inline proc($C: typeid, $T: typeid) -> proc(^Operation) {
	return proc(op: ^Operation) {
		ptr := uintptr(&op.user_data)
		cb  := intrinsics.unaligned_load((^C)(rawptr(ptr)))
		p   := intrinsics.unaligned_load((^T)(rawptr(ptr + size_of(C))))
		cb(op, p)
	}
}

_poly_cb2 :: #force_inline proc($C: typeid, $T: typeid, $T2: typeid) -> proc(^Operation) {
	return proc(op: ^Operation) {
		ptr := uintptr(&op.user_data)
		cb  := intrinsics.unaligned_load((^C) (rawptr(ptr)))
		p   := intrinsics.unaligned_load((^T) (rawptr(ptr + size_of(C))))
		p2  := intrinsics.unaligned_load((^T2)(rawptr(ptr + size_of(C) + size_of(T))))
		cb(op, p, p2)
	}
}

_poly_cb3 :: #force_inline proc($C: typeid, $T: typeid, $T2: typeid, $T3: typeid) -> proc(^Operation) {
	return proc(op: ^Operation) {
		ptr := uintptr(&op.user_data)
		cb  := intrinsics.unaligned_load((^C) (rawptr(ptr)))
		p   := intrinsics.unaligned_load((^T) (rawptr(ptr + size_of(C))))
		p2  := intrinsics.unaligned_load((^T2)(rawptr(ptr + size_of(C) + size_of(T))))
		p3  := intrinsics.unaligned_load((^T3)(rawptr(ptr + size_of(C) + size_of(T) + size_of(T2))))
		cb(op, p, p2, p3)
	}
}

_put_user_data :: #force_inline proc(op: ^Operation, cb: $C, p: $T) {
	ptr := uintptr(&op.user_data)
	intrinsics.unaligned_store((^C)(rawptr(ptr)),               cb)
	intrinsics.unaligned_store((^T)(rawptr(ptr + size_of(cb))), p)
}

_put_user_data2 :: #force_inline proc(op: ^Operation, cb: $C, p: $T, p2: $T2) {
	ptr := uintptr(&op.user_data)
	intrinsics.unaligned_store((^C) (rawptr(ptr)),                            cb)
	intrinsics.unaligned_store((^T) (rawptr(ptr + size_of(cb))),              p)
	intrinsics.unaligned_store((^T2)(rawptr(ptr + size_of(cb) + size_of(p))), p2)
}

_put_user_data3 :: #force_inline proc(op: ^Operation, cb: $C, p: $T, p2: $T2, p3: $T3) {
	ptr := uintptr(&op.user_data)
	intrinsics.unaligned_store((^C) (rawptr(ptr)),                                          cb)
	intrinsics.unaligned_store((^T) (rawptr(ptr + size_of(cb))),                            p)
	intrinsics.unaligned_store((^T2)(rawptr(ptr + size_of(cb) + size_of(p))),               p2)
	intrinsics.unaligned_store((^T3)(rawptr(ptr + size_of(cb) + size_of(p) + size_of(p2))), p3)
}
