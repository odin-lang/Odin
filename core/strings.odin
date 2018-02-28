import "core:mem.odin"

new_string :: proc(s: string) -> string {
	c := make([]byte, len(s)+1);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return string(c[..len(s)]);
}

new_cstring :: proc(s: string) -> cstring {
	c := make([]byte, len(s)+1);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return cstring(&c[0]);
}

to_odin_string :: proc(str: cstring) -> string {
	if str == nil do return "";
	return string(str);
}

contains_rune :: proc(s: string, r: rune) -> int {
	for c, offset in s {
		if c == r do return offset;
	}
	return -1;
}
