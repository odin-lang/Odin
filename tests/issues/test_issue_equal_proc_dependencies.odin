// The backend gives each comparable struct and union in the type table, and the key of each map, an equality
// procedure, so the runtime procedures it compares fields with must be dependencies however the type was reached
package test_issues

import "base:runtime"
import "core:fmt"
import "core:testing"

Quaternion :: distinct quaternion128

// only reached through type info, and recursive through its union
Entity :: struct {
	name:        string,
	orientation: Quaternion,
	small:       complex32,
	derived:     union {Frog},
}

Frog :: struct {
	entity: ^Entity,
	height: f32,
}

Key :: struct {
	name: string,
	q:    quaternion256,
}

Holder :: struct {
	m:    map[Key]int,
	next: ^Holder,
}

Variants :: union {complex128, quaternion64, cstring}

Wrapper :: struct {
	v: Variants,
}

struct_equal :: proc(ti: ^runtime.Type_Info) -> runtime.Equal_Proc {
	return runtime.type_info_base(ti).variant.(runtime.Type_Info_Struct).equal
}

@(test)
test_equal_procs_of_type_info :: proc(t: ^testing.T) {
	a := new(Entity)
	defer free(a)
	a.name = "frog"
	a.orientation = 1
	a.small = complex(f16(1), f16(2))
	a.derived = Frog{a, 1}
	s := fmt.tprint(a)
	testing.expect(t, len(s) > 0)

	b := new(Entity)
	defer free(b)
	b^ = a^

	entity_equal := struct_equal(runtime.type_info_base(type_info_of(^Entity)).variant.(runtime.Type_Info_Pointer).elem)
	testing.expect(t, entity_equal(a, b))
	b.small = complex(f16(1), f16(3))
	testing.expect(t, !entity_equal(a, b))
	b.small = a.small
	b.orientation = 2
	testing.expect(t, !entity_equal(a, b))

	h: ^Holder
	s = fmt.tprint(h)
	testing.expect(t, len(s) > 0)
	holder_info := runtime.type_info_base(type_info_of(^Holder)).variant.(runtime.Type_Info_Pointer).elem
	map_info := runtime.type_info_base(runtime.type_info_base(holder_info).variant.(runtime.Type_Info_Struct).types[0]).variant.(runtime.Type_Info_Map).map_info
	k1 := Key{"a", 1}
	k2 := Key{"a", 2}
	testing.expect(t, map_info.key_equal(&k1, &k1))
	testing.expect(t, !map_info.key_equal(&k1, &k2))

	w1 := Wrapper{quaternion64(1)}
	w2 := Wrapper{quaternion64(1)}
	s = fmt.tprint(&w1)
	testing.expect(t, len(s) > 0)
	wrapper_equal := struct_equal(runtime.type_info_base(type_info_of(^Wrapper)).variant.(runtime.Type_Info_Pointer).elem)
	testing.expect(t, wrapper_equal(&w1, &w2))
	w2.v = complex128(1)
	testing.expect(t, !wrapper_equal(&w1, &w2))
	w1.v = complex128(1)
	testing.expect(t, wrapper_equal(&w1, &w2))
}
