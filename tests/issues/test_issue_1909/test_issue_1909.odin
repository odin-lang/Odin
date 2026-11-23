package test_issue_1909

import "base:intrinsics"

main :: proc() {
	a: any = type_of(len)
	b := type_of(abs)
	c := intrinsics.atomic_type_is_lock_free(len)
	_, _, _ = a, b, c
}
