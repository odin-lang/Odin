# Bifrost

Bifrost is an event-driven HTTP/1.1 + HTTP/2 client/server stack for Odin, built on `core:nbio`.
TLS is provided by a vendored BoringSSL build and wrapped in `vendor:bifrost/tls`.
HTTP/2 client streaming uploads are supported via `Request.Body_Stream`.

## Layout

- `vendor/bifrost/http` — HTTP/1.1 + HTTP/2 implementation
- `vendor/bifrost/tls` — BoringSSL wrapper + generated bindings
- `vendor/boringssl` — vendored headers + static libs (Linux)

## Nbio-First Handler API (example shape)

```odin
package main

import "core:nbio"
import http "vendor:bifrost/http"

main :: proc() {
	nbio.acquire_thread_event_loop()
	defer nbio.release_thread_event_loop()

	srv := http.Server{
		Loop: nbio.thread_event_loop(),
		Handler: proc(req: ^http.Request, res: ^http.ResponseWriter) {
			res.Status = 200
			// res.Header.Set("content-type", "text/plain")
			// res.WriteString("hello")
			// res.End()
		},
	}

	// TODO(bifrost): http.Listen(srv, {nbio.IP4_Any, 8080})
nbio.run()
}
```

## Streaming Request Bodies

When `Server.Body_Handler` is set, you can opt into a pull-style body reader:

```odin
srv := http.Server{
	Loop = nbio.thread_event_loop(),
	Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
		// Call early (before Body_Handler consumes data).
		_ = http.request_body_stream_enable(req)
	},
	Body_Handler = proc(req: ^http.Request, res: ^http.ResponseWriter, data: []u8, done: bool) {
		buf: [1024]u8
		for {
			n, body_done, ok := http.request_body_read(req, buf[:])
			if !ok {
				break
			}
			// process buf[:n]
			if body_done {
				res.Status = 200
				http.response_end(res)
				return
			}
		}
	},
}
```

## Request User Context

`Request.User` is reserved for user state (useful in client callbacks).

## Porting Plan (Go Source Pointers)

Stage 1: HTTP/1.1 parsing + wire format
- Requests: `src/net/http/request.go`
- Responses: `src/net/http/response.go`
- Headers + canonicalization: `src/net/http/header.go`
- Transfer encoding, Content-Length, chunked framing: `src/net/http/transfer.go`

Stage 2: HTTP/1.1 server core
- Server state machine and connection handling: `src/net/http/server.go`
- Mux + routing helpers: `src/net/http/pattern.go` / `src/net/http/servemux121.go`

Stage 3: HTTP/1.1 client + transport
- Client: `src/net/http/client.go`
- RoundTrip glue: `src/net/http/roundtrip.go`
- Transport + connection pooling: `src/net/http/transport.go`

Stage 4: HTTP/2 (TLS ALPN and h2c)
- Bundled HTTP/2 implementation: `src/net/http/h2_bundle.go`
- HTTP/2 errors/constants: `src/net/http/h2_error.go`
- Omit deprecated priority and server push behavior (modern client alignment)

## TLS / Bindgen Notes

Bindings are generated with `odin-c-bindgen` using `vendor/bifrost/tls/bindgen.sjson`.
The `imports_file` in that config declares `foreign import` for the BoringSSL libs.

## BoringSSL Vendor Layout (Linux)

This repo keeps only the headers and static libraries needed for linking:

- Headers: `vendor/boringssl/include/openssl/`
- Libs: `vendor/boringssl/lib/libssl.a`, `vendor/boringssl/lib/libcrypto.a`

Expected workflow (from a BoringSSL clone located at `../boringssl`):

```sh
./vendor/boringssl/build_boringssl.sh
/tmp/odin-c-bindgen/bindgen vendor/bifrost/tls
```

The script uses `BORINGSSL_SRC` to locate the source (default `../boringssl`) and
copies headers/libs into `vendor/boringssl`.

Manual steps (if you prefer):

```sh
cmake -S ../boringssl -B ../boringssl/build -DCMAKE_BUILD_TYPE=Release
cmake --build ../boringssl/build --target ssl crypto

mkdir -p vendor/boringssl/include/openssl vendor/boringssl/lib
rsync -a ../boringssl/include/openssl/ vendor/boringssl/include/openssl/
cp -a ../boringssl/build/libssl.a ../boringssl/build/libcrypto.a vendor/boringssl/lib/
```

Linking:
The bindings use explicit library paths from `vendor/bifrost/tls/imports.odin`,
so no extra `-L` flags are needed when the vendored libs are present.
