package objc_Foundation

@(objc_class="NSURL")
URL :: struct{using _: Copying(URL)}


@(objc_type=URL, objc_name="alloc", objc_is_class_method=true)
URL_alloc :: proc() -> ^URL {
	return msgSend(^URL, URL, "alloc")
}

@(objc_type=URL, objc_name="init")
URL_init :: proc(self: ^URL) -> ^URL {
	return msgSend(^URL, self, "init")
}

@(objc_type=URL, objc_name="initWithString")
URL_initWithString :: proc(self: ^URL, value: ^String) -> ^URL {
	return msgSend(^URL, self, "initWithString:", value)
}

@(objc_type=URL, objc_name="initFileURLWithPath")
URL_initFileURLWithPath :: proc(self: ^URL, path: ^String) -> ^URL {
	return msgSend(^URL, self, "initFileURLWithPath:", path)
}

@(objc_type=URL, objc_name="fileSystemRepresentation")
URL_fileSystemRepresentation :: proc(self: ^URL) -> ^String {
	return msgSend(^String, self, "fileSystemRepresentation")
}