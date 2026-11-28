package test_internal

import "core:testing"
import "test_custom_linkage"

// A `weak` or `link_once` procedure defined in another package links and runs from here.
// The definition is `weak`, not `extern_weak`, which only a declaration may have.
@(test)
test_custom_linkage_across_packages :: proc(t: ^testing.T) {
	testing.expect_value(t, test_custom_linkage.weak_proc(1), 2)
	testing.expect_value(t, test_custom_linkage.link_once_proc(1), 3)
	testing.expect_value(t, test_custom_linkage.weak_var, 5)
}
