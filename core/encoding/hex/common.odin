package encoding_hex

import "base:runtime"

Error :: union #shared_nil {
	runtime.Allocator_Error,
	Decode_Error,
}

Decode_Error :: enum {
	None,
	Invalid_Length,
	Invalid_Character,
}
