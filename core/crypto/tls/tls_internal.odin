#+private
package tls

import "base:intrinsics"
import "core:bytes"
import "core:crypto/aead"
import "core:crypto/hash"
import "core:crypto/x509"
import "core:encoding/endian"

TLS10_PROTOCOL_VERSION : u16 : 0x0301
TLS12_PROTOCOL_VERSION : u16 : 0x0303
TLS13_PROTOCOL_VERSION : u16 : 0x0304

TLS_RECORD_HEADER_SIZE :: 1 + 2 + 2

TLS13_MAX_RECORD_SIZE   :: 1 << 14
TLS13_AEAD_OVERHEAD     :: 1 + AEAD_TAG_SIZE
TLS13_MAX_AEAD_OVERHEAD :: 255
TLS13_MAX_PAYLOAD_SIZE  :: TLS13_MAX_RECORD_SIZE - TLS_RECORD_HEADER_SIZE

RANDOM_SIZE            :: 32
LEGACY_SESSION_ID_SIZE :: 32

@(rodata)
HELLO_RETRY_REQUEST_RANDOM := []byte{
	0xcf, 0x21, 0xad, 0x74, 0xe5, 0x9a, 0x61, 0x11,
	0xbe, 0x1d, 0x8c, 0x02, 0x1e, 0x65, 0xb8, 0x91,
	0xc2, 0xa2, 0x11, 0x16, 0x7a, 0xbb, 0x8c, 0x5e,
	0x07, 0x9e, 0x09, 0xe2, 0xc8, 0xa8, 0x33, 0x9c,
}

@(rodata)
CERTIFICATE_VERIFY_PREFIX := [64]byte{
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
}

@(rodata)
SERVER_CERTIFICATE_VERIFY_PREFIX := [34]byte{
	// "TLS 1.3, server CertificateVerify\0"
	0x54, 0x4c, 0x53, 0x20, 0x31, 0x2e, 0x33, 0x2c,
	0x20, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x20,
	0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63,
	0x61, 0x74, 0x65, 0x56, 0x65, 0x72, 0x69, 0x66,
	0x79, 0x00,
}

Content_Type :: enum u8 {
	Invalid            = 0,
	Alert              = 21,
	Change_Cipher_Spec = 20,
	Handshake          = 22,
	Application_Data   = 23,
}

Alert_Level :: enum u8 {
	Warning = 1,
	Fatal   = 2,
}

Alert_Description :: enum u8 {
	Close_Notify                        = 0,   // Warning
	Unexpected_Message                  = 10,  // Fatal
	Bad_Record_Mac                      = 20,  // Fatal
	Decryption_Failed_RESERVED          = 21,
	Record_Overflow                     = 22,  // Fatal
	Decompression_Failure_RESERVED      = 30,
	Handshake_Failure                   = 40,  // Fatal
	No_Certificate_RESERVED             = 41,
	Bad_Certificate                     = 42,  // Fatal
	Unsupported_Certificate             = 43,  // Fatal
	Certificate_Revoked                 = 44,  // Fatal
	Certificate_Expired                 = 45,  // Fatal
	Certificate_Unknown                 = 46,  // Fatal
	Illegal_Parameter                   = 47,  // Fatal
	Unknown_Ca                          = 48,  // Fatal
	Access_Denied                       = 49,  // Fatal
	Decode_Error                        = 50,  // Fatal
	Decrypt_Error                       = 51,  // Fatal
	Export_Restriction_RESERVED         = 60,
	Protocol_Version                    = 70,  // Fatal
	Insufficient_Security               = 71,  // Fatal
	Internal_Error                      = 80,  // Fatal
	Inappropriate_Fallback              = 86,  // Fatal
	User_Canceled                       = 90,  // Warning
	Missing_Extension                   = 109, // Fatal
	No_Renegotiation_RESERVED           = 100,
	Unsupported_Extension               = 110, // Fatal
	Certificate_Unobtainable_RESERVED   = 111,
	Unrecognized_Name                   = 112, // Fatal
	Bad_Certificate_Status_Response     = 113, // Fatal
	Bad_Certificate_Hash_Value_RESERVED = 114,
	Unknown_Psk_Identity                = 115, // Fatal (optional, use Decrypt_Error)
	Certificate_Required                = 116, // Fatal
	General_Error                       = 117, // Fatal
	No_Application_Protocol             = 120, // Fatal
}

Handshake_Type :: enum u8 {
	Hello_Request_RESERVED        = 0,
	Client_Hello                  = 1,
	Server_Hello                  = 2,
	Hello_Verify_Request_RESERVED = 3,
	New_Session_Ticket            = 4,
	End_Of_Early_Data             = 5,
	Hello_Retry_Request_RESERVED  = 6,
	Encrypted_Extensions          = 8,
	Certificate                   = 11,
	Server_Key_Exchange_RESERVED  = 12,
	Certificate_Request           = 13,
	Server_Hello_Done_RESERVED    = 14,
	Certificate_Verify            = 15,
	Client_Key_Exchange_RESERVED  = 16,
	Finished                      = 20,
	Certificate_Url_RESERVED      = 21,
	Certificate_Dtatus_RESERVED   = 22,
	Supplemental_Data_RESERVED    = 23,
	Key_Update                    = 24,
	Message_Hash                  = 254,
}

Extension_Type :: enum u16 {
	Server_Name                            = 0,  // RFC 6066, 9261
	Status_Request                         = 5,  // RFC 6066, 9846
	Supported_Groups                       = 10, // RFC 7919, 9846
	Signature_Algorithms                   = 13, // RFC 9846
	Use_Srtp                               = 14, // RFC 5764
	Heartbeat                              = 15, // RFC 6520
	Application_Layer_Protocol_Negotiation = 16, // RFC 7301
	Client_Certificate_Type                = 19, // RFC 7250
	Server_Certificate_Type                = 20, // RFC 7250
	Padding                                = 21, // RFC 7685
	Compress_Certificate                   = 27, // RFC 8879
	Record_Size_Limit                      = 28, // RFC 8449
	Delegated_Credential                   = 34, // RFC 9345
	Supported_Ekt_Ciphers                  = 39, // RFC 8870
	Pre_Shared_Key                         = 41, // RFC 9846
	Early_Data                             = 42, // RFC 9846
	Supported_Versions                     = 43, // RFC 9846
	Cookie                                 = 44, // RFC 9846
	Psk_Key_Exchange_Modes                 = 45, // RFC 9846
	Certificate_Authorities                = 47, // RFC 9846
	Oid_Filters                            = 48, // RFC 9846
	Post_Handshake_Auth                    = 49, // RFC 9846
	Signature_Algorithms_Cert              = 50, // RFC 9846
	Key_Share                              = 51, // RFC 9846
	Transparency_Info                      = 52, // RFC 9162
	External_Id_Hash                       = 55, // RFC 8844
	External_Session_Id                    = 56, // RFC 8844
	Quic_Transport_Parameters              = 57, // RFC 9001
	Ticket_Request                         = 58, // RFC 9149
	Ech_Outer_Extensions                   = 64768, // RFC 9849
	Encrypted_Client_Hello                 = 65037, // RFC 9849

	// TLS 1.2
	Ec_Point_Formats                       = 11,    // RFC 8422
	Renegotiaton_Info                      = 65281, // RFC 5746
}

Key_Update_Request :: enum u8 {
	Update_Not_Requested = 0,
	Update_Requested     = 1,
}

Name_Type :: enum u8 {
	Host_Name = 0,
}

@(rodata)
PROTOCOL_ERROR_TO_ALERT := [Protocol_Error]Alert_Description{
	.None                            = .General_Error,
	.Close_Notify                    = .Close_Notify,
	.Unexpected_Message              = .Unexpected_Message,
	.Bad_Record_Mac                  = .Bad_Record_Mac,
	.Record_Overflow                 = .Record_Overflow,
	.Handshake_Failure               = .Handshake_Failure,
	.Bad_Certificate                 = .Bad_Certificate,
	.Unsupported_Certificate         = .Unsupported_Certificate,
	.Certificate_Revoked             = .Certificate_Revoked,
	.Certificate_Expired             = .Certificate_Expired,
	.Certificate_Unknown             = .Certificate_Unknown,
	.Illegal_Parameter               = .Illegal_Parameter,
	.Unknown_Ca                      = .Unknown_Ca,
	.Access_Denied                   = .Access_Denied,
	.Decode_Error                    = .Decode_Error,
	.Decrypt_Error                   = .Decrypt_Error,
	.Protocol_Version                = .Protocol_Version,
	.Insufficient_Security           = .Insufficient_Security,
	.Internal_Error                  = .Internal_Error,
	.Inappropriate_Fallback          = .Inappropriate_Fallback,
	.User_Canceled                   = .User_Canceled,
	.Missing_Extension               = .Missing_Extension,
	.Unsupported_Extension           = .Unsupported_Extension,
	.Unrecognized_Name               = .Unrecognized_Name,
	.Bad_Certificate_Status_Response = .Bad_Certificate_Status_Response,
	.Unknown_Psk_Identity            = .Unknown_Psk_Identity,
	.Certificate_Required            = .Certificate_Required,
	.General_Error                   = .General_Error,
	.No_Application_Protocol         = .No_Application_Protocol,
}

@(rodata)
ALERT_TO_ERROR := #sparse [Alert_Description]Error {
	.Close_Notify                    = Protocol_Error.Close_Notify,
	.Unexpected_Message              = Protocol_Error.Unexpected_Message,
	.Bad_Record_Mac                  = Protocol_Error.Bad_Record_Mac,
	.Record_Overflow                 = Protocol_Error.Record_Overflow,
	.Handshake_Failure               = Protocol_Error.Handshake_Failure,
	.Bad_Certificate                 = Protocol_Error.Bad_Certificate,
	.Unsupported_Certificate         = Protocol_Error.Unsupported_Certificate,
	.Certificate_Revoked             = Protocol_Error.Certificate_Revoked,
	.Certificate_Expired             = Protocol_Error.Certificate_Expired,
	.Certificate_Unknown             = Protocol_Error.Certificate_Unknown,
	.Illegal_Parameter               = Protocol_Error.Illegal_Parameter,
	.Unknown_Ca                      = Protocol_Error.Unknown_Ca,
	.Access_Denied                   = Protocol_Error.Access_Denied,
	.Decode_Error                    = Protocol_Error.Decode_Error,
	.Decrypt_Error                   = Protocol_Error.Decrypt_Error,
	.Protocol_Version                = Protocol_Error.Protocol_Version,
	.Insufficient_Security           = Protocol_Error.Insufficient_Security,
	.Internal_Error                  = Protocol_Error.Internal_Error,
	.Inappropriate_Fallback          = Protocol_Error.Inappropriate_Fallback,
	.User_Canceled                   = Protocol_Error.User_Canceled,
	.Missing_Extension               = Protocol_Error.Missing_Extension,
	.Unsupported_Extension           = Protocol_Error.Unsupported_Extension,
	.Unrecognized_Name               = Protocol_Error.Unrecognized_Name,
	.Bad_Certificate_Status_Response = Protocol_Error.Bad_Certificate_Status_Response,
	.Unknown_Psk_Identity            = Protocol_Error.Unknown_Psk_Identity,
	.Certificate_Required            = Protocol_Error.Certificate_Required,
	.General_Error                   = Protocol_Error.General_Error,
	.No_Application_Protocol         = Protocol_Error.No_Application_Protocol,

	// TLS 1.2
	.Decryption_Failed_RESERVED          = Protocol_Error.General_Error,
	.Decompression_Failure_RESERVED      = Protocol_Error.General_Error,
	.No_Certificate_RESERVED             = Protocol_Error.General_Error,
	.Export_Restriction_RESERVED         = Protocol_Error.General_Error,
	.No_Renegotiation_RESERVED           = Protocol_Error.General_Error,
	.Certificate_Unobtainable_RESERVED   = Protocol_Error.General_Error,
	.Bad_Certificate_Hash_Value_RESERVED = Protocol_Error.General_Error,
}

@(rodata)
CIPHER_SUITE_AEAD := [Cipher_Suite]aead.Algorithm {
	.TLS_AES_128_GCM_SHA256       = .AES_GCM_128,
	.TLS_AES_256_GCM_SHA384       = .AES_GCM_256,
	.TLS_CHACHA20_POLY1305_SHA256 = .CHACHA20POLY1305,
}

@(rodata)
CIPHER_SUITE_HASH := [Cipher_Suite]hash.Algorithm {
	.TLS_AES_128_GCM_SHA256       = .SHA256,
	.TLS_AES_256_GCM_SHA384       = .SHA384,
	.TLS_CHACHA20_POLY1305_SHA256 = .SHA256,
}

@(rodata)
SIGNATURE_SCHEME_HASH := #sparse [Signature_Scheme]hash.Algorithm {
	.Rsa_Pkcs1_Sha256 = .SHA256,
	.Rsa_Pkcs1_Sha384 = .SHA384,
	.Rsa_Pkcs1_Sha512 = .SHA512,

	.Ecdsa_Secp256r1_Sha256 = .SHA256,
	.Ecdsa_Secp384r1_Sha384 = .SHA384,
	// .Ecdsa_Secp521r1_Sha512 = .SHA512,

	.Rsa_Pss_Rsae_Sha256 = .SHA256,
	.Rsa_Pss_Rsae_Sha384 = .SHA384,
	.Rsa_Pss_Rsae_Sha512 = .SHA512,

	.Ed25519 = .Invalid,
	// .Ed448   = .Invalid,

	.Rsa_Pss_Pss_Sha256 = .SHA256,
	.Rsa_Pss_Pss_Sha384 = .SHA384,
	.Rsa_Pss_Pss_Sha512 = .SHA512,

	.Rsa_Pkcs1_Sha1 = .Invalid,
	.Ecdsa_Sha1     = .Invalid,
}

@(rodata)
SIGNATURE_SCHEME_TO_X509_PUBLIC_KEY := #sparse [Signature_Scheme]x509.Public_Key_Algorithm {
	.Rsa_Pkcs1_Sha256 = .RSA,
	.Rsa_Pkcs1_Sha384 = .RSA,
	.Rsa_Pkcs1_Sha512 = .RSA,

	.Ecdsa_Secp256r1_Sha256 = .ECDSA_P256,
	.Ecdsa_Secp384r1_Sha384 = .ECDSA_P384,
	// .Ecdsa_Secp521r1_Sha512 = .ECDSA_P521,

	.Rsa_Pss_Rsae_Sha256 = .RSA,
	.Rsa_Pss_Rsae_Sha384 = .RSA,
	.Rsa_Pss_Rsae_Sha512 = .RSA,

	.Ed25519 = .Ed25519,
	// .Ed448   = .Invalid,

	.Rsa_Pss_Pss_Sha256 = .RSA,
	.Rsa_Pss_Pss_Sha384 = .RSA,
	.Rsa_Pss_Pss_Sha512 = .RSA,

	.Rsa_Pkcs1_Sha1 = .Unknown,
	.Ecdsa_Sha1     = .Unknown,
}

@(rodata)
CERTIFICATE_FORBIDDEN_EXTENSIONS := #sparse [Extension_Type]bool {
	.Signature_Algorithms      = false, // RFC 9846
	.Status_Request            = false, // RFC 6066, 9846
	.Compress_Certificate      = false, // RFC 8879
	.Delegated_Credential      = false, // RFC 9345
	.Certificate_Authorities   = false, // RFC 9846
	.Oid_Filters               = false, // RFC 9846
	.Signature_Algorithms_Cert = false, // RFC 9846
	.Transparency_Info         = false, // RFC 9162

	.Server_Name                            = true,  // RFC 6066, 9261
	.Supported_Groups                       = true, // RFC 7919, 9846
	.Use_Srtp                               = true, // RFC 5764
	.Heartbeat                              = true, // RFC 6520
	.Application_Layer_Protocol_Negotiation = true, // RFC 7301
	.Client_Certificate_Type                = true, // RFC 7250
	.Server_Certificate_Type                = true, // RFC 7250
	.Padding                                = true, // RFC 7685
	.Record_Size_Limit                      = true, // RFC 8449
	.Supported_Ekt_Ciphers                  = true, // RFC 8870
	.Pre_Shared_Key                         = true, // RFC 9846
	.Early_Data                             = true, // RFC 9846
	.Supported_Versions                     = true, // RFC 9846
	.Cookie                                 = true, // RFC 9846
	.Psk_Key_Exchange_Modes                 = true, // RFC 9846
	.Post_Handshake_Auth                    = true, // RFC 9846
	.Key_Share                              = true, // RFC 9846
	.External_Id_Hash                       = true, // RFC 8844
	.External_Session_Id                    = true, // RFC 8844
	.Quic_Transport_Parameters              = true, // RFC 9001
	.Ticket_Request                         = true, // RFC 9149
	.Ech_Outer_Extensions                   = true, // RFC 9849
	.Encrypted_Client_Hello                 = true, // RFC 9849

	// TLS 1.2
	.Ec_Point_Formats                       = true, // RFC 8422
	.Renegotiaton_Info                      = true, // RFC 5746
}

@(rodata)
ALPN_STRINGS := [Alpn_Protocols]string {
	.None                = "",
	.Http_0_9            = "http/0.9",
	.Http_1_0            = "http/1.0",
	.Http_1_1            = "http/1.1",
	.Spdy_1              = "spdy/1",
	.Spdy_2              = "spdy/2",
	.Spdy_3              = "spdy/3",
	.Turn                = "stun.turn",
	.Stun                = "stun.nat-discovery",
	.Http_2              = "h2",
	// Http_2_Tcp        = "h2c", (Not valid for TLS ALPN)
	.Webrtc              = "webrtc",
	.Confidential_Webrtc = "c-webrtc",
	.Ftp                 = "ftp",
	.Imap                = "imap",
	.Pop3                = "pop3",
	.Managesieve         = "managesieve",
	.Coap_Tls            = "coap",
	.Coap_Dtls           = "co",
	.Xmpp_Client         = "xmpp-client",
	.Xmpp_Server         = "xmpp-server",
	.Acme_Tls_1          = "acme-tls/1",
	.Mqtt                = "mqtt",
	.Dot                 = "dot",
	.Ntske_1             = "ntske/1",
	.Sunrpc              = "sunrpc",
	.Http_3              = "h3",
	.Smb2                = "smb",
	.Irc                 = "irc",
	.Nntp_Reading        = "nntp",
	.Nntp_Transit        = "nnsp",
	.Doq                 = "doq",
	.Sip                 = "sip/2",
	.Tds_8_0             = "tds/8.0",
	.Dicom               = "dicom",
	.Postgresql          = "postgresql",
	.Radius_1_0          = "radius/1.0",
	.Radius_1_1          = "radius/1.1",
	.Npmp_Control        = "netperfmeter/control",
	.Npmp_Data           = "netperfmeter/data",
	.N_Pamp              = "n-pamp/2",
	.Eoq                 = "EoQ",
	.Snif_Over_Quic      = "snifq/1",
}

@(require_results)
alert_to_error :: proc(level: Alert_Level, alert: Alert_Description) -> Error {
	switch level {
	case .Warning, .Fatal:
	case:
		return Protocol_Error.Decode_Error
	}

	return ALERT_TO_ERROR[alert]
}

@(require_results)
error_to_alert :: proc(err: Error) -> Alert_Description {
	if proto_err, ok := err.(Protocol_Error); ok {
		return PROTOCOL_ERROR_TO_ALERT[proto_err]
	}

	return .Internal_Error
}

@(require_results)
alert_to_level :: proc(alert: Alert_Description) -> Alert_Level {
	#partial switch alert {
	case .Close_Notify, .User_Canceled:
		return .Warning
	case:
		return .Fatal
	}
}

@(require_results)
buffer_recv_raw_record :: proc(
	buf:                   ^Buffer,
	socket:                ^Socket,
	expected_content_type: Content_Type = .Application_Data,
	protected:             bool = false,
) -> (content_type: Content_Type, err: Error) {
	buffer_clear(buf)

	// Read the record header.
	buffer_write_recv(buf, socket.fd, TLS_RECORD_HEADER_SIZE) or_return

	// Validate the content_type.
	content_type = Content_Type(buffer_unchecked_read_u8(buf))
	#partial switch content_type {
	case .Alert, .Change_Cipher_Spec, .Handshake, .Application_Data:
	case:
		content_type = .Invalid
		return content_type, Protocol_Error.Unexpected_Message
	}

	// Ignore the legacy_protocol_version, till we support TLS 1.2,
	// in which case we care about it for the ServerHello.
	_ = buffer_unchecked_read_u16(buf)

	// Parse the length.
	length := int(buffer_unchecked_read_u16(buf))
	max_len := protected ? TLS13_MAX_RECORD_SIZE + TLS13_MAX_AEAD_OVERHEAD : TLS13_MAX_RECORD_SIZE
	if length > max_len {
		return .Invalid, Protocol_Error.Record_Overflow
	}

	// Read the payload.
	buffer_write_recv(buf, socket.fd, length) or_return

	if content_type != expected_content_type {
		err = Protocol_Error.Unexpected_Message
	}

	return
}

@(require_results)
buffer_recv_unprotected_handshake_record :: proc(
	buf:            ^Buffer,
	socket:         ^Socket,
	handshake_type: Handshake_Type,
) -> (content_type: Content_Type, err: Error) {
	tmp: [TLS13_MAX_RECORD_SIZE]byte
	tmp_buf: Buffer
	buffer_init(&tmp_buf, tmp[:])

	content_type = buffer_recv_raw_record(buf, socket, .Handshake) or_return

	// Ensure we have up to the length field.
	if buffer_unread_len(buf) < 1 + 3 {
		return .Invalid, Protocol_Error.Decode_Error
	}

	if Handshake_Type(buffer_unchecked_read_u8(buf)) != handshake_type {
		return .Invalid, Protocol_Error.Unexpected_Message
	}

	// Fast path for non-fragmented responses.
	payload_len := buffer_unchecked_read_u24(buf)
	if buffer_unread_len(buf) == payload_len {
		return
	}

	// We limit the size of unprotected records to that of a single
	// maximum sized TLS 1.3 record.
	if payload_len > buffer_available(buf) {
		return content_type, Protocol_Error.Decode_Error
	}

	// Receive additional records.
	for payload_len != 0 {
		content_type_ := buffer_recv_raw_record(&tmp_buf, socket, .Handshake) or_return
		if content_type_ != content_type {
			return content_type_, Protocol_Error.Unexpected_Message
		}

		l := buffer_unread_len(&tmp_buf)
		if l > payload_len {
			return .Invalid, Protocol_Error.Decode_Error
		}

		buffer_pullup(buf, &tmp_buf) or_return

		payload_len -= l
	}

	return
}

@(require_results)
buffer_send_change_cipher_spec :: proc(socket: ^Socket) -> (err: Error) {
	ccs_data: [TLS_RECORD_HEADER_SIZE+1]byte = ---
	buf: Buffer

	buffer_init(&buf, ccs_data[:])
	buffer_unchecked_write_u8(&buf, u8(Content_Type.Change_Cipher_Spec))
	buffer_unchecked_write_u16(&buf, TLS12_PROTOCOL_VERSION)
	buffer_unchecked_write_u16(&buf, 1)

	buffer_unchecked_write_u8(&buf, 0x01)

	return buffer_send(&buf, socket.fd)
}

buffer_send_early_alert :: proc(
	socket: ^Socket,
	alert:  Alert_Description,
) -> (err: Error) {
	alert_data: [TLS_RECORD_HEADER_SIZE+2]byte = ---
	buf: Buffer

	buffer_init(&buf, alert_data[:])
	buffer_unchecked_write_u8(&buf, u8(Content_Type.Alert))
	buffer_unchecked_write_u16(&buf, TLS12_PROTOCOL_VERSION)
	buffer_unchecked_write_u16(&buf, 2)

	buffer_unchecked_write_u8(&buf, u8(alert_to_level(alert)))
	buffer_unchecked_write_u8(&buf, u8(alert))

	return buffer_send(&buf, socket.fd)
}

buffer_send_alert :: proc(
	buf:    ^Buffer,
	socket: ^Socket,
	alert:  Alert_Description,
) -> (err: Error) {
	PAYLOAD_SIZE :: 2

	buffer_clear(buf)
	buffer_check_write(buf, TLS_RECORD_HEADER_SIZE + PAYLOAD_SIZE + TLS13_AEAD_OVERHEAD) or_return
	buffer_unchecked_write_u8(buf, u8(Content_Type.Application_Data))
	buffer_unchecked_write_u16(buf, TLS12_PROTOCOL_VERSION)
	buffer_unchecked_write_u16(buf, PAYLOAD_SIZE + TLS13_AEAD_OVERHEAD)

	buffer_unchecked_write_u8(buf, u8(alert_to_level(alert)))
	buffer_unchecked_write_u8(buf, u8(alert))
	buffer_unchecked_write_u8(buf, u8(Content_Type.Alert))

	return buffer_send_record(buf, socket)
}

buffer_send_key_update :: proc(
	buf:              ^Buffer,
	socket:           ^Socket,
	update_requested: Key_Update_Request,
) -> (err: Error) {
	PAYLOAD_SIZE :: 1 + 3 + 1

	buffer_clear(buf)
	buffer_check_write(buf, TLS_RECORD_HEADER_SIZE + PAYLOAD_SIZE + TLS13_AEAD_OVERHEAD) or_return
	buffer_unchecked_write_u8(buf, u8(Content_Type.Application_Data))
	buffer_unchecked_write_u16(buf, TLS12_PROTOCOL_VERSION)
	buffer_unchecked_write_u16(buf, PAYLOAD_SIZE + TLS13_AEAD_OVERHEAD)

	buffer_unchecked_write_u8(buf, u8(Handshake_Type.Key_Update))
	buffer_unchecked_write_u24(buf, 1)
	buffer_unchecked_write_u8(buf, u8(update_requested))
	buffer_unchecked_write_u8(buf, u8(Content_Type.Handshake))

	return buffer_send_record(buf, socket)
}

@(require_results)
buffer_send_finished :: proc(
	buf:             ^Buffer,
	socket:          ^Socket,
	transcript_hash: ^hash.Context,
) -> (err: Error) {
	tmp: [hash.MAX_DIGEST_SIZE]byte = ---
	secrets := &socket._state.secrets

	hash_len := hash.DIGEST_SIZES[secrets.hash]

	verify_data := tmp[:hash_len]

	derive_connection_finished(secrets, transcript_hash, verify_data, socket._state.secrets.is_client)

	payload_size := 3 + 1 + hash_len

	buffer_clear(buf)
	buffer_check_write(buf, TLS_RECORD_HEADER_SIZE + payload_size + TLS13_AEAD_OVERHEAD) or_return
	buffer_unchecked_write_u8(buf, u8(Content_Type.Application_Data))
	buffer_unchecked_write_u16(buf, TLS12_PROTOCOL_VERSION)
	buffer_unchecked_write_u16(buf, u16(payload_size + TLS13_AEAD_OVERHEAD))

	buffer_unchecked_write_u8(buf, u8(Handshake_Type.Finished))
	buffer_unchecked_write_u24(buf, hash_len)
	buffer_unchecked_write_bytes(buf, verify_data)
	buffer_unchecked_write_u8(buf, u8(Content_Type.Handshake))

	return buffer_send_record(buf, socket)
}

@(require_results)
buffer_send_empty_certificate :: proc(
	buf:         ^Buffer,
	socket:      ^Socket,
	request_ctx: []byte,
) -> (err: Error) {
	payload_size := 1 + 1 + len(request_ctx) + 3

	buffer_clear(buf)
	buffer_check_write(buf, TLS_RECORD_HEADER_SIZE + payload_size + TLS13_AEAD_OVERHEAD) or_return
	buffer_unchecked_write_u8(buf, u8(Content_Type.Application_Data))
	buffer_unchecked_write_u16(buf, TLS12_PROTOCOL_VERSION)
	buffer_unchecked_write_u16(buf, u16(payload_size + TLS13_AEAD_OVERHEAD))

	buffer_unchecked_write_u8(buf, u8(Handshake_Type.Certificate))
	buffer_unchecked_write_u8(buf, u8(len(request_ctx)))
	buffer_unchecked_write_bytes(buf, request_ctx)
	buffer_unchecked_write_u24(buf, 0)
	buffer_unchecked_write_u8(buf, u8(Content_Type.Handshake))

	return buffer_send_record(buf, socket)
}

@(require_results)
buffer_read_handshake_msg :: proc(
	buf:                      ^Buffer,
	record_buf:               ^Buffer,
	socket:                   ^Socket,
	is_client:                bool,
	allow_change_cipher_spec: ^bool,
) -> (msg: []byte, err: Error) {
	MSG_HDR_SIZE :: 4 // `HandshakeType` + `length`

	for {
		// The accumulator buffer has data.
		if l := buffer_unread_len(buf); l >= MSG_HDR_SIZE {
			msg = buffer_unread_bytes(buf)
			// msg_type := msg[0]
			msg_len := int(endian.unchecked_get_unsigned_be(msg[1:], 24))
			n := MSG_HDR_SIZE + msg_len
			if n >= msg_len {
				return buffer_unchecked_read_skip(buf, n), nil
			}
		}

		for {
			content_type: Content_Type
			send_alert: bool
			content_type, err, send_alert = buffer_recv_handshake_record(
				record_buf,
				socket,
				is_client,
				allow_change_cipher_spec^,
			)
			if err != nil {
				if send_alert {
					buffer_send_alert(record_buf, socket, error_to_alert(err))
				}
				return
			}
			if content_type == .Change_Cipher_Spec {
				allow_change_cipher_spec^ = false
				continue
			}
			if err = buffer_pullup(buf, record_buf); err != nil {
				buffer_send_alert(record_buf, socket, .Internal_Error)
			}
			break
		}
	}
}

@(require_results)
buffer_recv_handshake_record :: proc(
	buf:                      ^Buffer,
	socket:                   ^Socket,
	is_client:                bool,
	allow_change_cipher_spec: bool,
) -> (content_type: Content_Type, err: Error, send_alert: bool) {
	content_type, err = buffer_recv_record(buf, socket, true, allow_change_cipher_spec)
	if err != nil {
		if content_type == .Alert {
			return .Alert, err, false
		}

		return .Invalid, err, true
	}
	#partial switch content_type {
	case .Handshake:
	case .Change_Cipher_Spec:
		return
	case:
		return content_type, Protocol_Error.Unexpected_Message, true
	}

	if buffer_unread_len(buf) < 1 {
		return content_type, Protocol_Error.Decode_Error, true
	}
	_ = buffer_trim(buf, 1) // Trim off the `content_type`.

	// RFC 9846 5.4
	//
	//  Implementations MUST NOT send Handshake and Alert records
	//  that have a zero-length TLSInnerPlaintext.content; if such
	//  a message is received, the receiving implementation MUST
	//  terminate the connection with an "unexpected_message" alert.
	if buffer_unread_len(buf) == 0 {
		return content_type, Protocol_Error.Unexpected_Message, true
	}

	return
}

@(require_results)
buffer_recv_record :: proc(
	buf:                      ^Buffer,
	socket:                   ^Socket,
	is_client:                bool,
	allow_change_cipher_spec: bool = false,
) -> (content_type: Content_Type, err: Error) {
	content_type, err = buffer_recv_raw_record(buf, socket, .Application_Data, true)
	if err != nil {
		// Each side is allowed to send a single ChangeCipherSpec
		// between the ClientHello/ServerHello and Finished.
		if intrinsics.unlikely(err == Protocol_Error.Unexpected_Message && content_type == .Change_Cipher_Spec && allow_change_cipher_spec) {
			if buffer_unread_len(buf) != 1 {
				return content_type, Protocol_Error.Decode_Error
			}
			if buffer_unchecked_read_u8(buf) != 0x01 {
				return content_type, Protocol_Error.Illegal_Parameter
			}

			return content_type, nil
		}

		return
	}

	// Decrypt.
	aead_state: ^Aead_State
	switch is_client {
	case true:
		aead_state = &socket._state.secrets.server_aead
	case false:
		aead_state = &socket._state.secrets.client_aead
	}

	aad := buffer_bytes(buf)[:TLS_RECORD_HEADER_SIZE]
	payload := buffer_bytes_at(buf, TLS_RECORD_HEADER_SIZE)
	payload_len := len(payload) - AEAD_TAG_SIZE
	if payload_len <= 0 {
		// Need at least one payload byte for the content
		// type.
		return .Invalid, Protocol_Error.Decode_Error
	}

	tag := payload[payload_len:]
	payload = payload[:payload_len]

	iv: [AEAD_IV_SIZE]byte
	endian.unchecked_put_u64be(iv[4:], aead_state.seq)
	for v, i in aead_state.iv {
		if i < 4 {
			iv[i] = v
		} else {
			iv[i] ~= v
		}
	}

	ok := aead.open(&aead_state.ctx, payload, iv[:], aad, payload, tag)
	if !ok {
		return .Invalid, Protocol_Error.Bad_Record_Mac
	}

	// See if we ran out of secure sequence number space.  This should
	// not happen because we proactively request a re-key well in advance.
	//
	// Note: We do lose a record, but the amount of data transfered
	// needed to hit this point is astronomical.
	if aead_state.seq += 1; aead_state.seq == AEAD_ABORT_SEQ[socket._state.secrets.aead] {
		return .Invalid, Protocol_Error.Internal_Error
	}

	// Trim the tag.
	_ = buffer_trim(buf, AEAD_TAG_SIZE)

	// Find the actual Content_Type (last non-zero byte in the
	// protected payload), and trim off the padding.
	payload = bytes.trim_right(payload, []byte{0x00})
	l := len(payload)
	if l == 0 {
		return .Invalid, Protocol_Error.Bad_Record_Mac
	}
	_ = buffer_trim(buf, payload_len - l)

	content_type = Content_Type(payload[l-1])
	if content_type == .Alert {
		if buffer_unread_len(buf) == 3 {
			return .Alert, alert_to_error(
				Alert_Level(buffer_unchecked_read_u8(buf)),
				Alert_Description(buffer_unchecked_read_u8(buf)),
			)
		}
		return .Invalid, Protocol_Error.Bad_Record_Mac
	}

	return
}

@(require_results)
buffer_send_record :: proc(buf: ^Buffer, socket: ^Socket) -> (err: Error) {
	// Encrypt.
	aead_state: ^Aead_State
	switch socket._state.secrets.is_client {
	case true:
		aead_state = &socket._state.secrets.client_aead
	case false:
		aead_state = &socket._state.secrets.server_aead
	}

	aad := buffer_bytes(buf)[:TLS_RECORD_HEADER_SIZE]
	payload := buffer_bytes_at(buf, TLS_RECORD_HEADER_SIZE)

	iv: [AEAD_IV_SIZE]byte
	endian.unchecked_put_u64be(iv[4:], aead_state.seq)
	for v, i in aead_state.iv {
		if i < 4 {
			iv[i] = v
		} else {
			iv[i] ~= v
		}
	}

	tag: [AEAD_TAG_SIZE]byte = ---
	aead.seal(&aead_state.ctx, payload, tag[:], iv[:], aad, payload)

	// See if we ran out of secure sequence number space.  This should
	// not happen because we proactively re-key well in advance.
	//
	// Note: We do lose a record, but the amount of data transfered
	// needed to hit this point is astronomical.
	if aead_state.seq += 1; aead_state.seq == AEAD_ABORT_SEQ[socket._state.secrets.aead] {
		return Protocol_Error.Internal_Error
	}

	buffer_write_bytes(buf, tag[:]) or_return

	return buffer_send(buf, socket.fd)
}
