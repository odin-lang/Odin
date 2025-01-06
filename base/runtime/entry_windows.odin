#+private
#+build windows
#+no-instrumentation
package runtime

import "base:intrinsics"

when ODIN_BUILD_MODE == .Dynamic {
	@(link_name="DllMain", linkage="strong", require)
	DllMain :: proc "system" (hinstDLL: rawptr, fdwReason: u32, lpReserved: rawptr) -> b32 {
		context = default_context()

		// Populate Windows DLL-specific globals
		dll_forward_reason = DLL_Forward_Reason(fdwReason)
		dll_instance       = hinstDLL

		switch dll_forward_reason {
		case .Process_Attach:
			#force_no_inline _startup_runtime()
			intrinsics.__entry_point()
		case .Process_Detach:
			#force_no_inline _cleanup_runtime()
		case .Thread_Attach:
			break
		case .Thread_Detach:
			break
		}
		return true
	}
} else when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
	when ODIN_ARCH == .i386 || ODIN_NO_CRT {
		@(link_name="mainCRTStartup", linkage="strong", require)
		mainCRTStartup :: proc "system" () -> i32 {
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