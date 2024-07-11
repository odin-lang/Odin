package net
// +build windows

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

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

import "core:c"
import win "core:sys/windows"

Create_Socket_Error :: enum c.int {
	None                                 = 0,
	Network_Subsystem_Failure            = win.WSAENETDOWN,
	Family_Not_Supported_For_This_Socket = win.WSAEAFNOSUPPORT,
	No_Socket_Descriptors_Available      = win.WSAEMFILE,
	No_Buffer_Space_Available            = win.WSAENOBUFS,
	Protocol_Unsupported_By_System       = win.WSAEPROTONOSUPPORT,
	Wrong_Protocol_For_Socket            = win.WSAEPROTOTYPE,
	Family_And_Socket_Type_Mismatch      = win.WSAESOCKTNOSUPPORT,
}

Dial_Error :: enum c.int {
	None                      = 0,
	Port_Required             = -1,
	Address_In_Use            = win.WSAEADDRINUSE,
	In_Progress               = win.WSAEALREADY,
	Cannot_Use_Any_Address    = win.WSAEADDRNOTAVAIL,
	Wrong_Family_For_Socket   = win.WSAEAFNOSUPPORT,
	Refused                   = win.WSAECONNREFUSED,
	Is_Listening_Socket       = win.WSAEINVAL,
	Already_Connected         = win.WSAEISCONN,
	Network_Unreachable       = win.WSAENETUNREACH,  // Device is offline
	Host_Unreachable          = win.WSAEHOSTUNREACH, // Remote host cannot be reached
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket                = win.WSAENOTSOCK,
	Timeout                   = win.WSAETIMEDOUT,
	Would_Block               = win.WSAEWOULDBLOCK,  // TODO: we may need special handling for this; maybe make a socket a struct with metadata?
}

Bind_Error :: enum c.int {
	None                    = 0,
	Address_In_Use          = win.WSAEADDRINUSE,    // Another application is currently bound to this endpoint.
	Given_Nonlocal_Address  = win.WSAEADDRNOTAVAIL, // The address is not a local address on this machine.
	Broadcast_Disabled      = win.WSAEACCES,        // To bind a UDP socket to the broadcast address, the appropriate socket option must be set.
	Address_Family_Mismatch = win.WSAEFAULT,        // The address family of the address does not match that of the socket.
	Already_Bound           = win.WSAEINVAL,        // The socket is already bound to an address.
	No_Ports_Available      = win.WSAENOBUFS,       // There are not enough ephemeral ports available.
}

Listen_Error :: enum c.int {
	None                                    = 0,
	Address_In_Use                          = win.WSAEADDRINUSE,
	Already_Connected                       = win.WSAEISCONN,
	No_Socket_Descriptors_Available         = win.WSAEMFILE,
	No_Buffer_Space_Available               = win.WSAENOBUFS,
	Nonlocal_Address                        = win.WSAEADDRNOTAVAIL,
	Not_Socket                              = win.WSAENOTSOCK,
	Listening_Not_Supported_For_This_Socket = win.WSAEOPNOTSUPP,
}

Accept_Error :: enum c.int {
	None                                              = 0,
	Not_Listening                                     = win.WSAEINVAL,
	No_Socket_Descriptors_Available_For_Client_Socket = win.WSAEMFILE,
	No_Buffer_Space_Available                         = win.WSAENOBUFS,
	Not_Socket                                        = win.WSAENOTSOCK,
	Not_Connection_Oriented_Socket                    = win.WSAEOPNOTSUPP,

	// TODO: we may need special handling for this; maybe make a socket a struct with metadata?
	Would_Block                                       = win.WSAEWOULDBLOCK, 
}

TCP_Recv_Error :: enum c.int {
	None                      = 0,
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Not_Connected             = win.WSAENOTCONN,
	Bad_Buffer                = win.WSAEFAULT,
	Keepalive_Failure         = win.WSAENETRESET,
	Not_Socket                = win.WSAENOTSOCK,
	Shutdown                  = win.WSAESHUTDOWN,
	Would_Block               = win.WSAEWOULDBLOCK,
	Aborted                   = win.WSAECONNABORTED, 
	Timeout                   = win.WSAETIMEDOUT,

	// TODO(tetra): Determine when this is different from the syscall returning n=0 and maybe normalize them?
	Connection_Closed         = win.WSAECONNRESET, 

	// TODO: verify can actually happen
	Host_Unreachable          = win.WSAEHOSTUNREACH,
}

UDP_Recv_Error :: enum c.int {
	None                      = 0,
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Aborted                   = win.WSAECONNABORTED,
	Buffer_Too_Small          = win.WSAEMSGSIZE,     // The buffer is too small to fit the entire message, and the message was truncated. When this happens, the rest of message is lost.
	Remote_Not_Listening      = win.WSAECONNRESET,   // The machine at the remote endpoint doesn't have the given port open to receiving UDP data.
	Shutdown                  = win.WSAESHUTDOWN,
	Broadcast_Disabled        = win.WSAEACCES,       // A broadcast address was specified, but the .Broadcast socket option isn't set.
	Bad_Buffer                = win.WSAEFAULT,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket                = win.WSAENOTSOCK,     // The socket is not valid socket handle.
	Would_Block               = win.WSAEWOULDBLOCK,
	Host_Unreachable          = win.WSAEHOSTUNREACH, // The remote host cannot be reached from this host at this time.
	Offline                   = win.WSAENETUNREACH,  // The network cannot be reached from this host at this time.
	Timeout                   = win.WSAETIMEDOUT,

	// TODO: can this actually happen? The socket isn't bound; an unknown flag specified; or MSG_OOB specified with SO_OOBINLINE enabled.
	Incorrectly_Configured    = win.WSAEINVAL, 
	TTL_Expired               = win.WSAENETRESET,    // The message took more hops than was allowed (the Time To Live) to reach the remote endpoint.
}

// TODO: consider merging some errors to make handling them easier
// TODO: verify once more what errors to actually expose
TCP_Send_Error :: enum c.int {
	None                      = 0,
	
	Aborted                   = win.WSAECONNABORTED, 
	Not_Connected             = win.WSAENOTCONN,
	Shutdown                  = win.WSAESHUTDOWN,
	Connection_Closed         = win.WSAECONNRESET,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Host_Unreachable          = win.WSAEHOSTUNREACH,
	Would_Block               = win.WSAEWOULDBLOCK,

	// TODO: verify possible, as not mentioned in docs
	Offline                   = win.WSAENETUNREACH,  
	Timeout                   = win.WSAETIMEDOUT,

	// A broadcast address was specified, but the .Broadcast socket option isn't set.
	Broadcast_Disabled        = win.WSAEACCES,
	Bad_Buffer                = win.WSAEFAULT,

	// Connection is broken due to keepalive activity detecting a failure during the operation.
	Keepalive_Failure         = win.WSAENETRESET, // TODO: not functionally different from Reset; merge?
	Not_Socket                = win.WSAENOTSOCK,  // The so-called socket is not an open socket.
}

UDP_Send_Error :: enum c.int {
	None                      = 0,
	Network_Subsystem_Failure = win.WSAENETDOWN,

	Aborted                   = win.WSAECONNABORTED,
	Message_Too_Long          = win.WSAEMSGSIZE, 	 // The message is larger than the maximum UDP packet size.
	Remote_Not_Listening      = win.WSAECONNRESET,   // The machine at the remote endpoint doesn't have the given port open to receiving UDP data.
	Shutdown                  = win.WSAESHUTDOWN,    // A broadcast address was specified, but the .Broadcast socket option isn't set.
	Broadcast_Disabled        = win.WSAEACCES,
	Bad_Buffer                = win.WSAEFAULT,       // Connection is broken due to keepalive activity detecting a failure during the operation.

	// TODO: not functionally different from Reset; merge?
	Keepalive_Failure         = win.WSAENETRESET, 
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket                = win.WSAENOTSOCK,     // The socket is not valid socket handle.

	// This socket is unidirectional and cannot be used to send any data.
	// TODO: verify possible; decide whether to keep if not
	Receive_Only                         = win.WSAEOPNOTSUPP,
	Would_Block                          = win.WSAEWOULDBLOCK,
	Host_Unreachable                     = win.WSAEHOSTUNREACH,  // The remote host cannot be reached from this host at this time.
	Cannot_Use_Any_Address               = win.WSAEADDRNOTAVAIL, // Attempt to send to the Any address.
	Family_Not_Supported_For_This_Socket = win.WSAEAFNOSUPPORT,  // The address is of an incorrect address family for this socket.
	Offline                              = win.WSAENETUNREACH,   // The network cannot be reached from this host at this time.
	Timeout                              = win.WSAETIMEDOUT,
}

Shutdown_Manner :: enum c.int {
	Receive = win.SD_RECEIVE,
	Send    = win.SD_SEND,
	Both    = win.SD_BOTH,
}

Shutdown_Error :: enum c.int {
	None           = 0,
	Aborted        = win.WSAECONNABORTED,
	Reset          = win.WSAECONNRESET,
	Offline        = win.WSAENETDOWN,
	Not_Connected  = win.WSAENOTCONN,
	Not_Socket     = win.WSAENOTSOCK,
	Invalid_Manner = win.WSAEINVAL,
}

Socket_Option :: enum c.int {
	// bool: Whether the address that this socket is bound to can be reused by other sockets.
	//       This allows you to bypass the cooldown period if a program dies while the socket is bound.
	Reuse_Address             = win.SO_REUSEADDR,

	// bool: Whether other programs will be inhibited from binding the same endpoint as this socket.
	Exclusive_Addr_Use        = win.SO_EXCLUSIVEADDRUSE,

	// bool: When true, keepalive packets will be automatically be sent for this connection. TODO: verify this understanding
	Keep_Alive                = win.SO_KEEPALIVE, 

	// bool: When true, client connections will immediately be sent a TCP/IP RST response, rather than being accepted.
	Conditional_Accept        = win.SO_CONDITIONAL_ACCEPT,

	// bool: If true, when the socket is closed, but data is still waiting to be sent, discard that data.
	Dont_Linger               = win.SO_DONTLINGER,

	// bool: When true, 'out-of-band' data sent over the socket will be read by a normal net.recv() call, the same as normal 'in-band' data.
	Out_Of_Bounds_Data_Inline = win.SO_OOBINLINE,   

	// bool: When true, disables send-coalescing, therefore reducing latency.
	TCP_Nodelay               = win.TCP_NODELAY, 

	// win.LINGER: Customizes how long (if at all) the socket will remain open when there
	// is some remaining data waiting to be sent, and net.close() is called.
	Linger                    = win.SO_LINGER, 

	// win.DWORD: The size, in bytes, of the OS-managed receive-buffer for this socket.
	Receive_Buffer_Size       = win.SO_RCVBUF, 

	// win.DWORD: The size, in bytes, of the OS-managed send-buffer for this socket.
	Send_Buffer_Size          = win.SO_SNDBUF,

	// win.DWORD: For blocking sockets, the time in milliseconds to wait for incoming data to be received, before giving up and returning .Timeout.
	//            For non-blocking sockets, ignored.
	//            Use a value of zero to potentially wait forever.
	Receive_Timeout           = win.SO_RCVTIMEO,

	// win.DWORD: For blocking sockets, the time in milliseconds to wait for outgoing data to be sent, before giving up and returning .Timeout.
	//            For non-blocking sockets, ignored.
	//            Use a value of zero to potentially wait forever.
	Send_Timeout              = win.SO_SNDTIMEO,

	// bool: Allow sending to, receiving from, and binding to, a broadcast address.
	Broadcast                 = win.SO_BROADCAST, 
}

Socket_Option_Error :: enum c.int {
	None                               = 0,
	Linger_Only_Supports_Whole_Seconds = 1,

	// The given value is too big or small to be given to the OS.
	Value_Out_Of_Range, 

	Network_Subsystem_Failure          = win.WSAENETDOWN,
	Timeout_When_Keepalive_Set         = win.WSAENETRESET,
	Invalid_Option_For_Socket          = win.WSAENOPROTOOPT,
	Reset_When_Keepalive_Set           = win.WSAENOTCONN,
	Not_Socket                         = win.WSAENOTSOCK,
}

Set_Blocking_Error :: enum c.int {
	None = 0,

	Network_Subsystem_Failure          = win.WSAENETDOWN,
	Blocking_Call_In_Progress          = win.WSAEINPROGRESS,
	Not_Socket                         = win.WSAENOTSOCK,

	// TODO: are those errors possible?
	Network_Subsystem_Not_Initialized  = win.WSAENOTINITIALISED,
	Invalid_Argument_Pointer           = win.WSAEFAULT,
}