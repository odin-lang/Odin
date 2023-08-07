package netpbm

import "core:bytes"
import "core:image"

destroy :: proc(img: ^image.Image) -> bool {
	if img == nil {
		return false
	}

	defer free(img)
	bytes.buffer_destroy(&img.pixels)

	info := img.metadata.(^image.Netpbm_Info) or_return

	header_destroy(&info.header)
	free(info)
	img.metadata = nil

	return true
}

header_destroy :: proc(header: ^Header) {
	if header.format == .P7 && header.tupltype != "" {
		delete(header.tupltype)
		header.tupltype = ""
	}
}
