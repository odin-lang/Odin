#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// sys/socket.h - main sockets header

#assert(Protocol.IP == Protocol(0), "socket() assumes this")

foreign libc {
	/*
	Creates a socket.

	Returns: -1 (setting errno) on failure, file descriptor of socket otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/socket.html ]]
	*/
	@(link_name=LSOCKET)
	socket :: proc(domain: AF, type: Sock, protocol: Protocol = .IP) -> FD ---

	/*
	Extracts the first connection on the queue of pending connections.

	Blocks (if not O_NONBLOCK) if there is no pending connection.

	Returns: -1 (setting errno) on failure, file descriptor of accepted socket otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/accept.html ]]
	*/
	accept :: proc(socket: FD, address: ^sockaddr, address_len: ^socklen_t) -> FD ---

	/*
	Assigns a local socket address to the socket.

	Example:
		sfd := posix.socket(.UNIX, .STREAM)
		if sfd == -1 {
			/* Handle error */
		}

		addr: posix.sockaddr_un
		addr.sun_family = .UNIX
		copy(addr.sun_path[:], "/somepath\x00")

		/*
			unlink the socket before binding in case
			of previous runs not cleaning up the socket
		*/
		posix.unlink("/somepath")

		if posix.bind(sfd, (^posix.sockaddr)(&addr), size_of(addr)) != .OK {
			/* Handle error */
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/bind.html ]]
	*/
	bind :: proc(socket: FD, address: ^sockaddr, address_len: socklen_t) -> result ---

	/*
	Attempt to make a connection.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/connect.html ]]
	*/
	connect :: proc(socket: FD, address: ^sockaddr, address_len: socklen_t) -> result ---

	/*
	Get the peer address of the specified socket.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpeername.html ]]
	*/
	getpeername :: proc(socket: FD, address: ^sockaddr, address_len: ^socklen_t) -> result ---

	/*
	Get the socket name.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getsockname.html ]]
	*/
	getsockname :: proc(socket: FD, address: ^sockaddr, address_len: ^socklen_t) -> result ---

	/*
	Retrieves the value for the option specified by option_name.

	level: either `c.int(posix.Protocol(...))` to specify a protocol level or `posix.SOL_SOCKET`
	to specify the socket local level.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getsockopt.html ]]
	*/
	getsockopt :: proc(
		socket:       FD,
		level:        c.int,
		option_name:  Sock_Option,
		option_value: rawptr,
		option_len:   ^socklen_t,
	) -> result ---

	/*
	Sets the specified option.

	level: either `c.int(posix.Protocol(...))` to specify a protocol level or `posix.SOL_SOCKET`
	to specify the socket local level.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setsockopt.html ]]
	*/
	setsockopt :: proc(
		socket:       FD,
		level:        c.int,
		option_name:  Sock_Option,
		option_value: rawptr,
		option_len:   socklen_t,
	) -> result ---

	/*
	Mark the socket as a socket accepting connections.

	backlog provides a hint to limit the number of connections on the listen queue.
	Implementation may silently reduce the backlog, additionally `SOMAXCONN` specifies the maximum
	an implementation has to support.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/listen.html ]]
	*/
	listen :: proc(socket: FD, backlog: c.int) -> result ---

	/*
	Receives a message from a socket.

	Blocks (besides with O_NONBLOCK) if there is nothing to receive.

	Returns: 0 when the peer shutdown with no more messages, -1 (setting errno) on failure, the amount of bytes received on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/recv.html ]]
	*/
	recv :: proc(socket: FD, buffer: rawptr, length: c.size_t, flags: Msg_Flags) -> c.ssize_t ---

	/*
	Receives a message from a socket.

	Equivalent to recv() but retrieves the source address too.

	Returns: 0 when the peer shutdown with no more messages, -1 (setting errno) on failure, the amount of bytes received on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/recvfrom.html ]]
	*/
	recvfrom :: proc(
		socket:      FD,
		buffer:      rawptr,
		length:      c.size_t,
		flags:       Msg_Flags,
		address:     ^sockaddr,
		address_len: ^socklen_t,
	) -> c.ssize_t ---

	/*
	Receives a message from a socket.

	Returns: 0 when the peer shutdown with no more messages, -1 (setting errno) on failure, the amount of bytes received on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/recvmsg.html ]]
	*/
	recvmsg :: proc(socket: FD, message: ^msghdr, flags: Msg_Flags) -> c.ssize_t ---

	/*
	Sends a message on a socket.

	Returns: -1 (setting errno) on failure, the amount of bytes received on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/send.html ]]
	*/
	send :: proc(socket: FD, buffer: rawptr, length: c.size_t, flags: Msg_Flags) -> c.ssize_t ---

	/*
	Sends a message on a socket.

	Returns: -1 (setting errno) on failure, the amount of bytes received on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sendmsg.html ]]
	*/
	sendmsg :: proc(socket: FD, message: ^msghdr, flags: Msg_Flags) -> c.ssize_t ---

	/*
	Sends a message on a socket.

	If the socket is connectionless, the dest_addr is used to send to.

	Returns: -1 (setting errno) on failure, the amount of bytes received on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sendto.html ]]
	*/
	sendto :: proc(
		socket:    FD,
		message:   rawptr,
		length:    c.size_t,
		flags:     Msg_Flags,
		dest_addr: ^sockaddr,
		dest_len:  socklen_t,
	) -> c.ssize_t ---

	/*
	Shuts down a socket end or both.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shutdown.html ]]
	*/
	shutdown :: proc(socket: FD, how: Shut) -> result ---

	/*
	Determine wheter a socket is at the out-of-band mark.

	Returns: -1 (setting errno) on failure, 0 if not at the mark, 1 if it is

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sockatmark.html ]]
	*/
	sockatmark :: proc(socket: FD) -> c.int ---

	/*
	Create a pair of connected sockets.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/socketpair.html ]]
	*/
	socketpair :: proc(domain: AF, type: Sock, protocol: Protocol, socket_vector: ^[2]FD) -> result ---
}

AF_UNSPEC :: 0

AF :: enum c.int {
	// Unspecified.
	UNSPEC = AF_UNSPEC,
	// Internet domain sockets for use with IPv4 addresses.
	INET   = AF_INET,
	// Internet domain sockets for use with IPv6 addresses.
	INET6  = AF_INET6,
	// UNIX domain sockets.
	UNIX   = AF_UNIX,
}

sa_family_t :: enum _sa_family_t {
	// Unspecified.
	UNSPEC = AF_UNSPEC,
	// Internet domain sockets for use with IPv4 addresses.
	INET   = AF_INET,
	// Internet domain sockets for use with IPv6 addresses.
	INET6  = AF_INET6,
	// UNIX domain sockets.
	UNIX   = AF_UNIX,
}

Sock :: enum c.int {
	// Datagram socket.
	DGRAM     = SOCK_DGRAM,
	// Raw Protocol Interface.
	RAW       = SOCK_RAW,
	// Sequenced-packet socket.
	SEQPACKET = SOCK_SEQPACKET,
	// Byte-stream socket.
	STREAM    = SOCK_STREAM,
}

Shut :: enum c.int {
	// Disables further receive operations.
	RD   = SHUT_RD,
	// Disables further send and receive operations.
	RDWR = SHUT_RDWR,
	// Disables further send operations.
	WR   = SHUT_WR,
}

Msg_Flag_Bits :: enum c.int {
	// Control data truncated.
	CTRUNC    = log2(MSG_CTRUNC),
	// Send without using routing table.
	DONTROUTE = log2(MSG_DONTROUTE),
	// Terminates a record (if supported by protocol).
	EOR       = log2(MSG_EOR),
	// Out-of-band data.
	OOB       = log2(MSG_OOB),
	// No SIGPIPE is generated when an attempt to send is made on a stream-oriented socket that is
	// no longer connected.
	NOSIGNAL  = log2(MSG_NOSIGNAL),
	// Leave received data in queue.
	PEEK      = log2(MSG_PEEK),
	// Normal data truncated.
	TRUNC     = log2(MSG_TRUNC),
	// Attempt to fill the read buffer.
	WAITALL   = log2(MSG_WAITALL),
}
Msg_Flags :: bit_set[Msg_Flag_Bits; c.int]

Sock_Option :: enum c.int {
	// Transmission of broadcast message is supported.
	BROADCAST  = SO_BROADCAST,
	// Debugging information is being recorded.
	DEBUG      = SO_DEBUG,
	// Bypass normal routing.
	DONTROUTE  = SO_DONTROUTE,
	// Socket error status.
	ERROR      = SO_ERROR,
	// Connections are kept alive with periodic messages.
	KEEPALIVE  = SO_KEEPALIVE,
	// Socket lingers on close.
	LINGER     = SO_LINGER,
	// Out-of-band data is transmitted in line.
	OOBINLINE  = SO_OOBINLINE,
	// Receive buffer size.
	RCVBUF     = SO_RCVBUF,
	// Receive low water mark.
	RCVLOWAT   = SO_RCVLOWAT,
	// Receive timeout.
	RCVTIMEO   = SO_RCVTIMEO,
	// Reuse of local addresses is supported.
	REUSEADDR  = SO_REUSEADDR,
	// Send buffer size.
	SNDBUF     = SO_SNDBUF,
	// Send low water mark.
	SNDLOWAT   = SO_SNDLOWAT,
	// Send timeout.
	SNDTIMEO   = SO_SNDTIMEO,
	// Socket type.
	TYPE       = SO_TYPE,
}

when ODIN_OS == .NetBSD {
	@(private) LSOCKET :: "__socket30"
} else {
	@(private) LSOCKET :: "socket"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	socklen_t :: distinct c.uint

	when ODIN_OS == .Linux {
		_sa_family_t :: distinct c.ushort

		sockaddr :: struct {
			sa_family: sa_family_t, /* [PSX] address family */
			sa_data:   [14]c.char,  /* [PSX] socket address */
		}
	} else {
		_sa_family_t :: distinct c.uint8_t

		sockaddr :: struct {
			sa_len:    c.uint8_t,   /* total length */
			sa_family: sa_family_t, /* [PSX] address family */
			sa_data:   [14]c.char,  /* [PSX] socket address */
		}
	}


	when ODIN_OS == .OpenBSD {
		@(private)
		_SS_PAD1SIZE :: 6
		@(private)
		_SS_PAD2SIZE :: 240
	} else when ODIN_OS == .Linux {
		@(private)
		_SS_SIZE :: 128
		@(private)
		_SS_PADSIZE :: _SS_SIZE - size_of(c.uint16_t) - size_of(c.uint64_t)
	} else {
		@(private)
		_SS_MAXSIZE   :: 128
		@(private)
		_SS_ALIGNSIZE :: size_of(c.int64_t)
		@(private)
		_SS_PAD1SIZE  :: _SS_ALIGNSIZE - size_of(c.uint8_t) - size_of(sa_family_t)
		@(private)
		_SS_PAD2SIZE  :: _SS_MAXSIZE - size_of(c.uint8_t) - size_of(sa_family_t) - _SS_PAD1SIZE - _SS_ALIGNSIZE
	}

	when ODIN_OS == .Linux {
		sockaddr_storage :: struct {
			ss_family:    sa_family_t,          /* [PSX] address family */
			__ss_padding: [_SS_PADSIZE]c.char,
			__ss_align:   c.uint64_t,           /* force structure storage alignment */
		}

		msghdr :: struct {
			msg_name:       rawptr,    /* [PSX] optional address */
			msg_namelen:    socklen_t, /* [PSX] size of address */
			msg_iov:        [^]iovec,  /* [PSX] scatter/gather array */
			msg_iovlen:     c.size_t,  /* [PSX] members in msg_iov */
			msg_control:    rawptr,    /* [PSX] ancillary data */
			msg_controllen: c.size_t,  /* [PSX] ancillary data buffer length */
			msg_flags:      Msg_Flags, /* [PSX] flags on received message */
		}

		cmsghdr :: struct {
			cmsg_len:   c.size_t, /* [PSX] data byte count, including cmsghdr */
			cmsg_level: c.int,     /* [PSX] originating protocol */
			cmsg_type:  c.int,     /* [PSX] protocol-specific type */
		}
	} else {
		sockaddr_storage :: struct {
			ss_len:     c.uint8_t,            /* address length */
			ss_family:  sa_family_t,          /* [PSX] address family */
			__ss_pad1:  [_SS_PAD1SIZE]c.char,
			__ss_align: c.int64_t,            /* force structure storage alignment */
			__ss_pad2:  [_SS_PAD2SIZE]c.char,
		}

		msghdr :: struct {
			msg_name:       rawptr,    /* [PSX] optional address */
			msg_namelen:    socklen_t, /* [PSX] size of address */
			msg_iov:        [^]iovec,  /* [PSX] scatter/gather array */
			msg_iovlen:     c.int,     /* [PSX] members in msg_iov */
			msg_control:    rawptr,    /* [PSX] ancillary data */
			msg_controllen: socklen_t, /* [PSX] ancillary data buffer length */
			msg_flags:      Msg_Flags, /* [PSX] flags on received message */
		}

		cmsghdr :: struct {
			cmsg_len:   socklen_t, /* [PSX] data byte count, including cmsghdr */
			cmsg_level: c.int,     /* [PSX] originating protocol */
			cmsg_type:  c.int,     /* [PSX] protocol-specific type */
		}
	}

	SCM_RIGHTS :: 0x01

	@(private)
	__ALIGN32 :: #force_inline proc "contextless" (p: uintptr) -> uintptr {
		__ALIGNBYTES32 :: size_of(c.uint32_t) - 1
		return (p + __ALIGNBYTES32) &~ __ALIGNBYTES32
	}

	// Returns a pointer to the data array.
	CMSG_DATA :: #force_inline proc "contextless" (cmsg: ^cmsghdr) -> [^]c.uchar {
		return ([^]c.uchar)(uintptr(cmsg) + __ALIGN32(size_of(cmsghdr)))
	}

	// Returns a pointer to the next cmsghdr or nil.
	CMSG_NXTHDR :: #force_inline proc "contextless" (mhdr: ^msghdr, cmsg: ^cmsghdr) -> ^cmsghdr {
		if cmsg == nil {
			return CMSG_FIRSTHDR(mhdr)
		}

		ptr := uintptr(cmsg) + __ALIGN32(uintptr(cmsg.cmsg_len))
		if ptr + __ALIGN32(size_of(cmsghdr)) > uintptr(mhdr.msg_control) + uintptr(mhdr.msg_controllen) {
			return nil
		}

		return (^cmsghdr)(ptr)
	}

	// Returns a pointer to the first cmsghdr or nil.
	CMSG_FIRSTHDR :: #force_inline proc "contextless" (mhdr: ^msghdr) -> ^cmsghdr {
		if mhdr.msg_controllen >= size_of(cmsghdr) {
			return (^cmsghdr)(mhdr.msg_control)
		}

		return nil
	}

	linger :: struct {
		l_onoff:  c.int, /* [PSX] indicates whether linger option is enabled */
		l_linger: c.int, /* [PSX] linger time in seconds */
	}

	SOCK_DGRAM     :: 2
	SOCK_RAW       :: 3
	SOCK_SEQPACKET :: 5
	SOCK_STREAM    :: 1

	// Options to be accessed at socket level, not protocol level.
	when ODIN_OS == .Linux {
		SOL_SOCKET :: 1

		SO_ACCEPTCONN :: 30
		SO_BROADCAST  :: 6
		SO_DEBUG      :: 1
		SO_DONTROUTE  :: 5
		SO_ERROR      :: 4
		SO_KEEPALIVE  :: 9
		SO_OOBINLINE  :: 10
		SO_RCVBUF     :: 8
		SO_RCVLOWAT   :: 18
		SO_REUSEADDR  :: 2
		SO_SNDBUF     :: 7
		SO_SNDLOWAT   :: 19
		SO_TYPE       :: 3
		SO_LINGER     :: 13

		SO_RCVTIMEO   :: 66
		SO_SNDTIMEO   :: 67
	} else {
		SOL_SOCKET :: 0xffff

		SO_ACCEPTCONN :: 0x0002
		SO_BROADCAST  :: 0x0020
		SO_DEBUG      :: 0x0001
		SO_DONTROUTE  :: 0x0010
		SO_ERROR      :: 0x1007
		SO_KEEPALIVE  :: 0x0008
		SO_OOBINLINE  :: 0x0100
		SO_RCVBUF     :: 0x1002
		SO_RCVLOWAT   :: 0x1004
		SO_REUSEADDR  :: 0x0004
		SO_SNDBUF     :: 0x1001
		SO_SNDLOWAT   :: 0x1003
		SO_TYPE       :: 0x1008

		when ODIN_OS == .Darwin {
			SO_LINGER   :: 0x1080
			SO_RCVTIMEO :: 0x1006
			SO_SNDTIMEO :: 0x1005
		} else when ODIN_OS == .FreeBSD {
			SO_LINGER   :: 0x0080
			SO_RCVTIMEO :: 0x1006
			SO_SNDTIMEO :: 0x1005
		} else when ODIN_OS == .NetBSD {
			SO_LINGER   :: 0x0080
			SO_RCVTIMEO :: 0x100c
			SO_SNDTIMEO :: 0x100b
		} else when ODIN_OS == .OpenBSD {
			SO_LINGER   :: 0x0080
			SO_RCVTIMEO :: 0x1006
			SO_SNDTIMEO :: 0x1005
		}
	}

	// The maximum backlog queue length for listen().
	SOMAXCONN :: 128

	when ODIN_OS == .Linux {
		MSG_CTRUNC    :: 0x008
		MSG_DONTROUTE :: 0x004
		MSG_EOR       :: 0x080
		MSG_OOB       :: 0x001
		MSG_PEEK      :: 0x002
		MSG_TRUNC     :: 0x020
		MSG_WAITALL   :: 0x100
		MSG_NOSIGNAL  :: 0x4000
	} else {
		MSG_CTRUNC    :: 0x20
		MSG_DONTROUTE :: 0x4
		MSG_EOR       :: 0x8
		MSG_OOB       :: 0x1
		MSG_PEEK      :: 0x2
		MSG_TRUNC     :: 0x10
		MSG_WAITALL   :: 0x40

		when ODIN_OS == .Darwin {
			MSG_NOSIGNAL :: 0x80000
		} else when ODIN_OS == .FreeBSD {
			MSG_NOSIGNAL :: 0x00020000
		} else when ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {
			MSG_NOSIGNAL :: 0x0400
		}
	}

	AF_INET   :: 2
	AF_UNIX   :: 1

	when ODIN_OS == .Darwin {
		AF_INET6 :: 30
	} else when ODIN_OS == .FreeBSD {
		AF_INET6 :: 28
	} else when ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {
		AF_INET6 :: 24
	} else when ODIN_OS == .Linux {
		AF_INET6 :: 10
	}

	SHUT_RD   :: 0
	SHUT_RDWR :: 2
	SHUT_WR   :: 1

}
