package bifrost_http

import "core:bytes"
import "core:nbio"
import base64 "core:encoding/base64"
import "core:strconv"
import "core:strings"
import "core:time"
import tls "vendor:bifrost/tls"

CLIENT_DEFAULT_MAX_HEADER :: 32 * 1024
CLIENT_DEFAULT_MAX_BODY   :: 4 * 1024 * 1024

Client_Final_Action :: enum {
	None,
	Pool,
	Close,
}

Client_Conn :: struct {
	transport: ^Transport,
	endpoint: nbio.Endpoint,
	pool_key: string,
	pool_key_owned: bool,
	host: string,

	socket: nbio.TCP_Socket,
	use_tls: bool,
	tls_stream: tls.TLS_Stream,

	recv_tmp: []u8,
	in_buf: [dynamic]u8,

	send_buf: bytes.Buffer,
	send_in_flight: bool,

	header_parsed: bool,
	header_end: int,
	body_start: int,
	parse_pos: int,
	content_length: int,
	chunked: bool,
	chunk_state: Chunk_State,
	chunk_size: int,
	chunk_total: int,

	response: Response,
	resp_body: bytes.Buffer,
	keep_alive: bool,

	req: Request,
	cb: Client_Response_Handler,
	active: bool,
	final_action: Client_Final_Action,

	body_stream: Client_Body_Source,
	body_stream_user: rawptr,
	upload_chunked: bool,
	upload_final_pending: bool,
	upload_done: bool,
	upload_in_flight: bool,
	upload_buf: []u8,

	use_h2: bool,
	h2: H2_Client_Conn,
	h2c_upgrade: bool,
}

transport_init :: proc(t: ^Transport, loop: ^nbio.Event_Loop, tls_cfg: ^tls.Config) {
	if t == nil {
		return
	}
	if t.Loop == nil {
		t.Loop = loop
	}
	if t.TLS == nil {
		t.TLS = tls_cfg
	}
	if t.Max_Idle <= 0 {
		t.Max_Idle = 8
	}
	if t.Max_Per_Host <= 0 {
		t.Max_Per_Host = 2
	}
	if t._pool == nil {
		t._pool = make(map[string][]^Client_Conn)
	}
	if t.TLS != nil && t._tls_ctx == nil {
		ctx, ok := tls.context_create(t.TLS, false)
		if ok {
			t._tls_ctx = ctx
		}
	}
}

client_do :: proc(client: ^Client, endpoint: nbio.Endpoint, host: string, req: ^Request, cb: Client_Response_Handler) {
	if client == nil || req == nil || cb == nil {
		return
	}

	if client.Loop == nil {
		client.Loop = nbio.current_thread_event_loop()
	}

	t := client.Transport
	if t == nil {
		t = new(Transport)
		client.Transport = t
	}
	transport_init(t, client.Loop, client.TLS)

	transport_round_trip(t, endpoint, host, req, cb, client.Timeout)
}

transport_round_trip :: proc(t: ^Transport, endpoint: nbio.Endpoint, host: string, req: ^Request, cb: Client_Response_Handler, timeout: time.Duration = 0) {
	if t == nil || req == nil || cb == nil {
		return
	}
	if t.Loop == nil {
		t.Loop = nbio.current_thread_event_loop()
	}
	if t._pool == nil {
		transport_init(t, t.Loop, t.TLS)
	}

	key, key_owned := transport_key(endpoint, host, t.TLS != nil)
	if conn := transport_pop_idle(t, key); conn != nil {
		if conn.pool_key_owned && conn.pool_key != key {
			header_free_string(conn.pool_key)
		}
		conn.use_h2 = false
		conn.req = req^
		conn.req.Header = header_clone(req.Header)
		conn.cb = cb
		conn.host = host
		conn.pool_key = key
		conn.pool_key_owned = key_owned
		conn.active = false
		conn.final_action = .None
		conn.body_stream = req.Body_Stream
		conn.body_stream_user = req.Body_Stream_User
		client_conn_reset(conn)
		client_send_request(conn)
		return
	}

	conn := new(Client_Conn)
	conn.transport = t
	conn.endpoint = endpoint
	conn.pool_key = key
	conn.pool_key_owned = key_owned
	conn.host = host
	conn.use_tls = t.TLS != nil
	conn.req = req^
	conn.req.Header = header_clone(req.Header)
	conn.cb = cb
	conn.body_stream = req.Body_Stream
	conn.body_stream_user = req.Body_Stream_User
	conn.recv_tmp = make([]u8, 16 * 1024)
	conn.in_buf = make([dynamic]u8, 0, 16 * 1024)
	conn.content_length = -1
	conn.chunk_state = .Size
	conn.active = false
	conn.final_action = .None
	conn.body_stream = nil
	conn.body_stream_user = nil
	conn.upload_chunked = false
	conn.upload_final_pending = false
	conn.upload_done = false
	conn.upload_in_flight = false
	conn.upload_buf = nil
	conn.use_h2 = false
	bytes.buffer_init_allocator(&conn.send_buf, 0, 1024)
	bytes.buffer_init_allocator(&conn.resp_body, 0, 16 * 1024)

	nbio.dial_poly(endpoint, conn, client_on_dial, timeout, l=t.Loop)
}

transport_destroy :: proc(t: ^Transport) {
	if t == nil {
		return
	}
	if t._pool != nil {
		for _, list in t._pool {
			for conn in list {
				client_conn_close(conn)
			}
			if list != nil {
				delete(list)
			}
		}
		delete(t._pool)
		t._pool = nil
	}
	if t._tls_ctx != nil {
		tls.context_free(t._tls_ctx)
		free(t._tls_ctx)
		t._tls_ctx = nil
	}
	free(t)
}

transport_key :: proc(endpoint: nbio.Endpoint, host: string, use_tls: bool) -> (key: string, owned: bool) {
	key = host
	if len(key) == 0 {
		key = nbio.endpoint_to_string(endpoint)
	}
	if use_tls {
		joined, err := strings.join({key, "|tls"}, "", context.allocator)
		if err != nil {
			return key, false
		}
		return joined, true
	}
	return key, false
}

transport_pop_idle :: proc(t: ^Transport, key: string) -> ^Client_Conn {
	if t == nil || t._pool == nil {
		return nil
	}
	list, ok := t._pool[key]
	if !ok || len(list) == 0 {
		return nil
	}
	conn := list[len(list)-1]
	if len(list) == 1 {
		delete(list)
		delete_key(&t._pool, key)
	} else {
		t._pool[key] = list[:len(list)-1]
	}
	return conn
}

transport_push_idle :: proc(t: ^Transport, key: string, conn: ^Client_Conn) -> bool {
	if t == nil || conn == nil {
		return false
	}
	if t._pool == nil {
		t._pool = make(map[string][]^Client_Conn)
	}
	total := 0
	for _, list in t._pool {
		total += len(list)
	}
	list := t._pool[key]
	if len(list) >= t.Max_Per_Host || total >= t.Max_Idle {
		return false
	}
	new_list := make([]^Client_Conn, len(list)+1)
	copy(new_list, list)
	new_list[len(list)] = conn
	t._pool[key] = new_list
	if list != nil {
		delete(list)
	}
	return true
}

client_on_dial :: proc(op: ^nbio.Operation, conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	if op.dial.err != nil {
		client_finish_error(conn, .Dial, "dial failed")
		_ = client_finalize(conn)
		return
	}

	conn.socket = op.dial.socket
	if conn.use_tls {
		ctx := conn.transport._tls_ctx
		if ctx == nil {
			client_finish_error(conn, .TLS, "tls context missing")
			_ = client_finalize(conn)
			return
		}
		ok := tls.stream_init(&conn.tls_stream, conn.transport.Loop, conn.socket, ctx, false, conn.host)
		if !ok {
			client_finish_error(conn, .TLS, "tls init failed")
			_ = client_finalize(conn)
			return
		}
		conn.tls_stream.on_handshake = client_on_tls_handshake
		conn.tls_stream.on_data = client_on_tls_data
		conn.tls_stream.on_close = client_on_tls_close
		conn.tls_stream.on_error = client_on_tls_error
		conn.tls_stream.on_flush = client_on_tls_flush
		conn.tls_stream.user = conn
		tls.stream_start(&conn.tls_stream)
		return
	}

	client_send_request(conn)
}

client_on_tls_handshake :: proc(s: ^tls.TLS_Stream) {
	if s == nil {
		return
	}
	conn := (^Client_Conn)(s.user)
	if conn == nil {
		return
	}
	if s.conn != nil && s.conn.alpn_selected == .HTTP2 {
		h2_client_init(conn)
		return
	}
	client_send_request(conn)
}

client_on_tls_data :: proc(s: ^tls.TLS_Stream, data: []u8) {
	if s == nil {
		return
	}
	conn := (^Client_Conn)(s.user)
	if conn == nil {
		return
	}
	_ = client_on_data(conn, data)
}

client_on_tls_close :: proc(s: ^tls.TLS_Stream) {
	if s == nil {
		return
	}
	conn := (^Client_Conn)(s.user)
	if conn == nil {
		return
	}
	if conn.use_h2 {
		if conn.active {
			client_finish_error(conn, .Closed, "connection closed")
			_ = client_finalize(conn)
		} else {
			client_conn_close(conn)
		}
		return
	}
	if conn.active && conn.header_parsed && conn.content_length < 0 {
		conn.response.Body = bytes.buffer_to_bytes(&conn.resp_body)
		client_finish_ok(conn)
		_ = client_finalize(conn)
	} else if conn.active {
		client_finish_error(conn, .Closed, "connection closed")
		_ = client_finalize(conn)
	} else {
		client_conn_close(conn)
	}
}

client_on_tls_error :: proc(s: ^tls.TLS_Stream, status: tls.TLS_Status, message: string) {
	if s == nil {
		return
	}
	conn := (^Client_Conn)(s.user)
	if conn == nil {
		return
	}
	_ = status
	if conn.active {
		client_finish_error(conn, .TLS, message)
		_ = client_finalize(conn)
	} else {
		client_conn_close(conn)
	}
}

client_on_tls_flush :: proc(s: ^tls.TLS_Stream) {
	if s == nil {
		return
	}
	conn := (^Client_Conn)(s.user)
	if conn == nil {
		return
	}
	if conn.upload_in_flight {
		conn.upload_in_flight = false
		if conn.use_h2 {
			h2_client_upload_next(conn)
		} else {
			client_upload_next(conn)
		}
	}
}

client_send_request :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	use_h2c_upgrade := false
	if !conn.use_tls && client_request_wants_h2(conn.req) {
		if conn.req.Header != nil && header_has_token(conn.req.Header, "upgrade", "h2c") {
			use_h2c_upgrade = true
		} else {
			h2_client_init(conn)
			return
		}
	}

	bytes.buffer_reset(&conn.send_buf)
	method := conn.req.Method
	if len(method) == 0 {
		method = "GET"
	}
	proto := conn.req.Proto
	if len(proto) == 0 {
		proto = "HTTP/1.1"
	}
	if use_h2c_upgrade {
		proto = "HTTP/1.1"
	}
	target := conn.req.Target
	if len(target) == 0 {
		target = "/"
	}

	if conn.req.Header == nil {
		conn.req.Header = make(Header)
	}
	if _, ok := header_get(conn.req.Header, "host"); !ok && len(conn.host) > 0 {
		header_set(&conn.req.Header, "host", conn.host)
	}
	if use_h2c_upgrade {
		if len(conn.req.Body) > 0 || conn.req.Body_Stream != nil {
			client_finish_error(conn, .Send, "h2c upgrade requires empty body")
			_ = client_finalize(conn)
			return
		}
		settings_payload := h2_settings_payload_default()
		settings_val, err := base64.encode(settings_payload[:], base64.ENC_URL_TABLE, allocator=context.temp_allocator)
		if err != nil {
			client_finish_error(conn, .Send, "h2c settings encode failed")
			_ = client_finalize(conn)
			return
		}
		settings_val = strings.trim_right(settings_val, "=")
		if len(settings_val) == 0 {
			client_finish_error(conn, .Send, "h2c settings encode failed")
			_ = client_finalize(conn)
			return
		}
		header_set(&conn.req.Header, "upgrade", "h2c")
		header_set(&conn.req.Header, "connection", "Upgrade, HTTP2-Settings")
		header_set(&conn.req.Header, "http2-settings", settings_val)
		conn.h2c_upgrade = true
	}

	keep_alive := !strings.equal_fold(proto, "HTTP/1.0")
	if header_has_token(conn.req.Header, "connection", "close") {
		keep_alive = false
	}
	if header_has_token(conn.req.Header, "connection", "keep-alive") {
		keep_alive = true
	}
	conn.keep_alive = keep_alive

	conn.body_stream = conn.req.Body_Stream
	conn.body_stream_user = conn.req.Body_Stream_User
	conn.upload_chunked = conn.body_stream != nil
	conn.upload_final_pending = false
	conn.upload_done = false
	conn.upload_in_flight = false

	body := conn.req.Body
	if conn.upload_chunked {
		if vals, ok := header_values(conn.req.Header, "transfer-encoding"); ok {
			chunked, ok_te, present := parse_transfer_encoding(vals)
			if present && (!ok_te || !chunked) {
				client_finish_error(conn, .Send, "unsupported transfer-encoding for streaming")
				_ = client_finalize(conn)
				return
			}
		}
		header_del(&conn.req.Header, "content-length")
		if !header_has_token(conn.req.Header, "transfer-encoding", "chunked") {
			header_set(&conn.req.Header, "transfer-encoding", "chunked")
		}
	} else {
		if !header_has_token(conn.req.Header, "transfer-encoding", "chunked") {
			if _, ok := header_get(conn.req.Header, "content-length"); !ok {
				buf: [32]u8
				header_set(&conn.req.Header, "content-length", strconv.write_int(buf[:], i64(len(body)), 10))
			}
		}
	}
	if _, ok := header_get(conn.req.Header, "connection"); !ok {
		if !keep_alive {
			header_set(&conn.req.Header, "connection", "close")
		}
	}

	for name, vals in conn.req.Header {
		if !header_valid_field_name(name) {
			client_finish_error(conn, .Send, "invalid header field name")
			_ = client_finalize(conn)
			return
		}
		for v in vals {
			if !header_valid_field_value(v) {
				client_finish_error(conn, .Send, "invalid header field value")
				_ = client_finalize(conn)
				return
			}
		}
	}

	_, _ = bytes.buffer_write_string(&conn.send_buf, method)
	_, _ = bytes.buffer_write_string(&conn.send_buf, " ")
	_, _ = bytes.buffer_write_string(&conn.send_buf, target)
	_, _ = bytes.buffer_write_string(&conn.send_buf, " ")
	_, _ = bytes.buffer_write_string(&conn.send_buf, proto)
	_, _ = bytes.buffer_write_string(&conn.send_buf, "\r\n")

	header_write_subset(&conn.send_buf, conn.req.Header, nil)
	_, _ = bytes.buffer_write_string(&conn.send_buf, "\r\n")
	if !conn.upload_chunked && len(body) > 0 {
		_, _ = bytes.buffer_write(&conn.send_buf, body)
	}
	if use_h2c_upgrade {
		h2_out := h2_client_build_initial(conn, len(conn.req.Body) == 0, true)
		if h2_out == nil || len(h2_out) == 0 {
			client_finish_error(conn, .Send, "http2 request build failed")
			_ = client_finalize(conn)
			return
		}
		_, _ = bytes.buffer_write(&conn.send_buf, h2_out)
		delete(h2_out)
	}

	out := bytes.buffer_to_bytes(&conn.send_buf)
	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		bytes.buffer_reset(&conn.send_buf)
		if status == .Error || status == .Closed {
			client_finish_error(conn, .Send, "tls write failed")
			_ = client_finalize(conn)
			return
		}
		conn.active = true
		if conn.upload_chunked {
			client_upload_next(conn)
		}
		return
	}

	conn.send_in_flight = true
	conn.active = true
	if conn.upload_chunked {
		nbio.send_poly(conn.socket, {out}, conn, client_on_send_headers_done, l=conn.transport.Loop)
	} else {
		nbio.send_poly(conn.socket, {out}, conn, client_on_send_done, l=conn.transport.Loop)
	}
}

client_request_wants_h2 :: proc(req: Request) -> bool {
	if strings.equal_fold(req.Proto, "HTTP/2.0") {
		return true
	}
	if strings.equal_fold(req.Proto, "HTTP/2") {
		return true
	}
	return false
}

client_on_send_done :: proc(op: ^nbio.Operation, conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	conn.send_in_flight = false
	bytes.buffer_reset(&conn.send_buf)
	if op.send.err != nil {
		client_finish_error(conn, .Send, "send failed")
		_ = client_finalize(conn)
		return
	}
	client_recv(conn)
}

client_on_send_headers_done :: proc(op: ^nbio.Operation, conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	conn.send_in_flight = false
	bytes.buffer_reset(&conn.send_buf)
	if op.send.err != nil {
		client_finish_error(conn, .Send, "send failed")
		_ = client_finalize(conn)
		return
	}
	client_upload_next(conn)
	if conn.upload_done && !conn.use_tls {
		client_recv(conn)
	}
}

client_on_upload_sent :: proc(op: ^nbio.Operation, conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	conn.upload_in_flight = false
	if conn.upload_buf != nil {
		delete(conn.upload_buf)
		conn.upload_buf = nil
	}
	if op.send.err != nil {
		client_finish_error(conn, .Send, "send failed")
		_ = client_finalize(conn)
		return
	}
	client_upload_next(conn)
	if conn.upload_done && !conn.use_tls {
		client_recv(conn)
	}
}

client_upload_next :: proc(conn: ^Client_Conn) {
	if conn == nil || !conn.upload_chunked || conn.upload_done || conn.upload_in_flight {
		return
	}

	for {
		if conn.upload_done || conn.upload_in_flight {
			return
		}
		if conn.upload_final_pending {
			if client_upload_send_final(conn) {
				return
			}
			continue
		}

		if conn.body_stream == nil {
			client_finish_error(conn, .Send, "missing body stream")
			_ = client_finalize(conn)
			return
		}

		data, done, ok := conn.body_stream(conn.body_stream_user)
		if !ok {
			client_finish_error(conn, .Send, "body stream failed")
			_ = client_finalize(conn)
			return
		}

		if done && len(data) == 0 {
			if client_upload_send_final(conn) {
				return
			}
			continue
		}

		if client_upload_send_chunk(conn, data) {
			return
		}
		if done {
			conn.upload_final_pending = true
		}
	}
}

client_upload_send_final :: proc(conn: ^Client_Conn) -> (waiting: bool) {
	if conn == nil {
		return true
	}
	conn.upload_final_pending = false
	conn.upload_done = true
	final_str := "0\r\n\r\n"
	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, transmute([]u8)final_str)
		if status == .Error || status == .Closed {
			client_finish_error(conn, .Send, "tls write failed")
			_ = client_finalize(conn)
			return true
		}
		if !conn.tls_stream.send_in_flight && tls.pending_outgoing(conn.tls_stream.conn) == 0 {
			return false
		}
		conn.upload_in_flight = true
		return true
	}
	conn.upload_in_flight = true
	conn.upload_buf = make([]u8, len(final_str))
	copy(conn.upload_buf[:], transmute([]u8)final_str)
	nbio.send_poly(conn.socket, {conn.upload_buf}, conn, client_on_upload_sent, l=conn.transport.Loop)
	return true
}

client_upload_send_chunk :: proc(conn: ^Client_Conn, data: []u8) -> (waiting: bool) {
	if conn == nil {
		return true
	}
	tmp: [64]u8
	size_hex := strconv.write_int(tmp[:], i64(len(data)), 16)
	total := len(size_hex) + 2 + len(data) + 2
	if conn.use_tls {
		chunk := make([]u8, total)
		copy(chunk[:], size_hex)
		chunk[len(size_hex)+0] = '\r'
		chunk[len(size_hex)+1] = '\n'
		if len(data) > 0 {
			copy(chunk[len(size_hex)+2:], data)
		}
		chunk[total-2] = '\r'
		chunk[total-1] = '\n'
		_, status := tls.stream_write(&conn.tls_stream, chunk)
		delete(chunk)
		if status == .Error || status == .Closed {
			client_finish_error(conn, .Send, "tls write failed")
			_ = client_finalize(conn)
			return true
		}
		if !conn.tls_stream.send_in_flight && tls.pending_outgoing(conn.tls_stream.conn) == 0 {
			return false
		}
		conn.upload_in_flight = true
		return true
	}

	conn.upload_in_flight = true
	conn.upload_buf = make([]u8, total)
	copy(conn.upload_buf[:], size_hex)
	conn.upload_buf[len(size_hex)+0] = '\r'
	conn.upload_buf[len(size_hex)+1] = '\n'
	if len(data) > 0 {
		copy(conn.upload_buf[len(size_hex)+2:], data)
	}
	conn.upload_buf[total-2] = '\r'
	conn.upload_buf[total-1] = '\n'
	nbio.send_poly(conn.socket, {conn.upload_buf}, conn, client_on_upload_sent, l=conn.transport.Loop)
	return true
}

client_recv :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	if conn.use_h2 {
		if conn.h2.recv_in_flight {
			return
		}
		conn.h2.recv_in_flight = true
	}
	nbio.recv_poly(conn.socket, {conn.recv_tmp}, conn, client_on_recv, l=conn.transport.Loop)
}

client_on_recv :: proc(op: ^nbio.Operation, conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	if conn.use_h2 {
		conn.h2.recv_in_flight = false
	}
	if conn.use_h2 && conn.h2.finish_pending {
		return
	}
	if op.recv.err != nil {
		if conn.active {
			client_finish_error(conn, .Recv, "recv failed")
			_ = client_finalize(conn)
		} else {
			client_conn_close(conn)
		}
		return
	}
	if op.recv.received == 0 {
		if conn.use_h2 {
			if conn.active {
				client_finish_error(conn, .Closed, "connection closed")
				_ = client_finalize(conn)
			} else {
				client_conn_close(conn)
			}
			return
		}
		if conn.active && conn.header_parsed && conn.content_length < 0 {
			conn.response.Body = bytes.buffer_to_bytes(&conn.resp_body)
			client_finish_ok(conn)
			_ = client_finalize(conn)
		} else if conn.active {
			client_finish_error(conn, .Closed, "connection closed")
			_ = client_finalize(conn)
		} else {
			client_conn_close(conn)
		}
		return
	}
	if !client_on_data(conn, conn.recv_tmp[:op.recv.received]) {
		return
	}
	if conn.active {
		client_recv(conn)
	}
}

client_on_data :: proc(conn: ^Client_Conn, data: []u8) -> (alive: bool) {
	if conn == nil || len(data) == 0 {
		return conn != nil
	}
	if conn.use_h2 {
		return h2_client_on_data(conn, data)
	}
	append(&conn.in_buf, ..data)
	if client_process_buffer(conn) {
		return client_finalize(conn)
	}
	return true
}

client_process_buffer :: proc(conn: ^Client_Conn) -> (finished: bool) {
	if conn == nil {
		return false
	}

	for {
		if !conn.header_parsed {
			idx := find_header_end(conn.in_buf[:])
			if idx < 0 {
				if len(conn.in_buf) > CLIENT_DEFAULT_MAX_HEADER {
					client_finish_error(conn, .Parse, "response headers too large")
					return true
				}
				return false
			}
			if idx+4 > CLIENT_DEFAULT_MAX_HEADER {
				client_finish_error(conn, .Parse, "response headers too large")
				return true
			}

			conn.header_parsed = true
			conn.header_end = idx
			conn.body_start = idx + 4
			conn.parse_pos = conn.body_start
			conn.content_length = -1
			conn.chunked = false
			conn.chunk_state = .Size
			conn.chunk_size = 0
			conn.chunk_total = 0
			bytes.buffer_reset(&conn.resp_body)

			status, text := client_parse_headers(conn)
			if status != 0 {
				client_finish_error(conn, .Parse, text)
				return true
			}
			if conn.use_h2 {
				return false
			}
			if !conn.header_parsed {
				continue
			}
		}

		if conn.chunked {
			done, status := client_parse_chunked_body(conn)
			if status != 0 {
				client_finish_error(conn, .Parse, "invalid chunked response")
				return true
			}
			if !done {
				return false
			}
			conn.response.Body = bytes.buffer_to_bytes(&conn.resp_body)
			client_finish_ok(conn)
			return true
		}

		if conn.content_length < 0 {
			if len(conn.in_buf) > conn.body_start {
				if bytes.buffer_length(&conn.resp_body)+len(conn.in_buf)-conn.body_start > CLIENT_DEFAULT_MAX_BODY {
					client_finish_error(conn, .Parse, "response body too large")
					return true
				}
				_, _ = bytes.buffer_write(&conn.resp_body, conn.in_buf[conn.body_start:])
				client_consume(conn, len(conn.in_buf))
			}
			return false
		}
		body_len := len(conn.in_buf) - conn.body_start
		if body_len < conn.content_length {
			return false
		}

		if conn.content_length > 0 {
			_, _ = bytes.buffer_write(&conn.resp_body, conn.in_buf[conn.body_start:conn.body_start+conn.content_length])
		}
		conn.response.Body = bytes.buffer_to_bytes(&conn.resp_body)
		client_consume(conn, conn.body_start+conn.content_length)
		client_finish_ok(conn)
		return true
	}
}

client_parse_headers :: proc(conn: ^Client_Conn) -> (status: int, text: string) {
	raw := string(conn.in_buf[:conn.body_start])
	lines, _ := strings.split(raw, "\r\n", context.temp_allocator)
	if len(lines) < 1 {
		return Status_Bad_Request, "invalid response"
	}
	line := lines[0]
	first := strings.index_byte(line, ' ')
	if first < 0 {
		return Status_Bad_Request, "invalid status line"
	}
	second := strings.index_byte(line[first+1:], ' ')
	code_str := ""
	status_text := ""
	if second < 0 {
		code_str = strings.trim_space(line[first+1:])
	} else {
		code_str = strings.trim_space(line[first+1 : first+1+second])
		status_text = strings.trim_space(line[first+1+second+1:])
	}
	proto := line[:first]
	if len(code_str) == 0 {
		return Status_Bad_Request, "invalid status code"
	}
	code, ok := parse_int_safe(code_str)
	if !ok {
		return Status_Bad_Request, "invalid status code"
	}
	proto, _ = strings.clone(proto)
	if len(status_text) > 0 {
		status_text, _ = strings.clone(status_text)
	}

	conn.response = Response{
		Status = code,
		Status_Text = status_text,
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
		header_add(&conn.response.Header, name, value)
	}

	if conn.response.Status >= Status_Continue && conn.response.Status < Status_OK {
		if conn.response.Status == Status_Continue {
			client_release_response(conn)
			client_consume(conn, conn.body_start)
			conn.header_parsed = false
			return 0, ""
		}
		if conn.response.Status == Status_Switching_Protocols && conn.h2c_upgrade {
			if !header_has_token(conn.response.Header, "upgrade", "h2c") {
				return Status_Bad_Request, "h2c upgrade rejected"
			}
			pending: []u8
			if len(conn.in_buf) > conn.body_start {
				pending = make([]u8, len(conn.in_buf)-conn.body_start)
				copy(pending, conn.in_buf[conn.body_start:])
			}
			client_release_response(conn)
			client_consume(conn, conn.body_start)
			conn.header_parsed = false
			conn.h2c_upgrade = false
			if !h2_client_setup_state(conn) {
				return Status_Bad_Request, "h2c upgrade failed"
			}
			if pending != nil && len(pending) > 0 {
				_ = h2_client_on_data(conn, pending)
				delete(pending)
			}
			return 0, ""
		}
		return Status_Bad_Request, "unexpected 1xx response"
	}

	if vals, ok := header_values(conn.response.Header, "content-length"); ok {
		n, ok_cl, _, canonical := parse_content_length_values(vals)
		if !ok_cl {
			return Status_Bad_Request, "invalid content-length"
		}
		conn.content_length = n
		if canonical != "" {
			header_set(&conn.response.Header, "content-length", canonical)
		}
	}

	if vals, ok := header_values(conn.response.Header, "transfer-encoding"); ok {
		chunked, ok_te, present := parse_transfer_encoding(vals)
		if present && !ok_te {
			return Status_Bad_Request, "unsupported transfer-encoding"
		}
		if chunked {
			conn.chunked = true
			conn.content_length = -1
		}
	}

	conn.keep_alive = !strings.equal_fold(proto, "HTTP/1.0")
	if header_has_token(conn.response.Header, "connection", "close") {
		conn.keep_alive = false
	}
	if header_has_token(conn.response.Header, "connection", "keep-alive") {
		conn.keep_alive = true
	}

	body_expected := true
	if conn.response.Status == Status_No_Content || conn.response.Status == Status_Not_Modified {
		body_expected = false
	}
	if strings.equal_fold(conn.req.Method, "HEAD") {
		body_expected = false
	}

	if !body_expected {
		conn.content_length = 0
	}
	if body_expected && !conn.chunked && conn.content_length < 0 {
		conn.keep_alive = false
	}

	if !conn.chunked && conn.content_length > int(CLIENT_DEFAULT_MAX_BODY) {
		return Status_Bad_Request, "response body too large"
	}

	return 0, ""
}

client_parse_chunked_body :: proc(conn: ^Client_Conn) -> (done: bool, status: int) {
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
			if conn.chunk_total+conn.chunk_size > int(CLIENT_DEFAULT_MAX_BODY) {
				return false, Status_Bad_Request
			}
			_, _ = bytes.buffer_write(&conn.resp_body, conn.in_buf[conn.parse_pos:conn.parse_pos+conn.chunk_size])
			conn.chunk_total += conn.chunk_size
			conn.parse_pos += conn.chunk_size
			if conn.in_buf[conn.parse_pos] != '\r' || conn.in_buf[conn.parse_pos+1] != '\n' {
				return false, Status_Bad_Request
			}
			conn.parse_pos += 2
			conn.chunk_state = .Size
			if conn.parse_pos > 0 {
				client_consume(conn, conn.parse_pos)
				conn.parse_pos = 0
				conn.body_start = 0
			}
		case .Trailer:
			remaining := len(conn.in_buf) - conn.parse_pos
			if remaining >= 2 && conn.in_buf[conn.parse_pos] == '\r' && conn.in_buf[conn.parse_pos+1] == '\n' {
				conn.parse_pos += 2
				client_consume(conn, conn.parse_pos)
				conn.parse_pos = 0
				conn.body_start = 0
				return true, 0
			}
			offset := find_header_end(conn.in_buf[conn.parse_pos:])
			if offset < 0 {
				return false, 0
			}
			conn.parse_pos += offset + 4
			client_consume(conn, conn.parse_pos)
			conn.parse_pos = 0
			conn.body_start = 0
			return true, 0
		}
	}
}

client_finish_ok :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	err := Client_Error{}
	if conn.cb != nil {
		conn.cb(&conn.req, &conn.response, err)
	}
	conn.active = false
	if conn.keep_alive {
		conn.final_action = .Pool
	} else {
		conn.final_action = .Close
	}
}

client_release_response :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	header_reset(&conn.response.Header)
	header_free_string(conn.response.Status_Text)
	header_free_string(conn.response.Proto)
	conn.response = Response{}
}

client_finish_error :: proc(conn: ^Client_Conn, kind: Client_Error_Kind, message: string) {
	if conn == nil {
		return
	}
	err := Client_Error{Kind = kind, Message = message}
	if conn.cb != nil {
		conn.cb(&conn.req, nil, err)
	}
	conn.active = false
	conn.final_action = .Close
}

client_finalize :: proc(conn: ^Client_Conn) -> (alive: bool) {
	if conn == nil {
		return false
	}
	client_release_request_response(conn)
	if conn.use_h2 && conn.h2.send_in_flight > 0 {
		conn.h2.finish_pending = true
		return true
	}
	if conn.final_action == .Pool {
		if transport_push_idle(conn.transport, conn.pool_key, conn) {
			conn.final_action = .None
			client_conn_reset(conn)
			return true
		}
	}
	conn.final_action = .None
	client_conn_close(conn)
	return false
}

client_release_request_response :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	header_reset(&conn.req.Header)
	client_release_response(conn)
}

client_conn_reset :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	if conn.use_h2 {
		h2_client_free(conn)
	}
	conn.h2c_upgrade = false
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
	conn.response = Response{}
	conn.active = false
	conn.final_action = .None
	conn.body_stream = nil
	conn.body_stream_user = nil
	conn.upload_chunked = false
	conn.upload_final_pending = false
	conn.upload_done = false
	conn.upload_in_flight = false
	if conn.upload_buf != nil {
		delete(conn.upload_buf)
		conn.upload_buf = nil
	}
	if conn.in_buf != nil {
		resize(&conn.in_buf, 0)
	}
	bytes.buffer_reset(&conn.resp_body)
}

client_conn_close :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	if conn.use_h2 {
		h2_client_free(conn)
	}
	conn.h2c_upgrade = false
	if conn.use_tls {
		tls.stream_free(&conn.tls_stream)
	}
	nbio.close(conn.socket)
	if conn.pool_key_owned {
		header_free_string(conn.pool_key)
		conn.pool_key = ""
		conn.pool_key_owned = false
	}
	header_reset(&conn.req.Header)
	header_reset(&conn.response.Header)
	bytes.buffer_destroy(&conn.send_buf)
	bytes.buffer_destroy(&conn.resp_body)
	if conn.upload_buf != nil {
		delete(conn.upload_buf)
		conn.upload_buf = nil
	}
	delete(conn.recv_tmp)
	delete(conn.in_buf)
	free(conn)
}

client_consume :: proc(conn: ^Client_Conn, n: int) {
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
