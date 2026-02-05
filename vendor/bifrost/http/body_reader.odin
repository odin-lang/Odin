package bifrost_http

import "core:bytes"

Request_Body_Mode :: enum {
	None,
	Full,
	Stream,
}

@(private)
Request_Body_State :: struct {
	mode: Request_Body_Mode,
	full: []u8,
	full_pos: int,
	stream: bytes.Buffer,
	done: bool,
}

@(private)
request_body_state :: proc(req: ^Request, create: bool) -> ^Request_Body_State {
	if req == nil {
		return nil
	}
	state := (^Request_Body_State)(req._body)
	if state == nil && create {
		state = new(Request_Body_State)
		req._body = state
	}
	return state
}

@(private)
request_body_state_free :: proc(req: ^Request) {
	if req == nil {
		return
	}
	state := (^Request_Body_State)(req._body)
	if state == nil {
		return
	}
	if state.mode == .Stream {
		bytes.buffer_destroy(&state.stream)
	}
	free(state)
	req._body = nil
}

// request_body_stream_enable enables buffering for streaming request bodies.
// Call this in the handler when Server.Body_Handler is set (streaming mode).
request_body_stream_enable :: proc(req: ^Request) -> bool {
	if req == nil {
		return false
	}
	state := request_body_state(req, true)
	if state == nil {
		return false
	}
	if state.mode == .Full && len(state.full) > 0 {
		return false
	}
	state.mode = .Stream
	state.full = nil
	state.full_pos = 0
	state.done = false
	if state.stream.buf == nil {
		bytes.buffer_init_allocator(&state.stream, 0, 16 * 1024)
	}
	return true
}

// request_body_read reads from the request body into dst.
// Returns ok=false when no data is available yet for streaming bodies.
request_body_read :: proc(req: ^Request, dst: []u8) -> (n: int, done: bool, ok: bool) {
	if req == nil {
		return 0, false, false
	}
	state := (^Request_Body_State)(req._body)
	if state == nil {
		if req.Body == nil {
			return 0, false, false
		}
		state = request_body_state(req, true)
		if state == nil {
			return 0, false, false
		}
		state.mode = .Full
		state.full = req.Body
		state.full_pos = 0
	}

	switch state.mode {
	case .Full:
		remaining := len(state.full) - state.full_pos
		if remaining <= 0 {
			return 0, true, true
		}
		if len(dst) == 0 {
			return 0, false, true
		}
		n = len(dst)
		if n > remaining {
			n = remaining
		}
		copy(dst[:n], state.full[state.full_pos:state.full_pos+n])
		state.full_pos += n
		return n, state.full_pos >= len(state.full), true
	case .Stream:
		if bytes.buffer_length(&state.stream) == 0 {
			if state.done {
				return 0, true, true
			}
			return 0, false, false
		}
		if len(dst) == 0 {
			return 0, false, true
		}
		n, _ = bytes.buffer_read(&state.stream, dst)
		return n, state.done && bytes.buffer_length(&state.stream) == 0, true
	}

	return 0, false, false
}

@(private)
request_body_stream_push :: proc(req: ^Request, data: []u8, done: bool) {
	if req == nil {
		return
	}
	state := (^Request_Body_State)(req._body)
	if state == nil || state.mode != .Stream {
		return
	}
	if len(data) > 0 {
		_, _ = bytes.buffer_write(&state.stream, data)
	}
	if done {
		state.done = true
	}
}
