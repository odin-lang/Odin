package test_core_image

import "core:strings"
import "core:testing"

@test
test_index_any_small_string_not_found :: proc(t: ^testing.T) {
    index := strings.index_any(".", "/:\"")
    testing.log(t, index)
    testing.expect(t, index == -1, "index_any should be negative")
}

@test
test_index_any_larger_string_not_found :: proc(t: ^testing.T) {
    index := strings.index_any("aaaaaaaa.aaaaaaaa", "/:\"")
    testing.expect(t, index == -1, "index_any should be negative")
}

@test
test_index_any_small_string_found :: proc(t: ^testing.T) {
    index := strings.index_any(".", "/:.\"")
    testing.expect(t, index == 0, "index_any should be 0")
}

@test
test_index_any_larger_string_found :: proc(t: ^testing.T) {
    index := strings.index_any("aaaaaaaa:aaaaaaaa", "/:\"")
    testing.expect(t, index == 8, "index_any should be 8")
}
