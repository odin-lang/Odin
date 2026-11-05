// Tests issue #7783 https://github.com/odin-lang/Odin/issues/7783
// `-sanitize:address` must report an overflow of a global variable in a separate-module build
package test_issue_7783

global_table: [8]u8
index := 8

main :: proc() {
	p: [^]u8 = &global_table[0]
	p[index] = 1
}
