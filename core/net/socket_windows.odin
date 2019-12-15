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
import "core:fmt" // TODO(tetra): remove

Socket :: struct {
	handle: win32.SOCKET,
	type: Socket_Type,
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
	return;
}

// WARNING: Must be kept in sync with Create_Error.
Dial_Address_Error :: enum {
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
// For UDP, this still calls connect so that you can use send/recv.
//
// TODO(tetra): Fast data?
// TODO(tetra): Dual stack? This might mean fucking up socket options though...
dial :: proc(addr: Address, port: int, type := Socket_Type.Tcp) -> (skt: Socket, err: Dial_Address_Error) {
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

	native_addr, native_addr_size := to_socket_address(addr, port);
	res := win32.connect(skt.handle, &native_addr, native_addr_size);
	if res == win32.SOCKET_ERROR {
		dial_err := win32.WSAGetLastError();
		switch dial_err {
		case win32.WSAEACCES:        unimplemented(); // TODO(tetra): broadcasting
		case win32.WSAEWOULDBLOCK:   unimplemented();
		case win32.WSAEISCONN:       unreachable();
		case win32.WSAEINVAL:        unreachable();
		case win32.WSAEFAULT:        unreachable();
		case win32.WSAEAFNOSUPPORT:  unreachable();
		case win32.WSAEALREADY:      unimplemented();
		case win32.WSAEADDRNOTAVAIL: panic("attempt to connect to the Any address");
		case win32.WSAENETDOWN:      panic("network subsystem failure");
		case:
			err = Dial_Address_Error(dial_err);
		}
		return;
	}

	return;
}

Resolve_Dial_Error :: enum {
	Ok,
	Resolve_Failed,
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

// Create a blocking socket and listen on a local address for incoming connections.
// For UDP, this just binds to the address so that you can recv_from.
listen :: proc(bind_addr: Address, port: int, type := Socket_Type.Tcp, accept_queue_length := win32.SO_MAXCONN) -> (skt: Socket, err: Listen_Error) {
	// TODO(tetra): Sub-enums.
	create_err: Create_Error = ---;
	skt, create_err = create(get_addr_type(bind_addr), type);
	if create_err != .Ok do return;

	// NOTE(tetra): For security.
	// Without this, it's possible to hijack the socket.
	set_option(skt, .Exclusive_Addr_Use, true);

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



Poll_Error :: enum i32 {
	Ok,
	Offline = win32.WSAENETDOWN,
	Resources = win32.WSAENOBUFS,
}

Poll_Result :: struct {
	readable, writable, failed, closed: bool,
}

poll :: inline proc(skt: Socket) -> (result: Poll_Result, err: Poll_Error) {
	return poll_wait(skt, 0); // 0 timeout = nonblocking.
}

poll_wait :: proc(skt: Socket, timeout_ms := -1) -> (result: Poll_Result, err: Poll_Error) {
	fd := win32.pollfd{
		fd = skt.handle,
		events = win32.POLLWRNORM | win32.POLLRDNORM | win32.POLLERR,
	};
	res := win32.WSAPoll(&fd, 1, i32(timeout_ms));
	if res == 1 {
		result.writable = (fd.revents & win32.POLLWRNORM) != 0;
		result.readable  = (fd.revents & win32.POLLRDNORM) != 0;
		result.failed   = (fd.revents & win32.POLLERR) != 0;
		result.closed   = (fd.revents & win32.POLLHUP) != 0;
	} else if res == win32.SOCKET_ERROR {
		err = Poll_Error(win32.WSAGetLastError());
	}
	return;
}



Send_Datagram_Error :: enum {
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

send_some_to :: proc(datagram_socket: Socket, data: []byte, to: Endpoint) -> (n: int, err: Send_Datagram_Error) {
	limit := min(int(max(i32)), len(data));

	native_addr, native_addr_len := to_socket_address(to.addr, to.port);
	res := win32.sendto(datagram_socket.handle, &data[0], i32(limit), 0, &native_addr, native_addr_len); // NOTE(tetra): pass MSG_NOSIGNAL on Unix.
	if res == win32.SOCKET_ERROR {
		send_err := win32.WSAGetLastError();
		switch send_err {
		case win32.WSAENETUNREACH:  err = .Offline;
		case win32.WSAENETDOWN:     err = .Offline;
		case win32.WSAENETRESET:    unreachable(); // because datagram socket.
		case win32.WSAEAFNOSUPPORT: err = .Bad_Addr;

		case win32.WSAEINVAL:      panic("socket not bound");
		case win32.WSAEWOULDBLOCK: unimplemented();
		case win32.WSAEOPNOTSUPP:  unimplemented(); // TODO(tetra): OOB data.
		case win32.WSAEACCES:      unimplemented(); // TODO(tetra): broadcast
		case:
			err = Send_Datagram_Error(send_err);
		}
		return;
	}

	n = int(res);
	return;
}

send_all_to :: proc(datagram_socket: Socket, data: []byte, to: Endpoint) -> (err: Send_Datagram_Error) {
	sent := 0;
	n: int = ---;
	for sent < len(data) {
		n, err = send_some_to(datagram_socket, data[sent:], to);
		if err != .Ok do return;
		sent += n;
	}
	err = .Ok;
	return;
}

Send_Bound_Error :: enum {
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
	// // operation is completing asynchronously; use the net.ready_to_* procs to probe after this.
	// Would_Block = win32.WSAEWOULDBLOCK,
}

send_some_bound :: proc(socket: Socket, data: []byte) -> (n: int, err: Send_Bound_Error) {
	limit := min(int(max(i32)), len(data));
	
	res := win32.send(socket.handle, &data[0], i32(limit), 0);
	if res == win32.SOCKET_ERROR {
		send_err := win32.WSAGetLastError();
		switch send_err {
		case win32.WSAECONNABORTED: err = .Aborted; // socket broken - must be reopened.
		case win32.WSAENETRESET:    err = .Aborted; // keep alive failed
		case win32.WSAEINVAL:       panic("socket not bound");
		case win32.WSAEWOULDBLOCK:  unimplemented();
		case win32.WSAEOPNOTSUPP:   panic("OOB data not implemented");
		case win32.WSAEACCES:       panic("broadcast not implemented");
		case:
			err = Send_Bound_Error(send_err);
		}
		return;
	}

	n = int(res);
	return;
}

send_all_bound :: proc(socket: Socket, data: []byte) -> (err: Send_Bound_Error) {
	n: int = ---;
	sent := 0;
	for sent < len(data) {
		n, err = send_some(socket, data[sent:]);
		if err != .Ok do return;
		sent += n;
	}
	err = .Ok;
	return;
}


// TODO(tetra): Should send_all be send?
send_some :: proc{send_some_to, send_some_bound};
send_all  :: proc{send_all_to, send_all_bound};


Recv_Datagram_Error :: enum {
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

recv_some_from :: proc(datagram_socket: Socket, buffer: []byte) -> (n: int, from: Endpoint, err: Recv_Datagram_Error) {
	limit := min(len(buffer), int(max(i32)));
	
	native_addr: win32.Socket_Address;
	native_addr_len := i32(size_of(native_addr));
	res := win32.recvfrom(datagram_socket.handle, &buffer[0], i32(limit), 0, &native_addr, &native_addr_len);
	if res == win32.SOCKET_ERROR {
		recv_err := win32.WSAGetLastError();
		switch recv_err {
		case win32.WSAENETRESET, win32.WSAECONNRESET:
			err = .Unreachable; // TTL expired
		case win32.WSAENETDOWN:  err = .Offline;
		case win32.WSAESHUTDOWN: err = .Shutdown;
		case win32.WSAEMSGSIZE:  err = .Truncated;
		case win32.WSAETIMEDOUT: err = .Timeout;
		case win32.WSAEWOULDBLOCK: unimplemented();
		case win32.WSAEISCONN:  panic("attempt to recv from connected socket");
		case win32.WSAEINVAL:   panic("socket not bound");
		case: fmt.panicf("send failed with unhandled error %v\n", Socket_Error(recv_err)); // TODO(tetra): remove need for fmt
		}
		return;
	}

	from = to_canonical_endpoint(native_addr, native_addr_len);
	n = int(res);
	return;
}

recv_all_from :: proc(datagram_socket: Socket, buffer: []byte) -> (from: Endpoint, err: Recv_Datagram_Error) {
	recvd := 0;
	n: int = ---;
	for recvd < len(buffer) {
		n, from, err = recv_some_from(datagram_socket, buffer[recvd:]);
		if err != .Ok do return;
		recvd += n;
	}
	return;
}

Recv_Error :: enum {
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

recv_some :: proc(socket: Socket, buffer: []byte) -> (n: int, err: Recv_Error) {
	if len(buffer) == 0 do return;

	limit := min(len(buffer), int(max(i32)));
	n = int(win32.recv(socket.handle, &buffer[0], i32(limit), 0));
	if n >= 0 do return;
	
	if n == win32.SOCKET_ERROR {
		err = Recv_Error(win32.WSAGetLastError());
	}
	return;
}

recv_all :: proc(datagram_socket: Socket, buffer: []byte) -> (err: Recv_Error) {
	recvd := 0;
	n: int = ---;
	for recvd < len(buffer) {
		n, err = recv_some(datagram_socket, buffer[recvd:]);
		if err != .Ok do return;
		recvd += n;
	}
	return;
}

peek_some :: proc(socket: Socket, buffer: []byte) -> (n: int, err: Recv_Error) {
	if len(buffer) == 0 do return;

	limit := min(len(buffer), int(max(i32)));
	n = int(win32.recv(socket.handle, &buffer[0], i32(limit), win32.MSG_PEEK));
	if n >= 0 do return;
	
	peek_err := win32.WSAGetLastError();
	switch peek_err {
	case win32.WSAEHOSTUNREACH, win32.WSAENETUNREACH:
		err = .Unreachable;
	case win32.WSAEWOULDBLOCK:
		unimplemented();
	case:
		err = Recv_Error(peek_err);
	}
	return;
}

peek_some_from :: proc(datagram_socket: Socket, buffer: []byte) -> (n: int, from: Endpoint, err: Recv_Datagram_Error) {
	limit := min(len(buffer), int(max(i32)));
	
	native_addr: win32.Socket_Address;
	native_addr_len := i32(size_of(native_addr));
	res := win32.recvfrom(datagram_socket.handle, &buffer[0], i32(limit), win32.MSG_PEEK, &native_addr, &native_addr_len);
	if res == win32.SOCKET_ERROR {
		recv_err := win32.WSAGetLastError();
		switch recv_err {
		case win32.WSAENETRESET, win32.WSAECONNRESET:
			err = .Unreachable; // TTL expired
		case win32.WSAEWOULDBLOCK: unimplemented();
		case win32.WSAEISCONN:  panic("attempt to recv_some_to on connected socket");
		case win32.WSAEINVAL:   panic("socket not bound");
		case:
			err = Recv_Datagram_Error(recv_err);
		}
		return;
	}

	from = to_canonical_endpoint(native_addr, native_addr_len);
	n = int(res);
	return;
}



Accept_Error :: enum {
	Ok,
	Resources,
	Reset = win32.WSAECONNRESET,
}

accept :: proc(socket: Socket) -> (peer: Socket, remote_ep: Endpoint, err: Accept_Error) {
	skt: win32.SOCKET;
	native_addr: win32.Socket_Address;
	sz := i32(size_of(native_addr)); 
	skt = win32.accept(socket.handle, &native_addr, &sz);
	remote_ep = to_canonical_endpoint(native_addr, sz);

	if skt == win32.INVALID_SOCKET {
		skt_err := win32.WSAGetLastError();
		switch skt_err {
		case win32.WSAECONNRESET: err = .Reset;
		case win32.WSAEMFILE:     err = .Resources;
		case win32.WSAENOBUFS:    err = .Resources;
		case: assert(false);
		}
		return;
	}

	peer = Socket { handle = skt, type = socket.type };
	return;
}


Shutdown_Options :: enum {
	Receive = win32.SD_RECIEVE,
	Send = win32.SD_SEND,
	Both = win32.SD_BOTH,
}

shutdown :: proc(socket: Socket, ways: Shutdown_Options) -> bool {
	res := win32.shutdown(socket.handle, i32(ways));
	return res == 0;
}

close :: proc(socket: Socket) {
	// NOTE(tetra): Should handle the errors?
	_ = shutdown(socket, .Both);
	_ = win32.closesocket(socket.handle);
}



Socket_Option :: enum i32 {
	Reuse_Addr 				= win32.SO_REUSEADDR,
	Exclusive_Addr_Use		= win32.SO_EXCLUSIVEADDRUSE,
	Keep_Alive 				= win32.SO_KEEPALIVE,
	Broadcast 				= win32.SO_BROADCAST,
	Send_Timeout 			= win32.SO_SNDTIMEO,
	Receive_Timeout 		= win32.SO_RCVTIMEO,
	Receive_Buffer_Size 	= win32.SO_RCVBUF,
	Send_Buffer_Size 		= win32.SO_SNDBUF,
	Max_Message_Size 		= win32.SO_MAX_MSG_SIZE,

	Socket_Type 			= win32.SO_TYPE,
	Can_Accept 				= win32.SO_ACCEPTCONN,
	Pause_Accepting 		= win32.SO_PAUSE_ACCEPT,
	Use_Random_Outgoing_Port = win32.SO_RANDOMIZE_PORT,
	No_Unicast 				= win32.SO_REUSE_MULTICASTPORT,

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
// 	case Send_Timeout: fallthrough;
// 	case Receive_Timeout: fallthrough;
// 	case Send_Buffer_Size: fallthrough;
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
// 	case Send_Timeout: fallthrough;
// 	case Receive_Timeout: fallthrough;
// 	case Send_Buffer_Size: fallthrough;
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
	sz := size_of(T);
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
set_recv_timeout :: proc(s: Socket, milliseconds: int) {
	set_option(s, .Receive_Timeout, i32(milliseconds));
}

// Sets the maximum amount of time `send` will wait for data to be sent.
// Or zero for no timeout.
set_send_timeout :: proc(s: Socket, milliseconds: int) {
	set_option(s, .Send_Timeout, i32(milliseconds));
}

set_recv_buffer_size :: proc(s: Socket, count: int) {
	set_option(s, .Receive_Buffer_Size, i32(count));
}

set_send_buffer_size :: proc(s: Socket, count: int) {
	set_option(s, .Send_Buffer_Size, i32(count));
}

