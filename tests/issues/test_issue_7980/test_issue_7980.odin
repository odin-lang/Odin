// Tests https://github.com/odin-lang/Odin/issues/7980.
// Expected: missing self and the later type error, without a compiler assertion.
package test_issue_7980

import "base:intrinsics"

foreign import lib "system:Foundation.framework"

@(objc_class="NSObject")
Object :: struct {using _: intrinsics.objc_object}

foreign lib {
	@(objc_type=Object, objc_selector="hash", objc_name="hash")
	Object_hash :: proc(self: ^Object) -> uint ---
}

main :: proc() {
	object: ^Object
	_ = object->hash()
	_ = object.hash(object)

	value := object.hash()
	#assert(type_of(value) == uint)

	type_error: u32 = u64(12)
	_ = type_error
}
