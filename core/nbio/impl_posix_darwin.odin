#+private
package nbio

import "core:net"
import "core:sys/posix"

foreign import lib "system:System"

posix_sendfile :: proc(fd: Handle, s: TCP_Socket, offset, nbytes: int) -> (sent: int, ok := true) {
	foreign lib {
		@(link_name="sendfile")
		_posix_sendfile :: proc (fd, s: posix.FD, offset: posix.off_t, len: ^posix.off_t, hdtr: rawptr, flags: i32) -> posix.result ---
	}

	len := posix.off_t(nbytes)
	if _posix_sendfile(posix.FD(fd), posix.FD(s), posix.off_t(offset), &len, nil, 0) != .OK {
		ok = false
	}
	sent = int(len)
	return
}

posix_listen_error   :: net._listen_error
posix_accept_error   :: net._accept_error
posix_dial_error     :: net._dial_error
posix_tcp_send_error :: net._tcp_send_error
posix_udp_send_error :: net._udp_send_error
posix_tcp_recv_error :: net._tcp_recv_error
posix_udp_recv_error :: net._udp_recv_error
