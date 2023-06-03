package objc_Foundation

@(objc_class="NSData")
Data :: struct {using _: Copying(Data)}

@(objc_type=Data, objc_name="alloc", objc_is_class_method=true)
Data_alloc :: proc "c" () -> ^Data {
	return msgSend(^Data, Data, "alloc")
}

@(objc_type=Data, objc_name="init")
Data_init :: proc "c" (self: ^Data) -> ^Data {
	return msgSend(^Data, self, "init")
}

@(objc_type=Data, objc_name="mutableBytes")
Data_mutableBytes :: proc "c" (self: ^Data) -> rawptr {
	return msgSend(rawptr, self, "mutableBytes")
}

@(objc_type=Data, objc_name="length")
Data_length :: proc "c" (self: ^Data) -> UInteger {
	return msgSend(UInteger, self, "length")
}