/*
Bifrost HTTP: nbio-driven HTTP/1.1 + HTTP/2 client/server stack.

Design goals:
- Event-driven API aligned with core:nbio.
- Linux-only initially.
- Optional TLS via vendor:bifrost/tls (BoringSSL).
- Optional streaming request bodies via Server.Body_Handler.
- Optional streaming request body reader via request_body_stream_enable/request_body_read (enable early in the handler).
- Client transport scaffolding with connection pooling.
- Client chunked upload via Request.Body_Stream.
- HTTP/2 client streaming upload via Request.Body_Stream.
- Streaming responses (chunked) for SSE-style handlers via response_sse_start/response_sse_write/response_sse_flush.
- Hash-based static file serving helpers (hashfs_serve, hashfs_hash_name).
- HTTP/2 prior knowledge via Request.Proto = "HTTP/2.0".
- HTTP/2 h2c upgrade when Request.Proto = "HTTP/2.0" and "Upgrade: h2c" is present; the client adds "Connection: Upgrade, HTTP2-Settings" and "HTTP2-Settings".
- Request.User is reserved for user state (useful in client callbacks).
*/
package bifrost_http
