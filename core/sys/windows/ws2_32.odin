#+build windows
package sys_windows

// Define flags to be used with the WSAAsyncSelect() call.
FD_READ       :: 0x01
FD_WRITE      :: 0x02
FD_OOB        :: 0x04
FD_ACCEPT     :: 0x08
FD_CONNECT    :: 0x10
FD_CLOSE      :: 0x20
FD_MAX_EVENTS :: 10

INADDR_LOOPBACK :: 0x7f000001

// Event flag definitions for WSAPoll().
POLLRDNORM :: 0x0100
POLLRDBAND :: 0x0200
POLLIN     :: (POLLRDNORM | POLLRDBAND)
POLLPRI    :: 0x0400
POLLWRNORM :: 0x0010
POLLOUT    :: (POLLWRNORM)
POLLWRBAND :: 0x0020
POLLERR    :: 0x0001
POLLHUP    :: 0x0002
POLLNVAL   :: 0x0004

WSA_POLLFD :: struct{
	fd:      SOCKET,
	events:  c_short,
	revents: c_short,
}

WSANETWORKEVENTS :: struct {
	lNetworkEvents: c_long,
	iErrorCode:     [FD_MAX_EVENTS]c_int,
}

WSAEVENT :: HANDLE

WSAID_ACCEPTEX             :: GUID{0xb5367df1, 0xcbac, 0x11cf, {0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92}}
WSAID_GETACCEPTEXSOCKADDRS :: GUID{0xb5367df2, 0xcbac, 0x11cf, {0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92}}
WSAID_CONNECTX             :: GUID{0x25a207b9, 0xddf3, 0x4660, {0x8e, 0xe9, 0x76, 0xe5, 0x8c, 0x74, 0x06, 0x3e}}

SIO_GET_EXTENSION_FUNCTION_POINTER :: IOC_INOUT | IOC_WS2 | 6

IOC_OUT   :: 0x40000000
IOC_IN    :: 0x80000000
IOC_INOUT :: (IOC_IN | IOC_OUT)
IOC_WS2   :: 0x08000000

SO_UPDATE_ACCEPT_CONTEXT :: 28683

LPFN_CONNECTEX :: #type proc "system" (
	s:                SOCKET,
	sockaddr:         ^SOCKADDR_STORAGE_LH,
	namelen:          c_int,
	lpSendBuffer:     PVOID,
	dwSendDataLength: DWORD,
	lpdwBytesSent:    LPDWORD,
	lpOverlapped:     LPOVERLAPPED,
) -> BOOL

LPFN_ACCEPTEX :: #type proc "system" (
	sListenSocket:         SOCKET,
	sAcceptSocket:         SOCKET,
	lpOutputBuffer:        PVOID,
	dwReceiveDataLength:   DWORD,
	dwLocalAddressLength:  DWORD,
	dwRemoteAddressLength: DWORD,
	lpdwBytesReceived:     LPDWORD,
	lpOverlapped:          LPOVERLAPPED,
) -> BOOL

/*
Example Load:
	load_accept_ex :: proc(listener: SOCKET, fn_acceptex: ^LPFN_ACCEPTEX) {
		bytes: u32
		guid_accept_ex := WSAID_ACCEPTEX
		rc := WSAIoctl(listener, SIO_GET_EXTENSION_FUNCTION_POINTER, &guid_accept_ex, size_of(guid_accept_ex),
			fn_acceptex, size_of(fn_acceptex), &bytes, nil,	nil)
		assert(rc != windows.SOCKET_ERROR)
	}
*/

foreign import ws2_32 "system:Ws2_32.lib"
@(default_calling_convention="system")
foreign ws2_32 {
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsastartup)
	WSAStartup :: proc(wVersionRequested: WORD, lpWSAData: LPWSADATA) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsacleanup)
	WSACleanup :: proc() -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsagetlasterror)
	WSAGetLastError :: proc() -> c_int ---
	WSASetLastError :: proc(err: c_int) ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsapoll)
	WSAPoll :: proc(fdArray: ^WSA_POLLFD, fds: c_ulong, timeout: c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsaduplicatesocketw)
	WSADuplicateSocketW :: proc(
		s: SOCKET,
		dwProcessId: DWORD,
		lpProtocolInfo: LPWSAPROTOCOL_INFO,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsasend)
	WSASend :: proc(
		s: SOCKET,
		lpBuffers: LPWSABUF,
		dwBufferCount: DWORD,
		lpNumberOfBytesSent: LPDWORD,
		dwFlags: DWORD,
		lpOverlapped: LPWSAOVERLAPPED,
		lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsarecv)
	WSARecv :: proc(
		s: SOCKET,
		lpBuffers: LPWSABUF,
		dwBufferCount: DWORD,
		lpNumberOfBytesRecvd: LPDWORD,
		lpFlags: LPDWORD,
		lpOverlapped: LPWSAOVERLAPPED,
		lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsasocketw)
	WSASocketW :: proc(
		af: c_int,
		kind: c_int,
		protocol: c_int,
		lpProtocolInfo: LPWSAPROTOCOL_INFO,
		g: GROUP,
		dwFlags: DWORD,
	) -> SOCKET ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsaioctl)
	WSAIoctl :: proc(s: SOCKET, dwIoControlCode: DWORD, lpvInBuffer: rawptr, cbInBuffer: DWORD, lpvOutBuffer: rawptr, cbOutBuffer: DWORD, lpcbBytesReturned: ^DWORD, lpOverlapped: ^OVERLAPPED, lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsaeventselect)
	WSAEventSelect :: proc(s: SOCKET, hEventObject: WSAEVENT, lNetworkEvents: i32) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsawaitformultipleevents)
	WSAWaitForMultipleEvents :: proc(cEvents: DWORD, lphEvents: ^WSAEVENT, fWaitAll: BOOL, dwTimeout: DWORD, fAlertable: BOOL) -> DWORD ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsaenumnetworkevents)
	WSAEnumNetworkEvents :: proc(s: SOCKET, hEventObject: WSAEVENT, lpNetworkEvents: ^WSANETWORKEVENTS) -> c_int ---
	//[MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsagetoverlappedresult)
	WSAGetOverlappedResult :: proc(s: SOCKET, lpOverlapped: ^OVERLAPPED, lpcbTransfer: ^DWORD, fWait: BOOL, lpdwFlags: ^DWORD) -> BOOL ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-socket)
	socket :: proc(
		af: c_int,
		type: c_int,
		protocol: c_int,
	) -> SOCKET ---

	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-ioctlsocket)
	ioctlsocket :: proc(s: SOCKET, cmd: c_long, argp: ^c_ulong) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-closesocket)
	closesocket :: proc(socket: SOCKET) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-recv)
	recv :: proc(socket: SOCKET, buf: rawptr, len: c_int, flags: c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-send)
	send :: proc(socket: SOCKET, buf: rawptr, len: c_int, flags: c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-recvfrom)
	recvfrom :: proc(
		socket: SOCKET,
		buf: rawptr,
		len: c_int,
		flags: c_int,
		addr: ^SOCKADDR_STORAGE_LH,
		addrlen: ^c_int,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-sendto)
	sendto :: proc(
		socket: SOCKET,
		buf: rawptr,
		len: c_int,
		flags: c_int,
		addr: ^SOCKADDR_STORAGE_LH,
		addrlen: c_int,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-shutdown)
	shutdown :: proc(socket: SOCKET, how: c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-accept)
	accept :: proc(socket: SOCKET, address: ^SOCKADDR_STORAGE_LH, address_len: ^c_int) -> SOCKET ---

	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-setsockopt)
	setsockopt :: proc(
		s: SOCKET,
		level: c_int,
		optname: c_int,
		optval: rawptr,
		optlen: c_int,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-getsockname)
	getsockname :: proc(socket: SOCKET, address: ^SOCKADDR_STORAGE_LH, address_len: ^c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-getpeername)
	getpeername :: proc(socket: SOCKET, address: ^SOCKADDR_STORAGE_LH, address_len: ^c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-bind)
	bind :: proc(socket: SOCKET, address: ^SOCKADDR_STORAGE_LH, address_len: socklen_t) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-listen)
	listen :: proc(socket: SOCKET, backlog: c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-connect)
	connect :: proc(socket: SOCKET, address: ^SOCKADDR_STORAGE_LH, len: c_int) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ws2tcpip/nf-ws2tcpip-getaddrinfo)
	getaddrinfo :: proc(
		node: cstring,
		service: cstring,
		hints: ^ADDRINFOA,
		res: ^^ADDRINFOA,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ws2tcpip/nf-ws2tcpip-freeaddrinfo)
	freeaddrinfo :: proc(res: ^ADDRINFOA) ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ws2tcpip/nf-ws2tcpip-freeaddrinfoexw)
	FreeAddrInfoExW :: proc(pAddrInfoEx: PADDRINFOEXW) ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ws2tcpip/nf-ws2tcpip-getaddrinfoexw)
	GetAddrInfoExW :: proc(
		pName:               PCWSTR,
		pServiceName:        PCWSTR,
		dwNameSpace:         DWORD,
		lpNspId:             LPGUID,
		hints:               ^ADDRINFOEXW,
		ppResult:            ^PADDRINFOEXW,
		timeout:             ^timeval,
		lpOverlapped:        LPOVERLAPPED,
		lpCompletionRoutine: LPLOOKUPSERVICE_COMPLETION_ROUTINE,
		lpHandle:            LPHANDLE) -> INT ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-select)
	select :: proc(
		nfds: c_int,
		readfds: ^fd_set,
		writefds: ^fd_set,
		exceptfds: ^fd_set,
		timeout: ^timeval,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-getsockopt)
	getsockopt :: proc(
		s: SOCKET,
		level: c_int,
		optname: c_int,
		optval: ^c_char,
		optlen: ^c_int,
	) -> c_int ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-ntohl)
	ntohl :: proc(netlong: c_ulong) -> c_ulong ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-ntohs)
	ntohs :: proc(netshort: c_ushort) -> c_ushort ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-htonl)
	@(deprecated="Use endian specific integers instead, https://odin-lang.org/docs/overview/#basic-types")
	htonl :: proc(hostlong: c_ulong) -> c_ulong ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-htons)
	@(deprecated="Use endian specific integers instead, https://odin-lang.org/docs/overview/#basic-types")
	htons :: proc(hostshort: c_ushort) -> c_ushort ---
}
