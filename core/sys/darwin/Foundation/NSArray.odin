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


@(objc_class="NSMutableArray")
MutableArray :: struct {
	using _: Copying(MutableArray),
}

@(objc_type=MutableArray, objc_name="alloc", objc_is_class_method=true)
MutableArray_alloc :: proc "c" () -> ^MutableArray {
	return msgSend(^MutableArray, MutableArray, "alloc")
}

@(objc_type=MutableArray, objc_name="init")
MutableArray_init :: proc "c" (self: ^MutableArray) -> ^MutableArray {
	return msgSend(^MutableArray, self, "init")
}

@(objc_type=MutableArray, objc_name="initWithObjects")
MutableArray_initWithObjects :: proc "c" (self: ^MutableArray, objects: [^]^Object, count: UInteger) -> ^MutableArray {
	return msgSend(^MutableArray, self, "initWithObjects:count:", objects, count)
}

@(objc_type=MutableArray, objc_name="initWithCoder")
MutableArray_initWithCoder :: proc "c" (self: ^MutableArray, coder: ^Coder) -> ^MutableArray {
	return msgSend(^MutableArray, self, "initWithCoder:", coder)
}

@(objc_type=MutableArray, objc_name="object")
MutableArray_object :: proc "c" (self: ^MutableArray, index: UInteger) -> ^Object {
	return msgSend(^Object, self, "objectAtIndex:", index)
}
@(objc_type=MutableArray, objc_name="objectAs")
MutableArray_objectAs :: proc "c" (self: ^MutableArray, index: UInteger, $T: typeid) -> T where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object)  {
	return (T)(MutableArray_object(self, index))
}

@(objc_type=MutableArray, objc_name="count")
MutableArray_count :: proc "c" (self: ^MutableArray) -> UInteger {
	return msgSend(UInteger, self, "count")
}


@(objc_type=MutableArray, objc_name="exchangeObjectAtIndex")
MutableArray_exchangeObjectAtIndex :: proc "c" (self: ^MutableArray, idx1, idx2: UInteger) {
	msgSend(nil, self, "exchangeObjectAtIndex:withObjectAtIndex:", idx1, idx2)
}
