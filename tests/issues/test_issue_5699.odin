// Tests issue #5699 https://github.com/odin-lang/Odin/issues/5699
package test_issues

import "core:testing"

Issue5699_Value :: struct {
    value: i32,
}

Issue5699_Result :: union {
    Issue5699_Value,
}

test_issue_5699_increment_union :: proc(counter: ^i32) -> Issue5699_Result {
    counter^ += 1
    return Issue5699_Value{0}
}

@test
test_issue_5699_union :: proc(t: ^testing.T) {
    counter: i32 = 0
    _ = test_issue_5699_increment_union(&counter).(Issue5699_Value).value
    testing.expectf(t, counter == 1, "\n\texpected: 1\n\tgot:      %d", counter)
}

test_issue_5699_increment_any :: proc(counter: ^i32) -> any {
    counter^ += 1
    return Issue5699_Value{0}
}

@test
test_issue_5699_any :: proc(t: ^testing.T) {
    counter: i32 = 0
    _ = test_issue_5699_increment_any(&counter).(Issue5699_Value).value
    testing.expectf(t, counter == 1, "\n\texpected: 1\n\tgot:      %d", counter)
}
