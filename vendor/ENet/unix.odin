//+build linux, darwin, freebsd, openbsd, netbsd
package ENet

// When we implement the appropriate bindings for Unix, the section separated
// by `{` and `}` here can be removed in favor of using the bindings.
// {
import "core:c"

@(private="file") FD_SETSIZE :: 1024

@(private="file") fd_set :: struct {
	fds_bits: [FD_SETSIZE / 8 / size_of(c.long)]c.ulong,
}

@(private="file") FD_ZERO :: #force_inline proc(s: ^fd_set) {
	for i := size_of(fd_set) / size_of(c.long); i != 0; i -= 1 {
		s.fds_bits[i] = 0
	}
}

@(private="file") FD_SET :: #force_inline proc(d: i32, s: ^fd_set) {
	s.fds_bits[d / (8 * size_of(c.long))] |= c.ulong(1) << (c.ulong(d) % (8 * size_of(c.ulong)))
}

@(private="file") FD_CLR :: #force_inline proc(d: i32, s: ^fd_set) {
	s.fds_bits[d / (8 * size_of(c.long))] &~= c.ulong(1) << (c.ulong(d) % (8 * size_of(c.ulong)))
}

@(private="file") FD_ISSET :: #force_inline proc(d: i32, s: ^fd_set) -> bool {
	return (s.fds_bits[d / (8 * size_of(c.long))] & c.ulong(1) << (c.ulong(d) % (8 * size_of(c.ulong)))) != 0
}
// }

Socket :: distinct i32

SOCKET_NULL :: Socket(-1)

Buffer :: struct {
	data:       rawptr,
	dataLength: uint,
}

SocketSet :: distinct fd_set

SOCKETSET_EMPTY :: #force_inline proc(sockset: ^SocketSet) {
	FD_ZERO(cast(^fd_set)sockset)
}

SOCKETSET_ADD :: #force_inline proc(sockset: ^SocketSet, socket: Socket) {
	FD_SET(i32(socket), cast(^fd_set)sockset)
}

SOCKETSET_REMOVE :: #force_inline proc(sockset: ^SocketSet, socket: Socket) {
	FD_CLR(i32(socket), cast(^fd_set)sockset)
}

SOCKSET_CHECK :: #force_inline proc(sockset: ^SocketSet, socket: Socket) -> bool {
	return FD_ISSET(i32(socket), cast(^fd_set)sockset)
}
