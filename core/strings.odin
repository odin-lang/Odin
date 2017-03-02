new_c_string :: proc(s: string) -> ^byte {
	c := new_slice(byte, s.count+1);
	copy(c, cast([]byte)s);
	c[s.count] = 0;
	return c.data;
}

to_odin_string :: proc(c: ^byte) -> string {
	s: string;
	s.data = c;
	for (c+s.count)^ != 0 {
		s.count++;
	}
	return s;
}
