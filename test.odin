package min_max_test

import "core:fmt"

main :: proc() {
	a: f32 = max(1)
	b: f32 = min(2)
    fmt.println(a, b)
}