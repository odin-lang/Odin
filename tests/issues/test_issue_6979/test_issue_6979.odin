// Tests issue https://github.com/odin-lang/Odin/issues/6979
package test_issues

error :: proc() -> typeid {
	data :: struct{type: typeid}{int}
	return data.type
}
