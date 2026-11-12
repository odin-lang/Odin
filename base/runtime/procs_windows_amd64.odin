#+private
#+no-instrumentation
package runtime

when ODIN_NO_CRT {
	// __chkstk uses a special calling convention with implicit register inputs.
	@(require)
	foreign import crt_lib "procs_windows_amd64.asm"
}
