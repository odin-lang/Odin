package test_issue_8102

import "core:testing"
import "pkg"

@(export)
issue_8102_local :: proc() -> i32 {
	return 1
}

local_alias :: issue_8102_local
imported_alias :: pkg.issue_8102_imported

@(test)
test_alias_of_exported_procedure :: proc(t: ^testing.T) {
	testing.expect_value(t, local_alias(), 1)
	testing.expect_value(t, imported_alias(), 2)
}
