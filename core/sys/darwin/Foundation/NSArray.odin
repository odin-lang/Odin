package objc_Foundation

import "core:intrinsics"

@(objc_class="NSArray")
Array :: struct {
	using _: Copying(Array),
}

@(objc_type=Array, objc_class_name="alloc")
Array_alloc :: proc() -> ^Array {
	return msgSend(^Array, Array, "alloc")
}

@(objc_type=Array, objc_name="init")
Array_init :: proc(self: ^Array) -> ^Array {
	return msgSend(^Array, self, "init")
}

@(objc_type=Array, objc_name="initWithObjects")
Array_initWithObjects :: proc(self: ^Array, objects: [^]^Object, count: UInteger) -> ^Array {
	return msgSend(^Array, self, "initWithObjects:count:", objects, count)
}

@(objc_type=Array, objc_name="initWithCoder")
Array_initWithCoder :: proc(self: ^Array, coder: ^Coder) -> ^Array {
	return msgSend(^Array, self, "initWithCoder:", coder)
}

@(objc_type=Array, objc_name="object")
Array_object :: proc(self: ^Array, index: UInteger) -> ^Object {
	return msgSend(^Object, self, "objectAtIndex:", index)
}
@(objc_type=Array, objc_name="objectAs")
Array_objectAs :: proc(self: ^Array, index: UInteger, $T: typeid) -> T where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object)  {
	return (T)(Array_object(self, index))
}

@(objc_type=Array, objc_name="count")
Array_count :: proc(self: ^Array) -> UInteger {
	return msgSend(UInteger, self, "count")
}
