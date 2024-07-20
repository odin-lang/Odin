package glfw_bindings

import "core:c"

Window  :: struct{}
Monitor :: struct{}
Cursor  :: struct{}

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
WindowIconifyProc      :: #type proc "c" (window: ^Window, iconified: c.int)
WindowRefreshProc      :: #type proc "c" (window: ^Window)
WindowFocusProc        :: #type proc "c" (window: ^Window, focused: c.int)
WindowCloseProc        :: #type proc "c" (window: ^Window)
WindowSizeProc         :: #type proc "c" (window: ^Window, width, height: c.int)
WindowPosProc          :: #type proc "c" (window: ^Window, xpos, ypos: c.int)
WindowMaximizeProc     :: #type proc "c" (window: ^Window, iconified: c.int) 
WindowContentScaleProc :: #type proc "c" (window: ^Window, xscale, yscale: f32)
FramebufferSizeProc    :: #type proc "c" (window: ^Window, width, height: c.int)
DropProc               :: #type proc "c" (window: ^Window, count: c.int, paths: [^]cstring)
MonitorProc            :: #type proc "c" (window: ^Window, event: c.int)

KeyProc                :: #type proc "c" (window: ^Window, key, scancode, action, mods: c.int)
MouseButtonProc        :: #type proc "c" (window: ^Window, button, action, mods: c.int)
CursorPosProc          :: #type proc "c" (window: ^Window, xpos,  ypos: f64)
ScrollProc             :: #type proc "c" (window: ^Window, xoffset, yoffset: f64)
CharProc               :: #type proc "c" (window: ^Window, codepoint: rune)
CharModsProc           :: #type proc "c" (window: ^Window, codepoint: rune, mods: c.int)
CursorEnterProc        :: #type proc "c" (window: ^Window, entered: c.int)
JoystickProc           :: #type proc "c" (joy, event: c.int)

ErrorProc              :: #type proc "c" (error: c.int, description: cstring)

AllocateProc           :: #type proc "c" (size: c.size_t, user: rawptr) -> rawptr
ReallocateProc         :: #type proc "c" (block: rawptr, size: c.size_t, user: rawptr) -> rawptr
DeallocateProc         :: #type proc "c" (block: rawptr, user: rawptr)
