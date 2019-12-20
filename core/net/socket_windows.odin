package net

/*
	TODO:

	Returning a single error type means that we can name all the errors 'err', but that
	we have to do things like
	```
	n: int;
	n, err = net.recv(...);
	if err != .Ok {
		// ...
	}
	```

	With specific errors:
	```
	read, read_err := net.recv(...);
	if read_err != .Ok {
		// ...
	}
	```

	This does seem better, but you still are forced to name the error something
	specific.
	I'm not sure I want to _force_ people to have to do this.


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
import "core:sync"

import "core:fmt" // TODO(tetra): remove

Socket :: struct {
	handle: win32.SOCKET,
}

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

equal :: proc(s, t: Socket) -> bool {
	return uintptr(s.handle) == uintptr(t.handle);
}

// WARNING: Must be kept in sync with Dial_Error.
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
	#complete switch type {
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


	skt = Socket { handle = win32.SOCKET(s) };
	assert(set_blocking(skt, false) == .Ok);

	return;
}

// WARNING: Must be kept in sync with Create_Error.
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

// Create a blocking socket and connect it to a remote server.
// For UDP, this still calls connect so that you can use write/recv.
//
// TODO(tetra): Fast data?
start_dial :: proc(addr: Address, port: int, type := Socket_Type.Tcp) -> (skt: Socket, err: Dial_Error) {
	assert(addr != nil); // TODO(tetra): Return error instead?

	create_err: Create_Error = ---;
	skt, create_err = create(get_addr_type(addr), type);
	if err != .Ok {
		switch create_err {
		case .Resources:
			err = .Resources;
		case: unreachable();
		}
		return;
	}

	assert(set_option(skt, .Inline_Out_Of_Band, true) == .Ok);
	assert(set_option(skt, .Write_Buffer_Size, i32(2)) == .Ok);

	native_addr, native_addr_size := to_socket_address(addr, port);
	res := win32.connect(skt.handle, &native_addr, native_addr_size);
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

Finish_Dial_Error :: enum i32 {
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

// Wait until the dial is finished.
finish_dial :: proc(skt: Socket) -> (err: Finish_Dial_Error) {
	wait_err := wait_for_writable(skt);
	if wait_err != .Ok {
		err = Finish_Dial_Error(wait_err);
		return;
	}
	return;
}

// See if the dial is finished without blocking.
try_finish_dial :: proc(skt: Socket) -> (done: bool, err: Finish_Dial_Error) {
	_, w, wait_err := check_for_status(skt, {.Writable, .Failed});
	if wait_err != .Ok {
		err = Finish_Dial_Error(wait_err);
		return;
	}
	done = w;
	return;
}

dial :: proc(addr: Address, port: int, type := Socket_Type.Tcp) -> (skt: Socket, err: Dial_Error) {
	s, start_err := start_dial(addr, port, type);
	fin_err := finish_dial(s);
	if fin_err != .Ok {
		err = Dial_Error(fin_err);
		return;
	}
	skt = s;
	return;
}



Listen_Error :: enum {
	Ok,
	// too many connections or not enough memory
	Resources,
	// addr or port are already in use.
	Addr_Taken = win32.WSAEADDRINUSE,
}

// Create a blocking socket and listen on a local address for incoming connections.
// For UDP, this just binds to the address so that you can read_from.
listen :: proc(bind_addr: Address, port: int, type := Socket_Type.Tcp, accept_queue_length := win32.SO_MAXCONN) -> (skt: Socket, err: Listen_Error) {
	// TODO(tetra): Sub-enums.
	create_err: Create_Error = ---;
	skt, create_err = create(get_addr_type(bind_addr), type);
	if create_err != .Ok do return;

	// NOTE(tetra): For security.
	// Without this, it's possible to hijack the socket.
	set_option(skt, .Exclusive_Addr_Use, true);

	// NOTE(tetra): We do this because without it, polling notifies
	// us that an error occurred if OOB data is received.
	set_option(skt, .Inline_Out_Of_Band, true);

	native_addr, native_addr_size := to_socket_address(bind_addr, port);
	res := win32.bind(skt.handle, &native_addr, native_addr_size);
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
		res = win32.listen(skt.handle, i32(accept_queue_length));
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
	}

	return;
}



Event_Type :: enum {
	Readable,
	Writable,
	Failed,
}

// Check if an event has occurred without blocking.
check_for_status :: inline proc(skt: Socket, targest := bit_set[Event_Type]{.Readable, .Writable, .Failed}) -> (read_ok, write_ok: bool, err: Socket_Error) {
	return wait_for_status(skt, 0); // 0 timeout = nonblocking.
}

// Waits for an event to occur.
// Returns false for all events if we time out.
wait_for_status :: proc(skt: Socket, timeout_ms := -1, types := bit_set[Event_Type]{.Readable, .Writable, .Failed}) -> (read_ok, write_ok: bool, err: Socket_Error) {
	rfd: win32.fd_set = ---;
	rfd.count = 1;
	rfd.array[0] = skt.handle;

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
		.Readable in types ? &rfd : nil,
		.Writable in types ? &wfd : nil,
		.Failed   in types ? &efd : nil,
		timeout_ms == -1 ? nil : &timeout
	);
	assert(res != win32.SOCKET_ERROR);
	if res == 1 {
		read_ok = rfd.count == 1;
		write_ok = wfd.count == 1;
		if efd.count == 1 {
			last_err, get_err := get_option(skt, .Error, i32);
			assert(get_err == .Ok);
			err = Socket_Error(last_err);
		}
	}
	return;
}

wait_for_readable :: inline proc(skt: Socket) -> (err: Socket_Error) {
	readable: bool = ---;
	readable, _, err = wait_for_status(skt, -1, {.Readable, .Failed});
	assert(readable || err != .Ok); // won't be false be we won't time out.
	return;
}

wait_for_writable :: inline proc(skt: Socket) -> (err: Socket_Error) {
	writable: bool = ---;
	_, writable, err = wait_for_status(skt, -1, {.Writable, .Failed});
	assert(writable || err != .Ok); // won't be false be we won't time out.
	return;
}


Write_Datagram_Error :: enum {
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

try_write_to :: proc(dgram_skt: Socket, data: []u8, to: Endpoint) -> (n: int, err: Write_Datagram_Error) {
	limit := min(int(max(i32)), len(data));

	native_addr, native_addr_len := to_socket_address(to.addr, to.port);
	res := win32.sendto(dgram_skt.handle, &data[0], i32(limit), 0, &native_addr, native_addr_len); // NOTE(tetra): pass MSG_NOSIGNAL on Unix.
	if res == win32.SOCKET_ERROR {
		write_err := win32.WSAGetLastError();
		switch write_err {
		case win32.WSAENETUNREACH:  err = .Offline;
		case win32.WSAENETDOWN:     err = .Offline;
		case win32.WSAENETRESET:    unreachable(); // because datagram socket.
		case win32.WSAEAFNOSUPPORT: err = .Bad_Addr;

		case win32.WSAEINVAL:      panic("socket not bound");
		case win32.WSAEWOULDBLOCK:
			err = .Ok;
			n = 0;
		case win32.WSAEOPNOTSUPP:  unimplemented(); // TODO(tetra): OOB data.
		case win32.WSAEACCES:      unimplemented(); // TODO(tetra): broadcast
		case:
			err = Write_Datagram_Error(write_err);
		}
		return;
	}

	n = int(res);
	return;
}

write_to :: proc(dgram_skt: Socket, data: []u8, to: Endpoint) -> (err: Write_Datagram_Error) {
	sent := 0;
	n: int = ---;
	for sent < len(data) {
		wait_err := wait_for_writable(dgram_skt);
		if wait_err != .Ok {
			err = Write_Datagram_Error(wait_err);
			return;
		}
		n, err = try_write_to(dgram_skt, data[sent:], to);
		if err != .Ok do return;
		sent += n;
	}
	err = .Ok;
	return;
}

Write_Error :: enum {
	Ok,
	// socket broke somewhere - should be reopened.
	Aborted,
	// socket not connected (only connection-based sockets)
	Not_Connected = win32.WSAENOTCONN,
	// socket has been shut down in the required direction.
	Shutdown = win32.WSAESHUTDOWN,
	// datagram socket and the data is too big.
	Truncated = win32.WSAEMSGSIZE,
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

try_write :: proc(skt: Socket, data: []u8) -> (n: int, err: Write_Error) {
	limit := min(int(max(i32)), len(data));
	
	res := win32.send(skt.handle, &data[0], i32(limit), 0);
	if res == win32.SOCKET_ERROR {
		write_err := win32.WSAGetLastError();
		switch write_err {
		case win32.WSAECONNABORTED: err = .Aborted; // socket broken - must be reopened.
		case win32.WSAENETRESET:    err = .Aborted; // keep alive failed
		case win32.WSAEINVAL:       panic("socket not bound");
		case win32.WSAEWOULDBLOCK:
			err = .Ok;
			n = 0; // TODO(tetra): Verify that this means that no data was sent.
		case win32.WSAEOPNOTSUPP:   panic("OOB data not implemented");
		case win32.WSAEACCES:       panic("broadcast not implemented");
		case:
			err = Write_Error(write_err);
		}
		return;
	}

	n = int(res);
	assert(n == len(data), "turns out write can sometimes not send it all");
	return;
}

write :: proc(skt: Socket, data: []u8) -> (err: Write_Error) {
	n: int = ---;
	sent := 0;
	for sent < len(data) {
		wait_err := wait_for_writable(skt);
		if wait_err != .Ok {
			err = Write_Error(wait_err);
			return;
		}
		n, err = try_write(skt, data[sent:]);
		if err != .Ok do return;
		assert(n > 0);
		sent += n;
	}
	err = .Ok;
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

try_read_from :: proc(dgram_skt: Socket, buffer: []u8) -> (n: int, from: Endpoint, err: Read_From_Error) {
	limit := min(len(buffer), int(max(i32)));
	
	native_addr: win32.Socket_Address;
	native_addr_len := i32(size_of(native_addr));
	res := win32.recvfrom(dgram_skt.handle, &buffer[0], i32(limit), 0, &native_addr, &native_addr_len);
	if res == win32.SOCKET_ERROR {
		read_err := win32.WSAGetLastError();
		switch read_err {
		case win32.WSAENETRESET, win32.WSAECONNRESET:
			err = .Unreachable; // TTL expired
		case win32.WSAENETDOWN:  err = .Offline;
		case win32.WSAESHUTDOWN: err = .Shutdown;
		case win32.WSAEMSGSIZE:  err = .Truncated;
		case win32.WSAETIMEDOUT: err = .Timeout;
		case win32.WSAEWOULDBLOCK:
			err = .Ok;
			n = 0;
		case win32.WSAEISCONN:  panic("attempt to recv from connected socket");
		case win32.WSAEINVAL:   panic("socket not bound");
		case: fmt.panicf("write failed with unhandled error %v\n", Socket_Error(read_err)); // TODO(tetra): remove need for fmt
		}
		return;
	}

	from = to_canonical_endpoint(native_addr, native_addr_len);
	n = int(res);
	return;
}

read_from :: proc(dgram_skt: Socket, buffer: []u8) -> (n: int, from: Endpoint, err: Read_From_Error) {
	wait_err := wait_for_readable(dgram_skt);
	if wait_err != .Ok {
		err = Read_From_Error(wait_err);
		return;
	}
	return try_read_from(dgram_skt, buffer);
}

// Same as `read_all`, but returns 0 immediately instead of blocking.
// TODO(tetra): Audit that this works.
try_read_all_from :: proc(skt: Socket, buffer: []u8) -> (ok: bool, from: Endpoint, err: Read_From_Error) {
	set_min_data_to_read(skt, len(buffer));
	defer set_min_data_to_read(skt, 1);

	n: int = ---;
	n, from, err = read_from(skt, buffer[:n]);
	assert(n == 0 || n == len(buffer));
	ok = n == len(buffer);
	return;
}


read_all_from :: proc(dgram_skt: Socket, buffer: []u8) -> (from: Endpoint, err: Read_From_Error) {
	recvd := 0;
	n: int = ---;
	for recvd < len(buffer) {
		n, from, err = read_from(dgram_skt, buffer[recvd:]);
		if err != .Ok do return;
		recvd += n;
	}
	return;
}

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

try_read :: proc(skt: Socket, buffer: []u8) -> (n: int, err: Read_Error) {
	if len(buffer) == 0 do return;

	limit := min(len(buffer), int(max(i32)));
	n = int(win32.recv(skt.handle, &buffer[0], i32(limit), 0));
	if n >= 0 do return;
	
	assert(n == win32.SOCKET_ERROR);
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

read :: proc(skt: Socket, buffer: []u8) -> (n: int, err: Read_Error) {
	wait_err := wait_for_readable(skt);
	if wait_err != .Ok {
		err = Read_Error(wait_err);
		return;
	}
	return try_read(skt, buffer);
}

// Same as `read_all`, but returns 0 immediately instead of blocking.
// TODO(tetra): Audit that this works.
try_read_all :: proc(skt: Socket, buffer: []u8) -> (n: int, err: Read_Error) {
	set_min_data_to_read(skt, len(buffer));
	defer set_min_data_to_read(skt, 1);

	n, err = read(skt, buffer[:n]);
	assert(n == 0 || n == len(buffer));
	return;
}

read_all :: proc(skt: Socket, buffer: []u8) -> (err: Read_Error) {
	recvd := 0;
	n: int = ---;
	for recvd < len(buffer) {
		n, err = read(skt, buffer[recvd:]);
		if err != .Ok do return;
		recvd += n;
	}
	return;
}



Accept_Error :: enum {
	Ok,
	Resources,
	Reset = win32.WSAECONNRESET,
}

Accept_Option :: enum {
	// return immediately, with accepted=false if no-one is waiting.
	Check_For_Client,
	// block until a client connects.
	Wait_For_Client,
}

try_accept :: proc(skt: Socket, options := Accept_Option.Check_For_Client) -> (peer: Socket, remote_ep: Endpoint, accepted: bool, err: Accept_Error) {
	if options == .Wait_For_Client {
		wait_err := wait_for_readable(skt);
		if wait_err != .Ok {
			err = Accept_Error(wait_err);
			return;
		}
	}

	s: win32.SOCKET;
	native_addr: win32.Socket_Address;
	sz := i32(size_of(native_addr)); 
	s = win32.accept(skt.handle, &native_addr, &sz);

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
	peer = Socket { handle = s };
	accepted = true;
	return;
}

accept :: inline proc(skt: Socket) -> (peer: Socket, remote_ep: Endpoint, err: Accept_Error) {
	accepted: bool = ---;
	peer, remote_ep, accepted, err = try_accept(skt, .Wait_For_Client);
	assert(accepted);
	return;
}

Shutdown_Options :: enum {
	Receive = win32.SD_RECIEVE,
	Write = win32.SD_SEND,
	Both = win32.SD_BOTH,
}

shutdown :: proc(skt: Socket, ways: Shutdown_Options) -> bool {
	res := win32.shutdown(skt.handle, i32(ways));
	return res == 0;
}

close :: proc(skt: Socket) {
	// NOTE(tetra): Should handle the errors?
	_ = shutdown(skt, .Both);
	_ = win32.closesocket(skt.handle);
}



Socket_Option :: enum i32 {
	Reuse_Addr 				= win32.SO_REUSEADDR,
	Exclusive_Addr_Use		= win32.SO_EXCLUSIVEADDRUSE,
	Keep_Alive 				= win32.SO_KEEPALIVE,
	Broadcast 				= win32.SO_BROADCAST,
	Max_Message_Size 		= win32.SO_MAX_MSG_SIZE,

	Read_Timeout	 		= win32.SO_RCVTIMEO,
	Read_Buffer_Size	 	= win32.SO_RCVBUF,
	Read_Low_Mark           = win32.SO_SNDLOWAT, // read at least this amount, or none.
	Write_Timeout 			= win32.SO_SNDTIMEO,
	Write_Buffer_Size 		= win32.SO_SNDBUF,
	Write_Low_Mark			= win32.SO_RCVLOWAT, // write at least this amount, or none.

	Socket_Type 			= win32.SO_TYPE,
	Can_Accept 				= win32.SO_ACCEPTCONN,
	Pause_Accepting 		= win32.SO_PAUSE_ACCEPT, // when true, listen sockets will auto-reply with TCP RST.
	Use_Random_Outgoing_Port = win32.SO_RANDOMIZE_PORT,
	No_Unicast 				= win32.SO_REUSE_MULTICASTPORT,
	Inline_Out_Of_Band		= win32.SO_OOBINLINE,
	Error					= win32.SO_ERROR,
	// TODO
	// Manual_Ip_Header,
}

// @private
// get_option_level :: proc(opt: Socket_Option) -> i32 {
// 	switch opt {
// 	case Reuse_Addr: fallthrough;
// 	case Exclusive_Addr_Use: fallthrough;
// 	case Keep_Alive: fallthrough;
// 	case Broadcast: fallthrough;
// 	case Write_Timeout: fallthrough;
// 	case Receive_Timeout: fallthrough;
// 	case Write_Buffer_Size: fallthrough;
// 	case Receive_Buffer_Size: fallthrough;
// 	case Max_Message_Size: fallthrough;
// 	case Socket_Type: fallthrough;
// 	case Can_Accept: fallthrough;
// 	case Pause_Accepting: fallthrough;
// 	case Use_Random_Outgoing_Port: fallthrough;
// 	case No_Unicast: fallthrough;
// 	case Manual_Ip_Header:
// 		return win32.SOL_SOCKET;

// 	case: assert(false);
// 	}
// }

// @private
// get_option_value :: proc(opt: Socket_Option) -> i32 {
// 	switch opt {
// 	case Reuse_Addr: fallthrough;
// 	case Exclusive_Addr_Use: fallthrough;
// 	case Keep_Alive: fallthrough;
// 	case Broadcast: fallthrough;
// 	case Write_Timeout: fallthrough;
// 	case Receive_Timeout: fallthrough;
// 	case Write_Buffer_Size: fallthrough;
// 	case Receive_Buffer_Size: fallthrough;
// 	case Max_Message_Size: fallthrough;
// 	case Socket_Type: fallthrough;
// 	case Can_Accept: fallthrough;
// 	case Pause_Accepting: fallthrough;
// 	case Use_Random_Outgoing_Port: fallthrough;
// 	case No_Unicast:
// 		return i32(opt);
// 	case Manual_Ip_Header:

// 	}
// }

set_option :: proc(s: Socket, option: Socket_Option, value: $T) -> (err: Socket_Error) {
	value_ := value;
	res := win32.setsockopt(s.handle, win32.SOL_SOCKET, i32(option), &value_, size_of(value_));
	if res == win32.SOCKET_ERROR {
		err = Socket_Error(win32.WSAGetLastError());
	}
	return;
}

get_option :: proc(s: Socket, option: Socket_Option, $T: typeid) -> (value: T, err: Socket_Error) {
	sz := i32(size_of(T));
	res := win32.getsockopt(s.handle, win32.SOL_SOCKET, i32(option), &value, &sz);
	if res == win32.SOCKET_ERROR {
		err = Socket_Error(win32.WSAGetLastError());
	} else {
		assert(sz == size_of(T));
	}
	return;
}

// Sets the maximum amount of time `recv` will wait for data to be read.
// Or zero for no timeout.
set_read_timeout :: proc(s: Socket, milliseconds: int) {
	set_option(s, .Read_Timeout, i32(milliseconds));
}

// Sets the maximum amount of time `write` will wait for data to be sent.
// Or zero for no timeout.
set_write_timeout :: proc(s: Socket, milliseconds: int) {
	set_option(s, .Write_Timeout, i32(milliseconds));
}

set_read_buffer_size :: proc(s: Socket, count: int) {
	set_option(s, .Read_Buffer_Size, i32(count));
}

set_write_buffer_size :: proc(s: Socket, count: int) {
	set_option(s, .Write_Buffer_Size, i32(count));
}

set_blocking :: proc(skt: Socket, blocking: bool) -> Socket_Error {
	mode: c.ulong = blocking ? 0 : 1;
	res := win32.ioctlsocket(skt.handle, win32.FIONBIO, &mode);
	if res != 0 {
		return Socket_Error(win32.WSAGetLastError());
	}
	return .Ok;
}

set_min_data_to_read :: proc(skt: Socket, count: int) {
	set_option(skt, .Read_Low_Mark, i32(count));
}