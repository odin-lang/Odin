#import "fmt.odin";

#foreign_system_library ws2 "Ws2_32.lib" when ODIN_OS == "windows";


SOCKET :: type uint;
INVALID_SOCKET :: ~(cast(SOCKET)0);

AF :: enum i32 {
	UNSPEC    = 0,       // unspecified
	UNIX      = 1,       // local to host (pipes, portals)
	INET      = 2,       // internetwork: UDP, TCP, etc.
	IMPLINK   = 3,       // arpanet imp addresses
	PUP       = 4,       // pup protocols: e.g. BSP
	CHAOS     = 5,       // mit CHAOS protocols
	NS        = 6,       // XEROX NS protocols
	ISO       = 7,       // ISO protocols
	OSI       = ISO,     // OSI is ISO
	ECMA      = 8,       // european computer manufacturers
	DATAKIT   = 9,       // datakit protocols
	CCITT     = 10,      // CCITT protocols, X.25 etc
	SNA       = 11,      // IBM SNA
	DECnet    = 12,      // DECnet
	DLI       = 13,      // Direct data link interface
	LAT       = 14,      // LAT
	HYLINK    = 15,      // NSC Hyperchannel
	APPLETALK = 16,      // AppleTalk
	ROUTE     = 17,      // Internal Routing Protocol
	LINK      = 18,      // Link layer interface
	XTP       = 19,      // eXpress Transfer Protocol (no AF)
	COIP      = 20,      // connection-oriented IP, aka ST II
	CNT       = 21,      // Computer Network Technology
	RTIP      = 22,      // Help Identify RTIP packets
	IPX       = 23,      // Novell Internet Protocol
	SIP       = 24,      // Simple Internet Protocol
	PIP       = 25,      // Help Identify PIP packets
	MAX       = 26,
};

SOCK_STREAM  :: 1;
SOCKET_ERROR :: -1;
IPPROTO_TCP  :: 6;
AI_PASSIVE   :: 0x0020;
SOMAXCONN    :: 128;

SD_RECEIVE :: 0;
SD_SEND    :: 1;
SD_BOTH    :: 2;

WSADESCRIPTION_LEN :: 256;
WSASYS_STATUS_LEN  :: 128;
WSADATA :: struct #ordered {
	version:       i16,
	high_version:  i16,


// NOTE(bill): This is x64 ordering
	max_sockets:   u16,
	max_udp_dg:    u16,
	vendor_info:   ^byte,
	description:   [WSADESCRIPTION_LEN+1]byte,
	system_status: [WSASYS_STATUS_LEN+1]byte,
}

addrinfo :: struct #ordered {
	flags:     i32,
	family:    i32,
	socktype:  i32,
	protocol:  i32,
	addrlen:   uint,
	canonname: ^u8,
	addr:      ^sockaddr,
	next:      ^addrinfo,
}

sockaddr :: struct #ordered {
	family: u16,
	data:   [14]byte,
}


WSAStartup      :: proc(version_requested: i16, data: ^WSADATA) -> i32                             #foreign ws2;
WSACleanup      :: proc() -> i32                                                                   #foreign ws2;
getaddrinfo     :: proc(node_name, service_name: ^u8, hints: ^addrinfo, result: ^^addrinfo) -> i32 #foreign ws2;
freeaddrinfo    :: proc(ai: ^addrinfo)                                                             #foreign ws2;
socket          :: proc(af, type_, protocol: i32) -> SOCKET                                        #foreign ws2;
closesocket     :: proc(s: SOCKET) -> i32                                                          #foreign ws2;
bind            :: proc(s: SOCKET, name: ^sockaddr, name_len: i32) -> i32                          #foreign ws2;
listen          :: proc(s: SOCKET, back_log: i32) -> i32                                           #foreign ws2;
accept          :: proc(s: SOCKET, addr: ^sockaddr, addr_len: i32) -> SOCKET                       #foreign ws2;
recv            :: proc(s: SOCKET, buf: ^byte, len: i32, flags: i32) -> i32                        #foreign ws2;
send            :: proc(s: SOCKET, buf: ^byte, len: i32, flags: i32) -> i32                        #foreign ws2;
shutdown        :: proc(s: SOCKET, how: i32) -> i32                                                #foreign ws2;
WSAGetLastError :: proc() -> i32                                                                   #foreign ws2;

to_c_string :: proc(s: string) -> ^byte {
	c_str := new_slice(byte, s.count+1);
	assert(c_str.data != nil);
	copy(c_str, cast([]byte)s);
	c_str[s.count] = 0;
	return c_str.data;
}

run :: proc() {
	wsa: WSADATA;
	res:  ^addrinfo = nil;
	hints: addrinfo;
	s, client: SOCKET;

	if WSAStartup(2 | (2 << 8), ^wsa) != 0 {
		fmt.println("WSAStartup failed: ", WSAGetLastError());
		return;
	}
	defer WSACleanup();

	hints.family   = cast(i32)AF.INET;
	hints.socktype = SOCK_STREAM;
	hints.protocol = IPPROTO_TCP;
	hints.flags    = AI_PASSIVE;

	if getaddrinfo(nil, to_c_string("8080"), ^hints, ^res) != 0 {
		fmt.println("getaddrinfo failed: ", WSAGetLastError());
		return;
	}
	defer freeaddrinfo(res);

	s = socket(res.family, res.socktype, res.protocol);
	if s == INVALID_SOCKET {
		fmt.println("socket failed: ", WSAGetLastError());
		return;
	}
	defer closesocket(s);

	bind(s, res.addr, cast(i32)res.addrlen);
	listen(s, SOMAXCONN);

	client = accept(s, nil, 0);
	if client == INVALID_SOCKET {
		fmt.println("socket failed: ", WSAGetLastError());
		return;
	}
	defer closesocket(client);

	html :=
`HTTP/1.1 200 OK
Connection: close
Content-type: text/html

<html>
<head>
	<title>Demo Title</title>
</head>
<body>
	<h1 style="color: orange;">Odin Server Demo</h1>
</body>
</html>
`;

	buf: [1024]byte;
	for {
		bytes := recv(client, ^buf[0], cast(i32)buf.count, 0);
		if bytes > 0 {
			// fmt.println(buf[:bytes] as string)
			bytes_sent := send(client, html.data, cast(i32)(html.count-1), 0);
			if bytes_sent == SOCKET_ERROR {
				fmt.println("send failed: ", WSAGetLastError());
				return;
			}
			break;
		} else if bytes == 0 {
			fmt.println("Connection closing...");
			break;
		} else {
			fmt.println("recv failed: ", WSAGetLastError());
			return;
		}
	}

	shutdown(client, SD_SEND);
}
