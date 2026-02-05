// Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
// Copyright 2005 Nokia. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package bifrost_tls_bindings
foreign import lib {
	LIBSSL_PATH,
	LIBCRYPTO_PATH,
	"system:stdc++",
	"system:gcc_s",
}

import "core:c"


// Intentionally empty. Linking is handled in link.odin to avoid duplicate
// declarations across generated binding files.


// Forward-declare struct timeval. On Windows, it is defined in winsock2.h and
// Windows headers define too many macros to be included in public headers.
// However, only a forward declaration is needed.
timeval :: struct {
	// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
	// Copyright 2005 Nokia. All rights reserved.
	//
	// Licensed under the Apache License, Version 2.0 (the "License");
	tv_sec: __time_t,

	// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
	// Copyright 2005 Nokia. All rights reserved.
	//
	// Licensed under the Apache License, Version 2.0 (the "License");
	// you may not use this file except in compliance with the License.
	tv_usec: __suseconds_t,
}

@(default_calling_convention="c")
foreign lib {
	// TLS_method is the |SSL_METHOD| used for TLS connections.
	TLS_method :: proc() -> ^SSL_METHOD ---

	// DTLS_method is the |SSL_METHOD| used for DTLS connections.
	DTLS_method :: proc() -> ^SSL_METHOD ---

	// TLS_with_buffers_method is like |TLS_method|, but avoids all use of
	// crypto/x509. All client connections created with |TLS_with_buffers_method|
	// will fail unless a certificate verifier is installed with
	// |SSL_set_custom_verify| or |SSL_CTX_set_custom_verify|.
	TLS_with_buffers_method :: proc() -> ^SSL_METHOD ---

	// DTLS_with_buffers_method is like |DTLS_method|, but avoids all use of
	// crypto/x509.
	DTLS_with_buffers_method :: proc() -> ^SSL_METHOD ---

	// SSL_CTX_new returns a newly-allocated |SSL_CTX| with default settings or NULL
	// on error.
	SSL_CTX_new :: proc(method: ^SSL_METHOD) -> ^SSL_CTX ---

	// SSL_CTX_up_ref increments the reference count of |ctx|. It returns one.
	SSL_CTX_up_ref :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_free releases memory associated with |ctx|.
	SSL_CTX_free :: proc(ctx: ^SSL_CTX) ---

	// SSL_new returns a newly-allocated |SSL| using |ctx| or NULL on error. The new
	// connection inherits settings from |ctx| at the time of creation. Settings may
	// also be individually configured on the connection.
	//
	// On creation, an |SSL| is not configured to be either a client or server. Call
	// |SSL_set_connect_state| or |SSL_set_accept_state| to set this.
	SSL_new :: proc(ctx: ^SSL_CTX) -> ^SSL ---

	// SSL_free releases memory associated with |ssl|.
	SSL_free :: proc(ssl: ^SSL) ---

	// SSL_get_SSL_CTX returns the |SSL_CTX| associated with |ssl|. If
	// |SSL_set_SSL_CTX| is called, it returns the new |SSL_CTX|, not the initial
	// one.
	SSL_get_SSL_CTX :: proc(ssl: ^SSL) -> ^SSL_CTX ---

	// SSL_set_connect_state configures |ssl| to be a client.
	SSL_set_connect_state :: proc(ssl: ^SSL) ---

	// SSL_set_accept_state configures |ssl| to be a server.
	SSL_set_accept_state :: proc(ssl: ^SSL) ---

	// SSL_is_server returns one if |ssl| is configured as a server and zero
	// otherwise.
	SSL_is_server :: proc(ssl: ^SSL) -> i32 ---

	// SSL_is_dtls returns one if |ssl| is a DTLS connection and zero otherwise.
	SSL_is_dtls :: proc(ssl: ^SSL) -> i32 ---

	// SSL_is_quic returns one if |ssl| is a QUIC connection and zero otherwise.
	SSL_is_quic :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_bio configures |ssl| to read from |rbio| and write to |wbio|. |ssl|
	// takes ownership of the two |BIO|s. If |rbio| and |wbio| are the same, |ssl|
	// only takes ownership of one reference. See |SSL_set0_rbio| and
	// |SSL_set0_wbio| for requirements on |rbio| and |wbio|, respectively.
	//
	// If |rbio| is the same as the currently configured |BIO| for reading, that
	// side is left untouched and is not freed.
	//
	// If |wbio| is the same as the currently configured |BIO| for writing AND |ssl|
	// is not currently configured to read from and write to the same |BIO|, that
	// side is left untouched and is not freed. This asymmetry is present for
	// historical reasons.
	//
	// Due to the very complex historical behavior of this function, calling this
	// function if |ssl| already has |BIO|s configured is deprecated. Prefer
	// |SSL_set0_rbio| and |SSL_set0_wbio| instead.
	SSL_set_bio :: proc(ssl: ^SSL, rbio: ^BIO, wbio: ^BIO) ---

	// SSL_set0_rbio configures |ssl| to read from |rbio|. It takes ownership of
	// |rbio|. |rbio| may be a custom |BIO|, in which case it must implement
	// |BIO_read| with |BIO_meth_set_read|. In DTLS, |rbio| must be non-blocking to
	// properly handle timeouts and retransmits.
	//
	// Note that, although this function and |SSL_set0_wbio| may be called on the
	// same |BIO|, each call takes a reference. Use |BIO_up_ref| to balance this.
	SSL_set0_rbio :: proc(ssl: ^SSL, rbio: ^BIO) ---

	// SSL_set0_wbio configures |ssl| to write to |wbio|. It takes ownership of
	// |wbio|. |wbio| may be a custom |BIO|, in which case it must implement
	// |BIO_write| with |BIO_meth_set_write|. It must additionally implement
	// |BIO_flush| with |BIO_meth_set_ctrl| and |BIO_CTRL_FLUSH|. If flushing is
	// unnecessary with |wbio|, |BIO_flush| should return one and do nothing.
	//
	// Note that, although this function and |SSL_set0_rbio| may be called on the
	// same |BIO|, each call takes a reference. Use |BIO_up_ref| to balance this.
	SSL_set0_wbio :: proc(ssl: ^SSL, wbio: ^BIO) ---

	// SSL_get_rbio returns the |BIO| that |ssl| reads from.
	SSL_get_rbio :: proc(ssl: ^SSL) -> ^BIO ---

	// SSL_get_wbio returns the |BIO| that |ssl| writes to.
	SSL_get_wbio :: proc(ssl: ^SSL) -> ^BIO ---

	// SSL_get_fd calls |SSL_get_rfd|.
	SSL_get_fd :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_rfd returns the file descriptor that |ssl| is configured to read
	// from. If |ssl|'s read |BIO| is not configured or doesn't wrap a file
	// descriptor then it returns -1.
	//
	// Note: On Windows, this may return either a file descriptor or a socket (cast
	// to int), depending on whether |ssl| was configured with a file descriptor or
	// socket |BIO|.
	SSL_get_rfd :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_wfd returns the file descriptor that |ssl| is configured to write
	// to. If |ssl|'s write |BIO| is not configured or doesn't wrap a file
	// descriptor then it returns -1.
	//
	// Note: On Windows, this may return either a file descriptor or a socket (cast
	// to int), depending on whether |ssl| was configured with a file descriptor or
	// socket |BIO|.
	SSL_get_wfd :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_fd configures |ssl| to read from and write to |fd|. It returns one
	// on success and zero on allocation error. The caller retains ownership of
	// |fd|.
	//
	// On Windows, |fd| is cast to a |SOCKET| and used with Winsock APIs.
	SSL_set_fd :: proc(ssl: ^SSL, fd: i32) -> i32 ---

	// SSL_set_rfd configures |ssl| to read from |fd|. It returns one on success and
	// zero on allocation error. The caller retains ownership of |fd|.
	//
	// On Windows, |fd| is cast to a |SOCKET| and used with Winsock APIs.
	SSL_set_rfd :: proc(ssl: ^SSL, fd: i32) -> i32 ---

	// SSL_set_wfd configures |ssl| to write to |fd|. It returns one on success and
	// zero on allocation error. The caller retains ownership of |fd|.
	//
	// On Windows, |fd| is cast to a |SOCKET| and used with Winsock APIs.
	SSL_set_wfd :: proc(ssl: ^SSL, fd: i32) -> i32 ---

	// SSL_do_handshake continues the current handshake. If there is none or the
	// handshake has completed or False Started, it returns one. Otherwise, it
	// returns <= 0. The caller should pass the value into |SSL_get_error| to
	// determine how to proceed.
	//
	// In DTLS, the caller must drive retransmissions and timeouts. After calling
	// this function, the caller must use |DTLSv1_get_timeout| to determine the
	// current timeout, if any. If it expires before the application next calls into
	// |ssl|, call |DTLSv1_handle_timeout|. Note that DTLS handshake retransmissions
	// use fresh sequence numbers, so it is not sufficient to replay packets at the
	// transport.
	//
	// After the DTLS handshake, some retransmissions may remain. If |ssl| wrote
	// last in the handshake, it may need to retransmit the final flight in case of
	// packet loss. Additionally, in DTLS 1.3, it may need to retransmit
	// post-handshake messages. To handle these, the caller must always be prepared
	// to receive packets and process them with |SSL_read|, even when the
	// application protocol would otherwise not read from the connection.
	//
	// TODO(davidben): Ensure 0 is only returned on transport EOF.
	// https://crbug.com/466303.
	SSL_do_handshake :: proc(ssl: ^SSL) -> i32 ---

	// SSL_connect configures |ssl| as a client, if unconfigured, and calls
	// |SSL_do_handshake|.
	SSL_connect :: proc(ssl: ^SSL) -> i32 ---

	// SSL_accept configures |ssl| as a server, if unconfigured, and calls
	// |SSL_do_handshake|.
	SSL_accept :: proc(ssl: ^SSL) -> i32 ---

	// SSL_read reads up to |num| bytes from |ssl| into |buf|. It implicitly runs
	// any pending handshakes, including renegotiations when enabled. On success, it
	// returns the number of bytes read. Otherwise, it returns <= 0. The caller
	// should pass the value into |SSL_get_error| to determine how to proceed.
	//
	// In DTLS 1.3, the caller must also drive timeouts from retransmitting the
	// final flight of the handshake, as well as post-handshake messages. After
	// calling this function, the caller must use |DTLSv1_get_timeout| to determine
	// the current timeout, if any. If it expires before the application next calls
	// into |ssl|, call |DTLSv1_handle_timeout|.
	//
	// TODO(davidben): Ensure 0 is only returned on transport EOF.
	// https://crbug.com/466303.
	SSL_read :: proc(ssl: ^SSL, buf: rawptr, num: i32) -> i32 ---

	// SSL_peek behaves like |SSL_read| but does not consume any bytes returned.
	SSL_peek :: proc(ssl: ^SSL, buf: rawptr, num: i32) -> i32 ---

	// SSL_pending returns the number of buffered, decrypted bytes available for
	// read in |ssl|. It does not read from the transport.
	//
	// In DTLS, it is possible for this function to return zero while there is
	// buffered, undecrypted data from the transport in |ssl|. For example,
	// |SSL_read| may read a datagram with two records, decrypt the first, and leave
	// the second buffered for a subsequent call to |SSL_read|. Callers that wish to
	// detect this case can use |SSL_has_pending|.
	SSL_pending :: proc(ssl: ^SSL) -> i32 ---

	// SSL_has_pending returns one if |ssl| has buffered, decrypted bytes available
	// for read, or if |ssl| has buffered data from the transport that has not yet
	// been decrypted. If |ssl| has neither, this function returns zero.
	//
	// In TLS, BoringSSL does not implement read-ahead, so this function returns one
	// if and only if |SSL_pending| would return a non-zero value. In DTLS, it is
	// possible for this function to return one while |SSL_pending| returns zero.
	// For example, |SSL_read| may read a datagram with two records, decrypt the
	// first, and leave the second buffered for a subsequent call to |SSL_read|.
	//
	// As a result, if this function returns one, the next call to |SSL_read| may
	// still fail, read from the transport, or both. The buffered, undecrypted data
	// may be invalid or incomplete.
	SSL_has_pending :: proc(ssl: ^SSL) -> i32 ---

	// SSL_write writes up to |num| bytes from |buf| into |ssl|. It implicitly runs
	// any pending handshakes, including renegotiations when enabled. On success, it
	// returns the number of bytes written. Otherwise, it returns <= 0. The caller
	// should pass the value into |SSL_get_error| to determine how to proceed.
	//
	// In TLS, a non-blocking |SSL_write| differs from non-blocking |write| in that
	// a failed |SSL_write| still commits to the data passed in. When retrying, the
	// caller must supply the original write buffer (or a larger one containing the
	// original as a prefix). By default, retries will fail if they also do not
	// reuse the same |buf| pointer. This may be relaxed with
	// |SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER|, but the buffer contents still must be
	// unchanged.
	//
	// By default, in TLS, |SSL_write| will not return success until all |num| bytes
	// are written. This may be relaxed with |SSL_MODE_ENABLE_PARTIAL_WRITE|. It
	// allows |SSL_write| to complete with a partial result when only part of the
	// input was written in a single record.
	//
	// In DTLS, neither |SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER| and
	// |SSL_MODE_ENABLE_PARTIAL_WRITE| do anything. The caller may retry with a
	// different buffer freely. A single call to |SSL_write| only ever writes a
	// single record in a single packet, so |num| must be at most
	// |SSL3_RT_MAX_PLAIN_LENGTH|.
	//
	// TODO(davidben): Ensure 0 is only returned on transport EOF.
	// https://crbug.com/466303.
	SSL_write :: proc(ssl: ^SSL, buf: rawptr, num: i32) -> i32 ---
}

// SSL_KEY_UPDATE_REQUESTED indicates that the peer should reply to a KeyUpdate
// message with its own, thus updating traffic secrets for both directions on
// the connection.
SSL_KEY_UPDATE_REQUESTED :: 1

// SSL_KEY_UPDATE_NOT_REQUESTED indicates that the peer should not reply with
// it's own KeyUpdate message.
SSL_KEY_UPDATE_NOT_REQUESTED :: 0

@(default_calling_convention="c")
foreign lib {
	// SSL_key_update queues a TLS 1.3 KeyUpdate message to be sent on |ssl|
	// if one is not already queued. The |request_type| argument must one of the
	// |SSL_KEY_UPDATE_*| values. This function requires that |ssl| have completed a
	// TLS >= 1.3 handshake. It returns one on success or zero on error.
	//
	// Note that this function does not _send_ the message itself. The next call to
	// |SSL_write| will cause the message to be sent. |SSL_write| may be called with
	// a zero length to flush a KeyUpdate message when no application data is
	// pending.
	SSL_key_update :: proc(ssl: ^SSL, request_type: i32) -> i32 ---

	// SSL_shutdown shuts down |ssl|. It runs in two stages. First, it sends
	// close_notify and returns zero or one on success or -1 on failure. Zero
	// indicates that close_notify was sent, but not received, and one additionally
	// indicates that the peer's close_notify had already been received.
	//
	// To then wait for the peer's close_notify, run |SSL_shutdown| to completion a
	// second time. This returns 1 on success and -1 on failure. Application data
	// is considered a fatal error at this point. To process or discard it, read
	// until close_notify with |SSL_read| instead.
	//
	// In both cases, on failure, pass the return value into |SSL_get_error| to
	// determine how to proceed.
	//
	// Most callers should stop at the first stage. Reading for close_notify is
	// primarily used for uncommon protocols where the underlying transport is
	// reused after TLS completes. Additionally, DTLS uses an unordered transport
	// and is unordered, so the second stage is a no-op in DTLS.
	SSL_shutdown :: proc(ssl: ^SSL) -> i32 ---

	// SSL_CTX_set_quiet_shutdown sets quiet shutdown on |ctx| to |mode|. If
	// enabled, |SSL_shutdown| will not send a close_notify alert or wait for one
	// from the peer. It will instead synchronously return one.
	SSL_CTX_set_quiet_shutdown :: proc(ctx: ^SSL_CTX, mode: i32) ---

	// SSL_CTX_get_quiet_shutdown returns whether quiet shutdown is enabled for
	// |ctx|.
	SSL_CTX_get_quiet_shutdown :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_set_quiet_shutdown sets quiet shutdown on |ssl| to |mode|. If enabled,
	// |SSL_shutdown| will not send a close_notify alert or wait for one from the
	// peer. It will instead synchronously return one.
	SSL_set_quiet_shutdown :: proc(ssl: ^SSL, mode: i32) ---

	// SSL_get_quiet_shutdown returns whether quiet shutdown is enabled for
	// |ssl|.
	SSL_get_quiet_shutdown :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_error returns a |SSL_ERROR_*| value for the most recent operation on
	// |ssl|. It should be called after an operation failed to determine whether the
	// error was fatal and, if not, when to retry.
	SSL_get_error :: proc(ssl: ^SSL, ret_code: i32) -> i32 ---
}

// SSL_ERROR_NONE indicates the operation succeeded.
SSL_ERROR_NONE :: 0

// SSL_ERROR_SSL indicates the operation failed within the library. The caller
// may inspect the error queue (see |ERR_get_error|) for more information.
SSL_ERROR_SSL :: 1

// SSL_ERROR_WANT_READ indicates the operation failed attempting to read from
// the transport. The caller may retry the operation when the transport is ready
// for reading.
SSL_ERROR_WANT_READ :: 2

// SSL_ERROR_WANT_WRITE indicates the operation failed attempting to write to
// the transport. The caller may retry the operation when the transport is ready
// for writing.
SSL_ERROR_WANT_WRITE :: 3

// SSL_ERROR_WANT_X509_LOOKUP indicates the operation failed in calling the
// |cert_cb| or |client_cert_cb|. The caller may retry the operation when the
// callback is ready to return a certificate or one has been configured
// externally.
//
// See also |SSL_CTX_set_cert_cb| and |SSL_CTX_set_client_cert_cb|.
SSL_ERROR_WANT_X509_LOOKUP :: 4

// SSL_ERROR_SYSCALL indicates the operation failed externally to the library.
// The caller should consult the system-specific error mechanism. This is
// typically |errno| but may be something custom if using a custom |BIO|. It
// may also be signaled if the transport returned EOF, in which case the
// operation's return value will be zero.
SSL_ERROR_SYSCALL :: 5

// SSL_ERROR_ZERO_RETURN indicates the operation failed because the connection
// was cleanly shut down with a close_notify alert.
SSL_ERROR_ZERO_RETURN :: 6

// SSL_ERROR_WANT_CONNECT indicates the operation failed attempting to connect
// the transport (the |BIO| signaled |BIO_RR_CONNECT|). The caller may retry the
// operation when the transport is ready.
SSL_ERROR_WANT_CONNECT :: 7

// SSL_ERROR_WANT_ACCEPT indicates the operation failed attempting to accept a
// connection from the transport (the |BIO| signaled |BIO_RR_ACCEPT|). The
// caller may retry the operation when the transport is ready.
//
// TODO(davidben): Remove this. It's used by accept BIOs which are bizarre.
SSL_ERROR_WANT_ACCEPT :: 8

// SSL_ERROR_WANT_CHANNEL_ID_LOOKUP is never used.
//
// TODO(davidben): Remove this. Some callers reference it when stringifying
// errors. They should use |SSL_error_description| instead.
SSL_ERROR_WANT_CHANNEL_ID_LOOKUP :: 9

// SSL_ERROR_PENDING_SESSION indicates the operation failed because the session
// lookup callback indicated the session was unavailable. The caller may retry
// the operation when lookup has completed.
//
// See also |SSL_CTX_sess_set_get_cb| and |SSL_magic_pending_session_ptr|.
SSL_ERROR_PENDING_SESSION :: 11

// SSL_ERROR_PENDING_CERTIFICATE indicates the operation failed because the
// early callback indicated certificate lookup was incomplete. The caller may
// retry the operation when lookup has completed.
//
// See also |SSL_CTX_set_select_certificate_cb|.
SSL_ERROR_PENDING_CERTIFICATE :: 12

// SSL_ERROR_WANT_PRIVATE_KEY_OPERATION indicates the operation failed because
// a private key operation was unfinished. The caller may retry the operation
// when the private key operation is complete.
//
// See also |SSL_set_private_key_method|, |SSL_CTX_set_private_key_method|, and
// |SSL_CREDENTIAL_set_private_key_method|.
SSL_ERROR_WANT_PRIVATE_KEY_OPERATION :: 13

// SSL_ERROR_PENDING_TICKET indicates that a ticket decryption is pending. The
// caller may retry the operation when the decryption is ready.
//
// See also |SSL_CTX_set_ticket_aead_method|.
SSL_ERROR_PENDING_TICKET :: 14

// SSL_ERROR_EARLY_DATA_REJECTED indicates that early data was rejected. The
// caller should treat this as a connection failure and retry any operations
// associated with the rejected early data. |SSL_reset_early_data_reject| may be
// used to reuse the underlying connection for the retry.
SSL_ERROR_EARLY_DATA_REJECTED :: 15

// SSL_ERROR_WANT_CERTIFICATE_VERIFY indicates the operation failed because
// certificate verification was incomplete. The caller may retry the operation
// when certificate verification is complete.
//
// See also |SSL_CTX_set_custom_verify|.
SSL_ERROR_WANT_CERTIFICATE_VERIFY :: 16
SSL_ERROR_HANDOFF                 :: 17
SSL_ERROR_HANDBACK                :: 18

// SSL_ERROR_WANT_RENEGOTIATE indicates the operation is pending a response to
// a renegotiation request from the server. The caller may call
// |SSL_renegotiate| to schedule a renegotiation and retry the operation.
//
// See also |ssl_renegotiate_explicit|.
SSL_ERROR_WANT_RENEGOTIATE :: 19

// SSL_ERROR_HANDSHAKE_HINTS_READY indicates the handshake has progressed enough
// for |SSL_serialize_handshake_hints| to be called. See also
// |SSL_request_handshake_hints|.
SSL_ERROR_HANDSHAKE_HINTS_READY :: 20

@(default_calling_convention="c")
foreign lib {
	// SSL_error_description returns a string representation of |err|, where |err|
	// is one of the |SSL_ERROR_*| constants returned by |SSL_get_error|, or NULL
	// if the value is unrecognized.
	SSL_error_description :: proc(err: i32) -> cstring ---

	// DTLSv1_set_initial_timeout_duration sets the initial duration for a DTLS
	// handshake timeout.
	//
	// This duration overrides the default of 400 milliseconds, which is
	// recommendation of RFC 9147 for real-time protocols.
	//
	// If |ssl| is an open connection, this function may update currently running
	// timers and may make them expire. Callers should call
	// |DTLSv1_get_timeout| for an updated timeout and reschedule accordingly.
	DTLSv1_set_initial_timeout_duration :: proc(ssl: ^SSL, duration_ms: u32) ---
}

// Protocol versions.
DTLS1_VERSION_MAJOR :: 0xfe
SSL3_VERSION_MAJOR  :: 0x03
SSL3_VERSION        :: 0x0300
TLS1_VERSION        :: 0x0301
TLS1_1_VERSION      :: 0x0302
TLS1_2_VERSION      :: 0x0303
TLS1_3_VERSION      :: 0x0304
DTLS1_VERSION       :: 0xfeff
DTLS1_2_VERSION     :: 0xfefd
DTLS1_3_VERSION     :: 0xfefc

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_min_proto_version sets the minimum protocol version for |ctx| to
	// |version|. If |version| is zero, the default minimum version is used. It
	// returns one on success and zero if |version| is invalid.
	SSL_CTX_set_min_proto_version :: proc(ctx: ^SSL_CTX, version: u16) -> i32 ---

	// SSL_CTX_set_max_proto_version sets the maximum protocol version for |ctx| to
	// |version|. If |version| is zero, the default maximum version is used. It
	// returns one on success and zero if |version| is invalid.
	SSL_CTX_set_max_proto_version :: proc(ctx: ^SSL_CTX, version: u16) -> i32 ---

	// SSL_CTX_get_min_proto_version returns the minimum protocol version for |ctx|
	SSL_CTX_get_min_proto_version :: proc(ctx: ^SSL_CTX) -> u16 ---

	// SSL_CTX_get_max_proto_version returns the maximum protocol version for |ctx|
	SSL_CTX_get_max_proto_version :: proc(ctx: ^SSL_CTX) -> u16 ---

	// SSL_set_min_proto_version sets the minimum protocol version for |ssl| to
	// |version|. If |version| is zero, the default minimum version is used. It
	// returns one on success and zero if |version| is invalid.
	SSL_set_min_proto_version :: proc(ssl: ^SSL, version: u16) -> i32 ---

	// SSL_set_max_proto_version sets the maximum protocol version for |ssl| to
	// |version|. If |version| is zero, the default maximum version is used. It
	// returns one on success and zero if |version| is invalid.
	SSL_set_max_proto_version :: proc(ssl: ^SSL, version: u16) -> i32 ---

	// SSL_get_min_proto_version returns the minimum protocol version for |ssl|. If
	// the connection's configuration has been shed, 0 is returned.
	SSL_get_min_proto_version :: proc(ssl: ^SSL) -> u16 ---

	// SSL_get_max_proto_version returns the maximum protocol version for |ssl|. If
	// the connection's configuration has been shed, 0 is returned.
	SSL_get_max_proto_version :: proc(ssl: ^SSL) -> u16 ---

	// SSL_version returns the TLS or DTLS protocol version used by |ssl|, which is
	// one of the |*_VERSION| values. (E.g. |TLS1_2_VERSION|.) Before the version
	// is negotiated, the result is undefined.
	SSL_version :: proc(ssl: ^SSL) -> i32 ---
}

// Options.
//
// Options configure protocol behavior.

// SSL_OP_NO_QUERY_MTU, in DTLS, disables querying the MTU from the underlying
// |BIO|. Instead, the MTU is configured with |SSL_set_mtu|.
SSL_OP_NO_QUERY_MTU :: 0x00001000

// SSL_OP_NO_TICKET disables session ticket support (RFC 5077).
SSL_OP_NO_TICKET :: 0x00004000

// SSL_OP_CIPHER_SERVER_PREFERENCE configures servers to select ciphers and
// ECDHE curves according to the server's preferences instead of the
// client's.
SSL_OP_CIPHER_SERVER_PREFERENCE :: 0x00400000

// The following flags toggle individual protocol versions. This is deprecated.
// Use |SSL_CTX_set_min_proto_version| and |SSL_CTX_set_max_proto_version|
// instead.
SSL_OP_NO_TLSv1    :: 0x04000000
SSL_OP_NO_TLSv1_2  :: 0x08000000
SSL_OP_NO_TLSv1_1  :: 0x10000000
SSL_OP_NO_TLSv1_3  :: 0x20000000
SSL_OP_NO_DTLSv1   :: SSL_OP_NO_TLSv1
SSL_OP_NO_DTLSv1_2 :: SSL_OP_NO_TLSv1_2

// Modes.
//
// Modes configure API behavior.

// SSL_MODE_ENABLE_PARTIAL_WRITE, in TLS, allows |SSL_write| to complete with a
// partial result when the only part of the input was written in a single
// record. In DTLS, it does nothing.
SSL_MODE_ENABLE_PARTIAL_WRITE :: 0x00000001

// SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER, in TLS, allows retrying an incomplete
// |SSL_write| with a different buffer. However, |SSL_write| still assumes the
// buffer contents are unchanged. This is not the default to avoid the
// misconception that non-blocking |SSL_write| behaves like non-blocking
// |write|. In DTLS, it does nothing.
SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER :: 0x00000002
SSL_MODE_NO_AUTO_CHAIN              :: 0x00000008

// SSL_MODE_ENABLE_FALSE_START allows clients to send application data before
// receipt of ChangeCipherSpec and Finished. This mode enables full handshakes
// to 'complete' in one RTT. See RFC 7918.
//
// When False Start is enabled, |SSL_do_handshake| may succeed before the
// handshake has completely finished. |SSL_write| will function at this point,
// and |SSL_read| will transparently wait for the final handshake leg before
// returning application data. To determine if False Start occurred or when the
// handshake is completely finished, see |SSL_in_false_start|, |SSL_in_init|,
// and |SSL_CB_HANDSHAKE_DONE| from |SSL_CTX_set_info_callback|.
SSL_MODE_ENABLE_FALSE_START :: 0x00000080

// SSL_MODE_CBC_RECORD_SPLITTING causes multi-byte CBC records in TLS 1.0 to be
// split in two: the first record will contain a single byte and the second will
// contain the remainder. This effectively randomises the IV and prevents BEAST
// attacks.
SSL_MODE_CBC_RECORD_SPLITTING :: 0x00000100

// SSL_MODE_NO_SESSION_CREATION will cause any attempts to create a session to
// fail with SSL_R_SESSION_MAY_NOT_BE_CREATED. This can be used to enforce that
// session resumption is used for a given SSL*.
SSL_MODE_NO_SESSION_CREATION :: 0x00000200

// SSL_MODE_SEND_FALLBACK_SCSV sends TLS_FALLBACK_SCSV in the ClientHello.
// To be set only by applications that reconnect with a downgraded protocol
// version; see RFC 7507 for details.
//
// DO NOT ENABLE THIS if your application attempts a normal handshake. Only use
// this in explicit fallback retries, following the guidance in RFC 7507.
SSL_MODE_SEND_FALLBACK_SCSV :: 0x00000400

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set0_buffer_pool sets a |CRYPTO_BUFFER_POOL| that will be used to
	// store certificates. This can allow multiple connections to share
	// certificates and thus save memory.
	//
	// The SSL_CTX does not take ownership of |pool| and the caller must ensure
	// that |pool| outlives |ctx| and all objects linked to it, including |SSL|,
	// |X509| and |SSL_SESSION| objects. Basically, don't ever free |pool|.
	SSL_CTX_set0_buffer_pool :: proc(ctx: ^SSL_CTX, pool: ^CRYPTO_BUFFER_POOL) ---

	// SSL_CREDENTIAL_new_x509 returns a new, empty X.509 credential, or NULL on
	// error. Callers should release the result with |SSL_CREDENTIAL_free| when
	// done.
	//
	// Callers should configure a certificate chain and private key on the
	// credential, along with other properties, then add it with
	// |SSL_CTX_add1_credential|.
	SSL_CREDENTIAL_new_x509 :: proc() -> ^SSL_CREDENTIAL ---

	// SSL_CREDENTIAL_up_ref increments the reference count of |cred|.
	SSL_CREDENTIAL_up_ref :: proc(cred: ^SSL_CREDENTIAL) ---

	// SSL_CREDENTIAL_free decrements the reference count of |cred|. If it reaches
	// zero, all data referenced by |cred| and |cred| itself are released.
	SSL_CREDENTIAL_free :: proc(cred: ^SSL_CREDENTIAL) ---

	// SSL_CREDENTIAL_set1_private_key sets |cred|'s private key to |cred|. It
	// returns one on success and zero on failure.
	SSL_CREDENTIAL_set1_private_key :: proc(cred: ^SSL_CREDENTIAL, key: ^EVP_PKEY) -> i32 ---

	// SSL_CREDENTIAL_set1_signing_algorithm_prefs configures |cred| to use |prefs|
	// as the preference list when signing with |cred|'s private key. It returns one
	// on success and zero on error. |prefs| should not include the internal-only
	// value |SSL_SIGN_RSA_PKCS1_MD5_SHA1|.
	//
	// It is an error to call this function with delegated credentials (see
	// |SSL_CREDENTIAL_new_delegated|) because delegated credentials already
	// constrain the key to a single algorithm.
	SSL_CREDENTIAL_set1_signing_algorithm_prefs :: proc(cred: ^SSL_CREDENTIAL, prefs: ^u16, num_prefs: c.size_t) -> i32 ---

	// SSL_CREDENTIAL_set1_cert_chain sets |cred|'s certificate chain, starting from
	// the leaf, to |num_cert|s certificates from |certs|. It returns one on success
	// and zero on error.
	SSL_CREDENTIAL_set1_cert_chain :: proc(cred: ^SSL_CREDENTIAL, certs: ^^CRYPTO_BUFFER, num_certs: c.size_t) -> i32 ---

	// SSL_CREDENTIAL_set1_ocsp_response sets |cred|'s stapled OCSP response to
	// |ocsp|. It returns one on success and zero on error.
	SSL_CREDENTIAL_set1_ocsp_response :: proc(cred: ^SSL_CREDENTIAL, ocsp: ^CRYPTO_BUFFER) -> i32 ---

	// SSL_CREDENTIAL_set1_certificate_properties parses
	// |certificate_property_list| as a CertificatePropertyList (see Section 6 of
	// draft-ietf-tls-trust-anchor-ids-00) and applies recognized properties to
	// |cred|. It returns one on success and zero on error. It is an error if
	// |certificate_property_list| does not parse correctly, or if any recognized
	// properties from |certificate_property_list| cannot be applied to |cred|.
	//
	// CertificatePropertyList is an extensible structure which allows serving
	// properties of a certificate chain to be passed from a CA, through an
	// application's issuance and configuration pipeline, and to the TLS serving
	// logic, without requiring application changes for each property defined.
	//
	// BoringSSL currently supports the following properties:
	// * trust_anchor_identifier (see |SSL_CREDENTIAL_set1_trust_anchor_id|)
	//
	// Note this function does not automatically enable issuer matching. Callers
	// must separately call |SSL_CREDENTIAL_set_must_match_issuer| if desired.
	SSL_CREDENTIAL_set1_certificate_properties :: proc(cred: ^SSL_CREDENTIAL, cert_property_list: ^CRYPTO_BUFFER) -> i32 ---

	// SSL_CREDENTIAL_set1_signed_cert_timestamp_list sets |cred|'s list of signed
	// certificate timestamps |sct_list|. |sct_list| must contain one or more SCT
	// structures serialised as a SignedCertificateTimestampList (see
	// https://tools.ietf.org/html/rfc6962#section-3.3) – i.e. each SCT is prefixed
	// by a big-endian, uint16 length and the concatenation of one or more such
	// prefixed SCTs are themselves also prefixed by a uint16 length. It returns one
	// on success and zero on error.
	SSL_CREDENTIAL_set1_signed_cert_timestamp_list :: proc(cred: ^SSL_CREDENTIAL, sct_list: ^CRYPTO_BUFFER) -> i32 ---

	// SSL_CREDENTIAL_set_must_match_issuer configures whether |cred| should check
	// if the peer supports the certificate chain's issuer.
	//
	// If |match| is non-zero, |cred| will only be applicable when the certificate
	// chain is issued by some CA requested by the peer in the
	// certificate_authorities extension or, if |cred| has a trust anchor ID (see
	// |SSL_CREDENTIAL_set1_trust_anchor_id|), the trust_anchors extension. |cred|'s
	// certificate chain must then be a correctly ordered certification path.
	//
	// If |match| is zero (default), |cred| will not be conditioned on the peer's
	// requested CAs. This can be used for certificate chains that are assumed to be
	// usable by most peers.
	//
	// This setting can be used for certificate chains that may not be usable by all
	// peers, e.g. chains with fewer cross-signs or issued from a newer CA. The
	// credential list is tried in order, so more specific credentials that enable
	// issuer matching should generally be ordered before less specific credentials
	// that do not.
	SSL_CREDENTIAL_set_must_match_issuer :: proc(cred: ^SSL_CREDENTIAL, match: i32) ---

	// SSL_CTX_add1_credential appends |cred| to |ctx|'s credential list. It returns
	// one on success and zero on error. The credential list is maintained in order
	// of decreasing preference, so earlier calls are preferred over later calls.
	//
	// After calling this function, it is an error to modify |cred|. Doing so may
	// result in inconsistent handshake behavior or race conditions.
	SSL_CTX_add1_credential :: proc(ctx: ^SSL_CTX, cred: ^SSL_CREDENTIAL) -> i32 ---

	// SSL_add1_credential appends |cred| to |ssl|'s credential list. It returns one
	// on success and zero on error. The credential list is maintained in order of
	// decreasing preference, so earlier calls are preferred over later calls.
	//
	// After calling this function, it is an error to modify |cred|. Doing so may
	// result in inconsistent handshake behavior or race conditions.
	SSL_add1_credential :: proc(ssl: ^SSL, cred: ^SSL_CREDENTIAL) -> i32 ---

	// SSL_certs_clear removes all credentials configured on |ssl|. It also removes
	// the certificate chain and private key on the legacy credential.
	SSL_certs_clear :: proc(ssl: ^SSL) ---

	// SSL_get0_selected_credential returns the credential in use in the current
	// handshake on |ssl|. If there is current handshake on |ssl| or if the
	// handshake has not progressed to this point, it returns NULL.
	//
	// This function is intended for use with |SSL_CREDENTIAL_get_ex_data|. It may
	// be called from handshake callbacks, such as those in
	// |SSL_PRIVATE_KEY_METHOD|, to trigger credential-specific behavior.
	//
	// In applications that use the older APIs, such as |SSL_use_certificate|, this
	// function may return an internal |SSL_CREDENTIAL| object. This internal object
	// will have no ex_data installed. To avoid this, it is recommended that callers
	// moving to |SSL_CREDENTIAL| use the new APIs consistently.
	SSL_get0_selected_credential :: proc(ssl: ^SSL) -> ^SSL_CREDENTIAL ---

	// SSL_CTX_use_certificate sets |ctx|'s leaf certificate to |x509|. It returns
	// one on success and zero on failure. If |ctx| has a private key which is
	// inconsistent with |x509|, the private key is silently dropped.
	SSL_CTX_use_certificate :: proc(ctx: ^SSL_CTX, x509: ^X509) -> i32 ---

	// SSL_use_certificate sets |ssl|'s leaf certificate to |x509|. It returns one
	// on success and zero on failure. If |ssl| has a private key which is
	// inconsistent with |x509|, the private key is silently dropped.
	SSL_use_certificate :: proc(ssl: ^SSL, x509: ^X509) -> i32 ---

	// SSL_CTX_use_PrivateKey sets |ctx|'s private key to |pkey|. It returns one on
	// success and zero on failure. If |ctx| had a private key or
	// |SSL_PRIVATE_KEY_METHOD| previously configured, it is replaced.
	SSL_CTX_use_PrivateKey :: proc(ctx: ^SSL_CTX, pkey: ^EVP_PKEY) -> i32 ---

	// SSL_use_PrivateKey sets |ssl|'s private key to |pkey|. It returns one on
	// success and zero on failure. If |ssl| had a private key or
	// |SSL_PRIVATE_KEY_METHOD| previously configured, it is replaced.
	SSL_use_PrivateKey :: proc(ssl: ^SSL, pkey: ^EVP_PKEY) -> i32 ---

	// SSL_CTX_set_cert_cb sets a callback that is called to select a certificate.
	// The callback returns one on success, zero on internal error, and a negative
	// number on failure or to pause the handshake. If the handshake is paused,
	// |SSL_get_error| will return |SSL_ERROR_WANT_X509_LOOKUP|.
	//
	// On the client, the callback may call |SSL_get0_certificate_types| and
	// |SSL_get_client_CA_list| for information on the server's certificate
	// request.
	//
	// On the server, the callback will be called after extensions have been
	// processed, but before the resumption decision has been made. This differs
	// from OpenSSL which handles resumption before selecting the certificate.
	SSL_CTX_set_cert_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, arg: rawptr) -> i32, arg: rawptr) ---

	// SSL_set_cert_cb sets a callback that is called to select a certificate. The
	// callback returns one on success, zero on internal error, and a negative
	// number on failure or to pause the handshake. If the handshake is paused,
	// |SSL_get_error| will return |SSL_ERROR_WANT_X509_LOOKUP|.
	//
	// On the client, the callback may call |SSL_get0_certificate_types| and
	// |SSL_get_client_CA_list| for information on the server's certificate
	// request.
	//
	// On the server, the callback will be called after extensions have been
	// processed, but before the resumption decision has been made. This differs
	// from OpenSSL which handles resumption before selecting the certificate.
	SSL_set_cert_cb :: proc(ssl: ^SSL, cb: proc "c" (ssl: ^SSL, arg: rawptr) -> i32, arg: rawptr) ---

	// SSL_get0_peer_verify_algorithms sets |*out_sigalgs| to an array containing
	// the signature algorithms the peer is able to verify. It returns the length of
	// the array. Note these values are only sent starting TLS 1.2 and only
	// mandatory starting TLS 1.3. If not sent, the empty array is returned. For the
	// historical client certificate types list, see |SSL_get0_certificate_types|.
	//
	// The behavior of this function is undefined except during the callbacks set by
	// by |SSL_CTX_set_cert_cb| and |SSL_CTX_set_client_cert_cb| or when the
	// handshake is paused because of them.
	SSL_get0_peer_verify_algorithms :: proc(ssl: ^SSL, out_sigalgs: ^^u16) -> c.size_t ---

	// SSL_get0_peer_delegation_algorithms sets |*out_sigalgs| to an array
	// containing the signature algorithms the peer is willing to use with delegated
	// credentials.  It returns the length of the array. If not sent, the empty
	// array is returned.
	//
	// The behavior of this function is undefined except during the callbacks set by
	// by |SSL_CTX_set_cert_cb| and |SSL_CTX_set_client_cert_cb| or when the
	// handshake is paused because of them.
	SSL_get0_peer_delegation_algorithms :: proc(ssl: ^SSL, out_sigalgs: ^^u16) -> c.size_t ---

	// SSL_CTX_get0_certificate returns |ctx|'s leaf certificate.
	SSL_CTX_get0_certificate :: proc(ctx: ^SSL_CTX) -> ^X509 ---

	// SSL_get_certificate returns |ssl|'s leaf certificate.
	SSL_get_certificate :: proc(ssl: ^SSL) -> ^X509 ---

	// SSL_CTX_get0_privatekey returns |ctx|'s private key.
	SSL_CTX_get0_privatekey :: proc(ctx: ^SSL_CTX) -> ^EVP_PKEY ---

	// SSL_get_privatekey returns |ssl|'s private key.
	SSL_get_privatekey :: proc(ssl: ^SSL) -> ^EVP_PKEY ---

	// SSL_CTX_set_signed_cert_timestamp_list sets the list of signed certificate
	// timestamps that is sent to clients that request it. The |list| argument must
	// contain one or more SCT structures serialised as a SignedCertificateTimestamp
	// List (see https://tools.ietf.org/html/rfc6962#section-3.3) – i.e. each SCT
	// is prefixed by a big-endian, uint16 length and the concatenation of one or
	// more such prefixed SCTs are themselves also prefixed by a uint16 length. It
	// returns one on success and zero on error. The caller retains ownership of
	// |list|.
	SSL_CTX_set_signed_cert_timestamp_list :: proc(ctx: ^SSL_CTX, list: ^u8, list_len: c.size_t) -> i32 ---

	// SSL_set_signed_cert_timestamp_list sets the list of signed certificate
	// timestamps that is sent to clients that request is. The same format as the
	// one used for |SSL_CTX_set_signed_cert_timestamp_list| applies. The caller
	// retains ownership of |list|.
	SSL_set_signed_cert_timestamp_list :: proc(ctx: ^SSL, list: ^u8, list_len: c.size_t) -> i32 ---

	// SSL_CTX_set_ocsp_response sets the OCSP response that is sent to clients
	// which request it. It returns one on success and zero on error. The caller
	// retains ownership of |response|.
	SSL_CTX_set_ocsp_response :: proc(ctx: ^SSL_CTX, response: ^u8, response_len: c.size_t) -> i32 ---

	// SSL_set_ocsp_response sets the OCSP response that is sent to clients which
	// request it. It returns one on success and zero on error. The caller retains
	// ownership of |response|.
	SSL_set_ocsp_response :: proc(ssl: ^SSL, response: ^u8, response_len: c.size_t) -> i32 ---
}

// SSL_SIGN_* are signature algorithm values as defined in TLS 1.3.
SSL_SIGN_RSA_PKCS1_SHA1         :: 0x0201
SSL_SIGN_RSA_PKCS1_SHA256       :: 0x0401
SSL_SIGN_RSA_PKCS1_SHA384       :: 0x0501
SSL_SIGN_RSA_PKCS1_SHA512       :: 0x0601
SSL_SIGN_ECDSA_SHA1             :: 0x0203
SSL_SIGN_ECDSA_SECP256R1_SHA256 :: 0x0403
SSL_SIGN_ECDSA_SECP384R1_SHA384 :: 0x0503
SSL_SIGN_ECDSA_SECP521R1_SHA512 :: 0x0603
SSL_SIGN_RSA_PSS_RSAE_SHA256    :: 0x0804
SSL_SIGN_RSA_PSS_RSAE_SHA384    :: 0x0805
SSL_SIGN_RSA_PSS_RSAE_SHA512    :: 0x0806
SSL_SIGN_ED25519                :: 0x0807

// SSL_SIGN_RSA_PKCS1_SHA256_LEGACY is a backport of RSASSA-PKCS1-v1_5 with
// SHA-256 to TLS 1.3. It is disabled by default and only defined for client
// certificates.
SSL_SIGN_RSA_PKCS1_SHA256_LEGACY :: 0x0420

// SSL_SIGN_RSA_PKCS1_MD5_SHA1 is an internal signature algorithm used to
// specify raw RSASSA-PKCS1-v1_5 with an MD5/SHA-1 concatenation, as used in TLS
// before TLS 1.2.
SSL_SIGN_RSA_PKCS1_MD5_SHA1 :: 0xff01

@(default_calling_convention="c")
foreign lib {
	// SSL_get_signature_algorithm_name returns a human-readable name for |sigalg|,
	// or NULL if unknown. If |include_curve| is one, the curve for ECDSA algorithms
	// is included as in TLS 1.3. Otherwise, it is excluded as in TLS 1.2.
	SSL_get_signature_algorithm_name :: proc(sigalg: u16, include_curve: i32) -> cstring ---

	// SSL_get_all_signature_algorithm_names outputs a list of possible strings
	// |SSL_get_signature_algorithm_name| may return in this version of BoringSSL.
	// It writes at most |max_out| entries to |out| and returns the total number it
	// would have written, if |max_out| had been large enough. |max_out| may be
	// initially set to zero to size the output.
	//
	// This function is only intended to help initialize tables in callers that want
	// possible strings pre-declared. This list would not be suitable to set a list
	// of supported features. It is in no particular order, and may contain
	// placeholder, experimental, or deprecated values that do not apply to every
	// caller. Future versions of BoringSSL may also return strings not in this
	// list, so this does not apply if, say, sending strings across services.
	SSL_get_all_signature_algorithm_names :: proc(out: ^cstring, max_out: c.size_t) -> c.size_t ---

	// SSL_get_signature_algorithm_key_type returns the key type associated with
	// |sigalg| as an |EVP_PKEY_*| constant or |EVP_PKEY_NONE| if unknown.
	SSL_get_signature_algorithm_key_type :: proc(sigalg: u16) -> i32 ---

	// SSL_get_signature_algorithm_digest returns the digest function associated
	// with |sigalg| or |NULL| if |sigalg| has no prehash (Ed25519) or is unknown.
	SSL_get_signature_algorithm_digest :: proc(sigalg: u16) -> ^EVP_MD ---

	// SSL_is_signature_algorithm_rsa_pss returns one if |sigalg| is an RSA-PSS
	// signature algorithm and zero otherwise.
	SSL_is_signature_algorithm_rsa_pss :: proc(sigalg: u16) -> i32 ---

	// SSL_CTX_set_signing_algorithm_prefs configures |ctx| to use |prefs| as the
	// preference list when signing with |ctx|'s private key in TLS 1.2 and up. It
	// returns one on success and zero on error. |prefs| should not include the
	// internal-only TLS 1.0 value |SSL_SIGN_RSA_PKCS1_MD5_SHA1|.
	//
	// This setting is not used in TLS 1.0 and 1.1. Those protocols always sign a
	// hardcoded algorithm (an MD5/SHA-1 concatenation for RSA, and SHA-1 for
	// ECDSA). BoringSSL will use those algorithms if and only if those versions are
	// used. To disable them, set the minimum version to TLS 1.2 (default) or
	// higher.
	SSL_CTX_set_signing_algorithm_prefs :: proc(ctx: ^SSL_CTX, prefs: ^u16, num_prefs: c.size_t) -> i32 ---

	// SSL_set_signing_algorithm_prefs configures |ssl| to use |prefs| as the
	// preference list when signing with |ssl|'s private key in TLS 1.2 and up. It
	// returns one on success and zero on error. |prefs| should not include the
	// internal-only TLS 1.0 value |SSL_SIGN_RSA_PKCS1_MD5_SHA1|.
	//
	// This setting is not used in TLS 1.0 and 1.1. Those protocols always sign a
	// hardcoded algorithm (an MD5/SHA-1 concatenation for RSA, and SHA-1 for
	// ECDSA). BoringSSL will use those algorithms if and only if those versions are
	// used. To disable them, set the minimum version to TLS 1.2 (default) or
	// higher.
	SSL_set_signing_algorithm_prefs :: proc(ssl: ^SSL, prefs: ^u16, num_prefs: c.size_t) -> i32 ---

	// SSL_CTX_set_chain_and_key sets the certificate chain and private key for a
	// TLS client or server. References to the given |CRYPTO_BUFFER| and |EVP_PKEY|
	// objects are added as needed. Exactly one of |privkey| or |privkey_method|
	// may be non-NULL. Returns one on success and zero on error.
	SSL_CTX_set_chain_and_key :: proc(ctx: ^SSL_CTX, certs: ^^CRYPTO_BUFFER, num_certs: c.size_t, privkey: ^EVP_PKEY, privkey_method: ^SSL_PRIVATE_KEY_METHOD) -> i32 ---

	// SSL_set_chain_and_key sets the certificate chain and private key for a TLS
	// client or server. References to the given |CRYPTO_BUFFER| and |EVP_PKEY|
	// objects are added as needed. Exactly one of |privkey| or |privkey_method|
	// may be non-NULL. Returns one on success and zero on error.
	SSL_set_chain_and_key :: proc(ssl: ^SSL, certs: ^^CRYPTO_BUFFER, num_certs: c.size_t, privkey: ^EVP_PKEY, privkey_method: ^SSL_PRIVATE_KEY_METHOD) -> i32 ---

	// SSL_CTX_get0_chain returns the list of |CRYPTO_BUFFER|s that were set by
	// |SSL_CTX_set_chain_and_key|. Reference counts are not incremented by this
	// call. The return value may be |NULL| if no chain has been set.
	//
	// (Note: if a chain was configured by non-|CRYPTO_BUFFER|-based functions then
	// the return value is undefined and, even if not NULL, the stack itself may
	// contain nullptrs. Thus you shouldn't mix this function with
	// non-|CRYPTO_BUFFER| functions for manipulating the chain.)
	SSL_CTX_get0_chain :: proc(ctx: ^SSL_CTX) -> ^stack_st_CRYPTO_BUFFER ---

	// SSL_get0_chain returns the list of |CRYPTO_BUFFER|s that were set by
	// |SSL_set_chain_and_key|, unless they have been discarded. Reference counts
	// are not incremented by this call. The return value may be |NULL| if no chain
	// has been set.
	//
	// (Note: if a chain was configured by non-|CRYPTO_BUFFER|-based functions then
	// the return value is undefined and, even if not NULL, the stack itself may
	// contain nullptrs. Thus you shouldn't mix this function with
	// non-|CRYPTO_BUFFER| functions for manipulating the chain.)
	//
	// This function may return nullptr if a handshake has completed even if
	// |SSL_set_chain_and_key| was previously called, since the configuration
	// containing the certificates is typically cleared after handshake completion.
	SSL_get0_chain :: proc(ssl: ^SSL) -> ^stack_st_CRYPTO_BUFFER ---

	// SSL_CTX_use_RSAPrivateKey sets |ctx|'s private key to |rsa|. It returns one
	// on success and zero on failure.
	SSL_CTX_use_RSAPrivateKey :: proc(ctx: ^SSL_CTX, rsa: ^RSA) -> i32 ---

	// SSL_use_RSAPrivateKey sets |ctx|'s private key to |rsa|. It returns one on
	// success and zero on failure.
	SSL_use_RSAPrivateKey :: proc(ssl: ^SSL, rsa: ^RSA) -> i32 ---

	// The following functions configure certificates or private keys but take as
	// input DER-encoded structures. They return one on success and zero on
	// failure.
	SSL_CTX_use_certificate_ASN1   :: proc(ctx: ^SSL_CTX, der_len: c.size_t, der: ^u8) -> i32 ---
	SSL_use_certificate_ASN1       :: proc(ssl: ^SSL, der: ^u8, der_len: c.size_t) -> i32 ---
	SSL_CTX_use_PrivateKey_ASN1    :: proc(pk: i32, ctx: ^SSL_CTX, der: ^u8, der_len: c.size_t) -> i32 ---
	SSL_use_PrivateKey_ASN1        :: proc(type: i32, ssl: ^SSL, der: ^u8, der_len: c.size_t) -> i32 ---
	SSL_CTX_use_RSAPrivateKey_ASN1 :: proc(ctx: ^SSL_CTX, der: ^u8, der_len: c.size_t) -> i32 ---
	SSL_use_RSAPrivateKey_ASN1     :: proc(ssl: ^SSL, der: ^u8, der_len: c.size_t) -> i32 ---
}

// The following functions configure certificates or private keys but take as
// input files to read from. They return one on success and zero on failure. The
// |type| parameter is one of the |SSL_FILETYPE_*| values and determines whether
// the file's contents are read as PEM or DER.
SSL_FILETYPE_PEM  :: 1
SSL_FILETYPE_ASN1 :: 2

@(default_calling_convention="c")
foreign lib {
	SSL_CTX_use_RSAPrivateKey_file :: proc(ctx: ^SSL_CTX, file: cstring, type: i32) -> i32 ---
	SSL_use_RSAPrivateKey_file     :: proc(ssl: ^SSL, file: cstring, type: i32) -> i32 ---
	SSL_CTX_use_certificate_file   :: proc(ctx: ^SSL_CTX, file: cstring, type: i32) -> i32 ---
	SSL_use_certificate_file       :: proc(ssl: ^SSL, file: cstring, type: i32) -> i32 ---
	SSL_CTX_use_PrivateKey_file    :: proc(ctx: ^SSL_CTX, file: cstring, type: i32) -> i32 ---
	SSL_use_PrivateKey_file        :: proc(ssl: ^SSL, file: cstring, type: i32) -> i32 ---

	// SSL_CTX_use_certificate_chain_file configures certificates for |ctx|. It
	// reads the contents of |file| as a PEM-encoded leaf certificate followed
	// optionally by the certificate chain to send to the peer. It returns one on
	// success and zero on failure.
	//
	// WARNING: If the input contains "TRUSTED CERTIFICATE" PEM blocks, this
	// function parses auxiliary properties as in |d2i_X509_AUX|. Passing untrusted
	// input to this function allows an attacker to influence those properties. See
	// |d2i_X509_AUX| for details.
	SSL_CTX_use_certificate_chain_file :: proc(ctx: ^SSL_CTX, file: cstring) -> i32 ---

	// SSL_CTX_set_default_passwd_cb sets the password callback for PEM-based
	// convenience functions called on |ctx|.
	SSL_CTX_set_default_passwd_cb :: proc(ctx: ^SSL_CTX, cb: ^pem_password_cb) ---

	// SSL_CTX_get_default_passwd_cb returns the callback set by
	// |SSL_CTX_set_default_passwd_cb|.
	SSL_CTX_get_default_passwd_cb :: proc(ctx: ^SSL_CTX) -> ^pem_password_cb ---

	// SSL_CTX_set_default_passwd_cb_userdata sets the userdata parameter for
	// |ctx|'s password callback.
	SSL_CTX_set_default_passwd_cb_userdata :: proc(ctx: ^SSL_CTX, data: rawptr) ---

	// SSL_CTX_get_default_passwd_cb_userdata returns the userdata parameter set by
	// |SSL_CTX_set_default_passwd_cb_userdata|.
	SSL_CTX_get_default_passwd_cb_userdata :: proc(ctx: ^SSL_CTX) -> rawptr ---
}

// Custom private keys.
ssl_private_key_result_t :: enum u32 {
	success = 0,
	retry   = 1,
	failure = 2,
}

// ssl_private_key_method_st (aka |SSL_PRIVATE_KEY_METHOD|) describes private
// key hooks. This is used to off-load signing operations to a custom,
// potentially asynchronous, backend. Metadata about the key such as the type
// and size are parsed out of the certificate.
ssl_private_key_method_st :: struct {
	// sign signs the message |in| in using the specified signature algorithm. On
	// success, it returns |ssl_private_key_success| and writes at most |max_out|
	// bytes of signature data to |out| and sets |*out_len| to the number of bytes
	// written. On failure, it returns |ssl_private_key_failure|. If the operation
	// has not completed, it returns |ssl_private_key_retry|. |sign| should
	// arrange for the high-level operation on |ssl| to be retried when the
	// operation is completed. This will result in a call to |complete|.
	//
	// |signature_algorithm| is one of the |SSL_SIGN_*| values, as defined in TLS
	// 1.3. Note that, in TLS 1.2, ECDSA algorithms do not require that curve
	// sizes match hash sizes, so the curve portion of |SSL_SIGN_ECDSA_*| values
	// must be ignored. BoringSSL will internally handle the curve matching logic
	// where appropriate.
	//
	// It is an error to call |sign| while another private key operation is in
	// progress on |ssl|.
	sign: proc "c" (ssl: ^SSL, out: ^u8, out_len: ^c.size_t, max_out: c.size_t, signature_algorithm: u16, _in: ^u8, in_len: c.size_t) -> ssl_private_key_result_t,

	// decrypt decrypts |in_len| bytes of encrypted data from |in|. On success it
	// returns |ssl_private_key_success|, writes at most |max_out| bytes of
	// decrypted data to |out| and sets |*out_len| to the actual number of bytes
	// written. On failure it returns |ssl_private_key_failure|. If the operation
	// has not completed, it returns |ssl_private_key_retry|. The caller should
	// arrange for the high-level operation on |ssl| to be retried when the
	// operation is completed, which will result in a call to |complete|. This
	// function only works with RSA keys and should perform a raw RSA decryption
	// operation with no padding.
	//
	// It is an error to call |decrypt| while another private key operation is in
	// progress on |ssl|.
	decrypt: proc "c" (ssl: ^SSL, out: ^u8, out_len: ^c.size_t, max_out: c.size_t, _in: ^u8, in_len: c.size_t) -> ssl_private_key_result_t,

	// complete completes a pending operation. If the operation has completed, it
	// returns |ssl_private_key_success| and writes the result to |out| as in
	// |sign|. Otherwise, it returns |ssl_private_key_failure| on failure and
	// |ssl_private_key_retry| if the operation is still in progress.
	//
	// |complete| may be called arbitrarily many times before completion, but it
	// is an error to call |complete| if there is no pending operation in progress
	// on |ssl|.
	complete: proc "c" (ssl: ^SSL, out: ^u8, out_len: ^c.size_t, max_out: c.size_t) -> ssl_private_key_result_t,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_set_private_key_method configures a custom private key on |ssl|.
	// |key_method| must remain valid for the lifetime of |ssl|.
	//
	// If using an RSA or ECDSA key, callers should configure signing capabilities
	// with |SSL_set_signing_algorithm_prefs|. Otherwise, BoringSSL may select a
	// signature algorithm that |key_method| does not support.
	SSL_set_private_key_method :: proc(ssl: ^SSL, key_method: ^SSL_PRIVATE_KEY_METHOD) ---

	// SSL_CTX_set_private_key_method configures a custom private key on |ctx|.
	// |key_method| must remain valid for the lifetime of |ctx|.
	//
	// If using an RSA or ECDSA key, callers should configure signing capabilities
	// with |SSL_CTX_set_signing_algorithm_prefs|. Otherwise, BoringSSL may select a
	// signature algorithm that |key_method| does not support.
	SSL_CTX_set_private_key_method :: proc(ctx: ^SSL_CTX, key_method: ^SSL_PRIVATE_KEY_METHOD) ---

	// SSL_CREDENTIAL_set_private_key_method configures a custom private key on
	// |cred|. |key_method| must remain valid for the lifetime of |cred|. It returns
	// one on success and zero if |cred| does not use private keys.
	//
	// If using an RSA or ECDSA key, callers should configure signing capabilities
	// with |SSL_CREDENTIAL_set1_signing_algorithm_prefs|. Otherwise, BoringSSL may
	// select a signature algorithm that |key_method| does not support. This is not
	// necessary for delegated credentials (see |SSL_CREDENTIAL_new_delegated|)
	// because delegated credentials only support a single signature algorithm.
	//
	// Functions in |key_method| will be passed an |SSL| object, but not |cred|
	// directly. Use |SSL_get0_selected_credential| to determine the selected
	// credential. From there, |SSL_CREDENTIAL_get_ex_data| can be used to look up
	// credential-specific state, such as a handle to the private key.
	SSL_CREDENTIAL_set_private_key_method :: proc(cred: ^SSL_CREDENTIAL, key_method: ^SSL_PRIVATE_KEY_METHOD) -> i32 ---

	// SSL_can_release_private_key returns one if |ssl| will no longer call into the
	// private key and zero otherwise. If the function returns one, the caller can
	// release state associated with the private key.
	//
	// NOTE: This function assumes the caller does not use |SSL_clear| to reuse
	// |ssl| for a second connection. If |SSL_clear| is used, BoringSSL may still
	// use the private key on the second connection.
	SSL_can_release_private_key :: proc(ssl: ^SSL) -> i32 ---
}

sk_SSL_CIPHER_delete_if_func :: proc "c" (^SSL_CIPHER, rawptr) -> i32
sk_SSL_CIPHER_cmp_func       :: proc "c" (^^SSL_CIPHER, ^^SSL_CIPHER) -> i32
sk_SSL_CIPHER_free_func      :: proc "c" (^SSL_CIPHER)
stack_st_SSL_CIPHER          :: struct {}
sk_SSL_CIPHER_copy_func      :: proc "c" (^SSL_CIPHER) -> ^SSL_CIPHER

// The following constants are TLS cipher suite protocol IDs, as returned from
// |SSL_CIPHER_get_protocol_id|.
SSL_CIPHER_AES_128_GCM_SHA256                        :: 0x1301
SSL_CIPHER_AES_256_GCM_SHA384                        :: 0x1302
SSL_CIPHER_CHACHA20_POLY1305_SHA256                  :: 0x1303
SSL_CIPHER_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256       :: 0xc02b
SSL_CIPHER_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384       :: 0xc02c
SSL_CIPHER_ECDHE_RSA_WITH_AES_128_GCM_SHA256         :: 0xc02f
SSL_CIPHER_ECDHE_RSA_WITH_AES_256_GCM_SHA384         :: 0xc030
SSL_CIPHER_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256   :: 0xcca8
SSL_CIPHER_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 :: 0xcca9
SSL_CIPHER_ECDHE_PSK_WITH_CHACHA20_POLY1305_SHA256   :: 0xccac
SSL_CIPHER_ECDHE_ECDSA_WITH_AES_128_CBC_SHA          :: 0xc009
SSL_CIPHER_ECDHE_ECDSA_WITH_AES_256_CBC_SHA          :: 0xc00a
SSL_CIPHER_ECDHE_RSA_WITH_AES_128_CBC_SHA            :: 0xc013
SSL_CIPHER_ECDHE_RSA_WITH_AES_256_CBC_SHA            :: 0xc014
SSL_CIPHER_ECDHE_PSK_WITH_AES_128_CBC_SHA            :: 0xc035
SSL_CIPHER_ECDHE_PSK_WITH_AES_256_CBC_SHA            :: 0xc036
SSL_CIPHER_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256       :: 0xc023
SSL_CIPHER_ECDHE_RSA_WITH_AES_128_CBC_SHA256         :: 0xc027
SSL_CIPHER_RSA_WITH_AES_128_GCM_SHA256               :: 0x009c
SSL_CIPHER_RSA_WITH_AES_256_GCM_SHA384               :: 0x009d
SSL_CIPHER_RSA_WITH_AES_128_CBC_SHA                  :: 0x002f
SSL_CIPHER_RSA_WITH_AES_256_CBC_SHA                  :: 0x0035
SSL_CIPHER_PSK_WITH_AES_128_CBC_SHA                  :: 0x008c
SSL_CIPHER_PSK_WITH_AES_256_CBC_SHA                  :: 0x008d
SSL_CIPHER_RSA_WITH_3DES_EDE_CBC_SHA                 :: 0x000a

// The following constants are not cipher suites, but are used in the protocol
// as signalling values.
SSL_CIPHER_EMPTY_RENEGOTIATION_INFO_SCSV :: 0x00ff
SSL_CIPHER_FALLBACK_SCSV                 :: 0x5600

@(default_calling_convention="c")
foreign lib {
	// SSL_get_cipher_by_value returns the structure representing a TLS cipher
	// suite based on its assigned number, or NULL if unknown. See
	// https://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-4.
	SSL_get_cipher_by_value :: proc(value: u16) -> ^SSL_CIPHER ---

	// SSL_CIPHER_get_protocol_id returns |cipher|'s two-byte protocol ID.
	SSL_CIPHER_get_protocol_id :: proc(cipher: ^SSL_CIPHER) -> u16 ---

	// SSL_CIPHER_is_aead returns one if |cipher| uses an AEAD cipher.
	SSL_CIPHER_is_aead :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_is_block_cipher returns one if |cipher| is a block cipher.
	SSL_CIPHER_is_block_cipher :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_get_cipher_nid returns the NID for |cipher|'s bulk
	// cipher. Possible values are |NID_aes_128_gcm|, |NID_aes_256_gcm|,
	// |NID_chacha20_poly1305|, |NID_aes_128_cbc|, |NID_aes_256_cbc|, and
	// |NID_des_ede3_cbc|.
	SSL_CIPHER_get_cipher_nid :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_get_digest_nid returns the NID for |cipher|'s HMAC if it is a
	// legacy cipher suite. For modern AEAD-based ciphers (see
	// |SSL_CIPHER_is_aead|), it returns |NID_undef|.
	//
	// Note this function only returns the legacy HMAC digest, not the PRF hash.
	SSL_CIPHER_get_digest_nid :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_get_kx_nid returns the NID for |cipher|'s key exchange. This may
	// be |NID_kx_rsa|, |NID_kx_ecdhe|, or |NID_kx_psk| for TLS 1.2. In TLS 1.3,
	// cipher suites do not specify the key exchange, so this function returns
	// |NID_kx_any|.
	SSL_CIPHER_get_kx_nid :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_get_auth_nid returns the NID for |cipher|'s authentication
	// type. This may be |NID_auth_rsa|, |NID_auth_ecdsa|, or |NID_auth_psk| for TLS
	// 1.2. In TLS 1.3, cipher suites do not specify authentication, so this
	// function returns |NID_auth_any|.
	SSL_CIPHER_get_auth_nid :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_get_handshake_digest returns |cipher|'s PRF hash. If |cipher|
	// is a pre-TLS-1.2 cipher, it returns |EVP_md5_sha1| but note these ciphers use
	// SHA-256 in TLS 1.2. Other return values may be treated uniformly in all
	// applicable versions.
	SSL_CIPHER_get_handshake_digest :: proc(cipher: ^SSL_CIPHER) -> ^EVP_MD ---

	// SSL_CIPHER_get_prf_nid behaves like |SSL_CIPHER_get_handshake_digest| but
	// returns the NID constant. Use |SSL_CIPHER_get_handshake_digest| instead.
	SSL_CIPHER_get_prf_nid :: proc(cipher: ^SSL_CIPHER) -> i32 ---

	// SSL_CIPHER_get_min_version returns the minimum protocol version required
	// for |cipher|.
	SSL_CIPHER_get_min_version :: proc(cipher: ^SSL_CIPHER) -> u16 ---

	// SSL_CIPHER_get_max_version returns the maximum protocol version that
	// supports |cipher|.
	SSL_CIPHER_get_max_version :: proc(cipher: ^SSL_CIPHER) -> u16 ---

	// SSL_CIPHER_standard_name returns the standard IETF name for |cipher|. For
	// example, "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256".
	SSL_CIPHER_standard_name :: proc(cipher: ^SSL_CIPHER) -> cstring ---

	// SSL_CIPHER_get_kx_name returns a string that describes the key-exchange
	// method used by |cipher|. For example, "ECDHE_ECDSA". TLS 1.3 AEAD-only
	// ciphers return the string "GENERIC".
	SSL_CIPHER_get_kx_name :: proc(cipher: ^SSL_CIPHER) -> cstring ---

	// SSL_CIPHER_get_bits returns the strength, in bits, of |cipher|. If
	// |out_alg_bits| is not NULL, it writes the number of bits consumed by the
	// symmetric algorithm to |*out_alg_bits|.
	SSL_CIPHER_get_bits :: proc(cipher: ^SSL_CIPHER, out_alg_bits: ^i32) -> i32 ---

	// SSL_get_all_cipher_names outputs a list of possible strings
	// |SSL_CIPHER_get_name| may return in this version of BoringSSL. It writes at
	// most |max_out| entries to |out| and returns the total number it would have
	// written, if |max_out| had been large enough. |max_out| may be initially set
	// to zero to size the output.
	//
	// This function is only intended to help initialize tables in callers that want
	// possible strings pre-declared. This list would not be suitable to set a list
	// of supported features. It is in no particular order, and may contain
	// placeholder, experimental, or deprecated values that do not apply to every
	// caller. Future versions of BoringSSL may also return strings not in this
	// list, so this does not apply if, say, sending strings across services.
	SSL_get_all_cipher_names :: proc(out: ^cstring, max_out: c.size_t) -> c.size_t ---

	// SSL_get_all_standard_cipher_names outputs a list of possible strings
	// |SSL_CIPHER_standard_name| may return in this version of BoringSSL. It writes
	// at most |max_out| entries to |out| and returns the total number it would have
	// written, if |max_out| had been large enough. |max_out| may be initially set
	// to zero to size the output.
	//
	// This function is only intended to help initialize tables in callers that want
	// possible strings pre-declared. This list would not be suitable to set a list
	// of supported features. It is in no particular order, and may contain
	// placeholder, experimental, or deprecated values that do not apply to every
	// caller. Future versions of BoringSSL may also return strings not in this
	// list, so this does not apply if, say, sending strings across services.
	SSL_get_all_standard_cipher_names :: proc(out: ^cstring, max_out: c.size_t) -> c.size_t ---
}

// Cipher suite configuration.
//
// OpenSSL uses a mini-language to configure cipher suites. The language
// maintains an ordered list of enabled ciphers, along with an ordered list of
// disabled but available ciphers. Initially, all ciphers are disabled with a
// default ordering. The cipher string is then interpreted as a sequence of
// directives, separated by colons, each of which modifies this state.
//
// Most directives consist of a one character or empty opcode followed by a
// selector which matches a subset of available ciphers.
//
// Available opcodes are:
//
// - The empty opcode enables and appends all matching disabled ciphers to the
//   end of the enabled list. The newly appended ciphers are ordered relative to
//   each other matching their order in the disabled list.
//
// - |-| disables all matching enabled ciphers and prepends them to the disabled
//   list, with relative order from the enabled list preserved. This means the
//   most recently disabled ciphers get highest preference relative to other
//   disabled ciphers if re-enabled.
//
// - |+| moves all matching enabled ciphers to the end of the enabled list, with
//   relative order preserved.
//
// - |!| deletes all matching ciphers, enabled or not, from either list. Deleted
//   ciphers will not matched by future operations.
//
// A selector may be a specific cipher (using either the standard or OpenSSL
// name for the cipher) or one or more rules separated by |+|. The final
// selector matches the intersection of each rule. For instance, |AESGCM+aECDSA|
// matches ECDSA-authenticated AES-GCM ciphers.
//
// Available cipher rules are:
//
// - |ALL| matches all ciphers, except for deprecated ciphers which must be
//   named explicitly.
//
// - |kRSA|, |kDHE|, |kECDHE|, and |kPSK| match ciphers using plain RSA, DHE,
//   ECDHE, and plain PSK key exchanges, respectively. Note that ECDHE_PSK is
//   matched by |kECDHE| and not |kPSK|.
//
// - |aRSA|, |aECDSA|, and |aPSK| match ciphers authenticated by RSA, ECDSA, and
//   a pre-shared key, respectively.
//
// - |RSA|, |DHE|, |ECDHE|, |PSK|, |ECDSA|, and |PSK| are aliases for the
//   corresponding |k*| or |a*| cipher rule. |RSA| is an alias for |kRSA|, not
//   |aRSA|.
//
// - |3DES|, |AES128|, |AES256|, |AES|, |AESGCM|, |CHACHA20| match ciphers
//   whose bulk cipher use the corresponding encryption scheme. Note that
//   |AES|, |AES128|, and |AES256| match both CBC and GCM ciphers.
//
// - |SHA1|, and its alias |SHA|, match legacy cipher suites using HMAC-SHA1.
//
// Deprecated cipher rules:
//
// - |kEDH|, |EDH|, |kEECDH|, and |EECDH| are legacy aliases for |kDHE|, |DHE|,
//   |kECDHE|, and |ECDHE|, respectively.
//
// - |HIGH| is an alias for |ALL|.
//
// - |FIPS| is an alias for |HIGH|.
//
// - |SSLv3| and |TLSv1| match ciphers available in TLS 1.1 or earlier.
//   |TLSv1_2| matches ciphers new in TLS 1.2. This is confusing and should not
//   be used.
//
// Unknown rules are silently ignored by legacy APIs, and rejected by APIs with
// "strict" in the name, which should be preferred. Cipher lists can be long
// and it's easy to commit typos. Strict functions will also reject the use of
// spaces, semi-colons and commas as alternative separators.
//
// The special |@STRENGTH| directive will sort all enabled ciphers by strength.
//
// The |DEFAULT| directive, when appearing at the front of the string, expands
// to the default ordering of available ciphers.
//
// If configuring a server, one may also configure equal-preference groups to
// partially respect the client's preferences when
// |SSL_OP_CIPHER_SERVER_PREFERENCE| is enabled. Ciphers in an equal-preference
// group have equal priority and use the client order. This may be used to
// enforce that AEADs are preferred but select AES-GCM vs. ChaCha20-Poly1305
// based on client preferences. An equal-preference is specified with square
// brackets, combining multiple selectors separated by |. For example:
//
//   [TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256|TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256]
//
// Once an equal-preference group is used, future directives must be
// opcode-less. Inside an equal-preference group, spaces are not allowed.
//
// TLS 1.3 ciphers do not participate in this mechanism and instead have a
// built-in preference order. Functions to set cipher lists do not affect TLS
// 1.3, and functions to query the cipher list do not include TLS 1.3 ciphers.

// SSL_DEFAULT_CIPHER_LIST is the default cipher suite configuration. It is
// substituted when a cipher string starts with 'DEFAULT'.
SSL_DEFAULT_CIPHER_LIST :: "ALL"

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_strict_cipher_list configures the cipher list for |ctx|,
	// evaluating |str| as a cipher string and returning error if |str| contains
	// anything meaningless. It returns one on success and zero on failure.
	SSL_CTX_set_strict_cipher_list :: proc(ctx: ^SSL_CTX, str: cstring) -> i32 ---

	// SSL_CTX_set_cipher_list configures the cipher list for |ctx|, evaluating
	// |str| as a cipher string. It returns one on success and zero on failure.
	//
	// Prefer to use |SSL_CTX_set_strict_cipher_list|. This function tolerates
	// garbage inputs, unless an empty cipher list results.
	SSL_CTX_set_cipher_list :: proc(ctx: ^SSL_CTX, str: cstring) -> i32 ---

	// SSL_set_strict_cipher_list configures the cipher list for |ssl|, evaluating
	// |str| as a cipher string and returning error if |str| contains anything
	// meaningless. It returns one on success and zero on failure.
	SSL_set_strict_cipher_list :: proc(ssl: ^SSL, str: cstring) -> i32 ---

	// SSL_set_cipher_list configures the cipher list for |ssl|, evaluating |str| as
	// a cipher string. It returns one on success and zero on failure.
	//
	// Prefer to use |SSL_set_strict_cipher_list|. This function tolerates garbage
	// inputs, unless an empty cipher list results.
	SSL_set_cipher_list :: proc(ssl: ^SSL, str: cstring) -> i32 ---

	// SSL_CTX_get_ciphers returns the cipher list for |ctx|, in order of
	// preference.
	SSL_CTX_get_ciphers :: proc(ctx: ^SSL_CTX) -> ^stack_st_SSL_CIPHER ---

	// SSL_CTX_cipher_in_group returns one if the |i|th cipher (see
	// |SSL_CTX_get_ciphers|) is in the same equipreference group as the one
	// following it and zero otherwise.
	SSL_CTX_cipher_in_group :: proc(ctx: ^SSL_CTX, i: c.size_t) -> i32 ---

	// SSL_get_ciphers returns the cipher list for |ssl|, in order of preference.
	SSL_get_ciphers :: proc(ssl: ^SSL) -> ^stack_st_SSL_CIPHER ---

	// SSL_is_init_finished returns one if |ssl| has completed its initial handshake
	// and has no pending handshake. It returns zero otherwise.
	SSL_is_init_finished :: proc(ssl: ^SSL) -> i32 ---

	// SSL_in_init returns one if |ssl| has a pending handshake and zero
	// otherwise.
	SSL_in_init :: proc(ssl: ^SSL) -> i32 ---

	// SSL_in_false_start returns one if |ssl| has a pending handshake that is in
	// False Start. |SSL_write| may be called at this point without waiting for the
	// peer, but |SSL_read| will complete the handshake before accepting application
	// data.
	//
	// See also |SSL_MODE_ENABLE_FALSE_START|.
	SSL_in_false_start :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_peer_certificate returns the peer's leaf certificate or NULL if the
	// peer did not use certificates. The caller must call |X509_free| on the
	// result to release it.
	SSL_get_peer_certificate :: proc(ssl: ^SSL) -> ^X509 ---

	// SSL_get_peer_cert_chain returns the peer's certificate chain or NULL if
	// unavailable or the peer did not use certificates. This is the unverified list
	// of certificates as sent by the peer, not the final chain built during
	// verification. The caller does not take ownership of the result.
	//
	// WARNING: This function behaves differently between client and server. If
	// |ssl| is a server, the returned chain does not include the leaf certificate.
	// If a client, it does.
	SSL_get_peer_cert_chain :: proc(ssl: ^SSL) -> ^stack_st_X509 ---

	// SSL_get_peer_full_cert_chain returns the peer's certificate chain, or NULL if
	// unavailable or the peer did not use certificates. This is the unverified list
	// of certificates as sent by the peer, not the final chain built during
	// verification. The caller does not take ownership of the result.
	//
	// This is the same as |SSL_get_peer_cert_chain| except that this function
	// always returns the full chain, i.e. the first element of the return value
	// (if any) will be the leaf certificate. In contrast, |SSL_get_peer_cert_chain|
	// returns only the intermediate certificates if the |ssl| is a server.
	SSL_get_peer_full_cert_chain :: proc(ssl: ^SSL) -> ^stack_st_X509 ---

	// SSL_get0_peer_certificates returns the peer's certificate chain, or NULL if
	// unavailable or the peer did not use certificates. This is the unverified list
	// of certificates as sent by the peer, not the final chain built during
	// verification. The caller does not take ownership of the result.
	//
	// This is the |CRYPTO_BUFFER| variant of |SSL_get_peer_full_cert_chain|.
	SSL_get0_peer_certificates :: proc(ssl: ^SSL) -> ^stack_st_CRYPTO_BUFFER ---

	// SSL_get0_signed_cert_timestamp_list sets |*out| and |*out_len| to point to
	// |*out_len| bytes of SCT information from the server. This is only valid if
	// |ssl| is a client. The SCT information is a SignedCertificateTimestampList
	// (including the two leading length bytes).
	// See https://tools.ietf.org/html/rfc6962#section-3.3
	// If no SCT was received then |*out_len| will be zero on return.
	//
	// WARNING: the returned data is not guaranteed to be well formed.
	SSL_get0_signed_cert_timestamp_list :: proc(ssl: ^SSL, out: ^^u8, out_len: ^c.size_t) ---

	// SSL_get0_ocsp_response sets |*out| and |*out_len| to point to |*out_len|
	// bytes of an OCSP response from the server. This is the DER encoding of an
	// OCSPResponse type as defined in RFC 2560.
	//
	// WARNING: the returned data is not guaranteed to be well formed.
	SSL_get0_ocsp_response :: proc(ssl: ^SSL, out: ^^u8, out_len: ^c.size_t) ---

	// SSL_get_tls_unique writes at most |max_out| bytes of the tls-unique value
	// for |ssl| to |out| and sets |*out_len| to the number of bytes written. It
	// returns one on success or zero on error. In general |max_out| should be at
	// least 12.
	//
	// This function will always fail if the initial handshake has not completed.
	// The tls-unique value will change after a renegotiation but, since
	// renegotiations can be initiated by the server at any point, the higher-level
	// protocol must either leave them disabled or define states in which the
	// tls-unique value can be read.
	//
	// The tls-unique value is defined by
	// https://tools.ietf.org/html/rfc5929#section-3.1. Due to a weakness in the
	// TLS protocol, tls-unique is broken for resumed connections unless the
	// Extended Master Secret extension is negotiated. Thus this function will
	// return zero if |ssl| performed session resumption unless EMS was used when
	// negotiating the original session.
	SSL_get_tls_unique :: proc(ssl: ^SSL, out: ^u8, out_len: ^c.size_t, max_out: c.size_t) -> i32 ---

	// SSL_get_extms_support returns one if the Extended Master Secret extension or
	// TLS 1.3 was negotiated. Otherwise, it returns zero.
	SSL_get_extms_support :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_current_cipher returns cipher suite used by |ssl|, or NULL if it has
	// not been negotiated yet.
	SSL_get_current_cipher :: proc(ssl: ^SSL) -> ^SSL_CIPHER ---

	// SSL_export_keying_material exports a connection-specific secret from |ssl|,
	// as specified in RFC 5705. It writes |out_len| bytes to |out| given a label
	// and optional context. If |use_context| is zero, the |context| parameter is
	// ignored.
	//
	// To derive the same value, both sides of a connection must use the same output
	// length, label, and context. In TLS 1.2 and earlier, using a zero-length
	// context and using no context would give different output. In TLS 1.3 and
	// later, the output length impacts the derivation, so a truncated longer export
	// will not match a shorter export.
	//
	// It returns one on success and zero otherwise.
	SSL_export_keying_material :: proc(ssl: ^SSL, out: ^u8, out_len: c.size_t, label: cstring, label_len: c.size_t, _context: ^u8, context_len: c.size_t, use_context: i32) -> i32 ---
	PEM_write_bio_SSL_SESSION  :: proc(bp: ^BIO, x: ^SSL_SESSION) -> i32 ---
	PEM_read_SSL_SESSION       :: proc(fp: ^FILE, x: ^^SSL_SESSION, cb: ^pem_password_cb, u: rawptr) -> ^SSL_SESSION ---
	PEM_write_SSL_SESSION      :: proc(fp: ^FILE, x: ^SSL_SESSION) -> i32 ---
	PEM_read_bio_SSL_SESSION   :: proc(bp: ^BIO, x: ^^SSL_SESSION, cb: ^pem_password_cb, u: rawptr) -> ^SSL_SESSION ---

	// SSL_SESSION_new returns a newly-allocated blank |SSL_SESSION| or NULL on
	// error. This may be useful when writing tests but should otherwise not be
	// used.
	SSL_SESSION_new :: proc(ctx: ^SSL_CTX) -> ^SSL_SESSION ---

	// SSL_SESSION_up_ref increments the reference count of |session| and returns
	// one.
	SSL_SESSION_up_ref :: proc(session: ^SSL_SESSION) -> i32 ---

	// SSL_SESSION_free decrements the reference count of |session|. If it reaches
	// zero, all data referenced by |session| and |session| itself are released.
	SSL_SESSION_free :: proc(session: ^SSL_SESSION) ---

	// SSL_SESSION_to_bytes serializes |in| into a newly allocated buffer and sets
	// |*out_data| to that buffer and |*out_len| to its length. The caller takes
	// ownership of the buffer and must call |OPENSSL_free| when done. It returns
	// one on success and zero on error.
	SSL_SESSION_to_bytes :: proc(_in: ^SSL_SESSION, out_data: ^^u8, out_len: ^c.size_t) -> i32 ---

	// SSL_SESSION_to_bytes_for_ticket serializes |in|, but excludes the session
	// identification information, namely the session ID and ticket.
	SSL_SESSION_to_bytes_for_ticket :: proc(_in: ^SSL_SESSION, out_data: ^^u8, out_len: ^c.size_t) -> i32 ---

	// SSL_SESSION_from_bytes parses |in_len| bytes from |in| as an SSL_SESSION. It
	// returns a newly-allocated |SSL_SESSION| on success or NULL on error.
	SSL_SESSION_from_bytes :: proc(_in: ^u8, in_len: c.size_t, ctx: ^SSL_CTX) -> ^SSL_SESSION ---

	// SSL_SESSION_get_version returns a string describing the TLS or DTLS version
	// |session| was established at. For example, "TLSv1.2" or "DTLSv1".
	SSL_SESSION_get_version :: proc(session: ^SSL_SESSION) -> cstring ---

	// SSL_SESSION_get_protocol_version returns the TLS or DTLS version |session|
	// was established at.
	SSL_SESSION_get_protocol_version :: proc(session: ^SSL_SESSION) -> u16 ---

	// SSL_SESSION_set_protocol_version sets |session|'s TLS or DTLS version to
	// |version|. This may be useful when writing tests but should otherwise not be
	// used. It returns one on success and zero on error.
	SSL_SESSION_set_protocol_version :: proc(session: ^SSL_SESSION, version: u16) -> i32 ---
}

// SSL_MAX_SSL_SESSION_ID_LENGTH is the maximum length of an SSL session ID.
SSL_MAX_SSL_SESSION_ID_LENGTH :: 32

@(default_calling_convention="c")
foreign lib {
	// SSL_SESSION_get_id returns a pointer to a buffer containing |session|'s
	// session ID and sets |*out_len| to its length.
	//
	// This function should only be used for implementing a TLS session cache. TLS
	// sessions are not suitable for application-level session state, and a session
	// ID is an implementation detail of the TLS resumption handshake mechanism. Not
	// all resumption flows use session IDs, and not all connections within an
	// application-level session will reuse TLS sessions.
	//
	// To determine if resumption occurred, use |SSL_session_reused| instead.
	// Comparing session IDs will not give the right result in all cases.
	//
	// As a workaround for some broken applications, BoringSSL sometimes synthesizes
	// arbitrary session IDs for non-ID-based sessions. This behavior may be
	// removed in the future.
	SSL_SESSION_get_id :: proc(session: ^SSL_SESSION, out_len: ^u32) -> ^u8 ---

	// SSL_SESSION_set1_id sets |session|'s session ID to |sid|, It returns one on
	// success and zero on error. This function may be useful in writing tests but
	// otherwise should not be used.
	SSL_SESSION_set1_id :: proc(session: ^SSL_SESSION, sid: ^u8, sid_len: c.size_t) -> i32 ---

	// SSL_SESSION_get_time returns the time at which |session| was established in
	// seconds since the UNIX epoch.
	SSL_SESSION_get_time :: proc(session: ^SSL_SESSION) -> u64 ---

	// SSL_SESSION_get_timeout returns the lifetime of |session| in seconds.
	SSL_SESSION_get_timeout :: proc(session: ^SSL_SESSION) -> u32 ---

	// SSL_SESSION_get0_peer returns the peer leaf certificate stored in
	// |session|.
	//
	// TODO(davidben): This should return a const X509 *.
	SSL_SESSION_get0_peer :: proc(session: ^SSL_SESSION) -> ^X509 ---

	// SSL_SESSION_get0_peer_certificates returns the peer certificate chain stored
	// in |session|, or NULL if the peer did not use certificates. This is the
	// unverified list of certificates as sent by the peer, not the final chain
	// built during verification. The caller does not take ownership of the result.
	SSL_SESSION_get0_peer_certificates :: proc(session: ^SSL_SESSION) -> ^stack_st_CRYPTO_BUFFER ---

	// SSL_SESSION_get0_signed_cert_timestamp_list sets |*out| and |*out_len| to
	// point to |*out_len| bytes of SCT information stored in |session|. This is
	// only valid for client sessions. The SCT information is a
	// SignedCertificateTimestampList (including the two leading length bytes). See
	// https://tools.ietf.org/html/rfc6962#section-3.3 If no SCT was received then
	// |*out_len| will be zero on return.
	//
	// WARNING: the returned data is not guaranteed to be well formed.
	SSL_SESSION_get0_signed_cert_timestamp_list :: proc(session: ^SSL_SESSION, out: ^^u8, out_len: ^c.size_t) ---

	// SSL_SESSION_get0_ocsp_response sets |*out| and |*out_len| to point to
	// |*out_len| bytes of an OCSP response from the server. This is the DER
	// encoding of an OCSPResponse type as defined in RFC 2560.
	//
	// WARNING: the returned data is not guaranteed to be well formed.
	SSL_SESSION_get0_ocsp_response :: proc(session: ^SSL_SESSION, out: ^^u8, out_len: ^c.size_t) ---
}

// SSL_MAX_MASTER_KEY_LENGTH is the maximum length of a master secret.
SSL_MAX_MASTER_KEY_LENGTH :: 48

@(default_calling_convention="c")
foreign lib {
	// SSL_SESSION_get_master_key writes up to |max_out| bytes of |session|'s secret
	// to |out| and returns the number of bytes written. If |max_out| is zero, it
	// returns the size of the secret.
	SSL_SESSION_get_master_key :: proc(session: ^SSL_SESSION, out: ^u8, max_out: c.size_t) -> c.size_t ---

	// SSL_SESSION_set_time sets |session|'s creation time to |time| and returns
	// |time|. This function may be useful in writing tests but otherwise should not
	// be used.
	SSL_SESSION_set_time :: proc(session: ^SSL_SESSION, time: u64) -> u64 ---

	// SSL_SESSION_set_timeout sets |session|'s timeout to |timeout| and returns
	// one. This function may be useful in writing tests but otherwise should not
	// be used.
	SSL_SESSION_set_timeout :: proc(session: ^SSL_SESSION, timeout: u32) -> u32 ---

	// SSL_SESSION_get0_id_context returns a pointer to a buffer containing
	// |session|'s session ID context (see |SSL_CTX_set_session_id_context|) and
	// sets |*out_len| to its length.
	SSL_SESSION_get0_id_context :: proc(session: ^SSL_SESSION, out_len: ^u32) -> ^u8 ---

	// SSL_SESSION_set1_id_context sets |session|'s session ID context (see
	// |SSL_CTX_set_session_id_context|) to |sid_ctx|. It returns one on success and
	// zero on error. This function may be useful in writing tests but otherwise
	// should not be used.
	SSL_SESSION_set1_id_context :: proc(session: ^SSL_SESSION, sid_ctx: ^u8, sid_ctx_len: c.size_t) -> i32 ---

	// SSL_SESSION_should_be_single_use returns one if |session| should be
	// single-use (TLS 1.3 and later) and zero otherwise.
	//
	// If this function returns one, clients retain multiple sessions and use each
	// only once. This prevents passive observers from correlating connections with
	// tickets. See RFC 8446, appendix C.4. If it returns zero, |session| cannot be
	// used without leaking a correlator.
	SSL_SESSION_should_be_single_use :: proc(session: ^SSL_SESSION) -> i32 ---

	// SSL_SESSION_is_resumable returns one if |session| is complete and contains a
	// session ID or ticket. It returns zero otherwise. Note this function does not
	// ensure |session| will be resumed. It may be expired, dropped by the server,
	// or associated with incompatible parameters.
	SSL_SESSION_is_resumable :: proc(session: ^SSL_SESSION) -> i32 ---

	// SSL_SESSION_has_ticket returns one if |session| has a ticket and zero
	// otherwise.
	SSL_SESSION_has_ticket :: proc(session: ^SSL_SESSION) -> i32 ---

	// SSL_SESSION_get0_ticket sets |*out_ticket| and |*out_len| to |session|'s
	// ticket, or NULL and zero if it does not have one. |out_ticket| may be NULL
	// if only the ticket length is needed.
	SSL_SESSION_get0_ticket :: proc(session: ^SSL_SESSION, out_ticket: ^^u8, out_len: ^c.size_t) ---

	// SSL_SESSION_set_ticket sets |session|'s ticket to |ticket|. It returns one on
	// success and zero on error. This function may be useful in writing tests but
	// otherwise should not be used.
	SSL_SESSION_set_ticket :: proc(session: ^SSL_SESSION, ticket: ^u8, ticket_len: c.size_t) -> i32 ---

	// SSL_SESSION_get_ticket_lifetime_hint returns ticket lifetime hint of
	// |session| in seconds or zero if none was set.
	SSL_SESSION_get_ticket_lifetime_hint :: proc(session: ^SSL_SESSION) -> u32 ---

	// SSL_SESSION_get0_cipher returns the cipher negotiated by the connection which
	// established |session|.
	//
	// Note that, in TLS 1.3, there is no guarantee that resumptions with |session|
	// will use that cipher. Prefer calling |SSL_get_current_cipher| on the |SSL|
	// instead.
	SSL_SESSION_get0_cipher :: proc(session: ^SSL_SESSION) -> ^SSL_CIPHER ---

	// SSL_SESSION_has_peer_sha256 returns one if |session| has a SHA-256 hash of
	// the peer's certificate retained and zero if the peer did not present a
	// certificate or if this was not enabled when |session| was created. See also
	// |SSL_CTX_set_retain_only_sha256_of_client_certs|.
	SSL_SESSION_has_peer_sha256 :: proc(session: ^SSL_SESSION) -> i32 ---

	// SSL_SESSION_get0_peer_sha256 sets |*out_ptr| and |*out_len| to the SHA-256
	// hash of the peer certificate retained in |session|, or NULL and zero if it
	// does not have one. See also |SSL_CTX_set_retain_only_sha256_of_client_certs|.
	SSL_SESSION_get0_peer_sha256 :: proc(session: ^SSL_SESSION, out_ptr: ^^u8, out_len: ^c.size_t) ---

	// SSL_SESSION_is_resumable_across_names returns one if |session| may be resumed
	// with any identity in the server certificate and zero otherwise. See
	// draft-ietf-tls-cross-sni-resumption.
	SSL_SESSION_is_resumable_across_names :: proc(session: ^SSL_SESSION) -> i32 ---
}

// Session caching.
//
// Session caching allows connections to be established more efficiently based
// on saved parameters from a previous connection, called a session (see
// |SSL_SESSION|). The client offers a saved session, using an opaque identifier
// from a previous connection. The server may accept the session, if it has the
// parameters available. Otherwise, it will decline and continue with a full
// handshake.
//
// This requires both the client and the server to retain session state. A
// client does so with a stateful session cache. A server may do the same or, if
// supported by both sides, statelessly using session tickets. For more
// information on the latter, see the next section.
//
// For a server, the library implements a built-in internal session cache as an
// in-memory hash table. Servers may also use |SSL_CTX_sess_set_get_cb| and
// |SSL_CTX_sess_set_new_cb| to implement a custom external session cache. In
// particular, this may be used to share a session cache between multiple
// servers in a large deployment. An external cache may be used in addition to
// or instead of the internal one. Use |SSL_CTX_set_session_cache_mode| to
// toggle the internal cache.
//
// For a client, the only option is an external session cache. Clients may use
// |SSL_CTX_sess_set_new_cb| to register a callback for when new sessions are
// available. These may be cached and, in subsequent compatible connections,
// configured with |SSL_set_session|.
//
// Note that offering or accepting a session short-circuits certificate
// verification and most parameter negotiation. Resuming sessions across
// different contexts may result in security failures and surprising
// behavior. For a typical client, this means sessions for different hosts must
// be cached under different keys. A client that connects to the same host with,
// e.g., different cipher suite settings or client certificates should also use
// separate session caches between those contexts. Servers should also partition
// session caches between SNI hosts with |SSL_CTX_set_session_id_context|.
//
// Note also, in TLS 1.2 and earlier, offering sessions allows passive observers
// to correlate different client connections. TLS 1.3 and later fix this,
// provided clients use sessions at most once. Session caches are managed by the
// caller in BoringSSL, so this must be implemented externally. See
// |SSL_SESSION_should_be_single_use| for details.

// SSL_SESS_CACHE_OFF disables all session caching.
SSL_SESS_CACHE_OFF :: 0x0000

// SSL_SESS_CACHE_CLIENT enables session caching for a client. The internal
// cache is never used on a client, so this only enables the callbacks.
SSL_SESS_CACHE_CLIENT :: 0x0001

// SSL_SESS_CACHE_SERVER enables session caching for a server.
SSL_SESS_CACHE_SERVER :: 0x0002

// SSL_SESS_CACHE_BOTH enables session caching for both client and server.
SSL_SESS_CACHE_BOTH :: (SSL_SESS_CACHE_CLIENT|SSL_SESS_CACHE_SERVER)

// SSL_SESS_CACHE_NO_AUTO_CLEAR disables automatically calling
// |SSL_CTX_flush_sessions| every 255 connections.
SSL_SESS_CACHE_NO_AUTO_CLEAR :: 0x0080

// SSL_SESS_CACHE_NO_INTERNAL_LOOKUP, on a server, disables looking up a session
// from the internal session cache.
SSL_SESS_CACHE_NO_INTERNAL_LOOKUP :: 0x0100

// SSL_SESS_CACHE_NO_INTERNAL_STORE, on a server, disables storing sessions in
// the internal session cache.
SSL_SESS_CACHE_NO_INTERNAL_STORE :: 0x0200

// SSL_SESS_CACHE_NO_INTERNAL, on a server, disables the internal session
// cache.
SSL_SESS_CACHE_NO_INTERNAL :: (SSL_SESS_CACHE_NO_INTERNAL_LOOKUP|SSL_SESS_CACHE_NO_INTERNAL_STORE)

@(default_calling_convention="c")
foreign lib {
	// SSL_set_session, for a client, configures |ssl| to offer to resume |session|
	// in the initial handshake and returns one. The caller retains ownership of
	// |session|. Note that configuring a session assumes the authentication in the
	// session is valid. For callers that wish to revalidate the session before
	// offering, see |SSL_SESSION_get0_peer_certificates|,
	// |SSL_SESSION_get0_signed_cert_timestamp_list|, and
	// |SSL_SESSION_get0_ocsp_response|.
	//
	// It is an error to call this function after the handshake has begun.
	SSL_set_session :: proc(ssl: ^SSL, session: ^SSL_SESSION) -> i32 ---
}

// SSL_DEFAULT_SESSION_TIMEOUT is the default lifetime, in seconds, of a
// session in TLS 1.2 or earlier. This is how long we are willing to use the
// secret to encrypt traffic without fresh key material.
SSL_DEFAULT_SESSION_TIMEOUT :: (2*60*60)

// SSL_DEFAULT_SESSION_PSK_DHE_TIMEOUT is the default lifetime, in seconds, of a
// session for TLS 1.3 psk_dhe_ke. This is how long we are willing to use the
// secret as an authenticator.
SSL_DEFAULT_SESSION_PSK_DHE_TIMEOUT :: (2*24*60*60)

// SSL_DEFAULT_SESSION_AUTH_TIMEOUT is the default non-renewable lifetime, in
// seconds, of a TLS 1.3 session. This is how long we are willing to trust the
// signature in the initial handshake.
SSL_DEFAULT_SESSION_AUTH_TIMEOUT :: (7*24*60*60)

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_timeout sets the lifetime, in seconds, of TLS 1.2 (or earlier)
	// sessions created in |ctx| to |timeout|.
	SSL_CTX_set_timeout :: proc(ctx: ^SSL_CTX, timeout: u32) -> u32 ---

	// SSL_CTX_set_session_psk_dhe_timeout sets the lifetime, in seconds, of TLS 1.3
	// sessions created in |ctx| to |timeout|.
	SSL_CTX_set_session_psk_dhe_timeout :: proc(ctx: ^SSL_CTX, timeout: u32) ---

	// SSL_CTX_get_timeout returns the lifetime, in seconds, of TLS 1.2 (or earlier)
	// sessions created in |ctx|.
	SSL_CTX_get_timeout :: proc(ctx: ^SSL_CTX) -> u32 ---
}

// SSL_MAX_SID_CTX_LENGTH is the maximum length of a session ID context.
SSL_MAX_SID_CTX_LENGTH :: 32

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_session_id_context sets |ctx|'s session ID context to |sid_ctx|.
	// It returns one on success and zero on error. The session ID context is an
	// application-defined opaque byte string. A session will not be used in a
	// connection without a matching session ID context.
	//
	// For a server, if |SSL_VERIFY_PEER| is enabled, it is an error to not set a
	// session ID context.
	SSL_CTX_set_session_id_context :: proc(ctx: ^SSL_CTX, sid_ctx: ^u8, sid_ctx_len: c.size_t) -> i32 ---

	// SSL_set_session_id_context sets |ssl|'s session ID context to |sid_ctx|. It
	// returns one on success and zero on error. See also
	// |SSL_CTX_set_session_id_context|.
	SSL_set_session_id_context :: proc(ssl: ^SSL, sid_ctx: ^u8, sid_ctx_len: c.size_t) -> i32 ---

	// SSL_get0_session_id_context returns a pointer to |ssl|'s session ID context
	// and sets |*out_len| to its length.  It returns NULL on error.
	SSL_get0_session_id_context :: proc(ssl: ^SSL, out_len: ^c.size_t) -> ^u8 ---
}

// SSL_SESSION_CACHE_MAX_SIZE_DEFAULT is the default maximum size of a session
// cache.
SSL_SESSION_CACHE_MAX_SIZE_DEFAULT :: (1024*20)

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_add_session inserts |session| into |ctx|'s internal session cache. It
	// returns one on success and zero on error or if |session| is already in the
	// cache. The caller retains its reference to |session|.
	SSL_CTX_add_session :: proc(ctx: ^SSL_CTX, session: ^SSL_SESSION) -> i32 ---

	// SSL_CTX_remove_session removes |session| from |ctx|'s internal session cache.
	// It returns one on success and zero if |session| was not in the cache.
	SSL_CTX_remove_session :: proc(ctx: ^SSL_CTX, session: ^SSL_SESSION) -> i32 ---

	// SSL_CTX_flush_sessions removes all sessions from |ctx| which have expired as
	// of time |time|. If |time| is zero, all sessions are removed.
	SSL_CTX_flush_sessions :: proc(ctx: ^SSL_CTX, time: u64) ---
}

// SSL_new_session_cb is the type of the callback that is called when a new
// session is established and ready to be cached.
SSL_new_session_cb :: proc "c" (ssl: ^SSL, session: ^SSL_SESSION) -> i32

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_sess_set_new_cb sets the callback to be called when a new session is
	// established and ready to be cached. If the session cache is disabled (the
	// appropriate one of |SSL_SESS_CACHE_CLIENT| or |SSL_SESS_CACHE_SERVER| is
	// unset), the callback is not called.
	//
	// The callback is passed a reference to |session|. It returns one if it takes
	// ownership (and then calls |SSL_SESSION_free| when done) and zero otherwise. A
	// consumer which places |session| into an in-memory cache will likely return
	// one, with the cache calling |SSL_SESSION_free|. A consumer which serializes
	// |session| with |SSL_SESSION_to_bytes| may not need to retain |session| and
	// will likely return zero. Returning one is equivalent to calling
	// |SSL_SESSION_up_ref| and then returning zero.
	//
	// Note: For a client, the callback may be called on abbreviated handshakes if a
	// ticket is renewed. Further, it may not be called until some time after
	// |SSL_do_handshake| or |SSL_connect| completes if False Start is enabled. Thus
	// it's recommended to use this callback over calling |SSL_get_session| on
	// handshake completion.
	SSL_CTX_sess_set_new_cb :: proc(ctx: ^SSL_CTX, new_session_cb: SSL_new_session_cb) ---

	// SSL_CTX_sess_get_new_cb returns the callback set by
	// |SSL_CTX_sess_set_new_cb|.
	SSL_CTX_sess_get_new_cb :: proc(ctx: ^SSL_CTX) -> SSL_new_session_cb ---
}

// SSL_remove_session_cb is the type of the callback that is called when a
// session is removed from the internal session cache.
SSL_remove_session_cb :: proc "c" (ctx: ^SSL_CTX, session: ^SSL_SESSION)

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_sess_set_remove_cb sets a callback which is called when a session is
	// removed from the internal session cache.
	//
	// TODO(davidben): What is the point of this callback? It seems useless since it
	// only fires on sessions in the internal cache.
	SSL_CTX_sess_set_remove_cb :: proc(ctx: ^SSL_CTX, remove_session_cb: SSL_remove_session_cb) ---

	// SSL_CTX_sess_get_remove_cb returns the callback set by
	// |SSL_CTX_sess_set_remove_cb|.
	SSL_CTX_sess_get_remove_cb :: proc(ctx: ^SSL_CTX) -> SSL_remove_session_cb ---
}

// SSL_get_session_cb is the type of the callback that is called to look up a
// session by ID for a server.
SSL_get_session_cb :: proc "c" (ssl: ^SSL, id: ^u8, id_len: i32, out_copy: ^i32) -> ^SSL_SESSION

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_sess_set_get_cb sets a callback to look up a session by ID for a
	// server. The callback is passed the session ID and should return a matching
	// |SSL_SESSION| or NULL if not found. It should set |*out_copy| to zero and
	// return a new reference to the session. This callback is not used for a
	// client.
	//
	// For historical reasons, if |*out_copy| is set to one (default), the SSL
	// library will take a new reference to the returned |SSL_SESSION|, expecting
	// the callback to return a non-owning pointer. This is not recommended. If
	// |ctx| and thus the callback is used on multiple threads, the session may be
	// removed and invalidated before the SSL library calls |SSL_SESSION_up_ref|,
	// whereas the callback may synchronize internally.
	//
	// To look up a session asynchronously, the callback may return
	// |SSL_magic_pending_session_ptr|. See the documentation for that function and
	// |SSL_ERROR_PENDING_SESSION|.
	//
	// If the internal session cache is enabled, the callback is only consulted if
	// the internal cache does not return a match.
	SSL_CTX_sess_set_get_cb :: proc(ctx: ^SSL_CTX, get_session_cb: SSL_get_session_cb) ---

	// SSL_CTX_sess_get_get_cb returns the callback set by
	// |SSL_CTX_sess_set_get_cb|.
	SSL_CTX_sess_get_get_cb :: proc(ctx: ^SSL_CTX) -> SSL_get_session_cb ---

	// SSL_magic_pending_session_ptr returns a magic |SSL_SESSION|* which indicates
	// that the session isn't currently unavailable. |SSL_get_error| will then
	// return |SSL_ERROR_PENDING_SESSION| and the handshake can be retried later
	// when the lookup has completed.
	SSL_magic_pending_session_ptr :: proc() -> ^SSL_SESSION ---

	// SSL_CTX_set_resumption_across_names_enabled configures whether |ctx|, as a
	// TLS 1.3 server, signals its sessions are compatible with any identity in the
	// server certificate, e.g. all DNS names in the subjectAlternateNames list.
	// This does not change BoringSSL's resumption behavior, only whether it signals
	// this to the client. See draft-ietf-tls-cross-sni-resumption.
	//
	// When this is enabled, all identities in the server certificate should by
	// hosted by servers that accept TLS 1.3 tickets issued by |ctx|. The connection
	// will otherwise function, but performance may suffer from clients wasting
	// single-use tickets.
	SSL_CTX_set_resumption_across_names_enabled :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_set_resumption_across_names_enabled configures whether |ssl|, as a
	// TLS 1.3 server, signals its sessions are compatible with any identity in the
	// server certificate, e.g. all DNS names in the subjectAlternateNames list.
	// This does not change BoringSSL's resumption behavior, only whether it signals
	// this to the client. See draft-ietf-tls-cross-sni-resumption.
	//
	// When this is enabled, all identities in the server certificate should by
	// hosted by servers that accept TLS 1.3 tickets issued by |ssl|. The connection
	// will otherwise function, but performance may suffer from clients wasting
	// single-use tickets.
	SSL_set_resumption_across_names_enabled :: proc(ssl: ^SSL, enabled: i32) ---
}

// Session tickets.
//
// Session tickets, from RFC 5077, allow session resumption without server-side
// state. The server maintains a secret ticket key and sends the client opaque
// encrypted session parameters, called a ticket. When offering the session, the
// client sends the ticket which the server decrypts to recover session state.
// Session tickets are enabled by default but may be disabled with
// |SSL_OP_NO_TICKET|.
//
// On the client, ticket-based sessions use the same APIs as ID-based tickets.
// Callers do not need to handle them differently.
//
// On the server, tickets are encrypted and authenticated with a secret key.
// By default, an |SSL_CTX| will manage session ticket encryption keys by
// generating them internally and rotating every 48 hours. Tickets are minted
// and processed transparently. The following functions may be used to configure
// a persistent key or implement more custom behavior, including key rotation
// and sharing keys between multiple servers in a large deployment. There are
// three levels of customisation possible:
//
// 1) One can simply set the keys with |SSL_CTX_set_tlsext_ticket_keys|.
// 2) One can configure an |EVP_CIPHER_CTX| and |HMAC_CTX| directly for
//    encryption and authentication.
// 3) One can configure an |SSL_TICKET_AEAD_METHOD| to have more control
//    and the option of asynchronous decryption.
//
// An attacker that compromises a server's session ticket key can impersonate
// the server and, prior to TLS 1.3, retroactively decrypt all application
// traffic from sessions using that ticket key. Thus ticket keys must be
// regularly rotated for forward secrecy. Note the default key is rotated
// automatically once every 48 hours but manually configured keys are not.

// SSL_DEFAULT_TICKET_KEY_ROTATION_INTERVAL is the interval with which the
// default session ticket encryption key is rotated, if in use. If any
// non-default ticket encryption mechanism is configured, automatic rotation is
// disabled.
SSL_DEFAULT_TICKET_KEY_ROTATION_INTERVAL :: (2*24*60*60)

// SSL_TICKET_KEY_NAME_LEN is the length of the key name prefix of a session
// ticket.
SSL_TICKET_KEY_NAME_LEN :: 16

// ssl_ticket_aead_result_t enumerates the possible results from decrypting a
// ticket with an |SSL_TICKET_AEAD_METHOD|.
ssl_ticket_aead_result_t :: enum u32 {
	// ssl_ticket_aead_success indicates that the ticket was successfully
	// decrypted.
	success       = 0,

	// ssl_ticket_aead_retry indicates that the operation could not be
	// immediately completed and must be reattempted, via |open|, at a later
	// point.
	retry         = 1,

	// ssl_ticket_aead_ignore_ticket indicates that the ticket should be ignored
	// (i.e. is corrupt or otherwise undecryptable).
	ignore_ticket = 2,

	// ssl_ticket_aead_error indicates that a fatal error occurred and the
	// handshake should be terminated.
	error         = 3,
}

// ssl_ticket_aead_method_st (aka |SSL_TICKET_AEAD_METHOD|) contains methods
// for encrypting and decrypting session tickets.
ssl_ticket_aead_method_st :: struct {
	// max_overhead returns the maximum number of bytes of overhead that |seal|
	// may add.
	max_overhead: proc "c" (ssl: ^SSL) -> c.size_t,

	// seal encrypts and authenticates |in_len| bytes from |in|, writes, at most,
	// |max_out_len| bytes to |out|, and puts the number of bytes written in
	// |*out_len|. The |in| and |out| buffers may be equal but will not otherwise
	// alias. It returns one on success or zero on error. If the function returns
	// but |*out_len| is zero, BoringSSL will skip sending a ticket.
	seal: proc "c" (ssl: ^SSL, out: ^u8, out_len: ^c.size_t, max_out_len: c.size_t, _in: ^u8, in_len: c.size_t) -> i32,

	// open authenticates and decrypts |in_len| bytes from |in|, writes, at most,
	// |max_out_len| bytes of plaintext to |out|, and puts the number of bytes
	// written in |*out_len|. The |in| and |out| buffers may be equal but will
	// not otherwise alias. See |ssl_ticket_aead_result_t| for details of the
	// return values. In the case that a retry is indicated, the caller should
	// arrange for the high-level operation on |ssl| to be retried when the
	// operation is completed, which will result in another call to |open|.
	open: proc "c" (ssl: ^SSL, out: ^u8, out_len: ^c.size_t, max_out_len: c.size_t, _in: ^u8, in_len: c.size_t) -> ssl_ticket_aead_result_t,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_ticket_aead_method configures a custom ticket AEAD method table
	// on |ctx|. |aead_method| must remain valid for the lifetime of |ctx|.
	SSL_CTX_set_ticket_aead_method :: proc(ctx: ^SSL_CTX, aead_method: ^SSL_TICKET_AEAD_METHOD) ---

	// SSL_process_tls13_new_session_ticket processes an unencrypted TLS 1.3
	// NewSessionTicket message from |buf| and returns a resumable |SSL_SESSION|,
	// or NULL on error. The caller takes ownership of the returned session and
	// must call |SSL_SESSION_free| to free it.
	//
	// |buf| contains |buf_len| bytes that represents a complete NewSessionTicket
	// message including its header, i.e., one byte for the type (0x04) and three
	// bytes for the length. |buf| must contain only one such message.
	//
	// This function may be used to process NewSessionTicket messages in TLS 1.3
	// clients that are handling the record layer externally.
	SSL_process_tls13_new_session_ticket :: proc(ssl: ^SSL, buf: ^u8, buf_len: c.size_t) -> ^SSL_SESSION ---

	// SSL_CTX_set_num_tickets configures |ctx| to send |num_tickets| immediately
	// after a successful TLS 1.3 handshake as a server. It returns one. Large
	// values of |num_tickets| will be capped within the library.
	//
	// By default, BoringSSL sends two tickets.
	SSL_CTX_set_num_tickets :: proc(ctx: ^SSL_CTX, num_tickets: c.size_t) -> i32 ---

	// SSL_CTX_get_num_tickets returns the number of tickets |ctx| will send
	// immediately after a successful TLS 1.3 handshake as a server.
	SSL_CTX_get_num_tickets :: proc(ctx: ^SSL_CTX) -> c.size_t ---
}

// Diffie-Hellman groups and ephemeral key exchanges.
//
// Most TLS handshakes (ECDHE cipher suites in TLS 1.2, and all supported TLS
// 1.3 modes) incorporate an ephemeral key exchange, most commonly using
// Elliptic Curve Diffie-Hellman (ECDH), as described in RFC 8422. The key
// exchange algorithm is negotiated separately from the cipher suite, using
// NamedGroup values, which define Diffie-Hellman groups.
//
// Historically, these values were known as "curves", in reference to ECDH, and
// some APIs refer to the original name. RFC 7919 renamed them to "groups" in
// reference to Diffie-Hellman in general. These values are also used to select
// experimental post-quantum KEMs. Though not Diffie-Hellman groups, KEMs can
// fill a similar role in TLS, so they use the same codepoints.
//
// In TLS 1.2, the ECDH values also negotiate elliptic curves used in ECDSA. In
// TLS 1.3 and later, ECDSA curves are part of the signature algorithm. See
// |SSL_SIGN_*|.

// SSL_GROUP_* define TLS group IDs.
SSL_GROUP_SECP256R1               :: 23
SSL_GROUP_SECP384R1               :: 24
SSL_GROUP_SECP521R1               :: 25
SSL_GROUP_X25519                  :: 29
SSL_GROUP_X25519_MLKEM768         :: 0x11ec
SSL_GROUP_X25519_KYBER768_DRAFT00 :: 0x6399
SSL_GROUP_MLKEM1024               :: 0x0202

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set1_group_ids sets the preferred groups for |ctx| to |group_ids|.
	// Each element of |group_ids| should be a unique one of the |SSL_GROUP_*|
	// constants. If |group_ids| is empty, a default list will be set instead. It
	// returns one on success and zero on failure.
	SSL_CTX_set1_group_ids :: proc(ctx: ^SSL_CTX, group_ids: ^u16, num_group_ids: c.size_t) -> i32 ---

	// SSL_set1_group_ids sets the preferred groups for |ssl| to |group_ids|. Each
	// element of |group_ids| should be a unique one of the |SSL_GROUP_*| constants.
	// If |group_ids| is empty, a default list will be set instead. It returns one
	// on success and zero on failure.
	SSL_set1_group_ids :: proc(ssl: ^SSL, group_ids: ^u16, num_group_ids: c.size_t) -> i32 ---
}

// SSL_GROUP_FLAG_* define flags used with SSL_CTX_set1_group_ids_with_flags
// and SSL_set1_group_ids_with_flags.
//
// If configuring a server, SSL_GROUP_FLAG_EQUAL_PREFERENCE_WITH_NEXT indicates
// that the corresponding group has equal preference with the next member of the
// list of groups being configured. Assigning equal preference to a range of
// consecutively listed groups allows a server to partially respect the
// client's preferences when |SSL_OP_CIPHER_SERVER_PREFERENCE| is enabled.
SSL_GROUP_FLAG_EQUAL_PREFERENCE_WITH_NEXT :: 0x01

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set1_group_ids_with_flags sets the preferred groups for |ctx| to
	// |group_ids|, using the corresponding |flags| for each element, which is a set
	// of SSL_GROUP_FLAG_* values ORed together. Each element of |group_ids| should
	// be a unique one of the |SSL_GROUP_*| constants. If |group_ids| is empty, a
	// default list of groups and flags defaulting to zero will be set instead.
	// |group_ids| and |flags| should both have |num_group_ids| elements. It returns
	// one on success and zero on failure.
	SSL_CTX_set1_group_ids_with_flags :: proc(ctx: ^SSL_CTX, group_ids: ^u16, flags: ^u32, num_group_ids: c.size_t) -> i32 ---

	// SSL_set1_group_ids_with_flags sets the preferred groups for |ssl| to
	// |group_ids|, using the corresponding |flags| for each element, which is a set
	// of SSL_GROUP_FLAG_* values ORed toegether. Each element of |group_ids| should
	// be a unique one of the |SSL_GROUP_*| constants. If |group_ids| is empty, a
	// default list of groups and flags defaulting to zero will be set instead.
	// |group_ids| and |flags| should both have |num_group_ids| elements.  It
	// returns one on success and zero on failure.
	SSL_set1_group_ids_with_flags :: proc(ssl: ^SSL, group_ids: ^u16, flags: ^u32, num_group_ids: c.size_t) -> i32 ---

	// SSL_get_group_id returns the ID of the group used by |ssl|'s most recently
	// completed handshake, or 0 if not applicable.
	SSL_get_group_id :: proc(ssl: ^SSL) -> u16 ---

	// SSL_get_group_name returns a human-readable name for the group specified by
	// the given TLS group ID, or NULL if the group is unknown.
	SSL_get_group_name :: proc(group_id: u16) -> cstring ---

	// SSL_get_all_group_names outputs a list of possible strings
	// |SSL_get_group_name| may return in this version of BoringSSL. It writes at
	// most |max_out| entries to |out| and returns the total number it would have
	// written, if |max_out| had been large enough. |max_out| may be initially set
	// to zero to size the output.
	//
	// This function is only intended to help initialize tables in callers that want
	// possible strings pre-declared. This list would not be suitable to set a list
	// of supported features. It is in no particular order, and may contain
	// placeholder, experimental, or deprecated values that do not apply to every
	// caller. Future versions of BoringSSL may also return strings not in this
	// list, so this does not apply if, say, sending strings across services.
	SSL_get_all_group_names :: proc(out: ^cstring, max_out: c.size_t) -> c.size_t ---

	// SSL_CTX_set1_groups_list decodes |groups| as a non-empty colon-separated list
	// of group names (e.g. "X25519" or "P-256") and sets |ctx|'s preferred groups
	// to the result. The list must not contain duplicates. It returns one on
	// success and zero on failure.
	SSL_CTX_set1_groups_list :: proc(ctx: ^SSL_CTX, groups: cstring) -> i32 ---

	// SSL_set1_groups_list decodes |groups| as a non-empty colon-separated list of
	// group names (e.g. "X25519" or "P-256") and sets |ssl|'s preferred groups to
	// the result. The list must not contain duplicates. It returns one on success
	// and zero on failure.
	SSL_set1_groups_list :: proc(ssl: ^SSL, groups: cstring) -> i32 ---

	// SSL_set1_client_key_shares, when called by a client before the handshake,
	// configures |ssl| to send a key_share extension in the initial ClientHello
	// containing exactly the groups given by |group_ids|, in the order given. Each
	// member of |group_ids| should be one of the |SSL_GROUP_*| constants, and they
	// must be unique. This function returns one on success and zero on failure.
	//
	// If non-empty, the sequence of |group_ids| must be a (not necessarily
	// contiguous) subsequence of the groups supported by |ssl|, which may have been
	// configured explicitly on |ssl| or its context, or populated by default.
	// Caller should finish configuring the group list before calling this function.
	// Changing the supported groups for |ssl| after having set client key shares
	// will result in the key share selections being reset if this constraint no
	// longer holds.
	//
	// Setting an empty sequence of |group_ids| results in an empty client
	// key_share, which will cause the handshake to always take an extra round-trip
	// for HelloRetryRequest.
	//
	// An extra round-trip will be needed if the server's choice of group is not
	// among the key shares sent; conversely, sending any key shares other than the
	// server's choice wastes CPU and bandwidth (the latter is particularly costly
	// for post-quantum key exchanges). To avoid these sub-optimal outcomes,
	// key shares should be chosen such that they are likely to be supported by the
	// peer server.
	SSL_set1_client_key_shares :: proc(ssl: ^SSL, group_ids: ^u16, num_group_ids: c.size_t) -> i32 ---

	// SSL_set1_server_supported_groups_hint, when |ssl| is a client, indicates that
	// the server is likely to support groups listed in |server_groups|, in order of
	// decreasing server preference. This function returns one on success and zero
	// on error. This may be used when receiving a server hint, such as described in
	// draft-ietf-tls-key-share-prediction.
	//
	// If called, |ssl| will try to predict the server's selected named group based
	// on |ssl|'s local preferences and |server_groups|. If it predicts a group, it
	// will then send an initial ClientHello with key_share extension containing
	// only this prediction. In this case, the prediction will supersede any
	// configuration from |SSL_set1_client_key_shares|. This is a convenience
	// function so that callers do not need to process the server preference list
	// themselves.
	//
	// Groups listed in |server_groups| should be identified by their TLS group IDs,
	// such as the |SSL_GROUP_*| constants. A server may implement groups not known
	// to BoringSSL, so |server_groups| may contain unrecognized group IDs. If so,
	// this function will ignore them.
	SSL_set1_server_supported_groups_hint :: proc(ssl: ^SSL, server_groups: ^u16, num_server_groups: c.size_t) -> i32 ---
}

// Certificate verification.
//
// SSL may authenticate either endpoint with an X.509 certificate. Typically
// this is used to authenticate the server to the client. These functions
// configure certificate verification.
//
// WARNING: By default, certificate verification errors on a client are not
// fatal. See |SSL_VERIFY_NONE| This may be configured with
// |SSL_CTX_set_verify|.
//
// By default clients are anonymous but a server may request a certificate from
// the client by setting |SSL_VERIFY_PEER|.
//
// Many of these functions use OpenSSL's legacy X.509 stack which is
// underdocumented and deprecated, but the replacement isn't ready yet. For
// now, consumers may use the existing stack or bypass it by performing
// certificate verification externally. This may be done with
// |SSL_CTX_set_cert_verify_callback| or by extracting the chain with
// |SSL_get_peer_cert_chain| after the handshake. In the future, functions will
// be added to use the SSL stack without dependency on any part of the legacy
// X.509 and ASN.1 stack.
//
// To augment certificate verification, a client may also enable OCSP stapling
// (RFC 6066) and Certificate Transparency (RFC 6962) extensions.

// SSL_VERIFY_NONE, on a client, verifies the server certificate but does not
// make errors fatal. The result may be checked with |SSL_get_verify_result|. On
// a server it does not request a client certificate. This is the default.
SSL_VERIFY_NONE :: 0x00

// SSL_VERIFY_PEER, on a client, makes server certificate errors fatal. On a
// server it requests a client certificate and makes errors fatal. However,
// anonymous clients are still allowed. See
// |SSL_VERIFY_FAIL_IF_NO_PEER_CERT|.
SSL_VERIFY_PEER :: 0x01

// SSL_VERIFY_FAIL_IF_NO_PEER_CERT configures a server to reject connections if
// the client declines to send a certificate. This flag must be used together
// with |SSL_VERIFY_PEER|, otherwise it won't work.
SSL_VERIFY_FAIL_IF_NO_PEER_CERT :: 0x02

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_verify configures certificate verification behavior. |mode| is
	// one of the |SSL_VERIFY_*| values defined above. |callback| should be NULL.
	//
	// If |callback| is non-NULL, it is called as in |X509_STORE_CTX_set_verify_cb|,
	// which is a deprecated and fragile mechanism to run the default certificate
	// verification process, but suppress individual errors in it. See
	// |X509_STORE_CTX_set_verify_cb| for details, If set, the callback may use
	// |SSL_get_ex_data_X509_STORE_CTX_idx| with |X509_STORE_CTX_get_ex_data| to
	// look up the |SSL| from |store_ctx|.
	//
	// WARNING: |callback| is not suitable for implementing custom certificate
	// check, accepting all certificates, or extracting the certificate after
	// verification. It does not replace the default process and is called multiple
	// times throughout that process. It is also very difficult to implement this
	// callback safely, without inadvertently relying on implementation details or
	// making incorrect assumptions about when the callback is called.
	//
	// Instead, use |SSL_CTX_set_custom_verify| or
	// |SSL_CTX_set_cert_verify_callback| to customize certificate verification.
	// Those callbacks can inspect the peer-sent chain, call |X509_verify_cert| and
	// inspect the result, or perform other operations more straightforwardly.
	SSL_CTX_set_verify :: proc(ctx: ^SSL_CTX, mode: i32, callback: proc "c" (ok: i32, store_ctx: ^X509_STORE_CTX) -> i32) ---

	// SSL_set_verify configures certificate verification behavior. |mode| is one of
	// the |SSL_VERIFY_*| values defined above. |callback| should be NULL.
	//
	// If |callback| is non-NULL, it is called as in |X509_STORE_CTX_set_verify_cb|,
	// which is a deprecated and fragile mechanism to run the default certificate
	// verification process, but suppress individual errors in it. See
	// |X509_STORE_CTX_set_verify_cb| for details, If set, the callback may use
	// |SSL_get_ex_data_X509_STORE_CTX_idx| with |X509_STORE_CTX_get_ex_data| to
	// look up the |SSL| from |store_ctx|.
	//
	// WARNING: |callback| is not suitable for implementing custom certificate
	// check, accepting all certificates, or extracting the certificate after
	// verification. It does not replace the default process and is called multiple
	// times throughout that process. It is also very difficult to implement this
	// callback safely, without inadvertently relying on implementation details or
	// making incorrect assumptions about when the callback is called.
	//
	// Instead, use |SSL_set_custom_verify| or |SSL_set_cert_verify_callback| to
	// customize certificate verification. Those callbacks can inspect the peer-sent
	// chain, call |X509_verify_cert| and inspect the result, or perform other
	// operations more straightforwardly.
	SSL_set_verify :: proc(ssl: ^SSL, mode: i32, callback: proc "c" (ok: i32, store_ctx: ^X509_STORE_CTX) -> i32) ---
}

ssl_verify_result_t :: enum u32 {
	ok      = 0,
	invalid = 1,
	retry   = 2,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_custom_verify configures certificate verification. |mode| is one
	// of the |SSL_VERIFY_*| values defined above. |callback| performs the
	// certificate verification.
	//
	// The callback may call |SSL_get0_peer_certificates| for the certificate chain
	// to validate. The callback should return |ssl_verify_ok| if the certificate is
	// valid. If the certificate is invalid, the callback should return
	// |ssl_verify_invalid| and optionally set |*out_alert| to an alert to send to
	// the peer. Some useful alerts include |SSL_AD_CERTIFICATE_EXPIRED|,
	// |SSL_AD_CERTIFICATE_REVOKED|, |SSL_AD_UNKNOWN_CA|, |SSL_AD_BAD_CERTIFICATE|,
	// |SSL_AD_CERTIFICATE_UNKNOWN|, and |SSL_AD_INTERNAL_ERROR|. See RFC 5246
	// section 7.2.2 for their precise meanings. If unspecified,
	// |SSL_AD_CERTIFICATE_UNKNOWN| will be sent by default.
	//
	// To verify a certificate asynchronously, the callback may return
	// |ssl_verify_retry|. The handshake will then pause with |SSL_get_error|
	// returning |SSL_ERROR_WANT_CERTIFICATE_VERIFY|.
	SSL_CTX_set_custom_verify :: proc(ctx: ^SSL_CTX, mode: i32, callback: proc "c" (ssl: ^SSL, out_alert: ^u8) -> ssl_verify_result_t) ---

	// SSL_set_custom_verify behaves like |SSL_CTX_set_custom_verify| but configures
	// an individual |SSL|.
	SSL_set_custom_verify :: proc(ssl: ^SSL, mode: i32, callback: proc "c" (ssl: ^SSL, out_alert: ^u8) -> ssl_verify_result_t) ---

	// SSL_CTX_get_verify_mode returns |ctx|'s verify mode, set by
	// |SSL_CTX_set_verify|.
	SSL_CTX_get_verify_mode :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_get_verify_mode returns |ssl|'s verify mode, set by |SSL_CTX_set_verify|
	// or |SSL_set_verify|.  It returns -1 on error.
	SSL_get_verify_mode :: proc(ssl: ^SSL) -> i32 ---

	// SSL_CTX_get_verify_callback returns the callback set by
	// |SSL_CTX_set_verify|.
	SSL_CTX_get_verify_callback :: proc(ok: i32, store_ctx: ^X509_STORE_CTX, ctx: ^SSL_CTX) -> proc "c" (i32, ^X509_STORE_CTX) -> i32 ---

	// SSL_get_verify_callback returns the callback set by |SSL_CTX_set_verify| or
	// |SSL_set_verify|.
	SSL_get_verify_callback :: proc(ok: i32, store_ctx: ^X509_STORE_CTX, ssl: ^SSL) -> proc "c" (i32, ^X509_STORE_CTX) -> i32 ---

	// SSL_set1_host sets a DNS name that will be required to be present in the
	// verified leaf certificate. It returns one on success and zero on error.
	//
	// Note: unless _some_ name checking is performed, certificate validation is
	// ineffective. Simply checking that a host has some certificate from a CA is
	// rarely meaningful—you have to check that the CA believed that the host was
	// who you expect to be talking to.
	//
	// By default, both subject alternative names and the subject's common name
	// attribute are checked. The latter has long been deprecated, so callers should
	// call |SSL_set_hostflags| with |X509_CHECK_FLAG_NEVER_CHECK_SUBJECT| to use
	// the standard behavior. https://crbug.com/boringssl/464 tracks fixing the
	// default.
	SSL_set1_host :: proc(ssl: ^SSL, hostname: cstring) -> i32 ---

	// SSL_set_hostflags calls |X509_VERIFY_PARAM_set_hostflags| on the
	// |X509_VERIFY_PARAM| associated with this |SSL*|. |flags| should be some
	// combination of the |X509_CHECK_*| constants.
	SSL_set_hostflags :: proc(ssl: ^SSL, flags: u32) ---

	// SSL_CTX_set_verify_depth sets the maximum depth of a certificate chain
	// accepted in verification. This count excludes both the target certificate and
	// the trust anchor (root certificate).
	SSL_CTX_set_verify_depth :: proc(ctx: ^SSL_CTX, depth: i32) ---

	// SSL_set_verify_depth sets the maximum depth of a certificate chain accepted
	// in verification. This count excludes both the target certificate and the
	// trust anchor (root certificate).
	SSL_set_verify_depth :: proc(ssl: ^SSL, depth: i32) ---

	// SSL_CTX_get_verify_depth returns the maximum depth of a certificate accepted
	// in verification.
	SSL_CTX_get_verify_depth :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_get_verify_depth returns the maximum depth of a certificate accepted in
	// verification.
	SSL_get_verify_depth :: proc(ssl: ^SSL) -> i32 ---

	// SSL_CTX_set1_param sets verification parameters from |param|. It returns one
	// on success and zero on failure. The caller retains ownership of |param|.
	SSL_CTX_set1_param :: proc(ctx: ^SSL_CTX, param: ^X509_VERIFY_PARAM) -> i32 ---

	// SSL_set1_param sets verification parameters from |param|. It returns one on
	// success and zero on failure. The caller retains ownership of |param|.
	SSL_set1_param :: proc(ssl: ^SSL, param: ^X509_VERIFY_PARAM) -> i32 ---

	// SSL_CTX_get0_param returns |ctx|'s |X509_VERIFY_PARAM| for certificate
	// verification. The caller must not release the returned pointer but may call
	// functions on it to configure it.
	SSL_CTX_get0_param :: proc(ctx: ^SSL_CTX) -> ^X509_VERIFY_PARAM ---

	// SSL_get0_param returns |ssl|'s |X509_VERIFY_PARAM| for certificate
	// verification. The caller must not release the returned pointer but may call
	// functions on it to configure it.
	SSL_get0_param :: proc(ssl: ^SSL) -> ^X509_VERIFY_PARAM ---

	// SSL_CTX_set_purpose sets |ctx|'s |X509_VERIFY_PARAM|'s 'purpose' parameter to
	// |purpose|. It returns one on success and zero on error.
	SSL_CTX_set_purpose :: proc(ctx: ^SSL_CTX, purpose: i32) -> i32 ---

	// SSL_set_purpose sets |ssl|'s |X509_VERIFY_PARAM|'s 'purpose' parameter to
	// |purpose|. It returns one on success and zero on error.
	SSL_set_purpose :: proc(ssl: ^SSL, purpose: i32) -> i32 ---

	// SSL_CTX_set_trust sets |ctx|'s |X509_VERIFY_PARAM|'s 'trust' parameter to
	// |trust|. It returns one on success and zero on error.
	SSL_CTX_set_trust :: proc(ctx: ^SSL_CTX, trust: i32) -> i32 ---

	// SSL_set_trust sets |ssl|'s |X509_VERIFY_PARAM|'s 'trust' parameter to
	// |trust|. It returns one on success and zero on error.
	SSL_set_trust :: proc(ssl: ^SSL, trust: i32) -> i32 ---

	// SSL_CTX_set_cert_store sets |ctx|'s certificate store to |store|. It takes
	// ownership of |store|. The store is used for certificate verification.
	//
	// The store is also used for the auto-chaining feature, but this is deprecated.
	// See also |SSL_MODE_NO_AUTO_CHAIN|.
	SSL_CTX_set_cert_store :: proc(ctx: ^SSL_CTX, store: ^X509_STORE) ---

	// SSL_CTX_get_cert_store returns |ctx|'s certificate store.
	SSL_CTX_get_cert_store :: proc(ctx: ^SSL_CTX) -> ^X509_STORE ---

	// SSL_CTX_set_default_verify_paths calls |X509_STORE_set_default_paths| on
	// |ctx|'s store. See that function for details.
	//
	// Using this function is not recommended. In OpenSSL, these defaults are
	// determined by OpenSSL's install prefix. There is no corresponding concept for
	// BoringSSL. Future versions of BoringSSL may change or remove this
	// functionality.
	SSL_CTX_set_default_verify_paths :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_load_verify_locations calls |X509_STORE_load_locations| on |ctx|'s
	// store. See that function for details.
	SSL_CTX_load_verify_locations :: proc(ctx: ^SSL_CTX, ca_file: cstring, ca_dir: cstring) -> i32 ---

	// SSL_get_verify_result returns the result of certificate verification. It is
	// either |X509_V_OK| or a |X509_V_ERR_*| value.
	SSL_get_verify_result :: proc(ssl: ^SSL) -> c.long ---

	// SSL_alert_from_verify_result returns the SSL alert code, such as
	// |SSL_AD_CERTIFICATE_EXPIRED|, that corresponds to an |X509_V_ERR_*| value.
	// The return value is always an alert, even when |result| is |X509_V_OK|.
	SSL_alert_from_verify_result :: proc(result: c.long) -> i32 ---

	// SSL_get_ex_data_X509_STORE_CTX_idx returns the ex_data index used to look up
	// the |SSL| associated with an |X509_STORE_CTX| in the verify callback.
	SSL_get_ex_data_X509_STORE_CTX_idx :: proc() -> i32 ---

	// SSL_CTX_set_cert_verify_callback sets a custom callback to be called on
	// certificate verification rather than |X509_verify_cert|. |store_ctx| contains
	// the verification parameters. The callback should return one on success and
	// zero on fatal error. It may use |X509_STORE_CTX_set_error| to set a
	// verification result.
	//
	// The callback may use |SSL_get_ex_data_X509_STORE_CTX_idx| to recover the
	// |SSL| object from |store_ctx|.
	SSL_CTX_set_cert_verify_callback :: proc(ctx: ^SSL_CTX, callback: proc "c" (store_ctx: ^X509_STORE_CTX, arg: rawptr) -> i32, arg: rawptr) ---

	// SSL_enable_signed_cert_timestamps causes |ssl| (which must be the client end
	// of a connection) to request SCTs from the server. See
	// https://tools.ietf.org/html/rfc6962.
	//
	// Call |SSL_get0_signed_cert_timestamp_list| to recover the SCT after the
	// handshake.
	SSL_enable_signed_cert_timestamps :: proc(ssl: ^SSL) ---

	// SSL_CTX_enable_signed_cert_timestamps enables SCT requests on all client SSL
	// objects created from |ctx|.
	//
	// Call |SSL_get0_signed_cert_timestamp_list| to recover the SCT after the
	// handshake.
	SSL_CTX_enable_signed_cert_timestamps :: proc(ctx: ^SSL_CTX) ---

	// SSL_enable_ocsp_stapling causes |ssl| (which must be the client end of a
	// connection) to request a stapled OCSP response from the server.
	//
	// Call |SSL_get0_ocsp_response| to recover the OCSP response after the
	// handshake.
	SSL_enable_ocsp_stapling :: proc(ssl: ^SSL) ---

	// SSL_CTX_enable_ocsp_stapling enables OCSP stapling on all client SSL objects
	// created from |ctx|.
	//
	// Call |SSL_get0_ocsp_response| to recover the OCSP response after the
	// handshake.
	SSL_CTX_enable_ocsp_stapling :: proc(ctx: ^SSL_CTX) ---

	// SSL_CTX_set0_verify_cert_store sets an |X509_STORE| that will be used
	// exclusively for certificate verification and returns one. Ownership of
	// |store| is transferred to the |SSL_CTX|.
	SSL_CTX_set0_verify_cert_store :: proc(ctx: ^SSL_CTX, store: ^X509_STORE) -> i32 ---

	// SSL_CTX_set1_verify_cert_store sets an |X509_STORE| that will be used
	// exclusively for certificate verification and returns one. An additional
	// reference to |store| will be taken.
	SSL_CTX_set1_verify_cert_store :: proc(ctx: ^SSL_CTX, store: ^X509_STORE) -> i32 ---

	// SSL_set0_verify_cert_store sets an |X509_STORE| that will be used
	// exclusively for certificate verification and returns one. Ownership of
	// |store| is transferred to the |SSL|.
	SSL_set0_verify_cert_store :: proc(ssl: ^SSL, store: ^X509_STORE) -> i32 ---

	// SSL_set1_verify_cert_store sets an |X509_STORE| that will be used
	// exclusively for certificate verification and returns one. An additional
	// reference to |store| will be taken.
	SSL_set1_verify_cert_store :: proc(ssl: ^SSL, store: ^X509_STORE) -> i32 ---

	// SSL_CTX_set_verify_algorithm_prefs configures |ctx| to use |prefs| as the
	// preference list when verifying signatures from the peer's long-term key in
	// TLS 1.2 and up. It returns one on zero on error. |prefs| should not include
	// the internal-only TLS 1.0 value |SSL_SIGN_RSA_PKCS1_MD5_SHA1|.
	//
	// This setting is not used in TLS 1.0 and 1.1. Those protocols always sign a
	// hardcoded algorithm (an MD5/SHA-1 concatenation for RSA, and SHA-1 for
	// ECDSA). BoringSSL will accept those algorithms if and only if those versions
	// are used. To disable them, set the minimum version to TLS 1.2 (default) or
	// higher.
	SSL_CTX_set_verify_algorithm_prefs :: proc(ctx: ^SSL_CTX, prefs: ^u16, num_prefs: c.size_t) -> i32 ---

	// SSL_set_verify_algorithm_prefs configures |ssl| to use |prefs| as the
	// preference list when verifying signatures from the peer's long-term key in
	// TLS 1.2 and up. It returns one on zero on error. |prefs| should not include
	// the internal-only TLS 1.0 value |SSL_SIGN_RSA_PKCS1_MD5_SHA1|.
	//
	// This setting is not used in TLS 1.0 and 1.1. Those protocols always sign a
	// hardcoded algorithm (an MD5/SHA-1 concatenation for RSA, and SHA-1 for
	// ECDSA). BoringSSL will accept those algorithms if and only if those versions
	// are used. To disable them, set the minimum version to TLS 1.2 (default) or
	// higher.
	SSL_set_verify_algorithm_prefs :: proc(ssl: ^SSL, prefs: ^u16, num_prefs: c.size_t) -> i32 ---

	// SSL_set_client_CA_list sets |ssl|'s client certificate CA list to
	// |name_list|. It takes ownership of |name_list|.
	SSL_set_client_CA_list :: proc(ssl: ^SSL, name_list: ^stack_st_X509_NAME) ---

	// SSL_CTX_set_client_CA_list sets |ctx|'s client certificate CA list to
	// |name_list|. It takes ownership of |name_list|.
	SSL_CTX_set_client_CA_list :: proc(ctx: ^SSL_CTX, name_list: ^stack_st_X509_NAME) ---

	// SSL_set0_client_CAs sets |ssl|'s client certificate CA list to |name_list|,
	// which should contain DER-encoded distinguished names (RFC 5280). It takes
	// ownership of |name_list|.
	SSL_set0_client_CAs :: proc(ssl: ^SSL, name_list: ^stack_st_CRYPTO_BUFFER) ---

	// SSL_set0_CA_names sets |ssl|'s CA name list for the certificate authorities
	// extension to |name_list|, which should contain DER-encoded distinguished
	// names (RFC 5280). It takes ownership of |name_list|.
	SSL_set0_CA_names :: proc(ssl: ^SSL, name_list: ^stack_st_CRYPTO_BUFFER) ---

	// SSL_CTX_set0_client_CAs sets |ctx|'s client certificate CA list to
	// |name_list|, which should contain DER-encoded distinguished names (RFC 5280).
	// It takes ownership of |name_list|.
	SSL_CTX_set0_client_CAs :: proc(ctx: ^SSL_CTX, name_list: ^stack_st_CRYPTO_BUFFER) ---

	// SSL_get_client_CA_list returns |ssl|'s client certificate CA list. If |ssl|
	// has not been configured as a client, this is the list configured by
	// |SSL_CTX_set_client_CA_list|.
	//
	// If configured as a client, it returns the client certificate CA list sent by
	// the server. In this mode, the behavior is undefined except during the
	// callbacks set by |SSL_CTX_set_cert_cb| and |SSL_CTX_set_client_cert_cb| or
	// when the handshake is paused because of them.
	SSL_get_client_CA_list :: proc(ssl: ^SSL) -> ^stack_st_X509_NAME ---

	// SSL_get0_server_requested_CAs returns the CAs sent by a server to guide a
	// client in certificate selection. They are a series of DER-encoded X.509
	// names. This function may only be called during a callback set by
	// |SSL_CTX_set_cert_cb| or when the handshake is paused because of it.
	//
	// The returned stack is owned by |ssl|, as are its contents. It should not be
	// used past the point where the handshake is restarted after the callback.
	SSL_get0_server_requested_CAs :: proc(ssl: ^SSL) -> ^stack_st_CRYPTO_BUFFER ---

	// SSL_CTX_get_client_CA_list returns |ctx|'s client certificate CA list.
	SSL_CTX_get_client_CA_list :: proc(ctx: ^SSL_CTX) -> ^stack_st_X509_NAME ---

	// SSL_add_client_CA appends |x509|'s subject to the client certificate CA list.
	// It returns one on success or zero on error. The caller retains ownership of
	// |x509|.
	SSL_add_client_CA :: proc(ssl: ^SSL, x509: ^X509) -> i32 ---

	// SSL_CTX_add_client_CA appends |x509|'s subject to the client certificate CA
	// list. It returns one on success or zero on error. The caller retains
	// ownership of |x509|.
	SSL_CTX_add_client_CA :: proc(ctx: ^SSL_CTX, x509: ^X509) -> i32 ---

	// SSL_load_client_CA_file opens |file| and reads PEM-encoded certificates from
	// it. It returns a newly-allocated stack of the certificate subjects or NULL
	// on error. Duplicates in |file| are ignored.
	SSL_load_client_CA_file :: proc(file: cstring) -> ^stack_st_X509_NAME ---

	// SSL_dup_CA_list makes a deep copy of |list|. It returns the new list on
	// success or NULL on allocation error.
	SSL_dup_CA_list :: proc(list: ^stack_st_X509_NAME) -> ^stack_st_X509_NAME ---

	// SSL_add_file_cert_subjects_to_stack behaves like |SSL_load_client_CA_file|
	// but appends the result to |out|. It returns one on success or zero on
	// error.
	SSL_add_file_cert_subjects_to_stack :: proc(out: ^stack_st_X509_NAME, file: cstring) -> i32 ---

	// SSL_add_bio_cert_subjects_to_stack behaves like
	// |SSL_add_file_cert_subjects_to_stack| but reads from |bio|.
	SSL_add_bio_cert_subjects_to_stack :: proc(out: ^stack_st_X509_NAME, bio: ^BIO) -> i32 ---

	// SSL_CREDENTIAL_set1_trust_anchor_id sets |cred|'s trust anchor ID to |id|, or
	// clears it if |id_len| is zero. It returns one on success and zero on
	// error. If not clearing, |id| must be in binary format (Section 3 of
	// draft-ietf-tls-trust-anchor-ids-00) of length |id_len|, and describe the
	// issuer of the final certificate in |cred|'s certificate chain.
	//
	// Additionally, |cred| must enable issuer matching (see
	// |SSL_CREDENTIAL_set_must_match_issuer|) for this value to take effect.
	//
	// For better extensibility, callers are recommended to configure this
	// information with a CertificatePropertyList instead. See
	// |SSL_CREDENTIAL_set1_certificate_properties|.
	SSL_CREDENTIAL_set1_trust_anchor_id :: proc(cred: ^SSL_CREDENTIAL, id: ^u8, id_len: c.size_t) -> i32 ---

	// SSL_CTX_set1_requested_trust_anchors configures |ctx| to request a
	// certificate issued by one of the trust anchors in |ids|. It returns one on
	// success and zero on error. |ids| must be a list of trust anchor IDs in
	// wire-format (a series of non-empty, 8-bit length-prefixed strings).
	//
	// The list may describe application's full list of supported trust anchors, or
	// a, possibly empty, subset. Applications can select this subset using
	// out-of-band information, such as the DNS hint in Section 5 of
	// draft-ietf-tls-trust-anchor-ids-00. Client applications sending a subset
	// should use |SSL_get0_peer_available_trust_anchors| to implement the retry
	// flow from Section 4.3 of draft-ietf-tls-trust-anchor-ids-00.
	//
	// If empty (|ids_len| is zero), the trust_anchors extension will still be sent
	// in ClientHello. This may be used by a client application to signal support
	// for the retry flow without requesting specific trust anchors.
	//
	// This function does not directly impact certificate verification, only the
	// list of trust anchors sent to the peer.
	SSL_CTX_set1_requested_trust_anchors :: proc(ctx: ^SSL_CTX, ids: ^u8, ids_len: c.size_t) -> i32 ---

	// SSL_set1_requested_trust_anchors behaves like
	// |SSL_CTX_set1_requested_trust_anchors| but configures the value on |ssl|.
	SSL_set1_requested_trust_anchors :: proc(ssl: ^SSL, ids: ^u8, ids_len: c.size_t) -> i32 ---

	// SSL_peer_matched_trust_anchor returns one if the peer reported that its
	// certificate chain matched one of the trust anchor IDs requested by |ssl|, and
	// zero otherwise.
	//
	// This value is only available during the handshake and is expected to be
	// called during certificate verification, e.g. during |SSL_set_custom_verify|
	// or |SSL_CTX_set_cert_verify_callback| callbacks. If the value is one, callers
	// can safely treat the peer's certificate chain as a pre-built path and skip
	// path-building in certificate verification.
	SSL_peer_matched_trust_anchor :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get0_peer_available_trust_anchors gets the peer's available trust anchor
	// IDs. It sets |*out| and |*out_len| so that |*out| points to |*out_len| bytes
	// containing the list in wire format (i.e. a series of non-empty
	// 8-bit-length-prefixed strings). If the peer did not provide a list, the
	// function will output zero bytes. Only servers can provide available trust
	// anchor IDs, so this API will only output a list when |ssl| is a client.
	//
	// This value is only available during the handshake and is expected to be
	// called in the event of certificate verification failure. Client applications
	// can use it to retry the connection, requesting different trust anchors. See
	// Section 4.3 of draft-ietf-tls-trust-anchor-ids-00 for details.
	// |CBS_get_u8_length_prefixed| may be used to iterate over the format.
	//
	// If needed in other contexts, callers may save the value during certificate
	// verification, or at |SSL_CB_HANDSHAKE_DONE| with |SSL_CTX_set_info_callback|.
	SSL_get0_peer_available_trust_anchors :: proc(ssl: ^SSL, out: ^^u8, out_len: ^c.size_t) ---
}

// Server name indication.
//
// The server_name extension (RFC 3546) allows the client to advertise the name
// of the server it is connecting to. This is used in virtual hosting
// deployments to select one of a several certificates on a single IP. Only the
// host_name name type is supported.
TLSEXT_NAMETYPE_host_name :: 0

@(default_calling_convention="c")
foreign lib {
	// SSL_get_servername, for a server, returns the hostname supplied by the
	// client or NULL if there was none. The |type| argument must be
	// |TLSEXT_NAMETYPE_host_name|.
	SSL_get_servername :: proc(ssl: ^SSL, type: i32) -> cstring ---

	// SSL_get_servername_type, for a server, returns |TLSEXT_NAMETYPE_host_name|
	// if the client sent a hostname and -1 otherwise.
	SSL_get_servername_type :: proc(ssl: ^SSL) -> i32 ---
}

// SSL_TLSEXT_ERR_* are values returned by some extension-related callbacks.
SSL_TLSEXT_ERR_OK            :: 0
SSL_TLSEXT_ERR_ALERT_WARNING :: 1
SSL_TLSEXT_ERR_ALERT_FATAL   :: 2
SSL_TLSEXT_ERR_NOACK         :: 3

@(default_calling_convention="c")
foreign lib {
	// SSL_set_SSL_CTX changes |ssl|'s |SSL_CTX|. |ssl| will use the
	// certificate-related settings from |ctx|, and |SSL_get_SSL_CTX| will report
	// |ctx|. This function may be used during the callbacks registered by
	// |SSL_CTX_set_select_certificate_cb|,
	// |SSL_CTX_set_tlsext_servername_callback|, and |SSL_CTX_set_cert_cb| or when
	// the handshake is paused from them. It is typically used to switch
	// certificates based on SNI.
	//
	// Note the session cache and related settings will continue to use the initial
	// |SSL_CTX|. Callers should use |SSL_CTX_set_session_id_context| to partition
	// the session cache between different domains.
	//
	// TODO(davidben): Should other settings change after this call?
	SSL_set_SSL_CTX :: proc(ssl: ^SSL, ctx: ^SSL_CTX) -> ^SSL_CTX ---

	// SSL_CTX_set_alpn_protos sets the client ALPN protocol list on |ctx| to
	// |protos|. |protos| must be in wire-format (i.e. a series of non-empty, 8-bit
	// length-prefixed strings), or the empty string to disable ALPN. It returns
	// zero on success and one on failure. Configuring a non-empty string enables
	// ALPN on a client.
	//
	// WARNING: this function is dangerous because it breaks the usual return value
	// convention.
	SSL_CTX_set_alpn_protos :: proc(ctx: ^SSL_CTX, protos: ^u8, protos_len: c.size_t) -> i32 ---

	// SSL_set_alpn_protos sets the client ALPN protocol list on |ssl| to |protos|.
	// |protos| must be in wire-format (i.e. a series of non-empty, 8-bit
	// length-prefixed strings), or the empty string to disable ALPN. It returns
	// zero on success and one on failure. Configuring a non-empty string enables
	// ALPN on a client.
	//
	// WARNING: this function is dangerous because it breaks the usual return value
	// convention.
	SSL_set_alpn_protos :: proc(ssl: ^SSL, protos: ^u8, protos_len: c.size_t) -> i32 ---

	// SSL_CTX_set_alpn_select_cb sets a callback function on |ctx| that is called
	// during ClientHello processing in order to select an ALPN protocol from the
	// client's list of offered protocols. |SSL_select_next_proto| is an optional
	// utility function which may be useful in implementing this callback.
	//
	// The callback is passed a wire-format (i.e. a series of non-empty, 8-bit
	// length-prefixed strings) ALPN protocol list in |in|. To select a protocol,
	// the callback should set |*out| and |*out_len| to the selected protocol and
	// return |SSL_TLSEXT_ERR_OK| on success. It does not pass ownership of the
	// buffer, so |*out| should point to a static string, a buffer that outlives the
	// callback call, or the corresponding entry in |in|.
	//
	// If the server supports ALPN, but there are no protocols in common, the
	// callback should return |SSL_TLSEXT_ERR_ALERT_FATAL| to abort the connection
	// with a no_application_protocol alert.
	//
	// If the server does not support ALPN, it can return |SSL_TLSEXT_ERR_NOACK| to
	// continue the handshake without negotiating a protocol. This may be useful if
	// multiple server configurations share an |SSL_CTX|, only some of which have
	// ALPN protocols configured.
	//
	// |SSL_TLSEXT_ERR_ALERT_WARNING| is ignored and will be treated as
	// |SSL_TLSEXT_ERR_NOACK|.
	//
	// The callback will only be called if the client supports ALPN. Callers that
	// wish to require ALPN for all clients must check |SSL_get0_alpn_selected|
	// after the handshake. In QUIC connections, this is done automatically.
	//
	// The cipher suite is selected before negotiating ALPN. The callback may use
	// |SSL_get_pending_cipher| to query the cipher suite. This may be used to
	// implement HTTP/2's cipher suite constraints.
	SSL_CTX_set_alpn_select_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, out: ^^u8, out_len: ^u8, _in: ^u8, in_len: u32, arg: rawptr) -> i32, arg: rawptr) ---

	// SSL_get0_alpn_selected gets the selected ALPN protocol (if any) from |ssl|.
	// On return it sets |*out_data| to point to |*out_len| bytes of protocol name
	// (not including the leading length-prefix byte). If the server didn't respond
	// with a negotiated protocol then |*out_len| will be zero.
	SSL_get0_alpn_selected :: proc(ssl: ^SSL, out_data: ^^u8, out_len: ^u32) ---

	// SSL_CTX_set_allow_unknown_alpn_protos configures client connections on |ctx|
	// to allow unknown ALPN protocols from the server. Otherwise, by default, the
	// client will require that the protocol be advertised in
	// |SSL_CTX_set_alpn_protos|.
	SSL_CTX_set_allow_unknown_alpn_protos :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_add_application_settings configures |ssl| to enable ALPS with ALPN
	// protocol |proto|, sending an ALPS value of |settings|. It returns one on
	// success and zero on error. If |proto| is negotiated via ALPN and the peer
	// supports ALPS, |settings| will be sent to the peer. The peer's ALPS value can
	// be retrieved with |SSL_get0_peer_application_settings|.
	//
	// On the client, this function should be called before the handshake, once for
	// each supported ALPN protocol which uses ALPS. |proto| must be included in the
	// client's ALPN configuration (see |SSL_CTX_set_alpn_protos| and
	// |SSL_set_alpn_protos|). On the server, ALPS can be preconfigured for each
	// protocol as in the client, or configuration can be deferred to the ALPN
	// callback (see |SSL_CTX_set_alpn_select_cb|), in which case only the selected
	// protocol needs to be configured.
	//
	// ALPS can be independently configured from 0-RTT, however changes in protocol
	// settings will fallback to 1-RTT to negotiate the new value, so it is
	// recommended for |settings| to be relatively stable.
	SSL_add_application_settings :: proc(ssl: ^SSL, proto: ^u8, proto_len: c.size_t, settings: ^u8, settings_len: c.size_t) -> i32 ---

	// SSL_get0_peer_application_settings sets |*out_data| and |*out_len| to a
	// buffer containing the peer's ALPS value, or the empty string if ALPS was not
	// negotiated. Note an empty string could also indicate the peer sent an empty
	// settings value. Use |SSL_has_application_settings| to check if ALPS was
	// negotiated. The output buffer is owned by |ssl| and is valid until the next
	// time |ssl| is modified.
	SSL_get0_peer_application_settings :: proc(ssl: ^SSL, out_data: ^^u8, out_len: ^c.size_t) ---

	// SSL_has_application_settings returns one if ALPS was negotiated on this
	// connection and zero otherwise.
	SSL_has_application_settings :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_alps_use_new_codepoint configures whether to use the new ALPS
	// codepoint. By default, the old codepoint is used.
	SSL_set_alps_use_new_codepoint :: proc(ssl: ^SSL, use_new: i32) ---
}

// ssl_cert_compression_func_t is a pointer to a function that performs
// compression. It must write the compressed representation of |in| to |out|,
// returning one on success and zero on error. The results of compressing
// certificates are not cached internally. Implementations may wish to implement
// their own cache if they expect it to be useful given the certificates that
// they serve.
ssl_cert_compression_func_t :: proc "c" (ssl: ^SSL, out: ^CBB, _in: ^u8, in_len: c.size_t) -> i32

// ssl_cert_decompression_func_t is a pointer to a function that performs
// decompression. The compressed data from the peer is passed as |in| and the
// decompressed result must be exactly |uncompressed_len| bytes long. It returns
// one on success, in which case |*out| must be set to the result of
// decompressing |in|, or zero on error. Setting |*out| transfers ownership,
// i.e. |CRYPTO_BUFFER_free| will be called on |*out| at some point in the
// future. The results of decompressions are not cached internally.
// Implementations may wish to implement their own cache if they expect it to be
// useful.
ssl_cert_decompression_func_t :: proc "c" (ssl: ^SSL, out: ^^CRYPTO_BUFFER, uncompressed_len: c.size_t, _in: ^u8, in_len: c.size_t) -> i32

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_add_cert_compression_alg registers a certificate compression
	// algorithm on |ctx| with ID |alg_id|. (The value of |alg_id| should be an IANA
	// assigned value and each can only be registered once.)
	//
	// One of the function pointers may be NULL to avoid having to implement both
	// sides of a compression algorithm if you're only going to use it in one
	// direction. In this case, the unimplemented direction acts like it was never
	// configured.
	//
	// For a server, algorithms are registered in preference order with the most
	// preferable first. It returns one on success or zero on error.
	SSL_CTX_add_cert_compression_alg :: proc(ctx: ^SSL_CTX, alg_id: u16, compress: ssl_cert_compression_func_t, decompress: ssl_cert_decompression_func_t) -> i32 ---

	// SSL_CTX_set_next_protos_advertised_cb sets a callback that is called when a
	// TLS server needs a list of supported protocols for Next Protocol Negotiation.
	//
	// If the callback wishes to advertise NPN to the client, it should return
	// |SSL_TLSEXT_ERR_OK| and then set |*out| and |*out_len| to describe to a
	// buffer containing a (possibly empty) list of supported protocols in wire
	// format. That is, each protocol is prefixed with a 1-byte length, then
	// concatenated. From there, the client will select a protocol, possibly one not
	// on the server's list. The caller can use |SSL_get0_next_proto_negotiated|
	// after the handshake completes to query the final protocol.
	//
	// The returned buffer must remain valid and unmodified for at least the
	// duration of the |SSL| operation (e.g. |SSL_do_handshake|) that triggered the
	// callback.
	//
	// If the caller wishes not to advertise NPN, it should return
	// |SSL_TLSEXT_ERR_NOACK|. No NPN extension will be included in the ServerHello,
	// and the TLS server will behave as if it does not implement NPN.
	SSL_CTX_set_next_protos_advertised_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, out: ^^u8, out_len: ^u32, arg: rawptr) -> i32, arg: rawptr) ---

	// SSL_CTX_set_next_proto_select_cb sets a callback that is called when a client
	// needs to select a protocol from the server's provided list, passed in wire
	// format in |in_len| bytes from |in|. The callback can assume that |in| is
	// syntactically valid. |SSL_select_next_proto| is an optional utility function
	// which may be useful in implementing this callback.
	//
	// On success, the callback should return |SSL_TLSEXT_ERR_OK| and set |*out| and
	// |*out_len| to describe a buffer containing the selected protocol, or an
	// empty buffer to select no protocol. The returned buffer may point within
	// |in|, or it may point to some other buffer that remains valid and unmodified
	// for at least the duration of the |SSL| operation (e.g. |SSL_do_handshake|)
	// that triggered the callback.
	//
	// Returning any other value indicates a fatal error and will terminate the TLS
	// connection. To proceed without selecting a protocol, the callback must return
	// |SSL_TLSEXT_ERR_OK| and set |*out| and |*out_len| to an empty buffer. (E.g.
	// NULL and zero, respectively.)
	//
	// Configuring this callback enables NPN on a client. Although the callback can
	// then decline to negotiate a protocol, merely configuring the callback causes
	// the client to offer NPN in the ClientHello. Callers thus should not configure
	// this callback in TLS client contexts that are not intended to use NPN.
	SSL_CTX_set_next_proto_select_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, out: ^^u8, out_len: ^u8, _in: ^u8, in_len: u32, arg: rawptr) -> i32, arg: rawptr) ---

	// SSL_get0_next_proto_negotiated sets |*out_data| and |*out_len| to point to
	// the client's requested protocol for this connection. If the client didn't
	// request any protocol, then |*out_len| is set to zero.
	//
	// Note that the client can request any protocol it chooses. The value returned
	// from this function need not be a member of the list of supported protocols
	// provided by the server.
	SSL_get0_next_proto_negotiated :: proc(ssl: ^SSL, out_data: ^^u8, out_len: ^u32) ---

	// SSL_select_next_proto implements the standard protocol selection for either
	// ALPN servers or NPN clients. It is expected that this function is called from
	// the callback set by |SSL_CTX_set_alpn_select_cb| or
	// |SSL_CTX_set_next_proto_select_cb|.
	//
	// |peer| and |supported| contain the peer and locally-configured protocols,
	// respectively. This function finds the first protocol in |peer| which is also
	// in |supported|. If one was found, it sets |*out| and |*out_len| to point to
	// it and returns |OPENSSL_NPN_NEGOTIATED|. Otherwise, it returns
	// |OPENSSL_NPN_NO_OVERLAP| and sets |*out| and |*out_len| to the first
	// supported protocol.
	//
	// In ALPN, the server should only select protocols among those that the client
	// offered. Thus, if this function returns |OPENSSL_NPN_NO_OVERLAP|, the caller
	// should ignore |*out| and return |SSL_TLSEXT_ERR_ALERT_FATAL| from
	// |SSL_CTX_set_alpn_select_cb|'s callback to indicate there was no match.
	//
	// In NPN, the client may either select one of the server's protocols, or an
	// "opportunistic" protocol as described in Section 6 of
	// draft-agl-tls-nextprotoneg-03. When this function returns
	// |OPENSSL_NPN_NO_OVERLAP|, |*out| implicitly selects the first supported
	// protocol for use as the opportunistic protocol. The caller may use it,
	// ignore it and select a different opportunistic protocol, or ignore it and
	// select no protocol (empty string).
	//
	// |peer| and |supported| must be vectors of 8-bit, length-prefixed byte
	// strings. The length byte itself is not included in the length. A byte string
	// of length 0 is invalid. No byte string may be truncated. |supported| must be
	// non-empty; a caller that supports no ALPN/NPN protocols should skip
	// negotiating the extension, rather than calling this function. If any of these
	// preconditions do not hold, this function will return |OPENSSL_NPN_NO_OVERLAP|
	// and set |*out| and |*out_len| to an empty buffer for robustness, but callers
	// are not recommended to rely on this. An empty buffer is not a valid output
	// for |SSL_CTX_set_alpn_select_cb|'s callback.
	//
	// WARNING: |*out| and |*out_len| may alias either |peer| or |supported| and may
	// not be used after one of those buffers is modified or released. Additionally,
	// this function is not const-correct for compatibility reasons. Although |*out|
	// is a non-const pointer, callers may not modify the buffer though |*out|.
	SSL_select_next_proto :: proc(out: ^^u8, out_len: ^u8, peer: ^u8, peer_len: u32, supported: ^u8, supported_len: u32) -> i32 ---
}

OPENSSL_NPN_UNSUPPORTED :: 0
OPENSSL_NPN_NEGOTIATED  :: 1
OPENSSL_NPN_NO_OVERLAP  :: 2

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_tls_channel_id_enabled configures whether connections associated
	// with |ctx| should enable Channel ID as a server.
	SSL_CTX_set_tls_channel_id_enabled :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_set_tls_channel_id_enabled configures whether |ssl| should enable Channel
	// ID as a server.
	SSL_set_tls_channel_id_enabled :: proc(ssl: ^SSL, enabled: i32) ---

	// SSL_CTX_set1_tls_channel_id configures a TLS client to send a TLS Channel ID
	// to compatible servers. |private_key| must be a P-256 EC key. It returns one
	// on success and zero on error.
	SSL_CTX_set1_tls_channel_id :: proc(ctx: ^SSL_CTX, private_key: ^EVP_PKEY) -> i32 ---

	// SSL_set1_tls_channel_id configures a TLS client to send a TLS Channel ID to
	// compatible servers. |private_key| must be a P-256 EC key. It returns one on
	// success and zero on error.
	SSL_set1_tls_channel_id :: proc(ssl: ^SSL, private_key: ^EVP_PKEY) -> i32 ---

	// SSL_get_tls_channel_id gets the client's TLS Channel ID from a server |SSL|
	// and copies up to the first |max_out| bytes into |out|. The Channel ID
	// consists of the client's P-256 public key as an (x,y) pair where each is a
	// 32-byte, big-endian field element. It returns 0 if the client didn't offer a
	// Channel ID and the length of the complete Channel ID otherwise. This function
	// always returns zero if |ssl| is a client.
	SSL_get_tls_channel_id :: proc(ssl: ^SSL, out: ^u8, max_out: c.size_t) -> c.size_t ---
}

// srtp_protection_profile_st (aka |SRTP_PROTECTION_PROFILE|) is an SRTP
// profile for use with the use_srtp extension.
srtp_protection_profile_st :: struct {
	name: cstring,
	id:   c.ulong,
}

sk_SRTP_PROTECTION_PROFILE_delete_if_func :: proc "c" (^SRTP_PROTECTION_PROFILE, rawptr) -> i32
sk_SRTP_PROTECTION_PROFILE_copy_func      :: proc "c" (^SRTP_PROTECTION_PROFILE) -> ^SRTP_PROTECTION_PROFILE
stack_st_SRTP_PROTECTION_PROFILE          :: struct {}
sk_SRTP_PROTECTION_PROFILE_free_func      :: proc "c" (^SRTP_PROTECTION_PROFILE)
sk_SRTP_PROTECTION_PROFILE_cmp_func       :: proc "c" (^^SRTP_PROTECTION_PROFILE, ^^SRTP_PROTECTION_PROFILE) -> i32

// SRTP_* define constants for SRTP profiles.
SRTP_AES128_CM_SHA1_80 :: 0x0001
SRTP_AES128_CM_SHA1_32 :: 0x0002
SRTP_AES128_F8_SHA1_80 :: 0x0003
SRTP_AES128_F8_SHA1_32 :: 0x0004
SRTP_NULL_SHA1_80      :: 0x0005
SRTP_NULL_SHA1_32      :: 0x0006
SRTP_AEAD_AES_128_GCM  :: 0x0007
SRTP_AEAD_AES_256_GCM  :: 0x0008

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_srtp_profiles enables SRTP for all SSL objects created from
	// |ctx|. |profile| contains a colon-separated list of profile names. It returns
	// one on success and zero on failure.
	SSL_CTX_set_srtp_profiles :: proc(ctx: ^SSL_CTX, profiles: cstring) -> i32 ---

	// SSL_set_srtp_profiles enables SRTP for |ssl|.  |profile| contains a
	// colon-separated list of profile names. It returns one on success and zero on
	// failure.
	SSL_set_srtp_profiles :: proc(ssl: ^SSL, profiles: cstring) -> i32 ---

	// SSL_get_srtp_profiles returns the SRTP profiles supported by |ssl|.
	SSL_get_srtp_profiles :: proc(ssl: ^SSL) -> ^stack_st_SRTP_PROTECTION_PROFILE ---

	// SSL_get_selected_srtp_profile returns the selected SRTP profile, or NULL if
	// SRTP was not negotiated.
	SSL_get_selected_srtp_profile :: proc(ssl: ^SSL) -> ^SRTP_PROTECTION_PROFILE ---
}

// Pre-shared keys.
//
// Connections may be configured with PSK (Pre-Shared Key) cipher suites. These
// authenticate using out-of-band pre-shared keys rather than certificates. See
// RFC 4279.
//
// This implementation uses NUL-terminated C strings for identities and identity
// hints, so values with a NUL character are not supported. (RFC 4279 does not
// specify the format of an identity.)

// PSK_MAX_IDENTITY_LEN is the maximum supported length of a PSK identity,
// excluding the NUL terminator.
PSK_MAX_IDENTITY_LEN :: 128

// PSK_MAX_PSK_LEN is the maximum supported length of a pre-shared key.
PSK_MAX_PSK_LEN :: 256

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_psk_client_callback sets the callback to be called when PSK is
	// negotiated on the client. This callback must be set to enable PSK cipher
	// suites on the client.
	//
	// The callback is passed the identity hint in |hint| or NULL if none was
	// provided. It should select a PSK identity and write the identity and the
	// corresponding PSK to |identity| and |psk|, respectively. The identity is
	// written as a NUL-terminated C string of length (excluding the NUL terminator)
	// at most |max_identity_len|. The PSK's length must be at most |max_psk_len|.
	// The callback returns the length of the PSK or 0 if no suitable identity was
	// found.
	SSL_CTX_set_psk_client_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, hint: cstring, identity: cstring, max_identity_len: u32, psk: ^u8, max_psk_len: u32) -> u32) ---

	// SSL_set_psk_client_callback sets the callback to be called when PSK is
	// negotiated on the client. This callback must be set to enable PSK cipher
	// suites on the client. See also |SSL_CTX_set_psk_client_callback|.
	SSL_set_psk_client_callback :: proc(ssl: ^SSL, cb: proc "c" (ssl: ^SSL, hint: cstring, identity: cstring, max_identity_len: u32, psk: ^u8, max_psk_len: u32) -> u32) ---

	// SSL_CTX_set_psk_server_callback sets the callback to be called when PSK is
	// negotiated on the server. This callback must be set to enable PSK cipher
	// suites on the server.
	//
	// The callback is passed the identity in |identity|. It should write a PSK of
	// length at most |max_psk_len| to |psk| and return the number of bytes written
	// or zero if the PSK identity is unknown.
	SSL_CTX_set_psk_server_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, identity: cstring, psk: ^u8, max_psk_len: u32) -> u32) ---

	// SSL_set_psk_server_callback sets the callback to be called when PSK is
	// negotiated on the server. This callback must be set to enable PSK cipher
	// suites on the server. See also |SSL_CTX_set_psk_server_callback|.
	SSL_set_psk_server_callback :: proc(ssl: ^SSL, cb: proc "c" (ssl: ^SSL, identity: cstring, psk: ^u8, max_psk_len: u32) -> u32) ---

	// SSL_CTX_use_psk_identity_hint configures server connections to advertise an
	// identity hint of |identity_hint|. It returns one on success and zero on
	// error.
	SSL_CTX_use_psk_identity_hint :: proc(ctx: ^SSL_CTX, identity_hint: cstring) -> i32 ---

	// SSL_use_psk_identity_hint configures server connections to advertise an
	// identity hint of |identity_hint|. It returns one on success and zero on
	// error.
	SSL_use_psk_identity_hint :: proc(ssl: ^SSL, identity_hint: cstring) -> i32 ---

	// SSL_get_psk_identity_hint returns the PSK identity hint advertised for |ssl|
	// or NULL if there is none.
	SSL_get_psk_identity_hint :: proc(ssl: ^SSL) -> cstring ---

	// SSL_get_psk_identity, after the handshake completes, returns the PSK identity
	// that was negotiated by |ssl| or NULL if PSK was not used.
	SSL_get_psk_identity :: proc(ssl: ^SSL) -> cstring ---

	// SSL_CREDENTIAL_new_delegated returns a new, empty delegated credential, or
	// NULL on error. Callers should release the result with |SSL_CREDENTIAL_free|
	// when done.
	//
	// Callers should configure a delegated credential, certificate chain and
	// private key on the credential, along with other properties, then add it with
	// |SSL_CTX_add1_credential|.
	SSL_CREDENTIAL_new_delegated :: proc() -> ^SSL_CREDENTIAL ---

	// SSL_CREDENTIAL_set1_delegated_credential sets |cred|'s delegated credentials
	// structure to |dc|. It returns one on success and zero on error, including if
	// |dc| is malformed. This should be a DelegatedCredential structure, signed by
	// the end-entity certificate, as described in RFC 9345.
	SSL_CREDENTIAL_set1_delegated_credential :: proc(cred: ^SSL_CREDENTIAL, dc: ^CRYPTO_BUFFER) -> i32 ---
}

SSL_PAKE_SPAKE2PLUSV1 :: 0x7d96

@(default_calling_convention="c")
foreign lib {
	// SSL_spake2plusv1_register computes the values that the client (w0,
	// w1) and server (w0, registration_record) require to run SPAKE2+. These values
	// can be used when calling |SSL_CREDENTIAL_new_spake2plusv1_client| and
	// |SSL_CREDENTIAL_new_spake2plusv1_server|. The client and server identities
	// must match the values passed to those functions.
	//
	// Returns one on success and zero on error.
	SSL_spake2plusv1_register :: proc(out_w0: ^[32]u8, out_w1: ^[32]u8, out_registration_record: ^[65]u8, password: ^u8, password_len: c.size_t, client_identity: ^u8, client_identity_len: c.size_t, server_identity: ^u8, server_identity_len: c.size_t) -> i32 ---

	// SSL_CREDENTIAL_new_spake2plusv1_client creates a new |SSL_CREDENTIAL| that
	// authenticates using SPAKE2+. It is to be used with a TLS client.
	//
	// The |context|, |client_identity|, and |server_identity| fields serve to
	// identity the SPAKE2+ settings and both sides of a connection must agree on
	// these values. If |context| is |NULL|, a default value will be used.
	//
	// |error_limit| is the number of failed handshakes allowed on the credential.
	// After the limit is reached, using the credential will fail. Ideally this
	// value is set to 1. Setting it to a higher value allows an attacker to have
	// that many attempts at guessing the password using this |SSL_CREDENTIAL|.
	// (Assuming that multiple TLS connections are allowed.)
	//
	// |w0| and |w1| come from calling |SSL_spake2plusv1_register|.
	//
	// Unlike most |SSL_CREDENTIAL|s, PAKE client credentials must be the only
	// credential configured on the connection. BoringSSL does not currently support
	// configuring multiple PAKE credentials as a client, or configuring a mix of
	// PAKE and non-PAKE credentials. Once a PAKE credential is configured, the
	// connection will require the server to authenticate with the same secret, so a
	// successful connection then implies that the server supported the PAKE and
	// knew the password.
	SSL_CREDENTIAL_new_spake2plusv1_client :: proc(_context: ^u8, context_len: c.size_t, client_identity: ^u8, client_identity_len: c.size_t, server_identity: ^u8, server_identity_len: c.size_t, error_limit: u32, w0: ^u8, w0_len: c.size_t, w1: ^u8, w1_len: c.size_t) -> ^SSL_CREDENTIAL ---

	// SSL_CREDENTIAL_new_spake2plusv1_server creates a new |SSL_CREDENTIAL| that
	// authenticates using SPAKE2+. It is to be used with a TLS server.
	//
	// The |context|, |client_identity|, and |server_identity| fields serve to
	// identity the SPAKE2+ settings and both sides of a connection must agree on
	// these values. If |context| is |NULL|, a default value will be used.
	//
	// |rate_limit| is the number of failed or unfinished handshakes allowed on the
	// credential. After the limit is reached, using the credential will fail.
	// Ideally this value is set to 1. Setting it to a higher value allows an
	// attacker to have that many attempts at guessing the password using this
	// |SSL_CREDENTIAL|. (Assuming that multiple TLS connections are allowed.)
	//
	// WARNING: |rate_limit| differs from the client's |error_limit| parameter.
	// Server PAKE credentials must temporarily deduct incomplete handshakes from
	// the limit, until the peer completes the handshake correctly. Thus
	// applications that use multiple connections in parallel may need a higher
	// limit, and thus higher attacker exposure, to avoid failures. Such
	// applications should instead use one PAKE-based connection to established a
	// high-entropy secret (e.g. with |SSL_export_keying_material|) instead of
	// repeating the PAKE exchange for each connection.
	//
	// |w0| and |registration_record| come from calling |SSL_spake2plusv1_register|,
	// which may be computed externally so that the server does not know the
	// password, or a password-equivalent secret.
	//
	// A server wishing to support a PAKE should install one of these credentials.
	// It is also possible to install certificate-based credentials, in which case
	// both PAKE and non-PAKE clients can be supported. However, if only a PAKE
	// credential is installed then the server knows that any successfully-connected
	// clients also knows the password. Otherwise, the server must be careful to
	// inspect the credential used for a connection before assuming that.
	SSL_CREDENTIAL_new_spake2plusv1_server :: proc(_context: ^u8, context_len: c.size_t, client_identity: ^u8, client_identity_len: c.size_t, server_identity: ^u8, server_identity_len: c.size_t, rate_limit: u32, w0: ^u8, w0_len: c.size_t, registration_record: ^u8, registration_record_len: c.size_t) -> ^SSL_CREDENTIAL ---
}

// ssl_encryption_level_t represents an encryption level in TLS 1.3. Values in
// this enum match the first 4 epochs used in DTLS 1.3 (section 6.1).
ssl_encryption_level_t :: enum u32 {
	initial     = 0,
	early_data  = 1,
	handshake   = 2,
	application = 3,
}

// ssl_quic_method_st (aka |SSL_QUIC_METHOD|) describes custom QUIC hooks.
ssl_quic_method_st :: struct {
	// set_read_secret configures the read secret and cipher suite for the given
	// encryption level. It returns one on success and zero to terminate the
	// handshake with an error. It will be called at most once per encryption
	// level.
	//
	// BoringSSL will not release read keys before QUIC may use them. Once a level
	// has been initialized, QUIC may begin processing data from it. Handshake
	// data should be passed to |SSL_provide_quic_data| and application data (if
	// |level| is |ssl_encryption_early_data| or |ssl_encryption_application|) may
	// be processed according to the rules of the QUIC protocol.
	//
	// QUIC ACKs packets at the same encryption level they were received at,
	// except that client |ssl_encryption_early_data| (0-RTT) packets trigger
	// server |ssl_encryption_application| (1-RTT) ACKs. BoringSSL will always
	// install ACK-writing keys with |set_write_secret| before the packet-reading
	// keys with |set_read_secret|. This ensures the caller can always ACK any
	// packet it decrypts. Note this means the server installs 1-RTT write keys
	// before 0-RTT read keys.
	//
	// The converse is not true. An encryption level may be configured with write
	// secrets a roundtrip before the corresponding secrets for reading ACKs is
	// available.
	set_read_secret: proc "c" (ssl: ^SSL, level: ssl_encryption_level_t, cipher: ^SSL_CIPHER, secret: ^u8, secret_len: c.size_t) -> i32,

	// set_write_secret behaves like |set_read_secret| but configures the write
	// secret and cipher suite for the given encryption level. It will be called
	// at most once per encryption level.
	//
	// BoringSSL will not release write keys before QUIC may use them. If |level|
	// is |ssl_encryption_early_data| or |ssl_encryption_application|, QUIC may
	// begin sending application data at |level|. However, note that BoringSSL
	// configures server |ssl_encryption_application| write keys before the client
	// Finished. This allows QUIC to send half-RTT data, but the handshake is not
	// confirmed at this point and, if requesting client certificates, the client
	// is not yet authenticated.
	//
	// See |set_read_secret| for additional invariants between packets and their
	// ACKs.
	//
	// Note that, on 0-RTT reject, the |ssl_encryption_early_data| write secret
	// may use a different cipher suite from the other keys.
	set_write_secret: proc "c" (ssl: ^SSL, level: ssl_encryption_level_t, cipher: ^SSL_CIPHER, secret: ^u8, secret_len: c.size_t) -> i32,

	// add_handshake_data adds handshake data to the current flight at the given
	// encryption level. It returns one on success and zero on error.
	//
	// BoringSSL will pack data from a single encryption level together, but a
	// single handshake flight may include multiple encryption levels. Callers
	// should defer writing data to the network until |flush_flight| to better
	// pack QUIC packets into transport datagrams.
	//
	// If |level| is not |ssl_encryption_initial|, this function will not be
	// called before |level| is initialized with |set_write_secret|.
	add_handshake_data: proc "c" (ssl: ^SSL, level: ssl_encryption_level_t, data: ^u8, len: c.size_t) -> i32,

	// flush_flight is called when the current flight is complete and should be
	// written to the transport. Note a flight may contain data at several
	// encryption levels. It returns one on success and zero on error.
	flush_flight: proc "c" (ssl: ^SSL) -> i32,

	// send_alert sends a fatal alert at the specified encryption level. It
	// returns one on success and zero on error.
	//
	// If |level| is not |ssl_encryption_initial|, this function will not be
	// called before |level| is initialized with |set_write_secret|.
	send_alert: proc "c" (ssl: ^SSL, level: ssl_encryption_level_t, alert: u8) -> i32,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_quic_max_handshake_flight_len returns returns the maximum number of bytes
	// that may be received at the given encryption level. This function should be
	// used to limit buffering in the QUIC implementation.
	//
	// See https://www.rfc-editor.org/rfc/rfc9000#section-7.5
	SSL_quic_max_handshake_flight_len :: proc(ssl: ^SSL, level: ssl_encryption_level_t) -> c.size_t ---

	// SSL_quic_read_level returns the current read encryption level.
	//
	// TODO(davidben): Is it still necessary to expose this function to callers?
	// QUICHE does not use it.
	SSL_quic_read_level :: proc(ssl: ^SSL) -> ssl_encryption_level_t ---

	// SSL_quic_write_level returns the current write encryption level.
	//
	// TODO(davidben): Is it still necessary to expose this function to callers?
	// QUICHE does not use it.
	SSL_quic_write_level :: proc(ssl: ^SSL) -> ssl_encryption_level_t ---

	// SSL_provide_quic_data provides data from QUIC at a particular encryption
	// level |level|. It returns one on success and zero on error. Note this
	// function will return zero if the handshake is not expecting data from |level|
	// at this time. The QUIC implementation should then close the connection with
	// an error.
	SSL_provide_quic_data :: proc(ssl: ^SSL, level: ssl_encryption_level_t, data: ^u8, len: c.size_t) -> i32 ---

	// SSL_process_quic_post_handshake processes any data that QUIC has provided
	// after the handshake has completed. This includes NewSessionTicket messages
	// sent by the server. It returns one on success and zero on error.
	SSL_process_quic_post_handshake :: proc(ssl: ^SSL) -> i32 ---

	// SSL_CTX_set_quic_method configures the QUIC hooks. This should only be
	// configured with a minimum version of TLS 1.3. |quic_method| must remain valid
	// for the lifetime of |ctx|. It returns one on success and zero on error.
	SSL_CTX_set_quic_method :: proc(ctx: ^SSL_CTX, quic_method: ^SSL_QUIC_METHOD) -> i32 ---

	// SSL_set_quic_method configures the QUIC hooks. This should only be
	// configured with a minimum version of TLS 1.3. |quic_method| must remain valid
	// for the lifetime of |ssl|. It returns one on success and zero on error.
	SSL_set_quic_method :: proc(ssl: ^SSL, quic_method: ^SSL_QUIC_METHOD) -> i32 ---

	// SSL_set_quic_transport_params configures |ssl| to send |params| (of length
	// |params_len|) in the quic_transport_parameters extension in either the
	// ClientHello or EncryptedExtensions handshake message. It is an error to set
	// transport parameters if |ssl| is not configured for QUIC. The buffer pointed
	// to by |params| only need be valid for the duration of the call to this
	// function. This function returns 1 on success and 0 on failure.
	SSL_set_quic_transport_params :: proc(ssl: ^SSL, params: ^u8, params_len: c.size_t) -> i32 ---

	// SSL_get_peer_quic_transport_params provides the caller with the value of the
	// quic_transport_parameters extension sent by the peer. A pointer to the buffer
	// containing the TransportParameters will be put in |*out_params|, and its
	// length in |*params_len|. This buffer will be valid for the lifetime of the
	// |SSL|. If no params were received from the peer, |*out_params_len| will be 0.
	SSL_get_peer_quic_transport_params :: proc(ssl: ^SSL, out_params: ^^u8, out_params_len: ^c.size_t) ---

	// SSL_set_quic_use_legacy_codepoint configures whether to use the legacy QUIC
	// extension codepoint 0xffa5 as opposed to the official value 57. Call with
	// |use_legacy| set to 1 to use 0xffa5 and call with 0 to use 57. By default,
	// the standard code point is used.
	SSL_set_quic_use_legacy_codepoint :: proc(ssl: ^SSL, use_legacy: i32) ---

	// SSL_set_quic_early_data_context configures a context string in QUIC servers
	// for accepting early data. If a resumption connection offers early data, the
	// server will check if the value matches that of the connection which minted
	// the ticket. If not, resumption still succeeds but early data is rejected.
	// This should include all QUIC Transport Parameters except ones specified that
	// the client MUST NOT remember. This should also include any application
	// protocol-specific state. For HTTP/3, this should be the serialized server
	// SETTINGS frame and the QUIC Transport Parameters (except the stateless reset
	// token).
	//
	// This function may be called before |SSL_do_handshake| or during server
	// certificate selection. It returns 1 on success and 0 on failure.
	SSL_set_quic_early_data_context :: proc(ssl: ^SSL, _context: ^u8, context_len: c.size_t) -> i32 ---

	// SSL_CTX_set_early_data_enabled sets whether early data is allowed to be used
	// with resumptions using |ctx|.
	SSL_CTX_set_early_data_enabled :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_set_early_data_enabled sets whether early data is allowed to be used
	// with resumptions using |ssl|. See |SSL_CTX_set_early_data_enabled| for more
	// information.
	SSL_set_early_data_enabled :: proc(ssl: ^SSL, enabled: i32) ---

	// SSL_in_early_data returns one if |ssl| has a pending handshake that has
	// progressed enough to send or receive early data. Clients may call |SSL_write|
	// to send early data, but |SSL_read| will complete the handshake before
	// accepting application data. Servers may call |SSL_read| to read early data
	// and |SSL_write| to send half-RTT data.
	SSL_in_early_data :: proc(ssl: ^SSL) -> i32 ---

	// SSL_SESSION_early_data_capable returns whether early data would have been
	// attempted with |session| if enabled.
	SSL_SESSION_early_data_capable :: proc(session: ^SSL_SESSION) -> i32 ---

	// SSL_SESSION_copy_without_early_data returns a copy of |session| with early
	// data disabled. If |session| already does not support early data, it returns
	// |session| with the reference count increased. The caller takes ownership of
	// the result and must release it with |SSL_SESSION_free|.
	//
	// This function may be used on the client to clear early data support from
	// existing sessions when the server rejects early data. In particular,
	// |SSL_R_WRONG_VERSION_ON_EARLY_DATA| requires a fresh connection to retry, and
	// the client would not want 0-RTT enabled for the next connection attempt.
	SSL_SESSION_copy_without_early_data :: proc(session: ^SSL_SESSION) -> ^SSL_SESSION ---

	// SSL_early_data_accepted returns whether early data was accepted on the
	// handshake performed by |ssl|.
	SSL_early_data_accepted :: proc(ssl: ^SSL) -> i32 ---

	// SSL_reset_early_data_reject resets |ssl| after an early data reject. All
	// 0-RTT state is discarded, including any pending |SSL_write| calls. The caller
	// should treat |ssl| as a logically fresh connection, usually by driving the
	// handshake to completion using |SSL_do_handshake|.
	//
	// It is an error to call this function on an |SSL| object that is not signaling
	// |SSL_ERROR_EARLY_DATA_REJECTED|.
	SSL_reset_early_data_reject :: proc(ssl: ^SSL) ---

	// SSL_get_ticket_age_skew returns the difference, in seconds, between the
	// client-sent ticket age and the server-computed value in TLS 1.3 server
	// connections which resumed a session.
	SSL_get_ticket_age_skew :: proc(ssl: ^SSL) -> i32 ---
}

// An ssl_early_data_reason_t describes why 0-RTT was accepted or rejected.
// These values are persisted to logs. Entries should not be renumbered and
// numeric values should never be reused.
ssl_early_data_reason_t :: enum u32 {
	// The handshake has not progressed far enough for the 0-RTT status to be
	// known.
	unknown                 = 0,

	// 0-RTT is disabled for this connection.
	disabled                = 1,

	// 0-RTT was accepted.
	accepted                = 2,

	// The negotiated protocol version does not support 0-RTT.
	protocol_version        = 3,

	// The peer declined to offer or accept 0-RTT for an unknown reason.
	peer_declined           = 4,

	// The client did not offer a session.
	no_session_offered      = 5,

	// The server declined to resume the session.
	session_not_resumed     = 6,

	// The session does not support 0-RTT.
	unsupported_for_session = 7,

	// The server sent a HelloRetryRequest.
	hello_retry_request     = 8,

	// The negotiated ALPN protocol did not match the session.
	alpn_mismatch           = 9,

	// The connection negotiated Channel ID, which is incompatible with 0-RTT.
	channel_id              = 10,

	// Value 11 is reserved. (It has historically |ssl_early_data_token_binding|.)
	// The client and server ticket age were too far apart.
	ticket_age_skew         = 12,

	// QUIC parameters differ between this connection and the original.
	quic_parameter_mismatch = 13,

	// The application settings did not match the session.
	alps_mismatch           = 14,

	// The value of the largest entry.
	reason_max_value        = 14,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_get_early_data_reason returns details why 0-RTT was accepted or rejected
	// on |ssl|. This is primarily useful on the server.
	SSL_get_early_data_reason :: proc(ssl: ^SSL) -> ssl_early_data_reason_t ---

	// SSL_early_data_reason_string returns a string representation for |reason|, or
	// NULL if |reason| is unknown. This function may be used for logging.
	SSL_early_data_reason_string :: proc(reason: ssl_early_data_reason_t) -> cstring ---

	// SSL_set_enable_ech_grease configures whether the client will send a GREASE
	// ECH extension when no supported ECHConfig is available.
	SSL_set_enable_ech_grease :: proc(ssl: ^SSL, enable: i32) ---

	// SSL_set1_ech_config_list configures |ssl| to, as a client, offer ECH with the
	// specified configuration. |ech_config_list| should contain a serialized
	// ECHConfigList structure. It returns one on success and zero on error.
	//
	// This function returns an error if the input is malformed. If the input is
	// valid but none of the ECHConfigs implement supported parameters, it will
	// return success and proceed without ECH.
	//
	// If a supported ECHConfig is found, |ssl| will encrypt the true ClientHello
	// parameters. If the server cannot decrypt it, e.g. due to a key mismatch, ECH
	// has a recovery flow. |ssl| will handshake using the cleartext parameters,
	// including a public name in the ECHConfig. If using
	// |SSL_CTX_set_custom_verify|, callers should use |SSL_get0_ech_name_override|
	// to verify the certificate with the public name. If using the built-in
	// verifier, the |X509_STORE_CTX| will be configured automatically.
	//
	// If no other errors are found in this handshake, it will fail with
	// |SSL_R_ECH_REJECTED|. Since it didn't use the true parameters, the connection
	// cannot be used for application data. Instead, callers should handle this
	// error by calling |SSL_get0_ech_retry_configs| and retrying the connection
	// with updated ECH parameters. If the retry also fails with
	// |SSL_R_ECH_REJECTED|, the caller should report a connection failure.
	SSL_set1_ech_config_list :: proc(ssl: ^SSL, ech_config_list: ^u8, ech_config_list_len: c.size_t) -> i32 ---

	// SSL_get0_ech_name_override, if |ssl| is a client and the server rejected ECH,
	// sets |*out_name| and |*out_name_len| to point to a buffer containing the ECH
	// public name. Otherwise, the buffer will be empty.
	//
	// When offering ECH as a client, this function should be called during the
	// certificate verification callback (see |SSL_CTX_set_custom_verify|). If
	// |*out_name_len| is non-zero, the caller should verify the certificate against
	// the result, interpreted as a DNS name, rather than the true server name. In
	// this case, the handshake will never succeed and is only used to authenticate
	// retry configs. See also |SSL_get0_ech_retry_configs|.
	SSL_get0_ech_name_override :: proc(ssl: ^SSL, out_name: ^cstring, out_name_len: ^c.size_t) ---

	// SSL_get0_ech_retry_configs sets |*out_retry_configs| and
	// |*out_retry_configs_len| to a buffer containing a serialized ECHConfigList.
	// If the server did not provide an ECHConfigList, |*out_retry_configs_len| will
	// be zero.
	//
	// When handling an |SSL_R_ECH_REJECTED| error code as a client, callers should
	// use this function to recover from potential key mismatches. If the result is
	// non-empty, the caller should retry the connection, passing this buffer to
	// |SSL_set1_ech_config_list|. If the result is empty, the server has rolled
	// back ECH support, and the caller should retry without ECH.
	//
	// This function must only be called in response to an |SSL_R_ECH_REJECTED|
	// error code. Calling this function on |ssl|s that have not authenticated the
	// rejection handshake will assert in debug builds and otherwise return an
	// unparsable list.
	SSL_get0_ech_retry_configs :: proc(ssl: ^SSL, out_retry_configs: ^^u8, out_retry_configs_len: ^c.size_t) ---

	// SSL_marshal_ech_config constructs a new serialized ECHConfig. On success, it
	// sets |*out| to a newly-allocated buffer containing the result and |*out_len|
	// to the size of the buffer. The caller must call |OPENSSL_free| on |*out| to
	// release the memory. On failure, it returns zero.
	//
	// The |config_id| field is a single byte identifier for the ECHConfig. Reusing
	// config IDs is allowed, but if multiple ECHConfigs with the same config ID are
	// active at a time, server load may increase. See
	// |SSL_ECH_KEYS_has_duplicate_config_id|.
	//
	// The public key and KEM algorithm are taken from |key|. |public_name| is the
	// DNS name used to authenticate the recovery flow. |max_name_len| should be the
	// length of the longest name in the ECHConfig's anonymity set and influences
	// client padding decisions.
	SSL_marshal_ech_config :: proc(out: ^^u8, out_len: ^c.size_t, config_id: u8, key: ^EVP_HPKE_KEY, public_name: cstring, max_name_len: c.size_t) -> i32 ---

	// SSL_ECH_KEYS_new returns a newly-allocated |SSL_ECH_KEYS| or NULL on error.
	SSL_ECH_KEYS_new :: proc() -> ^SSL_ECH_KEYS ---

	// SSL_ECH_KEYS_up_ref increments the reference count of |keys|.
	SSL_ECH_KEYS_up_ref :: proc(keys: ^SSL_ECH_KEYS) ---

	// SSL_ECH_KEYS_free releases memory associated with |keys|.
	SSL_ECH_KEYS_free :: proc(keys: ^SSL_ECH_KEYS) ---

	// SSL_ECH_KEYS_add decodes |ech_config| as an ECHConfig and appends it with
	// |key| to |keys|. If |is_retry_config| is non-zero, this config will be
	// returned to the client on configuration mismatch. It returns one on success
	// and zero on error.
	//
	// This function should be called successively to register each ECHConfig in
	// decreasing order of preference. This configuration must be completed before
	// setting |keys| on an |SSL_CTX| with |SSL_CTX_set1_ech_keys|. After that
	// point, |keys| is immutable; no more ECHConfig values may be added.
	//
	// See also |SSL_CTX_set1_ech_keys|.
	SSL_ECH_KEYS_add :: proc(keys: ^SSL_ECH_KEYS, is_retry_config: i32, ech_config: ^u8, ech_config_len: c.size_t, key: ^EVP_HPKE_KEY) -> i32 ---

	// SSL_ECH_KEYS_has_duplicate_config_id returns one if |keys| has duplicate
	// config IDs or zero otherwise. Duplicate config IDs still work, but may
	// increase server load due to trial decryption.
	SSL_ECH_KEYS_has_duplicate_config_id :: proc(keys: ^SSL_ECH_KEYS) -> i32 ---

	// SSL_ECH_KEYS_marshal_retry_configs serializes the retry configs in |keys| as
	// an ECHConfigList. On success, it sets |*out| to a newly-allocated buffer
	// containing the result and |*out_len| to the size of the buffer. The caller
	// must call |OPENSSL_free| on |*out| to release the memory. On failure, it
	// returns zero.
	//
	// This output may be advertised to clients in DNS.
	SSL_ECH_KEYS_marshal_retry_configs :: proc(keys: ^SSL_ECH_KEYS, out: ^^u8, out_len: ^c.size_t) -> i32 ---

	// SSL_CTX_set1_ech_keys configures |ctx| to use |keys| to decrypt encrypted
	// ClientHellos. It returns one on success, and zero on failure. If |keys| does
	// not contain any retry configs, this function will fail. Retry configs are
	// marked as such when they are added to |keys| with |SSL_ECH_KEYS_add|.
	//
	// Once |keys| has been passed to this function, it is immutable. Unlike most
	// |SSL_CTX| configuration functions, this function may be called even if |ctx|
	// already has associated connections on multiple threads. This may be used to
	// rotate keys in a long-lived server process.
	//
	// The configured ECHConfig values should also be advertised out-of-band via DNS
	// (see draft-ietf-dnsop-svcb-https). Before advertising an ECHConfig in DNS,
	// deployments should ensure all instances of the service are configured with
	// the ECHConfig and corresponding private key.
	//
	// Only the most recent fully-deployed ECHConfigs should be advertised in DNS.
	// |keys| may contain a newer set if those ECHConfigs are mid-deployment. It
	// should also contain older sets, until the DNS change has rolled out and the
	// old records have expired from caches.
	//
	// If there is a mismatch, |SSL| objects associated with |ctx| will complete the
	// handshake using the cleartext ClientHello and send updated ECHConfig values
	// to the client. The client will then retry to recover, but with a latency
	// penalty. This recovery flow depends on the public name in the ECHConfig.
	// Before advertising an ECHConfig in DNS, deployments must ensure all instances
	// of the service can present a valid certificate for the public name.
	//
	// BoringSSL negotiates ECH before certificate selection callbacks are called,
	// including |SSL_CTX_set_select_certificate_cb|. If ECH is negotiated, the
	// reported |SSL_CLIENT_HELLO| structure and |SSL_get_servername| function will
	// transparently reflect the inner ClientHello. Callers should select parameters
	// based on these values to correctly handle ECH as well as the recovery flow.
	SSL_CTX_set1_ech_keys :: proc(ctx: ^SSL_CTX, keys: ^SSL_ECH_KEYS) -> i32 ---

	// SSL_ech_accepted returns one if |ssl| negotiated ECH and zero otherwise.
	SSL_ech_accepted :: proc(ssl: ^SSL) -> i32 ---
}

// Alerts.
//
// TLS uses alerts to signal error conditions. Alerts have a type (warning or
// fatal) and description. OpenSSL internally handles fatal alerts with
// dedicated error codes (see |SSL_AD_REASON_OFFSET|). Except for close_notify,
// warning alerts are silently ignored and may only be surfaced with
// |SSL_CTX_set_info_callback|.

// SSL_AD_REASON_OFFSET is the offset between error reasons and |SSL_AD_*|
// values. Any error code under |ERR_LIB_SSL| with an error reason above this
// value corresponds to an alert description. Consumers may add or subtract
// |SSL_AD_REASON_OFFSET| to convert between them.
//
// make_errors.go reserves error codes above 1000 for manually-assigned errors.
// This value must be kept in sync with reservedReasonCode in make_errors.h
SSL_AD_REASON_OFFSET :: 1000

@(default_calling_convention="c")
foreign lib {
	// SSL_alert_type_string_long returns a string description of |value| as an
	// alert type (warning or fatal).
	SSL_alert_type_string_long :: proc(value: i32) -> cstring ---

	// SSL_alert_desc_string_long returns a string description of |value| as an
	// alert description or "unknown" if unknown.
	SSL_alert_desc_string_long :: proc(value: i32) -> cstring ---

	// SSL_send_fatal_alert sends a fatal alert over |ssl| of the specified type,
	// which should be one of the |SSL_AD_*| constants. It returns one on success
	// and <= 0 on error. The caller should pass the return value into
	// |SSL_get_error| to determine how to proceed. Once this function has been
	// called, future calls to |SSL_write| will fail.
	//
	// If retrying a failed operation due to |SSL_ERROR_WANT_WRITE|, subsequent
	// calls must use the same |alert| parameter.
	SSL_send_fatal_alert :: proc(ssl: ^SSL, alert: u8) -> i32 ---

	// ex_data functions.
	//
	// See |ex_data.h| for details.
	SSL_set_ex_data                 :: proc(ssl: ^SSL, idx: i32, data: rawptr) -> i32 ---
	SSL_get_ex_data                 :: proc(ssl: ^SSL, idx: i32) -> rawptr ---
	SSL_get_ex_new_index            :: proc(argl: c.long, argp: rawptr, unused: ^CRYPTO_EX_unused, dup_unused: ^CRYPTO_EX_dup, free_func: ^CRYPTO_EX_free) -> i32 ---
	SSL_SESSION_set_ex_data         :: proc(session: ^SSL_SESSION, idx: i32, data: rawptr) -> i32 ---
	SSL_SESSION_get_ex_data         :: proc(session: ^SSL_SESSION, idx: i32) -> rawptr ---
	SSL_SESSION_get_ex_new_index    :: proc(argl: c.long, argp: rawptr, unused: ^CRYPTO_EX_unused, dup_unused: ^CRYPTO_EX_dup, free_func: ^CRYPTO_EX_free) -> i32 ---
	SSL_CTX_set_ex_data             :: proc(ctx: ^SSL_CTX, idx: i32, data: rawptr) -> i32 ---
	SSL_CTX_get_ex_data             :: proc(ctx: ^SSL_CTX, idx: i32) -> rawptr ---
	SSL_CTX_get_ex_new_index        :: proc(argl: c.long, argp: rawptr, unused: ^CRYPTO_EX_unused, dup_unused: ^CRYPTO_EX_dup, free_func: ^CRYPTO_EX_free) -> i32 ---
	SSL_CREDENTIAL_set_ex_data      :: proc(cred: ^SSL_CREDENTIAL, idx: i32, data: rawptr) -> i32 ---
	SSL_CREDENTIAL_get_ex_data      :: proc(cred: ^SSL_CREDENTIAL, idx: i32) -> rawptr ---
	SSL_CREDENTIAL_get_ex_new_index :: proc(argl: c.long, argp: rawptr, unused: ^CRYPTO_EX_unused, dup_unused: ^CRYPTO_EX_dup, free_func: ^CRYPTO_EX_free) -> i32 ---

	// SSL_get_ivs sets |*out_iv_len| to the length of the IVs for the ciphers
	// underlying |ssl| and sets |*out_read_iv| and |*out_write_iv| to point to the
	// current IVs for the read and write directions. This is only meaningful for
	// connections with implicit IVs (i.e. CBC mode with TLS 1.0).
	//
	// It returns one on success or zero on error.
	SSL_get_ivs :: proc(ssl: ^SSL, out_read_iv: ^^u8, out_write_iv: ^^u8, out_iv_len: ^c.size_t) -> i32 ---

	// SSL_get_key_block_len returns the length of |ssl|'s key block, for TLS 1.2
	// and below. It is an error to call this function during a handshake, or if
	// |ssl| negotiated TLS 1.3.
	SSL_get_key_block_len :: proc(ssl: ^SSL) -> c.size_t ---

	// SSL_generate_key_block generates |out_len| bytes of key material for |ssl|'s
	// current connection state, for TLS 1.2 and below. It is an error to call this
	// function during a handshake, or if |ssl| negotiated TLS 1.3.
	SSL_generate_key_block :: proc(ssl: ^SSL, out: ^u8, out_len: c.size_t) -> i32 ---

	// SSL_get_read_sequence returns, in TLS, the expected sequence number of the
	// next incoming record in the current epoch.
	//
	// TODO(crbug.com/42290608): In DTLS, it returns the maximum sequence number
	// received in the current epoch (for some notion of "current" specific to
	// BoringSSL) and includes the epoch number in the two most significant bytes,
	// but this is deprecated. Use |SSL_get_dtls_read_sequence| instead.
	SSL_get_read_sequence :: proc(ssl: ^SSL) -> u64 ---

	// SSL_get_write_sequence returns the sequence number of the next outgoing
	// record in the current epoch.
	//
	// TODO(crbug.com/42290608): In DTLS, it includes the epoch number in the two
	// most significant bytes, but this is deprecated. Use
	// |SSL_get_dtls_write_sequence| instead.
	SSL_get_write_sequence :: proc(ssl: ^SSL) -> u64 ---

	// SSL_CTX_set_record_protocol_version returns whether |version| is zero.
	SSL_CTX_set_record_protocol_version :: proc(ctx: ^SSL_CTX, version: i32) -> i32 ---

	// SSL_is_dtls_handshake_idle returns one |ssl|'s handshake is idle and zero if
	// it is busy. The handshake is considered idle if all of the following are
	// true:
	//
	// - |ssl| is not mid handshake or post-handshake transaction.
	// - In DTLS 1.3, all sent handshake messages have been acknowledged. That is,
	//   |ssl| does not have data to retransmit.
	// - All received handshake data has been processed. That is, |ssl| has no
	//   buffered partial or out-of-order messages.
	//
	// If any condition is false, the handshake is considered busy. If this function
	// reports the handshake is busy, it is expected that the handshake will become
	// idle after short timers and a few roundtrips of successful communication.
	// However, this is not guaranteed if, e.g., the peer misbehaves or sends many
	// KeyUpdates.
	//
	// WARNING: In DTLS 1.3, this function may return one while multiple active read
	// epochs exist in |ssl|.
	//
	// WARNING: In DTLS 1.2 (or earlier), if |ssl| is the role that speaks last, it
	// retains its final flight for retransmission in case of loss. There is no
	// explicit protocol signal for when this completes, though after receiving
	// application data and/or a timeout it is likely that this is no longer needed.
	// BoringSSL does not currently evaluate either condition and leaves it it to
	// the caller to determine whether this is now unnecessary. This applies when
	// |ssl| is a server for full handshakes and when |ssl| is a client for full
	// handshakes.
	SSL_is_dtls_handshake_idle :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_dtls_handshake_read_seq returns the 16-bit sequence number of the
	// next DTLS handshake message to be read, or 0x10000 if handshake message
	// 0xffff (the maximum) has already been read.
	SSL_get_dtls_handshake_read_seq :: proc(ssl: ^SSL) -> u32 ---

	// SSL_get_dtls_handshake_write_seq returns the 16-bit sequence number of the
	// next DTLS handshake message to be written or 0x10000 if handshake message
	// 0xffff (the maximum) has already been written.
	SSL_get_dtls_handshake_write_seq :: proc(ssl: ^SSL) -> u32 ---

	// SSL_get_dtls_read_epoch returns the highest available DTLS read epoch in
	// |ssl|. In DTLS 1.3, |ssl| may have earlier epochs also active, sometimes to
	// optionally improve handling of reordered packets and sometimes as an
	// important part of the protocol correctness in the face of packet loss.
	//
	// The failure conditions of |SSL_get_dtls_read_traffic_secret| and
	// |SSL_get_dtls_read_sequence| can be used to determine if past epochs are
	// active.
	SSL_get_dtls_read_epoch :: proc(ssl: ^SSL) -> u16 ---

	// SSL_get_dtls_write_epoch returns the current DTLS write epoch. If the
	// handshake is idle (see |SSL_is_dtls_handshake_idle|), no other write epochs
	// will be active.
	SSL_get_dtls_write_epoch :: proc(ssl: ^SSL) -> u16 ---

	// SSL_get_dtls_read_sequence returns one more than the sequence number of the
	// highest record received in |epoch|. If no records have been received in
	// |epoch|. If the epoch does not exist, it returns |UINT64_MAX|.
	//
	// It is safe to discard all sequence numbers less than the return value of this
	// function. The sequence numbers returned by this function do not include the
	// epoch number in the upper 16 bits.
	SSL_get_dtls_read_sequence :: proc(ssl: ^SSL, epoch: u16) -> u64 ---

	// SSL_get_dtls_write_sequence returns the sequence number of the next record to
	// be sent in |epoch|. If the epoch does not exist, it returns |UINT64_MAX|.
	//
	// The sequence numbers returned by this function do not include the epoch
	// number in the upper 16 bits.
	SSL_get_dtls_write_sequence :: proc(ssl: ^SSL, epoch: u16) -> u64 ---

	// SSL_get_dtls_read_traffic_secret looks up the traffic secret for read epoch
	// |epoch|. If the epoch exists and is an encrypted (not epoch zero) DTLS 1.3
	// epoch, it sets |*out_data| and |*out_len| to a buffer containing the secrets
	// and returns one. Otherwise, it returns zero. The buffer is valid until the
	// next operation on |ssl|.
	SSL_get_dtls_read_traffic_secret :: proc(ssl: ^SSL, out_data: ^^u8, out_len: ^c.size_t, epoch: u16) -> i32 ---

	// SSL_get_dtls_write_traffic_secret looks up the traffic secret for write epoch
	// |epoch|. If the epoch exists and is an encrypted (not epoch zero) DTLS 1.3
	// epoch, it sets |*out_data| and |*out_len| to a buffer containing the secrets
	// and returns one. Otherwise, it returns zero. The buffer is valid until the
	// next operation on |ssl|.
	SSL_get_dtls_write_traffic_secret :: proc(ssl: ^SSL, out_data: ^^u8, out_len: ^c.size_t, epoch: u16) -> i32 ---

	// SSL_serialize_capabilities writes an opaque byte string to |out| describing
	// some of |ssl|'s capabilities. It returns one on success and zero on error.
	//
	// This string is used by BoringSSL internally to reduce the impact of version
	// skew.
	SSL_serialize_capabilities :: proc(ssl: ^SSL, out: ^CBB) -> i32 ---

	// SSL_request_handshake_hints configures |ssl| to generate a handshake hint for
	// |client_hello|. It returns one on success and zero on error. |client_hello|
	// should contain a serialized ClientHello structure, from the |client_hello|
	// and |client_hello_len| fields of the |SSL_CLIENT_HELLO| structure.
	// |capabilities| should contain the output of |SSL_serialize_capabilities|.
	//
	// When configured, |ssl| will perform no I/O (so there is no need to configure
	// |BIO|s). For QUIC, the caller should still configure an |SSL_QUIC_METHOD|,
	// but the callbacks themselves will never be called and may be left NULL or
	// report failure. |SSL_provide_quic_data| also should not be called.
	//
	// If hint generation is successful, |SSL_do_handshake| will stop the handshake
	// early with |SSL_get_error| returning |SSL_ERROR_HANDSHAKE_HINTS_READY|. At
	// this point, the caller should run |SSL_serialize_handshake_hints| to extract
	// the resulting hints.
	//
	// Hint generation may fail if, e.g., |ssl| was unable to process the
	// ClientHello. Callers should then complete the certificate selection RPC and
	// continue the original handshake with no hint. It will likely fail, but this
	// reports the correct alert to the client and is more robust in case of
	// mismatch.
	SSL_request_handshake_hints :: proc(ssl: ^SSL, client_hello: ^u8, client_hello_len: c.size_t, capabilities: ^u8, capabilities_len: c.size_t) -> i32 ---

	// SSL_serialize_handshake_hints writes an opaque byte string to |out|
	// containing the handshake hints computed by |out|. It returns one on success
	// and zero on error. This function should only be called if
	// |SSL_request_handshake_hints| was configured and the handshake terminated
	// with |SSL_ERROR_HANDSHAKE_HINTS_READY|.
	//
	// This string may be passed to |SSL_set_handshake_hints| on another |SSL| to
	// avoid an extra signature call.
	SSL_serialize_handshake_hints :: proc(ssl: ^SSL, out: ^CBB) -> i32 ---

	// SSL_set_handshake_hints configures |ssl| to use |hints| as handshake hints.
	// It returns one on success and zero on error. The handshake will then continue
	// as before, but apply predicted values from |hints| where applicable.
	//
	// Hints may contain connection and session secrets, so they must not leak and
	// must come from a source trusted to terminate the connection. However, they
	// will not change |ssl|'s configuration. The caller is responsible for
	// serializing and applying options from the RPC server as needed. This ensures
	// |ssl|'s behavior is self-consistent and consistent with the caller's local
	// decisions.
	SSL_set_handshake_hints :: proc(ssl: ^SSL, hints: ^u8, hints_len: c.size_t) -> i32 ---

	// SSL_CTX_set_msg_callback installs |cb| as the message callback for |ctx|.
	// This callback will be called when sending or receiving low-level record
	// headers, complete handshake messages, ChangeCipherSpec, alerts, and DTLS
	// ACKs. |write_p| is one for outgoing messages and zero for incoming messages.
	//
	// For each record header, |cb| is called with |version| = 0 and |content_type|
	// = |SSL3_RT_HEADER|. The |len| bytes from |buf| contain the header. Note that
	// this does not include the record body. If the record is sealed, the length
	// in the header is the length of the ciphertext.
	//
	// For each handshake message, ChangeCipherSpec, alert, and DTLS ACK, |version|
	// is the protocol version and |content_type| is the corresponding record type.
	// The |len| bytes from |buf| contain the handshake message, one-byte
	// ChangeCipherSpec body, two-byte alert, and ACK respectively.
	//
	// In connections that enable ECH, |cb| is additionally called with
	// |content_type| = |SSL3_RT_CLIENT_HELLO_INNER| for each ClientHelloInner that
	// is encrypted or decrypted. The |len| bytes from |buf| contain the
	// ClientHelloInner, including the reconstructed outer extensions and handshake
	// header.
	//
	// For a V2ClientHello, |version| is |SSL2_VERSION|, |content_type| is zero, and
	// the |len| bytes from |buf| contain the V2ClientHello structure.
	SSL_CTX_set_msg_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (is_write: i32, version: i32, content_type: i32, buf: rawptr, len: c.size_t, ssl: ^SSL, arg: rawptr)) ---

	// SSL_set_msg_callback installs |cb| as the message callback of |ssl|. See
	// |SSL_CTX_set_msg_callback| for when this callback is called.
	SSL_set_msg_callback :: proc(ssl: ^SSL, cb: proc "c" (write_p: i32, version: i32, content_type: i32, buf: rawptr, len: c.size_t, ssl: ^SSL, arg: rawptr)) ---

	// SSL_CTX_set_keylog_callback configures a callback to log key material. This
	// is intended for debugging use with tools like Wireshark. The |cb| function
	// should log |line| followed by a newline, synchronizing with any concurrent
	// access to the log.
	//
	// The format is described in
	// https://www.ietf.org/archive/id/draft-ietf-tls-keylogfile-01.html
	//
	// WARNING: The data in |line| allows an attacker to break security properties
	// of the TLS protocol, including confidentiality, integrity, and forward
	// secrecy. This impacts both the current connection, and, in TLS 1.2, future
	// connections that resume a session from it. Both direct access to the data and
	// side channel leaks from application code are possible attack vectors. This
	// callback is intended for debugging and should not be used in production
	// connections.
	SSL_CTX_set_keylog_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, line: cstring)) ---

	// SSL_CTX_get_keylog_callback returns the callback configured by
	// |SSL_CTX_set_keylog_callback|.
	SSL_CTX_get_keylog_callback :: proc(ssl: ^SSL, line: cstring, ctx: ^SSL_CTX) -> proc "c" (^SSL, cstring) ---

	// SSL_CTX_set_current_time_cb configures a callback to retrieve the current
	// time, which should be set in |*out_clock|. This can be used for testing
	// purposes; for example, a callback can be configured that returns a time
	// set explicitly by the test. The |ssl| pointer passed to |cb| is always null.
	SSL_CTX_set_current_time_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, out_clock: ^timeval)) ---

	// SSL_set_shed_handshake_config allows some of the configuration of |ssl| to be
	// freed after its handshake completes.  Once configuration has been shed, APIs
	// that query it may fail.  "Configuration" in this context means anything that
	// was set by the caller, as distinct from information derived from the
	// handshake.  For example, |SSL_get_ciphers| queries how the |SSL| was
	// configured by the caller, and fails after configuration has been shed,
	// whereas |SSL_get_cipher| queries the result of the handshake, and is
	// unaffected by configuration shedding.
	//
	// If configuration shedding is enabled, it is an error to call |SSL_clear|.
	//
	// Note that configuration shedding as a client additionally depends on
	// renegotiation being disabled (see |SSL_set_renegotiate_mode|). If
	// renegotiation is possible, the configuration will be retained. If
	// configuration shedding is enabled and renegotiation later disabled after the
	// handshake, |SSL_set_renegotiate_mode| will shed configuration then. This may
	// be useful for clients which support renegotiation with some ALPN protocols,
	// such as HTTP/1.1, and not others, such as HTTP/2.
	SSL_set_shed_handshake_config :: proc(ssl: ^SSL, enable: i32) ---
}

ssl_renegotiate_mode_t :: enum u32 {
	never    = 0,
	once     = 1,
	freely   = 2,
	ignore   = 3,
	explicit = 4,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_set_renegotiate_mode configures how |ssl|, a client, reacts to
	// renegotiation attempts by a server. If |ssl| is a server, peer-initiated
	// renegotiations are *always* rejected and this function does nothing.
	//
	// WARNING: Renegotiation is error-prone, complicates TLS's security properties,
	// and increases its attack surface. When enabled, many common assumptions about
	// BoringSSL's behavior no longer hold, and the calling application must handle
	// more cases. Renegotiation is also incompatible with many application
	// protocols, e.g. section 9.2.1 of RFC 7540. Many functions behave in ambiguous
	// or undefined ways during a renegotiation.
	//
	// The renegotiation mode defaults to |ssl_renegotiate_never|, but may be set
	// at any point in a connection's lifetime. Set it to |ssl_renegotiate_once| to
	// allow one renegotiation, |ssl_renegotiate_freely| to allow all
	// renegotiations or |ssl_renegotiate_ignore| to ignore HelloRequest messages.
	// Note that ignoring HelloRequest messages may cause the connection to stall
	// if the server waits for the renegotiation to complete.
	//
	// If set to |ssl_renegotiate_explicit|, |SSL_read| and |SSL_peek| calls which
	// encounter a HelloRequest will pause with |SSL_ERROR_WANT_RENEGOTIATE|.
	// |SSL_write| will continue to work while paused. The caller may call
	// |SSL_renegotiate| to begin the renegotiation at a later point. This mode may
	// be used if callers wish to eagerly call |SSL_peek| without triggering a
	// renegotiation.
	//
	// If configuration shedding is enabled (see |SSL_set_shed_handshake_config|),
	// configuration is released if, at any point after the handshake, renegotiation
	// is disabled. It is not possible to switch from disabling renegotiation to
	// enabling it on a given connection. Callers that condition renegotiation on,
	// e.g., ALPN must enable renegotiation before the handshake and conditionally
	// disable it afterwards.
	//
	// When enabled, renegotiation can cause properties of |ssl|, such as the cipher
	// suite, to change during the lifetime of the connection. More over, during a
	// renegotiation, not all properties of the new handshake are available or fully
	// established. In BoringSSL, most functions, such as |SSL_get_current_cipher|,
	// report information from the most recently completed handshake, not the
	// pending one. However, renegotiation may rerun handshake callbacks, such as
	// |SSL_CTX_set_cert_cb|. Such callbacks must ensure they are acting on the
	// desired versions of each property.
	//
	// BoringSSL does not reverify peer certificates on renegotiation and instead
	// requires they match between handshakes, so certificate verification callbacks
	// (see |SSL_CTX_set_custom_verify|) may assume |ssl| is in the initial
	// handshake and use |SSL_get0_peer_certificates|, etc.
	//
	// There is no support in BoringSSL for initiating renegotiations as a client
	// or server.
	SSL_set_renegotiate_mode :: proc(ssl: ^SSL, mode: ssl_renegotiate_mode_t) ---

	// SSL_renegotiate starts a deferred renegotiation on |ssl| if it was configured
	// with |ssl_renegotiate_explicit| and has a pending HelloRequest. It returns
	// one on success and zero on error.
	//
	// This function does not do perform any I/O. On success, a subsequent
	// |SSL_do_handshake| call will run the handshake. |SSL_write| and
	// |SSL_read| will also complete the handshake before sending or receiving
	// application data.
	SSL_renegotiate :: proc(ssl: ^SSL) -> i32 ---

	// SSL_renegotiate_pending returns one if |ssl| is in the middle of a
	// renegotiation.
	SSL_renegotiate_pending :: proc(ssl: ^SSL) -> i32 ---
}

// SSL_MAX_CERT_LIST_DEFAULT is the default maximum length, in bytes, of a peer
// certificate chain.
SSL_MAX_CERT_LIST_DEFAULT :: (1024*100)

// ssl_early_callback_ctx (aka |SSL_CLIENT_HELLO|) is passed to certain
// callbacks that are called very early on during the server handshake. At this
// point, much of the SSL* hasn't been filled out and only the ClientHello can
// be depended on.
ssl_early_callback_ctx :: struct {
	ssl:                     ^SSL,
	client_hello:            ^u8,
	client_hello_len:        c.size_t,
	version:                 u16,
	random:                  ^u8,
	random_len:              c.size_t,
	session_id:              ^u8,
	session_id_len:          c.size_t,
	dtls_cookie:             ^u8,
	dtls_cookie_len:         c.size_t,
	cipher_suites:           ^u8,
	cipher_suites_len:       c.size_t,
	compression_methods:     ^u8,
	compression_methods_len: c.size_t,
	extensions:              ^u8,
	extensions_len:          c.size_t,
}

// ssl_select_cert_result_t enumerates the possible results from selecting a
// certificate with |select_certificate_cb|.
ssl_select_cert_result_t :: enum i32 {
	// ssl_select_cert_success indicates that the certificate selection was
	// successful.
	success     = 1,

	// ssl_select_cert_retry indicates that the operation could not be
	// immediately completed and must be reattempted at a later point.
	retry       = 0,

	// ssl_select_cert_error indicates that a fatal error occurred and the
	// handshake should be terminated.
	error       = -1,

	// ssl_select_cert_disable_ech indicates that, although an encrypted
	// ClientHelloInner was decrypted, it should be discarded. The certificate
	// selection callback will then be called again, passing in the
	// ClientHelloOuter instead. From there, the handshake will proceed
	// without retry_configs, to signal to the client to disable ECH.
	//
	// This value may only be returned when |SSL_ech_accepted| returns one. It
	// may be useful if the ClientHelloInner indicated a service which does not
	// support ECH, e.g. if it is a TLS-1.2 only service.
	disable_ech = -2,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_early_callback_ctx_extension_get searches the extensions in
	// |client_hello| for an extension of the given type. If not found, it returns
	// zero. Otherwise it sets |out_data| to point to the extension contents (not
	// including the type and length bytes), sets |out_len| to the length of the
	// extension contents and returns one.
	SSL_early_callback_ctx_extension_get :: proc(client_hello: ^SSL_CLIENT_HELLO, extension_type: u16, out_data: ^^u8, out_len: ^c.size_t) -> i32 ---

	// SSL_CTX_set_select_certificate_cb sets a callback that is called before most
	// ClientHello processing and before the decision whether to resume a session
	// is made. The callback may inspect the ClientHello and configure the
	// connection. See |ssl_select_cert_result_t| for details of the return values.
	//
	// In the case that a retry is indicated, |SSL_get_error| will return
	// |SSL_ERROR_PENDING_CERTIFICATE| and the caller should arrange for the
	// high-level operation on |ssl| to be retried at a later time, which will
	// result in another call to |cb|.
	//
	// |SSL_get_servername| may be used during this callback.
	//
	// Note: The |SSL_CLIENT_HELLO| is only valid for the duration of the callback
	// and is not valid while the handshake is paused.
	SSL_CTX_set_select_certificate_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (^SSL_CLIENT_HELLO) -> ssl_select_cert_result_t) ---

	// SSL_CTX_set_dos_protection_cb sets a callback that is called once the
	// resumption decision for a ClientHello has been made. It can return one to
	// allow the handshake to continue or zero to cause the handshake to abort.
	SSL_CTX_set_dos_protection_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (^SSL_CLIENT_HELLO) -> i32) ---

	// SSL_CTX_set_reverify_on_resume configures whether the certificate
	// verification callback will be used to reverify stored certificates
	// when resuming a session. This only works with |SSL_CTX_set_custom_verify|.
	// For now, this is incompatible with |SSL_VERIFY_NONE| mode, and is only
	// respected on clients.
	SSL_CTX_set_reverify_on_resume :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_set_enforce_rsa_key_usage configures whether, when |ssl| is a client
	// negotiating TLS 1.2 or below, the keyUsage extension of RSA leaf server
	// certificates will be checked for consistency with the TLS usage. In all other
	// cases, this check is always enabled.
	//
	// This parameter may be set late; it will not be read until after the
	// certificate verification callback.
	SSL_set_enforce_rsa_key_usage :: proc(ssl: ^SSL, enabled: i32) ---

	// SSL_was_key_usage_invalid returns one if |ssl|'s handshake succeeded despite
	// using TLS parameters which were incompatible with the leaf certificate's
	// keyUsage extension. Otherwise, it returns zero.
	//
	// If |SSL_set_enforce_rsa_key_usage| is enabled or not applicable, this
	// function will always return zero because key usages will be consistently
	// checked.
	SSL_was_key_usage_invalid :: proc(ssl: ^SSL) -> i32 ---
}

// SSL_ST_* are possible values for |SSL_state|, the bitmasks that make them up,
// and some historical values for compatibility. Only |SSL_ST_INIT| and
// |SSL_ST_OK| are ever returned.
SSL_ST_CONNECT     :: 0x1000
SSL_ST_ACCEPT      :: 0x2000
SSL_ST_MASK        :: 0x0FFF
SSL_ST_INIT        :: (SSL_ST_CONNECT|SSL_ST_ACCEPT)
SSL_ST_OK          :: 0x03
SSL_ST_RENEGOTIATE :: (0x04|SSL_ST_INIT)
SSL_ST_BEFORE      :: (0x05|SSL_ST_INIT)

// TLS_ST_* are aliases for |SSL_ST_*| for OpenSSL 1.1.0 compatibility.
TLS_ST_OK     :: SSL_ST_OK
TLS_ST_BEFORE :: SSL_ST_BEFORE

// SSL_CB_* are possible values for the |type| parameter in the info
// callback and the bitmasks that make them up.
SSL_CB_LOOP            :: 0x01
SSL_CB_EXIT            :: 0x02
SSL_CB_READ            :: 0x04
SSL_CB_WRITE           :: 0x08
SSL_CB_ALERT           :: 0x4000
SSL_CB_READ_ALERT      :: (SSL_CB_ALERT|SSL_CB_READ)
SSL_CB_WRITE_ALERT     :: (SSL_CB_ALERT|SSL_CB_WRITE)
SSL_CB_ACCEPT_LOOP     :: (SSL_ST_ACCEPT|SSL_CB_LOOP)
SSL_CB_ACCEPT_EXIT     :: (SSL_ST_ACCEPT|SSL_CB_EXIT)
SSL_CB_CONNECT_LOOP    :: (SSL_ST_CONNECT|SSL_CB_LOOP)
SSL_CB_CONNECT_EXIT    :: (SSL_ST_CONNECT|SSL_CB_EXIT)
SSL_CB_HANDSHAKE_START :: 0x10
SSL_CB_HANDSHAKE_DONE  :: 0x20

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_info_callback configures a callback to be run when various
	// events occur during a connection's lifetime. The |type| argument determines
	// the type of event and the meaning of the |value| argument. Callbacks must
	// ignore unexpected |type| values.
	//
	// |SSL_CB_READ_ALERT| is signaled for each alert received, warning or fatal.
	// The |value| argument is a 16-bit value where the alert level (either
	// |SSL3_AL_WARNING| or |SSL3_AL_FATAL|) is in the most-significant eight bits
	// and the alert type (one of |SSL_AD_*|) is in the least-significant eight.
	//
	// |SSL_CB_WRITE_ALERT| is signaled for each alert sent. The |value| argument
	// is constructed as with |SSL_CB_READ_ALERT|.
	//
	// |SSL_CB_HANDSHAKE_START| is signaled when a handshake begins. The |value|
	// argument is always one.
	//
	// |SSL_CB_HANDSHAKE_DONE| is signaled when a handshake completes successfully.
	// The |value| argument is always one. If a handshake False Starts, this event
	// may be used to determine when the Finished message is received.
	//
	// The following event types expose implementation details of the handshake
	// state machine. Consuming them is deprecated.
	//
	// |SSL_CB_ACCEPT_LOOP| (respectively, |SSL_CB_CONNECT_LOOP|) is signaled when
	// a server (respectively, client) handshake progresses. The |value| argument
	// is always one.
	//
	// |SSL_CB_ACCEPT_EXIT| (respectively, |SSL_CB_CONNECT_EXIT|) is signaled when
	// a server (respectively, client) handshake completes, fails, or is paused.
	// The |value| argument is one if the handshake succeeded and <= 0
	// otherwise.
	SSL_CTX_set_info_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, type: i32, value: i32)) ---

	// SSL_CTX_get_info_callback returns the callback set by
	// |SSL_CTX_set_info_callback|.
	SSL_CTX_get_info_callback :: proc(ctx: ^SSL_CTX) -> proc "c" (^SSL, i32, i32) ---

	// SSL_set_info_callback configures a callback to be run at various events
	// during a connection's lifetime. See |SSL_CTX_set_info_callback|.
	SSL_set_info_callback :: proc(ssl: ^SSL, cb: proc "c" (ssl: ^SSL, type: i32, value: i32)) ---

	// SSL_get_info_callback returns the callback set by |SSL_set_info_callback|.
	SSL_get_info_callback :: proc(ssl: ^SSL) -> proc "c" (^SSL, i32, i32) ---

	// SSL_state_string_long returns the current state of the handshake state
	// machine as a string. This may be useful for debugging and logging.
	SSL_state_string_long :: proc(ssl: ^SSL) -> cstring ---
}

SSL_SENT_SHUTDOWN     :: 1
SSL_RECEIVED_SHUTDOWN :: 2

@(default_calling_convention="c")
foreign lib {
	// SSL_get_shutdown returns a bitmask with a subset of |SSL_SENT_SHUTDOWN| and
	// |SSL_RECEIVED_SHUTDOWN| to query whether close_notify was sent or received,
	// respectively.
	SSL_get_shutdown :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_peer_signature_algorithm returns the signature algorithm used by the
	// peer. If not applicable, it returns zero.
	SSL_get_peer_signature_algorithm :: proc(ssl: ^SSL) -> u16 ---

	// SSL_get_client_random writes up to |max_out| bytes of the most recent
	// handshake's client_random to |out| and returns the number of bytes written.
	// If |max_out| is zero, it returns the size of the client_random.
	SSL_get_client_random :: proc(ssl: ^SSL, out: ^u8, max_out: c.size_t) -> c.size_t ---

	// SSL_get_server_random writes up to |max_out| bytes of the most recent
	// handshake's server_random to |out| and returns the number of bytes written.
	// If |max_out| is zero, it returns the size of the server_random.
	SSL_get_server_random :: proc(ssl: ^SSL, out: ^u8, max_out: c.size_t) -> c.size_t ---

	// SSL_get_pending_cipher returns the cipher suite for the current handshake or
	// NULL if one has not been negotiated yet or there is no pending handshake.
	SSL_get_pending_cipher :: proc(ssl: ^SSL) -> ^SSL_CIPHER ---

	// SSL_set_retain_only_sha256_of_client_certs, on a server, sets whether only
	// the SHA-256 hash of peer's certificate should be saved in memory and in the
	// session. This can save memory, ticket size and session cache space. If
	// enabled, |SSL_get_peer_certificate| will return NULL after the handshake
	// completes. See |SSL_SESSION_has_peer_sha256| and
	// |SSL_SESSION_get0_peer_sha256| to query the hash.
	SSL_set_retain_only_sha256_of_client_certs :: proc(ssl: ^SSL, enable: i32) ---

	// SSL_CTX_set_retain_only_sha256_of_client_certs, on a server, sets whether
	// only the SHA-256 hash of peer's certificate should be saved in memory and in
	// the session. This can save memory, ticket size and session cache space. If
	// enabled, |SSL_get_peer_certificate| will return NULL after the handshake
	// completes. See |SSL_SESSION_has_peer_sha256| and
	// |SSL_SESSION_get0_peer_sha256| to query the hash.
	SSL_CTX_set_retain_only_sha256_of_client_certs :: proc(ctx: ^SSL_CTX, enable: i32) ---

	// SSL_CTX_set_grease_enabled configures whether sockets on |ctx| should enable
	// GREASE. See RFC 8701.
	SSL_CTX_set_grease_enabled :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_CTX_set_permute_extensions configures whether sockets on |ctx| should
	// permute extensions. For now, this is only implemented for the ClientHello.
	SSL_CTX_set_permute_extensions :: proc(ctx: ^SSL_CTX, enabled: i32) ---

	// SSL_set_permute_extensions configures whether sockets on |ssl| should
	// permute extensions. For now, this is only implemented for the ClientHello.
	SSL_set_permute_extensions :: proc(ssl: ^SSL, enabled: i32) ---

	// SSL_max_seal_overhead returns the maximum overhead, in bytes, of sealing a
	// record with |ssl|.
	SSL_max_seal_overhead :: proc(ssl: ^SSL) -> c.size_t ---

	// SSL_CTX_set_false_start_allowed_without_alpn configures whether connections
	// on |ctx| may use False Start (if |SSL_MODE_ENABLE_FALSE_START| is enabled)
	// without negotiating ALPN.
	SSL_CTX_set_false_start_allowed_without_alpn :: proc(ctx: ^SSL_CTX, allowed: i32) ---

	// SSL_used_hello_retry_request returns one if the TLS 1.3 HelloRetryRequest
	// message has been either sent by the server or received by the client. It
	// returns zero otherwise.
	SSL_used_hello_retry_request :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_jdk11_workaround configures whether to workaround various bugs in
	// JDK 11's TLS 1.3 implementation by disabling TLS 1.3 for such clients.
	//
	// https://bugs.openjdk.java.net/browse/JDK-8211806
	// https://bugs.openjdk.java.net/browse/JDK-8212885
	// https://bugs.openjdk.java.net/browse/JDK-8213202
	SSL_set_jdk11_workaround :: proc(ssl: ^SSL, enable: i32) ---

	// SSL_parse_client_hello decodes a ClientHello structure from |len| bytes in
	// |in|. On success, it returns one and writes the result to |*out|. Otherwise,
	// it returns zero. |ssl| will be saved into |*out| and determines how the
	// ClientHello is parsed, notably TLS vs DTLS. The fields in |*out| will alias
	// |in| and are only valid as long as |in| is valid and unchanged.
	//
	// |in| should contain just the ClientHello structure (RFC 8446 and RFC 9147),
	// excluding the handshake header and already reassembled from record layer.
	// That is, |in| should begin with the legacy_version field, not the
	// client_hello HandshakeType constant or the handshake ContentType constant.
	SSL_parse_client_hello :: proc(ssl: ^SSL, out: ^SSL_CLIENT_HELLO, _in: ^u8, len: c.size_t) -> i32 ---

	// SSL_library_init returns one.
	SSL_library_init :: proc() -> i32 ---

	// SSL_CIPHER_description writes a description of |cipher| into |buf| and
	// returns |buf|. If |buf| is NULL, it returns a newly allocated string, to be
	// freed with |OPENSSL_free|, or NULL on error.
	//
	// The description includes a trailing newline and has the form:
	// AES128-SHA              Kx=RSA      Au=RSA  Enc=AES(128)  Mac=SHA1
	//
	// Consider |SSL_CIPHER_standard_name| or |SSL_CIPHER_get_name| instead.
	SSL_CIPHER_description :: proc(cipher: ^SSL_CIPHER, buf: cstring, len: i32) -> cstring ---

	// SSL_CIPHER_get_version returns the string "TLSv1/SSLv3".
	SSL_CIPHER_get_version :: proc(cipher: ^SSL_CIPHER) -> cstring ---

	// SSL_CIPHER_get_id returns |cipher|'s IANA-assigned number, OR-d with
	// 0x03000000. This is part of OpenSSL's SSL 2.0 legacy. SSL 2.0 has long since
	// been removed from BoringSSL. Use |SSL_CIPHER_get_protocol_id| instead.
	SSL_CIPHER_get_id :: proc(cipher: ^SSL_CIPHER) -> u32 ---

	// SSL_CIPHER_get_name returns the OpenSSL name of |cipher|. For example,
	// "ECDHE-RSA-AES128-GCM-SHA256". Callers are recommended to use
	// |SSL_CIPHER_standard_name| instead.
	SSL_CIPHER_get_name :: proc(cipher: ^SSL_CIPHER) -> cstring ---
}

COMP_METHOD       :: struct {}
SSL_COMP          :: ssl_comp_st
stack_st_SSL_COMP :: struct {}

@(default_calling_convention="c")
foreign lib {
	// SSL_COMP_get_compression_methods returns NULL.
	SSL_COMP_get_compression_methods :: proc() -> ^stack_st_SSL_COMP ---

	// SSL_COMP_add_compression_method returns one.
	SSL_COMP_add_compression_method :: proc(id: i32, cm: ^COMP_METHOD) -> i32 ---

	// SSL_COMP_get_name returns NULL.
	SSL_COMP_get_name :: proc(comp: ^COMP_METHOD) -> cstring ---

	// SSL_COMP_get0_name returns the |name| member of |comp|.
	SSL_COMP_get0_name :: proc(comp: ^SSL_COMP) -> cstring ---

	// SSL_COMP_get_id returns the |id| member of |comp|.
	SSL_COMP_get_id :: proc(comp: ^SSL_COMP) -> i32 ---

	// SSL_COMP_free_compression_methods does nothing.
	SSL_COMP_free_compression_methods :: proc() ---

	// SSLv23_method calls |TLS_method|.
	SSLv23_method :: proc() -> ^SSL_METHOD ---

	// These version-specific methods behave exactly like |TLS_method| and
	// |DTLS_method| except they also call |SSL_CTX_set_min_proto_version| and
	// |SSL_CTX_set_max_proto_version| to lock connections to that protocol
	// version.
	TLSv1_method    :: proc() -> ^SSL_METHOD ---
	TLSv1_1_method  :: proc() -> ^SSL_METHOD ---
	TLSv1_2_method  :: proc() -> ^SSL_METHOD ---
	DTLSv1_method   :: proc() -> ^SSL_METHOD ---
	DTLSv1_2_method :: proc() -> ^SSL_METHOD ---

	// These client- and server-specific methods call their corresponding generic
	// methods.
	TLS_server_method      :: proc() -> ^SSL_METHOD ---
	TLS_client_method      :: proc() -> ^SSL_METHOD ---
	SSLv23_server_method   :: proc() -> ^SSL_METHOD ---
	SSLv23_client_method   :: proc() -> ^SSL_METHOD ---
	TLSv1_server_method    :: proc() -> ^SSL_METHOD ---
	TLSv1_client_method    :: proc() -> ^SSL_METHOD ---
	TLSv1_1_server_method  :: proc() -> ^SSL_METHOD ---
	TLSv1_1_client_method  :: proc() -> ^SSL_METHOD ---
	TLSv1_2_server_method  :: proc() -> ^SSL_METHOD ---
	TLSv1_2_client_method  :: proc() -> ^SSL_METHOD ---
	DTLS_server_method     :: proc() -> ^SSL_METHOD ---
	DTLS_client_method     :: proc() -> ^SSL_METHOD ---
	DTLSv1_server_method   :: proc() -> ^SSL_METHOD ---
	DTLSv1_client_method   :: proc() -> ^SSL_METHOD ---
	DTLSv1_2_server_method :: proc() -> ^SSL_METHOD ---
	DTLSv1_2_client_method :: proc() -> ^SSL_METHOD ---

	// SSL_clear resets |ssl| to allow another connection and returns one on success
	// or zero on failure. It returns most configuration state but releases memory
	// associated with the current connection.
	//
	// Free |ssl| and create a new one instead.
	SSL_clear :: proc(ssl: ^SSL) -> i32 ---

	// SSL_CTX_set_tmp_rsa_callback does nothing.
	SSL_CTX_set_tmp_rsa_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, is_export: i32, keylength: i32) -> ^RSA) ---

	// SSL_set_tmp_rsa_callback does nothing.
	SSL_set_tmp_rsa_callback :: proc(ssl: ^SSL, cb: proc "c" (ssl: ^SSL, is_export: i32, keylength: i32) -> ^RSA) ---

	// SSL_CTX_sess_connect returns zero.
	SSL_CTX_sess_connect :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_connect_good returns zero.
	SSL_CTX_sess_connect_good :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_connect_renegotiate returns zero.
	SSL_CTX_sess_connect_renegotiate :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_accept returns zero.
	SSL_CTX_sess_accept :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_accept_renegotiate returns zero.
	SSL_CTX_sess_accept_renegotiate :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_accept_good returns zero.
	SSL_CTX_sess_accept_good :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_hits returns zero.
	SSL_CTX_sess_hits :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_cb_hits returns zero.
	SSL_CTX_sess_cb_hits :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_misses returns zero.
	SSL_CTX_sess_misses :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_timeouts returns zero.
	SSL_CTX_sess_timeouts :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_CTX_sess_cache_full returns zero.
	SSL_CTX_sess_cache_full :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_cutthrough_complete calls |SSL_in_false_start|.
	SSL_cutthrough_complete :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_read_ahead returns zero.
	SSL_get_read_ahead :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_read_ahead returns one.
	SSL_set_read_ahead :: proc(ssl: ^SSL, yes: i32) -> i32 ---

	// SSL_set_state does nothing.
	SSL_set_state :: proc(ssl: ^SSL, state: i32) ---

	// SSL_get_shared_ciphers writes an empty string to |buf| and returns a
	// pointer to |buf|, or NULL if |len| is less than or equal to zero.
	SSL_get_shared_ciphers :: proc(ssl: ^SSL, buf: cstring, len: i32) -> cstring ---

	// SSL_get_shared_sigalgs returns zero.
	SSL_get_shared_sigalgs :: proc(ssl: ^SSL, idx: i32, psign: ^i32, phash: ^i32, psignandhash: ^i32, rsig: ^u8, rhash: ^u8) -> i32 ---
}

// SSL_MODE_HANDSHAKE_CUTTHROUGH is the same as SSL_MODE_ENABLE_FALSE_START.
SSL_MODE_HANDSHAKE_CUTTHROUGH :: SSL_MODE_ENABLE_FALSE_START

@(default_calling_convention="c")
foreign lib {
	// i2d_SSL_SESSION serializes |in|, as described in |i2d_SAMPLE|.
	//
	// Use |SSL_SESSION_to_bytes| instead.
	i2d_SSL_SESSION :: proc(_in: ^SSL_SESSION, pp: ^^u8) -> i32 ---

	// d2i_SSL_SESSION parses a serialized session from the |len| bytes pointed to
	// by |*inp|, as described in |d2i_SAMPLE|.
	//
	// Use |SSL_SESSION_from_bytes| instead.
	d2i_SSL_SESSION :: proc(out: ^^SSL_SESSION, inp: ^^u8, len: c.long) -> ^SSL_SESSION ---

	// i2d_SSL_SESSION_bio serializes |session| and writes the result to |bio|. It
	// returns the number of bytes written on success and <= 0 on error.
	i2d_SSL_SESSION_bio :: proc(bio: ^BIO, session: ^SSL_SESSION) -> i32 ---

	// d2i_SSL_SESSION_bio reads a serialized |SSL_SESSION| from |bio| and returns a
	// newly-allocated |SSL_SESSION| or NULL on error. If |out| is not NULL, it also
	// frees |*out| and sets |*out| to the new |SSL_SESSION|.
	d2i_SSL_SESSION_bio :: proc(bio: ^BIO, out: ^^SSL_SESSION) -> ^SSL_SESSION ---

	// ERR_load_SSL_strings does nothing.
	ERR_load_SSL_strings :: proc() ---

	// SSL_load_error_strings does nothing.
	SSL_load_error_strings :: proc() ---

	// SSL_CTX_set_tlsext_use_srtp calls |SSL_CTX_set_srtp_profiles|. It returns
	// zero on success and one on failure.
	//
	// WARNING: this function is dangerous because it breaks the usual return value
	// convention. Use |SSL_CTX_set_srtp_profiles| instead.
	SSL_CTX_set_tlsext_use_srtp :: proc(ctx: ^SSL_CTX, profiles: cstring) -> i32 ---

	// SSL_set_tlsext_use_srtp calls |SSL_set_srtp_profiles|. It returns zero on
	// success and one on failure.
	//
	// WARNING: this function is dangerous because it breaks the usual return value
	// convention. Use |SSL_set_srtp_profiles| instead.
	SSL_set_tlsext_use_srtp :: proc(ssl: ^SSL, profiles: cstring) -> i32 ---

	// SSL_get_current_compression returns NULL.
	SSL_get_current_compression :: proc(ssl: ^SSL) -> ^COMP_METHOD ---

	// SSL_get_current_expansion returns NULL.
	SSL_get_current_expansion :: proc(ssl: ^SSL) -> ^COMP_METHOD ---

	// SSL_get_server_tmp_key returns zero.
	SSL_get_server_tmp_key :: proc(ssl: ^SSL, out_key: ^^EVP_PKEY) -> i32 ---

	// SSL_CTX_set_tmp_dh_callback does nothing.
	SSL_CTX_set_tmp_dh_callback :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, is_export: i32, keylength: i32) -> ^DH) ---

	// SSL_set_tmp_dh_callback does nothing.
	SSL_set_tmp_dh_callback :: proc(ssl: ^SSL, cb: proc "c" (ssl: ^SSL, is_export: i32, keylength: i32) -> ^DH) ---

	// SSL_CTX_set1_sigalgs takes |num_values| ints and interprets them as pairs
	// where the first is the nid of a hash function and the second is an
	// |EVP_PKEY_*| value. It configures the signature algorithm preferences for
	// |ctx| based on them and returns one on success or zero on error.
	//
	// This API is compatible with OpenSSL. However, BoringSSL-specific code should
	// prefer |SSL_CTX_set_signing_algorithm_prefs| because it's clearer and it's
	// more convenient to codesearch for specific algorithm values.
	SSL_CTX_set1_sigalgs :: proc(ctx: ^SSL_CTX, values: ^i32, num_values: c.size_t) -> i32 ---

	// SSL_set1_sigalgs takes |num_values| ints and interprets them as pairs where
	// the first is the nid of a hash function and the second is an |EVP_PKEY_*|
	// value. It configures the signature algorithm preferences for |ssl| based on
	// them and returns one on success or zero on error.
	//
	// This API is compatible with OpenSSL. However, BoringSSL-specific code should
	// prefer |SSL_CTX_set_signing_algorithm_prefs| because it's clearer and it's
	// more convenient to codesearch for specific algorithm values.
	SSL_set1_sigalgs :: proc(ssl: ^SSL, values: ^i32, num_values: c.size_t) -> i32 ---

	// SSL_CTX_set1_sigalgs_list takes a textual specification of a set of signature
	// algorithms and configures them on |ctx|. It returns one on success and zero
	// on error. See
	// https://www.openssl.org/docs/man1.1.0/man3/SSL_CTX_set1_sigalgs_list.html for
	// a description of the text format. Also note that TLS 1.3 names (e.g.
	// "rsa_pkcs1_md5_sha1") can also be used (as in OpenSSL, although OpenSSL
	// doesn't document that).
	//
	// This API is compatible with OpenSSL. However, BoringSSL-specific code should
	// prefer |SSL_CTX_set_signing_algorithm_prefs| because it's clearer and it's
	// more convenient to codesearch for specific algorithm values.
	SSL_CTX_set1_sigalgs_list :: proc(ctx: ^SSL_CTX, str: cstring) -> i32 ---

	// SSL_set1_sigalgs_list takes a textual specification of a set of signature
	// algorithms and configures them on |ssl|. It returns one on success and zero
	// on error. See
	// https://www.openssl.org/docs/man1.1.0/man3/SSL_CTX_set1_sigalgs_list.html for
	// a description of the text format. Also note that TLS 1.3 names (e.g.
	// "rsa_pkcs1_md5_sha1") can also be used (as in OpenSSL, although OpenSSL
	// doesn't document that).
	//
	// This API is compatible with OpenSSL. However, BoringSSL-specific code should
	// prefer |SSL_CTX_set_signing_algorithm_prefs| because it's clearer and it's
	// more convenient to codesearch for specific algorithm values.
	SSL_set1_sigalgs_list :: proc(ssl: ^SSL, str: cstring) -> i32 ---
}

ssl_comp_st :: struct {
	id:     i32,
	name:   cstring,
	method: cstring,
}

sk_SSL_COMP_free_func      :: proc "c" (^SSL_COMP)
sk_SSL_COMP_copy_func      :: proc "c" (^SSL_COMP) -> ^SSL_COMP
sk_SSL_COMP_cmp_func       :: proc "c" (^^SSL_COMP, ^^SSL_COMP) -> i32
sk_SSL_COMP_delete_if_func :: proc "c" (^SSL_COMP, rawptr) -> i32

// The following flags do nothing and are included only to make it easier to
// compile code with BoringSSL.
SSL_MODE_AUTO_RETRY                           :: 0
SSL_MODE_RELEASE_BUFFERS                      :: 0
SSL_MODE_SEND_CLIENTHELLO_TIME                :: 0
SSL_MODE_SEND_SERVERHELLO_TIME                :: 0
SSL_OP_ALL                                    :: 0
SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION      :: 0
SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS            :: 0
SSL_OP_EPHEMERAL_RSA                          :: 0
SSL_OP_LEGACY_SERVER_CONNECT                  :: 0
SSL_OP_MICROSOFT_BIG_SSLV3_BUFFER             :: 0
SSL_OP_MICROSOFT_SESS_ID_BUG                  :: 0
SSL_OP_MSIE_SSLV2_RSA_PADDING                 :: 0
SSL_OP_NETSCAPE_CA_DN_BUG                     :: 0
SSL_OP_NETSCAPE_CHALLENGE_BUG                 :: 0
SSL_OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG        :: 0
SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG       :: 0
SSL_OP_NO_COMPRESSION                         :: 0
SSL_OP_NO_RENEGOTIATION                       :: 0  // ssl_renegotiate_never is the default
SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION :: 0
SSL_OP_NO_SSLv2                               :: 0
SSL_OP_NO_SSLv3                               :: 0
SSL_OP_PKCS1_CHECK_1                          :: 0
SSL_OP_PKCS1_CHECK_2                          :: 0
SSL_OP_SINGLE_DH_USE                          :: 0
SSL_OP_SINGLE_ECDH_USE                        :: 0
SSL_OP_SSLEAY_080_CLIENT_DH_BUG               :: 0
SSL_OP_SSLREF2_REUSE_CERT_TYPE_BUG            :: 0
SSL_OP_TLS_BLOCK_PADDING_BUG                  :: 0
SSL_OP_TLS_D5_BUG                             :: 0
SSL_OP_TLS_ROLLBACK_BUG                       :: 0
SSL_VERIFY_CLIENT_ONCE                        :: 0

@(default_calling_convention="c")
foreign lib {
	// SSL_cache_hit calls |SSL_session_reused|.
	SSL_cache_hit :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_default_timeout returns |SSL_DEFAULT_SESSION_TIMEOUT|.
	SSL_get_default_timeout :: proc(ssl: ^SSL) -> c.long ---

	// SSL_get_version returns a string describing the TLS version used by |ssl|.
	// For example, "TLSv1.2" or "DTLSv1".
	SSL_get_version :: proc(ssl: ^SSL) -> cstring ---

	// SSL_get_all_version_names outputs a list of possible strings
	// |SSL_get_version| may return in this version of BoringSSL. It writes at most
	// |max_out| entries to |out| and returns the total number it would have
	// written, if |max_out| had been large enough. |max_out| may be initially set
	// to zero to size the output.
	//
	// This function is only intended to help initialize tables in callers that want
	// possible strings pre-declared. This list would not be suitable to set a list
	// of supported features. It is in no particular order, and may contain
	// placeholder, experimental, or deprecated values that do not apply to every
	// caller. Future versions of BoringSSL may also return strings not in this
	// list, so this does not apply if, say, sending strings across services.
	SSL_get_all_version_names :: proc(out: ^cstring, max_out: c.size_t) -> c.size_t ---

	// SSL_get_cipher_list returns the name of the |n|th cipher in the output of
	// |SSL_get_ciphers| or NULL if out of range. Use |SSL_get_ciphers| instead.
	SSL_get_cipher_list :: proc(ssl: ^SSL, n: i32) -> cstring ---

	// SSL_CTX_set_client_cert_cb sets a callback which is called on the client if
	// the server requests a client certificate and none is configured. On success,
	// the callback should return one and set |*out_x509| to |*out_pkey| to a leaf
	// certificate and private key, respectively, passing ownership. It should
	// return zero to send no certificate and -1 to fail or pause the handshake. If
	// the handshake is paused, |SSL_get_error| will return
	// |SSL_ERROR_WANT_X509_LOOKUP|.
	//
	// The callback may call |SSL_get0_certificate_types| and
	// |SSL_get_client_CA_list| for information on the server's certificate request.
	//
	// Use |SSL_CTX_set_cert_cb| instead. Configuring intermediate certificates with
	// this function is confusing. This callback may not be registered concurrently
	// with |SSL_CTX_set_cert_cb| or |SSL_set_cert_cb|.
	SSL_CTX_set_client_cert_cb :: proc(ctx: ^SSL_CTX, cb: proc "c" (ssl: ^SSL, out_x509: ^^X509, out_pkey: ^^EVP_PKEY) -> i32) ---
}

SSL_NOTHING :: SSL_ERROR_NONE
SSL_WRITING :: SSL_ERROR_WANT_WRITE
SSL_READING :: SSL_ERROR_WANT_READ

@(default_calling_convention="c")
foreign lib {
	// SSL_want returns one of the above values to determine what the most recent
	// operation on |ssl| was blocked on. Use |SSL_get_error| instead.
	SSL_want :: proc(ssl: ^SSL) -> i32 ---

	// SSL_get_finished writes up to |count| bytes of the Finished message sent by
	// |ssl| to |buf|. It returns the total untruncated length or zero if none has
	// been sent yet. At TLS 1.3 and later, it returns zero.
	//
	// Use |SSL_get_tls_unique| instead.
	SSL_get_finished :: proc(ssl: ^SSL, buf: rawptr, count: c.size_t) -> c.size_t ---

	// SSL_get_peer_finished writes up to |count| bytes of the Finished message
	// received from |ssl|'s peer to |buf|. It returns the total untruncated length
	// or zero if none has been received yet. At TLS 1.3 and later, it returns
	// zero.
	//
	// Use |SSL_get_tls_unique| instead.
	SSL_get_peer_finished :: proc(ssl: ^SSL, buf: rawptr, count: c.size_t) -> c.size_t ---

	// SSL_alert_type_string returns "!". Use |SSL_alert_type_string_long|
	// instead.
	SSL_alert_type_string :: proc(value: i32) -> cstring ---

	// SSL_alert_desc_string returns "!!". Use |SSL_alert_desc_string_long|
	// instead.
	SSL_alert_desc_string :: proc(value: i32) -> cstring ---

	// SSL_state_string returns "!!!!!!". Use |SSL_state_string_long| for a more
	// intelligible string.
	SSL_state_string :: proc(ssl: ^SSL) -> cstring ---
}

// SSL_TXT_* expand to strings.
SSL_TXT_MEDIUM   :: "MEDIUM"
SSL_TXT_HIGH     :: "HIGH"
SSL_TXT_FIPS     :: "FIPS"
SSL_TXT_kRSA     :: "kRSA"
SSL_TXT_kDHE     :: "kDHE"
SSL_TXT_kEDH     :: "kEDH"
SSL_TXT_kECDHE   :: "kECDHE"
SSL_TXT_kEECDH   :: "kEECDH"
SSL_TXT_kPSK     :: "kPSK"
SSL_TXT_aRSA     :: "aRSA"
SSL_TXT_aECDSA   :: "aECDSA"
SSL_TXT_aPSK     :: "aPSK"
SSL_TXT_DH       :: "DH"
SSL_TXT_DHE      :: "DHE"
SSL_TXT_EDH      :: "EDH"
SSL_TXT_RSA      :: "RSA"
SSL_TXT_ECDH     :: "ECDH"
SSL_TXT_ECDHE    :: "ECDHE"
SSL_TXT_EECDH    :: "EECDH"
SSL_TXT_ECDSA    :: "ECDSA"
SSL_TXT_PSK      :: "PSK"
SSL_TXT_3DES     :: "3DES"
SSL_TXT_RC4      :: "RC4"
SSL_TXT_AES128   :: "AES128"
SSL_TXT_AES256   :: "AES256"
SSL_TXT_AES      :: "AES"
SSL_TXT_AES_GCM  :: "AESGCM"
SSL_TXT_CHACHA20 :: "CHACHA20"
SSL_TXT_MD5      :: "MD5"
SSL_TXT_SHA1     :: "SHA1"
SSL_TXT_SHA      :: "SHA"
SSL_TXT_SHA256   :: "SHA256"
SSL_TXT_SHA384   :: "SHA384"
SSL_TXT_SSLV3    :: "SSLv3"
SSL_TXT_TLSV1    :: "TLSv1"
SSL_TXT_TLSV1_1  :: "TLSv1.1"
SSL_TXT_TLSV1_2  :: "TLSv1.2"
SSL_TXT_TLSV1_3  :: "TLSv1.3"
SSL_TXT_ALL      :: "ALL"
SSL_TXT_CMPDEF   :: "COMPLEMENTOFDEFAULT"

ssl_conf_ctx_st :: struct {}
SSL_CONF_CTX    :: ssl_conf_ctx_st

@(default_calling_convention="c")
foreign lib {
	// SSL_state returns |SSL_ST_INIT| if a handshake is in progress and |SSL_ST_OK|
	// otherwise.
	//
	// Use |SSL_is_init| instead.
	SSL_state :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_shutdown causes |ssl| to behave as if the shutdown bitmask (see
	// |SSL_get_shutdown|) were |mode|. This may be used to skip sending or
	// receiving close_notify in |SSL_shutdown| by causing the implementation to
	// believe the events already happened.
	//
	// It is an error to use |SSL_set_shutdown| to unset a bit that has already been
	// set. Doing so will trigger an |assert| in debug builds and otherwise be
	// ignored.
	//
	// Use |SSL_CTX_set_quiet_shutdown| instead.
	SSL_set_shutdown :: proc(ssl: ^SSL, mode: i32) ---

	// SSL_add_dir_cert_subjects_to_stack lists files in directory |dir|. It calls
	// |SSL_add_file_cert_subjects_to_stack| on each file and returns one on success
	// or zero on error. This function is only available from the libdecrepit
	// library.
	SSL_add_dir_cert_subjects_to_stack :: proc(out: ^stack_st_X509_NAME, dir: cstring) -> i32 ---

	// SSL_CTX_enable_tls_channel_id calls |SSL_CTX_set_tls_channel_id_enabled|.
	SSL_CTX_enable_tls_channel_id :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_enable_tls_channel_id calls |SSL_set_tls_channel_id_enabled|.
	SSL_enable_tls_channel_id :: proc(ssl: ^SSL) -> i32 ---

	// BIO_f_ssl returns a |BIO_METHOD| that can wrap an |SSL*| in a |BIO*|. Note
	// that this has quite different behaviour from the version in OpenSSL (notably
	// that it doesn't try to auto renegotiate).
	//
	// IMPORTANT: if you are not curl, don't use this.
	BIO_f_ssl :: proc() -> ^BIO_METHOD ---

	// BIO_set_ssl sets |ssl| as the underlying connection for |bio|, which must
	// have been created using |BIO_f_ssl|. If |take_owership| is true, |bio| will
	// call |SSL_free| on |ssl| when closed. It returns one on success or something
	// other than one on error.
	BIO_set_ssl :: proc(bio: ^BIO, ssl: ^SSL, take_owership: i32) -> c.long ---

	// SSL_get_session returns a non-owning pointer to |ssl|'s session. For
	// historical reasons, which session it returns depends on |ssl|'s state.
	//
	// Prior to the start of the initial handshake, it returns the session the
	// caller set with |SSL_set_session|. After the initial handshake has finished
	// and if no additional handshakes are in progress, it returns the currently
	// active session. Its behavior is undefined while a handshake is in progress.
	//
	// If trying to add new sessions to an external session cache, use
	// |SSL_CTX_sess_set_new_cb| instead. In particular, using the callback is
	// required as of TLS 1.3. For compatibility, this function will return an
	// unresumable session which may be cached, but will never be resumed.
	//
	// If querying properties of the connection, use APIs on the |SSL| object.
	SSL_get_session :: proc(ssl: ^SSL) -> ^SSL_SESSION ---
}

// SSL_get0_session is an alias for |SSL_get_session|.
SSL_get0_session :: SSL_get_session

@(default_calling_convention="c")
foreign lib {
	// SSL_get1_session acts like |SSL_get_session| but returns a new reference to
	// the session.
	SSL_get1_session :: proc(ssl: ^SSL) -> ^SSL_SESSION ---
}

OPENSSL_INIT_NO_LOAD_SSL_STRINGS :: 0
OPENSSL_INIT_LOAD_SSL_STRINGS    :: 0
OPENSSL_INIT_SSL_DEFAULT         :: 0

@(default_calling_convention="c")
foreign lib {
	// OPENSSL_init_ssl returns one.
	OPENSSL_init_ssl :: proc(opts: u64, settings: ^OPENSSL_INIT_SETTINGS) -> i32 ---
}

// The following constants are legacy aliases for RSA-PSS with rsaEncryption
// keys. Use the new names instead.
SSL_SIGN_RSA_PSS_SHA256 :: SSL_SIGN_RSA_PSS_RSAE_SHA256
SSL_SIGN_RSA_PSS_SHA384 :: SSL_SIGN_RSA_PSS_RSAE_SHA384
SSL_SIGN_RSA_PSS_SHA512 :: SSL_SIGN_RSA_PSS_RSAE_SHA512

@(default_calling_convention="c")
foreign lib {
	// SSL_set_tlsext_status_type configures a client to request OCSP stapling if
	// |type| is |TLSEXT_STATUSTYPE_ocsp| and disables it otherwise. It returns one
	// on success and zero if handshake configuration has already been shed.
	//
	// Use |SSL_enable_ocsp_stapling| instead.
	SSL_set_tlsext_status_type :: proc(ssl: ^SSL, type: i32) -> i32 ---

	// SSL_get_tlsext_status_type returns |TLSEXT_STATUSTYPE_ocsp| if the client
	// requested OCSP stapling and |TLSEXT_STATUSTYPE_nothing| otherwise. On the
	// client, this reflects whether OCSP stapling was enabled via, e.g.,
	// |SSL_set_tlsext_status_type|. On the server, this is determined during the
	// handshake. It may be queried in callbacks set by |SSL_CTX_set_cert_cb|. The
	// result is undefined after the handshake completes.
	SSL_get_tlsext_status_type :: proc(ssl: ^SSL) -> i32 ---

	// SSL_set_tlsext_status_ocsp_resp sets the OCSP response. It returns one on
	// success and zero on error. On success, |ssl| takes ownership of |resp|, which
	// must have been allocated by |OPENSSL_malloc|.
	//
	// Use |SSL_set_ocsp_response| instead.
	SSL_set_tlsext_status_ocsp_resp :: proc(ssl: ^SSL, resp: ^u8, resp_len: c.size_t) -> i32 ---

	// SSL_get_tlsext_status_ocsp_resp sets |*out| to point to the OCSP response
	// from the server. It returns the length of the response. If there was no
	// response, it sets |*out| to NULL and returns zero.
	//
	// Use |SSL_get0_ocsp_response| instead.
	//
	// WARNING: the returned data is not guaranteed to be well formed.
	SSL_get_tlsext_status_ocsp_resp :: proc(ssl: ^SSL, out: ^^u8) -> c.size_t ---

	// SSL_CTX_set_tlsext_status_cb configures the legacy OpenSSL OCSP callback and
	// returns one. Though the type signature is the same, this callback has
	// different behavior for client and server connections:
	//
	// For clients, the callback is called after certificate verification. It should
	// return one for success, zero for a bad OCSP response, and a negative number
	// for internal error. Instead, handle this as part of certificate verification.
	// (Historically, OpenSSL verified certificates just before parsing stapled OCSP
	// responses, but BoringSSL fixes this ordering. All server credentials are
	// available during verification.)
	//
	// Do not use this callback as a server. It is provided for compatibility
	// purposes only. For servers, it is called to configure server credentials. It
	// should return |SSL_TLSEXT_ERR_OK| on success, |SSL_TLSEXT_ERR_NOACK| to
	// ignore OCSP requests, or |SSL_TLSEXT_ERR_ALERT_FATAL| on error. It is usually
	// used to fetch OCSP responses on demand, which is not ideal. Instead, treat
	// OCSP responses like other server credentials, such as certificates or SCT
	// lists. Configure, store, and refresh them eagerly. This avoids downtime if
	// the CA's OCSP responder is briefly offline.
	SSL_CTX_set_tlsext_status_cb :: proc(ctx: ^SSL_CTX, callback: proc "c" (ssl: ^SSL, arg: rawptr) -> i32) -> i32 ---

	// SSL_CTX_set_tlsext_status_arg sets additional data for
	// |SSL_CTX_set_tlsext_status_cb|'s callback and returns one.
	SSL_CTX_set_tlsext_status_arg :: proc(ctx: ^SSL_CTX, arg: rawptr) -> i32 ---
}

// The following symbols are compatibility aliases for reason codes used when
// receiving an alert from the peer. Use the other names instead, which fit the
// naming convention.
//
// TODO(davidben): Fix references to |SSL_R_TLSV1_CERTIFICATE_REQUIRED| and
// remove the compatibility value. The others come from OpenSSL.
SSL_R_TLSV1_UNSUPPORTED_EXTENSION           :: 1110
SSL_R_TLSV1_CERTIFICATE_UNOBTAINABLE        :: 1111
SSL_R_TLSV1_UNRECOGNIZED_NAME               :: 1112
SSL_R_TLSV1_BAD_CERTIFICATE_STATUS_RESPONSE :: 1113
SSL_R_TLSV1_BAD_CERTIFICATE_HASH_VALUE      :: 1114
SSL_R_TLSV1_CERTIFICATE_REQUIRED            :: 1116

// The following symbols are compatibility aliases for |SSL_GROUP_*|.
SSL_CURVE_SECP256R1               :: SSL_GROUP_SECP256R1
SSL_CURVE_SECP384R1               :: SSL_GROUP_SECP384R1
SSL_CURVE_SECP521R1               :: SSL_GROUP_SECP521R1
SSL_CURVE_X25519                  :: SSL_GROUP_X25519
SSL_CURVE_X25519_KYBER768_DRAFT00 :: SSL_GROUP_X25519_KYBER768_DRAFT00

@(default_calling_convention="c")
foreign lib {
	// SSL_get_curve_id calls |SSL_get_group_id|.
	SSL_get_curve_id :: proc(ssl: ^SSL) -> u16 ---

	// SSL_get_curve_name calls |SSL_get_group_name|.
	SSL_get_curve_name :: proc(curve_id: u16) -> cstring ---

	// SSL_get_all_curve_names calls |SSL_get_all_group_names|.
	SSL_get_all_curve_names :: proc(out: ^cstring, max_out: c.size_t) -> c.size_t ---

	// SSL_CTX_set1_curves_list calls |SSL_CTX_set1_groups_list|.
	SSL_CTX_set1_curves_list :: proc(ctx: ^SSL_CTX, curves: cstring) -> i32 ---

	// SSL_set1_curves_list calls |SSL_set1_groups_list|.
	SSL_set1_curves_list :: proc(ssl: ^SSL, curves: cstring) -> i32 ---
}

// TLSEXT_nid_unknown is a constant used in OpenSSL for
// |SSL_get_negotiated_group| to return an unrecognized group. BoringSSL never
// returns this value, but we define this constant for compatibility.
TLSEXT_nid_unknown :: 0x1000000

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_check_private_key returns one if |ctx| has both a certificate and
	// private key, and zero otherwise.
	//
	// This function does not check consistency because the library checks when the
	// certificate and key are individually configured. However, if the private key
	// is configured before the certificate, inconsistent private keys are silently
	// dropped. Some callers are inadvertently relying on this function to detect
	// when this happens.
	//
	// Instead, callers should configure the certificate first, then the private
	// key, checking for errors in each. This function is then unnecessary.
	SSL_CTX_check_private_key :: proc(ctx: ^SSL_CTX) -> i32 ---

	// SSL_check_private_key returns one if |ssl| has both a certificate and private
	// key, and zero otherwise.
	//
	// See discussion in |SSL_CTX_check_private_key|.
	SSL_check_private_key :: proc(ssl: ^SSL) -> i32 ---

	// SSL_CTX_get_security_level returns zero.
	//
	// This function is not meaningful in BoringSSL. OpenSSL has an arbitrary
	// mapping from algorithms to "security levels" and offers an API to filter TLS
	// configuration by those levels. In OpenSSL, this function does not return how
	// secure |ctx| is, just what security level the caller previously configured.
	// As BoringSSL does not implement this API, we return zero to report that the
	// security levels mechanism is not used.
	SSL_CTX_get_security_level :: proc(ctx: ^SSL_CTX) -> i32 ---
}

// Compliance policy configurations
//
// A TLS connection has a large number of different parameters. Some are well
// known, like cipher suites, but many are obscure and configuration functions
// for them may not exist. These policy controls allow broad configuration
// goals to be specified so that they can flow down to all the different
// parameters of a TLS connection.
ssl_compliance_policy_t :: enum u32 {
	// ssl_compliance_policy_none does nothing. However, since setting this
	// doesn't undo other policies it's an error to try and set it.
	none            = 0,

	// ssl_compliance_policy_fips_202205 configures a TLS connection to use:
	//   * TLS 1.2 or 1.3
	//   * For TLS 1.2, only ECDHE_[RSA|ECDSA]_WITH_AES_*_GCM_SHA*.
	//   * For TLS 1.3, only AES-GCM
	//   * P-256 or P-384 for key agreement.
	//   * For server signatures, only PKCS#1/PSS with SHA256/384/512, or ECDSA
	//     with P-256 or P-384 and SHA256/SHA384.
	//
	// Note: this policy can be configured even if BoringSSL has not been built in
	// FIPS mode. Call |FIPS_mode| to check that.
	//
	// Note: this setting aids with compliance with NIST requirements but does not
	// guarantee it. Careful reading of SP 800-52r2 is recommended.
	fips_202205     = 1,

	// ssl_compliance_policy_wpa3_192_202304 configures a TLS connection to use:
	//   * TLS 1.2 or 1.3.
	//   * For TLS 1.2, only TLS_ECDHE_[ECDSA|RSA]_WITH_AES_256_GCM_SHA384.
	//   * For TLS 1.3, only AES-256-GCM.
	//   * P-384 for key agreement.
	//   * For handshake signatures, only ECDSA with P-384 and SHA-384, or RSA
	//     with SHA-384 or SHA-512.
	//
	// No limitations on the certificate chain nor leaf public key are imposed,
	// other than by the supported signature algorithms. But WPA3's "192-bit"
	// mode requires at least P-384 or 3072-bit along the chain. The caller must
	// enforce this themselves on the verified chain using functions such as
	// |X509_STORE_CTX_get0_chain|.
	//
	// Note that this setting is less secure than the default. The
	// implementation risks of using a more obscure primitive like P-384
	// dominate other considerations.
	wpa3_192_202304 = 2,

	// ssl_compliance_policy_cnsa_202407 configures a TLS connection to use:
	//   * For TLS 1.3, AES-256-GCM over AES-128-GCM over ChaCha20-Poly1305.
	//
	// I.e. it ensures that AES-GCM will be used whenever the client supports it.
	// The cipher suite configuration mini-language can be used to similarly
	// configure prior TLS versions if they are enabled.
	cnsa_202407     = 3,
}

@(default_calling_convention="c")
foreign lib {
	// SSL_CTX_set_compliance_policy configures various aspects of |ctx| based on
	// the given policy requirements. Subsequently calling other functions that
	// configure |ctx| may override |policy|, or may not. This should be the final
	// configuration function called in order to have defined behaviour. It's a
	// fatal error if |policy| is |ssl_compliance_policy_none|.
	SSL_CTX_set_compliance_policy :: proc(ctx: ^SSL_CTX, policy: ssl_compliance_policy_t) -> i32 ---

	// SSL_CTX_get_compliance_policy returns the compliance policy configured on
	// |ctx|.
	SSL_CTX_get_compliance_policy :: proc(ctx: ^SSL_CTX) -> ssl_compliance_policy_t ---

	// SSL_set_compliance_policy acts the same as |SSL_CTX_set_compliance_policy|,
	// but only configures a single |SSL*|.
	SSL_set_compliance_policy :: proc(ssl: ^SSL, policy: ssl_compliance_policy_t) -> i32 ---

	// SSL_get_compliance_policy returns the compliance policy configured on
	// |ssl|.
	SSL_get_compliance_policy :: proc(ssl: ^SSL) -> ssl_compliance_policy_t ---
}

SSL_R_APP_DATA_IN_HANDSHAKE                          :: 100
SSL_R_ATTEMPT_TO_REUSE_SESSION_IN_DIFFERENT_CONTEXT  :: 101
SSL_R_BAD_ALERT                                      :: 102
SSL_R_BAD_CHANGE_CIPHER_SPEC                         :: 103
SSL_R_BAD_DATA_RETURNED_BY_CALLBACK                  :: 104
SSL_R_BAD_DH_P_LENGTH                                :: 105
SSL_R_BAD_DIGEST_LENGTH                              :: 106
SSL_R_BAD_ECC_CERT                                   :: 107
SSL_R_BAD_ECPOINT                                    :: 108
SSL_R_BAD_HANDSHAKE_RECORD                           :: 109
SSL_R_BAD_HELLO_REQUEST                              :: 110
SSL_R_BAD_LENGTH                                     :: 111
SSL_R_BAD_PACKET_LENGTH                              :: 112
SSL_R_BAD_RSA_ENCRYPT                                :: 113
SSL_R_BAD_SIGNATURE                                  :: 114
SSL_R_BAD_SRTP_MKI_VALUE                             :: 115
SSL_R_BAD_SRTP_PROTECTION_PROFILE_LIST               :: 116
SSL_R_BAD_SSL_FILETYPE                               :: 117
SSL_R_BAD_WRITE_RETRY                                :: 118
SSL_R_BIO_NOT_SET                                    :: 119
SSL_R_BN_LIB                                         :: 120
SSL_R_BUFFER_TOO_SMALL                               :: 121
SSL_R_CA_DN_LENGTH_MISMATCH                          :: 122
SSL_R_CA_DN_TOO_LONG                                 :: 123
SSL_R_CCS_RECEIVED_EARLY                             :: 124
SSL_R_CERTIFICATE_VERIFY_FAILED                      :: 125
SSL_R_CERT_CB_ERROR                                  :: 126
SSL_R_CERT_LENGTH_MISMATCH                           :: 127
SSL_R_CHANNEL_ID_NOT_P256                            :: 128
SSL_R_CHANNEL_ID_SIGNATURE_INVALID                   :: 129
SSL_R_CIPHER_OR_HASH_UNAVAILABLE                     :: 130
SSL_R_CLIENTHELLO_PARSE_FAILED                       :: 131
SSL_R_CLIENTHELLO_TLSEXT                             :: 132
SSL_R_CONNECTION_REJECTED                            :: 133
SSL_R_CONNECTION_TYPE_NOT_SET                        :: 134
SSL_R_CUSTOM_EXTENSION_ERROR                         :: 135
SSL_R_DATA_LENGTH_TOO_LONG                           :: 136
SSL_R_DECODE_ERROR                                   :: 137
SSL_R_DECRYPTION_FAILED                              :: 138
SSL_R_DECRYPTION_FAILED_OR_BAD_RECORD_MAC            :: 139
SSL_R_DH_PUBLIC_VALUE_LENGTH_IS_WRONG                :: 140
SSL_R_DH_P_TOO_LONG                                  :: 141
SSL_R_DIGEST_CHECK_FAILED                            :: 142
SSL_R_DTLS_MESSAGE_TOO_BIG                           :: 143
SSL_R_ECC_CERT_NOT_FOR_SIGNING                       :: 144
SSL_R_EMS_STATE_INCONSISTENT                         :: 145
SSL_R_ENCRYPTED_LENGTH_TOO_LONG                      :: 146
SSL_R_ERROR_ADDING_EXTENSION                         :: 147
SSL_R_ERROR_IN_RECEIVED_CIPHER_LIST                  :: 148
SSL_R_ERROR_PARSING_EXTENSION                        :: 149
SSL_R_EXCESSIVE_MESSAGE_SIZE                         :: 150
SSL_R_EXTRA_DATA_IN_MESSAGE                          :: 151
SSL_R_FRAGMENT_MISMATCH                              :: 152
SSL_R_GOT_NEXT_PROTO_WITHOUT_EXTENSION               :: 153
SSL_R_HANDSHAKE_FAILURE_ON_CLIENT_HELLO              :: 154
SSL_R_HTTPS_PROXY_REQUEST                            :: 155
SSL_R_HTTP_REQUEST                                   :: 156
SSL_R_INAPPROPRIATE_FALLBACK                         :: 157
SSL_R_INVALID_COMMAND                                :: 158
SSL_R_INVALID_MESSAGE                                :: 159
SSL_R_INVALID_SSL_SESSION                            :: 160
SSL_R_INVALID_TICKET_KEYS_LENGTH                     :: 161
SSL_R_LENGTH_MISMATCH                                :: 162
SSL_R_MISSING_EXTENSION                              :: 164
SSL_R_MISSING_RSA_CERTIFICATE                        :: 165
SSL_R_MISSING_TMP_DH_KEY                             :: 166
SSL_R_MISSING_TMP_ECDH_KEY                           :: 167
SSL_R_MIXED_SPECIAL_OPERATOR_WITH_GROUPS             :: 168
SSL_R_MTU_TOO_SMALL                                  :: 169
SSL_R_NEGOTIATED_BOTH_NPN_AND_ALPN                   :: 170
SSL_R_NESTED_GROUP                                   :: 171
SSL_R_NO_CERTIFICATES_RETURNED                       :: 172
SSL_R_NO_CERTIFICATE_ASSIGNED                        :: 173
SSL_R_NO_CERTIFICATE_SET                             :: 174
SSL_R_NO_CIPHERS_AVAILABLE                           :: 175
SSL_R_NO_CIPHERS_PASSED                              :: 176
SSL_R_NO_CIPHER_MATCH                                :: 177
SSL_R_NO_COMPRESSION_SPECIFIED                       :: 178
SSL_R_NO_METHOD_SPECIFIED                            :: 179
SSL_R_NO_PRIVATE_KEY_ASSIGNED                        :: 181
SSL_R_NO_RENEGOTIATION                               :: 182
SSL_R_NO_REQUIRED_DIGEST                             :: 183
SSL_R_NO_SHARED_CIPHER                               :: 184
SSL_R_NULL_SSL_CTX                                   :: 185
SSL_R_NULL_SSL_METHOD_PASSED                         :: 186
SSL_R_OLD_SESSION_CIPHER_NOT_RETURNED                :: 187
SSL_R_OLD_SESSION_VERSION_NOT_RETURNED               :: 188
SSL_R_OUTPUT_ALIASES_INPUT                           :: 189
SSL_R_PARSE_TLSEXT                                   :: 190
SSL_R_PATH_TOO_LONG                                  :: 191
SSL_R_PEER_DID_NOT_RETURN_A_CERTIFICATE              :: 192
SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE        :: 193
SSL_R_PROTOCOL_IS_SHUTDOWN                           :: 194
SSL_R_PSK_IDENTITY_NOT_FOUND                         :: 195
SSL_R_PSK_NO_CLIENT_CB                               :: 196
SSL_R_PSK_NO_SERVER_CB                               :: 197
SSL_R_READ_TIMEOUT_EXPIRED                           :: 198
SSL_R_RECORD_LENGTH_MISMATCH                         :: 199
SSL_R_RECORD_TOO_LARGE                               :: 200
SSL_R_RENEGOTIATION_ENCODING_ERR                     :: 201
SSL_R_RENEGOTIATION_MISMATCH                         :: 202
SSL_R_REQUIRED_CIPHER_MISSING                        :: 203
SSL_R_RESUMED_EMS_SESSION_WITHOUT_EMS_EXTENSION      :: 204
SSL_R_RESUMED_NON_EMS_SESSION_WITH_EMS_EXTENSION     :: 205
SSL_R_SCSV_RECEIVED_WHEN_RENEGOTIATING               :: 206
SSL_R_SERVERHELLO_TLSEXT                             :: 207
SSL_R_SESSION_ID_CONTEXT_UNINITIALIZED               :: 208
SSL_R_SESSION_MAY_NOT_BE_CREATED                     :: 209
SSL_R_SIGNATURE_ALGORITHMS_EXTENSION_SENT_BY_SERVER  :: 210
SSL_R_SRTP_COULD_NOT_ALLOCATE_PROFILES               :: 211
SSL_R_SRTP_UNKNOWN_PROTECTION_PROFILE                :: 212
SSL_R_SSL3_EXT_INVALID_SERVERNAME                    :: 213
SSL_R_SSL_CTX_HAS_NO_DEFAULT_SSL_VERSION             :: 214
SSL_R_SSL_HANDSHAKE_FAILURE                          :: 215
SSL_R_SSL_SESSION_ID_CONTEXT_TOO_LONG                :: 216
SSL_R_TLS_PEER_DID_NOT_RESPOND_WITH_CERTIFICATE_LIST :: 217
SSL_R_TLS_RSA_ENCRYPTED_VALUE_LENGTH_IS_WRONG        :: 218
SSL_R_TOO_MANY_EMPTY_FRAGMENTS                       :: 219
SSL_R_TOO_MANY_WARNING_ALERTS                        :: 220
SSL_R_UNABLE_TO_FIND_ECDH_PARAMETERS                 :: 221
SSL_R_UNEXPECTED_EXTENSION                           :: 222
SSL_R_UNEXPECTED_MESSAGE                             :: 223
SSL_R_UNEXPECTED_OPERATOR_IN_GROUP                   :: 224
SSL_R_UNEXPECTED_RECORD                              :: 225
SSL_R_UNINITIALIZED                                  :: 226
SSL_R_UNKNOWN_ALERT_TYPE                             :: 227
SSL_R_UNKNOWN_CERTIFICATE_TYPE                       :: 228
SSL_R_UNKNOWN_CIPHER_RETURNED                        :: 229
SSL_R_UNKNOWN_CIPHER_TYPE                            :: 230
SSL_R_UNKNOWN_DIGEST                                 :: 231
SSL_R_UNKNOWN_KEY_EXCHANGE_TYPE                      :: 232
SSL_R_UNKNOWN_PROTOCOL                               :: 233
SSL_R_UNKNOWN_SSL_VERSION                            :: 234
SSL_R_UNKNOWN_STATE                                  :: 235
SSL_R_UNSAFE_LEGACY_RENEGOTIATION_DISABLED           :: 236
SSL_R_UNSUPPORTED_CIPHER                             :: 237
SSL_R_UNSUPPORTED_COMPRESSION_ALGORITHM              :: 238
SSL_R_UNSUPPORTED_ELLIPTIC_CURVE                     :: 239
SSL_R_UNSUPPORTED_PROTOCOL                           :: 240
SSL_R_WRONG_CERTIFICATE_TYPE                         :: 241
SSL_R_WRONG_CIPHER_RETURNED                          :: 242
SSL_R_WRONG_CURVE                                    :: 243
SSL_R_WRONG_MESSAGE_TYPE                             :: 244
SSL_R_WRONG_SIGNATURE_TYPE                           :: 245
SSL_R_WRONG_SSL_VERSION                              :: 246
SSL_R_WRONG_VERSION_NUMBER                           :: 247
SSL_R_X509_LIB                                       :: 248
SSL_R_X509_VERIFICATION_SETUP_PROBLEMS               :: 249
SSL_R_SHUTDOWN_WHILE_IN_INIT                         :: 250
SSL_R_INVALID_OUTER_RECORD_TYPE                      :: 251
SSL_R_UNSUPPORTED_PROTOCOL_FOR_CUSTOM_KEY            :: 252
SSL_R_NO_COMMON_SIGNATURE_ALGORITHMS                 :: 253
SSL_R_DOWNGRADE_DETECTED                             :: 254
SSL_R_EXCESS_HANDSHAKE_DATA                          :: 255
SSL_R_INVALID_COMPRESSION_LIST                       :: 256
SSL_R_DUPLICATE_EXTENSION                            :: 257
SSL_R_MISSING_KEY_SHARE                              :: 258
SSL_R_INVALID_ALPN_PROTOCOL                          :: 259
SSL_R_TOO_MANY_KEY_UPDATES                           :: 260
SSL_R_BLOCK_CIPHER_PAD_IS_WRONG                      :: 261
SSL_R_NO_CIPHERS_SPECIFIED                           :: 262
SSL_R_RENEGOTIATION_EMS_MISMATCH                     :: 263
SSL_R_DUPLICATE_KEY_SHARE                            :: 264
SSL_R_NO_GROUPS_SPECIFIED                            :: 265
SSL_R_NO_SHARED_GROUP                                :: 266
SSL_R_PRE_SHARED_KEY_MUST_BE_LAST                    :: 267
SSL_R_OLD_SESSION_PRF_HASH_MISMATCH                  :: 268
SSL_R_INVALID_SCT_LIST                               :: 269
SSL_R_TOO_MUCH_SKIPPED_EARLY_DATA                    :: 270
SSL_R_PSK_IDENTITY_BINDER_COUNT_MISMATCH             :: 271
SSL_R_CANNOT_PARSE_LEAF_CERT                         :: 272
SSL_R_SERVER_CERT_CHANGED                            :: 273
SSL_R_CERTIFICATE_AND_PRIVATE_KEY_MISMATCH           :: 274
SSL_R_CANNOT_HAVE_BOTH_PRIVKEY_AND_METHOD            :: 275
SSL_R_TICKET_ENCRYPTION_FAILED                       :: 276
SSL_R_ALPN_MISMATCH_ON_EARLY_DATA                    :: 277
SSL_R_WRONG_VERSION_ON_EARLY_DATA                    :: 278
SSL_R_UNEXPECTED_EXTENSION_ON_EARLY_DATA             :: 279
SSL_R_NO_SUPPORTED_VERSIONS_ENABLED                  :: 280
SSL_R_EMPTY_HELLO_RETRY_REQUEST                      :: 282
SSL_R_EARLY_DATA_NOT_IN_USE                          :: 283
SSL_R_HANDSHAKE_NOT_COMPLETE                         :: 284
SSL_R_NEGOTIATED_TB_WITHOUT_EMS_OR_RI                :: 285
SSL_R_SERVER_ECHOED_INVALID_SESSION_ID               :: 286
SSL_R_PRIVATE_KEY_OPERATION_FAILED                   :: 287
SSL_R_SECOND_SERVERHELLO_VERSION_MISMATCH            :: 288
SSL_R_OCSP_CB_ERROR                                  :: 289
SSL_R_SSL_SESSION_ID_TOO_LONG                        :: 290
SSL_R_APPLICATION_DATA_ON_SHUTDOWN                   :: 291
SSL_R_CERT_DECOMPRESSION_FAILED                      :: 292
SSL_R_UNCOMPRESSED_CERT_TOO_LARGE                    :: 293
SSL_R_UNKNOWN_CERT_COMPRESSION_ALG                   :: 294
SSL_R_INVALID_SIGNATURE_ALGORITHM                    :: 295
SSL_R_DUPLICATE_SIGNATURE_ALGORITHM                  :: 296
SSL_R_TLS13_DOWNGRADE                                :: 297
SSL_R_QUIC_INTERNAL_ERROR                            :: 298
SSL_R_WRONG_ENCRYPTION_LEVEL_RECEIVED                :: 299
SSL_R_TOO_MUCH_READ_EARLY_DATA                       :: 300
SSL_R_INVALID_DELEGATED_CREDENTIAL                   :: 301
SSL_R_KEY_USAGE_BIT_INCORRECT                        :: 302
SSL_R_INCONSISTENT_CLIENT_HELLO                      :: 303
SSL_R_CIPHER_MISMATCH_ON_EARLY_DATA                  :: 304
SSL_R_QUIC_TRANSPORT_PARAMETERS_MISCONFIGURED        :: 305
SSL_R_UNEXPECTED_COMPATIBILITY_MODE                  :: 306
SSL_R_NO_APPLICATION_PROTOCOL                        :: 307
SSL_R_NEGOTIATED_ALPS_WITHOUT_ALPN                   :: 308
SSL_R_ALPS_MISMATCH_ON_EARLY_DATA                    :: 309
SSL_R_ECH_SERVER_CONFIG_AND_PRIVATE_KEY_MISMATCH     :: 310
SSL_R_ECH_SERVER_CONFIG_UNSUPPORTED_EXTENSION        :: 311
SSL_R_UNSUPPORTED_ECH_SERVER_CONFIG                  :: 312
SSL_R_ECH_SERVER_WOULD_HAVE_NO_RETRY_CONFIGS         :: 313
SSL_R_INVALID_CLIENT_HELLO_INNER                     :: 314
SSL_R_INVALID_ALPN_PROTOCOL_LIST                     :: 315
SSL_R_COULD_NOT_PARSE_HINTS                          :: 316
SSL_R_INVALID_ECH_PUBLIC_NAME                        :: 317
SSL_R_INVALID_ECH_CONFIG_LIST                        :: 318
SSL_R_ECH_REJECTED                                   :: 319
SSL_R_INVALID_OUTER_EXTENSION                        :: 320
SSL_R_INCONSISTENT_ECH_NEGOTIATION                   :: 321
SSL_R_INVALID_ALPS_CODEPOINT                         :: 322
SSL_R_NO_MATCHING_ISSUER                             :: 323
SSL_R_INVALID_SPAKE2PLUSV1_VALUE                     :: 324
SSL_R_PAKE_EXHAUSTED                                 :: 325
SSL_R_PEER_PAKE_MISMATCH                             :: 326
SSL_R_UNSUPPORTED_CREDENTIAL_LIST                    :: 327
SSL_R_INVALID_TRUST_ANCHOR_LIST                      :: 328
SSL_R_INVALID_CERTIFICATE_PROPERTY_LIST              :: 329
SSL_R_DUPLICATE_GROUP                                :: 330
SSL_R_SSLV3_ALERT_CLOSE_NOTIFY                       :: 1000
SSL_R_SSLV3_ALERT_UNEXPECTED_MESSAGE                 :: 1010
SSL_R_SSLV3_ALERT_BAD_RECORD_MAC                     :: 1020
SSL_R_TLSV1_ALERT_DECRYPTION_FAILED                  :: 1021
SSL_R_TLSV1_ALERT_RECORD_OVERFLOW                    :: 1022
SSL_R_SSLV3_ALERT_DECOMPRESSION_FAILURE              :: 1030
SSL_R_SSLV3_ALERT_HANDSHAKE_FAILURE                  :: 1040
SSL_R_SSLV3_ALERT_NO_CERTIFICATE                     :: 1041
SSL_R_SSLV3_ALERT_BAD_CERTIFICATE                    :: 1042
SSL_R_SSLV3_ALERT_UNSUPPORTED_CERTIFICATE            :: 1043
SSL_R_SSLV3_ALERT_CERTIFICATE_REVOKED                :: 1044
SSL_R_SSLV3_ALERT_CERTIFICATE_EXPIRED                :: 1045
SSL_R_SSLV3_ALERT_CERTIFICATE_UNKNOWN                :: 1046
SSL_R_SSLV3_ALERT_ILLEGAL_PARAMETER                  :: 1047
SSL_R_TLSV1_ALERT_UNKNOWN_CA                         :: 1048
SSL_R_TLSV1_ALERT_ACCESS_DENIED                      :: 1049
SSL_R_TLSV1_ALERT_DECODE_ERROR                       :: 1050
SSL_R_TLSV1_ALERT_DECRYPT_ERROR                      :: 1051
SSL_R_TLSV1_ALERT_EXPORT_RESTRICTION                 :: 1060
SSL_R_TLSV1_ALERT_PROTOCOL_VERSION                   :: 1070
SSL_R_TLSV1_ALERT_INSUFFICIENT_SECURITY              :: 1071
SSL_R_TLSV1_ALERT_INTERNAL_ERROR                     :: 1080
SSL_R_TLSV1_ALERT_INAPPROPRIATE_FALLBACK             :: 1086
SSL_R_TLSV1_ALERT_USER_CANCELLED                     :: 1090
SSL_R_TLSV1_ALERT_NO_RENEGOTIATION                   :: 1100
SSL_R_TLSV1_ALERT_UNSUPPORTED_EXTENSION              :: 1110
SSL_R_TLSV1_ALERT_CERTIFICATE_UNOBTAINABLE           :: 1111
SSL_R_TLSV1_ALERT_UNRECOGNIZED_NAME                  :: 1112
SSL_R_TLSV1_ALERT_BAD_CERTIFICATE_STATUS_RESPONSE    :: 1113
SSL_R_TLSV1_ALERT_BAD_CERTIFICATE_HASH_VALUE         :: 1114
SSL_R_TLSV1_ALERT_UNKNOWN_PSK_IDENTITY               :: 1115
SSL_R_TLSV1_ALERT_CERTIFICATE_REQUIRED               :: 1116
SSL_R_TLSV1_ALERT_NO_APPLICATION_PROTOCOL            :: 1120
SSL_R_TLSV1_ALERT_ECH_REQUIRED                       :: 1121
SSL_R_PAKE_AND_KEY_SHARE_NOT_ALLOWED                 :: 1122
