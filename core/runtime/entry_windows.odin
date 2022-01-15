//+private
//+build windows
package runtime

import "core:intrinsics"

when ODIN_BUILD_MODE == .Dynamic {
	@(link_name="DllMain", linkage="strong", require)
	DllMain :: proc "stdcall" (hinstDLL: rawptr, fdwReason: u32, lpReserved: rawptr) -> b32 {
		context = default_context()
		switch fdwReason {
		case 1: // DLL_PROCESS_ATTACH
			#force_no_inline _startup_runtime()
			intrinsics.__entry_point()
		case 0: // DLL_PROCESS_DETACH
			#force_no_inline _cleanup_runtime()
		case 2: // DLL_THREAD_ATTACH
			break
		case 3: // DLL_THREAD_DETACH
			break
		}
		return true
	}
} else when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
	when ODIN_ARCH == "386" || ODIN_NO_CRT {
		@(link_name="mainCRTStartup", linkage="strong", require)
		mainCRTStartup :: proc "stdcall" () -> i32 {
			context = default_context()
			#force_no_inline _startup_runtime()
			intrinsics.__entry_point()
			#force_no_inline _cleanup_runtime()
			return 0
		}
	} else {
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
}