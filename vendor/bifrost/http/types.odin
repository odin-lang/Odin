package bifrost_http

import "core:nbio"
import "core:time"
import tls "vendor:bifrost/tls"

Header :: map[string][]string

Chunk_State :: enum {
	Size,
	Data,
	Trailer,
}

Client_Body_Source :: proc(user: rawptr) -> (data: []u8, done: bool, ok: bool)

Request :: struct {
	Method: string,
	Target: string,
	Proto:  string,

	Header: Header,
	Body: []u8,
	Body_Stream: Client_Body_Source,
	Body_Stream_User: rawptr,
	// User-defined context pointer (for callbacks or higher-level glue).
	User: rawptr,

	// Internal request body reader state (see request_body_stream_enable/request_body_read).
	_body: rawptr,
}

ResponseWriter :: struct {
	Status: int,
	Header: Header,

	_write: Response_Write_Proc,
	_end: Response_End_Proc,
	_stream_start: Response_Stream_Start_Proc,
	_stream_write: Response_Stream_Write_Proc,
	_stream_end: Response_Stream_End_Proc,
	_stream_flush: Response_Stream_Flush_Proc,
	_internal: rawptr,
	_kind: Response_Internal_Kind,
}

Response_Internal_Kind :: enum {
	HTTP1,
	HTTP2,
}

Response_Write_Proc :: proc(res: ^ResponseWriter, data: []u8) -> bool
Response_End_Proc :: proc(res: ^ResponseWriter)
Response_Stream_Start_Proc :: proc(res: ^ResponseWriter) -> bool
Response_Stream_Write_Proc :: proc(res: ^ResponseWriter, data: []u8) -> bool
Response_Stream_End_Proc :: proc(res: ^ResponseWriter)
Response_Stream_Flush_Proc :: proc(res: ^ResponseWriter) -> bool

Handler :: proc(req: ^Request, res: ^ResponseWriter)
Body_Handler :: proc(req: ^Request, res: ^ResponseWriter, data: []u8, done: bool)

Response :: struct {
	Status: int,
	Status_Text: string,
	Proto: string,
	Header: Header,
	Body: []u8,
}

Client_Error_Kind :: enum {
	None,
	Dial,
	TLS,
	Send,
	Recv,
	Parse,
	Closed,
}

Client_Error :: struct {
	Kind: Client_Error_Kind,
	Message: string,
}

Client_Response_Handler :: proc(req: ^Request, res: ^Response, err: Client_Error)

Transport :: struct {
	Loop: ^nbio.Event_Loop,
	TLS: ^tls.Config,
	Max_Idle: int,
	Max_Per_Host: int,

	_pool: map[string][]^Client_Conn,
	_tls_ctx: ^tls.Context,
}

Server_State :: struct {
	server: ^Server,
}

Server :: struct {
	Loop: ^nbio.Event_Loop,
	Handler: Handler,
	Body_Handler: Body_Handler,
	TLS: ^tls.Config,

	Max_Header_Bytes: int,
	Max_Body_Bytes:   i64,

	_tls_ctx: ^tls.Context,
	_state: Server_State,
}

Client :: struct {
	Loop: ^nbio.Event_Loop,
	TLS:  ^tls.Config,
	Transport: ^Transport,
	Timeout: time.Duration,
}
