package net
// +build linux

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
		flysand:         Move dependency from core:linux.Errno to core:sys/linux
		Feoramund:       FreeBSD platform code
*/

import "core:c"
import "core:sys/linux"

Create_Socket_Error :: enum c.int {
	None                                 = 0,
	Family_Not_Supported_For_This_Socket = c.int(linux.Errno.EAFNOSUPPORT),
	No_Socket_Descriptors_Available      = c.int(linux.Errno.EMFILE),
	No_Buffer_Space_Available            = c.int(linux.Errno.ENOBUFS),
	No_Memory_Available_Available        = c.int(linux.Errno.ENOMEM),
	Protocol_Unsupported_By_System       = c.int(linux.Errno.EPROTONOSUPPORT),
	Wrong_Protocol_For_Socket            = c.int(linux.Errno.EPROTONOSUPPORT),
	Family_And_Socket_Type_Mismatch      = c.int(linux.Errno.EPROTONOSUPPORT),
}

Dial_Error :: enum c.int {
	None                      = 0,
	Port_Required             = -1,

	Address_In_Use            = c.int(linux.Errno.EADDRINUSE),
	In_Progress               = c.int(linux.Errno.EINPROGRESS),
	Cannot_Use_Any_Address    = c.int(linux.Errno.EADDRNOTAVAIL),
	Wrong_Family_For_Socket   = c.int(linux.Errno.EAFNOSUPPORT),
	Refused                   = c.int(linux.Errno.ECONNREFUSED),
	Is_Listening_Socket       = c.int(linux.Errno.EACCES),
	Already_Connected         = c.int(linux.Errno.EISCONN),
	Network_Unreachable       = c.int(linux.Errno.ENETUNREACH), // Device is offline
	Host_Unreachable          = c.int(linux.Errno.EHOSTUNREACH), // Remote host cannot be reached
	No_Buffer_Space_Available = c.int(linux.Errno.ENOBUFS),
	Not_Socket                = c.int(linux.Errno.ENOTSOCK),
	Timeout                   = c.int(linux.Errno.ETIMEDOUT),

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block               = c.int(linux.Errno.EWOULDBLOCK), 
}

Bind_Error :: enum c.int {
	None                    = 0,
	Address_In_Use          = c.int(linux.Errno.EADDRINUSE),    // Another application is currently bound to this endpoint.
	Given_Nonlocal_Address  = c.int(linux.Errno.EADDRNOTAVAIL), // The address is not a local address on this machine.
	Broadcast_Disabled      = c.int(linux.Errno.EACCES),        // To bind a UDP socket to the broadcast address, the appropriate socket option must be set.
	Address_Family_Mismatch = c.int(linux.Errno.EFAULT),        // The address family of the address does not match that of the socket.
	Already_Bound           = c.int(linux.Errno.EINVAL),        // The socket is already bound to an address.
	No_Ports_Available      = c.int(linux.Errno.ENOBUFS),       // There are not enough ephemeral ports available.
}

Listen_Error :: enum c.int {
	None                                    = 0,
	Address_In_Use                          = c.int(linux.Errno.EADDRINUSE),
	Already_Connected                       = c.int(linux.Errno.EISCONN),
	No_Socket_Descriptors_Available         = c.int(linux.Errno.EMFILE),
	No_Buffer_Space_Available               = c.int(linux.Errno.ENOBUFS),
	Nonlocal_Address                        = c.int(linux.Errno.EADDRNOTAVAIL),
	Not_Socket                              = c.int(linux.Errno.ENOTSOCK),
	Listening_Not_Supported_For_This_Socket = c.int(linux.Errno.EOPNOTSUPP),
}

Accept_Error :: enum c.int {
	None                                              = 0,
	Not_Listening                                     = c.int(linux.Errno.EINVAL),
	No_Socket_Descriptors_Available_For_Client_Socket = c.int(linux.Errno.EMFILE),
	No_Buffer_Space_Available                         = c.int(linux.Errno.ENOBUFS),
	Not_Socket                                        = c.int(linux.Errno.ENOTSOCK),
	Not_Connection_Oriented_Socket                    = c.int(linux.Errno.EOPNOTSUPP),

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block                                       = c.int(linux.Errno.EWOULDBLOCK),
}

TCP_Recv_Error :: enum c.int {
	None              = 0,
	Shutdown          = c.int(linux.Errno.ESHUTDOWN),
	Not_Connected     = c.int(linux.Errno.ENOTCONN),
	Connection_Broken = c.int(linux.Errno.ENETRESET),
	Not_Socket        = c.int(linux.Errno.ENOTSOCK),
	Aborted           = c.int(linux.Errno.ECONNABORTED),

	// TODO(tetra): Determine when this is different from the syscall returning n=0 and maybe normalize them?
	Connection_Closed = c.int(linux.Errno.ECONNRESET), 
	Offline           = c.int(linux.Errno.ENETDOWN),
	Host_Unreachable  = c.int(linux.Errno.EHOSTUNREACH),
	Interrupted       = c.int(linux.Errno.EINTR),
	Timeout           = c.int(linux.Errno.EWOULDBLOCK), // NOTE: No, really. Presumably this means something different for nonblocking sockets...
}

UDP_Recv_Error :: enum c.int {
	None             = 0,

	Buffer_Too_Small = c.int(linux.Errno.EMSGSIZE), // The buffer is too small to fit the entire message, and the message was truncated. When this happens, the rest of message is lost.
	Not_Socket       = c.int(linux.Errno.ENOTSOCK), // The so-called socket is not an open socket.
	Not_Descriptor   = c.int(linux.Errno.EBADF),    // The so-called socket is, in fact, not even a valid descriptor.
	Bad_Buffer       = c.int(linux.Errno.EFAULT),   // The buffer did not point to a valid location in memory.
	Interrupted      = c.int(linux.Errno.EINTR),    // A signal occurred before any data was transmitted. See signal(7).

	// The send timeout duration passed before all data was received. See Socket_Option.Receive_Timeout.
	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout          = c.int(linux.Errno.EWOULDBLOCK), 
	Socket_Not_Bound = c.int(linux.Errno.EINVAL), // The socket must be bound for this operation, but isn't.
}

TCP_Send_Error :: enum c.int {
	None                      = 0,
	Aborted                   = c.int(linux.Errno.ECONNABORTED), 
	Connection_Closed         = c.int(linux.Errno.ECONNRESET),
	Not_Connected             = c.int(linux.Errno.ENOTCONN),
	Shutdown                  = c.int(linux.Errno.ESHUTDOWN),

	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available = c.int(linux.Errno.ENOBUFS),
	Offline                   = c.int(linux.Errno.ENETDOWN),
	Host_Unreachable          = c.int(linux.Errno.EHOSTUNREACH),
	Interrupted               = c.int(linux.Errno.EINTR),        // A signal occurred before any data was transmitted. See signal(7).
	Timeout                   = c.int(linux.Errno.EWOULDBLOCK),  // The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	Not_Socket                = c.int(linux.Errno.ENOTSOCK),     // The so-called socket is not an open socket.
}

// TODO
UDP_Send_Error :: enum c.int {
	None                        = 0,
	Message_Too_Long            = c.int(linux.Errno.EMSGSIZE), // The message is larger than the maximum UDP packet size. No data was sent.

	// TODO: not sure what the exact circumstances for this is yet
	Network_Unreachable         = c.int(linux.Errno.ENETUNREACH), 
	No_Outbound_Ports_Available = c.int(linux.Errno.EAGAIN),      // There are no more emphemeral outbound ports available to bind the socket to, in order to send.

	// The send timeout duration passed before all data was sent. See Socket_Option.Send_Timeout.
	// NOTE: No, really. Presumably this means something different for nonblocking sockets...
	Timeout                     = c.int(linux.Errno.EWOULDBLOCK), 
	Not_Socket                  = c.int(linux.Errno.ENOTSOCK), // The so-called socket is not an open socket.
	Not_Descriptor              = c.int(linux.Errno.EBADF),    // The so-called socket is, in fact, not even a valid descriptor.
	Bad_Buffer                  = c.int(linux.Errno.EFAULT),   // The buffer did not point to a valid location in memory.
	Interrupted                 = c.int(linux.Errno.EINTR),    // A signal occurred before any data was transmitted. See signal(7).

	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available   = c.int(linux.Errno.ENOBUFS),
	No_Memory_Available         = c.int(linux.Errno.ENOMEM), // No memory was available to properly manage the send queue.
}

// TODO(flysand): slight regression
Shutdown_Manner :: enum c.int {
	Receive = c.int(linux.Shutdown_How.RD),
	Send    = c.int(linux.Shutdown_How.WR),
	Both    = c.int(linux.Shutdown_How.RDWR),
}

Shutdown_Error :: enum c.int {
	None           = 0,
	Aborted        = c.int(linux.Errno.ECONNABORTED),
	Reset          = c.int(linux.Errno.ECONNRESET),
	Offline        = c.int(linux.Errno.ENETDOWN),
	Not_Connected  = c.int(linux.Errno.ENOTCONN),
	Not_Socket     = c.int(linux.Errno.ENOTSOCK),
	Invalid_Manner = c.int(linux.Errno.EINVAL),
}

Socket_Option_Error :: enum c.int {
	None                       = 0,
	Offline                    = c.int(linux.Errno.ENETDOWN),
	Timeout_When_Keepalive_Set = c.int(linux.Errno.ENETRESET),
	Invalid_Option_For_Socket  = c.int(linux.Errno.ENOPROTOOPT),
	Reset_When_Keepalive_Set   = c.int(linux.Errno.ENOTCONN),
	Not_Socket                 = c.int(linux.Errno.ENOTSOCK),
}

Set_Blocking_Error :: enum c.int {
	None = 0,

	// TODO: add errors occuring on followig calls:
	// flags, _ := linux.Errno.fcntl(sd, linux.Errno.F_GETFL, 0)
	// linux.Errno.fcntl(sd, linux.Errno.F_SETFL, flags | int(linux.Errno.O_NONBLOCK))
}