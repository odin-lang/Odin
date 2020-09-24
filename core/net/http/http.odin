package http

import "core:net"
import "core:strings"
import "core:os"
import "core:strconv"
import "core:mem"
import "core:fmt" // for panicf

Status :: enum {
	Unknown = 0,

	// NOTE(tetra): Only produced by recv_request.
	Bad_Response_Header = -1,
	Bad_Status_Code = -2,

	Ok = 200,
	Bad_Request = 400,
	Forbidden = 403,
	Not_Found = 404,
	Im_A_Teapot = 418,

	Moved_Permanently = 301,
	Moved_Temporarily = 302,
	See_Other = 303,
	Not_Modified = 304,
	Temporary_Redirect = 307, // same as Moved_Temporarily, but requires use of same Method.
	Permanent_Redirect = 308, // same as Moved_Permanently, but requires use of same Method.

	Internal_Error = 500,
	Not_Implemented = 501,
	Bad_Upstream_Response = 502,
	Service_Unavailable = 503,
	No_Upstream_Response = 504,
}

Method :: enum u8 {
	Get,
	Post,
}



Response :: struct {
	status: Status,
	headers: map[string]string, // TODO: We don't currently destroy the keys or values.
	body: string,
}

response_destroy :: proc(using r: Response) {
	// TODO(tetra): Use arenas for the map data in Requests and Responses so that the memory
	// can be block-freed.
	for k, v in headers {
		delete(k, headers.allocator);
		delete(v, headers.allocator);
	}
	delete(headers);
	delete(body);
}



Request :: struct {
	method: Method,
	scheme, host, path: string, // NOTE: _NOT_ percent encoded.
	headers, queries: map[string]string,
	body: string,
}

request_init :: proc(req: ^Request, method: Method, url: string, allocator := context.allocator) {
	scheme, host, path, queries := net.split_url(url, allocator);
	req^ = Request {
		method = method,
		scheme = scheme,
		host = host,
		path = path,
		queries = queries,
	};
	req.headers.allocator = allocator;
}

request_destroy :: proc(using req: Request) {
	delete(headers);
	delete(queries);
}



get :: proc(url: string, allocator := context.allocator) -> (resp: Response, ok: bool) {
	r: Request;
	request_init(&r, .Get, url, allocator);
	defer if !ok do request_destroy(r);
	r.headers["Connection"] = "close";
	resp, ok = execute_request(r, allocator);
	return;
}

send_request :: proc(r: Request, allocator := context.allocator) -> (socket: net.Socket, ok: bool) {
	if r.scheme != "http" {
		fmt.panicf("%v is not a supported scheme at this time", r.scheme);
	}

	host, port, port_ok := net.split_port(r.host);
	if !port_ok do return;
	if port == 0 do port = 80;

	addr4, addr6, resolve_ok := net.resolve(host);
	if !resolve_ok do return;
	addr := addr4 != nil ? addr4 : addr6;

	// TODO(tetra): SSL/TLS.
	skt, err := net.dial(addr, port, .Tcp);
	if err != .Ok do return;

	bytes := request_to_bytes(r, allocator);
	if bytes == nil do return;
	defer delete(bytes);

	_, write_err := net.send(skt, bytes);
	if write_err != .Ok do return;

	return skt, true;
}

// TODO(tetra): Ideally, we'd have a nice way to read from a slice too.
recv_response :: proc(skt: net.Socket, allocator := context.allocator) -> (resp: Response, ok: bool) {
	using strings;

	context.allocator = allocator;

	// TODO: Read all the data, then parse it.

	read_buf: [8192]byte = ---;
	incoming := make_builder(0, 8192);
	defer destroy_builder(&incoming);
	for {
		// if has_suffix(to_string(incoming), "\r\n\r\n") do break;

		n, read_err := net.recv(skt, read_buf[:]);
		if read_err != .Ok do return;
		if n == 0 do break;

		write_bytes(&incoming, read_buf[:n]);
	}

	resp_parts := split(to_string(incoming), "\n");
	assert(len(resp_parts) >= 1);

	status_parts := split(resp_parts[0], " ");
	assert(len(status_parts) >= 3); // NOTE(tetra): 3 for OK, more if status text is more than one word.

	status_code, _ := strconv.parse_int(status_parts[1]);
	resp.status = Status(status_code);

	resp_parts = resp_parts[1:];

	// TODO(tetra): Use an arena for the response data.
	resp.headers = make(map[string]string, len(resp_parts));
	defer if !ok do response_destroy(resp);

	last_hdr_index := -1;
	for part, i in resp_parts {
		trimmed_part := trim_right_space(part);
		last_hdr_index = i;
		if trimmed_part == "" do break; // end of headers. (empty, because we split by newlines.)

		idx := index(trimmed_part, ":");
		if idx == -1 {
			resp.status = .Bad_Response_Header;
			return;
		}
		// the header parts are currently in `read_buf` (temporary memory), but we want to return them.
		name  := clone(trim_space(trimmed_part[:idx]));
		value := clone(trim_space(trimmed_part[idx+1:]));
		resp.headers[name] = value;

	}
	if last_hdr_index == -1 {
		// NOTE(tetra): Should have found the last header.
		resp.status = .Bad_Response_Header;
		return;
	}

	if resp.status != .Ok {
		ok = true;
		return;
	}

	body_buf := make_builder(0, 8192);
	defer if !ok do destroy_builder(&body_buf);

	explicit_encoding, _ := resp.headers["Transfer-Encoding"]; // NOTE(tetra): error ignored because it'll be the empty string if there was one
	switch {
	case explicit_encoding == "":
		remaining := resp_parts[last_hdr_index+1:];
		for len(remaining) > 0 {
			if has_suffix(to_string(body_buf), "\r\n\r\n") do break;
			chunk := remaining[0];
			write_bytes(&body_buf, transmute([]byte) trim_right_space(chunk));
			remaining = remaining[1:];
		}
	case explicit_encoding == "chunked":
		// NOTE(tetra): instead of getting the body as normal, you get the number of bytes in the following chunk,
		// followed by \r\n\r\n, followed by the chunk.
		remaining := resp_parts[last_hdr_index+1:];
		expect_count := true;
		was_blank := false;
		for len(remaining) > 0 {
			defer remaining = remaining[1:];
			if expect_count {
				expect_count = false;
				continue;
			}
			chunk := remaining[0];
			if was_blank && chunk == "" {
				break;
			}
			if chunk == "" {
				// means it was \r\n\r\n
				was_blank = true;
				continue;
			}
			fmt.printf("committing chunk with %v bytes: %v\n", len(chunk), chunk if len(chunk) <= 16 else "<...>");
			write_bytes(&body_buf, transmute([]byte) trim_right_space(chunk));
			expect_count = true;
		}
		// for len(remaining) > 0 {
		// 	if len(remaining) < 3 do break;
		// 	size_part := remaining[0];
		// 	chunk := remaining[1];
		// 	empty := remaining[2];
		// 	assert(empty == "");
		// 	remaining = remaining[3:];
		// 	write_bytes(&body_buf, transmute([]byte) chunk);
		// }
	case:
		return;
	}

	// TODO(tetra): Use the content-length to slice the body.
	body := to_string(body_buf);
	resp.body = body;
	ok = true;
	return;
}

// Executes an HTTP 1.1 request.
// Follows 301 redirects.
// If ok=true, you should call response_destroy on the response.
execute_request :: proc(r: Request, allocator := context.allocator) -> (response: Response, ok: bool) {
	r := r;
	resp: Response;

	context.allocator = allocator;

	for {
		skt, send_ok := send_request(r);
		if !send_ok do return;
		defer net.close(skt);

		read_ok: bool;
		resp, read_ok = recv_response(skt);
		if !read_ok do return;

		if resp.status != .Moved_Permanently {
			break;
		} else {
			location, has_new_location := resp.headers["Location"];
			if !has_new_location do return;

			r2 := r;
			request_init(&r2, .Get, location);
			r2.headers = r.headers;
			r2.queries = r.queries;
			r = r2;

			response_destroy(resp);
		}
	}

	response = resp;
	ok = true;
	return;
}

request_to_bytes :: proc(r: Request, allocator := context.allocator) -> []byte {
	using strings;

	b := make_builder(allocator);
	grow_builder(&b, 8192);
	if b.buf == nil do return nil;

	assert(r.method == .Get, "only GET requests are supported at this time");
	write_string(&b, "GET ");

	write_string(&b, r.path);

	if r.queries != nil {
		write_rune(&b, '?');
		for query_name, query_value in r.queries {
			write_string(&b, query_name);
			if query_value != "" {
				write_string(&b, "=");
				write_string(&b, net.percent_encode(query_value, context.temp_allocator));
			}
		}
	}
	write_string(&b, " HTTP/1.1\r\n");

	if _, ok := r.headers["Host"]; !ok {
		write_string(&b, "Host: ");
		write_string(&b, r.host);
		write_string(&b, "\r\n");
	}
	for name, value in r.headers {
		write_string(&b, name);
		write_string(&b, ": ");
		write_string(&b, value);
		write_string(&b, "\r\n");
	}

	if r.body != "" {
		write_string(&b, r.body);
		write_string(&b, "\r\n");
	}

	write_string(&b, "\r\n");
	return b.buf[:];
}
