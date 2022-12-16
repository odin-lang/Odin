package vendor_openexr

when ODIN_OS == .Windows {
	foreign import lib "OpenEXRCore-3_1.lib"
} else {
	foreign import lib "system:OpenEXRCore-3_1"
}

@(link_prefix="exr_", default_calling_convention="c")
foreign lib {
	print_context_info :: proc(c: const_context_t, verbose: b32) -> result_t ---
}