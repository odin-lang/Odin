package tests_nbio

import "core:mem"
import "core:nbio"
import "core:net"
import "core:testing"
import "core:time"
import "core:log"

open_next_available_local_port :: proc(t: ^testing.T, addr: net.Address = net.IP4_Loopback, loc := #caller_location) -> (sock: net.TCP_Socket, ep: net.Endpoint) {
	err: net.Network_Error
	sock, err = nbio.listen_tcp({addr, 0})
	if err != nil {
		log.errorf("listen_tcp: %v", err, location=loc)
		return
	}

	ep, err = net.bound_endpoint(sock)
	if err != nil {
		log.errorf("bound_endpoint: %v", err, location=loc)
	}

	return
}

@(test)
client_and_server_send_recv :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, ep := open_next_available_local_port(t)

		CONTENT :: [20]byte{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}

		State :: struct {
			server:        net.TCP_Socket,
			server_client: net.TCP_Socket,
			client:        net.TCP_Socket,
			recv_buf:      [20]byte,
			send_buf:      [20]byte,
		}

		state := State{
			server   = server,
			send_buf = CONTENT,
		}

		close_ok :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.close.err, nil)
		}

		// Server
		{
			nbio.accept_poly2(server, t, &state, on_accept)

			on_accept :: proc(op: ^nbio.Operation, t: ^testing.T, state: ^State) {
				ev(t, op.accept.err, nil)

				state.server_client = op.accept.client

				log.debugf("accepted connection from: %v", op.accept.client_endpoint)

				nbio.recv_poly2(state.server_client, {state.recv_buf[:]}, t, state, on_recv)
			}

			on_recv :: proc(op: ^nbio.Operation, t: ^testing.T, state: ^State) {
				ev(t, op.recv.err, nil)
				ev(t, op.recv.received, 20)
				ev(t, state.recv_buf, CONTENT)

				nbio.close_poly(state.server_client, t, close_ok)
				nbio.close_poly(state.server, t, close_ok)
			}

			ev(t, nbio.tick(0), nil)
		}

		// Client
		{
			nbio.dial_poly2(ep, t, &state, on_dial)

			on_dial :: proc(op: ^nbio.Operation, t: ^testing.T, state: ^State) {
				ev(t, op.dial.err, nil)

				state.client = op.dial.socket

				nbio.send_poly2(state.client, {state.send_buf[:]}, t, state, on_send)
			}

			on_send :: proc(op: ^nbio.Operation, t: ^testing.T, state: ^State) {
				ev(t, op.send.err, nil)
				ev(t, op.send.sent, 20)

				nbio.close_poly(state.client, t, close_ok)
			}
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
close_and_remove_accept :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, _ := open_next_available_local_port(t)

		accept := nbio.accept_poly(server, t, proc(_: ^nbio.Operation, t: ^testing.T) {
			testing.fail_now(t)
		})

		ev(t, nbio.tick(0), nil)

		nbio.close_poly(server, t, proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.close.err, nil)
		})

		nbio.remove(accept)
		ev(t, nbio.run(), nil)
	}
}

// Tests that when a client calls `close` on it's socket, `recv` returns with `0, nil` (connection closed).
@(test)
close_errors_recv :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, ep := open_next_available_local_port(t)

		// Server
		{
			nbio.accept_poly(server, t, on_accept)

			on_accept :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.accept.err, nil)

				bytes := make([]byte, 128, context.temp_allocator)
				nbio.recv_poly(op.accept.client, {bytes}, t, on_recv)
			}

			on_recv :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.recv.received, 0)
				ev(t, op.recv.err, nil)
			}

			ev(t, nbio.tick(0), nil)
		}

		// Client
		{
			nbio.dial_poly(ep, t, on_dial)

			on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.dial.err, nil)
				nbio.close_poly(op.dial.socket, t, on_close)
			}

			on_close :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.close.err, nil)
			}
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
ipv6 :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, ep := open_next_available_local_port(t, net.IP6_Loopback)

		nbio.accept_poly(server, t, on_accept)
		on_accept :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.accept.err, nil)
			addr, is_ipv6 := op.accept.client_endpoint.address.(net.IP6_Address)
			e(t, is_ipv6)
			ev(t, addr, net.IP6_Loopback)
			e(t, op.accept.client_endpoint.port != 0)
			nbio.close(op.accept.client)
			nbio.close(op.accept.socket)
		}

		nbio.dial_poly(ep, t, on_dial)
		on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.dial.err, nil)
			nbio.close(op.dial.socket)
		}

		ev(t, nbio.run(), nil)
	}
}

@(test)
accept_timeout :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		sock, _ := open_next_available_local_port(t)

		hit: bool
		nbio.accept_poly2(sock, t, &hit, on_accept, timeout=time.Millisecond)

		on_accept :: proc(op: ^nbio.Operation, t: ^testing.T, hit: ^bool) {
			hit^ = true
			ev(t, op.accept.err, net.Accept_Error.Timeout)
			nbio.close(op.accept.socket)
		}

		ev(t, nbio.run(), nil)

		e(t, hit)
	}
}

@(test)
poll_timeout :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		sock, err := nbio.create_udp_socket(.IP4)
		ev(t, err, nil)
		berr := nbio.bind(sock, {nbio.IP4_Loopback, 0})
		ev(t, berr, nil)

		nbio.poll_poly(sock, .Receive, t, on_poll, time.Millisecond)
		on_poll :: proc(op: ^nbio.Operation, t: ^testing.T) {
			ev(t, op.poll.result, nbio.Poll_Result.Timeout)
		}

		ev(t, nbio.run(), nil)
	}
}

/*
This test walks through the scenario where a user wants to `poll` in order to check if some other package (in this case `core:net`),
would be able to do an operation without blocking.

It also tests whether a poll can be issues when it is already in a ready state.
And it tests big send/recv buffers being handled properly.
*/
@(test)
poll :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
//		testing.set_fail_timeout(t, time.Minute)

		can_recv: bool

		sock, ep := open_next_available_local_port(t)

		// Server
		{
			nbio.accept_poly2(sock, t, &can_recv, on_accept)

			on_accept :: proc(op: ^nbio.Operation, t: ^testing.T, can_recv: ^bool) {
				ev(t, op.accept.err, nil)

				check_recv :: proc(op: ^nbio.Operation, t: ^testing.T, can_recv: ^bool, client: net.TCP_Socket) {
					// Not ready to unblock the client yet, requeue for after 10ms.
					if !can_recv^ {
						nbio.timeout_poly3(time.Millisecond * 10, t, can_recv, client, check_recv)
						return
					}

					free_all(context.temp_allocator)

					// Connection was closed by client, close server.
					if op.type == .Recv && op.recv.received == 0 && op.recv.err == nil {
						nbio.close(client)
						return
					}

					if op.type == .Recv {
						log.debugf("received %M this time", op.recv.received)
					}

					// Receive some data to unblock the client, which should complete the poll it does, allowing it to send data again.
					buf, mem_err := make([]byte, mem.Gigabyte, context.temp_allocator)
					ev(t, mem_err, nil)
					nbio.recv_poly3(client, {buf}, t, can_recv, client, check_recv)
				}
				nbio.timeout_poly3(time.Millisecond * 10, t, can_recv, op.accept.client, check_recv)
			}

			ev(t, nbio.tick(0), nil)
		}

		// Client
		{
			nbio.dial_poly2(ep, t, &can_recv, on_dial)

			on_dial :: proc(op: ^nbio.Operation, t: ^testing.T, can_recv: ^bool) {
				ev(t, op.dial.err, nil)

				// Do a poll even though we know it's ready, so we can test that all implementations can handle that.
				nbio.poll_poly2(op.dial.socket, .Send, t, can_recv, on_poll1)
			}

			on_poll1 :: proc(op: ^nbio.Operation, t: ^testing.T, can_recv: ^bool) {
				ev(t, op.poll.result, nil)

				// Send 4 GB of data, which in my experience causes a Would_Block error because we filled up the internal buffer.
				buf, mem_err := make([]byte, mem.Gigabyte*4, context.temp_allocator)
				ev(t, mem_err, nil)

				// Use `core:net` as example external code that doesn't care about the event loop.
				net.set_blocking(op.poll.socket, false)
				n, send_err := net.send(op.poll.socket, buf)
				ev(t, send_err, net.TCP_Send_Error.Would_Block)

				log.debugf("blocking after %M", n)

				// Tell the server it can start issueing recv calls, so it unblocks us.
				can_recv^ = true

				// Now poll again, when the server reads enough data it should complete, telling us we can send without blocking again.
				nbio.poll_poly(op.poll.socket, .Send, t, on_poll2)
			}

			on_poll2 :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.poll.result, nil)

				buf: [128]byte
				bytes_written, send_err := net.send(op.poll.socket, buf[:])
				ev(t, bytes_written, 128)
				ev(t, send_err, nil)

				nbio.close(op.poll.socket.(net.TCP_Socket))
			}
		}

		ev(t, nbio.run(), nil)
		nbio.close(sock)
		ev(t, nbio.run(), nil)
	}
}

@(test)
sendfile :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		CONTENT :: #load(#file)

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

				nbio.sendfile_poly2(client, op.open.handle, t, server, on_sendfile)
			}

			on_sendfile :: proc(op: ^nbio.Operation, t: ^testing.T, server: net.TCP_Socket) {
				ev(t, op.sendfile.err, nil)
				ev(t, op.sendfile.sent, len(CONTENT))

				nbio.close(op.sendfile.file)
				nbio.close(op.sendfile.socket)
				nbio.close(server)
			}
		}

		// Client
		{
			nbio.dial_poly(ep, t, on_dial)

			on_dial :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.dial.err, nil)

				buf := make([]byte, len(CONTENT), context.temp_allocator)
				nbio.recv_poly(op.dial.socket, {buf}, t, on_recv, all=true)
			}

			on_recv :: proc(op: ^nbio.Operation, t: ^testing.T) {
				ev(t, op.recv.err, nil)
				ev(t, op.recv.received, len(CONTENT))
				ev(t, string(op.recv.bufs[0]), string(CONTENT))

				nbio.close(op.recv.socket.(net.TCP_Socket))
			}
		}

		ev(t, nbio.run(), nil)
	}
}
