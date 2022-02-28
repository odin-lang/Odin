//+private
//+build linux, darwin, freebsd, openbsd
package runtime

import "core:intrinsics"

when ODIN_BUILD_MODE == .Dynamic {
	@(link_name="_odin_entry_point", linkage="strong", require/*, link_section=".init"*/)
	_odin_entry_point :: proc "c" () {
		context = default_context()
		#force_no_inline _startup_runtime()
		intrinsics.__entry_point()
	}
	@(link_name="_odin_exit_point", linkage="strong", require/*, link_section=".fini"*/)
	_odin_exit_point :: proc "c" () {
		context = default_context()
		#force_no_inline _cleanup_runtime()
	}
	@(link_name="main", linkage="strong", require)
	main :: proc "c" (argc: i32, argv: [^]cstring) -> i32 {
		return 0
	}
} else when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
	@(link_name="main", linkage="strong", require)
	main :: proc "c" (argc: i32, argv: [^]cstring) -> i32 {
		args__ = argv[:argc]
		context = default_context()
		#force_no_inline _startup_runtime()
		intrinsics.__entry_point()
		#force_no_inline _cleanup_runtime()
		return 0
	}
}