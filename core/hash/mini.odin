package hash

ginger_hash8 :: proc "contextless" (x: u8) -> u8 {
	h := x * 251
	h += ~(x << 3)
	h ~=  (x >> 1)
	h += ~(x << 7)
	h ~=  (x >> 6)
	h +=  (x << 2)
	return h
}


ginger_hash16 :: proc "contextless" (x: u16) -> u16 {
	z := (x << 8) | (x >> 8)
	h := z
	h += ~(z << 5)
	h ~=  (z >> 2)
	h += ~(z << 13)
	h ~=  (z >> 10)
	h += ~(z << 4)
	h = (h << 10) | (h >> 10)
	return h
}


ginger8 :: proc "contextless" (data: []byte) -> u8 {
	h := ginger_hash8(0)
	for b in data {
		h ~= ginger_hash8(b)
	}
	return h
}
ginger16 :: proc "contextless" (data: []byte) -> u16 {
	h := ginger_hash16(0)
	for b in data {
		h ~= ginger_hash16(u16(b))
	}
	return h
}
