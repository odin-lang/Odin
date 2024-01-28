//+build js
package runtime

foreign import "odin_env"

_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	foreign odin_env {
		write :: proc "contextless" (fd: u32, p: []byte) ---
	}
	write(1, data)
	return len(data), 0
}
