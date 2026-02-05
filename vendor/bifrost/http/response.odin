package bifrost_http

import "core:bytes"
import "core:nbio"
import "core:strconv"
import tls "vendor:bifrost/tls"

@(private)
response_writer_init :: proc(res: ^ResponseWriter, internal: rawptr, kind: Response_Internal_Kind) {
	if res == nil {
		return
	}
	res._internal = internal
	res._kind = kind
	switch kind {
	case .HTTP1:
		res._write = response_write_http1
		res._end = response_end_http1
		res._stream_start = response_stream_start_http1
		res._stream_write = response_stream_write_http1
		res._stream_end = response_stream_end_http1
		res._stream_flush = response_stream_flush_http1
	case .HTTP2:
		res._write = h2_response_write
		res._end = h2_response_end
		res._stream_start = h2_response_stream_start
		res._stream_write = h2_response_stream_write
		res._stream_end = h2_response_stream_end
		res._stream_flush = h2_response_stream_flush
	}
}

@(private)
response_write_http1 :: proc(res: ^ResponseWriter, data: []u8) -> bool {
	if res == nil {
		return false
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return false
	}
	_, _ = bytes.buffer_write(&conn.body_buf, data)
	return true
}

response_write :: proc(res: ^ResponseWriter, data: []u8) -> bool {
	if res == nil {
		return false
	}
	if res._write != nil {
		return res._write(res, data)
	}
	if res._kind == .HTTP2 {
		return h2_response_write(res, data)
	}
	return response_write_http1(res, data)
}

response_write_string :: proc(res: ^ResponseWriter, s: string) -> bool {
	if res == nil {
		return false
	}
	if res._write != nil {
		return res._write(res, transmute([]u8)s)
	}
	if res._kind == .HTTP2 {
		return h2_response_write(res, transmute([]u8)s)
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return false
	}
	_, _ = bytes.buffer_write_string(&conn.body_buf, s)
	return true
}

@(private)
response_end_http1 :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return
	}
	if conn.streaming_response {
		response_stream_end_http1(res)
		return
	}
	if conn.responded {
		return
	}
	conn.responded = true

	status := res.Status
	if status == 0 {
		status = Status_OK
	}
	status_text := status_phrase(status)

	body := bytes.buffer_to_bytes(&conn.body_buf)
	if _, ok := header_get(res.Header, "content-length"); !ok {
		buf: [32]u8
		header_set(&res.Header, "content-length", strconv.write_int(buf[:], i64(len(body)), 10))
	}
	close_after := !conn.keep_alive
	if header_has_token(res.Header, "connection", "close") {
		close_after = true
	}
	if header_has_token(res.Header, "connection", "keep-alive") && conn.keep_alive {
		close_after = false
	}
	if conn.stream_body && !conn.body_done {
		close_after = true
	}
	conn.close_after_response = close_after
	if _, ok := header_get(res.Header, "connection"); !ok {
		if close_after {
			header_set(&res.Header, "connection", "close")
		} else if conn.http10 {
			header_set(&res.Header, "connection", "keep-alive")
		}
	}

	resp := new(bytes.Buffer)
	bytes.buffer_init_allocator(resp, 0, 512 + len(body))

	_, _ = bytes.buffer_write_string(resp, "HTTP/1.1 ")
	code_buf: [32]u8
	_, _ = bytes.buffer_write_string(resp, strconv.write_int(code_buf[:], i64(status), 10))
	_, _ = bytes.buffer_write_string(resp, " ")
	_, _ = bytes.buffer_write_string(resp, status_text)
	_, _ = bytes.buffer_write_string(resp, "\r\n")

	for name, vals in res.Header {
		for v in vals {
			_, _ = bytes.buffer_write_string(resp, name)
			_, _ = bytes.buffer_write_string(resp, ": ")
			_, _ = bytes.buffer_write_string(resp, v)
			_, _ = bytes.buffer_write_string(resp, "\r\n")
		}
	}
	_, _ = bytes.buffer_write_string(resp, "\r\n")
	_, _ = bytes.buffer_write(resp, body)

	out := bytes.buffer_to_bytes(resp)

	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		bytes.buffer_destroy(resp)
		free(resp)
		if status == .Error || status == .Closed {
			conn_close(conn)
			return
		}
		if conn.close_after_response {
			tls.stream_close(&conn.tls_stream)
			return
		}
		conn_after_response(conn)
		return
	}

	nbio_send_response(conn, out, resp)
}

response_end :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	if res._end != nil {
		res._end(res)
		return
	}
	if res._kind == .HTTP2 {
		h2_response_end(res)
		return
	}
	response_end_http1(res)
}

nbio_send_response :: proc(conn: ^Conn, out: []u8, resp: ^bytes.Buffer) {
	nbio.send_poly2(conn.socket, {out}, conn, resp, on_send_done, l=conn.server.Loop)
}

on_send_done :: proc(op: ^nbio.Operation, conn: ^Conn, resp: ^bytes.Buffer) {
	if resp != nil {
		bytes.buffer_destroy(resp)
		free(resp)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
		return
	}
	if conn.close_after_response {
		conn_close(conn)
		return
	}
	conn_after_response(conn)
}

@(private)
response_stream_write_http1 :: proc(res: ^ResponseWriter, data: []u8) -> bool {
	if res == nil {
		return false
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return false
	}
	if conn.responded && !conn.streaming_response {
		return false
	}

	if !conn.streaming_response {
		conn.streaming_response = true
		conn.responded = true
	}

	if len(data) == 0 {
		return true
	}

	resp := new(bytes.Buffer)
	bytes.buffer_init_allocator(resp, 0, 256 + len(data))

	if !conn.stream_headers_sent {
		response_stream_headers(res, conn, resp)
	}

	tmp: [32]u8
	size_hex := strconv.write_int(tmp[:], i64(len(data)), 16)
	_, _ = bytes.buffer_write_string(resp, size_hex)
	_, _ = bytes.buffer_write_string(resp, "\r\n")
	_, _ = bytes.buffer_write(resp, data)
	_, _ = bytes.buffer_write_string(resp, "\r\n")

	out := bytes.buffer_to_bytes(resp)

	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		bytes.buffer_destroy(resp)
		free(resp)
		if status == .Error || status == .Closed {
			conn_close(conn)
			return false
		}
		return true
	}

	conn.stream_send_in_flight += 1
	nbio.send_poly2(conn.socket, {out}, conn, resp, on_send_stream_chunk, l=conn.server.Loop)
	return true
}

response_stream_write :: proc(res: ^ResponseWriter, data: []u8) -> bool {
	if res == nil {
		return false
	}
	if res._stream_write != nil {
		return res._stream_write(res, data)
	}
	if res._kind == .HTTP2 {
		return h2_response_stream_write(res, data)
	}
	return response_stream_write_http1(res, data)
}

response_stream_write_string :: proc(res: ^ResponseWriter, s: string) -> bool {
	return response_stream_write(res, transmute([]u8)s)
}

@(private)
response_stream_end_http1 :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return
	}
	if !conn.streaming_response {
		return
	}

	final_str := "0\r\n\r\n"
	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, transmute([]u8)final_str)
		if status == .Error || status == .Closed {
			conn_close(conn)
			return
		}
		if conn.close_after_response {
			tls.stream_close(&conn.tls_stream)
			return
		}
		conn_after_response(conn)
		return
	}

	if conn.stream_end_pending {
		return
	}
	conn.stream_end_pending = true
	resp := new(bytes.Buffer)
	bytes.buffer_init_allocator(resp, 0, len(final_str))
	_, _ = bytes.buffer_write_string(resp, final_str)
	out := bytes.buffer_to_bytes(resp)
	conn.stream_send_in_flight += 1
	nbio.send_poly2(conn.socket, {out}, conn, resp, on_send_stream_end, l=conn.server.Loop)
}

response_stream_end :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	if res._stream_end != nil {
		res._stream_end(res)
		return
	}
	if res._kind == .HTTP2 {
		h2_response_stream_end(res)
		return
	}
	response_stream_end_http1(res)
}

@(private)
response_stream_start_http1 :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return false
	}
	if conn.streaming_response && conn.stream_headers_sent {
		return true
	}
	if !conn.streaming_response {
		conn.streaming_response = true
		conn.responded = true
	}

	resp := new(bytes.Buffer)
	bytes.buffer_init_allocator(resp, 0, 256)
	response_stream_headers(res, conn, resp)
	out := bytes.buffer_to_bytes(resp)

	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		bytes.buffer_destroy(resp)
		free(resp)
		if status == .Error || status == .Closed {
			conn_close(conn)
			return false
		}
		return true
	}

	conn.stream_send_in_flight += 1
	nbio.send_poly2(conn.socket, {out}, conn, resp, on_send_stream_headers, l=conn.server.Loop)
	return true
}

response_stream_start :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	if res._stream_start != nil {
		return res._stream_start(res)
	}
	if res._kind == .HTTP2 {
		return h2_response_stream_start(res)
	}
	return response_stream_start_http1(res)
}

@(private)
response_stream_flush_http1 :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return false
	}
	if conn.responded && !conn.streaming_response {
		return false
	}
	if !conn.stream_headers_sent {
		return response_stream_start_http1(res)
	}
	if conn.use_tls {
		tls.stream_flush(&conn.tls_stream)
	}
	return true
}

response_stream_flush :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	if res._stream_flush != nil {
		return res._stream_flush(res)
	}
	if res._kind == .HTTP2 {
		return h2_response_stream_flush(res)
	}
	return response_stream_flush_http1(res)
}

response_stream_headers :: proc(res: ^ResponseWriter, conn: ^Conn, resp: ^bytes.Buffer) {
	close_after := !conn.keep_alive
	if header_has_token(res.Header, "connection", "close") {
		close_after = true
	}
	if header_has_token(res.Header, "connection", "keep-alive") && conn.keep_alive {
		close_after = false
	}
	conn.close_after_response = close_after

	status := res.Status
	if status == 0 {
		status = Status_OK
	}
	status_text := status_phrase(status)

	header_del(&res.Header, "content-length")
	if _, ok := header_get(res.Header, "transfer-encoding"); !ok {
		header_set(&res.Header, "transfer-encoding", "chunked")
	}
	if _, ok := header_get(res.Header, "connection"); !ok {
		if close_after {
			header_set(&res.Header, "connection", "close")
		} else if conn.http10 {
			header_set(&res.Header, "connection", "keep-alive")
		}
	}

	_, _ = bytes.buffer_write_string(resp, "HTTP/1.1 ")
	code_buf: [32]u8
	_, _ = bytes.buffer_write_string(resp, strconv.write_int(code_buf[:], i64(status), 10))
	_, _ = bytes.buffer_write_string(resp, " ")
	_, _ = bytes.buffer_write_string(resp, status_text)
	_, _ = bytes.buffer_write_string(resp, "\r\n")

	for name, vals in res.Header {
		for v in vals {
			_, _ = bytes.buffer_write_string(resp, name)
			_, _ = bytes.buffer_write_string(resp, ": ")
			_, _ = bytes.buffer_write_string(resp, v)
			_, _ = bytes.buffer_write_string(resp, "\r\n")
		}
	}
	_, _ = bytes.buffer_write_string(resp, "\r\n")
	conn.stream_headers_sent = true
}

response_sse_write :: proc(res: ^ResponseWriter, s: string) -> bool {
	if res == nil {
		return false
	}
	if res.Header == nil {
		res.Header = make(Header)
	}
	if _, ok := header_get(res.Header, "content-type"); !ok {
		header_set(&res.Header, "content-type", "text/event-stream")
	}
	if _, ok := header_get(res.Header, "cache-control"); !ok {
		header_set(&res.Header, "cache-control", "no-cache")
	}
	if _, ok := header_get(res.Header, "connection"); !ok {
		header_set(&res.Header, "connection", "keep-alive")
	}
	return response_stream_write_string(res, s)
}

response_sse_start :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	if res.Header == nil {
		res.Header = make(Header)
	}
	if _, ok := header_get(res.Header, "content-type"); !ok {
		header_set(&res.Header, "content-type", "text/event-stream")
	}
	if _, ok := header_get(res.Header, "cache-control"); !ok {
		header_set(&res.Header, "cache-control", "no-cache")
	}
	if _, ok := header_get(res.Header, "connection"); !ok {
		header_set(&res.Header, "connection", "keep-alive")
	}
	return response_stream_start(res)
}

response_sse_flush :: proc(res: ^ResponseWriter) -> bool {
	if res == nil {
		return false
	}
	if res.Header == nil {
		res.Header = make(Header)
	}
	if _, ok := header_get(res.Header, "content-type"); !ok {
		header_set(&res.Header, "content-type", "text/event-stream")
	}
	if _, ok := header_get(res.Header, "cache-control"); !ok {
		header_set(&res.Header, "cache-control", "no-cache")
	}
	if _, ok := header_get(res.Header, "connection"); !ok {
		header_set(&res.Header, "connection", "keep-alive")
	}
	return response_stream_flush(res)
}

on_send_stream_chunk :: proc(op: ^nbio.Operation, conn: ^Conn, resp: ^bytes.Buffer) {
	if resp != nil {
		bytes.buffer_destroy(resp)
		free(resp)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
		return
	}
	stream_send_done(conn)
}

on_send_stream_headers :: proc(op: ^nbio.Operation, conn: ^Conn, resp: ^bytes.Buffer) {
	if resp != nil {
		bytes.buffer_destroy(resp)
		free(resp)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
		return
	}
	stream_send_done(conn)
}

on_send_stream_end :: proc(op: ^nbio.Operation, conn: ^Conn, resp: ^bytes.Buffer) {
	if resp != nil {
		bytes.buffer_destroy(resp)
		free(resp)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
		return
	}
	stream_send_done(conn)
}

stream_send_done :: proc(conn: ^Conn) {
	if conn == nil {
		return
	}
	if conn.stream_send_in_flight > 0 {
		conn.stream_send_in_flight -= 1
	}
	if !conn.stream_end_pending {
		return
	}
	if conn.stream_send_in_flight > 0 {
		return
	}
	conn.stream_end_pending = false
	if conn.close_after_response {
		conn_close(conn)
		return
	}
	conn_after_response(conn)
}
