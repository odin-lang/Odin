package objc_Foundation

@(objc_class="NSURL")
URL :: struct{using _: Copying(URL)}

URL_initWithString :: proc(self: ^URL, value: ^String) -> ^URL {
	return msgSend(^URL, self, "initWithString:", value)
}
URL_initFileURLWithPath :: proc(self: ^URL, path: ^String) -> ^URL {
	return msgSend(^URL, self, "initFileURLWithPath:", path)
}

URL_fileSystemRepresentation :: proc(self: ^URL) -> ^String {
	return msgSend(^String, self, "fileSystemRepresentation")
}