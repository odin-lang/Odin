// Tests issue #6782 https://github.com/odin-lang/Odin/issues/6782
package test_issues

import "core:testing"

EVAL :: false

@(private = "file")
@(disabled = !EVAL)
disabled_proc_kills_checks :: proc(x: DoesNotExist) {
    _ = missing_symbol()
}

@(test)
test_disabled_proc_kills_checks :: proc(t: ^testing.T) {
    disabled_proc_kills_checks(missing_symbol())
    testing.expect(t, true)
}
