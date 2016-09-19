#import "fmt.odin" as fmt

main :: proc() {
	Fruit :: enum {
		APPLE = -2,
		BANANA,
		GRAPE,
		MELON = 123,
		TOMATO,
	}

	s1 := enum_to_string(Fruit.BANANA)
	e := Fruit.MELON
	s2 := enum_to_string(e)

	fmt.println(Fruit.APPLE)
	fmt.println(Fruit.count)
	fmt.println(Fruit.min_value)
	fmt.println(Fruit.max_value)
}


// #import "fmt.odin" as fmt

// #foreign_system_library "Ws2_32"

// WSADESCRIPTION_LEN :: 256
// WSASYS_STATUS_LEN  :: 128
// WSADATA :: struct #ordered {
// 	version:       i16
// 	high_version:  i16


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


// SOCKET :: type uint
// INVALID_SOCKET :: ~(0 as SOCKET)

// AF_UNSPEC      :: 0       // unspecified
// AF_UNIX        :: 1       // local to host (pipes, portals)
// AF_INET        :: 2       // internetwork: UDP, TCP, etc.
// AF_IMPLINK     :: 3       // arpanet imp addresses
// AF_PUP         :: 4       // pup protocols: e.g. BSP
// AF_CHAOS       :: 5       // mit CHAOS protocols
// AF_NS          :: 6       // XEROX NS protocols
// AF_ISO         :: 7       // ISO protocols
// AF_OSI         :: AF_ISO  // OSI is ISO
// AF_ECMA        :: 8       // european computer manufacturers
// AF_DATAKIT     :: 9       // datakit protocols
// AF_CCITT       :: 10      // CCITT protocols, X.25 etc
// AF_SNA         :: 11      // IBM SNA
// AF_DECnet      :: 12      // DECnet
// AF_DLI         :: 13      // Direct data link interface
// AF_LAT         :: 14      // LAT
// AF_HYLINK      :: 15      // NSC Hyperchannel
// AF_APPLETALK   :: 16      // AppleTalk
// AF_ROUTE       :: 17      // Internal Routing Protocol
// AF_LINK        :: 18      // Link layer interface
// pseudo_AF_XTP  :: 19      // eXpress Transfer Protocol (no AF)
// AF_COIP        :: 20      // connection-oriented IP, aka ST II
// AF_CNT         :: 21      // Computer Network Technology
// pseudo_AF_RTIP :: 22      // Help Identify RTIP packets
// AF_IPX         :: 23      // Novell Internet Protocol
// AF_SIP         :: 24      // Simple Internet Protocol
// pseudo_AF_PIP  :: 25      // Help Identify PIP packets
// AF_MAX         :: 26

// SOCK_STREAM  :: 1
// SOCKET_ERROR :: -1
// IPPROTO_TCP  :: 6
// AI_PASSIVE   :: 0x0020
// SOMAXCONN    :: 128

// SD_RECEIVE :: 0
// SD_SEND    :: 1
// SD_BOTH    :: 2

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

// 	hints.family   = AF_INET
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
