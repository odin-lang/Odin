package test_core_container

import "core:container/xar"
import "core:testing"

@test
test_xar_pointer_stability :: proc(t: ^testing.T) {
	Value :: struct {
		v: int,
		p: ^int,
	}

	x: xar.Array(int, 4)
	defer xar.destroy(&x)

	values: [dynamic]Value
	defer delete(values)

	N :: 512
	for i in 1..=N {
		v := i * 10 + 1
		xar.push_back(&x, v)
		ptr := xar.get_ptr(&x, i - 1)
		append(&values, Value{v = v, p = ptr})
	}

	assert(xar.len(x) == N)
	assert(xar.cap(x) >= N)

	for value, i in values {
		ptr := xar.get_ptr(&x, i)
		assert(ptr == value.p)
		assert(ptr^ == value.v)
	}

	xar.clear(&x)
	assert(xar.len(x) == 0)
	assert(xar.cap(x) >= N)
}