package sys_windows

foreign import ws2_32 "system:Ws2_32.lib"

@(default_calling_convention="stdcall")
foreign ws2_32 {
	WSAStartup :: proc(wVersionRequested: WORD, lpWSAData: LPWSADATA) -> c_int ---
	WSACleanup :: proc() -> c_int ---
	WSAGetLastError :: proc() -> c_int ---
	WSADuplicateSocketW :: proc(
		s: SOCKET,
		dwProcessId: DWORD,
		lpProtocolInfo: LPWSAPROTOCOL_INFO,
	) -> c_int ---
	WSASend :: proc(
		s: SOCKET,
		lpBuffers: LPWSABUF,
		dwBufferCount: DWORD,
		lpNumberOfBytesSent: LPDWORD,
		dwFlags: DWORD,
		lpOverlapped: LPWSAOVERLAPPED,
		lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE,
	) -> c_int ---
	WSARecv :: proc(
		s: SOCKET,
		lpBuffers: LPWSABUF,
		dwBufferCount: DWORD,
		lpNumberOfBytesRecvd: LPDWORD,
		lpFlags: LPDWORD,
		lpOverlapped: LPWSAOVERLAPPED,
		lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE,
	) -> c_int ---
	WSASocketW :: proc(
		af: c_int,
		kind: c_int,
		protocol: c_int,
		lpProtocolInfo: LPWSAPROTOCOL_INFO,
		g: GROUP,
		dwFlags: DWORD,
	) -> SOCKET ---

	ioctlsocket :: proc(s: SOCKET, cmd: c_long, argp: ^c_ulong) -> c_int ---
	closesocket :: proc(socket: SOCKET) -> c_int ---
	recv :: proc(socket: SOCKET, buf: rawptr, len: c_int, flags: c_int) -> c_int ---
	send :: proc(socket: SOCKET, buf: rawptr, len: c_int, flags: c_int) -> c_int ---
	recvfrom :: proc(
		socket: SOCKET,
		buf: rawptr,
		len: c_int,
		flags: c_int,
		addr: ^SOCKADDR,
		addrlen: ^c_int,
	) -> c_int ---
	sendto :: proc(
		socket: SOCKET,
		buf: rawptr,
		len: c_int,
		flags: c_int,
		addr: ^SOCKADDR,
		addrlen: c_int,
	) -> c_int ---
	shutdown :: proc(socket: SOCKET, how: c_int) -> c_int ---
	accept :: proc(socket: SOCKET, address: ^SOCKADDR, address_len: ^c_int) -> SOCKET ---

	setsockopt :: proc(
		s: SOCKET,
		level: c_int,
		optname: c_int,
		optval: rawptr,
		optlen: c_int,
	) -> c_int ---
	getsockname :: proc(socket: SOCKET, address: ^SOCKADDR, address_len: ^c_int) -> c_int ---
	getpeername :: proc(socket: SOCKET, address: ^SOCKADDR, address_len: ^c_int) -> c_int ---
	bind :: proc(socket: SOCKET, address: ^SOCKADDR, address_len: socklen_t) -> c_int ---
	listen :: proc(socket: SOCKET, backlog: c_int) -> c_int ---
	connect :: proc(socket: SOCKET, address: ^SOCKADDR, len: c_int) -> c_int ---
	getaddrinfo :: proc(
		node: ^c_char,
		service: ^c_char,
		hints: ^ADDRINFOA,
		res: ^ADDRINFOA,
	) -> c_int ---
	freeaddrinfo :: proc(res: ^ADDRINFOA) ---
	select :: proc(
		nfds: c_int,
		readfds: ^fd_set,
		writefds: ^fd_set,
		exceptfds: ^fd_set,
		timeout: ^timeval,
	) -> c_int ---
	getsockopt :: proc(
		s: SOCKET,
		level: c_int,
		optname: c_int,
		optval: ^c_char,
		optlen: ^c_int,
	) -> c_int ---

}
