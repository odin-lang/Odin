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
import sync "core:sync/sync2"
import "core:thread"

Request_Status :: enum {
	Unknown, // NOTE: ID does not exist
	Need_Send,
	Send_Failed,
	Wait_Reply,
	Recv_Failed,
	Done,
}

Request_ID :: distinct int

Client_Request :: struct {
	request:         Request,        // Memory managed by user
	response:        Response,       // Memory managed by user after request is completed
	socket:          net.TCP_Socket, // only valid if status == .Wait_Reply
	status:          Request_Status,
	being_processed: bool,           // Updated in client_process_one_request()
}

/*
	Provides a mechanism to easily run multiple HTTP requests at once.

	This can be done using worker threads, or by manually calling client_process_one_request() or client_wait_for_response().

	client_submit_request() can be used to add a pending request to the queue, which gives you a Request_ID that can be used to determine
	when that request is done, or has failed.

	There are two ways to retreive the result of a request:
	- client_check_for_response() to poll the status of a request, and to retrieve the final result, without blocking.
	- client_wait_for_response() to block until a request is done, temporarily donating the current thread to processing pending requests.

	Forward progress is accomplished via calls to client_process_one_request(), which makes progress with a single
	request in a blocking manner.
	Worker threads, if created, will do this automatically, but if you ask for there to be no worker threads,
	you will either have to call client_process_one_request() manually, as appropriate, or call client_wait_for_response(), which will
	call through to it if the current request is not yet completed.

	With the exception of client_init() and client_destroy(), all procedures are thread-safe.
*/
Client :: struct {
	next_id:         Request_ID,                    // NOTE(tetra): Updated under request_lock
	requests:        map[Request_ID]Client_Request, // NOTE(tetra): Updated under request_lock
	request_lock:    sync.Mutex,
	work_available:  sync.Sema,
	workers:         []^thread.Thread,
	workers_running: bool,                          // NOTE(tetra): Updated atomically
}

client_init :: proc(c: ^Client, worker_count: int, allocator := context.allocator) {
	context.allocator = allocator

	c^ = {}
	c.requests.allocator = allocator

	if worker_count > 0 {
		c.workers = make([]^thread.Thread, worker_count)
		c.workers_running = true

		for _, i in c.workers {
			c.workers[i] = thread.create_and_start_with_data(c, proc(data: rawptr) {
				c := cast(^Client) data
				for sync.atomic_load(&c.workers_running) {
					client_process_one_request(c)
				}
			})
		}
	}
}

client_destroy :: proc(c: ^Client) {
	sync.atomic_store(&c.workers_running, false)
	sync.sema_post(&c.work_available, len(c.workers))
	for w in c.workers {
		thread.destroy(w)
	}
	delete(c.workers, c.requests.allocator)

	for _, cr in c.requests {
		if cr.status == .Wait_Reply {
			net.close(cr.socket)
		}
	}
	delete(c.requests)

	c^ = {}
}


/*
	Adds a pending HTTP request to the queue.

	It is up to the caller to ensure that the Request remains valid for the duration of the request.

	A request is considered completed when client_check_for_response() or client_wait_for_response() returns a status of Done
	for a particular ID.
*/
client_submit_request :: proc(c: ^Client, req: Request) -> Request_ID {
	cr := Client_Request{
		request = req,
		response = {},
		status = .Need_Send,
	}

	defer sync.sema_post(&c.work_available)

	{
		sync.mutex_lock(&c.request_lock)
		defer sync.mutex_unlock(&c.request_lock)
		id := c.next_id
		c.next_id += 1
		c.requests[id] = cr
		return Request_ID(id)
	}
}

/*
	Checks what the status of the request corresponding to the given ID is.

	The request is removed from the queue if it is completed, otherwise it is
	left in the queue.

	When this procedure returns a status of Done, the returned Response is now managed by the caller
	and needs to be destroyed as appropriate.
*/
client_check_for_response :: proc(c: ^Client, id: Request_ID) -> (response: Response, status: Request_Status) {
	cr: Client_Request
	ok: bool
	{
		sync.mutex_lock(&c.request_lock)
		defer sync.mutex_unlock(&c.request_lock)
		cr, ok = c.requests[id]
		if ok && cr.status == .Done {
			delete_key(&c.requests, id)
		}
	}

	if !ok {
		status = .Unknown
		return
	}
	return cr.response, cr.status
}

/*
	Waits for the request with the corresponding ID to be completed, or to fail.

	When this procedure returns a status of Done, the returned Response is now managed by the caller
	and needs to be destroyed as appropriate.

	If the request is not finished, and hasn't failed, the current thread will be utilised to process pending requests with
	calls to client_process_one_request().
*/
client_wait_for_response :: proc(c: ^Client, id: Request_ID) -> (response: Response, status: Request_Status) {
	loop: for {
		response, status = client_check_for_response(c, id)
		switch status {
		case .Unknown:
			return // NOTE: ID did not exist!
		case .Done, .Send_Failed, .Recv_Failed:
			break loop
		case .Need_Send, .Wait_Reply:
			// NOTE: gotta wait - might as well use the current thread to advance the requests
			// TODO: block until there's stuff to process rather than spinning
			client_process_one_request(c)
		}
	}
	return
}

/*
	Adds a request to the queue and blocks until it has completed.

	This procedure just calls client_submit_request() and client_wait_for_response() internally.
*/
client_execute_request :: proc(c: ^Client, req: Request) -> (response: Response, status: Request_Status) {
	id := client_submit_request(c, req)
	response, status = client_wait_for_response(c, id)
	return
}

/*
	Waits for pending work to be available, and then makes progress to exactly one pending request.

	This procedure is called by any worker threads you've asked for, calls to client_wait_for_response() when the desired
	request isn't finished yet, or manually at your leisure.

	If this procedure is not called anywhere, no requests will make progress.
*/
client_process_one_request :: proc(c: ^Client) {
	//
	// Fetch a request that isn't being processed yet
	//

	sync.sema_wait(&c.work_available)

	id_to_process: Request_ID = ---
	req_copy: Client_Request = ---
	block: {
		sync.mutex_lock(&c.request_lock)
		defer sync.mutex_unlock(&c.request_lock)

		for id, req in &c.requests {
			switch req.status {
			case .Done, .Send_Failed, .Recv_Failed:
				continue
			case .Need_Send, .Wait_Reply:
				req.being_processed = true
				id_to_process = id
				req_copy = req
				break block
			case .Unknown:
				unreachable()
			case:
				unreachable()
			}
		}

		return // NOTE(tetra): Nothing to do, or all requests are being processed already.
	}
	req_copy.being_processed = false

	//
	// Process the one we grabbed
	//

	close_socket :: proc(s: ^net.TCP_Socket) {
		net.close(s^)
		s^ = {}
	}

	switch req_copy.status {
	case .Need_Send:
		skt, ok := send_request(req_copy.request)
		if ok {
			req_copy.socket = skt
			req_copy.status = .Wait_Reply
			sync.sema_post(&c.work_available)
		} else {
			req_copy.status = .Send_Failed
			close_socket(&req_copy.socket)
		}
	case .Wait_Reply:
		resp, ok := recv_response(req_copy.socket)
		if ok {
			req_copy.response = resp
			req_copy.status = .Done
		} else {
			req_copy.status = .Recv_Failed
		}
		close_socket(&req_copy.socket)
	case .Done, .Send_Failed, .Recv_Failed:
		// do nothing.
		// it'll be removed from the list when user code
		// asks for it.
	case .Unknown:
		unreachable()
	}

	//
	// Store the updated request back into the map
	//

	sync.mutex_lock(&c.request_lock)
	defer sync.mutex_unlock(&c.request_lock)
	c.requests[id_to_process] = req_copy
}
