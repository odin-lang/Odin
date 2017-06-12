proc new_c_string(s: string) -> ^u8 {
	var c = make([]u8, len(s)+1);
	copy(c, []u8(s));
	c[len(s)] = 0;
	return &c[0];
}

proc to_odin_string(c: ^u8) -> string {
	var len = 0;
	for (c+len)^ != 0 {
		len++;
	}
	return string(slice_ptr(c, len));
}
