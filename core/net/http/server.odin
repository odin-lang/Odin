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

import "core:fmt"
import "core:strings"
import "core:net"
import "core:os"

guess_mime :: proc(filename: string) -> (mime: string) {
	if strings.has_suffix(filename, ".html") {
		return "text/html"
	} else if strings.has_suffix(filename, ".css") {
		return "text/css"
	} else if strings.has_suffix(filename, ".js") {
		return "text/javascript"
	}

	return "application/octet-stream"
}

errcode_to_string :: proc(code: Status_Code) -> (err_str: string) {
	#partial switch code {
	case .Ok: return "OK"
	case .Bad_Request: return "Bad Request"
	case .Forbidden: return "Forbidden"
	case .Not_Found: return "Not Found"
	case .Not_Implemented: return "Not Implemented"
	case .Internal_Error: return "Internal Error"
	case: return "Internal Error"
	}

	unreachable()
}

build_response :: proc(code: Status_Code, headers: []string = nil, msg := "", allocator := context.allocator) -> (resp: string) {
	b := strings.make_builder(allocator)
	defer strings.destroy_builder(&b)

	err_msg := errcode_to_string(code)

	strings.write_string(&b, "HTTP/1.1 ")
	strings.write_int(&b, int(code))
	strings.write_string(&b, " ")
	strings.write_string(&b, err_msg)

	for hdr in headers {
		strings.write_string(&b, hdr)
	}

	strings.write_string(&b, "\nContent-Length: ")
	strings.write_int(&b, len(msg))
	strings.write_string(&b, "\r\n\r\n")
	strings.write_string(&b, msg)

	return strings.clone(strings.to_string(b))
}

send_response :: proc(skt: net.TCP_Socket, msg: []u8) -> (ok: bool) {
	_, send_err := net.send_tcp(skt, msg[:])
	if send_err != nil {
		fmt.printf("Failed to send data to socket!\n")
		return
	}
	return true
}

parse_request :: proc(buffer: []u8) -> (req: Request, status_code: Status_Code) {
	read_str := string(buffer[:])

	line, line_ok := strings.split_lines_iterator(&read_str)
	if !line_ok {
		status_code = .Bad_Request
		return
	}

	hdr_elems := strings.fields(line)
	if len(hdr_elems) != 3 {
		status_code = .Bad_Request
		return
	}

	path := hdr_elems[1]

	version := hdr_elems[2]
	if version != "HTTP/1.1" {
		status_code = .Not_Implemented
		return
	}

	method_str := hdr_elems[0]
	method: Method
	switch method_str {
	case "GET":
		method = .GET
	case:
		status_code = .Not_Implemented
		return
	}

	hdr_end := strings.index(read_str, "\r\n\r\n")
	if hdr_end == -1 {
		status_code = .Bad_Request
		return
	}

	headers := make(map[string]string)
	hdrs := read_str[:hdr_end]
	for hdr in strings.split_lines_iterator(&hdrs) {
		hdr_hinge := strings.index(hdr, ":")
		if hdr_hinge == -1 {
			status_code = .Bad_Request
			return
		}

		hdr_name := hdr[:hdr_hinge]
		hdr_data := strings.trim_left_space(hdr[hdr_hinge+1:])
		headers[hdr_name] = hdr_data
	}

	data := read_str[hdr_end:]

	req.method = method
	req.path = path
	req.headers = headers
	req.body = data

	status_code = .Unknown
	return
}

find_file :: proc(path: string, dir: string) -> (filepath: string, ok: bool) {
	//TODO(cloin): This should be sanitized to remove ".." and "*"

	path_buf := make([dynamic]u8, 4096)
	file_path := fmt.bprintf(path_buf[:], "%s%s", dir, path)

	if !os.is_file(file_path) {
		delete(path_buf)
		return "", false
	}

	return file_path, true
}

// serve "project/static/*"
serve_files :: proc(dir_path: string, port: int, allocator := context.allocator) -> () {
	context.allocator = allocator

	skt, err := net.listen_tcp({net.IP6_Any, port})
	if err != nil {
		fmt.printf("Failed to bind to port!\n")
		return
	}

	for ;; {
		client, _, accept_err := net.accept_tcp(skt)
		if accept_err != nil {
			fmt.printf("Failed to listen for client?\n")
			return
		}
		defer net.close(client)

		read_buf := [4096]u8{}
		_, recv_err := net.recv_tcp(client, read_buf[:])
		if recv_err != nil {
			fmt.printf("Failed to get data from client!\n")
			return
		}

		req, status := parse_request(read_buf[:])
		defer request_destroy(req)
		if status != .Unknown {
			resp := build_response(status)
			send_response(client, transmute([]u8)resp)
			delete(resp)
			continue
		}

		out_headers := make([dynamic]string)
		defer delete(out_headers)

		#partial switch req.method {
		case .GET:
			b := strings.make_builder(allocator)
			defer strings.destroy_builder(&b)

			strings.write_string(&b, req.path)
			req_path := strings.to_string(b)

			out_path, found_ok := find_file(req_path, dir_path)
			if !found_ok {
				// is this a directory?
				if req.path[len(req.path)-1] != '/' {
					strings.write_string(&b, "/")
				}
				strings.write_string(&b, "index.html")

				req_path = strings.to_string(b)
				out_path, found_ok = find_file(req_path, dir_path)
				if !found_ok {
					resp := build_response(.Bad_Request, out_headers[:])
					send_response(client, transmute([]u8)resp)
					delete(resp)
					continue
				}
			}
			defer delete(out_path)

			file_blob, file_ok := os.read_entire_file_from_filename(out_path)
			if !file_ok {
				resp := build_response(.Bad_Request, out_headers[:])
				send_response(client, transmute([]u8)resp)
				delete(resp)
				continue
			}

			mime_buf := [1024]u8{}
			mime_hdr := fmt.bprintf(mime_buf[:], "\nContent-Type: %s", guess_mime(out_path))
			append(&out_headers, mime_hdr)

			resp := build_response(.Ok, out_headers[:], string(file_blob))
			send_response(client, transmute([]u8)resp)
			delete(resp)
		case:
			fmt.printf("Request type %s not handled!\n", req.method)
			resp := build_response(.Not_Implemented, out_headers[:])
			send_response(client, transmute([]u8)resp)
			delete(resp)
		}
	}

	unreachable()
}
