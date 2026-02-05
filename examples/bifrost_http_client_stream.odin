package main

import "core:fmt"
import "core:nbio"
import http "vendor:bifrost/http"

Body_Stream_State :: struct {
	chunks: [2][]u8,
	index: int,
}

body_stream :: proc(user: rawptr) -> (data: []u8, done: bool, ok: bool) {
	state := (^Body_Stream_State)(user)
	if state == nil {
		return nil, true, false
	}
	if state.index >= len(state.chunks) {
		return nil, true, true
	}
	data = state.chunks[state.index]
	state.index += 1
	done = state.index >= len(state.chunks)
	return data, done, true
}

main :: proc() {
	err := nbio.acquire_thread_event_loop()
	if err != nil {
		fmt.println("nbio unsupported:", err)
		return
	}
	defer nbio.release_thread_event_loop()

	body_state := Body_Stream_State{
		chunks = {[]u8("he"), []u8("llo")},
	}

	req := http.Request{
		Method = "POST",
		Target = "/upload",
		Header = make(http.Header),
		Body_Stream = body_stream,
		Body_Stream_User = &body_state,
	}

	client := http.Client{Loop = nbio.current_thread_event_loop()}
	http.client_do(&client, {nbio.IP4_Loopback, 8080}, "localhost", &req,
		proc(req: ^http.Request, res: ^http.Response, err: http.Client_Error) {
			if err.Kind != .None {
				fmt.println("request failed:", err.Message)
				return
			}
			fmt.printf("status=%d body=%s\n", res.Status, string(res.Body))
		},
	)

	nbio.run()
}
