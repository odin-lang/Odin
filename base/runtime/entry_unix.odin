//+private
//+build linux, darwin, freebsd, openbsd, netbsd, haiku
//+no-instrumentation
package runtime

import "base:intrinsics"

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
	when ODIN_NO_CRT {
		// NOTE(flysand): We need to start from assembly because we need
		// to retrieve argc and argv from the stack
		when ODIN_ARCH == .amd64 {
			@require foreign import entry "entry_unix_no_crt_amd64.asm"
			SYS_exit :: 60
		} else when ODIN_ARCH == .i386 {
			@require foreign import entry "entry_unix_no_crt_i386.asm"
			SYS_exit :: 1
		} else when ODIN_OS == .Darwin && ODIN_ARCH == .arm64 {
			@require foreign import entry "entry_unix_no_crt_darwin_arm64.asm"
			SYS_exit :: 1
		} else when ODIN_ARCH == .riscv64 {
			@require foreign import entry "entry_unix_no_crt_riscv64.asm"
			SYS_exit :: 93
		}
		@(link_name="_start_odin", linkage="strong", require)
		_start_odin :: proc "c" (argc: i32, argv: [^]cstring) -> ! {
			args__ = argv[:argc]
			context = default_context()
			#force_no_inline _startup_runtime()
			intrinsics.__entry_point()
			#force_no_inline _cleanup_runtime()
			intrinsics.syscall(SYS_exit, 0)
			unreachable()
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
