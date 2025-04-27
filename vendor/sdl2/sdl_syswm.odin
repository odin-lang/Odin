package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

SYSWM_TYPE :: enum c.int {
	UNKNOWN,
	WINDOWS,
	X11,
	DIRECTFB,
	COCOA,
	UIKIT,
	WAYLAND,
	MIR,  /* no longer available, left for API/ABI compatibility. Remove in 2.1! */
	WINRT,
	ANDROID,
	VIVANTE,
	OS2,
	HAIKU,
	KMSDRM,
}

XEvent :: struct {
	type: c.int,
	pad: [24]c.long,
}

SysWMmsg :: struct {
	version: version,
	subsystem: SYSWM_TYPE,
	msg: struct #raw_union {
		win: struct {
			hwnd:   rawptr, /**< The window for the message */
			msg:    u32,    /**< The type of message */
			wParam: uint,   /**< WORD message parameter */
			lParam: int,    /**< LONG message parameter */
		},
		x11: struct {
			event: XEvent,
		},
		cocoa: struct {
			dummy: c.int,
		},
		uikit: struct {
			dummy: c.int,
		},
		dummy: c.int,
	},
}

/**
 *  The custom window manager information structure.
 *
 *  When this structure is returned, it holds information about which
 *  low level system it is using, and will be one of SYSWM_TYPE.
 */
SysWMinfo :: struct {
	version:   version,
	subsystem: SYSWM_TYPE,
	info: struct #raw_union {
		win: struct {
			window:    rawptr,
			hdc:       rawptr,
			hinstance: rawptr,
		},
		winrt: struct {
			window: rawptr, /**< The WinRT CoreWindow */
		},
		x11: struct {
			display: rawptr,
			window: uintptr, /**< The X11 window */
		},
		cocoa: struct {
			window: rawptr,                     /**< The Cocoa window */
		},
		uikit: struct {
			window: rawptr,          /**< The UIKit window */
			framebuffer: u32,        /**< The GL view's Framebuffer Object. It must be bound when rendering to the screen using GL. */
			colorbuffer: u32,        /**< The GL view's color Renderbuffer Object. It must be bound when SDL_GL_SwapWindow is called. */
			resolveFramebuffer: u32, /**< The Framebuffer Object which holds the resolve color Renderbuffer, when MSAA is used. */
		},
		wl: struct {
			display:       rawptr, /**< Wayland display */
			surface:       rawptr, /**< Wayland surface */
			shell_surface: rawptr, /**< DEPRECATED Wayland shell_surface (window manager handle) */
			egl_window:    rawptr, /**< Wayland EGL window (native window) */
			xdg_surface:   rawptr, /**< Wayland xdg surface (window manager handle) */
		},
		mir: struct {
			connection: rawptr,  /**< Mir display server connection */
			surface:    rawptr,  /**< Mir surface */
		},
		android: struct {
			window:  rawptr,
			surface: rawptr,
		},
		dummy: [64]u8,
	},
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetWindowWMInfo :: proc(window: ^Window, info: ^SysWMinfo) -> bool ---
}
