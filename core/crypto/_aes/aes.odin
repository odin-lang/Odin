package _aes

// KEY_SIZE_128 is the AES-128 key size in bytes.
KEY_SIZE_128 :: 16
// KEY_SIZE_192 is the AES-192 key size in bytes.
KEY_SIZE_192 :: 24
// KEY_SIZE_256 is the AES-256 key size in bytes.
KEY_SIZE_256 :: 32

// BLOCK_SIZE is the AES block size in bytes.
BLOCK_SIZE :: 16

// ROUNDS_128 is the number of rounds for AES-128.
ROUNDS_128 :: 10
// ROUNDS_192 is the number of rounds for AES-192.
ROUNDS_192 :: 12
// ROUNDS_256 is the number of rounds for AES-256.
ROUNDS_256 :: 14

// GHASH_KEY_SIZE is the GHASH key size in bytes.
GHASH_KEY_SIZE :: 16
// GHASH_BLOCK_SIZE is the GHASH block size in bytes.
GHASH_BLOCK_SIZE :: 16
// GHASH_TAG_SIZE is the GHASH tag size in bytes.
GHASH_TAG_SIZE :: 16

// RCON is the AES keyschedule round constants.
@(rodata)
RCON := [10]byte{0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36}
