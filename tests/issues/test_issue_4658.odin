package issues

import "core:testing"

arr: [max(i64)]byte

@(test)
test_max_i64_array :: proc(t: ^testing.T) {
    testing.expect_value(t, arr[max(i64)-1], 0)
    arr[max(i64)-1] = 255
    testing.expect_value(t, arr[max(i64)-1], 255)
}