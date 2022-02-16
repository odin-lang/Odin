//+build darwin
package objc_Foundation

@(objc_class="NSData")
Data :: struct {using _: Copying(Data)}

@(objc_type=Data, objc_name="alloc", objc_is_class_method=true)
Data_alloc :: proc() -> ^Data {
	return msgSend(^Data, Data, "alloc")
}

@(objc_type=Data, objc_name="init")
Data_init :: proc(self: ^Data) -> ^Data {
	return msgSend(^Data, self, "init")
}

@(objc_type=Data, objc_name="mutableBytes")
Data_mutableBytes :: proc(self: ^Data) -> rawptr {
	return msgSend(rawptr, self, "mutableBytes")
}

@(objc_type=Data, objc_name="length")
Data_length :: proc(self: ^Data) -> UInteger {
	return msgSend(UInteger, self, "length")
}