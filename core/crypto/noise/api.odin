package noise

import "base:runtime"
import "core:crypto/ecdh"

// MAX_PACKET_SIZE is the maximum Noise message size, including TAG_SIZE
// if relevant (`seal_message`, `open_message`).
MAX_PACKET_SIZE :: 65535

// PSK_SIZE is the size of an optional handshake pre-shared symmetric key.
PSK_SIZE :: 32
// TAG_SIZE is the size of the AEAD authentication tag.
TAG_SIZE :: 16
// MAX_STEP_MSG_SIZE is the maximum per-handshake step message size,
// excluding the optional payload.
//
// `e` is DH_LEN, `s` is either DH_LEN or DH_LEN + TAG_SIZE, and there
// is a maximum of one per each message, and a possible mandatory tag.
MAX_STEP_MSG_SIZE :: (MAX_DH_SIZE*2)+TAG_SIZE+TAG_SIZE

// Status is the status of Noise protocol operation.
Status :: enum {
	Ok,

	// States
	Handshake_Pending,
	Handshake_Complete,
	Handshake_Split,
	Handshake_Failed,

	// Errors
	Invalid_Protocol_String,
	Invalid_Pre_Shared_Key,
	Invalid_DH_Key,
	No_Self_Identity,
	No_Peer_Identity,
	Unexpected_Peer_Identity,
	Unexpected_Pre_Shared_Key,

	DH_Failure,
	Invalid_Handshake_Message,

	Decryption_Failure,
	IV_Exhausted,
	Invalid_Cipher_State,
	Invalid_Destination_Buffer,
	Invalid_Payload_Message,
	Max_Packet_Size,

	Out_Of_Memory,
}

// Handshake_State is the per-handshake state.
Handshake_State :: struct {
	s: ecdh.Private_Key,
	e: ecdh.Private_Key,
	rs: ecdh.Public_Key,
	re: ecdh.Public_Key,
	psk: [PSK_SIZE]byte,

	symmetric_state: Symmetric_State,
	message_pattern: ^Message_Pattern,
	current_message: int,

	status: Status,

	initiator: bool,
	pre_set_e: bool,
}

// Cipher_States are the keyed AEAD instances and associated state,
// derived from a successful handshake.
Cipher_States :: struct {
	c1_i_to_r: Cipher_State,
	c2_r_to_i: Cipher_State,

	initiator: bool,
}

// handshake_init initializes a Handshake_State with the provided parameters.
// The relevant values are copied into the Handshake_State instance, and
// can be discarded/sanitized right after handshake_init returns (eg: psk).
//
// Note: While this implementation supports setting `e`, this is primarily
// intended for testing, or cases where the runtime cryptographic entropy
// source is unavailable.  Use of this functionality is STRONGLY
// discouraged.
@(require_results)
handshake_init :: proc(
	self: ^Handshake_State,
	initiator: bool,
	prologue: []byte,
	s: ^ecdh.Private_Key, // Our static key
	rs: ^ecdh.Public_Key, // Peer static key
	protocol_name: string,
	psk: []byte = nil,
	_e: ^ecdh.Private_Key = nil, // Our ephemeral key (for testing/RNG-less systems)
) -> Status {
	return handshakestate_initialize(
		self,
		initiator,
		prologue,
		s,
		_e,
		rs,
		nil,
		protocol_name,
		psk,
	)
}

// handshake_initiator_step takes an input_message received from the responder
// if any and an optional payload to be sent to the responder, and performs
// one step of the Noise handshake process, returning the message to be sent
// to the responder if any, the payload received from the responder if any,
// and the status of the handshake.
//
// The output message MUST be sent to the responder even if the status code
// returned is .Handshake_Complete.
//
// If the dst parameter is provided, the message and payload will be written
// to dst, otherwise new buffers will be allocated.
@(require_results)
handshake_initiator_step :: proc(
	self: ^Handshake_State,
	input_message: []byte,
	payload: []byte = nil,
	dst: []byte = nil,
	allocator := context.allocator,
) -> ([]byte, []byte, Status) {
	output_message: []byte
	payload_buffer: []byte
	status: Status

	dst := dst
	if input_message == nil {
		output_message, status = handshakestate_write_message(self, payload, dst, allocator)
	} else {
		payload_buffer, status = handshakestate_read_message(self, input_message, dst, allocator)
		if status == .Handshake_Pending {
			if dst != nil {
				dst = dst[len(payload_buffer):]
			}
			output_message, status = handshakestate_write_message(self, payload, dst, allocator)
		}
	}

	return output_message, payload_buffer, status
}

// handshake_responder_step takes a input_message received from the initiator,
// and and an optional payload to be sent to the initiator, and performs
// one step of the Noise handshake process, returning the message to be sent
// to the initiator if any, the payload received from the initiator if any,
// and the status of the handshake.
//
// The output message MUST be sent to the initiator even if the status code
// returned is .Handshake_Complete.
//
// If the dst parameter is provided, the message and payload will be written
// to dst, otherwise new buffers will be allocated.
@(require_results)
handshake_responder_step :: proc(
	self: ^Handshake_State,
	input_message: []byte,
	payload: []byte = nil,
	dst: []byte = nil,
	allocator := context.allocator,
) -> ([]byte, []byte, Status) {
	output_message: []byte

	if input_message == nil {
		return nil, nil, .Invalid_Handshake_Message
	}

	dst := dst
	payload_buffer, status := handshakestate_read_message(self, input_message, dst, allocator)
	if status == .Handshake_Pending {
		if dst != nil {
			dst = dst[len(payload_buffer):]
		}
		output_message, status = handshakestate_write_message(self, payload, dst, allocator)
	}

	return output_message, payload_buffer, status
}

// handshake_write_message calls the Noise HandshakeState's WriteMessage
// function directly.  In most cases you are better off using
// handshake_initiator_step or handshake_responder_step.
//
// If the dst parameter is provided, the message and payload will be written
// to dst, otherwise new buffers will be allocated.
@(require_results)
handshake_write_message :: proc(
	self: ^Handshake_State,
	payload: []byte,
	dst: []byte = nil,
	allocator := context.allocator,
) -> ([]byte, Status) {
	return handshakestate_write_message(self, payload, dst, allocator)
}

// handshake_read_message calls the Noise HandshakeState's ReadMessage
// function directly.  In most cases you are better off using
// handshake_initiator_step or handshake_responder_step.
//
// If the dst parameter is provided, the message and payload will be written
// to dst, otherwise new buffers will be allocated.
@(require_results)
handshake_read_message :: proc(
	self: ^Handshake_State,
	message: []byte,
	dst: []byte = nil,
	allocator := context.allocator,
) -> ([]byte, Status) {
	return handshakestate_read_message(self, message, dst, allocator)
}

// handshake_split initializes a Cipher_States instance from a completed
// handshake.  This can be called once and only once per Handshake_State
// instance.
@(require_results)
handshake_split :: proc(self: ^Handshake_State, cipher_states: ^Cipher_States) -> Status {
	if self.status != .Handshake_Complete {
		return self.status
	}

	symmetricstate_split(&self.symmetric_state, cipher_states)
	if self.message_pattern.is_one_way {
		cipherstate_reset(&cipher_states.c2_r_to_i)
		cipher_states.c2_r_to_i.is_invalid = true
	}
	cipher_states.initiator = self.initiator
	self.status = .Handshake_Split

	return .Ok
}

// handshake_peer_identity returns the peer's static DH key used by
// a completed handshake.
//
// This returns a pointer to the Handshake_State's copy of the peer's
// public key, that will get wiped by handshake_reset.  If the key is
// needed after a call to handshake_reset, it must be copied.
@(require_results)
handshake_peer_identity :: proc(self: ^Handshake_State) -> (^ecdh.Public_Key, Status) {
	#partial switch self.status {
	case .Handshake_Complete, .Handshake_Split:
	case:
		return nil, self.status
	}

	if ecdh.curve(&self.rs) == .Invalid {
		return nil, .No_Peer_Identity
	}

	return &self.rs, .Ok
}

// handshake_hash returns the handshake transcript hash of a completed
// handshake, for the purposes of channel binding.  See 11.2 of the
// specification for details on usage.
//
// This returns a slice to an internal buffer that will get wiped by
// handshake_reset.  If the hash is needed after a call to handshake_reset,
// the slice must be copied.
@(require_results)
handshake_hash :: proc(self: ^Handshake_State) -> ([]byte, Status) {
	#partial switch self.status {
	case .Handshake_Complete, .Handshake_Split:
	case:
		return nil, self.status
	}

	return symmetricstate_get_handshake_hash(&self.symmetric_state), .Ok
}

// handshake_reset sanitizes the Handshake_State.  It is both safe and
// recommended to call this as soon as practical (after any calls to
// handshake_peer_identity, handshake_hash, and handshake_split are
// complete).
handshake_reset :: proc(self: ^Handshake_State) {
	handshakestate_reset(self)
}

// seal_message encrypts the provided data, authenticates the aad and
// ciphertext, and returns the resulting ciphertext.  The ciphertext
// will ALWAYS be `len(plaintext) + TAG_SIZE` bytes in length.
//
// If the dst parameter is provided, the ciphertext will be written
// to dst, otherwise a new buffer will be allocated.
@(require_results)
seal_message :: proc(self: ^Cipher_States, aad, plaintext: []byte, dst: []byte = nil, allocator := context.allocator) -> ([]byte, Status) {
	data_len := len(plaintext)

	dst := dst
	did_alloc: bool
	switch {
	case dst == nil:
		err: runtime.Allocator_Error
		dst, err = make([]byte, data_len + TAG_SIZE, allocator)
		if err != nil {
			return nil, .Out_Of_Memory
		}
		did_alloc = true
	case:
		if len(dst) != data_len + TAG_SIZE {
			return nil, .Invalid_Destination_Buffer
		}
	}

	status: Status
	switch self.initiator {
	case true:
		dst, status = cipherstate_encrypt_with_ad(&self.c1_i_to_r, aad, plaintext, dst)
	case false:
		dst, status = cipherstate_encrypt_with_ad(&self.c2_r_to_i, aad, plaintext, dst)
	}
	if status != .Ok && did_alloc {
		delete(dst, allocator)
		dst = nil
	}

	return dst, status
}

// open_message authenticates the aad and ciphertext, decrypts the
// ciphertext and returns the resulting plaintext.  The plaintext will
// ALWAYS be `len(ciphertext) - TAG_SIZE` bytes in length.
//
// If the dst parameter is provided, the plaintext will be written to
// dst, otherwise a new buffer will be allocated.
@(require_results)
open_message :: proc(self: ^Cipher_States, aad, ciphertext: []byte, dst: []byte = nil, allocator := context.allocator) -> ([]byte, Status) {
	if len(ciphertext) < TAG_SIZE {
		return nil, .Invalid_Payload_Message
	}

	data_len := len(ciphertext) - TAG_SIZE

	dst := dst
	did_alloc: bool
	switch {
	case dst == nil:
		if data_len > 0 {
			err: runtime.Allocator_Error
			dst, err = make([]byte, data_len, allocator)
			if err != nil {
				return nil, .Out_Of_Memory
			}
			did_alloc = true
		}
	case:
		if len(dst) != data_len {
			return nil, .Invalid_Destination_Buffer
		}
	}

	status: Status
	switch self.initiator {
	case true:
		dst, status = cipherstate_decrypt_with_ad(&self.c2_r_to_i, aad, ciphertext, dst)
	case false:
		dst, status = cipherstate_decrypt_with_ad(&self.c1_i_to_r, aad, ciphertext, dst)
	}
	if status != .Ok && did_alloc {
		delete(dst, allocator)
		dst = nil
	}

	return dst, status
}

// cipherstates_rekey updates the selected AEAD key, using a one way function.
// See 11.3 of the specification for examples of usage.
//
// Note: If one side updates the seal_key, the other side must update
// the non-seal_key and vice versa.
@(require_results)
cipherstates_rekey :: proc(self: ^Cipher_States, seal_key: bool) -> Status {
	cs := cipherstates_cs(self, seal_key)
	if cs.is_invalid {
		return .Invalid_Cipher_State
	}
	if !cipherstate_has_key(cs) {
		return .Handshake_Pending
	}

	cipherstate_rekey(cs)

	return .Ok
}

// cipherstates_set_n sets the interal counter used to generate the AEAD
// IV to an explicit value.  This can be used to deal with out-of-order
// transport messages.  See 11.4 of the specification.
//
// WARNING: Reusing n across different aad/messages with the same Cipher_States
// will result in catastrophic loss of security.
@(require_results)
cipherstates_set_n :: proc(self: ^Cipher_States, seal_key: bool, n: u64) -> Status {
	cs := cipherstates_cs(self, seal_key)
	if cs.is_invalid {
		return .Invalid_Cipher_State
	}
	if !cipherstate_has_key(cs) {
		return .Handshake_Pending
	}

	cs.n = n

	return .Ok
}

// cipherstates_n returns the interal counter used to generate the AEAD
// IV.  This can be used to deal with out-of-order transport messages.
// See 11.4 of the specification.
//
// WARNING: Reusing n across different aad/messages with the same Cipher_States
// will result in catastrophic loss of security.
@(require_results)
cipherstates_n :: proc(self: ^Cipher_States, seal_key: bool, n: u64) -> (u64, Status) {
	cs := cipherstates_cs(self, seal_key)
	if cs.is_invalid {
		return 0, .Invalid_Cipher_State
	}
	if !cipherstate_has_key(cs) {
		return 0, .Handshake_Pending
	}

	return cs.n, .Ok
}

// cipherstates_reset sanitizes the Cipher_States.
cipherstates_reset :: proc(self: ^Cipher_States) {
	self.initiator = false
	cipherstate_reset(&self.c1_i_to_r)
	cipherstate_reset(&self.c2_r_to_i)
}

@(private = "file")
cipherstates_cs :: proc(self: ^Cipher_States, seal_key: bool) -> ^Cipher_State {
	switch self.initiator {
	case true:
		switch seal_key {
		case true:
			return &self.c1_i_to_r
		case false:
			return &self.c2_r_to_i
		}
	case false:
		switch seal_key {
		case true:
			return &self.c2_r_to_i
		case false:
			return &self.c1_i_to_r
		}
	}
	unreachable()
}

// split_protocol_string splits a protocol string into individual components.
@(require_results)
split_protocol_string :: proc(protocol_name: string) -> (Handshake_Pattern, ecdh.Curve, aead.Algorithm, hash.Algorithm, Status) {
	str := protocol_name

	if len(str) > 255 {
		return .Invalid, .Invalid, .Invalid, .Invalid, .Invalid_Protocol_String
	}

	s, ok := strings.split_by_byte_iterator(&str, '_')
	if !ok || s != "Noise" {
		return .Invalid, .Invalid, .Invalid, .Invalid, .Invalid_Protocol_String
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid, .Invalid, .Invalid, .Invalid, .Invalid_Protocol_String
	}

	pattern: Handshake_Pattern
	switch s {
	case "N" : pattern = .N
	case "K" : pattern = .K
	case "X" : pattern = .X
	case "XX": pattern = .XX
	case "NK": pattern = .NK
	case "NN": pattern = .NN
	case "KN": pattern = .KN
	case "KK": pattern = .KK
	case "NX": pattern = .NX
	case "KX": pattern = .KX
	case "XN": pattern = .XN
	case "IN": pattern = .IN
	case "XK": pattern = .XK
	case "IK": pattern = .IK
	case "IX": pattern = .IX
	case "NK1": pattern = .NK1
	case "NX1": pattern = .NX1
	case "X1N": pattern = .X1N
	case "X1K": pattern = .X1K
	case "XK1": pattern = .XK1
	case "X1K1": pattern = .X1K1
	case "X1X": pattern = .X1X
	case "XX1": pattern = .XX1
	case "X1X1": pattern = .X1X1
	case "K1N": pattern = .K1N
	case "K1K": pattern = .K1K
	case "KK1": pattern = .KK1
	case "K1K1": pattern = .K1K1
	case "K1X": pattern = .K1X
	case "KX1": pattern = .KX1
	case "K1X1": pattern = .K1X1
	case "I1N": pattern = .I1N
	case "I1K": pattern = .I1K
	case "IK1": pattern = .IK1
	case "I1K1": pattern = .I1K1
	case "I1X": pattern = .I1X
	case "IX1": pattern = .IX1
	case "I1X1": pattern = .I1X1
	case "Npsk0": pattern = .Npsk0
	case "Kpsk0": pattern = .Kpsk0
	case "Xpsk1": pattern = .Xpsk1
	case "NNpsk0": pattern = .NNpsk0
	case "NNpsk2": pattern = .NNpsk2
	case "NKpsk0": pattern = .NKpsk0
	case "NKpsk2": pattern = .NKpsk2
	case "NXpsk2": pattern = .NXpsk2
	case "XNpsk3": pattern = .XNpsk3
	case "XKpsk3": pattern = .XKpsk3
	case "XXpsk3": pattern = .XXpsk3
	case "KNpsk0": pattern = .KNpsk0
	case "KNpsk2": pattern = .KNpsk2
	case "KKpsk0": pattern = .KKpsk0
	case "KKpsk2": pattern = .KKpsk2
	case "KXpsk2": pattern = .KXpsk2
	case "INpsk1": pattern = .INpsk1
	case "INpsk2": pattern = .INpsk2
	case "IKpsk1": pattern = .IKpsk1
	case "IKpsk2": pattern = .IKpsk2
	case "IXpsk2": pattern = .IXpsk2
	case: pattern = .Invalid
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid, .Invalid, .Invalid, .Invalid, .Invalid_Protocol_String
	}
	dh: ecdh.Curve
	switch s {
	case "25519": dh = .X25519
	case "448": dh = .X448
	case: dh = .Invalid
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid, .Invalid, .Invalid, .Invalid, .Invalid_Protocol_String
	}
	cipher: aead.Algorithm
	switch s {
	case "AESGCM": cipher = .AES_GCM_256
	case "ChaChaPoly": cipher = .CHACHA20POLY1305
	case: cipher = .Invalid
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid, .Invalid, .Invalid, .Invalid, .Invalid_Protocol_String
	}
	hash: hash.Algorithm
	switch s {
	case "SHA512": hash = .SHA512
	case "SHA256": hash = .SHA256
	case "BLAKE2s": hash = .BLAKE2S
	case "BLAKE2b": hash = .BLAKE2B
	case: hash = .Invalid
	}

	status: Status

	if len(str) != 0 {
		status = .Invalid_Protocol_String
	}
	if pattern == .Invalid || dh == .Invalid || cipher == .Invalid || hash == .Invalid {
		status = .Invalid_Protocol_String
	}

	return pattern, dh, cipher, hash, status
}
