// `crc32`, `crc64`, `adler32`, `djb`, `fnv`, `jenkins`, `murmur` and other hashes.
package hash

/*
	Copyright 2016 Ginger Bill.
	Copyright 2021-2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Ginger Bill:     Initial implementation: CRC-32, djb2, FNV, Jenkins, Murmur, sdbm, ginger16, the first Adler-32.
		Jeroen van Rijn: CRC-16 and CRC-64, hardware-accelerated CRC-32 and `crc32_combine`, Adler-32 rewrites.
		Manuel:          MurmurHash3.

	`crc64_xz` is based on Mark Adler's v1.4 implementation in C, under the zlib license.
*/