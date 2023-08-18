// Tests issue https://github.com/odin-lang/Odin/issues/2666
// @(disabled=<boolean>) does not work with polymorphic procs
package test_issues

import "core:testing"

@(test)
test_disabled_parapoly :: proc(t: ^testing.T) {
	disabled_parapoly(t, 1)
	disabled_parapoly_constant(t, 1)
}

@(private="file")
@(disabled = true)
disabled_parapoly :: proc(t: ^testing.T, num: $T) {
	testing.error(t, "disabled_parapoly should be disabled")
}

@(private="file")
DISABLE :: true

@(disabled = DISABLE)
@(private = "file")
disabled_parapoly_constant :: proc(t: ^testing.T, num: $T) {
	testing.error(t, "disabled_parapoly_constant should be disabled")
}
