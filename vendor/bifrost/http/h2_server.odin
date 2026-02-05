package bifrost_http

import "core:bytes"
import "core:strconv"
import "core:strings"
import "core:mem"
import "core:nbio"
import tls "vendor:bifrost/tls"

H2_Stream_State :: enum {
	Idle,
	Open,
	Half_Closed_Local,
	Half_Closed_Remote,
	Closed,
}

H2_Stream :: struct {
	id: u32,
	state: H2_Stream_State,
	conn: ^Conn,

	header_block: [dynamic]u8,
	headers_done: bool,
	end_stream: bool,

	req_cache: Request,
	res_cache: ResponseWriter,
	body_buf: bytes.Buffer,
	body_received: int,
	stream_body: bool,
	req_dispatched: bool,
	responded: bool,
	response_headers_sent: bool,
}

H2_Server_Conn :: struct {
	conn: ^Conn,
	recv_buf: [dynamic]u8,
	recv_pos: int,
	preface_done: bool,

	decoder: H2_Hpack_Decoder,
	encoder: H2_Hpack_Encoder,

	streams: map[u32]^H2_Stream,
	peer_settings: H2_Settings,
	local_settings: H2_Settings,
}

H2_Send_State :: struct {
	buf: []u8,
}

h2_server_init :: proc(conn: ^Conn) {
	if conn == nil || conn.server == nil {
		return
	}
	conn.use_h2 = true

	conn.h2 = H2_Server_Conn{
		conn = conn,
		recv_buf = make([dynamic]u8, 0, 16 * 1024),
		recv_pos = 0,
		preface_done = false,
		streams = make(map[u32]^H2_Stream),
		peer_settings = h2_settings_default(),
		local_settings = h2_settings_default(),
	}
	conn.h2.local_settings.Enable_Push = false
	h2_hpack_decoder_init(&conn.h2.decoder, 4096)
	h2_hpack_encoder_init(&conn.h2.encoder, 4096)

	h2_send_settings(conn, false)
}

h2_server_free :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	for _, stream in conn.h2.streams {
		h2_stream_free(stream)
	}
	delete(conn.h2.streams)
	h2_hpack_decoder_free(&conn.h2.decoder)
	h2_hpack_encoder_free(&conn.h2.encoder)
	delete(conn.h2.recv_buf)
	conn.h2 = H2_Server_Conn{}
}

h2_stream_new :: proc(conn: ^Conn, id: u32) -> ^H2_Stream {
	stream := new(H2_Stream)
	stream.id = id
	stream.state = .Open
	stream.conn = conn
	stream.header_block = make([dynamic]u8, 0, 1024)
	stream.headers_done = false
	stream.end_stream = false
	stream.req_cache = Request{Header = make(Header)}
	stream.res_cache = ResponseWriter{Header = make(Header)}
	response_writer_init(&stream.res_cache, stream, .HTTP2)
	bytes.buffer_init_allocator(&stream.body_buf, 0, 16 * 1024)
	stream.stream_body = conn.server.Body_Handler != nil
	stream.req_dispatched = false
	stream.responded = false
	stream.response_headers_sent = false
	return stream
}

h2_stream_free :: proc(stream: ^H2_Stream) {
	if stream == nil {
		return
	}
	header_free_string(stream.req_cache.Method)
	header_free_string(stream.req_cache.Target)
	header_free_string(stream.req_cache.Proto)
	request_body_state_free(&stream.req_cache)
	header_reset(&stream.req_cache.Header)
	header_reset(&stream.res_cache.Header)
	bytes.buffer_destroy(&stream.body_buf)
	delete(stream.header_block)
	free(stream)
}

h2_server_on_data :: proc(conn: ^Conn, data: []u8) {
	if conn == nil || !conn.use_h2 {
		return
	}
	append(&conn.h2.recv_buf, ..data)

	if !conn.h2.preface_done {
		if len(conn.h2.recv_buf) < len(H2_PREFACE) {
			return
		}
		preface_bytes := transmute([]u8)string(H2_PREFACE)
		if mem.compare(conn.h2.recv_buf[:len(preface_bytes)], preface_bytes) != 0 {
			conn_close(conn)
			return
		}
		conn.h2.preface_done = true
		conn.h2.recv_pos = len(preface_bytes)
	}

	for {
		available := len(conn.h2.recv_buf) - conn.h2.recv_pos
		if available < H2_FRAME_HEADER_LEN {
			break
		}
		buf := conn.h2.recv_buf[conn.h2.recv_pos:]
		hdr, ok := h2_frame_header_parse(buf)
		if !ok {
			conn_close(conn)
			return
		}
		if available < H2_FRAME_HEADER_LEN+hdr.Length {
			break
		}
		payload := buf[H2_FRAME_HEADER_LEN : H2_FRAME_HEADER_LEN+hdr.Length]
		h2_handle_frame(conn, hdr, payload)
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
}

h2_handle_frame :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	#partial switch hdr.Type {
	case .Settings:
		h2_handle_settings(conn, hdr, payload)
	case .Ping:
		h2_handle_ping(conn, hdr, payload)
	case .Headers:
		h2_handle_headers(conn, hdr, payload)
	case .Continuation:
		h2_handle_continuation(conn, hdr, payload)
	case .Data:
		h2_handle_data(conn, hdr, payload)
	case .RST_Stream:
		h2_handle_rst_stream(conn, hdr, payload)
	case .GoAway:
		conn_close(conn)
	default:
		{}
	}
}

h2_handle_settings :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	if (hdr.Flags & H2_FLAG_ACK) != 0 {
		return
	}
	if len(payload)%6 != 0 {
		return
	}
	for i := 0; i < len(payload); i += 6 {
		id := H2_Settings_Id(u16(payload[i])<<8 | u16(payload[i+1]))
		value := u32(payload[i+2])<<24 | u32(payload[i+3])<<16 | u32(payload[i+4])<<8 | u32(payload[i+5])
		switch id {
		case .Header_Table_Size:
			conn.h2.peer_settings.Header_Table_Size = value
		case .Enable_Push:
			conn.h2.peer_settings.Enable_Push = value != 0
		case .Max_Concurrent_Streams:
			conn.h2.peer_settings.Max_Concurrent_Streams = value
		case .Initial_Window_Size:
			conn.h2.peer_settings.Initial_Window_Size = value
		case .Max_Frame_Size:
			conn.h2.peer_settings.Max_Frame_Size = value
		case .Max_Header_List_Size:
			conn.h2.peer_settings.Max_Header_List_Size = value
		}
	}
	h2_send_settings(conn, true)
}

h2_handle_ping :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	if len(payload) != 8 {
		return
	}
	if (hdr.Flags & H2_FLAG_ACK) != 0 {
		return
	}
	h2_send_ping(conn, payload)
}

h2_handle_headers :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	if hdr.Stream_ID == 0 {
		return
	}
	stream, ok := conn.h2.streams[hdr.Stream_ID]
	if !ok {
		stream = h2_stream_new(conn, hdr.Stream_ID)
		conn.h2.streams[hdr.Stream_ID] = stream
	}

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
	append(&stream.header_block, ..fragment)
	if (hdr.Flags & H2_FLAG_END_HEADERS) != 0 {
		stream.headers_done = true
		h2_stream_headers_complete(conn, stream)
	}
	if (hdr.Flags & H2_FLAG_END_STREAM) != 0 {
		stream.end_stream = true
		if stream.headers_done && !stream.stream_body && !stream.req_dispatched {
			h2_stream_dispatch(conn, stream)
		}
	}
}

h2_handle_continuation :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	stream, ok := conn.h2.streams[hdr.Stream_ID]
	if !ok || stream.headers_done {
		return
	}
	append(&stream.header_block, ..payload)
	if (hdr.Flags & H2_FLAG_END_HEADERS) != 0 {
		stream.headers_done = true
		h2_stream_headers_complete(conn, stream)
		if stream.end_stream && !stream.stream_body && !stream.req_dispatched {
			h2_stream_dispatch(conn, stream)
		}
	}
}

h2_handle_data :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	if hdr.Stream_ID == 0 {
		return
	}
	stream, ok := conn.h2.streams[hdr.Stream_ID]
	if !ok {
		return
	}

	if stream.stream_body {
		if len(payload) > 0 {
			request_body_stream_push(&stream.req_cache, payload, false)
		}
		if conn.server.Body_Handler != nil && len(payload) > 0 {
			conn.server.Body_Handler(&stream.req_cache, &stream.res_cache, payload, false)
		}
	} else {
		if len(payload) > 0 {
			_, _ = bytes.buffer_write(&stream.body_buf, payload)
		}
	}

	if (hdr.Flags & H2_FLAG_END_STREAM) != 0 {
		stream.end_stream = true
		if stream.stream_body {
			request_body_stream_push(&stream.req_cache, nil, true)
			if conn.server.Body_Handler != nil {
				conn.server.Body_Handler(&stream.req_cache, &stream.res_cache, nil, true)
			}
			if !stream.responded {
				response_end(&stream.res_cache)
			}
			return
		}
		if stream.headers_done && !stream.req_dispatched {
			h2_stream_dispatch(conn, stream)
		}
	}
}

h2_handle_rst_stream :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
	if len(payload) != 4 {
		return
	}
	stream, ok := conn.h2.streams[hdr.Stream_ID]
	if !ok {
		return
	}
	h2_stream_close(conn, stream)
}

h2_stream_headers_complete :: proc(conn: ^Conn, stream: ^H2_Stream) {
	fields, err := h2_hpack_decode(&conn.h2.decoder, stream.header_block[:])
	delete(stream.header_block)
	stream.header_block = make([dynamic]u8, 0, 256)
	if err != .None {
		h2_hpack_fields_free(fields[:])
		delete(fields)
		return
	}

	method := ""
	target := ""
	authority := ""

	for f in fields {
		if len(f.Name) > 0 && f.Name[0] == ':' {
			switch f.Name {
			case ":method":
				method = f.Value
			case ":path":
				target = f.Value
			case ":authority":
				authority = f.Value
			default:
				{}
			}
			continue
		}
			header_add(&stream.req_cache.Header, f.Name, f.Value)
	}

	if authority != "" {
		header_set(&stream.req_cache.Header, "host", authority)
	}

	stream.req_cache.Method = header_clone_string(method)
	stream.req_cache.Target = header_clone_string(target)
	stream.req_cache.Proto = header_clone_string("HTTP/2.0")

	h2_hpack_fields_free(fields[:])
	delete(fields)

	if stream.stream_body {
		stream.req_cache.Body = nil
		h2_stream_dispatch(conn, stream)
		if stream.end_stream {
			request_body_stream_push(&stream.req_cache, nil, true)
			if conn.server.Body_Handler != nil {
				conn.server.Body_Handler(&stream.req_cache, &stream.res_cache, nil, true)
			}
			if !stream.responded {
				response_end(&stream.res_cache)
			}
		}
		return
	}
	if stream.end_stream {
		h2_stream_dispatch(conn, stream)
	}
}

h2_stream_dispatch :: proc(conn: ^Conn, stream: ^H2_Stream) {
	if stream.req_dispatched {
		return
	}
	stream.req_dispatched = true
	if !stream.stream_body {
		stream.req_cache.Body = bytes.buffer_to_bytes(&stream.body_buf)
	}
	conn.server.Handler(&stream.req_cache, &stream.res_cache)
	if !stream.responded && !stream.stream_body {
		response_end(&stream.res_cache)
	}
}

h2_stream_close :: proc(conn: ^Conn, stream: ^H2_Stream) {
	if stream == nil {
		return
	}
	delete_key(&conn.h2.streams, stream.id)
	h2_stream_free(stream)
}

h2_send_settings :: proc(conn: ^Conn, ack: bool) {
	payload: []u8 = nil
	if !ack {
		payload = make([]u8, 12)
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
	}
	flags := u8(0)
	if ack {
		flags = H2_FLAG_ACK
	}
	hdr := H2_Frame_Header{
		Length = len(payload),
		Type = .Settings,
		Flags = flags,
		Stream_ID = 0,
	}
	h2_send_frame(conn, hdr, payload)
	if payload != nil {
		delete(payload)
	}
}

h2_send_ping :: proc(conn: ^Conn, data: []u8) {
	hdr := H2_Frame_Header{
		Length = len(data),
		Type = .Ping,
		Flags = H2_FLAG_ACK,
		Stream_ID = 0,
	}
	h2_send_frame(conn, hdr, data)
}

h2_send_frame :: proc(conn: ^Conn, hdr: H2_Frame_Header, payload: []u8) {
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
			conn_close(conn)
		}
		return
	}

	state := new(H2_Send_State)
	state.buf = out
	conn.h2_send_in_flight += 1
	nbio.send_poly2(conn.socket, {out}, conn, state, h2_on_send, l=conn.server.Loop)
}

h2_on_send :: proc(op: ^nbio.Operation, conn: ^Conn, state: ^H2_Send_State) {
	if state != nil {
		delete(state.buf)
		free(state)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
		return
	}
	if conn.h2_send_in_flight > 0 {
		conn.h2_send_in_flight -= 1
	}
	if conn.h2_close_after_send && conn.h2_send_in_flight == 0 {
		conn_close(conn)
	}
}

h2_send_headers :: proc(conn: ^Conn, stream_id: u32, header_block: []u8, end_stream: bool) {
	max_frame := int(conn.h2.peer_settings.Max_Frame_Size)
	if max_frame <= 0 || max_frame > H2_MAX_FRAME_SIZE {
		max_frame = 16384
	}
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
			Stream_ID = stream_id,
		}
		h2_send_frame(conn, hdr, header_block[offset:offset+chunk])
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
			Stream_ID = stream_id,
		}
		h2_send_frame(conn, hdr, nil)
	}
}

h2_send_data :: proc(conn: ^Conn, stream_id: u32, data: []u8, end_stream: bool) {
	max_frame := int(conn.h2.peer_settings.Max_Frame_Size)
	if max_frame <= 0 || max_frame > H2_MAX_FRAME_SIZE {
		max_frame = 16384
	}
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
			Stream_ID = stream_id,
		}
		h2_send_frame(conn, hdr, data[offset:offset+chunk])
		offset += chunk
	}
	if len(data) == 0 {
		flags := u8(0)
		if end_stream {
			flags = H2_FLAG_END_STREAM
		}
		hdr := H2_Frame_Header{
			Length = 0,
			Type = .Data,
			Flags = flags,
			Stream_ID = stream_id,
		}
		h2_send_frame(conn, hdr, nil)
	}
}

h2_response_write :: proc(res: ^ResponseWriter, data: []u8) -> bool {
	if res == nil {
		return false
	}
	stream := (^H2_Stream)(res._internal)
	if stream == nil {
		return false
	}
	_, _ = bytes.buffer_write(&stream.body_buf, data)
	return true
}

h2_response_end :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	stream := (^H2_Stream)(res._internal)
	if stream == nil || stream.responded {
		return
	}
	if stream.response_headers_sent {
		h2_response_stream_end(res)
		return
	}
	stream.responded = true

	status := res.Status
	if status == 0 {
		status = Status_OK
	}

	fields := make([dynamic]H2_Hpack_Field, 0, 8)
	lower_names := make([dynamic]string, 0, 8)
	code_buf: [32]u8
	status_str := strconv.write_int(code_buf[:], i64(status), 10)
	append(&fields, H2_Hpack_Field{Name = ":status", Value = status_str})

	body := bytes.buffer_to_bytes(&stream.body_buf)
	if _, ok := header_get(res.Header, "content-length"); !ok && len(body) > 0 {
		len_buf: [32]u8
		header_set(&res.Header, "content-length", strconv.write_int(len_buf[:], i64(len(body)), 10))
	}

	for name, vals in res.Header {
		lower, _ := strings.to_lower(name)
		append(&lower_names, lower)
		if lower == "connection" || lower == "transfer-encoding" || lower == "upgrade" || lower == "keep-alive" || lower == "proxy-connection" {
			continue
		}
		for v in vals {
			append(&fields, H2_Hpack_Field{Name = lower, Value = v})
		}
	}

	header_block := h2_hpack_encode_literal(fields[:])
	for ln in lower_names {
		delete(ln)
	}
	delete(lower_names)
	delete(fields)

	end_stream := len(body) == 0
	h2_send_headers(stream.conn, stream.id, header_block, end_stream)

	if len(body) > 0 {
		h2_send_data(stream.conn, stream.id, body, true)
	}
	delete(header_block)
	h2_stream_close(stream.conn, stream)
	stream.conn.h2_close_after_send = true
	if stream.conn.use_tls {
		tls.stream_flush(&stream.conn.tls_stream)
	} else if stream.conn.h2_send_in_flight == 0 {
		conn_close(stream.conn)
	}
}

h2_response_stream_start :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	stream := (^H2_Stream)(res._internal)
	if stream == nil {
		return false
	}
	if stream.response_headers_sent {
		return true
	}

	status := res.Status
	if status == 0 {
		status = Status_OK
	}
	fields := make([dynamic]H2_Hpack_Field, 0, 8)
	lower_names := make([dynamic]string, 0, 8)
	code_buf: [32]u8
	status_str := strconv.write_int(code_buf[:], i64(status), 10)
	append(&fields, H2_Hpack_Field{Name = ":status", Value = status_str})

	for name, vals in res.Header {
		lower, _ := strings.to_lower(name)
		append(&lower_names, lower)
		if lower == "connection" || lower == "transfer-encoding" || lower == "upgrade" || lower == "keep-alive" || lower == "proxy-connection" {
			continue
		}
		for v in vals {
			append(&fields, H2_Hpack_Field{Name = lower, Value = v})
		}
	}

	header_block := h2_hpack_encode_literal(fields[:])
	for ln in lower_names {
		delete(ln)
	}
	delete(lower_names)
	delete(fields)

	h2_send_headers(stream.conn, stream.id, header_block, false)
	delete(header_block)
	stream.response_headers_sent = true
	stream.responded = true
	return true
}

h2_response_stream_write :: proc(res: ^ResponseWriter, data: []u8) -> bool {
	if res == nil {
		return false
	}
	stream := (^H2_Stream)(res._internal)
	if stream == nil {
		return false
	}
	if !stream.response_headers_sent {
		if !h2_response_stream_start(res) {
			return false
		}
	}
	if len(data) == 0 {
		return true
	}
	h2_send_data(stream.conn, stream.id, data, false)
	return true
}

h2_response_stream_end :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	stream := (^H2_Stream)(res._internal)
	if stream == nil {
		return
	}
	if !stream.response_headers_sent {
		_ = h2_response_stream_start(res)
	}
	h2_send_data(stream.conn, stream.id, nil, true)
	stream.responded = true
	h2_stream_close(stream.conn, stream)
	stream.conn.h2_close_after_send = true
	if stream.conn.use_tls {
		tls.stream_flush(&stream.conn.tls_stream)
	} else if stream.conn.h2_send_in_flight == 0 {
		conn_close(stream.conn)
	}
}

h2_response_stream_flush :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	stream := (^H2_Stream)(res._internal)
	if stream == nil {
		return false
	}
	if !stream.response_headers_sent {
		return h2_response_stream_start(res)
	}
	return true
}
