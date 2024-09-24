package sdl2

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "SDL2.lib"
} else {
	foreign import lib "system:SDL2"
}

TouchID  :: distinct i64
FingerID :: distinct i64

TouchDeviceType :: enum c.int {
	INVALID = -1,
	DIRECT,            /* touch screen with window-relative coordinates */
	INDIRECT_ABSOLUTE, /* trackpad with absolute device coordinates */
	INDIRECT_RELATIVE, /* trackpad with screen cursor-relative coordinates */
}

Finger :: struct {
	id: FingerID,
	x:        f32,
	y:        f32,
	pressure: f32,
}

TOUCH_MOUSEID  :: ~u32(0)
MOUSE_TOUCH_ID :: TouchID(-1)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumTouchDevices :: proc() -> c.int ---
	GetTouchDevice     :: proc(index: c.int) -> TouchID ---
	GetTouchDeviceType :: proc(touchID: TouchID) -> TouchDeviceType ---
	GetNumTouchFingers :: proc(touchID: TouchID) -> c.int ---
	GetTouchFinger     :: proc(touchID: TouchID, index: c.int) -> ^Finger ---
}
