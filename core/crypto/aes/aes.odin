/*
package aes implements the AES block cipher and some common modes.

See:
- https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197-upd1.pdf
- https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf
- https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38d.pdf
*/
package aes

import "core:crypto/_aes"

// KEY_SIZE_128 is the AES-128 key size in bytes.
KEY_SIZE_128 :: _aes.KEY_SIZE_128
// KEY_SIZE_192 is the AES-192 key size in bytes.
KEY_SIZE_192 :: _aes.KEY_SIZE_192
// KEY_SIZE_256 is the AES-256 key size in bytes.
KEY_SIZE_256 :: _aes.KEY_SIZE_256

// BLOCK_SIZE is the AES block size in bytes.
BLOCK_SIZE :: _aes.BLOCK_SIZE
