package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

// Gesture

GestureID :: distinct i64

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	RecordGesture          :: proc(touchId: ^TouchID)                 -> c.int ---
	SaveAllDollarTemplates :: proc(dst: ^RWops)                       -> c.int ---
	SaveDollarTemplate     :: proc(gestureId: GestureID, dst: ^RWops) -> c.int ---
	LoadDollarTemplates    :: proc(touchId: ^TouchID, src: ^RWops)    -> c.int ---
}

// Haptic

Haptic :: struct {}


HapticType :: enum u16 {
	CONSTANT      = 1<<0,
	SINE          = 1<<1,
	LEFTRIGHT     = 1<<2,
	TRIANGLE      = 1<<3,
	SAWTOOTHUP    = 1<<4,
	SAWTOOTHDOWN  = 1<<5,
	RAMP          = 1<<6,
	SPRING        = 1<<7,
	DAMPER        = 1<<8,
	INERTIA       = 1<<9,
	FRICTION      = 1<<10,
	CUSTOM        = 1<<11,
	GAIN          = 1<<12,
	AUTOCENTER    = 1<<13,
	STATUS        = 1<<14,
	PAUSE         = 1<<15,
}
HAPTIC_CONSTANT      :: HapticType.CONSTANT
HAPTIC_SINE          :: HapticType.SINE
HAPTIC_LEFTRIGHT     :: HapticType.LEFTRIGHT
HAPTIC_TRIANGLE      :: HapticType.TRIANGLE
HAPTIC_SAWTOOTHUP    :: HapticType.SAWTOOTHUP
HAPTIC_SAWTOOTHDOWN  :: HapticType.SAWTOOTHDOWN
HAPTIC_RAMP          :: HapticType.RAMP
HAPTIC_SPRING        :: HapticType.SPRING
HAPTIC_DAMPER        :: HapticType.DAMPER
HAPTIC_INERTIA       :: HapticType.INERTIA
HAPTIC_FRICTION      :: HapticType.FRICTION
HAPTIC_CUSTOM        :: HapticType.CUSTOM
HAPTIC_GAIN          :: HapticType.GAIN
HAPTIC_AUTOCENTER    :: HapticType.AUTOCENTER
HAPTIC_STATUS        :: HapticType.STATUS
HAPTIC_PAUSE         :: HapticType.PAUSE

HapticDirectionType :: enum u8 {
	POLAR         = 0,
	CARTESIAN     = 1,
	SPHERICAL     = 2,
	STEERING_AXIS = 3,
}

HAPTIC_POLAR         :: HapticDirectionType.POLAR
HAPTIC_CARTESIAN     :: HapticDirectionType.CARTESIAN
HAPTIC_SPHERICAL     :: HapticDirectionType.SPHERICAL
HAPTIC_STEERING_AXIS :: HapticDirectionType.STEERING_AXIS

HAPTIC_INFINITY :: 4294967295

HapticDirection :: struct {
	type: HapticDirectionType, /**< The type of encoding. */
	dir:  [3]i32,              /**< The encoded direction. */
}

HapticConstant :: struct {
	/* Header */
	type:          HapticType,      /**< ::SDL_HAPTIC_CONSTANT */
	direction:     HapticDirection, /**< Direction of the effect. */

	/* Replay */
	length:        u32,             /**< Duration of the effect. */
	delay:         u16,             /**< Delay before starting the effect. */

	/* Trigger */
	button:        u16,             /**< Button that triggers the effect. */
	interval:      u16,             /**< How soon it can be triggered again after button. */

	/* Constant */
	level:         i16,             /**< Strength of the constant effect. */

	/* Envelope */
	attack_length: u16,             /**< Duration of the attack. */
	attack_level:  u16,             /**< Level at the start of the attack. */
	fade_length:   u16,             /**< Duration of the fade. */
	fade_level:    u16,             /**< Level at the end of the fade. */
}

HapticPeriodic :: struct {
	/* Header */
	type: HapticType,  /**< ::SDL_HAPTIC_SINE, ::SDL_HAPTIC_LEFTRIGHT,
	                        ::SDL_HAPTIC_TRIANGLE, ::SDL_HAPTIC_SAWTOOTHUP or
	                        ::SDL_HAPTIC_SAWTOOTHDOWN */
	direction: HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length: u32,                 /**< Duration of the effect. */
	delay:  u16,                 /**< Delay before starting the effect. */

	/* Trigger */
	button:   u16,               /**< Button that triggers the effect. */
	interval: u16,               /**< How soon it can be triggered again after button. */

	/* Periodic */
	period:    u16,              /**< Period of the wave. */
	magnitude: i16,              /**< Peak value; if negative, equivalent to 180 degrees extra phase shift. */
	offset:    i16,              /**< Mean value of the wave. */
	phase:     u16,              /**< Positive phase shift given by hundredth of a degree. */

	/* Envelope */
	attack_length: u16,          /**< Duration of the attack. */
	attack_level:  u16,          /**< Level at the start of the attack. */
	fade_length:   u16,          /**< Duration of the fade. */
	fade_level:    u16,          /**< Level at the end of the fade. */
}

HapticCondition :: struct {
	/* Header */
	type: HapticType,   /**< ::SDL_HAPTIC_SPRING, ::SDL_HAPTIC_DAMPER,
	                         ::SDL_HAPTIC_INERTIA or ::SDL_HAPTIC_FRICTION */
	direction: HapticDirection, /**< Direction of the effect - Not used ATM. */

	/* Replay */
	length: u32,         /**< Duration of the effect. */
	delay:  u16,         /**< Delay before starting the effect. */

	/* Trigger */
	button:   u16,       /**< Button that triggers the effect. */
	interval: u16,       /**< How soon it can be triggered again after button. */

	/* Condition */
	right_sat:   [3]u16, /**< Level when joystick is to the positive side; max 0xFFFF. */
	left_sat:    [3]u16, /**< Level when joystick is to the negative side; max 0xFFFF. */
	right_coeff: [3]i16, /**< How fast to increase the force towards the positive side. */
	left_coeff:  [3]i16, /**< How fast to increase the force towards the negative side. */
	deadband:    [3]u16, /**< Size of the dead zone; max 0xFFFF: whole axis-range when 0-centered. */
	center:      [3]i16, /**< Position of the dead zone. */
}

HapticRamp :: struct {
	/* Header */
	type: HapticType,            /**< ::SDL_HAPTIC_RAMP */
	direction: HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length: u32,        /**< Duration of the effect. */
	delay:  u16,        /**< Delay before starting the effect. */

	/* Trigger */
	button:   u16,      /**< Button that triggers the effect. */
	interval: u16,      /**< How soon it can be triggered again after button. */

	/* Ramp */
	start: i16,         /**< Beginning strength level. */
	end:   i16,         /**< Ending strength level. */

	/* Envelope */
	attack_length: u16, /**< Duration of the attack. */
	attack_level:  u16, /**< Level at the start of the attack. */
	fade_length:   u16, /**< Duration of the fade. */
	fade_level:    u16, /**< Level at the end of the fade. */
}

HapticLeftRight :: struct {
	/* Header */
	type: HapticType,            /**< ::SDL_HAPTIC_LEFTRIGHT */

	/* Replay */
	length: u32,          /**< Duration of the effect in milliseconds. */

	/* Rumble */
	large_magnitude: u16, /**< Control of the large controller motor. */
	small_magnitude: u16, /**< Control of the small controller motor. */
}


HapticCustom :: struct {
	/* Header */
	type: HapticType,           /**< ::SDL_HAPTIC_CUSTOM */
	direction: HapticDirection, /**< Direction of the effect. */

	/* Replay */
	length:        u32,  /**< Duration of the effect. */
	delay:         u16,  /**< Delay before starting the effect. */

	/* Trigger */
	button:        u16,  /**< Button that triggers the effect. */
	interval:      u16,  /**< How soon it can be triggered again after button. */

	/* Custom */
	channels:      u8,     /**< Axes to use, minimum of one. */
	period:        u16,    /**< Sample periods. */
	samples:       u16,    /**< Amount of samples. */
	data:          [^]u16, /**< Should contain channels*samples items. */

	/* Envelope */
	attack_length: u16,  /**< Duration of the attack. */
	attack_level:  u16,  /**< Level at the start of the attack. */
	fade_length:   u16,  /**< Duration of the fade. */
	fade_level:    u16,  /**< Level at the end of the fade. */
}

HapticEffect :: struct #raw_union {
	/* Common for all force feedback effects */
	type:      HapticType,      /**< Effect type. */
	constant:  HapticConstant,  /**< Constant effect. */
	periodic:  HapticPeriodic,  /**< Periodic effect. */
	condition: HapticCondition, /**< Condition effect. */
	ramp:      HapticRamp,      /**< Ramp effect. */
	leftright: HapticLeftRight, /**< Left/Right effect. */
	custom:    HapticCustom,    /**< Custom effect. */
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	NumHaptics              :: proc() -> c.int ---
	HapticName              :: proc(device_index: c.int) -> cstring ---
	HapticOpen              :: proc(device_index: c.int) -> ^Haptic ---
	HapticOpened            :: proc(device_index: c.int) -> c.int ---
	HapticIndex             :: proc(haptic: ^Haptic) -> c.int ---
	MouseIsHaptic           :: proc() -> c.int ---
	HapticOpenFromMouse     :: proc() -> ^Haptic ---
	JoystickIsHaptic        :: proc(joystick: ^Joystick) -> c.int ---
	HapticOpenFromJoystick  :: proc(joystick: ^Joystick) -> ^Haptic ---
	HapticClose             :: proc(haptic: ^Haptic) ---
	HapticNumEffects        :: proc(haptic: ^Haptic) -> c.int ---
	HapticNumEffectsPlaying :: proc(haptic: ^Haptic) -> c.int ---
	HapticQuery             :: proc(haptic: ^Haptic) -> c.uint ---
	HapticNumAxes           :: proc(haptic: ^Haptic) -> c.int ---
	HapticEffectSupported   :: proc(haptic: ^Haptic, effect: ^HapticEffect) -> c.int ---
	HapticNewEffect         :: proc(haptic: ^Haptic, effect: ^HapticEffect) -> c.int ---
	HapticUpdateEffect      :: proc(haptic: ^Haptic, effect: c.int, data: ^HapticEffect) -> c.int ---
	HapticRunEffect         :: proc(haptic: ^Haptic, effect: c.int, iterations: u32) -> c.int ---
	HapticStopEffect        :: proc(haptic: ^Haptic, effect: c.int) -> c.int ---
	HapticDestroyEffect     :: proc(haptic: ^Haptic, effect: c.int) ---
	HapticGetEffectStatus   :: proc(haptic: ^Haptic, effect: c.int) -> c.int ---
	HapticSetGain           :: proc(haptic: ^Haptic, gain: c.int) -> c.int ---
	HapticSetAutocenter     :: proc(haptic: ^Haptic, autocenter: c.int) -> c.int ---
	HapticPause             :: proc(haptic: ^Haptic) -> c.int ---
	HapticUnpause           :: proc(haptic: ^Haptic) -> c.int ---
	HapticStopAll           :: proc(haptic: ^Haptic) -> c.int ---
	HapticRumbleSupported   :: proc(haptic: ^Haptic) -> c.int ---
	HapticRumbleInit        :: proc(haptic: ^Haptic) -> c.int ---
	HapticRumblePlay        :: proc(haptic: ^Haptic, strength: f32, length: u32) -> c.int ---
	HapticRumbleStop        :: proc(haptic: ^Haptic) -> c.int ---
}
