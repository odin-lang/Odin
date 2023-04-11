package http

Verb :: enum {
	GET,
	POST,
	PUT,
	DELETE,
	PATCH,
	HEAD,
	OPTIONS,
	CONNECT,
	TRACE,
}

// TODO: i dont think i like this setup for Version, review again once working Request/Response:
Version :: enum {
	Http_0_9,
	Http_1_0,
	Http_1_1,
	Http_2_0,
	Http_3_0,
}
VersionString :: [Version]string {
	.Http_0_9 = "HTTP/0.9",
	.Http_1_0 = "HTTP/1.0",
	.Http_1_1 = "HTTP/1.1",
	.Http_2_0 = "HTTP/2.0",
	.Http_3_0 = "HTTP/3.0",
}