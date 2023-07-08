// Tests issue #2637 https://github.com/odin-lang/Odin/issues/2637
package test_issues

import "core:testing"

Foo :: Maybe(string)

@(test)
test_expect_value_succeeds_with_nil :: proc(t: ^testing.T) {
  x: Foo
  testing.expect(t, x == nil) // Succeeds
  testing.expect_value(t, x, nil) // Fails, "expected nil, got nil"
}
