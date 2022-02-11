package objc_Foundation

@(objc_class="NSAutoreleasePool")
AutoreleasePool :: struct {using _: Object}

@(objc_type=AutoreleasePool, objc_class_name="alloc")
AutoreleasePool_alloc :: proc() -> ^AutoreleasePool {
	return msgSend(^AutoreleasePool, AutoreleasePool, "alloc")
}

@(objc_type=AutoreleasePool, objc_name="init")
AutoreleasePool_init :: proc(self: ^AutoreleasePool) -> ^AutoreleasePool {
	return msgSend(^AutoreleasePool, self, "init")
}

@(objc_type=AutoreleasePool, objc_name="drain")
AutoreleasePool_drain :: proc(self: ^AutoreleasePool) {
	msgSend(nil, self, "drain")
}
@(objc_type=AutoreleasePool, objc_name="addObject")
AutoreleasePool_addObject :: proc(self: ^AutoreleasePool, obj: ^Object) {
	msgSend(nil, self, "addObject:", obj)
}
@(objc_type=AutoreleasePool, objc_name="showPools")
AutoreleasePool_showPools :: proc(self: ^AutoreleasePool, obj: ^Object) {
	msgSend(nil, self, "showPools")
}


@(deferred_out=AutoreleasePool_drain)
scoped_autoreleasepool :: proc() -> ^AutoreleasePool {
	return AutoreleasePool.alloc()->init()
}