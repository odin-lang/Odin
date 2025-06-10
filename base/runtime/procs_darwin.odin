#+private
package runtime

@(priority_index=-1e6)
foreign import ObjC "system:objc"

import "base:intrinsics"

objc_id    :: ^intrinsics.objc_object
objc_Class :: ^intrinsics.objc_class
objc_SEL   :: ^intrinsics.objc_selector
objc_Ivar  :: ^intrinsics.objc_ivar
objc_BOOL  :: bool


objc_IMP :: proc "c" (object: objc_id, sel: objc_SEL, #c_vararg args: ..any) -> objc_id

foreign ObjC {
	sel_registerName :: proc "c" (name: cstring) -> objc_SEL ---

	objc_msgSend        :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) ---
	objc_msgSend_fpret  :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) -> f64 ---
	objc_msgSend_fp2ret :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) -> complex128 ---
	objc_msgSend_stret  :: proc "c" (self: objc_id, op: objc_SEL, #c_vararg args: ..any) ---

	objc_lookUpClass          :: proc "c" (name: cstring) -> objc_Class ---
	objc_allocateClassPair    :: proc "c" (superclass: objc_Class, name: cstring, extraBytes: uint) -> objc_Class ---
	objc_registerClassPair    :: proc "c" (cls : objc_Class) ---
	class_addMethod           :: proc "c" (cls: objc_Class, name: objc_SEL, imp: objc_IMP, types: cstring) -> objc_BOOL ---
	class_addIvar             :: proc "c" (cls: objc_Class, name: cstring, size: uint, alignment: u8, types: cstring) -> objc_BOOL ---
	class_getInstanceVariable :: proc "c" (cls : objc_Class, name: cstring) -> objc_Ivar ---
	class_getInstanceSize     :: proc "c" (cls : objc_Class) -> uint ---
	ivar_getOffset            :: proc "c" (v: objc_Ivar) -> uintptr ---
}

