package test_issue_4578

import "core:fmt"
import "core:testing"
import "pkg"

LOCAL :: 7

typed_conversion :: proc($T: typeid, x: T = T(3), y: T = cast(T)4) -> T {
	return x + y
}

untyped_conversion :: proc($T: typeid, x := T(3)) -> T {
	return x
}

constant_defaults :: proc(v: $T, y: T = 0, z: T = LOCAL, s := "s", p: ^T = nil) -> (T, string, bool) {
	return v + y + z, s, p == nil
}

literal_default :: proc($T: typeid, p := proc(x: T) -> T { return x + x }) -> T {
	return p(T(5))
}

typed_literal_default :: proc(num: $T, a: proc(num: T) -> bool, b: proc(num: T) -> bool = proc(num: T) -> bool { return num > 0 }) -> bool {
	return a(num) && b(num)
}

nil_default :: proc(num: $T, a: proc(num: T) -> bool, b: proc(num: T) -> bool = nil) -> bool {
	return a(num) && (b == nil || b(num))
}

constant_parameter :: proc($N: int, p: proc() -> int = proc() -> int { return 1 }) -> int {
	return N + p()
}

stringify :: proc(v: $T, p := proc(x: T) -> string { return fmt.tprint(x) }) -> string {
	return p(v)
}

@(test)
test_polymorphic_parameter_defaults :: proc(t: ^testing.T) {
	testing.expect_value(t, typed_conversion(int), 7)
	testing.expect_value(t, typed_conversion(f32, 0.5), 4.5)
	testing.expect_value(t, untyped_conversion(int), 3)
	testing.expect_value(t, untyped_conversion(f64), 3)

	n, s, is_nil := constant_defaults(1.5)
	testing.expect_value(t, n, 8.5)
	testing.expect_value(t, s, "s")
	testing.expect(t, is_nil)

	testing.expect_value(t, literal_default(int), 10)
	testing.expect_value(t, literal_default(f32), 10)
	testing.expect_value(t, literal_default(int, proc(x: int) -> int { return x }), 5)

	testing.expect(t, typed_literal_default(1, proc(num: int) -> bool { return num == 1 }))
	testing.expect(t, !typed_literal_default(f32(-1), proc(num: f32) -> bool { return true }))
	testing.expect(t, nil_default(0, proc(num: int) -> bool { return num == 0 }))

	testing.expect_value(t, constant_parameter(1), 2)
	testing.expect_value(t, constant_parameter(2), 3)

	testing.expect_value(t, stringify(3), "3")
	testing.expect_value(t, stringify("s"), "s")
	testing.expect_value(t, stringify(1.5), "1.5")
}

@(test)
test_polymorphic_parameter_defaults_across_packages :: proc(t: ^testing.T) {
	testing.expect_value(t, pkg.add(1), 43)
	testing.expect_value(t, pkg.add(0.5), 42.5)
	testing.expect_value(t, pkg.describe(1), "1 41")
	testing.expect_value(t, pkg.describe("s"), "s 41")
}
