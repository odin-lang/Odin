#+build amd64
package test_internal

import "core:testing"

@(private="file")
Big :: struct {
	a, b, c, d: int,
	tag:        u8,
}

@(private="file")
g_stash: ^Big

@(private="file")
write_stash_read :: #force_no_inline proc(v: Big) -> int {
	g_stash.a = 99
	return v.a
}

@(private="file")
asm_identity :: #force_inline proc "contextless" (p: rawptr) -> rawptr {
	identity :: asm(p: rawptr) -> (r: rawptr) {
		mov r, p
	}
	return identity(p)
}

// NOTE(bill): An address passed through inline asm escapes too, and the caller's copy is kept
@(test)
test_by_value_params_escape_through_asm :: proc(t: ^testing.T) {
	x := Big{a = 1}
	g_stash = (^Big)(asm_identity(&x))
	testing.expect_value(t, write_stash_read(x), 1)
	g_stash = nil
}
