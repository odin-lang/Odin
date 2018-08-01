package strings

import "core:mem"

new_string :: proc(s: string) -> string {
	c := make([]byte, len(s)+1);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return string(c[:len(s)]);
}

new_cstring :: proc(s: string) -> cstring {
	c := make([]byte, len(s)+1);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return cstring(&c[0]);
}

@(deprecated="Please use a standard cast for cstring to string")
to_odin_string :: proc(str: cstring) -> string {
	return string(str);
}

string_from_ptr :: proc(ptr: ^byte, len: int) -> string {
	return transmute(string)mem.Raw_String{ptr, len};
}

contains_rune :: proc(s: string, r: rune) -> int {
	for c, offset in s {
		if c == r do return offset;
	}
	return -1;
}
