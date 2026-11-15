// Tests issue #7564: #location in a global variable caused a backend crash when read.
// https://github.com/odin-lang/Odin/issues/7564
package test_issue_7564

main_symbol := #location(main)

main :: proc() {
	symbol := main_symbol
	assert(symbol == main_symbol)
}
