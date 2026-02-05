<p align="center">
    <img src="misc/logo-slim.png" alt="Odin logo" style="width:65%">
    <br/>
   The Data-Oriented Language for Sane Software Development.
    <br/>
    <br/>
    <a href="https://github.com/odin-lang/odin/releases/latest">
        <img src="https://img.shields.io/github/release/odin-lang/odin.svg">
    </a>
    <a href="https://github.com/odin-lang/odin/releases/latest">
        <img src="https://img.shields.io/badge/platforms-Windows%20|%20Linux%20|%20macOS-green.svg">
    </a>
    <br>
    <a href="https://discord.com/invite/sVBPHEv">
        <img src="https://img.shields.io/discord/568138951836172421?logo=discord">
    </a>
    <a href="https://github.com/odin-lang/odin/actions">
        <img src="https://github.com/odin-lang/odin/actions/workflows/ci.yml/badge.svg?branch=master&event=push">
    </a>
</p>

# The Odin Programming Language


Odin is a general-purpose programming language with distinct typing, built for high performance, modern systems, and built-in data-oriented data types. The Odin Programming Language, the C alternative for the joy of programming.

Website: [https://odin-lang.org/](https://odin-lang.org/)

```odin
package main

import "core:fmt"

main :: proc() {
	program := "+ + * 😃 - /"
	accumulator := 0

	for token in program {
		switch token {
		case '+': accumulator += 1
		case '-': accumulator -= 1
		case '*': accumulator *= 2
		case '/': accumulator /= 2
		case '😃': accumulator *= accumulator
		case: // Ignore everything else
		}
	}

	fmt.printf("The program \"%s\" calculates the value %d\n",
	           program, accumulator)
}

```

## Documentation

#### [Getting Started](https://odin-lang.org/docs/install)

Instructions for downloading and installing the Odin compiler and libraries.

#### [Nightly Builds](https://odin-lang.org/docs/nightly/)

Get the latest nightly builds of Odin.

### Learning Odin

#### [Overview of Odin](https://odin-lang.org/docs/overview)

An overview of the Odin programming language.

#### [Frequently Asked Questions (FAQ)](https://odin-lang.org/docs/faq)

Answers to common questions about Odin.

#### [Packages](https://pkg.odin-lang.org/)

Documentation for all the official packages part of the [core](https://pkg.odin-lang.org/core/) and [vendor](https://pkg.odin-lang.org/vendor/) library collections.

#### [Examples](https://github.com/odin-lang/examples)

Examples on how to write idiomatic Odin code. Shows how to accomplish specific tasks in Odin, as well as how to use packages from `core` and `vendor`.

#### [Odin Documentation](https://odin-lang.org/docs/)

Documentation for the Odin language itself.

#### [Odin Discord](https://discord.gg/sVBPHEv)

Get live support and talk with other Odin programmers on the Odin Discord.

### Articles

#### [The Odin Blog](https://odin-lang.org/news/)

The official blog of the Odin programming language, featuring announcements, news, and in-depth articles by the Odin team and guests.

## Warnings

* The Odin compiler is still in development.

## Bifrost (HTTP/TLS)

Bifrost is an event-driven HTTP/1.1 + HTTP/2 client/server stack for Odin, built on `core:nbio`.
TLS is provided via a vendored BoringSSL build. Linux only for now.

### Layout

* `vendor/bifrost/http` — HTTP/1.1 + HTTP/2 implementation
* `vendor/bifrost/tls` — BoringSSL wrapper + generated bindings
* `vendor/boringssl` — vendored headers + static libs (Linux)

### Handler Example (nbio-first)

```odin
package main

import "core:nbio"
import http "vendor:bifrost/http"

main :: proc() {
	nbio.acquire_thread_event_loop()
	defer nbio.release_thread_event_loop()

	srv := http.Server{
		Loop = nbio.current_thread_event_loop(),
		Handler = proc(req: ^http.Request, res: ^http.ResponseWriter) {
			res.Status = 200
			http.response_write_string(res, "hello")
			http.response_end(res)
		},
	}

	_, _ = http.listen(&srv, {nbio.IP4_Any, 8080})
nbio.run()
}
```

### Streaming Request Bodies

When using `Server.Body_Handler`, you can opt into a pull-style reader:

```odin
srv := http.Server{
	Loop = nbio.current_thread_event_loop(),
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

### Request User Context

`Request.User` is reserved for user state (useful in client callbacks).

### HTTP/2 Notes

* Prior knowledge (cleartext): set `Request.Proto = "HTTP/2.0"`.
* h2c upgrade (cleartext): set `Request.Proto = "HTTP/2.0"` and `Upgrade: h2c` in the request header; Bifrost will add `HTTP2-Settings` and `Connection: Upgrade, HTTP2-Settings` automatically.
* HTTP/2 client streaming uploads are supported via `Request.Body_Stream`.

### BoringSSL Vendor Build (Linux)

This repo vendors only the headers and static libs needed for linking, not the full BoringSSL source.

Expected layout:

* `vendor/boringssl/include/openssl/`
* `vendor/boringssl/lib/libssl.a`
* `vendor/boringssl/lib/libcrypto.a`

Build from a sibling checkout at `../boringssl`:

```sh
./vendor/boringssl/build_boringssl.sh
```

Manual build (if you prefer):

```sh
cmake -S ../boringssl -B ../boringssl/build -DCMAKE_BUILD_TYPE=Release
cmake --build ../boringssl/build --target ssl crypto

mkdir -p vendor/boringssl/include/openssl vendor/boringssl/lib
rsync -a ../boringssl/include/openssl/ vendor/boringssl/include/openssl/
cp -a ../boringssl/build/libssl.a ../boringssl/build/libcrypto.a vendor/boringssl/lib/
```

Bindings are generated with `odin-c-bindgen` using `vendor/bifrost/tls/bindgen.sjson`.

### Port Plan (Go Source Pointers)

1. Stage 1: HTTP/1.1 parsing + wire format. Go source: `src/net/http/request.go`, `src/net/http/response.go`, `src/net/http/header.go`, `src/net/http/transfer.go`.
2. Stage 2: HTTP/1.1 server core. Go source: `src/net/http/server.go`, `src/net/http/pattern.go`, `src/net/http/servemux121.go`.
3. Stage 3: HTTP/1.1 client + transport. Go source: `src/net/http/client.go`, `src/net/http/roundtrip.go`, `src/net/http/transport.go`.
4. Stage 4: HTTP/2 (TLS ALPN and h2c). Go source: `src/net/http/h2_bundle.go`, `src/net/http/h2_error.go`. Omit deprecated priority and server push behavior (modern client alignment).
