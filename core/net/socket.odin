#+build windows, linux, darwin, freebsd
package net

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022-2023 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022-2023 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022-2023 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

any_socket_to_socket :: proc "contextless" (socket: Any_Socket) -> Socket {
	switch s in socket {
	case TCP_Socket:  return Socket(s)
	case UDP_Socket:  return Socket(s)
	case:
		// TODO(tetra): Bluetooth, Raw
		return Socket({})
	}
}

/*
    Expects both hostname and port to be present in the `hostname_and_port` parameter, either as:
    `a.host.name:9999`, or as `1.2.3.4:9999`, or IP6 equivalent.

    Calls `parse_hostname_or_endpoint` and `dial_tcp_from_host_or_endpoint`.
*/
dial_tcp_from_hostname_and_port_string :: proc(hostname_and_port: string, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname_and_port) or_return

	return dial_tcp_from_host_or_endpoint(target, options)
}

/*
    Expects the `hostname` as a string and `port` as a `int`.
    `parse_hostname_or_endpoint` is called and the `hostname` will be resolved into an IP.

    If a `hostname` of form `a.host.name:9999` is given, the port will be ignored in favor of the explicit `port` param.
*/
dial_tcp_from_hostname_with_port_override :: proc(hostname: string, port: int, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname) or_return
	switch &t in target {
	case Endpoint:
		t.port = port
	case Host:
		t.port = port
	}

	return dial_tcp_from_host_or_endpoint(target, options)
}

/*
    Expects the `host` as Host.
*/
dial_tcp_from_host :: proc(host: Host, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	if host.port == 0 {
		return 0, .Port_Required
	}
	ep4, ep6 := resolve(host.hostname) or_return
	ep := ep4 if ep4.address != nil else ep6 // NOTE(tetra): We don't know what family the server uses, so we just default to IP4.
	ep.port = host.port
	return dial_tcp_from_endpoint(ep, options)
}

/*
    Expects the `target` as a Host_OrEndpoint.
    Unwraps the underlying type and calls `dial_tcp_from_host` or `dial_tcp_from_endpoint`.
*/
dial_tcp_from_host_or_endpoint :: proc(target: Host_Or_Endpoint, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	switch t in target {
	case Endpoint:
		return dial_tcp_from_endpoint(t, options)
	case Host:
		return dial_tcp_from_host(t, options)
	}
	unreachable()
}

// Dial from an Address
dial_tcp_from_address_and_port :: proc(address: Address, port: int, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	return dial_tcp_from_endpoint({address, port}, options)
}

dial_tcp_from_endpoint :: proc(endpoint: Endpoint, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	return _dial_tcp_from_endpoint(endpoint, options)
}

dial_tcp :: proc{
	dial_tcp_from_endpoint,
	dial_tcp_from_address_and_port,
	dial_tcp_from_hostname_and_port_string,
	dial_tcp_from_hostname_with_port_override,
	dial_tcp_from_host,
	dial_tcp_from_host_or_endpoint,
}

create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Network_Error) {
	return _create_socket(family, protocol)
}

bind :: proc(socket: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	return _bind(socket, ep)
}

/*
	This type of socket becomes bound when you try to send data.
	It is likely what you want if you want to send data unsolicited.

	This is like a client TCP socket, except that it can send data to any remote endpoint without needing to establish a connection first.
*/
make_unbound_udp_socket :: proc(family: Address_Family) -> (socket: UDP_Socket, err: Network_Error) {
	sock := create_socket(family, .UDP) or_return
	socket = sock.(UDP_Socket)
	return
}

/*
	This type of socket is bound immediately, which enables it to receive data on the port.
	Since it's UDP, it's also able to send data without receiving any first.

	This is like a listening TCP socket, except that data packets can be sent and received without needing to establish a connection first.
	The `bound_address` is the address of the network interface that you want to use, or a loopback address if you don't care which to use.
*/
make_bound_udp_socket :: proc(bound_address: Address, port: int) -> (socket: UDP_Socket, err: Network_Error) {
	if bound_address == nil {
		return {}, .Bad_Address
	}
	socket = make_unbound_udp_socket(family_from_address(bound_address)) or_return
	bind(socket, {bound_address, port}) or_return
	return
}

listen_tcp :: proc(interface_endpoint: Endpoint, backlog := 1000) -> (socket: TCP_Socket, err: Network_Error) {
	assert(backlog > 0 && backlog < int(max(i32)))

	return _listen_tcp(interface_endpoint, backlog)
}

/*
	Returns the endpoint that the given socket is listening / bound on.
*/
bound_endpoint :: proc(socket: Any_Socket) -> (endpoint: Endpoint, err: Network_Error) {
	return _bound_endpoint(socket)
}

accept_tcp :: proc(socket: TCP_Socket, options := default_tcp_options) -> (client: TCP_Socket, source: Endpoint, err: Network_Error) {
	return _accept_tcp(socket, options)
}

close :: proc(socket: Any_Socket) {
	_close(socket)
}

recv_tcp :: proc(socket: TCP_Socket, buf: []byte) -> (bytes_read: int, err: Network_Error) {
	return _recv_tcp(socket, buf)
}

recv_udp :: proc(socket: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	return _recv_udp(socket, buf)
}

/*
	Receive data from into a buffer from any socket.

	Note: `remote_endpoint` parameter is non-nil only if the socket type is UDP. On TCP sockets it
	will always return `nil`.
*/
recv_any :: proc(socket: Any_Socket, buf: []byte) -> (
	bytes_read: int,
	remote_endpoint: Maybe(Endpoint),
	err: Network_Error,
) {
	switch socktype in socket {
	case TCP_Socket:
		bytes_read, err = recv_tcp(socktype, buf)
		return
	case UDP_Socket:
		return recv_udp(socktype, buf)
	case: panic("Not supported")
	}
}

recv :: proc{recv_tcp, recv_udp, recv_any}

/*
	Repeatedly sends data until the entire buffer is sent.
	If a send fails before all data is sent, returns the amount sent up to that point.
*/
send_tcp :: proc(socket: TCP_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	return _send_tcp(socket, buf)
}

/*
	Sends a single UDP datagram packet.

	Datagrams are limited in size; attempting to send more than this limit at once will result in a Message_Too_Long error.
	UDP packets are not guarenteed to be received in order.
*/
send_udp :: proc(socket: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	return _send_udp(socket, buf, to)
}

send_any :: proc(socket: Any_Socket, buf: []byte, to: Maybe(Endpoint) = nil) -> (
	bytes_written: int,
	err: Network_Error,
) {
	switch socktype in socket {
	case TCP_Socket:
		return send_tcp(socktype, buf)
	case UDP_Socket:
		return send_udp(socktype, buf, to.(Endpoint))
	case: panic("Not supported")
	}
}

send :: proc{send_tcp, send_udp, send_any}

shutdown :: proc(socket: Any_Socket, manner: Shutdown_Manner) -> (err: Network_Error) {
	return _shutdown(socket, manner)
}

set_option :: proc(socket: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Network_Error {
	return _set_option(socket, option, value, loc)
}

set_blocking :: proc(socket: Any_Socket, should_block: bool) -> (err: Network_Error) {
	return _set_blocking(socket, should_block)
}
