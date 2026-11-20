package test_issue_7502_cycle

Array :: struct ($T: typeid, $N: int) where size_of(T) > 0, N > 0 {
	items: [N]T,
}

poly_where :: proc() {
	View :: struct {
		name: string,
		ctx:  ^Context,
	}

	Context :: struct {
		views: Array(View, 33),
	}
}

array_count :: proc() {
	View :: struct {
		name: string,
		ctx:  ^Context,
	}

	Context :: struct {
		buf: [size_of(View)]u8,
	}
}
