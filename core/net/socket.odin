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
		return Socket({})
	}
}

/*
    Expects both hostname and port to be present in the `hostname_and_port` parameter, either as:
    `a.host.name:9999`, or as `1.2.3.4:9999`, or IP6 equivalent.

    Calls `parse_hostname_or_endpoint` and `resolve`, then `dial_tcp_from_endpoint`.
*/
dial_tcp_from_hostname_and_port_string :: proc(hostname_and_port: string, options := default_tcp_options) -> (skt: TCP_Socket, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname_and_port) or_return
	switch t in target {
	case Endpoint:
		return dial_tcp_from_endpoint(t, options)
	case Host:
		if t.port == 0 {
			return 0, .Port_Required
		}
		ep4, ep6 := resolve(t.hostname) or_return
		ep := ep4 if ep4.address != nil else ep6 // NOTE(tetra): We don't know what family the server uses, so we just default to IP4.
		ep.port = t.port
		return dial_tcp_from_endpoint(ep, options)
	}
	unreachable()
}

/*
    Expects the `hostname` as a string and `port` as a `int`.
    `parse_hostname_or_endpoint` is called and the `hostname` will be resolved into an IP.

    If a `hostname` of form `a.host.name:9999` is given, the port will be ignored in favor of the explicit `port` param.
*/
dial_tcp_from_hostname_string_and_explicit_port :: proc(hostname: string, port: int, options := default_tcp_options) -> (skt: TCP_Socket, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname) or_return
	switch t in target {
	case Endpoint:
		return dial_tcp_from_endpoint({t.address, port}, options)
	case Host:
		if port == 0 {
			return 0, .Port_Required
		}
		ep4, ep6 := resolve(t.hostname) or_return
		ep := ep4 if ep4.address != nil else ep6 // NOTE(tetra): We don't know what family the server uses, so we just default to IP4.
		ep.port = port
		return dial_tcp_from_endpoint(ep, options)
	}
	unreachable()
}

dial_tcp_from_address_and_port :: proc(address: Address, port: int, options := default_tcp_options) -> (skt: TCP_Socket, err: Network_Error) {
	return dial_tcp_from_endpoint({address, port}, options)
}

dial_tcp :: proc{
	dial_tcp_from_endpoint,
	dial_tcp_from_address_and_port,
	dial_tcp_from_hostname_and_port_string,
	dial_tcp_from_hostname_string_and_explicit_port,
}