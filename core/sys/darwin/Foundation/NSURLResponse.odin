package objc_Foundation

@(objc_class = "NSURLResponse")
URLResponse :: struct { using _: Object }

@(objc_type = URLResponse, objc_name = "alloc", objc_is_class_method = true)
URLResponse_alloc :: proc "c" () -> ^URLResponse {
	return msgSend(^URLResponse, URLResponse, "alloc")
}

@(objc_type = URLResponse, objc_name = "init")
URLResponse_init :: proc "c" (self: ^URLResponse) -> ^URLResponse {
	return msgSend(^URLResponse, URLResponse, "init")
}

@(objc_type = URLResponse, objc_name = "initWithURL")
URLResponse_initWithURL :: proc "c" (self: ^URLResponse, url: ^URL, mime_type: ^String, length: int, encoding: ^String ) -> ^URLResponse {
	return msgSend(^URLResponse, self, "initWithURL:MIMEType:expectedContentLength:textEncodingName:", url, mime_type, Integer(length), encoding)
}