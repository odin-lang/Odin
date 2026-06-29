package tests_nbio

import "core:nbio"
import "core:net"
import "core:testing"
import "core:time"
import "core:log"

// Removals are pretty complex.

@(test)
immediate_remove_of_sendfile :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		sock, ep := open_next_available_local_port(t)

		// Server
		{
			nbio.accept_poly(sock, t, on_accept)

			on_accept :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.accept.err, nil)
				e(t, op.accept.client != 0)

				log.debugf("connection from: %v", op.accept.client_endpoint)
				nbio.open_poly3(#file, t, op.accept.socket, op.accept.client, on_open)
			}

			on_open :: proc(op: ^nbio.Operation, t: ^testing.T, server, client: net.TCP_Socket) {
				ev(t, op.open.err, nil)
				e(t, op.open.handle != 0)

				sendfile_op := nbio.sendfile_poly2(client, op.open.handle, t, server, on_sendfile)

				// oh no changed my mind.
				nbio.remove(sendfile_op)

				nbio.close(op.open.handle)
				nbio.close(client)
				nbio.close(server)
			}

			on_sendfile :: proc(op: ^nbio.Operation, t: ^testing.T, server: net.TCP_Socket) {
				log.error("on_sendfile shouldn't be called")
			}
		}

		// Client
		{
			nbio.dial_poly(ep, t, on_dial)

			on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.dial.err, nil)

				buf := make([]byte, 128, context.temp_allocator)
				nbio.recv_poly(op.dial.socket, {buf}, t, on_recv)
			}

			on_recv :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.recv.err, nil) 

				nbio.close(op.recv.socket.(net.TCP_Socket))
			}
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
immediate_remove_of_sendfile_without_stat :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		sock, ep := open_next_available_local_port(t)

		// Server
		{
			nbio.accept_poly(sock, t, on_accept)

			on_accept :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.accept.err, nil)
				e(t, op.accept.client != 0)

				log.debugf("connection from: %v", op.accept.client_endpoint)
				nbio.open_poly3(#file, t, op.accept.socket, op.accept.client, on_open)
			}

			on_open :: proc(op: ^nbio.Operation, t: ^testing.T, server, client: net.TCP_Socket) {
				ev(t, op.open.err, nil)
				e(t, op.open.handle != 0)

				nbio.stat_poly3(op.open.handle, t, server, client, on_stat)
			}

			on_stat :: proc(op: ^nbio.Operation, t: ^testing.T, server, client: net.TCP_Socket) {
				ev(t, op.stat.err, nil)

				sendfile_op := nbio.sendfile_poly2(client, op.stat.handle, t, server, on_sendfile, nbytes=int(op.stat.size))

				// oh no changed my mind.
				nbio.remove(sendfile_op)

				nbio.timeout_poly3(time.Millisecond * 10, op.stat.handle, client, server, proc(op: ^nbio.Operation, p1: nbio.Handle, p2, p3: net.TCP_Socket){
					nbio.close(p1)
					nbio.close(p2)
					nbio.close(p3)
				})
			}

			on_sendfile :: proc(op: ^nbio.Operation, t: ^testing.T, server: net.TCP_Socket) {
				log.error("on_sendfile shouldn't be called")
			}
		}

		// Client
		{
			nbio.dial_poly(ep, t, on_dial)

			on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.dial.err, nil)

				buf := make([]byte, 128, context.temp_allocator)
				nbio.recv_poly(op.dial.socket, {buf}, t, on_recv)
			}

			on_recv :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.recv.err, nil) 

				nbio.close(op.recv.socket.(net.TCP_Socket))
			}
		}

		ev(t, nbio.run(), nil)
	}
}

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

		sock, ep := open_next_available_local_port(t)
		defer nbio.close(sock)

		hit: bool

		first := nbio.poll(sock, .Receive, on_poll)
		nbio.poll_poly2(sock, .Receive, t, &hit, on_poll2)

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

		nbio.dial_poly(ep, t, on_dial)

		on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.dial.err, nil)
		}

		ev(t, nbio.run(), nil)
		e(t, hit)
	}
}
