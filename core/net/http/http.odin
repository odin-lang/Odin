package http

import "core:net"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:fmt"

Status :: enum {
	Ok = 200,
	Bad_Request = 400,
	Bad_Response_Header,
	Forbidden = 403,
	Not_Found = 404,
	Internal_Error = 500,
}

Response :: struct {
	status: Status,
	headers: map[string]string,
	body: string,
}

destroy_response :: proc(using r: ^Response) {
	delete(headers);
	delete(body);
	headers = nil;
	body = "";
}

get :: proc(url: string, allocator := context.allocator) -> (resp: Response, ok: bool) {
	r: Request;
	init_request(&r, .Get, url, allocator);
	r.headers["Connection"] = "close";
	resp, ok = execute_request(r, allocator);
	return;
}

Request :: struct {
	method: Method,
	// NOTE(tetra): NOT percent encoded.
	// This is done in execute_request to isolate the programmer from this detail.
	scheme, host, path: string,
	headers, queries: map[string]string,
	body: string,
}

Method :: enum u8 {
	Get,
	Post,
}

init_request :: proc(req: ^Request, method: Method, url: string, allocator := context.allocator) {
	scheme, host, path, queries := net.split_url(url);
	assert(scheme == "http");
	req^ = Request {
		method = method,
		scheme = scheme,
		host = host,
		path = path,
		queries = queries,
	};
	req.headers.allocator = allocator;
	req.headers["Host"] = host;
}

execute_request :: proc(r: Request, response_allocator := context.allocator) -> (resp: Response, ok: bool) {
	using strings;

	// pool: mem.Dynamic_Pool;
	// mem.dynamic_pool_init(&pool, allocator, allocator, 1024);
	// defer mem.dynamic_pool_destroy(&pool);
	// context.allocator = mem.dynamic_pool_allocator(&pool);

	addr4, addr6, resolve_ok := net.resolve(r.host);
	if !resolve_ok do return;
	addr := addr4 != nil ? addr4 : addr6;


	// TODO(tetra): Use arena and stack allocate if possible?
	// Maybe instead of building the string, just write it to the socket incrementally
	// to avoid allocation.
	b := make_builder(context.temp_allocator);
	grow_builder(&b, 1024);
	defer destroy_builder(&b);
	
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


	for header_name, header_value in r.headers {
		write_string(&b, header_name);
		write_string(&b, ": ");
		write_string(&b, header_value);
		write_string(&b, "\r\n");
	}

	write_string(&b, "\r\n");
	req_str := to_string(b);

	fmt.printf("%q\n", req_str);

	skt, err := net.dial(addr, 80); // TODO(tetra): HTTPS
	if err != nil do return; // TODO(tetra): return instead?
	defer net.close(skt);

	write_err := net.write(skt, req_str);
	if write_err != nil do return; // TODO(tetra): return instead?

	read_buf: [4096]byte;
	n, read_err := net.read(skt, read_buf[:]);
	if read_err != nil do return; // TODO(tetra): return instead?

	resp_parts := split(string(read_buf[:n]), "\n");

	assert(len(resp_parts) >= 1);

	status_parts := split(resp_parts[0], " ");
	assert(len(status_parts) >= 3); // NOTE(tetra): 3 for OK, more if status text is more than one word.

	i, _ := strconv.parse_int(status_parts[1]);
	resp.status = Status(i);

	resp_parts = resp_parts[1:];

	resp.headers = make(map[string]string, len(resp_parts), response_allocator);
	// NOTE(tetra): conform to the common idiom that ok=false means that the
	// that the caller does not have to clean up `resp` ... because we already did.
	defer if !ok do delete(resp.headers);

	last_hdr_index := -1;
	for part, i in resp_parts {
		trimmed_part := trim_right_space(part);
		last_hdr_index = i;
		if trimmed_part == "" do break; // end of headers. (empty, because we split by newlines.)

		hdr_parts := split(trimmed_part, ":");
		if len(hdr_parts) < 2 {
			resp.status = .Bad_Response_Header;
			return;
		}

		header_name := clone(trim_space(hdr_parts[0]), response_allocator); // the hdr_parts are currently in `read_buf` (stack memory), but we want to return them.
		header_value := clone(trim_space(hdr_parts[1]), response_allocator);
		resp.headers[header_name] = header_value;
	}
	if last_hdr_index == -1 {
		// NOTE(tetra): Should have found the last header.
		// TODO(tetra): Handle not receiving the response in one read call.
		resp.status = .Bad_Response_Header;
		return;
	}

	body := resp_parts[last_hdr_index+1];
	body = trim_space(body);
	resp.body = clone(body, response_allocator);

	ok = true;
	return;
}