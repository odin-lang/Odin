package aes

import "core:crypto/_aes/ct64"
import "core:mem"
import "core:reflect"

@(private)
Context_Impl :: union {
	ct64.Context,
	Context_Impl_Hardware,
}

// DEFAULT_IMPLEMENTATION is the implementation that will be used by
// default if possible.
DEFAULT_IMPLEMENTATION :: Implementation.Hardware

// Implementation is an AES implementation.  Most callers will not need
// to use this as the package will automatically select the most performant
// implementation available (See `is_hardware_accelerated()`).
Implementation :: enum {
	Portable,
	Hardware,
}

@(private)
init_impl :: proc(ctx: ^Context_Impl, key: []byte, impl: Implementation) {
	impl := impl
	if !is_hardware_accelerated() {
		impl = .Portable
	}

	switch impl {
	case .Portable:
		reflect.set_union_variant_typeid(ctx^, typeid_of(ct64.Context))
		ct64.init(&ctx.(ct64.Context), key)
	case .Hardware:
		reflect.set_union_variant_typeid(ctx^, typeid_of(Context_Impl_Hardware))
		init_impl_hw(&ctx.(Context_Impl_Hardware), key)
	}
}

@(private)
reset_impl :: proc "contextless" (ctx: ^Context_Impl) {
	mem.zero_explicit(ctx, size_of(Context_Impl))
}
