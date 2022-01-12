//+private
//+build linux, darwin
package runtime

import "core:intrinsics"

when ODIN_BUILD_MODE == "dynamic" {
	@(link_name="_odin_entry_point", linkage="strong", require)
	_odin_entry_point :: proc "c" () {
		context = default_context()
		#force_no_inline _startup_runtime()
		intrinsics.__entry_point()
	}
	@(link_name="_odin_exit_point", linkage="strong", require)
	_odin_exit_point :: proc "c" () {
		context = default_context()
		#force_no_inline _cleanup_runtime()
	}
}