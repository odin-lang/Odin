#+private
package nbio

import "core:net"

posix_listen_error   :: net._listen_error
posix_accept_error   :: net._accept_error
posix_dial_error     :: net._dial_error
posix_tcp_send_error :: net._tcp_send_error
posix_udp_send_error :: net._udp_send_error
posix_tcp_recv_error :: net._tcp_recv_error
posix_udp_recv_error :: net._udp_recv_error
