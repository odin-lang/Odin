import "fmt.odin";

foreign_system_library ws2 "Ws2_32.lib" when ODIN_OS == "windows";


type SOCKET uint;
const INVALID_SOCKET = ~SOCKET(0);

type AF enum i32 {
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

const (
	SOCK_STREAM  = 1;
	SOCKET_ERROR = -1;
	IPPROTO_TCP  = 6;
	AI_PASSIVE   = 0x0020;
	SOMAXCONN    = 128;
)
const (
	SD_RECEIVE = 0;
	SD_SEND    = 1;
	SD_BOTH    = 2;
)

const WSADESCRIPTION_LEN = 256;
const WSASYS_STATUS_LEN  = 128;
type WSADATA struct #ordered {
	version:       i16,
	high_version:  i16,


// NOTE(bill): This is x64 ordering
	max_sockets:   u16,
	max_udp_dg:    u16,
	vendor_info:   ^u8,
	description:   [WSADESCRIPTION_LEN+1]u8,
	system_status: [WSASYS_STATUS_LEN+1]u8,
}

type addrinfo struct #ordered {
	flags:     i32,
	family:    i32,
	socktype:  i32,
	protocol:  i32,
	addrlen:   uint,
	canonname: ^u8,
	addr:      ^sockaddr,
	next:      ^addrinfo,
}

type sockaddr struct #ordered {
	family: u16,
	data:   [14]u8,
}

foreign ws2 {
	proc WSAStartup     (version_requested: i16, data: ^WSADATA) -> i32;
	proc WSACleanup     () -> i32;
	proc getaddrinfo    (node_name, service_name: ^u8, hints: ^addrinfo, result: ^^addrinfo) -> i32;
	proc freeaddrinfo   (ai: ^addrinfo);
	proc socket         (af, type_, protocol: i32) -> SOCKET;
	proc closesocket    (s: SOCKET) -> i32;
	proc bind           (s: SOCKET, name: ^sockaddr, name_len: i32) -> i32;
	proc listen         (s: SOCKET, back_log: i32) -> i32;
	proc accept         (s: SOCKET, addr: ^sockaddr, addr_len: i32) -> SOCKET;
	proc recv           (s: SOCKET, buf: ^u8, len: i32, flags: i32) -> i32;
	proc send           (s: SOCKET, buf: ^u8, len: i32, flags: i32) -> i32;
	proc shutdown       (s: SOCKET, how: i32) -> i32;
	proc WSAGetLastError() -> i32;
}
proc to_c_string(s: string) -> ^u8 {
	var c_str = make([]u8, len(s)+1);
	copy(c_str, []u8(s));
	c_str[len(s)] = 0;
	return &c_str[0];
}

proc run() {
	var (
		wsa: WSADATA;
		res:  ^addrinfo = nil;
		hints: addrinfo;
		s, client: SOCKET;
	)

	if WSAStartup(2 | (2 << 8), &wsa) != 0 {
		fmt.println("WSAStartup failed: ", WSAGetLastError());
		return;
	}
	defer WSACleanup();

	hints.family   = i32(AF.INET);
	hints.socktype = SOCK_STREAM;
	hints.protocol = IPPROTO_TCP;
	hints.flags    = AI_PASSIVE;

	if getaddrinfo(nil, to_c_string("8080"), &hints, &res) != 0 {
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

	bind(s, res.addr, i32(res.addrlen));
	listen(s, SOMAXCONN);

	client = accept(s, nil, 0);
	if client == INVALID_SOCKET {
		fmt.println("socket failed: ", WSAGetLastError());
		return;
	}
	defer closesocket(client);

	var html =
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

	var buf: [1024]u8;
	for {
		var bytes = recv(client, &buf[0], i32(len(buf)), 0);
		if bytes > 0 {
			// fmt.println(string(buf[0..<bytes]))
			var bytes_sent = send(client, &html[0], i32(len(html)-1), 0);
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
