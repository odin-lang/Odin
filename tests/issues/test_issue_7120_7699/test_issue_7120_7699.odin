package test_issue_7120_7699

import "core:testing"

Second :: struct($N: int) where N > 0 {
	floats: [N]f32,
}

First :: struct($N: int) {
	second: Second(N),
}

first_create :: proc($N: int) -> First(N) {
	f := First(N){}
	return f
}

Positive :: union($N: int) where N > 0 {
	[N]int,
	f32,
}

make_positive :: proc($N: int) -> Positive(N) {
	return [N]int{}
}

True  :: distinct struct{}
False :: distinct struct{}

Check :: struct(B: bool) {
	v: (True when (B == true) else False),
}

check :: proc($N: int) -> (v: Check(0 < N)) {
	return
}

@(test)
test_where_clause_in_generic_result :: proc(t: ^testing.T) {
	f := first_create(10)
	testing.expect_value(t, len(f.second.floats), 10)

	p := make_positive(3)
	_, ok := p.([3]int)
	testing.expect(t, ok)
}

@(test)
test_constant_expression_in_generic_result :: proc(t: ^testing.T) {
	testing.expect_value(t, typeid_of(type_of(check(100).v)), True)
	testing.expect_value(t, typeid_of(type_of(check(-1).v)), False)
}
