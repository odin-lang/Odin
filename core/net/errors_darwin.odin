#+build darwin
package net

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

import "core:c"
import "core:sys/posix"

@(private)
ESHUTDOWN :: 58

Create_Socket_Error :: enum c.int {
	None                                 = 0,
	Family_Not_Supported_For_This_Socket = c.int(posix.EAFNOSUPPORT),
	No_Socket_Descriptors_Available      = c.int(posix.EMFILE),
	No_Buffer_Space_Available            = c.int(posix.ENOBUFS),
	No_Memory_Available                  = c.int(posix.ENOMEM),
	Protocol_Unsupported_By_System       = c.int(posix.EPROTONOSUPPORT),
	Wrong_Protocol_For_Socket            = c.int(posix.EPROTONOSUPPORT),
	Family_And_Socket_Type_Mismatch      = c.int(posix.EPROTONOSUPPORT),
}

Dial_Error :: enum c.int {
	None                      = 0,
	Port_Required             = -1, // Attempted to dial an endpointing without a port being set.

	Address_In_Use            = c.int(posix.EADDRINUSE),
	In_Progress               = c.int(posix.EINPROGRESS),
	Cannot_Use_Any_Address    = c.int(posix.EADDRNOTAVAIL),
	Wrong_Family_For_Socket   = c.int(posix.EAFNOSUPPORT),
	Refused                   = c.int(posix.ECONNREFUSED),
	Is_Listening_Socket       = c.int(posix.EACCES),
	Already_Connected         = c.int(posix.EISCONN),
	Network_Unreachable       = c.int(posix.ENETUNREACH),  // Device is offline
	Host_Unreachable          = c.int(posix.EHOSTUNREACH), // Remote host cannot be reached
	No_Buffer_Space_Available = c.int(posix.ENOBUFS),
	Not_Socket                = c.int(posix.ENOTSOCK),
	Timeout                   = c.int(posix.ETIMEDOUT),

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block               = c.int(posix.EWOULDBLOCK), 
}

Bind_Error :: enum c.int {
	None                         = 0,
	Privileged_Port_Without_Root = -1, // Attempted to bind to a port less than 1024 without root access.

	Address_In_Use          = c.int(posix.EADDRINUSE),    // Another application is currently bound to this endpoint.
	Given_Nonlocal_Address  = c.int(posix.EADDRNOTAVAIL), // The address is not a local address on this machine.
	Broadcast_Disabled      = c.int(posix.EACCES),        // To bind a UDP socket to the broadcast address, the appropriate socket option must be set.
	Address_Family_Mismatch = c.int(posix.EFAULT),        // The address family of the address does not match that of the socket.
	Already_Bound           = c.int(posix.EINVAL),        // The socket is already bound to an address.
	No_Ports_Available      = c.int(posix.ENOBUFS),       // There are not enough ephemeral ports available.
}

Listen_Error :: enum c.int {
	None                                    = 0,
	Address_In_Use                          = c.int(posix.EADDRINUSE),
	Already_Connected                       = c.int(posix.EISCONN),
	No_Socket_Descriptors_Available         = c.int(posix.EMFILE),
	No_Buffer_Space_Available               = c.int(posix.ENOBUFS),
	Nonlocal_Address                        = c.int(posix.EADDRNOTAVAIL),
	Not_Socket                              = c.int(posix.ENOTSOCK),
	Listening_Not_Supported_For_This_Socket = c.int(posix.EOPNOTSUPP),
}

Accept_Error :: enum c.int {
	None                                              = 0,
	// TODO(tetra): Is this error actually possible here? Or is like Linux, in which case we can remove it.
	Reset                                             = c.int(posix.ECONNRESET), 
	Not_Listening                                     = c.int(posix.EINVAL),
	No_Socket_Descriptors_Available_For_Client_Socket = c.int(posix.EMFILE),
	No_Buffer_Space_Available                         = c.int(posix.ENOBUFS),
	Not_Socket                                        = c.int(posix.ENOTSOCK),
	Not_Connection_Oriented_Socket                    = c.int(posix.EOPNOTSUPP),

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block                                       = c.int(posix.EWOULDBLOCK), 
}

TCP_Recv_Error :: enum c.int {
	None              = 0,
	Shutdown          = ESHUTDOWN,
	Not_Connected     = c.int(posix.ENOTCONN),

	// TODO(tetra): Is this error actually possible here?
	Connection_Broken = c.int(posix.ENETRESET),
	Not_Socket        = c.int(posix.ENOTSOCK),
	Aborted           = c.int(posix.ECONNABORTED),

	// TODO(tetra): Determine when this is different from the syscall returning n=0 and maybe normalize them?
	Connection_Closed = c.int(posix.ECONNRESET),
	Offline           = c.int(posix.ENETDOWN),
	Host_Unreachable  = c.int(posix.EHOSTUNREACH),
	Interrupted       = c.int(posix.EINTR),

	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout           = c.int(posix.EWOULDBLOCK),
}

UDP_Recv_Error :: enum c.int {
	None             = 0,
	Buffer_Too_Small = c.int(posix.EMSGSIZE), // The buffer is too small to fit the entire message, and the message was truncated. When this happens, the rest of message is lost.
	Not_Socket       = c.int(posix.ENOTSOCK), // The so-called socket is not an open socket.
	Not_Descriptor   = c.int(posix.EBADF),    // The so-called socket is, in fact, not even a valid descriptor.
	Bad_Buffer       = c.int(posix.EFAULT),   // The buffer did not point to a valid location in memory.
	Interrupted      = c.int(posix.EINTR),    // A signal occurred before any data was transmitted. See signal(7).

	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout          = c.int(posix.EWOULDBLOCK), 
	Socket_Not_Bound = c.int(posix.EINVAL), // The socket must be bound for this operation, but isn't.
}

TCP_Send_Error :: enum c.int {
	None                      = 0,

	Aborted                   = c.int(posix.ECONNABORTED), 
	Connection_Closed         = c.int(posix.ECONNRESET),
	Not_Connected             = c.int(posix.ENOTCONN),
	Shutdown                  = ESHUTDOWN,

	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available = c.int(posix.ENOBUFS),
	Offline                   = c.int(posix.ENETDOWN),
	Host_Unreachable          = c.int(posix.EHOSTUNREACH),
	Interrupted               = c.int(posix.EINTR), // A signal occurred before any data was transmitted. See signal(7).

	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	Timeout                   = c.int(posix.EWOULDBLOCK), 
	Not_Socket                = c.int(posix.ENOTSOCK), // The so-called socket is not an open socket.
}

// TODO
UDP_Send_Error :: enum c.int {
	None                        = 0,
	Message_Too_Long            = c.int(posix.EMSGSIZE), // The message is larger than the maximum UDP packet size. No data was sent.

	// TODO: not sure what the exact circumstances for this is yet
	Network_Unreachable         = c.int(posix.ENETUNREACH),
	No_Outbound_Ports_Available = c.int(posix.EAGAIN),   // There are no more emphemeral outbound ports available to bind the socket to, in order to send.

	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout                     = c.int(posix.EWOULDBLOCK), 
	Not_Socket                  = c.int(posix.ENOTSOCK), // The so-called socket is not an open socket.
	Not_Descriptor              = c.int(posix.EBADF),    // The so-called socket is, in fact, not even a valid descriptor.
	Bad_Buffer                  = c.int(posix.EFAULT),   // The buffer did not point to a valid location in memory.
	Interrupted                 = c.int(posix.EINTR),    // A signal occurred before any data was transmitted. See signal(7).

	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available   = c.int(posix.ENOBUFS),
	No_Memory_Available         = c.int(posix.ENOMEM),   // No memory was available to properly manage the send queue.
}

Shutdown_Manner :: enum c.int {
	Receive = c.int(posix.SHUT_RD),
	Send    = c.int(posix.SHUT_WR),
	Both    = c.int(posix.SHUT_RDWR),
}

Shutdown_Error :: enum c.int {
	None           = 0,
	Aborted        = c.int(posix.ECONNABORTED),
	Reset          = c.int(posix.ECONNRESET),
	Offline        = c.int(posix.ENETDOWN),
	Not_Connected  = c.int(posix.ENOTCONN),
	Not_Socket     = c.int(posix.ENOTSOCK),
	Invalid_Manner = c.int(posix.EINVAL),
}

Socket_Option_Error :: enum c.int {
	None                       = 0,
	Offline                    = c.int(posix.ENETDOWN),
	Timeout_When_Keepalive_Set = c.int(posix.ENETRESET),
	Invalid_Option_For_Socket  = c.int(posix.ENOPROTOOPT),
	Reset_When_Keepalive_Set   = c.int(posix.ENOTCONN),
	Not_Socket                 = c.int(posix.ENOTSOCK),
}

Set_Blocking_Error :: enum c.int {
	None = 0,

	// TODO: Add errors for `set_blocking`
}
