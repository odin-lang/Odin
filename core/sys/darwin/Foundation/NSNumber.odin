package objc_Foundation

@(objc_class="NSValue")
Value :: struct{using _: Copying(Value)}


@(objc_class="NSNumber")
Number :: struct{using _: Copying(Number), using _: Value}


Value_valueWithBytes :: proc(value: rawptr, type: cstring) -> ^Value {
	return msgSend(^Value, Value, "valueWithBytes:objCType:", value, type)
}

Value_valueWithPointer :: proc(pointer: rawptr) -> ^Value {
	return msgSend(^Value, Value, "valueWithPointer:", pointer)
}

Value_initWithBytes :: proc(value: rawptr, type: cstring) -> ^Value {
	return msgSend(^Value, Value, "initWithBytes:objCType:", value, type)
}

Value_initWithCoder :: proc(coder: ^Coder) -> ^Value {
	return msgSend(^Value, Value, "initWithCoder:", coder)
}

Value_getValue :: proc(self: ^Value, value: rawptr, size: UInteger) {
	msgSend(nil, self, "getValue:size:", value, size)
}


Value_objCType :: proc(self: ^Value) -> cstring {
	return msgSend(cstring, self, "objCType")
}

Value_isEqualToValue :: proc(self, other: ^Value) -> BOOL {
	return msgSend(BOOL, self, "isEqualToValue:", other)
}

Value_pointerValue :: proc(self: ^Value) -> rawptr {
	return msgSend(rawptr, self, "pointerValue")
}


// TODO(bill): Number methods