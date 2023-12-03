//+build darwin
package darwin

foreign import security "system:Security.framework"

// A reference to a random number generator.
SecRandomRef :: distinct rawptr

OSStatus :: distinct i32

errSec :: enum OSStatus {
	Success       = 0,  // No error.
	Unimplemented = -4, // Function or operation not implemented.

	// Many more...
}

foreign security {
	// Synonym for nil, uses a cryptographically secure random number generator.
	kSecRandomDefault: SecRandomRef
	
	// Generates an array of cryptographically secure random bytes.
	SecRandomCopyBytes :: proc(rnd: SecRandomRef = kSecRandomDefault, count: uint, bytes: [^]byte) -> errSec ---

	SecCopyErrorMessageString :: proc(status: errSec, reserved: rawptr = nil) -> CFStringRef ---
}
