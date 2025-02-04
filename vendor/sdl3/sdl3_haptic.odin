package sdl3

import "core:c"

Haptic :: struct {}

HapticType :: Uint16

HAPTIC_CONSTANT     :: 1<<0
HAPTIC_SINE         :: 1<<1
HAPTIC_SQUARE       :: 1<<2
HAPTIC_TRIANGLE     :: 1<<3
HAPTIC_SAWTOOTHUP   :: 1<<4
HAPTIC_SAWTOOTHDOWN :: 1<<5
HAPTIC_RAMP         :: 1<<6
HAPTIC_SPRING       :: 1<<7
HAPTIC_DAMPER       :: 1<<8
HAPTIC_INERTIA      :: 1<<9
HAPTIC_FRICTION     :: 1<<10
HAPTIC_LEFTRIGHT    :: 1<<11
HAPTIC_RESERVED1    :: 1<<12
HAPTIC_RESERVED2    :: 1<<13
HAPTIC_RESERVED3    :: 1<<14
HAPTIC_CUSTOM       :: 1<<15
HAPTIC_GAIN         :: 1<<16
HAPTIC_AUTOCENTER   :: 1<<17
HAPTIC_STATUS       :: 1<<18
HAPTIC_PAUSE        :: 1<<19

HapticDirectionType :: enum Uint8 {
	POLAR         = 0,
	CARTESIAN     = 1,
	SPHERICAL     = 2,
	STEERING_AXIS = 3,
}

HAPTIC_INFINITY :: c.uint(4294967295)


HapticDirection :: struct {
	type: HapticDirectionType, /**< The type of encoding. */
	dir:  [3]Sint32,           /**< The encoded direction. */
}


HapticConstant :: struct {
	/* Header */
	type:          HapticType,       /**< HAPTIC_CONSTANT */
	direction:     HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length:        Uint32,           /**< Duration of the effect. */
	delay:         Uint16,           /**< Delay before starting the effect. */

	/* Trigger */
	button:        Uint16,           /**< Button that triggers the effect. */
	interval:      Uint16,           /**< How soon it can be triggered again after button. */

	/* Constant */
	level:         Sint16,           /**< Strength of the constant effect. */

	/* Envelope */
	attack_length: Uint16,           /**< Duration of the attack. */
	attack_level:  Uint16,           /**< Level at the start of the attack. */
	fade_length:   Uint16,           /**< Duration of the fade. */
	fade_level:    Uint16,           /**< Level at the end of the fade. */
}

HapticPeriodic :: struct {
	/* Header */
	type: HapticType,            /**< HAPTIC_SINE, HAPTIC_SQUARE
	                                  HAPTIC_TRIANGLE, HAPTIC_SAWTOOTHUP or
	                                  HAPTIC_SAWTOOTHDOWN */
	direction: HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length: Uint32,         /**< Duration of the effect. */
	delay:  Uint16,         /**< Delay before starting the effect. */

	/* Trigger */
	button:   Uint16,       /**< Button that triggers the effect. */
	interval: Uint16,       /**< How soon it can be triggered again after button. */

	/* Periodic */
	period:    Uint16,      /**< Period of the wave. */
	magnitude: Sint16,      /**< Peak value; if negative, equivalent to 180 degrees extra phase shift. */
	offset:    Sint16,      /**< Mean value of the wave. */
	phase:     Uint16,      /**< Positive phase shift given by hundredth of a degree. */

	/* Envelope */
	attack_length: Uint16,  /**< Duration of the attack. */
	attack_level:  Uint16,  /**< Level at the start of the attack. */
	fade_length:   Uint16,  /**< Duration of the fade. */
	fade_level:    Uint16,  /**< Level at the end of the fade. */
}

HapticCondition :: struct {
	/* Header */
	type: HapticType,            /**< HAPTIC_SPRING, HAPTIC_DAMPER,
                                          HAPTIC_INERTIA or HAPTIC_FRICTION */
	direction: HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length: Uint32,              /**< Duration of the effect. */
	delay: Uint16,               /**< Delay before starting the effect. */

	/* Trigger */
	button: Uint16,              /**< Button that triggers the effect. */
	interval: Uint16,            /**< How soon it can be triggered again after button. */

	/* Condition */
	right_sat:   [3]Uint16,      /**< Level when joystick is to the positive side; max 0xFFFF. */
	left_sat:    [3]Uint16,      /**< Level when joystick is to the negative side; max 0xFFFF. */
	right_coeff: [3]Sint16,      /**< How fast to increase the force towards the positive side. */
	left_coeff:  [3]Sint16,      /**< How fast to increase the force towards the negative side. */
	deadband:    [3]Uint16,      /**< Size of the dead zone; max 0xFFFF: whole axis-range when 0-centered. */
	center:      [3]Sint16,      /**< Position of the dead zone. */
}

HapticRamp :: struct {
	/* Header */
	type:          HapticType,       /**< HAPTIC_RAMP */
	direction:     HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length:        Uint32,           /**< Duration of the effect. */
	delay:         Uint16,           /**< Delay before starting the effect. */

	/* Trigger */
	button:        Uint16,           /**< Button that triggers the effect. */
	interval:      Uint16,           /**< How soon it can be triggered again after button. */

	/* Ramp */
	start:         Sint16,           /**< Beginning strength level. */
	end:           Sint16,           /**< Ending strength level. */

	/* Envelope */
	attack_length: Uint16,           /**< Duration of the attack. */
	attack_level:  Uint16,           /**< Level at the start of the attack. */
	fade_length:   Uint16,           /**< Duration of the fade. */
	fade_level:    Uint16,           /**< Level at the end of the fade. */
}


HapticLeftRight :: struct {
	/* Header */
	type: HapticType,        /**< HAPTIC_LEFTRIGHT */

	/* Replay */
	length: Uint32,          /**< Duration of the effect in milliseconds. */

	/* Rumble */
	large_magnitude: Uint16, /**< Control of the large controller motor. */
	small_magnitude: Uint16, /**< Control of the small controller motor. */
}


HapticCustom :: struct {
	/* Header */
	type:          HapticType,       /**< HAPTIC_CUSTOM */
	direction:     HapticDirection,  /**< Direction of the effect. */

	/* Replay */
	length:        Uint32,           /**< Duration of the effect. */
	delay:         Uint16,           /**< Delay before starting the effect. */

	/* Trigger */
	button:        Uint16,           /**< Button that triggers the effect. */
	interval:      Uint16,           /**< How soon it can be triggered again after button. */

	/* Custom */
	channels:      Uint8,            /**< Axes to use, minimum of one. */
	period:        Uint16,           /**< Sample periods. */
	samples:       Uint16,           /**< Amount of samples. */
	data:          [^]Uint16,        /**< Should contain channels*samples items. */

	/* Envelope */
	attack_length: Uint16,           /**< Duration of the attack. */
	attack_level:  Uint16,           /**< Level at the start of the attack. */
	fade_length:   Uint16,           /**< Duration of the fade. */
	fade_level:    Uint16,           /**< Level at the end of the fade. */
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


HapticID :: distinct Uint32


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetHaptics                 :: proc(count: ^c.int) -> ^HapticID ---
	GetHapticNameForID         :: proc(instance_id: HapticID) -> cstring ---
	OpenHaptic                 :: proc(instance_id: HapticID) -> ^Haptic ---
	GetHapticFromID            :: proc(instance_id: HapticID) -> ^Haptic ---
	GetHapticID                :: proc(haptic: ^Haptic) -> HapticID ---
	GetHapticName              :: proc(haptic: ^Haptic) -> cstring ---
	IsMouseHaptic              :: proc() -> bool ---
	OpenHapticFromMouse        :: proc() -> ^Haptic ---
	IsJoystickHaptic           :: proc(joystick: ^Joystick) -> bool ---
	OpenHapticFromJoystick     :: proc(joystick: ^Joystick) -> ^Haptic ---
	CloseHaptic                :: proc(haptic: ^Haptic) ---
	GetMaxHapticEffects        :: proc(haptic: ^Haptic) -> c.int ---
	GetMaxHapticEffectsPlaying :: proc(haptic: ^Haptic) -> c.int ---
	GetHapticFeatures          :: proc(haptic: ^Haptic) -> Uint32 ---
	GetNumHapticAxes           :: proc(haptic: ^Haptic) -> c.int ---
	HapticEffectSupported      :: proc(haptic: ^Haptic, #by_ptr effect: HapticEffect) -> bool ---
	CreateHapticEffect         :: proc(haptic: ^Haptic, #by_ptr effect: HapticEffect) -> c.int ---
	UpdateHapticEffect         :: proc(haptic: ^Haptic, effect: c.int, #by_ptr data: HapticEffect) -> bool ---
	RunHapticEffect            :: proc(haptic: ^Haptic, effect: c.int, iterations: Uint32) -> bool ---
	StopHapticEffect           :: proc(haptic: ^Haptic, effect: c.int) -> bool ---
	DestroyHapticEffect        :: proc(haptic: ^Haptic, effect: c.int) ---
	GetHapticEffectStatus      :: proc(haptic: ^Haptic, effect: c.int) -> bool ---
	SetHapticGain              :: proc(haptic: ^Haptic, gain: c.int) -> bool ---
	SetHapticAutocenter        :: proc(haptic: ^Haptic, autocenter: c.int) -> bool ---
	PauseHaptic                :: proc(haptic: ^Haptic) -> bool ---
	ResumeHaptic               :: proc(haptic: ^Haptic) -> bool ---
	StopHapticEffects          :: proc(haptic: ^Haptic) -> bool ---
	HapticRumbleSupported      :: proc(haptic: ^Haptic) -> bool ---
	InitHapticRumble           :: proc(haptic: ^Haptic) -> bool ---
	PlayHapticRumble           :: proc(haptic: ^Haptic, strength: f32, length: Uint32) -> bool ---
	StopHapticRumble           :: proc(haptic: ^Haptic) -> bool ---
}