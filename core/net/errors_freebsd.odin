//+build freebsd
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
import "core:sys/freebsd"

Create_Socket_Error :: enum c.int {
	None                                 = 0,
	Access_Denied                        = cast(c.int)freebsd.Errno.EACCES,
	Family_Not_Supported_For_This_Socket = cast(c.int)freebsd.Errno.EAFNOSUPPORT,
	Full_Per_Process_Descriptor_Table    = cast(c.int)freebsd.Errno.EMFILE,
	Full_System_File_Table               = cast(c.int)freebsd.Errno.ENFILE,
	No_Buffer_Space_Available            = cast(c.int)freebsd.Errno.ENOBUFS,
	Insufficient_Permission              = cast(c.int)freebsd.Errno.EPERM,
	Protocol_Unsupported_In_Family       = cast(c.int)freebsd.Errno.EPROTONOSUPPORT,
	Socket_Type_Unsupported_By_Protocol  = cast(c.int)freebsd.Errno.EPROTOTYPE,
}

Dial_Error :: enum c.int {
	None                        = 0,
	Port_Required               = -1,
	Not_Descriptor              = cast(c.int)freebsd.Errno.EBADF,
	Invalid_Namelen             = cast(c.int)freebsd.Errno.EINVAL,
	Not_Socket                  = cast(c.int)freebsd.Errno.ENOTSOCK,
	Address_Unavailable         = cast(c.int)freebsd.Errno.EADDRNOTAVAIL,
	Wrong_Family_For_Socket     = cast(c.int)freebsd.Errno.EAFNOSUPPORT,
	Already_Connected           = cast(c.int)freebsd.Errno.EISCONN,
	Timeout                     = cast(c.int)freebsd.Errno.ETIMEDOUT,
	Refused_By_Remote_Host      = cast(c.int)freebsd.Errno.ECONNREFUSED,
	// `Refused` alias for `core:net` tests.
	// The above default name `Refused_By_Remote_Host` is more explicit.
	Refused                     = Refused_By_Remote_Host,
	Reset_By_Remote_Host        = cast(c.int)freebsd.Errno.ECONNRESET,
	Network_Unreachable         = cast(c.int)freebsd.Errno.ENETUNREACH,
	Host_Unreachable            = cast(c.int)freebsd.Errno.EHOSTUNREACH,
	Address_In_Use              = cast(c.int)freebsd.Errno.EADDRINUSE,
	Invalid_Address_Space       = cast(c.int)freebsd.Errno.EFAULT,
	In_Progress                 = cast(c.int)freebsd.Errno.EINPROGRESS,
	Interrupted_By_Signal       = cast(c.int)freebsd.Errno.EINTR,
	Previous_Attempt_Incomplete = cast(c.int)freebsd.Errno.EALREADY,
	Broadcast_Unavailable       = cast(c.int)freebsd.Errno.EACCES,
	Auto_Port_Unavailable       = cast(c.int)freebsd.Errno.EAGAIN,

	// NOTE: There are additional connect() error possibilities, but they are
	// strictly for addresses in the UNIX domain.
}

Bind_Error :: enum c.int {
	None                         = 0,
	Kernel_Resources_Unavailable = cast(c.int)freebsd.Errno.EAGAIN,
	Not_Descriptor               = cast(c.int)freebsd.Errno.EBADF,

	// NOTE: bind() can also return EINVAL if the underlying `addrlen` is an
	// invalid length for the address family. This shouldn't happen for the net
	// package, but it's worth noting.
	Already_Bound                = cast(c.int)freebsd.Errno.EINVAL,
	Not_Socket                   = cast(c.int)freebsd.Errno.ENOTSOCK,
	Given_Nonlocal_Address       = cast(c.int)freebsd.Errno.EADDRNOTAVAIL,
	Address_In_Use               = cast(c.int)freebsd.Errno.EADDRINUSE,
	Address_Family_Mismatch      = cast(c.int)freebsd.Errno.EAFNOSUPPORT,
	Protected_Address            = cast(c.int)freebsd.Errno.EACCES,
	Invalid_Address_Space        = cast(c.int)freebsd.Errno.EFAULT,

	// NOTE: There are additional bind() error possibilities, but they are
	// strictly for addresses in the UNIX domain.
}

Listen_Error :: enum c.int {
	None                                    = 0,
	Not_Descriptor                          = cast(c.int)freebsd.Errno.EBADF,
	Socket_Not_Bound                        = cast(c.int)freebsd.Errno.EDESTADDRREQ,
	Already_Connected                       = cast(c.int)freebsd.Errno.EINVAL,
	Not_Socket                              = cast(c.int)freebsd.Errno.ENOTSOCK,
	Listening_Not_Supported_For_This_Socket = cast(c.int)freebsd.Errno.EOPNOTSUPP,
}

Accept_Error :: enum c.int {
	None                              = 0,
	Not_Descriptor                    = cast(c.int)freebsd.Errno.EBADF,
	Interrupted                       = cast(c.int)freebsd.Errno.EINTR,
	Full_Per_Process_Descriptor_Table = cast(c.int)freebsd.Errno.EMFILE,
	Full_System_File_Table            = cast(c.int)freebsd.Errno.ENFILE,
	Not_Socket                        = cast(c.int)freebsd.Errno.ENOTSOCK,
	Listen_Not_Called_On_Socket_Yet   = cast(c.int)freebsd.Errno.EINVAL,
	Address_Not_Writable              = cast(c.int)freebsd.Errno.EFAULT,

	// NOTE: This is the same as EWOULDBLOCK.
	No_Connections_Available          = cast(c.int)freebsd.Errno.EAGAIN,
	// `Would_Block` alias for `core:net` tests.
	Would_Block                       = cast(c.int)freebsd.Errno.EAGAIN,

	New_Connection_Aborted            = cast(c.int)freebsd.Errno.ECONNABORTED,
}

TCP_Recv_Error :: enum c.int {
	None                                 = 0,
	Not_Descriptor                       = cast(c.int)freebsd.Errno.EBADF,
	Connection_Closed                    = cast(c.int)freebsd.Errno.ECONNRESET,
	Not_Connected                        = cast(c.int)freebsd.Errno.ENOTCONN,
	Not_Socket                           = cast(c.int)freebsd.Errno.ENOTSOCK,

	// NOTE(Feoramund): The next two errors are only relevant for recvmsg(),
	// but I'm including them for completeness's sake.
	Full_Table_And_Pending_Data          = cast(c.int)freebsd.Errno.EMFILE,
	Invalid_Message_Size                 = cast(c.int)freebsd.Errno.EMSGSIZE,

	Timeout                              = cast(c.int)freebsd.Errno.EAGAIN,
	Interrupted_By_Signal                = cast(c.int)freebsd.Errno.EINTR,
	Buffer_Pointer_Outside_Address_Space = cast(c.int)freebsd.Errno.EFAULT,
}

UDP_Recv_Error :: enum c.int {
	None                                 = 0,
	Not_Descriptor                       = cast(c.int)freebsd.Errno.EBADF,
	Connection_Closed                    = cast(c.int)freebsd.Errno.ECONNRESET,
	Not_Connected                        = cast(c.int)freebsd.Errno.ENOTCONN,
	Not_Socket                           = cast(c.int)freebsd.Errno.ENOTSOCK,

	// NOTE(Feoramund): The next two errors are only relevant for recvmsg(),
	// but I'm including them for completeness's sake.
	Full_Table_And_Data_Discarded        = cast(c.int)freebsd.Errno.EMFILE,
	Invalid_Message_Size                 = cast(c.int)freebsd.Errno.EMSGSIZE,

	Timeout                              = cast(c.int)freebsd.Errno.EAGAIN,
	Interrupted_By_Signal                = cast(c.int)freebsd.Errno.EINTR,
	Buffer_Pointer_Outside_Address_Space = cast(c.int)freebsd.Errno.EFAULT,
}

TCP_Send_Error :: enum c.int {
	None                              = 0,
	Connection_Closed                 = cast(c.int)freebsd.Errno.ECONNRESET,
	Not_Descriptor                    = cast(c.int)freebsd.Errno.EBADF,
	Broadcast_Status_Mismatch         = cast(c.int)freebsd.Errno.EACCES,
	Not_Connected                     = cast(c.int)freebsd.Errno.ENOTCONN,
	Not_Socket                        = cast(c.int)freebsd.Errno.ENOTSOCK,
	Argument_In_Invalid_Address_Space = cast(c.int)freebsd.Errno.EFAULT,

	Message_Size_Breaks_Atomicity     = cast(c.int)freebsd.Errno.EMSGSIZE,

	/* The socket is marked non-blocking, or MSG_DONTWAIT is
	   specified, and the requested operation would block. */
	Would_Block                       = cast(c.int)freebsd.Errno.EAGAIN,

	/* NOTE: This error arises for two distinct reasons:

	   1. The system was unable to allocate an internal buffer.
	      The operation may succeed when buffers become available.

	   2. The output queue for a network interface was full.
	      This generally indicates that the interface has stopped
	      sending, but may be caused by transient congestion.
	*/
	No_Buffer_Space_Available         = cast(c.int)freebsd.Errno.ENOBUFS,

	Host_Unreachable                  = cast(c.int)freebsd.Errno.EHOSTUNREACH,
	Already_Connected                 = cast(c.int)freebsd.Errno.EISCONN,
	ICMP_Unreachable                  = cast(c.int)freebsd.Errno.ECONNREFUSED,
	Host_Down                         = cast(c.int)freebsd.Errno.EHOSTDOWN,
	Network_Down                      = cast(c.int)freebsd.Errno.ENETDOWN,
	Jailed_Socket_Tried_To_Escape     = cast(c.int)freebsd.Errno.EADDRNOTAVAIL,
	Cannot_Send_More_Data             = cast(c.int)freebsd.Errno.EPIPE,
}

// NOTE(Feoramund): The same as TCP errors go, as far as I'm aware.
UDP_Send_Error :: distinct TCP_Send_Error

Shutdown_Manner :: enum c.int {
	Receive = cast(c.int)freebsd.Shutdown_Method.RD,
	Send    = cast(c.int)freebsd.Shutdown_Method.WR,
	Both    = cast(c.int)freebsd.Shutdown_Method.RDWR,
}

Shutdown_Error :: enum c.int {
	None           = 0,
	Not_Descriptor = cast(c.int)freebsd.Errno.EBADF,
	Invalid_Manner = cast(c.int)freebsd.Errno.EINVAL,
	Not_Connected  = cast(c.int)freebsd.Errno.ENOTCONN,
	Not_Socket     = cast(c.int)freebsd.Errno.ENOTSOCK,
}

Socket_Option_Error :: enum c.int {
	None                              = 0,
	Value_Out_Of_Range                = -1,
	Not_Descriptor                    = cast(c.int)freebsd.Errno.EBADF,
	Not_Socket                        = cast(c.int)freebsd.Errno.ENOTSOCK,
	Unknown_Option_For_Level          = cast(c.int)freebsd.Errno.ENOPROTOOPT,
	Argument_In_Invalid_Address_Space = cast(c.int)freebsd.Errno.EFAULT,
	// This error can arise for many different reasons.
	Invalid_Value                     = cast(c.int)freebsd.Errno.EINVAL,
	System_Memory_Allocation_Failed   = cast(c.int)freebsd.Errno.ENOMEM,
	Insufficient_System_Resources     = cast(c.int)freebsd.Errno.ENOBUFS,
}

Set_Blocking_Error :: enum c.int {
	None             = 0,
	Not_Descriptor   = cast(c.int)freebsd.Errno.EBADF,
	Wrong_Descriptor = cast(c.int)freebsd.Errno.ENOTTY,
}
