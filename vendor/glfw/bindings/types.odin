package glfw_bindings

import "core:c"

WindowHandle  :: distinct rawptr
MonitorHandle :: distinct rawptr
CursorHandle  :: distinct rawptr

VidMode :: struct {
	width:        c.int,
	height:       c.int,
	red_bits:     c.int,
	green_bits:   c.int,
	blue_bits:    c.int,
	refresh_rate: c.int,
}

GammaRamp :: struct {
	red, green, blue: [^]c.ushort,
	size:                c.uint, 
}

Image :: struct {
	width, height: c.int,
	pixels:        [^]u8,
}

GamepadState :: struct {
	buttons: [15]u8,
	axes:    [6]f32,
}

Allocator :: struct {
	allocate:   AllocateProc,
	reallocate: ReallocateProc,
	deallocate: DeallocateProc,
	user:       rawptr,
}

/*** Procedure type declarations ***/
WindowIconifyProc      :: #type proc "c" (window: WindowHandle, iconified: c.int)
WindowRefreshProc      :: #type proc "c" (window: WindowHandle)
WindowFocusProc        :: #type proc "c" (window: WindowHandle, focused: c.int)
WindowCloseProc        :: #type proc "c" (window: WindowHandle)
WindowSizeProc         :: #type proc "c" (window: WindowHandle, width, height: c.int)
WindowPosProc          :: #type proc "c" (window: WindowHandle, xpos, ypos: c.int)
WindowMaximizeProc     :: #type proc "c" (window: WindowHandle, iconified: c.int) 
WindowContentScaleProc :: #type proc "c" (window: WindowHandle, xscale, yscale: f32)
FramebufferSizeProc    :: #type proc "c" (window: WindowHandle, width, height: c.int)
DropProc               :: #type proc "c" (window: WindowHandle, count: c.int, paths: [^]cstring)
MonitorProc            :: #type proc "c" (monitor: MonitorHandle, event: c.int)

KeyProc                :: #type proc "c" (window: WindowHandle, key, scancode, action, mods: c.int)
MouseButtonProc        :: #type proc "c" (window: WindowHandle, button, action, mods: c.int)
CursorPosProc          :: #type proc "c" (window: WindowHandle, xpos,  ypos: f64)
ScrollProc             :: #type proc "c" (window: WindowHandle, xoffset, yoffset: f64)
CharProc               :: #type proc "c" (window: WindowHandle, codepoint: rune)
CharModsProc           :: #type proc "c" (window: WindowHandle, codepoint: rune, mods: c.int)
CursorEnterProc        :: #type proc "c" (window: WindowHandle, entered: c.int)
JoystickProc           :: #type proc "c" (joy, event: c.int)

ErrorProc              :: #type proc "c" (error: c.int, description: cstring)

AllocateProc           :: #type proc "c" (size: c.size_t, user: rawptr) -> rawptr
ReallocateProc         :: #type proc "c" (block: rawptr, size: c.size_t, user: rawptr) -> rawptr
DeallocateProc         :: #type proc "c" (block: rawptr, user: rawptr)
