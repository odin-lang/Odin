#+private
#+no-instrumentation
package runtime

when ODIN_NO_CRT {
	// NOTE: `__chkstk` is emitted by the compiler (see `lb_generate_code`), as it uses a special
	// calling convention with implicit register inputs and Odin cannot assemble foreign `.asm`
	// files for arm64.
	@(private, export, link_name="_fltused")   _fltused:   i32 = 0x9875
	@(private, export, link_name="_tls_index") _tls_index: u32
}
