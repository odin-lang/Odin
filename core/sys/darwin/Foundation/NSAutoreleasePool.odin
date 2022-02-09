package objc_Foundation

@(objc_class="NSAutoreleasePool")
AutoreleasePool :: struct {using _: Object}

AutoreleasePool_drain :: proc(self: ^AutoreleasePool) {
	msgSend(nil, self, "drain")
}
AutoreleasePool_addObject :: proc(self: ^AutoreleasePool, obj: ^Object) {
	msgSend(nil, self, "addObject:", obj)
}
AutoreleasePool_showPools :: proc(self: ^AutoreleasePool, obj: ^Object) {
	msgSend(nil, self, "showPools")
}

