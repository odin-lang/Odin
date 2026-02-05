package bifrost_tls

import "core:c"
import "core:mem"
import "base:runtime"
import "core:strings"
import bssl "vendor:bifrost/tls/bindings"


TLS_Status :: enum {
	Ok,
	Want_Read,
	Want_Write,
	Closed,
	Error,
}

Context :: struct {
	ctx: ^bssl.SSL_CTX,
	is_server: bool,
	alpn_wire: []u8,
}

Connection :: struct {
	ssl: ^bssl.SSL,
	in_bio:  ^bssl.BIO,
	out_bio: ^bssl.BIO,
	is_server: bool,
	handshake_done: bool,
	alpn_selected: ALPN_Protocol,
}

context_create :: proc(config: ^Config, is_server: bool) -> (ctx: ^Context, ok: bool) {
	method := bssl.TLS_method()
	if method == nil {
		return nil, false
	}

	ssl_ctx := bssl.SSL_CTX_new(method)
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
				case .Unknown: str = ""
				}
				if len(str) == 0 || len(str) > 255 {
					bssl.SSL_CTX_free(ssl_ctx)
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
				case .Unknown: str = ""
				}
				ctx.alpn_wire[idx] = u8(len(str))
				idx += 1
				runtime.copy_from_string(ctx.alpn_wire[idx:], str)
				idx += len(str)
			}

			if is_server {
				bssl.SSL_CTX_set_alpn_select_cb(ssl_ctx, alpn_select_cb, ctx)
			} else {
				if bssl.SSL_CTX_set_alpn_protos(ssl_ctx, &ctx.alpn_wire[0], c.size_t(len(ctx.alpn_wire))) != 0 {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
			}
		}

		if is_server {
			defer runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			if config.cert_chain_file != "" {
				cert_cstr, cerr := strings.clone_to_cstring(config.cert_chain_file, context.temp_allocator)
				if cerr != nil {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
				if bssl.SSL_CTX_use_certificate_chain_file(ssl_ctx, cert_cstr) != 1 {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
			}
			if config.key_file != "" {
				key_cstr, kerr := strings.clone_to_cstring(config.key_file, context.temp_allocator)
				if kerr != nil {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
				if bssl.SSL_CTX_use_PrivateKey_file(ssl_ctx, key_cstr, bssl.SSL_FILETYPE_PEM) != 1 {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
			}
		}

		if config.ca_file != "" || config.ca_dir != "" {
			defer runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			ca_file_cstr: cstring
			ca_dir_cstr: cstring
			if config.ca_file != "" {
				ca_cstr, cerr := strings.clone_to_cstring(config.ca_file, context.temp_allocator)
				if cerr != nil {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
				ca_file_cstr = ca_cstr
			}
			if config.ca_dir != "" {
				dir_cstr, derr := strings.clone_to_cstring(config.ca_dir, context.temp_allocator)
				if derr != nil {
					bssl.SSL_CTX_free(ssl_ctx)
					return nil, false
				}
				ca_dir_cstr = dir_cstr
			}
			if bssl.SSL_CTX_load_verify_locations(ssl_ctx,
				(ca_file_cstr if config.ca_file != "" else nil),
				(ca_dir_cstr if config.ca_dir != "" else nil),
			) != 1 {
				bssl.SSL_CTX_free(ssl_ctx)
				return nil, false
			}
		}

		if config.verify_depth > 0 {
			bssl.SSL_CTX_set_verify_depth(ssl_ctx, i32(config.verify_depth))
		}

		if config.verify_peer {
			mode := bssl.SSL_VERIFY_PEER
			if is_server && config.require_client_cert {
				mode = bssl.SSL_VERIFY_PEER | bssl.SSL_VERIFY_FAIL_IF_NO_PEER_CERT
			}
			bssl.SSL_CTX_set_verify(ssl_ctx, i32(mode), nil)
		} else {
			bssl.SSL_CTX_set_verify(ssl_ctx, bssl.SSL_VERIFY_NONE, nil)
		}
	}

	return ctx, true
}

context_free :: proc(ctx: ^Context) {
	if ctx == nil {
		return
	}
	if ctx.ctx != nil {
		bssl.SSL_CTX_free(ctx.ctx)
		ctx.ctx = nil
	}
	if ctx.alpn_wire != nil {
		delete(ctx.alpn_wire)
		ctx.alpn_wire = nil
	}
}

connection_create :: proc(ctx: ^Context, is_server: bool, server_name: string = "") -> (conn: ^Connection, ok: bool) {
	if ctx == nil || ctx.ctx == nil {
		return nil, false
	}

	ssl := bssl.SSL_new(ctx.ctx)
	if ssl == nil {
		return nil, false
	}

	in_bio := bssl.BIO_new(bssl.BIO_s_mem())
	out_bio := bssl.BIO_new(bssl.BIO_s_mem())
	if in_bio == nil || out_bio == nil {
		bssl.SSL_free(ssl)
		return nil, false
	}

	bssl.SSL_set_bio(ssl, in_bio, out_bio)

	if is_server {
		bssl.SSL_set_accept_state(ssl)
	} else {
		bssl.SSL_set_connect_state(ssl)
		if server_name != "" {
			defer runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			host_cstr, herr := strings.clone_to_cstring(server_name, context.temp_allocator)
			if herr != nil {
				bssl.SSL_free(ssl)
				return nil, false
			}
			_ = bssl.SSL_set1_host(ssl, host_cstr)
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
		bssl.SSL_free(conn.ssl)
		conn.ssl = nil
	}
	conn.in_bio = nil
	conn.out_bio = nil
	free(conn)
}

handshake :: proc(conn: ^Connection) -> TLS_Status {
	if conn == nil || conn.ssl == nil {
		return .Error
	}
	if conn.handshake_done {
		return .Ok
	}

	ret := bssl.SSL_do_handshake(conn.ssl)
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
	ret := bssl.SSL_shutdown(conn.ssl)
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
	return bssl.BIO_write_all(conn.in_bio, &data[0], c.size_t(len(data))) == 1
}

pending_outgoing :: proc(conn: ^Connection) -> int {
	if conn == nil || conn.out_bio == nil {
		return 0
	}
	return int(bssl.BIO_ctrl_pending(conn.out_bio))
}

read_outgoing :: proc(conn: ^Connection, out: []u8) -> int {
	if conn == nil || conn.out_bio == nil {
		return -1
	}
	if len(out) == 0 {
		return 0
	}
	return int(bssl.BIO_read(conn.out_bio, &out[0], i32(len(out))))
}

read_app :: proc(conn: ^Connection, out: []u8) -> (n: int, status: TLS_Status) {
	if conn == nil || conn.ssl == nil {
		return 0, .Error
	}
	if len(out) == 0 {
		return 0, .Ok
	}
	ret := bssl.SSL_read(conn.ssl, &out[0], i32(len(out)))
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
	ret := bssl.SSL_write(conn.ssl, &data[0], i32(len(data)))
	if ret > 0 {
		return int(ret), .Ok
	}
	return 0, status_from_ssl_error(conn.ssl, ret)
}

selected_alpn :: proc(conn: ^Connection) -> ALPN_Protocol {
	if conn == nil || conn.ssl == nil {
		return .Unknown
	}
	data: ^u8
	len_u32: u32
	bssl.SSL_get0_alpn_selected(conn.ssl, &data, &len_u32)
	if data == nil || len_u32 == 0 {
		return .Unknown
	}

	bytes := transmute([]u8)mem.Raw_Slice{data, int(len_u32)}
	if mem.compare(bytes, transmute([]u8)string("h2")) == 0 {
		return .HTTP2
	}
	if mem.compare(bytes, transmute([]u8)string("http/1.1")) == 0 {
		return .HTTP1_1
	}
	return .Unknown
}

last_error_string :: proc(buf: []u8) -> string {
	if len(buf) == 0 {
		return ""
	}
	code := bssl.ERR_get_error()
	if code == 0 {
		buf[0] = 0
		return ""
	}
	bssl.ERR_error_string_n(code, cstring(&buf[0]), c.size_t(len(buf)))
	end := 0
	for end < len(buf) && buf[end] != 0 {
		end += 1
	}
	return string(buf[0:end])
}

status_from_ssl_error :: proc(ssl: ^bssl.SSL, ret: i32) -> TLS_Status {
	err := bssl.SSL_get_error(ssl, ret)
	switch err {
	case bssl.SSL_ERROR_NONE:		return .Ok
	case bssl.SSL_ERROR_WANT_READ:	return .Want_Read
	case bssl.SSL_ERROR_WANT_WRITE:	return .Want_Write
	case bssl.SSL_ERROR_ZERO_RETURN:	return .Closed
	case bssl.SSL_ERROR_SYSCALL:		return .Error
	case bssl.SSL_ERROR_SSL:		return .Error
	case:				return .Error
	}
}

alpn_select_cb :: proc "c" (ssl: ^bssl.SSL, out: ^^u8, out_len: ^u8, _in: ^u8, in_len: u32, arg: rawptr) -> i32 {
	ctx := (^Context)(arg)
	if ctx == nil || len(ctx.alpn_wire) == 0 || _in == nil || in_len == 0 {
		return bssl.SSL_TLSEXT_ERR_NOACK
	}

	res := bssl.SSL_select_next_proto(out, out_len, _in, in_len, &ctx.alpn_wire[0], u32(len(ctx.alpn_wire)))
	if res == bssl.OPENSSL_NPN_NEGOTIATED {
		return bssl.SSL_TLSEXT_ERR_OK
	}
	return bssl.SSL_TLSEXT_ERR_NOACK
}
