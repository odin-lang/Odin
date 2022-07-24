package netpbm

import "core:bytes"
import "core:image"

destroy :: proc(img: ^image.Image) -> bool {
	if img == nil do return false

	defer free(img)
	bytes.buffer_destroy(&img.pixels)

	info, ok := img.metadata.(^image.Netpbm_Info)
	if !ok do return false

	header_destroy(&info.header)
	free(info)
	img.metadata = nil

	return true
}

header_destroy :: proc(using header: ^Header) {
	if format == .P7 && tupltype != "" {
		delete(tupltype)
		tupltype = ""
	}
}
