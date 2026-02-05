package bifrost_http

import "core:bytes"
import "core:nbio"
import "core:strconv"
import "core:strings"
import tls "vendor:bifrost/tls"

H2_Client_Conn :: struct {
	conn: ^Client_Conn,
	recv_buf: [dynamic]u8,
	recv_pos: int,

	decoder: H2_Hpack_Decoder,
	encoder: H2_Hpack_Encoder,
	stream_id: u32,
	send_in_flight: int,
	finish_pending: bool,
	recv_in_flight: bool,
	upload_start_pending: bool,

	header_block: [dynamic]u8,
	headers_done: bool,
	end_stream: bool,
	response_done: bool,
}

H2_Client_Send_State :: struct {
	buf: []u8,
}

h2_client_setup_state :: proc(conn: ^Client_Conn) -> bool {
	if conn == nil {
		return false
	}
	conn.use_h2 = true
	conn.keep_alive = false
	bytes.buffer_reset(&conn.resp_body)
	client_release_response(conn)

	conn.h2 = H2_Client_Conn{
		conn = conn,
		recv_buf = make([dynamic]u8, 0, 16 * 1024),
		recv_pos = 0,
		stream_id = 1,
		send_in_flight = 0,
		finish_pending = false,
		recv_in_flight = false,
		upload_start_pending = false,
		header_block = make([dynamic]u8, 0, 1024),
		headers_done = false,
		end_stream = false,
		response_done = false,
	}
	h2_hpack_decoder_init(&conn.h2.decoder, 4096)
	h2_hpack_encoder_init(&conn.h2.encoder, 4096)
	return true
}

h2_client_init :: proc(conn: ^Client_Conn) {
	if !h2_client_setup_state(conn) {
		return
	}

	conn.body_stream = conn.req.Body_Stream
	conn.body_stream_user = conn.req.Body_Stream_User
	conn.upload_done = false
	conn.upload_in_flight = false
	conn.upload_final_pending = false

	if conn.body_stream != nil {
		if len(conn.req.Body) > 0 {
			client_finish_error(conn, .Send, "http2 streaming upload requires empty Body")
			_ = client_finalize(conn)
			return
		}
		out := h2_client_build_initial(conn, false, false)
		if out == nil || len(out) == 0 {
			client_finish_error(conn, .Send, "http2 request build failed")
			_ = client_finalize(conn)
			return
		}

		if conn.use_tls {
			_, status := tls.stream_write(&conn.tls_stream, out)
			delete(out)
			if status == .Error || status == .Closed {
				client_finish_error(conn, .Send, "tls write failed")
				_ = client_finalize(conn)
				return
			}
			conn.active = true
			h2_client_upload_next(conn)
			return
		}

		state := new(H2_Client_Send_State)
		state.buf = out
		conn.active = true
		conn.h2.send_in_flight += 1
		conn.h2.upload_start_pending = true
		nbio.send_poly2(conn.socket, {out}, conn, state, h2_client_on_send, l=conn.transport.Loop)
		return
	}

	out := h2_client_build_initial(conn, len(conn.req.Body) == 0, true)
	if out == nil || len(out) == 0 {
		client_finish_error(conn, .Send, "http2 request build failed")
		_ = client_finalize(conn)
		return
	}

	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		delete(out)
		if status == .Error || status == .Closed {
			client_finish_error(conn, .Send, "tls write failed")
			_ = client_finalize(conn)
			return
		}
		conn.active = true
		return
	}

	state := new(H2_Client_Send_State)
	state.buf = out
	conn.active = true
	conn.h2.send_in_flight += 1
	nbio.send_poly2(conn.socket, {out}, conn, state, h2_client_on_send, l=conn.transport.Loop)
}

h2_client_free :: proc(conn: ^Client_Conn) {
	if conn == nil {
		return
	}
	h2_hpack_decoder_free(&conn.h2.decoder)
	h2_hpack_encoder_free(&conn.h2.encoder)
	delete(conn.h2.recv_buf)
	delete(conn.h2.header_block)
	conn.h2 = H2_Client_Conn{}
	conn.use_h2 = false
}

h2_client_on_send :: proc(op: ^nbio.Operation, conn: ^Client_Conn, state: ^H2_Client_Send_State) {
	if state != nil {
		if state.buf != nil {
			delete(state.buf)
		}
		free(state)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		if conn.h2.send_in_flight > 0 {
			conn.h2.send_in_flight -= 1
		}
		client_finish_error(conn, .Send, "send failed")
		_ = client_finalize(conn)
		return
	}
	if conn.h2.send_in_flight > 0 {
		conn.h2.send_in_flight -= 1
	}
	if conn.h2.finish_pending && conn.h2.send_in_flight == 0 {
		if conn.body_stream != nil && !conn.upload_done {
			// Wait for upload to finish before finalizing.
		} else {
			conn.h2.finish_pending = false
			if conn.h2.response_done {
				client_finish_ok(conn)
			}
			_ = client_finalize(conn)
			return
		}
	}
	if conn.h2.upload_start_pending && conn.h2.send_in_flight == 0 {
		conn.h2.upload_start_pending = false
		h2_client_upload_next(conn)
	}
	if conn.upload_in_flight && conn.h2.send_in_flight == 0 {
		conn.upload_in_flight = false
		h2_client_upload_next(conn)
	}
	if conn.active {
		client_recv(conn)
	}
}

h2_client_on_data :: proc(conn: ^Client_Conn, data: []u8) -> (alive: bool) {
	if conn == nil || len(data) == 0 {
		return conn != nil
	}
	append(&conn.h2.recv_buf, ..data)

	for {
		available := len(conn.h2.recv_buf) - conn.h2.recv_pos
		if available < H2_FRAME_HEADER_LEN {
			break
		}
		buf := conn.h2.recv_buf[conn.h2.recv_pos:]
		hdr, ok := h2_frame_header_parse(buf)
		if !ok {
			client_finish_error(conn, .Parse, "invalid http2 frame")
			return client_finalize(conn)
		}
		if available < H2_FRAME_HEADER_LEN+hdr.Length {
			break
		}
		payload := buf[H2_FRAME_HEADER_LEN : H2_FRAME_HEADER_LEN+hdr.Length]
		if !h2_client_handle_frame(conn, hdr, payload) {
			return false
		}
		conn.h2.recv_pos += H2_FRAME_HEADER_LEN + hdr.Length
	}

	if conn.h2.recv_pos > 0 {
		remaining := len(conn.h2.recv_buf) - conn.h2.recv_pos
		if remaining > 0 {
			copy(conn.h2.recv_buf[:remaining], conn.h2.recv_buf[conn.h2.recv_pos:])
		}
		resize(&conn.h2.recv_buf, remaining)
		conn.h2.recv_pos = 0
	}

	return true
}

h2_client_handle_frame :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) -> bool {
	#partial switch hdr.Type {
	case .Settings:
		h2_client_handle_settings(conn, hdr, payload)
	case .Ping:
		h2_client_handle_ping(conn, hdr, payload)
	case .Headers:
		h2_client_handle_headers(conn, hdr, payload)
	case .Continuation:
		h2_client_handle_continuation(conn, hdr, payload)
	case .Data:
		h2_client_handle_data(conn, hdr, payload)
	case .RST_Stream:
		client_finish_error(conn, .Closed, "stream reset")
		_ = client_finalize(conn)
		return false
	case .GoAway:
		client_finish_error(conn, .Closed, "goaway")
		_ = client_finalize(conn)
		return false
	}
	return true
}

h2_client_handle_settings :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) {
	if (hdr.Flags & H2_FLAG_ACK) != 0 {
		return
	}
	if len(payload)%6 != 0 {
		return
	}
	h2_client_send_settings(conn, true)
}

h2_client_handle_ping :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) {
	if len(payload) != 8 {
		return
	}
	if (hdr.Flags & H2_FLAG_ACK) != 0 {
		return
	}
	h2_client_send_ping(conn, payload)
}

h2_client_handle_headers :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) {
	offset := 0
	pad_len := 0
	if (hdr.Flags & H2_FLAG_PADDED) != 0 {
		if len(payload) < 1 {
			return
		}
		pad_len = int(payload[0])
		offset += 1
	}
	if (hdr.Flags & H2_FLAG_PRIORITY) != 0 {
		if len(payload) < offset+5 {
			return
		}
		offset += 5
	}
	if pad_len > len(payload)-offset {
		return
	}
	fragment := payload[offset : len(payload)-pad_len]
	append(&conn.h2.header_block, ..fragment)
	if (hdr.Flags & H2_FLAG_END_HEADERS) != 0 {
		conn.h2.headers_done = true
		h2_client_headers_complete(conn)
	}
	if (hdr.Flags & H2_FLAG_END_STREAM) != 0 {
		conn.h2.end_stream = true
		if conn.h2.headers_done {
			h2_client_finish_response(conn)
		}
	}
}

h2_client_handle_continuation :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) {
	if conn.h2.headers_done {
		return
	}
	append(&conn.h2.header_block, ..payload)
	if (hdr.Flags & H2_FLAG_END_HEADERS) != 0 {
		conn.h2.headers_done = true
		h2_client_headers_complete(conn)
		if conn.h2.end_stream {
			h2_client_finish_response(conn)
		}
	}
}

h2_client_handle_data :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) {
	if len(payload) > 0 {
		_, _ = bytes.buffer_write(&conn.resp_body, payload)
	}
	if (hdr.Flags & H2_FLAG_END_STREAM) != 0 {
		conn.h2.end_stream = true
		if conn.h2.headers_done {
			h2_client_finish_response(conn)
		}
	}
}

h2_client_headers_complete :: proc(conn: ^Client_Conn) {
	fields, err := h2_hpack_decode(&conn.h2.decoder, conn.h2.header_block[:])
	delete(conn.h2.header_block)
	conn.h2.header_block = make([dynamic]u8, 0, 256)
	if err != .None {
		h2_hpack_fields_free(fields[:])
		delete(fields)
		client_finish_error(conn, .Parse, "hpack decode failed")
		_ = client_finalize(conn)
		return
	}

	status := 0
	if conn.response.Header == nil {
		conn.response.Header = make(Header)
	}
	for f in fields {
		if f.Name == ":status" {
			if code, ok := strconv.parse_int(f.Value, 10); ok {
				status = code
			}
		} else {
			header_add(&conn.response.Header, f.Name, f.Value)
		}
	}

	h2_hpack_fields_free(fields[:])
	delete(fields)

	if status == 0 {
		status = Status_OK
	}
	conn.response.Status = status
	conn.response.Status_Text = header_clone_string(status_phrase(status))
	conn.response.Proto = header_clone_string("HTTP/2.0")
}

h2_client_finish_response :: proc(conn: ^Client_Conn) {
	if conn == nil || conn.h2.response_done {
		return
	}
	conn.h2.response_done = true
	conn.response.Body = bytes.buffer_to_bytes(&conn.resp_body)
	if conn.body_stream != nil && !conn.upload_done {
		conn.h2.finish_pending = true
		conn.active = false
		return
	}
	if conn.h2.send_in_flight > 0 {
		conn.h2.finish_pending = true
		conn.active = false
		return
	}
	client_finish_ok(conn)
	_ = client_finalize(conn)
}

h2_client_build_initial :: proc(conn: ^Client_Conn, end_stream: bool, include_body: bool) -> []u8 {
	if conn == nil {
		return nil
	}

	method := conn.req.Method
	if len(method) == 0 {
		method = "GET"
	}
	target := conn.req.Target
	if len(target) == 0 {
		target = "/"
	}
	scheme := "http"
	if conn.use_tls {
		scheme = "https"
	}

	authority := conn.host
	host_val, host_ok := header_get(conn.req.Header, "host")
	if host_ok && len(host_val) > 0 {
		authority = host_val
	}

	if strings.has_prefix(target, "http://") || strings.has_prefix(target, "https://") {
		tmp := target
		if strings.has_prefix(tmp, "http://") {
			scheme = "http"
			tmp = tmp[len("http://"):]
		} else {
			scheme = "https"
			tmp = tmp[len("https://"):]
		}
		slash := strings.index_byte(tmp, '/')
		if slash >= 0 {
			authority = tmp[:slash]
			target = tmp[slash:]
		} else {
			authority = tmp
			target = "/"
		}
	}

	if target == "" {
		target = "/"
	}

	headers := make([dynamic]H2_Hpack_Field, 0, 8)
	append(&headers, H2_Hpack_Field{Name = ":method", Value = method})
	append(&headers, H2_Hpack_Field{Name = ":path", Value = target})
	append(&headers, H2_Hpack_Field{Name = ":scheme", Value = scheme})
	if authority != "" {
		append(&headers, H2_Hpack_Field{Name = ":authority", Value = authority})
	}

	lower_names := make([dynamic]string, 0, 8)
	for name, vals in conn.req.Header {
		lower, _ := strings.to_lower(name)
		append(&lower_names, lower)
		if lower == "connection" || lower == "transfer-encoding" || lower == "upgrade" ||
			lower == "keep-alive" || lower == "proxy-connection" || lower == "http2-settings" ||
			lower == "host" {
			continue
		}
		for v in vals {
			append(&headers, H2_Hpack_Field{Name = lower, Value = v})
		}
	}

	header_block := h2_hpack_encode_literal(headers[:])
	for ln in lower_names {
		delete(ln)
	}
	delete(lower_names)
	delete(headers)

	body := conn.req.Body
	out := make([dynamic]u8, 0, len(H2_PREFACE)+len(header_block)+len(body)+64)
	append(&out, ..transmute([]u8)string(H2_PREFACE))
	h2_client_append_settings(&out)
	h2_client_append_headers(&out, header_block, end_stream)
	if include_body && len(body) > 0 {
		h2_client_append_data(&out, body, true)
	}
	delete(header_block)
	return out[:]
}

h2_settings_payload_default :: proc() -> [12]u8 {
	payload: [12]u8
	// SETTINGS_ENABLE_PUSH = 0
	payload[0] = 0x00
	payload[1] = 0x02
	payload[2] = 0x00
	payload[3] = 0x00
	payload[4] = 0x00
	payload[5] = 0x00
	// SETTINGS_MAX_FRAME_SIZE = 16384
	payload[6] = 0x00
	payload[7] = 0x05
	payload[8] = 0x00
	payload[9] = 0x00
	payload[10] = 0x40
	payload[11] = 0x00
	return payload
}

h2_client_append_settings :: proc(out: ^[dynamic]u8) {
	if out == nil {
		return
	}
	payload := h2_settings_payload_default()

	hdr := H2_Frame_Header{
		Length = len(payload[:]),
		Type = .Settings,
		Flags = 0,
		Stream_ID = 0,
	}
	h2_client_append_frame(out, hdr, payload[:])
}

h2_client_send_settings :: proc(conn: ^Client_Conn, ack: bool) {
	flags := u8(0)
	if ack {
		flags = H2_FLAG_ACK
	}
	hdr := H2_Frame_Header{
		Length = 0,
		Type = .Settings,
		Flags = flags,
		Stream_ID = 0,
	}
	h2_client_send_frame(conn, hdr, nil)
}

h2_client_send_ping :: proc(conn: ^Client_Conn, data: []u8) {
	hdr := H2_Frame_Header{
		Length = len(data),
		Type = .Ping,
		Flags = H2_FLAG_ACK,
		Stream_ID = 0,
	}
	h2_client_send_frame(conn, hdr, data)
}

h2_client_send_frame :: proc(conn: ^Client_Conn, hdr: H2_Frame_Header, payload: []u8) {
	if conn == nil {
		return
	}
	out := make([]u8, H2_FRAME_HEADER_LEN+len(payload))
	if !h2_frame_header_write(hdr, out) {
		delete(out)
		return
	}
	if len(payload) > 0 {
		copy(out[H2_FRAME_HEADER_LEN:], payload)
	}

	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		delete(out)
		if status == .Error || status == .Closed {
			client_finish_error(conn, .Send, "tls write failed")
			_ = client_finalize(conn)
		}
		return
	}

	state := new(H2_Client_Send_State)
	state.buf = out
	conn.h2.send_in_flight += 1
	nbio.send_poly2(conn.socket, {out}, conn, state, h2_client_on_send, l=conn.transport.Loop)
}

h2_client_append_frame :: proc(out: ^[dynamic]u8, hdr: H2_Frame_Header, payload: []u8) {
	tmp: [H2_FRAME_HEADER_LEN]u8
	if !h2_frame_header_write(hdr, tmp[:]) {
		return
	}
	append(out, ..tmp[:])
	if len(payload) > 0 {
		append(out, ..payload)
	}
}

h2_client_append_headers :: proc(out: ^[dynamic]u8, header_block: []u8, end_stream: bool) {
	max_frame := 16384
	offset := 0
	first := true
	for offset < len(header_block) {
		remaining := len(header_block) - offset
		chunk := remaining
		if chunk > max_frame {
			chunk = max_frame
		}
		flags := u8(0)
		if offset+chunk == len(header_block) {
			flags |= H2_FLAG_END_HEADERS
		}
		if first && end_stream {
			flags |= H2_FLAG_END_STREAM
		}
		hdr_type := H2_Frame_Type.Headers
		if !first {
			hdr_type = .Continuation
		}
		hdr := H2_Frame_Header{
			Length = chunk,
			Type = hdr_type,
			Flags = flags,
			Stream_ID = 1,
		}
		h2_client_append_frame(out, hdr, header_block[offset:offset+chunk])
		offset += chunk
		first = false
	}
	if len(header_block) == 0 {
		flags := u8(0)
		if end_stream {
			flags = H2_FLAG_END_STREAM | H2_FLAG_END_HEADERS
		} else {
			flags = H2_FLAG_END_HEADERS
		}
		hdr := H2_Frame_Header{
			Length = 0,
			Type = .Headers,
			Flags = flags,
			Stream_ID = 1,
		}
		h2_client_append_frame(out, hdr, nil)
	}
}

h2_client_append_data :: proc(out: ^[dynamic]u8, data: []u8, end_stream: bool) {
	max_frame := 16384
	offset := 0
	for offset < len(data) {
		remaining := len(data) - offset
		chunk := remaining
		if chunk > max_frame {
			chunk = max_frame
		}
		flags := u8(0)
		if offset+chunk == len(data) && end_stream {
			flags |= H2_FLAG_END_STREAM
		}
		hdr := H2_Frame_Header{
			Length = chunk,
			Type = .Data,
			Flags = flags,
			Stream_ID = 1,
		}
		h2_client_append_frame(out, hdr, data[offset:offset+chunk])
		offset += chunk
	}
	if len(data) == 0 && end_stream {
		hdr := H2_Frame_Header{
			Length = 0,
			Type = .Data,
			Flags = H2_FLAG_END_STREAM,
			Stream_ID = 1,
		}
		h2_client_append_frame(out, hdr, nil)
	}
}

h2_client_send_data :: proc(conn: ^Client_Conn, data: []u8, end_stream: bool) {
	max_frame := 16384
	offset := 0
	for offset < len(data) {
		remaining := len(data) - offset
		chunk := remaining
		if chunk > max_frame {
			chunk = max_frame
		}
		flags := u8(0)
		if offset+chunk == len(data) && end_stream {
			flags |= H2_FLAG_END_STREAM
		}
		hdr := H2_Frame_Header{
			Length = chunk,
			Type = .Data,
			Flags = flags,
			Stream_ID = conn.h2.stream_id,
		}
		h2_client_send_frame(conn, hdr, data[offset:offset+chunk])
		offset += chunk
	}
	if len(data) == 0 && end_stream {
		hdr := H2_Frame_Header{
			Length = 0,
			Type = .Data,
			Flags = H2_FLAG_END_STREAM,
			Stream_ID = conn.h2.stream_id,
		}
		h2_client_send_frame(conn, hdr, nil)
	}
}

h2_client_upload_next :: proc(conn: ^Client_Conn) {
	if conn == nil || conn.body_stream == nil || conn.upload_done || conn.upload_in_flight {
		return
	}

	for {
		if conn.upload_done || conn.upload_in_flight {
			return
		}

		data, done, ok := conn.body_stream(conn.body_stream_user)
		if !ok {
			client_finish_error(conn, .Send, "body stream failed")
			_ = client_finalize(conn)
			return
		}

		if done && len(data) == 0 {
			if h2_client_upload_send_data(conn, nil, true) {
				return
			}
			conn.upload_done = true
		} else {
			if h2_client_upload_send_data(conn, data, done) {
				if done {
					conn.upload_done = true
				}
				return
			}
			if done {
				conn.upload_done = true
			}
		}

		if conn.upload_done && conn.h2.response_done {
			if conn.h2.send_in_flight > 0 {
				conn.h2.finish_pending = true
				conn.active = false
				return
			}
			client_finish_ok(conn)
			_ = client_finalize(conn)
			return
		}
	}
}

h2_client_upload_send_data :: proc(conn: ^Client_Conn, data: []u8, end_stream: bool) -> (waiting: bool) {
	if conn == nil {
		return true
	}
	h2_client_send_data(conn, data, end_stream)
	if conn.use_tls {
		if conn.tls_stream.send_in_flight || tls.pending_outgoing(conn.tls_stream.conn) > 0 {
			conn.upload_in_flight = true
			return true
		}
		return false
	}
	conn.upload_in_flight = true
	return true
}
