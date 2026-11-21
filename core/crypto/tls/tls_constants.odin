package tls

// Maximum length of a SNI host name based on DNS limits.
SNI_MAX_HOSTNAME_SIZE :: 253

// ALPN protocols (subset)
//
// See: https://www.iana.org/assignments/tls-extensiontype-values
Alpn_Protocols :: enum {
	None,                // Invalid
	Http_0_9,            // "http/0.9"
	Http_1_0,            // "http/1.0"
	Http_1_1,            // "http/1.1"
	Spdy_1,              // "spdy/1"
	Spdy_2,              // "spdy/2"
	Spdy_3,              // "spdy/3"
	Turn,                // "stun.turn"
	Stun,                // "stun.nat-discovery"
	Http_2,              // "h2"
	// Http_2_Tcp,       // "h2c" (Not valid for TLS ALPN)
	Webrtc,              // "webrtc"
	Confidential_Webrtc, // "c-webrtc"
	Ftp,                 // "ftp"
	Imap,                // "imap"
	Pop3,                // "pop3"
	Managesieve,         // "managesieve"
	Coap_Tls,            // "coap"
	Coap_Dtls,           // "co"
	Xmpp_Client,         // "xmpp-client"
	Xmpp_Server,         // "xmpp-server"
	Acme_Tls_1,          // "acme-tls/1"
	Mqtt,                // "mqtt"
	Dot,                 // "dot" (DNS-over-TLS)
	Ntske_1,             // "ntske/1"
	Sunrpc,              // "sunrpc"
	Http_3,              // "h3"
	Smb2,                // "smb"
	Irc,                 // "irc"
	Nntp_Reading,        // "nntp"
	Nntp_Transit,        // "nnsp"
	Doq,                 // "doq"
	Sip,                 // "sip/2"
	Tds_8_0,             // "tds/8.0"
	Dicom,               // "dicom"
	Postgresql,          // "postgresql"
	Radius_1_0,          // "radius/1.0"
	Radius_1_1,          // "radius/1.1"
	Npmp_Control,        // "netperfmeter/control"
	Npmp_Data,           // "netperfmeter/data"
	N_Pamp,              // "n-pamp/2"
	Eoq,                 // "EoQ"
	Snif_Over_Quic,      // "snifq/1"
}
