#+build linux
package test_core_net

import "core:net"
import "core:sys/linux"
import "core:testing"
import "core:time"

// `SO_LINGER` expects a `struct linger`, not a `struct timeval`. Make sure the
// value the kernel receives is the one that was requested.
@(test)
test_set_option_linger :: proc(t: ^testing.T) {
	LINGER_SECONDS :: 5

	listener, listen_err := net.listen_tcp({net.IP4_Loopback, 0})
	if !testing.expect_value(t, listen_err, nil) {
		return
	}
	defer net.close(listener)

	endpoint, bound_err := net.bound_endpoint(listener)
	if !testing.expect_value(t, bound_err, nil) {
		return
	}

	client, dial_err := net.dial_tcp(endpoint)
	if !testing.expect_value(t, dial_err, nil) {
		return
	}
	defer net.close(client)

	server, _, accept_err := net.accept_tcp(listener)
	if !testing.expect_value(t, accept_err, nil) {
		return
	}
	defer net.close(server)

	set_err := net.set_option(server, .Linger, LINGER_SECONDS * time.Second)
	if !testing.expect_value(t, set_err, nil) {
		return
	}

	held: linux.Linger
	_, get_err := linux.getsockopt_base(linux.Fd(server), int(linux.SOL_SOCKET), .LINGER, &held)
	if !testing.expect_value(t, get_err, linux.Errno.NONE) {
		return
	}

	testing.expect_value(t, held.l_onoff, i32(1))
	testing.expect_value(t, held.l_linger, i32(LINGER_SECONDS))
}
