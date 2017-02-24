new_c_string :: proc(s: string) -> ^byte {
	c := new_c_string(byte, s.count+1);
	copy(c, cast([]byte)s);
	c[s.count] = 0;
	return c;
}

to_odin_string :: proc(c: ^byte) -> string {
	s: string;
	s.data = c;
	for (c+s.count)^ != 0 {
		s.count += 1;
	}
	return s;
}
