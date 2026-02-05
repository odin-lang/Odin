/*
Bifrost HTTP: nbio-driven HTTP/1.1 + HTTP/2 client/server stack.

Design goals:
- Event-driven API aligned with core:nbio.
- Linux-only initially.
- Optional TLS via vendor:bifrost/tls (BoringSSL).
*/
package bifrost_http
