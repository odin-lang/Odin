#+private
#+no-instrumentation
package runtime

@require foreign import "system:int64.lib"

@(private, export, link_name="_fltused") _fltused: i32 = 0x9875

when ODIN_NO_CRT {
	@(private, export, link_name="_tls_index") _tls_index: u32
	@(private, export, link_name="_tls_array") _tls_array: u32
}
