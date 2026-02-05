package tests_bifrost

import "core:bytes"
import "core:log"
import "core:nbio"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"
import "base:runtime"
import os "core:os/os2"
import http "vendor:bifrost/http"
import tls "vendor:bifrost/tls"

TLS_TEST_CERT_PEM: string = "-----BEGIN CERTIFICATE-----\n" +
	"MIIDCTCCAfGgAwIBAgIUCAequJqK/9OZt7XHPq6p7xM0xfcwDQYJKoZIhvcNAQEL\n" +
	"BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI2MDIwNTExNDA0NVoXDTI2MDIw\n" +
	"NjExNDA0NVowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEF\n" +
	"AAOCAQ8AMIIBCgKCAQEA6r9S81u0dp055iIBWjBcrFkuolpEkVetqvngnmQGV0sO\n" +
	"XhjBi3IVKztzpPvx9ffWxlFoVE7a7NsbZkt5SdUaR7zT9XMblr2QNvOSbYnU0o61\n" +
	"FzYdsCYN6G1+WiEM5X1fpE6/ZuZclSNwCgJDRJv956kZtoRshcdzOGxNjo3SzEDa\n" +
	"uo11ecclX8MBLi8J45rfBdL5BEHGCz86WD1PFAGFHZrB055ZE8AMJ5in70fKXDIs\n" +
	"isvkuOz5AddVQky7nCQ9iRigJCi+iyn1eLxWUn5RjuI7Vp6RMW8MErbOGM0oeHbP\n" +
	"46SUpG/afvE7hi3dAUjTMKdSBn8l36hu0fA6GB0R4QIDAQABo1MwUTAdBgNVHQ4E\n" +
	"FgQUdCqbrytD4Nhqi4QTY3bOf9Lq95EwHwYDVR0jBBgwFoAUdCqbrytD4Nhqi4QT\n" +
	"Y3bOf9Lq95EwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAUjpq\n" +
	"/REixn8s7T5fZe0oKUmMT/b1Yz859c88i8noHEg1Y0Tbds/iSrx/OlzTuEN7fm1e\n" +
	"vuzNTi8UiOCLaCn8qbQ1JaPhyh2TMWHlKyHZxtNA2muXiqpabwFL9LRJsZwOv6mj\n" +
	"XSH4AuqjYpL6SI/m9GaLqHz499s29pONeg+ykT+SSfNrD1h3avg0zhO6qx9FhtVG\n" +
	"yR6BQiHP7Byftcn+wsCUZG9OI4vIQlDhHxv+0bG9X+kbtkOiXTtW1UJ7jraounKf\n" +
	"gfqm4QtBcZbwZ992B1Ti75+cqdlFWgeIddPhjT5lV698ZdPwfSMnp+HSeR2EWjF6\n" +
	"TiQZFzlInX9mBmhLkg==\n" +
	"-----END CERTIFICATE-----\n"

TLS_TEST_KEY_PEM: string = "-----BEGIN PRIVATE KEY-----\n" +
	"MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDqv1LzW7R2nTnm\n" +
	"IgFaMFysWS6iWkSRV62q+eCeZAZXSw5eGMGLchUrO3Ok+/H199bGUWhUTtrs2xtm\n" +
	"S3lJ1RpHvNP1cxuWvZA285JtidTSjrUXNh2wJg3obX5aIQzlfV+kTr9m5lyVI3AK\n" +
	"AkNEm/3nqRm2hGyFx3M4bE2OjdLMQNq6jXV5xyVfwwEuLwnjmt8F0vkEQcYLPzpY\n" +
	"PU8UAYUdmsHTnlkTwAwnmKfvR8pcMiyKy+S47PkB11VCTLucJD2JGKAkKL6LKfV4\n" +
	"vFZSflGO4jtWnpExbwwSts4YzSh4ds/jpJSkb9p+8TuGLd0BSNMwp1IGfyXfqG7R\n" +
	"8DoYHRHhAgMBAAECggEAC5jpqnOyofSJDn1KF1BR18LtKqCuiAauogaHyhNze78N\n" +
	"xejPsQmxEYp1n2ZCES6OGgyeDKI7rx1xCFf8tUDVtEsYJqVp7MPPOuPELWy0irV5\n" +
	"rVyjUVdD8yJrrly5JCJSRg4M5zLEyqpuR9ROSfax7867Ijj/Goncv6IcH8mSazxF\n" +
	"xxFm+aNfNopfZwORldpn+Qp8UTFi9CXzzMbK1bHJ2PVbGyi5q2lyRgCVFfitQOAm\n" +
	"raMh0M5o/LDeDzyLPOuERA+lYgIGhEtrTn/gYC9q/EAKpCQ9LV2INF779A2tw/dT\n" +
	"mMvb8yFFjqJAHZZrXohMlSZlR0Kf61+YUSfdgJGk9QKBgQD7qjlXkCRVYXkfaTxq\n" +
	"2LPJ5JrU0+HL4CLaRXMueIgLAj79mFAxNNJcUjv1Wz5UzdOS8gAGFXU3raeZmuKY\n" +
	"ckZwJggH7LoMqOe193+UTI/RUKOUHYqkjU1lGpmQuEdlOrG+bwCP/fToeiWvlZnm\n" +
	"GgDOPs2sUTg2myEaqBZwZP9JLQKBgQDuyn97WOA9XrlfCmQOHlWIknd3Nxlq+ZAY\n" +
	"JMUjKIVQYR6GGndX899DHrpnsoQxfq6mvR98rdjn2KzWT6laiIJx9ZVaWp/kezgt\n" +
	"wrrmWYWk79PhqLDT8bMcVRomdt5K8uLF0W3528YakWRTCz2bTs573auEaJHbPnqV\n" +
	"eRTbwIG0BQKBgBRcIyN4X9ggeKIX63FhcrokqnoJYj0SNv+dmsHpsmfhmKL/jY1N\n" +
	"jq81X/Brn1FRDYrX1TSoy8DjZanBpA9dP2GXUhMCDdM0XvqTuViQERqIAZPcB/lk\n" +
	"DRze2AmjPvNrmjGj3VHI4+Vi7GWWHstE00fcQNtt/rQ8PKNhcd9J7HVJAoGBAJ+Z\n" +
	"0ukDdyUtmaJvVH6nQa39j0GsHx4D3Y51jRm5rJkTwI4LRHcRtcir0hUbGQXn0R36\n" +
	"y//ORmp3xNWc+ula0i0O4ps4dSQGQ386Zycs8IlUDn8F++I86uTl8IuC6YKYon9r\n" +
	"QiE9BkSdprtmiO+0FYhumYPvTIWIVfBvtERIf6htAoGBAJ1ykSJujOJImLWyML2C\n" +
	"+MA5Hd5ELrHQ1dDGYCUmGOt4AjLM2cCyKc9U5zRXAyomr7/vcdBD4QJ/eNIEg87J\n" +
	"allnOlCPA3UiRuHFWwPDDB2cA4T4K1VUIfWorfbrLe4mSjaVcORMR2/CXeyq03WL\n" +
	"k63oSfJm9XKEmXgHpSKzSKVg\n" +
	"-----END PRIVATE KEY-----\n"

write_tls_test_files :: proc(t: ^testing.T) -> (temp_dir, cert_path, key_path: string) {
	derr: os.Error
	temp_dir, derr = os.make_directory_temp("", "bifrost_tls_*", context.allocator)
	ev(t, derr, nil)
	perr: os.Error
	cert_path, perr = os.join_path({temp_dir, "cert.pem"}, context.allocator)
	ev(t, perr, nil)
	kerr: os.Error
	key_path, kerr = os.join_path({temp_dir, "key.pem"}, context.allocator)
	ev(t, kerr, nil)

	cf, cerr := os.open(cert_path, {.Write, .Create, .Trunc})
	ev(t, cerr, nil)
	_, werr := os.write(cf, transmute([]u8)TLS_TEST_CERT_PEM)
	ev(t, werr, nil)
	os.close(cf)

	kf, kerr2 := os.open(key_path, {.Write, .Create, .Trunc})
	ev(t, kerr2, nil)
	_, werr2 := os.write(kf, transmute([]u8)TLS_TEST_KEY_PEM)
	ev(t, werr2, nil)
	os.close(kf)

	return
}

ev :: testing.expect_value
e  :: testing.expect

@(deferred_in=event_loop_guard_exit)
event_loop_guard :: proc(t: ^testing.T) -> bool {
	err := nbio.acquire_thread_event_loop()
	if err == .Unsupported || !nbio.FULLY_SUPPORTED {
		log.warn("nbio unsupported, skipping")
		return false
	}
	ev(t, err, nil)
	return true
}

event_loop_guard_exit :: proc(t: ^testing.T) {
	nbio.release_thread_event_loop()
}

Server_State :: struct {
	t: ^testing.T,
	server: nbio.TCP_Socket,
	client: nbio.TCP_Socket,
	recv_tmp: [4096]u8,
	in_buf: [dynamic]u8,
	header_parsed: bool,
	body_start: int,
	parse_pos: int,
	chunk_state: http.Chunk_State,
	chunk_size: int,
	body: bytes.Buffer,
	expected: string,
	resp: []u8,
	sent: bool,
}

KeepAlive_Client_State :: struct {
	t: ^testing.T,
	client: ^http.Client,
	endpoint: nbio.Endpoint,
	done: ^bool,
}

keepalive_client_cb :: proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
	state := (^KeepAlive_Client_State)(req.User)
	if state == nil || state.t == nil {
		return
	}
	ev(state.t, err.Kind, http.Client_Error_Kind.None)
	if err.Kind == .None {
		ev(state.t, res.Status, http.Status_OK)
		ev(state.t, string(res.Body), "ok")
	}
	if state.done != nil {
		state.done^ = true
	}
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

http1_status_line :: proc(status: int, text: string) -> string {
	buf: [64]byte
	n := 0
	n += copy(buf[n:], "HTTP/1.1 ")
	code := strconv.write_int(buf[n:], i64(status), 10)
	n += len(code)
	n += copy(buf[n:], " ")
	n += copy(buf[n:], text)
	n += copy(buf[n:], "\r\n")
	return string(buf[:n])
}

@test
test_h2_frame_header_roundtrip :: proc(t: ^testing.T) {
	hdr := http.H2_Frame_Header{
		Length = 1024,
		Type = .Headers,
		Flags = http.H2_FLAG_END_STREAM | http.H2_FLAG_END_HEADERS,
		Stream_ID = 1,
	}
	buf := make([]u8, http.H2_FRAME_HEADER_LEN)
	ok := http.h2_frame_header_write(hdr, buf)
	ev(t, ok, true)

	parsed, pok := http.h2_frame_header_parse(buf)
	ev(t, pok, true)
	ev(t, parsed.Length, hdr.Length)
	ev(t, parsed.Type, hdr.Type)
	ev(t, parsed.Flags, hdr.Flags)
	ev(t, parsed.Stream_ID, hdr.Stream_ID)
	delete(buf)
}

@test
test_h2_frame_header_reserved_bit :: proc(t: ^testing.T) {
	buf := make([]u8, http.H2_FRAME_HEADER_LEN)
	_ = http.h2_frame_header_write(http.H2_Frame_Header{
		Length = 0,
		Type = .Ping,
		Flags = 0,
		Stream_ID = 1,
	}, buf)

	// Set the reserved bit in the stream id.
	buf[5] = buf[5] | 0x80

	parsed, ok := http.h2_frame_header_parse(buf)
	ev(t, ok, true)
	ev(t, parsed.Stream_ID, u32(1))
	delete(buf)
}

@test
test_h2_hpack_encode_decode_literal :: proc(t: ^testing.T) {
	enc_headers := []http.H2_Hpack_Field{
		{Name = ":method", Value = "GET"},
		{Name = "content-type", Value = "text/plain"},
	}
	encoded := http.h2_hpack_encode_literal(enc_headers)

	dec: http.H2_Hpack_Decoder
	http.h2_hpack_decoder_init(&dec, 4096)
	decoded, err := http.h2_hpack_decode(&dec, encoded)
	ev(t, err, http.H2_Hpack_Error.None)
	ev(t, len(decoded), 2)
	if len(decoded) >= 2 {
		ev(t, decoded[0].Name, enc_headers[0].Name)
		ev(t, decoded[0].Value, enc_headers[0].Value)
		ev(t, decoded[1].Name, enc_headers[1].Name)
		ev(t, decoded[1].Value, enc_headers[1].Value)
	}
	http.h2_hpack_fields_free(decoded[:])
	delete(decoded)
	http.h2_hpack_decoder_free(&dec)
	delete(encoded)
}

parse_int_safe :: proc(s: string, base: int = 10) -> (n: int, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	return strconv.parse_int(s, base)
}

copy_string :: proc(s: string) -> string {
	if len(s) == 0 {
		return ""
	}
	buf := make([]u8, len(s))
	copy(buf, transmute([]u8)s)
	return string(buf)
}

free_string :: proc(s: string) {
	if len(s) == 0 {
		return
	}
	buf := transmute([]u8)s
	delete(buf)
}

server_consume :: proc(state: ^Server_State, n: int) {
	if state == nil || n <= 0 {
		return
	}
	if n >= len(state.in_buf) {
		resize(&state.in_buf, 0)
		return
	}
	copy(state.in_buf[:], state.in_buf[n:])
	resize(&state.in_buf, len(state.in_buf)-n)
}

server_on_accept :: proc(op: ^nbio.Operation, state: ^Server_State) {
	if state == nil {
		return
	}
	ev(state.t, op.accept.err, nil)
	state.client = op.accept.client
	nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, server_on_recv, l=nbio.current_thread_event_loop())
}

server_on_recv :: proc(op: ^nbio.Operation, state: ^Server_State) {
	if state == nil {
		return
	}
	if op.recv.err != nil || op.recv.received == 0 {
		testing.fail_now(state.t)
	}
	append(&state.in_buf, ..state.recv_tmp[:op.recv.received])

	done, ok := server_process_buffer(state)
	if !ok {
		testing.fail_now(state.t)
	}
	if done && !state.sent {
		state.sent = true
		body := bytes.buffer_to_bytes(&state.body)
		ev(state.t, string(body), state.expected)

		resp_str := http1_status_line(http.Status_OK, http.Status_Text_OK) +
			"Transfer-Encoding: chunked\r\nConnection: close\r\n\r\n5\r\nworld\r\n0\r\n\r\n"
		state.resp = make([]u8, len(resp_str))
		runtime.copy_from_string(state.resp[:], resp_str)
		nbio.send_poly(state.client, {state.resp}, state, server_on_send, l=nbio.current_thread_event_loop())
		return
	}

	nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, server_on_recv, l=nbio.current_thread_event_loop())
}

server_on_send :: proc(op: ^nbio.Operation, state: ^Server_State) {
	if state == nil {
		return
	}
	ev(state.t, op.send.err, nil)
	nbio.close(state.client)
	nbio.close(state.server)
	bytes.buffer_destroy(&state.body)
	delete(state.in_buf)
	delete(state.resp)
	free(state)
}

server_process_buffer :: proc(state: ^Server_State) -> (done: bool, ok: bool) {
	if state == nil {
		return false, false
	}

	if !state.header_parsed {
		idx := find_header_end(state.in_buf[:])
		if idx < 0 {
			return false, true
		}
		state.header_parsed = true
		state.body_start = idx + 4
		state.parse_pos = state.body_start
		state.chunk_state = .Size

		raw := string(state.in_buf[:state.body_start])
		lines, _ := strings.split(raw, "\r\n", context.temp_allocator)
		has_chunked := false
		for i in 1..<len(lines) {
			line := lines[i]
			if len(line) == 0 {
				break
			}
			colon := strings.index_byte(line, ':')
			if colon < 0 {
				continue
			}
			name := strings.trim_space(line[:colon])
			value := strings.trim_space(line[colon+1:])
			if strings.equal_fold(name, "transfer-encoding") && strings.equal_fold(value, "chunked") {
				has_chunked = true
				break
			}
		}
		if !has_chunked {
			return false, false
		}
	}

	for {
		switch state.chunk_state {
		case .Size:
			idx := find_crlf(state.in_buf[:], state.parse_pos)
			if idx < 0 {
				return false, true
			}
			line := string(state.in_buf[state.parse_pos:idx])
			if semi := strings.index_byte(line, ';'); semi >= 0 {
				line = line[:semi]
			}
			line = strings.trim_space(line)
			if len(line) == 0 {
				return false, false
			}
			size, ok := parse_int_safe(line, 16)
			if !ok || size < 0 {
				return false, false
			}
			state.chunk_size = size
			state.parse_pos = idx + 2
			if size == 0 {
				state.chunk_state = .Trailer
			} else {
				state.chunk_state = .Data
			}
		case .Data:
			need := state.chunk_size + 2
			remaining := len(state.in_buf) - state.parse_pos
			if remaining < need {
				return false, true
			}
			_, _ = bytes.buffer_write(&state.body, state.in_buf[state.parse_pos:state.parse_pos+state.chunk_size])
			state.parse_pos += state.chunk_size
			if state.in_buf[state.parse_pos] != '\r' || state.in_buf[state.parse_pos+1] != '\n' {
				return false, false
			}
			state.parse_pos += 2
			state.chunk_state = .Size
			if state.parse_pos > 0 {
				server_consume(state, state.parse_pos)
				state.parse_pos = 0
				state.body_start = 0
			}
		case .Trailer:
			remaining := len(state.in_buf) - state.parse_pos
			if remaining >= 2 && state.in_buf[state.parse_pos] == '\r' && state.in_buf[state.parse_pos+1] == '\n' {
				state.parse_pos += 2
				server_consume(state, state.parse_pos)
				state.parse_pos = 0
				state.body_start = 0
				return true, true
			}
			offset := find_header_end(state.in_buf[state.parse_pos:])
			if offset < 0 {
				return false, true
			}
			state.parse_pos += offset + 4
			server_consume(state, state.parse_pos)
			state.parse_pos = 0
			state.body_start = 0
			return true, true
		}
	}
}

Body_Stream_State :: struct {
	chunks: [2][]u8,
	index: int,
	t: ^testing.T,
	done: ^bool,
}

body_stream :: proc(user: rawptr) -> (data: []u8, done: bool, ok: bool) {
	state := (^Body_Stream_State)(user)
	if state == nil {
		return nil, true, false
	}
	if state.index >= len(state.chunks) {
		return nil, true, true
	}
	data = state.chunks[state.index]
	state.index += 1
	done = state.index >= len(state.chunks)
	return data, done, true
}

client_consume :: proc(buf: ^[dynamic]u8, n: int) {
	if buf == nil || n <= 0 {
		return
	}
	if n >= len(buf^) {
		resize(buf, 0)
		return
	}
	copy(buf^[:], buf^[n:])
	resize(buf, len(buf^)-n)
}

parse_one_response :: proc(buf: []u8) -> (consumed: int, status: int, body: string, ok: bool) {
	idx := find_header_end(buf)
	if idx < 0 {
		return
	}
	header := string(buf[:idx])
	lines, _ := strings.split(header, "\r\n", context.temp_allocator)
	if len(lines) < 1 {
		return
	}
	parts, _ := strings.split(lines[0], " ", context.temp_allocator)
	if len(parts) < 2 {
		return
	}
	if len(parts[1]) == 0 {
		return
	}
	code, ok_code := parse_int_safe(parts[1])
	if !ok_code {
		return
	}
	content_length := -1
	for i in 1..<len(lines) {
		line := lines[i]
		if len(line) == 0 {
			continue
		}
		colon := strings.index_byte(line, ':')
		if colon < 0 {
			continue
		}
		name := strings.trim_space(line[:colon])
		value := strings.trim_space(line[colon+1:])
		if strings.equal_fold(name, "content-length") {
			if len(value) == 0 {
				continue
			}
			if n, ok := parse_int_safe(value); ok {
				content_length = n
			}
		}
	}
	if content_length < 0 {
		return
	}
	body_start := idx + 4
	if len(buf) < body_start+content_length {
		return
	}
	body = string(buf[body_start : body_start+content_length])
	return body_start + content_length, code, body, true
}

raw_request_exchange :: proc(t: ^testing.T, ep: nbio.Endpoint, server: nbio.TCP_Socket, req: string, expected_status: int, close_server: bool = true) {
	Client_State :: struct {
		t: ^testing.T,
		server: nbio.TCP_Socket,
		socket: nbio.TCP_Socket,
		recv_tmp: [4096]u8,
		in_buf: [dynamic]u8,
		send_buf: []u8,
		req: string,
		expected_status: int,
		close_server: bool,
		done: bool,
	}

	state := new(Client_State)
	state.t = t
	state.server = server
	state.in_buf = make([dynamic]u8, 0, 4096)
	state.req = req
	state.expected_status = expected_status
	state.close_server = close_server

	on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
		if op.recv.err != nil {
			testing.fail_now(state.t)
		}
		if op.recv.received == 0 {
			testing.fail_now(state.t)
		}
		append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
		consumed, status, _, ok := parse_one_response(state.in_buf[:])
		if ok {
			ev(state.t, status, state.expected_status)
			client_consume(&state.in_buf, consumed)
			nbio.close(state.socket)
			if state.close_server {
				nbio.close(state.server)
			}
			state.done = true
			delete(state.in_buf)
			free(state)
			return
		}
		nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
	}

	on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
		ev(state.t, op.send.err, nil)
		if state.send_buf != nil {
			delete(state.send_buf)
			state.send_buf = nil
		}
		nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
	}

	on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
		ev(state.t, op.dial.err, nil)
		state.socket = op.dial.socket
		state.send_buf = make([]u8, len(state.req))
		runtime.copy_from_string(state.send_buf, state.req)
		nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
	}

	nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())
	ev(t, nbio.run_until(&state.done), nil)
}

raw_request_exchange_body :: proc(t: ^testing.T, ep: nbio.Endpoint, server: nbio.TCP_Socket, req: string, expected_status: int, out_body: ^string, close_server: bool = true) {
	Client_State :: struct {
		t: ^testing.T,
		server: nbio.TCP_Socket,
		socket: nbio.TCP_Socket,
		recv_tmp: [4096]u8,
		in_buf: [dynamic]u8,
		send_buf: []u8,
		req: string,
		expected_status: int,
		close_server: bool,
		out_body: ^string,
		done: bool,
	}

	state := new(Client_State)
	state.t = t
	state.server = server
	state.in_buf = make([dynamic]u8, 0, 4096)
	state.req = req
	state.expected_status = expected_status
	state.close_server = close_server
	state.out_body = out_body

	on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
		if op.recv.err != nil {
			testing.fail_now(state.t)
		}
		if op.recv.received == 0 {
			testing.fail_now(state.t)
		}
		append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
		consumed, status, body, ok := parse_one_response(state.in_buf[:])
		if ok {
			ev(state.t, status, state.expected_status)
			if state.out_body != nil {
				state.out_body^ = copy_string(body)
			}
			client_consume(&state.in_buf, consumed)
			nbio.close(state.socket)
			if state.close_server {
				nbio.close(state.server)
			}
			state.done = true
			delete(state.in_buf)
			free(state)
			return
		}
		nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
	}

	on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
		ev(state.t, op.send.err, nil)
		if state.send_buf != nil {
			delete(state.send_buf)
			state.send_buf = nil
		}
		nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
	}

	on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
		ev(state.t, op.dial.err, nil)
		state.socket = op.dial.socket
		state.send_buf = make([]u8, len(state.req))
		runtime.copy_from_string(state.send_buf, state.req)
		nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
	}

	nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())
	ev(t, nbio.run_until(&state.done), nil)
}

raw_response_exchange :: proc(t: ^testing.T, resp: string, expected_err: http.Client_Error_Kind, expected_status: int = 0) {
	Client_State :: struct {
		t: ^testing.T,
		expected_err: http.Client_Error_Kind,
		expected_status: int,
		done: ^bool,
	}

	Server_State :: struct {
		t: ^testing.T,
		server: nbio.TCP_Socket,
		client: nbio.TCP_Socket,
		recv_tmp: [1024]u8,
		resp: []u8,
		sent: bool,
	}

	server, err := nbio.listen_tcp({nbio.IP4_Loopback, 0})
	ev(t, err, nil)
	ep, eperr := nbio.bound_endpoint(server)
	ev(t, eperr, nil)

	state := new(Server_State)
	state.t = t
	state.server = server
	state.resp = make([]u8, len(resp))
	runtime.copy_from_string(state.resp, resp)

	on_send :: proc(op: ^nbio.Operation, state: ^Server_State) {
		if op.send.err != nil {
			testing.fail_now(state.t)
		}
		nbio.close(state.client)
		nbio.close(state.server)
		delete(state.resp)
		free(state)
	}

	on_recv :: proc(op: ^nbio.Operation, state: ^Server_State) {
		if op.recv.err != nil {
			testing.fail_now(state.t)
		}
		if op.recv.received == 0 {
			testing.fail_now(state.t)
		}
		if state.sent {
			return
		}
		state.sent = true
		nbio.send_poly(state.client, {state.resp}, state, on_send, l=nbio.current_thread_event_loop())
	}

	on_accept :: proc(op: ^nbio.Operation, state: ^Server_State) {
		ev(state.t, op.accept.err, nil)
		state.client = op.accept.client
		nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
	}

	nbio.accept_poly(server, state, on_accept, l=nbio.current_thread_event_loop())

	done := false
	client_state := Client_State{
		t = t,
		expected_err = expected_err,
		expected_status = expected_status,
		done = &done,
	}

	cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
		state := (^Client_State)(req.User)
		if state == nil {
			return
		}
		ev(state.t, err.Kind, state.expected_err)
		if err.Kind == .None {
			ev(state.t, res.Status, state.expected_status)
		}
		if state.done != nil {
			state.done^ = true
		}
	}

	client := http.Client{Loop = nbio.current_thread_event_loop()}
	req := http.Request{
		Method = "GET",
		Target = "/",
		Header = make(http.Header),
		User = &client_state,
	}
	http.client_do(&client, ep, "localhost", &req, cb)

	ev(t, nbio.run_until(&done), nil)
	e(t, done)
	if client.Transport != nil {
		http.transport_destroy(client.Transport)
		client.Transport = nil
	}
}

header_has_value :: proc(header: string, name, value: string) -> bool {
	lines, _ := strings.split(header, "\r\n", context.temp_allocator)
	for i in 1..<len(lines) {
		line := lines[i]
		if len(line) == 0 {
			continue
		}
		colon := strings.index_byte(line, ':')
		if colon < 0 {
			continue
		}
		key := strings.trim_space(line[:colon])
		val := strings.trim_space(line[colon+1:])
		if strings.equal_fold(key, name) && strings.equal_fold(val, value) {
			return true
		}
	}
	return false
}

@(test)
chunked_upload_and_response :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, err := nbio.listen_tcp({nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(server)
		ev(t, eperr, nil)

		state := new(Server_State)
		state.t = t
		state.server = server
		state.in_buf = make([dynamic]u8, 0, 4096)
		state.expected = "hello"
		bytes.buffer_init_allocator(&state.body, 0, 64)

		nbio.accept_poly(server, state, server_on_accept, l=nbio.current_thread_event_loop())

		done := false
		body_state := Body_Stream_State{
			chunks = {transmute([]u8)string("he"), transmute([]u8)string("llo")},
			t = t,
			done = &done,
		}
		req := http.Request{
			Method = "POST",
			Target = "/upload",
			Header = make(http.Header),
			Body_Stream = body_stream,
			Body_Stream_User = &body_state,
		}

		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^Body_Stream_State)(req.Body_Stream_User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			ev(state.t, res.Status, http.Status_OK)
			ev(state.t, string(res.Body), "world")
			if state.done != nil {
				state.done^ = true
			}
		}

		client := http.Client{Loop = nbio.current_thread_event_loop()}
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)
		http.header_reset(&req.Header)
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
	}
}

@(test)
server_basic_get :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write_string(res, "ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			consumed, status, body, ok := parse_one_response(state.in_buf[:])
			if ok {
				ev(state.t, status, http.Status_OK)
				ev(state.t, body, "ok")
				client_consume(&state.in_buf, consumed)
				nbio.close(state.socket)
				nbio.close(state.server)
				state.done = true
				delete(state.in_buf)
				free(state)
				return
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "GET / HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_tls_basic_get :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		temp_dir, cert_path, key_path := write_tls_test_files(t)

		server_tls := tls.Config{
			alpn = []tls.ALPN_Protocol{.HTTP1_1},
			cert_chain_file = cert_path,
			key_file = key_path,
		}

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			TLS = &server_tls,
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write_string(res, "tls ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		TLS_Client_State :: struct {
			t: ^testing.T,
			done: ^bool,
		}

		done := false
		state := TLS_Client_State{t = t, done = &done}
		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^TLS_Client_State)(req.User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), "tls ok")
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		client_tls := tls.Config{verify_peer = false}
		client := http.Client{Loop = nbio.current_thread_event_loop(), TLS = &client_tls}
		req := http.Request{
			Method = "GET",
			Target = "/",
			Header = make(http.Header),
			User = &state,
		}
		http.header_set(&req.Header, "connection", "close")
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)

		http.header_reset(&req.Header)
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
		nbio.close(sock)
		for _ in 0..<128 {
			_ = nbio.tick(1 * time.Millisecond)
		}
		if server._tls_ctx != nil {
			tls.context_free(server._tls_ctx)
			free(server._tls_ctx)
			server._tls_ctx = nil
		}
		os.remove(cert_path)
		os.remove(key_path)
		os.remove(temp_dir)
		delete(cert_path)
		delete(key_path)
		delete(temp_dir)
	}
}

@(test)
client_http2_tls_alpn :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		temp_dir, cert_path, key_path := write_tls_test_files(t)

		server_tls := tls.Config{
			alpn = []tls.ALPN_Protocol{.HTTP2, .HTTP1_1},
			cert_chain_file = cert_path,
			key_file = key_path,
		}

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			TLS = &server_tls,
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write_string(res, "h2 tls ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		H2_TLS_State :: struct {
			t: ^testing.T,
			done: ^bool,
		}

		done := false
		state := H2_TLS_State{t = t, done = &done}
		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^H2_TLS_State)(req.User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), "h2 tls ok")
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		client_tls := tls.Config{
			verify_peer = false,
			alpn = []tls.ALPN_Protocol{.HTTP2, .HTTP1_1},
		}
		client := http.Client{Loop = nbio.current_thread_event_loop(), TLS = &client_tls}
		req := http.Request{
			Method = "GET",
			Target = "/",
			Proto = "HTTP/2.0",
			Header = make(http.Header),
			User = &state,
		}
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)

		http.header_reset(&req.Header)
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
		nbio.close(sock)
		for _ in 0..<128 {
			_ = nbio.tick(1 * time.Millisecond)
		}
		if server._tls_ctx != nil {
			tls.context_free(server._tls_ctx)
			free(server._tls_ctx)
			server._tls_ctx = nil
		}
		os.remove(cert_path)
		os.remove(key_path)
		os.remove(temp_dir)
		delete(cert_path)
		delete(key_path)
		delete(temp_dir)
	}
}

@(test)
client_http2_tls_streaming_upload :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		temp_dir, cert_path, key_path := write_tls_test_files(t)

		server_tls := tls.Config{
			alpn = []tls.ALPN_Protocol{.HTTP2, .HTTP1_1},
			cert_chain_file = cert_path,
			key_file = key_path,
		}

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			TLS = &server_tls,
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				ev(t, req.Proto, "HTTP/2.0")
				ev(t, string(req.Body), "hello")
				res.Status = http.Status_OK
				http.response_write_string(res, "ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		H2_TLS_State :: struct {
			t: ^testing.T,
			done: ^bool,
		}

		done := false
		state := H2_TLS_State{t = t, done = &done}
		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^H2_TLS_State)(req.User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), "ok")
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		client_tls := tls.Config{
			verify_peer = false,
			alpn = []tls.ALPN_Protocol{.HTTP2, .HTTP1_1},
		}
		body_state := Body_Stream_State{
			chunks = {[]u8("he"), []u8("llo")},
		}
		client := http.Client{Loop = nbio.current_thread_event_loop(), TLS = &client_tls}
		req := http.Request{
			Method = "POST",
			Target = "/upload",
			Proto = "HTTP/2.0",
			Header = make(http.Header),
			Body_Stream = body_stream,
			Body_Stream_User = &body_state,
			User = &state,
		}
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)

		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
		nbio.close(sock)
		for _ in 0..<128 {
			_ = nbio.tick(1 * time.Millisecond)
		}
		if server._tls_ctx != nil {
			tls.context_free(server._tls_ctx)
			free(server._tls_ctx)
			server._tls_ctx = nil
		}
		os.remove(cert_path)
		os.remove(key_path)
		os.remove(temp_dir)
		delete(cert_path)
		delete(key_path)
		delete(temp_dir)
	}
}

@(test)
client_http2_prior_knowledge :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write_string(res, "h2 ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		H2_Client_State :: struct {
			t: ^testing.T,
			done: ^bool,
		}

		done := false
		state := H2_Client_State{t = t, done = &done}
		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^H2_Client_State)(req.User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), "h2 ok")
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		client := http.Client{Loop = nbio.current_thread_event_loop()}
		req := http.Request{
			Method = "GET",
			Target = "/",
			Proto = "HTTP/2.0",
			Header = make(http.Header),
			User = &state,
		}
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)
		nbio.close(sock)
		for _ in 0..<128 {
			_ = nbio.tick(1 * time.Millisecond)
		}
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
	}
}

@(test)
client_http2_h2c_upgrade :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write_string(res, "h2 upgrade ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		H2_Client_State :: struct {
			t: ^testing.T,
			done: ^bool,
		}

		done := false
		state := H2_Client_State{t = t, done = &done}
		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^H2_Client_State)(req.User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), "h2 upgrade ok")
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		client := http.Client{Loop = nbio.current_thread_event_loop()}
		req := http.Request{
			Method = "GET",
			Target = "/",
			Proto = "HTTP/2.0",
			Header = make(http.Header),
			User = &state,
		}
		http.header_set(&req.Header, "upgrade", "h2c")
		defer http.header_reset(&req.Header)
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
		nbio.close(sock)
	}
}

@(test)
client_http2_streaming_upload :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				ev(t, req.Proto, "HTTP/2.0")
				ev(t, string(req.Body), "hello")
				res.Status = http.Status_OK
				http.response_write_string(res, "ok")
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Stream_State :: struct {
			t: ^testing.T,
			done: ^bool,
		}

		done := false
		state := Stream_State{t = t, done = &done}
		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^Stream_State)(req.User)
			if state == nil || state.t == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), "ok")
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		body_state := Body_Stream_State{
			chunks = {[]u8("he"), []u8("llo")},
		}
		client := http.Client{Loop = nbio.current_thread_event_loop()}
		req := http.Request{
			Method = "POST",
			Target = "/upload",
			Proto = "HTTP/2.0",
			Header = make(http.Header),
			Body_Stream = body_stream,
			Body_Stream_User = &body_state,
			User = &state,
		}
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)

		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
		nbio.close(sock)
		for _ in 0..<64 {
			_ = nbio.tick(1 * time.Millisecond)
		}
	}
}

@(test)
server_keep_alive_two_requests :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				if req.Target == "/one" {
					http.response_write_string(res, "one")
				} else {
					http.response_write_string(res, "two")
				}
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			got: int,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			for {
				consumed, status, body, ok := parse_one_response(state.in_buf[:])
				if !ok {
					break
				}
				ev(state.t, status, http.Status_OK)
				if state.got == 0 {
					ev(state.t, body, "one")
				} else {
					ev(state.t, body, "two")
				}
				state.got += 1
				client_consume(&state.in_buf, consumed)
				if state.got == 2 {
					nbio.close(state.socket)
					nbio.close(state.server)
					state.done = true
					delete(state.in_buf)
					free(state)
					return
				}
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "GET /one HTTP/1.1\r\nHost: localhost\r\nConnection: keep-alive\r\n\r\nGET /two HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
client_keep_alive_reuse :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server, err := nbio.listen_tcp({nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(server)
		ev(t, eperr, nil)

		Server_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			client: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			sending: bool,
			req_count: int,
			accept_count: ^int,
			resp_buf: []u8,
			done: ^bool,
		}

		accept_count := 0
		done := false

		state := new(Server_State)
		state.t = t
		state.server = server
		state.in_buf = make([dynamic]u8, 0, 4096)
		state.accept_count = &accept_count
		state.done = &done

		on_recv :: proc(op: ^nbio.Operation, state: ^Server_State) {
			if state == nil {
				return
			}
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			if state.sending {
				return
			}
			idx := find_header_end(state.in_buf[:])
			if idx < 0 {
				nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
				return
			}
			state.req_count += 1
			client_consume(&state.in_buf, idx+4)
			resp := ""
			if state.req_count == 1 {
				resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
					"Content-Length: 2\r\nConnection: keep-alive\r\n\r\nok"
			} else {
				resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
					"Content-Length: 2\r\nConnection: close\r\n\r\nok"
			}
			state.resp_buf = make([]u8, len(resp))
			runtime.copy_from_string(state.resp_buf, resp)
			state.sending = true
			nbio.send_poly(state.client, {state.resp_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Server_State) {
			if state == nil {
				return
			}
			if op.send.err != nil {
				testing.fail_now(state.t)
			}
			if state.resp_buf != nil {
				delete(state.resp_buf)
				state.resp_buf = nil
			}
			state.sending = false
			if state.req_count >= 2 {
				nbio.close(state.client)
				nbio.close(state.server)
				if state.done != nil {
					state.done^ = true
				}
				delete(state.in_buf)
				free(state)
				return
			}
			if len(state.in_buf) > 0 {
				idx := find_header_end(state.in_buf[:])
				if idx >= 0 {
					state.req_count += 1
					client_consume(&state.in_buf, idx+4)
					resp := ""
					if state.req_count == 1 {
						resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
							"Content-Length: 2\r\nConnection: keep-alive\r\n\r\nok"
					} else {
						resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
							"Content-Length: 2\r\nConnection: close\r\n\r\nok"
					}
					state.resp_buf = make([]u8, len(resp))
					runtime.copy_from_string(state.resp_buf, resp)
					state.sending = true
					nbio.send_poly(state.client, {state.resp_buf}, state, on_send, l=nbio.current_thread_event_loop())
					return
				}
			}
			nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_accept :: proc(op: ^nbio.Operation, state: ^Server_State) {
			if state == nil {
				return
			}
			ev(state.t, op.accept.err, nil)
			state.client = op.accept.client
			if state.accept_count != nil {
				state.accept_count^ += 1
			}
			nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		nbio.accept_poly(server, state, on_accept, l=nbio.current_thread_event_loop())

		client := http.Client{Loop = nbio.current_thread_event_loop()}
		cs := KeepAlive_Client_State{
			t = t,
			client = &client,
			endpoint = ep,
			done = nil,
		}

		req1 := http.Request{
			Method = "GET",
			Target = "/one",
			Header = make(http.Header),
			User = &cs,
		}
		req2 := http.Request{
			Method = "GET",
			Target = "/two",
			Header = make(http.Header),
			User = &cs,
		}
		done1 := false
		cs.done = &done1
		http.client_do(&client, ep, "localhost", &req1, keepalive_client_cb)
		ev(t, nbio.run_until(&done1), nil)
		e(t, done1)

		done2 := false
		cs.done = &done2
		http.client_do(&client, ep, "localhost", &req2, keepalive_client_cb)
		ev(t, nbio.run_until(&done2), nil)
		e(t, done2)
		ev(t, accept_count, 1)

		http.header_reset(&req1.Header)
		http.header_reset(&req2.Header)
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
	}
}

@(test)
server_chunked_request :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
			testing.set_fail_timeout(t, time.Minute)

			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_write(res, req.Body)
					http.response_end(res)
				},
			}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

			Client_State :: struct {
				t: ^testing.T,
				server: nbio.TCP_Socket,
				socket: nbio.TCP_Socket,
				recv_tmp: [4096]u8,
				in_buf: [dynamic]u8,
				send_buf: []u8,
				done: bool,
			}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			consumed, status, body, ok := parse_one_response(state.in_buf[:])
			if ok {
				ev(state.t, status, http.Status_OK)
				ev(state.t, body, "hello")
				client_consume(&state.in_buf, consumed)
				nbio.close(state.socket)
				nbio.close(state.server)
				state.done = true
				delete(state.in_buf)
				free(state)
				return
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

			on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
				ev(state.t, op.send.err, nil)
				if state.send_buf != nil {
					delete(state.send_buf)
					state.send_buf = nil
				}
				nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
			}

			on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
				ev(state.t, op.dial.err, nil)
				state.socket = op.dial.socket
				req := "POST /chunk HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n5\r\nhello\r\n0\r\n\r\n"
				state.send_buf = make([]u8, len(req))
				runtime.copy_from_string(state.send_buf, req)
				nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
			}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_chunked_request_trailer :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write(res, req.Body)
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			consumed, status, body, ok := parse_one_response(state.in_buf[:])
			if ok {
				ev(state.t, status, http.Status_OK)
				ev(state.t, body, "hello")
				client_consume(&state.in_buf, consumed)
				nbio.close(state.socket)
				nbio.close(state.server)
				state.done = true
				delete(state.in_buf)
				free(state)
				return
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "POST /chunk HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n5\r\nhello\r\n0\r\nX-Trailer: yes\r\n\r\n"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_basic_post :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				http.header_set(&res.Header, "x-test", "yes")
				http.header_set(&res.Header, "x-method", req.Method)
				http.header_set(&res.Header, "x-target", req.Target)
				http.response_write(res, req.Body)
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			idx := find_header_end(state.in_buf[:])
			if idx >= 0 {
				header := string(state.in_buf[:idx])
				ev(state.t, header_has_value(header, "x-test", "yes"), true)
				ev(state.t, header_has_value(header, "x-method", "POST"), true)
				ev(state.t, header_has_value(header, "x-target", "/submit"), true)
				consumed, status, body, ok := parse_one_response(state.in_buf[:])
				if ok {
					ev(state.t, status, http.Status_OK)
					ev(state.t, body, "hello")
					client_consume(&state.in_buf, consumed)
					nbio.close(state.socket)
					nbio.close(state.server)
					state.done = true
					delete(state.in_buf)
					free(state)
					return
				}
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "POST /submit HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_body_reader_stream :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Stream_State :: struct {
			t: ^testing.T,
			body: bytes.Buffer,
			done: bool,
		}

		stream_state := new(Stream_State)
		stream_state.t = t
		bytes.buffer_init_allocator(&stream_state.body, 0, 32)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				ev(t, http.request_body_stream_enable(req), true)
			},
			Body_Handler = proc(req: ^http.Request, res: ^http.ResponseWriter, data: []u8, done: bool) {
				_ = data
				_ = done
				tmp: [2]u8
				for {
					n, body_done, ok := http.request_body_read(req, tmp[:])
					if !ok {
						break
					}
					if n > 0 {
						_, _ = bytes.buffer_write(&stream_state.body, tmp[:n])
					}
					if body_done && !stream_state.done {
						stream_state.done = true
						ev(stream_state.t, string(bytes.buffer_to_bytes(&stream_state.body)), "abcdef")
						res.Status = http.Status_OK
						http.response_write_string(res, "ok")
						http.response_end(res)
						return
					}
				}
			},
		}

		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			consumed, status, body, ok := parse_one_response(state.in_buf[:])
			if ok {
				ev(state.t, status, http.Status_OK)
				ev(state.t, body, "ok")
				client_consume(&state.in_buf, consumed)
				nbio.close(state.socket)
				nbio.close(state.server)
				state.done = true
				delete(state.in_buf)
				free(state)
				bytes.buffer_destroy(&stream_state.body)
				free(stream_state)
				return
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "POST /stream HTTP/1.1\r\nHost: localhost\r\nContent-Length: 6\r\nConnection: close\r\n\r\nabcdef"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_body_reader_stream_chunked :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Stream_State :: struct {
			t: ^testing.T,
			body: bytes.Buffer,
			done: bool,
		}

		stream_state := new(Stream_State)
		stream_state.t = t
		bytes.buffer_init_allocator(&stream_state.body, 0, 32)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				ev(t, http.request_body_stream_enable(req), true)
			},
			Body_Handler = proc(req: ^http.Request, res: ^http.ResponseWriter, data: []u8, done: bool) {
				_ = data
				_ = done
				tmp: [2]u8
				for {
					n, body_done, ok := http.request_body_read(req, tmp[:])
					if !ok {
						break
					}
					if n > 0 {
						_, _ = bytes.buffer_write(&stream_state.body, tmp[:n])
					}
					if body_done && !stream_state.done {
						stream_state.done = true
						ev(stream_state.t, string(bytes.buffer_to_bytes(&stream_state.body)), "abcdef")
						res.Status = http.Status_OK
						http.response_write_string(res, "ok")
						http.response_end(res)
						return
					}
				}
			},
		}

		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			consumed, status, body, ok := parse_one_response(state.in_buf[:])
			if ok {
				ev(state.t, status, http.Status_OK)
				ev(state.t, body, "ok")
				client_consume(&state.in_buf, consumed)
				nbio.close(state.socket)
				nbio.close(state.server)
				state.done = true
				delete(state.in_buf)
				free(state)
				bytes.buffer_destroy(&stream_state.body)
				free(stream_state)
				return
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "POST /stream HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n3\r\nabc\r\n3\r\ndef\r\n0\r\n\r\n"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_expect_continue :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_write_string(res, string(req.Body))
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			send_buf: []u8,
			body_buf: []u8,
			sent_body: bool,
			got_continue: bool,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)
		state.body_buf = make([]u8, 5)
		runtime.copy_from_string(state.body_buf, "hello")

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])

			for {
				idx := find_header_end(state.in_buf[:])
				if idx < 0 {
					break
				}
				header := string(state.in_buf[:idx])
				lines, _ := strings.split(header, "\r\n", context.temp_allocator)
				if len(lines) < 1 {
					testing.fail_now(state.t)
				}
				parts, _ := strings.split(lines[0], " ", context.temp_allocator)
				if len(parts) < 2 {
					testing.fail_now(state.t)
				}
				status, ok := parse_int_safe(parts[1])
				if !ok {
					testing.fail_now(state.t)
				}
				if status == http.Status_Continue {
					state.got_continue = true
					client_consume(&state.in_buf, idx+4)
					if !state.sent_body {
						state.sent_body = true
						nbio.send_poly(state.socket, {state.body_buf}, state, on_send_body, l=nbio.current_thread_event_loop())
						return
					}
					continue
				}
				break
			}

			consumed, status, body, ok := parse_one_response(state.in_buf[:])
			if ok {
				ev(state.t, state.got_continue, true)
				ev(state.t, status, http.Status_OK)
				ev(state.t, body, "hello")
				client_consume(&state.in_buf, consumed)
				nbio.close(state.socket)
				nbio.close(state.server)
				state.done = true
				delete(state.in_buf)
				delete(state.send_buf)
				delete(state.body_buf)
				free(state)
				return
			}

			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send_body :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "POST /expect HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\nExpect: 100-continue\r\nConnection: close\r\n\r\n"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_file_response :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		temp_dir, derr := os.make_directory_temp("", "bifrost_http_*", context.allocator)
		ev(t, derr, nil)
		path, perr := os.join_path({temp_dir, "file.txt"}, context.allocator)
		ev(t, perr, nil)

		f, ferr := os.open(path, {.Write, .Create, .Trunc})
		ev(t, ferr, nil)
		content := "hello-file"
		n, werr := os.write(f, transmute([]u8)content)
		ev(t, werr, nil)
		ev(t, n, len(content))
		os.close(f)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				if req.Target != "/file" {
					res.Status = http.Status_Not_Found
					http.response_end(res)
					return
				}
				path, ok := http.header_get(req.Header, "x-file-path")
				if !ok || path == "" {
					res.Status = http.Status_Bad_Request
					http.response_end(res)
					return
				}
				data, rerr := os.read_entire_file(path, context.allocator)
				if rerr != nil {
					res.Status = http.Status_Not_Found
					http.response_end(res)
					return
				}
				http.response_write(res, data)
				http.response_end(res)
				delete(data)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			content: string,
			path: string,
			temp_dir: string,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)
		state.content = content
		state.path = path
		state.temp_dir = temp_dir

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			consumed, status, body, ok := parse_one_response(state.in_buf[:])
				if ok {
					ev(state.t, status, http.Status_OK)
					ev(state.t, body, state.content)
					client_consume(&state.in_buf, consumed)
					nbio.close(state.socket)
					nbio.close(state.server)
					os.remove(state.path)
					os.remove(state.temp_dir)
					delete(state.path)
					delete(state.temp_dir)
					state.done = true
					delete(state.in_buf)
					free(state)
					return
				}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := strings.join({"GET /file HTTP/1.1\r\nHost: localhost\r\nX-File-Path: ", state.path, "\r\nConnection: close\r\n\r\n"}, "", context.temp_allocator)
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
hashfs_format_parse :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	hash := strings.repeat("a", 64, context.temp_allocator)
	expected_js, _ := strings.join({"app-", hash, ".js"}, "", context.temp_allocator)
	expected_multi, _ := strings.join({"app-", hash, ".bundle.js"}, "", context.temp_allocator)
	expected_noext, _ := strings.join({"app-", hash}, "", context.temp_allocator)

	hashed_js := http.hashfs_format_name("app.js", hash, context.temp_allocator)
	ev(t, hashed_js, expected_js)
	base, parsed := http.hashfs_parse_name(hashed_js, context.temp_allocator)
	ev(t, base, "app.js")
	ev(t, parsed, hash)

	hashed_multi := http.hashfs_format_name("app.bundle.js", hash, context.temp_allocator)
	ev(t, hashed_multi, expected_multi)
	base, parsed = http.hashfs_parse_name(hashed_multi, context.temp_allocator)
	ev(t, base, "app.bundle.js")
	ev(t, parsed, hash)

	hashed_noext := http.hashfs_format_name("app", hash, context.temp_allocator)
	ev(t, hashed_noext, expected_noext)
	base, parsed = http.hashfs_parse_name(hashed_noext, context.temp_allocator)
	ev(t, base, "app")
	ev(t, parsed, hash)

	base, parsed = http.hashfs_parse_name("plain.txt", context.temp_allocator)
	ev(t, base, "plain.txt")
	ev(t, parsed, "")
}

@(test)
server_hashfs_file :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		temp_dir, derr := os.make_directory_temp("", "bifrost_hashfs_*", context.allocator)
		ev(t, derr, nil)
		path, perr := os.join_path({temp_dir, "app.js"}, context.allocator)
		ev(t, perr, nil)

		content := "console.log(\"ok\");"
		f, ferr := os.open(path, {.Write, .Create, .Trunc})
		ev(t, ferr, nil)
		n, werr := os.write(f, transmute([]u8)content)
		ev(t, werr, nil)
		ev(t, n, len(content))
		os.close(f)

		base := ""
		hash := ""

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				root, ok := http.header_get(req.Header, "x-hashfs-root")
				if !ok || root == "" {
					res.Status = http.Status_Bad_Request
					http.response_end(res)
					return
				}
				fs_local := http.hashfs_new(root)
				http.hashfs_serve(&fs_local, req, res)
				http.hashfs_destroy(&fs_local)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			content: string,
			hash: string,
			hashed: string,
			path: string,
			temp_dir: string,
			fs: http.HashFS,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)
		state.content = content
		state.path = path
		state.temp_dir = temp_dir
		state.fs = http.hashfs_new(temp_dir)
		state.hashed = http.hashfs_hash_name(&state.fs, "app.js")
		base, hash = http.hashfs_parse_name(state.hashed, context.temp_allocator)
		ev(t, base, "app.js")
		e(t, hash != "")
		state.hash = hash

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])
			idx := find_header_end(state.in_buf[:])
			if idx >= 0 {
				header := string(state.in_buf[:idx])
				ev(state.t, header_has_value(header, "cache-control", "public, max-age=31536000"), true)
				etag, _ := strings.join({"\"", state.hash, "\""}, "", context.temp_allocator)
				ev(state.t, header_has_value(header, "etag", etag), true)
				consumed, status, body, ok := parse_one_response(state.in_buf[:])
				if ok {
					ev(state.t, status, http.Status_OK)
					ev(state.t, body, state.content)
					client_consume(&state.in_buf, consumed)
					nbio.close(state.socket)
					nbio.close(state.server)
						os.remove(state.path)
						os.remove(state.temp_dir)
						delete(state.path)
						delete(state.temp_dir)
						http.hashfs_destroy(&state.fs)
						state.done = true
						delete(state.in_buf)
						free(state)
						return
				}
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := strings.join({
				"GET /", state.hashed, " HTTP/1.1\r\n",
				"Host: localhost\r\n",
				"X-HashFS-Root: ", state.temp_dir, "\r\n",
				"Connection: close\r\n\r\n",
			}, "", context.temp_allocator)
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
server_sse_streaming :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				if res.Header == nil {
					res.Header = make(http.Header)
				}
				http.header_set(&res.Header, "connection", "close")
				ok := http.response_sse_start(res)
				if !ok {
					return
				}
				http.response_sse_write(res, "data: one\n\n")
				http.response_sse_flush(res)
				http.response_sse_write(res, "data: two\n\n")
				http.response_stream_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		Client_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			socket: nbio.TCP_Socket,
			recv_tmp: [4096]u8,
			in_buf: [dynamic]u8,
			header_parsed: bool,
			body_start: int,
			parse_pos: int,
			chunk_state: http.Chunk_State,
			chunk_size: int,
			body: bytes.Buffer,
			send_buf: []u8,
			done: bool,
		}

		state := new(Client_State)
		state.t = t
		state.server = sock
		state.in_buf = make([dynamic]u8, 0, 4096)
		state.chunk_state = .Size
		bytes.buffer_init_allocator(&state.body, 0, 256)

		on_recv :: proc(op: ^nbio.Operation, state: ^Client_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			append(&state.in_buf, ..state.recv_tmp[:op.recv.received])

			for {
				if !state.header_parsed {
					idx := find_header_end(state.in_buf[:])
					if idx < 0 {
						nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
						return
					}
					header := string(state.in_buf[:idx])
					lines, _ := strings.split(header, "\r\n", context.temp_allocator)
					has_proto := false
					if len(lines[0]) >= 7 {
						has_proto = strings.equal_fold(lines[0][:7], "HTTP/1.")
					}
					ev(state.t, has_proto, true)
					has_chunked := false
					has_sse := false
					for i in 1..<len(lines) {
						line := lines[i]
						if len(line) == 0 {
							continue
						}
						colon := strings.index_byte(line, ':')
						if colon < 0 {
							continue
						}
						name := strings.trim_space(line[:colon])
						value := strings.trim_space(line[colon+1:])
						if strings.equal_fold(name, "transfer-encoding") && strings.equal_fold(value, "chunked") {
							has_chunked = true
						}
						if strings.equal_fold(name, "content-type") && strings.equal_fold(value, "text/event-stream") {
							has_sse = true
						}
					}
					ev(state.t, has_chunked, true)
					ev(state.t, has_sse, true)
					state.header_parsed = true
					state.body_start = idx + 4
					state.parse_pos = state.body_start
				}

				switch state.chunk_state {
				case .Size:
					idx := find_crlf(state.in_buf[:], state.parse_pos)
					if idx < 0 {
						nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
						return
					}
					line := string(state.in_buf[state.parse_pos:idx])
						if semi := strings.index_byte(line, ';'); semi >= 0 {
							line = line[:semi]
						}
						line = strings.trim_space(line)
						if len(line) == 0 {
							testing.fail_now(state.t)
						}
						size, ok := parse_int_safe(line, 16)
					if !ok || size < 0 {
						testing.fail_now(state.t)
					}
					state.chunk_size = size
					state.parse_pos = idx + 2
					if size == 0 {
						state.chunk_state = .Trailer
					} else {
						state.chunk_state = .Data
					}
				case .Data:
					need := state.chunk_size + 2
					remaining := len(state.in_buf) - state.parse_pos
					if remaining < need {
						nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
						return
					}
					_, _ = bytes.buffer_write(&state.body, state.in_buf[state.parse_pos:state.parse_pos+state.chunk_size])
					state.parse_pos += state.chunk_size
					if state.in_buf[state.parse_pos] != '\r' || state.in_buf[state.parse_pos+1] != '\n' {
						testing.fail_now(state.t)
					}
					state.parse_pos += 2
					state.chunk_state = .Size
					if state.parse_pos > 0 {
						client_consume(&state.in_buf, state.parse_pos)
						state.parse_pos = 0
						state.body_start = 0
					}
				case .Trailer:
					remaining := len(state.in_buf) - state.parse_pos
					if remaining >= 2 && state.in_buf[state.parse_pos] == '\r' && state.in_buf[state.parse_pos+1] == '\n' {
						state.parse_pos += 2
						client_consume(&state.in_buf, state.parse_pos)
						state.parse_pos = 0
						state.body_start = 0
						body := bytes.buffer_to_bytes(&state.body)
						ev(state.t, string(body), "data: one\n\ndata: two\n\n")
						nbio.close(state.socket)
						nbio.close(state.server)
						bytes.buffer_destroy(&state.body)
						state.done = true
						delete(state.in_buf)
						free(state)
						return
					}
					offset := find_header_end(state.in_buf[state.parse_pos:])
					if offset < 0 {
						nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
						return
					}
					state.parse_pos += offset + 4
					client_consume(&state.in_buf, state.parse_pos)
					state.parse_pos = 0
					state.body_start = 0
					body := bytes.buffer_to_bytes(&state.body)
					ev(state.t, string(body), "data: one\n\ndata: two\n\n")
					nbio.close(state.socket)
					nbio.close(state.server)
					bytes.buffer_destroy(&state.body)
					state.done = true
					delete(state.in_buf)
					free(state)
					return
				}
			}
		}

		on_send :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.send.err, nil)
			if state.send_buf != nil {
				delete(state.send_buf)
				state.send_buf = nil
			}
			nbio.recv_poly(state.socket, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		on_dial :: proc(op: ^nbio.Operation, state: ^Client_State) {
			ev(state.t, op.dial.err, nil)
			state.socket = op.dial.socket
			req := "GET /sse HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
			state.send_buf = make([]u8, len(req))
			runtime.copy_from_string(state.send_buf, req)
			nbio.send_poly(state.socket, {state.send_buf}, state, on_send, l=nbio.current_thread_event_loop())
		}

		nbio.dial_poly(ep, state, on_dial, l=nbio.current_thread_event_loop())

		ev(t, nbio.run_until(&state.done), nil)
		e(t, state.done)
	}
}

@(test)
go_request_transfer_encoding :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			te: string,
			body: string,
			status: int,
		}
		cases := []Case{
			{name = "chunked", te = "Transfer-Encoding: chunked\r\n", body = "0\r\n\r\n", status = http.Status_OK},
			{name = "identity", te = "Transfer-Encoding: identity\r\n", body = "", status = http.Status_Not_Implemented},
			{name = "chunked_identity", te = "Transfer-Encoding: chunked, identity\r\n", body = "0\r\n\r\n", status = http.Status_Not_Implemented},
			{name = "gzip", te = "Transfer-Encoding: gzip\r\n", body = "", status = http.Status_Not_Implemented},
			{name = "chunked_chunked", te = "Transfer-Encoding: chunked, chunked\r\n", body = "0\r\n\r\n", status = http.Status_Not_Implemented},
		}

		for c in cases {
			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_end(res)
				},
			}
			sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
			ev(t, err, nil)
			ep, eperr := nbio.bound_endpoint(sock)
			ev(t, eperr, nil)

			req := strings.join({
				"POST /te HTTP/1.1\r\n",
				"Host: localhost\r\n",
				c.te,
				"Connection: close\r\n\r\n",
				c.body,
			}, "", context.temp_allocator)
			raw_request_exchange(t, ep, sock, req, c.status, true)
		}
	}
}

@(test)
go_request_invalid_content_length :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			cl: string,
			status: int,
		}
		cases := []Case{
			{name = "plus", cl = "Content-Length: +3\r\n", status = http.Status_Bad_Request},
			{name = "negative", cl = "Content-Length: -1\r\n", status = http.Status_Bad_Request},
			{name = "empty", cl = "Content-Length: \r\n", status = http.Status_Bad_Request},
		}

		for c in cases {
			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_end(res)
				},
			}
			sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
			ev(t, err, nil)
			ep, eperr := nbio.bound_endpoint(sock)
			ev(t, eperr, nil)

			req := strings.join({
				"POST /cl HTTP/1.1\r\n",
				"Host: localhost\r\n",
				c.cl,
				"Connection: close\r\n\r\n",
			}, "", context.temp_allocator)
			raw_request_exchange(t, ep, sock, req, c.status, true)
		}
	}
}

@(test)
go_request_expect_continue_http10 :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "POST /expect HTTP/1.0\r\nHost: localhost\r\nExpect: 100-continue\r\nConnection: close\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_Expectation_Failed, true)
	}
}

@(test)
go_request_expect_unsupported :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "POST /expect HTTP/1.1\r\nHost: localhost\r\nExpect: 100-continue, foo\r\nConnection: close\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_Expectation_Failed, true)
	}
}

@(test)
go_request_invalid_chunk_size :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "POST /chunk HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\nZ\r\nhello\r\n0\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_Bad_Request, true)
	}
}

@(test)
go_request_header_too_large :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Max_Header_Bytes = 64,
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		long_val := strings.repeat("a", 80, context.temp_allocator)
		req, _ := strings.join({
			"GET / HTTP/1.1\r\nHost: localhost\r\nX-Long: ",
			long_val,
			"\r\nConnection: close\r\n\r\n",
		}, "", context.temp_allocator)
		raw_request_exchange(t, ep, sock, req, http.Status_Request_Header_Fields_Too_Large, true)
	}
}

@(test)
go_request_body_too_large :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			req: string,
		}
		cases := []Case{
			{
				name = "content_length",
				req = "POST /big HTTP/1.1\r\nHost: localhost\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello",
			},
			{
				name = "chunked",
				req = "POST /big HTTP/1.1\r\nHost: localhost\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n3\r\nabc\r\n2\r\nde\r\n0\r\n\r\n",
			},
		}

		for c in cases {
			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Max_Body_Bytes = 4,
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_end(res)
				},
			}
			sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
			ev(t, err, nil)
			ep, eperr := nbio.bound_endpoint(sock)
			ev(t, eperr, nil)

			raw_request_exchange(t, ep, sock, c.req, http.Status_Payload_Too_Large, true)
		}
	}
}

@(test)
go_response_transfer_encoding :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			resp: string,
			err: http.Client_Error_Kind,
			status: int,
		}
		cases := []Case{
			{
				name = "chunked",
				resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
					"Transfer-Encoding: chunked\r\nConnection: close\r\n\r\n0\r\n\r\n",
				err = .None,
				status = http.Status_OK,
			},
			{
				name = "chunked_identity",
				resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
					"Transfer-Encoding: chunked, identity\r\nConnection: close\r\n\r\n0\r\n\r\n",
				err = .Parse,
				status = 0,
			},
			{
				name = "gzip",
				resp = http1_status_line(http.Status_OK, http.Status_Text_OK) +
					"Transfer-Encoding: gzip\r\nConnection: close\r\n\r\n0\r\n\r\n",
				err = .Parse,
				status = 0,
			},
		}

		for c in cases {
			raw_response_exchange(t, c.resp, c.err, c.status)
		}
	}
}

@(test)
go_response_invalid_content_length :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		resp := http1_status_line(http.Status_OK, http.Status_Text_OK) +
			"Content-Length: +3\r\nConnection: close\r\n\r\nabc"
		raw_response_exchange(t, resp, .Parse, 0)
	}
}

@(test)
go_response_invalid_chunk_size :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		resp := http1_status_line(http.Status_OK, http.Status_Text_OK) +
			"Transfer-Encoding: chunked\r\nConnection: close\r\n\r\nZ\r\n"
		raw_response_exchange(t, resp, .Parse, 0)
	}
}

@(test)
go_response_close_delimited_body :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Server_State :: struct {
			t: ^testing.T,
			server: nbio.TCP_Socket,
			client: nbio.TCP_Socket,
			recv_tmp: [1024]u8,
			resp: []u8,
			sent: bool,
		}

		server, err := nbio.listen_tcp({nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(server)
		ev(t, eperr, nil)

		state := new(Server_State)
		state.t = t
		state.server = server
		resp := http1_status_line(http.Status_OK, http.Status_Text_OK) +
			"Connection: close\r\n\r\nhello"
		state.resp = make([]u8, len(resp))
		runtime.copy_from_string(state.resp, resp)

		on_send :: proc(op: ^nbio.Operation, state: ^Server_State) {
			if op.send.err != nil {
				testing.fail_now(state.t)
			}
			nbio.close(state.client)
			nbio.close(state.server)
			delete(state.resp)
			free(state)
		}

		on_recv :: proc(op: ^nbio.Operation, state: ^Server_State) {
			if op.recv.err != nil {
				testing.fail_now(state.t)
			}
			if op.recv.received == 0 {
				testing.fail_now(state.t)
			}
			if state.sent {
				return
			}
			state.sent = true
			nbio.send_poly(state.client, {state.resp}, state, on_send, l=nbio.current_thread_event_loop())
		}

		on_accept :: proc(op: ^nbio.Operation, state: ^Server_State) {
			ev(state.t, op.accept.err, nil)
			state.client = op.accept.client
			nbio.recv_poly(state.client, {state.recv_tmp[:]}, state, on_recv, l=nbio.current_thread_event_loop())
		}

		nbio.accept_poly(server, state, on_accept, l=nbio.current_thread_event_loop())

		done := false
		Client_State :: struct {
			t: ^testing.T,
			expected_body: string,
			done: ^bool,
		}
		client_state := Client_State{t = t, expected_body = "hello", done = &done}

		cb := proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			state := (^Client_State)(req.User)
			if state == nil {
				return
			}
			ev(state.t, err.Kind, http.Client_Error_Kind.None)
			if err.Kind == .None {
				ev(state.t, res.Status, http.Status_OK)
				ev(state.t, string(res.Body), state.expected_body)
			}
			if state.done != nil {
				state.done^ = true
			}
		}

		client := http.Client{Loop = nbio.current_thread_event_loop()}
		req := http.Request{
			Method = "GET",
			Target = "/",
			Header = make(http.Header),
			User = &client_state,
		}
		http.client_do(&client, ep, "localhost", &req, cb)

		ev(t, nbio.run_until(&done), nil)
		e(t, done)
		if client.Transport != nil {
			http.transport_destroy(client.Transport)
			client.Transport = nil
		}
	}
}

@(test)
go_response_header_too_large :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

		long_val := strings.repeat("b", 33*1024, context.temp_allocator)
		resp, _ := strings.join({
			http1_status_line(http.Status_OK, http.Status_Text_OK) + "X-Long: ",
			long_val,
			"\r\nConnection: close\r\n\r\n",
		}, "", context.temp_allocator)
		raw_response_exchange(t, resp, .Parse, 0)
	}
}

@(test)
go_request_missing_host :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "GET / HTTP/1.1\r\nConnection: close\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_Bad_Request, true)
	}
}

@(test)
go_request_http10_no_host :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "GET / HTTP/1.0\r\nConnection: close\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_OK, true)
	}
}

@(test)
go_request_bad_request_line :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "GET /only-two-parts\r\nConnection: close\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_Bad_Request, true)
	}
}

@(test)
go_request_invalid_version :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		server := http.Server{
			Loop = nbio.current_thread_event_loop(),
			Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
				res.Status = http.Status_OK
				http.response_end(res)
			},
		}
		sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
		ev(t, err, nil)
		ep, eperr := nbio.bound_endpoint(sock)
		ev(t, eperr, nil)

		req := "GET / HTTP/2.0\r\nHost: localhost\r\nConnection: close\r\n\r\n"
		raw_request_exchange(t, ep, sock, req, http.Status_HTTP_Version_Not_Supported, true)
	}
}

@(test)
go_request_duplicate_content_length :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			cl: string,
			body: string,
			status: int,
		}
		cases := []Case{
			{name = "same", cl = "Content-Length: 3\r\nContent-Length: 3\r\n", body = "abc", status = http.Status_OK},
			{name = "diff", cl = "Content-Length: 3\r\nContent-Length: 4\r\n", body = "abcd", status = http.Status_Bad_Request},
		}

		for c in cases {
			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_end(res)
				},
			}
			sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
			ev(t, err, nil)
			ep, eperr := nbio.bound_endpoint(sock)
			ev(t, eperr, nil)

			req := strings.join({
				"POST /dup HTTP/1.1\r\n",
				"Host: localhost\r\n",
				c.cl,
				"Connection: close\r\n\r\n",
				c.body,
			}, "", context.temp_allocator)
			raw_request_exchange(t, ep, sock, req, c.status, true)
		}
	}
}

@(test)
go_response_100_continue_then_ok :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		resp := http1_status_line(http.Status_Continue, http.Status_Text_Continue) +
			"\r\n" +
			http1_status_line(http.Status_OK, http.Status_Text_OK) +
			"Content-Length: 2\r\nConnection: close\r\n\r\nok"
		raw_response_exchange(t, resp, .None, http.Status_OK)
	}
}

@(test)
go_response_invalid_status_line :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		resp := "HTTP/1.1 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
		raw_response_exchange(t, resp, .Parse, 0)
	}
}

@(test)
go_response_duplicate_content_length :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)
		resp := http1_status_line(http.Status_OK, http.Status_Text_OK) +
			"Content-Length: 2\r\nContent-Length: 3\r\nConnection: close\r\n\r\nok"
		raw_response_exchange(t, resp, .Parse, 0)
	}
}

@(test)
go_request_validate_host_header :: proc(t: ^testing.T) {
	if event_loop_guard(t) {
		testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			line: string,
			host: string,
			status: int,
		}

		cases := []Case{
			{name = "http11_missing", line = "GET / HTTP/1.1", host = "", status = http.Status_Bad_Request},
			{name = "http11_empty", line = "GET / HTTP/1.1", host = "Host: \r\n", status = http.Status_OK},
			{name = "http11_ipv4", line = "GET / HTTP/1.1", host = "Host: 1.2.3.4\r\n", status = http.Status_OK},
			{name = "http11_domain", line = "GET / HTTP/1.1", host = "Host: foo.com\r\n", status = http.Status_OK},
			{name = "http11_domain_underscore", line = "GET / HTTP/1.1", host = "Host: foo-bar_baz.com\r\n", status = http.Status_OK},
			{name = "http11_port", line = "GET / HTTP/1.1", host = "Host: foo.com:80\r\n", status = http.Status_OK},
			{name = "http11_ipv6", line = "GET / HTTP/1.1", host = "Host: ::1\r\n", status = http.Status_OK},
			{name = "http11_ipv6_bracket", line = "GET / HTTP/1.1", host = "Host: [::1]\r\n", status = http.Status_OK},
			{name = "http11_ipv6_port", line = "GET / HTTP/1.1", host = "Host: [::1]:80\r\n", status = http.Status_OK},
			{name = "http11_ipv6_zone", line = "GET / HTTP/1.1", host = "Host: [::1%25en0]:80\r\n", status = http.Status_OK},
			{name = "http11_ctrl", line = "GET / HTTP/1.1", host = "Host: \x06\r\n", status = http.Status_Bad_Request},
			{name = "http11_nonascii", line = "GET / HTTP/1.1", host = "Host: \xff\r\n", status = http.Status_Bad_Request},
			{name = "http11_lbrace", line = "GET / HTTP/1.1", host = "Host: {\r\n", status = http.Status_Bad_Request},
			{name = "http11_rbrace", line = "GET / HTTP/1.1", host = "Host: }\r\n", status = http.Status_Bad_Request},
			{name = "http11_multi", line = "GET / HTTP/1.1", host = "Host: first\r\nHost: second\r\n", status = http.Status_Bad_Request},

			{name = "http10_missing", line = "GET / HTTP/1.0", host = "", status = http.Status_OK},
			{name = "http10_multi", line = "GET / HTTP/1.0", host = "Host: first\r\nHost: second\r\n", status = http.Status_Bad_Request},
			{name = "http10_nonascii", line = "GET / HTTP/1.0", host = "Host: \xff\r\n", status = http.Status_Bad_Request},

			{name = "connect_no_host", line = "CONNECT golang.org:443 HTTP/1.1", host = "", status = http.Status_OK},
		}

		for c in cases {
			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_end(res)
				},
			}
			sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
			ev(t, err, nil)
			ep, eperr := nbio.bound_endpoint(sock)
			ev(t, eperr, nil)

			req := strings.join({
				c.line, "\r\n",
				c.host,
				"Connection: close\r\n\r\n",
			}, "", context.temp_allocator)
			raw_request_exchange(t, ep, sock, req, c.status, true)
		}
	}
}

@(test)
	go_request_target_forms :: proc(t: ^testing.T) {
		if event_loop_guard(t) {
			testing.set_fail_timeout(t, time.Minute)

		Case :: struct {
			name: string,
			line: string,
			host: string,
			expect_status: int,
			expect_target: string,
		}

		cases := []Case{
			{
				name = "origin_form",
				line = "GET /a/b?c=d HTTP/1.1",
				host = "Host: example.com\r\n",
				expect_status = http.Status_OK,
				expect_target = "/a/b?c=d",
			},
			{
				name = "absolute_form",
				line = "GET http://example.com/a/b?c=d HTTP/1.1",
				host = "Host: example.com\r\n",
				expect_status = http.Status_OK,
				expect_target = "/a/b?c=d",
			},
			{
				name = "absolute_form_no_path",
				line = "GET http://example.com HTTP/1.1",
				host = "Host: example.com\r\n",
				expect_status = http.Status_OK,
				expect_target = "/",
			},
			{
				name = "absolute_form_https",
				line = "GET https://example.com/secure HTTP/1.1",
				host = "Host: example.com\r\n",
				expect_status = http.Status_OK,
				expect_target = "/secure",
			},
			{
				name = "asterisk_form",
				line = "OPTIONS * HTTP/1.1",
				host = "Host: example.com\r\n",
				expect_status = http.Status_OK,
				expect_target = "*",
			},
			{
				name = "bad_form",
				line = "GET mailto:root@example.com HTTP/1.1",
				host = "Host: example.com\r\n",
				expect_status = http.Status_Bad_Request,
				expect_target = "",
			},
		}

		for c in cases {
			server := http.Server{
				Loop = nbio.current_thread_event_loop(),
				Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
					res.Status = http.Status_OK
					http.response_write_string(res, req.Target)
					http.response_end(res)
				},
			}
			sock, err := http.listen(&server, {nbio.IP4_Loopback, 0})
			ev(t, err, nil)
			ep, eperr := nbio.bound_endpoint(sock)
			ev(t, eperr, nil)

			req := strings.join({
				c.line, "\r\n",
				c.host,
				"Connection: close\r\n\r\n",
			}, "", context.temp_allocator)
			got_target := ""
			raw_request_exchange_body(t, ep, sock, req, c.expect_status, &got_target, true)
			if c.expect_status == http.Status_OK {
				ev(t, got_target, c.expect_target)
			}
			if len(got_target) > 0 {
				free_string(got_target)
			}
		}
	}
}
