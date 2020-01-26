package http

import "core:net"
import "core:strings"
import "core:strconv"

Status :: enum {
	Unknown = 0,
	Bad_Response_Header = -1, // NOTE(tetra): Only produced by execute_request.

	Ok = 200,
	Bad_Request = 400,
	Forbidden = 403,
	Not_Found = 404,
	Im_A_Teapot = 418,

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

response_destroy :: proc(using r: ^Response) {
	// TODO(tetra): Use arenas for the map data in Requests and Responses so that the memory
	// can be block-freed.
	for k, v in headers {
		delete(k, headers.allocator);
		delete(v, headers.allocator);
	}
	delete(headers);
	delete(body);
	r^ = {};
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



get :: proc(url: string, allocator := context.allocator) -> (resp: Response, ok: bool) {
	r: Request;
	request_init(&r, .Get, url, allocator);
	r.headers["Connection"] = "close";
	resp, ok = execute_request(r, allocator);
	return;
}

execute_request :: proc(r: Request, allocator := context.allocator) -> (resp: Response, ok: bool) {
	using strings;

	assert(r.scheme == "http", "only HTTP is supported at this time");

	context.allocator = allocator;

	addr4, addr6, resolve_ok := net.resolve(r.host);
	if !resolve_ok do return;
	addr := addr4 != nil ? addr4 : addr6;

	// TODO(tetra): SSL/TLS.
	skt, err := net.dial(addr, 80);
	if err != .Ok do return; // TODO(tetra): return instead?

	bytes := request_to_bytes(r);
	if bytes == nil do return;

	write_err := net.write(skt, bytes);
	if write_err != .Ok do return; // TODO(tetra): return instead?

	read_err: net.Read_Error;
	resp, read_err = read_response(skt);
	if read_err != .Ok do return; // TODO(tetra): return instead?

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

// TODO(tetra): Ideally, we'd have a nice way to read from a slice too.
read_response :: proc(skt: net.Socket, allocator := context.allocator) -> (resp: Response, read_err: net.Read_Error) {
	using strings;

	context.allocator = allocator;

	// TODO(tetra): Handle not receiving the response in one read call.
	read_buf: [4096]byte;
	n: int;
	n, read_err = net.read(skt, read_buf[:]);
	assert(n > 0); // TODO

	resp_parts := split(string(read_buf[:n]), "\n");
	assert(len(resp_parts) >= 1);

	status_parts := split(resp_parts[0], " ");
	assert(len(status_parts) >= 3); // NOTE(tetra): 3 for OK, more if status text is more than one word.

	status_code, _ := strconv.parse_int(status_parts[1]);
	resp.status = Status(status_code);

	resp_parts = resp_parts[1:];

	// TODO(tetra): Use an arena for the response data.
	resp.headers = make(map[string]string, len(resp_parts));
	defer if read_err != .Ok do response_destroy(&resp);

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
		// the header parts are currently in `read_buf` (stack memory), but we want to return them.
		name  := clone(trim_space(trimmed_part[:idx]));
		value := clone(trim_space(trimmed_part[idx+1:]));
		resp.headers[name] = value;

	}
	if last_hdr_index == -1 {
		// NOTE(tetra): Should have found the last header.
		resp.status = .Bad_Response_Header;
		return;
	}

	// TODO(tetra): Use the content-length to slice the body.
	body := resp_parts[last_hdr_index+1];
	body = trim_space(body);
	resp.body = clone(body);
	return;
}