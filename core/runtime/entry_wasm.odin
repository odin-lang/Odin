//+private
//+build wasm32, wasm64p32
package runtime

import "core:intrinsics"

when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
	@(link_name="_start", linkage="strong", require, export)
	_start :: proc "c" () {
		context = default_context()
		#force_no_inline _startup_runtime()
		intrinsics.__entry_point()
	}
	@(link_name="_end", linkage="strong", require, export)
	_end :: proc "c" () {
		context = default_context()
		#force_no_inline _cleanup_runtime()
	}
}