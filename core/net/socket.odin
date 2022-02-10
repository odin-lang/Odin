package net

//
// TODO(tetra): Bluetooth, Raw
//

Tcp_Socket :: distinct Socket
Udp_Socket :: distinct Socket

Socket_Protocol :: enum {
    Tcp,
    Udp,
}

Address_Family :: enum {
    IPv4,
    IPv6,
}

Any_Socket :: union {
    Tcp_Socket,
    Udp_Socket,
}

any_socket_to_socket :: proc(any_socket: Any_Socket) -> Socket {
    switch s in any_socket {
    case Tcp_Socket:  return Socket(s)
    case Udp_Socket:  return Socket(s)
    case:
        unreachable()
    }
}