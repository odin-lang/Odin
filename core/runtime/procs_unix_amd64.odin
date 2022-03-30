//+private
package runtime

when ODIN_NO_CRT {
	@(require)
	foreign import crt_lib "procs_unix_amd64.asm"
}
