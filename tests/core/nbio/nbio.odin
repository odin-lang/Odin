package tests_nbio

import "core:log"
import "core:nbio"
import "core:testing"
import "core:thread"
import "core:time"
import "core:os"

ev :: testing.expect_value
e  :: testing.expect

@(deferred_in=event_loop_guard_exit)
event_loop_guard :: proc(t: ^testing.T) -> bool {
	err := nbio.acquire_thread_event_loop()
	if err == .Unsupported || !nbio.FULLY_SUPPORTED {
		log.warn("nbio unsupported, skipping")
		return false
	}

	ev(t, err, nil)
	return true
}

event_loop_guard_exit :: proc(t: ^testing.T) {
	ev(t, nbio.run(), nil) // Could have some things to clean up from a `defer` in the test.
	nbio.release_thread_event_loop()
}

// Tests that all poly variants are correctly passing through arguments, and that
// all procs eventually get their callback called.
//
// This is important because the poly procs are only checked when they are called,
// So this will also catch any typos in their implementations.
@(test)
all_poly_work :: proc(tt: ^testing.T) {
	if event_loop_guard(tt) {
		testing.set_fail_timeout(tt, time.Minute)

		@static t: ^testing.T
		t = tt

		@static n: int
		n = 0
		NUM_TESTS :: 39

		UDP_SOCKET :: max(nbio.UDP_Socket)
		TCP_SOCKET :: max(nbio.TCP_Socket)

		tmp, terr := os.create_temp_file("", "tests_nbio_poly*", {.Non_Blocking})
		ev(t, terr, nil)
		defer os.close(tmp)

		HANDLE, aerr := nbio.associate_handle(os.fd(tmp))
		ev(t, aerr, nil)

		_buf: [1]byte
		buf := _buf[:]

		one :: proc(op: ^nbio.Operation, one: int) {
			n += 1
			ev(t, one, 1)
		}

		two :: proc(op: ^nbio.Operation, one: int, two: int) {
			n += 1
			ev(t, one, 1)
			ev(t, two, 2)
		}

		three :: proc(op: ^nbio.Operation, one: int, two: int, three: int) {
			n += 1
			ev(t, one, 1)
			ev(t, two, 2)
			ev(t, three, 3)
		}

		nbio.accept_poly(TCP_SOCKET, 1, one)
		nbio.accept_poly2(TCP_SOCKET, 1, 2, two)
		nbio.accept_poly3(TCP_SOCKET, 1, 2, 3, three)

		nbio.close_poly(max(nbio.Handle), 1, one)
		nbio.close_poly2(max(nbio.Handle), 1, 2, two)
		nbio.close_poly3(max(nbio.Handle), 1, 2, 3, three)

		nbio.dial_poly({nbio.IP4_Address{127, 0, 0, 1}, 0}, 1, one)
		nbio.dial_poly2({nbio.IP4_Address{127, 0, 0, 1}, 0}, 1, 2, two)
		nbio.dial_poly3({nbio.IP4_Address{127, 0, 0, 1}, 0}, 1, 2, 3, three)

		nbio.recv_poly(TCP_SOCKET, {buf}, 1, one)
		nbio.recv_poly2(TCP_SOCKET, {buf}, 1, 2, two)
		nbio.recv_poly3(TCP_SOCKET, {buf}, 1, 2, 3, three)

		nbio.send_poly(TCP_SOCKET, {buf}, 1, one)
		nbio.send_poly2(TCP_SOCKET, {buf}, 1, 2, two)
		nbio.send_poly3(TCP_SOCKET, {buf}, 1, 2, 3, three)

		nbio.sendfile_poly(TCP_SOCKET, HANDLE, 1, one)
		nbio.sendfile_poly2(TCP_SOCKET, HANDLE, 1, 2, two)
		nbio.sendfile_poly3(TCP_SOCKET, HANDLE, 1, 2, 3, three)

		nbio.read_poly(HANDLE, 0, buf, 1, one)
		nbio.read_poly2(HANDLE, 0, buf, 1, 2, two)
		nbio.read_poly3(HANDLE, 0, buf, 1, 2, 3, three)

		nbio.write_poly(HANDLE, 0, buf, 1, one)
		nbio.write_poly2(HANDLE, 0, buf, 1, 2, two)
		nbio.write_poly3(HANDLE, 0, buf, 1, 2, 3, three)

		nbio.next_tick_poly(1, one)
		nbio.next_tick_poly2(1, 2, two)
		nbio.next_tick_poly3(1, 2, 3, three)

		nbio.timeout_poly(1, 1, one)
		nbio.timeout_poly2(1, 1, 2, two)
		nbio.timeout_poly3(1, 1, 2, 3, three)

		nbio.poll_poly(TCP_SOCKET, .Receive, 1, one)
		nbio.poll_poly2(TCP_SOCKET, .Receive, 1, 2, two)
		nbio.poll_poly3(TCP_SOCKET, .Receive, 1, 2, 3, three)

		nbio.open_poly("", 1, one)
		nbio.open_poly2("", 1, 2, two)
		nbio.open_poly3("", 1, 2, 3, three)

		nbio.stat_poly(HANDLE, 1, one)
		nbio.stat_poly2(HANDLE, 1, 2, two)
		nbio.stat_poly3(HANDLE, 1, 2, 3, three)

		ev(t, n, 0) // Test that no callbacks are ran before the loop is ticked.
		ev(t, nbio.run(), nil)
		ev(t, n, NUM_TESTS) // Test that all callbacks have ran.
	}
}

@(test)
two_ops_at_the_same_time :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, err := nbio.create_udp_socket(.IP4)
		ev(t, err, nil)
		defer nbio.close(server)

		berr := nbio.bind(server, {nbio.IP4_Loopback, 0})
		ev(t, berr, nil)
		ep, eperr := nbio.bound_endpoint(server)
		ev(t, eperr, nil)

		// Server.
		{
			nbio.poll_poly(server, .Receive, t, on_poll)

			on_poll :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.poll.result, nbio.Poll_Result.Ready)
			}

			buf: [128]byte
			nbio.recv_poly(server, {buf[:]}, t, on_recv)

			on_recv :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.recv.err, nil)
			}
		}

		// Client.
		{
			sock, cerr := nbio.create_udp_socket(.IP4)
			ev(t, cerr, nil)

			// Make sure the server would block.
			nbio.timeout_poly3(time.Millisecond*10, t, sock, ep.port, on_timeout)

			on_timeout :: proc(op: ^nbio.Operation, t: ^testing.T, sock: nbio.UDP_Socket, port: int) {
				nbio.send_poly(sock, {transmute([]byte)string("Hiya")}, t, on_send, {nbio.IP4_Loopback, port})
			}

			on_send :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.send.err, nil)
				ev(t, op.send.sent, 4)

				// Do another send after a bit, some backends don't trigger both ops when one was enough to
				// use up the socket.
				nbio.timeout_poly3(time.Millisecond*10, t, op.send.socket.(nbio.UDP_Socket), op.send.endpoint.port, on_timeout2)
			}

			on_timeout2 :: proc(op: ^nbio.Operation, t: ^testing.T, sock: nbio.UDP_Socket, port: int) {
				nbio.send_poly(sock, {transmute([]byte)string("Hiya")}, t, on_send2, {nbio.IP4_Loopback, port})
			}

			on_send2 :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.send.err, nil)
				ev(t, op.send.sent, 4)

				nbio.close(op.send.socket.(nbio.UDP_Socket))
			}
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
timeout :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		start := time.now()

		nbio.timeout_poly2(time.Millisecond*20, t, start, on_timeout)

		on_timeout :: proc(op: ^nbio.Operation, t: ^testing.T, start: time.Time) {
			since := time.since(start)
			log.infof("timeout ran after: %v", since)
			testing.expect(t, since >= time.Millisecond*19) // A ms grace, for some reason it is sometimes ran after 19.8ms.
			if since < 20 {
				log.warnf("timeout ran after: %v", since)
			}
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
wake_up :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, time.Minute)
	if event_loop_guard(t) {
		for _ in 0..<2 {
			sock, _ := open_next_available_local_port(t)

			// Add an accept, with nobody dialling this should block the event loop forever.
			accept := nbio.accept(sock, proc(op: ^nbio.Operation) {
				log.error("shouldn't be called")
			})

			// Make sure the accept is in progress.
			ev(t, nbio.tick(timeout=0), nil)

			hit: bool
			thr := thread.create_and_start_with_poly_data2(nbio.current_thread_event_loop(), &hit, proc(l: ^nbio.Event_Loop, hit: ^bool) {
				hit^ = true
				nbio.wake_up(l)
			}, context)
			defer thread.destroy(thr)

			// Should block forever until the thread calling wake_up will make it return.
			ev(t, nbio.tick(), nil)
			e(t, hit)

			nbio.remove(accept)
			nbio.close(sock)

			ev(t, nbio.run(), nil)
			ev(t, nbio.tick(timeout=0), nil)
		}
	}
}

// Tests that if multiple accepts are queued, and a dial comes in which completes one of them,
// the rest are queued again properly.
@(test)
still_pending :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		sock, ep := open_next_available_local_port(t)
		defer nbio.close(sock)

		N :: 3

		State :: struct {
			accepted: int,
		}
		state: State

		on_accept :: proc(op: ^nbio.Operation, t: ^testing.T, state: ^State) {
			ev(t, op.accept.err, nil)
			state.accepted += 1
			nbio.close(op.accept.client)
		}

		on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.dial.err, nil)
			nbio.close(op.dial.socket)
		}

		for _ in 0..<N {
			nbio.accept_poly2(sock, t, &state, on_accept)
		}

		nbio.dial_poly(ep, t, on_dial)

		for state.accepted < 1 {
			ev(t, nbio.tick(), nil)
		}

		for _ in 0..<N-1 {
			nbio.dial_poly(ep, t, on_dial)
		}

		ev(t, nbio.run(), nil)
		ev(t, state.accepted, N)
 	}
 }
