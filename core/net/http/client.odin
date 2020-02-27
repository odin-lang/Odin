package http

import "core:net"
import "core:fmt"
import "core:mem"
import "core:sync"


Client_Request :: struct {
	request: Request,

}


Client :: struct {
	pool:      mem.Dynamic_Arena,
	requests:  [dynamic]^Client_Request,
	lock:      sync.Ticket_Mutex,
}

client_init :: proc(using c: ^Client, allocator := context.allocator) {
	mem.dynamic_arena_init(&pool, allocator);
	requests.allocator = mem.dynamic_arena_allocator(&pool);
	sync.ticket_mutex_init(&lock);
}

client_destroy :: proc(using c: Client) {
	mem.dynamic_arena_destroy(&pool);
}

client_submit_request :: proc(using c: ^Client, req: Request) {
	sync.ticket_mutex_lock(&lock);
	defer sync.ticket_mutex_unlock(&lock);

	append(&requests);
}

client_get_response :: proc(using c: ^Client) -> ^Response {
	
}

client_execute_request :: proc(using c: ^Client, req: Request) {
	
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

client_begin_request :: proc(using c: ^Client, req: Request) -> (token: Client_Request_Token, ok: bool) {
	slot := new(Client_Request, allocator);
	if slot == nil do return;
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