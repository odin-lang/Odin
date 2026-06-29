// Bindings for [[ X11's Xlib (PDF) ; https://xorg.freedesktop.org/archive/current/doc/libX11/libX11/libX11.pdf ]].
package xlib

// Value, specifying whether `vendor:x11/xlib` is available on the current platform.
IS_SUPPORTED :: ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD
