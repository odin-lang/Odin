package sdl3

import "core:c"


TouchID  :: distinct Uint64
FingerID :: distinct Uint64

TouchDeviceType :: enum c.int {
	INVALID = -1,
	DIRECT,            /**< touch screen with window-relative coordinates */
	INDIRECT_ABSOLUTE, /**< trackpad with absolute device coordinates */
	INDIRECT_RELATIVE, /**< trackpad with screen cursor-relative coordinates */
}

Finger :: struct {
	id:       FingerID, /**< the finger ID */
	x:        f32,      /**< the x-axis location of the touch event, normalized (0...1) */
	y:        f32,      /**< the y-axis location of the touch event, normalized (0...1) */
	pressure: f32,      /**< the quantity of pressure applied, normalized (0...1) */
}

TOUCH_MOUSEID :: MouseID(1<<32 - 1)
MOUSE_TOUCHID :: TouchID(1<<64 - 1)

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetTouchDevices    :: proc(count: ^c.int) -> [^]TouchID ---
	GetTouchDeviceName :: proc(touchID: TouchID) -> cstring ---
	GetTouchDeviceType :: proc(touchID: TouchID) -> TouchDeviceType ---
	GetTouchFingers    :: proc(touchID: TouchID, count: ^c.int) -> [^]^Finger ---
}