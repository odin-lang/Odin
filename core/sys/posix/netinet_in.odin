package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// netinet/in.h - Internet address family

foreign lib {
	in6addr_any:      in6_addr
	in6addr_loopback: in6_addr
}

in_port_t :: u16be
in_addr_t :: u32be

INET_ADDRSTRLEN  :: 16
INET6_ADDRSTRLEN :: 46

Protocol :: enum c.int {
	IP   = IPPROTO_IP,
	ICMP = IPPROTO_ICMP,
	IPV6 = IPPROTO_IPV6,
	RAW  = IPPROTO_RAW,
	TCP  = IPPROTO_TCP,
	UDP  = IPPROTO_UDP,
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	in_addr :: struct {
		s_addr: in_addr_t, /* [PSX] big endian address */
	}

	in6_addr :: struct {
		using _: struct #raw_union {
			s6_addr:     [16]c.uint8_t, /* [PSX] big endian address */
			__u6_addr16: [8]c.uint16_t,
			__u6_addr32: [4]c.uint32_t,
		},
	}

	when ODIN_OS == .Linux {

		sockaddr_in :: struct {
			sin_family: sa_family_t, /* [PSX] AF_INET (but a smaller size) */
			sin_port:   in_port_t,   /* [PSX] port number */
			sin_addr:   in_addr,     /* [PSX] IP address */
			sin_zero:   [8]c.char,
		}

		sockaddr_in6 :: struct {
			sin6_family:   sa_family_t, /* [PSX] AF_INET6 (but a smaller size) */
			sin6_port:     in_port_t,   /* [PSX] port number */
			sin6_flowinfo: u32be,       /* [PSX] IPv6 traffic class and flow information */
			sin6_addr:     in6_addr,    /* [PSX] IPv6 address */
			sin6_scope_id: c.uint32_t,  /* [PSX] set of interfaces for a scope */
		}

		IPV6_MULTICAST_IF   :: 17
		IPV6_UNICAST_HOPS   :: 16
		IPV6_MULTICAST_HOPS :: 18
		IPV6_MULTICAST_LOOP :: 19
		IPV6_JOIN_GROUP     :: 20
		IPV6_LEAVE_GROUP    :: 21
		IPV6_V6ONLY         :: 26

	} else {

		sockaddr_in :: struct {
			sin_len:    c.uint8_t,
			sin_family: sa_family_t, /* [PSX] AF_INET (but a smaller size) */
			sin_port:   in_port_t,   /* [PSX] port number */
			sin_addr:   in_addr,     /* [PSX] IP address */
			sin_zero:   [8]c.char,
		}

		sockaddr_in6 :: struct {
			sin6_len:      c.uint8_t,
			sin6_family:   sa_family_t, /* [PSX] AF_INET6 (but a smaller size) */
			sin6_port:     in_port_t,   /* [PSX] port number */
			sin6_flowinfo: c.uint32_t,  /* [PSX] IPv6 traffic class and flow information */
			sin6_addr:     in6_addr,    /* [PSX] IPv6 address */
			sin6_scope_id: c.uint32_t,  /* [PSX] set of interfaces for a scope */
		}

		ipv6_mreq :: struct {
			ipv6mr_multiaddr: in6_addr, /* [PSX] IPv6 multicast address */
			ipv6mr_interface: c.uint,   /* [PSX] interface index */
		}

		IPV6_JOIN_GROUP     :: 12
		IPV6_LEAVE_GROUP    :: 13
		IPV6_MULTICAST_HOPS :: 10
		IPV6_MULTICAST_IF   :: 9
		IPV6_MULTICAST_LOOP :: 11
		IPV6_UNICAST_HOPS   :: 4
		IPV6_V6ONLY         :: 27

	}

	IPPROTO_IP   :: 0
	IPPROTO_ICMP :: 1
	IPPROTO_IPV6 :: 41
	IPPROTO_RAW  :: 255
	IPPROTO_TCP  :: 6
	IPPROTO_UDP  :: 17

	INADDR_ANY       :: 0x00000000
	INADDR_BROADCAST :: 0xFFFFFFFF

	IN6_IS_ADDR_UNSPECIFIED :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return a.s6_addr == 0
	}

	IN6_IS_ADDR_LOOPBACK :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		a := a
		return (
			(^c.uint32_t)(&a.s6_addr[0])^  == 0 &&
			(^c.uint32_t)(&a.s6_addr[4])^  == 0 &&
			(^c.uint32_t)(&a.s6_addr[8])^  == 0 &&
			(^u32be)(&a.s6_addr[12])^ == 1 \
		)
	}

	IN6_IS_ADDR_MULTICAST :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return a.s6_addr[0] == 0xff
	}

	IN6_IS_ADDR_LINKLOCAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return a.s6_addr[0] == 0xfe && a.s6_addr[1] & 0xc0 == 0x80
	}

	IN6_IS_ADDR_SITELOCAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return a.s6_addr[0] == 0xfe && a.s6_addr[1] & 0xc0 == 0xc0
	}

	IN6_IS_ADDR_V4MAPPED :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		a := a
		return (
			(^c.uint32_t)(&a.s6_addr[0])^ == 0 &&
			(^c.uint32_t)(&a.s6_addr[4])^ == 0 &&
			(^u32be)(&a.s6_addr[8])^ == 0x0000ffff \
		)
	}

	IN6_IS_ADDR_V4COMPAT :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		a := a
		return (
			(^c.uint32_t)(&a.s6_addr[0])^  == 0 &&
			(^c.uint32_t)(&a.s6_addr[4])^  == 0 &&
			(^c.uint32_t)(&a.s6_addr[8])^  == 0 &&
			(^c.uint32_t)(&a.s6_addr[12])^ != 0 &&
			(^u32be)(&a.s6_addr[12])^ != 1 \
		)
	}

	@(private)
	__IPV6_ADDR_SCOPE_NODELOCAL :: 0x01
	@(private)
	__IPV6_ADDR_SCOPE_LINKLOCAL :: 0x02
	@(private)
	__IPV6_ADDR_SCOPE_SITELOCAL :: 0x05
	@(private)
	__IPV6_ADDR_SCOPE_ORGLOCAL  :: 0x08
	@(private)
	__IPV6_ADDR_SCOPE_GLOBAL    :: 0x0e

	@(private)
	IPV6_ADDR_MC_FLAGS :: #force_inline proc "contextless" (a: in6_addr) -> c.uint8_t {
		return a.s6_addr[1] & 0xf0
	}

	@(private)
	IPV6_ADDR_MC_FLAGS_TRANSIENT     :: 0x10
	@(private)
	IPV6_ADDR_MC_FLAGS_PREFIX        :: 0x20
	@(private)
	IPV6_ADDR_MC_FLAGS_UNICAST_BASED :: IPV6_ADDR_MC_FLAGS_TRANSIENT | IPV6_ADDR_MC_FLAGS_PREFIX

	@(private)
	__IPV6_ADDR_MC_SCOPE :: #force_inline proc "contextless" (a: in6_addr) -> c.uint8_t {
		return a.s6_addr[1] & 0x0f
	}

	IN6_IS_ADDR_MC_NODELOCAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return (
			IN6_IS_ADDR_MULTICAST(a) &&
			(__IPV6_ADDR_MC_SCOPE(a) == __IPV6_ADDR_SCOPE_NODELOCAL) \
		)
	}

	IN6_IS_ADDR_MC_LINKLOCAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return (
			IN6_IS_ADDR_MULTICAST(a) &&
			(IPV6_ADDR_MC_FLAGS(a) != IPV6_ADDR_MC_FLAGS_UNICAST_BASED) &&
			(__IPV6_ADDR_MC_SCOPE(a) == __IPV6_ADDR_SCOPE_LINKLOCAL) \
		)
	}

	IN6_IS_ADDR_MC_SITELOCAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return (
			IN6_IS_ADDR_MULTICAST(a) &&
			(__IPV6_ADDR_MC_SCOPE(a) == __IPV6_ADDR_SCOPE_SITELOCAL) \
		)
	}

	IN6_IS_ADDR_MC_ORGLOCAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return (
			IN6_IS_ADDR_MULTICAST(a) &&
			(__IPV6_ADDR_MC_SCOPE(a) == __IPV6_ADDR_SCOPE_ORGLOCAL) \
		)
	}

	IN6_IS_ADDR_MC_GLOBAL :: #force_inline proc "contextless" (a: in6_addr) -> b32 {
		return (
			IN6_IS_ADDR_MULTICAST(a) &&
			(__IPV6_ADDR_MC_SCOPE(a) == __IPV6_ADDR_SCOPE_GLOBAL) \
		)
	}

} else {
	#panic("posix is unimplemented for the current target")
}
