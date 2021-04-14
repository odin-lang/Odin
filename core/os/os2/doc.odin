// Package os provides a platform-independent interface to operating system functionality.
// The design is UNIX-like but with Odin-like error handling. Failing calls return values with a specific error type rather than error number.
//
// The package os interface is intended to be uniform across all operating systems.
// Features not generally available appear in the system-specific packages under core:sys/*.
//
//
// IMPORTANT NOTE from Bill: this is purely a mockup of what I want the new package os to be, and NON-FUNCTIONING.
// It is not complete but should give designers a better idea of the general interface and how to write things.
// This entire interface is subject to change.
package os2
