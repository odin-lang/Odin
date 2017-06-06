new_c_string :: proc(s: string) -> ^u8 {
	c := make([]u8, len(s)+1);
	copy(c, []u8(s));
	c[len(s)] = 0;
	return &c[0];
}

to_odin_string :: proc(c: ^u8) -> string {
	len := 0;
	for (c+len)^ != 0 {
		len++;
	}
	return string(slice_ptr(c, len));
}
