/*
package aes implements the AES block cipher and some common modes.


An example of how to use 'AES-ECB instance' to decrypt binary files

```odin

package foo
import "core:fmt"
import "core:crypto/aes"
import "core:os"
import "core:bytes"

BLOCK_SIZE :: aes.BLOCK_SIZE

main :: proc() {
	data, ok := os.read_entire_file("data.bin")
	if !ok {
		fmt.eprintln("Error Reading File")
		return
	}

	if len(data) % aes.BLOCK_SIZE != 0 {
		fmt.eprintln("Error: Data length is not a multiple of AES block size")
		return
	}

	key := transmute([]u8)string("aeskey")
	ctx: aes.Context_ECB
	aes.init_ecb(&ctx, key)
	// Allocate space for decrypted data
	plaintext := make([]byte, len(data))

	plain := plaintext // Preserve original slice view of the decrypted data
	for len(data) > 0 {
		aes.decrypt_ecb(&ctx, plain[:BLOCK_SIZE], data[:BLOCK_SIZE])
		data  = data[BLOCK_SIZE:]  // Advance encrypted data
		plain = plain[BLOCK_SIZE:] // Advance second view of the same destination memory
	}

	// Output decrypted data
	fmt.println(plaintext)
	os.write_entire_file("rcdecrypted.bin", plaintext)
}
```

*/
package aes