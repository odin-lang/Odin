package compress_filters

swap2 :: proc "contextless" (data: []u8) -> (processed: int) #no_bounds_check {
	processed = len(data) &~ 1
	for i := 0; i < processed; i += 2 {
		data[i], data[i + 1] = data[i + 1], data[i]
	}
	return
}

swap4 :: proc "contextless" (data: []u8) -> (processed: int) #no_bounds_check {
	processed = len(data) &~ 3
	address := uintptr(raw_data(data))
	head := 0
	if address & 3 == 0 {
		head = min(int(32 - address & 31) & 31, processed)
	}
	for i := 0; i < head; i += 4 {
		put_be32(data, i, get_le32(data, i))
	}
	for i := head; i < processed; i += 4 {
		put_be32(data, i, get_le32(data, i))
	}
	return
}
