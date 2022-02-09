package objc_Foundation

import "core:intrinsics"

@(objc_class="NSArray")
Array :: struct($T: typeid) where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	using _: Copying(Array(T)),
}

Array_initWithObjects :: proc(self: ^$A/Array($T), objects: [^]^Object, count: UInteger) -> ^A {
	return msgSend(^A, "initWithObjects:count:", objects, count)
}

Array_initWithCoder :: proc(self: ^$A/Array($T), coder: ^Coder) -> ^A {
	return msgSend(^A, "initWithCoder:", coder)
}

Array_objectAtIndex :: proc(self: ^Array($T), index: UInteger) -> ^Object {
	return msgSend(^Object, self, "objectAtIndex:", index)
}

Array_object :: proc(self: ^Array($T), index: UInteger) -> ^T {
	return (^T)(Array_objectAtIndex(self, index))
}

Array_count :: proc(self: ^Array($T)) -> UInteger {
	return msgSend(UInteger, self, "count")
}
