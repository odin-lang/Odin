#+build linux, darwin, netbsd, openbsd, freebsd
package posix

// netinet/tcp.h - definitions for the Internet Transmission Control Protocol (TCP)

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	TCP_NODELAY :: 0x01

}
