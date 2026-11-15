// An imported Objective-C method is a message send at each call site, so it cannot be a deferred procedure;
// this used to crash in the backend.
// Expected: 1 error, for `pool_bad`.
package test_issue_objc_deferred_import

import "base:intrinsics"

foreign import lib "system:Foundation.framework"

@(objc_class="NSAutoreleasePool")
AutoreleasePool :: struct {using _: intrinsics.objc_object}

foreign lib {
	@(objc_type=AutoreleasePool, objc_selector="drain", objc_name="drain")
	AutoreleasePool_drain :: proc(self: ^AutoreleasePool) ---
}

new_pool :: proc "c" () -> ^AutoreleasePool {
	pool := intrinsics.objc_send(^AutoreleasePool, AutoreleasePool, "alloc")
	return intrinsics.objc_send(^AutoreleasePool, pool, "init")
}

@(deferred_out=AutoreleasePool_drain)
pool_bad :: proc "c" () -> ^AutoreleasePool {
	return new_pool()
}

pool_drain :: proc "c" (pool: ^AutoreleasePool) {
	pool->drain()
}

@(deferred_out=pool_drain)
pool_good :: proc "c" () -> ^AutoreleasePool {
	return new_pool()
}
