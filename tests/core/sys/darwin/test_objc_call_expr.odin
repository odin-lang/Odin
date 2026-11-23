#+build darwin
package test_core_sys_darwin

import "core:testing"
import _NS "core:sys/darwin/Foundation"
import NS "vendor:darwin/AppKit"

/*
This test comes from a compiler bug where `_NS.String.alloc()`, the expression part of the selector-call expression
`_NS.String.alloc()->initWithBytes(...)` below, was converted into a field-value AST node, causing an assertion failure
in the Obj-C call expression checking code: https://github.com/odin-lang/Odin/pull/8396
*/
@(test)
test_objc_call_expr :: proc(t: ^testing.T) {
	str := "str"
	ns_str := _NS.String.alloc()->initWithBytes(
		bytes    = raw_data(str),
		len      = NS.UInteger(len(str)),
		encoding = _NS.UTF8StringEncoding)
	testing.expect_value(t, NS.UInteger(len(str)), ns_str->length())
}
