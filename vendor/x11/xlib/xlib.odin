// Bindings for [[ X11's Xlib (PDF) ; https://www.x.org/docs/X11/xlib.pdf ]].
package xlib

// Value, specifying whether `vendor:x11/xlib` is available on the current platform.
IS_SUPPORTED :: ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD
