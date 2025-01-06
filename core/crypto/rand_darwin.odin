package crypto

import "core:fmt"

import CF "core:sys/darwin/CoreFoundation"
import Sec "core:sys/darwin/Security"

HAS_RAND_BYTES :: true

@(private)
_rand_bytes :: proc(dst: []byte) {
	err := Sec.RandomCopyBytes(count=len(dst), bytes=raw_data(dst))
	if err != .Success {
		msg := CF.StringCopyToOdinString(Sec.CopyErrorMessageString(err))
		fmt.panicf("crypto/rand_bytes: SecRandomCopyBytes returned non-zero result: %v %s", err, msg)
	}
}
