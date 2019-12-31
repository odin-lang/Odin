package http

import "core:net"


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




Response :: struct {
	status: Status,
	headers: map[string]string, // TODO: We don't currently destroy the keys or values.
	body: string,
}

response_destroy :: proc(using r: ^Response) {
	// TODO(tetra): Use arenas for the map data in Requests and Responses so that the memory
	// can be block-freed.
	for k, v in headers {
		delete(k);
		delete(v);
	}
	delete(headers);
	delete(body);
	r^ = {};
}



Method :: enum u8 {
	Get,
	Post,
}

Request :: struct {
	method: Method,
	scheme, host, path: string, // NOTE: _NOT_ percent encoded.
	headers, queries: map[string]string,
	body: string,
}

request_init :: proc(req: ^Request, method: Method, url: string, allocator := context.allocator) {
	scheme, host, path, queries := net.split_url(url, allocator);
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
