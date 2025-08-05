#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

// sys/un.h = definitions for UNIX domain sockets

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	sockaddr_un :: struct {
		sun_len:    c.uchar,     /* sockaddr len including nil */
		sun_family: sa_family_t, /* [PSX] address family */
		sun_path:   [104]c.char, /* [PSX] socket pathname */
	}

} else when ODIN_OS == .Linux {

	sockaddr_un :: struct {
		sun_family: sa_family_t, /* [PSX] address family */
		sun_path:   [108]c.char, /* [PSX] socket pathname */
	}

} else when ODIN_OS == .Haiku {

	sockaddr_un :: struct {
		sun_len:    c.uint8_t,
		sun_family: sa_family_t, /* [PSX] address family */
		sun_path:   [126]c.char, /* [PSX] socket pathname */
	}

}
