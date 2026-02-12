// package os_old provides a platform-independent interface to operating system functionality.
// The design is UNIX-like but with Odin-like error handling. Failing calls return values with a specific error type rather than error number.
//
// The package os_old interface is intended to be uniform across all operating systems.
// Features not generally available appear in the system-specific packages under core:sys/*.
package os
