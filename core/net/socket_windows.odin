package net

/*
	TODO:

	Include subsystem failure in accept, etc, for this is also present on Unix.

	-----


	Many of the errors can only happen under specific circumstances - either cannot happen at all because
	the procedure guards against those situtations (like EFAULT), or because they simply only apply
	to `connect` for instance, and so `recv` cannot return them.

	You could return specific errors, but you can't just cast from the system error to the specific one,
	because several system error values might map to the same error for us.
	Like .Unsupported_Address_Family, .Unsupported_Socket_Type, etc... they'd all be .Unsupported.

	

*/

// TODO(tetra): get_bound_address via getsockname?

import "core:sys/win32"
import "core:c"
import "core:mem"
import "core:fmt" // TODO(tetra): remove

Socket :: distinct win32.SOCKET;

// TODO(tetra): Raw/Bluetooth.
Socket_Type :: enum u8 {
	Tcp,
	Udp,
}

Addr_Type :: enum u8 {
	Ipv4,
	Ipv6,
}

// TODO(tetra): RDM?
Socket_Protocol :: enum u8 {
	Auto,
	Tcp = win32.IPPROTO_TCP,
	Udp = win32.IPPROTO_UDP,
}

Socket_Error :: win32.Socket_Error;




//                             //
// Easy to use blocking calls. //
//                             //

Read_Error :: enum {
	Ok,
	// socket has been shut down in the required direction.
	Shutdown = win32.WSAESHUTDOWN,
	// socket broke somewhere - should be reopened.
	Aborted = win32.WSAECONNABORTED,
	// the other peer closed their socket.
	Reset = win32.WSAECONNRESET,
	// datagram socket and the data is too big.
	Truncated = win32.WSAEMSGSIZE,
	// you are offline
	Offline = win32.WSAENETDOWN,
	// the host is offline
	Unreachable = win32.WSAEHOSTUNREACH,
	// short write because of possible received SIGTERM or SIGINT; only on Linux.
	Interrupted = win32.WSAEINTR,
	// operation did not complete within the time limit
	Timeout = win32.WSAETIMEDOUT,
}

Write_Error :: enum {
	Ok,
	// socket broke somewhere - should be reopened.
	Aborted = win32.WSAECONNABORTED,
	// socket not connected (only connection-based sockets)
	Not_Connected = win32.WSAENOTCONN,
	// socket has been shut down in the required direction.
	Shutdown = win32.WSAESHUTDOWN,
	// datagram socket and the data is too big.
	Truncated = win32.WSAEMSGSIZE,                          // TODO(tetra): Seperate Tcp / Udp sockets
	// the other peer closed their socket.
	Reset = win32.WSAECONNRESET,
	// out of buffer space
	Resources = win32.WSAENOBUFS,
	// you are offline
	Offline = win32.WSAENETDOWN,
	// the host is offline
	Unreachable = win32.WSAEHOSTUNREACH,
	// short write because of possible received SIGTERM or SIGINT; only on Linux.
	Interrupted = win32.WSAEINTR,
	// operation did not complete within the time limit
	Timeout = win32.WSAETIMEDOUT,
}

read :: proc(skt: Socket, buffer: []u8) -> (n: int, err: Read_Error) {
	wait_err := wait_for_available_data(skt);
	if wait_err != .Ok {
		err = Read_Error(wait_err);
		return;
	}
	n, err = try_read(skt, buffer);
	return;
}

try_read :: proc(skt: Socket, buffer: []u8) -> (n: int, err: Read_Error) {
	limit := min(len(buffer), int(max(i32)));
	n = int(win32.recv(win32.SOCKET(skt), &buffer[0], i32(limit), 0));
	if n != win32.SOCKET_ERROR do return;

	// AUDIT(tetra): panic on weird errors
	recv_err := win32.WSAGetLastError();
	switch recv_err {
	case win32.WSAEWOULDBLOCK:
		err = .Ok;
		n = 0;
	case:
		err = Read_Error(recv_err);
	}
	return;
}

// Write some data to a socket and wait for it to all be put into the OS's send buffer.
write :: proc(skt: Socket, buffer: []u8) -> (err: Write_Error) {
	sent := 0;
	n: int = ---;
	for sent < len(buffer) {
		wait_err := wait_for_can_write(skt);
		if wait_err != .Ok {
			err = Write_Error(wait_err);
			return;
		}
		n, err = try_write(skt, buffer[sent:]);
		if err != .Ok do break;
		assert(n > 0);
		sent += n;
	}
	return;
}

// Write some data to the socket, or none if the OS's send buffer does not have enough space.
try_write :: proc(skt: Socket, data: []u8) -> (n: int, err: Write_Error) {
	limit := min(int(max(i32)), len(data));

	n = int(win32.send(win32.SOCKET(skt), &data[0], i32(limit), 0));
	if n != win32.SOCKET_ERROR {
		assert(n == len(data), "turns out write can sometimes not send it all");
		return;
	}

	write_err := win32.WSAGetLastError();
	switch write_err {
	case win32.WSAEWOULDBLOCK:
		err = .Ok;
		n = 0; // AUDIT(tetra): Verify that this means that no data was sent.
	case win32.WSAECONNABORTED: err = .Aborted; // socket broken - must be reopened.
	case win32.WSAENETRESET:    err = .Aborted; // keep alive failed
	case win32.WSAEINVAL:       panic("socket not bound");
	case win32.WSAEOPNOTSUPP:   panic("OOB data not implemented");
	case win32.WSAEACCES:       panic("broadcast not implemented");
	case:
		err = Write_Error(write_err);
	}
	return;
}

// Waits until a certain number of bytes have been read from a socket.
read_all :: proc(skt: Socket, buffer: []u8) -> (err: Read_Error) {
	recvd := 0;
	n: int = ---;
	for recvd < len(buffer) {
		n, err = read(skt, buffer[recvd:]);
		if err != .Ok do break;
		recvd += n;
	}
	return;
}

// Same as `read_all`, but returns 0 immediately instead of blocking.
//
// Can be used to read at least a specific amount of data at once.
//
// AUDIT(tetra): Does this actually work?
try_read_all :: proc(skt: Socket, buffer: []u8) -> (n: int, err: Read_Error) {
	set_min_data_to_read(skt, len(buffer));
	defer set_min_data_to_read(skt, 1);

	n, err = try_read(skt, buffer[:n]);
	assert(n == 0 || n == len(buffer)); // NOTE(tetra): Will fail if len(buffer) > max(i32).
	return;
}



Read_From_Error :: enum {
	Ok,
	// socket has been shut down in the required direction.
	Shutdown,
	// datagram socket and the data is too big.
	Truncated = win32.WSAEMSGSIZE,
	// socket broke somewhere - should be reopened.
	Aborted = win32.WSAECONNABORTED,
	// the other peer closed their socket.
	Reset = win32.WSAECONNRESET,
	// you are offline
	Offline = win32.WSAENETDOWN,
	// the host is offline
	Unreachable = win32.WSAEHOSTUNREACH,
	// short write because of possible received SIGTERM or SIGINT; only on Linux.
	Interrupted = win32.WSAEINTR,
	// operation did not complete within the time limit
	Timeout = win32.WSAETIMEDOUT,
}

Write_To_Error :: enum {
	Ok,
	// short write because of possible received SIGTERM or SIGINT; only on Linux.
	Interrupted,
	// socket has been shut down in the required direction.
	Shutdown = win32.WSAESHUTDOWN,
	// datagram socket and the data is too big.
	Truncated = win32.WSAEMSGSIZE,
	// socket broke somewhere - should be reopened.
	Aborted = win32.WSAECONNABORTED,
	// the other peer closed their socket.
	Reset = win32.WSAECONNRESET,
	// out of buffer space
	Resources = win32.WSAENOBUFS,
	// you are offline
	Offline = win32.WSAENETDOWN,
	// the host is offline
	Unreachable = win32.WSAEHOSTUNREACH,
	// address not of the appropriate type
	Bad_Addr = win32.WSAEAFNOSUPPORT,
	// operation did not complete within the time limit
	Timeout = win32.WSAETIMEDOUT, // TODO(tetra): Audit that this can actually happen!
}

read_from :: proc(dgram_skt: Socket, buffer: []u8) -> (n: int, from: Endpoint, err: Read_From_Error) {
	wait_err := wait_for_available_data(dgram_skt);
	if wait_err != .Ok {
		err = Read_From_Error(wait_err);
		return;
	}
	n, from, err = try_read_from(dgram_skt, buffer);
	return;
}

try_read_from :: proc(dgram_skt: Socket, buffer: []u8) -> (n: int, from: Endpoint, err: Read_From_Error) {
	limit := min(len(buffer), int(max(i32)));

	native_addr: win32.Socket_Address; // TODO(tetra): Uninitialize this?
	native_addr_len := i32(size_of(native_addr));
	n = int(win32.recvfrom(win32.SOCKET(dgram_skt), &buffer[0], i32(limit), 0, &native_addr, &native_addr_len));
	if n != win32.SOCKET_ERROR {
		from = to_canonical_endpoint(native_addr, native_addr_len);
		return;
	}

	read_err := win32.WSAGetLastError();
	switch read_err {
	case win32.WSAEWOULDBLOCK:
		err = .Ok;
		n = 0;
	case win32.WSAEISCONN:   panic("attempt to use try_read_from on connection-oriented socket");
	case win32.WSAECONNRESET: err = .Reset; // For datagrams, this means TTL expired.
	case win32.WSAENETRESET: err = .Unreachable;
	case win32.WSAENETDOWN:  err = .Offline;
	case win32.WSAESHUTDOWN: err = .Shutdown;
	case win32.WSAEMSGSIZE:  err = .Truncated;
	case win32.WSAETIMEDOUT: err = .Timeout;
	case win32.WSAEINVAL:    panic("socket not bound");
	case: fmt.panicf("read_from failed with unhandled error %v\n", Socket_Error(read_err)); // TODO(tetra): remove need for fmt
	}
	return;
}

write_to :: proc(dgram_skt: Socket, buffer: []u8, to: Endpoint) -> (err: Write_To_Error) {
	sent := 0;
	n: int = ---;
	for sent < len(buffer) {
		wait_err := wait_for_can_write(dgram_skt);
		if wait_err != .Ok {
			err = Write_To_Error(wait_err);
			return;
		}
		n, err = try_write_to(dgram_skt, buffer[sent:], to);
		if err != .Ok do break;
		sent += n;
	}
	return;
}

try_write_to :: proc(dgram_skt: Socket, data: []u8, to: Endpoint) -> (n: int, err: Write_To_Error) {
	limit := min(int(max(i32)), len(data));

	native_addr, native_addr_len := to_socket_address(to.addr, to.port);
	n = int(win32.sendto(win32.SOCKET(dgram_skt), &data[0], i32(limit), 0, &native_addr, native_addr_len)); // NOTE(tetra): pass MSG_NOSIGNAL on Unix.
	if n != win32.SOCKET_ERROR do return;

	write_err := win32.WSAGetLastError();
	switch write_err {
	case win32.WSAEWOULDBLOCK:
		err = .Ok;
		n = 0;

	case win32.WSAENETUNREACH:  err = .Offline;
	case win32.WSAENETDOWN:     err = .Offline;
	case win32.WSAENETRESET:    unreachable(); // NOTE(tetra): This should not a connection-oriented socket.
	case win32.WSAEAFNOSUPPORT: err = .Bad_Addr;
	case win32.WSAEINVAL:       panic("socket not bound");
	case win32.WSAEOPNOTSUPP:   unimplemented(); // TODO(tetra): OOB data.
	case win32.WSAEACCES:       unimplemented(); // TODO(tetra): broadcast
	case:
		err = Write_To_Error(write_err);
	}
	return;
}


read_all_from :: proc(dgram_skt: Socket, buffer: []u8) -> (from: Endpoint, err: Read_From_Error) {
	recvd := 0;
	n: int = ---;
	for recvd < len(buffer) {
		wait_err := wait_for_available_data(dgram_skt);
		if wait_err != .Ok {
			err = Read_From_Error(wait_err);
			return;
		}
		n, from, err = read_from(dgram_skt, buffer[recvd:]);
		if err != .Ok do return;
		recvd += n;
	}
	return;
}





// Same as `read_all`, but returns 0 immediately instead of blocking.
// AUDIT(tetra): Does this actually work?
try_read_all_from :: proc(skt: Socket, buffer: []u8) -> (ok: bool, from: Endpoint, err: Read_From_Error) {
	set_min_data_to_read(skt, len(buffer));
	defer set_min_data_to_read(skt, 1);

	n: int = ---;
	n, from, err = try_read_from(skt, buffer[:n]);
	assert(n == 0 || n == len(buffer)); // NOTE(tetra): Will fail if len(buffer) > max(i32).
	ok = n == len(buffer);
	return;
}


Dial_Error :: enum {
	Ok,
	// not enough system resources, be it buffers, socket descriptors, or ports.
	Resources = win32.WSAENOBUFS,
	// the local address is already in use.
	Addr_Taken = win32.WSAEADDRINUSE,
	// the remote peer is not listening on this endpoint.
	Refused = win32.WSAECONNREFUSED,
	// the network cannot be reached from this computer at this time.
	Offline = win32.WSAENETUNREACH,
	// unreachable address,
	Unreachable = win32.WSAEHOSTUNREACH,
	Timeout = win32.WSAETIMEDOUT,
}

Listen_Error :: enum {
	Ok,
	// too many connections or not enough memory
	Resources,
	// addr or port are already in use.
	Addr_Taken = win32.WSAEADDRINUSE,
}

// Create a socket and wait for it to connect to a remote server.
//
// For UDP, this still calls connect, which means that you can use `write`/`try_write`/`read`/`try_read` etc, on it, but
// packets from other peers will be lost.
//
// TODO(tetra): Fast data?
dial :: proc(addr: Address, port: int, type := Socket_Type.Tcp) -> (skt: Socket, err: Dial_Error) {
	skt, err = start_dial(addr, port, type);
	if err != .Ok do return;

	err = finish_dial(skt);
	if err != .Ok do return;

	return;
}

// Create a socket and listen on a local address for incoming connections.
// For UDP, this just binds to the address so that you can `read_from`.
listen :: proc(bind_addr: Address, port: int, type := Socket_Type.Tcp, accept_queue_length := win32.SO_MAXCONN) -> (skt: Socket, err: Listen_Error) {
	// TODO(tetra): Sub-enums.
	create_err: Create_Error = ---;
	skt, create_err = create(get_addr_type(bind_addr), type);
	if create_err != .Ok do return;

	set_blocking(skt, false);

	// NOTE(tetra): For security.
	// Without this, it's possible to hijack the socket.
	// TODO(tetra): Include citation
	set_option(skt, .Exclusive_Addr_Use, true);

	// NOTE(tetra): We do this because without it, polling notifies
	// us that an error occurred if OOB data is received.
	if type != .Udp do set_option(skt, .Inline_Out_Of_Band, true);

	native_addr, native_addr_size := to_socket_address(bind_addr, port);
	res := win32.bind(win32.SOCKET(skt), &native_addr, native_addr_size);
	if res == win32.SOCKET_ERROR {
		bind_err := win32.WSAGetLastError();
		switch bind_err {
		case win32.WSAENOBUFS: err = .Resources;

		case win32.WSAEADDRNOTAVAIL: panic("binding addr not valid for this machine");
		case win32.WSAEACCES:   unimplemented(); // TODO(tetra): broadcasting
		case win32.WSAENETDOWN: panic("network subsystem failure");
		case:
			err = Listen_Error(bind_err);
		}
		return;
	}

	switch type {
	case .Tcp:
		res = win32.listen(win32.SOCKET(skt), i32(accept_queue_length));
		if res == win32.SOCKET_ERROR {
			listen_err := win32.WSAGetLastError();
			switch listen_err {
			case win32.WSAEMFILE, win32.WSAENOBUFS:
				err = .Resources;
			case win32.WSAEOPNOTSUPP: fmt.panicf("socket type %v does not support listen\n", type);
			case win32.WSAENETDOWN: panic("network subsystem failure");
			case:
				err = Listen_Error(listen_err);
			}
			return;			
		}
	case .Udp: // nothing
	}

	return;
}


Accept_Error :: enum {
	Ok,
	Resources,
	Reset = win32.WSAECONNRESET,
}

try_accept :: proc(skt: Socket) -> (accepted: bool, peer: Socket, remote_ep: Endpoint, err: Accept_Error) {
	s: win32.SOCKET;
	native_addr: win32.Socket_Address;
	sz := i32(size_of(native_addr));
	s = win32.accept(win32.SOCKET(skt), &native_addr, &sz);

	if s == win32.INVALID_SOCKET {
		skt_err := win32.WSAGetLastError();
		switch skt_err {
		case win32.WSAECONNRESET: err = .Reset;
		case win32.WSAEMFILE:     err = .Resources;
		case win32.WSAENOBUFS:    err = .Resources;
		case win32.WSAEWOULDBLOCK: err = .Ok;
		case: assert(false);
		}
		return;
	}

	remote_ep = to_canonical_endpoint(native_addr, sz);
	peer = Socket(s);
	accepted = true;
	return;
}

accept :: proc(skt: Socket) -> (peer: Socket, remote_ep: Endpoint, err: Accept_Error) {
	wait_err := wait_for_available_data(skt);
	if wait_err != .Ok {
		err = Accept_Error(wait_err);
		return;
	}
	accepted := false;
	accepted, peer, remote_ep, err = try_accept(skt);
	assert(accepted);
	return;
}






//                  //
// Creating sockets //
//                  //


// Create a non-blocking socket and tell it to connect to a remote server, but does not wait
// for it to complete.
// Call `finish_dial` to wait for it, or `try_finish_dial` to only check it.
//
// For UDP, this still calls connect, which means that you can use write/read on it,
// which will ignore packets from other peers.
//
// TODO(tetra): Fast data?
start_dial :: proc(addr: Address, port: int, type := Socket_Type.Tcp) -> (skt: Socket, err: Dial_Error) {
	assert(addr != nil, "attempt to dial nil address"); // TODO(tetra): Return error instead?

	create_err: Create_Error = ---;
	skt, create_err = create(get_addr_type(addr), type);
	switch create_err {
	case .Ok: // nothing
	case .Resources:      err = .Resources;
	case .Offline:        assert(false);
	case .Bad_Protocol:   assert(false);
	case .Bad_Type:       assert(false);
	case .Wrong_Protocol: assert(false);
	}

	if type != .Udp do set_option(skt, .Inline_Out_Of_Band, true);
	set_blocking(skt, false);

	native_addr, native_addr_size := to_socket_address(addr, port);
	res := win32.connect(win32.SOCKET(skt), &native_addr, native_addr_size);
	if res == win32.SOCKET_ERROR {
		dial_err := win32.WSAGetLastError();
		switch dial_err {
		case win32.WSAEACCES:        unimplemented(); // TODO(tetra): broadcasting
		case win32.WSAEWOULDBLOCK:   err = .Ok;
		case win32.WSAEISCONN:       unreachable();
		case win32.WSAEINVAL:        unreachable();
		case win32.WSAEFAULT:        unreachable();
		case win32.WSAEAFNOSUPPORT:  unreachable();
		case win32.WSAEALREADY:      unimplemented();
		case win32.WSAEADDRNOTAVAIL: panic("attempt to connect to the Any address");
		case win32.WSAENETDOWN:      panic("network subsystem failure");
		case:
			err = Dial_Error(dial_err);
		}
		return;
	}

	return;
}

// See if the dial is finished without blocking.
try_finish_dial :: proc(skt: Socket, timeout_ms	:= 0) -> (done: bool, err: Dial_Error) {
	_, w, wait_err := wait_for(skt, {.Can_Write}, timeout_ms);
	if wait_err != .Ok {
		err = Dial_Error(wait_err);
		return;
	}
	done = w;
	return;
}

finish_dial :: proc(skt: Socket) -> (err: Dial_Error) {
	wait_err := wait_for_can_write(skt);
	if wait_err != .Ok {
		err = Dial_Error(wait_err);
	}
	return;
}





equal :: proc(s, t: Socket) -> bool {
	return uintptr(win32.SOCKET(s)) == uintptr(win32.SOCKET(t));
}

Create_Error :: enum {
	Ok,
	// you are offline
	Offline,
	// socket descriptors or memory exhausted.
	Resources,
	// socket type not supported on the system.
	Bad_Type,
	// protocol not configured on this system, or protocol not implemented on socket type.
	Bad_Protocol,
	// wrong protocol type for this socket.
	Wrong_Protocol,
}

create :: proc(addr_type: Addr_Type, type: Socket_Type, protocol := Socket_Protocol.Auto) -> (skt: Socket, err: Create_Error) {
	win32.ensure_subsystem_started();

	// TODO(tetra): Local sockets
	native_family: i32;
	switch addr_type {
	case .Ipv4: native_family = win32.AF_INET;
	case .Ipv6: native_family = win32.AF_INET6;
	case: panic("unknown address type");
	}
	native_sock_type: i32;
	native_protocol: i32;
	switch type {
	case .Tcp:
		native_sock_type = win32.SOCK_STREAM;
		native_protocol = win32.IPPROTO_TCP;
	case .Udp:
		native_sock_type = win32.SOCK_DGRAM;
		native_protocol = win32.IPPROTO_UDP;
	case: assert(false);
	}
	if protocol != .Auto do native_protocol = i32(protocol);

	s := win32.socket(native_family, native_sock_type, native_protocol);
	if s == win32.INVALID_SOCKET {
		sock_err := win32.WSAGetLastError();
		switch sock_err {
		case win32.WSAENETDOWN:  err = .Offline;
		case win32.WSAENOBUFS,
			 win32.WSAEMFILE:    err = .Resources;

		case win32.WSAESOCKTNOSUPPORT: err = .Bad_Type;
		case win32.WSAEPROTONOSUPPORT: err = .Bad_Protocol;

		case win32.WSAEPROTOTYPE:      panic("protocol invalid for this socket"); // NOTE(tetra): Wrong protocol for this socket.
		case win32.WSAEAFNOSUPPORT:    assert(false); // TODO(tetra): Local sockets
		case win32.WSAEINVAL:          panic("used AF_UNSPEC, but no socket type or protocol");
		case win32.WSAENOTINITIALISED: panic("subsystem not initialized");

		case: fmt.panicf("create failed with unhandled error %v\n", Socket_Error(sock_err)); // TODO(tetra): remove need for fmt
		}
		return;
	}

	skt = Socket(win32.SOCKET(s));
	return;
}



Waitable_Status :: enum {
	Can_Read,
	Can_Accept,

	Can_Write,
	Dial_Complete,
}

WAIT_FOREVER :: -1;
DONT_WAIT    :: 0;

// Check if an event has occurred without blocking.
check_for :: inline proc(skt: Socket, statuses := bit_set[Waitable_Status]{.Can_Read, .Can_Write}) -> (readable, writable: bool, err: Socket_Error) {
	return wait_for(skt, statuses, DONT_WAIT);
}

// Waits for an event to occur.
// Returns false for all statuses if we time out.
wait_for :: proc(skt: Socket, statuses := Wait_Status{.Can_Read, .Can_Write}, timeout_ms := WAIT_FOREVER) -> (readable, writable: bool, err: Socket_Error) {
	rfd: win32.fd_set = ---;
	rfd.count = 1;
	rfd.array[0] = win32.SOCKET(skt);

	// value copy
	wfd := rfd;
	efd := rfd;

	timeout: win32.TIMEVAL;
	if timeout_ms >= 0 {
		if timeout_ms < 1000 {
			timeout.tv_usec = i32(timeout_ms * 1000);
		} else {
			timeout.tv_sec = i32(timeout_ms / 1000);
			timeout.tv_usec = i32(timeout_ms % 1000 * 1000);
		}
	}

	// returns 0 if it timed out.
	res := win32.select(
		0,
		.Can_Read in statuses || .Can_Accept in statuses ? &rfd : nil,
		.Can_Write in statuses || .Dial_Complete in statuses ? &wfd : nil,
		&efd,
		timeout_ms == -1 ? nil : &timeout
	);
	assert(res != win32.SOCKET_ERROR);
	if res == 1 {
		readable = rfd.count == 1;
		writable = wfd.count == 1;
		if efd.count == 1 {
			err = Socket_Error(get_option(skt, .Last_Error, i32));
		}
	}
	return;
}

Wait_Result :: struct {
	socket: Socket,
	status: bit_set[Waitable_Status],
	error: Socket_Error,
}

Wait_Status :: bit_set[Waitable_Status];

wait_for_any :: proc(skts: []Socket, statuses := Wait_Status{.Can_Read, .Can_Write}, timeout_ms := WAIT_FOREVER) -> []Wait_Result {
	results := make([dynamic]Wait_Result, context.temp_allocator);

	rfd: win32.fd_set;
	rfd.count = u32(len(skts));
	for s, i in skts do  rfd.array[i] = win32.SOCKET(s);

	// value copy
	wfd := rfd;
	efd := rfd;

	timeout: win32.TIMEVAL;
	if timeout_ms >= 0 {
		if timeout_ms < 1000 {
			timeout.tv_usec = i32(timeout_ms * 1000);
		} else {
			timeout.tv_sec = i32(timeout_ms / 1000);
			timeout.tv_usec = i32(timeout_ms % 1000 * 1000);
		}
	}

	// returns 0 if it timed out.
	res := win32.select(
		0,
		.Can_Read in statuses || .Can_Accept in statuses ? &rfd : nil,
		.Can_Write in statuses || .Dial_Complete in statuses ? &wfd : nil,
		&efd,
		timeout_ms == WAIT_FOREVER ? nil : &timeout
	);
	assert(res != win32.SOCKET_ERROR, "attempt to wait on closed socket");

	for s in skts {
		st: Wait_Status;

		readers := mem.slice_ptr(&rfd.array[0], int(rfd.count));
		writers := mem.slice_ptr(&wfd.array[0], int(wfd.count));
		failed  := mem.slice_ptr(&efd.array[0], int(efd.count));

		// TODO(tetra): SPEED: Really linear search?

		for r in readers {
			if equal(s, Socket(r)) {
				if is_listening_socket(s) {
					incl(&st, Wait_Status.Can_Accept);
				} else {
					incl(&st, Wait_Status.Can_Read);
				}
				break;
			}
		}

		for w in writers {
			if equal(s, Socket(w)) {
				incl(&st, Wait_Status.Can_Write);
				break;
			}
		}

		err := Socket_Error.Ok;
		for f in failed {
			if equal(s, Socket(f)) {
				err = Socket_Error(get_option(s, .Last_Error, i32));
				break;
			}
		}

		append(&results, Wait_Result {
			socket = s,
			status = st,
			error = err,
		});
	}

	return results[:];
}

wait_for_available_data :: inline proc(skt: Socket) -> (err: Socket_Error) {
	readable: bool = ---;
	readable, _, err = wait_for(skt, {.Can_Read}, WAIT_FOREVER);
	assert(readable || err != .Ok); // won't be false unless we time out.
	return;
}

wait_for_can_write :: inline proc(skt: Socket) -> (err: Socket_Error) {
	writable: bool = ---;
	_, writable, err = wait_for(skt, {.Can_Write}, WAIT_FOREVER);
	assert(writable || err != .Ok); // won't be false unless we time out.
	return;
}

wait_for_clients :: wait_for_available_data; // if a listening socket reports 'readable', it means a client is ready to accept.



Shutdown_Options :: enum {
	Receive = win32.SD_RECIEVE,
	Write = win32.SD_SEND,
	Both = win32.SD_BOTH,
}

shutdown :: proc(skt: Socket, ways: Shutdown_Options) -> bool {
	res := win32.shutdown(win32.SOCKET(skt), i32(ways));
	return res == 0;
}

close :: proc(skt: Socket) {
	// NOTE(tetra): Should handle the errors?
	_ = shutdown(skt, .Both);
	_ = win32.closesocket(win32.SOCKET(skt));
}



Socket_Option :: enum i32 {
	// Sets whether the socket is blocking or not.
	//
	// You should normally avoid using this and call `read`/`write`/`try_read`/`try_write` etc instead.
	//
	// However, normally, the underlying socket is non-blocking by default, and `read` and `write` poll-then-read, and poll-then-write, respectively.
	// If set to blocking mode, `try_write` and `try_read` may be used to do blocking calls instead and avoid the poll syscall.
	//
	// You cannot get this option's value.
	Blocking,

	Reuse_Addr               = win32.SO_REUSEADDR,
	Exclusive_Addr_Use       = win32.SO_EXCLUSIVEADDRUSE,
	Keep_Alive               = win32.SO_KEEPALIVE,
	Broadcast                = win32.SO_BROADCAST,
	Max_Message_Size         = win32.SO_MAX_MSG_SIZE,

	Blocking_Read_Timeout    = win32.SO_RCVTIMEO,
	Read_Buffer_Size_Hint    = win32.SO_RCVBUF,
	Read_Low_Mark            = win32.SO_SNDLOWAT, // read at least this amount, or none.
	Blocking_Write_Timeout   = win32.SO_SNDTIMEO,
	Write_Buffer_Size_Hint   = win32.SO_SNDBUF,
	Write_Low_Mark           = win32.SO_RCVLOWAT, // write at least this amount, or none.

	Socket_Type              = win32.SO_TYPE,
	Can_Accept               = win32.SO_ACCEPTCONN,
	Pause_Accepting          = win32.SO_PAUSE_ACCEPT, // when true, listen sockets will auto-reply with TCP RST.
	Use_Random_Outgoing_Port = win32.SO_RANDOMIZE_PORT,
	No_Unicast               = win32.SO_REUSE_MULTICASTPORT,
	Inline_Out_Of_Band       = win32.SO_OOBINLINE,
	Last_Error               = win32.SO_ERROR,
}

set_option :: proc(skt: Socket, option: Socket_Option, value: $T) {
	#partial switch option {
	case .Blocking:
		mode: c.ulong = bool(value) ? 0 : 1;
		res := win32.ioctlsocket(win32.SOCKET(skt), win32.FIONBIO, &mode);
		assert(res == 0);
	case:
		value_ := value;
		res := win32.setsockopt(win32.SOCKET(skt), win32.SOL_SOCKET, i32(option), &value_, size_of(T));
		assert(res != win32.SOCKET_ERROR);
	}
}

get_option :: proc(skt: Socket, option: Socket_Option, $T: typeid) -> (value: T) {
	sz := i32(size_of(T));
	res := win32.getsockopt(win32.SOCKET(skt), win32.SOL_SOCKET, i32(option), &value, &sz);
	assert(res != win32.SOCKET_ERROR);
	assert(sz == size_of(T));
	return;
}

// Sets the minumum amount of data that must be read by a read call of any kind.
// Normally, this is 1 byte, but it can be set higher in order to try to read at least
// a specific amount at once.
//
// If there is not the specfied amount of data available to read at the time of the call,
// it will return 0.
set_min_data_to_read :: inline proc(skt: Socket, count: int) {
	set_option(skt, .Read_Low_Mark, i32(count));
}

// If enabled, clients that connect will immediately be sent a TCP RST packet, causing they're connection to be reset.
set_accept_paused :: inline proc(skt: Socket, paused: bool) {
	set_option(skt, .Pause_Accepting, true);
}

set_blocking :: proc(skt: Socket, blocking: bool) {
	mode: c.ulong = blocking ? 0 : 1;
	res := win32.ioctlsocket(win32.SOCKET(skt), win32.FIONBIO, &mode);
	assert(res == 0);
}

is_listening_socket :: inline proc(skt: Socket) -> bool {
	return get_option(skt, .Can_Accept, bool);
}