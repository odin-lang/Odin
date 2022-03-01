/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

/*
	Package http implements the HTTP 1.x protocol using the cross-platform sockets from package net.
	For other protocols, see their respective subdirectories of the net package.
*/
package http

import "core:net"
import "core:strings"
import "core:strconv"
import "core:fmt" // for panicf
import "core:time"

/*
	By default we allow a generous 10 redirects, which the programmer can override at runtime and compile-time.
	We limit it to a maximum of 50 to prevent accidental misconfiguration causing a DOS.

	If you have a legitmate reason to require more than this amount of redirects,
	feel free to clone `get` and `execute_request` into your project.
*/
ODIN_HTTP_MAX_REDIRECTS :: #config(ODIN_HTTP_MAX_REDIRECTS, 10)
#assert(ODIN_HTTP_MAX_REDIRECTS > 0 && ODIN_HTTP_MAX_REDIRECTS <= 50)


Status_Code :: enum {
	Unknown = 0,

	// NOTE(tetra): Only produced by recv_request.
	Bad_Response_Header = -1,
	Bad_Status_Code = -2,

	Too_Many_Redirects = -3,

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
	GET,
	POST,
	PUT,
	HEAD,
	DELETE,
}


get :: proc(url: string, max_redirects := ODIN_HTTP_MAX_REDIRECTS, options := default_request_options, allocator := context.allocator) -> (resp: Response, ok: bool) {
	r: Request
	request_init(&r, .GET, url, options, allocator)
	defer request_destroy(r)
	resp, ok = execute_request(r, max_redirects, allocator)
	return
}



Response :: struct {
	status_code: Status_Code,
	headers: map[string]string, // TODO: We don't currently destroy the keys or values.
	body: string,
}

response_destroy :: proc(using r: Response) {
	// TODO(tetra): Use arenas for the map data in Requests and Responses so that the memory
	// can be block-freed.
	for k, v in headers {
		delete(k, headers.allocator)
		delete(v, headers.allocator)
	}
	delete(headers)
	delete(body, headers.allocator)
}


ODIN_HTTP_DEFAULT_SEND_TIMEOUT_MILLISECONDS    :: #config(ODIN_HTTP_DEFAULT_SEND_TIMEOUT_MILLISECONDS,    5000)
ODIN_HTTP_DEFAULT_RECEIVE_TIMEOUT_MILLISECONDS :: #config(ODIN_HTTP_DEFAULT_RECEIVE_TIMEOUT_MILLISECONDS, 5000)
Request_Options :: struct {
	send_timeout: time.Duration,
	recv_timeout: time.Duration,
}
default_request_options := Request_Options {
	send_timeout = time.Millisecond * ODIN_HTTP_DEFAULT_SEND_TIMEOUT_MILLISECONDS,
	recv_timeout = time.Millisecond * ODIN_HTTP_DEFAULT_RECEIVE_TIMEOUT_MILLISECONDS,
}

Request :: struct {
	method:             Method,
	scheme, host, path: string, // NOTE: _NOT_ percent encoded.
	headers, queries:   map[string]string,
	body:               string,
	options:            Request_Options, // TODO(tetra): Consider if we actually want these 16 bytes to be in every request
}

request_init :: proc(req: ^Request, method: Method, url: string, options := default_request_options, allocator := context.allocator) {
	scheme, host, path, queries := net.split_url(url, allocator)
	req^ = Request {
		method = method,
		scheme = scheme,
		host = host,
		path = path,
		queries = queries,
		options = options,
	}
	req.headers.allocator = allocator
}

request_destroy :: proc(using req: Request) {
	delete(headers)
	delete(queries)
}



send_request :: proc(r: Request, allocator := context.allocator) -> (socket: net.TCP_Socket, ok: bool) {
	scheme := r.scheme
	if scheme == "" {
		scheme = "http"
	}
	if scheme != "http" {
		fmt.panicf("%v is not a supported scheme at this time", scheme)
	}

	// NOTE(tetra): The host string may or may not have a port,
	// but dial needs one.
	host, port := net.split_port(r.host) or_return
	if port == 0 {
		port = 80
	}

	// TODO(tetra): SSL/TLS.
	skt, err := net.dial_tcp(host, port)
	if err != nil do return

	net.set_option(skt, .Send_Timeout, r.options.send_timeout)
	net.set_option(skt, .Receive_Timeout, r.options.recv_timeout)

	bytes := request_to_bytes(r, allocator)
	if bytes == nil do return
	defer delete(bytes)

	_, write_err := net.send(skt, bytes)
	if write_err != nil do return
	return skt, true
}

// TODO(tetra): Ideally, we'd have a nice way to read from a slice too.
recv_response :: proc(skt: net.TCP_Socket, allocator := context.allocator) -> (resp: Response, ok: bool) {
	using strings

	context.allocator = allocator

	// TODO: Read all the data, then parse it.

	read_buf: [8192]byte = ---
	incoming := make_builder(0, 8192)
	defer destroy_builder(&incoming)
	for {
		n, read_err := net.recv(skt, read_buf[:])
		if read_err != nil do return
		if n == 0 do break

		write_bytes(&incoming, read_buf[:n])
	}

	resp_parts := split(to_string(incoming), "\n", context.temp_allocator)
	if len(resp_parts) < 1 {
		return
	}

	status_parts := split(resp_parts[0], " ", context.temp_allocator)
	// NOTE(tetra): 3 for OK, more if status text is more than one word.
	if len(status_parts) < 3 {
		return
	}

	status_code, _ := strconv.parse_int(status_parts[1])
	resp.status_code = Status_Code(status_code)

	resp_parts = resp_parts[1:]

	// TODO(tetra): Use an arena for the response data.
	resp.headers = make(map[string]string, len(resp_parts))
	defer if !ok do response_destroy(resp)

	last_hdr_index := -1
	for part, i in resp_parts {
		trimmed_part := trim_right_space(part)
		last_hdr_index = i
		if trimmed_part == "" do break // end of headers. (empty, because we split by newlines.)

		idx := index(trimmed_part, ":")
		if idx == -1 {
			resp.status_code = .Bad_Response_Header
			return
		}
		// the header parts are currently in `read_buf` (temporary memory), but we want to return them.
		name  := clone(trim_space(trimmed_part[:idx]), resp.headers.allocator)
		value := clone(trim_space(trimmed_part[idx+1:]), resp.headers.allocator)
		resp.headers[name] = value

	}
	if last_hdr_index == -1 {
		// NOTE(tetra): Should have found the last header.
		resp.status_code = .Bad_Response_Header
		return
	}

	if resp.status_code != .Ok {
		ok = true
		return
	}

	body_buf := make_builder(0, 8192)
	defer if !ok do destroy_builder(&body_buf)

	explicit_encoding, _ := resp.headers["Transfer-Encoding"] // NOTE(tetra): error ignored because it'll be the empty string if there was one
	switch {
	case explicit_encoding == "":
		remaining := resp_parts[last_hdr_index+1:]
		for len(remaining) > 0 {
			if has_suffix(to_string(body_buf), "\r\n\r\n") do break
			chunk := remaining[0]
			write_string(&body_buf, trim_right_space(chunk))
			remaining = remaining[1:]
		}
	case explicit_encoding == "chunked":
		// NOTE(tetra): instead of getting the body as normal, you get the number of bytes in the following chunk,
		// followed by \r\n\r\n, followed by the chunk.
		remaining := resp_parts[last_hdr_index+1:]
		expect_count := true
		was_blank := false
		for len(remaining) > 0 {
			defer remaining = remaining[1:]
			if expect_count {
				expect_count = false
				continue
			}
			chunk := remaining[0]
			if was_blank && chunk == "" {
				break
			}
			if chunk == "" {
				// means it was \r\n\r\n
				was_blank = true
				continue
			}
			write_string(&body_buf, trim_right_space(chunk))
			expect_count = true
		}
	case:
		return
	}

	// TODO(tetra): Use the content-length to slice the body.
	body := to_string(body_buf)
	resp.body = body
	ok = true
	return
}

// Executes an HTTP 1.1 request.
// Follows 301 redirects.
// If ok=true, you should call response_destroy on the response.
execute_request :: proc(r: Request, max_redirects := ODIN_HTTP_MAX_REDIRECTS, allocator := context.allocator) -> (response: Response, ok: bool) {
	r := r
	max_redirects := max_redirects

	resp: Response
	context.allocator = allocator

	redirect_count := 0
	max_redirects   = min(max_redirects, ODIN_HTTP_MAX_REDIRECTS)

	location: string
	for {
		skt := send_request(r) or_return
		defer net.close(skt)

		if redirect_count > 0 {
			/*
				Free the location string from the previous request, which is a no-op for the initial request.
				In later requests in case of a redirect, this will be the cloned location which we only
				needed for `send_request`. There's no need to carry around a stack of previous addresses.
			*/
			delete(location)			
		}


		resp = recv_response(skt) or_return

		/*
			Not a redirect, we're done.
		*/
		if resp.status_code != .Moved_Permanently && resp.status_code != .Moved_Temporarily {
			return resp, true
		}

		redirect_count += 1
		if redirect_count > max_redirects {
			response = resp
			response.status_code = .Too_Many_Redirects
			return
		}

		/*
			We're about to free the old response but need the newly given Location. Clone it.
		*/
		location = resp.headers["Location"] or_return
		location = strings.clone(location)

		r2 := r
		request_init(&r2, .GET, location)
		r2.headers = r.headers
		r2.queries = r.queries
		r = r2

		response_destroy(resp)
	}
	unreachable()
}

request_to_bytes :: proc(r: Request, allocator := context.allocator) -> []byte {
	using strings

	b := make_builder(allocator)
	grow_builder(&b, 8192)
	if b.buf == nil do return nil

	assert(r.method == .GET, "only GET requests are supported at this time")
	write_string(&b, "GET ")

	write_string(&b, r.path)

	if r.queries != nil {
		write_rune_builder(&b, '?')
		for query_name, query_value in r.queries {
			write_string(&b, query_name)
			if query_value != "" {
				write_string(&b, "=")
				write_string(&b, net.percent_encode(query_value, context.temp_allocator))
			}
		}
	}
	write_string(&b, " HTTP/1.1\r\n")

	write_header_or_default(&b, r.headers, "Host",       r.host)
	write_header_or_default(&b, r.headers, "Connection", "close")

	for name in r.headers {
		write_header_or_default(&b, r.headers, name, "")
	}

	if r.body != "" {
		write_string(&b, r.body)
		write_string(&b, "\r\n")
	}

	write_string(&b, "\r\n")
	return b.buf[:]


	write_header_or_default :: proc(b: ^strings.Builder, headers: map[string]string, key, default_value: string) {
		write_string(b, key)
		write_string(b, ": ")
		if v, ok := headers[key]; !ok {
			write_string(b, default_value)
		} else {
			write_string(b, v)
		}
		write_string(b, "\r\n")
	}
}
