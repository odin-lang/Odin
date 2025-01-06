#+build windows
package sys_windows

foreign import "system:xinput.lib"

// Device types available in XINPUT_CAPABILITIES
// Correspond to XINPUT_DEVTYPE_...
XINPUT_DEVTYPE :: enum BYTE {
	GAMEPAD = 0x01,
}

// Device subtypes available in XINPUT_CAPABILITIES
// Correspond to XINPUT_DEVSUBTYPE_...
XINPUT_DEVSUBTYPE :: enum BYTE {
	UNKNOWN          = 0x00,
	GAMEPAD          = 0x01,
	WHEEL            = 0x02,
	ARCADE_STICK     = 0x03,
	FLIGHT_STICK     = 0x04,
	DANCE_PAD        = 0x05,
	GUITAR           = 0x06,
	GUITAR_ALTERNATE = 0x07,
	DRUM_KIT         = 0x08,
	GUITAR_BASS      = 0x0B,
	ARCADE_PAD       = 0x13,
}

// Flags for XINPUT_CAPABILITIES
// Correspond to log2(XINPUT_CAPS_...)
XINPUT_CAP :: enum WORD {
	FFB_SUPPORTED   = 0,
	WIRELESS        = 1,
	VOICE_SUPPORTED = 2,
	PMD_SUPPORTED   = 3,
	NO_NAVIGATION   = 4,
}
XINPUT_CAPS :: distinct bit_set[XINPUT_CAP;WORD]

// Constants for gamepad buttons
// Correspond to log2(XINPUT_GAMEPAD_...)
XINPUT_GAMEPAD_BUTTON_BIT :: enum WORD {
	DPAD_UP        = 0,
	DPAD_DOWN      = 1,
	DPAD_LEFT      = 2,
	DPAD_RIGHT     = 3,
	START          = 4,
	BACK           = 5,
	LEFT_THUMB     = 6,
	RIGHT_THUMB    = 7,
	LEFT_SHOULDER  = 8,
	RIGHT_SHOULDER = 9,
	A              = 12,
	B              = 13,
	X              = 14,
	Y              = 15,
}
XINPUT_GAMEPAD_BUTTON :: distinct bit_set[XINPUT_GAMEPAD_BUTTON_BIT;WORD]

// Gamepad thresholds
XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE: SHORT : 7849
XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE: SHORT : 8689
XINPUT_GAMEPAD_TRIGGER_THRESHOLD: SHORT : 30

// Flags to pass to XInputGetCapabilities
// Corresponds to log2(XINPUT_FLAG_...)
XINPUT_FLAG_BIT :: enum WORD {
	GAMEPAD = 0,
}
XINPUT_FLAG :: distinct bit_set[XINPUT_FLAG_BIT;DWORD]

// Devices that support batteries
// Corresponds to BATTERY_DEVTYPE_...
BATTERY_DEVTYPE :: enum BYTE {
	GAMEPAD = 0x00,
	HEADSET = 0x01,
}

// Flags for battery status level
// Correspond to BATTERY_TYPE_...
BATTERY_TYPE :: enum BYTE {
	DISCONNECTED = 0x00, // This device is not connected
	WIRED        = 0x01, // Wired device, no battery
	ALKALINE     = 0x02, // Alkaline battery source
	NIMH         = 0x03, // Nickel Metal Hydride battery source
	UNKNOWN      = 0xFF, // Cannot determine the battery type
}

// These are only valid for wireless, connected devices, with known battery types
// The amount of use time remaining depends on the type of device.
// Correspond to BATTERY_LEVEL_...
BATTERY_LEVEL :: enum BYTE {
	EMPTY  = 0x00,
	LOW    = 0x01,
	MEDIUM = 0x02,
	FULL   = 0x03,
}

// User index definitions

// Index of the gamer associated with the device
XUSER :: enum DWORD {
	One   = 0,
	Two   = 1,
	Three = 2,
	Four  = 3,
	Any   = 0x000000FF, // Can be only used with XInputGetKeystroke
}

XUSER_MAX_COUNT :: 4

// Codes returned for the gamepad keystroke
// Corresponds to VK_PAD_...
VK_PAD :: enum WORD {
	A                = 0x5800,
	B                = 0x5801,
	X                = 0x5802,
	Y                = 0x5803,
	RSHOULDER        = 0x5804,
	LSHOULDER        = 0x5805,
	LTRIGGER         = 0x5806,
	RTRIGGER         = 0x5807,
	DPAD_UP          = 0x5810,
	DPAD_DOWN        = 0x5811,
	DPAD_LEFT        = 0x5812,
	DPAD_RIGHT       = 0x5813,
	START            = 0x5814,
	BACK             = 0x5815,
	LTHUMB_PRESS     = 0x5816,
	RTHUMB_PRESS     = 0x5817,
	LTHUMB_UP        = 0x5820,
	LTHUMB_DOWN      = 0x5821,
	LTHUMB_RIGHT     = 0x5822,
	LTHUMB_LEFT      = 0x5823,
	LTHUMB_UPLEFT    = 0x5824,
	LTHUMB_UPRIGHT   = 0x5825,
	LTHUMB_DOWNRIGHT = 0x5826,
	LTHUMB_DOWNLEFT  = 0x5827,
	RTHUMB_UP        = 0x5830,
	RTHUMB_DOWN      = 0x5831,
	RTHUMB_RIGHT     = 0x5832,
	RTHUMB_LEFT      = 0x5833,
	RTHUMB_UPLEFT    = 0x5834,
	RTHUMB_UPRIGHT   = 0x5835,
	RTHUMB_DOWNRIGHT = 0x5836,
	RTHUMB_DOWNLEFT  = 0x5837,
}

// Flags used in XINPUT_KEYSTROKE
// Correspond to log2(XINPUT_KEYSTROKE_...)
XINPUT_KEYSTROKE_BIT :: enum WORD {
	KEYDOWN = 0,
	KEYUP   = 1,
	REPEAT  = 2,
}
XINPUT_KEYSTROKES :: distinct bit_set[XINPUT_KEYSTROKE_BIT;WORD]

// Structures used by XInput APIs
XINPUT_GAMEPAD :: struct {
	wButtons:      XINPUT_GAMEPAD_BUTTON,
	bLeftTrigger:  BYTE,
	bRightTrigger: BYTE,
	sThumbLX:      SHORT,
	sThumbLY:      SHORT,
	sThumbRX:      SHORT,
	sThumbRY:      SHORT,
}

XINPUT_STATE :: struct {
	dwPacketNumber: DWORD,
	Gamepad:        XINPUT_GAMEPAD,
}

XINPUT_VIBRATION :: struct {
	wLeftMotorSpeed:  WORD,
	wRightMotorSpeed: WORD,
}

XINPUT_CAPABILITIES :: struct {
	Type:      XINPUT_DEVTYPE,
	SubType:   XINPUT_DEVSUBTYPE,
	Flags:     XINPUT_CAPS,
	Gamepad:   XINPUT_GAMEPAD,
	Vibration: XINPUT_VIBRATION,
}

XINPUT_BATTERY_INFORMATION :: struct {
	BatteryType:  BATTERY_TYPE,
	BatteryLevel: BATTERY_LEVEL,
}

XINPUT_KEYSTROKE :: struct {
	VirtualKey: VK_PAD,
	Unicode:    WCHAR,
	Flags:      XINPUT_KEYSTROKES,
	UserIndex:  XUSER,
	HidCode:    BYTE,
}

// XInput APIs
@(default_calling_convention = "system")
foreign xinput {
	XInputGetState :: proc(user: XUSER, pState: ^XINPUT_STATE) -> System_Error ---
	XInputSetState :: proc(user: XUSER, pVibration: ^XINPUT_VIBRATION) -> System_Error ---
	XInputGetCapabilities :: proc(user: XUSER, dwFlags: XINPUT_FLAG, pCapabilities: ^XINPUT_CAPABILITIES) -> System_Error ---
	XInputEnable :: proc(enable: BOOL) ---
	XInputGetAudioDeviceIds :: proc(user: XUSER, pRenderDeviceId: LPWSTR, pRenderCount: ^UINT, pCaptureDeviceId: LPWSTR, pCaptureCount: ^UINT) -> System_Error ---
	XInputGetBatteryInformation :: proc(user: XUSER, devType: BATTERY_DEVTYPE, pBatteryInformation: ^XINPUT_BATTERY_INFORMATION) -> System_Error ---
	XInputGetKeystroke :: proc(user: XUSER, dwReserved: DWORD, pKeystroke: ^XINPUT_KEYSTROKE) -> System_Error ---
	XInputGetDSoundAudioDeviceGuids :: proc(user: XUSER, pDSoundRenderGuid: ^GUID, pDSoundCaptureGuid: ^GUID) -> System_Error ---
}
