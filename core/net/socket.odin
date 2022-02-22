/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/
package net

//
// TODO(tetra): Bluetooth, Raw
//

any_socket_to_socket :: proc(any_socket: Any_Socket) -> Socket {
	switch s in any_socket {
	case TCP_Socket:  return Socket(s)
	case UDP_Socket:  return Socket(s)
	case:
		unreachable()
	}
}

Dial_String_Error :: enum {
	Bad_Port,
	Port_Required,
	Resolve_Failure,
}

dial_tcp_from_endpoint_string :: proc(endpoint: string, default_port := 0, options := default_tcp_options) -> (skt: TCP_Socket, err: Network_Error) {
	host, port, split_ok := split_port(endpoint)
	if !split_ok {
		return 0, .Bad_Port
	}
	port = port if port != 0 else default_port
	if port == 0 {
		return 0, .Port_Required
	}
	addr4, addr6, ok := resolve(host)
	if !ok {
		return 0, .Resolve_Failure  // TODO: replace with Resolve_Error when that's a thing
	}
	addr := addr4 if addr4 != nil else addr6 // NOTE(tetra): We don't know what family the server uses, so we just default to IPv4.
	return dial_tcp_from_endpoint({addr, port}, options)
}

dial_tcp :: proc{dial_tcp_from_endpoint, dial_tcp_from_endpoint_string}