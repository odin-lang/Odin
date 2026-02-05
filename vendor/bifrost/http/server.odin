package bifrost_http

import "core:nbio"
import "core:bytes"
import "core:strings"
import "core:mem"
import "core:strconv"
import tls "vendor:bifrost/tls"

SERVER_DEFAULT_MAX_HEADER :: 32 * 1024
SERVER_DEFAULT_MAX_BODY   :: 1 * 1024 * 1024

Conn :: struct {
	server: ^Server,
	socket: nbio.TCP_Socket,
	use_tls: bool,
	tls_stream: tls.TLS_Stream,
	use_h2: bool,
	h2: H2_Server_Conn,

	recv_tmp: []u8,
	in_buf:   [dynamic]u8,
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
	expect_continue: bool,
	sent_continue: bool,
	stream_body: bool,
	body_received: int,
	body_done: bool,
	req_dispatched: bool,
	keep_alive: bool,
	http10: bool,
	close_after_response: bool,
	responded: bool,
	streaming_response: bool,
	stream_headers_sent: bool,
	stream_send_in_flight: int,
	stream_end_pending: bool,
	h2_upgrade: bool,
	h2_send_in_flight: int,
	h2_close_after_send: bool,

	req_cache: Request,
	res_cache: ResponseWriter,
}

listen :: proc(server: ^Server, endpoint: nbio.Endpoint, backlog := 1000) -> (socket: nbio.TCP_Socket, err: nbio.Network_Error) {
	if server == nil || server.Handler == nil {
		return 0, nbio.Listen_Error.Invalid_Argument
	}

	if server.Loop == nil {
		server.Loop = nbio.current_thread_event_loop()
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

	server._state.server = server
	nbio.accept_poly(socket, &server._state, server_on_accept, l=server.Loop)

	return socket, nil
}

server_on_accept :: proc(op: ^nbio.Operation, state: ^Server_State) {
	if state == nil || state.server == nil {
		return
	}
	server := state.server

	if op.accept.err != nil {
		#partial switch op.accept.err {
		case .Would_Block, .Interrupted, .Timeout, .Aborted:
			// Keep accepting even if a transient accept fails.
			nbio.accept_poly(op.accept.socket, state, server_on_accept, l=server.Loop)
		}
		return
	}

	conn := new(Conn)
	conn.server = server
	conn.socket = op.accept.client
	conn.use_tls = server.TLS != nil
	conn.use_h2 = false
	conn.recv_tmp = make([]u8, 16 * 1024)
	conn.in_buf = make([dynamic]u8, 0, 16 * 1024)
	conn.content_length = -1
	conn.chunk_state = .Size
	conn.keep_alive = false
	conn.http10 = false
	conn.close_after_response = false
	conn.expect_continue = false
	conn.sent_continue = false
	conn.h2_upgrade = false
	conn.stream_body = false
	conn.body_received = 0
	conn.body_done = false
	conn.req_dispatched = false
	bytes.buffer_init_allocator(&conn.req_body, 0, 16 * 1024)
	bytes.buffer_init_allocator(&conn.body_buf, 0, 16 * 1024)
	conn.streaming_response = false
	conn.stream_headers_sent = false
	conn.h2_send_in_flight = 0
	conn.h2_close_after_send = false

	if conn.use_tls {
		ok := tls.stream_init(&conn.tls_stream, server.Loop, conn.socket, server._tls_ctx, true)
		if !ok {
			conn_close(conn)
		} else {
			conn.tls_stream.on_handshake = tls_on_handshake
			conn.tls_stream.on_data = tls_on_data
			conn.tls_stream.on_close = tls_on_close
			conn.tls_stream.on_error = tls_on_error
			conn.tls_stream.on_flush = tls_on_flush
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
	if conn.use_h2 {
		if !conn.h2_close_after_send {
			conn_recv(conn)
		}
		return
	}
	if !conn.responded {
		conn_recv(conn)
	}
}

conn_on_plain_data :: proc(conn: ^Conn, data: []u8) {
	if conn == nil || len(data) == 0 {
		return
	}
	if conn.use_h2 {
		if conn.h2_close_after_send {
			return
		}
		h2_server_on_data(conn, data)
		return
	}
	if len(conn.in_buf) == 0 && len(data) >= len(H2_PREFACE) {
		preface := transmute([]u8)string(H2_PREFACE)
		if mem.compare(data[:len(preface)], preface) == 0 {
			h2_server_init(conn)
			h2_server_on_data(conn, data)
			return
		}
	}
	append(&conn.in_buf, ..data)
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
				idx := find_header_end(conn.in_buf[:])
				if idx < 0 {
				if len(conn.in_buf) > conn.server.Max_Header_Bytes {
					conn_send_error(conn, Status_Request_Header_Fields_Too_Large, Status_Text_Request_Header_Fields_Too_Large)
				}
				return
			}
			if idx+4 > conn.server.Max_Header_Bytes {
				conn_send_error(conn, Status_Request_Header_Fields_Too_Large, Status_Text_Request_Header_Fields_Too_Large)
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
			if conn.stream_body && !conn.req_dispatched {
				conn.req_cache.Body = nil
				conn_dispatch_request(conn)
				conn.req_dispatched = true
				if conn.responded {
					return
				}
				if !conn.chunked && conn.content_length == 0 {
					conn.body_done = true
					request_body_stream_push(&conn.req_cache, nil, true)
					if conn.server.Body_Handler != nil {
						conn.server.Body_Handler(&conn.req_cache, &conn.res_cache, nil, true)
					}
					if !conn.responded {
						response_end(&conn.res_cache)
					}
					return
				}
			}
			if conn.h2_upgrade {
				if conn.chunked || conn.content_length > 0 {
					conn_send_error(conn, Status_Bad_Request, Status_Text_Bad_Request)
					return
				}
				conn_send_h2_upgrade(conn)
				return
			}
			if conn.expect_continue && !conn.sent_continue && len(conn.in_buf) == conn.body_start && !conn.responded {
				conn_send_continue(conn)
			}
		}

		if conn.chunked {
			done, status := conn_parse_chunked_body(conn)
			if status != 0 {
				if status == Status_Payload_Too_Large {
					conn_send_error(conn, Status_Payload_Too_Large, Status_Text_Payload_Too_Large)
				} else {
					conn_send_error(conn, Status_Bad_Request, Status_Text_Bad_Request)
				}
				return
			}
			if !done {
				return
			}
			if conn.stream_body {
				conn_consume(conn, conn.parse_pos)
				conn.parse_pos = 0
				conn.body_start = 0
				conn.body_done = true
				request_body_stream_push(&conn.req_cache, nil, true)
				if conn.server.Body_Handler != nil {
					conn.server.Body_Handler(&conn.req_cache, &conn.res_cache, nil, true)
				}
				if !conn.responded {
					response_end(&conn.res_cache)
				}
				return
			}
			conn.req_cache.Body = bytes.buffer_to_bytes(&conn.req_body)
			conn_consume(conn, conn.parse_pos)
			conn_dispatch_request(conn)
			return
		}

		if conn.content_length < 0 {
			conn.content_length = 0
		}

		if conn.stream_body {
			remaining := conn.content_length - conn.body_received
			if remaining <= 0 {
				conn.body_done = true
				request_body_stream_push(&conn.req_cache, nil, true)
				if conn.server.Body_Handler != nil {
					conn.server.Body_Handler(&conn.req_cache, &conn.res_cache, nil, true)
				}
				if !conn.responded {
					response_end(&conn.res_cache)
				}
				return
			}
			available := len(conn.in_buf) - conn.parse_pos
			if available <= 0 {
				return
			}
			if available > remaining {
				available = remaining
			}
			done := conn.body_received+available == conn.content_length
			request_body_stream_push(&conn.req_cache, conn.in_buf[conn.parse_pos:conn.parse_pos+available], done)
			if conn.server.Body_Handler != nil {
				conn.server.Body_Handler(&conn.req_cache, &conn.res_cache, conn.in_buf[conn.parse_pos:conn.parse_pos+available], done)
			}
			conn.body_received += available
			conn.parse_pos += available
			conn_consume(conn, conn.parse_pos)
			conn.parse_pos = 0
			conn.body_start = 0
			if done {
				conn.body_done = true
				if !conn.responded {
					response_end(&conn.res_cache)
				}
			}
			return
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
		conn_consume(conn, conn.body_start+conn.content_length)

		conn_dispatch_request(conn)
		return
	}
}

conn_parse_headers :: proc(conn: ^Conn) -> (status: int, text: string) {
	if conn == nil {
		return Status_Bad_Request, Status_Text_Bad_Request
	}

	raw := string(conn.in_buf[:conn.body_start])
	lines, _ := strings.split(raw, "\r\n", context.temp_allocator)
	if len(lines) < 1 {
		return Status_Bad_Request, Status_Text_Bad_Request
	}

	parts, _ := strings.split(lines[0], " ", context.temp_allocator)
	if len(parts) < 3 {
		return Status_Bad_Request, Status_Text_Bad_Request
	}
	if len(parts) > 3 {
		return Status_Bad_Request, Status_Text_Bad_Request
	}

	method := parts[0]
	target := parts[1]
	proto := parts[2]

	if strings.equal_fold(proto, "HTTP/1.0") {
		conn.http10 = true
	} else if strings.equal_fold(proto, "HTTP/1.1") {
		conn.http10 = false
	} else {
		return Status_HTTP_Version_Not_Supported, Status_Text_HTTP_Version_Not_Supported
	}

	parsed_target, ok_target := parse_request_target(method, target)
	if !ok_target {
		return Status_Bad_Request, Status_Text_Bad_Request
	}

	method, _ = strings.clone(method)
	target, _ = strings.clone(parsed_target)
	proto, _ = strings.clone(proto)
	conn_req := Request{
		Method = method,
		Target = target,
		Proto = proto,
		Header = make(Header),
	}
	ok := false
	defer if !ok {
		header_reset(&conn_req.Header)
		header_free_string(conn_req.Method)
		header_free_string(conn_req.Target)
		header_free_string(conn_req.Proto)
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

	if vals, ok := header_values(conn_req.Header, "content-length"); ok {
		n, ok_cl, _ := parse_content_length_values(vals)
		if !ok_cl {
			return Status_Bad_Request, Status_Text_Bad_Request
		}
		conn.content_length = n
	}

	conn.expect_continue = false
	if vals, ok := header_values(conn_req.Header, "expect"); ok {
		has_continue := false
		unsupported := false
		for v in vals {
			parts, _ := strings.split(v, ",", context.temp_allocator)
			for p in parts {
				token := strings.trim_space(p)
				if len(token) == 0 {
					continue
				}
				if strings.equal_fold(token, "100-continue") {
					has_continue = true
					continue
				}
				unsupported = true
			}
		}
		if unsupported {
			return Status_Expectation_Failed, Status_Text_Expectation_Failed
		}
		if has_continue && !conn.http10 {
			conn.expect_continue = true
		}
		if has_continue && conn.http10 {
			return Status_Expectation_Failed, Status_Text_Expectation_Failed
		}
	}

	conn.chunked = false
	if vals, ok := header_values(conn_req.Header, "transfer-encoding"); ok {
		chunked, ok_te, present := parse_transfer_encoding(vals)
		if present && !ok_te {
			return Status_Not_Implemented, Status_Text_Not_Implemented
		}
		if chunked {
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

	conn.h2_upgrade = false
	if !conn.use_tls &&
		header_has_token(conn_req.Header, "upgrade", "h2c") &&
		header_has_token(conn_req.Header, "connection", "upgrade") {
		if _, ok := header_get(conn_req.Header, "http2-settings"); !ok {
			return Status_Bad_Request, Status_Text_Bad_Request
		}
		conn.h2_upgrade = true
	}

	host_vals, has_host := header_values(conn_req.Header, "host")
	if !conn.http10 {
		if !has_host && !strings.equal_fold(conn_req.Method, "CONNECT") {
			return Status_Bad_Request, Status_Text_Bad_Request
		}
	}
	if has_host {
		if len(host_vals) != 1 {
			return Status_Bad_Request, Status_Text_Bad_Request
		}
		if !valid_host_header(host_vals[0]) {
			return Status_Bad_Request, Status_Text_Bad_Request
		}
	}

	if !conn.chunked && conn.server.Max_Body_Bytes > 0 && conn.content_length > int(conn.server.Max_Body_Bytes) {
		return Status_Payload_Too_Large, Status_Text_Payload_Too_Large
	}

	conn.stream_body = conn.server.Body_Handler != nil
	conn.body_received = 0
	conn.body_done = false
	conn.req_dispatched = false
	conn.req_cache = conn_req
	ok = true

	return 0, ""
}

conn_dispatch_request :: proc(conn: ^Conn) {
	if conn == nil || conn.server == nil {
		return
	}

	conn.res_cache = ResponseWriter{
		Status = 0,
		Header = make(Header),
	}
	response_writer_init(&conn.res_cache, conn, .HTTP1)

	conn.server.Handler(&conn.req_cache, &conn.res_cache)
	if !conn.responded && !conn.stream_body {
		response_end(&conn.res_cache)
	}
}

conn_send_error :: proc(conn: ^Conn, status: int, text: string) {
	if conn == nil {
		return
	}
	conn.keep_alive = false
	res := ResponseWriter{
		Status = status,
		Header = make(Header),
	}
	response_writer_init(&res, conn, .HTTP1)
	response_write_string(&res, text)
	response_end(&res)
	header_reset(&res.Header)
}

conn_send_continue :: proc(conn: ^Conn) {
	if conn == nil || conn.sent_continue {
		return
	}
	conn.sent_continue = true
	buf: [64]byte
	n := 0
	n += copy(buf[n:], "HTTP/1.1 ")
	code := strconv.write_int(buf[n:], i64(Status_Continue), 10)
	n += len(code)
	n += copy(buf[n:], " ")
	n += copy(buf[n:], Status_Text_Continue)
	n += copy(buf[n:], "\r\n\r\n")
	msg := string(buf[:n])
	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, transmute([]u8)msg)
		if status == .Error || status == .Closed {
			conn_close(conn)
		}
		return
	}
	nbio.send_poly(conn.socket, {transmute([]u8)msg}, conn, on_send_continue, l=conn.server.Loop)
}

on_send_continue :: proc(op: ^nbio.Operation, conn: ^Conn) {
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
	}
}

H2_Upgrade_State :: struct {
	pending: []u8,
}

conn_send_h2_upgrade :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	if conn.use_tls {
		conn_send_error(conn, Status_Bad_Request, Status_Text_Bad_Request)
		return
	}

	pending := conn.in_buf[conn.body_start:]
	pending_copy: []u8
	if len(pending) > 0 {
		pending_copy = make([]u8, len(pending))
		copy(pending_copy, pending)
	}
	conn_consume(conn, conn.body_start)
	conn.h2_upgrade = false

	header_free_string(conn.req_cache.Method)
	header_free_string(conn.req_cache.Target)
	header_free_string(conn.req_cache.Proto)
	header_reset(&conn.req_cache.Header)
	header_reset(&conn.res_cache.Header)
	conn_reset_request_state(conn)

	state := new(H2_Upgrade_State)
	state.pending = pending_copy

	buf: [128]byte
	n := 0
	n += copy(buf[n:], "HTTP/1.1 ")
	code := strconv.write_int(buf[n:], i64(Status_Switching_Protocols), 10)
	n += len(code)
	n += copy(buf[n:], " ")
	n += copy(buf[n:], Status_Text_Switching_Protocols)
	n += copy(buf[n:], "\r\nConnection: Upgrade\r\nUpgrade: h2c\r\n\r\n")
	msg := string(buf[:n])
	nbio.send_poly2(conn.socket, {transmute([]u8)msg}, conn, state, on_send_h2_upgrade, l=conn.server.Loop)
}

on_send_h2_upgrade :: proc(op: ^nbio.Operation, conn: ^Conn, state: ^H2_Upgrade_State) {
	if conn == nil {
		if state != nil {
			if state.pending != nil {
				delete(state.pending)
			}
			free(state)
		}
		return
	}
	if op.send.err != nil {
		if state != nil {
			if state.pending != nil {
				delete(state.pending)
			}
			free(state)
		}
		conn_close(conn)
		return
	}

	h2_server_init(conn)
	if state != nil {
		if state.pending != nil && len(state.pending) > 0 {
			h2_server_on_data(conn, state.pending)
			delete(state.pending)
		}
		free(state)
	}
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
	conn.streaming_response = false
	conn.stream_headers_sent = false
	conn.stream_send_in_flight = 0
	conn.stream_end_pending = false
	header_free_string(conn.req_cache.Method)
	header_free_string(conn.req_cache.Target)
	header_free_string(conn.req_cache.Proto)
	conn.req_cache.Method = ""
	conn.req_cache.Target = ""
	conn.req_cache.Proto = ""
	header_reset(&conn.req_cache.Header)
	header_reset(&conn.res_cache.Header)
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
	conn.expect_continue = false
	conn.sent_continue = false
	conn.h2_upgrade = false
	conn.stream_body = false
	conn.body_received = 0
	conn.body_done = false
	conn.req_dispatched = false
	conn.keep_alive = false
	conn.http10 = false
	request_body_state_free(&conn.req_cache)
	conn.req_cache = Request{}
	conn.res_cache = ResponseWriter{}
	conn.streaming_response = false
	conn.stream_headers_sent = false
	conn.h2_send_in_flight = 0
	conn.h2_close_after_send = false
}

conn_consume :: proc(conn: ^Conn, n: int) {
	if conn == nil || n <= 0 {
		return
	}
	if n >= len(conn.in_buf) {
		resize(&conn.in_buf, 0)
		return
	}
	copy(conn.in_buf[:], conn.in_buf[n:])
	resize(&conn.in_buf, len(conn.in_buf)-n)
}

conn_parse_chunked_body :: proc(conn: ^Conn) -> (done: bool, status: int) {
	if conn == nil {
		return false, Status_Bad_Request
	}

	for {
		switch conn.chunk_state {
		case .Size:
			idx := find_crlf(conn.in_buf[:], conn.parse_pos)
			if idx < 0 {
				return false, 0
			}
			line := string(conn.in_buf[conn.parse_pos:idx])
			if semi := strings.index_byte(line, ';'); semi >= 0 {
				line = line[:semi]
			}
			line = strings.trim_space(line)
			if len(line) == 0 {
				return false, Status_Bad_Request
			}
			size, ok := parse_int_safe(line, 16)
			if !ok || size < 0 {
				return false, Status_Bad_Request
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
				return false, Status_Payload_Too_Large
			}
			if conn.stream_body {
				request_body_stream_push(&conn.req_cache, conn.in_buf[conn.parse_pos:conn.parse_pos+conn.chunk_size], false)
				if conn.server.Body_Handler != nil {
					conn.server.Body_Handler(&conn.req_cache, &conn.res_cache, conn.in_buf[conn.parse_pos:conn.parse_pos+conn.chunk_size], false)
				}
			} else {
				_, _ = bytes.buffer_write(&conn.req_body, conn.in_buf[conn.parse_pos:conn.parse_pos+conn.chunk_size])
			}
			conn.chunk_total += conn.chunk_size
			conn.parse_pos += conn.chunk_size
			if conn.in_buf[conn.parse_pos] != '\r' || conn.in_buf[conn.parse_pos+1] != '\n' {
				return false, Status_Bad_Request
			}
			conn.parse_pos += 2
			conn.chunk_state = .Size
			if conn.parse_pos > 0 {
				conn_consume(conn, conn.parse_pos)
				conn.parse_pos = 0
				conn.body_start = 0
			}
		case .Trailer:
			remaining := len(conn.in_buf) - conn.parse_pos
			if remaining >= 2 && conn.in_buf[conn.parse_pos] == '\r' && conn.in_buf[conn.parse_pos+1] == '\n' {
				conn.parse_pos += 2
				return true, 0
			}
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
	if conn.use_h2 {
		h2_server_free(conn)
	}
	if conn.use_tls {
		tls.stream_free(&conn.tls_stream)
	}
	nbio.close(conn.socket)
	request_body_state_free(&conn.req_cache)
	header_free_string(conn.req_cache.Method)
	header_free_string(conn.req_cache.Target)
	header_free_string(conn.req_cache.Proto)
	header_reset(&conn.req_cache.Header)
	header_reset(&conn.res_cache.Header)
	bytes.buffer_destroy(&conn.req_body)
	bytes.buffer_destroy(&conn.body_buf)
	delete(conn.recv_tmp)
	delete(conn.in_buf)
	free(conn)
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
	pos := start
	if pos < 0 {
		pos = 0
	}
	if len(buf) < 2 || pos >= len(buf)-1 {
		return -1
	}
	for i := pos; i < len(buf)-1; i += 1 {
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
	if s.conn != nil && s.conn.alpn_selected == .HTTP2 {
		h2_server_init(conn)
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

tls_on_flush :: proc(s: ^tls.TLS_Stream) {
	if s == nil {
		return
	}
	conn := (^Conn)(s.user)
	if conn == nil {
		return
	}
	if conn.use_h2 && conn.h2_close_after_send {
		conn_close(conn)
	}
}
