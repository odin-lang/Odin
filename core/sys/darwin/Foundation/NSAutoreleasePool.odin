package objc_Foundation

@(objc_class="NSAutoreleasePool")
AutoreleasePool :: struct {using _: Object}

@(objc_type=AutoreleasePool, objc_name="alloc", objc_is_class_method=true)
AutoreleasePool_alloc :: proc "c" () -> ^AutoreleasePool {
	return msgSend(^AutoreleasePool, AutoreleasePool, "alloc")
}

@(objc_type=AutoreleasePool, objc_name="init")
AutoreleasePool_init :: proc "c" (self: ^AutoreleasePool) -> ^AutoreleasePool {
	return msgSend(^AutoreleasePool, self, "init")
}

@(objc_type=AutoreleasePool, objc_name="drain")
AutoreleasePool_drain :: proc "c" (self: ^AutoreleasePool) {
	msgSend(nil, self, "drain")
}
@(objc_type=AutoreleasePool, objc_name="addObject")
AutoreleasePool_addObject :: proc "c" (self: ^AutoreleasePool, obj: ^Object) {
	msgSend(nil, self, "addObject:", obj)
}
@(objc_type=AutoreleasePool, objc_name="showPools")
AutoreleasePool_showPools :: proc "c" (self: ^AutoreleasePool, obj: ^Object) {
	msgSend(nil, self, "showPools")
}


@(deferred_out=AutoreleasePool_drain)
scoped_autoreleasepool :: proc "c" () -> ^AutoreleasePool {
	return AutoreleasePool.alloc()->init()
}