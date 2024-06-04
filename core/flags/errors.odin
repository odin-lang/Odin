package flags

import "base:runtime"

Parse_Error_Type :: enum {
	None,
	Extra_Pos,
	Bad_Type,
	Missing_Field,
	Missing_Value,
}

Parse_Error :: struct {
	type: Parse_Error_Type,
	message: string,
}

Validation_Error :: struct {
	message: string,
}

Help_Request :: distinct bool

Error :: union {
	runtime.Allocator_Error,
	Parse_Error,
	Validation_Error,
	Help_Request,
}
