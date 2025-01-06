/*
package aead provides a generic interface to the supported Authenticated
Encryption with Associated Data algorithms.

Both a one-shot and context based interface are provided, with similar
usage.  If multiple messages are to be sealed/opened via the same key,
the context based interface may be more efficient, depending on the
algorithm.

WARNING: Reusing the same key + iv to seal (encrypt) multiple messages
results in catastrophic loss of security for most algorithms.

Example:
	package aead_example

	import "core:bytes"
	import "core:crypto"
	import "core:crypto/aead"

	main :: proc() {
		algo := aead.Algorithm.XCHACHA20POLY1305

		// The example added associated data, and plaintext.
		aad_str := "Get your ass in gear boys."
		pt_str := "They're immanetizing the Eschaton."

		aad := transmute([]byte)aad_str
		plaintext := transmute([]byte)pt_str
		pt_len := len(plaintext)

		// Generate a random key for the purposes of illustration.
		key := make([]byte, aead.KEY_SIZES[algo])
		defer delete(key)
		crypto.rand_bytes(key)

		// `ciphertext || tag`, is a common way data is transmitted, so
		// demonstrate that.
		buf := make([]byte, pt_len + aead.TAG_SIZES[algo])
		defer delete(buf)
		ciphertext, tag := buf[:pt_len], buf[pt_len:]

		// Seal the AAD + Plaintext.
		iv := make([]byte, aead.IV_SIZES[algo])
		defer delete(iv)
		crypto.rand_bytes(iv) // Random IVs are safe with XChaCha20-Poly1305.
		aead.seal(algo, ciphertext, tag, key, iv, aad, plaintext)

		// Open the AAD + Ciphertext.
		opened_pt := buf[:pt_len]
		if ok := aead.open(algo, opened_pt, key, iv, aad, ciphertext, tag); !ok {
			panic("aead example: failed to open")
		}

		assert(bytes.equal(opened_pt, plaintext))
	}
*/
package aead
