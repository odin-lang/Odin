package crypto

import "core:fmt"

import CF "core:sys/darwin/CoreFoundation"
import Sec "core:sys/darwin/Security"

_rand_bytes :: proc(dst: []byte) {
	err := Sec.RandomCopyBytes(count=len(dst), bytes=raw_data(dst))
	if err != .Success {
        msg := CF.StringCopyToOdinString(Sec.CopyErrorMessageString(err))
        panic(fmt.tprintf("crypto/rand_bytes: SecRandomCopyBytes returned non-zero result: %v %s", err, msg))
	}
}

_has_rand_bytes :: proc() -> bool {
	return true
}
