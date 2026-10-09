// `intrinsics.procedure_of` of a polymorphic call: procedures without results, any calling convention,
// and the specialized procedure is a concrete value usable through `type_of`
package test_issues

import "base:intrinsics"
import "core:fmt"
import "core:testing"

without_return :: proc "contextless" ($i: int) {}
without_return_1 :: intrinsics.procedure_of(without_return(1))

with_return :: proc "contextless" ($i: int) -> int { return i }
with_return_1 :: intrinsics.procedure_of(with_return(1))
with_return_1_type :: type_of(with_return_1)

contextfull :: proc($i: int) -> int { return i }
global_contextfull_1 :: intrinsics.procedure_of(contextfull(1))

double :: proc(x: $T) -> T { return x * 2 }
double_int :: intrinsics.procedure_of(double(int(0)))
double_f32 :: intrinsics.procedure_of(double(f32(0)))

Holder :: struct {
	f: type_of(double_int),
	g: [2]type_of(double_f32),
}

@(test)
test_procedure_of_specialized :: proc(t: ^testing.T) {
	main_contextfull_2 :: intrinsics.procedure_of(contextfull(2))

	without_return_1()
	testing.expect_value(t, with_return_1(), 1)
	testing.expect_value(t, global_contextfull_1(), 1)
	testing.expect_value(t, main_contextfull_2(), 2)

	f: with_return_1_type = with_return_1
	testing.expect_value(t, f(), 1)

	g := double_int
	testing.expect_value(t, g(21), 42)
	testing.expect(t, type_of(double_int) != type_of(double_f32))

	h := Holder{double_int, {double_f32, double_f32}}
	testing.expect_value(t, h.f(4), 8)
	testing.expect_value(t, h.g[1](1.5), 3)

	fs: [dynamic]type_of(double_int)
	defer delete(fs)
	append(&fs, double_int)
	testing.expect_value(t, fs[0](5), 10)

	testing.expect_value(t, fmt.tprint(typeid_of(type_of(double_int))), "proc(int) -> int")
	testing.expect(t, fmt.tprint(double_int) != "")
}
