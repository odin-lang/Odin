// #soa arrays work with -no-rtti: the runtime takes their field sizes from `intrinsics.type_soa_field_sizes`, not from type info
package test_issue_soa_no_rtti

import "base:runtime"

Particle :: struct {
	pos: [3]f32,
	age: i32,
}

@(export)
soa_no_rtti :: proc "contextless" (allocator: runtime.Allocator) -> int {
	context = {}
	context.allocator = allocator

	ps := make(#soa[dynamic]Particle)
	defer delete(ps)
	append(&ps, Particle{{1, 2, 3}, 4})
	inject_at_soa(&ps, 0, Particle{{5, 6, 7}, 8})
	resize(&ps, 8)
	ordered_remove_soa(&ps, 1)

	lanes := make(#soa[][4]f32, 16)
	defer delete(lanes)
	lanes[3] = {1, 2, 3, 4}

	fixed: #soa[dynamic; 8]Particle
	append(&fixed, Particle{{1, 2, 3}, 4})
	inject_at(&fixed, 0, Particle{{5, 6, 7}, 8})
	resize(&fixed, 4)
	ordered_remove(&fixed, 1)

	aos: [4]Particle
	n := copy(ps[:], fixed[:])
	n += copy(aos[:], ps[:])
	n += copy(ps[:], aos[:])

	quads: [16][4]f32
	n += copy(lanes, quads[:])
	n += copy(quads[:], lanes)

	return len(ps) + len(lanes) + len(fixed) + n
}
