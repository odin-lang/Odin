#import "fmt.odin"
#import "os.odin"



main :: proc() {
	// struct_padding()
	// bounds_checking()
	// type_introspection()
	// any_type()
	crazy_introspection()
	// namespaces_and_files()
	// miscellany()
}

struct_padding :: proc() {
	{
		A :: struct {
			a: u8
			b: u32
			c: u16
		}

		B :: struct {
			a: [7]u8
			b: [3]u16
			c: u8
			d: u16
		}

		fmt.println("size_of(A):", size_of(A))
		fmt.println("size_of(B):", size_of(B))

		// n.b. http://cbloomrants.blogspot.co.uk/2012/07/07-23-12-structs-are-not-what-you-want.html
	}
	{
		A :: struct #ordered {
			a: u8
			b: u32
			c: u16
		}

		B :: struct #ordered {
			a: [7]u8
			b: [3]u16
			c: u8
			d: u16
		}

		fmt.println("size_of(A):", size_of(A))
		fmt.println("size_of(B):", size_of(B))

		// C-style structure layout
	}
	{
		A :: struct #packed {
			a: u8
			b: u32
			c: u16
		}

		B :: struct #packed {
			a: [7]u8
			b: [3]u16
			c: u8
			d: u16
		}

		fmt.println("size_of(A):", size_of(A))
		fmt.println("size_of(B):", size_of(B))

		// Useful for explicit layout
	}

	// Member sorting by priority
	// Alignment desc.
	// Size desc.
	// source order asc.

	/*
		A :: struct {
			a: u8
			b: u32
			c: u16
		}

		B :: struct {
			a: [7]u8
			b: [3]u16
			c: u8
			d: u16
		}

		Equivalent too

		A :: struct #ordered {
			b: u32
			c: u16
			a: u8
		}

		B :: struct #ordered {
			b: [3]u16
			d: u16
			a: [7]u8
			c: u8
		}
	*/
}

bounds_checking :: proc() {
	x: [4]int
	// x[-1] = 0; // Compile Time
	// x[4]  = 0; // Compile Time

	/*{
		a, b := -1, 4;
		x[a] = 0; // Runtime Time
		x[b] = 0; // Runtime Time
	}*/

	// Works for arrays, strings, slices, and related procedures & operations

	{
		base: [10]int
		s := base[2:6]
		a, b := -1, 6

		#no_bounds_check {
			s[a] = 0;
			// #bounds_check s[b] = 0;
		}

	#no_bounds_check
		if s[a] == 0 {
			// Do whatever
		}

		// Bounds checking can be toggled explicit
		// on a per statement basis.
		// _any statement_
	}
}

type_introspection :: proc() {

	info: ^Type_Info
	x: int

	info = type_info(int) // by type
	info = type_info(x) // by value
	// See: runtime.odin

	match type i : info {
	case Type_Info.Integer:
		fmt.println("integer!")
	case Type_Info.Float:
		fmt.println("float!")
	default:
		fmt.println("potato!")
	}

	// Unsafe cast
	integer_info := info as ^Type_Info.Integer
}

any_type :: proc() {
	a: any

	x := 123
	y := 6.28
	z := "Yo-Yo Ma"
	// All types can be implicit cast to `any`
	a = x
	a = y
	a = z
	a = a

	// any has two members
	// data      - rawptr to the data
	// type_info - pointer to the type info

	fmt.println(x, y, z)
	// See: Implementation
}

crazy_introspection :: proc() {
	{
		Fruit :: enum {
			APPLE,
			BANANA,
			GRAPE,
			MELON,
			PEACH,
			TOMATO,
		}

		s: string
		s = enum_to_string(Fruit.PEACH)
		fmt.println(s)

		f := Fruit.GRAPE
		s = enum_to_string(f)
		fmt.println(s)

		fmt.println(f)
	}


	{
		// NOTE(bill): This is not safe code and I would not recommend this at all
		// I'd recommend you use `match type` to get the subtype rather than
		// casting pointers

		Fruit :: enum {
			APPLE,
			BANANA,
			GRAPE,
			MELON,
			PEACH,
			TOMATO,
		}

		fruit_ti := type_info(Fruit)
		name := (fruit_ti as ^Type_Info.Named).name // Unsafe casts
		info := type_info_base(fruit_ti) as ^Type_Info.Enum // Unsafe casts

		fmt.printf("% :: enum ", name);
		fmt.fprint_type(os.stdout, info.base)
		fmt.printf(" {\n")
		for i := 0; i < info.values.count; i++ {
			fmt.printf("\t%\t= %,\n", info.names[i], info.values[i])
		}
		fmt.printf("}\n")
	}

	{
		Vector3 :: struct {x, y, z: f32}

		a := Vector3{x = 1, y = 4, z = 9}
		fmt.println(a)
		b := Vector3{x = 9, y = 3, z = 1}
		fmt.println(b)

		// NOTE(bill): See fmt.odin
	}

	// n.b. This pretty much "solves" serialization (to strings)
}


namespaces_and_files :: proc() {
	/*
		// Non-exporting import
		#import "file.odin"
		#import "file.odin" as file
		#import "file.odin" as .
		#import "file.odin" as _

		// Exporting import
		#load "file.odin"
	*/

	// Talk about scope rules and diagram
}

miscellany :: proc() {
	/*
		win32 `__imp__` prefix
		#dll_import
		#dll_export

		Change exported name/symbol for linking
		#link_name

		Custom calling conventions
		#stdcall
		#fastcall

		Runtime stuff
		#shared_global_scope
	*/

	// assert(false)
	// compile_assert(false)
	// panic("Panic message goes here")
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
