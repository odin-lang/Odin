// A call within an expression whose value holds no pointers still stores what it stores;
// each warning is next to a case which must stay quiet
package test_issues

Holder :: struct {
	p: ^int,
}

put :: proc(h: ^Holder, p: ^int) -> int {
	h.p = p
	return 0
}

in_binary :: proc() -> Holder {
	b := 1
	h: Holder
	n := 1 + put(&h, &b)
	_ = n
	return h // warning
}

in_lhs_index :: proc() -> Holder {
	arr: [4]int
	b := 1
	h: Holder
	arr[put(&h, &b)] = 1
	return h // warning
}

in_condition :: proc() -> Holder {
	b := 1
	h: Holder
	if put(&h, &b) != 0 {
		return {}
	}
	return h // warning
}

in_cast :: proc() -> Holder {
	b := 1
	h: Holder
	n := f64(put(&h, &b)) * 2
	_ = n
	return h // warning
}

in_ternary :: proc(c: bool) -> Holder {
	b := 1
	h: Holder
	n := c ? 0 : -put(&h, &b)
	_ = n
	return h // warning
}

global_holder: Holder

// The summary of a procedure keeps what a nested call stores, so its callers see it
forwards :: proc(h: ^Holder, p: ^int) -> bool {
	return put(h, p) == 0
}

through_summary :: proc() {
	b := 1
	_ = forwards(&global_holder, &b) // warning
}

// Quiet: only what the caller gave is stored
stores_callers :: proc(h: ^Holder, p: ^int) -> int {
	return 1 + put(h, p)
}
