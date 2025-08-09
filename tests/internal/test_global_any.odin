package test_internal

@(private="file")
global_any_from_proc: any = from_proc()

from_proc :: proc "contextless" () -> f32 {
	return 1.1
}

@(private="file")
global_any: any = 1

import "core:testing"

@(test)
test_global_any :: proc(t: ^testing.T) {
	as_f32, is_f32 := global_any_from_proc.(f32)
	testing.expect(t, is_f32 == true)
	testing.expect(t, as_f32 == 1.1)

	as_int, is_int := global_any.(int)
	testing.expect(t, is_int == true)
	testing.expect(t, as_int == 1)
}

@(test)
test_static_any :: proc(t: ^testing.T) {
	@(static)
	var: any = 3

	as_int, is_int := var.(int)
	testing.expect(t, is_int == true)
	testing.expect(t, as_int == 3)

	var = f32(1.1)

	as_f32, is_f32 := var.(f32)
	testing.expect(t, is_f32 == true)
	testing.expect(t, as_f32 == 1.1)
}
