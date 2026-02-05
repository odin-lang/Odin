package bifrost_tls

import "core:nbio"

TLS_Stream_On_Handshake :: proc(s: ^TLS_Stream)
TLS_Stream_On_Data :: proc(s: ^TLS_Stream, data: []u8)
TLS_Stream_On_Close :: proc(s: ^TLS_Stream)
TLS_Stream_On_Error :: proc(s: ^TLS_Stream, status: TLS_Status, message: string)

TLS_Stream :: struct {
	loop:   ^nbio.Event_Loop,
	socket: nbio.TCP_Socket,
	conn:   ^Connection,

	recv_buf: []u8,
	app_buf:  []u8,
	send_buf: []u8,
	out_chunk: int,
	send_in_flight: bool,

	handshake_notified: bool,

	on_handshake: TLS_Stream_On_Handshake,
	on_data:      TLS_Stream_On_Data,
	on_close:     TLS_Stream_On_Close,
	on_error:     TLS_Stream_On_Error,

	user: rawptr,
}

TLS_DEFAULT_RECV_BUF :: 16 * 1024
TLS_DEFAULT_APP_BUF  :: 16 * 1024
TLS_DEFAULT_OUT_CHUNK :: 16 * 1024

stream_init :: proc(
	s: ^TLS_Stream,
	loop: ^nbio.Event_Loop,
	socket: nbio.TCP_Socket,
	ctx: ^Context,
	is_server: bool,
	server_name: string = "",
	recv_buf_size := TLS_DEFAULT_RECV_BUF,
	app_buf_size := TLS_DEFAULT_APP_BUF,
	out_chunk_size := TLS_DEFAULT_OUT_CHUNK,
) -> bool {
	if s == nil {
		return false
	}
	conn, ok := connection_create(ctx, is_server, server_name)
	if !ok {
		return false
	}

	s.loop = loop
	s.socket = socket
	s.conn = conn
	s.recv_buf = make([]u8, recv_buf_size)
	s.app_buf = make([]u8, app_buf_size)
	if out_chunk_size <= 0 {
		out_chunk_size = TLS_DEFAULT_OUT_CHUNK
	}
	s.send_buf = make([]u8, out_chunk_size)
	s.out_chunk = out_chunk_size
	s.send_in_flight = false
	s.handshake_notified = false

	return true
}

stream_start :: proc(s: ^TLS_Stream) {
	if s == nil {
		return
	}
	stream_drive(s)
	stream_recv(s)
}

stream_write :: proc(s: ^TLS_Stream, data: []u8) -> (n: int, status: TLS_Status) {
	if s == nil || s.conn == nil {
		return 0, .Error
	}

	n, status = write_app(s.conn, data)
	stream_flush_outgoing(s)
	return n, status
}

stream_close :: proc(s: ^TLS_Stream) {
	if s == nil || s.conn == nil {
		return
	}
	_ = shutdown(s.conn)
	stream_flush_outgoing(s)
	nbio.close(s.socket)
}

stream_recv :: proc(s: ^TLS_Stream) {
	if s == nil {
		return
	}
	nbio.recv_poly(s.socket, {s.recv_buf}, s, stream_on_recv, l=s.loop)
}

stream_on_recv :: proc(op: ^nbio.Operation, s: ^TLS_Stream) {
	if s == nil {
		return
	}
	if op.recv.err != nil {
		stream_error(s, .Error)
		return
	}
	if op.recv.received == 0 {
		stream_close_notify(s)
		return
	}

	data := s.recv_buf[:op.recv.received]
	if !feed_incoming(s.conn, data) {
		stream_error(s, .Error)
		return
	}

	stream_drive(s)
	stream_recv(s)
}

stream_drive :: proc(s: ^TLS_Stream) {
	if s == nil || s.conn == nil {
		return
	}

	for {
		if !s.conn.handshake_done {
			status := handshake(s.conn)
			stream_flush_outgoing(s)

			switch status {
			case .Ok:
				if !s.handshake_notified {
					s.handshake_notified = true
					if s.on_handshake != nil {
						s.on_handshake(s)
					}
				}
				continue
			case .Want_Read, .Want_Write:
				return
			case .Closed:
				stream_close_notify(s)
				return
			case .Error:
				stream_error(s, status)
				return
			}
		}

		read_n, read_status := read_app(s.conn, s.app_buf)
		stream_flush_outgoing(s)

		if read_status == .Ok && read_n > 0 {
			if s.on_data != nil {
				s.on_data(s, s.app_buf[:read_n])
			}
			continue
		}

		switch read_status {
		case .Ok, .Want_Read, .Want_Write:
			return
		case .Closed:
			stream_close_notify(s)
			return
		case .Error:
			stream_error(s, read_status)
			return
		}
	}
}

stream_flush_outgoing :: proc(s: ^TLS_Stream) {
	if s == nil || s.conn == nil {
		return
	}

	for {
		if s.send_in_flight {
			return
		}
		pending := pending_outgoing(s.conn)
		if pending <= 0 {
			return
		}

		chunk := pending
		if s.out_chunk > 0 && chunk > s.out_chunk {
			chunk = s.out_chunk
		}
		if len(s.send_buf) < chunk {
			return
		}

		read_n := read_outgoing(s.conn, s.send_buf[:chunk])
		if read_n <= 0 {
			return
		}

		s.send_in_flight = true
		nbio.send_poly(s.socket, {s.send_buf[:read_n]}, s, stream_on_send_done, l=s.loop)
	}
}

stream_on_send_done :: proc(op: ^nbio.Operation, s: ^TLS_Stream) {
	if s == nil {
		return
	}
	s.send_in_flight = false
	if op.send.err != nil {
		stream_error(s, .Error)
		return
	}
	stream_flush_outgoing(s)
}

stream_error :: proc(s: ^TLS_Stream, status: TLS_Status) {
	if s == nil {
		return
	}
	if s.on_error != nil {
		buf := make([]u8, 256)
		msg := last_error_string(buf)
		delete(buf)
		s.on_error(s, status, msg)
	}
}

stream_close_notify :: proc(s: ^TLS_Stream) {
	if s == nil {
		return
	}
	if s.on_close != nil {
		s.on_close(s)
	}
}
