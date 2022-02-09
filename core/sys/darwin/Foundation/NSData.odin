package objc_Foundation

@(objc_class="NSData")
Data :: struct {using _: Copying(Data)}

Data_mutableBytes :: proc(self: ^Data) -> rawptr {
	return msgSend(rawptr, self, "mutableBytes")
}

Data_length :: proc(self: ^Data) -> UInteger {
	return msgSend(UInteger, self, "length")
}