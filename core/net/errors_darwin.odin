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
import "core:os"

Create_Socket_Error :: enum c.int {
	None                                 = 0,
	Family_Not_Supported_For_This_Socket = c.int(os.EAFNOSUPPORT),
	No_Socket_Descriptors_Available      = c.int(os.EMFILE),
	No_Buffer_Space_Available            = c.int(os.ENOBUFS),
	No_Memory_Available_Available        = c.int(os.ENOMEM),
	Protocol_Unsupported_By_System       = c.int(os.EPROTONOSUPPORT),
	Wrong_Protocol_For_Socket            = c.int(os.EPROTONOSUPPORT),
	Family_And_Socket_Type_Mismatch      = c.int(os.EPROTONOSUPPORT),
}

Dial_Error :: enum c.int {
	None                      = 0,
	Port_Required             = -1, // Attempted to dial an endpointing without a port being set.

	Address_In_Use            = c.int(os.EADDRINUSE),
	In_Progress               = c.int(os.EINPROGRESS),
	Cannot_Use_Any_Address    = c.int(os.EADDRNOTAVAIL),
	Wrong_Family_For_Socket   = c.int(os.EAFNOSUPPORT),
	Refused                   = c.int(os.ECONNREFUSED),
	Is_Listening_Socket       = c.int(os.EACCES),
	Already_Connected         = c.int(os.EISCONN),
	Network_Unreachable       = c.int(os.ENETUNREACH),  // Device is offline
	Host_Unreachable          = c.int(os.EHOSTUNREACH), // Remote host cannot be reached
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Not_Socket                = c.int(os.ENOTSOCK),
	Timeout                   = c.int(os.ETIMEDOUT),

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block               = c.int(os.EWOULDBLOCK), 
}

Bind_Error :: enum c.int {
	None                         = 0,
	Privileged_Port_Without_Root = -1, // Attempted to bind to a port less than 1024 without root access.

	Address_In_Use          = c.int(os.EADDRINUSE),    // Another application is currently bound to this endpoint.
	Given_Nonlocal_Address  = c.int(os.EADDRNOTAVAIL), // The address is not a local address on this machine.
	Broadcast_Disabled      = c.int(os.EACCES),        // To bind a UDP socket to the broadcast address, the appropriate socket option must be set.
	Address_Family_Mismatch = c.int(os.EFAULT),        // The address family of the address does not match that of the socket.
	Already_Bound           = c.int(os.EINVAL),        // The socket is already bound to an address.
	No_Ports_Available      = c.int(os.ENOBUFS),       // There are not enough ephemeral ports available.
}

Listen_Error :: enum c.int {
	None                                    = 0,
	Address_In_Use                          = c.int(os.EADDRINUSE),
	Already_Connected                       = c.int(os.EISCONN),
	No_Socket_Descriptors_Available         = c.int(os.EMFILE),
	No_Buffer_Space_Available               = c.int(os.ENOBUFS),
	Nonlocal_Address                        = c.int(os.EADDRNOTAVAIL),
	Not_Socket                              = c.int(os.ENOTSOCK),
	Listening_Not_Supported_For_This_Socket = c.int(os.EOPNOTSUPP),
}

Accept_Error :: enum c.int {
	None                                              = 0,
	// TODO(tetra): Is this error actually possible here? Or is like Linux, in which case we can remove it.
	Reset                                             = c.int(os.ECONNRESET), 
	Not_Listening                                     = c.int(os.EINVAL),
	No_Socket_Descriptors_Available_For_Client_Socket = c.int(os.EMFILE),
	No_Buffer_Space_Available                         = c.int(os.ENOBUFS),
	Not_Socket                                        = c.int(os.ENOTSOCK),
	Not_Connection_Oriented_Socket                    = c.int(os.EOPNOTSUPP),

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block                                       = c.int(os.EWOULDBLOCK), 
}

TCP_Recv_Error :: enum c.int {
	None              = 0,
	Shutdown          = c.int(os.ESHUTDOWN),
	Not_Connected     = c.int(os.ENOTCONN),

	// TODO(tetra): Is this error actually possible here?
	Connection_Broken = c.int(os.ENETRESET),
	Not_Socket        = c.int(os.ENOTSOCK),
	Aborted           = c.int(os.ECONNABORTED),

	// TODO(tetra): Determine when this is different from the syscall returning n=0 and maybe normalize them?
	Connection_Closed = c.int(os.ECONNRESET),
	Offline           = c.int(os.ENETDOWN),
	Host_Unreachable  = c.int(os.EHOSTUNREACH),
	Interrupted       = c.int(os.EINTR),

	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout           = c.int(os.EWOULDBLOCK),
}

UDP_Recv_Error :: enum c.int {
	None             = 0,
	Buffer_Too_Small = c.int(os.EMSGSIZE), // The buffer is too small to fit the entire message, and the message was truncated. When this happens, the rest of message is lost.
	Not_Socket       = c.int(os.ENOTSOCK), // The so-called socket is not an open socket.
	Not_Descriptor   = c.int(os.EBADF),    // The so-called socket is, in fact, not even a valid descriptor.
	Bad_Buffer       = c.int(os.EFAULT),   // The buffer did not point to a valid location in memory.
	Interrupted      = c.int(os.EINTR),    // A signal occurred before any data was transmitted. See signal(7).

	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout          = c.int(os.EWOULDBLOCK), 
	Socket_Not_Bound = c.int(os.EINVAL), // The socket must be bound for this operation, but isn't.
}

TCP_Send_Error :: enum c.int {
	None                      = 0,

	Aborted                   = c.int(os.ECONNABORTED), 
	Connection_Closed         = c.int(os.ECONNRESET),
	Not_Connected             = c.int(os.ENOTCONN),
	Shutdown                  = c.int(os.ESHUTDOWN),

	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Offline                   = c.int(os.ENETDOWN),
	Host_Unreachable          = c.int(os.EHOSTUNREACH),
	Interrupted               = c.int(os.EINTR), // A signal occurred before any data was transmitted. See signal(7).

	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	Timeout                   = c.int(os.EWOULDBLOCK), 
	Not_Socket                = c.int(os.ENOTSOCK), // The so-called socket is not an open socket.
}

// TODO
UDP_Send_Error :: enum c.int {
	None                        = 0,
	Message_Too_Long            = c.int(os.EMSGSIZE), // The message is larger than the maximum UDP packet size. No data was sent.

	// TODO: not sure what the exact circumstances for this is yet
	Network_Unreachable         = c.int(os.ENETUNREACH),
	No_Outbound_Ports_Available = c.int(os.EAGAIN),   // There are no more emphemeral outbound ports available to bind the socket to, in order to send.

	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout                     = c.int(os.EWOULDBLOCK), 
	Not_Socket                  = c.int(os.ENOTSOCK), // The so-called socket is not an open socket.
	Not_Descriptor              = c.int(os.EBADF),    // The so-called socket is, in fact, not even a valid descriptor.
	Bad_Buffer                  = c.int(os.EFAULT),   // The buffer did not point to a valid location in memory.
	Interrupted                 = c.int(os.EINTR),    // A signal occurred before any data was transmitted. See signal(7).

	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available   = c.int(os.ENOBUFS),
	No_Memory_Available         = c.int(os.ENOMEM),   // No memory was available to properly manage the send queue.
}

Shutdown_Manner :: enum c.int {
	Receive = c.int(os.SHUT_RD),
	Send    = c.int(os.SHUT_WR),
	Both    = c.int(os.SHUT_RDWR),
}

Shutdown_Error :: enum c.int {
	None           = 0,
	Aborted        = c.int(os.ECONNABORTED),
	Reset          = c.int(os.ECONNRESET),
	Offline        = c.int(os.ENETDOWN),
	Not_Connected  = c.int(os.ENOTCONN),
	Not_Socket     = c.int(os.ENOTSOCK),
	Invalid_Manner = c.int(os.EINVAL),
}

Socket_Option_Error :: enum c.int {
	None                       = 0,
	Offline                    = c.int(os.ENETDOWN),
	Timeout_When_Keepalive_Set = c.int(os.ENETRESET),
	Invalid_Option_For_Socket  = c.int(os.ENOPROTOOPT),
	Reset_When_Keepalive_Set   = c.int(os.ENOTCONN),
	Not_Socket                 = c.int(os.ENOTSOCK),
}

Set_Blocking_Error :: enum c.int {
	None = 0,

	// TODO: Add errors for `set_blocking`
}