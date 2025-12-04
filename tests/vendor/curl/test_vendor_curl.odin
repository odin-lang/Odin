#+build windows, linux, darwin
package test_vendor_curl

import "base:runtime"
import "core:testing"
import "vendor:curl"

@(test)
test_curl :: proc(t: ^testing.T) {
	data_callback :: proc "c" (contents: [^]byte, size: int, nmemb: int, userp: rawptr) -> int {
		context = runtime.default_context()

		real_size := size * nmemb
		memory := (^[dynamic]byte)(userp)

		n := len(memory^)
		resize(memory, n + real_size)
		copy(memory[n:], contents[:real_size])

		return real_size
	}


	curl.global_init(curl.GLOBAL_ALL)

	c := curl.easy_init()
	testing.expect(t, c != nil, "curl.easy_init failed")

	defer curl.easy_cleanup(c)

	memory, memory_err := make([dynamic]byte)
	testing.expectf(t, memory_err == nil, "make failed: %v", memory_err)
	defer delete(memory)

	curl.easy_setopt(c, .URL, cstring("https://odin-lang.org"))
	curl.easy_setopt(c, .WRITEFUNCTION, data_callback)
	curl.easy_setopt(c, .WRITEDATA, &memory)
	curl.easy_setopt(c, .USERAGENT, cstring("libcurl-agent/1.0"))

	res := curl.easy_perform(c)
	testing.expectf(t, res == nil, "curl.easy_perform failed: %v", res)
}
