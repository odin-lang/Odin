#+private
package runtime

foreign import "system:Foundation.framework"

import "base:intrinsics"

objc_id :: ^intrinsics.objc_object
objc_Class :: ^intrinsics.objc_class
objc_SEL :: ^intrinsics.objc_selector

foreign Foundation {
	objc_lookUpClass :: proc "c" (name: cstring) -> objc_Class ---
	sel_registerName :: proc "c" (name: cstring) -> objc_SEL ---
	objc_allocateClassPair :: proc "c" (superclass: objc_Class, name: cstring, extraBytes: uint) -> objc_Class ---

	objc_msgSend        :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) ---
	objc_msgSend_fpret  :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) -> f64 ---
	objc_msgSend_fp2ret :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) -> complex128 ---
	objc_msgSend_stret  :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) ---
}
