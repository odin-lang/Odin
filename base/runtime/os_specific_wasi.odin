//+build wasi
//+private
package runtime

import "core:sys/wasm/wasi"

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	data_iovec := (wasi.ciovec_t)(data)
	n, err := wasi.fd_write(1, {data_iovec})
	return int(n), _OS_Errno(err)
}
