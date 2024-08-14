package posix

import "core:c"

// sys/un.h = definitions for UNIX domain sockets

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	sockaddr_un :: struct {
		sun_len:    c.uchar,     /* sockaddr len including nil */
		sun_family: sa_family_t, /* [PSX] address family */
		sun_path:   [104]c.char, /* [PSX] socket pathname */
	}

} else {
	#panic("posix is unimplemented for the current target")
}
