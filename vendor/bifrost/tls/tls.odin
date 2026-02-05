package bifrost_tls

import "core:c"
import "core:mem"

TLS_Status :: enum {
	Ok,
	Want_Read,
	Want_Write,
	Closed,
	Error,
}

Context :: struct {
	ctx: ^SSL_CTX,
	is_server: bool,
	alpn_wire: []u8,
}

Connection :: struct {
	ssl: ^SSL,
	in_bio:  ^BIO,
	out_bio: ^BIO,
	is_server: bool,
	handshake_done: bool,
	alpn_selected: ALPN_Protocol,
}

context_create :: proc(config: ^Config, is_server: bool) -> (ctx: ^Context, ok: bool) {
	method := TLS_method()
	if method == nil {
		return nil, false
	}

	ssl_ctx := SSL_CTX_new(method)
	if ssl_ctx == nil {
		return nil, false
	}

	ctx = new(Context)
	ctx.ctx = ssl_ctx
	ctx.is_server = is_server

	if config != nil {
		if len(config.alpn) > 0 {
			total := 0
			for p in config.alpn {
				str := ""
				switch p {
				case .HTTP2:   str = "h2"
				case .HTTP1_1: str = "http/1.1"
				case:          str = ""
				}
				if len(str) == 0 || len(str) > 255 {
					SSL_CTX_free(ssl_ctx)
					return nil, false
				}
				total += 1 + len(str)
			}

			ctx.alpn_wire = make([]u8, total)
			idx := 0
			for p in config.alpn {
				str := ""
				switch p {
				case .HTTP2:   str = "h2"
				case .HTTP1_1: str = "http/1.1"
				case:          str = ""
				}
				ctx.alpn_wire[idx] = u8(len(str))
				idx += 1
				copy(ctx.alpn_wire[idx:], []u8(str))
				idx += len(str)
			}

			if is_server {
				SSL_CTX_set_alpn_select_cb(ssl_ctx, alpn_select_cb, ctx)
			} else {
				if SSL_CTX_set_alpn_protos(ssl_ctx, &ctx.alpn_wire[0], c.size_t(len(ctx.alpn_wire))) != 0 {
					SSL_CTX_free(ssl_ctx)
					return nil, false
				}
			}
		}

		if is_server {
			if config.cert_chain_file != "" {
				if SSL_CTX_use_certificate_chain_file(ssl_ctx, cstring(config.cert_chain_file)) != 1 {
					SSL_CTX_free(ssl_ctx)
					return nil, false
				}
			}
			if config.key_file != "" {
				if SSL_CTX_use_PrivateKey_file(ssl_ctx, cstring(config.key_file), SSL_FILETYPE_PEM) != 1 {
					SSL_CTX_free(ssl_ctx)
					return nil, false
				}
			}
		}

		if config.ca_file != "" || config.ca_dir != "" {
			if SSL_CTX_load_verify_locations(ssl_ctx,
				(cstring(config.ca_file) if config.ca_file != "" else nil),
				(cstring(config.ca_dir) if config.ca_dir != "" else nil),
			) != 1 {
				SSL_CTX_free(ssl_ctx)
				return nil, false
			}
		}

		if config.verify_depth > 0 {
			SSL_CTX_set_verify_depth(ssl_ctx, i32(config.verify_depth))
		}

		if config.verify_peer {
			mode := SSL_VERIFY_PEER
			if is_server && config.require_client_cert {
				mode = SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT
			}
			SSL_CTX_set_verify(ssl_ctx, mode, nil)
		} else {
			SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_NONE, nil)
		}
	}

	return ctx, true
}

context_free :: proc(ctx: ^Context) {
	if ctx == nil {
		return
	}
	if ctx.ctx != nil {
		SSL_CTX_free(ctx.ctx)
		ctx.ctx = nil
	}
}

connection_create :: proc(ctx: ^Context, is_server: bool, server_name: string = "") -> (conn: ^Connection, ok: bool) {
	if ctx == nil || ctx.ctx == nil {
		return nil, false
	}

	ssl := SSL_new(ctx.ctx)
	if ssl == nil {
		return nil, false
	}

	in_bio := BIO_new(BIO_s_mem())
	out_bio := BIO_new(BIO_s_mem())
	if in_bio == nil || out_bio == nil {
		SSL_free(ssl)
		return nil, false
	}

	SSL_set_bio(ssl, in_bio, out_bio)

	if is_server {
		SSL_set_accept_state(ssl)
	} else {
		SSL_set_connect_state(ssl)
		if server_name != "" {
			_ = SSL_set1_host(ssl, cstring(server_name))
		}
	}

	conn = new(Connection)
	conn.ssl = ssl
	conn.in_bio = in_bio
	conn.out_bio = out_bio
	conn.is_server = is_server
	conn.handshake_done = false
	conn.alpn_selected = .Unknown

	return conn, true
}

connection_free :: proc(conn: ^Connection) {
	if conn == nil {
		return
	}
	if conn.ssl != nil {
		SSL_free(conn.ssl)
		conn.ssl = nil
	}
	conn.in_bio = nil
	conn.out_bio = nil
}

handshake :: proc(conn: ^Connection) -> TLS_Status {
	if conn == nil || conn.ssl == nil {
		return .Error
	}
	if conn.handshake_done {
		return .Ok
	}

	ret := SSL_do_handshake(conn.ssl)
	if ret == 1 {
		conn.handshake_done = true
		conn.alpn_selected = selected_alpn(conn)
		return .Ok
	}
	return status_from_ssl_error(conn.ssl, ret)
}

shutdown :: proc(conn: ^Connection) -> TLS_Status {
	if conn == nil || conn.ssl == nil {
		return .Error
	}
	ret := SSL_shutdown(conn.ssl)
	if ret == 1 {
		return .Ok
	}
	return status_from_ssl_error(conn.ssl, ret)
}

feed_incoming :: proc(conn: ^Connection, data: []u8) -> bool {
	if conn == nil || conn.in_bio == nil {
		return false
	}
	if len(data) == 0 {
		return true
	}
	return BIO_write_all(conn.in_bio, &data[0], c.size_t(len(data))) == 1
}

pending_outgoing :: proc(conn: ^Connection) -> int {
	if conn == nil || conn.out_bio == nil {
		return 0
	}
	return int(BIO_ctrl_pending(conn.out_bio))
}

read_outgoing :: proc(conn: ^Connection, out: []u8) -> int {
	if conn == nil || conn.out_bio == nil {
		return -1
	}
	if len(out) == 0 {
		return 0
	}
	return int(BIO_read(conn.out_bio, &out[0], i32(len(out))))
}

read_app :: proc(conn: ^Connection, out: []u8) -> (n: int, status: TLS_Status) {
	if conn == nil || conn.ssl == nil {
		return 0, .Error
	}
	if len(out) == 0 {
		return 0, .Ok
	}
	ret := SSL_read(conn.ssl, &out[0], i32(len(out)))
	if ret > 0 {
		return int(ret), .Ok
	}
	return 0, status_from_ssl_error(conn.ssl, ret)
}

write_app :: proc(conn: ^Connection, data: []u8) -> (n: int, status: TLS_Status) {
	if conn == nil || conn.ssl == nil {
		return 0, .Error
	}
	if len(data) == 0 {
		return 0, .Ok
	}
	ret := SSL_write(conn.ssl, &data[0], i32(len(data)))
	if ret > 0 {
		return int(ret), .Ok
	}
	return 0, status_from_ssl_error(conn.ssl, ret)
}

selected_alpn :: proc(conn: ^Connection) -> ALPN_Protocol {
	if conn == nil || conn.ssl == nil {
		return .Unknown
	}
	var data: ^u8
	var len_u32: u32
	SSL_get0_alpn_selected(conn.ssl, &data, &len_u32)
	if data == nil || len_u32 == 0 {
		return .Unknown
	}

	bytes := unsafe_slice(data, int(len_u32))
	if mem.compare(bytes, []u8("h2")) == 0 {
		return .HTTP2
	}
	if mem.compare(bytes, []u8("http/1.1")) == 0 {
		return .HTTP1_1
	}
	return .Unknown
}

last_error_string :: proc(buf: []u8) -> string {
	if len(buf) == 0 {
		return ""
	}
	code := ERR_get_error()
	if code == 0 {
		buf[0] = 0
		return ""
	}
	ERR_error_string_n(code, cstring(&buf[0]), c.size_t(len(buf)))
	end := 0
	for end < len(buf) && buf[end] != 0 {
		end += 1
	}
	return string(buf[0:end])
}

status_from_ssl_error :: proc(ssl: ^SSL, ret: i32) -> TLS_Status {
	err := SSL_get_error(ssl, ret)
	switch err {
	case SSL_ERROR_NONE:		return .Ok
	case SSL_ERROR_WANT_READ:	return .Want_Read
	case SSL_ERROR_WANT_WRITE:	return .Want_Write
	case SSL_ERROR_ZERO_RETURN:	return .Closed
	case SSL_ERROR_SYSCALL:		return .Error
	case SSL_ERROR_SSL:		return .Error
	case:				return .Error
	}
}

alpn_select_cb :: proc "c" (ssl: ^SSL, out: ^^u8, out_len: ^u8, _in: ^u8, in_len: u32, arg: rawptr) -> i32 {
	ctx := (^Context)(arg)
	if ctx == nil || len(ctx.alpn_wire) == 0 || _in == nil || in_len == 0 {
		return SSL_TLSEXT_ERR_NOACK
	}

	res := SSL_select_next_proto(out, out_len, _in, in_len, &ctx.alpn_wire[0], u32(len(ctx.alpn_wire)))
	if res == OPENSSL_NPN_NEGOTIATED {
		return SSL_TLSEXT_ERR_OK
	}
	return SSL_TLSEXT_ERR_NOACK
}
