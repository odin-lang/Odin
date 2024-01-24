package test_core_crypto

/*
	Copyright 2021 zhibog
	Made available under the BSD-3 license.

	List of contributors:
		zhibog, dotbmp:  Initial implementation.
		Jeroen van Rijn: Test runner setup.

	Tests for the hashing algorithms within the crypto library.
	Where possible, the official test vectors are used to validate the implementation.
*/

import "core:testing"
import "core:fmt"

import "core:crypto/siphash"
import "core:os"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}
	test_hash(&t)

	test_siphash_2_4(&t)

	// "modern" crypto tests
	test_chacha20(&t)
	test_poly1305(&t)
	test_chacha20poly1305(&t)
	test_x25519(&t)
	test_rand_bytes(&t)

	bench_modern(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

hex_string :: proc(bytes: []byte, allocator := context.temp_allocator) -> string {
	lut: [16]byte = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'}
	buf := make([]byte, len(bytes) * 2, allocator)
	for i := 0; i < len(bytes); i += 1 {
		buf[i * 2 + 0] = lut[bytes[i] >> 4 & 0xf]
		buf[i * 2 + 1] = lut[bytes[i]      & 0xf]
	}
	return string(buf)
}

@(test)
test_siphash_2_4 :: proc(t: ^testing.T) {
	// Test vectors from
	// https://github.com/veorq/SipHash/blob/master/vectors.h
	test_vectors := [?]u64 {
		0x726fdb47dd0e0e31, 0x74f839c593dc67fd, 0x0d6c8009d9a94f5a, 0x85676696d7fb7e2d,
		0xcf2794e0277187b7, 0x18765564cd99a68d, 0xcbc9466e58fee3ce, 0xab0200f58b01d137,
		0x93f5f5799a932462, 0x9e0082df0ba9e4b0, 0x7a5dbbc594ddb9f3, 0xf4b32f46226bada7,
		0x751e8fbc860ee5fb, 0x14ea5627c0843d90, 0xf723ca908e7af2ee, 0xa129ca6149be45e5,
		0x3f2acc7f57c29bdb, 0x699ae9f52cbe4794, 0x4bc1b3f0968dd39c, 0xbb6dc91da77961bd,
		0xbed65cf21aa2ee98, 0xd0f2cbb02e3b67c7, 0x93536795e3a33e88, 0xa80c038ccd5ccec8,
		0xb8ad50c6f649af94, 0xbce192de8a85b8ea, 0x17d835b85bbb15f3, 0x2f2e6163076bcfad,
		0xde4daaaca71dc9a5, 0xa6a2506687956571, 0xad87a3535c49ef28, 0x32d892fad841c342,
		0x7127512f72f27cce, 0xa7f32346f95978e3, 0x12e0b01abb051238, 0x15e034d40fa197ae,
		0x314dffbe0815a3b4, 0x027990f029623981, 0xcadcd4e59ef40c4d, 0x9abfd8766a33735c,
		0x0e3ea96b5304a7d0, 0xad0c42d6fc585992, 0x187306c89bc215a9, 0xd4a60abcf3792b95,
		0xf935451de4f21df2, 0xa9538f0419755787, 0xdb9acddff56ca510, 0xd06c98cd5c0975eb,
		0xe612a3cb9ecba951, 0xc766e62cfcadaf96, 0xee64435a9752fe72, 0xa192d576b245165a,
		0x0a8787bf8ecb74b2, 0x81b3e73d20b49b6f, 0x7fa8220ba3b2ecea, 0x245731c13ca42499,
		0xb78dbfaf3a8d83bd, 0xea1ad565322a1a0b, 0x60e61c23a3795013, 0x6606d7e446282b93,
		0x6ca4ecb15c5f91e1, 0x9f626da15c9625f3, 0xe51b38608ef25f57, 0x958a324ceb064572,
	}

	key: [16]byte
	for i in 0..<16 {
		key[i] = byte(i)
	}

	for i in 0..<len(test_vectors) {
		data := make([]byte, i)
		for j in 0..<i {
			data[j] = byte(j)
		}

		vector   := test_vectors[i]
		computed := siphash.sum_2_4(data[:], key[:])

		expect(t, computed == vector, fmt.tprintf("Expected: 0x%x for input of %v, but got 0x%x instead", vector, data, computed))
	}
}
