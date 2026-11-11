package tests_nbio

import "core:nbio"
import "core:testing"
import "core:time"
import "core:log"

// Removals are pretty complex.

// Open should free the temporary memory allocated for the path when removed.
// Can't really test that though, so should be checked manually that the internal callback is called but not the external.
@(test)
remove_open :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		open := nbio.open(#file, on_open)
		nbio.remove(open)

		on_open :: proc(op: ^nbio.Operation) {
			log.error("on_open shouldn't be called")
		}

		ev(t, nbio.run(), nil)
	}
}

// Dial should close the socket when removed.
// Can't really test that though, so should be checked manually that the internal callback is called but not the external.
@(test)
remove_dial :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		sock, ep := open_next_available_local_port(t)
		defer nbio.close(sock)

		dial := nbio.dial(ep, on_dial)
		nbio.remove(dial)

		on_dial :: proc(op: ^nbio.Operation) {
			log.error("on_dial shouldn't be called")
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
remove_next_tick :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		nt := nbio.next_tick_poly(t, proc(op: ^nbio.Operation, t: ^testing.T) {
			log.error("shouldn't be called")
		})
		nbio.remove(nt)

		ev(t, nbio.run(), nil)
	}
}

@(test)
remove_timeout :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		hit: bool
		timeout := nbio.timeout_poly(time.Second, &hit, proc(_: ^nbio.Operation, hit: ^bool) {
			hit^ = true
		})

		nbio.remove(timeout)

		ev(t, nbio.run(), nil)

		e(t, !hit)
	}
}

@(test)
remove_multiple_poll :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		// Two sockets rather than two polls on one socket: only one poll per socket is
		// delivered on Windows, and what this tests is removal, not that.
		removed_sock, removed_ep := open_next_available_local_port(t)
		defer nbio.close(removed_sock)

		kept_sock, kept_ep := open_next_available_local_port(t)
		defer nbio.close(kept_sock)

		hit: bool

		first := nbio.poll(removed_sock, .Receive, on_poll)
		nbio.poll_poly2(kept_sock, .Receive, t, &hit, on_poll2)

		on_poll :: proc(op: ^nbio.Operation) {
			log.error("shouldn't be called")
		}

		on_poll2 :: proc(op: ^nbio.Operation, t: ^testing.T, hit: ^bool) {
			ev(t, op.poll.result, nbio.Poll_Result.Ready)
			hit^ = true
		}

		ev(t, nbio.tick(0), nil)

		nbio.remove(first)

		ev(t, nbio.tick(0), nil)

		// Make both readable, the removed poll must still not fire.
		nbio.dial_poly(removed_ep, t, on_dial)
		nbio.dial_poly(kept_ep, t, on_dial)

		on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.dial.err, nil)
		}

		ev(t, nbio.run(), nil)
		e(t, hit)
	}
}
