/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	An example of how to use `zlib.inflate`.
*/

/*
Example:
	package main

	import "core:bytes"
	import "core:compress/zlib"
	import "core:fmt"

	main :: proc() {
		ODIN_DEMO := []u8{
			120, 218, 101, 144,  65, 110, 131,  48,  16,  69, 215, 246,  41, 190,  44,  69,  73,  32, 148, 182,
			 75,  75,  28,  32, 251,  46, 217,  88, 238,   0,  86, 192,  32, 219,  36, 170, 170, 172, 122, 137,
			238, 122, 197,  30, 161,  70, 162,  20,  81, 203, 139,  25, 191, 255, 191,  60,  51,  40, 125,  81,
			 53,  33, 144,  15, 156, 155, 110, 232,  93, 128, 208, 189,  35,  89, 117,  65, 112, 222,  41,  99,
			 33,  37,   6, 215, 235, 195,  17, 239, 156, 197, 170, 118, 170, 131,  44,  32,  82, 164,  72, 240,
			253, 245, 249, 129,  12, 185, 224,  76, 105,  61, 118,  99, 171,  66, 239,  38, 193,  35, 103,  85,
			172,  66, 127,  33, 139,  24, 244, 235, 141,  49, 204, 223,  76, 208, 205, 204, 166,   7, 173,  60,
			 97, 159, 238,  37, 214,  41, 105, 129, 167,   5, 102,  27, 152, 173,  97, 178, 129,  73, 129, 231,
			  5, 230,  27, 152, 175, 225,  52, 192, 127, 243, 170, 157, 149,  18, 121, 142, 115, 109, 227, 122,
			 64,  87, 114, 111, 161,  49, 182,   6, 181, 158, 162, 226, 206, 167,  27, 215, 246,  48,  56,  99,
			 67, 117,  16,  47,  13,  45,  35, 151,  98, 231,  75,   1, 173,  90,  61, 101, 146,  71, 136, 244,
			170, 218, 145, 176, 123,  45, 173,  56, 113, 134, 191,  51, 219,  78, 235,  95,  28, 249, 253,   7,
			159, 150, 133, 125,
		}
		OUTPUT_SIZE :: 432

		buf: bytes.Buffer

		// We can pass ", true" to inflate a raw DEFLATE stream instead of a ZLIB wrapped one.
		err := zlib.inflate(input=ODIN_DEMO, buf=&buf, expected_output_size=OUTPUT_SIZE)
		defer bytes.buffer_destroy(&buf)

		if err != nil {
			fmt.printf("\nError: %v\n", err)
		}
		s := bytes.buffer_to_string(&buf)
		fmt.printf("Input: %v bytes, output (%v bytes):\n%v\n", len(ODIN_DEMO), len(s), s)
		assert(len(s) == OUTPUT_SIZE)
	}
*/
package compress_zlib
