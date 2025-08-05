package sdl2

/*
	Simple DirectMedia Layer
	Copyright (C) 1997-2017 Sam Lantinga <slouken@libsdl.org>

	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	  claim that you wrote the original software. If you use this software
	  in a product, an acknowledgment in the product documentation would be
	  appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	  misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/


import "core:c"
import "base:intrinsics"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

version :: struct {
	major: u8,        /**< major version */
	minor: u8,        /**< minor version */
	patch: u8,        /**< update version */
}

MAJOR_VERSION   :: 2
MINOR_VERSION   :: 0
PATCHLEVEL      :: 16

VERSION :: proc "contextless" (ver: ^version) {
	ver.major = MAJOR_VERSION
	ver.minor = MINOR_VERSION
	ver.patch = PATCHLEVEL
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetVersion  :: proc(ver: ^version) ---
	GetRevision :: proc() -> cstring ---

}

InitFlag :: enum u32 {
	TIMER          =  0x00,
	AUDIO          =  0x04,
	VIDEO          =  0x05,
	JOYSTICK       =  0x09,
	HAPTIC         =  0x0c,
	GAMECONTROLLER =  0x0d,
	EVENTS         =  0x0e,
	SENSOR         =  0x0f,
	NOPARACHUTE    =  0x14,
}

InitFlags :: bit_set[InitFlag; u32]

INIT_TIMER          :: InitFlags{.TIMER}
INIT_AUDIO          :: InitFlags{.AUDIO}
INIT_VIDEO          :: InitFlags{.VIDEO}           /**< INIT_VIDEO implies INIT_EVENTS */
INIT_JOYSTICK       :: InitFlags{.JOYSTICK}        /**< INIT_JOYSTICK implies INIT_EVENTS */
INIT_HAPTIC         :: InitFlags{.HAPTIC}
INIT_GAMECONTROLLER :: InitFlags{.GAMECONTROLLER}  /**< INIT_GAMECONTROLLER implies INIT_JOYSTICK */
INIT_EVENTS         :: InitFlags{.EVENTS}
INIT_SENSOR         :: InitFlags{.SENSOR}
INIT_NOPARACHUTE    :: InitFlags{.NOPARACHUTE}     /**< compatibility; this flag is ignored. */
INIT_EVERYTHING :: InitFlags{.TIMER, .AUDIO, .VIDEO, .EVENTS, .JOYSTICK, .HAPTIC, .GAMECONTROLLER, .SENSOR}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Init          :: proc(flags: InitFlags) -> c.int     ---
	InitSubSystem :: proc(flags: InitFlags) -> c.int     ---
	QuitSubSystem :: proc(flags: InitFlags)              ---
	WasInit       :: proc(flags: InitFlags) -> InitFlags ---
	Quit          :: proc() ---
}



// Atomic
// NOTE: Prefer the intrinsics built into Odin 'package intrinsics'
SpinLock :: distinct c.int
atomic_t :: struct { value: c.int }

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	AtomicTryLock                :: proc(lock: ^SpinLock) -> bool ---
	AtomicLock                   :: proc(lock: ^SpinLock) ---
	AtomicUnlock                 :: proc(lock: ^SpinLock) ---
	MemoryBarrierReleaseFunction :: proc() ---
	MemoryBarrierAcquireFunction :: proc() ---
	AtomicCAS                    :: proc(a: ^atomic_t, oldval, newval: c.int) -> bool ---
	AtomicSet                    :: proc(a: ^atomic_t, v: c.int) -> c.int ---
	AtomicGet                    :: proc(a: ^atomic_t) -> c.int ---
	AtomicAdd                    :: proc(a: ^atomic_t, v: c.int) -> c.int ---
	AtomicCASPtr                 :: proc(a: ^rawptr, oldval, newval: rawptr) -> bool ---
	AtomicSetPtr                 :: proc(a: ^rawptr, v: rawptr) -> rawptr ---
	AtomicGetPtr                 :: proc(a: ^rawptr) -> rawptr ---
}


// Bits
MostSignificantBitIndex32 :: #force_inline proc "c" (x: u32) -> c.int {
	return c.int(intrinsics.count_leading_zeros(x))
}

HasExactlyOneBitSet32 :: #force_inline proc "c" (x: u32) -> bool {
	return intrinsics.count_ones(x) == 1
}

// Clipboard

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetClipboardText :: proc(text: cstring) -> c.int ---
	GetClipboardText :: proc() -> cstring ---
	HasClipboardText :: proc() -> bool ---
}


// Error

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetError    :: proc(fmt: cstring, #c_vararg args: ..any) -> c.int ---
	GetError    :: proc() -> cstring ---
	GetErrorMsg :: proc(errstr: [^]u8, maxlen: c.int) -> cstring ---
	ClearError  :: proc() ---
}

GetErrorString :: proc "c" () -> string {
	return string(GetError())
}
GetErrorMsgString :: proc "c" (buf: []u8) -> string {
	cstr := GetErrorMsg(raw_data(buf), c.int(len(buf)))
	return string(cstr)
}


/**
 *  \name Internal error functions
 *
 *  \internal
 *  Private error reporting function - used internally.
 */
OutOfMemory       :: #force_inline proc "c" ()               -> c.int { return Error(.ENOMEM) }
Unsupported       :: #force_inline proc "c" ()               -> c.int { return Error(.UNSUPPORTED) }
InvalidParamError :: #force_inline proc "c" (param: cstring) -> c.int { return SetError("Parameter '%s' is invalid", param) }

errorcode :: enum c.int {
	ENOMEM,
	EFREAD,
	EFWRITE,
	EFSEEK,
	UNSUPPORTED,
	LASTERROR,
}

/* SDL_Error() unconditionally returns -1. */
@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	Error :: proc(code: errorcode) -> c.int ---
}


// Filesystem

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetBasePath :: proc() -> cstring ---
	GetPrefPath :: proc(org, app: cstring) -> cstring ---
}


// loadso

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	LoadObject   :: proc(sofile: cstring) -> rawptr ---
	LoadFunction :: proc(handle: rawptr, name: cstring) -> rawptr ---
	UnloadObject :: proc(handle: rawptr) ---
}


// locale


Locale :: struct {
	language: cstring, /**< A language name, like "en" for English. */
	country:  cstring, /**< A country, like "US" for America. Can be NULL. */
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetPreferredLocales :: proc() -> [^]Locale ---
}

// misc

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	OpenURL :: proc(url: cstring) -> c.int ---
}

// platform

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetPlatform :: proc() -> cstring ---
}

// power

PowerState :: enum c.int {
	UNKNOWN,      /**< cannot determine power status */
	ON_BATTERY,   /**< Not plugged in, running on the battery */
	NO_BATTERY,   /**< Plugged in, no battery available */
	CHARGING,     /**< Plugged in, charging battery */
	CHARGED,      /**< Plugged in, battery charged */
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetPowerInfo :: proc(secs: ^c.int, pct: ^c.int) -> PowerState ---
}

// quit

QuitRequested :: #force_inline proc "c" () -> bool {
	PumpEvents()
	return bool(PeepEvents(nil, 0, .PEEKEVENT, .QUIT, .QUIT) > 0)
}


// sensor

Sensor :: struct {}

SensorID :: distinct i32

SensorType :: enum c.int {
	INVALID = -1,    /**< Returned for an invalid sensor */
	UNKNOWN,         /**< Unknown sensor type */
	ACCEL,           /**< Accelerometer */
	GYRO,            /**< Gyroscope */
}

STANDARD_GRAVITY :: 9.80665


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	LockSensors                    :: proc() ---
	UnlockSensors                  :: proc() ---
	NumSensors                     :: proc() -> c.int ---
	SensorGetDeviceName            :: proc(device_index: c.int) -> cstring ---
	SensorGetDeviceType            :: proc(device_index: c.int) -> SensorType ---
	SensorGetDeviceNonPortableType :: proc(device_index: c.int) -> c.int ---
	SensorGetDeviceInstanceID      :: proc(device_index: c.int) -> SensorID ---
	SensorOpen                     :: proc(device_index: c.int) -> ^Sensor ---
	SensorFromInstanceID           :: proc(instance_id: SensorID) -> ^Sensor ---
	SensorGetName                  :: proc(sensor: ^Sensor) -> cstring ---
	SensorGetType                  :: proc(sensor: ^Sensor) -> SensorType ---
	SensorGetNonPortableType       :: proc(sensor: ^Sensor) -> c.int ---
	SensorGetInstanceID            :: proc(sensor: ^Sensor) -> SensorID ---
	SensorGetData                  :: proc(sensor: ^Sensor, data: [^]f32, num_values: c.int) -> c.int ---
	SensorClose                    :: proc(sensor: ^Sensor) ---
	SensorUpdate                   :: proc() ---
}


// shape

NONSHAPEABLE_WINDOW    :: -1
INVALID_SHAPE_ARGUMENT :: -2
WINDOW_LACKS_SHAPE     :: -3

WindowShapeModeEnum :: enum c.int {
	/** \brief The default mode, a binarized alpha cutoff of 1. */
	Default,
	/** \brief A binarized alpha cutoff with a given integer value. */
	BinarizeAlpha,
	/** \brief A binarized alpha cutoff with a given integer value, but with the opposite comparison. */
	ReverseBinarizeAlpha,
	/** \brief A color key is applied. */
	ColorKey,
}

SHAPEMODEALPHA :: #force_inline proc "c" (mode: WindowShapeModeEnum) -> bool {
	return bool(mode == .Default || mode == .BinarizeAlpha || mode == .ReverseBinarizeAlpha)
}


WindowShapeParams :: struct #raw_union {
	binarizationCutoff: u8,
	colorKey:           Color,
}

WindowShapeMode :: struct {
	mode:       WindowShapeModeEnum,
	parameters: WindowShapeParams,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	CreateShapedWindow  :: proc(title: cstring, x, y, w, h: c.uint, flags: WindowFlags) -> ^Window ---
	IsShapedWindow      :: proc(window: ^Window) -> bool ---
	SetWindowShape      :: proc(window: ^Window, shape: ^Surface, shape_mode: ^WindowShapeMode) -> c.int ---
	GetShapedWindowMode :: proc(window: ^Window, shape_mode: ^WindowShapeMode) -> c.int ---
}
