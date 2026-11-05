package test_issue_7986_lib

import common "../common"

@(export)
lib_counter :: proc "c" () -> int {
	return common.get()
}
