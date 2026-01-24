// Tests issue #6165 https://github.com/odin-lang/Odin/issues/6165
package test_issues

import "core:testing"

@(test)
test_issue_6165 :: proc(t: ^testing.T) {
	TXT :: #load(ODIN_ROOT + "LICENSE")

	// We don't really care about the length. The test is whether this compiles, or
	// if the compiler says it can't find the file we know to exist.
	assert(len(TXT) > 0)
}