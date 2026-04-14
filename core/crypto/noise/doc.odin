/*
An implementation of the Noise Protocol Framework (Revision 34).

The `fallback` modifier and deferred/multi-PSK patterns are not supported
for the sake of simplicity.

See:
- [[ https://noiseprotocol.org/ ]]
*/
package noise

// In general, to complete a noise handshake you must:
//
// - If you are initiating the connection, call `handshake_initiator_step`
//   passing `nil` as the `input_message` parameter.
//
// - Send the resulting `[]byte` to the responder (generally a server) via
//   the method of your choice.  This MUST be done even if the status code
//   returned is `.Handshake_Complete`.
//
// - If the status code returned by `handshake_initiator_step` was
//   `.Handshake_Complete`, the handshake completed successfully,
//   and it is now possible to validate the peer identity, obtain the
//   handshake transcript hash, and most usefully call `handshake_split`
//   to populate the `Cipher_States` struct that will be used to
//   encrypt/decrypt data.
//
//   Otherwise, read the response from the responder and feed the response
//   data as the `input_message` to the next `handshake_initiator_step`
//   until it returns `.Handshake_Complete`.
//
// - If you are the responder, the method is much the same, except you
//   must pass a valid `input_message` received from an initiator to the
//   first call to `handshake_responder_step`. Repeat until the returned
//   status is `.Handshake_Complete`.
