// Tests issue https://github.com/odin-lang/Odin/issues/6979
package test_issue_6979

error :: proc() -> typeid {
	data :: struct{type: typeid}{int}
	return data.type
}
