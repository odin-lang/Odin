#+build !darwin
#+build !linux
#+build !freebsd
#+build !windows
#+build !netbsd
#+build !openbsd
#+private
package net

_SOCKET_OPTION_BROADCAST                 :: -1
_SOCKET_OPTION_REUSE_ADDRESS             :: -1
_SOCKET_OPTION_KEEP_ALIVE                :: -1
_SOCKET_OPTION_OUT_OF_BOUNDS_DATA_INLINE :: -1
_SOCKET_OPTION_LINGER                    :: -1
_SOCKET_OPTION_RECEIVE_BUFFER_SIZE       :: -1
_SOCKET_OPTION_SEND_BUFFER_SIZE          :: -1
_SOCKET_OPTION_RECEIVE_TIMEOUT           :: -1
_SOCKET_OPTION_SEND_TIMEOUT              :: -1

_SOCKET_OPTION_TCP_NODELAY :: -1

_SOCKET_OPTION_USE_LOOPBACK              :: -1
_SOCKET_OPTION_REUSE_PORT                :: -1
_SOCKET_OPTION_NO_SIGPIPE_FROM_EPIPE     :: -1
_SOCKET_OPTION_REUSE_PORT_LOAD_BALANCING :: -1

_SOCKET_OPTION_EXCLUSIVE_ADDR_USE :: -1
_SOCKET_OPTION_CONDITIONAL_ACCEPT :: -1
_SOCKET_OPTION_DONT_LINGER        :: -1

_SHUTDOWN_MANNER_RECEIVE :: -1
_SHUTDOWN_MANNER_SEND    :: -1
_SHUTDOWN_MANNER_BOTH    :: -1

_dial_tcp_from_endpoint :: proc(endpoint: Endpoint, options := DEFAULT_TCP_OPTIONS) -> (sock: TCP_Socket, err: Network_Error) {
	err = Create_Socket_Error.Network_Unreachable
	return
}

_create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (sock: Any_Socket, err: Create_Socket_Error) {
	err = .Network_Unreachable
	return
}

_bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Bind_Error) {
	err = .Network_Unreachable
	return
}

_listen_tcp :: proc(interface_endpoint: Endpoint, backlog := 1000) -> (skt: TCP_Socket, err: Network_Error) {
	err = Create_Socket_Error.Network_Unreachable
	return
}

_bound_endpoint :: proc(sock: Any_Socket) -> (ep: Endpoint, err: Socket_Info_Error) {
	err = .Network_Unreachable
	return
}

_peer_endpoint :: proc(sock: Any_Socket) -> (ep: Endpoint, err: Socket_Info_Error) {
	err = .Network_Unreachable
	return
}

_accept_tcp :: proc(sock: TCP_Socket, options := DEFAULT_TCP_OPTIONS) -> (client: TCP_Socket, source: Endpoint, err: Accept_Error) {
	err = .Network_Unreachable
	return
}

_close :: proc(skt: Any_Socket) {
}

_recv_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_read: int, err: TCP_Recv_Error) {
	err = .Network_Unreachable
	return
}

_recv_udp :: proc(skt: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: UDP_Recv_Error) {
	err = .Network_Unreachable
	return
}

_send_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_written: int, err: TCP_Send_Error) {
	err = .Network_Unreachable
	return
}

_send_udp :: proc(skt: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: UDP_Send_Error) {
	err = .Network_Unreachable
	return
}

_shutdown :: proc(skt: Any_Socket, manner: Shutdown_Manner) -> (err: Shutdown_Error) {
	err = .Network_Unreachable
	return
}

_set_option :: proc(s: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Socket_Option_Error {
	return .Network_Unreachable
}

_set_blocking :: proc(socket: Any_Socket, should_block: bool) -> (err: Set_Blocking_Error) {
	err = .Network_Unreachable
	return
}
