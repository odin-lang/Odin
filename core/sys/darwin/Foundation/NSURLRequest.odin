package objc_Foundation

@(objc_class = "URLRequest")
URLRequest :: struct { using _: Object }

@(objc_type = URLRequest, objc_name = "alloc", objc_is_class_method = true)
URLRequest_alloc :: proc "c" () -> ^URLRequest {
	return msgSend(^URLRequest, URLRequest, "alloc")
}

@(objc_type = URLRequest, objc_name = "requestWithURL", objc_is_class_method = true)
URLRequest_requestWithURL :: proc "c" (url: ^URL) -> ^URLRequest {
	return msgSend(^URLRequest, URLRequest, "requestWithURL:", url)
}

@(objc_type = URLRequest, objc_name = "init")
URLRequest_init :: proc "c" (self: ^URLRequest) -> ^URLRequest {
	return msgSend(^URLRequest, URLRequest, "init")
}

@(objc_type = URLRequest, objc_name = "url")
URLRequest_url :: proc "c" (self: ^URLRequest) -> ^URL {
	return msgSend(^URL, self, "URL")
}