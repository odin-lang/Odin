package Security

import CF "core:sys/darwin/CoreFoundation"

foreign import Security "system:Security.framework"

// A reference to a random number generator.
RandomRef :: distinct rawptr

@(link_prefix="Sec", default_calling_convention="c")
foreign Security {
	// Default random ref for /dev/random. Synonym for nil.
	@(link_name="kSecRandomDefault") kSecRandomDefault: RandomRef

	// Generates an array of cryptographically secure random bytes.
	RandomCopyBytes :: proc(rnd: RandomRef = kSecRandomDefault, count: uint, bytes: [^]byte) -> errSec ---

	CopyErrorMessageString :: proc(status: errSec, reserved: rawptr = nil) -> CF.String ---
}