/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
		graphitemaster:  pton/ntop IANA test vectors
		Feoramund:       FreeBSD-specific tests.

	A test suite for `core:net`
*/
#+build freebsd
package test_core_net

import "core:net"
import "core:time"
import "core:testing"

@test
test_duplicate_binding :: proc(t: ^testing.T) {
	// FreeBSD has the capacity to permit multiple processes and sockets to
	// bind on the same port with the right option.

	raw_socket1, err_create1 := net.create_socket(.IP4, .TCP)
	if !testing.expect_value(t, err_create1, nil) {
		return
	}
	defer net.close(raw_socket1)
	tcp_socket1 := raw_socket1.(net.TCP_Socket)
	err_set1 := net.set_option(tcp_socket1, .Reuse_Port, true)
	if !testing.expect_value(t, err_set1, nil) {
		return
	}
	err_bind1 := net.bind(tcp_socket1, {net.IP4_Loopback, 0})
	if !testing.expect_value(t, err_bind1, nil) {
		return
	}

	ep, err_bound := net.bound_endpoint(tcp_socket1)
	if !testing.expect_value(t, err_bound, nil) {
		return
	}

	raw_socket2, err_create2 := net.create_socket(.IP4, .TCP)
	if !testing.expect_value(t, err_create2, nil) {
		return
	}
	defer net.close(raw_socket2)
	tcp_socket2 := raw_socket2.(net.TCP_Socket)
	err_set2 := net.set_option(tcp_socket2, .Reuse_Port, true)
	if !testing.expect_value(t, err_set2, nil) {
		return
	}
	err_bind2 := net.bind(tcp_socket2, ep)
	if !testing.expect_value(t, err_bind2, nil) {
		return
	}
}

@test
test_sigpipe_bypass :: proc(t: ^testing.T) {
	// If the internals aren't working as expected, this test will fail by raising SIGPIPE.

	server_socket, listen_err := net.listen_tcp({net.IP4_Loopback, 0})
	if !testing.expect_value(t, listen_err, nil) {
		return
	}
	defer net.close(server_socket)

	ep, bound_err := net.bound_endpoint(server_socket)
	if !testing.expect_value(t, bound_err, nil) {
		return
	}

	client_socket, dial_err := net.dial_tcp(ep)
	if !testing.expect_value(t, dial_err, nil) {
		return
	}
	defer net.close(client_socket)

	time.sleep(10 * time.Millisecond)

	net.close(server_socket)

	time.sleep(10 * time.Millisecond)

	data := "Hellope!"
	bytes_written, err_send := net.send(client_socket, transmute([]u8)data)
	if !testing.expect_value(t, err_send, net.TCP_Send_Error.Connection_Closed) {
		return
	}
	if !testing.expect_value(t, bytes_written, 0) {
		return
	}
}
