package bifrost_http

import "core:nbio"
import "core:bytes"
import "core:strings"
import "core:strconv"
import tls "vendor:bifrost/tls"

SERVER_DEFAULT_MAX_HEADER :: 32 * 1024
SERVER_DEFAULT_MAX_BODY   :: 1 * 1024 * 1024

Chunk_State :: enum {
	Size,
	Data,
	Trailer,
}

Conn :: struct {
	server: ^Server,
	socket: nbio.TCP_Socket,
	use_tls: bool,
	tls_stream: tls.TLS_Stream,

	recv_tmp: []u8,
	in_buf:   []u8,
	req_body: bytes.Buffer,
	body_buf: bytes.Buffer,

	header_parsed: bool,
	header_end: int,
	body_start: int,
	parse_pos: int,
	content_length: int,
	chunked: bool,
	chunk_state: Chunk_State,
	chunk_size: int,
	chunk_total: int,
	keep_alive: bool,
	http10: bool,
	close_after_response: bool,
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
	conn.chunk_state = .Size
	conn.keep_alive = false
	conn.http10 = false
	conn.close_after_response = false
	bytes.buffer_init_allocator(&conn.req_body, 0, 16 * 1024)
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
	conn.in_buf = append(conn.in_buf, data...)
	if conn.responded {
		return
	}

	conn_process_buffer(conn)
}

conn_process_buffer :: proc(conn: ^Conn) {
	if conn == nil || conn.responded {
		return
	}

	for {
		if !conn.header_parsed {
			idx := find_header_end(conn.in_buf)
			if idx < 0 {
				if len(conn.in_buf) > conn.server.Max_Header_Bytes {
					conn_send_error(conn, 431, "Request Header Fields Too Large")
				}
				return
			}
			if idx+4 > conn.server.Max_Header_Bytes {
				conn_send_error(conn, 431, "Request Header Fields Too Large")
				return
			}

			conn.header_parsed = true
			conn.header_end = idx
			conn.body_start = idx + 4
			conn.parse_pos = conn.body_start

			status, text := conn_parse_headers(conn)
			if status != 0 {
				conn_send_error(conn, status, text)
				return
			}
			if conn.chunked {
				bytes.buffer_reset(&conn.req_body)
				conn.chunk_total = 0
				conn.chunk_state = .Size
			}
		}

		if conn.chunked {
			done, status := conn_parse_chunked_body(conn)
			if status != 0 {
				if status == 413 {
					conn_send_error(conn, status, "Payload Too Large")
				} else {
					conn_send_error(conn, status, "Bad Request")
				}
				return
			}
			if !done {
				return
			}
			conn.req_cache.Body = bytes.buffer_to_bytes(&conn.req_body)
			conn.req_cache.Body_Len = i64(len(conn.req_cache.Body))
			conn_consume(conn, conn.parse_pos)
			conn_dispatch_request(conn)
			return
		}

		if conn.content_length < 0 {
			conn.content_length = 0
		}

		body_len := len(conn.in_buf) - conn.body_start
		if body_len < conn.content_length {
			return
		}

		bytes.buffer_reset(&conn.req_body)
		if conn.content_length > 0 {
			_, _ = bytes.buffer_write(&conn.req_body, conn.in_buf[conn.body_start:conn.body_start+conn.content_length])
		}
		conn.req_cache.Body = bytes.buffer_to_bytes(&conn.req_body)
		conn.req_cache.Body_Len = i64(len(conn.req_cache.Body))
		conn_consume(conn, conn.body_start+conn.content_length)

		conn_dispatch_request(conn)
		return
	}
}

conn_parse_headers :: proc(conn: ^Conn) -> (status: int, text: string) {
	if conn == nil {
		return 400, "Bad Request"
	}

	raw := string(conn.in_buf[:conn.body_start])
	lines, _ := strings.split(raw, "\r\n", context.temp_allocator)
	if len(lines) < 1 {
		return 400, "Bad Request"
	}

	parts, _ := strings.split(lines[0], " ", context.temp_allocator)
	if len(parts) < 3 {
		return 400, "Bad Request"
	}

	proto := parts[2]
	if strings.equal_fold(proto, "HTTP/1.0") {
		conn.http10 = true
	} else if strings.equal_fold(proto, "HTTP/1.1") {
		conn.http10 = false
	} else {
		return 505, "HTTP Version Not Supported"
	}

	conn_req := Request{
		Method = parts[0],
		Target = parts[1],
		Proto = proto,
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
				return 400, "Bad Request"
			}
			conn.content_length = n
		} else {
			return 400, "Bad Request"
		}
	}

	conn.chunked = false
	if vals, ok := conn_req.Header[header_key("transfer-encoding")]; ok {
		has_chunked := false
		unsupported := false
		for v in vals {
			parts, _ := strings.split(v, ",", context.temp_allocator)
			for p in parts {
				token := strings.trim_space(p)
				if len(token) == 0 {
					continue
				}
				if strings.equal_fold(token, "chunked") {
					has_chunked = true
					continue
				}
				if strings.equal_fold(token, "identity") {
					continue
				}
				unsupported = true
			}
		}
		if unsupported {
			return 501, "Not Implemented"
		}
		if has_chunked {
			conn.chunked = true
			conn.content_length = -1
		}
	}

	conn.keep_alive = !conn.http10
	if header_has_token(conn_req.Header, "connection", "close") {
		conn.keep_alive = false
	}
	if header_has_token(conn_req.Header, "connection", "keep-alive") {
		conn.keep_alive = true
	}

	if !conn.chunked && conn.server.Max_Body_Bytes > 0 && conn.content_length > int(conn.server.Max_Body_Bytes) {
		return 413, "Payload Too Large"
	}

	conn.req_cache = conn_req

	return 0, ""
}

conn_dispatch_request :: proc(conn: ^Conn) {
	if conn == nil || conn.server == nil {
		return
	}

	res := ResponseWriter{
		Status = 0,
		Header = make(Header),
		_internal = conn,
	}

	conn.server.Handler(&conn.req_cache, &res)
	if !conn.responded {
		response_end(&res)
	}

	conn_reset_request_state(conn)
}

conn_send_error :: proc(conn: ^Conn, status: int, text: string) {
	if conn == nil {
		return
	}
	conn.keep_alive = false
	res := ResponseWriter{
		Status = status,
		Header = make(Header),
		_internal = conn,
	}
	response_write_string(&res, text)
	response_end(&res)
}

conn_after_response :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	if conn.close_after_response {
		conn_close(conn)
		return
	}

	conn.responded = false
	conn.close_after_response = false
	bytes.buffer_reset(&conn.body_buf)
	bytes.buffer_reset(&conn.req_body)
	conn_reset_request_state(conn)

	if len(conn.in_buf) > 0 {
		conn_process_buffer(conn)
	}
	if !conn.responded && !conn.use_tls {
		conn_recv(conn)
	}
}

conn_reset_request_state :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	conn.header_parsed = false
	conn.header_end = 0
	conn.body_start = 0
	conn.parse_pos = 0
	conn.content_length = -1
	conn.chunked = false
	conn.chunk_state = .Size
	conn.chunk_size = 0
	conn.chunk_total = 0
	conn.keep_alive = false
	conn.http10 = false
	conn.req_cache = Request{}
}

conn_consume :: proc(conn: ^Conn, n: int) {
	if conn == nil || n <= 0 {
		return
	}
	if n >= len(conn.in_buf) {
		conn.in_buf = conn.in_buf[:0]
		return
	}
	copy(conn.in_buf[:], conn.in_buf[n:])
	conn.in_buf = conn.in_buf[:len(conn.in_buf)-n]
}

conn_parse_chunked_body :: proc(conn: ^Conn) -> (done: bool, status: int) {
	if conn == nil {
		return false, 400
	}

	for {
		switch conn.chunk_state {
		case .Size:
			idx := find_crlf(conn.in_buf, conn.parse_pos)
			if idx < 0 {
				return false, 0
			}
			line := string(conn.in_buf[conn.parse_pos:idx])
			if semi := strings.index_byte(line, ';'); semi >= 0 {
				line = line[:semi]
			}
			line = strings.trim_space(line)
			if len(line) == 0 {
				return false, 400
			}
			size, ok := strconv.parse_int(line, 16)
			if !ok || size < 0 {
				return false, 400
			}
			conn.chunk_size = size
			conn.parse_pos = idx + 2
			if size == 0 {
				conn.chunk_state = .Trailer
			} else {
				conn.chunk_state = .Data
			}
		case .Data:
			need := conn.chunk_size + 2
			remaining := len(conn.in_buf) - conn.parse_pos
			if remaining < need {
				return false, 0
			}
			if conn.server.Max_Body_Bytes > 0 && conn.chunk_total+conn.chunk_size > int(conn.server.Max_Body_Bytes) {
				return false, 413
			}
			_, _ = bytes.buffer_write(&conn.req_body, conn.in_buf[conn.parse_pos:conn.parse_pos+conn.chunk_size])
			conn.chunk_total += conn.chunk_size
			conn.parse_pos += conn.chunk_size
			if conn.in_buf[conn.parse_pos] != '\r' || conn.in_buf[conn.parse_pos+1] != '\n' {
				return false, 400
			}
			conn.parse_pos += 2
			conn.chunk_state = .Size
		case .Trailer:
			offset := find_header_end(conn.in_buf[conn.parse_pos:])
			if offset < 0 {
				return false, 0
			}
			conn.parse_pos += offset + 4
			return true, 0
		}
	}
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
	}
	nbio.close(conn.socket)
	bytes.buffer_destroy(&conn.req_body)
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

find_crlf :: proc(buf: []u8, start: int) -> int {
	if start < 0 {
		start = 0
	}
	if len(buf) < 2 || start >= len(buf)-1 {
		return -1
	}
	for i := start; i < len(buf)-1; i += 1 {
		if buf[i] == '\r' && buf[i+1] == '\n' {
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
