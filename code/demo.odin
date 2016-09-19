// #import "fmt.odin" as fmt
// #import "os.odin" as os

main :: proc() {

}


// #import "fmt.odin" as fmt

// #foreign_system_library "Ws2_32"


// SOCKET :: type uint
// INVALID_SOCKET :: ~(0 as SOCKET)

// AF :: enum i32 {
// 	UNSPEC    = 0,       // unspecified
// 	UNIX      = 1,       // local to host (pipes, portals)
// 	INET      = 2,       // internetwork: UDP, TCP, etc.
// 	IMPLINK   = 3,       // arpanet imp addresses
// 	PUP       = 4,       // pup protocols: e.g. BSP
// 	CHAOS     = 5,       // mit CHAOS protocols
// 	NS        = 6,       // XEROX NS protocols
// 	ISO       = 7,       // ISO protocols
// 	OSI       = ISO,     // OSI is ISO
// 	ECMA      = 8,       // european computer manufacturers
// 	DATAKIT   = 9,       // datakit protocols
// 	CCITT     = 10,      // CCITT protocols, X.25 etc
// 	SNA       = 11,      // IBM SNA
// 	DECnet    = 12,      // DECnet
// 	DLI       = 13,      // Direct data link interface
// 	LAT       = 14,      // LAT
// 	HYLINK    = 15,      // NSC Hyperchannel
// 	APPLETALK = 16,      // AppleTalk
// 	ROUTE     = 17,      // Internal Routing Protocol
// 	LINK      = 18,      // Link layer interface
// 	XTP       = 19,      // eXpress Transfer Protocol (no AF)
// 	COIP      = 20,      // connection-oriented IP, aka ST II
// 	CNT       = 21,      // Computer Network Technology
// 	RTIP      = 22,      // Help Identify RTIP packets
// 	IPX       = 23,      // Novell Internet Protocol
// 	SIP       = 24,      // Simple Internet Protocol
// 	PIP       = 25,      // Help Identify PIP packets
// 	MAX       = 26,
// }

// SOCK_STREAM  :: 1
// SOCKET_ERROR :: -1
// IPPROTO_TCP  :: 6
// AI_PASSIVE   :: 0x0020
// SOMAXCONN    :: 128

// SD_RECEIVE :: 0
// SD_SEND    :: 1
// SD_BOTH    :: 2

// WSADESCRIPTION_LEN :: 256
// WSASYS_STATUS_LEN  :: 128
// WSADATA :: struct #ordered {
// 	version:       i16
// 	high_version:  i16


// // NOTE(bill): This is x64 ordering
// 	max_sockets:   u16
// 	max_udp_dg:    u16
// 	vendor_info:   ^byte
// 	description:   [WSADESCRIPTION_LEN+1]byte
// 	system_status: [WSASYS_STATUS_LEN+1]byte
// }

// addrinfo :: struct #ordered {
// 	flags:     i32
// 	family:    i32
// 	socktype:  i32
// 	protocol:  i32
// 	addrlen:   uint
// 	canonname: ^u8
// 	addr:      ^sockaddr
// 	next:      ^addrinfo
// }

// sockaddr :: struct #ordered {
// 	family: u16
// 	data:   [14]byte
// }


// WSAStartup      :: proc(version_requested: i16, data: ^WSADATA) -> i32                             #foreign #dll_import
// WSACleanup      :: proc() -> i32                                                                   #foreign #dll_import
// getaddrinfo     :: proc(node_name, service_name: ^u8, hints: ^addrinfo, result: ^^addrinfo) -> i32 #foreign #dll_import
// freeaddrinfo    :: proc(ai: ^addrinfo)                                                             #foreign #dll_import
// socket          :: proc(af, type_, protocol: i32) -> SOCKET                                        #foreign #dll_import
// closesocket     :: proc(s: SOCKET) -> i32                                                          #foreign #dll_import
// bind            :: proc(s: SOCKET, name: ^sockaddr, name_len: i32) -> i32                          #foreign #dll_import
// listen          :: proc(s: SOCKET, back_log: i32) -> i32                                           #foreign #dll_import
// accept          :: proc(s: SOCKET, addr: ^sockaddr, addr_len: i32) -> SOCKET                       #foreign #dll_import
// recv            :: proc(s: SOCKET, buf: ^byte, len: i32, flags: i32) -> i32                        #foreign #dll_import
// send            :: proc(s: SOCKET, buf: ^byte, len: i32, flags: i32) -> i32                        #foreign #dll_import
// shutdown        :: proc(s: SOCKET, how: i32) -> i32                                                #foreign #dll_import
// WSAGetLastError :: proc() -> i32                                                                   #foreign #dll_import

// to_c_string :: proc(s: string) -> ^byte {
// 	c_str := new_slice(byte, s.count+1)
// 	assert(c_str.data != null)
// 	copy(c_str, s as []byte)
// 	c_str[s.count] = 0
// 	return c_str.data
// }

// main :: proc() {
// 	wsa: WSADATA
// 	res:  ^addrinfo = null
// 	hints: addrinfo
// 	s, client: SOCKET

// 	if WSAStartup(2 | (2 << 8), ^wsa) != 0 {
// 		fmt.println("WSAStartup failed: ", WSAGetLastError())
// 		return
// 	}
// 	defer WSACleanup()

// 	hints.family   = AF.INET as i32
// 	hints.socktype = SOCK_STREAM
// 	hints.protocol = IPPROTO_TCP
// 	hints.flags    = AI_PASSIVE

// 	if getaddrinfo(null, to_c_string("8080"), ^hints, ^res) != 0 {
// 		fmt.println("getaddrinfo failed: ", WSAGetLastError())
// 		return
// 	}
// 	defer freeaddrinfo(res)

// 	s = socket(res.family, res.socktype, res.protocol)
// 	if s == INVALID_SOCKET {
// 		fmt.println("socket failed: ", WSAGetLastError())
// 		return
// 	}
// 	defer closesocket(s)

// 	bind(s, res.addr, res.addrlen as i32)
// 	listen(s, SOMAXCONN)

// 	client = accept(s, null, null)
// 	if client == INVALID_SOCKET {
// 		fmt.println("socket failed: ", WSAGetLastError())
// 		return
// 	}
// 	defer closesocket(client)

// 	html :=
// `HTTP/1.1 200 OK
// Connection: close
// Content-type: text/html

// <html>
// <head>
// 	<title>Demo Title</title>
// </head>
// <body>
// 	<h1 style="color: orange;">Odin Server Demo</h1>
// </body>
// </html>
// `

// 	buf: [1024]byte
// 	for {
// 		bytes := recv(client, ^buf[0], buf.count as i32, 0)
// 		if bytes > 0 {
// 			// fmt.println(buf[:bytes] as string)
// 			bytes_sent := send(client, html.data, (html.count-1) as i32, 0)
// 			if bytes_sent == SOCKET_ERROR {
// 				fmt.println("send failed: ", WSAGetLastError())
// 				return
// 			}
// 			break
// 		} else if bytes == 0 {
// 			fmt.println("Connection closing...")
// 			break
// 		} else {
// 			fmt.println("recv failed: ", WSAGetLastError())
// 			return
// 		}
// 	}

// 	shutdown(client, SD_SEND)
// }
