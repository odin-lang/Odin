/*
Formats:

	PBM (P1, P4): Portable Bit Map,       stores black and white images   (1 channel)
	PGM (P2, P5): Portable Gray Map,      stores greyscale images         (1 channel, 1 or 2 bytes per value)
	PPM (P3, P6): Portable Pixel Map,     stores colour images            (3 channel, 1 or 2 bytes per value)
	PAM (P7    ): Portable Arbitrary Map, stores arbitrary channel images            (1 or 2 bytes per value)
	PFM (Pf, PF): Portable Float Map,     stores floating-point images    (Pf: 1 channel, PF: 3 channel)

Reading:

- All formats fill out header fields `format`, `width`, `height`, `channels`, `depth`.
- Specific formats use more fields:
	PGM, PPM, and PAM set `maxval` (maximum of 65535)
	PAM sets `tupltype` if there is one, and can set `channels` to any value (not just 1 or 3)
	PFM sets `scale` (float equivalent of `maxval`) and `little_endian` (endianness of stored floats)
- Currently doesn't support reading multiple images from one binary-format file.

Writing:

- You can use your own `Netpbm_Info` struct to control how images are written.
- All formats require the header field `format` to be specified.
- Additional header fields are required for specific formats:
	PGM, PPM, and PAM require `maxval` (maximum of 65535)
	PAM also uses `tupltype`, though it may be left as default (empty or nil string)
	PFM requires `scale`, and optionally `little_endian`

Some syntax differences from the specifications:

- `channels` stores the number of values per pixel, what the PAM specification calls `depth`
- `depth` instead is the number of bits for a single value (32 for PFM, 16 or 8 otherwise)
- `scale` and `little_endian` are separated, so the `header` will always store a positive `scale`
- `little_endian` will only be true for a negative `scale` PFM, every other format will be false
- `little_endian` only describes the netpbm data being read/written, the image buffer will be native
*/
package netpbm
