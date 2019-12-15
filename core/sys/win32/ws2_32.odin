package win32

foreign import "system:Ws2_32.lib"

@(default_calling_convention="std")
foreign Ws2_32 {
	WSAStartup :: proc(version_requested: u32, data: ^WSADATA) -> i32 ---;
	WSAGetLastError :: proc() -> i32 ---;
	
	@(link_name="WSACleanup") wsa_cleanup :: proc() -> i32 ---;
}

@(default_calling_convention="std")
foreign Ws2_32 {
	@(link_name="socket")       socket :: proc(addr_family: i32, socket_type: i32, protocol: i32) -> SOCKET ---;
	@(link_name="closesocket")  closesocket :: proc(socket: SOCKET) -> i32 ---;
	@(link_name="connect")      connect :: proc(socket: SOCKET, name: ^Socket_Address, name_length: i32) -> i32 ---;
	@(link_name="gethostbyname") gethostbyname :: proc(name: cstring) -> ^HOSTENT ---;
	@(link_name="getaddrinfo")  getaddrinfo :: proc(name: cstring, port: cstring, hints: ^addrinfo, addr_list: ^^addrinfo) -> i32 ---;
	@(link_name="bind")         bind :: proc(socket: SOCKET, addr: ^Socket_Address, size_of_addr: i32) -> i32 ---;
	@(link_name="listen")       listen :: proc(socket: SOCKET, pending_conn_queue_length: i32) -> i32 ---;
	
	// NOTE(tetra): addr_length is max size of addr on call, and actual size on return (which tells you if it's Ipv4 or Ipv6).
	@(link_name="accept")       accept :: proc(socket: SOCKET, addr: ^Socket_Address, addr_length: ^i32) -> SOCKET ---;

	@(link_name="send")         send :: proc(socket: SOCKET, buffer: ^u8, buffer_length: i32, flags: i32) -> i32 ---;
	@(link_name="sendto")       sendto :: proc(socket: SOCKET, buffer: ^u8, buffer_length: i32, flags: i32, addr: ^Socket_Address, addr_length: i32) -> i32 ---;
	@(link_name="recv")         recv :: proc(socket: SOCKET, buffer: ^u8, buffer_length: i32, flags: i32) -> i32 ---;
	@(link_name="recvfrom")     recvfrom :: proc(socket: SOCKET, buffer: ^u8, buffer_length: i32, flags: i32, addr: ^Socket_Address, addr_length: ^i32) -> i32 ---;
	@(link_name="shutdown")     shutdown :: proc(socket: SOCKET, operations_to_shutdown: i32) -> i32 ---;
	@(link_name="setsockopt")   setsockopt :: proc(socket: SOCKET, level: i32, name: i32, value: rawptr, length: i32) -> i32 ---;
	@(link_name="getsockopt")   getsockopt :: proc(socket: SOCKET, level: i32, name: i32, value: rawptr, length: ^i32) -> i32 ---;
	@(link_name="freeaddrinfo") freeaddrinfo :: proc(info: ^addrinfo) ---;

	WSASocket :: proc(family: i32, type: i32, protocol: i32, proto_info: rawptr, group: i32, flags: u32) ---;

	// returns the number of sockets in the array that had something happen, or -1 for error.
	WSAPoll :: proc(skts: ^pollfd, num_skts: u64, timeout: i32) -> i32 ---;

	WSAGetOverlappedResult :: proc(skt: SOCKET, overlapped: ^WSAOVERLAPPED, result: ^u32, wait: b32, flags: ^u32) -> b32 ---;
	WSACreateEvent :: proc() -> WSAEVENT ---;
	WSACloseEvent :: proc(evt: WSAEVENT) -> b32 ---;
}

AF_UNSPEC :: 0;
AF_INET   :: 2;  // IPv4
AF_INET6  :: 23; // IPv6
AF_IRDA   :: 26; // Infrared
AF_BTH    :: 32; // Bluetooth

SOCK_STREAM    :: 1; // TCP
SOCK_DGRAM     :: 2; // UDP
SOCK_RAW       :: 3; // Requires options IP_HDRINCL for v4, IPV6_HDRINCL for v6, on the socket
SOCK_RDM       :: 4; // Requires "Reliable Multicast Protocol" to be installed - see WSAEnumProtocols
SOCK_SEQPACKET :: 5; // Provides psuedo-stream packet based on DGRAMs.

IPPROTO_ICMP    :: 1;   // (AF_UNSPEC, AF_INET, AF_INET6) + SOCK_RAW | not specified
IPPROTO_IGMP    :: 2;   // (AF_UNSPEC, AF_INET, AF_INET6) + SOCK_RAW | not specified
BTHPROTO_RFCOMM :: 3;   // Bluetooth: AF_BTH + SOCK_STREAM
IPPROTO_TCP     :: 6;   // (AF_INET, AF_INET6) + SOCK_STREAM
IPPROTO_UDP     :: 17;  // (AF_INET, AF_INET6) + SOCK_DGRAM
IPPROTO_ICMPV6  :: 58;  // (AF_UNSPEC, AF_INET, AF_INET6) + SOCK_RAW
IPPROTO_RM      :: 113; // AF_INET + SOCK_RDM [requires "Reliable Multicast Protocol" to be installed - see WSAEnumProtocols]

WSAEINTR               :: 10004; // Call interrupted. CancelBlockingCall was called. (This is different on Linux.)
WSAEACCES              :: 10013; // If you try to bind a Udp socket to the broadcast address without the socket option set.
WSAEFAULT              :: 10014; // A pointer that was passed to a WSA function is invalid, such as a buffer size is smaller than you said it was
WSAEINVAL              :: 10022; // Invalid argument supplied
WSAEMFILE              :: 10024; // SOCKET handles exhausted
WSAEWOULDBLOCK         :: 10035; // No data is ready yet
WSAENOTSOCK            :: 10038; // Not a socket.
WSAEINPROGRESS         :: 10036; // WS1.1 call is in progress or callback function is still being processed
WSAEALREADY            :: 10037; // Already connecting in parallel.
WSAEMSGSIZE            :: 10040; // Wrong protocol for the provided socket
WSAEPROTOTYPE          :: 10041; // Wrong protocol for the provided socket
WSAENOPROTOOPT         :: 10042;
WSAEPROTONOSUPPORT     :: 10043; // Protocol not supported
WSAESOCKTNOSUPPORT     :: 10044; // SOCKET type not supported in the given address family
WSAEAFNOSUPPORT        :: 10047; // Address family not supported
WSAEOPNOTSUPP          :: 10045; // Attempt to accept on non-stream socket, etc.
WSAEADDRINUSE          :: 10048; // Address family not supported
WSAEADDRNOTAVAIL       :: 10049; // Not a valid local IP address on this computer.
WSAENETDOWN            :: 10050;
WSAENETUNREACH         :: 10051;
WSAENETRESET           :: 10052;
WSAECONNABORTED        :: 10053; // Connection has been aborted by software in the host machine.
WSAECONNRESET          :: 10054; // The connection was reset while trying to accept, read or write.
WSAENOBUFS             :: 10055; // No buffer space is available. The outgoing queue may be full in which case you should probably try again after a pause.
WSAEISCONN             :: 10056; // The socket is already connected.
WSAENOTCONN            :: 10057; // The socket is not connected yet, or no address was supplied to sendto.
WSAESHUTDOWN           :: 10058; // The socket has been shutdown in the direction required.
WSAETIMEDOUT           :: 10060;
WSAECONNREFUSED        :: 10061;
WSAEHOSTDOWN           :: 10064; // Destination host was down.
WSAEHOSTUNREACH        :: 10065;
WSAENOTINITIALISED     :: 10093; // Needs WSAStartup call
WSAEINVALIDPROCTABLE   :: 10104; // Invalid or incomplete procedure table was returned
WSAEINVALIDPROVIDER    :: 10105; // Service provider version is not 2.2
WSAEPROVIDERFAILEDINIT :: 10106; // Service provider failed to initialize

Socket_Error :: enum i32 {
	Ok,
	Access = WSAEACCES,
	Invalid_Pointer = WSAEFAULT,
	Invalid_Value = WSAEINVAL,
	No_More_Sockets = WSAEMFILE,
	Would_Block = WSAEWOULDBLOCK,
	Bad_Socket = WSAENOTSOCK,
	Truncated = WSAEMSGSIZE,
	Unsupported_Operation = WSAEOPNOTSUPP,
	Unsupported_Socket_Type = WSAESOCKTNOSUPPORT,
	Unsupported_Address_Family = WSAEAFNOSUPPORT,
	Unsupported_Protocol = WSAEPROTONOSUPPORT,
	Addr_Taken = WSAEADDRINUSE,
	Bad_Addr = WSAEADDRNOTAVAIL,
	Network_Down = WSAENETDOWN,
	Network_Unreachable = WSAENETUNREACH,
	Network_Reset = WSAENETRESET,
	Aborted = WSAECONNABORTED,
	Reset = WSAECONNRESET,
	No_More_Buffers = WSAENOBUFS,
	Already_Connected = WSAEISCONN,
	Shutdown = WSAESHUTDOWN,
	Timed_Out = WSAETIMEDOUT,
	Refused = WSAECONNREFUSED,
	Host_Down = WSAEHOSTDOWN,
	Host_Unreachable = WSAEHOSTUNREACH,
	Not_Connected = WSAENOTCONN,
	Not_Initialized = WSAENOTINITIALISED,
	Invalid_Proc_Table = WSAEINVALIDPROCTABLE,
	Provider_Init_Failed = WSAEPROVIDERFAILEDINIT,
	Invalid_Provider = WSAEINVALIDPROVIDER,
	Option_Unknown = WSAENOPROTOOPT,
}

WSA_FLAG_OVERLAPPED :: 1;
WSA_FLAG_MULTIPOINT_C_ROOT :: 2;
WSA_FLAG_MULTIPOINT_C_LEAF :: 4;
WSA_FLAG_MULTIPOINT_D_ROOT :: 8;
WSA_FLAG_MULTIPOINT_D_LEAF :: 16;
WSA_FLAG_ACCESS_SYSTEM_SECURITY :: 32;
WSA_FLAG_NO_HANDLE_INHERIT :: 64;

INVALID_SOCKET :: SOCKET(INVALID_HANDLE);
SOMAXCONN      :: 128; // The number of messages that can be queued in memory after being received; use 2-4 for Bluetooth
SOCKET_ERROR   :: -1;

SD_RECIEVE :: 0; // Declare that you are never going to receive data on a socket again.
SD_SEND    :: 1; // Declare that you are never going to send data to a socket again.
SD_BOTH    :: 2; // Declare that you are never going to send or receive data on a socket again.

MSG_OOB :: 1; // `send`/`recv` should process out-of-band data.
MSG_PEEK :: 2; // `recv` should not remove the data from the buffer. Only valid for non-overlapped operations.

AI_PASSIVE :: 1; // The socket will be used in a call to the 'bind' function
AI_NUMERICSERV :: 8;

SG_UNCONSTRAINED_GROUP :: 1;
SG_CONSTRAINED_GROUP :: 2;

// NOTE: Used with SO_LINGER.
linger :: struct {
	l_onoff: u16,  // non-zero = yes.
	l_linger: u16, // time in seconds
}

in_addr  :: distinct [4]u8;
in6_addr :: distinct [16]u8;



//
// NOTE(tetra): sockaddr, sockaddr_in and sockaddr_in6 should
// be used as if they were fields of a `struct #raw_union`.
// i.e: Like `Socket_Address` below. How handy!
//

sockaddr :: struct {
	family: u16,
	port: u16be,
	data: [14]u8,
}

sockaddr_in :: struct {
	family: u16,
	port:   u16be,
	addr:   in_addr,
	_:      [8]u8, // must be zeroed
}

sockaddr_in6 :: struct {
	family:    u16,
	port:      u16be,
	flow_info: u32,
	addr:      in6_addr,
	scope_id:  u32,
}

Socket_Address :: struct #raw_union {
	ipv4: sockaddr_in,
	ipv6: sockaddr_in6,
}

make_sockaddr :: proc(family: u16, addr: $T, port: u16) -> Socket_Address {
	res: Socket_Address;
	when T == in_addr {
		res.ipv4.addr = addr;
		res.ipv4.port = u16be(port);
		res.ipv4.family = family;
	} else when T == in6_addr {
		res.ipv6.addr = addr;
		res.ipv6.port = u16be(port);
		res.ipv6.family = family;
	} else {
		#panic("to_socket_address only support in_addr and in6_addr");
	}
	return res;
}



addrinfo :: struct {
	flags:       i32,
	family:      i32,
	socket_type: i32,
	protocol:    i32,
	addrlen:     u32,
	addr:        ^sockaddr,
	name:        cstring,
	next:        ^addrinfo,
}

HOSTENT :: struct {
	name:      ^u8,
	aliases:   ^^u8,
	addr_type: i16,
	length:    i16,
	addr_list: ^^u8,
}

WSADATA :: struct {
	version:                   i32,
	high_version:              i32,
	description:               [256]u8,
	system_status:             [256]u8,
	max_sockets:               u16,       // deprecated
	max_datagram_message_size: u16,       // ignored by Winsock after v2
	vendor_info:               ^u8,      // should be ignored after v2
}



SOCKET :: distinct Handle;

ensure_subsystem_started :: proc() {
	@static started := false;
	if started do return;

	word: u32 = (2 << 8) | 2;
	data: WSADATA;
	result := WSAStartup(word, &data);
	assert(result == 0);
}



//
// SOCKET options
//

SOL_SOCKET :: 0xffff;

SO_DEBUG 		:: 0x0001; // turn on debugging info recording
SO_ACCEPTCONN 	:: 0x0002; // socket has had listen()
SO_REUSEADDR 	:: 0x0004; // allow local address reuse
SO_KEEPALIVE 	:: 0x0008; // keep connections alive
SO_DONTROUTE 	:: 0x0010; // just use interface addresses
SO_BROADCAST 	:: 0x0020; // permit sending of broadcast msgs
SO_USELOOPBACK  :: 0x0040; // bypass hardware when possible
SO_LINGER 		:: 0x0080; // linger on close if data present
SO_OOBINLINE 	:: 0x0100; // leave received OOB data in line

SO_DONTLINGER :: ~i32(SO_LINGER);
SO_EXCLUSIVEADDRUSE :: ~i32(SO_REUSEADDR); // disallow local address reuse

SO_SNDBUF :: 0x1001; // send buffer size
SO_RCVBUF :: 0x1002; // receive buffer size
SO_SNDLOWAT :: 0x1003; // send low-water mark
SO_RCVLOWAT :: 0x1004; // receive low-water mark
SO_SNDTIMEO :: 0x1005; // send timeout
SO_RCVTIMEO :: 0x1006; // receive timeout
SO_ERROR :: 0x1007; // get error status and clear
SO_TYPE :: 0x1008; // get socket type
SO_BSP_STATE :: 0x1009; // get socket 5-tuple state

SO_GROUP_ID :: 0x2001; // ID of a socket group
SO_GROUP_PRIORITY :: 0x2002; // the relative priority within a group
SO_MAX_MSG_SIZE :: 0x2003; // maximum message size
SO_MAXCONN :: 128; // Maximum number of pending connections to accept.

SO_CONDITIONAL_ACCEPT :: 0x3002; // enable true conditional accept:
								 // connection is not ack-ed to the
								 // other side until conditional
								 // function returns CF_ACCEPT

SO_PAUSE_ACCEPT :: 0x3003; // pause accepting new connections
SO_COMPARTMENT_ID :: 0x3004; // get/set the compartment for a socket
SO_RANDOMIZE_PORT :: 0x3005; // randomize assignment of wildcard ports
SO_PORT_SCALABILITY :: 0x3006; // enable port scalability
SO_REUSE_UNICASTPORT :: 0x3007; // defer ephemeral port allocation for outbound connections
SO_REUSE_MULTICASTPORT :: 0x3008; // enable port reuse and disable unicast reception.

IP_OPTIONS 					:: 1; // Set/get IP options.
IP_HDRINCL 					:: 2; // Header is included with data.
IP_TOS 						:: 3; // IP type of service.
IP_TTL 						:: 4; // IP TTL (hop limit).
IP_MULTICAST_IF 			:: 9; // IP multicast interface.
IP_MULTICAST_TTL 			:: 10; // IP multicast TTL (hop limit).
IP_MULTICAST_LOOP 			:: 11; // IP multicast loopback.
IP_ADD_MEMBERSHIP 			:: 12; // Add an IP group membership.
IP_DROP_MEMBERSHIP 			:: 13; // Drop an IP group membership.
IP_DONTFRAGMENT 			:: 14; // Don't fragment IP datagrams.
IP_ADD_SOURCE_MEMBERSHIP 	:: 15; // Join IP group/source.
IP_DROP_SOURCE_MEMBERSHIP 	:: 16; // Leave IP group/source.
IP_BLOCK_SOURCE 			:: 17; // Block IP group/source.
IP_UNBLOCK_SOURCE 			:: 18; // Unblock IP group/source.
IP_PKTINFO 					:: 19; // Receive packet information.
IP_HOPLIMIT 				:: 21; // Receive packet hop limit.
IP_RECVTTL 					:: 21; // Receive packet Time To Live (TTL).
IP_RECEIVE_BROADCAST 		:: 22; // Allow/block broadcast reception.
IP_RECVIF 					:: 24; // Receive arrival interface.
IP_RECVDSTADDR 				:: 25; // Receive destination address.
IP_IFLIST 					:: 28; // Enable/Disable an interface list.
IP_ADD_IFLIST				:: 29; // Add an interface list entry.
IP_DEL_IFLIST 				:: 30; // Delete an interface list entry.
IP_UNICAST_IF 				:: 31; // IP unicast interface.
IP_RTHDR 					:: 32; // Set/get IPv6 routing header.
IP_GET_IFLIST 				:: 33; // Get an interface list.
IP_RECVRTHDR 				:: 38; // Receive the routing header.
IP_TCLASS 					:: 39; // Packet traffic class.
IP_RECVTCLASS				:: 40; // Receive packet traffic class.
IP_RECVTOS 					:: 40; // Receive packet Type Of Service (TOS).
IP_ORIGINAL_ARRIVAL_IF 		:: 47; // Original Arrival Interface Index.
IP_ECN 						:: 50; // Receive ECN codepoints in the IP header.
IP_PKTINFO_EX 				:: 51; // Receive extended packet information.
IP_WFP_REDIRECT_RECORDS 	:: 60; // WFP's Connection Redirect Records.
IP_WFP_REDIRECT_CONTEXT 	:: 70; // WFP's Connection Redirect Context.
IP_MTU_DISCOVER 			:: 71; // Set/get path MTU discover state.
IP_MTU 						:: 73; // Get path MTU.
IP_NRT_INTERFACE 			:: 74; // Set NRT interface constraint (outbound).
IP_RECVERR 					:: 75; // Receive ICMP errors.

IPV6_HOPOPTS           :: 1; // Set/get IPv6 hop-by-hop options.
IPV6_HDRINCL           :: 2; // Header is included with data.
IPV6_UNICAST_HOPS      :: 4; // IP unicast hop limit.
IPV6_MULTICAST_IF      :: 9; // IP multicast interface.
IPV6_MULTICAST_HOPS   :: 10; // IP multicast hop limit.
IPV6_MULTICAST_LOOP   :: 11; // IP multicast loopback.
IPV6_ADD_MEMBERSHIP   :: 12; // Add an IP group membership.
IPV6_JOIN_GROUP       :: IPV6_ADD_MEMBERSHIP;
IPV6_DROP_MEMBERSHIP  :: 13; // Drop an IP group membership.
IPV6_LEAVE_GROUP      :: IPV6_DROP_MEMBERSHIP;
IPV6_DONTFRAG         :: 14; // Don't fragment IP datagrams.
IPV6_PKTINFO          :: 19; // Receive packet information.
IPV6_HOPLIMIT         :: 21; // Receive packet hop limit.
IPV6_PROTECTION_LEVEL :: 23; // Set/get IPv6 protection level.
IPV6_RECVIF           :: 24; // Receive arrival interface.
IPV6_RECVDSTADDR      :: 25; // Receive destination address.
IPV6_CHECKSUM         :: 26; // Offset to checksum for raw IP socket send.
IPV6_V6ONLY           :: 27; // Treat wildcard bind as AF_INET6-only.
IPV6_IFLIST           :: 28; // Enable/Disable an interface list.
IPV6_ADD_IFLIST       :: 29; // Add an interface list entry.
IPV6_DEL_IFLIST       :: 30; // Delete an interface list entry.
IPV6_UNICAST_IF       :: 31; // IP unicast interface.
IPV6_RTHDR            :: 32; // Set/get IPv6 routing header.
IPV6_GET_IFLIST       :: 33; // Get an interface list.
IPV6_RECVRTHDR        :: 38; // Receive the routing header.
IPV6_TCLASS           :: 39; // Packet traffic class.
IPV6_RECVTCLASS       :: 40; // Receive packet traffic class.
IPV6_ECN              :: 50; // Receive ECN codepoints in the IP header.
IPV6_PKTINFO_EX       :: 51; // Receive extended packet information.
IPV6_WFP_REDIRECT_RECORDS   :: 60; // WFP's Connection Redirect Records
IPV6_WFP_REDIRECT_CONTEXT   :: 70; // WFP's Connection Redirect Context
IPV6_MTU_DISCOVER           :: 71; // Set/get path MTU discover state.
IPV6_MTU                    :: 72; // Get path MTU.
IPV6_NRT_INTERFACE          :: 74; // Set NRT interface constraint (outbound).
IPV6_RECVERR                :: 75; // Receive ICMPv6 errors.



// TODO(tetra): don't need these?

// the bitmasks for events/revents in pollfd.
POLLRDNORM :: 0x0100; // data may be read without blocking
POLLRDBAND :: 0x0200; // OOB data may be read without blocking
POLLWRNORM :: 0x0010; // data may be written without blocking
POLLWRBAND :: 0x0020; // OOB data may be written without blocking
POLLHUP    :: 0x0002; // stream-oriented socket closed
POLLERR    :: 0x0001; // an error happened

pollfd :: struct {
	fd: SOCKET,
	events: u16, // bitmask of requested events
	revents: u16, // bitmask of received events
}


WSAEVENT :: distinct rawptr;

ERROR_IO_PENDING :: 997;
ERROR_IO_INCOMPLETE :: 996;

WSAOVERLAPPED :: struct {
	_, _: u32,
	_, _: u32,
	hevent: WSAEVENT,
}