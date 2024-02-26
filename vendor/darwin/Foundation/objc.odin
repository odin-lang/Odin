package objc_Foundation

foreign import "system:Foundation.framework"
// NOTE: Most of our bindings are reliant on Cocoa (everything under appkit) so just unconditionally import it
@(require) foreign import "system:Cocoa.framework"

import "base:intrinsics"
import "core:c"

IMP :: proc "c" (object: id, sel: SEL, #c_vararg args: ..any) -> id

foreign Foundation {
	objc_lookUpClass       :: proc "c" (name: cstring) -> Class ---
	sel_registerName       :: proc "c" (name: cstring) -> SEL ---
	objc_allocateClassPair :: proc "c" (superclass : Class, name : cstring, extraBytes : c.size_t) -> Class ---
	objc_registerClassPair :: proc "c" (cls : Class) ---

	class_addMethod         :: proc "c" (cls: Class, name: SEL, imp: IMP, types: cstring) -> BOOL ---
	class_getInstanceMethod :: proc "c" (cls: Class, name: SEL) -> Method ---
	class_createInstance    :: proc "c" (cls: Class, extraBytes: c.size_t) -> id ---

	method_setImplementation :: proc "c" (method: Method, imp: IMP) ---
	object_getIndexedIvars   :: proc(obj: id) -> rawptr ---
}


@(objc_class="NSZone")
Zone :: struct {using _: Object}

@(link_prefix="NS")
foreign Foundation {
	AllocateObject   :: proc "c" (aClass: Class, extraBytes: UInteger, zone: ^Zone) -> id ---
	DeallocateObject :: proc "c" (object: id) ---
}

Method :: ^objc_method
objc_method :: struct {
	method_name:  SEL,
	method_types: cstring,
	method_imp:   IMP,
}
objc_method_list :: struct {}

objc_ivar :: struct {}
objc_ivar_list :: struct {}

objc_cache :: struct {
	mask:     u32,
	occupied: u32,
	buckets:  [1]Method,
}

objc_protocol_list :: struct {
	next:  ^objc_protocol_list,
	count: c.int,
	list:  [1]^Protocol,
}

@(objc_class="Protocol")
Protocol :: struct{using _: intrinsics.objc_object}

objc_object_internals :: struct {
	isa: ^objc_class_internals,
}


objc_class_internals :: struct {
	isa:           Class,
	super_class:   Class,
	name:          cstring,
	version:       c.long,
	info:          c.long,
	instance_size: c.long,
	ivars:         ^objc_ivar_list,
	
	methodLists:   ^^objc_method_list,

	cache:         rawptr,
	protocols:     rawptr,

}
