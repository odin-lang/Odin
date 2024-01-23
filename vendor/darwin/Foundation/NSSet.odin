package objc_Foundation

@(objc_class="NSSet")
Set :: struct {using _: Copying(Set)}


@(objc_type=Set, objc_name="alloc", objc_is_class_method=true)
Set_alloc :: proc "c" () -> ^Set {
	return msgSend(^Set, Set, "alloc")
}

@(objc_type=Set, objc_name="init")
Set_init :: proc "c" (self: ^Set) -> ^Set {
	return msgSend(^Set, self, "init")
}


@(objc_type=Set, objc_name="initWithObjects")
Set_initWithObjects :: proc "c" (self: ^Set, objects: [^]^Object, count: UInteger) -> ^Set {
	return msgSend(^Set, self, "initWithObjects:count:", objects, count)
}


@(objc_type=Set, objc_name="initWithCoder")
Set_initWithCoder :: proc "c" (self: ^Set, coder: ^Coder) -> ^Set {
	return msgSend(^Set, self, "initWithCoder:", coder)
}
