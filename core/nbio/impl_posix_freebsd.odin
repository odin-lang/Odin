#+private
package nbio

import "core:net"
import "core:sys/posix"
import "core:sys/freebsd"

foreign import lib "system:c"

// TODO: rewrite freebsd implementation to use `sys/freebsd` instead of `sys/posix`.

posix_sendfile :: proc(fd: Handle, s: TCP_Socket, offset, nbytes: int) -> (sent: int, ok := true) {
	foreign lib {
		@(link_name="sendfile")
		_posix_sendfile :: proc (fd, s: posix.FD, offset: posix.off_t, nbytes: uint, hdtr: rawptr, sbytes: ^posix.off_t, flags: i32) -> posix.result ---
	}

	len: posix.off_t
	if _posix_sendfile(posix.FD(fd), posix.FD(s), posix.off_t(offset), uint(nbytes), nil, &len, 0) != .OK {
		ok = false
	}
	sent = int(len)
	return
}

posix_listen_error :: proc() -> Listen_Error {
	return net._listen_error(freebsd.Errno(posix.errno()))
}

posix_accept_error :: proc() -> Accept_Error {
	return net._accept_error(freebsd.Errno(posix.errno()))
}

posix_dial_error :: proc() -> Dial_Error {
	return net._dial_error(freebsd.Errno(posix.errno()))
}

posix_tcp_send_error :: proc() -> TCP_Send_Error {
	return net._tcp_send_error(freebsd.Errno(posix.errno()))
}

posix_udp_send_error :: proc() -> UDP_Send_Error {
	return net._udp_send_error(freebsd.Errno(posix.errno()))
}

posix_tcp_recv_error :: proc() -> TCP_Recv_Error {
	return net._tcp_recv_error(freebsd.Errno(posix.errno()))
}

posix_udp_recv_error :: proc() -> UDP_Recv_Error {
	return net._udp_recv_error(freebsd.Errno(posix.errno()))
}
