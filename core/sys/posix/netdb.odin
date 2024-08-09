package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// netdb.h - definitions for network database operations

foreign lib {
	/*
	Translate node/serv name and return a set of socket addresses and associated information to be
	used in creating a socket with which to address the specified service.

	Example:
		// The following (incomplete) program demonstrates the use of getaddrinfo() to obtain the
		// socket address structure(s) for the service named in the program's command-line argument.
		// The program then loops through each of the address structures attempting to create and bind
		// a socket to the address, until it performs a successful bind().

		args := runtime.args__
		if len(args) != 2 {
			fmt.eprintfln("Usage: %s port", args[0])
			posix.exit(1)
		}

		hints: posix.addrinfo
		hints.ai_socktype = .DGRAM
		hints.ai_flags    = { .PASSIVE }

		result: ^posix.addrinfo
		s := posix.getaddrinfo(nil, args[1], &hints, &result)
		if s != .NONE {
			fmt.eprintfln("getaddrinfo: %s", posix.gai_strerror(s))
			posix.exit(1)
		}
		defer posix.freeaddrinfo(result)

		// Try each address until a successful bind().
		rp: ^posix.addrinfo
		for rp = result; rp != nil; rp = rp.ai_next {
			sfd := posix.socket(rp.ai_family, rp.ai_socktype, rp.ai_protocol)
			if sfd == -1 {
				continue
			}

			if posix.bind(sfd, rp.ai_addr, rp.ai_addrlen) == 0 {
				// Success.
				break
			}

			posix.close(sfd)
		}

		if rp == nil {
			fmt.eprintln("Could not bind")
			posix.exit(1)
		}

		// Use the socket...

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getaddrinfo.html ]]
	*/
	getaddrinfo :: proc(
		nodename: cstring,
		servname: cstring,
		hints:    ^addrinfo,
		res:      ^^addrinfo,
	) -> Info_Errno ---

	/*
	Frees the given address info linked list.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getaddrinfo.html ]]
	*/
	freeaddrinfo :: proc(ai: ^addrinfo) ---

	/*
	Translate a socket address to a node name and service location.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getnameinfo.html ]]
	*/
	getnameinfo :: proc(
		sa:      ^sockaddr, salen:      socklen_t,
		node:    [^]byte,   nodelen:    socklen_t,
		service: [^]byte,   servicelen: socklen_t,
		flags: Nameinfo_Flags,
	) -> Info_Errno ---

	/*
	Get a textual description for the address info errors.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/gai_strerror.html ]]
	*/
	gai_strerror :: proc(ecode: Info_Errno) -> cstring ---

	/*
	Opens a connection to the database and set the next entry to the first entry in the database.

	This reads /etc/hosts on most systems.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sethostent.html ]]
	*/
	sethostent :: proc(stayopen: b32) ---

	/*
	Reads the next entry in the database, opening and closing a connection as necessary.

	This reads /etc/hosts on most systems.

	Example:
		posix.sethostent(true)
		defer posix.endhostent()
		for ent := posix.gethostent(); ent != nil; ent = posix.gethostent() {
			fmt.println(ent)
			fmt.println(ent.h_addr_list[0][:ent.h_length])
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sethostent.html ]]
	*/
	gethostent :: proc() -> ^hostent ---

	/*
	Closes the connection to the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sethostent.html ]]
	*/
	endhostent :: proc() ---

	/*
	Opens and rewinds the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setnetent.html ]]
	*/
	setnetent :: proc(stayopen: b32) ---

	/*
	Reads the next entry of the database.

	Example:
		posix.setnetent(true)
		defer posix.endnetent()
		for ent := posix.getnetent(); ent != nil; ent = posix.getnetent() {
			fmt.println(ent)
			fmt.println(transmute([4]byte)ent.n_net)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setnetent.html ]]
	*/
	getnetent :: proc() -> ^netent ---

	/*
	Search the database from the beginning, and find the first entry that matches.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setnetent.html ]]
	*/
	getnetbyaddr :: proc(net: c.uint32_t, type: AF) -> ^netent ---

	/*
	Search the database from the beginning, and find the first entry that matches.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setnetent.html ]]
	*/
	getnetbyname :: proc(name: cstring) -> ^netent ---

	/*
	Closes the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setnetent.html ]]
	*/
	endnetent :: proc() ---

	/*
	Opens and rewinds the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setprotoent.html ]]
	*/
	setprotoent :: proc(stayopen: b32) ---

	/*
	Reads the next entry of the database.

	Example:
		posix.setprotoent(true)
		defer posix.endprotoent()
		for ent := posix.getprotoent(); ent != nil; ent = posix.getprotoent() {
			fmt.println(ent)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setprotoent.html ]]
	*/
	getprotoent :: proc() -> ^protoent ---

	/*
	Search the database from the beginning, and find the first entry that matches.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setprotoent.html ]]
	*/
	getprotobyname :: proc(name: cstring) -> ^protoent ---

	/*
	Search the database from the beginning, and find the first entry that matches.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setprotoent.html ]]
	*/
	getprotobynumber :: proc(proto: c.int) -> ^protoent ---

	/*
	Closes the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setprotoent.html ]]
	*/
	endprotoent :: proc() ---

	/*
	Opens and rewinds the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setservent.html ]]
	*/
	setservent :: proc(stayopen: b32) ---

	/*
	Reads the next entry of the database.

	Example:
		posix.setservent(true)
		defer posix.endservent()
		for ent := posix.getservent(); ent != nil; ent = posix.getservent() {
			fmt.println(ent)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setservent.html ]]
	*/
	getservent :: proc() -> ^servent ---

	/*
	Search the database from the beginning, and find the first entry that matches.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setservent.html ]]
	*/
	getservbyname :: proc(name: cstring, proto: cstring) -> ^servent ---

	/*
	Search the database from the beginning, and find the first entry that matches.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setservent.html ]]
	*/
	getservbyport :: proc(port: c.int, proto: cstring) -> ^servent ---

	/*
	Closes the database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setservent.html ]]
	*/
	endservent :: proc() ---
}

Addrinfo_Flag_Bits :: enum c.int {
	// Socket address is intended for bind().
	PASSIVE     = log2(AI_PASSIVE),
	// Request for canonical name.
	CANONNAME   = log2(AI_CANONNAME),
	// Return numeric host address as name.
	NUMERICHOST = log2(AI_NUMERICHOST),
	// Inhibit service name resolution.
	NUMERICSERV = log2(AI_NUMERICSERV),
	// If no IPv6 addresses are found, query for IPv4 addresses and return them to the
	// caller as IPv4-mapped IPv6 addresses.
	V4MAPPED    = log2(AI_V4MAPPED),
	// Query for both IPv4 and IPv6 addresses.
	ALL         = log2(AI_ALL),
	// Query for IPv4 addresses only when an IPv4 address is configured; query for IPv6 addresses
	// only when an IPv6 address is configured.
	ADDRCONFIG  = log2(AI_ADDRCONFIG),
}
Addrinfo_Flags :: bit_set[Addrinfo_Flag_Bits; c.int]

Nameinfo_Flag_Bits :: enum c.int {
	// Only the nodename portion of the FQDN is returned for local hosts.
	NOFQDN       = log2(NI_NOFQDN),
	// The numeric form of the node's address is returned instead of its name.
	NUMERICHOST  = log2(NI_NUMERICHOST),
	// Return an error if the node's name cannot be located in the database.
	NAMEREQD     = log2(NI_NAMEREQD),
	// The numeric form of the service address is returned instead of its name.
	NUMERICSERV  = log2(NI_NUMERICSERV),
	// For IPv6 addresses, the numeric form of the scope identifier is returned instead of its name.
	NUMERICSCOPE = log2(NI_NUMERICSCOPE),
	// Indicates that the service is a datagram service (SOCK_DGRAM).
	DGRAM        = log2(NI_DGRAM),
}
Nameinfo_Flags :: bit_set[Nameinfo_Flag_Bits; c.int]

Info_Errno :: enum c.int {
	NONE     = 0,
	// The name could not be resolved at this time. Future attempts may succeed.
	AGAIN    = EAI_AGAIN,
	// The flags had an invalid value.
	BADFLAGS = EAI_BADFLAGS,
	// A non-recoverable error ocurred.
	FAIL     = EAI_FAIL,
	// The address family was not recognized or the address length was invald for the specified family.
	FAMILY   = EAI_FAMILY,
	// There was a memory allocation failure.
	MEMORY   = EAI_MEMORY,
	// The name does not resolve for the supplied parameters.
	NONAME   = EAI_NONAME,
	// The service passed was not recognized for the specified socket.
	SERVICE  = EAI_SERVICE,
	// The intended socket type was not recognized.
	SOCKTYPE = EAI_SOCKTYPE,
	// A system error occurred. The error code can be found in errno.
	SYSTEM   = EAI_SYSTEM,
	// An argument buffer overflowed.
	OVERFLOW = EAI_OVERFLOW,
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	hostent :: struct {
		h_name:      cstring,                /* [PSX] official name of host */
		h_aliases:   [^]cstring `fmt:"v,0"`, /* [PSX] alias list */
		h_addrtype:  AF,                     /* [PSX] host address type */
		h_length:    c.int,                  /* [PSX] length of address */
		h_addr_list: [^][^]byte `fmt:"v,0"`, /* [PSX] list of addresses from name server */
	}

	netent :: struct {
		n_name:     cstring,                /* [PSX] official name of net */
		n_aliases:  [^]cstring `fmt:"v,0"`, /* [PSX] alias list */
		n_addrtype: AF,                     /* [PSX] net address type */
		n_net:      c.uint32_t,             /* [PSX] network # */
	}

	protoent :: struct {
		p_name:    cstring,                /* [PSX] official protocol name */
		p_aliases: [^]cstring `fmt:"v,0"`, /* [PSX] alias list */
		p_proto:   c.int,                  /* [PSX] protocol # */
	}

	servent :: struct {
		s_name:    cstring,                /* [PSX] official service name */
		s_aliases: [^]cstring `fmt:"v,0"`, /* [PSX] alias list */
		s_port:    c.int,                  /* [PSX] port # */
		s_proto:   cstring,                /* [PSX] protocol # */
	}

	// The highest reserved port number.
	IPPORT_RESERVED :: 1024

	addrinfo :: struct {
		ai_flags:     Addrinfo_Flags, /* [PSX] input flags */
		ai_family:    AF,             /* [PSX] address family of socket */
		ai_socktype:  Sock,           /* [PSX] socket type */
		ai_protocol:  Protocol,       /* [PSX] protocol of socket */
		ai_addrlen:   socklen_t,      /* [PSX] length of socket address */
		ai_canonname: cstring,        /* [PSX] canonical name of service location */
		ai_addr:      ^sockaddr,      /* [PSX] binary address */
		ai_next:      ^addrinfo,      /* [PSX] pointer to next in list */
	}

	when ODIN_OS == .Darwin {

		AI_PASSIVE     :: 0x00000001
		AI_CANONNAME   :: 0x00000002
		AI_NUMERICHOST :: 0x00000004
		AI_NUMERICSERV :: 0x00001000
		AI_V4MAPPED    :: 0x00000800
		AI_ALL         :: 0x00000100
		AI_ADDRCONFIG  :: 0x00000400 

		NI_NOFQDN       :: 0x00000001
		NI_NUMERICHOST  :: 0x00000002
		NI_NAMEREQD     :: 0x00000004
		NI_NUMERICSERV  :: 0x00000008
		NI_NUMERICSCOPE :: 0x00000100
		NI_DGRAM        :: 0x00000010

	} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD {

		AI_PASSIVE     :: 0x00000001
		AI_CANONNAME   :: 0x00000002
		AI_NUMERICHOST :: 0x00000004
		AI_NUMERICSERV :: 0x00000008
		AI_V4MAPPED    :: 0x00000800 // NOTE: not implemented on netbsd
		AI_ALL         :: 0x00000100 // NOTE: not implemented on netbsd
		AI_ADDRCONFIG  :: 0x00000400 

		NI_NOFQDN       :: 0x00000001
		NI_NUMERICHOST  :: 0x00000002
		NI_NAMEREQD     :: 0x00000004
		NI_NUMERICSERV  :: 0x00000008
		NI_NUMERICSCOPE :: 0x00000010
		NI_DGRAM        :: 0x00000020

	} else when ODIN_OS == .OpenBSD {

		AI_PASSIVE     :: 1
		AI_CANONNAME   :: 2
		AI_NUMERICHOST :: 4
		AI_NUMERICSERV :: 16
		AI_V4MAPPED    :: 0x00000800 // NOTE: not implemented
		AI_ALL         :: 0x00000100 // NOTE: not implemented
		AI_ADDRCONFIG  :: 64

		NI_NOFQDN       :: 4
		NI_NUMERICHOST  :: 1
		NI_NAMEREQD     :: 8
		NI_NUMERICSERV  :: 2
		NI_NUMERICSCOPE :: 32
		NI_DGRAM        :: 16
	}

	when ODIN_OS == .OpenBSD {
		EAI_AGAIN    :: -3
		EAI_BADFLAGS :: -1
		EAI_FAIL     :: -4
		EAI_FAMILY   :: -6
		EAI_MEMORY   :: -10
		EAI_NONAME   :: -2
		EAI_SERVICE  :: -8
		EAI_SOCKTYPE :: -7
		EAI_SYSTEM   :: -11
		EAI_OVERFLOW :: -14
	} else {
		EAI_AGAIN    :: 2
		EAI_BADFLAGS :: 3
		EAI_FAIL     :: 4
		EAI_FAMILY   :: 5
		EAI_MEMORY   :: 6
		EAI_NONAME   :: 8
		EAI_SERVICE  :: 9
		EAI_SOCKTYPE :: 10
		EAI_SYSTEM   :: 11
		EAI_OVERFLOW :: 14
	}

}else {
	#panic("posix is unimplemented for the current target")
}
