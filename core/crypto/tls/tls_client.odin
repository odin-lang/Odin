package tls

import "base:runtime"
import "core:bytes"
import "core:crypto"
import "core:crypto/aes"
import "core:crypto/ecdh"
import "core:crypto/ecdsa"
import "core:crypto/ed25519"
import "core:crypto/hash"
import "core:crypto/mlkem"
import "core:crypto/rsa"
import "core:crypto/x509"
import "core:encoding/endian"
import "core:io"
import "core:net"
import "core:os"
import "core:slice"
import "core:sync"
import "core:sync/chan"
import "core:time"
import "core:thread"

@(private="file")
MAX_SERVER_RESPONSES_SIZE :: 256 * 1024

// client_handshake performs a TLS handshake given an established
// TCP connection (`net_socket`).  `trust_roots` is expected to be
// populated with certificate authority certificates.
//
// Debugging options (that destroy security):
// - unsafe_skip_verify: Omits checking the certificate chain.
// - unsafe_secret_logger: Writes the handshake key material for use
//   with Wireshark and similar tools.
//
// Once this function returns with a non-error result `close` MUST
// be called to free up resources.
@(require_results)
client_handshake :: proc(
	socket:               ^Socket,
	net_socket:           net.TCP_Socket,
	host_name:            string,
	trust_roots:          []^x509.Certificate,
	alpn_protocols:       []Alpn_Protocols = nil,
	unsafe_skip_verify:   bool = false,
	unsafe_secret_logger: ^os.File = nil,
	allocator:            runtime.Allocator = context.allocator,
) -> Error {
	if err := net.set_blocking(net_socket, true); err != nil {
		return General_Error.Nonblocking_Socket
	}
	err := _client_handshake(
		socket,
		net_socket,
		SUPPORTED_GROUPS,
		host_name,
		trust_roots,
		alpn_protocols,
		unsafe_skip_verify,
		unsafe_secret_logger,
		allocator,
	)
	if err != nil {
		clear_connection_secrets(&socket._state.secrets)
	}
	return socket_set_error(socket, err)
}

@(require_results, private="file")
_client_handshake :: proc(
	socket:               ^Socket,
	net_socket:           net.TCP_Socket,
	supported_groups:     []Named_Group,
	host_name:            string,
	trust_roots:          []^x509.Certificate,
	alpn_protocols:       []Alpn_Protocols,
	unsafe_skip_verify:   bool,
	unsafe_secret_logger: ^os.File,
	allocator:            runtime.Allocator,
) -> Error {
	if len(host_name) > SNI_MAX_HOSTNAME_SIZE {
		return General_Error.Invalid_SNI_Hostname
	}

	// `server_name` MUST be a FQDN and not an IP address.
	sni_host := net.parse_address(host_name) == nil ? host_name : ""

	record_data: [TLS13_MAX_RECORD_SIZE+TLS13_MAX_AEAD_OVERHEAD]byte = ---
	record_buf: Buffer
	buffer_init(&record_buf, record_data[:])

	cipher_suites: []Cipher_Suite
	switch aes.is_hardware_accelerated() {
	case true:
		cipher_suites = CIPHER_SUITES_HW_AES
	case false:
		cipher_suites = CIPHER_SUITES
	}

	running_hash: hash.Context = ---

	socket.fd = net_socket
	socket.alpn_protocol = .None
	socket._state.allocator = allocator
	socket._state.err = nil
	socket._state.handshaked = false

	// Generate ephemeral keys.
	ephemeral_keys: Ephemeral_Keys = ---
	defer clear_ephemeral_keys(&ephemeral_keys)
	if !init_ephemeral_keys(&ephemeral_keys, supported_groups) {
		return General_Error.Failed_Key_Share_Generation
	}

	// Generate and send ClientHello.
	buf_client_random, buf_session_id := do_client_hello(
		socket,
		&record_buf,
		&ephemeral_keys,
		cipher_suites,
		sni_host,
		alpn_protocols,
	) or_return
	if unsafe_secret_logger == nil {
		buf_client_random = nil
	}

	handshake_keys: Handshake_Keys = ---
	defer clear_handshake_keys(&handshake_keys)

	// Receive and parse ServerHello.
	do_server_hello(
		socket,
		&handshake_keys,
		&ephemeral_keys,
		&running_hash,
		&record_buf,
		buf_session_id,
		buf_client_random,
		cipher_suites,
		unsafe_secret_logger,
		allocator,
	) or_return
	defer hash.reset(&running_hash)

	// RFC 9846 Section 5:
	//
	//   An implementation may receive an unencrypted record of type
	//   change_cipher_spec consisting of the single byte value 0x01
	//   at any time after the first ClientHello message has been sent
	//   or received and before the peer's Finished message has been
	//   received and MUST simply drop it without further processing.
	//
	// At this point we have an encrypted connection.
	//
	// It is perfectly legal to coallece multiple messages up to the
	// `Finished` into single/multiple records.

	msg_buf: Buffer
	msg: []byte
	allow_change_cipher_spec := true

	msgs_buf: Buffer
	if err := buffer_make(&msgs_buf, MAX_SERVER_RESPONSES_SIZE, allocator); err != nil {
		buffer_send_alert(&record_buf, socket, .Internal_Error)
		return err
	}
	defer buffer_delete(&msgs_buf, allocator)

	// Receive Encrypted Extensions
	{
		msg = buffer_read_handshake_msg(
			&msgs_buf,
			&record_buf,
			socket,
			true,
			&allow_change_cipher_spec,
		) or_return

		handshake_type := Handshake_Type(msg[0])
		if handshake_type != .Encrypted_Extensions {
			buffer_send_alert(&record_buf, socket, .Unexpected_Message)
			return Protocol_Error.Unexpected_Message
		}

		// Parse the extensions.
		//
		// TLS 1.3 allowed extensions, based on ClientHello:
		//  - application_layer_protocol_negotiation
		//  - server_name
		//
		// Send `illegal_parameter` for anything else.
		buffer_init(&msg_buf, msg[4:], true)

		// Check `extensions_length`.
		l := buffer_unread_len(&msg_buf)
		if l < 2 || l - 2 != int(buffer_unchecked_read_u16(&msg_buf)) {
			buffer_send_alert(&record_buf, socket, .Decode_Error)
			return Protocol_Error.Decode_Error
		}

		got_sni: bool
		for l = buffer_unread_len(&msg_buf); l >= 4; l = buffer_unread_len(&msg_buf) {
			// None of the buffer_read calls here can fail because we
			// at least have the extension type/length, and explicitly
			// check the data length.
			extension_type := Extension_Type(buffer_unchecked_read_u16(&msg_buf))
			extension_data, err := buffer_read_opaque_bytes(&msg_buf, 2)
			if err != nil {
				buffer_send_early_alert(socket, .Decode_Error)
				return Protocol_Error.Decode_Error
			}

			// Now we work off extension_data, so we can send alerts.
			#partial switch extension_type {
			case .Server_Name:
				// RFC 6066 3.
				//
				//  In this event, the server SHALL include an
				//  extension of type "server_name" in the (extended)
				//  server hello.  The "extension_data" field of this
				//  extension SHALL be empty.
				if got_sni || len(sni_host) == 0 {
					buffer_send_alert(&record_buf, socket, .Illegal_Parameter)
					return Protocol_Error.Illegal_Parameter
				}
				if len(extension_data) != 0 {
					buffer_send_alert(&record_buf, socket, .Illegal_Parameter)
					return Protocol_Error.Illegal_Parameter
				}
				got_sni = true
			case .Application_Layer_Protocol_Negotiation:
				ext_len := len(extension_data)
				if ext_len < 3 || len(alpn_protocols) == 0 {
					buffer_send_alert(&record_buf, socket, .Decode_Error)
					return Protocol_Error.Decode_Error
				}
				if socket.alpn_protocol != .None {
					buffer_send_alert(&record_buf, socket, .Illegal_Parameter)
					return Protocol_Error.Illegal_Parameter
				}
				alpn_ext_len := int(endian.unchecked_get_u16be(extension_data))
				extension_data = extension_data[2:]
				if len(extension_data) != alpn_ext_len {
					buffer_send_alert(&record_buf, socket, .Decode_Error)
					return Protocol_Error.Decode_Error
				}

				proto_len := int(extension_data[0])
				extension_data = extension_data[1:]
				if len(extension_data) != proto_len {
					buffer_send_alert(&record_buf, socket, .Decode_Error)
					return Protocol_Error.Decode_Error
				}
				proto_string := transmute(string)(extension_data)
				for candidate in alpn_protocols {
					if proto_string == ALPN_STRINGS[candidate] {
						socket.alpn_protocol = candidate
						break
					}
				}
				if socket.alpn_protocol == .None {
					buffer_send_alert(&record_buf, socket, .Illegal_Parameter)
					return Protocol_Error.Illegal_Parameter
				}
			case:
				buffer_send_alert(&record_buf, socket, .Illegal_Parameter)
				return Protocol_Error.Illegal_Parameter
			}
		}
		if buffer_unread_len(&msg_buf) != 0 {
			buffer_send_alert(&record_buf, socket, .Decode_Error)
			return Protocol_Error.Decode_Error
		}

		// Add to session transcript.
		hash.update(&running_hash, msg)

		buffer_trim_read(&msgs_buf)
	}

	// Maybe receive CertificateRequest.
	got_certificate_request: bool
	certificate_request_ctx: [dynamic; 255]byte
	for {
		msg = buffer_read_handshake_msg(
			&msgs_buf,
			&record_buf,
			socket,
			true,
			&allow_change_cipher_spec,
		) or_return

		handshake_type := Handshake_Type(msg[0])
		if handshake_type != .Certificate_Request {
			break
		}

		// Parse the message, and set flag to send empty
		// Certificate prior to client Finished.
		buffer_init(&msg_buf, msg[4:], true)
		ctx, err := do_certificate_request(
			socket,
			&msg_buf,
			&record_buf,
		)
		if err != nil {
			// Callee sends alerts for protocol errors.
			if _, ok := err.(Protocol_Error); !ok {
				buffer_send_alert(&record_buf, socket, .Decode_Error)
				return Protocol_Error.Decode_Error
			}
			return err
		}
		append(&certificate_request_ctx, ..ctx)
		got_certificate_request = true

		// Add to session transcript.
		hash.update(&running_hash, msg)

		buffer_trim_read(&msgs_buf)
		msg = nil

		break
	}

	// Receive Certificate.
	leaf_cert: x509.Certificate
	leaf_data: []byte
	{
		// We probably already have the Certificate message
		// from when we looked for the CertificateRequest.
		if msg == nil {
			msg = buffer_read_handshake_msg(
				&msgs_buf,
				&record_buf,
				socket,
				true,
				&allow_change_cipher_spec,
			) or_return
		}

		handshake_type := Handshake_Type(msg[0])
		if handshake_type != .Certificate {
			buffer_send_alert(&record_buf, socket, .Unexpected_Message)
			return Protocol_Error.Unexpected_Message
		}

		err: Error
		buffer_init(&msg_buf, msg[4:], true)
		leaf_cert, leaf_data, err = do_certificate(
			socket,
			&msg_buf,
			&record_buf,
			host_name,
			trust_roots,
			unsafe_skip_verify,
			allocator,
		)
		if err != nil {
			if leaf_data != nil {
				x509.destroy(&leaf_cert, allocator)
				delete(leaf_data, allocator)
			}
			if _, ok := err.(Protocol_Error); !ok {
				buffer_send_alert(&record_buf, socket, .Decode_Error)
				return Protocol_Error.Decode_Error
			}
			return err
		}

		// Add to session transcript.
		hash.update(&running_hash, msg)

		buffer_trim_read(&msgs_buf)
	}
	defer x509.destroy(&leaf_cert, allocator)
	defer delete(leaf_data, allocator)

	// Receive CertificateVerify.
	{
		msg = buffer_read_handshake_msg(
			&msgs_buf,
			&record_buf,
			socket,
			true,
			&allow_change_cipher_spec,
		) or_return

		handshake_type := Handshake_Type(msg[0])
		if handshake_type != .Certificate_Verify {
			buffer_send_alert(&record_buf, socket, .Unexpected_Message)
			return Protocol_Error.Unexpected_Message
		}

		// Parse the message.
		buffer_init(&msg_buf, msg[4:], true)
		if buffer_unread_len(&msg_buf) < 4 {
			buffer_send_alert(&record_buf, socket, .Decode_Error)
			return Protocol_Error.Decode_Error
		}
		sig_algo := Signature_Scheme(buffer_unchecked_read_u16(&msg_buf))
		sig_len := int(buffer_unchecked_read_u16(&msg_buf))
		if sig_len != buffer_unread_len(&msg_buf) {
			buffer_send_alert(&record_buf, socket, .Decrypt_Error)
			return Protocol_Error.Decode_Error
		}
		hash_algo := SIGNATURE_SCHEME_HASH[sig_algo]
		if sig_algo == nil || (hash_algo == .Invalid && sig_algo != .Ed25519) {
			buffer_send_alert(&record_buf, socket, .Decrypt_Error)
			return Protocol_Error.Decrypt_Error
		}
		sig := buffer_unread_bytes(&msg_buf)

		transcript_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
		transcript_hash := transcript_hash_buf[:hash.digest_size(&running_hash)]
		hash.final(&running_hash, transcript_hash, true)

		MSG_MAX_LEN :: len(CERTIFICATE_VERIFY_PREFIX) + len(SERVER_CERTIFICATE_VERIFY_PREFIX) + hash.MAX_DIGEST_SIZE
		sig_msg: [dynamic; MSG_MAX_LEN]byte
		append(&sig_msg, ..CERTIFICATE_VERIFY_PREFIX[:])
		append(&sig_msg, ..SERVER_CERTIFICATE_VERIFY_PREFIX[:])
		append(&sig_msg, ..transcript_hash)

		pk_type := SIGNATURE_SCHEME_TO_X509_PUBLIC_KEY[sig_algo]
		if pk_type != leaf_cert.public_key_algorithm {
			buffer_send_alert(&record_buf, socket, .Decrypt_Error)
			return Protocol_Error.Decrypt_Error
		}

		// Verify the signature from the key from the certificate.
		sig_ok: bool
		#partial switch pk_type {
		case .RSA:
			cert_pk: rsa.Public_Key
			if !rsa.public_key_set_bytes(&cert_pk, leaf_cert.rsa_n, leaf_cert.rsa_e) {
				break
			}
			#partial switch sig_algo {
			case .Rsa_Pkcs1_Sha256, .Rsa_Pkcs1_Sha384, .Rsa_Pkcs1_Sha512:
				sig_ok = rsa.verify_pkcs1(&cert_pk, hash_algo, sig_msg[:], sig)
			case:
				// TODO:
				//  - RSASSA-PSS PSS: If the corresponding public key's
				//    parameters are present, then the parameters in the
				//    signature MUST be identical to those in the public
				//    key.
				salt_len := hash.DIGEST_SIZES[hash_algo]
				sig_ok = rsa.verify_pss(&cert_pk, hash_algo, salt_len, sig_msg[:], sig)
			}
		case .ECDSA_P256, .ECDSA_P384:
			cert_pk: ecdsa.Public_Key
			cert_curve: ecdsa.Curve = pk_type == .ECDSA_P256 ? .SECP256R1 : .SECP384R1
			if !ecdsa.public_key_set_bytes(&cert_pk, cert_curve, leaf_cert.ec_point) {
				break
			}
			sig_ok = ecdsa.verify_asn1(&cert_pk, hash_algo, sig_msg[:], sig)
		case .Ed25519:
			cert_pk: ed25519.Public_Key
			if !ed25519.public_key_set_bytes(&cert_pk, leaf_cert.ec_point) {
				break
			}
			sig_ok = ed25519.verify(&cert_pk, sig_msg[:], sig)
		case:
		}
		if !sig_ok {
			buffer_send_alert(&record_buf, socket, .Decrypt_Error)
			return Protocol_Error.Decrypt_Error
		}

		// Add to session transcript.
		hash.update(&running_hash, msg)

		buffer_trim_read(&msgs_buf)
	}

	// Receive Finished.
	{
		msg = buffer_read_handshake_msg(
			&msgs_buf,
			&record_buf,
			socket,
			true,
			&allow_change_cipher_spec,
		) or_return

		handshake_type := Handshake_Type(msg[0])
		if handshake_type != .Finished {
			buffer_send_alert(&record_buf, socket, .Unexpected_Message)
			return Protocol_Error.Unexpected_Message
		}

		if !verify_connection_finished(&socket._state.secrets, &running_hash, msg[4:], true) {
			buffer_send_alert(&record_buf, socket, .Decrypt_Error)
			return Protocol_Error.Decrypt_Error
		}

		// Add to session transcript.
		hash.update(&running_hash, msg)

		if buffer_unread_len(&msgs_buf) != 0 {
			buffer_send_alert(&record_buf, socket, .Unexpected_Message)
			return Protocol_Error.Unexpected_Message
		}
	}

	// Send ChangeCipherSpec
	buffer_send_change_cipher_spec(socket) or_return

	// If a Certificate_Request was received, send a Certificate.
	if got_certificate_request {
		buffer_send_empty_certificate(&record_buf, socket, certificate_request_ctx[:]) or_return
	}

	// Send Finished
	buffer_send_finished(&record_buf, socket, &running_hash) or_return

	// Switch to the AEAD keys derived from the master secret.
	finished_connection_secrets(&socket._state.secrets, &handshake_keys, &running_hash)

	// Initialize and start the workers.
	err: Error
	socket._state.tx_chan = chan.create(chan.Chan(Worker_Req), 3, allocator) or_return
	if socket._state.tx_resp_chan, err = chan.create(chan.Chan(Worker_Resp), allocator); err != nil {
		chan.destroy(socket._state.tx_chan)
		return err
	}
	if socket._state.rx_chan, err = chan.create(chan.Chan(Worker_Req), allocator); err != nil {
		chan.destroy(socket._state.tx_chan)
		chan.destroy(socket._state.tx_resp_chan)
		return err
	}
	if socket._state.rx_resp_chan, err = chan.create(chan.Chan(Worker_Resp), allocator); err != nil {
		chan.destroy(socket._state.tx_chan)
		chan.destroy(socket._state.tx_resp_chan)
		chan.destroy(socket._state.rx_chan)
		return err
	}
	sync.wait_group_add(&socket._state.done, 2)
	thread.create_and_start_with_poly_data(
		socket,
		worker_sender,
		self_cleanup = true,
	)
	thread.create_and_start_with_poly_data(
		socket,
		worker_receiver,
		self_cleanup = true,
	)
	socket._state.handshaked = true

	return nil
}

@(private="file", require_results)
do_client_hello :: proc(
	socket:         ^Socket,
	buf:            ^Buffer,
	ephemeral_keys: ^Ephemeral_Keys,
	cipher_suites:  []Cipher_Suite,
	host_name:      string,
	alpn_protocols: []Alpn_Protocols,
) -> (client_random: []byte, session_id: []byte, err: Error) {
	// Size of a X25519MLKEM768 key is maximum needed for now,
	// and all values are public so there is no need to sanitize.
	scratch: [32+1184]byte = ---

	cipher_suites_u16 := slice.reinterpret([]u16, cipher_suites)

	// Outer TLSPlaintext
	//
	// RFC 9846 5.1
	//
	//   To maximize backward compatibility, a record containing an
	//   initial ClientHello SHOULD have version 0x0301 (reflecting
	//   TLS 1.0) and a record containing a second ClientHello or a
	//   ServerHello MUST have version 0x0303 (reflecting TLS 1.2).
	buffer_write_u8(buf, u8(Content_Type.Handshake)) or_return
	buffer_write_u16(buf, TLS10_PROTOCOL_VERSION) or_return
	tls_plaintext_len_off := buffer_len(buf)
	buffer_write_u16(buf, 0) or_return // Filled in later

	// ClientHello
	buffer_write_u8(buf, u8(Handshake_Type.Client_Hello)) or_return
	client_hello_len_off := buffer_len(buf)
	buffer_write_u24(buf, 0) or_return // Filled in later
	buffer_write_u16(buf, TLS12_PROTOCOL_VERSION) or_return

	r := scratch[:RANDOM_SIZE + LEGACY_SESSION_ID_SIZE] // random/session_id
	crypto.rand_bytes(r)
	client_random_off := buffer_len(buf)
	buffer_write_bytes(buf, r[:RANDOM_SIZE]) or_return // random
	session_id_off := buffer_len(buf) + 1 // Skip the length
	buffer_write_opaque_bytes(buf, r[RANDOM_SIZE:], 1) or_return // legacy_session_id
	buffer_write_opaque_u16s(buf, cipher_suites_u16, 2) or_return
	buffer_write_opaque_bytes(buf, []byte{0}, 1) or_return // legacy_compression_methods

	// ClientHello - Extensions
	extensions_len_off := buffer_len(buf)
	buffer_write_u16(buf, 0) or_return // Filled in later

	// supported_versions
	buffer_write_u16(buf, u16(Extension_Type.Supported_Versions)) or_return
	buffer_write_u16(buf, 1 + 2) or_return // Length
	buffer_write_opaque_u16s(buf, []u16{TLS13_PROTOCOL_VERSION}, 1) or_return

	// If we were to support early data/0-rtt/PSK modes etc, we would
	// need to implement:
	//
	//  - session_ticket
	//  - post_handshake_auth
	//  - psk_key_exchange_modes
	//
	// If we ever get to the point where we do NOT send a key_share for
	// every single supported group, we need to implement:
	//
	//  - cookie (Mandatory 4.3.2)
	//
	// Until then, we never will receive a cookie from the server since
	// this will only happen as part of a HelloRetryRequest, and we send
	// an exhaustive list of key_share(s), and no early data.
	//
	// Nice to haves:
	//  - record_size_limit
	//  - compress_certificate

	// server_name
	if len(host_name) != 0 {
		// SNI was well intentioned and supports multiple names, but
		// more than one is NEVER used in practice.
		buffer_write_u16(buf, u16(Extension_Type.Server_Name)) or_return
		host := transmute([]byte)host_name
		l := len(host)
		if 2 + 1 + 2 + l > int(max(u16)) {
			return nil, nil, io.Error.Short_Buffer
		}
		buffer_write_u16(buf, 2 + 1 + 2 + u16(l)) or_return
		buffer_write_u16(buf, 1 + 2 + u16(l)) or_return
		buffer_write_u8(buf, u8(Name_Type.Host_Name)) or_return
		buffer_write_opaque_bytes(buf, host, 2) or_return
	}

	// signature_algorithms
	{
		buffer_write_u16(buf, u16(Extension_Type.Signature_Algorithms)) or_return
		signature_algorithms := slice.reinterpret([]u16, SIGNATURE_SCHEMES)
		l := len(signature_algorithms) * 2
		if 2 + 2 + l > int(max(u16)) {
			return nil, nil, io.Error.Short_Buffer
		}
		buffer_write_u16(buf, 2 + u16(l)) or_return
		buffer_write_opaque_u16s(buf, signature_algorithms, 2) or_return
	}

	// supported_groups
	{
		buffer_write_u16(buf, u16(Extension_Type.Supported_Groups)) or_return
		supported_groups := slice.reinterpret([]u16, ephemeral_keys.supported_groups)
		l := len(supported_groups) * 2
		if 2 + 2 + l > int(max(u16)) {
			return nil, nil, io.Error.Short_Buffer
		}
		buffer_write_u16(buf, 2 + u16(l)) or_return
		buffer_write_opaque_u16s(buf, supported_groups, 2) or_return
	}

	// key_share (TLS 1.3)
	{
		buffer_write_u16(buf, u16(Extension_Type.Key_Share)) or_return
		ext_len_off := buffer_len(buf)
		buffer_write_u16(buf, 0) or_return // Length (fill in later)
		buffer_write_u16(buf, 0) or_return // Fill in later

		for group in ephemeral_keys.supported_groups {
			#partial switch group {
			case .X25519MLKEM768:
				buffer_write_u16(buf, u16(Named_Group.X25519MLKEM768)) or_return
				mlkem.decapsulation_key_encaps_bytes(&ephemeral_keys.pqt_x25519mlkem768_decaps, scratch[:1184])
				ecdh.private_key_public_bytes(&ephemeral_keys.pqt_x25519_priv, scratch[1184:])
				buffer_write_opaque_bytes(buf, scratch[:], 2) or_return
			case .X25519:
				buffer_write_u16(buf, u16(Named_Group.X25519)) or_return
				ecdh.private_key_public_bytes(&ephemeral_keys.x25519_priv, scratch[:32])
				buffer_write_opaque_bytes(buf, scratch[:32], 2) or_return
			case .X448:
				buffer_write_u16(buf, u16(Named_Group.X448)) or_return
				ecdh.private_key_public_bytes(&ephemeral_keys.x448_priv, scratch[:56])
				buffer_write_opaque_bytes(buf, scratch[:56], 2) or_return
			case .Secp256r1:
				buffer_write_u16(buf, u16(Named_Group.Secp256r1)) or_return
				ecdh.private_key_public_bytes(&ephemeral_keys.secp256r1_priv, scratch[:65])
				buffer_write_opaque_bytes(buf, scratch[:65], 2) or_return
			case .Secp384r1:
				buffer_write_u16(buf, u16(Named_Group.Secp384r1)) or_return
				ecdh.private_key_public_bytes(&ephemeral_keys.secp384r1_priv, scratch[:97])
				buffer_write_opaque_bytes(buf, scratch[:97], 2) or_return
			}
		}

		// Fill in the lengths
		off := buffer_len(buf)
		endian.unchecked_put_u16be(
			buffer_bytes_at(buf, ext_len_off),
			u16(off - (ext_len_off + 2)),
		)
		endian.unchecked_put_u16be(
			buffer_bytes_at(buf, ext_len_off + 2),
			u16(off - (ext_len_off + 2 + 2)),
		)
	}

	// application_layer_protocol_negotiation
	if len(alpn_protocols) != 0 {
		buffer_write_u16(buf, u16(Extension_Type.Application_Layer_Protocol_Negotiation)) or_return
		ext_len_off := buffer_len(buf)
		buffer_write_u16(buf, 0) or_return // Length (fill in later)
		buffer_write_u16(buf, 0) or_return // Fill in later

		for id in alpn_protocols {
			s := ALPN_STRINGS[id]
			if len(s) == 0 || len(s) > int(max(u8)) {
				return nil, nil, io.Error.Short_Buffer
			}
			buffer_write_opaque_bytes(buf, transmute([]byte)s, 1) or_return
		}

		// Fill in the lengths
		off := buffer_len(buf)
		endian.unchecked_put_u16be(
			buffer_bytes_at(buf, ext_len_off),
			u16(off - (ext_len_off + 2)),
		)
		endian.unchecked_put_u16be(
			buffer_bytes_at(buf, ext_len_off + 2),
			u16(off - (ext_len_off + 2 + 2)),
		)
	}

	// TLS 1.2 backward compatibility.
	{
		// renegotiation_info
		buffer_write_u16(buf, u16(Extension_Type.Renegotiaton_Info)) or_return
		buffer_write_u16(buf, 1) or_return // Length
		buffer_write_u8(buf, 0) or_return

		// ec_point_formats
		buffer_write_u16(buf, u16(Extension_Type.Ec_Point_Formats)) or_return
		buffer_write_u16(buf, 2) or_return // Length
		buffer_write_opaque_bytes(buf, []byte{0}, 1) or_return
	}

	// Fill in the length fields
	off := buffer_len(buf)
	endian.unchecked_put_u16be(
		buffer_bytes_at(buf, tls_plaintext_len_off),
		u16(off - (tls_plaintext_len_off + 2)),
	)
	endian.unchecked_put_unsigned_be(
		buffer_bytes_at(buf, client_hello_len_off),
		u64(off - (client_hello_len_off + 3)),
		24,
	)
	endian.unchecked_put_u16be(
		buffer_bytes_at(buf, extensions_len_off),
		u16(off - (extensions_len_off + 2)),
	)

	// Note: Some implementations supposedly choke on ClientHellos
	// that have a length in the range [256, 512) (RFC 7685), which
	// would require padding for compatibility.  However, this will
	// NEVER generate such a ClientHello due to the inclusion of a
	// PQ/T key share.

	buffer_send(buf, socket.fd) or_return

	return buffer_bytes_at(buf, client_random_off)[:RANDOM_SIZE], buffer_bytes_at(buf, session_id_off)[:LEGACY_SESSION_ID_SIZE], nil
}

@(private="file", require_results)
do_server_hello :: proc(
	socket:               ^Socket,
	handshake_keys:       ^Handshake_Keys,
	ephemeral_keys:       ^Ephemeral_Keys,
	running_hash:         ^hash.Context,
	client_hello:         ^Buffer,
	client_session_id:    []byte,
	client_random:        []byte,
	cipher_suites:        []Cipher_Suite,
	unsafe_secret_logger: ^os.File,
	allocator:            runtime.Allocator,
) -> (err: Error) {
	// Note: Some TLS 1.3 implementations do not bother parsing alerts
	// sent in response to a ServerHello, as they are not protected by
	// the handshake key.

	// We need an extra buffer to receive the ServerHello as we do not
	// know which hash algorithm to use for the transcript hash, and
	// the ClientHello gets hashed first.
	record_data: [TLS13_MAX_RECORD_SIZE]byte = ---
	record_buf: Buffer
	buffer_init(&record_buf, record_data[:])

	content_type: Content_Type
	if content_type, err = buffer_recv_unprotected_handshake_record(&record_buf, socket, .Server_Hello); err != nil {
		if content_type == .Alert {
			if buffer_unread_len(&record_buf) == 2 {
				return alert_to_error(
					Alert_Level(buffer_unchecked_read_u8(&record_buf)),
					Alert_Description(buffer_unchecked_read_u8(&record_buf)),
				)
			}
			return Protocol_Error.Decode_Error
		}

		buffer_send_early_alert(socket, error_to_alert(err))
		return
	}

	// Ensure we have up to the extensions length field.
	if buffer_unread_len(&record_buf) < 2 + RANDOM_SIZE + 1 + LEGACY_SESSION_ID_SIZE + 2 + 1 + 2 {
		// Send `decode_error` alert.
		buffer_send_early_alert(socket, .Decode_Error)
		return Protocol_Error.Decode_Error
	}

	// Check `protocol_version`.
	if buffer_unchecked_read_u16(&record_buf) != TLS12_PROTOCOL_VERSION {
		// Send `protocol_version` alert.
		buffer_send_early_alert(socket, .Protocol_Version)
		return Protocol_Error.Protocol_Version
	}

	// Check `random` to see if it is a HelloRetryRequest,
	// which we should never get.
	//
	// Once we support TLS 1.2, the last 8-bytes must be
	// `44 4F 57 4E 47 52 44 01`, if the server decides to negotiate
	// TLS 1.2, though this is a TLS 1.3-ism, so should NEVER happen.
	tmp: [RANDOM_SIZE]byte = ---
	buffer_unchecked_read_bytes(&record_buf, tmp[:])
	if bytes.equal(tmp[:], HELLO_RETRY_REQUEST_RANDOM) {
		// Send `unexpected_message` alert.
		buffer_send_early_alert(socket, .Unexpected_Message)
		return Protocol_Error.Unexpected_Message
	}

	// Check `legacy_session_id_echo`.
	session_id_len := buffer_unchecked_read_u8(&record_buf)
	if session_id_len != LEGACY_SESSION_ID_SIZE {
		// Send `illegal_parameter` alert.
		buffer_send_early_alert(socket, .Illegal_Parameter)
		return Protocol_Error.Illegal_Parameter
	}
	buffer_unchecked_read_bytes(&record_buf, tmp[:])
	if !bytes.equal(client_session_id, tmp[:]) {
		// Send `illegal_parameter` alert.
		buffer_send_early_alert(socket, .Illegal_Parameter)
		return Protocol_Error.Illegal_Parameter
	}

	// Parse `cipher_suite`.
	socket.cipher_suite = Cipher_Suite(buffer_unchecked_read_u16(&record_buf))
	if _, ok := slice.linear_search(cipher_suites, socket.cipher_suite); !ok {
		// Send `illegal_parameter` alert.
		buffer_send_early_alert(socket, .Illegal_Parameter)
		return Protocol_Error.Illegal_Parameter
	}
	aead_algo := CIPHER_SUITE_AEAD[socket.cipher_suite]

	// Check legacy_compression_method.
	if buffer_unchecked_read_u8(&record_buf) != 0 {
		// Send `illegal_parameter` alert.
		buffer_send_early_alert(socket, .Illegal_Parameter)
		return Protocol_Error.Illegal_Parameter
	}

	// Start up the transcript hash and key derivation.
	hash_algo := CIPHER_SUITE_HASH[socket.cipher_suite]
	hash.init(running_hash, hash_algo)
	hash.update(running_hash, buffer_bytes_at(client_hello, TLS_RECORD_HEADER_SIZE))
	hash.update(running_hash, buffer_bytes_at(&record_buf, TLS_RECORD_HEADER_SIZE))

	init_handshake_keys(handshake_keys, hash_algo)

	// Parse the extensions.
	//
	// TLS 1.3 allowed extensions:
	//  - pre_shared_key (For now send `unsupported_extension`)
	//  - supported_versions (mandatory)
	//  - key_share (mandatory)
	//
	// Send `unsupported_extension` for anything else.
	extensions_len := int(buffer_unchecked_read_u16(&record_buf))
	if buffer_unread_len(&record_buf) != extensions_len {
		buffer_send_early_alert(socket, .Decode_Error)
		return Protocol_Error.Decode_Error
	}

	got_version, got_key_share: bool
	named_group: Named_Group
	key_share_bytes: []byte
	is_tls13: bool
extension_loop:
	for l := buffer_unread_len(&record_buf); l >= 4; l = buffer_unread_len(&record_buf) {
		// None of the buffer_read calls here can fail because we
		// at least have the extension type/length, and explicitly
		// check the data length.
		extension_type := Extension_Type(buffer_unchecked_read_u16(&record_buf))
		extension_data: []byte
		if extension_data, err = buffer_read_opaque_bytes(&record_buf, 2); err != nil {
			buffer_send_early_alert(socket, .Decode_Error)
			return Protocol_Error.Decode_Error
		}

		// Now we work off extension_data, so we can send alerts.
		#partial switch extension_type {
		case .Supported_Versions:
			if got_version {
				buffer_send_early_alert(socket, .Illegal_Parameter)
				return Protocol_Error.Illegal_Parameter
			}
			got_version = true

			if len(extension_data) != 2 {
				buffer_send_early_alert(socket, .Decode_Error)
				return Protocol_Error.Decode_Error
			}
			is_tls13 = endian.unchecked_get_u16be(extension_data) == TLS13_PROTOCOL_VERSION
		case .Key_Share:
			if got_key_share {
				buffer_send_early_alert(socket, .Illegal_Parameter)
				return Protocol_Error.Illegal_Parameter
			}
			got_key_share = true

			if len(extension_data) < 4 {
				buffer_send_early_alert(socket, .Decode_Error)
				return Protocol_Error.Decode_Error
			}
			named_group = Named_Group(endian.unchecked_get_u16be(extension_data))
			kex_len := int(endian.unchecked_get_u16be(extension_data[2:]))
			key_share_bytes = extension_data[4:]
			if kex_len != len(key_share_bytes) {
				buffer_send_early_alert(socket, .Decode_Error)
				return Protocol_Error.Decode_Error
			}
		case .Pre_Shared_Key:
			// Unsupported for now, and we treat as an error because
			// we do not negotiate for it.
			fallthrough
		case:
			buffer_send_early_alert(socket, .Unsupported_Extension)
			return Protocol_Error.Unsupported_Extension
		}
	}

	// Send alerts:
	//  - `illegal_parameter` if not TLS 1.3.
	//  - `missing_extension` if no `key_share`.
	//  - `decode_error` for trailing garbage.
	if !is_tls13 {
		buffer_send_early_alert(socket, .Illegal_Parameter)
		return Protocol_Error.Illegal_Parameter
	}
	if !got_key_share {
		buffer_send_early_alert(socket, .Missing_Extension)
		return Protocol_Error.Missing_Extension
	}
	if buffer_unread_len(&record_buf) != 0 {
		buffer_send_early_alert(socket, .Decode_Error)
		return Protocol_Error.Decode_Error
	}

	// Key schedule:
	//  - Do the DH, update the handshake_secret.
	//  - Compute the current transcript hash.
	//  - Derive the handshake_traffic_secrets.
	//  - Derive the AEAD keys/IVs.
	if !update_handshake_keys_ephemeral(handshake_keys, ephemeral_keys, named_group, key_share_bytes) {
		buffer_send_early_alert(socket, .General_Error)
		return Protocol_Error.General_Error
	}
	clear_ephemeral_keys(ephemeral_keys)

	init_connection_secrets(&socket._state.secrets, handshake_keys, running_hash, aead_algo, true, allocator, client_random, unsafe_secret_logger)

	return
}

@(private="file", require_results)
do_certificate_request :: proc(
	socket:             ^Socket,
	buf:                ^Buffer,
	record_buf:         ^Buffer,
) -> (ctx: []byte, err: Error) {
	ctx = buffer_read_opaque_bytes(buf, 1) or_return

	// Parse extensions.
	extensions_len := int(buffer_read_u16(buf) or_return)
	if buffer_unread_len(buf) != extensions_len {
		buffer_send_alert(record_buf, socket, .Decode_Error)
		return nil, Protocol_Error.Decode_Error
	}

	// TLS 1.3 allowed extensions:
	//  - signature_algorithms (mandatory)
	//  - status_request
	//  - compress_certificate
	//  - delegated_credential
	//  - certificate_authorities
	//  - oid_filters
	//  - signature_algorithms_cert
	//  - transparancy_info
	//
	// TODO: Enforce that there is at most one of each of the
	// ignored extensions.
	got_signature_algorithms: bool
	got_duplicate_unsupported: bool
	unsupported_extensions: bit_set[0..<7]
extension_loop:
	for l := buffer_unread_len(buf); l >= 4; l = buffer_unread_len(buf) {
		// None of the buffer_read calls here can fail because we
		// at least have the extension type/length, and explicitly
		// check the data length.
		extension_type := Extension_Type(buffer_unchecked_read_u16(buf))
		extension_data := buffer_read_opaque_bytes(buf, 2) or_return
		extension_len := len(extension_data)

		if CERTIFICATE_FORBIDDEN_EXTENSIONS[extension_type] {
			buffer_send_alert(record_buf, socket, .Unsupported_Extension)
			return nil, Protocol_Error.Unsupported_Extension
		}

		// Now we work off extension_data, so we can send alerts.
		#partial switch extension_type {
		case .Signature_Algorithms:
			if got_signature_algorithms {
				got_signature_algorithms = false
				break extension_loop
			}
			got_signature_algorithms = true
			if extension_len % 2 != 0 || extension_len < 4 {
				buffer_send_alert(record_buf, socket, .Decode_Error)
				return nil, Protocol_Error.Decode_Error
			}
			if int(endian.unchecked_get_u16be(extension_data)) != extension_len - 2 {
				buffer_send_alert(record_buf, socket, .Decode_Error)
				return nil, Protocol_Error.Decode_Error
			}
			// TODO: When we actually support client certificate auth,
			// save the supported signature algorithms.
		case .Status_Request:
			if 0 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {0}
		case .Compress_Certificate:
			if 1 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {1}
		case .Delegated_Credential:
			if 2 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {2}
		case .Certificate_Authorities:
			if 3 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {3}
		case .Oid_Filters:
			if 4 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {4}
		case .Signature_Algorithms_Cert:
			if 5 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {5}
		case .Transparency_Info:
			if 6 in unsupported_extensions {
				got_duplicate_unsupported = true
				break extension_loop
			}
			unsupported_extensions += {6}
		case:
			// Ignore unsupported extensions.
		}
	}
	if !got_signature_algorithms {
		buffer_send_alert(record_buf, socket, .Missing_Extension)
		return nil, Protocol_Error.Missing_Extension
	}
	if got_duplicate_unsupported {
		buffer_send_alert(record_buf, socket, .Illegal_Parameter)
		return nil, Protocol_Error.Illegal_Parameter
	}
	if buffer_unread_len(buf) != 0 {
		buffer_send_alert(record_buf, socket, .Decode_Error)
		return nil, Protocol_Error.Decode_Error
	}

	return
}

@(private="file", require_results)
do_certificate :: proc(
	socket:             ^Socket,
	buf:                ^Buffer,
	record_buf:         ^Buffer,
	host_name:          string,
	trust_roots:        []^x509.Certificate,
	unsafe_skip_verify: bool,
	allocator:          runtime.Allocator,
) -> (leaf: x509.Certificate, leaf_data: []byte, err: Error) {
	// `certificate_request_context`
	if (buffer_read_u8(buf) or_return) != 0 {
		buffer_send_alert(record_buf, socket, .Illegal_Parameter)
		return {}, nil, Protocol_Error.Illegal_Parameter
	}

	certificates_len := buffer_read_u24(buf) or_return
	if certificates_len != buffer_unread_len(buf) {
		return {}, nil, io.Error.Unexpected_EOF
	}

	free_chain := proc(
		chain:     [dynamic]^x509.Certificate,
		allocator: runtime.Allocator,
	) {
		for cert in chain {
			x509.destroy(cert, allocator)
			free(cert, allocator)
		}
		delete(chain)
	}
	cert_chain := make([dynamic]^x509.Certificate, allocator)
	defer free_chain(cert_chain, allocator)

	// Parse the certificates.
	n: int
	for buffer_unread_len(buf) > 0 {
		cert_der := buffer_read_opaque_bytes(buf, 3) or_return
		ext_len := buffer_read_u16(buf) or_return
		if ext_len != 0 { // We negotiate no extensions.
			buffer_send_alert(record_buf, socket, .Illegal_Parameter)
			return leaf, leaf_data, Protocol_Error.Illegal_Parameter
		}

		cert_err: x509.Error
		switch n {
		case 0:
			// We clone the certificate DER because the Certificate
			// relies on the raw DER out-living it, and we need it
			// later for CertificateVerify.
			leaf_data = bytes.clone_safe(cert_der, allocator) or_return
			leaf, cert_err = x509.parse(leaf_data, allocator)
		case:
			cert := new(x509.Certificate) or_return
			cert^, cert_err = x509.parse(cert_der, allocator)
			if cert_err == nil {
				append(&cert_chain, cert) or_return
			}
		}
		if cert_err != nil {
			buffer_send_alert(record_buf, socket, .Bad_Certificate)
			return leaf, leaf_data, Protocol_Error.Bad_Certificate
		}

		n += 1
	}
	if n == 0 {
		// No certificates were found.
		buffer_send_alert(record_buf, socket, .Illegal_Parameter)
		return leaf, leaf_data, Protocol_Error.Illegal_Parameter
	}

	if unsafe_skip_verify {
		return
	}

	// Validate the cert chain.
	verify_opts := x509.Verify_Options{
		roots         = trust_roots,
		intermediates = cert_chain[:],
		current_time  = time.now(),
		dns_name      = host_name,
		required_eku  = .Server_Auth,
	}

	verified_chain, cert_err := x509.verify_chain(&leaf, verify_opts, allocator)
	if cert_err != nil {
		alert: Alert_Description
		#partial switch cert_err {
		case .Signature_Invalid, .Unsupported_Algorithm, .Not_Yet_Valid, .Expired:
			alert = .Certificate_Expired
		case .Unknown_Authority:
			alert = .Unknown_Ca
		case .Unhandled_Critical_Extension, .Incompatible_Usage:
			alert = .Certificate_Unknown
		case:
			alert = .Bad_Certificate
		}

		buffer_send_alert(record_buf, socket, alert)
		return leaf, leaf_data, alert_to_error(.Fatal, alert)
	}
	delete(verified_chain, allocator)

	return
}
