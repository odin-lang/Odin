/*
A small `GZIP` unpacker.

Example:
	import    "core:bytes"
	import os "core:os/os2"
	import    "core:compress"
	import    "core:compress/gzip"
	import    "core:fmt"

	// Small GZIP file with fextra, fname and fcomment present.
	@private
	TEST: []u8 = {
		0x1f, 0x8b, 0x08, 0x1c, 0xcb, 0x3b, 0x3a, 0x5a,
		0x02, 0x03, 0x07, 0x00, 0x61, 0x62, 0x03, 0x00,
		0x63, 0x64, 0x65, 0x66, 0x69, 0x6c, 0x65, 0x6e,
		0x61, 0x6d, 0x65, 0x00, 0x54, 0x68, 0x69, 0x73,
		0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x63, 0x6f,
		0x6d, 0x6d, 0x65, 0x6e, 0x74, 0x00, 0x2b, 0x48,
		0xac, 0xcc, 0xc9, 0x4f, 0x4c, 0x01, 0x00, 0x15,
		0x6a, 0x2c, 0x42, 0x07, 0x00, 0x00, 0x00,
	}

	main :: proc() {
		// Set up output buffer.
		buf: bytes.Buffer
		defer bytes.buffer_destroy(&buf)

		stdout :: proc(s: string) {
			os.write_string(os.stdout, s)
		}
		stderr :: proc(s: string) {
			os.write_string(os.stderr, s)
		}

		if len(os.args) < 2 {
			stderr("No input file specified.\n")
			err := gzip.load(data=TEST, buf=&buf, known_gzip_size=len(TEST))
			if err == nil {
				stdout("Displaying test vector: \"")
				stdout(bytes.buffer_to_string(&buf))
				stdout("\"\n")
			} else {
				fmt.printf("gzip.load returned %v\n", err)
			}
			bytes.buffer_destroy(&buf)
			os.exit(0)
		}

		for file in os.args[1:] {
			err: gzip.Error

			if file == "-" {
				// Read from stdin
				ctx := &compress.Context_Stream_Input{
					input = os.stdin.stream,
				}
				err = gzip.load(ctx, &buf)
			} else {
				err = gzip.load(file, &buf)
			}
			switch err {
			case nil:
				stdout(bytes.buffer_to_string(&buf))
			case gzip.E_General.File_Not_Found:
				stderr("File not found: ")
				stderr(file)
				stderr("\n")
				os.exit(1)
			case:
				stderr("GZIP returned an error.\n")
				os.exit(2)
			}
		}
	}
*/
package compress_gzip

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
		Ginger Bill:     Cosmetic changes.

	A small GZIP implementation as an example.
*/