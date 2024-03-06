package crypto

import "core:fmt"
import "core:sys/darwin"

_rand_bytes :: proc(dst: []byte) {
	res := darwin.SecRandomCopyBytes(count=len(dst), bytes=raw_data(dst))
	if res != .Success {
		msg := darwin.CFStringCopyToOdinString(darwin.SecCopyErrorMessageString(res))
		panic(fmt.tprintf("crypto/rand_bytes: SecRandomCopyBytes returned non-zero result: %v %s", res, msg))
	}
}
