// Tests issue #7167 https://github.com/odin-lang/Odin/issues/7167
package test_issue_7167

import "core:fmt"
import "core:path/filepath"

main :: proc() {
	fmt.printf(filepath.join({}))
}
