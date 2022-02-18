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

/*
 * Determines the default value for whether dial_tcp() and accept_tcp() will set TCP_NODELAY on the new
 * socket, and the client socket, respectively.
 * This can also be set on a per-socket basis using the 'options' optional parameter to those procedures.
 *
 * When TCP_NODELAY is set, data will be sent out to the peer as quickly as possible, rather than being
 * coalesced into fewer network packets.
 *
 * This makes the networking layer more eagerly send data when you ask it to,
 * which can reduce latency by up to 200ms.
 *
 * This does mean that a lot of small writes will negatively effect throughput however,
 * since the Nagel algorithm will be disabled, and each write becomes one
 * IP packet. This will increase traffic by a factor of 40, with IP and TCP
 * headers for each payload.
 *
 * However, you can avoid this by buffering things up yourself if you wish to send a lot of
 * short data chunks, when TCP_NODELAY is enabled on that socket.
 */
ODIN_NET_TCP_NODELAY_DEFAULT :: #config(ODIN_NET_TCP_NODELAY_DEFAULT, true)

Tcp_Options :: struct {
    no_delay: bool,
}
default_tcp_options := Tcp_Options {
    no_delay = ODIN_NET_TCP_NODELAY_DEFAULT,
}