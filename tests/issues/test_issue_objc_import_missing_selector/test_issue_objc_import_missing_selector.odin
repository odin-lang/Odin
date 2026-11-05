// Imported Objective-C methods must have `@(objc_selector)`; a missing one used to fall back to `objc_name` silently.
// Expected: 1 error, for `Object_noSelector`.
package test_issue_objc_import_missing_selector

import "base:intrinsics"

foreign import lib "system:Foundation.framework"

@(objc_class="NSObject")
Object :: struct {using _: intrinsics.objc_object}

foreign lib {
	@(objc_type=Object, objc_name="noSelector")
	Object_noSelector :: proc(self: ^Object) -> ^Object ---

	@(objc_type=Object, objc_selector="description", objc_name="description")
	Object_description :: proc(self: ^Object) -> ^Object ---
}
