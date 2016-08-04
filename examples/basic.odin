putchar :: proc(c : i32) -> i32 #foreign

print_string :: proc(s : string) {
	for i := 0; i < len(s); i++ {
		c := cast(i32)s[i];
		putchar(c);
	}
}
