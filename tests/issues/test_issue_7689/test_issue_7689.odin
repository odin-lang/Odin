// Tests debug source locations in if-else chains.
//
// NOTE: This is an interactive, manual test.
//       Run it in the debugger and single-step through. Control flow
//       should make sense for any value of `x`.
package test_issue_7689

import "core:fmt"
import "core:os"

main :: proc() {
	x := len(os.args)+1 // runtime value so nothing is folded

	r: int
	if x == 1 {
		r = 1
	} else {
		if x == 2 {
			r = 2
		} else {
			if x == 3 {
				r = 3
			} else {
				if x == 4 {
					r = 4
				}
			}
		}
	}

	fmt.println(r)
}
