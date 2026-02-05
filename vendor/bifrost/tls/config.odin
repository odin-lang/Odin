package bifrost_tls

ALPN_Protocol :: enum {
	HTTP1_1,
	HTTP2,
}

Config :: struct {
	// TODO(bifrost): flesh out with certs, keys, CA roots, verification options.
	alpn: []ALPN_Protocol,
}
