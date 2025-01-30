package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

Joystick :: struct {}

JoystickGUID :: struct {
	data: [16]u8,
}

JoystickID :: distinct i32

JoystickType :: enum c.int {
	UNKNOWN,
	GAMECONTROLLER,
	WHEEL,
	ARCADE_STICK,
	FLIGHT_STICK,
	DANCE_PAD,
	GUITAR,
	DRUM_KIT,
	ARCADE_PAD,
	THROTTLE,
}

JoystickPowerLevel :: enum c.int {
	UNKNOWN = -1,
	EMPTY,   /* <= 5% */
	LOW,     /* <= 20% */
	MEDIUM,  /* <= 70% */
	FULL,    /* <= 100% */
	WIRED,
	MAX,
}

IPHONE_MAX_GFORCE :: 5.0

JOYSTICK_AXIS_MAX :: +32767
JOYSTICK_AXIS_MIN :: -32768

HAT_CENTERED  :: 0x00
HAT_UP        :: 0x01
HAT_RIGHT     :: 0x02
HAT_DOWN      :: 0x04
HAT_LEFT      :: 0x08
HAT_RIGHTUP   :: HAT_RIGHT|HAT_UP
HAT_RIGHTDOWN :: HAT_RIGHT|HAT_DOWN
HAT_LEFTUP    :: HAT_LEFT|HAT_UP
HAT_LEFTDOWN  :: HAT_LEFT|HAT_DOWN

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	LockJoysticks                   :: proc() ---
	UnlockJoysticks                 :: proc() ---
	NumJoysticks                    :: proc() -> c.int ---
	JoystickNameForIndex            :: proc(device_index: c.int) -> cstring ---
	JoystickGetDevicePlayerIndex    :: proc(device_index: c.int) -> c.int ---
	JoystickGetDeviceGUID           :: proc(device_index: c.int) -> JoystickGUID ---
	JoystickGetDeviceVendor         :: proc(device_index: c.int) -> u16 ---
	JoystickGetDeviceProduct        :: proc(device_index: c.int) -> u16 ---
	JoystickGetDeviceProductVersion :: proc(device_index: c.int) -> u16 ---
	JoystickGetDeviceType           :: proc(device_index: c.int) -> JoystickType ---
	JoystickGetDeviceInstanceID     :: proc(device_index: c.int) -> JoystickID ---
	JoystickOpen                    :: proc(device_index: c.int) -> ^Joystick ---
	JoystickFromInstanceID          :: proc(instance_id: JoystickID ) -> ^Joystick ---
	JoystickFromPlayerIndex         :: proc(player_index: c.int) -> ^Joystick ---
	JoystickAttachVirtual           :: proc(type: JoystickType, naxes, nbuttons, nhats: c.int) -> c.int ---
	JoystickDetachVirtual           :: proc(device_index: c.int) -> c.int ---
	JoystickIsVirtual               :: proc(device_index: c.int) -> bool ---
	JoystickSetVirtualAxis          :: proc(joystick: ^Joystick, axis: c.int, value: i16) -> c.int ---
	JoystickSetVirtualButton        :: proc(joystick: ^Joystick, button: c.int, value: u8) -> c.int ---
	JoystickSetVirtualHat           :: proc(joystick: ^Joystick, hat: c.int, value: u8) -> c.int ---
	JoystickName                    :: proc(joystick: ^Joystick) -> cstring ---
	JoystickGetPlayerIndex          :: proc(joystick: ^Joystick) -> c.int ---
	JoystickSetPlayerIndex          :: proc(joystick: ^Joystick, player_index: c.int) ---
	JoystickGetGUID                 :: proc(joystick: ^Joystick) -> JoystickGUID ---
	JoystickGetVendor               :: proc(joystick: ^Joystick) -> u16 ---
	JoystickGetProduct              :: proc(joystick: ^Joystick) -> u16 ---
	JoystickGetProductVersion       :: proc(joystick: ^Joystick) -> u16 ---
	JoystickGetSerial               :: proc(joystick: ^Joystick) -> cstring ---
	JoystickGetType                 :: proc(joystick: ^Joystick) -> JoystickType ---
	JoystickGetGUIDString           :: proc(guid: JoystickGUID, pszGUID: [^]u8, cbGUID: c.int) ---
	JoystickGetGUIDFromString       :: proc(pchGUID: cstring) -> JoystickGUID ---
	JoystickGetAttached             :: proc(joystick: ^Joystick) -> bool ---
	JoystickInstanceID              :: proc(joystick: ^Joystick) -> JoystickID ---
	JoystickNumAxes                 :: proc(joystick: ^Joystick) -> c.int ---
	JoystickNumBalls                :: proc(joystick: ^Joystick) -> c.int ---
	JoystickNumHats                 :: proc(joystick: ^Joystick) -> c.int ---
	JoystickNumButtons              :: proc(joystick: ^Joystick) -> c.int ---
	JoystickUpdate                  :: proc() ---
	JoystickEventState              :: proc(state: c.int) -> c.int ---
	JoystickGetAxis                 :: proc(joystick: ^Joystick, axis: c.int) -> i64 ---
	JoystickGetAxisInitialState     :: proc(joystick: ^Joystick, axis: c.int, state: ^i16) -> bool ---
	JoystickGetHat                  :: proc(joystick: ^Joystick, hat: c.int) -> u8 ---
	JoystickGetBall                 :: proc(joystick: ^Joystick, ball: c.int, dx, dy: ^c.int) -> c.int ---
	JoystickGetButton               :: proc(joystick: ^Joystick, button: c.int) -> u8 ---
	JoystickRumble                  :: proc(joystick: ^Joystick, low_frequency_rumble, high_frequency_rumble: u16, duration_ms: u32) -> c.int ---
	JoystickRumbleTriggers          :: proc(joystick: ^Joystick, left_rumble, right_rumble: u16, duration_ms: u32) -> c.int ---
	JoystickHasLED                  :: proc(joystick: ^Joystick) -> bool ---
	JoystickSetLED                  :: proc(joystick: ^Joystick, red, green, blue: u8) -> c.int ---
	JoystickSendEffect              :: proc(joystick: ^Joystick, data: rawptr, size: c.int) -> c.int ---
	JoystickClose                   :: proc(joystick: ^Joystick) ---
	JoystickCurrentPowerLevel       :: proc(joystick: ^Joystick) -> JoystickPowerLevel ---
}
