package objc_Foundation

import "base:intrinsics"

@(objc_class="NSArray")
Array :: struct {
	using _: Copying(Array),
}

@(objc_type=Array, objc_name="alloc", objc_is_class_method=true)
Array_alloc :: proc "c" () -> ^Array {
	return msgSend(^Array, Array, "alloc")
}

@(objc_type=Array, objc_name="init")
Array_init :: proc "c" (self: ^Array) -> ^Array {
	return msgSend(^Array, self, "init")
}

@(objc_type=Array, objc_name="initWithObjects")
Array_initWithObjects :: proc "c" (self: ^Array, objects: [^]^Object, count: UInteger) -> ^Array {
	return msgSend(^Array, self, "initWithObjects:count:", objects, count)
}

@(objc_type=Array, objc_name="initWithCoder")
Array_initWithCoder :: proc "c" (self: ^Array, coder: ^Coder) -> ^Array {
	return msgSend(^Array, self, "initWithCoder:", coder)
}

@(objc_type=Array, objc_name="object")
Array_object :: proc "c" (self: ^Array, index: UInteger) -> ^Object {
	return msgSend(^Object, self, "objectAtIndex:", index)
}
@(objc_type=Array, objc_name="objectAs")
Array_objectAs :: proc "c" (self: ^Array, index: UInteger, $T: typeid) -> T where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object)  {
	return (T)(Array_object(self, index))
}

@(objc_type=Array, objc_name="count")
Array_count :: proc "c" (self: ^Array) -> UInteger {
	return msgSend(UInteger, self, "count")
}
