package netpbm

import "core:image"

destroy :: proc(img: ^image.Image) -> bool {
	if img == nil {
		return false
	}
	context.allocator = img.pixels.allocator if img.pixels.allocator.procedure != nil else context.allocator

	defer free(img)
	delete(img.pixels)

	info := img.metadata.(^image.Netpbm_Info) or_return

	header_destroy(&info.header)
	free(info)
	img.metadata = nil

	return true
}

header_destroy :: proc(header: ^Header, allocator := context.allocator) {
	if header.format == .P7 && header.tupltype != "" {
		delete(header.tupltype, allocator)
		header.tupltype = ""
	}
}
