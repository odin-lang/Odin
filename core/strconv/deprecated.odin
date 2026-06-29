package strconv

// 2025-10-03 Deprecated C short names and implementations

@(deprecated="Use strconv.write_int() instead")
itoa :: proc(buf: []byte, i: int) -> string {
	return write_int(buf, i64(i), 10)
}

@(deprecated="Use strconv.parse_int() instead")
atoi :: proc(s: string) -> int {
	v, _ := parse_int(s)
	return v
}

@(deprecated="Use strconv.parse_f64() instead")
atof :: proc(s: string) -> f64 {
	v, _  := parse_f64(s)
	return v
}

@(deprecated="Use strconv.write_float() instead")
ftoa :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return string(generic_ftoa(buf, f, fmt, prec, bit_size))
}