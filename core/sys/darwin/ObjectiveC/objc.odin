// Bindings for the [[ Objective-C runtime ; https://developer.apple.com/documentation/objectivec/objective-c-runtime ]].
#+build darwin
package darwin_ObjectiveC

import "base:intrinsics"
import "core:c"

foreign import lib "system:objc"

id    :: ^intrinsics.objc_object
SEL   :: ^intrinsics.objc_selector
Class :: ^intrinsics.objc_class
IMP   :: proc "c" (object: id, sel: SEL, #c_vararg args: ..any) -> id
BOOL  :: bool

@(objc_class="Protocol")
Protocol :: struct {using _: intrinsics.objc_object}

Method :: ^objc_method
objc_method :: struct {
	method_name:  SEL,
	method_types: cstring,
	method_imp:   IMP,
}
objc_method_list :: struct {}

objc_property   :: struct {}
objc_property_t :: ^objc_property

objc_property_attribute_t :: struct {
	name:  cstring,
	value: cstring,
}

objc_ivar :: struct {}
Ivar      :: ^objc_ivar

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

// The receiver and the class at which to start searching for a method implementation, for `objc_msgSendSuper`.
objc_super :: struct {
	receiver:    id,
	super_class: Class,
}

objc_AssociationPolicy :: enum c.uintptr_t {
	Assign           = 0,
	Retain_Nonatomic = 1,
	Copy_Nonatomic   = 3,
	Retain           = 0o1401,
	Copy             = 0o1403,
}

@(default_calling_convention="c")
foreign lib {
	objc_getClass                 :: proc(name: cstring) -> Class ---
	objc_getMetaClass             :: proc(name: cstring) -> id ---
	objc_lookUpClass              :: proc(name: cstring) -> Class ---
	objc_allocateClassPair        :: proc(superclass: Class, name: cstring, extraBytes: c.size_t) -> Class ---
	objc_registerClassPair        :: proc(cls: Class) ---
	objc_disposeClassPair         :: proc(cls: Class) ---
	objc_duplicateClass           :: proc(original: Class, name: cstring, extraBytes: c.size_t) -> Class ---
	objc_getProtocol              :: proc(name: cstring) -> ^Protocol ---
	objc_copyProtocolList         :: proc(outCount: ^c.uint) -> [^]^Protocol ---
	objc_constructInstance        :: proc(cls: Class, bytes: rawptr) -> id ---
	objc_destructInstance         :: proc(obj: id) -> rawptr ---
	objc_getClassList             :: proc(buffer: [^]Class, bufferCount: c.int) -> c.int ---
	objc_copyClassList            :: proc(outCount: ^c.uint) -> [^]Class ---
	objc_getRequiredClass         :: proc(name: cstring) -> Class ---
	objc_setAssociatedObject      :: proc(object: id, key: rawptr, value: id, policy: objc_AssociationPolicy) ---
	objc_getAssociatedObject      :: proc(object: id, key: rawptr) -> id ---
	objc_removeAssociatedObjects  :: proc(object: id) ---
	objc_msgSendSuper             :: proc(super: ^objc_super, op: SEL, #c_vararg args: ..any) -> id ---
	objc_msgSendSuper2            :: proc(super: ^objc_super, op: SEL, #c_vararg args: ..any) -> id ---

	sel_registerName              :: proc(name: cstring) -> SEL ---
	sel_getName                   :: proc(sel: SEL) -> cstring ---
	sel_isEqual                   :: proc(lhs, rhs: SEL) -> BOOL ---

	class_addMethod               :: proc(cls: Class, name: SEL, imp: IMP, types: cstring) -> BOOL ---
	class_getInstanceMethod       :: proc(cls: Class, name: SEL) -> Method ---
	class_getClassMethod          :: proc(cls: Class, name: SEL) -> Method ---
	class_copyMethodList          :: proc(cls: Class, outCount: ^c.uint) -> [^]Method ---
	class_createInstance          :: proc(cls: Class, extraBytes: c.size_t) -> id ---
	class_replaceMethod           :: proc(cls: Class, name: SEL, imp: IMP, types: cstring) -> IMP ---
	class_getMethodImplementation :: proc(cls: Class, name: SEL) -> IMP ---
	class_getSuperclass           :: proc(cls: Class) -> Class ---
	class_getName                 :: proc(cls: Class) -> cstring ---
	class_isMetaClass             :: proc(cls: Class) -> BOOL ---
	class_addProtocol             :: proc(cls: Class, protocol: ^Protocol) -> BOOL ---
	class_getVersion              :: proc(cls: Class) -> c.int ---
	class_setVersion              :: proc(cls: Class, version: c.int) ---
	class_getProperty             :: proc(cls: Class, name: cstring) -> objc_property_t ---
	class_addProperty             :: proc(cls: Class, name: cstring, attributes: [^]objc_property_attribute_t, attributeCount: c.uint) -> BOOL ---
	class_replaceProperty         :: proc(cls: Class, name: cstring, attributes: [^]objc_property_attribute_t, attributeCount: c.uint) ---
	class_copyPropertyList        :: proc(cls: Class, outCount: ^c.uint) -> [^]objc_property_t ---
	class_conformsToProtocol      :: proc(cls: Class, protocol: ^Protocol) -> BOOL ---
	class_copyProtocolList        :: proc(cls: Class, outCount: ^c.uint) -> [^]^Protocol ---
	class_respondsToSelector      :: proc(cls: Class, sel: SEL) -> BOOL ---
	class_getClassVariable        :: proc(cls: Class, name: cstring) -> Ivar ---
	class_getInstanceVariable     :: proc(cls: Class, name: cstring) -> Ivar ---
	class_addIvar                 :: proc(cls: Class, name: cstring, size: c.size_t, alignment: u8, types: cstring) -> BOOL ---
	class_copyIvarList            :: proc(cls: Class, outCount: ^c.uint) -> [^]Ivar ---
	class_getInstanceSize         :: proc(cls: Class) -> c.size_t ---

	property_getName              :: proc(property: objc_property_t) -> cstring ---
	property_getAttributes        :: proc(property: objc_property_t) -> cstring ---
	property_copyAttributeList    :: proc(property: objc_property_t, outCount: ^c.uint) -> [^]objc_property_attribute_t ---
	property_copyAttributeValue   :: proc(property: objc_property_t, attributeName: cstring) -> cstring ---

	protocol_conformsToProtocol   :: proc(proto: ^Protocol, other: ^Protocol) -> BOOL ---
	protocol_isEqual              :: proc(proto: ^Protocol, other: ^Protocol) -> BOOL ---
	protocol_getName              :: proc(proto: ^Protocol) -> cstring ---

	method_getName                :: proc(m: Method) -> SEL ---
	method_getImplementation      :: proc(m: Method) -> IMP ---
	method_setImplementation      :: proc(m: Method, imp: IMP) -> IMP ---
	method_getTypeEncoding        :: proc(m: Method) -> cstring ---
	method_copyArgumentType       :: proc(m: Method, index: c.uint) -> cstring ---
	method_copyReturnType         :: proc(m: Method) -> cstring ---
	method_getReturnType          :: proc(m: Method, dst: [^]byte, dst_len: c.size_t) ---
	method_getNumberOfArguments   :: proc(m: Method) -> c.uint ---
	method_getArgumentType        :: proc(m: Method, index: c.uint, dst: [^]byte, dst_len: c.size_t) ---

	object_getClass               :: proc(obj: id) -> Class ---
	object_setClass               :: proc(obj: id, cls: Class) -> Class ---
	object_copy                   :: proc(obj: id, size: c.size_t) -> id ---
	object_dispose                :: proc(obj: id) -> id ---
	object_getClassName           :: proc(obj: id) -> cstring ---
	object_getIndexedIvars        :: proc(obj: id) -> rawptr ---
	object_getInstanceVariable    :: proc(obj: id, name: cstring, outValue: ^rawptr) -> Ivar ---
	object_setInstanceVariable    :: proc(obj: id, name: cstring, value: rawptr) -> Ivar ---
	object_getIvar                :: proc(obj: id, ivar: Ivar) -> id ---
	object_setIvar                :: proc(obj: id, ivar: Ivar, value: id) ---

	ivar_getName                  :: proc(v: Ivar) -> cstring ---
	ivar_getTypeEncoding          :: proc(v: Ivar) -> cstring ---
	ivar_getOffset                :: proc(v: Ivar) -> c.ptrdiff_t ---
}
