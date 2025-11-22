/*!
 * libretro.h is a simple API that allows for the creation of games and emulators.
 *
 * @file libretro.h
 * @version 1
 * @author libretro
 * @copyright Copyright (C) 2010-2024 The RetroArch team
 *
 * @paragraph LICENSE
 * The following license statement only applies to this libretro API header (libretro.h).
 *
 * Copyright (C) 2010-2024 The RetroArch team
 *
 * Permission is hereby granted, free of charge,
 * to any person obtaining a copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package libretro

import "core:c"

/**
* The major version of the libretro API and ABI.
* Cores may support multiple versions,
* or they may reject cores with unsupported versions.
* It is only incremented for incompatible API/ABI changes;
* this generally implies a function was removed or changed,
* or that a \c struct had fields removed or changed.
* @note A design goal of libretro is to avoid having to increase this value at all costs.
* This is why there are APIs that are "extended" or "V2".
*/
API_VERSION         :: 1

/**
* @defgroup DEVICE Input Devices
* @brief Libretro's fundamental device abstractions.
*
* Libretro's input system consists of abstractions over standard device types,
* such as a joypad (with or without analog), mouse, keyboard, light gun, or an abstract pointer.
* Instead of managing input devices themselves,
* cores need only to map their own concept of a controller to libretro's abstractions.
* This makes it possible for frontends to map the abstract types to a real input device
* without having to worry about the correct use of arbitrary (real) controller layouts.
* @{
*/
DEVICE_TYPE_SHIFT         :: 8
DEVICE_MASK               :: ((1<<DEVICE_TYPE_SHIFT)-1)

/**
* @defgroup DEVICE Input Device Classes
* @{
*/

/**
* Indicates no input.
*
* When provided as the \c device argument to \c retro_input_state_t,
* all other arguments are ignored and zero is returned.
*
* @see retro_input_state_t
*/
DEVICE_NONE         :: 0

/**
* An abstraction around a game controller, known as a "RetroPad".
*
* The RetroPad is modelled after a SNES controller,
* but with additional L2/R2/L3/R3 buttons
* (similar to a PlayStation controller).
*
* When provided as the \c device argument to \c retro_input_state_t,
* the \c id argument denotes the button (including D-Pad directions) to query.
* The result of said query will be 1 if the button is down, 0 if not.
*
* There is one exception; if \c DEVICE_ID_JOYPAD_MASK is queried
* (and the frontend supports this query),
* the result will be a bitmask of all pressed buttons.
*
* @see retro_input_state_t
* @see DEVICE_ANALOG
* @see DEVICE_ID_JOYPAD
* @see DEVICE_ID_JOYPAD_MASK
* @see ENVIRONMENT_GET_INPUT_BITMASKS
*/
DEVICE_JOYPAD       :: 1

/**
* An abstraction around a mouse, similar to the SNES Mouse but with more buttons.
*
* When provided as the \c device argument to \c retro_input_state_t,
* the \c id argument denotes the button or axis to query.
* For buttons, the result of said query
* will be 1 if the button is down or 0 if not.
* For mouse wheel axes, the result
* will be 1 if the wheel was rotated in that direction and 0 if not.
* For the mouse pointer axis, the result will be thee mouse's movement
* relative to the last poll.
* The core is responsible for tracking the mouse's position,
* and the frontend is responsible for preventing interference
* by the real hardware pointer (if applicable).
*
* @note This should only be used for cores that emulate mouse input,
* such as for home computers
* or consoles with mouse attachments.
* Cores that emulate light guns should use \c DEVICE_LIGHTGUN,
* and cores that emulate touch screens should use \c DEVICE_POINTER.
*
* @see DEVICE_POINTER
* @see DEVICE_LIGHTGUN
*/
DEVICE_MOUSE        :: 2

/**
* An abstraction around a keyboard.
*
* When provided as the \c device argument to \c retro_input_state_t,
* the \c id argument denotes the key to poll.
*
* @note This should only be used for cores that emulate keyboard input,
* such as for home computers
* or consoles with keyboard attachments.
* Cores that emulate gamepads should use \c DEVICE_JOYPAD or \c DEVICE_ANALOG,
* and leave keyboard compatibility to the frontend.
*
* @see ENVIRONMENT_SET_KEYBOARD_CALLBACK
* @see retro_key
*/
DEVICE_KEYBOARD     :: 3

/**
* An abstraction around a light gun, similar to the PlayStation's Guncon.
*
* When provided as the \c device argument to \c retro_input_state_t,
* the \c id argument denotes one of several possible inputs.
*
* The gun's coordinates are reported in screen space (similar to the pointer)
* in the range of [-0x8000, 0x7fff].
* Zero is the center of the game's screen
* and -0x8000 represents out-of-bounds.
* The trigger and various auxiliary buttons are also reported.
*
* @note A forced off-screen shot can be requested for auto-reloading
* function in some games.
*
* @see DEVICE_POINTER
*/
DEVICE_LIGHTGUN     :: 4

/**
* An extension of the RetroPad that supports analog input.
*
* The analog RetroPad provides two virtual analog sticks (similar to DualShock controllers)
* and allows any button to be treated as analog (similar to Xbox shoulder triggers).
*
* When provided as the \c device argument to \c retro_input_state_t,
* the \c id argument denotes an analog axis or an analog button.
*
* Analog axes are reported in the range of [-0x8000, 0x7fff],
* with the X axis being positive towards the right
* and the Y axis being positive towards the bottom.
*
* Analog buttons are reported in the range of [0, 0x7fff],
* where 0 is unpressed and 0x7fff is fully pressed.
*
* @note Cores should only use this type if they need analog input.
* Otherwise, \c DEVICE_JOYPAD should be used.
* @see DEVICE_JOYPAD
*/
DEVICE_ANALOG       :: 5

/**
* Input Device: Pointer.
*
* Abstracts the concept of a pointing mechanism, e.g. touch.
* This allows libretro to query in absolute coordinates where on the
* screen a mouse (or something similar) is being placed.
* For a touch centric device, coordinates reported are the coordinates
* of the press.
*
* Coordinates in X and Y are reported as:
* [-0x7fff, 0x7fff]: -0x7fff corresponds to the far left/top of the screen,
* and 0x7fff corresponds to the far right/bottom of the screen.
* The "screen" is here defined as area that is passed to the frontend and
* later displayed on the monitor. If the pointer is outside this screen,
* such as in the black surrounding areas when actual display is larger,
* edge position is reported. An explicit edge detection is also provided,
* that will return 1 if the pointer is near the screen edge or actually outside it.
*
* The frontend is free to scale/resize this screen as it sees fit, however,
* (X, Y) = (-0x7fff, -0x7fff) will correspond to the top-left pixel of the
* game image, etc.
*
* To check if the pointer coordinates are valid (e.g. a touch display
* actually being touched), \c DEVICE_ID_POINTER_PRESSED returns 1 or 0.
*
* If using a mouse on a desktop, \c DEVICE_ID_POINTER_PRESSED will
* usually correspond to the left mouse button, but this is a frontend decision.
* \c DEVICE_ID_POINTER_PRESSED will only return 1 if the pointer is
* inside the game screen.
*
* For multi-touch, the index variable can be used to successively query
* more presses.
* If index = 0 returns true for \c _PRESSED, coordinates can be extracted
* with \c _X, \c _Y for index = 0. One can then query \c _PRESSED, \c _X, \c _Y with
* index = 1, and so on.
* Eventually \c _PRESSED will return false for an index. No further presses
* are registered at this point.
*
* @see DEVICE_MOUSE
* @see DEVICE_ID_POINTER_X
* @see DEVICE_ID_POINTER_Y
* @see DEVICE_ID_POINTER_PRESSED
*/
DEVICE_POINTER      :: 6

/** @} */

/** @defgroup DEVICE_ID_JOYPAD RetroPad Input
* @brief Digital buttons for the RetroPad.
*
* Button placement is comparable to that of a SNES controller,
* combined with the shoulder buttons of a PlayStation controller.
* These values can also be used for the \c id field of \c DEVICE_INDEX_ANALOG_BUTTON
* to represent analog buttons (usually shoulder triggers).
* @{
*/

/** The equivalent of the SNES controller's south face button. */
DEVICE_ID_JOYPAD_B        :: 0

/** The equivalent of the SNES controller's west face button. */
DEVICE_ID_JOYPAD_Y        :: 1

/** The equivalent of the SNES controller's left-center button. */
DEVICE_ID_JOYPAD_SELECT   :: 2

/** The equivalent of the SNES controller's right-center button. */
DEVICE_ID_JOYPAD_START    :: 3

/** Up on the RetroPad's D-pad. */
DEVICE_ID_JOYPAD_UP       :: 4

/** Down on the RetroPad's D-pad. */
DEVICE_ID_JOYPAD_DOWN     :: 5

/** Left on the RetroPad's D-pad. */
DEVICE_ID_JOYPAD_LEFT     :: 6

/** Right on the RetroPad's D-pad. */
DEVICE_ID_JOYPAD_RIGHT    :: 7

/** The equivalent of the SNES controller's east face button. */
DEVICE_ID_JOYPAD_A        :: 8

/** The equivalent of the SNES controller's north face button. */
DEVICE_ID_JOYPAD_X        :: 9

/** The equivalent of the SNES controller's left shoulder button. */
DEVICE_ID_JOYPAD_L       :: 10

/** The equivalent of the SNES controller's right shoulder button. */
DEVICE_ID_JOYPAD_R       :: 11

/** The equivalent of the PlayStation's rear left shoulder button. */
DEVICE_ID_JOYPAD_L2      :: 12

/** The equivalent of the PlayStation's rear right shoulder button. */
DEVICE_ID_JOYPAD_R2      :: 13

/**
* The equivalent of the PlayStation's left analog stick button,
* although the actual button need not be in this position.
*/
DEVICE_ID_JOYPAD_L3      :: 14

/**
* The equivalent of the PlayStation's right analog stick button,
* although the actual button need not be in this position.
*/
DEVICE_ID_JOYPAD_R3      :: 15

/**
* Represents a bitmask that describes the state of all \c DEVICE_ID_JOYPAD button constants,
* rather than the state of a single button.
*
* @see ENVIRONMENT_GET_INPUT_BITMASKS
* @see DEVICE_JOYPAD
*/
DEVICE_ID_JOYPAD_MASK    :: 256

/** @} */

/** @defgroup DEVICE_ID_ANALOG Analog RetroPad Input
* @{
*/

/* Index / Id values for ANALOG device. */
DEVICE_INDEX_ANALOG_LEFT       :: 0
DEVICE_INDEX_ANALOG_RIGHT      :: 1
DEVICE_INDEX_ANALOG_BUTTON     :: 2
DEVICE_ID_ANALOG_X             :: 0
DEVICE_ID_ANALOG_Y             :: 1

/** @} */

/* Id values for MOUSE. */
DEVICE_ID_MOUSE_X                :: 0
DEVICE_ID_MOUSE_Y                :: 1
DEVICE_ID_MOUSE_LEFT             :: 2
DEVICE_ID_MOUSE_RIGHT            :: 3
DEVICE_ID_MOUSE_WHEELUP          :: 4
DEVICE_ID_MOUSE_WHEELDOWN        :: 5
DEVICE_ID_MOUSE_MIDDLE           :: 6
DEVICE_ID_MOUSE_HORIZ_WHEELUP    :: 7
DEVICE_ID_MOUSE_HORIZ_WHEELDOWN  :: 8
DEVICE_ID_MOUSE_BUTTON_4         :: 9
DEVICE_ID_MOUSE_BUTTON_5         :: 10

/* Id values for LIGHTGUN. */
DEVICE_ID_LIGHTGUN_SCREEN_X        :: 13 /*Absolute Position*/
DEVICE_ID_LIGHTGUN_SCREEN_Y        :: 14 /*Absolute Position*/

/** Indicates if lightgun points off the screen or near the edge */
DEVICE_ID_LIGHTGUN_IS_OFFSCREEN    :: 15 /*Status Check*/
DEVICE_ID_LIGHTGUN_TRIGGER          :: 2
DEVICE_ID_LIGHTGUN_RELOAD          :: 16 /*Forced off-screen shot*/
DEVICE_ID_LIGHTGUN_AUX_A            :: 3
DEVICE_ID_LIGHTGUN_AUX_B            :: 4
DEVICE_ID_LIGHTGUN_START            :: 6
DEVICE_ID_LIGHTGUN_SELECT           :: 7
DEVICE_ID_LIGHTGUN_AUX_C            :: 8
DEVICE_ID_LIGHTGUN_DPAD_UP          :: 9
DEVICE_ID_LIGHTGUN_DPAD_DOWN       :: 10
DEVICE_ID_LIGHTGUN_DPAD_LEFT       :: 11
DEVICE_ID_LIGHTGUN_DPAD_RIGHT      :: 12

/* deprecated */
DEVICE_ID_LIGHTGUN_X                :: 0 /*Relative Position*/
DEVICE_ID_LIGHTGUN_Y                :: 1 /*Relative Position*/
DEVICE_ID_LIGHTGUN_CURSOR           :: 3 /*Use Aux:A instead*/
DEVICE_ID_LIGHTGUN_TURBO            :: 4 /*Use Aux:B instead*/
DEVICE_ID_LIGHTGUN_PAUSE            :: 5 /*Use Start instead*/

/* Id values for POINTER. */
DEVICE_ID_POINTER_X             :: 0
DEVICE_ID_POINTER_Y             :: 1
DEVICE_ID_POINTER_PRESSED       :: 2
DEVICE_ID_POINTER_COUNT         :: 3

/** Indicates if pointer is off the screen or near the edge */
DEVICE_ID_POINTER_IS_OFFSCREEN :: 15

/** @} */

/* Returned from retro_get_region(). */
REGION_NTSC  :: 0
REGION_PAL   :: 1

/**
* Identifiers for supported languages.
* @see ENVIRONMENT_GET_LANGUAGE
*/
language :: enum u32 {
	ENGLISH             = 0,
	JAPANESE            = 1,
	FRENCH              = 2,
	SPANISH             = 3,
	GERMAN              = 4,
	ITALIAN             = 5,
	DUTCH               = 6,
	PORTUGUESE_BRAZIL   = 7,
	PORTUGUESE_PORTUGAL = 8,
	RUSSIAN             = 9,
	KOREAN              = 10,
	CHINESE_TRADITIONAL = 11,
	CHINESE_SIMPLIFIED  = 12,
	ESPERANTO           = 13,
	POLISH              = 14,
	VIETNAMESE          = 15,
	ARABIC              = 16,
	GREEK               = 17,
	TURKISH             = 18,
	SLOVAK              = 19,
	PERSIAN             = 20,
	HEBREW              = 21,
	ASTURIAN            = 22,
	FINNISH             = 23,
	INDONESIAN          = 24,
	SWEDISH             = 25,
	UKRAINIAN           = 26,
	CZECH               = 27,
	CATALAN_VALENCIA    = 28,
	CATALAN             = 29,
	BRITISH_ENGLISH     = 30,
	HUNGARIAN           = 31,
	BELARUSIAN          = 32,
	GALICIAN            = 33,
	NORWEGIAN           = 34,
	IRISH               = 35,
	LAST                = 36,

	/** Defined to ensure that <tt>sizeof(retro_language) == sizeof(int)</tt>. Do not use. */
	DUMMY               = 2147483647,
}

/** @defgroup MEMORY Memory Types
* @{
*/

/* Passed to retro_get_memory_data/size().
* If the memory type doesn't apply to the
* implementation NULL/0 can be returned.
*/
MEMORY_MASK        :: 0xff

/* Regular save RAM. This RAM is usually found on a game cartridge,
* backed up by a battery.
* If save game data is too complex for a single memory buffer,
* the SAVE_DIRECTORY (preferably) or SYSTEM_DIRECTORY environment
* callback can be used. */
MEMORY_SAVE_RAM    :: 0

/* Some games have a built-in clock to keep track of time.
* This memory is usually just a couple of bytes to keep track of time.
*/
MEMORY_RTC         :: 1

/* System ram lets a frontend peek into a game systems main RAM. */
MEMORY_SYSTEM_RAM  :: 2

/* Video ram lets a frontend peek into a game systems video RAM (VRAM). */
MEMORY_VIDEO_RAM   :: 3

/* Keysyms used for ID in input state callback when polling KEYBOARD. */
key :: enum u32 {
	K_UNKNOWN           = 0,
	K_FIRST             = 0,
	K_BACKSPACE         = 8,
	K_TAB               = 9,
	K_CLEAR             = 12,
	K_RETURN            = 13,
	K_PAUSE             = 19,
	K_ESCAPE            = 27,
	K_SPACE             = 32,
	K_EXCLAIM           = 33,
	K_QUOTEDBL          = 34,
	K_HASH              = 35,
	K_DOLLAR            = 36,
	K_AMPERSAND         = 38,
	K_QUOTE             = 39,
	K_LEFTPAREN         = 40,
	K_RIGHTPAREN        = 41,
	K_ASTERISK          = 42,
	K_PLUS              = 43,
	K_COMMA             = 44,
	K_MINUS             = 45,
	K_PERIOD            = 46,
	K_SLASH             = 47,
	K_0                 = 48,
	K_1                 = 49,
	K_2                 = 50,
	K_3                 = 51,
	K_4                 = 52,
	K_5                 = 53,
	K_6                 = 54,
	K_7                 = 55,
	K_8                 = 56,
	K_9                 = 57,
	K_COLON             = 58,
	K_SEMICOLON         = 59,
	K_LESS              = 60,
	K_EQUALS            = 61,
	K_GREATER           = 62,
	K_QUESTION          = 63,
	K_AT                = 64,
	K_LEFTBRACKET       = 91,
	K_BACKSLASH         = 92,
	K_RIGHTBRACKET      = 93,
	K_CARET             = 94,
	K_UNDERSCORE        = 95,
	K_BACKQUOTE         = 96,
	K_a                 = 97,
	K_b                 = 98,
	K_c                 = 99,
	K_d                 = 100,
	K_e                 = 101,
	K_f                 = 102,
	K_g                 = 103,
	K_h                 = 104,
	K_i                 = 105,
	K_j                 = 106,
	K_k                 = 107,
	K_l                 = 108,
	K_m                 = 109,
	K_n                 = 110,
	K_o                 = 111,
	K_p                 = 112,
	K_q                 = 113,
	K_r                 = 114,
	K_s                 = 115,
	K_t                 = 116,
	K_u                 = 117,
	K_v                 = 118,
	K_w                 = 119,
	K_x                 = 120,
	K_y                 = 121,
	K_z                 = 122,
	K_LEFTBRACE         = 123,
	K_BAR               = 124,
	K_RIGHTBRACE        = 125,
	K_TILDE             = 126,
	K_DELETE            = 127,
	K_KP0               = 256,
	K_KP1               = 257,
	K_KP2               = 258,
	K_KP3               = 259,
	K_KP4               = 260,
	K_KP5               = 261,
	K_KP6               = 262,
	K_KP7               = 263,
	K_KP8               = 264,
	K_KP9               = 265,
	K_KP_PERIOD         = 266,
	K_KP_DIVIDE         = 267,
	K_KP_MULTIPLY       = 268,
	K_KP_MINUS          = 269,
	K_KP_PLUS           = 270,
	K_KP_ENTER          = 271,
	K_KP_EQUALS         = 272,
	K_UP                = 273,
	K_DOWN              = 274,
	K_RIGHT             = 275,
	K_LEFT              = 276,
	K_INSERT            = 277,
	K_HOME              = 278,
	K_END               = 279,
	K_PAGEUP            = 280,
	K_PAGEDOWN          = 281,
	K_F1                = 282,
	K_F2                = 283,
	K_F3                = 284,
	K_F4                = 285,
	K_F5                = 286,
	K_F6                = 287,
	K_F7                = 288,
	K_F8                = 289,
	K_F9                = 290,
	K_F10               = 291,
	K_F11               = 292,
	K_F12               = 293,
	K_F13               = 294,
	K_F14               = 295,
	K_F15               = 296,
	K_NUMLOCK           = 300,
	K_CAPSLOCK          = 301,
	K_SCROLLOCK         = 302,
	K_RSHIFT            = 303,
	K_LSHIFT            = 304,
	K_RCTRL             = 305,
	K_LCTRL             = 306,
	K_RALT              = 307,
	K_LALT              = 308,
	K_RMETA             = 309,
	K_LMETA             = 310,
	K_LSUPER            = 311,
	K_RSUPER            = 312,
	K_MODE              = 313,
	K_COMPOSE           = 314,
	K_HELP              = 315,
	K_PRINT             = 316,
	K_SYSREQ            = 317,
	K_BREAK             = 318,
	K_MENU              = 319,
	K_POWER             = 320,
	K_EURO              = 321,
	K_UNDO              = 322,
	K_OEM_102           = 323,
	K_BROWSER_BACK      = 324,
	K_BROWSER_FORWARD   = 325,
	K_BROWSER_REFRESH   = 326,
	K_BROWSER_STOP      = 327,
	K_BROWSER_SEARCH    = 328,
	K_BROWSER_FAVORITES = 329,
	K_BROWSER_HOME      = 330,
	K_VOLUME_MUTE       = 331,
	K_VOLUME_DOWN       = 332,
	K_VOLUME_UP         = 333,
	K_MEDIA_NEXT        = 334,
	K_MEDIA_PREV        = 335,
	K_MEDIA_STOP        = 336,
	K_MEDIA_PLAY_PAUSE  = 337,
	K_LAUNCH_MAIL       = 338,
	K_LAUNCH_MEDIA      = 339,
	K_LAUNCH_APP1       = 340,
	K_LAUNCH_APP2       = 341,
	K_LAST              = 342,
	K_DUMMY             = 2147483647, /* Ensure sizeof(enum) == sizeof(int) */
}

mod :: enum u32 {
	NONE      = 0,
	SHIFT     = 1,
	CTRL      = 2,
	ALT       = 4,
	META      = 8,
	NUMLOCK   = 16,
	CAPSLOCK  = 32,
	SCROLLOCK = 64,
	DUMMY     = 2147483647, /* Ensure sizeof(enum) == sizeof(int) */
}

/**
* @defgroup ENVIRONMENT Environment Callbacks
* @{
*/

/**
* This bit indicates that the associated environment call is experimental,
* and may be changed or removed in the future.
* Frontends should mask out this bit before handling the environment call.
*/
ENVIRONMENT_EXPERIMENTAL :: 0x10000

/** Frontend-internal environment callbacks should include this bit. */
ENVIRONMENT_PRIVATE :: 0x20000

/* Environment commands. */
/**
* Requests the frontend to set the screen rotation.
*
* @param[in] data <tt>const unsigned*</tt>.
* Valid values are 0, 1, 2, and 3.
* These numbers respectively set the screen rotation to 0, 90, 180, and 270 degrees counter-clockwise.
* @returns \c true if the screen rotation was set successfully.
*/
ENVIRONMENT_SET_ROTATION  :: 1

/**
* Queries whether the core should use overscan or not.
*
* @param[out] data <tt>bool*</tt>.
* Set to \c true if the core should use overscan,
* \c false if it should be cropped away.
* @returns \c true if the environment call is available.
* Does \em not indicate whether overscan should be used.
* @deprecated As of 2019 this callback is considered deprecated in favor of
* using core options to manage overscan in a more nuanced, core-specific way.
*/
ENVIRONMENT_GET_OVERSCAN  :: 2

/**
* Queries whether the frontend supports frame duping,
* in the form of passing \c NULL to the video frame callback.
*
* @param[out] data <tt>bool*</tt>.
* Set to \c true if the frontend supports frame duping.
* @returns \c true if the environment call is available.
* @see retro_video_refresh_t
*/
ENVIRONMENT_GET_CAN_DUPE  :: 3

/*
* Environ 4, 5 are no longer supported (GET_VARIABLE / SET_VARIABLES),
* and reserved to avoid possible ABI clash.
*/

/**
* @brief Displays a user-facing message for a short time.
*
* Use this callback to convey important status messages,
* such as errors or the result of long-running operations.
* For trivial messages or logging, use \c ENVIRONMENT_GET_LOG_INTERFACE or \c stderr.
*
* \code{.c}
* void set_message_example(void)
* {
*    struct retro_message msg;
*    msg.frames = 60 * 5; // 5 seconds
*    msg.msg = "Hello world!";
*
*    environ_cb(ENVIRONMENT_SET_MESSAGE, &msg);
* }
* \endcode
*
* @deprecated Prefer using \c ENVIRONMENT_SET_MESSAGE_EXT for new code,
* as it offers more features.
* Only use this environment call for compatibility with older cores or frontends.
*
* @param[in] data <tt>const struct retro_message*</tt>.
* Details about the message to show to the user.
* Behavior is undefined if <tt>NULL</tt>.
* @returns \c true if the environment call is available.
* @see retro_message
* @see ENVIRONMENT_GET_LOG_INTERFACE
* @see ENVIRONMENT_SET_MESSAGE_EXT
* @see ENVIRONMENT_SET_MESSAGE
* @see ENVIRONMENT_GET_MESSAGE_INTERFACE_VERSION
* @note The frontend must make its own copy of the message and the underlying string.
*/
ENVIRONMENT_SET_MESSAGE   :: 6

/**
* Requests the frontend to shutdown the core.
* Should only be used if the core can exit on its own,
* such as from a menu item in a game
* or an emulated power-off in an emulator.
*
* @param data Ignored.
* @returns \c true if the environment call is available.
*/
ENVIRONMENT_SHUTDOWN      :: 7

/**
* Gives a hint to the frontend of how demanding this core is on the system.
* For example, reporting a level of 2 means that
* this implementation should run decently on frontends
* of level 2 and above.
*
* It can be used by the frontend to potentially warn
* about too demanding implementations.
*
* The levels are "floating".
*
* This function can be called on a per-game basis,
* as a core may have different demands for different games or settings.
* If called, it should be called in <tt>retro_load_game()</tt>.
* @param[in] data <tt>const unsigned*</tt>.
*/
ENVIRONMENT_SET_PERFORMANCE_LEVEL :: 8

/**
* Returns the path to the frontend's system directory,
* which can be used to store system-specific configuration
* such as BIOS files or cached data.
*
* @param[out] data <tt>const char**</tt>.
* Pointer to the \c char* in which the system directory will be saved.
* The string is managed by the frontend and must not be modified or freed by the core.
* May be \c NULL if no system directory is defined,
* in which case the core should find an alternative directory.
* @return \c true if the environment call is available,
* even if the value returned in \c data is <tt>NULL</tt>.
* @note Historically, some cores would use this folder for save data such as memory cards or SRAM.
* This is now discouraged in favor of \c ENVIRONMENT_GET_SAVE_DIRECTORY.
* @see ENVIRONMENT_GET_SAVE_DIRECTORY
*/
ENVIRONMENT_GET_SYSTEM_DIRECTORY :: 9

/**
* Sets the internal pixel format used by the frontend for rendering.
* The default pixel format is \c PIXEL_FORMAT_0RGB1555 for compatibility reasons,
* although it's considered deprecated and shouldn't be used by new code.
*
* @param[in] data <tt>const enum retro_pixel_format *</tt>.
* Pointer to the pixel format to use.
* @returns \c true if the pixel format was set successfully,
* \c false if it's not supported or this callback is unavailable.
* @note This function should be called inside \c retro_load_game()
* or <tt>retro_get_system_av_info()</tt>.
* @see retro_pixel_format
*/
ENVIRONMENT_SET_PIXEL_FORMAT :: 10

/**
* Sets an array of input descriptors for the frontend
* to present to the user for configuring the core's controls.
*
* This function can be called at any time,
* preferably early in the core's life cycle.
* Ideally, no later than \c retro_load_game().
*
* @param[in] data <tt>const struct retro_input_descriptor *</tt>.
* An array of input descriptors terminated by one whose
* \c retro_input_descriptor::description field is set to \c NULL.
* Behavior is undefined if \c NULL.
* @return \c true if the environment call is recognized.
* @see retro_input_descriptor
*/
ENVIRONMENT_SET_INPUT_DESCRIPTORS :: 11

/**
* Sets a callback function used to notify the core about keyboard events.
* This should only be used for cores that specifically need keyboard input,
* such as for home computer emulators or games with text entry.
*
* @param[in] data <tt>const struct retro_keyboard_callback *</tt>.
* Pointer to the callback function.
* Behavior is undefined if <tt>NULL</tt>.
* @return \c true if the environment call is recognized.
* @see retro_keyboard_callback
* @see retro_key
*/
ENVIRONMENT_SET_KEYBOARD_CALLBACK :: 12

/**
* Sets an interface that the frontend can use to insert and remove disks
* from the emulated console's disk drive.
* Can be used for optical disks, floppy disks, or any other game storage medium
* that can be swapped at runtime.
*
* This is intended for multi-disk games that expect the player
* to manually swap disks at certain points in the game.
*
* @deprecated Prefer using \c ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE
* over this environment call, as it supports additional features.
* Only use this callback to maintain compatibility
* with older cores or frontends.
*
* @param[in] data <tt>const struct retro_disk_control_callback *</tt>.
* Pointer to the callback functions to use.
* May be \c NULL, in which case the existing disk callback is deregistered.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
* @see retro_disk_control_callback
* @see ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE
*/
ENVIRONMENT_SET_DISK_CONTROL_INTERFACE :: 13

/**
* Requests that a frontend enable a particular hardware rendering API.
*
* If successful, the frontend will create a context (and other related resources)
* that the core can use for rendering.
* The framebuffer will be at least as large as
* the maximum dimensions provided in <tt>retro_get_system_av_info</tt>.
*
* @param[in, out] data <tt>struct retro_hw_render_callback *</tt>.
* Pointer to the hardware render callback struct.
* Used to define callbacks for the hardware-rendering life cycle,
* as well as to request a particular rendering API.
* @return \c true if the environment call is recognized
* and the requested rendering API is supported.
* \c false if \c data is \c NULL
* or the frontend can't provide the requested rendering API.
* @see retro_hw_render_callback
* @see retro_video_refresh_t
* @see ENVIRONMENT_GET_PREFERRED_HW_RENDER
* @note Should be called in <tt>retro_load_game()</tt>.
* @note If HW rendering is used, pass only \c HW_FRAME_BUFFER_VALID or
* \c NULL to <tt>retro_video_refresh_t</tt>.
*/
ENVIRONMENT_SET_HW_RENDER :: 14

/**
* Retrieves a core option's value from the frontend.
* \c retro_variable::key should be set to an option key
* that was previously set in \c ENVIRONMENT_SET_VARIABLES
* (or a similar environment call).
*
* @param[in,out] data <tt>struct retro_variable *</tt>.
* Pointer to a single \c retro_variable struct.
* See the documentation for \c retro_variable for details
* on which fields are set by the frontend or core.
* May be \c NULL.
* @returns \c true if the environment call is available,
* even if \c data is \c NULL or the key it specifies is not found.
* @note Passing \c NULL in to \c data can be useful to
* test for support of this environment call without looking up any variables.
* @see retro_variable
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
* @see ENVIRONMENT_GET_VARIABLE_UPDATE
*/
ENVIRONMENT_GET_VARIABLE :: 15

/**
* Notifies the frontend of the core's available options.
*
* The core may check these options later using \c ENVIRONMENT_GET_VARIABLE.
* The frontend may also present these options to the user
* in its own configuration UI.
*
* This should be called the first time as early as possible,
* ideally in \c retro_set_environment.
* The core may later call this function again
* to communicate updated options to the frontend,
* but the number of core options must not change.
*
* Here's an example that sets two options.
*
* @code
* void set_variables_example(void)
* {
*    struct retro_variable options[] = {
*        { "foo_speedhack", "Speed hack; false|true" }, // false by default
*        { "foo_displayscale", "Display scale factor; 1|2|3|4" }, // 1 by default
*        { NULL, NULL },
*    };
*
*    environ_cb(ENVIRONMENT_SET_VARIABLES, &options);
* }
* @endcode
*
* The possible values will generally be displayed and stored as-is by the frontend.
*
* @deprecated Prefer using \c ENVIRONMENT_SET_CORE_OPTIONS_V2 for new code,
* as it offers more features such as categories and translation.
* Only use this environment call to maintain compatibility
* with older frontends or cores.
* @note Keep the available options (and their possible values) as low as possible;
* it should be feasible to cycle through them without a keyboard.
* @param[in] data <tt>const struct retro_variable *</tt>.
* Pointer to an array of \c retro_variable structs that define available core options,
* terminated by a <tt>{ NULL, NULL }</tt> element.
* The frontend must maintain its own copy of this array.
*
* @returns \c true if the environment call is available,
* even if \c data is <tt>NULL</tt>.
* @see retro_variable
* @see ENVIRONMENT_GET_VARIABLE
* @see ENVIRONMENT_GET_VARIABLE_UPDATE
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
*/
ENVIRONMENT_SET_VARIABLES :: 16

/**
* Queries whether at least one core option was updated by the frontend
* since the last call to \ref ENVIRONMENT_GET_VARIABLE.
* This typically means that the user opened the core options menu and made some changes.
*
* Cores usually call this each frame before the core's main emulation logic.
* Specific options can then be queried with \ref ENVIRONMENT_GET_VARIABLE.
*
* @param[out] data <tt>bool *</tt>.
* Set to \c true if at least one core option was updated
* since the last call to \ref ENVIRONMENT_GET_VARIABLE.
* Behavior is undefined if this pointer is \c NULL.
* @returns \c true if the environment call is available.
* @see ENVIRONMENT_GET_VARIABLE
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
*/
ENVIRONMENT_GET_VARIABLE_UPDATE :: 17

/**
* Notifies the frontend that this core can run without loading any content,
* such as when emulating a console that has built-in software.
* When a core is loaded without content,
* \c retro_load_game receives an argument of <tt>NULL</tt>.
* This should be called within \c retro_set_environment() only.
*
* @param[in] data <tt>const bool *</tt>.
* Pointer to a single \c bool that indicates whether this frontend can run without content.
* Can point to a value of \c false but this isn't necessary,
* as contentless support is opt-in.
* The behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available.
* @see retro_load_game
*/
ENVIRONMENT_SET_SUPPORT_NO_GAME :: 18

/**
* Retrieves the absolute path from which this core was loaded.
* Useful when loading assets from paths relative to the core,
* as is sometimes the case when using <tt>ENVIRONMENT_SET_SUPPORT_NO_GAME</tt>.
*
* @param[out] data <tt>const char **</tt>.
* Pointer to a string in which the core's path will be saved.
* The string is managed by the frontend and must not be modified or freed by the core.
* May be \c NULL if the core is statically linked to the frontend
* or if the core's path otherwise cannot be determined.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available.
*/
ENVIRONMENT_GET_LIBPATH :: 19

/* Environment call 20 was an obsolete version of SET_AUDIO_CALLBACK.
* It was not used by any known core at the time, and was removed from the API.
* The number 20 is reserved to prevent ABI clashes.
*/

/**
* Sets a callback that notifies the core of how much time has passed
* since the last iteration of <tt>retro_run</tt>.
* If the frontend is not running the core in real time
* (e.g. it's frame-stepping or running in slow motion),
* then the reference value will be provided to the callback instead.
*
* @param[in] data <tt>const struct retro_frame_time_callback *</tt>.
* Pointer to a single \c retro_frame_time_callback struct.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available.
* @note Frontends may disable this environment call in certain situations.
* It will return \c false in those cases.
* @see retro_frame_time_callback
*/
ENVIRONMENT_SET_FRAME_TIME_CALLBACK :: 21

/**
* Registers a set of functions that the frontend can use
* to tell the core it's ready for audio output.
*
* It is intended for games that feature asynchronous audio.
* It should not be used for emulators unless their audio is asynchronous.
*
*
* The callback only notifies about writability; the libretro core still
* has to call the normal audio callbacks
* to write audio. The audio callbacks must be called from within the
* notification callback.
* The amount of audio data to write is up to the core.
* Generally, the audio callback will be called continuously in a loop.
*
* A frontend may disable this callback in certain situations.
* The core must be able to render audio with the "normal" interface.
*
* @param[in] data <tt>const struct retro_audio_callback *</tt>.
* Pointer to a set of functions that the frontend will call to notify the core
* when it's ready to receive audio data.
* May be \c NULL, in which case the frontend will return
* whether this environment callback is available.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
* @warning The provided callbacks can be invoked from any thread,
* so their implementations \em must be thread-safe.
* @note If a core uses this callback,
* it should also use <tt>ENVIRONMENT_SET_FRAME_TIME_CALLBACK</tt>.
* @see retro_audio_callback
* @see retro_audio_sample_t
* @see retro_audio_sample_batch_t
* @see ENVIRONMENT_SET_FRAME_TIME_CALLBACK
*/
ENVIRONMENT_SET_AUDIO_CALLBACK :: 22

/**
* Gets an interface that a core can use to access a controller's rumble motors.
*
* The interface supports two independently-controlled motors,
* one strong and one weak.
*
* Should be called from either \c retro_init() or \c retro_load_game(),
* but not from \c retro_set_environment().
*
* @param[out] data <tt>struct retro_rumble_interface *</tt>.
* Pointer to the interface struct.
* Behavior is undefined if \c NULL.
* @returns \c true if the environment call is available,
* even if the current device doesn't support vibration.
* @see retro_rumble_interface
* @defgroup GET_RUMBLE_INTERFACE Rumble Interface
*/
ENVIRONMENT_GET_RUMBLE_INTERFACE :: 23

/**
* Returns the frontend's supported input device types.
*
* The supported device types are returned as a bitmask,
* with each value of \ref DEVICE corresponding to a bit.
*
* Should only be called in \c retro_run().
*
* @code
* #define REQUIRED_DEVICES ((1 << DEVICE_JOYPAD) | (1 << DEVICE_ANALOG))
* void get_input_device_capabilities_example(void)
* {
*    uint64_t capabilities;
*    environ_cb(ENVIRONMENT_GET_INPUT_DEVICE_CAPABILITIES, &capabilities);
*    if ((capabilities & REQUIRED_DEVICES) == REQUIRED_DEVICES)
*      printf("Joypad and analog device types are supported");
* }
* @endcode
*
* @param[out] data <tt>uint64_t *</tt>.
* Pointer to a bitmask of supported input device types.
* If the frontend supports a particular \c DEVICE_* type,
* then the bit <tt>(1 << DEVICE_*)</tt> will be set.
*
* Each bit represents a \c DEVICE constant,
* e.g. bit 1 represents \c DEVICE_JOYPAD,
* bit 2 represents \c DEVICE_MOUSE, and so on.
*
* Bits that do not correspond to known device types will be set to zero
* and are reserved for future use.
*
* Behavior is undefined if \c NULL.
* @returns \c true if the environment call is available.
* @note If the frontend supports multiple input drivers,
* availability of this environment call (and the reported capabilities)
* may depend on the active driver.
* @see DEVICE
*/
ENVIRONMENT_GET_INPUT_DEVICE_CAPABILITIES :: 24

/**
* Returns an interface that the core can use to access and configure available sensors,
* such as an accelerometer or gyroscope.
*
* @param[out] data <tt>struct retro_sensor_interface *</tt>.
* Pointer to the sensor interface that the frontend will populate.
* Behavior is undefined if is \c NULL.
* @returns \c true if the environment call is available,
* even if the device doesn't have any supported sensors.
* @see retro_sensor_interface
* @see retro_sensor_action
* @see SENSOR
* @addtogroup SENSOR
*/
ENVIRONMENT_GET_SENSOR_INTERFACE :: (25|ENVIRONMENT_EXPERIMENTAL)

/**
* Gets an interface to the device's video camera.
*
* The frontend delivers new video frames via a user-defined callback
* that runs in the same thread as \c retro_run().
* Should be called in \c retro_load_game().
*
* @param[in,out] data <tt>struct retro_camera_callback *</tt>.
* Pointer to the camera driver interface.
* Some fields in the struct must be filled in by the core,
* others are provided by the frontend.
* Behavior is undefined if \c NULL.
* @returns \c true if this environment call is available,
* even if an actual camera isn't.
* @note This API only supports one video camera at a time.
* If the device provides multiple cameras (e.g. inner/outer cameras on a phone),
* the frontend will choose one to use.
* @see retro_camera_callback
* @see ENVIRONMENT_SET_HW_RENDER
*/
ENVIRONMENT_GET_CAMERA_INTERFACE :: (26|ENVIRONMENT_EXPERIMENTAL)

/**
* Gets an interface that the core can use for cross-platform logging.
* Certain platforms don't have a console or <tt>stderr</tt>,
* or they have their own preferred logging methods.
* The frontend itself may also display log output.
*
* @attention This should not be used for information that the player must immediately see,
* such as major errors or warnings.
* In most cases, this is best for information that will help you (the developer)
* identify problems when debugging or providing support.
* Unless a core or frontend is intended for advanced users,
* the player might not check (or even know about) their logs.
*
* @param[out] data <tt>struct retro_log_callback *</tt>.
* Pointer to the callback where the function pointer will be saved.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available.
* @see retro_log_callback
* @note Cores can fall back to \c stderr if this interface is not available.
*/
ENVIRONMENT_GET_LOG_INTERFACE :: 27

/**
* Returns an interface that the core can use for profiling code
* and to access performance-related information.
*
* This callback supports performance counters, a high-resolution timer,
* and listing available CPU features (mostly SIMD instructions).
*
* @param[out] data <tt>struct retro_perf_callback *</tt>.
* Pointer to the callback interface.
* Behavior is undefined if \c NULL.
* @returns \c true if the environment call is available.
* @see retro_perf_callback
*/
ENVIRONMENT_GET_PERF_INTERFACE :: 28

/**
* Returns an interface that the core can use to retrieve the device's location,
* including its current latitude and longitude.
*
* @param[out] data <tt>struct retro_location_callback *</tt>.
* Pointer to the callback interface.
* Behavior is undefined if \c NULL.
* @return \c true if the environment call is available,
* even if there's no location information available.
* @see retro_location_callback
*/
ENVIRONMENT_GET_LOCATION_INTERFACE :: 29

/**
* @deprecated An obsolete alias to \c ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY kept for compatibility.
* @see ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY
**/
ENVIRONMENT_GET_CONTENT_DIRECTORY :: 30

/**
* Returns the frontend's "core assets" directory,
* which can be used to store assets that the core needs
* such as art assets or level data.
*
* @param[out] data <tt>const char **</tt>.
* Pointer to a string in which the core assets directory will be saved.
* This string is managed by the frontend and must not be modified or freed by the core.
* May be \c NULL if no core assets directory is defined,
* in which case the core should find an alternative directory.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available,
* even if the value returned in \c data is <tt>NULL</tt>.
*/
ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY :: 30

/**
* Returns the frontend's save data directory, if available.
* This directory should be used to store game-specific save data,
* including memory card images.
*
* Although libretro provides an interface for cores to expose SRAM to the frontend,
* not all cores can support it correctly.
* In this case, cores should use this environment callback
* to save their game data to disk manually.
*
* Cores that use this environment callback
* should flush their save data to disk periodically and when unloading.
*
* @param[out] data <tt>const char **</tt>.
* Pointer to the string in which the save data directory will be saved.
* This string is managed by the frontend and must not be modified or freed by the core.
* May return \c NULL if no save data directory is defined.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available,
* even if the value returned in \c data is <tt>NULL</tt>.
* @note Early libretro cores used \c ENVIRONMENT_GET_SYSTEM_DIRECTORY for save data.
* This is still supported for backwards compatibility,
* but new cores should use this environment call instead.
* \c ENVIRONMENT_GET_SYSTEM_DIRECTORY should be used for game-agnostic data
* such as BIOS files or core-specific configuration.
* @note The returned directory may or may not be the same
* as the one used for \c retro_get_memory_data.
*
* @see retro_get_memory_data
* @see ENVIRONMENT_GET_SYSTEM_DIRECTORY
*/
ENVIRONMENT_GET_SAVE_DIRECTORY :: 31

/**
* Sets new video and audio parameters for the core.
* This can only be called from within <tt>retro_run</tt>.
*
* This environment call may entail a full reinitialization of the frontend's audio/video drivers,
* hence it should \em only be used if the core needs to make drastic changes
* to audio/video parameters.
*
* This environment call should \em not be used when:
* <ul>
* <li>Changing the emulated system's internal resolution,
* within the limits defined by the existing values of \c max_width and \c max_height.
* Use \c ENVIRONMENT_SET_GEOMETRY instead,
* and adjust \c retro_get_system_av_info to account for
* supported scale factors and screen layouts
* when computing \c max_width and \c max_height.
* Only use this environment call if \c max_width or \c max_height needs to increase.
* <li>Adjusting the screen's aspect ratio,
* e.g. when changing the layout of the screen(s).
* Use \c ENVIRONMENT_SET_GEOMETRY or \c ENVIRONMENT_SET_ROTATION instead.
* </ul>
*
* The frontend will reinitialize its audio and video drivers within this callback;
* after that happens, audio and video callbacks will target the newly-initialized driver,
* even within the same \c retro_run call.
*
* This callback makes it possible to support configurable resolutions
* while avoiding the need to compute the "worst case" values of \c max_width and \c max_height.
*
* @param[in] data <tt>const struct retro_system_av_info *</tt>.
* Pointer to the new video and audio parameters that the frontend should adopt.
* @returns \c true if the environment call is available
* and the new av_info struct was accepted.
* \c false if the environment call is unavailable or \c data is <tt>NULL</tt>.
* @see retro_system_av_info
* @see ENVIRONMENT_SET_GEOMETRY
*/
ENVIRONMENT_SET_SYSTEM_AV_INFO :: 32

/**
* Provides an interface that a frontend can use
* to get function pointers from the core.
*
* This allows cores to define their own extensions to the libretro API,
* or to expose implementations of a frontend's libretro extensions.
*
* @param[in] data <tt>const struct retro_get_proc_address_interface *</tt>.
* Pointer to the interface that the frontend can use to get function pointers from the core.
* The frontend must maintain its own copy of this interface.
* @returns \c true if the environment call is available
* and the returned interface was accepted.
* @note The provided interface may be called at any time,
* even before this environment call returns.
* @note Extensions should be prefixed with the name of the frontend or core that defines them.
* For example, a frontend named "foo" that defines a debugging extension
* should expect the core to define functions prefixed with "foo_debug_".
* @warning If a core wants to use this environment call,
* it \em must do so from within \c retro_set_environment().
* @see retro_get_proc_address_interface
*/
ENVIRONMENT_SET_PROC_ADDRESS_CALLBACK :: 33

/**
* Registers a core's ability to handle "subsystems",
* which are secondary platforms that augment a core's primary emulated hardware.
*
* A core doesn't need to emulate a secondary platform
* in order to use it as a subsystem;
* as long as it can load a secondary file for some practical use,
* then this environment call is most likely suitable.
*
* Possible use cases of a subsystem include:
*
* \li Installing software onto an emulated console's internal storage,
* such as the Nintendo DSi.
* \li Emulating accessories that are used to support another console's games,
* such as the Super Game Boy or the N64 Transfer Pak.
* \li Inserting a secondary ROM into a console
* that features multiple cartridge ports,
* such as the Nintendo DS's Slot-2.
* \li Loading a save data file created and used by another core.
*
* Cores should \em not use subsystems for:
*
* \li Emulators that support multiple "primary" platforms,
* such as a Game Boy/Game Boy Advance core
* or a Sega Genesis/Sega CD/32X core.
* Use \c retro_system_content_info_override, \c retro_system_info,
* and/or runtime detection instead.
* \li Selecting different memory card images.
* Use dynamically-populated core options instead.
* \li Different variants of a single console,
* such the Game Boy vs. the Game Boy Color.
* Use core options or runtime detection instead.
* \li Games that span multiple disks.
* Use \c ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE
* and m3u-formatted playlists instead.
* \li Console system files (BIOS, firmware, etc.).
* Use \c ENVIRONMENT_GET_SYSTEM_DIRECTORY
* and a common naming convention instead.
*
* When the frontend loads a game via a subsystem,
* it must call \c retro_load_game_special() instead of \c retro_load_game().
*
* @param[in] data <tt>const struct retro_subsystem_info *</tt>.
* Pointer to an array of subsystem descriptors,
* terminated by a zeroed-out \c retro_subsystem_info struct.
* The frontend should maintain its own copy
* of this array and the strings within it.
* Behavior is undefined if \c NULL.
* @returns \c true if this environment call is available.
* @note This environment call \em must be called from within \c retro_set_environment(),
* as frontends may need the registered information before loading a game.
* @see retro_subsystem_info
* @see retro_load_game_special
*/
ENVIRONMENT_SET_SUBSYSTEM_INFO :: 34

/**
* Declares one or more types of controllers supported by this core.
* The frontend may then allow the player to select one of these controllers in its menu.
*
* Many consoles had controllers that came in different versions,
* were extensible with peripherals,
* or could be held in multiple ways;
* this environment call can be used to represent these differences
* and adjust the core's behavior to match.
*
* Possible use cases include:
*
* \li Supporting different classes of a single controller that supported their own sets of games.
*     For example, the SNES had two different lightguns (the Super Scope and the Justifier)
*     whose games were incompatible with each other.
* \li Representing a platform's alternative controllers.
*     For example, several platforms had music/rhythm games that included controllers
*     shaped like musical instruments.
* \li Representing variants of a standard controller with additional inputs.
*     For example, numerous consoles in the 90's introduced 6-button controllers for fighting games,
*     steering wheels for racing games,
*     or analog sticks for 3D platformers.
* \li Representing add-ons for consoles or standard controllers.
*     For example, the 3DS had a Circle Pad Pro attachment that added a second analog stick.
* \li Selecting different configurations for a single controller.
*     For example, the Wii Remote could be held sideways like a traditional game pad
*     or in one hand like a wand.
* \li Providing multiple ways to simulate the experience of using a particular controller.
*     For example, the Game Boy Advance featured several games
*     with motion or light sensors in their cartridges;
*     a core could provide controller configurations
*     that allow emulating the sensors with either analog axes
*     or with their host device's sensors.
*
* Should be called in retro_load_game.
* The frontend must maintain its own copy of the provided array,
* including all strings and subobjects.
* A core may exclude certain controllers for known incompatible games.
*
* When the frontend changes the active device for a particular port,
* it must call \c retro_set_controller_port_device() with that port's index
* and one of the IDs defined in its retro_controller_info::types field.
*
* Input ports are generally associated with different players
* (and the frontend's UI may reflect this with "Player 1" labels),
* but this is not required.
* Some games use multiple controllers for a single player,
* or some cores may use port indexes to represent an emulated console's
* alternative input peripherals.
*
* @param[in] data <tt>const struct retro_controller_info *</tt>.
* Pointer to an array of controller types defined by this core,
* terminated by a zeroed-out \c retro_controller_info.
* Each element of this array represents a controller port on the emulated device.
* Behavior is undefined if \c NULL.
* @returns \c true if this environment call is available.
* @see retro_controller_info
* @see retro_set_controller_port_device
* @see DEVICE_SUBCLASS
*/
ENVIRONMENT_SET_CONTROLLER_INFO :: 35

/**
* Notifies the frontend of the address spaces used by the core's emulated hardware,
* and of the memory maps within these spaces.
* This can be used by the frontend to provide cheats, achievements, or debugging capabilities.
* Should only be used by emulators, as it makes little sense for game engines.
*
* @note Cores should also expose these address spaces
* through retro_get_memory_data and \c retro_get_memory_size if applicable;
* this environment call is not intended to replace those two functions,
* as the emulated hardware may feature memory regions outside of its own address space
* that are nevertheless useful for the frontend.
*
* @param[in] data <tt>const struct retro_memory_map *</tt>.
* Pointer to a single memory-map listing.
* The frontend must maintain its own copy of this object and its contents,
* including strings and nested objects.
* Behavior is undefined if \c NULL.
* @returns \c true if this environment call is available.
* @see retro_memory_map
* @see retro_get_memory_data
* @see retro_memory_descriptor
*/
ENVIRONMENT_SET_MEMORY_MAPS :: (36|ENVIRONMENT_EXPERIMENTAL)

/**
* Resizes the viewport without reinitializing the video driver.
*
* Similar to \c ENVIRONMENT_SET_SYSTEM_AV_INFO,
* but any changes that would require video reinitialization will not be performed.
* Can only be called from within \c retro_run().
*
* This environment call allows a core to revise the size of the viewport at will,
* which can be useful for emulated platforms that support dynamic resolution changes
* or for cores that support multiple screen layouts.
*
* A frontend must guarantee that this environment call completes in
* constant time.
*
* @param[in] data <tt>const struct retro_game_geometry *</tt>.
* Pointer to the new video parameters that the frontend should adopt.
* \c retro_game_geometry::max_width and \c retro_game_geometry::max_height
* will be ignored.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @return \c true if the environment call is available.
* @see ENVIRONMENT_SET_SYSTEM_AV_INFO
*/
ENVIRONMENT_SET_GEOMETRY :: 37

/**
* Returns the name of the user, if possible.
* This callback is suitable for cores that offer personalization,
* such as online facilities or user profiles on the emulated system.
* @param[out] data <tt>const char **</tt>.
* Pointer to the user name string.
* May be \c NULL, in which case the core should use a default name.
* The returned pointer is owned by the frontend and must not be modified or freed by the core.
* Behavior is undefined if \c NULL.
* @returns \c true if the environment call is available,
* even if the frontend couldn't provide a name.
*/
ENVIRONMENT_GET_USERNAME :: 38

/**
* Returns the frontend's configured language.
* It can be used to localize the core's UI,
* or to customize the emulated firmware if applicable.
*
* @param[out] data <tt>retro_language *</tt>.
* Pointer to the language identifier.
* Behavior is undefined if \c NULL.
* @returns \c true if the environment call is available.
* @note The returned language may not be the same as the operating system's language.
* Cores should fall back to the operating system's language (or to English)
* if the environment call is unavailable or the returned language is unsupported.
* @see retro_language
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL
*/
ENVIRONMENT_GET_LANGUAGE :: 39

/**
* Returns a frontend-managed framebuffer
* that the core may render directly into
*
* This environment call is provided as an optimization
* for cores that use software rendering
* (i.e. that don't use \refitem ENVIRONMENT_SET_HW_RENDER "a graphics hardware API");
* specifically, the intended use case is to allow a core
* to render directly into frontend-managed video memory,
* avoiding the bandwidth use that copying a whole framebuffer from core to video memory entails.
*
* Must be called every frame if used,
* as this may return a different framebuffer each frame
* (e.g. for swap chains).
* However, a core may render to a different buffer even if this call succeeds.
*
* @param[in,out] data <tt>struct retro_framebuffer *</tt>.
* Pointer to a frontend's frame buffer and accompanying data.
* Some fields are set by the core, others are set by the frontend.
* Only guaranteed to be valid for the duration of the current \c retro_run call,
* and must not be used afterwards.
* Behavior is undefined if \c NULL.
* @return \c true if the environment call was recognized
* and the framebuffer was successfully returned.
* @see retro_framebuffer
*/
ENVIRONMENT_GET_CURRENT_SOFTWARE_FRAMEBUFFER :: (40|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns an interface for accessing the data of specific rendering APIs.
* Not all hardware rendering APIs support or need this.
*
* The details of these interfaces are specific to each rendering API.
*
* @note \c retro_hw_render_callback::context_reset must be called by the frontend
* before this environment call can be used.
* Additionally, the contents of the returned interface are invalidated
* after \c retro_hw_render_callback::context_destroyed has been called.
* @param[out] data <tt>const struct retro_hw_render_interface **</tt>.
* The render interface for the currently-enabled hardware rendering API, if any.
* The frontend will store a pointer to the interface at the address provided here.
* The returned interface is owned by the frontend and must not be modified or freed by the core.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is available,
* the active graphics API has a libretro rendering interface,
* and the frontend is able to return said interface.
* \c false otherwise.
* @see ENVIRONMENT_SET_HW_RENDER
* @see retro_hw_render_interface
* @note Since not every libretro-supported hardware rendering API
* has a \c retro_hw_render_interface implementation,
* a result of \c false is not necessarily an error.
*/
ENVIRONMENT_GET_HW_RENDER_INTERFACE :: (41|ENVIRONMENT_EXPERIMENTAL)

/**
* Explicitly notifies the frontend of whether this core supports achievements.
* The core must expose its emulated address space via
* \c retro_get_memory_data or \c ENVIRONMENT_GET_MEMORY_MAPS.
* Must be called before the first call to <tt>retro_run</tt>.
*
* If \ref retro_get_memory_data returns a valid address
* but this environment call is not used,
* the frontend (at its discretion) may or may not opt in the core to its achievements support.
* whether this core is opted in to the frontend's achievement support
* is left to the frontend's discretion.
* @param[in] data <tt>const bool *</tt>.
* Pointer to a single \c bool that indicates whether this core supports achievements.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if the environment call is available.
* @see ENVIRONMENT_SET_MEMORY_MAPS
* @see retro_get_memory_data
*/
ENVIRONMENT_SET_SUPPORT_ACHIEVEMENTS :: (42|ENVIRONMENT_EXPERIMENTAL)

/**
* Defines an interface that the frontend can use
* to ask the core for the parameters it needs for a hardware rendering context.
* The exact semantics depend on \ref ENVIRONMENT_SET_HW_RENDER "the active rendering API".
* Will be used some time after \c ENVIRONMENT_SET_HW_RENDER is called,
* but before \c retro_hw_render_callback::context_reset is called.
*
* @param[in] data <tt>const struct retro_hw_render_context_negotiation_interface *</tt>.
* Pointer to the context negotiation interface.
* Will be populated by the frontend.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is supported,
* even if the current graphics API doesn't use
* a context negotiation interface (in which case the argument is ignored).
* @see retro_hw_render_context_negotiation_interface
* @see ENVIRONMENT_GET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_SUPPORT
* @see ENVIRONMENT_SET_HW_RENDER
*/
ENVIRONMENT_SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE :: (43|ENVIRONMENT_EXPERIMENTAL)

/**
* Notifies the frontend of any quirks associated with serialization.
*
* Should be set in either \c retro_init or \c retro_load_game, but not both.
* @param[in, out] data <tt>uint64_t *</tt>.
* Pointer to the core's serialization quirks.
* The frontend will set the flags of the quirks it supports
* and clear the flags of those it doesn't.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is supported.
* @see retro_serialize
* @see retro_unserialize
* @see SERIALIZATION_QUIRK
*/
ENVIRONMENT_SET_SERIALIZATION_QUIRKS :: 44

/**
* The frontend will try to use a "shared" context when setting up a hardware context.
* Mostly applicable to OpenGL.
*
* In order for this to have any effect,
* the core must call \c ENVIRONMENT_SET_HW_RENDER at some point
* if it hasn't already.
*
* @param data Ignored.
* @returns \c true if the environment call is available
* and the frontend supports shared hardware contexts.
*/
ENVIRONMENT_SET_HW_SHARED_CONTEXT :: (44|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns an interface that the core can use to access the file system.
* Should be called as early as possible.
*
* @param[in,out] data <tt>struct retro_vfs_interface_info *</tt>.
* Information about the desired VFS interface,
* as well as the interface itself.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is available
* and the frontend can provide a VFS interface of the requested version or newer.
* @see retro_vfs_interface_info
* @see file_path
* @see retro_dirent
* @see file_stream
*/
ENVIRONMENT_GET_VFS_INTERFACE :: (45|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns an interface that the core can use
* to set the state of any accessible device LEDs.
*
* @param[out] data <tt>struct retro_led_interface *</tt>.
* Pointer to the LED interface that the frontend will populate.
* May be \c NULL, in which case the frontend will only return
* whether this environment callback is available.
* @returns \c true if the environment call is available,
* even if \c data is \c NULL
* or no LEDs are accessible.
* @see retro_led_interface
*/
ENVIRONMENT_GET_LED_INTERFACE :: (46|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns hints about certain steps that the core may skip for this frame.
*
* A frontend may not need a core to generate audio or video in certain situations;
* this environment call sets a bitmask that indicates
* which steps the core may skip for this frame.
*
* This can be used to increase performance for some frontend features.
*
* @note Emulation accuracy should not be compromised;
* for example, if a core emulates a platform that supports display capture
* (i.e. looking at its own VRAM), then it should perform its rendering as normal
* unless it can prove that the emulated game is not using display capture.
*
* @param[out] data <tt>retro_av_enable_flags *</tt>.
* Pointer to the bitmask of steps that the frontend will skip.
* Other bits are set to zero and are reserved for future use.
* If \c NULL, the frontend will only return whether this environment callback is available.
* @returns \c true if the environment call is available,
* regardless of the value output to \c data.
* If \c false, the core should assume that the frontend will not skip any steps.
* @see retro_av_enable_flags
*/
ENVIRONMENT_GET_AUDIO_VIDEO_ENABLE :: (47|ENVIRONMENT_EXPERIMENTAL)

/**
* Gets an interface that the core can use for raw MIDI I/O.
*
* @param[out] data <tt>struct retro_midi_interface *</tt>.
* Pointer to the MIDI interface.
* May be \c NULL.
* @return \c true if the environment call is available,
* even if \c data is \c NULL.
* @see retro_midi_interface
*/
ENVIRONMENT_GET_MIDI_INTERFACE :: (48|ENVIRONMENT_EXPERIMENTAL)

/**
* Asks the frontend if it's currently in fast-forward mode.
* @param[out] data <tt>bool *</tt>.
* Set to \c true if the frontend is currently fast-forwarding its main loop.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @returns \c true if this environment call is available,
* regardless of the value returned in \c data.
*
* @see ENVIRONMENT_SET_FASTFORWARDING_OVERRIDE
*/
ENVIRONMENT_GET_FASTFORWARDING :: (49|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns the refresh rate the frontend is targeting, in Hz.
* The intended use case is for the core to use the result to select an ideal refresh rate.
*
* @param[out] data <tt>float *</tt>.
* Pointer to the \c float in which the frontend will store its target refresh rate.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @return \c true if this environment call is available,
* regardless of the value returned in \c data.
*/
ENVIRONMENT_GET_TARGET_REFRESH_RATE :: (50|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns whether the frontend can return the state of all buttons at once as a bitmask,
* rather than requiring a series of individual calls to \c retro_input_state_t.
*
* If this callback returns \c true,
* you can get the state of all buttons by passing \c DEVICE_ID_JOYPAD_MASK
* as the \c id parameter to \c retro_input_state_t.
* Bit #N represents the DEVICE_ID_JOYPAD constant of value N,
* e.g. <tt>(1 << DEVICE_ID_JOYPAD_A)</tt> represents the A button.
*
* @param data Ignored.
* @returns \c true if the frontend can report the complete digital joypad state as a bitmask.
* @see retro_input_state_t
* @see DEVICE_JOYPAD
* @see DEVICE_ID_JOYPAD_MASK
*/
ENVIRONMENT_GET_INPUT_BITMASKS :: (51|ENVIRONMENT_EXPERIMENTAL)

/**
* Returns the version of the core options API supported by the frontend.
*
* Over the years, libretro has used several interfaces
* for allowing cores to define customizable options.
* \ref SET_CORE_OPTIONS_V2 "Version 2 of the interface"
* is currently preferred due to its extra features,
* but cores and frontends should strive to support
* versions \ref ENVIRONMENT_SET_CORE_OPTIONS "1"
* and \ref ENVIRONMENT_SET_VARIABLES "0" as well.
* This environment call provides the information that cores need for that purpose.
*
* If this environment call returns \c false,
* then the core should assume version 0 of the core options API.
*
* @param[out] data <tt>unsigned *</tt>.
* Pointer to the integer that will store the frontend's
* supported core options API version.
* Behavior is undefined if \c NULL.
* @returns \c true if the environment call is available,
* \c false otherwise.
* @see ENVIRONMENT_SET_VARIABLES
* @see ENVIRONMENT_SET_CORE_OPTIONS
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
*/
ENVIRONMENT_GET_CORE_OPTIONS_VERSION :: 52

/**
* @copybrief ENVIRONMENT_SET_CORE_OPTIONS_V2
*
* @deprecated This environment call has been superseded
* by ENVIRONMENT_SET_CORE_OPTIONS_V2,
* which supports categorizing options into groups.
* This environment call should only be used to maintain compatibility
* with older cores and frontends.
*
* This environment call is intended to replace \c ENVIRONMENT_SET_VARIABLES,
* and should only be called if \c ENVIRONMENT_GET_CORE_OPTIONS_VERSION
* returns an API version of at least 1.
*
* This should be called the first time as early as possible,
* ideally in \c retro_set_environment (but \c retro_load_game is acceptable).
* It may then be called again later to update
* the core's options and their associated values,
* as long as the number of options doesn't change
* from the number given in the first call.
*
* The core can retrieve option values at any time with \c ENVIRONMENT_GET_VARIABLE.
* If a saved value for a core option doesn't match the option definition's values,
* the frontend may treat it as incorrect and revert to the default.
*
* Core options and their values are usually defined in a large static array,
* but they may be generated at runtime based on the loaded game or system state.
* Here are some use cases for that:
*
* @li Selecting a particular file from one of the
*     \ref ENVIRONMENT_GET_ASSET_DIRECTORY "frontend's"
*     \ref ENVIRONMENT_GET_SAVE_DIRECTORY "content"
*     \ref ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY "directories",
*     such as a memory card image or figurine data file.
* @li Excluding options that are not relevant to the current game,
*     for cores that define a large number of possible options.
* @li Choosing a default value at runtime for a specific game,
*     such as a BIOS file whose region matches that of the loaded content.
*
* @note A guiding principle of libretro's API design is that
* all common interactions (gameplay, menu navigation, etc.)
* should be possible without a keyboard.
* This implies that cores should keep the number of options and values
* as low as possible.
*
* Example entry:
* @code
* {
*     "foo_option",
*     "Speed hack coprocessor X",
*     "Provides increased performance at the expense of reduced accuracy",
*     {
*         { "false",    NULL },
*         { "true",     NULL },
*         { "unstable", "Turbo (Unstable)" },
*         { NULL, NULL },
*     },
*     "false"
* }
* @endcode
*
* @param[in] data <tt>const struct retro_core_option_definition *</tt>.
* Pointer to one or more core option definitions,
* terminated by a \ref retro_core_option_definition whose values are all zero.
* May be \c NULL, in which case the frontend will remove all existing core options.
* The frontend must maintain its own copy of this object,
* including all strings and subobjects.
* @return \c true if this environment call is available.
*
* @see retro_core_option_definition
* @see ENVIRONMENT_GET_VARIABLE
* @see ENVIRONMENT_SET_CORE_OPTIONS_INTL
*/
ENVIRONMENT_SET_CORE_OPTIONS :: 53

/**
* A variant of \ref ENVIRONMENT_SET_CORE_OPTIONS
* that supports internationalization.
*
* @deprecated This environment call has been superseded
* by \ref ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL,
* which supports categorizing options into groups
* (plus translating the groups themselves).
* Only use this environment call to maintain compatibility
* with older cores and frontends.
*
* This should be called instead of \c ENVIRONMENT_SET_CORE_OPTIONS
* if the core provides translations for its options.
* General use is largely the same,
* but see \ref retro_core_options_intl for some important details.
*
* @param[in] data <tt>const struct retro_core_options_intl *</tt>.
* Pointer to a core's option values and their translations.
* @see retro_core_options_intl
* @see ENVIRONMENT_SET_CORE_OPTIONS
*/
ENVIRONMENT_SET_CORE_OPTIONS_INTL :: 54

/**
* Notifies the frontend that it should show or hide the named core option.
*
* Some core options aren't relevant in all scenarios,
* such as a submenu for hardware rendering flags
* when the software renderer is configured.
* This environment call asks the frontend to stop (or start)
* showing the named core option to the player.
* This is only a hint, not a requirement;
* the frontend may ignore this environment call.
* By default, all core options are visible.
*
* @note This environment call must \em only affect a core option's visibility,
* not its functionality or availability.
* \ref ENVIRONMENT_GET_VARIABLE "Getting an invisible core option"
* must behave normally.
*
* @param[in] data <tt>const struct retro_core_option_display *</tt>.
* Pointer to a descriptor for the option that the frontend should show or hide.
* May be \c NULL, in which case the frontend will only return
* whether this environment callback is available.
* @return \c true if this environment call is available,
* even if \c data is \c NULL
* or the specified option doesn't exist.
* @see retro_core_option_display
* @see ENVIRONMENT_SET_CORE_OPTIONS_UPDATE_DISPLAY_CALLBACK
*/
ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY :: 55

/**
* Returns the frontend's preferred hardware rendering API.
* Cores should use this information to decide which API to use with \c ENVIRONMENT_SET_HW_RENDER.
* @param[out] data <tt>retro_hw_context_type *</tt>.
* Pointer to the hardware context type.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* This value will be set even if the environment call returns <tt>false</tt>,
* unless the frontend doesn't implement it.
* @returns \c true if the environment call is available
* and the frontend is able to use a hardware rendering API besides the one returned.
* If \c false is returned and the core cannot use the preferred rendering API,
* then it should exit or fall back to software rendering.
* @note The returned value does not indicate which API is currently in use.
* For example, the frontend may return \c HW_CONTEXT_OPENGL
* while a Direct3D context from a previous session is active;
* this would signal that the frontend's current preference is for OpenGL,
* possibly because the user changed their frontend's video driver while a game is running.
* @see retro_hw_context_type
* @see ENVIRONMENT_GET_HW_RENDER_INTERFACE
* @see ENVIRONMENT_SET_HW_RENDER
*/
ENVIRONMENT_GET_PREFERRED_HW_RENDER :: 56

/**
* Returns the minimum version of the disk control interface supported by the frontend.
*
* If this environment call returns \c false or \c data is 0 or greater,
* then cores may use disk control callbacks
* with \c ENVIRONMENT_SET_DISK_CONTROL_INTERFACE.
* If the reported version is 1 or greater,
* then cores should use \c ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE instead.
*
* @param[out] data <tt>unsigned *</tt>.
* Pointer to the unsigned integer that the frontend's supported disk control interface version will be stored in.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is available.
* @see ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE
*/
ENVIRONMENT_GET_DISK_CONTROL_INTERFACE_VERSION :: 57

/**
* @copybrief ENVIRONMENT_SET_DISK_CONTROL_INTERFACE
*
* This is intended for multi-disk games that expect the player
* to manually swap disks at certain points in the game.
* This version of the disk control interface provides
* more information about disk images.
* Should be called in \c retro_init.
*
* @param[in] data <tt>const struct retro_disk_control_ext_callback *</tt>.
* Pointer to the callback functions to use.
* May be \c NULL, in which case the existing disk callback is deregistered.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
* @see retro_disk_control_ext_callback
*/
ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE :: 58

/**
* Returns the version of the message interface supported by the frontend.
*
* A version of 0 indicates that the frontend
* only supports the legacy \c ENVIRONMENT_SET_MESSAGE interface.
* A version of 1 indicates that the frontend
* supports \c ENVIRONMENT_SET_MESSAGE_EXT as well.
* If this environment call returns \c false,
* the core should behave as if it had returned 0.
*
* @param[out] data <tt>unsigned *</tt>.
* Pointer to the result returned by the frontend.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is available.
* @see ENVIRONMENT_SET_MESSAGE_EXT
* @see ENVIRONMENT_SET_MESSAGE
*/
ENVIRONMENT_GET_MESSAGE_INTERFACE_VERSION :: 59

/**
* Displays a user-facing message for a short time.
*
* Use this callback to convey important status messages,
* such as errors or the result of long-running operations.
* For trivial messages or logging, use \c ENVIRONMENT_GET_LOG_INTERFACE or \c stderr.
*
* This environment call supersedes \c ENVIRONMENT_SET_MESSAGE,
* as it provides many more ways to customize
* how a message is presented to the player.
* However, a frontend that supports this environment call
* must still support \c ENVIRONMENT_SET_MESSAGE.
*
* @param[in] data <tt>const struct retro_message_ext *</tt>.
* Pointer to the message to display to the player.
* Behavior is undefined if \c NULL.
* @returns \c true if this environment call is available.
* @see retro_message_ext
* @see ENVIRONMENT_GET_MESSAGE_INTERFACE_VERSION
*/
ENVIRONMENT_SET_MESSAGE_EXT :: 60

/**
* Returns the number of active input devices currently provided by the frontend.
*
* This may change between frames,
* but will remain constant for the duration of each frame.
*
* If this callback returns \c true,
* a core need not poll any input device
* with an index greater than or equal to the returned value.
*
* If callback returns \c false,
* the number of active input devices is unknown.
* In this case, all input devices should be considered active.
*
* @param[out] data <tt>unsigned *</tt>.
* Pointer to the result returned by the frontend.
* Behavior is undefined if \c NULL.
* @return \c true if this environment call is available.
*/
ENVIRONMENT_GET_INPUT_MAX_USERS :: 61

/**
* Registers a callback that the frontend can use to notify the core
* of the audio output buffer's occupancy.
* Can be used by a core to attempt frame-skipping to avoid buffer under-runs
* (i.e. "crackling" sounds).
*
* @param[in] data <tt>const struct retro_audio_buffer_status_callback *</tt>.
* Pointer to the the buffer status callback,
* or \c NULL to unregister any existing callback.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
*
* @see retro_audio_buffer_status_callback
*/
ENVIRONMENT_SET_AUDIO_BUFFER_STATUS_CALLBACK :: 62

/**
* Requests a minimum frontend audio latency in milliseconds.
*
* This is a hint; the frontend may assign a different audio latency
* to accommodate hardware limits,
* although it should try to honor requests up to 512ms.
*
* This callback has no effect if the requested latency
* is less than the frontend's current audio latency.
* If value is zero or \c data is \c NULL,
* the frontend should set its default audio latency.
*
* May be used by a core to increase audio latency and
* reduce the risk of buffer under-runs (crackling)
* when performing 'intensive' operations.
*
* A core using ENVIRONMENT_SET_AUDIO_BUFFER_STATUS_CALLBACK
* to implement audio-buffer-based frame skipping can get good results
* by setting the audio latency to a high (typically 6x or 8x)
* integer multiple of the expected frame time.
*
* This can only be called from within \c retro_run().
*
* @warning This environment call may require the frontend to reinitialize its audio system.
* This environment call should be used sparingly.
* If the driver is reinitialized,
* \ref retro_audio_callback_t "all audio callbacks" will be updated
* to target the newly-initialized driver.
*
* @param[in] data <tt>const unsigned *</tt>.
* Minimum audio latency, in milliseconds.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
*
* @see ENVIRONMENT_SET_AUDIO_BUFFER_STATUS_CALLBACK
*/
ENVIRONMENT_SET_MINIMUM_AUDIO_LATENCY :: 63

/**
* Allows the core to tell the frontend when it should enable fast-forwarding,
* rather than relying solely on the frontend and user interaction.
*
* Possible use cases include:
*
* \li Temporarily disabling a core's fastforward support
*     while investigating a related bug.
* \li Disabling fastforward during netplay sessions,
*     or when using an emulated console's network features.
* \li Automatically speeding up the game when in a loading screen
*     that cannot be shortened with high-level emulation.
*
* @param[in] data <tt>const struct retro_fastforwarding_override *</tt>.
* Pointer to the parameters that decide when and how
* the frontend is allowed to enable fast-forward mode.
* May be \c NULL, in which case the frontend will return \c true
* without updating the fastforward state,
* which can be used to detect support for this environment call.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
*
* @see retro_fastforwarding_override
* @see ENVIRONMENT_GET_FASTFORWARDING
*/
ENVIRONMENT_SET_FASTFORWARDING_OVERRIDE :: 64
ENVIRONMENT_SET_CONTENT_INFO_OVERRIDE   :: 65

/* const struct retro_system_content_info_override * --
* Allows an implementation to override 'global' content
* info parameters reported by retro_get_system_info().
* Overrides also affect subsystem content info parameters
* set via ENVIRONMENT_SET_SUBSYSTEM_INFO.
* This function must be called inside retro_set_environment().
* If callback returns false, content info overrides
* are unsupported by the frontend, and will be ignored.
* If callback returns true, extended game info may be
* retrieved by calling ENVIRONMENT_GET_GAME_INFO_EXT
* in retro_load_game() or retro_load_game_special().
*
* 'data' points to an array of retro_system_content_info_override
* structs terminated by a { NULL, false, false } element.
* If 'data' is NULL, no changes will be made to the frontend;
* a core may therefore pass NULL in order to test whether
* the ENVIRONMENT_SET_CONTENT_INFO_OVERRIDE and
* ENVIRONMENT_GET_GAME_INFO_EXT callbacks are supported
* by the frontend.
*
* For struct member descriptions, see the definition of
* struct retro_system_content_info_override.
*
* Example:
*
* - struct retro_system_info:
* {
*    "My Core",                      // library_name
*    "v1.0",                         // library_version
*    "m3u|md|cue|iso|chd|sms|gg|sg", // valid_extensions
*    true,                           // need_fullpath
*    false                           // block_extract
* }
*
* - Array of struct retro_system_content_info_override:
* {
*    {
*       "md|sms|gg", // extensions
*       false,       // need_fullpath
*       true         // persistent_data
*    },
*    {
*       "sg",        // extensions
*       false,       // need_fullpath
*       false        // persistent_data
*    },
*    { NULL, false, false }
* }
*
* Result:
* - Files of type m3u, cue, iso, chd will not be
*   loaded by the frontend. Frontend will pass a
*   valid path to the core, and core will handle
*   loading internally
* - Files of type md, sms, gg will be loaded by
*   the frontend. A valid memory buffer will be
*   passed to the core. This memory buffer will
*   remain valid until retro_deinit() returns
* - Files of type sg will be loaded by the frontend.
*   A valid memory buffer will be passed to the core.
*   This memory buffer will remain valid until
*   retro_load_game() (or retro_load_game_special())
*   returns
*
* NOTE: If an extension is listed multiple times in
* an array of retro_system_content_info_override
* structs, only the first instance will be registered
*/
ENVIRONMENT_GET_GAME_INFO_EXT :: 66

/* const struct retro_game_info_ext ** --
* Allows an implementation to fetch extended game
* information, providing additional content path
* and memory buffer status details.
* This function may only be called inside
* retro_load_game() or retro_load_game_special().
* If callback returns false, extended game information
* is unsupported by the frontend. In this case, only
* regular retro_game_info will be available.
* ENVIRONMENT_GET_GAME_INFO_EXT is guaranteed
* to return true if ENVIRONMENT_SET_CONTENT_INFO_OVERRIDE
* returns true.
*
* 'data' points to an array of retro_game_info_ext structs.
*
* For struct member descriptions, see the definition of
* struct retro_game_info_ext.
*
* - If function is called inside retro_load_game(),
*   the retro_game_info_ext array is guaranteed to
*   have a size of 1 - i.e. the returned pointer may
*   be used to access directly the members of the
*   first retro_game_info_ext struct, for example:
*
*      struct retro_game_info_ext *game_info_ext;
*      if (environ_cb(ENVIRONMENT_GET_GAME_INFO_EXT, &game_info_ext))
*         printf("Content Directory: %s\n", game_info_ext->dir);
*
* - If the function is called inside retro_load_game_special(),
*   the retro_game_info_ext array is guaranteed to have a
*   size equal to the num_info argument passed to
*   retro_load_game_special()
*/

/**
* Defines a set of core options that can be shown and configured by the frontend,
* so that the player may customize their gameplay experience to their liking.
*
* @note This environment call is intended to replace
* \c ENVIRONMENT_SET_VARIABLES and \c ENVIRONMENT_SET_CORE_OPTIONS,
* and should only be called if \c ENVIRONMENT_GET_CORE_OPTIONS_VERSION
* returns an API version of at least 2.
*
* This should be called the first time as early as possible,
* ideally in \c retro_set_environment (but \c retro_load_game is acceptable).
* It may then be called again later to update
* the core's options and their associated values,
* as long as the number of options doesn't change
* from the number given in the first call.
*
* The core can retrieve option values at any time with \c ENVIRONMENT_GET_VARIABLE.
* If a saved value for a core option doesn't match the option definition's values,
* the frontend may treat it as incorrect and revert to the default.
*
* Core options and their values are usually defined in a large static array,
* but they may be generated at runtime based on the loaded game or system state.
* Here are some use cases for that:
*
* @li Selecting a particular file from one of the
*     \ref ENVIRONMENT_GET_ASSET_DIRECTORY "frontend's"
*     \ref ENVIRONMENT_GET_SAVE_DIRECTORY "content"
*     \ref ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY "directories",
*     such as a memory card image or figurine data file.
* @li Excluding options that are not relevant to the current game,
*     for cores that define a large number of possible options.
* @li Choosing a default value at runtime for a specific game,
*     such as a BIOS file whose region matches that of the loaded content.
*
* @note A guiding principle of libretro's API design is that
* all common interactions (gameplay, menu navigation, etc.)
* should be possible without a keyboard.
* This implies that cores should keep the number of options and values
* as low as possible.
*
* @param[in] data <tt>const struct retro_core_options_v2 *</tt>.
* Pointer to a core's options and their associated categories.
* May be \c NULL, in which case the frontend will remove all existing core options.
* The frontend must maintain its own copy of this object,
* including all strings and subobjects.
* @return \c true if this environment call is available
* and the frontend supports categories.
* Note that this environment call is guaranteed to successfully register
* the provided core options,
* so the return value does not indicate success or failure.
*
* @see retro_core_options_v2
* @see retro_core_option_v2_category
* @see retro_core_option_v2_definition
* @see ENVIRONMENT_GET_VARIABLE
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL
*/
ENVIRONMENT_SET_CORE_OPTIONS_V2 :: 67

/**
* A variant of \ref ENVIRONMENT_SET_CORE_OPTIONS_V2
* that supports internationalization.
*
* This should be called instead of \c ENVIRONMENT_SET_CORE_OPTIONS_V2
* if the core provides translations for its options.
* General use is largely the same,
* but see \ref retro_core_options_v2_intl for some important details.
*
* @param[in] data <tt>const struct retro_core_options_v2_intl *</tt>.
* Pointer to a core's option values and categories,
* plus a translation for each option and category.
* @see retro_core_options_v2_intl
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
*/
ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL :: 68

/**
* Registers a callback that the frontend can use
* to notify the core that at least one core option
* should be made hidden or visible.
* Allows a frontend to signal that a core must update
* the visibility of any dynamically hidden core options,
* and enables the frontend to detect visibility changes.
* Used by the frontend to update the menu display status
* of core options without requiring a call of retro_run().
* Must be called in retro_set_environment().
*
* @param[in] data <tt>const struct retro_core_options_update_display_callback *</tt>.
* The callback that the frontend should use.
* May be \c NULL, in which case the frontend will unset any existing callback.
* Can be used to query visibility support.
* @return \c true if this environment call is available,
* even if \c data is \c NULL.
* @see retro_core_options_update_display_callback
*/
ENVIRONMENT_SET_CORE_OPTIONS_UPDATE_DISPLAY_CALLBACK :: 69

/**
* Forcibly sets a core option's value.
*
* After changing a core option value with this callback,
* it will be reflected in the frontend
* and \ref ENVIRONMENT_GET_VARIABLE_UPDATE will return \c true.
* \ref retro_variable::key must match
* a \ref ENVIRONMENT_SET_CORE_OPTIONS_V2 "previously-set core option",
* and \ref retro_variable::value must match one of its defined values.
*
* Possible use cases include:
*
* @li Allowing the player to set certain core options
*     without entering the frontend's option menu,
*     using an in-core hotkey.
* @li Adjusting invalid combinations of settings.
* @li Migrating settings from older releases of a core.
*
* @param[in] data <tt>const struct retro_variable *</tt>.
* Pointer to a single option that the core is changing.
* May be \c NULL, in which case the frontend will return \c true
* to indicate that this environment call is available.
* @return \c true if this environment call is available
* and the option named by \c key was successfully
* set to the given \c value.
* \c false if the \c key or \c value fields are \c NULL, empty,
* or don't match a previously set option.
*
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
* @see ENVIRONMENT_GET_VARIABLE
* @see ENVIRONMENT_GET_VARIABLE_UPDATE
*/
ENVIRONMENT_SET_VARIABLE       :: 70
ENVIRONMENT_GET_THROTTLE_STATE :: (71|ENVIRONMENT_EXPERIMENTAL)

/* struct retro_throttle_state * --
* Allows an implementation to get details on the actual rate
* the frontend is attempting to call retro_run().
*/

/**
* Returns information about how the frontend will use savestates.
*
* @param[out] data <tt>retro_savestate_context *</tt>.
* Pointer to the current savestate context.
* May be \c NULL, in which case the environment call
* will return \c true to indicate its availability.
* @returns \c true if the environment call is available,
* even if \c data is \c NULL.
* @see retro_savestate_context
*/
ENVIRONMENT_GET_SAVESTATE_CONTEXT :: (72|ENVIRONMENT_EXPERIMENTAL)

/**
* Before calling \c SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE, will query which interface is supported.
*
* Frontend looks at \c retro_hw_render_interface_type and returns the maximum supported
* context negotiation interface version. If the \c retro_hw_render_interface_type is not
* supported or recognized by the frontend, a version of 0 must be returned in
* \c retro_hw_render_interface's \c interface_version and \c true is returned by frontend.
*
* If this environment call returns true with a \c interface_version greater than 0,
* a core can always use a negotiation interface version larger than what the frontend returns,
* but only earlier versions of the interface will be used by the frontend.
*
* A frontend must not reject a negotiation interface version that is larger than what the
* frontend supports. Instead, the frontend will use the older entry points that it recognizes.
* If this is incompatible with a particular core's requirements, it can error out early.
*
* @note Regarding backwards compatibility, this environment call was introduced after Vulkan v1
* context negotiation. If this environment call is not supported by frontend, i.e. the environment
* call returns \c false , only Vulkan v1 context negotiation is supported (if Vulkan HW rendering
* is supported at all). If a core uses Vulkan negotiation interface with version > 1, negotiation
* may fail unexpectedly. All future updates to the context negotiation interface implies that
* frontend must support this environment call to query support.
*
* @param[out] data <tt>struct retro_hw_render_context_negotiation_interface *</tt>.
* @return \c true if the environment call is available.
* @see SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE
* @see retro_hw_render_interface_type
* @see retro_hw_render_context_negotiation_interface
*/
ENVIRONMENT_GET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_SUPPORT :: (73|ENVIRONMENT_EXPERIMENTAL)

/**
* Asks the frontend whether JIT compilation can be used.
* Primarily used by iOS and tvOS.
* @param[out] data <tt>bool *</tt>.
* Set to \c true if the frontend has verified that JIT compilation is possible.
* @return \c true if the environment call is available.
*/
ENVIRONMENT_GET_JIT_CAPABLE :: 74

/**
* Returns an interface that the core can use to receive microphone input.
*
* @param[out] data <tt>retro_microphone_interface *</tt>.
* Pointer to the microphone interface.
* @return \true if microphone support is available,
* even if no microphones are plugged in.
* \c false if microphone support is disabled unavailable,
* or if \c data is \c NULL.
* @see retro_microphone_interface
*/
ENVIRONMENT_GET_MICROPHONE_INTERFACE :: (75|ENVIRONMENT_EXPERIMENTAL)

/* Environment 76 was an obsolete version of ENVIRONMENT_SET_NETPACKET_INTERFACE.
* It was not used by any known core at the time, and was removed from the API. */

/**
* Returns the device's current power state as reported by the frontend.
*
* This is useful for emulating the battery level in handheld consoles,
* or for reducing power consumption when on battery power.
*
* @note This environment call describes the power state for the entire device,
* not for individual peripherals like controllers.
*
* @param[out] data <struct retro_device_power *>.
* Indicates whether the frontend can provide this information, even if the parameter
* is \c NULL. If the frontend does not support this functionality, then the provided
* argument will remain unchanged.
* @return \c true if the environment call is available.
* @see retro_device_power
*/
ENVIRONMENT_GET_DEVICE_POWER        :: (77|ENVIRONMENT_EXPERIMENTAL)
ENVIRONMENT_SET_NETPACKET_INTERFACE :: 78

/* const struct retro_netpacket_callback * --
* When set, a core gains control over network packets sent and
* received during a multiplayer session. This can be used to
* emulate multiplayer games that were originally played on two
* or more separate consoles or computers connected together.
*
* The frontend will take care of connecting players together,
* and the core only needs to send the actual data as needed for
* the emulation, while handshake and connection management happen
* in the background.
*
* When two or more players are connected and this interface has
* been set, time manipulation features (such as pausing, slow motion,
* fast forward, rewinding, save state loading, etc.) are disabled to
* avoid interrupting communication.
*
* Should be set in either retro_init or retro_load_game, but not both.
*
* When not set, a frontend may use state serialization-based
* multiplayer, where a deterministic core supporting multiple
* input devices does not need to take any action on its own.
*/

/**
* Returns the device's current power state as reported by the frontend.
* This is useful for emulating the battery level in handheld consoles,
* or for reducing power consumption when on battery power.
*
* The return value indicates whether the frontend can provide this information,
* even if the parameter is \c NULL.
*
* If the frontend does not support this functionality,
* then the provided argument will remain unchanged.
* @param[out] data <tt>retro_device_power *</tt>.
* Pointer to the information that the frontend returns about its power state.
* May be \c NULL.
* @return \c true if the environment call is available,
* even if \c data is \c NULL.
* @see retro_device_power
* @note This environment call describes the power state for the entire device,
* not for individual peripherals like controllers.
*/

/**
* Returns the "playlist" directory of the frontend.
*
* This directory can be used to store core generated playlists, in case
* this internal functionality is available (e.g. internal core game detection
* engine).
*
* @param[out] data <tt>const char **</tt>.
* May be \c NULL. If so, no such directory is defined, and it's up to the
* implementation to find a suitable directory.
* @return \c true if the environment call is available.
*/
ENVIRONMENT_GET_PLAYLIST_DIRECTORY :: 79

/**
* Returns the "file browser" start directory of the frontend.
*
* This directory can serve as a start directory for the core in case it
* provides an internal way of loading content.
*
* @param[out] data <tt>const char **</tt>.
* May be \c NULL. If so, no such directory is defined, and it's up to the
* implementation to find a suitable directory.
* @return \c true if the environment call is available.
*/
ENVIRONMENT_GET_FILE_BROWSER_START_DIRECTORY :: 80

/**
* Returns the audio sample rate the frontend is targeting, in Hz.
* The intended use case is for the core to use the result to select an ideal sample rate.
*
* @param[out] data <tt>unsigned *</tt>.
* Pointer to the \c unsigned integer in which the frontend will store its target sample rate.
* Behavior is undefined if \c data is <tt>NULL</tt>.
* @return \c true if this environment call is available,
* regardless of the value returned in \c data.
*/
ENVIRONMENT_GET_TARGET_SAMPLE_RATE :: (81|ENVIRONMENT_EXPERIMENTAL)

/**
* Opaque file handle.
* @since VFS API v1
*/
vfs_file_handle :: struct {}

/**
* Opaque directory handle.
* @since VFS API v3
*/
vfs_dir_handle :: struct {}

/** @defgroup VFS_FILE_ACCESS File Access Flags
* File access flags.
* @since VFS API v1
* @{
*/

/** Opens a file for read-only access. */
VFS_FILE_ACCESS_READ            :: (1<<0)

/**
* Opens a file for write-only access.
* Any existing file at this path will be discarded and overwritten
* unless \c VFS_FILE_ACCESS_UPDATE_EXISTING is also specified.
*/
VFS_FILE_ACCESS_WRITE           :: (1<<1)

/**
* Opens a file for reading and writing.
* Any existing file at this path will be discarded and overwritten
* unless \c VFS_FILE_ACCESS_UPDATE_EXISTING is also specified.
*/
VFS_FILE_ACCESS_READ_WRITE      :: (VFS_FILE_ACCESS_READ|VFS_FILE_ACCESS_WRITE)

/**
* Opens a file without discarding its existing contents.
* Only meaningful if \c VFS_FILE_ACCESS_WRITE is specified.
*/
VFS_FILE_ACCESS_UPDATE_EXISTING :: (1<<2) /* Prevents discarding content of existing files opened for writing */

/** @} */

/** @defgroup VFS_FILE_ACCESS_HINT File Access Hints
*
* Hints to the frontend for how a file will be accessed.
* The VFS implementation may use these to optimize performance,
* react to external interference (such as concurrent writes),
* or it may ignore them entirely.
*
* Hint flags do not change the behavior of each VFS function
* unless otherwise noted.
* @{
*/

/** No particular hints are given. */
VFS_FILE_ACCESS_HINT_NONE              :: (0)

/**
* Indicates that the file will be accessed frequently.
*
* The frontend should cache it or map it into memory.
*/
VFS_FILE_ACCESS_HINT_FREQUENT_ACCESS   :: (1<<0)

/** @} */

/** @defgroup VFS_SEEK_POSITION File Seek Positions
* File access flags and hints.
* @{
*/

/**
* Indicates a seek relative to the start of the file.
*/
VFS_SEEK_POSITION_START    :: 0

/**
* Indicates a seek relative to the current stream position.
*/
VFS_SEEK_POSITION_CURRENT  :: 1

/**
* Indicates a seek relative to the end of the file.
* @note The offset passed to \c retro_vfs_seek_t should be negative.
*/
VFS_SEEK_POSITION_END      :: 2

/** @} */

/** @defgroup VFS_STAT File Status Flags
* File stat flags.
* @see retro_vfs_stat_t
* @since VFS API v3
* @{
*/

/** Indicates that the given path refers to a valid file. */
VFS_STAT_IS_VALID               :: (1<<0)

/** Indicates that the given path refers to a directory. */
VFS_STAT_IS_DIRECTORY           :: (1<<1)

/**
* Indicates that the given path refers to a character special file,
* such as \c /dev/null.
*/
VFS_STAT_IS_CHARACTER_SPECIAL   :: (1<<2)

/**
* Returns the path that was used to open this file.
*
* @param stream The opened file handle to get the path of.
* Behavior is undefined if \c NULL or closed.
* @return The path that was used to open \c stream.
* The string is owned by \c stream and must not be modified.
* @since VFS API v1
* @see filestream_get_path
*/
vfs_get_path_t :: proc "c" (stream: ^vfs_file_handle) -> cstring

/**
* Open a file for reading or writing.
*
* @param path The path to open.
* @param mode A bitwise combination of \c VFS_FILE_ACCESS flags.
* At a minimum, one of \c VFS_FILE_ACCESS_READ or \c VFS_FILE_ACCESS_WRITE must be specified.
* @param hints A bitwise combination of \c VFS_FILE_ACCESS_HINT flags.
* @return A handle to the opened file,
* or \c NULL upon failure.
* Note that this will return \c NULL if \c path names a directory.
* The returned file handle must be closed with \c retro_vfs_close_t.
* @since VFS API v1
* @see File Paths
* @see VFS_FILE_ACCESS
* @see VFS_FILE_ACCESS_HINT
* @see retro_vfs_close_t
* @see filestream_open
*/
vfs_open_t :: proc "c" (path: cstring, mode: u32, hints: u32) -> ^vfs_file_handle

/**
* Close the file and release its resources.
* All files returned by \c retro_vfs_open_t must be closed with this function.
*
* @param stream The file handle to close.
* Behavior is undefined if already closed.
* Upon completion of this function, \c stream is no longer valid
* (even if it returns failure).
* @return 0 on success, -1 on failure or if \c stream is \c NULL.
* @see retro_vfs_open_t
* @see filestream_close
* @since VFS API v1
*/
vfs_close_t :: proc "c" (stream: ^vfs_file_handle) -> i32

/**
* Return the size of the file in bytes.
*
* @param stream The file to query the size of.
* @return Size of the file in bytes, or -1 if there was an error.
* @see filestream_get_size
* @since VFS API v1
*/
vfs_size_t :: proc "c" (stream: ^vfs_file_handle) -> i64

/**
* Set the file's length.
*
* @param stream The file whose length will be adjusted.
* @param length The new length of the file, in bytes.
* If shorter than the original length, the extra bytes will be discarded.
* If longer, the file's padding is unspecified (and likely platform-dependent).
* @return 0 on success,
* -1 on failure.
* @see filestream_truncate
* @since VFS API v2
*/
vfs_truncate_t :: proc "c" (stream: ^vfs_file_handle, length: i64) -> i64

/**
* Gets the given file's current read/write position.
* This position is advanced with each call to \c retro_vfs_read_t or \c retro_vfs_write_t.
*
* @param stream The file to query the position of.
* @return The current stream position in bytes
* or -1 if there was an error.
* @see filestream_tell
* @since VFS API v1
*/
vfs_tell_t :: proc "c" (stream: ^vfs_file_handle) -> i64

/**
* Sets the given file handle's current read/write position.
*
* @param stream The file to set the position of.
* @param offset The new position, in bytes.
* @param seek_position The position to seek from.
* @return The new position,
* or -1 if there was an error.
* @since VFS API v1
* @see File Seek Positions
* @see filestream_seek
*/
vfs_seek_t :: proc "c" (stream: ^vfs_file_handle, offset: i64, seek_position: i32) -> i64

/**
* Read data from a file, if it was opened for reading.
*
* @param stream The file to read from.
* @param s The buffer to read into.
* @param len The number of bytes to read.
* The buffer pointed to by \c s must be this large.
* @return The number of bytes read,
* or -1 if there was an error.
* @since VFS API v1
* @see filestream_read
*/
vfs_read_t :: proc "c" (stream: ^vfs_file_handle, s: rawptr, len: u64) -> i64

/**
* Write data to a file, if it was opened for writing.
*
* @param stream The file handle to write to.
* @param s The buffer to write from.
* @param len The number of bytes to write.
* The buffer pointed to by \c s must be this large.
* @return The number of bytes written,
* or -1 if there was an error.
* @since VFS API v1
* @see filestream_write
*/
vfs_write_t :: proc "c" (stream: ^vfs_file_handle, s: rawptr, len: u64) -> i64

/**
* Flush pending writes to the file, if applicable.
*
* This does not mean that the changes will be immediately persisted to disk;
* that may be scheduled for later, depending on the platform.
*
* @param stream The file handle to flush.
* @return 0 on success, -1 on failure.
* @since VFS API v1
* @see filestream_flush
*/
vfs_flush_t :: proc "c" (stream: ^vfs_file_handle) -> i32

/**
* Deletes the file at the given path.
*
* @param path The path to the file that will be deleted.
* @return 0 on success, -1 on failure.
* @see filestream_delete
* @since VFS API v1
*/
vfs_remove_t :: proc "c" (path: cstring) -> i32

/**
* Rename the specified file.
*
* @param old_path Path to an existing file.
* @param new_path The destination path.
* Must not name an existing file.
* @return 0 on success, -1 on failure
* @see filestream_rename
* @since VFS API v1
*/
vfs_rename_t :: proc "c" (old_path: cstring, new_path: cstring) -> i32

/**
* Gets information about the given file.
*
* @param path The path to the file to query.
* @param[out] size The reported size of the file in bytes.
* May be \c NULL, in which case this value is ignored.
* @return A bitmask of \c VFS_STAT flags,
* or 0 if \c path doesn't refer to a valid file.
* @see path_stat
* @see path_get_size
* @see VFS_STAT
* @since VFS API v3
*/
vfs_stat_t :: proc "c" (path: cstring, size: ^i32) -> i32

/**
* Creates a directory at the given path.
*
* @param dir The desired location of the new directory.
* @return 0 if the directory was created,
* -2 if the directory already exists,
* or -1 if some other error occurred.
* @see path_mkdir
* @since VFS API v3
*/
vfs_mkdir_t :: proc "c" (dir: cstring) -> i32

/**
* Opens a handle to a directory so its contents can be inspected.
*
* @param dir The path to the directory to open.
* Must be an existing directory.
* @param include_hidden Whether to include hidden files in the directory listing.
* The exact semantics of this flag will depend on the platform.
* @return A handle to the opened directory,
* or \c NULL if there was an error.
* @see retro_opendir
* @since VFS API v3
*/
vfs_opendir_t :: proc "c" (dir: cstring, include_hidden: bool) -> ^vfs_dir_handle

/**
* Gets the next dirent ("directory entry")
* within the given directory.
*
* @param[in,out] dirstream The directory to read from.
* Updated to point to the next file, directory, or other path.
* @return \c true when the next dirent was retrieved,
* \c false if there are no more dirents to read.
* @note This API iterates over all files and directories within \c dirstream.
* Remember to check what the type of the current dirent is.
* @note This function does not recurse,
* i.e. it does not return the contents of subdirectories.
* @note This may include "." and ".." on Unix-like platforms.
* @see retro_readdir
* @see retro_vfs_dirent_is_dir_t
* @since VFS API v3
*/
vfs_readdir_t :: proc "c" (dirstream: ^vfs_dir_handle) -> bool

/**
* Gets the filename of the current dirent.
*
* The returned string pointer is valid
* until the next call to \c retro_vfs_readdir_t or \c retro_vfs_closedir_t.
*
* @param dirstream The directory to read from.
* @return The current dirent's name,
* or \c NULL if there was an error.
* @note This function only returns the file's \em name,
* not a complete path to it.
* @see retro_dirent_get_name
* @since VFS API v3
*/
vfs_dirent_get_name_t :: proc "c" (dirstream: ^vfs_dir_handle) -> cstring

/**
* Checks whether the current dirent names a directory.
*
* @param dirstream The directory to read from.
* @return \c true if \c dirstream's current dirent points to a directory,
* \c false if not or if there was an error.
* @see retro_dirent_is_dir
* @since VFS API v3
*/
vfs_dirent_is_dir_t :: proc "c" (dirstream: ^vfs_dir_handle) -> bool

/**
* Closes the given directory and release its resources.
*
* Must be called on any \c retro_vfs_dir_handle returned by \c retro_vfs_open_t.
*
* @param dirstream The directory to close.
* When this function returns (even failure),
* \c dirstream will no longer be valid and must not be used.
* @return 0 on success, -1 on failure.
* @see retro_closedir
* @since VFS API v3
*/
vfs_closedir_t :: proc "c" (dirstream: ^vfs_dir_handle) -> i32

/**
* File system interface exposed by the frontend.
*
* @see dirent_vfs_init
* @see filestream_vfs_init
* @see path_vfs_init
* @see ENVIRONMENT_GET_VFS_INTERFACE
*/
vfs_interface :: struct {
	/* VFS API v1 */
	/** @copydoc retro_vfs_get_path_t */
	get_path: vfs_get_path_t,

	/** @copydoc retro_vfs_open_t */
	open: vfs_open_t,

	/** @copydoc retro_vfs_close_t */
	close: vfs_close_t,

	/** @copydoc retro_vfs_size_t */
	size: vfs_size_t,

	/** @copydoc retro_vfs_tell_t */
	tell: vfs_tell_t,

	/** @copydoc retro_vfs_seek_t */
	seek: vfs_seek_t,

	/** @copydoc retro_vfs_read_t */
	read: vfs_read_t,

	/** @copydoc retro_vfs_write_t */
	write: vfs_write_t,

	/** @copydoc retro_vfs_flush_t */
	flush: vfs_flush_t,

	/** @copydoc retro_vfs_remove_t */
	remove: vfs_remove_t,

	/** @copydoc retro_vfs_rename_t */
	rename: vfs_rename_t,

	/* VFS API v2 */
	
	/** @copydoc retro_vfs_truncate_t */
	truncate: vfs_truncate_t,

	/* VFS API v3 */
	
	/** @copydoc retro_vfs_stat_t */
	stat: vfs_stat_t,

	/** @copydoc retro_vfs_mkdir_t */
	mkdir: vfs_mkdir_t,

	/** @copydoc retro_vfs_opendir_t */
	opendir: vfs_opendir_t,

	/** @copydoc retro_vfs_readdir_t */
	readdir: vfs_readdir_t,

	/** @copydoc retro_vfs_dirent_get_name_t */
	dirent_get_name: vfs_dirent_get_name_t,

	/** @copydoc retro_vfs_dirent_is_dir_t */
	dirent_is_dir: vfs_dirent_is_dir_t,

	/** @copydoc retro_vfs_closedir_t */
	closedir: vfs_closedir_t,
}

/**
* Represents a request by the core for the frontend's file system interface,
* as well as the interface itself returned by the frontend.
*
* You do not need to use these functions directly;
* you may pass this struct to \c dirent_vfs_init,
* \c filestream_vfs_init, or \c path_vfs_init
* so that you can use the wrappers provided by these modules.
*
* @see dirent_vfs_init
* @see filestream_vfs_init
* @see path_vfs_init
* @see ENVIRONMENT_GET_VFS_INTERFACE
*/
vfs_interface_info :: struct {
	/**
	* The minimum version of the VFS API that the core requires.
	* libretro-common's wrapper API initializers will check this value as well.
	*
	* Set to the core's desired VFS version when requesting an interface,
	* and set by the frontend to indicate its actual API version.
	*
	* If the core asks for a newer VFS API version than the frontend supports,
	* the frontend must return \c false within the \c ENVIRONMENT_GET_VFS_INTERFACE call.
	* @since VFS API v1
	*/
	required_interface_version: u32,

	/**
	* Set by the frontend.
	* The frontend will set this to the VFS interface it provides.
	*
	* The interface is owned by the frontend
	* and must not be modified or freed by the core.
	* @since VFS API v1 */
	iface: ^vfs_interface,
}

/**
* Describes the hardware rendering API supported by
* a particular subtype of \c retro_hw_render_interface.
*
* Not every rendering API supported by libretro has its own interface,
* or even needs one.
*
* @see ENVIRONMENT_SET_HW_RENDER
* @see ENVIRONMENT_GET_HW_RENDER_INTERFACE
*/
hw_render_interface_type :: enum u32 {
	/**
	* Indicates a \c retro_hw_render_interface for Vulkan.
	* @see retro_hw_render_interface_vulkan
	*/
	VULKAN    = 0,

	/** Indicates a \c retro_hw_render_interface for Direct3D 9. */
	D3D9      = 1,

	/** Indicates a \c retro_hw_render_interface for Direct3D 10. */
	D3D10     = 2,

	/**
	* Indicates a \c retro_hw_render_interface for Direct3D 11.
	* @see retro_hw_render_interface_d3d11
	*/
	D3D11     = 3,

	/**
	* Indicates a \c retro_hw_render_interface for Direct3D 12.
	* @see retro_hw_render_interface_d3d12
	*/
	D3D12     = 4,

	/**
	* Indicates a \c retro_hw_render_interface for
	* the PlayStation's 2 PSKit API.
	* @see retro_hw_render_interface_gskit_ps2
	*/
	GSKIT_PS2 = 5,

	/** @private Defined to ensure <tt>sizeof(retro_hw_render_interface_type) == sizeof(int)</tt>.
	* Do not use. */
	DUMMY     = 2147483647,
}

/**
* Base render interface type.
* All \c retro_hw_render_interface implementations
* will start with these two fields set to particular values.
*
* @see retro_hw_render_interface_type
* @see ENVIRONMENT_SET_HW_RENDER
* @see ENVIRONMENT_GET_HW_RENDER_INTERFACE
*/
hw_render_interface :: struct {
	/**
	* Denotes the particular rendering API that this interface is for.
	* Each interface requires this field to be set to a particular value.
	* Use it to cast this interface to the appropriate pointer.
	*/
	interface_type: hw_render_interface_type,

	/**
	* The version of this rendering interface.
	* @note This is not related to the version of the API itself.
	*/
	interface_version: u32,
}

/** @copydoc retro_led_interface::set_led_state */
set_led_state_t :: proc "c" (led: i32, state: i32)

/**
* Interface that the core can use to set the state of available LEDs.
* @see ENVIRONMENT_GET_LED_INTERFACE
*/
led_interface :: struct {
	/**
	* Sets the state of an LED.
	*
	* @param led The LED to set the state of.
	* @param state The state to set the LED to.
	* \c true to enable, \c false to disable.
	*/
	set_led_state: set_led_state_t,
}

/**
* Flags that define A/V steps that the core may skip for this frame.
*
* @see ENVIRONMENT_GET_AUDIO_VIDEO_ENABLE
*/
av_enable_flags :: enum u32 {
	/**
	* If set, the core should render video output with \c retro_video_refresh_t as normal.
	*
	* Otherwise, the frontend will discard any video data received this frame,
	* including frames presented via hardware acceleration.
	* \c retro_video_refresh_t will do nothing.
	*
	* @note After running the frame, the video output of the next frame
	* should be no different than if video was enabled,
	* and saving and loading state should have no issues.
	* This implies that the emulated console's graphics pipeline state
	* should not be affected by this flag.
	*
	* @note If emulating a platform that supports display capture
	* (i.e. reading its own VRAM),
	* the core may not be able to completely skip rendering,
	* as the VRAM is part of the graphics pipeline's state.
	*/
	VIDEO              = 1,

	/**
	* If set, the core should render audio output
	* with \c retro_audio_sample_t or \c retro_audio_sample_batch_t as normal.
	*
	* Otherwise, the frontend will discard any audio data received this frame.
	* The core should skip audio rendering if possible.
	*
	* @note After running the frame, the audio output of the next frame
	* should be no different than if audio was enabled,
	* and saving and loading state should have no issues.
	* This implies that the emulated console's audio pipeline state
	* should not be affected by this flag.
	*/
	AUDIO              = 2,

	/**
	* If set, indicates that any savestates taken this frame
	* are guaranteed to be created by the same binary that will load them,
	* and will not be written to or read from the disk.
	*
	* The core may use these guarantees to:
	*
	* @li Assume that loading state will succeed.
	* @li Update its memory buffers in-place if possible.
	* @li Skip clearing memory.
	* @li Skip resetting the system.
	* @li Skip validation steps.
	*
	* @deprecated Use \c ENVIRONMENT_GET_SAVESTATE_CONTEXT instead,
	* except for compatibility purposes.
	*/
	FAST_SAVESTATES    = 4,

	/**
	* If set, indicates that the frontend will never need audio from the core.
	* Used by a frontend for implementing runahead via a secondary core instance.
	*
	* The core may stop synthesizing audio if it can do so
	* without compromising emulation accuracy.
	*
	* Audio output for the next frame does not matter,
	* and the frontend will never need an accurate audio state in the future.
	*
	* State will never be saved while this flag is set.
	*/
	HARD_DISABLE_AUDIO = 8,

	/**
	* @private Defined to ensure <tt>sizeof(retro_av_enable_flags) == sizeof(int)</tt>.
	* Do not use.
	*/
	DUMMY              = 2147483647,
}

/** @copydoc retro_midi_interface::input_enabled */
midi_input_enabled_t :: proc "c" () -> bool

/** @copydoc retro_midi_interface::output_enabled */
midi_output_enabled_t :: proc "c" () -> bool

/** @copydoc retro_midi_interface::read */
midi_read_t :: proc "c" (byte: ^u8) -> bool

/** @copydoc retro_midi_interface::write */
midi_write_t :: proc "c" (byte: u8, delta_time: u32) -> bool

/** @copydoc retro_midi_interface::flush */
midi_flush_t :: proc "c" () -> bool

/**
* Interface that the core can use for raw MIDI I/O.
*/
midi_interface :: struct {
	/**
	* Retrieves the current state of MIDI input.
	*
	* @return \c true if MIDI input is enabled.
	*/
	input_enabled: midi_input_enabled_t,

	/**
	* Retrieves the current state of MIDI output.
	* @return \c true if MIDI output is enabled.
	*/
	output_enabled: midi_output_enabled_t,

	/**
	* Reads a byte from the MIDI input stream.
	*
	* @param[out] byte The byte received from the input stream.
	* @return \c true if a byte was read,
	* \c false if MIDI input is disabled or \c byte is \c NULL.
	*/
	read: midi_read_t,

	/**
	* Writes a byte to the output stream.
	*
	* @param byte The byte to write to the output stream.
	* @param delta_time Time since the previous write, in microseconds.
	* @return \c true if c\ byte was written, false otherwise.
	*/
	write: midi_write_t,

	/**
	* Flushes previously-written data.
	*
	* @return \c true if successful.
	*/
	flush: midi_flush_t,
}

/**
* Describes the hardware rendering API used by
* a particular subtype of \c retro_hw_render_context_negotiation_interface.
*
* Not every rendering API supported by libretro has a context negotiation interface,
* or even needs one.
*
* @see ENVIRONMENT_SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE
* @see ENVIRONMENT_SET_HW_RENDER
* @see ENVIRONMENT_GET_HW_RENDER_INTERFACE
*/
hw_render_context_negotiation_interface_type :: enum u32 {
	/**
	* Denotes a context negotiation interface for Vulkan.
	* @see retro_hw_render_context_negotiation_interface_vulkan
	*/
	VULKAN = 0,

	/**
	* @private Defined to ensure <tt>sizeof(retro_hw_render_context_negotiation_interface_type) == sizeof(int)</tt>.
	* Do not use.
	*/
	DUMMY  = 2147483647,
}

/**
* Base context negotiation interface type.
* All \c retro_hw_render_context_negotiation_interface implementations
* will start with these two fields set to particular values.
*
* @see retro_hw_render_interface_type
* @see ENVIRONMENT_SET_HW_RENDER
* @see ENVIRONMENT_GET_HW_RENDER_INTERFACE
* @see ENVIRONMENT_SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE
*/
hw_render_context_negotiation_interface :: struct {
	/**
	* Denotes the particular rendering API that this interface is for.
	* Each interface requires this field to be set to a particular value.
	* Use it to cast this interface to the appropriate pointer.
	*/
	interface_type: hw_render_context_negotiation_interface_type,

	/**
	* The version of this negotiation interface.
	* @note This is not related to the version of the API itself.
	*/
	interface_version: u32,
}

/** @} */

/** @defgroup SERIALIZATION_QUIRK Serialization Quirks
* @{
*/

/**
* Indicates that serialized state is incomplete in some way.
*
* Set if serialization is usable for the common case of saving and loading game state,
* but should not be relied upon for frame-sensitive frontend features
* such as netplay or rerecording.
*/
SERIALIZATION_QUIRK_INCOMPLETE :: (1<<0)

/**
* Indicates that core must spend some time initializing before serialization can be done.
*
* \c retro_serialize(), \c retro_unserialize(), and \c retro_serialize_size() will initially fail.
*/
SERIALIZATION_QUIRK_MUST_INITIALIZE :: (1<<1)

/** Set by the core to indicate that serialization size may change within a session. */
SERIALIZATION_QUIRK_CORE_VARIABLE_SIZE :: (1<<2)

/** Set by the frontend to acknowledge that it supports variable-sized states. */
SERIALIZATION_QUIRK_FRONT_VARIABLE_SIZE :: (1<<3)

/** Serialized state can only be loaded during the same session. */
SERIALIZATION_QUIRK_SINGLE_SESSION :: (1<<4)

/**
* Serialized state cannot be loaded on an architecture
* with a different endianness from the one it was saved on.
*/
SERIALIZATION_QUIRK_ENDIAN_DEPENDENT :: (1<<5)

/**
* Serialized state cannot be loaded on a different platform
* from the one it was saved on for reasons other than endianness,
* such as word size dependence.
*/
SERIALIZATION_QUIRK_PLATFORM_DEPENDENT :: (1<<6)

/** @} */

/** @defgroup SET_MEMORY_MAPS Memory Descriptors
* @{
*/

/** @defgroup MEMDESC Memory Descriptor Flags
* Information about how the emulated hardware uses this portion of its address space.
* @{
*/

/**
* Indicates that this memory area won't be modified
* once \c retro_load_game has returned.
*/
MEMDESC_CONST      :: (1<<0)

/**
* Indicates a memory area with big-endian byte ordering,
* as opposed to the default of little-endian.
*/
MEMDESC_BIGENDIAN  :: (1<<1)

/**
* Indicates a memory area that is used for the emulated system's main RAM.
*/
MEMDESC_SYSTEM_RAM :: (1<<2)

/**
* Indicates a memory area that is used for the emulated system's save RAM,
* usually found on a game cartridge as battery-backed RAM or flash memory.
*/
MEMDESC_SAVE_RAM   :: (1<<3)

/**
* Indicates a memory area that is used for the emulated system's video RAM,
* usually found on a console's GPU (or local equivalent).
*/
MEMDESC_VIDEO_RAM  :: (1<<4)

/**
* Indicates a memory area that requires all accesses
* to be aligned to 2 bytes or their own size
* (whichever is smaller).
*/
MEMDESC_ALIGN_2    :: (1<<16)

/**
* Indicates a memory area that requires all accesses
* to be aligned to 4 bytes or their own size
* (whichever is smaller).
*/
MEMDESC_ALIGN_4    :: (2<<16)

/**
* Indicates a memory area that requires all accesses
* to be aligned to 8 bytes or their own size
* (whichever is smaller).
*/
MEMDESC_ALIGN_8    :: (3<<16)

/**
* Indicates a memory area that requires all accesses
* to be at least 2 bytes long.
*/
MEMDESC_MINSIZE_2  :: (1<<24)

/**
* Indicates a memory area that requires all accesses
* to be at least 4 bytes long.
*/
MEMDESC_MINSIZE_4  :: (2<<24)

/**
* Indicates a memory area that requires all accesses
* to be at least 8 bytes long.
*/
MEMDESC_MINSIZE_8  :: (3<<24)

/**
* A mapping from a region of the emulated console's address space
* to the host's address space.
*
* Can be used to map an address in the console's address space
* to the host's address space, like so:
*
* @code
* void* emu_to_host(void* addr, struct retro_memory_descriptor* descriptor)
* {
*     return descriptor->ptr + (addr & ~descriptor->disconnect) - descriptor->start;
* }
* @endcode
*
* @see ENVIRONMENT_SET_MEMORY_MAPS
*/
memory_descriptor :: struct {
	/**
	* A bitwise \c OR of one or more \ref MEMDESC "flags"
	* that describe how the emulated system uses this descriptor's address range.
	*
	* @note If \c ptr is \c NULL,
	* then no flags should be set.
	* @see MEMDESC
	*/
	flags: u64,

	/**
	* Pointer to the start of this memory region's buffer
	* within the \em host's address space.
	* The address listed here must be valid for the duration of the session;
	* it must not be freed or modified by the frontend
	* and it must not be moved by the core.
	*
	* May be \c NULL to indicate a lack of accessible memory
	* at the emulated address given in \c start.
	*
	* @note Overlapping descriptors that include the same byte
	* must have the same \c ptr value.
	*/
	ptr: rawptr,

	/**
	* The offset of this memory region,
	* relative to the address given by \c ptr.
	*
	* @note It is recommended to use this field for address calculations
	* instead of performing arithmetic on \c ptr.
	*/
	offset: c.size_t,

	/**
	* The starting address of this memory region
	* <em>within the emulated hardware's address space</em>.
	*
	* @note Not represented as a pointer
	* because it's unlikely to be valid on the host device.
	*/
	start: c.size_t,

	/**
	* A bitmask that specifies which bits of an address must match
	* the bits of the \ref start address.
	*
	* Combines with \c disconnect to map an address to a memory block.
	*
	* If multiple memory descriptors can claim a particular byte,
	* the first one defined in the \ref retro_memory_descriptor array applies.
	* A bit which is set in \c start must also be set in this.
	*
	* Can be zero, in which case \c start and \c len represent
	* the complete mapping for this region of memory
	* (i.e. each byte is mapped exactly once).
	* In this case, \c len must be a power of two.
	*/
	select: c.size_t,

	/**
	* A bitmask of bits that are \em not used for addressing.
	*
	* Any set bits are assumed to be disconnected from
	* the emulated memory chip's address pins,
	* and are therefore ignored when memory-mapping.
	*/
	disconnect: c.size_t,

	/**
	* The length of this memory region, in bytes.
	*
	* If applying \ref start and \ref disconnect to an address
	* results in a value higher than this,
	* the highest bit of the address is cleared.
	*
	* If the address is still too high, the next highest bit is cleared.
	* Can be zero, in which case it's assumed to be
	* bounded only by \ref select and \ref disconnect.
	*/
	len: c.size_t,

	/**
	* A short name for this address space.
	*
	* Names must meet the following requirements:
	*
	* \li Characters must be in the set <tt>[a-zA-Z0-9_-]</tt>.
	* \li No more than 8 characters, plus a \c NULL terminator.
	* \li Names are case-sensitive, but lowercase characters are discouraged.
	* \li A name must not be the same as another name plus a character in the set \c [A-F0-9]
	*     (i.e. if an address space named "RAM" exists,
	*     then the names "RAM0", "RAM1", ..., "RAMF" are forbidden).
	*     This is to allow addresses to be named by each descriptor unambiguously,
	*     even if the areas overlap.
	* \li May be \c NULL or empty (both are considered equivalent).
	*
	* Here are some examples of pairs of address space names:
	*
	* \li \em blank + \em blank: valid (multiple things may be mapped in the same namespace)
	* \li \c Sp + \c Sp: valid (multiple things may be mapped in the same namespace)
	* \li \c SRAM + \c VRAM: valid (neither is a prefix of the other)
	* \li \c V + \em blank: valid (\c V is not in \c [A-F0-9])
	* \li \c a + \em blank: valid but discouraged (\c a is not in \c [A-F0-9])
	* \li \c a + \c A: valid but discouraged (neither is a prefix of the other)
	* \li \c AR + \em blank: valid (\c R is not in \c [A-F0-9])
	* \li \c ARB + \em blank: valid (there's no \c AR namespace,
	*     so the \c B doesn't cause ambiguity).
	* \li \em blank + \c B: invalid, because it's ambiguous which address space \c B1234 would refer to.
	*
	* The length of the address space's name can't be used to disambugiate,
	* as extra information may be appended to it without a separator.
	*/
	addrspace: cstring,
}

/**
* A list of regions within the emulated console's address space.
*
* The frontend may use the largest value of
* \ref retro_memory_descriptor::start + \ref retro_memory_descriptor::select
* in a certain namespace to infer the overall size of the address space.
* If the address space is larger than that,
* the last mapping in \ref descriptors should have \ref retro_memory_descriptor::ptr set to \c NULL
* and \ref retro_memory_descriptor::select should have all bits used in the address space set to 1.
*
* Here's an example set of descriptors for the SNES.
*
* @code{.c}
* struct retro_memory_map snes_descriptors = retro_memory_map
* {
*    .descriptors = (struct retro_memory_descriptor[])
*    {
*       // WRAM; must usually be mapped before the ROM,
*       // as some SNES ROM mappers try to claim 0x7E0000
*       { .addrspace="WRAM", .start=0x7E0000, .len=0x20000 },
*
*       // SPC700 RAM
*       { .addrspace="SPC700", .len=0x10000 },
*
*       // WRAM mirrors
*       { .addrspace="WRAM", .start=0x000000, .select=0xC0E000, .len=0x2000 },
*       { .addrspace="WRAM", .start=0x800000, .select=0xC0E000, .len=0x2000 },
*
*       // WRAM mirror, alternate equivalent descriptor
*       // (Various similar constructions can be created by combining parts of the above two.)
*       { .addrspace="WRAM", .select=0x40E000, .disconnect=~0x1FFF },
*
*       // LoROM (512KB, mirrored a couple of times)
*       { .addrspace="LoROM", .start=0x008000, .select=0x408000, .disconnect=0x8000, .len=512*1024, .flags=MEMDESC_CONST },
*       { .addrspace="LoROM", .start=0x400000, .select=0x400000, .disconnect=0x8000, .len=512*1024, .flags=MEMDESC_CONST },
*
*       // HiROM (4MB)
*       { .addrspace="HiROM", .start=0x400000, .select=0x400000, .len=4*1024*1024, .flags=MEMDESC_CONST },
*       { .addrspace="HiROM", .start=0x008000, .select=0x408000, .len=4*1024*1024, .offset=0x8000, .flags=MEMDESC_CONST },
*
*       // ExHiROM (8MB)
*       { .addrspace="ExHiROM", .start=0xC00000, .select=0xC00000, .len=4*1024*1024, .offset=0, .flags=MEMDESC_CONST },
*       { .addrspace="ExHiROM", .start=0x400000, .select=0xC00000, .len=4*1024*1024, .offset=4*1024*1024, .flags=MEMDESC_CONST },
*       { .addrspace="ExHiROM", .start=0x808000, .select=0xC08000, .len=4*1024*1024, .offset=0x8000, .flags=MEMDESC_CONST },
*       { .addrspace="ExHiROM", .start=0x008000, .select=0xC08000, .len=4*1024*1024, .offset=4*1024*1024+0x8000, .flags=MEMDESC_CONST },
*
*       // Clarifying the full size of the address space
*       { .select=0xFFFFFF, .ptr=NULL },
*    },
*    .num_descriptors = 14,
* };
* @endcode
*
* @see ENVIRONMENT_SET_MEMORY_MAPS
*/
memory_map :: struct {
	/**
	* Pointer to an array of memory descriptors,
	* each of which describes part of the emulated console's address space.
	*/
	descriptors: ^memory_descriptor,

	/** The number of descriptors in \c descriptors. */
	num_descriptors: u32,
}

/**
* Details about a controller (or controller configuration)
* supported by one of a core's emulated input ports.
*
* @see ENVIRONMENT_SET_CONTROLLER_INFO
*/
controller_description :: struct {
	/**
	* A human-readable label for the controller or configuration
	* represented by this device type.
	* Most likely the device's original brand name.
	*/
	desc: cstring,

	/**
	* A unique identifier that will be passed to \c retro_set_controller_port_device()'s \c device parameter.
	* May be the ID of one of \ref DEVICE "the generic controller types",
	* or a subclass ID defined with \c DEVICE_SUBCLASS.
	*
	* @see DEVICE_SUBCLASS
	*/
	id: u32,
}

/**
* Lists the types of controllers supported by
* one of core's emulated input ports.
*
* @see ENVIRONMENT_SET_CONTROLLER_INFO
*/
controller_info :: struct {
	/**
	* A pointer to an array of device types supported by this controller port.
	*
	* @note Ports that support the same devices
	* may share the same underlying array.
	*/
	types: ^controller_description,

	/** The number of elements in \c types. */
	num_types: u32,
}

/**
* Information about a type of memory associated with a subsystem.
* Usually used for SRAM (save RAM).
*
* @see ENVIRONMENT_SET_SUBSYSTEM_INFO
* @see retro_get_memory_data
* @see retro_get_memory_size
*/
subsystem_memory_info :: struct {
	/**
	* The file extension the frontend should use
	* to save this memory region to disk, e.g. "srm" or "sav".
	*/
	extension: cstring,

	/**
	* A constant that identifies this type of memory.
	* Should be at least 0x100 (256) to avoid conflict
	* with the standard libretro memory types,
	* unless a subsystem uses the main platform's memory region.
	* @see MEMORY
	*/
	type: u32,
}

/**
* Information about a type of ROM that a subsystem may use.
* Subsystems may use one or more ROMs at once,
* possibly of different types.
*
* @see ENVIRONMENT_SET_SUBSYSTEM_INFO
* @see retro_subsystem_info
*/
subsystem_rom_info :: struct {
	/**
	* Human-readable description of what the content represents,
	* e.g. "Game Boy ROM".
	*/
	desc: cstring,

	/** @copydoc retro_system_info::valid_extensions */
	valid_extensions: cstring,

	/** @copydoc retro_system_info::need_fullpath */
	need_fullpath: bool,

	/** @copydoc retro_system_info::block_extract */
	block_extract: bool,

	/**
	* Indicates whether this particular subsystem ROM is required.
	* If \c true and the user doesn't provide a ROM,
	* the frontend should not load the core.
	* If \c false and the user doesn't provide a ROM,
	* the frontend should pass a zeroed-out \c retro_game_info
	* to the corresponding entry in \c retro_load_game_special().
	*/
	required: bool,

	/**
	* Pointer to an array of memory descriptors that this subsystem ROM type uses.
	* Useful for secondary cartridges that have their own save data.
	* May be \c NULL, in which case this subsystem ROM's memory is not persisted by the frontend
	* and \c num_memory should be zero.
	*/
	memory: ^subsystem_memory_info,

	/** The number of elements in the array pointed to by \c memory. */
	num_memory: u32,
}

/**
* Information about a secondary platform that a core supports.
* @see ENVIRONMENT_SET_SUBSYSTEM_INFO
*/
subsystem_info :: struct {
	/**
	* A human-readable description of the subsystem type,
	* usually the brand name of the original platform
	* (e.g. "Super Game Boy").
	*/
	desc: cstring,

	/**
	* A short machine-friendly identifier for the subsystem,
	* usually an abbreviation of the platform name.
	* For example, a Super Game Boy subsystem for a SNES core
	* might use an identifier of "sgb".
	* This identifier can be used for command-line interfaces,
	* configuration, or other purposes.
	* Must use lower-case alphabetical characters only (i.e. from a-z).
	*/
	ident: cstring,

	/**
	* The list of ROM types that this subsystem may use.
	*
	* The first entry is considered to be the "most significant" content,
	* for the purposes of the frontend's categorization.
	* E.g. with Super GameBoy, the first content should be the GameBoy ROM,
	* as it is the most "significant" content to a user.
	*
	* If a frontend creates new files based on the content used (e.g. for savestates),
	* it should derive the filenames from the name of the first ROM in this list.
	*
	* @note \c roms can have a single element,
	* but this is usually a sign that the core should broaden its
	* primary system info instead.
	*
	* @see \c retro_system_info
	*/
	roms: ^subsystem_rom_info,

	/** The length of the array given in \c roms. */
	num_roms: u32,

	/** A unique identifier passed to retro_load_game_special(). */
	id: u32,
}

/**
* The function pointer type that \c retro_get_proc_address_t returns.
*
* Despite the signature shown here, the original function may include any parameters and return type
* that respects the calling convention and C ABI.
*
* The frontend is expected to cast the function pointer to the correct type.
*/
proc_address_t :: proc "c" ()

/**
* Get a symbol from a libretro core.
*
* Cores should only return symbols that serve as libretro extensions.
* Frontends should not use this to obtain symbols to standard libretro entry points;
* instead, they should link to the core statically or use \c dlsym (or local equivalent).
*
* The symbol name must be equal to the function name.
* e.g. if <tt>void retro_foo(void);</tt> exists, the symbol in the compiled library must be called \c retro_foo.
* The returned function pointer must be cast to the corresponding type.
*
* @param \c sym The name of the symbol to look up.
* @return Pointer to the exposed function with the name given in \c sym,
* or \c NULL if one couldn't be found.
* @note The frontend is expected to know the returned pointer's type in advance
* so that it can be cast correctly.
* @note The core doesn't need to expose every possible function through this interface.
* It's enough to only expose the ones that it expects the frontend to use.
* @note The functions exposed through this interface
* don't need to be publicly exposed in the compiled library
* (e.g. via \c __declspec(dllexport)).
* @see ENVIRONMENT_SET_PROC_ADDRESS_CALLBACK
*/
get_proc_address_t :: proc "c" (sym: cstring) -> proc_address_t

/**
* An interface that the frontend can use to get function pointers from the core.
*
* @note The returned function pointer will be invalidated once the core is unloaded.
* How and when that happens is up to the frontend.
*
* @see retro_get_proc_address_t
* @see ENVIRONMENT_SET_PROC_ADDRESS_CALLBACK
*/
get_proc_address_interface :: struct {
	/** Set by the core. */
	get_proc_address: get_proc_address_t,
}

/**
* The severity of a given message.
* The frontend may log messages differently depending on the level.
* It may also ignore log messages of a certain level.
* @see retro_log_callback
*/
log_level :: enum u32 {
	/** The logged message is most likely not interesting to the user. */
	DEBUG = 0,

	/** Information about the core operating normally. */
	INFO  = 1,

	/** Indicates a potential problem, possibly one that the core can recover from. */
	WARN  = 2,

	/** Indicates a degraded experience, if not failure. */
	ERROR = 3,

	/** Defined to ensure that sizeof(enum retro_log_level) == sizeof(int). Do not use. */
	DUMMY = 2147483647,
}

/**
* Logs a message to the frontend.
*
* @param level The log level of the message.
* @param fmt The format string to log.
* Same format as \c printf.
* Behavior is undefined if this is \c NULL.
* @param ... Zero or more arguments used by the format string.
* Behavior is undefined if these don't match the ones expected by \c fmt.
* @see retro_log_level
* @see retro_log_callback
* @see ENVIRONMENT_GET_LOG_INTERFACE
* @see printf
*/
log_printf_t :: proc "c" (level: log_level, fmt: cstring, #c_vararg _: ..any)

/**
* Details about how to make log messages.
*
* @see retro_log_printf_t
* @see ENVIRONMENT_GET_LOG_INTERFACE
*/
log_callback :: struct {
	/**
	* Called when logging a message.
	*
	* @note Set by the frontend.
	*/
	log: log_printf_t,
}

/** @} */

/** @defgroup GET_PERF_INTERFACE Performance Interface
* @{
*/

/** @defgroup SIMD CPU Features
* @{
*/

/**
* Indicates CPU support for the SSE instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#ssetechs=SSE
*/
SIMD_SSE      :: (1<<0)

/**
* Indicates CPU support for the SSE2 instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#ssetechs=SSE2
*/
SIMD_SSE2     :: (1<<1)

/** Indicates CPU support for the AltiVec (aka VMX or Velocity Engine) instruction set. */
SIMD_VMX      :: (1<<2)

/** Indicates CPU support for the VMX128 instruction set. Xbox 360 only. */
SIMD_VMX128   :: (1<<3)

/**
* Indicates CPU support for the AVX instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#avxnewtechs=AVX
*/
SIMD_AVX      :: (1<<4)

/**
* Indicates CPU support for the NEON instruction set.
* @see https://developer.arm.com/architectures/instruction-sets/intrinsics/#f:@navigationhierarchiessimdisa=[Neon]
*/
SIMD_NEON     :: (1<<5)

/**
* Indicates CPU support for the SSE3 instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#ssetechs=SSE3
*/
SIMD_SSE3     :: (1<<6)

/**
* Indicates CPU support for the SSSE3 instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#ssetechs=SSSE3
*/
SIMD_SSSE3    :: (1<<7)

/**
* Indicates CPU support for the MMX instruction set.
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=MMX
*/
SIMD_MMX      :: (1<<8)

/** Indicates CPU support for the MMXEXT instruction set. */
SIMD_MMXEXT   :: (1<<9)

/**
* Indicates CPU support for the SSE4 instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#ssetechs=SSE4_1
*/
SIMD_SSE4     :: (1<<10)

/**
* Indicates CPU support for the SSE4.2 instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#ssetechs=SSE4_2
*/
SIMD_SSE42    :: (1<<11)

/**
* Indicates CPU support for the AVX2 instruction set.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#avxnewtechs=AVX2
*/
SIMD_AVX2     :: (1<<12)

/** Indicates CPU support for the VFPU instruction set. PS2 and PSP only.
*
* @see https://pspdev.github.io/vfpu-docs
*/
SIMD_VFPU     :: (1<<13)

/**
* Indicates CPU support for Gekko SIMD extensions. GameCube only.
*/
SIMD_PS       :: (1<<14)

/**
* Indicates CPU support for AES instructions.
*
* @see https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#aestechs=AES&othertechs=AES
*/
SIMD_AES      :: (1<<15)

/**
* Indicates CPU support for the VFPv3 instruction set.
*/
SIMD_VFPV3    :: (1<<16)

/**
* Indicates CPU support for the VFPv4 instruction set.
*/
SIMD_VFPV4    :: (1<<17)

/** Indicates CPU support for the POPCNT instruction. */
SIMD_POPCNT   :: (1<<18)

/** Indicates CPU support for the MOVBE instruction. */
SIMD_MOVBE    :: (1<<19)

/** Indicates CPU support for the CMOV instruction. */
SIMD_CMOV     :: (1<<20)

/** Indicates CPU support for the ASIMD instruction set. */
SIMD_ASIMD    :: (1<<21)

/**
* An abstract unit of ticks.
*
* Usually nanoseconds or CPU cycles,
* but it depends on the platform and the frontend.
*/
perf_tick_t :: u64

/** Time in microseconds. */
time_t :: i64

/**
* A performance counter.
*
* Use this to measure the execution time of a region of code.
* @see retro_perf_callback
*/
perf_counter :: struct {
	/**
	* A human-readable identifier for the counter.
	*
	* May be displayed by the frontend.
	* Behavior is undefined if this is \c NULL.
	*/
	ident: cstring,

	/**
	* The time of the most recent call to \c retro_perf_callback::perf_start
	* on this performance counter.
	*
	* @see retro_perf_start_t
	*/
	start: perf_tick_t,

	/**
	* The total time spent within this performance counter's measured code,
	* i.e. between calls to \c retro_perf_callback::perf_start and \c retro_perf_callback::perf_stop.
	*
	* Updated after each call to \c retro_perf_callback::perf_stop.
	* @see retro_perf_stop_t
	*/
	total: perf_tick_t,

	/**
	* The number of times this performance counter has been started.
	*
	* Updated after each call to \c retro_perf_callback::perf_start.
	* @see retro_perf_start_t
	*/
	call_cnt: perf_tick_t,

	/**
	* \c true if this performance counter has been registered by the frontend.
	* Must be initialized to \c false by the core before registering it.
	* @see retro_perf_register_t
	*/
	registered: bool,
}

/**
* @returns The current system time in microseconds.
* @note Accuracy may vary by platform.
* The frontend should use the most accurate timer possible.
* @see ENVIRONMENT_GET_PERF_INTERFACE
*/
perf_get_time_usec_t :: proc "c" () -> time_t

/**
* @returns The number of ticks since some unspecified epoch.
* The exact meaning of a "tick" depends on the platform,
* but it usually refers to nanoseconds or CPU cycles.
* @see ENVIRONMENT_GET_PERF_INTERFACE
*/
perf_get_counter_t :: proc "c" () -> perf_tick_t

/**
* Returns a bitmask of detected CPU features.
*
* Use this for runtime dispatching of CPU-specific code.
*
* @returns A bitmask of detected CPU features.
* @see ENVIRONMENT_GET_PERF_INTERFACE
* @see SIMD
*/
get_cpu_features_t :: proc "c" () -> u64

/**
* Asks the frontend to log or display the state of performance counters.
* How this is done depends on the frontend.
* Performance counters can be reviewed manually as well.
*
* @see ENVIRONMENT_GET_PERF_INTERFACE
* @see retro_perf_counter
*/
perf_log_t :: proc "c" ()

/**
* Registers a new performance counter.
*
* If \c counter has already been registered beforehand,
* this function does nothing.
*
* @param counter The counter to register.
* \c counter::ident must be set to a unique identifier,
* and all other values in \c counter must be set to zero or \c false.
* Behavior is undefined if \c NULL.
* @post If \c counter is successfully registered,
* then \c counter::registered will be set to \c true.
* Otherwise, it will be set to \c false.
* Registration may fail if the frontend's maximum number of counters (if any) has been reached.
* @note The counter is owned by the core and must not be freed by the frontend.
* The frontend must also clean up any references to a core's performance counters
* before unloading it, otherwise undefined behavior may occur.
* @see retro_perf_start_t
* @see retro_perf_stop_t
*/
perf_register_t :: proc "c" (counter: ^perf_counter)

/**
* Starts a registered performance counter.
*
* Call this just before the code you want to measure.
*
* @param counter The counter to start.
* Behavior is undefined if \c NULL.
* @see retro_perf_stop_t
*/
perf_start_t :: proc "c" (counter: ^perf_counter)

/**
* Stops a registered performance counter.
*
* Call this just after the code you want to measure.
*
* @param counter The counter to stop.
* Behavior is undefined if \c NULL.
* @see retro_perf_start_t
* @see retro_perf_stop_t
*/
perf_stop_t :: proc "c" (counter: ^perf_counter)

/**
* An interface that the core can use to get performance information.
*
* Here's a usage example:
*
* @code{.c}
* #ifdef PROFILING
* // Wrapper macros to simplify using performance counters.
* // Optional; tailor these to your project's needs.
* #define PERFORMANCE_INIT(perf_cb, name) static struct retro_perf_counter name = {#name}; if (!name.registered) perf_cb.perf_register(&(name))
* #define PERFORMANCE_START(perf_cb, name) perf_cb.perf_start(&(name))
* #define PERFORMANCE_STOP(perf_cb, name) perf_cb.perf_stop(&(name))
* #else
* // Exclude the performance counters if profiling is disabled.
* #define PERFORMANCE_INIT(perf_cb, name) ((void)0)
* #define PERFORMANCE_START(perf_cb, name) ((void)0)
* #define PERFORMANCE_STOP(perf_cb, name) ((void)0)
* #endif
*
* // Defined somewhere else in the core.
* extern struct retro_perf_callback perf_cb;
*
* void retro_run(void)
* {
*    PERFORMANCE_INIT(cb, interesting);
*    PERFORMANCE_START(cb, interesting);
*    interesting_work();
*    PERFORMANCE_STOP(cb, interesting);
*
*    PERFORMANCE_INIT(cb, maybe_slow);
*    PERFORMANCE_START(cb, maybe_slow);
*    more_interesting_work();
*    PERFORMANCE_STOP(cb, maybe_slow);
* }
*
* void retro_deinit(void)
* {
*    // Asks the frontend to log the results of all performance counters.
*    perf_cb.perf_log();
* }
* @endcode
*
* All functions are set by the frontend.
*
* @see ENVIRONMENT_GET_PERF_INTERFACE
*/
perf_callback :: struct {
	/** @copydoc retro_perf_get_time_usec_t */
	get_time_usec: perf_get_time_usec_t,

	/** @copydoc retro_perf_get_counter_t */
	get_cpu_features: get_cpu_features_t,

	/** @copydoc retro_perf_get_counter_t */
	get_perf_counter: perf_get_counter_t,

	/** @copydoc retro_perf_register_t */
	perf_register: perf_register_t,

	/** @copydoc retro_perf_start_t */
	perf_start: perf_start_t,

	/** @copydoc retro_perf_stop_t */
	perf_stop: perf_stop_t,

	/** @copydoc retro_perf_log_t */
	perf_log: perf_log_t,
}

/**
* Defines actions that can be performed on sensors.
* @note Cores should only enable sensors while they're actively being used;
* depending on the frontend and platform,
* enabling these sensors may impact battery life.
*
* @see ENVIRONMENT_GET_SENSOR_INTERFACE
* @see retro_sensor_interface
* @see retro_set_sensor_state_t
*/
sensor_action :: enum u32 {
	/** Enables accelerometer input, if one exists. */
	ACCELEROMETER_ENABLE  = 0,

	/** Disables accelerometer input, if one exists. */
	ACCELEROMETER_DISABLE = 1,

	/** Enables gyroscope input, if one exists. */
	GYROSCOPE_ENABLE      = 2,

	/** Disables gyroscope input, if one exists. */
	GYROSCOPE_DISABLE     = 3,

	/** Enables ambient light input, if a luminance sensor exists. */
	ILLUMINANCE_ENABLE    = 4,

	/** Disables ambient light input, if a luminance sensor exists. */
	ILLUMINANCE_DISABLE   = 5,

	/** @private Defined to ensure <tt>sizeof(enum retro_sensor_action) == sizeof(int)</tt>. Do not use. */
	DUMMY                 = 2147483647,
}

/** @defgroup SENSOR_ID Sensor Value IDs
* @{
*/
/* Id values for SENSOR types. */

/**
* Returns the device's acceleration along its local X axis minus the effect of gravity, in m/s^2.
*
* Positive values mean that the device is accelerating to the right.
* assuming the user is looking at it head-on.
*/
SENSOR_ACCELEROMETER_X :: 0

/**
* Returns the device's acceleration along its local Y axis minus the effect of gravity, in m/s^2.
*
* Positive values mean that the device is accelerating upwards,
* assuming the user is looking at it head-on.
*/
SENSOR_ACCELEROMETER_Y :: 1

/**
* Returns the the device's acceleration along its local Z axis minus the effect of gravity, in m/s^2.
*
* Positive values indicate forward acceleration towards the user,
* assuming the user is looking at the device head-on.
*/
SENSOR_ACCELEROMETER_Z :: 2

/**
* Returns the angular velocity of the device around its local X axis, in radians per second.
*
* Positive values indicate counter-clockwise rotation.
*
* @note A radian is about 57 degrees, and a full 360-degree rotation is 2*pi radians.
* @see https://developer.android.com/reference/android/hardware/SensorEvent#sensor.type_gyroscope
* for guidance on using this value to derive a device's orientation.
*/
SENSOR_GYROSCOPE_X :: 3

/**
* Returns the angular velocity of the device around its local Z axis, in radians per second.
*
* Positive values indicate counter-clockwise rotation.
*
* @note A radian is about 57 degrees, and a full 360-degree rotation is 2*pi radians.
* @see https://developer.android.com/reference/android/hardware/SensorEvent#sensor.type_gyroscope
* for guidance on using this value to derive a device's orientation.
*/
SENSOR_GYROSCOPE_Y :: 4

/**
* Returns the angular velocity of the device around its local Z axis, in radians per second.
*
* Positive values indicate counter-clockwise rotation.
*
* @note A radian is about 57 degrees, and a full 360-degree rotation is 2*pi radians.
* @see https://developer.android.com/reference/android/hardware/SensorEvent#sensor.type_gyroscope
* for guidance on using this value to derive a device's orientation.
*/
SENSOR_GYROSCOPE_Z :: 5

/**
* Returns the ambient illuminance (light intensity) of the device's environment, in lux.
*
* @see https://en.wikipedia.org/wiki/Lux for a table of common lux values.
*/
SENSOR_ILLUMINANCE :: 6

/**
* Adjusts the state of a sensor.
*
* @param port The device port of the controller that owns the sensor given in \c action.
* @param action The action to perform on the sensor.
* Different devices support different sensors.
* @param rate The rate at which the underlying sensor should be updated, in Hz.
* This should be treated as a hint,
* as some device sensors may not support the requested rate
* (if it's configurable at all).
* @returns \c true if the sensor state was successfully adjusted, \c false otherwise.
* @note If one of the \c SENSOR_*_ENABLE actions fails,
* this likely means that the given sensor is not available
* on the provided \c port.
* @see retro_sensor_action
*/
set_sensor_state_t :: proc "c" (port: u32, action: sensor_action, rate: u32) -> bool

/**
* Retrieves the current value reported by sensor.
* @param port The device port of the controller that owns the sensor given in \c id.
* @param id The sensor value to query.
* @returns The current sensor value.
* Exact semantics depend on the value given in \c id,
* but will return 0 for invalid arguments.
*
* @see SENSOR_ID
*/
sensor_get_input_t :: proc "c" (port: u32, id: u32) -> f32

/**
* An interface that cores can use to access device sensors.
*
* All function pointers are set by the frontend.
*/
sensor_interface :: struct {
	/** @copydoc retro_set_sensor_state_t */
	set_sensor_state: set_sensor_state_t,

	/** @copydoc retro_sensor_get_input_t */
	get_sensor_input: sensor_get_input_t,
}

/**
* Denotes the type of buffer in which the camera will store its input.
*
* Different camera drivers may support different buffer types.
*
* @see ENVIRONMENT_GET_CAMERA_INTERFACE
* @see retro_camera_callback
*/
camera_buffer :: enum u32 {
	/**
	* Indicates that camera frames should be delivered to the core as an OpenGL texture.
	*
	* Requires that the core is using an OpenGL context via \c ENVIRONMENT_SET_HW_RENDER.
	*
	* @see retro_camera_frame_opengl_texture_t
	*/
	OPENGL_TEXTURE  = 0,

	/**
	* Indicates that camera frames should be delivered to the core as a raw buffer in memory.
	*
	* @see retro_camera_frame_raw_framebuffer_t
	*/
	RAW_FRAMEBUFFER = 1,

	/**
	* @private Defined to ensure <tt>sizeof(enum retro_camera_buffer) == sizeof(int)</tt>.
	* Do not use.
	*/
	DUMMY           = 2147483647,
}

/**
* Starts an initialized camera.
* The camera is disabled by default,
* and must be enabled with this function before being used.
*
* Set by the frontend.
*
* @returns \c true if the camera was successfully started, \c false otherwise.
* Failure may occur if no actual camera is available,
* or if the frontend doesn't have permission to access it.
* @note Must be called in \c retro_run().
* @see retro_camera_callback
*/
camera_start_t :: proc "c" () -> bool

/**
* Stops the running camera.
*
* Set by the frontend.
*
* @note Must be called in \c retro_run().
* @warning The frontend may close the camera on its own when unloading the core,
* but this behavior is not guaranteed.
* Cores should clean up the camera before exiting.
* @see retro_camera_callback
*/
camera_stop_t :: proc "c" ()

/**
* Called by the frontend to report the state of the camera driver.
*
* @see retro_camera_callback
*/
camera_lifetime_status_t :: proc "c" ()

/**
* Called by the frontend to report a new camera frame,
* delivered as a raw buffer in memory.
*
* Set by the core.
*
* @param buffer Pointer to the camera's most recent video frame.
* Each pixel is in XRGB8888 format.
* The first pixel represents the top-left corner of the image
* (i.e. the Y axis goes downward).
* @param width The width of the frame given in \c buffer, in pixels.
* @param height The height of the frame given in \c buffer, in pixels.
* @param pitch The width of the frame given in \c buffer, in bytes.
* @warning \c buffer may be invalidated when this function returns,
* so the core should make its own copy of \c buffer if necessary.
* @see CAMERA_BUFFER_RAW_FRAMEBUFFER
*/
camera_frame_raw_framebuffer_t :: proc "c" (buffer: ^u32, width: u32, height: u32, pitch: c.size_t)

/**
* Called by the frontend to report a new camera frame,
* delivered as an OpenGL texture.
*
* @param texture_id The ID of the OpenGL texture that represents the camera's most recent frame.
* Owned by the frontend, and must not be modified by the core.
* @param texture_target The type of the texture given in \c texture_id.
* Usually either \c GL_TEXTURE_2D or \c GL_TEXTURE_RECTANGLE,
* but other types are allowed.
* @param affine A pointer to a 3x3 column-major affine matrix
* that can be used to transform pixel coordinates to texture coordinates.
* After transformation, the bottom-left corner should have coordinates of <tt>(0, 0)</tt>
* and the top-right corner should have coordinates of <tt>(1, 1)</tt>
* (or <tt>(width, height)</tt> for \c GL_TEXTURE_RECTANGLE).
*
* @note GL-specific typedefs (e.g. \c GLfloat and \c GLuint) are avoided here
* so that the API doesn't rely on gl.h.
* @warning \c texture_id and \c affine may be invalidated when this function returns,
* so the core should make its own copy of them if necessary.
*/
camera_frame_opengl_texture_t :: proc "c" (texture_id: u32, texture_target: u32, affine: ^f32)

/**
* An interface that the core can use to access a device's camera.
*
* @see ENVIRONMENT_GET_CAMERA_INTERFACE
*/
camera_callback :: struct {
	/**
	* Requested camera capabilities,
	* given as a bitmask of \c retro_camera_buffer values.
	* Set by the core.
	*
	* Here's a usage example:
	* @code
	* // Requesting support for camera data delivered as both an OpenGL texture and a pixel buffer:
	* struct retro_camera_callback callback;
	* callback.caps = (1 << CAMERA_BUFFER_OPENGL_TEXTURE) | (1 << CAMERA_BUFFER_RAW_FRAMEBUFFER);
	* @endcode
	*/
	caps: u64,

	/**
	* The desired width of the camera frame, in pixels.
	* This is only a hint; the frontend may provide a different size.
	* Set by the core.
	* Use zero to let the frontend decide.
	*/
	width: u32,

	/**
	* The desired height of the camera frame, in pixels.
	* This is only a hint; the frontend may provide a different size.
	* Set by the core.
	* Use zero to let the frontend decide.
	*/
	height: u32,

	/**
	* @copydoc retro_camera_start_t
	* @see retro_camera_callback
	*/
	start: camera_start_t,

	/**
	* @copydoc retro_camera_stop_t
	* @see retro_camera_callback
	*/
	stop: camera_stop_t,

	/**
	* @copydoc retro_camera_frame_raw_framebuffer_t
	* @note If \c NULL, this function will not be called.
	*/
	frame_raw_framebuffer: camera_frame_raw_framebuffer_t,

	/**
	* @copydoc retro_camera_frame_opengl_texture_t
	* @note If \c NULL, this function will not be called.
	*/
	frame_opengl_texture: camera_frame_opengl_texture_t,

	/**
	* Core-defined callback invoked by the frontend right after the camera driver is initialized
	* (\em not when calling \c start).
	* May be \c NULL, in which case this function is skipped.
	*/
	initialized: camera_lifetime_status_t,

	/**
	* Core-defined callback invoked by the frontend
	* right before the video camera driver is deinitialized
	* (\em not when calling \c stop).
	* May be \c NULL, in which case this function is skipped.
	*/
	deinitialized: camera_lifetime_status_t,
}

/** @copydoc retro_location_callback::set_interval */
location_set_interval_t :: proc "c" (interval_ms: u32, interval_distance: u32)

/** @copydoc retro_location_callback::start */
location_start_t :: proc "c" () -> bool

/** @copydoc retro_location_callback::stop */
location_stop_t :: proc "c" ()

/** @copydoc retro_location_callback::get_position */
location_get_position_t :: proc "c" (lat: ^f64, lon: ^f64, horiz_accuracy: ^f64, vert_accuracy: ^f64) -> bool

/** Function type that reports the status of the location service. */
location_lifetime_status_t :: proc "c" ()

/**
* An interface that the core can use to access a device's location.
*
* @note It is the frontend's responsibility to request the necessary permissions
* from the operating system.
* @see ENVIRONMENT_GET_LOCATION_INTERFACE
*/
location_callback :: struct {
	/**
	* Starts listening the device's location service.
	*
	* The frontend will report changes to the device's location
	* at the interval defined by \c set_interval.
	* Set by the frontend.
	*
	* @return true if location services were successfully started, false otherwise.
	* Note that this will return \c false if location services are disabled
	* or the frontend doesn't have permission to use them.
	* @note The device's location service may or may not have been enabled
	* before the core calls this function.
	*/
	start: location_start_t,

	/**
	* Stop listening to the device's location service.
	*
	* Set by the frontend.
	*
	* @note The location service itself may or may not
	* be turned off by this function,
	* depending on the platform and the frontend.
	* @post The core will stop receiving location service updates.
	*/
	stop: location_stop_t,

	/**
	* Returns the device's current coordinates.
	*
	* Set by the frontend.
	*
	* @param[out] lat Pointer to latitude, in degrees.
	* Will be set to 0 if no change has occurred since the last call.
	* Behavior is undefined if \c NULL.
	* @param[out] lon Pointer to longitude, in degrees.
	* Will be set to 0 if no change has occurred since the last call.
	* Behavior is undefined if \c NULL.
	* @param[out] horiz_accuracy Pointer to horizontal accuracy.
	* Will be set to 0 if no change has occurred since the last call.
	* Behavior is undefined if \c NULL.
	* @param[out] vert_accuracy Pointer to vertical accuracy.
	* Will be set to 0 if no change has occurred since the last call.
	* Behavior is undefined if \c NULL.
	*/
	get_position: location_get_position_t,

	/**
	* Sets the rate at which the location service should report updates.
	*
	* This is only a hint; the actual rate may differ.
	* Sets the interval of time and/or distance at which to update/poll
	* location-based data.
	*
	* Some platforms may only support one of the two parameters;
	* cores should provide both to ensure compatibility.
	*
	* Set by the frontend.
	*
	* @param interval_ms The desired period of time between location updates, in milliseconds.
	* @param interval_distance The desired distance between location updates, in meters.
	*/
	set_interval: location_set_interval_t,

	/** Called when the location service is initialized. Set by the core. Optional. */
	initialized: location_lifetime_status_t,

	/** Called when the location service is deinitialized. Set by the core. Optional. */
	deinitialized: location_lifetime_status_t,
}

/**
* The type of rumble motor in a controller.
*
* Both motors can be controlled independently,
* and the strong motor does not override the weak motor.
* @see ENVIRONMENT_GET_RUMBLE_INTERFACE
*/
rumble_effect :: enum u32 {
	STRONG = 0,
	WEAK   = 1,

	/** @private Defined to ensure <tt>sizeof(enum retro_rumble_effect) == sizeof(int)</tt>. Do not use. */
	DUMMY  = 2147483647,
}

/**
* Requests a rumble state change for a controller.
* Set by the frontend.
*
* @param port The controller port to set the rumble state for.
* @param effect The rumble motor to set the strength of.
* @param strength The desired intensity of the rumble motor, ranging from \c 0 to \c 0xffff (inclusive).
* @return \c true if the requested rumble state was honored.
* If the controller doesn't support rumble, will return \c false.
* @note Calling this before the first \c retro_run() may return \c false.
* @see ENVIRONMENT_GET_RUMBLE_INTERFACE
*/
set_rumble_state_t :: proc "c" (port: u32, effect: rumble_effect, strength: u16) -> bool

/**
* An interface that the core can use to set the rumble state of a controller.
* @see ENVIRONMENT_GET_RUMBLE_INTERFACE
*/
rumble_interface :: struct {
	/** @copydoc retro_set_rumble_state_t */
	set_rumble_state: set_rumble_state_t,
}

/**
* Called by the frontend to request audio samples.
* The core should render audio within this function
* using the callback provided by \c retro_set_audio_sample or \c retro_set_audio_sample_batch.
*
* @warning This function may be called by any thread,
* therefore it must be thread-safe.
* @see ENVIRONMENT_SET_AUDIO_CALLBACK
* @see retro_audio_callback
* @see retro_audio_sample_batch_t
* @see retro_audio_sample_t
*/
audio_callback_t :: proc "c" ()

/**
* Called by the frontend to notify the core that it should pause or resume audio rendering.
* The initial state of the audio driver after registering this callback is \c false (inactive).
*
* @param enabled \c true if the frontend's audio driver is active.
* If so, the registered audio callback will be called regularly.
* If not, the audio callback will not be invoked until the next time
* the frontend calls this function with \c true.
* @warning This function may be called by any thread,
* therefore it must be thread-safe.
* @note Even if no audio samples are rendered,
* the core should continue to update its emulated platform's audio engine if necessary.
* @see ENVIRONMENT_SET_AUDIO_CALLBACK
* @see retro_audio_callback
* @see retro_audio_callback_t
*/
audio_set_state_callback_t :: proc "c" (enabled: bool)

/**
* An interface that the frontend uses to request audio samples from the core.
* @note To unregister a callback, pass a \c retro_audio_callback_t
* with both fields set to <tt>NULL</tt>.
* @see ENVIRONMENT_SET_AUDIO_CALLBACK
*/
audio_callback :: struct {
	/** @see retro_audio_callback_t */
	callback: audio_callback_t,

	/** @see retro_audio_set_state_callback_t */
	set_state: audio_set_state_callback_t,
}

usec_t :: i64

/**
* Called right before each iteration of \c retro_run
* if registered via <tt>ENVIRONMENT_SET_FRAME_TIME_CALLBACK</tt>.
*
* @param usec Time since the last call to <tt>retro_run</tt>, in microseconds.
* If the frontend is manipulating the frame time
* (e.g. via fast-forward or slow motion),
* this value will be the reference value initially provided to the environment call.
* @see ENVIRONMENT_SET_FRAME_TIME_CALLBACK
* @see retro_frame_time_callback
*/
frame_time_callback_t :: proc "c" (usec: usec_t)

/**
* @see ENVIRONMENT_SET_FRAME_TIME_CALLBACK
*/
frame_time_callback :: struct {
	/**
	* Called to notify the core of the current frame time.
	* If <tt>NULL</tt>, the frontend will clear its registered callback.
	*/
	callback: frame_time_callback_t,

	/**
	* The ideal duration of one frame, in microseconds.
	* Compute it as <tt>1000000 / fps</tt>.
	* The frontend will resolve rounding to ensure that framestepping, etc is exact.
	*/
	reference: usec_t,
}

/**
* Notifies a libretro core of how full the frontend's audio buffer is.
* Set by the core, called by the frontend.
* It will be called right before \c retro_run() every frame.
*
* @param active \c true if the frontend's audio buffer is currently in use,
* \c false if audio is disabled in the frontend.
* @param occupancy A value between 0 and 100 (inclusive),
* corresponding to the frontend's audio buffer occupancy percentage.
* @param underrun_likely \c true if the frontend expects an audio buffer underrun
* during the next frame, which indicates that a core should attempt frame-skipping.
*/
audio_buffer_status_callback_t :: proc "c" (active: bool, occupancy: u32, underrun_likely: bool)

/**
* A callback to register with the frontend to receive audio buffer occupancy information.
*/
audio_buffer_status_callback :: struct {
	/** @copydoc retro_audio_buffer_status_callback_t */
	callback: audio_buffer_status_callback_t,
}

/* Invalidates the current HW context.
* Any GL state is lost, and must not be deinitialized explicitly.
* If explicit deinitialization is desired by the libretro core,
* it should implement context_destroy callback.
* If called, all GPU resources must be reinitialized.
* Usually called when frontend reinits video driver.
* Also called first time video driver is initialized,
* allowing libretro core to initialize resources.
*/
hw_context_reset_t :: proc "c" ()

/* Gets current framebuffer which is to be rendered to.
* Could change every frame potentially.
*/
hw_get_current_framebuffer_t :: proc "c" () -> c.uintptr_t

/* Get a symbol from HW context. */
hw_get_proc_address_t :: proc "c" (sym: cstring) -> proc_address_t

hw_context_type :: enum u32 {
	NONE             = 0,

	/* OpenGL 2.x. Driver can choose to use latest compatibility context. */
	OPENGL           = 1,

	/* OpenGL ES 2.0. */
	OPENGLES2        = 2,

	/* Modern desktop core GL context. Use version_major/
	* version_minor fields to set GL version. */
	OPENGL_CORE      = 3,

	/* OpenGL ES 3.0 */
	OPENGLES3        = 4,

	/* OpenGL ES 3.1+. Set version_major/version_minor. For GLES2 and GLES3,
	* use the corresponding enums directly. */
	OPENGLES_VERSION = 5,

	/* Vulkan, see ENVIRONMENT_GET_HW_RENDER_INTERFACE. */
	VULKAN           = 6,

	/* Direct3D11, see ENVIRONMENT_GET_HW_RENDER_INTERFACE */
	D3D11            = 7,

	/* Direct3D10, see ENVIRONMENT_GET_HW_RENDER_INTERFACE */
	D3D10            = 8,

	/* Direct3D12, see ENVIRONMENT_GET_HW_RENDER_INTERFACE */
	D3D12            = 9,

	/* Direct3D9, see ENVIRONMENT_GET_HW_RENDER_INTERFACE */
	D3D9             = 10,

	/** Dummy value to ensure sizeof(enum retro_hw_context_type) == sizeof(int). Do not use. */
	DUMMY            = 2147483647,
}

hw_render_callback :: struct {
	/* Which API to use. Set by libretro core. */
	context_type: hw_context_type,

	/* Called when a context has been created or when it has been reset.
	* An OpenGL context is only valid after context_reset() has been called.
	*
	* When context_reset is called, OpenGL resources in the libretro
	* implementation are guaranteed to be invalid.
	*
	* It is possible that context_reset is called multiple times during an
	* application lifecycle.
	* If context_reset is called without any notification (context_destroy),
	* the OpenGL context was lost and resources should just be recreated
	* without any attempt to "free" old resources.
	*/
	context_reset: hw_context_reset_t,

	/* Set by frontend.
	* TODO: This is rather obsolete. The frontend should not
	* be providing preallocated framebuffers. */
	get_current_framebuffer: hw_get_current_framebuffer_t,

	/* Set by frontend.
	* Can return all relevant functions, including glClear on Windows. */
	get_proc_address: hw_get_proc_address_t,

	/* Set if render buffers should have depth component attached.
	* TODO: Obsolete. */
	depth: bool,

	/* Set if stencil buffers should be attached.
	* TODO: Obsolete. */
	stencil: bool,

	/* If depth and stencil are true, a packed 24/8 buffer will be added.
	* Only attaching stencil is invalid and will be ignored. */
	
	/* Use conventional bottom-left origin convention. If false,
	* standard libretro top-left origin semantics are used.
	* TODO: Move to GL specific interface. */
	bottom_left_origin: bool,

	/* Major version number for core GL context or GLES 3.1+. */
	version_major: u32,

	/* Minor version number for core GL context or GLES 3.1+. */
	version_minor: u32,

	/* If this is true, the frontend will go very far to avoid
	* resetting context in scenarios like toggling fullscreen, etc.
	* TODO: Obsolete? Maybe frontend should just always assume this ...
	*/
	cache_context: bool,

	/* The reset callback might still be called in extreme situations
	* such as if the context is lost beyond recovery.
	*
	* For optimal stability, set this to false, and allow context to be
	* reset at any time.
	*/
	
	/* A callback to be called before the context is destroyed in a
	* controlled way by the frontend. */
	context_destroy: hw_context_reset_t,

	/* OpenGL resources can be deinitialized cleanly at this step.
	* context_destroy can be set to NULL, in which resources will
	* just be destroyed without any notification.
	*
	* Even when context_destroy is non-NULL, it is possible that
	* context_reset is called without any destroy notification.
	* This happens if context is lost by external factors (such as
	* notified by GL_ARB_robustness).
	*
	* In this case, the context is assumed to be already dead,
	* and the libretro implementation must not try to free any OpenGL
	* resources in the subsequent context_reset.
	*/
	
	/* Creates a debug context. */
	debug_context: bool,
}

/* Callback type passed in ENVIRONMENT_SET_KEYBOARD_CALLBACK.
* Called by the frontend in response to keyboard events.
* down is set if the key is being pressed, or false if it is being released.
* keycode is the RETROK value of the char.
* character is the text character of the pressed key. (UTF-32).
* key_modifiers is a set of RETROKMOD values or'ed together.
*
* The pressed/keycode state can be independent of the character.
* It is also possible that multiple characters are generated from a
* single keypress.
* Keycode events should be treated separately from character events.
* However, when possible, the frontend should try to synchronize these.
* If only a character is posted, keycode should be RETROK_UNKNOWN.
*
* Similarly if only a keycode event is generated with no corresponding
* character, character should be 0.
*/
keyboard_event_t :: proc "c" (down: bool, keycode: u32, character: u32, key_modifiers: u16)

keyboard_callback :: struct {
	callback: keyboard_event_t,
}

/**
* Called by the frontend to open or close the emulated console's virtual disk tray.
*
* The frontend may only set the disk image index
* while the emulated tray is opened.
*
* If the emulated console's disk tray is already in the state given by \c ejected,
* then this function should return \c true without doing anything.
* The core should return \c false if it couldn't change the disk tray's state;
* this may happen if the console itself limits when the disk tray can be open or closed
* (e.g. to wait for the disc to stop spinning).
*
* @param ejected \c true if the virtual disk tray should be "ejected",
* \c false if it should be "closed".
* @return \c true if the virtual disk tray's state has been set to the given state,
* false if there was an error.
* @see retro_get_eject_state_t
*/
set_eject_state_t :: proc "c" (ejected: bool) -> bool

/**
* Gets the current ejected state of the disk drive.
* The initial state is closed, i.e. \c false.
*
* @return \c true if the virtual disk tray is "ejected",
* i.e. it's open and a disk can be inserted.
* @see retro_set_eject_state_t
*/
get_eject_state_t :: proc "c" () -> bool

/**
* Gets the index of the current disk image,
* as determined by however the frontend orders disk images
* (such as m3u-formatted playlists or special directories).
*
* @return The index of the current disk image
* (starting with 0 for the first disk),
* or a value greater than or equal to \c get_num_images() if no disk is inserted.
* @see retro_get_num_images_t
*/
get_image_index_t :: proc "c" () -> u32

/**
* Inserts the disk image at the given index into the emulated console's drive.
* Can only be called while the disk tray is ejected
* (i.e. \c retro_get_eject_state_t returns \c true).
*
* If the emulated disk tray is ejected
* and already contains the disk image named by \c index,
* then this function should do nothing and return \c true.
*
* @param index The index of the disk image to insert,
* starting from 0 for the first disk.
* A value greater than or equal to \c get_num_images()
* represents the frontend removing the disk without inserting a new one.
* @return \c true if the disk image was successfully set.
* \c false if the disk tray isn't ejected or there was another error
* inserting a new disk image.
*/
set_image_index_t :: proc "c" (index: u32) -> bool

/**
* @return The number of disk images which are available to use.
* These are most likely defined in a playlist file.
*/
get_num_images_t :: proc "c" () -> u32

/**
* Replaces the disk image at the given index with a new disk.
*
* Replaces the disk image associated with index.
* Arguments to pass in info have same requirements as retro_load_game().
* Virtual disk tray must be ejected when calling this.
*
* Passing \c NULL to this function indicates
* that the frontend has removed this disk image from its internal list.
* As a result, calls to this function can change the number of available disk indexes.
*
* For example, calling <tt>replace_image_index(1, NULL)</tt>
* will remove the disk image at index 1,
* and the disk image at index 2 (if any)
* will be moved to the newly-available index 1.
*
* @param index The index of the disk image to replace.
* @param info Details about the new disk image,
* or \c NULL if the disk image at the given index should be discarded.
* The semantics of each field are the same as in \c retro_load_game.
* @return \c true if the disk image was successfully replaced
* or removed from the playlist,
* \c false if the tray is not ejected
* or if there was an error.
*/
replace_image_index_t :: proc "c" (index: u32, info: ^game_info) -> bool

/**
* Adds a new index to the core's internal disk list.
* This will increment the return value from \c get_num_images() by 1.
* This image index cannot be used until a disk image has been set
* with \c replace_image_index.
*
* @return \c true if the core has added space for a new disk image
* and is ready to receive one.
*/
add_image_index_t :: proc "c" () -> bool

/**
* Sets the disk image that will be inserted into the emulated disk drive
* before \c retro_load_game is called.
*
* \c retro_load_game does not provide a way to ensure
* that a particular disk image in a playlist is inserted into the console;
* this function makes up for that.
* Frontends should call it immediately before \c retro_load_game,
* and the core should use the arguments
* to validate the disk image in \c retro_load_game.
*
* When content is loaded, the core should verify that the
* disk specified by \c index can be found at \c path.
* This is to guard against auto-selecting the wrong image
* if (for example) the user should modify an existing M3U playlist.
* We have to let the core handle this because
* \c set_initial_image() must be called before loading content,
* i.e. the frontend cannot access image paths in advance
* and thus cannot perform the error check itself.
* If \c index is invalid (i.e. <tt>index >= get_num_images()</tt>)
* or the disk image doesn't match the value given in \c path,
* the core should ignore the arguments
* and insert the disk at index 0 into the virtual disk tray.
*
* @warning If \c ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE is called within \c retro_load_game,
* then this function may not be executed.
* Set the disk control interface in \c retro_init if possible.
*
* @param index The index of the disk image within the playlist to set.
* @param path The path of the disk image to set as the first.
* The core should not load this path immediately;
* instead, it should use it within \c retro_load_game
* to verify that the correct disk image was loaded.
* @return \c true if the initial disk index was set,
* \c false if the arguments are invalid
* or the core doesn't support this function.
*/
set_initial_image_t :: proc "c" (index: u32, path: cstring) -> bool

/**
* Returns the path of the disk image at the given index
* on the host's file system.
*
* @param index The index of the disk image to get the path of.
* @param s A buffer to store the path in.
* @param len The size of \c s, in bytes.
* @return \c true if the disk image's location was successfully
* queried and copied into \c s,
* \c false if the index is invalid
* or the core couldn't locate the disk image.
*/
get_image_path_t :: proc "c" (index: u32, s: cstring, len: c.size_t) -> bool

/**
* Returns a friendly label for the given disk image.
*
* In the simplest case, this may be the disk image's file name
* with the extension omitted.
* For cores or games with more complex content requirements,
* the label can be used to provide information to help the player
* select a disk image to insert;
* for example, a core may label different kinds of disks
* (save data, level disk, installation disk, bonus content, etc.).
* with names that correspond to in-game prompts,
* so that the frontend can provide better guidance to the player.
*
* @param index The index of the disk image to return a label for.
* @param s A buffer to store the resulting label in.
* @param len The length of \c s, in bytes.
* @return \c true if the disk image at \c index is valid
* and a label was copied into \c s.
*/
get_image_label_t :: proc "c" (index: u32, s: cstring, len: c.size_t) -> bool

/**
* An interface that the frontend can use to exchange disks
* within the emulated console's disk drive.
*
* All function pointers are required.
*
* @deprecated This struct is superseded by \ref retro_disk_control_ext_callback.
* Only use this one to maintain compatibility
* with older cores and frontends.
*
* @see ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE
* @see retro_disk_control_ext_callback
*/
disk_control_callback :: struct {
	/** @copydoc retro_set_eject_state_t */
	set_eject_state: set_eject_state_t,

	/** @copydoc retro_get_eject_state_t */
	get_eject_state: get_eject_state_t,

	/** @copydoc retro_get_image_index_t */
	get_image_index: get_image_index_t,

	/** @copydoc retro_set_image_index_t */
	set_image_index: set_image_index_t,

	/** @copydoc retro_get_num_images_t */
	get_num_images: get_num_images_t,

	/** @copydoc retro_replace_image_index_t */
	replace_image_index: replace_image_index_t,

	/** @copydoc retro_add_image_index_t */
	add_image_index: add_image_index_t,
}

/**
* @copybrief retro_disk_control_callback
*
* All function pointers are required unless otherwise noted.
*
* @see ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE
*/
disk_control_ext_callback :: struct {
	/** @copydoc retro_set_eject_state_t */
	set_eject_state: set_eject_state_t,

	/** @copydoc retro_get_eject_state_t */
	get_eject_state: get_eject_state_t,

	/** @copydoc retro_get_image_index_t */
	get_image_index: get_image_index_t,

	/** @copydoc retro_set_image_index_t */
	set_image_index: set_image_index_t,

	/** @copydoc retro_get_num_images_t */
	get_num_images: get_num_images_t,

	/** @copydoc retro_replace_image_index_t */
	replace_image_index: replace_image_index_t,

	/** @copydoc retro_add_image_index_t */
	add_image_index: add_image_index_t,

	/** @copydoc retro_set_initial_image_t
	*
	* Optional; not called if \c NULL.
	*
	* @note The frontend will only try to record/restore the last-used disk index
	* if both \c set_initial_image and \c get_image_path are implemented.
	*/
	set_initial_image: set_initial_image_t,

	/**
	* @copydoc retro_get_image_path_t
	*
	* Optional; not called if \c NULL.
	*/
	get_image_path: get_image_path_t,

	/**
	* @copydoc retro_get_image_label_t
	*
	* Optional; not called if \c NULL.
	*/
	get_image_label: get_image_label_t,
}

/** @} */

/* Definitions for ENVIRONMENT_SET_NETPACKET_INTERFACE.
* A core can set it if sending and receiving custom network packets
* during a multiplayer session is desired.
*/

/* Netpacket flags for retro_netpacket_send_t */
NETPACKET_UNRELIABLE  :: 0        /* Packet to be sent unreliable, depending on network quality it might not arrive. */
NETPACKET_RELIABLE    :: (1<<0) /* Reliable packets are guaranteed to arrive at the target in the order they were sent. */
NETPACKET_UNSEQUENCED :: (1<<1) /* Packet will not be sequenced with other packets and may arrive out of order. Cannot be set on reliable packets. */
NETPACKET_FLUSH_HINT  :: (1<<2) /* Request the packet and any previously buffered ones to be sent immediately */

/* Broadcast client_id for retro_netpacket_send_t */
NETPACKET_BROADCAST :: 0xFFFF

/* Used by the core to send a packet to one or all connected players.
* A single packet sent via this interface can contain up to 64 KB of data.
*
* The client_id NETPACKET_BROADCAST sends the packet as a broadcast to
* all connected players. This is supported from the host as well as clients.
*  Otherwise, the argument indicates the player to send the packet to.
*
* A frontend must support sending reliable packets (NETPACKET_RELIABLE).
* Unreliable packets might not be supported by the frontend, but the flags can
* still be specified. Reliable transmission will be used instead.
*
* Calling this with the flag NETPACKET_FLUSH_HINT will send off the
* packet and any previously buffered ones immediately and without blocking.
* To only flush previously queued packets, buf or len can be passed as NULL/0.
*
* This function is not guaranteed to be thread-safe and must be called during
* retro_run or any of the netpacket callbacks passed with this interface.
*/
netpacket_send_t :: proc "c" (flags: i32, buf: rawptr, len: c.size_t, client_id: u16)

/* Optionally read any incoming packets without waiting for the end of the
* frame. While polling, retro_netpacket_receive_t and retro_netpacket_stop_t
* can be called. The core can perform this in a loop to do a blocking read,
* i.e., wait for incoming data, but needs to handle stop getting called and
* also give up after a short while to avoid freezing on a connection problem.
* It is a good idea to manually flush outgoing packets before calling this.
*
* This function is not guaranteed to be thread-safe and must be called during
* retro_run or any of the netpacket callbacks passed with this interface.
*/
netpacket_poll_receive_t :: proc "c" ()

/* Called by the frontend to signify that a multiplayer session has started.
* If client_id is 0 the local player is the host of the session and at this
* point no other player has connected yet.
*
* If client_id is > 0 the local player is a client connected to a host and
* at this point is already fully connected to the host.
*
* The core must store the function pointer send_fn and use it whenever it
* wants to send a packet. Optionally poll_receive_fn can be stored and used
* when regular receiving between frames is not enough. These function pointers
* remain valid until the frontend calls retro_netpacket_stop_t.
*/
netpacket_start_t :: proc "c" (client_id: u16, send_fn: netpacket_send_t, poll_receive_fn: netpacket_poll_receive_t)

/* Called by the frontend when a new packet arrives which has been sent from
* another player with retro_netpacket_send_t. The client_id argument indicates
* who has sent the packet.
*/
netpacket_receive_t :: proc "c" (buf: rawptr, len: c.size_t, client_id: u16)

/* Called by the frontend when the multiplayer session has ended.
* Once this gets called the function pointers passed to
* retro_netpacket_start_t will not be valid anymore.
*/
netpacket_stop_t :: proc "c" ()

/* Called by the frontend every frame (between calls to retro_run while
* updating the state of the multiplayer session.
* This is a good place for the core to call retro_netpacket_send_t from.
*/
netpacket_poll_t :: proc "c" ()

/* Called by the frontend when a new player connects to the hosted session.
* This is only called on the host side, not for clients connected to the host.
* If this function returns false, the newly connected player gets dropped.
* This can be used for example to limit the number of players.
*/
netpacket_connected_t :: proc "c" (client_id: u16) -> bool

/* Called by the frontend when a player leaves or disconnects from the hosted session.
* This is only called on the host side, not for clients connected to the host.
*/
netpacket_disconnected_t :: proc "c" (client_id: u16)

/**
* A callback interface for giving a core the ability to send and receive custom
* network packets during a multiplayer session between two or more instances
* of a libretro frontend.
*
* Normally during connection handshake the frontend will compare library_version
* used by both parties and show a warning if there is a difference. When the core
* supplies protocol_version, the frontend will check against this instead.
*
* @see ENVIRONMENT_SET_NETPACKET_INTERFACE
*/
netpacket_callback :: struct {
	start:            netpacket_start_t,
	receive:          netpacket_receive_t,
	stop:             netpacket_stop_t,         /* Optional - may be NULL */
	poll:             netpacket_poll_t,         /* Optional - may be NULL */
	connected:        netpacket_connected_t,    /* Optional - may be NULL */
	disconnected:     netpacket_disconnected_t, /* Optional - may be NULL */
	protocol_version: cstring,                  /* Optional - if not NULL will be used instead of core version to decide if communication is compatible */
}

/**
* The pixel format used for rendering.
* @see ENVIRONMENT_SET_PIXEL_FORMAT
*/
pixel_format :: enum u32 {
	/**
	* 0RGB1555, native endian.
	* Used as the default if \c ENVIRONMENT_SET_PIXEL_FORMAT is not called.
	* The most significant bit must be set to 0.
	* @deprecated This format remains supported to maintain compatibility.
	* New code should use <tt>PIXEL_FORMAT_RGB565</tt> instead.
	* @see PIXEL_FORMAT_RGB565
	*/
	_0RGB1555 = 0,

	/**
	* XRGB8888, native endian.
	* The most significant byte (the <tt>X</tt>) is ignored.
	*/
	XRGB8888  = 1,

	/**
	* RGB565, native endian.
	* This format is recommended if 16-bit pixels are desired,
	* as it is available on a variety of devices and APIs.
	*/
	RGB565    = 2,

	/** Defined to ensure that <tt>sizeof(retro_pixel_format) == sizeof(int)</tt>. Do not use. */
	UNKNOWN   = 2147483647,
}

/**
* Details about how the frontend will use savestates.
*
* @see ENVIRONMENT_GET_SAVESTATE_CONTEXT
* @see retro_serialize
*/
savestate_context :: enum u32 {
	/**
	* Standard savestate written to disk.
	* May be loaded at any time,
	* even in a separate session or on another device.
	*
	* Should not contain any pointers to code or data.
	*/
	NORMAL                 = 0,

	/**
	* The savestate is guaranteed to be loaded
	* within the same session, address space, and binary.
	* Will not be written to disk or sent over the network;
	* therefore, internal pointers to code or data are acceptable.
	* May still be loaded or saved at any time.
	*
	* @note This context generally implies the use of runahead or rewinding,
	* which may work by taking savestates multiple times per second.
	* Savestate code that runs in this context should be fast.
	*/
	RUNAHEAD_SAME_INSTANCE = 1,

	/**
	* The savestate is guaranteed to be loaded
	* in the same session and by the same binary,
	* but possibly by a different address space
	* (e.g. for "second instance" runahead)
	*
	* Will not be written to disk or sent over the network,
	* but may be loaded in a different address space.
	* Therefore, the savestate <em>must not</em> contain pointers.
	*/
	RUNAHEAD_SAME_BINARY   = 2,

	/**
	* The savestate will not be written to disk,
	* but no other guarantees are made.
	* The savestate will almost certainly be loaded
	* by a separate binary, device, and address space.
	*
	* This context is intended for use with frontends that support rollback netplay.
	* Serialized state should omit any data that would unnecessarily increase bandwidth usage.
	* Must not contain pointers, and integers must be saved in big-endian format.
	* @see retro_endianness.h
	* @see network_stream
	*/
	ROLLBACK_NETPLAY       = 3,

	/**
	* @private Defined to ensure <tt>sizeof(retro_savestate_context) == sizeof(int)</tt>.
	* Do not use.
	*/
	UNKNOWN                = 2147483647,
}

/**
* Defines a message that the frontend will display to the user,
* as determined by <tt>ENVIRONMENT_SET_MESSAGE</tt>.
*
* @deprecated This struct is superseded by \ref retro_message_ext,
* which provides more control over how a message is presented.
* Only use it for compatibility with older cores and frontends.
*
* @see ENVIRONMENT_SET_MESSAGE
* @see retro_message_ext
*/
message :: struct {
	/**
	* Null-terminated message to be displayed.
	* If \c NULL or empty, the message will be ignored.
	*/
	msg: cstring,

	/** Duration to display \c msg in frames. */
	frames: u32,
}

/**
* The method that the frontend will use to display a message to the player.
* @see retro_message_ext
*/
message_target :: enum u32 {
	/**
	* Indicates that the frontend should display the given message
	* using all other targets defined by \c retro_message_target at once.
	*/
	ALL = 0,

	/**
	* Indicates that the frontend should display the given message
	* using the frontend's on-screen display, if available.
	*
	* @attention If the frontend allows players to customize or disable notifications,
	* then they may not see messages sent to this target.
	*/
	OSD = 1,

	/**
	* Indicates that the frontend should log the message
	* via its usual logging mechanism, if available.
	*
	* This is not intended to be a substitute for \c ENVIRONMENT_SET_LOG_INTERFACE.
	* It is intended for the common use case of
	* logging a player-facing message.
	*
	* This target should not be used for messages
	* of type \c MESSAGE_TYPE_STATUS or \c MESSAGE_TYPE_PROGRESS,
	* as it may add unnecessary noise to a log file.
	*
	* @see ENVIRONMENT_SET_LOG_INTERFACE
	*/
	LOG = 2,
}

/**
* A broad category for the type of message that the frontend will display.
*
* Each message type has its own use case,
* therefore the frontend should present each one differently.
*
* @note This is a hint that the frontend may ignore.
* The frontend should fall back to \c MESSAGE_TYPE_NOTIFICATION
* for message types that it doesn't support.
*/
message_type :: enum u32 {
	/**
	* A standard on-screen message.
	*
	* Suitable for a variety of use cases,
	* such as messages about errors
	* or other important events.
	*
	* Frontends that display their own messages
	* should display this type of core-generated message the same way.
	*/
	NOTIFICATION     = 0,

	/**
	* An on-screen message that should be visually distinct
	* from \c MESSAGE_TYPE_NOTIFICATION messages.
	*
	* The exact meaning of "visually distinct" is left to the frontend,
	* but this usually implies that the frontend shows the message
	* in a way that it doesn't typically use for its own notices.
	*/
	NOTIFICATION_ALT = 1,

	/**
	* Indicates a frequently-updated status display,
	* rather than a standard notification.
	* Status messages are intended to be displayed permanently while a core is running
	* in a way that doesn't suggest user action is required.
	*
	* Here are some possible use cases for status messages:
	*
	* @li An internal framerate counter.
	* @li Debugging information.
	*     Remember to let the player disable it in the core options.
	* @li Core-specific state, such as when a microphone is active.
	*
	* The status message is displayed for the given duration,
	* unless another status message of equal or greater priority is shown.
	*/
	STATUS           = 2,

	/**
	* Denotes a message that reports the progress
	* of a long-running asynchronous task,
	* such as when a core loads large files from disk or the network.
	*
	* The frontend should display messages of this type as a progress bar
	* (or a progress spinner for indefinite tasks),
	* where \c retro_message_ext::msg is the progress bar's title
	* and \c retro_message_ext::progress sets the progress bar's length.
	*
	* This message type shouldn't be used for tasks that are expected to complete quickly.
	*/
	PROGRESS         = 3,
}

/**
* A core-provided message that the frontend will display to the player.
*
* @note The frontend is encouraged store these messages in a queue.
* However, it should not empty the queue of core-submitted messages upon exit;
* if a core exits with an error, it may want to use this API
* to show an error message to the player.
*
* The frontend should maintain its own copy of the submitted message
* and all subobjects, including strings.
*
* @see ENVIRONMENT_SET_MESSAGE_EXT
*/
message_ext :: struct {
	/**
	* The \c NULL-terminated text of a message to show to the player.
	* Must not be \c NULL.
	*
	* @note The frontend must honor newlines in this string
	* when rendering text to \c MESSAGE_TARGET_OSD.
	*/
	msg: cstring,

	/**
	* The duration that \c msg will be displayed on-screen, in milliseconds.
	*
	* Ignored for \c MESSAGE_TARGET_LOG.
	*/
	duration: u32,

	/**
	* The relative importance of this message
	* when targeting \c MESSAGE_TARGET_OSD.
	* Higher values indicate higher priority.
	*
	* The frontend should use this to prioritize messages
	* when it can't show all active messages at once,
	* or to remove messages from its queue if it's full.
	*
	* The relative display order of messages with the same priority
	* is left to the frontend's discretion,
	* although we suggest breaking ties
	* in favor of the most recently-submitted message.
	*
	* Frontends may handle deprioritized messages at their discretion;
	* such messages may have their \c duration altered,
	* be hidden without being delayed,
	* or even be discarded entirely.
	*
	* @note In the reference frontend (RetroArch),
	* the same priority values are used for frontend-generated notifications,
	* which are typically between 0 and 3 depending upon importance.
	*
	* Ignored for \c MESSAGE_TARGET_LOG.
	*/
	priority: u32,

	/**
	* The severity level of this message.
	*
	* The frontend may use this to filter or customize messages
	* depending on the player's preferences.
	* Here are some ideas:
	*
	* @li Use this to prioritize errors and warnings
	*     over higher-ranking info and debug messages.
	* @li Render warnings or errors with extra visual feedback,
	*     e.g. with brighter colors or accompanying sound effects.
	*
	* @see ENVIRONMENT_SET_LOG_INTERFACE
	*/
	level: log_level,

	/**
	* The intended destination of this message.
	*
	* @see retro_message_target
	*/
	target: message_target,

	/**
	* The intended semantics of this message.
	*
	* Ignored for \c MESSAGE_TARGET_LOG.
	*
	* @see retro_message_type
	*/
	type: message_type,

	/**
	* The progress of an asynchronous task.
	*
	* A value between 0 and 100 (inclusive) indicates the task's percentage,
	* and a value of -1 indicates a task of unknown completion.
	*
	* @note Since message type is a hint, a frontend may ignore progress values.
	* Where relevant, a core should include progress percentage within the message string,
	* such that the message intent remains clear when displayed
	* as a standard frontend-generated notification.
	*
	* Ignored for \c MESSAGE_TARGET_LOG and for
	* message types other than \c MESSAGE_TYPE_PROGRESS.
	*/
	progress: i8,
}

/* Describes how the libretro implementation maps a libretro input bind
* to its internal input system through a human readable string.
* This string can be used to better let a user configure input. */
input_descriptor :: struct {
	/* Associates given parameters with a description. */
	port:   u32,
	device: u32,
	index:  u32,
	id:     u32,

	/* Human readable description for parameters.
	* The pointer must remain valid until
	* retro_unload_game() is called. */
	description: cstring,
}

/**
* Contains basic information about the core.
*
* @see retro_get_system_info
* @warning All pointers are owned by the core
* and must remain valid throughout its lifetime.
*/
system_info :: struct {
	/**
	* Descriptive name of the library.
	*
	* @note Should not contain any version numbers, etc.
	*/
	library_name: cstring,

	/**
	* Descriptive version of the core.
	*/
	library_version: cstring,

	/**
	* A pipe-delimited string list of file extensions that this core can load, e.g. "bin|rom|iso".
	* Typically used by a frontend for filtering or core selection.
	*/
	valid_extensions: cstring,

	/* Libretro cores that need to have direct access to their content
	* files, including cores which use the path of the content files to
	* determine the paths of other files, should set need_fullpath to true.
	*
	* Cores should strive for setting need_fullpath to false,
	* as it allows the frontend to perform patching, etc.
	*
	* If need_fullpath is true and retro_load_game() is called:
	*    - retro_game_info::path is guaranteed to have a valid path
	*    - retro_game_info::data and retro_game_info::size are invalid
	*
	* If need_fullpath is false and retro_load_game() is called:
	*    - retro_game_info::path may be NULL
	*    - retro_game_info::data and retro_game_info::size are guaranteed
	*      to be valid
	*
	* See also:
	*    - ENVIRONMENT_GET_SYSTEM_DIRECTORY
	*    - ENVIRONMENT_GET_SAVE_DIRECTORY
	*/
	need_fullpath: bool,

	/* If true, the frontend is not allowed to extract any archives before
	* loading the real content.
	* Necessary for certain libretro implementations that load games
	* from zipped archives. */
	block_extract: bool,
}

/* Defines overrides which modify frontend handling of
* specific content file types.
* An array of retro_system_content_info_override is
* passed to ENVIRONMENT_SET_CONTENT_INFO_OVERRIDE
* NOTE: In the following descriptions, references to
*       retro_load_game() may be replaced with
*       retro_load_game_special() */
system_content_info_override :: struct {
	/* A list of file extensions for which the override
	* should apply, delimited by a 'pipe' character
	* (e.g. "md|sms|gg")
	* Permitted file extensions are limited to those
	* included in retro_system_info::valid_extensions
	* and/or retro_subsystem_rom_info::valid_extensions */
	extensions: cstring,

	/* Overrides the need_fullpath value set in
	* retro_system_info and/or retro_subsystem_rom_info.
	* To reiterate:
	*
	* If need_fullpath is true and retro_load_game() is called:
	*    - retro_game_info::path is guaranteed to contain a valid
	*      path to an existent file
	*    - retro_game_info::data and retro_game_info::size are invalid
	*
	* If need_fullpath is false and retro_load_game() is called:
	*    - retro_game_info::path may be NULL
	*    - retro_game_info::data and retro_game_info::size are guaranteed
	*      to be valid
	*
	* In addition:
	*
	* If need_fullpath is true and retro_load_game() is called:
	*    - retro_game_info_ext::full_path is guaranteed to contain a valid
	*      path to an existent file
	*    - retro_game_info_ext::archive_path may be NULL
	*    - retro_game_info_ext::archive_file may be NULL
	*    - retro_game_info_ext::dir is guaranteed to contain a valid path
	*      to the directory in which the content file exists
	*    - retro_game_info_ext::name is guaranteed to contain the
	*      basename of the content file, without extension
	*    - retro_game_info_ext::ext is guaranteed to contain the
	*      extension of the content file in lower case format
	*    - retro_game_info_ext::data and retro_game_info_ext::size
	*      are invalid
	*
	* If need_fullpath is false and retro_load_game() is called:
	*    - If retro_game_info_ext::file_in_archive is false:
	*       - retro_game_info_ext::full_path is guaranteed to contain
	*         a valid path to an existent file
	*       - retro_game_info_ext::archive_path may be NULL
	*       - retro_game_info_ext::archive_file may be NULL
	*       - retro_game_info_ext::dir is guaranteed to contain a
	*         valid path to the directory in which the content file exists
	*       - retro_game_info_ext::name is guaranteed to contain the
	*         basename of the content file, without extension
	*       - retro_game_info_ext::ext is guaranteed to contain the
	*         extension of the content file in lower case format
	*    - If retro_game_info_ext::file_in_archive is true:
	*       - retro_game_info_ext::full_path may be NULL
	*       - retro_game_info_ext::archive_path is guaranteed to
	*         contain a valid path to an existent compressed file
	*         inside which the content file is located
	*       - retro_game_info_ext::archive_file is guaranteed to
	*         contain a valid path to an existent content file
	*         inside the compressed file referred to by
	*         retro_game_info_ext::archive_path
	*            e.g. for a compressed file '/path/to/foo.zip'
	*            containing 'bar.sfc'
	*             > retro_game_info_ext::archive_path will be '/path/to/foo.zip'
	*             > retro_game_info_ext::archive_file will be 'bar.sfc'
	*       - retro_game_info_ext::dir is guaranteed to contain a
	*         valid path to the directory in which the compressed file
	*         (containing the content file) exists
	*       - retro_game_info_ext::name is guaranteed to contain
	*         EITHER
	*         1) the basename of the compressed file (containing
	*            the content file), without extension
	*         OR
	*         2) the basename of the content file inside the
	*            compressed file, without extension
	*         In either case, a core should consider 'name' to
	*         be the canonical name/ID of the the content file
	*       - retro_game_info_ext::ext is guaranteed to contain the
	*         extension of the content file inside the compressed file,
	*         in lower case format
	*    - retro_game_info_ext::data and retro_game_info_ext::size are
	*      guaranteed to be valid */
	need_fullpath: bool,

	/* If need_fullpath is false, specifies whether the content
	* data buffer available in retro_load_game() is 'persistent'
	*
	* If persistent_data is false and retro_load_game() is called:
	*    - retro_game_info::data and retro_game_info::size
	*      are valid only until retro_load_game() returns
	*    - retro_game_info_ext::data and retro_game_info_ext::size
	*      are valid only until retro_load_game() returns
	*
	* If persistent_data is true and retro_load_game() is called:
	*    - retro_game_info::data and retro_game_info::size
	*      are valid until retro_deinit() returns
	*    - retro_game_info_ext::data and retro_game_info_ext::size
	*      are valid until retro_deinit() returns */
	persistent_data: bool,
}

/* Similar to retro_game_info, but provides extended
* information about the source content file and
* game memory buffer status.
* And array of retro_game_info_ext is returned by
* ENVIRONMENT_GET_GAME_INFO_EXT
* NOTE: In the following descriptions, references to
*       retro_load_game() may be replaced with
*       retro_load_game_special() */
game_info_ext :: struct {
	/* - If file_in_archive is false, contains a valid
	*   path to an existent content file (UTF-8 encoded)
	* - If file_in_archive is true, may be NULL */
	full_path: cstring,

	/* - If file_in_archive is false, may be NULL
	* - If file_in_archive is true, contains a valid path
	*   to an existent compressed file inside which the
	*   content file is located (UTF-8 encoded) */
	archive_path: cstring,

	/* - If file_in_archive is false, may be NULL
	* - If file_in_archive is true, contain a valid path
	*   to an existent content file inside the compressed
	*   file referred to by archive_path (UTF-8 encoded)
	*      e.g. for a compressed file '/path/to/foo.zip'
	*      containing 'bar.sfc'
	*      > archive_path will be '/path/to/foo.zip'
	*      > archive_file will be 'bar.sfc' */
	archive_file: cstring,

	/* - If file_in_archive is false, contains a valid path
	*   to the directory in which the content file exists
	*   (UTF-8 encoded)
	* - If file_in_archive is true, contains a valid path
	*   to the directory in which the compressed file
	*   (containing the content file) exists (UTF-8 encoded) */
	dir: cstring,

	/* Contains the canonical name/ID of the content file
	* (UTF-8 encoded). Intended for use when identifying
	* 'complementary' content named after the loaded file -
	* i.e. companion data of a different format (a CD image
	* required by a ROM), texture packs, internally handled
	* save files, etc.
	* - If file_in_archive is false, contains the basename
	*   of the content file, without extension
	* - If file_in_archive is true, then string is
	*   implementation specific. A frontend may choose to
	*   set a name value of:
	*   EITHER
	*   1) the basename of the compressed file (containing
	*      the content file), without extension
	*   OR
	*   2) the basename of the content file inside the
	*      compressed file, without extension
	*   RetroArch sets the 'name' value according to (1).
	*   A frontend that supports routine loading of
	*   content from archives containing multiple unrelated
	*   content files may set the 'name' value according
	*   to (2). */
	name: cstring,

	/* - If file_in_archive is false, contains the extension
	*   of the content file in lower case format
	* - If file_in_archive is true, contains the extension
	*   of the content file inside the compressed file,
	*   in lower case format */
	ext: cstring,

	/* String of implementation specific meta-data. */
	meta: cstring,

	/* Memory buffer of loaded game content. Will be NULL:
	* IF
	* - retro_system_info::need_fullpath is true and
	*   retro_system_content_info_override::need_fullpath
	*   is unset
	* OR
	* - retro_system_content_info_override::need_fullpath
	*   is true */
	data: rawptr,

	/* Size of game content memory buffer, in bytes */
	size: c.size_t,

	/* True if loaded content file is inside a compressed
	* archive */
	file_in_archive: bool,

	/* - If data is NULL, value is unset/ignored
	* - If data is non-NULL:
	*   - If persistent_data is false, data and size are
	*     valid only until retro_load_game() returns
	*   - If persistent_data is true, data and size are
	*     are valid until retro_deinit() returns */
	persistent_data: bool,
}

/**
* Parameters describing the size and shape of the video frame.
* @see retro_system_av_info
* @see ENVIRONMENT_SET_SYSTEM_AV_INFO
* @see ENVIRONMENT_SET_GEOMETRY
* @see retro_get_system_av_info
*/
game_geometry :: struct {
	/**
	* Nominal video width of game, in pixels.
	* This will typically be the emulated platform's native video width
	* (or its smallest, if the original hardware supports multiple resolutions).
	*/
	base_width: u32,

	/**
	* Nominal video height of game, in pixels.
	* This will typically be the emulated platform's native video height
	* (or its smallest, if the original hardware supports multiple resolutions).
	*/
	base_height: u32,

	/**
	* Maximum possible width of the game screen, in pixels.
	* This will typically be the emulated platform's maximum video width.
	* For cores that emulate platforms with multiple screens (such as the Nintendo DS),
	* this should assume the core's widest possible screen layout (e.g. side-by-side).
	* For cores that support upscaling the resolution,
	* this should assume the highest supported scale factor is active.
	*/
	max_width: u32,

	/**
	* Maximum possible height of the game screen, in pixels.
	* This will typically be the emulated platform's maximum video height.
	* For cores that emulate platforms with multiple screens (such as the Nintendo DS),
	* this should assume the core's tallest possible screen layout (e.g. vertical).
	* For cores that support upscaling the resolution,
	* this should assume the highest supported scale factor is active.
	*/
	max_height: u32, /* Maximum possible height of game. */

	/**
	* Nominal aspect ratio of game.
	* If zero or less,
	* an aspect ratio of <tt>base_width / base_height</tt> is assumed.
	*
	* @note A frontend may ignore this setting.
	*/
	aspect_ratio: f32,
}

/**
* Parameters describing the timing of the video and audio.
* @see retro_system_av_info
* @see ENVIRONMENT_SET_SYSTEM_AV_INFO
* @see retro_get_system_av_info
*/
system_timing :: struct {
	/** Video output refresh rate, in frames per second. */
	fps: f64,

	/** The audio output sample rate, in Hz. */
	sample_rate: f64,
}

/**
* Configures how the core's audio and video should be updated.
* @see ENVIRONMENT_SET_SYSTEM_AV_INFO
* @see retro_get_system_av_info
*/
system_av_info :: struct {
	/** Parameters describing the size and shape of the video frame. */
	geometry: game_geometry,

	/** Parameters describing the timing of the video and audio. */
	timing: system_timing,
}

/**
* Represents \ref ENVIRONMENT_GET_VARIABLE "a core option query".
*
* @note In \ref ENVIRONMENT_SET_VARIABLES
* (which is a deprecated API),
* this \c struct serves as an option definition.
*
* @see ENVIRONMENT_GET_VARIABLE
*/
variable :: struct {
	/**
	* A unique key identifying this option.
	*
	* Should be a key for an option that was previously defined
	* with \ref ENVIRONMENT_SET_CORE_OPTIONS_V2 or similar.
	*
	* Should be prefixed with the core's name
	* to minimize the risk of collisions with another core's options,
	* as frontends are not required to use a namespacing scheme for storing options.
	* For example, a core named "foo" might define an option named "foo_option".
	*
	* @note In \ref ENVIRONMENT_SET_VARIABLES
	* (which is a deprecated API),
	* this field is used to define an option
	* named by this key.
	*/
	key: cstring,

	/**
	* Value to be obtained.
	*
	* Set by the frontend to \c NULL if
	* the option named by \ref key does not exist.
	*
	* @note In \ref ENVIRONMENT_SET_VARIABLES
	* (which is a deprecated API),
	* this field is set by the core to define the possible values
	* for an option named by \ref key.
	* When used this way, it must be formatted as follows:
	* @li The text before the first ';' is the option's human-readable title.
	* @li A single space follows the ';'.
	* @li The rest of the string is a '|'-delimited list of possible values,
	* with the first one being the default.
	*/
	value: cstring,
}

/**
* An argument that's used to show or hide a core option in the frontend.
*
* @see ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY
*/
core_option_display :: struct {
	/**
	* The key for a core option that was defined with \ref ENVIRONMENT_SET_CORE_OPTIONS_V2,
	* \ref ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL,
	* or their legacy equivalents.
	*/
	key: cstring,

	/**
	* Whether the option named by \c key
	* should be displayed to the player in the frontend's core options menu.
	*
	* @note This value is a hint, \em not a requirement;
	* the frontend is free to ignore this field.
	*/
	visible: bool,
}

/**
* The maximum number of choices that can be defined for a given core option.
*
* This limit was chosen as a compromise between
* a core's flexibility and a streamlined user experience.
*
* @note A guiding principle of libretro's API design is that
* all common interactions (gameplay, menu navigation, etc.)
* should be possible without a keyboard.
*
* If you need more than 128 choices for a core option,
* consider simplifying your option structure.
* Here are some ideas:
*
* \li If a core option represents a numeric value,
*     consider reducing the option's granularity
*     (e.g. define time limits in increments of 5 seconds instead of 1 second).
*     Providing a fixed set of values based on experimentation
*     is also a good idea.
* \li If a core option represents a dynamically-built list of files,
*     consider leaving out files that won't be useful.
*     For example, if a core allows the player to choose a specific BIOS file,
*     it can omit files of the wrong length or without a valid header.
*
* @see retro_core_option_definition
* @see retro_core_option_v2_definition
*/
NUM_CORE_OPTION_VALUES_MAX :: 128

/**
* A descriptor for a particular choice within a core option.
*
* @note All option values are represented as strings.
* If you need to represent any other type,
* parse the string in \ref value.
*
* @see retro_core_option_v2_category
*/
core_option_value :: struct {
	/**
	* The option value that the frontend will serialize.
	*
	* Must not be \c NULL or empty.
	* No other hard limits are placed on this value's contents,
	* but here are some suggestions:
	*
	* \li If the value represents a number,
	*     don't include any non-digit characters (units, separators, etc.).
	*     Instead, include that information in \c label.
	*     This will simplify parsing.
	* \li If the value represents a file path,
	*     store it as a relative path with respect to one of the common libretro directories
	*     (e.g. \ref ENVIRONMENT_GET_SYSTEM_DIRECTORY "the system directory"
	*     or \ref ENVIRONMENT_GET_SAVE_DIRECTORY "the save directory"),
	*     and use forward slashes (\c "/") as directory separators.
	*     This will simplify cloud storage if supported by the frontend,
	*     as the same file may be used on multiple devices.
	*/
	value: cstring,

	/**
	* Human-readable name for \c value that the frontend should show to players.
	*
	* May be \c NULL, in which case the frontend
	* should display \c value itself.
	*
	* Here are some guidelines for writing a good label:
	*
	* \li Make the option labels obvious
	*     so that they don't need to be explained in the description.
	* \li Keep labels short, and don't use unnecessary words.
	*     For example, "OpenGL" is a better label than "OpenGL Mode".
	* \li If the option represents a number,
	*     consider adding units, separators, or other punctuation
	*     into the label itself.
	*     For example, "5 seconds" is a better label than "5".
	* \li If the option represents a number, use intuitive units
	*     that don't take a lot of digits to express.
	*     For example, prefer "1 minute" over "60 seconds" or "60,000 milliseconds".
	*/
	label: cstring,
}

/**
* @copybrief retro_core_option_v2_definition
*
* @deprecated Use \ref retro_core_option_v2_definition instead,
* as it supports categorizing options into groups.
* Only use this \c struct to support older frontends or cores.
*
* @see ENVIRONMENT_SET_CORE_OPTIONS
* @see ENVIRONMENT_SET_CORE_OPTIONS_INTL
*/
core_option_definition :: struct {
	/** @copydoc retro_core_option_v2_definition::key */
	key: cstring,

	/** @copydoc retro_core_option_v2_definition::desc */
	desc: cstring,

	/** @copydoc retro_core_option_v2_definition::info */
	info: cstring,

	/** @copydoc retro_core_option_v2_definition::values */
	values: [128]core_option_value,

	/** @copydoc retro_core_option_v2_definition::default_value */
	default_value: cstring,
}

/**
* A variant of \ref retro_core_options that supports internationalization.
*
* @deprecated Use \ref retro_core_options_v2_intl instead,
* as it supports categorizing options into groups.
* Only use this \c struct to support older frontends or cores.
*
* @see retro_core_options
* @see ENVIRONMENT_SET_CORE_OPTIONS_INTL
* @see ENVIRONMENT_GET_LANGUAGE
* @see retro_language
*/
core_options_intl :: struct {
	/** @copydoc retro_core_options_v2_intl::us */
	us: ^core_option_definition,

	/** @copydoc retro_core_options_v2_intl::local */
	local: ^core_option_definition,
}

/**
* A descriptor for a group of related core options.
*
* Here's an example category:
*
* @code
* {
*     "cpu",
*     "CPU Emulation",
*     "Settings for CPU quirks."
* }
* @endcode
*
* @see retro_core_options_v2
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL
*/
core_option_v2_category :: struct {
	/**
	* A string that uniquely identifies this category within the core's options.
	* Any \c retro_core_option_v2_definition whose \c category_key matches this
	* is considered to be within this category.
	* Different cores may use the same category keys,
	* so namespacing them is not necessary.
	* Valid characters are <tt>[a-zA-Z0-9_-]</tt>.
	*
	* Frontends should use this category to organize core options,
	* but may customize this category's presentation in other ways.
	* For example, a frontend may use common keys like "audio" or "gfx"
	* to select an appropriate icon in its UI.
	*
	* Required; must not be \c NULL.
	*/
	key: cstring,

	/**
	* A brief human-readable name for this category,
	* intended for the frontend to display to the player.
	* This should be a name that's concise and descriptive, such as "Audio" or "Video".
	*
	* Required; must not be \c NULL.
	*/
	desc: cstring,

	/**
	* A human-readable description for this category,
	* intended for the frontend to display to the player
	* as secondary help text (e.g. a sublabel or a tooltip).
	* Optional; may be \c NULL or an empty string.
	*/
	info: cstring,
}

/**
* A descriptor for a particular core option and the values it may take.
*
* Supports categorizing options into groups,
* so as not to overwhelm the player.
*
* @see retro_core_option_v2_category
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL
*/
core_option_v2_definition :: struct {
	/**
	* A unique identifier for this option that cores may use
	* \ref ENVIRONMENT_GET_VARIABLE "to query its value from the frontend".
	* Must be unique within this core.
	*
	* Should be unique globally;
	* the recommended method for doing so
	* is to prefix each option with the core's name.
	* For example, an option that controls the resolution for a core named "foo"
	* should be named \c "foo_resolution".
	*
	* Valid key characters are in the set <tt>[a-zA-Z0-9_-]</tt>.
	*/
	key: cstring,

	/**
	* A human-readable name for this option,
	* intended to be displayed by frontends that don't support
	* categorizing core options.
	*
	* Required; must not be \c NULL or empty.
	*/
	desc: cstring,

	/**
	* A human-readable name for this option,
	* intended to be displayed by frontends that support
	* categorizing core options.
	*
	* This version may be slightly more concise than \ref desc,
	* as it can rely on the structure of the options menu.
	* For example, "Interface" is a good \c desc_categorized,
	* as it can be displayed as a sublabel for a "Network" category.
	* For \c desc, "Network Interface" would be more suitable.
	*
	* Optional; if this field or \c category_key is empty or \c NULL,
	* \c desc will be used instead.
	*/
	desc_categorized: cstring,

	/**
	* A human-readable description of this option and its effects,
	* intended to be displayed by frontends that don't support
	* categorizing core options.
	*
	* @details Intended to be displayed as secondary help text,
	* such as a tooltip or a sublabel.
	*
	* Here are some suggestions for writing a good description:
	*
	* \li Avoid technical jargon unless this option is meant for advanced users.
	*     If unavoidable, suggest one of the default options for those unsure.
	* \li Don't repeat the option name in the description;
	*     instead, describe what the option name means.
	* \li If an option requires a core restart or game reset to take effect,
	*     be sure to say so.
	* \li Try to make the option labels obvious
	*     so that they don't need to be explained in the description.
	*
	* Optional; may be \c NULL.
	*/
	info: cstring,

	/**
	* @brief A human-readable description of this option and its effects,
	* intended to be displayed by frontends that support
	* categorizing core options.
	*
	* This version is provided to accommodate descriptions
	* that reference other options by name,
	* as options may have different user-facing names
	* depending on whether the frontend supports categorization.
	*
	* @copydetails info
	*
	* If empty or \c NULL, \c info will be used instead.
	* Will be ignored if \c category_key is empty or \c NULL.
	*/
	info_categorized: cstring,

	/**
	* The key of the category that this option belongs to.
	*
	* Optional; if equal to \ref retro_core_option_v2_category::key "a defined category",
	* then this option shall be displayed by the frontend
	* next to other options in this same category,
	* assuming it supports doing so.
	* Option categories are intended to be displayed in a submenu,
	* but this isn't a hard requirement.
	*
	* If \c NULL, empty, or not equal to a defined category,
	* then this option is considered uncategorized
	* and the frontend shall display it outside of any category
	* (most likely at a top-level menu).
	*
	* @see retro_core_option_v2_category
	*/
	category_key: cstring,

	/**
	* One or more possible values for this option,
	* up to the limit of \ref NUM_CORE_OPTION_VALUES_MAX.
	*
	* Terminated by a \c { NULL, NULL } element,
	* although frontends should work even if all elements are used.
	*/
	values: [128]core_option_value,

	/**
	* The default value for this core option.
	* Used if it hasn't been set, e.g. for new cores.
	* Must equal one of the \ref value members in the \c values array,
	* or else this option will be ignored.
	*/
	default_value: cstring,
}

/**
* A set of core option descriptors and the categories that group them,
* suitable for enabling a core to be customized.
*
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2
*/
core_options_v2 :: struct {
	/**
	* An array of \ref retro_core_option_v2_category "option categories",
	* terminated by a zeroed-out category \c struct.
	*
	* Will be ignored if the frontend doesn't support core option categories.
	*
	* If \c NULL or ignored, all options will be treated as uncategorized.
	* This most likely means that a frontend will display them at a top-level menu
	* without any kind of hierarchy or grouping.
	*/
	categories: ^core_option_v2_category,

	/**
	* An array of \ref retro_core_option_v2_definition "core option descriptors",
	* terminated by a zeroed-out definition \c struct.
	*
	* Required; must not be \c NULL.
	*/
	definitions: ^core_option_v2_definition,
}

/**
* A variant of \ref retro_core_options_v2 that supports internationalization.
*
* @see retro_core_options_v2
* @see ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL
* @see ENVIRONMENT_GET_LANGUAGE
* @see retro_language
*/
core_options_v2_intl :: struct {
	/**
	* Pointer to a core options set
	* whose text is written in American English.
	*
	* This may be passed to \c ENVIRONMENT_SET_CORE_OPTIONS_V2 as-is
	* if not using \c ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL.
	*
	* Required; must not be \c NULL.
	*/
	us: ^core_options_v2,

	/**
	* Pointer to a core options set
	* whose text is written in one of libretro's \ref retro_language "supported languages",
	* most likely the one returned by \ref ENVIRONMENT_GET_LANGUAGE.
	*
	* Structure is the same, but usage is slightly different:
	*
	* \li All text (except for keys and option values)
	*     should be written in whichever language
	*     is returned by \c ENVIRONMENT_GET_LANGUAGE.
	* \li All fields besides keys and option values may be \c NULL,
	*     in which case the corresponding string in \c us
	*     is used instead.
	* \li All \ref retro_core_option_v2_definition::default_value "default option values"
	*     are taken from \c us.
	*     The defaults in this field are ignored.
	*
	* May be \c NULL, in which case \c us is used instead.
	*/
	local: ^core_options_v2,
}

/**
* Called by the frontend to determine if any core option's visibility has changed.
*
* Each time a frontend sets a core option,
* it should call this function to see if
* any core option should be made visible or invisible.
*
* May also be called after \ref retro_load_game "loading a game",
* to determine what the initial visibility of each option should be.
*
* Within this function, the core must update the visibility
* of any dynamically-hidden options
* using \ref ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY.
*
* @note All core options are visible by default,
* even during this function's first call.
*
* @return \c true if any core option's visibility was adjusted
* since the last call to this function.
* @see ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY
* @see retro_core_option_display
*/
core_options_update_display_callback_t :: proc "c" () -> bool

/**
* Callback registered by the core for the frontend to use
* when setting the visibility of each core option.
*
* @see ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY
* @see retro_core_option_display
*/
core_options_update_display_callback :: struct {
	/**
	* @copydoc retro_core_options_update_display_callback_t
	*
	* Set by the core.
	*/
	callback: core_options_update_display_callback_t,
}

/** @} */
game_info :: struct {
	path: cstring,  /* Path to game, UTF-8 encoded.
                            * Sometimes used as a reference for building other paths.
                            * May be NULL if game was loaded from stdin or similar,
                            * but in this case some cores will be unable to load `data`.
                            * So, it is preferable to fabricate something here instead
                            * of passing NULL, which will help more cores to succeed.
                            * retro_system_info::need_fullpath requires
                            * that this path is valid. */
	data: rawptr,   /* Memory buffer of loaded game. Will be NULL
                            * if need_fullpath was set. */
	size: c.size_t, /* Size of memory buffer. */
	meta: cstring,  /* String of implementation specific meta-data. */
}

/** @defgroup GET_CURRENT_SOFTWARE_FRAMEBUFFER Frontend-Owned Framebuffers
* @{
*/

/** @defgroup MEMORY_ACCESS Framebuffer Memory Access Types
* @{
*/

/** Indicates that core will write to the framebuffer returned by the frontend. */
MEMORY_ACCESS_WRITE :: (1<<0)

/** Indicates that the core will read from the framebuffer returned by the frontend. */
MEMORY_ACCESS_READ :: (1<<1)

/** @} */

/** @defgroup MEMORY_TYPE Framebuffer Memory Types
* @{
*/

/**
* Indicates that the returned framebuffer's memory is cached.
* If not set, random access to the buffer may be very slow.
*/
MEMORY_TYPE_CACHED :: (1<<0)

/**
* A frame buffer owned by the frontend that a core may use for rendering.
*
* @see GET_CURRENT_SOFTWARE_FRAMEBUFFER
* @see retro_video_refresh_t
*/
framebuffer :: struct {
	/**
	* Pointer to the beginning of the framebuffer provided by the frontend.
	* The initial contents of this buffer are unspecified,
	* as is the means used to map the memory;
	* this may be defined in software,
	* or it may be GPU memory mapped to RAM.
	*
	* If the framebuffer is used,
	* this pointer must be passed to \c retro_video_refresh_t as-is.
	* It is undefined behavior to pass an offset to this pointer.
	*
	* @warning This pointer is only guaranteed to be valid
	* for the duration of the same \c retro_run iteration
	* \ref GET_CURRENT_SOFTWARE_FRAMEBUFFER "that requested the framebuffer".
	* Reuse of this pointer is undefined.
	*/
	data: rawptr,

	/**
	* The width of the framebuffer given in \c data, in pixels.
	* Set by the core.
	*
	* @warning If the framebuffer is used,
	* this value must be passed to \c retro_video_refresh_t as-is.
	* It is undefined behavior to try to render \c data with any other width.
	*/
	width: u32,

	/**
	* The height of the framebuffer given in \c data, in pixels.
	* Set by the core.
	*
	* @warning If the framebuffer is used,
	* this value must be passed to \c retro_video_refresh_t as-is.
	* It is undefined behavior to try to render \c data with any other height.
	*/
	height: u32,

	/**
	* The distance between the start of one scanline and the beginning of the next, in bytes.
	* In practice this is usually equal to \c width times the pixel size,
	* but that's not guaranteed.
	* Sometimes called the "stride".
	*
	* @setby{frontend}
	* @warning If the framebuffer is used,
	* this value must be passed to \c retro_video_refresh_t as-is.
	* It is undefined to try to render \c data with any other pitch.
	*/
	pitch: c.size_t,

	/**
	* The pixel format of the returned framebuffer.
	* May be different than the format specified by the core in \c ENVIRONMENT_SET_PIXEL_FORMAT,
	* e.g. due to conversions.
	* Set by the frontend.
	*
	* @see ENVIRONMENT_SET_PIXEL_FORMAT
	*/
	format: pixel_format,

	/**
	* One or more \ref MEMORY_ACCESS "memory access flags"
	* that specify how the core will access the memory in \c data.
	*
	* @setby{core}
	*/
	access_flags: u32,

	/**
	* Zero or more \ref MEMORY_TYPE "memory type flags"
	* that describe how the framebuffer's memory has been mapped.
	*
	* @setby{frontend}
	*/
	memory_flags: u32,
}

/**
* Parameters that govern when and how the core takes control
* of fast-forwarding mode.
*/
fastforwarding_override :: struct {
	/**
	* The factor by which the core will be sped up
	* when \c fastforward is \c true.
	* This value is used as follows:
	*
	* @li A value greater than 1.0 will run the core at
	*     the specified multiple of normal speed.
	*     For example, a value of 5.0
	*     combined with a normal target rate of 60 FPS
	*     will result in a target rate of 300 FPS.
	*     The actual rate may be lower if the host's hardware can't keep up.
	* @li A value of 1.0 will run the core at normal speed.
	* @li A value between 0.0 (inclusive) and 1.0 (exclusive)
	*     will run the core as fast as the host system can manage.
	* @li A negative value will let the frontend choose a factor.
	* @li An infinite value or \c NaN results in undefined behavior.
	*
	* @attention Setting this value to less than 1.0 will \em not
	* slow down the core.
	*/
	ratio: f32,

	/**
	* If \c true, the frontend should activate fast-forwarding
	* until this field is set to \c false or the core is unloaded.
	*/
	fastforward: bool,

	/**
	* If \c true, the frontend should display an on-screen notification or icon
	* while \c fastforward is \c true (where supported).
	* Otherwise, the frontend should not display any such notification.
	*/
	notification: bool,

	/**
	* If \c true, the core has exclusive control
	* over enabling and disabling fast-forwarding
	* via the \c fastforward field.
	* The frontend will not be able to start or stop fast-forwarding
	* until this field is set to \c false or the core is unloaded.
	*/
	inhibit_toggle: bool,
}

/** @} */

/**
* During normal operation.
*
* @note Rate will be equal to the core's internal FPS.
*/
THROTTLE_NONE              :: 0

/**
* While paused or stepping single frames.
*
* @note Rate will be 0.
*/
THROTTLE_FRAME_STEPPING    :: 1

/**
* During fast forwarding.
*
* @note Rate will be 0 if not specifically limited to a maximum speed.
*/
THROTTLE_FAST_FORWARD      :: 2

/**
* During slow motion.
*
* @note Rate will be less than the core's internal FPS.
*/
THROTTLE_SLOW_MOTION       :: 3

/**
* While rewinding recorded save states.
*
* @note Rate can vary depending on the rewind speed or be 0 if the frontend
* is not aiming for a specific rate.
*/
THROTTLE_REWINDING         :: 4

/**
* While vsync is active in the video driver, and the target refresh rate is lower than the core's internal FPS.
*
* @note Rate is the target refresh rate.
*/
THROTTLE_VSYNC             :: 5

/**
* When the frontend does not throttle in any way.
*
* @note Rate will be 0. An example could be if no vsync or audio output is active.
*/
THROTTLE_UNBLOCKED         :: 6

/**
* Details about the actual rate an implementation is calling \c retro_run() at.
*
* @see ENVIRONMENT_GET_THROTTLE_STATE
*/
throttle_state :: struct {
	/**
	* The current throttling mode.
	*
	* @note Should be one of the \c THROTTLE_* values.
	* @see THROTTLE_NONE
	* @see THROTTLE_FRAME_STEPPING
	* @see THROTTLE_FAST_FORWARD
	* @see THROTTLE_SLOW_MOTION
	* @see THROTTLE_REWINDING
	* @see THROTTLE_VSYNC
	* @see THROTTLE_UNBLOCKED
	*/
	mode: u32,

	/**
	* How many times per second the frontend aims to call retro_run.
	*
	* @note Depending on the mode, it can be 0 if there is no known fixed rate.
	* This won't be accurate if the total processing time of the core and
	* the frontend is longer than what is available for one frame.
	*/
	rate: f32,
}

/**
* Opaque handle to a microphone that's been opened for use.
* The underlying object is accessed or created with \c retro_microphone_interface_t.
*/
microphone_t :: microphone
microphone   :: struct {}

/**
* Parameters for configuring a microphone.
* Some of these might not be honored,
* depending on the available hardware and driver configuration.
*/
microphone_params :: struct {
	/**
	* The desired sample rate of the microphone's input, in Hz.
	* The microphone's input will be resampled,
	* so cores can ask for whichever frequency they need.
	*
	* If zero, some reasonable default will be provided by the frontend
	* (usually from its config file).
	*
	* @see retro_get_mic_rate_t
	*/
	rate: u32,
}

/**
* Parameters for configuring a microphone.
* Some of these might not be honored,
* depending on the available hardware and driver configuration.
*/
microphone_params_t :: microphone_params

/**
* @copydoc retro_microphone_interface::open_mic
*/
open_mic_t :: proc "c" (params: ^microphone_params_t) -> ^microphone_t

/**
* @copydoc retro_microphone_interface::close_mic
*/
close_mic_t :: proc "c" (microphone: ^microphone_t)

/**
* @copydoc retro_microphone_interface::get_params
*/
get_mic_params_t :: proc "c" (microphone: ^microphone_t, params: ^microphone_params_t) -> bool

/**
* @copydoc retro_microphone_interface::set_mic_state
*/
set_mic_state_t :: proc "c" (microphone: ^microphone_t, state: bool) -> bool

/**
* @copydoc retro_microphone_interface::get_mic_state
*/
get_mic_state_t :: proc "c" (microphone: ^microphone_t) -> bool

/**
* @copydoc retro_microphone_interface::read_mic
*/
read_mic_t :: proc "c" (microphone: ^microphone_t, samples: ^i16, num_samples: c.size_t) -> i32

/**
* The current version of the microphone interface.
* Will be incremented whenever \c retro_microphone_interface or \c retro_microphone_params_t
* receive new fields.
*
* Frontends using cores built against older mic interface versions
* should not access fields introduced in newer versions.
*/
MICROPHONE_INTERFACE_VERSION :: 1

/**
* An interface for querying the microphone and accessing data read from it.
*
* @see ENVIRONMENT_GET_MICROPHONE_INTERFACE
*/
microphone_interface :: struct {
	/**
	* The version of this microphone interface.
	* Set by the core to request a particular version,
	* and set by the frontend to indicate the returned version.
	* 0 indicates that the interface is invalid or uninitialized.
	*/
	interface_version: u32,

	/**
	* Initializes a new microphone.
	* Assuming that microphone support is enabled and provided by the frontend,
	* cores may call this function whenever necessary.
	* A microphone could be opened throughout a core's lifetime,
	* or it could wait until a microphone is plugged in to the emulated device.
	*
	* The returned handle will be valid until it's freed,
	* even if the audio driver is reinitialized.
	*
	* This function is not guaranteed to be thread-safe.
	*
	* @param[in] args Parameters used to create the microphone.
	* May be \c NULL, in which case the default value of each parameter will be used.
	*
	* @returns Pointer to the newly-opened microphone,
	* or \c NULL if one couldn't be opened.
	* This likely means that no microphone is plugged in and recognized,
	* or the maximum number of supported microphones has been reached.
	*
	* @note Microphones are \em inactive by default;
	* to begin capturing audio, call \c set_mic_state.
	* @see retro_microphone_params_t
	*/
	open_mic: open_mic_t,

	/**
	* Closes a microphone that was initialized with \c open_mic.
	* Calling this function will stop all microphone activity
	* and free up the resources that it allocated.
	* Afterwards, the handle is invalid and must not be used.
	*
	* A frontend may close opened microphones when unloading content,
	* but this behavior is not guaranteed.
	* Cores should close their microphones when exiting, just to be safe.
	*
	* @param microphone Pointer to the microphone that was allocated by \c open_mic.
	* If \c NULL, this function does nothing.
	*
	* @note The handle might be reused if another microphone is opened later.
	*/
	close_mic: close_mic_t,

	/**
	* Returns the configured parameters of this microphone.
	* These may differ from what was requested depending on
	* the driver and device configuration.
	*
	* Cores should check these values before they start fetching samples.
	*
	* Will not change after the mic was opened.
	*
	* @param[in] microphone Opaque handle to the microphone
	* whose parameters will be retrieved.
	* @param[out] params The parameters object that the
	* microphone's parameters will be copied to.
	*
	* @return \c true if the parameters were retrieved,
	* \c false if there was an error.
	*/
	get_params: get_mic_params_t,

	/**
	* Enables or disables the given microphone.
	* Microphones are disabled by default
	* and must be explicitly enabled before they can be used.
	* Disabled microphones will not process incoming audio samples,
	* and will therefore have minimal impact on overall performance.
	* Cores may enable microphones throughout their lifetime,
	* or only for periods where they're needed.
	*
	* Cores that accept microphone input should be able to operate without it;
	* we suggest substituting silence in this case.
	*
	* @param microphone Opaque handle to the microphone
	* whose state will be adjusted.
	* This will have been provided by \c open_mic.
	* @param state \c true if the microphone should receive audio input,
	* \c false if it should be idle.
	* @returns \c true if the microphone's state was successfully set,
	* \c false if \c microphone is invalid
	* or if there was an error.
	*/
	set_mic_state: set_mic_state_t,

	/**
	* Queries the active state of a microphone at the given index.
	* Will return whether the microphone is enabled,
	* even if the driver is paused.
	*
	* @param microphone Opaque handle to the microphone
	* whose state will be queried.
	* @return \c true if the provided \c microphone is valid and active,
	* \c false if not or if there was an error.
	*/
	get_mic_state: get_mic_state_t,

	/**
	* Retrieves the input processed by the microphone since the last call.
	* \em Must be called every frame unless \c microphone is disabled,
	* similar to how \c retro_audio_sample_batch_t works.
	*
	* @param[in] microphone Opaque handle to the microphone
	* whose recent input will be retrieved.
	* @param[out] samples The buffer that will be used to store the microphone's data.
	* Microphone input is in mono (i.e. one number per sample).
	* Should be large enough to accommodate the expected number of samples per frame;
	* for example, a 44.1kHz sample rate at 60 FPS would require space for 735 samples.
	* @param[in] num_samples The size of the data buffer in samples (\em not bytes).
	* Microphone input is in mono, so a "frame" and a "sample" are equivalent in length here.
	*
	* @return The number of samples that were copied into \c samples.
	* If \c microphone is pending driver initialization,
	* this function will copy silence of the requested length into \c samples.
	*
	* Will return -1 if the microphone is disabled,
	* the audio driver is paused,
	* or there was an error.
	*/
	read_mic: read_mic_t,
}

/**
* Describes how a device is being powered.
* @see ENVIRONMENT_GET_DEVICE_POWER
*/
power_state :: enum u32 {
	/**
	* Indicates that the frontend cannot report its power state at this time,
	* most likely due to a lack of support.
	*
	* \c ENVIRONMENT_GET_DEVICE_POWER will not return this value;
	* instead, the environment callback will return \c false.
	*/
	UNKNOWN     = 0,

	/**
	* Indicates that the device is running on its battery.
	* Usually applies to portable devices such as handhelds, laptops, and smartphones.
	*/
	DISCHARGING = 1,

	/**
	* Indicates that the device's battery is currently charging.
	*/
	CHARGING    = 2,

	/**
	* Indicates that the device is connected to a power source
	* and that its battery has finished charging.
	*/
	CHARGED     = 3,

	/**
	* Indicates that the device is connected to a power source
	* and that it does not have a battery.
	* This usually suggests a desktop computer or a non-portable game console.
	*/
	PLUGGED_IN  = 4,
}

/**
* Indicates that an estimate is not available for the battery level or time remaining,
* even if the actual power state is known.
*/
POWERSTATE_NO_ESTIMATE :: (-1)

/**
* Describes the power state of the device running the frontend.
* @see ENVIRONMENT_GET_DEVICE_POWER
*/
device_power :: struct {
	/**
	* The current state of the frontend's power usage.
	*/
	state: power_state,

	/**
	* A rough estimate of the amount of time remaining (in seconds)
	* before the device powers off.
	* This value depends on a variety of factors,
	* so it is not guaranteed to be accurate.
	*
	* Will be set to \c POWERSTATE_NO_ESTIMATE if \c state does not equal \c POWERSTATE_DISCHARGING.
	* May still be set to \c POWERSTATE_NO_ESTIMATE if the frontend is unable to provide an estimate.
	*/
	seconds: i32,

	/**
	* The approximate percentage of battery charge,
	* ranging from 0 to 100 (inclusive).
	* The device may power off before this reaches 0.
	*
	* The user might have configured their device
	* to stop charging before the battery is full,
	* so do not assume that this will be 100 in the \c POWERSTATE_CHARGED state.
	*/
	percent: i8,
}

/**
* Environment callback to give implementations a way of performing uncommon tasks.
*
* @note Extensible.
*
* @param cmd The command to run.
* @param data A pointer to the data associated with the command.
*
* @return Varies by callback,
* but will always return \c false if the command is not recognized.
*
* @see ENVIRONMENT_SET_ROTATION
* @see retro_set_environment()
*/
environment_t :: proc "c" (cmd: u32, data: rawptr) -> bool

/**
* Render a frame.
*
* @note For performance reasons, it is highly recommended to have a frame
* that is packed in memory, i.e. pitch == width * byte_per_pixel.
* Certain graphic APIs, such as OpenGL ES, do not like textures
* that are not packed in memory.
*
* @param data A pointer to the frame buffer data with a pixel format of 15-bit \c 0RGB1555 native endian, unless changed with \c ENVIRONMENT_SET_PIXEL_FORMAT.
* @param width The width of the frame buffer, in pixels.
* @param height The height frame buffer, in pixels.
* @param pitch The width of the frame buffer, in bytes.
*
* @see retro_set_video_refresh()
* @see ENVIRONMENT_SET_PIXEL_FORMAT
* @see retro_pixel_format
*/
video_refresh_t :: proc "c" (data: rawptr, width: u32, height: u32, pitch: c.size_t)

/**
* Renders a single audio frame. Should only be used if implementation generates a single sample at a time.
*
* @param left The left audio sample represented as a signed 16-bit native endian.
* @param right The right audio sample represented as a signed 16-bit native endian.
*
* @see retro_set_audio_sample()
* @see retro_set_audio_sample_batch()
*/
audio_sample_t :: proc "c" (left: i16, right: i16)

/**
* Renders multiple audio frames in one go.
*
* @note Only one of the audio callbacks must ever be used.
*
* @param data A pointer to the audio sample data pairs to render.
* @param frames The number of frames that are represented in the data. One frame
*     is defined as a sample of left and right channels, interleaved.
*     For example: <tt>int16_t buf[4] = { l, r, l, r };</tt> would be 2 frames.
*
* @return The number of frames that were processed.
*
* @see retro_set_audio_sample_batch()
* @see retro_set_audio_sample()
*/
audio_sample_batch_t :: proc "c" (data: ^i16, frames: c.size_t) -> c.size_t

/**
* Polls input.
*
* @see retro_set_input_poll()
*/
input_poll_t :: proc "c" ()

/**
* Queries for input for player 'port'.
*
* @param port Which player 'port' to query.
* @param device Which device to query for. Will be masked with \c DEVICE_MASK.
* @param index The input index to retrieve.
* The exact semantics depend on the device type given in \c device.
* @param id The ID of which value to query, like \c DEVICE_ID_JOYPAD_B.
* @returns Depends on the provided arguments,
* but will return 0 if their values are unsupported
* by the frontend or the backing physical device.
* @note Specialization of devices such as \c DEVICE_JOYPAD_MULTITAP that
* have been set with \c retro_set_controller_port_device() will still use the
* higher level \c DEVICE_JOYPAD to request input.
*
* @see retro_set_input_state()
* @see DEVICE_NONE
* @see DEVICE_JOYPAD
* @see DEVICE_MOUSE
* @see DEVICE_KEYBOARD
* @see DEVICE_LIGHTGUN
* @see DEVICE_ANALOG
* @see DEVICE_POINTER
*/
input_state_t :: proc "c" (port: u32, device: u32, index: u32, id: u32) -> i16

@(default_calling_convention="c")
foreign _ {
	/**
	* Sets the environment callback.
	*
	* @param cb The function which is used when making environment calls.
	*
	* @note Guaranteed to be called before \c retro_init().
	*
	* @see ENVIRONMENT
	*/
	retro_set_environment :: proc(cb: environment_t) ---

	/**
	* Sets the video refresh callback.
	*
	* @param cb The function which is used when rendering a frame.
	*
	* @note Guaranteed to have been called before the first call to \c retro_run() is made.
	*/
	retro_set_video_refresh :: proc(cb: video_refresh_t) ---

	/**
	* Sets the audio sample callback.
	*
	* @param cb The function which is used when rendering a single audio frame.
	*
	* @note Guaranteed to have been called before the first call to \c retro_run() is made.
	*/
	retro_set_audio_sample :: proc(cb: audio_sample_t) ---

	/**
	* Sets the audio sample batch callback.
	*
	* @param cb The function which is used when rendering multiple audio frames in one go.
	*
	* @note Guaranteed to have been called before the first call to \c retro_run() is made.
	*/
	retro_set_audio_sample_batch :: proc(cb: audio_sample_batch_t) ---

	/**
	* Sets the input poll callback.
	*
	* @param cb The function which is used to poll the active input.
	*
	* @note Guaranteed to have been called before the first call to \c retro_run() is made.
	*/
	retro_set_input_poll :: proc(cb: input_poll_t) ---

	/**
	* Sets the input state callback.
	*
	* @param cb The function which is used to query the input state.
	*
	*@note Guaranteed to have been called before the first call to \c retro_run() is made.
	*/
	retro_set_input_state :: proc(cb: input_state_t) ---

	/**
	* Called by the frontend when initializing a libretro core.
	*
	* @warning There are many possible "gotchas" with global state in dynamic libraries.
	* Here are some to keep in mind:
	* <ul>
	* <li>Do not assume that the core was loaded by the operating system
	* for the first time within this call.
	* It may have been statically linked or retained from a previous session.
	* Consequently, cores must not rely on global variables being initialized
	* to their default values before this function is called;
	* this also goes for object constructors in C++.
	* <li>Although C++ requires that constructors be called for global variables,
	* it does not require that their destructors be called
	* if stored within a dynamic library's global scope.
	* <li>If the core is statically linked to the frontend,
	* global variables may be initialized when the frontend itself is initially executed.
	* </ul>
	* @see retro_deinit
	*/
	retro_init :: proc() ---

	/**
	* Called by the frontend when deinitializing a libretro core.
	* The core must release all of its allocated resources before this function returns.
	*
	* @warning There are many possible "gotchas" with global state in dynamic libraries.
	* Here are some to keep in mind:
	* <ul>
	* <li>Do not assume that the operating system will unload the core after this function returns,
	* as the core may be linked statically or retained in memory.
	* Cores should use this function to clean up all allocated resources
	* and reset all global variables to their default states.
	* <li>Do not assume that this core won't be loaded again after this function returns.
	* It may be kept in memory by the frontend for later use,
	* or it may be statically linked.
	* Therefore, all global variables should be reset to their default states within this function.
	* <li>C++ does not require that destructors be called
	* for variables within a dynamic library's global scope.
	* Therefore, global objects that own dynamically-managed resources
	* (such as \c std::string or <tt>std::vector</tt>)
	* should be kept behind pointers that are explicitly deallocated within this function.
	* </ul>
	* @see retro_init
	*/
	retro_deinit :: proc() ---

	/**
	* Retrieves which version of the libretro API is being used.
	*
	* @note This is used to validate ABI compatibility when the API is revised.
	*
	* @return Must return \c API_VERSION.
	*
	* @see API_VERSION
	*/
	retro_api_version :: proc() -> u32 ---

	/**
	* Gets statically known system info.
	*
	* @note Can be called at any time, even before retro_init().
	*
	* @param info A pointer to a \c retro_system_info where the info is to be loaded into. This must be statically allocated.
	*/
	retro_get_system_info :: proc(info: ^system_info) ---

	/**
	* Gets information about system audio/video timings and geometry.
	*
	* @note Can be called only after \c retro_load_game() has successfully completed.
	*
	* @note The implementation of this function might not initialize every variable
	* if needed. For example, \c geom.aspect_ratio might not be initialized if
	* the core doesn't desire a particular aspect ratio.
	*
	* @param info A pointer to a \c retro_system_av_info where the audio/video information should be loaded into.
	*
	* @see retro_system_av_info
	*/
	retro_get_system_av_info :: proc(info: ^system_av_info) ---

	/**
	* Sets device to be used for player 'port'.
	*
	* By default, \c DEVICE_JOYPAD is assumed to be plugged into all
	* available ports.
	*
	* @note Setting a particular device type is not a guarantee that libretro cores
	* will only poll input based on that particular device type. It is only a
	* hint to the libretro core when a core cannot automatically detect the
	* appropriate input device type on its own. It is also relevant when a
	* core can change its behavior depending on device type.
	*
	* @note As part of the core's implementation of retro_set_controller_port_device,
	* the core should call \c ENVIRONMENT_SET_INPUT_DESCRIPTORS to notify the
	* frontend if the descriptions for any controls have changed as a
	* result of changing the device type.
	*
	* @param port Which port to set the device for, usually indicates the player number.
	* @param device Which device the given port is using. By default, \c DEVICE_JOYPAD is assumed for all ports.
	*
	* @see DEVICE_NONE
	* @see DEVICE_JOYPAD
	* @see DEVICE_MOUSE
	* @see DEVICE_KEYBOARD
	* @see DEVICE_LIGHTGUN
	* @see DEVICE_ANALOG
	* @see DEVICE_POINTER
	* @see ENVIRONMENT_SET_CONTROLLER_INFO
	*/
	retro_set_controller_port_device :: proc(port: u32, device: u32) ---

	/**
	* Resets the currently-loaded game.
	* Cores should treat this as a soft reset (i.e. an emulated reset button) if possible,
	* but hard resets are acceptable.
	*/
	retro_reset :: proc() ---

	/**
	* Runs the game for one video frame.
	*
	* During \c retro_run(), the \c retro_input_poll_t callback must be called at least once.
	*
	* @note If a frame is not rendered for reasons where a game "dropped" a frame,
	* this still counts as a frame, and \c retro_run() should explicitly dupe
	* a frame if \c ENVIRONMENT_GET_CAN_DUPE returns true. In this case,
	* the video callback can take a NULL argument for data.
	*
	* @see retro_input_poll_t
	*/
	retro_run :: proc() ---

	/**
	* Returns the amount of data the implementation requires to serialize internal state (save states).
	*
	* @note Between calls to \c retro_load_game() and \c retro_unload_game(), the
	* returned size is never allowed to be larger than a previous returned
	* value, to ensure that the frontend can allocate a save state buffer once.
	*
	* @return The amount of data the implementation requires to serialize the internal state.
	*
	* @see retro_serialize()
	*/
	retro_serialize_size :: proc() -> c.size_t ---

	/**
	* Serializes the internal state.
	*
	* @param data A pointer to where the serialized data should be saved to.
	* @param size The size of the memory.
	*
	* @return If failed, or size is lower than \c retro_serialize_size(), it
	* should return false. On success, it will return true.
	*
	* @see retro_serialize_size()
	* @see retro_unserialize()
	*/
	retro_serialize :: proc(data: rawptr, len: c.size_t) -> bool ---

	/**
	* Unserialize the given state data, and load it into the internal state.
	*
	* @return Returns true if loading the state was successful, false otherwise.
	*
	* @see retro_serialize()
	*/
	retro_unserialize :: proc(data: rawptr, len: c.size_t) -> bool ---

	/**
	* Reset all the active cheats to their default disabled state.
	*
	* @see retro_cheat_set()
	*/
	retro_cheat_reset :: proc() ---

	/**
	* Enable or disable a cheat.
	*
	* @param index The index of the cheat to act upon.
	* @param enabled Whether to enable or disable the cheat.
	* @param code A string of the code used for the cheat.
	*
	* @see retro_cheat_reset()
	*/
	retro_cheat_set :: proc(index: u32, enabled: bool, code: cstring) ---

	/**
	* Loads a game.
	*
	* @param game A pointer to a \c retro_game_info detailing information about the game to load.
	* May be \c NULL if the core is loaded without content.
	*
	* @return Will return true when the game was loaded successfully, or false otherwise.
	*
	* @see retro_game_info
	* @see ENVIRONMENT_SET_SUPPORT_NO_GAME
	*/
	retro_load_game :: proc(game: ^game_info) -> bool ---

	/**
	* Called when the frontend has loaded one or more "special" content files,
	* typically through subsystems.
	*
	* @note Only necessary for cores that support subsystems.
	* Others may return \c false or delegate to <tt>retro_load_game</tt>.
	*
	* @param game_type The type of game to load,
	* as determined by \c retro_subsystem_info.
	* @param info A pointer to an array of \c retro_game_info objects
	* providing information about the loaded content.
	* @param num_info The number of \c retro_game_info objects passed into the info parameter.
	* @return \c true if loading is successful, false otherwise.
	* If the core returns \c false,
	* the frontend should abort the core
	* and return to its main menu (if applicable).
	*
	* @see ENVIRONMENT_GET_GAME_INFO_EXT
	* @see ENVIRONMENT_SET_SUBSYSTEM_INFO
	* @see retro_load_game()
	* @see retro_subsystem_info
	*/
	retro_load_game_special :: proc(game_type: u32, info: ^game_info, num_info: c.size_t) -> bool ---

	/**
	* Unloads the currently loaded game.
	*
	* @note This is called before \c retro_deinit(void).
	*
	* @see retro_load_game()
	* @see retro_deinit()
	*/
	retro_unload_game :: proc() ---

	/**
	* Gets the region of the actively loaded content as either \c REGION_NTSC or \c REGION_PAL.
	* @note This refers to the region of the content's intended television standard,
	* not necessarily the region of the content's origin.
	* For emulated consoles that don't use either standard
	* (e.g. handhelds or post-HD platforms),
	* the core should return \c REGION_NTSC.
	* @return The region of the actively loaded content.
	*
	* @see REGION_NTSC
	* @see REGION_PAL
	*/
	retro_get_region :: proc() -> u32 ---

	/**
	* Get a region of memory.
	*
	* @param id The ID for the memory block that's desired to retrieve. Can be \c MEMORY_SAVE_RAM, \c MEMORY_RTC, \c MEMORY_SYSTEM_RAM, or \c MEMORY_VIDEO_RAM.
	*
	* @return A pointer to the desired region of memory, or NULL when not available.
	*
	* @see MEMORY_SAVE_RAM
	* @see MEMORY_RTC
	* @see MEMORY_SYSTEM_RAM
	* @see MEMORY_VIDEO_RAM
	*/
	retro_get_memory_data :: proc(id: u32) -> rawptr ---

	/**
	* Gets the size of the given region of memory.
	*
	* @param id The ID for the memory block to check the size of. Can be MEMORY_SAVE_RAM, MEMORY_RTC, MEMORY_SYSTEM_RAM, or MEMORY_VIDEO_RAM.
	*
	* @return The size of the region in memory, or 0 when not available.
	*
	* @see MEMORY_SAVE_RAM
	* @see MEMORY_RTC
	* @see MEMORY_SYSTEM_RAM
	* @see MEMORY_VIDEO_RAM
	*/
	retro_get_memory_size :: proc(id: u32) -> c.size_t ---
}

