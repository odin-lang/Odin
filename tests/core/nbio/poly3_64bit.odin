#+build amd64, arm64, riscv64
package tests_nbio

import "core:nbio"
import "core:net"
import "core:testing"
import "core:time"
import "core:log"

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
				// The server cancelled a sendfile that had already put bytes on the wire and
				// then closed, which ends the connection with a reset rather than gracefully
				// often enough that both have to be accepted here.
				if op.recv.err != nil {
					ev(t, op.recv.err, net.TCP_Recv_Error.Connection_Closed)
				}

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
				// The server cancelled a sendfile that had already put bytes on the wire and
				// then closed, which ends the connection with a reset rather than gracefully
				// often enough that both have to be accepted here.
				if op.recv.err != nil {
					ev(t, op.recv.err, net.TCP_Recv_Error.Connection_Closed)
				}

				nbio.close(op.recv.socket.(net.TCP_Socket))
			}
		}

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
