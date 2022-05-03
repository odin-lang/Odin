package vendor_openexr

foreign import lib "OpenEXRCore-3_1.lib"

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	print_context_info :: proc(c: const_context_t, verbose: b32) -> result_t ---
}