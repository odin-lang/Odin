package test_internal

import "core:testing"

@(private="file")
Big :: struct { a: [16]int }

@(private="file", align=4096) g_page: [64]u8
@(private="file", align=128)  g_a, g_b: int
@(private="file", align=64)   g_init := Big{a = {0 = 1, 15 = 2}}
@(private="file", align=32, thread_local) g_tls: int

@(private="file")
is_aligned :: proc(p: rawptr, align: uintptr) -> bool {
	return uintptr(p) % align == 0
}

@(private="file")
make_big :: proc() -> Big {
	b: Big
	for &x, i in b.a { x = i }
	return b
}

// `x` is returned, which must not place it in the caller's return slot
@(private="file")
returned_local :: proc(t: ^testing.T) -> Big {
	@(align=256) x := make_big()
	testing.expect(t, is_aligned(&x, 256))
	return x
}

@(private="file")
generic_local :: proc(t: ^testing.T, $T: typeid) {
	@(align=max(64, align_of(T))) x: T
	testing.expect(t, is_aligned(&x, max(64, align_of(T))))
}

@test
test_variable_align :: proc(t: ^testing.T) {
	testing.expect(t, is_aligned(&g_page, 4096))
	testing.expect(t, is_aligned(&g_a, 128))
	testing.expect(t, is_aligned(&g_b, 128))
	testing.expect(t, is_aligned(&g_init, 64))
	testing.expect(t, g_init.a[0] == 1 && g_init.a[15] == 2)
	testing.expect(t, is_aligned(&g_tls, 32))

	@(align=512) x: int
	testing.expect(t, is_aligned(&x, 512))

	@(align=1024) lit := Big{a = {0 = 1, 1 = 2, 2 = 3}}
	testing.expect(t, is_aligned(&lit, 1024))
	testing.expect(t, lit.a[2] == 3)

	// a slice literal's own storage would otherwise be reused for `sl`
	@(align=256) sl := []int{1, 2, 3}
	testing.expect(t, is_aligned(&sl, 256))
	testing.expect(t, len(sl) == 3 && sl[2] == 3)

	@(align=64) a, b := 1, 2
	testing.expect(t, is_aligned(&a, 64))
	testing.expect(t, is_aligned(&b, 64))

	@(static, align=256) s: int
	testing.expect(t, is_aligned(&s, 256))
	@(thread_local, align=128) tl: int
	testing.expect(t, is_aligned(&tl, 128))

	r := returned_local(t)
	testing.expect(t, r.a[15] == 15)

	generic_local(t, u8)
	generic_local(t, #simd[32]f32)
}
