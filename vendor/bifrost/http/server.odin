package bifrost_http

import "core:nbio"
import "core:bytes"
import "core:strings"
import "core:strconv"
import tls "vendor:bifrost/tls"

SERVER_DEFAULT_MAX_HEADER :: 32 * 1024
SERVER_DEFAULT_MAX_BODY   :: 1 * 1024 * 1024

Conn :: struct {
	server: ^Server,
	socket: nbio.TCP_Socket,
	use_tls: bool,
	tls_stream: tls.TLS_Stream,

	recv_tmp: []u8,
	in_buf:   []u8,
	body_buf: bytes.Buffer,

	header_parsed: bool,
	header_end: int,
	body_start: int,
	content_length: int,
	responded: bool,

	req_cache: Request,
}

Server_State :: struct {
	server: ^Server,
}

listen :: proc(server: ^Server, endpoint: nbio.Endpoint, backlog := 1000) -> (socket: nbio.TCP_Socket, err: nbio.Network_Error) {
	if server == nil || server.Handler == nil {
		return 0, nbio.Listen_Error.Invalid_Argument
	}

	if server.Loop == nil {
		server.Loop = nbio.thread_event_loop()
	}
	if server.Max_Header_Bytes <= 0 {
		server.Max_Header_Bytes = SERVER_DEFAULT_MAX_HEADER
	}
	if server.Max_Body_Bytes <= 0 {
		server.Max_Body_Bytes = SERVER_DEFAULT_MAX_BODY
	}

	if server.TLS != nil && server._tls_ctx == nil {
		ctx, ok := tls.context_create(server.TLS, true)
		if !ok {
			return 0, nbio.Listen_Error.Unknown
		}
		server._tls_ctx = ctx
	}

	socket, err = nbio.listen_tcp(endpoint, backlog, l=server.Loop)
	if err != nil {
		return socket, err
	}

	state := new(Server_State)
	state.server = server
	nbio.accept_poly(socket, state, server_on_accept, l=server.Loop)

	return socket, nil
}

server_on_accept :: proc(op: ^nbio.Operation, state: ^Server_State) {
	if state == nil || state.server == nil {
		return
	}
	server := state.server

	if op.accept.err != nil {
		// Keep accepting even if a single accept fails.
		nbio.accept_poly(op.accept.socket, state, server_on_accept, l=server.Loop)
		return
	}

	conn := new(Conn)
	conn.server = server
	conn.socket = op.accept.client
	conn.use_tls = server.TLS != nil
	conn.recv_tmp = make([]u8, 16 * 1024)
	conn.in_buf = make([]u8, 0, 16 * 1024)
	conn.content_length = -1
	bytes.buffer_init_allocator(&conn.body_buf, 0, 16 * 1024)

	if conn.use_tls {
		ok := tls.stream_init(&conn.tls_stream, server.Loop, conn.socket, server._tls_ctx, true)
		if !ok {
			conn_close(conn)
		} else {
			conn.tls_stream.on_handshake = tls_on_handshake
			conn.tls_stream.on_data = tls_on_data
			conn.tls_stream.on_close = tls_on_close
			conn.tls_stream.on_error = tls_on_error
			conn.tls_stream.user = conn
			tls.stream_start(&conn.tls_stream)
		}
	} else {
		conn_recv(conn)
	}

	// Accept next connection.
	nbio.accept_poly(op.accept.socket, state, server_on_accept, l=server.Loop)
}

conn_recv :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	nbio.recv_poly(conn.socket, {conn.recv_tmp}, conn, conn_on_recv, l=conn.server.Loop)
}

conn_on_recv :: proc(op: ^nbio.Operation, conn: ^Conn) {
	if conn == nil {
		return
	}
	if op.recv.err != nil {
		conn_close(conn)
		return
	}
	if op.recv.received == 0 {
		conn_close(conn)
		return
	}

	conn_on_plain_data(conn, conn.recv_tmp[:op.recv.received])
	if !conn.responded {
		conn_recv(conn)
	}
}

conn_on_plain_data :: proc(conn: ^Conn, data: []u8) {
	if conn == nil || len(data) == 0 {
		return
	}
	if conn.responded {
		return
	}
	conn.in_buf = append(conn.in_buf, data...)

	if !conn.header_parsed {
		if len(conn.in_buf) > conn.server.Max_Header_Bytes {
			conn_send_error(conn, 431, "Request Header Fields Too Large")
			return
		}

		idx := find_header_end(conn.in_buf)
		if idx < 0 {
			return
		}

		conn.header_parsed = true
		conn.header_end = idx
		conn.body_start = idx + 4

		if !conn_parse_headers(conn) {
			if conn.content_length == -2 {
				conn_send_error(conn, 413, "Payload Too Large")
			} else {
				conn_send_error(conn, 400, "Bad Request")
			}
			return
		}
	}

	if conn.content_length < 0 {
		conn.content_length = 0
	}

	body_len := len(conn.in_buf) - conn.body_start
	if body_len < conn.content_length {
		return
	}

	conn_dispatch_request(conn)
}

conn_parse_headers :: proc(conn: ^Conn) -> bool {
	if conn == nil {
		return false
	}

	raw := string(conn.in_buf[:conn.body_start])
	lines, _ := strings.split(raw, "\r\n", context.temp_allocator)
	if len(lines) < 1 {
		return false
	}

	parts, _ := strings.split(lines[0], " ", context.temp_allocator)
	if len(parts) < 3 {
		return false
	}

	conn_req := Request{
		Method = parts[0],
		Target = parts[1],
		Proto = parts[2],
		Header = make(Header),
	}

	for i in 1..<len(lines) {
		line := lines[i]
		if len(line) == 0 {
			break
		}
		idx := strings.index_byte(line, ':')
		if idx < 0 {
			continue
		}
		name := strings.trim_space(line[:idx])
		value := strings.trim_space(line[idx+1:])
		header_add(&conn_req.Header, name, value)
	}

	if val, ok := header_get(conn_req.Header, "content-length"); ok {
		if n, ok := strconv.parse_int(val); ok {
			if n < 0 {
				return false
			}
			conn.content_length = n
		} else {
			return false
		}
	}

	// Enforce max body size if configured.
	if conn.server.Max_Body_Bytes > 0 && conn.content_length > int(conn.server.Max_Body_Bytes) {
		conn.content_length = -2
		return false
	}

	conn_req.Body_Len = i64(conn.content_length)
	conn.req_cache = conn_req

	return true
}

conn_dispatch_request :: proc(conn: ^Conn) {
	if conn == nil || conn.server == nil {
		return
	}

	conn.req_cache.Body = conn.in_buf[conn.body_start : conn.body_start+conn.content_length]

	res := ResponseWriter{
		Status = 0,
		Header = make(Header),
		_internal = conn,
	}

	conn.server.Handler(&conn.req_cache, &res)
	if !conn.responded {
		response_end(&res)
	}
}

conn_send_error :: proc(conn: ^Conn, status: int, text: string) {
	res := ResponseWriter{
		Status = status,
		Header = make(Header),
		_internal = conn,
	}
	response_write_string(&res, text)
	response_end(&res)
}

conn_close :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	if conn.use_tls {
		if conn.tls_stream.conn != nil {
			tls.connection_free(conn.tls_stream.conn)
			conn.tls_stream.conn = nil
		}
	} else {
		nbio.close(conn.socket)
	}
	bytes.buffer_destroy(&conn.body_buf)
	delete(conn.recv_tmp)
	delete(conn.in_buf)
	delete(conn)
}

find_header_end :: proc(buf: []u8) -> int {
	if len(buf) < 4 {
		return -1
	}
	for i in 0..<(len(buf)-3) {
		if buf[i] == '\r' && buf[i+1] == '\n' && buf[i+2] == '\r' && buf[i+3] == '\n' {
			return i
		}
	}
	return -1
}

// TLS callbacks

tls_on_handshake :: proc(s: ^tls.TLS_Stream) {
	if s == nil {
		return
	}
	conn := (^Conn)(s.user)
	if conn == nil {
		return
	}
}

tls_on_data :: proc(s: ^tls.TLS_Stream, data: []u8) {
	if s == nil {
		return
	}
	conn := (^Conn)(s.user)
	if conn == nil {
		return
	}
	conn_on_plain_data(conn, data)
}

tls_on_close :: proc(s: ^tls.TLS_Stream) {
	if s == nil {
		return
	}
	conn := (^Conn)(s.user)
	if conn == nil {
		return
	}
	conn_close(conn)
}

tls_on_error :: proc(s: ^tls.TLS_Stream, status: tls.TLS_Status, message: string) {
	if s == nil {
		return
	}
	conn := (^Conn)(s.user)
	if conn == nil {
		return
	}
	_ = status
	_ = message
	conn_close(conn)
}
