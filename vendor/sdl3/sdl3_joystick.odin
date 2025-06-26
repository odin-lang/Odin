package sdl3

import "core:c"

@(link_prefix="SDL_")
foreign lib {
	joystick_lock: ^Mutex
}

Joystick :: struct {}
JoystickID :: distinct Uint32


JoystickType :: enum c.int {
	UNKNOWN,
	GAMEPAD,
	WHEEL,
	ARCADE_STICK,
	FLIGHT_STICK,
	DANCE_PAD,
	GUITAR,
	DRUM_KIT,
	ARCADE_PAD,
	THROTTLE,
}

JOYSTICK_TYPE_COUNT :: len(JoystickType)

JoystickConnectionState :: enum c.int {
	INVALID = -1,
	UNKNOWN,
	WIRED,
	WIRELESS,
}

JOYSTICK_AXIS_MAX :: +32767
JOYSTICK_AXIS_MIN :: -32768


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	LockJoysticks                  :: proc() ---
	UnlockJoysticks                :: proc() ---
	HasJoystick                    :: proc() -> bool ---
	GetJoysticks                   :: proc(count: ^c.int) -> [^]JoystickID ---
	GetJoystickNameForID           :: proc(instance_id: JoystickID) -> cstring ---
	GetJoystickPathForID           :: proc(instance_id: JoystickID) -> cstring ---
	GetJoystickPlayerIndexForID    :: proc(instance_id: JoystickID) -> c.int ---
	GetJoystickGUIDForID           :: proc(instance_id: JoystickID) -> GUID ---
	GetJoystickVendorForID         :: proc(instance_id: JoystickID) -> Uint16 ---
	GetJoystickProductForID        :: proc(instance_id: JoystickID) -> Uint16 ---
	GetJoystickProductVersionForID :: proc(instance_id: JoystickID) -> Uint16 ---
	GetJoystickTypeForID           :: proc(instance_id: JoystickID) -> JoystickType ---
	OpenJoystick                   :: proc(instance_id: JoystickID) -> ^Joystick ---
	GetJoystickFromID              :: proc(instance_id: JoystickID) -> ^Joystick ---
	GetJoystickFromPlayerIndex     :: proc(player_index: c.int) -> ^Joystick ---
}

VirtualJoystickTouchpadDesc :: struct {
	nfingers: Uint16,    /**< the number of simultaneous fingers on this touchpad */
	padding:  [3]Uint16,
}

VirtualJoystickSensorDesc :: struct {
	type: SensorType,    /**< the type of this sensor */
	rate: f32,           /**< the update frequency of this sensor, may be 0.0f */
}

VirtualJoystickDesc :: struct {
	version:     Uint32,    /**< the version of this interface */
	type:        Uint16,    /**< `SDL_JoystickType` */
	padding:     Uint16,    /**< unused */
	vendor_id:   Uint16,    /**< the USB vendor ID of this joystick */
	product_id:  Uint16,    /**< the USB product ID of this joystick */
	naxes:       Uint16,    /**< the number of axes on this joystick */
	nbuttons:    Uint16,    /**< the number of buttons on this joystick */
	nballs:      Uint16,    /**< the number of balls on this joystick */
	nhats:       Uint16,    /**< the number of hats on this joystick */
	ntouchpads:  Uint16,    /**< the number of touchpads on this joystick, requires `touchpads` to point at valid descriptions */
	nsensors:    Uint16,    /**< the number of sensors on this joystick, requires `sensors` to point at valid descriptions */
	padding2:    [2]Uint16, /**< unused */
	button_mask: Uint32,    /**< A mask of which buttons are valid for this controller
                                     e.g. (1 << SDL_GAMEPAD_BUTTON_SOUTH) */
	axis_mask: Uint32,      /**< A mask of which axes are valid for this controller
	                             e.g. (1 << SDL_GAMEPAD_AXIS_LEFTX) */

	name:      cstring,                          /**< the name of the joystick */
	touchpads: [^]VirtualJoystickTouchpadDesc `fmt:"v,ntouchpads"`,   /**< A pointer to an array of touchpad descriptions, required if `ntouchpads` is > 0 */
	sensors:   [^]VirtualJoystickSensorDesc   `fmt:"v,nsensors"`,     /**< A pointer to an array of sensor descriptions, required if `nsensors` is > 0 */

	userdata:          rawptr,                                                                                   /**< User data pointer passed to callbacks */
	Update:            proc "c" (userdata: rawptr),                                                              /**< Called when the joystick state should be updated */
	SetPlayerIndex:    proc "c" (userdata: rawptr, player_index: c.int),                                         /**< Called when the player index is set */
	Rumble:            proc "c" (userdata: rawptr, low_frequency_rumble, high_frequency_rumble: Uint16) -> bool, /**< Implements SDL_RumbleJoystick() */
	RumbleTriggers:    proc "c" (userdata: rawptr, left_rumble, right_rumble: Uint16) -> bool,                   /**< Implements SDL_RumbleJoystickTriggers() */
	SetLED:            proc "c" (userdata: rawptr, red, green, blue: Uint8) -> bool,                             /**< Implements SDL_SetJoystickLED() */
	SendEffect:        proc "c" (userdata: rawptr, data: rawptr, size: c.int) -> bool,                           /**< Implements SDL_SendJoystickEffect() */
	SetSensorsEnabled: proc "c" (userdata: rawptr, enabled: bool) -> bool,                                       /**< Implements SDL_SetGamepadSensorEnabled() */
	Cleanup:           proc "c" (userdata: rawptr),                                                              /**< Cleans up the userdata when the joystick is detached */
}

#assert(
	(size_of(VirtualJoystickDesc) ==  84 && size_of(rawptr) == 4) ||
	(size_of(VirtualJoystickDesc) == 136 && size_of(rawptr) == 8),
)


PROP_JOYSTICK_CAP_MONO_LED_BOOLEAN       :: "SDL.joystick.cap.mono_led"
PROP_JOYSTICK_CAP_RGB_LED_BOOLEAN        :: "SDL.joystick.cap.rgb_led"
PROP_JOYSTICK_CAP_PLAYER_LED_BOOLEAN     :: "SDL.joystick.cap.player_led"
PROP_JOYSTICK_CAP_RUMBLE_BOOLEAN         :: "SDL.joystick.cap.rumble"
PROP_JOYSTICK_CAP_TRIGGER_RUMBLE_BOOLEAN :: "SDL.joystick.cap.trigger_rumble"


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
	AttachVirtualJoystick         :: proc(#by_ptr desc: VirtualJoystickDesc) -> JoystickID ---
	DetachVirtualJoystick         :: proc(instance_id: JoystickID) -> bool ---
	IsJoystickVirtual             :: proc(instance_id: JoystickID) -> bool ---
	SetJoystickVirtualAxis        :: proc(joystick: ^Joystick, axis: c.int, value: Sint16) -> bool ---
	SetJoystickVirtualBall        :: proc(joystick: ^Joystick, ball: c.int, xrel, yrel: Sint16) -> bool ---
	SetJoystickVirtualButton      :: proc(joystick: ^Joystick, button: c.int, down: bool) -> bool ---
	SetJoystickVirtualHat         :: proc(joystick: ^Joystick, hat: c.int, value: Uint8) -> bool ---
	SetJoystickVirtualTouchpad    :: proc(joystick: ^Joystick, touchpad: c.int, finger: c.int, down: bool, x, y: f32, pressure: f32) -> bool ---
	SendJoystickVirtualSensorData :: proc(joystick: ^Joystick, type: SensorType, sensor_timestamp: Uint64, data: [^]f32, num_values: c.int) -> bool ---
	GetJoystickProperties         :: proc(joystick: ^Joystick) -> PropertiesID ---
	GetJoystickName               :: proc(joystick: ^Joystick) -> cstring ---
	GetJoystickPath               :: proc(joystick: ^Joystick) -> cstring ---
	GetJoystickPlayerIndex        :: proc(joystick: ^Joystick) -> c.int ---
	SetJoystickPlayerIndex        :: proc(joystick: ^Joystick, player_index: c.int) -> bool ---
	GetJoystickGUID               :: proc(joystick: ^Joystick) -> GUID ---
	GetJoystickVendor             :: proc(joystick: ^Joystick) -> Uint16 ---
	GetJoystickProduct            :: proc(joystick: ^Joystick) -> Uint16 ---
	GetJoystickProductVersion     :: proc(joystick: ^Joystick) -> Uint16 ---
	GetJoystickFirmwareVersion    :: proc(joystick: ^Joystick) -> Uint16 ---
	GetJoystickSerial             :: proc(joystick: ^Joystick) -> cstring ---
	GetJoystickType               :: proc(joystick: ^Joystick) -> JoystickType ---
	GetJoystickGUIDInfo           :: proc(guid: GUID, vendor, product, version, crc16: ^Uint16) ---
	JoystickConnected             :: proc(joystick: ^Joystick) -> bool ---
	GetJoystickID                 :: proc(joystick: ^Joystick) -> JoystickID ---
	GetNumJoystickAxes            :: proc(joystick: ^Joystick) -> c.int ---
	GetNumJoystickBalls           :: proc(joystick: ^Joystick) -> c.int ---
	GetNumJoystickHats            :: proc(joystick: ^Joystick) -> c.int ---
	GetNumJoystickButtons         :: proc(joystick: ^Joystick) -> c.int ---
	SetJoystickEventsEnabled      :: proc(enabled: bool) ---
	JoystickEventsEnabled         :: proc() -> bool ---
	UpdateJoysticks               :: proc() ---
	GetJoystickAxis               :: proc(joystick: ^Joystick, axis: c.int) -> Sint16 ---
	GetJoystickAxisInitialState   :: proc(joystick: ^Joystick, axis: c.int, state: ^Sint16) -> bool ---
	GetJoystickBall               :: proc(joystick: ^Joystick, ball: c.int, dx, dy: ^c.int) -> bool ---
	GetJoystickHat                :: proc(joystick: ^Joystick, hat: c.int) -> Uint8 ---
	GetJoystickButton             :: proc(joystick: ^Joystick, button: c.int) -> bool ---
	RumbleJoystick                :: proc(joystick: ^Joystick, low_frequency_rumble, high_frequency_rumble: Uint16, duration_ms: Uint32) -> bool ---
	RumbleJoystickTriggers        :: proc(joystick: ^Joystick, left_rumble, right_rumble: Uint16, duration_ms: Uint32) -> bool ---
	SetJoystickLED                :: proc(joystick: ^Joystick, red, green, blue: Uint8) -> bool ---
	SendJoystickEffect            :: proc(joystick: ^Joystick, data: rawptr, size: c.int) -> bool ---
	CloseJoystick                 :: proc(joystick: ^Joystick) ---
	GetJoystickConnectionState    :: proc(joystick: ^Joystick) -> JoystickConnectionState ---
	GetJoystickPowerInfo          :: proc(joystick: ^Joystick, percent: c.int) -> PowerState ---
}
