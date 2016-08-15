putchar :: proc(c: i32) -> i32 #foreign

heap_alloc  :: proc(sz: int) -> rawptr #foreign "malloc"
heap_free   :: proc(ptr: rawptr)       #foreign "free"

mem_compare :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memcmp"
mem_copy    :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memcpy"
mem_move    :: proc(dst, src : rawptr, len: int) -> i32 #foreign "memmove"

debug_trap :: proc() #foreign "llvm.debugtrap"


__string_eq :: proc(a, b : string) -> bool {
	if len(a) != len(b) {
		return false;
	}
	if ^a[0] == ^b[0] {
		return true;
	}
	return mem_compare(^a[0], ^b[0], len(a)) == 0;
}

__string_ne :: proc(a, b : string) -> bool {
	return !__string_eq(a, b);
}

__string_cmp :: proc(a, b : string) -> int {
	min_len := len(a);
	if len(b) < min_len {
		min_len = len(b);
	}
	for i := 0; i < min_len; i++ {
		x := a[i];
		y := b[i];
		if x < y {
			return -1;
		} else if x > y {
			return +1;
		}
	}
	if len(a) < len(b) {
		return -1;
	} else if len(a) > len(b) {
		return +1;
	}
	return 0;
}

__string_lt :: proc(a, b : string) -> bool { return __string_cmp(a, b) < 0; }
__string_gt :: proc(a, b : string) -> bool { return __string_cmp(a, b) > 0; }
__string_le :: proc(a, b : string) -> bool { return __string_cmp(a, b) <= 0; }
__string_ge :: proc(a, b : string) -> bool { return __string_cmp(a, b) >= 0; }
