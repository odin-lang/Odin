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
			when !ODIN_BEDROCK { #force_no_inline _startup_runtime() }
			when ODIN_CODEPAGE_MAGIC {
				old_console_codepage = GetConsoleOutputCP()
				SetConsoleOutputCP(UTF_8)
			}
			intrinsics.__entry_point()
		case .Process_Detach:
			when !ODIN_BEDROCK { #force_no_inline _cleanup_runtime() }
			when ODIN_CODEPAGE_MAGIC { SetConsoleOutputCP(old_console_codepage) }
		case .Thread_Attach:
			break
		case .Thread_Detach:
			break
		}
		return true
	}
} else when !ODIN_TEST && !ODIN_NO_ENTRY_POINT {
	when ODIN_NO_CRT {
		@(link_name="mainCRTStartup", linkage="strong", require)
		mainCRTStartup :: proc "system" () -> i32 {
			context = default_context()
			when !ODIN_BEDROCK { #force_no_inline _startup_runtime() }
			when ODIN_CODEPAGE_MAGIC {
				old_console_codepage = GetConsoleOutputCP()
				SetConsoleOutputCP(UTF_8)
			}
			intrinsics.__entry_point()
			when !ODIN_BEDROCK       { #force_no_inline _cleanup_runtime() }
			when ODIN_CODEPAGE_MAGIC { SetConsoleOutputCP(old_console_codepage) }
			return 0
		}
	} else {
		@(link_name="wmain", linkage="strong", require)
		wmain :: proc "c" (argc: i32, argv: [^]cstring16) -> i32 {
			args__ = argv[:argc]
			context = default_context()
			when !ODIN_BEDROCK { #force_no_inline _startup_runtime() }
			when ODIN_CODEPAGE_MAGIC {
				old_console_codepage = GetConsoleOutputCP()
				SetConsoleOutputCP(UTF_8)
			}
			intrinsics.__entry_point()
			when !ODIN_BEDROCK       { #force_no_inline _cleanup_runtime() }
			when ODIN_CODEPAGE_MAGIC { SetConsoleOutputCP(old_console_codepage) }
			return 0
		}
	}
}