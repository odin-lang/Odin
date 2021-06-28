//+ignore
package zlib

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	An example of how to use `zlib.inflate`.
*/

import "core:bytes"
import "core:fmt"

main :: proc() {

	ODIN_DEMO := []u8{
		120, 156, 101, 144,  77, 110, 131,  48,  16, 133, 215, 204,  41, 158,  44,
		 69,  73,  32, 148, 182,  75,  35,  14, 208, 125,  47,  96, 185, 195, 143,
		130,  13,  50,  38,  81,  84, 101, 213,  75, 116, 215,  43, 246,   8,  53,
		 82, 126,   8, 181, 188, 152, 153, 111, 222, 147, 159, 123, 165, 247, 170,
		 98,  24, 213,  88, 162, 198, 244, 157, 243,  16, 186, 115,  44,  75, 227,
		  5,  77, 115,  72, 137, 222, 117, 122, 179, 197,  39,  69, 161, 170, 156,
		 50, 144,   5,  68, 130,   4,  49, 126, 127, 190, 191, 144,  34,  19,  57,
		 69,  74, 235, 209, 140, 173, 242, 157, 155,  54, 158, 115, 162, 168,  12,
		181, 239, 246, 108,  17, 188, 174, 242, 224,  20,  13, 199, 198, 235, 250,
		194, 166, 129,  86,   3,  99, 157, 172,  37, 230,  62,  73, 129, 151, 252,
		 70, 211,   5,  77,  31, 104, 188, 160, 113, 129, 215,  59, 205,  22,  52,
		123, 160,  83, 142, 255, 242,  89, 123,  93, 149, 200,  50, 188,  85,  54,
		252,  18, 248, 192, 238, 228, 235, 198,  86, 224, 118, 224, 176, 113, 166,
		112,  67, 106, 227, 159, 122, 215,  88,  95, 110, 196, 123, 205, 183, 224,
		 98,  53,   8, 104, 213, 234, 201, 147,   7, 248, 192,  14, 170,  29,  25,
		171,  15,  18,  59, 138, 112,  63,  23, 205, 110, 254, 136, 109,  78, 231,
		 63, 234, 138, 133, 204,
	};
	OUTPUT_SIZE :: 438;

	buf: bytes.Buffer;

	// We can pass ", true" to inflate a raw DEFLATE stream instead of a ZLIB wrapped one.
	err := inflate(input=ODIN_DEMO, buf=&buf, expected_output_size=OUTPUT_SIZE);
	defer bytes.buffer_destroy(&buf);

	if err != nil {
		fmt.printf("\nError: %v\n", err);
	}
	s := bytes.buffer_to_string(&buf);
	fmt.printf("Input: %v bytes, output (%v bytes):\n%v\n", len(ODIN_DEMO), len(s), s);
	assert(len(s) == OUTPUT_SIZE);
}
