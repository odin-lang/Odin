import "core:mem.odin"

new_string :: proc(s: string) -> string {
	c := make([]byte, len(s)+1);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return string(c[..len(s)]);
}

new_c_string :: proc(s: string) -> ^byte {
	c := make([]byte, len(s)+1);
	copy(c, cast([]byte)s);
	c[len(s)] = 0;
	return &c[0];
}

to_odin_string :: proc(str: ^byte) -> string {
	if str == nil do return "";
	end := str;
	for end^ != 0 do end+=1;
	return string(mem.slice_ptr(str, end-str));
}

contains_rune :: proc(s: string, r: rune) -> int {
	for c, offset in s {
		if c == r do return offset;
	}
	return -1;
}
