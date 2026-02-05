package bifrost_tls

ALPN_Protocol :: enum {
	Unknown,
	HTTP1_1,
	HTTP2,
}

Config :: struct {
	alpn: []ALPN_Protocol,

	// Server cert/key (PEM).
	cert_chain_file: string,
	key_file:        string,

	// Client verification settings.
	verify_peer:        bool,
	require_client_cert: bool,
	verify_depth:       int,
	ca_file:            string,
	ca_dir:             string,
}
