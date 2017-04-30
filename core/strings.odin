new_c_string :: proc(s: string) -> ^byte {
	c := make([]byte, len(s)+1);
	copy(c, []byte(s));
	c[len(s)] = 0;
	return &c[0];
}

to_odin_string :: proc(c: ^byte) -> string {
	len := 0;
	for (c+len)^ != 0 {
		len++;
	}
	return string(slice_ptr(c, len));
}
