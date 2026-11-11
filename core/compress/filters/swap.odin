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
	for i := 0; i < processed; i += 4 {
		put_be32(data, i, get_le32(data, i))
	}
	return
}
