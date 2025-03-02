package sdl3

import "core:c"

Gamepad :: struct {}

GamepadType :: enum c.int {
	UNKNOWN = 0,
	STANDARD,
	XBOX360,
	XBOXONE,
	PS3,
	PS4,
	PS5,
	NINTENDO_SWITCH_PRO,
	NINTENDO_SWITCH_JOYCON_LEFT,
	NINTENDO_SWITCH_JOYCON_RIGHT,
	NINTENDO_SWITCH_JOYCON_PAIR,
}

GamepadButton :: enum c.int {
	INVALID = -1,
	SOUTH,           /**< Bottom face button (e.g. Xbox A button) */
	EAST,            /**< Right face button (e.g. Xbox B button) */
	WEST,            /**< Left face button (e.g. Xbox X button) */
	NORTH,           /**< Top face button (e.g. Xbox Y button) */
	BACK,
	GUIDE,
	START,
	LEFT_STICK,
	RIGHT_STICK,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	DPAD_UP,
	DPAD_DOWN,
	DPAD_LEFT,
	DPAD_RIGHT,
	MISC1,           /**< Additional button (e.g. Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button, Google Stadia capture button) */
	RIGHT_PADDLE1,   /**< Upper or primary paddle, under your right hand (e.g. Xbox Elite paddle P1) */
	LEFT_PADDLE1,    /**< Upper or primary paddle, under your left hand (e.g. Xbox Elite paddle P3) */
	RIGHT_PADDLE2,   /**< Lower or secondary paddle, under your right hand (e.g. Xbox Elite paddle P2) */
	LEFT_PADDLE2,    /**< Lower or secondary paddle, under your left hand (e.g. Xbox Elite paddle P4) */
	TOUCHPAD,        /**< PS4/PS5 touchpad button */
	MISC2,           /**< Additional button */
	MISC3,           /**< Additional button */
	MISC4,           /**< Additional button */
	MISC5,           /**< Additional button */
	MISC6,           /**< Additional button */
}

GamepadButtonLabel :: enum c.int {
	UNKNOWN,
	A,
	B,
	X,
	Y,
	CROSS,
	CIRCLE,
	SQUARE,
	TRIANGLE,
}

GamepadAxis :: enum c.int {
	INVALID = -1,
	LEFTX,
	LEFTY,
	RIGHTX,
	RIGHTY,
	LEFT_TRIGGER,
	RIGHT_TRIGGER,
}


GamepadBindingType :: enum c.int {
	NONE = 0,
	BUTTON,
	AXIS,
	HAT,
}

GamepadBinding :: struct {
	input_type: GamepadBindingType,
	input: struct #raw_union {
		button: c.int,

		axis: struct {
			axis: c.int,
			axis_min: c.int,
			axis_max: c.int,
		},

		hat: struct {
			hat: c.int,
			hat_mask: c.int,
		},
	},

	output_type: GamepadBindingType,
	output: struct #raw_union {
		button: GamepadButton,

		axis: struct {
			axis: GamepadAxis,
			axis_min: c.int,
			axis_max: c.int,
		},
	},
}


PROP_GAMEPAD_CAP_MONO_LED_BOOLEAN       :: PROP_JOYSTICK_CAP_MONO_LED_BOOLEAN
PROP_GAMEPAD_CAP_RGB_LED_BOOLEAN        :: PROP_JOYSTICK_CAP_RGB_LED_BOOLEAN
PROP_GAMEPAD_CAP_PLAYER_LED_BOOLEAN     :: PROP_JOYSTICK_CAP_PLAYER_LED_BOOLEAN
PROP_GAMEPAD_CAP_RUMBLE_BOOLEAN         :: PROP_JOYSTICK_CAP_RUMBLE_BOOLEAN
PROP_GAMEPAD_CAP_TRIGGER_RUMBLE_BOOLEAN :: PROP_JOYSTICK_CAP_TRIGGER_RUMBLE_BOOLEAN


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	AddGamepadMapping                     :: proc(mapping: cstring) -> c.int ---
	AddGamepadMappingsFromIO              :: proc(src: ^IOStream, closeio: bool) -> c.int ---
	AddGamepadMappingsFromFile            :: proc(file: cstring) -> c.int ---
	ReloadGamepadMappings                 :: proc() -> bool ---
	GetGamepadMappings                    :: proc(count: ^c.int) -> [^][^]byte ---
	GetGamepadMappingForGUID              :: proc(guid: GUID) -> [^]byte---
	GetGamepadMapping                     :: proc(gamepad: ^Gamepad) -> [^]byte ---
	SetGamepadMapping                     :: proc(instance_id: JoystickID, mapping: cstring) -> bool ---
	HasGamepad                            :: proc() -> bool ---
	GetGamepads                           :: proc(count: ^c.int) -> [^]JoystickID ---
	IsGamepad                             :: proc(instance_id: JoystickID) -> bool ---
	GetGamepadNameForID                   :: proc(instance_id: JoystickID) -> cstring ---
	GetGamepadPathForID                   :: proc(instance_id: JoystickID) -> cstring ---
	GetGamepadPlayerIndexForID            :: proc(instance_id: JoystickID) -> c.int ---
	GetGamepadGUIDForID                   :: proc(instance_id: JoystickID) -> GUID ---
	GetGamepadVendorForID                 :: proc(instance_id: JoystickID) -> Uint16 ---
	GetGamepadProductForID                :: proc(instance_id: JoystickID) -> Uint16 ---
	GetGamepadProductVersionForID         :: proc(instance_id: JoystickID) -> Uint16 ---
	GetGamepadTypeForID                   :: proc(instance_id: JoystickID) -> GamepadType ---
	GetRealGamepadTypeForID               :: proc(instance_id: JoystickID) -> GamepadType ---
	GetGamepadMappingForID                :: proc(instance_id: JoystickID) -> [^]byte ---
	OpenGamepad                           :: proc(instance_id: JoystickID) -> ^Gamepad ---
	GetGamepadFromID                      :: proc(instance_id: JoystickID) -> ^Gamepad ---
	GetGamepadFromPlayerIndex             :: proc(player_index: c.int) -> ^Gamepad ---
	GetGamepadProperties                  :: proc(gamepad: ^Gamepad) -> PropertiesID ---
	GetGamepadID                          :: proc(gamepad: ^Gamepad) -> JoystickID ---
	GetGamepadName                        :: proc(gamepad: ^Gamepad) -> cstring ---
	GetGamepadPath                        :: proc(gamepad: ^Gamepad) -> cstring ---
	GetGamepadType                        :: proc(gamepad: ^Gamepad) -> GamepadType ---
	GetRealGamepadType                    :: proc(gamepad: ^Gamepad) -> GamepadType ---
	GetGamepadPlayerIndex                 :: proc(gamepad: ^Gamepad) -> c.int ---
	SetGamepadPlayerIndex                 :: proc(gamepad: ^Gamepad, player_index: c.int) -> bool ---
	GetGamepadVendor                      :: proc(gamepad: ^Gamepad) -> Uint16 ---
	GetGamepadProduct                     :: proc(gamepad: ^Gamepad) -> Uint16 ---
	GetGamepadProductVersion              :: proc(gamepad: ^Gamepad) -> Uint16 ---
	GetGamepadFirmwareVersion             :: proc(gamepad: ^Gamepad) -> Uint16 ---
	GetGamepadSerial                      :: proc(gamepad: ^Gamepad) -> cstring ---
	GetGamepadSteamHandle                 :: proc(gamepad: ^Gamepad) -> Uint64 ---
	GetGamepadConnectionState             :: proc(gamepad: ^Gamepad) -> JoystickConnectionState ---
	GetGamepadPowerInfo                   :: proc(gamepad: ^Gamepad, percent: ^c.int) -> PowerState ---
	GamepadConnected                      :: proc(gamepad: ^Gamepad) -> bool ---
	GetGamepadJoystick                    :: proc(gamepad: ^Gamepad) -> ^Joystick ---
	SetGamepadEventsEnabled               :: proc(enabled: bool) ---
	GamepadEventsEnabled                  :: proc() -> bool ---
	GetGamepadBindings                    :: proc(gamepad: ^Gamepad, count: ^c.int) -> [^]^GamepadBinding ---
	UpdateGamepads                        :: proc() ---
	GetGamepadTypeFromString              :: proc(str: cstring) -> GamepadType ---
	GetGamepadStringForType               :: proc(type: GamepadType) -> cstring ---
	GetGamepadAxisFromString              :: proc(str: cstring) -> GamepadAxis ---
	GetGamepadStringForAxis               :: proc(axis: GamepadAxis) -> cstring ---
	GamepadHasAxis                        :: proc(gamepad: ^Gamepad, axis: GamepadAxis) -> bool ---
	GetGamepadAxis                        :: proc(gamepad: ^Gamepad, axis: GamepadAxis) -> Sint16 ---
	GetGamepadButtonFromString            :: proc(str: cstring) -> GamepadButton ---
	GetGamepadStringForButton             :: proc(button: GamepadButton) -> cstring ---
	GamepadHasButton                      :: proc(gamepad: ^Gamepad, button: GamepadButton) -> bool ---
	GetGamepadButton                      :: proc(gamepad: ^Gamepad, button: GamepadButton) -> bool ---
	GetGamepadButtonLabelForType          :: proc(type: GamepadType, button: GamepadButton) -> GamepadButtonLabel ---
	GetGamepadButtonLabel                 :: proc(gamepad: ^Gamepad, button: GamepadButton) -> GamepadButtonLabel ---
	GetNumGamepadTouchpads                :: proc(gamepad: ^Gamepad) -> c.int ---
	GetNumGamepadTouchpadFingers          :: proc(gamepad: ^Gamepad, touchpad: c.int) -> c.int ---
	GetGamepadTouchpadFinger              :: proc(gamepad: ^Gamepad, touchpad: c.int, finger: c.int, down: ^bool, x, y: ^f32, pressure: ^f32) -> bool ---
	GamepadHasSensor                      :: proc(gamepad: ^Gamepad, type: SensorType) -> bool ---
	SetGamepadSensorEnabled               :: proc(gamepad: ^Gamepad, type: SensorType, enabled: bool) -> bool ---
	GamepadSensorEnabled                  :: proc(gamepad: ^Gamepad, type: SensorType) -> bool ---
	GetGamepadSensorDataRate              :: proc(gamepad: ^Gamepad, type: SensorType) -> f32 ---
	GetGamepadSensorData                  :: proc(gamepad: ^Gamepad, type: SensorType, data: [^]f32, num_values: c.int) -> bool ---
	RumbleGamepad                         :: proc(gamepad: ^Gamepad, low_frequency_rumble, high_frequency_rumble: Uint16, duration_ms: Uint32) -> bool ---
	RumbleGamepadTriggers                 :: proc(gamepad: ^Gamepad, left_rumble, right_rumble: Uint16, duration_ms: Uint32) -> bool ---
	SetGamepadLED                         :: proc(gamepad: ^Gamepad, red, green, blue: Uint8) -> bool ---
	SendGamepadEffect                     :: proc(gamepad: ^Gamepad, data: rawptr, size: c.int) -> bool ---
	CloseGamepad                          :: proc(gamepad: ^Gamepad) ---
	GetGamepadAppleSFSymbolsNameForButton :: proc(gamepad: ^Gamepad, button: GamepadButton) -> cstring ---
	GetGamepadAppleSFSymbolsNameForAxis   :: proc(gamepad: ^Gamepad, axis: GamepadAxis) -> cstring ---
}