package test_issue_objc_class_method_calls_pkg

import "base:intrinsics"

foreign import lib "system:Foundation.framework"

@(objc_class="NSString")
String :: struct {using _: intrinsics.objc_object}

@(objc_class="NSMutableString", objc_superclass=String)
MutableString :: struct {using _: String}

foreign lib {
	@(objc_type=String, objc_selector="string", objc_name="make", objc_is_class_method=true)
	String_make :: proc() -> intrinsics.objc_instancetype ---
}

make_string :: proc() -> ^String {
	// `Type_method()` within the package used to give `String` rather than `^String`
	s := String_make()
	#assert(type_of(s) == ^String)
	return s
}
