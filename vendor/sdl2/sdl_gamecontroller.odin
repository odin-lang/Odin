package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

GameController :: struct {}

GameControllerType :: enum c.int {
	UNKNOWN = 0,
	XBOX360,
	XBOXONE,
	PS3,
	PS4,
	NINTENDO_SWITCH_PRO,
	VIRTUAL,
	PS5,
	AMAZON_LUNA,
	GOOGLE_STADIA,
}

GameControllerBindType :: enum c.int {
	NONE = 0,
	BUTTON,
	AXIS,
	HAT,
}

GameControllerButtonBind :: struct {
	bindType: GameControllerBindType,
	value: struct #raw_union {
		button: c.int,
		axis:   c.int,
		hat: struct {
			hat:      c.int,
			hat_mask: c.int,
		},
	},
}

GameControllerAxis :: enum c.int {
	INVALID = -1,
	LEFTX,
	LEFTY,
	RIGHTX,
	RIGHTY,
	TRIGGERLEFT,
	TRIGGERRIGHT,
	MAX,
}

GameControllerButton :: enum c.int {
	INVALID = -1,
	A,
	B,
	X,
	Y,
	BACK,
	GUIDE,
	START,
	LEFTSTICK,
	RIGHTSTICK,
	LEFTSHOULDER,
	RIGHTSHOULDER,
	DPAD_UP,
	DPAD_DOWN,
	DPAD_LEFT,
	DPAD_RIGHT,
	MISC1,    /* Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button */
	PADDLE1,  /* Xbox Elite paddle P1 */
	PADDLE2,  /* Xbox Elite paddle P3 */
	PADDLE3,  /* Xbox Elite paddle P2 */
	PADDLE4,  /* Xbox Elite paddle P4 */
	TOUCHPAD, /* PS4/PS5 touchpad button */
	MAX,
}


GameControllerAddMappingsFromFile :: #force_inline proc "c" (file: cstring) -> c.int {
	return GameControllerAddMappingsFromRW(RWFromFile(file, "rb"), true)
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GameControllerAddMappingsFromRW     :: proc(rw: ^RWops, freerw: bool) -> c.int ---

	GameControllerAddMapping            :: proc(mappingString: cstring) -> c.int ---
	GameControllerNumMappings           :: proc() -> c.int ---
	GameControllerMappingForIndex       :: proc(mapping_index: c.int) -> cstring  ---
	GameControllerMappingForGUID        :: proc(guid: JoystickGUID) -> cstring  ---
	GameControllerMapping               :: proc(gamecontroller: ^GameController) -> cstring  ---
	IsGameController                    :: proc(joystick_index: c.int) -> bool ---
	GameControllerNameForIndex          :: proc(joystick_index: c.int) -> cstring ---
	GameControllerTypeForIndex          :: proc(joystick_index: c.int) -> GameControllerType ---
	GameControllerMappingForDeviceIndex :: proc(joystick_index: c.int) -> cstring ---
	GameControllerOpen                  :: proc(joystick_index: c.int) -> ^GameController ---
	GameControllerFromInstanceID        :: proc(joyid: JoystickID)     -> ^GameController ---
	GameControllerFromPlayerIndex       :: proc(player_index: c.int)   -> ^GameController ---
	GameControllerName                  :: proc(gamecontroller: ^GameController) -> cstring  ---
	GameControllerGetType               :: proc(gamecontroller: ^GameController) -> GameControllerType ---
	GameControllerGetPlayerIndex        :: proc(gamecontroller: ^GameController) -> c.int ---
	GameControllerSetPlayerIndex        :: proc(gamecontroller: ^GameController, player_index: c.int) ---
	GameControllerGetVendor             :: proc(gamecontroller: ^GameController) -> u16 ---
	GameControllerGetProduct            :: proc(gamecontroller: ^GameController) -> u16 ---
	GameControllerGetProductVersion     :: proc(gamecontroller: ^GameController) -> u16 ---
	GameControllerGetSerial             :: proc(gamecontroller: ^GameController) -> cstring ---
	GameControllerGetAttached           :: proc(gamecontroller: ^GameController) -> bool ---
	GameControllerGetJoystick           :: proc(gamecontroller: ^GameController) -> ^Joystick ---
	GameControllerEventState            :: proc(state: c.int) -> c.int ---
	GameControllerUpdate                :: proc() ---

	GameControllerGetAxisFromString     :: proc(str: cstring) -> GameControllerAxis ---
	GameControllerGetStringForAxis      :: proc(axis: GameControllerAxis) -> cstring ---
	GameControllerGetBindForAxis        :: proc(gamecontroller: ^GameController, axis: GameControllerAxis)  -> GameControllerButtonBind---
	GameControllerHasAxis               :: proc(gamecontroller: ^GameController, axis: GameControllerAxis) -> bool ---
	GameControllerGetAxis               :: proc(gamecontroller: ^GameController, axis: GameControllerAxis) -> i16 ---

	GameControllerGetButtonFromString   :: proc(str: cstring) -> GameControllerButton ---
	GameControllerGetStringForButton    :: proc(button: GameControllerButton) -> cstring ---
	GameControllerGetBindForButton      :: proc(gamecontroller: ^GameController, button: GameControllerButton) -> GameControllerButtonBind ---
	GameControllerHasButton             :: proc(gamecontroller: ^GameController, button: GameControllerButton) -> bool ---
	GameControllerGetButton             :: proc(gamecontroller: ^GameController, button: GameControllerButton) -> u8 ---
	GameControllerGetNumTouchpads       :: proc(gamecontroller: ^GameController) -> c.int ---
	GameControllerGetNumTouchpadFingers :: proc(gamecontroller: ^GameController, touchpad: c.int) -> c.int ---
	GameControllerGetTouchpadFinger     :: proc(gamecontroller: ^GameController, touchpad: c.int, finger: c.int, state: ^u8, x, y: ^f32, pressure: ^f32) -> c.int ---
	GameControllerHasSensor             :: proc(gamecontroller: ^GameController, type: SensorType) -> bool ---
	GameControllerSetSensorEnabled      :: proc(gamecontroller: ^GameController, type: SensorType, enabled: bool) -> c.int ---
	GameControllerIsSensorEnabled       :: proc(gamecontroller: ^GameController, type: SensorType) -> bool ---
	GameControllerGetSensorDataRate     :: proc(gamecontroller: ^GameController, type: SensorType) -> f32 ---
	GameControllerGetSensorData         :: proc(gamecontroller: ^GameController, type: SensorType, data: [^]f32, num_values: c.int) -> c.int ---
	GameControllerRumble                :: proc(gamecontroller: ^GameController, low_frequency_rumble, high_frequency_rumble: u16, duration_ms: u32) -> c.int ---
	GameControllerRumbleTriggers        :: proc(gamecontroller: ^GameController, left_rumble, right_rumble: u16, duration_ms: u32) -> c.int ---
	GameControllerHasLED                :: proc(gamecontroller: ^GameController) -> bool ---
	GameControllerSetLED                :: proc(gamecontroller: ^GameController, red, green, blue: u8) -> c.int ---
	GameControllerSendEffect            :: proc(gamecontroller: ^GameController, data: rawptr, size: c.int) -> c.int ---
	GameControllerClose                 :: proc(gamecontroller: ^GameController) ---
}
