// Tests issue #7700 https://github.com/odin-lang/Odin/issues/7700
// A field of a constant `#soa` array is the array of that field of each element
package test_issues

import "base:intrinsics"
import "core:fmt"
import "core:testing"

Field :: struct { name: string, type: typeid, n: int }

F1 :: Field{"x", int, 7}

STUFF  :: #soa[3]Field{{"i", i64, 1}, {"f", f64, 2}, {"p", rawptr, 3}}
NAMED  :: #soa[3]Field{{name = "a"}, {type = f32, n = 2}, {name = "c", type = bool}}
GAPS   :: #soa[4]Field{1 = {"b", u8, 1}, 3 = {"d", u16, 3}}
RANGES :: #soa[4]Field{0..<2 = {"r", i8, 5}, 3 = F1}
VECS   :: #soa[3][2]f32{{1, 2}, {3, 4}, {5, 6}}

Strings :: struct($strings: [3]string) {}
Types   :: struct($types: [3]typeid) {}

strings_proc :: proc($s: [3]string) -> [3]string { return s }
types_proc   :: proc($t: [3]typeid) -> [3]typeid { return t }

#assert(STUFF.name[1] == "f")
#assert(STUFF.n[2] == 3)
#assert(Types(STUFF.type) == Types([3]typeid{i64, f64, rawptr}))
#assert(Types([3]typeid{i64, f64, rawptr}) != Types([3]typeid{int, int, int}))

@(test)
test_issue_7700 :: proc(t: ^testing.T) {
	testing.expect_value(t, fmt.tprint(typeid_of(Strings(STUFF.name))), `Strings($strings={"i", "f", "p"})`)
	testing.expect_value(t, fmt.tprint(typeid_of(Types(STUFF.type))), `Types($types={i64, f64, rawptr})`)
	testing.expect_value(t, intrinsics.type_canonical_name(Strings(STUFF.name)), `test_issues::Strings(strings:$${"i","f","p"})`)
	testing.expect_value(t, intrinsics.type_canonical_name(Types(STUFF.type)), `test_issues::Types(types:$${i64,f64,rawptr})`)

	testing.expect_value(t, STUFF.name, [3]string{"i", "f", "p"})
	testing.expect_value(t, STUFF.type, [3]typeid{i64, f64, rawptr})
	testing.expect_value(t, STUFF.n, [3]int{1, 2, 3})
	testing.expect_value(t, strings_proc(STUFF.name), [3]string{"i", "f", "p"})
	testing.expect_value(t, types_proc(STUFF.type), [3]typeid{i64, f64, rawptr})

	testing.expect_value(t, NAMED.name, [3]string{"a", "", "c"})
	testing.expect_value(t, NAMED.type, [3]typeid{nil, f32, bool})
	testing.expect_value(t, NAMED.n, [3]int{0, 2, 0})

	testing.expect_value(t, GAPS.name, [4]string{"", "b", "", "d"})
	testing.expect_value(t, GAPS.type, [4]typeid{nil, u8, nil, u16})

	testing.expect_value(t, RANGES.name, [4]string{"r", "r", "", "x"})
	testing.expect_value(t, RANGES.n, [4]int{5, 5, 0, 7})

	testing.expect_value(t, VECS.x, [3]f32{1, 3, 5})
	testing.expect_value(t, VECS.y, [3]f32{2, 4, 6})
}
