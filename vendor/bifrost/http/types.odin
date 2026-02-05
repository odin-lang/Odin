package bifrost_http

import "core:nbio"
import tls "vendor:bifrost/tls"

Header :: map[string][]string

Request :: struct {
	Method: string,
	Target: string,
	Proto:  string,

	Header: Header,
	Body_Len: i64,
	Body: []u8,

	// TODO(bifrost): streaming body reader/state
	_body: rawptr,
}

ResponseWriter :: struct {
	Status: int,
	Header: Header,

	// TODO(bifrost): write/end callbacks wired by transport.
	_internal: rawptr,
}

Handler :: proc(req: ^Request, res: ^ResponseWriter)

Server :: struct {
	Loop: ^nbio.Event_Loop,
	Handler: Handler,
	TLS: ^tls.Config,

	Max_Header_Bytes: int,
	Max_Body_Bytes:   i64,

	_tls_ctx: ^tls.Context,
}

Client :: struct {
	Loop: ^nbio.Event_Loop,
	TLS:  ^tls.Config,
}
