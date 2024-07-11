//+build windows
package ENet

// When we implement the appropriate bindings for Windows, the section separated
// by `{` and `}` here can be removed in favor of using the bindings.
// {
foreign import WinSock2 "system:Ws2_32.lib"

@(private="file", default_calling_convention="c")
foreign WinSock2 {
	__WSAFDIsSet :: proc(fd: SOCKET, s: ^fd_set) -> i32 ---
}

@(private="file") SOCKET :: uintptr

@(private="file") FD_SETSIZE :: 64

@(private="file") fd_set :: struct {
	fd_count: u32,
	fd_array: [FD_SETSIZE]SOCKET,
}

@(private="file") FD_CLR :: proc(fd: SOCKET, s: ^fd_set) {
	for i := u32(0); i < s.fd_count; i += 1 {
		if s.fd_array[i] == fd {
			for i < s.fd_count - 1 {
				s.fd_array[i] = s.fd_array[i + 1]
				i += 1
			}
			s.fd_count -= 1
			break
		}
	}
}

@(private="file") FD_SET :: proc(fd: SOCKET, s: ^fd_set) {
	for i := u32(0); i < s.fd_count; i += 1 {
		if s.fd_array[i] == fd {
			return
		}
	}
	if s.fd_count >= FD_SETSIZE {
		return
	}
	s.fd_array[s.fd_count] = fd
	s.fd_count += 1
}

@(private="file") FD_ZERO :: #force_inline proc (s: ^fd_set) {
	s.fd_count = 0
}

@(private="file") FD_ISSET :: #force_inline proc (fd: SOCKET, s: ^fd_set) -> bool {
	return __WSAFDIsSet(fd, s) != 0
}
// }

Socket :: distinct SOCKET

SOCKET_NULL :: Socket(~uintptr(0))

Buffer :: struct {
	data:       rawptr,
	dataLength: uint,
}

SocketSet :: distinct fd_set

SOCKETSET_EMPTY :: #force_inline proc(sockset: ^SocketSet) {
	FD_ZERO(cast(^fd_set)sockset)
}

SOCKETSET_ADD :: #force_inline proc(sockset: ^SocketSet, socket: Socket) {
	FD_SET(SOCKET(socket), cast(^fd_set)sockset)
}

SOCKETSET_REMOVE :: #force_inline proc(sockset: ^SocketSet, socket: Socket) {
	FD_CLR(SOCKET(socket), cast(^fd_set)sockset)
}

SOCKSET_CHECK :: #force_inline proc(sockset: ^SocketSet, socket: Socket) -> bool {
	return FD_ISSET(SOCKET(socket), cast(^fd_set)sockset)
}