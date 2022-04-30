/*
Formats:
	PBM (P1, P4): Portable Bit Map,       stores black and white images   (1 channel)
	PGM (P2, P5): Portable Gray Map,      stores greyscale images         (1 channel, 1 or 2 bytes per value)
	PPM (P3, P6): Portable Pixel Map,     stores colour images            (3 channel, 1 or 2 bytes per value)
	PAM (P7    ): Portable Arbitrary Map, stores arbitrary channel images            (1 or 2 bytes per value)
	PFM (Pf, PF): Portable Float Map,     stores floating-point images    (Pf: 1 channel, PF: 3 channel)

Reading
	All formats fill out header fields `format`, `width`, `height`, `channels`, `depth`
	Specific formats use more fields
		PGM, PPM, and PAM set `maxval`
		PAM also sets `tupltype`, and is able to set `channels` to an arbitrary value
		PFM sets `scale` and `little_endian`
	Currently doesn't support reading multiple images from one binary-format file

Writing
	All formats require the header field `format` to be specified
	Additional header fields are required for specific formats
		PGM, PPM, and PAM require `maxval`
		PAM also uses `tupltype`, though it may be left as default (empty or nil string)
		PFM requires `scale` and `little_endian`, though the latter may be left untouched (default is false)

Some syntax differences from the specifications:
	`channels` stores what the PAM specification calls `depth`
	`depth` instead stores how many bytes will fit `maxval` (should only be 1, 2, or 4)
	`scale` and `little_endian` are separated, so the `header` will always store a positive `scale`
	`little_endian` will only be true for a negative `scale` PFM, every other format will be false
	`little_endian` only describes the netpbm data being read/written, the image buffer will be native
*/

package netpbm
