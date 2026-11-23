package test_paths_tempfiles

import "helper"

@(export)
tempfiles_sum :: proc "c" () -> int {
	return helper.value() + 2
}

main :: proc() {
	assert(tempfiles_sum() == 3)
}
