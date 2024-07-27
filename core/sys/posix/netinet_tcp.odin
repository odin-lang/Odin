package posix

// netinet/tcp.h - definitions for the Internet Transmission Control Protocol (TCP)

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	TCP_NODELAY :: 0x01

} else {
	#panic("posix is unimplemented for the current target")
}
