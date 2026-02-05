package bifrost_http

import "core:bytes"
import "core:strings"
import "core:nbio"
import "core:strconv"
import tls "vendor:bifrost/tls"

response_write :: proc(res: ^ResponseWriter, data: []u8) -> bool {
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

response_write_string :: proc(res: ^ResponseWriter, s: string) -> bool {
	if res == nil {
		return false
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return false
	}
	_, _ = bytes.buffer_write_string(&conn.body_buf, s)
	return true
}

response_end :: proc(res: ^ResponseWriter) {
	if res == nil {
		return
	}
	conn := (^Conn)(res._internal)
	if conn == nil {
		return
	}
	if conn.responded {
		return
	}
	conn.responded = true

	status := res.Status
	if status == 0 {
		status = 200
	}
	status_text := status_phrase(status)

	body := bytes.buffer_to_bytes(&conn.body_buf)
	if _, ok := header_get(res.Header, "content-length"); !ok {
		var buf: [32]u8
		header_set(&res.Header, "content-length", strconv.append_int(buf[:], i64(len(body)), 10))
	}
	if _, ok := header_get(res.Header, "connection"); !ok {
		header_set(&res.Header, "connection", "close")
	}

	resp := bytes.Buffer{}
	bytes.buffer_init_allocator(&resp, 0, 512 + len(body))

	_, _ = bytes.buffer_write_string(&resp, "HTTP/1.1 ")
	var code_buf: [32]u8
	_, _ = bytes.buffer_write_string(&resp, strconv.append_int(code_buf[:], i64(status), 10))
	_, _ = bytes.buffer_write_string(&resp, " ")
	_, _ = bytes.buffer_write_string(&resp, status_text)
	_, _ = bytes.buffer_write_string(&resp, "\r\n")

	for name, vals in res.Header {
		for v in vals {
			_, _ = bytes.buffer_write_string(&resp, name)
			_, _ = bytes.buffer_write_string(&resp, ": ")
			_, _ = bytes.buffer_write_string(&resp, v)
			_, _ = bytes.buffer_write_string(&resp, "\r\n")
		}
	}
	_, _ = bytes.buffer_write_string(&resp, "\r\n")
	_, _ = bytes.buffer_write(&resp, body)

	out := bytes.buffer_to_bytes(&resp)

	if conn.use_tls {
		_, status := tls.stream_write(&conn.tls_stream, out)
		_ = status
		bytes.buffer_destroy(&resp)
		tls.stream_close(&conn.tls_stream)
		return
	}

	nbio_send_response(conn, out, &resp)
}

nbio_send_response :: proc(conn: ^Conn, out: []u8, resp: ^bytes.Buffer) {
	nbio.send_poly2(conn.socket, {out}, conn, resp, on_send_done, l=conn.server.Loop)
}

on_send_done :: proc(op: ^nbio.Operation, conn: ^Conn, resp: ^bytes.Buffer) {
	if resp != nil {
		bytes.buffer_destroy(resp)
	}
	if conn == nil {
		return
	}
	if op.send.err != nil {
		conn_close(conn)
		return
	}
	nbio.close(conn.socket)
	conn_close(conn)
}

status_phrase :: proc(code: int) -> string {
	switch code {
	case 200: return "OK"
	case 201: return "Created"
	case 204: return "No Content"
	case 301: return "Moved Permanently"
	case 302: return "Found"
	case 304: return "Not Modified"
	case 400: return "Bad Request"
	case 401: return "Unauthorized"
	case 403: return "Forbidden"
	case 404: return "Not Found"
	case 405: return "Method Not Allowed"
	case 413: return "Payload Too Large"
	case 426: return "Upgrade Required"
	case 431: return "Request Header Fields Too Large"
	case 500: return "Internal Server Error"
	case 502: return "Bad Gateway"
	case 503: return "Service Unavailable"
	case: return "OK"
	}
}
