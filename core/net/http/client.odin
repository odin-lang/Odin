package http

import "core:net"
import "core:strings"
import "core:strconv"
import "core:fmt"


get :: proc(url: string, allocator := context.allocator) -> (resp: Response, ok: bool) {
	r: Request;
	request_init(&r, .Get, url, allocator);
	r.headers["Connection"] = "close";
	resp, ok = execute_request(r, allocator);
	return;
}

execute_request :: proc(r: Request, allocator := context.allocator) -> (resp: Response, ok: bool) {
	using strings;

	addr4, addr6, resolve_ok := net.resolve(r.host);
	if !resolve_ok do return;
	addr := addr4 != nil ? addr4 : addr6;

	//
	// TODO(tetra): Factor the request serializing out.
	//

	b := make_builder(allocator);
	grow_builder(&b, 8192);
	defer destroy_builder(&b);

	assert(r.method == .Get);
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
	req_str := to_string(b);

	fmt.printf("%q\n", req_str);

	// TODO(tetra): SSL/TLS.
	skt, err := net.dial(addr, 80);
	if err != .Ok do return; // TODO(tetra): return instead?

	write_err := net.write(skt, transmute([]byte) req_str);
	if write_err != .Ok do return; // TODO(tetra): return instead?

	read_buf: [4096]byte;
	n, read_err := net.read(skt, read_buf[:]);
	assert(n > 0);
	if read_err != .Ok do return; // TODO(tetra): return instead?


	//
	// TODO(tetra): Factor the response parsing out.
	//

	resp_parts := split(string(read_buf[:n]), "\n");
	assert(len(resp_parts) >= 1);

	status_parts := split(resp_parts[0], " ");
	assert(len(status_parts) >= 3); // NOTE(tetra): 3 for OK, more if status text is more than one word.

	status_code, _ := strconv.parse_int(status_parts[1]);
	resp.status = Status(status_code);

	resp_parts = resp_parts[1:];

	resp.headers = make(map[string]string, len(resp_parts), allocator);
	// NOTE(tetra): conform to the common idiom that ok=false means that the
	// that the caller does not have to clean up `resp` ... because we already did.
	defer if !ok do response_destroy(&resp);

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
		name  := clone(trim_space(trimmed_part[:idx]), allocator);
		value := clone(trim_space(trimmed_part[idx+1:]), allocator);
		resp.headers[name] = value;

	}
	if last_hdr_index == -1 {
		// NOTE(tetra): Should have found the last header.
		// TODO(tetra): Handle not receiving the response in one read call.
		resp.status = .Bad_Response_Header;
		return;
	}

	// TODO(tetra): Use the content-length to slice the body.
	body := resp_parts[last_hdr_index+1];
	body = trim_space(body);
	resp.body = clone(body, allocator);

	ok = true;
	return;
}


/*
Client_Request_State :: enum u8 {
	Pending,
	Connecting,
	Failed,
	// TODO
}

Client_Request_Token :: distinct u32;

Client_Connecting_Request 	:: struct { req: Request, skt: net.Socket };
Client_Failed_Request 		:: struct { req: Request, error: net.Dial_Error };
Client_Reading_Response     :: struct { req: Request, skt: net.Socket, resp: Response };

Client_Request :: union {
	Client_Connecting_Request,
	Client_Failed_Request,
	Client_Reading_Response,
}

Client :: struct {
	request_allocator: 	mem.Allocator, // TODO(tetra): use a pool here instead?
	requests:			[dynamic]^Client_Request,
	lock:               sync.Ticket_Mutex;
}

client_init :: proc(using c: ^Client, allocator := context.allocator) {
	request_allocator = allocator;
	pending.allocator = allocator;
	in_flight.allocator = allocator;
	conns.allocator = allocator;
	status.allocator = allocator;

	next_token = 0;
	sync.ticket_mutex_init(&lock);
}

client_begin_request :: proc(using c: ^Client, req: Request) -> (token: Client_Request_Token, ok: bool) {
	slot := new(Client_Request, request_allocator);
	if slot == nil do return;
	slot^ = req;
	defer if !ok do delete(slot);

	addr4, addr6, addr_ok := net.resolve(req.host);
	if !addr_ok do return;
	addr := addr4 != nil ? addr4 : addr6;

	sync.ticket_mutex_lock(&lock);
	defer sync.ticket_mutex_unlock(&lock);

	append(&requests, slot);
	tk := Client_Request_Token(len(requests));  // tokens are 1-based because 0 is the nil value.
	assert(tk > 0);

	skt, err := net.start_dial(addr, 80);
	if err != .Ok do return;

	slot^ = Client_Connecting_Request {
		req = req,
		skt = skt,
	};

	token = tk;
	ok = true;
	return;
}

client_poll_events :: proc(using c: ^Client) -> (updated: int) {
	sync.ticket_mutex_lock(&lock);
	defer sync.ticket_mutex_unlock(&lock);

	for req, i in requests {
		switch r in req {
		case Client_Connecting_Request:
			done, err := net.try_finish_dial(c);
			if err != .Ok {
				net.close(c);
				requests[i] = Client_Failed_Request {
					req = r.req,
					error = err,
				};
				updated += 1;
				fmt.println("failed");
				continue;
			}

			if done {
				write_request_to_socket(&r.req);
				requests[i] = Client_Reading_Response {
					req = r.req,
					skt = r.skt,
				};
				requests[i].resp.headers.allocator = request_allocator;
				fmt.println("connected");
				updated += 1;
			}

		case Client_Reading_Response:
			buf: [4096]byte = ---;
			n, err := net.try_read(r.skt, buf[:]);
			if n == 0 do continue;



			updated += 1;
		}
	}
}

client_get_response :: proc(using c: ^Client, token: Client_Request_Token) -> (done: bool, resp: Response) {
	i := int(token);
	if i < 0 || i >= len(requests) do return;

	switch r in requests[i] {
	case Client_Completed_Request:
		done = true;
		resp = r.resp;
	}
	return;
}


// TODO(tetra): maybe take request by ptr, and modify when response is ready?
client_execute_request :: proc(c: ^Client, req: Request) -> (resp: Response, ok: bool) {
	tok, ok := client_begin_request(c, req);
	for {
		if client_poll_events(c) == 0 {
			sync.yield_processor();
			continue;
		}

		done: bool;
		done, resp, err = client_get_response(c, tok);
		if done do break;

		sync.yield_processor();
	}

	ok = true;
	return;
}
*/