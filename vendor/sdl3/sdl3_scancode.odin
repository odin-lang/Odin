package sdl3

import "core:c"

Scancode :: enum c.int {
	UNKNOWN = 0,

	/**
	*  \name Usage page 0x07
	*
	*  These values are from usage page 0x07 (USB keyboard page).
	*/
	/* @{ */

	A = 4,
	B = 5,
	C = 6,
	D = 7,
	E = 8,
	F = 9,
	G = 10,
	H = 11,
	I = 12,
	J = 13,
	K = 14,
	L = 15,
	M = 16,
	N = 17,
	O = 18,
	P = 19,
	Q = 20,
	R = 21,
	S = 22,
	T = 23,
	U = 24,
	V = 25,
	W = 26,
	X = 27,
	Y = 28,
	Z = 29,

	_1 = 30,
	_2 = 31,
	_3 = 32,
	_4 = 33,
	_5 = 34,
	_6 = 35,
	_7 = 36,
	_8 = 37,
	_9 = 38,
	_0 = 39,

	RETURN = 40,
	ESCAPE = 41,
	BACKSPACE = 42,
	TAB = 43,
	SPACE = 44,

	MINUS = 45,
	EQUALS = 46,
	LEFTBRACKET = 47,
	RIGHTBRACKET = 48,
	BACKSLASH = 49, /**< Located at the lower left of the return
	                 *   key on ISO keyboards and at the right end
	                 *   of the QWERTY row on ANSI keyboards.
	                 *   Produces REVERSE SOLIDUS (backslash) and
	                 *   VERTICAL LINE in a US layout, REVERSE
	                 *   SOLIDUS and VERTICAL LINE in a UK Mac
	                 *   layout, NUMBER SIGN and TILDE in a UK
	                 *   Windows layout, DOLLAR SIGN and POUND SIGN
	                 *   in a Swiss German layout, NUMBER SIGN and
	                 *   APOSTROPHE in a German layout, GRAVE
	                 *   ACCENT and POUND SIGN in a French Mac
	                 *   layout, and ASTERISK and MICRO SIGN in a
	                 *   French Windows layout.
	                 */
	NONUSHASH = 50, /**< ISO USB keyboards actually use this code
	                 *   instead of 49 for the same key, but all
	                 *   OSes I've seen treat the two codes
	                 *   identically. So, as an implementor, unless
	                 *   your keyboard generates both of those
	                 *   codes and your OS treats them differently,
	                 *   you should generate BACKSLASH
	                 *   instead of this code. As a user, you
	                 *   should not rely on this code because SDL
	                 *   will never generate it with most (all?)
	                 *   keyboards.
	                 */
	SEMICOLON = 51,
	APOSTROPHE = 52,
	GRAVE = 53, /**< Located in the top left corner (on both ANSI
	             *   and ISO keyboards). Produces GRAVE ACCENT and
	             *   TILDE in a US Windows layout and in US and UK
	             *   Mac layouts on ANSI keyboards, GRAVE ACCENT
	             *   and NOT SIGN in a UK Windows layout, SECTION
	             *   SIGN and PLUS-MINUS SIGN in US and UK Mac
	             *   layouts on ISO keyboards, SECTION SIGN and
	             *   DEGREE SIGN in a Swiss German layout (Mac:
	             *   only on ISO keyboards), CIRCUMFLEX ACCENT and
	             *   DEGREE SIGN in a German layout (Mac: only on
	             *   ISO keyboards), SUPERSCRIPT TWO and TILDE in a
	             *   French Windows layout, COMMERCIAL AT and
	             *   NUMBER SIGN in a French Mac layout on ISO
	             *   keyboards, and LESS-THAN SIGN and GREATER-THAN
	             *   SIGN in a Swiss German, German, or French Mac
	             *   layout on ANSI keyboards.
	             */
	COMMA = 54,
	PERIOD = 55,
	SLASH = 56,

	CAPSLOCK = 57,

	F1 = 58,
	F2 = 59,
	F3 = 60,
	F4 = 61,
	F5 = 62,
	F6 = 63,
	F7 = 64,
	F8 = 65,
	F9 = 66,
	F10 = 67,
	F11 = 68,
	F12 = 69,

	PRINTSCREEN = 70,
	SCROLLLOCK = 71,
	PAUSE = 72,
	INSERT = 73, /**< insert on PC, help on some Mac keyboards (but
	                           does send code 73, not 117) */
	HOME = 74,
	PAGEUP = 75,
	DELETE = 76,
	END = 77,
	PAGEDOWN = 78,
	RIGHT = 79,
	LEFT = 80,
	DOWN = 81,
	UP = 82,

	NUMLOCKCLEAR = 83, /**< num lock on PC, clear on Mac keyboards
	                             */
	KP_DIVIDE = 84,
	KP_MULTIPLY = 85,
	KP_MINUS = 86,
	KP_PLUS = 87,
	KP_ENTER = 88,
	KP_1 = 89,
	KP_2 = 90,
	KP_3 = 91,
	KP_4 = 92,
	KP_5 = 93,
	KP_6 = 94,
	KP_7 = 95,
	KP_8 = 96,
	KP_9 = 97,
	KP_0 = 98,
	KP_PERIOD = 99,

	NONUSBACKSLASH = 100, /**< This is the additional key that ISO
	                       *   keyboards have over ANSI ones,
	                       *   located between left shift and Y.
	                       *   Produces GRAVE ACCENT and TILDE in a
	                       *   US or UK Mac layout, REVERSE SOLIDUS
	                       *   (backslash) and VERTICAL LINE in a
	                       *   US or UK Windows layout, and
	                       *   LESS-THAN SIGN and GREATER-THAN SIGN
	                       *   in a Swiss German, German, or French
	                       *   layout. */
	APPLICATION = 101, /**< windows contextual menu, compose */
	POWER = 102, /**< The USB document says this is a status flag,
	              *   not a physical key - but some Mac keyboards
	              *   do have a power key. */
	KP_EQUALS = 103,
	F13 = 104,
	F14 = 105,
	F15 = 106,
	F16 = 107,
	F17 = 108,
	F18 = 109,
	F19 = 110,
	F20 = 111,
	F21 = 112,
	F22 = 113,
	F23 = 114,
	F24 = 115,
	EXECUTE = 116,
	HELP = 117,    /**< AL Integrated Help Center */
	MENU = 118,    /**< Menu (show menu) */
	SELECT = 119,
	STOP = 120,    /**< AC Stop */
	AGAIN = 121,   /**< AC Redo/Repeat */
	UNDO = 122,    /**< AC Undo */
	CUT = 123,     /**< AC Cut */
	COPY = 124,    /**< AC Copy */
	PASTE = 125,   /**< AC Paste */
	FIND = 126,    /**< AC Find */
	MUTE = 127,
	VOLUMEUP = 128,
	VOLUMEDOWN = 129,
	/* not sure whether there's a reason to enable these */
	/*     LOCKINGCAPSLOCK = 130,  */
	/*     LOCKINGNUMLOCK = 131, */
	/*     LOCKINGSCROLLLOCK = 132, */
	KP_COMMA = 133,
	KP_EQUALSAS400 = 134,

	INTERNATIONAL1 = 135, /**< used on Asian keyboards, see
	                                    footnotes in USB doc */
	INTERNATIONAL2 = 136,
	INTERNATIONAL3 = 137, /**< Yen */
	INTERNATIONAL4 = 138,
	INTERNATIONAL5 = 139,
	INTERNATIONAL6 = 140,
	INTERNATIONAL7 = 141,
	INTERNATIONAL8 = 142,
	INTERNATIONAL9 = 143,
	LANG1 = 144, /**< Hangul/English toggle */
	LANG2 = 145, /**< Hanja conversion */
	LANG3 = 146, /**< Katakana */
	LANG4 = 147, /**< Hiragana */
	LANG5 = 148, /**< Zenkaku/Hankaku */
	LANG6 = 149, /**< reserved */
	LANG7 = 150, /**< reserved */
	LANG8 = 151, /**< reserved */
	LANG9 = 152, /**< reserved */

	ALTERASE = 153,    /**< Erase-Eaze */
	SYSREQ = 154,
	CANCEL = 155,      /**< AC Cancel */
	CLEAR = 156,
	PRIOR = 157,
	RETURN2 = 158,
	SEPARATOR = 159,
	OUT = 160,
	OPER = 161,
	CLEARAGAIN = 162,
	CRSEL = 163,
	EXSEL = 164,

	KP_00 = 176,
	KP_000 = 177,
	THOUSANDSSEPARATOR = 178,
	DECIMALSEPARATOR = 179,
	CURRENCYUNIT = 180,
	CURRENCYSUBUNIT = 181,
	KP_LEFTPAREN = 182,
	KP_RIGHTPAREN = 183,
	KP_LEFTBRACE = 184,
	KP_RIGHTBRACE = 185,
	KP_TAB = 186,
	KP_BACKSPACE = 187,
	KP_A = 188,
	KP_B = 189,
	KP_C = 190,
	KP_D = 191,
	KP_E = 192,
	KP_F = 193,
	KP_XOR = 194,
	KP_POWER = 195,
	KP_PERCENT = 196,
	KP_LESS = 197,
	KP_GREATER = 198,
	KP_AMPERSAND = 199,
	KP_DBLAMPERSAND = 200,
	KP_VERTICALBAR = 201,
	KP_DBLVERTICALBAR = 202,
	KP_COLON = 203,
	KP_HASH = 204,
	KP_SPACE = 205,
	KP_AT = 206,
	KP_EXCLAM = 207,
	KP_MEMSTORE = 208,
	KP_MEMRECALL = 209,
	KP_MEMCLEAR = 210,
	KP_MEMADD = 211,
	KP_MEMSUBTRACT = 212,
	KP_MEMMULTIPLY = 213,
	KP_MEMDIVIDE = 214,
	KP_PLUSMINUS = 215,
	KP_CLEAR = 216,
	KP_CLEARENTRY = 217,
	KP_BINARY = 218,
	KP_OCTAL = 219,
	KP_DECIMAL = 220,
	KP_HEXADECIMAL = 221,

	LCTRL = 224,
	LSHIFT = 225,
	LALT = 226, /**< alt, option */
	LGUI = 227, /**< windows, command (apple), meta */
	RCTRL = 228,
	RSHIFT = 229,
	RALT = 230, /**< alt gr, option */
	RGUI = 231, /**< windows, command (apple), meta */

	MODE = 257,    /**< I'm not sure if this is really not covered
	                *   by any of the above, but since there's a
	                *   special SDL_KMOD_MODE for it I'm adding it here
	                */

	/* @} *//* Usage page 0x07 */

	/**
	*  \name Usage page 0x0C
	*
	*  These values are mapped from usage page 0x0C (USB consumer page).
	*
	*  There are way more keys in the spec than we can represent in the
	*  current scancode range, so pick the ones that commonly come up in
	*  real world usage.
	*/
	/* @{ */

	SLEEP = 258,                   /**< Sleep */
	WAKE = 259,                    /**< Wake */

	CHANNEL_INCREMENT = 260,       /**< Channel Increment */
	CHANNEL_DECREMENT = 261,       /**< Channel Decrement */

	MEDIA_PLAY = 262,          /**< Play */
	MEDIA_PAUSE = 263,         /**< Pause */
	MEDIA_RECORD = 264,        /**< Record */
	MEDIA_FAST_FORWARD = 265,  /**< Fast Forward */
	MEDIA_REWIND = 266,        /**< Rewind */
	MEDIA_NEXT_TRACK = 267,    /**< Next Track */
	MEDIA_PREVIOUS_TRACK = 268, /**< Previous Track */
	MEDIA_STOP = 269,          /**< Stop */
	MEDIA_EJECT = 270,         /**< Eject */
	MEDIA_PLAY_PAUSE = 271,    /**< Play / Pause */
	MEDIA_SELECT = 272,        /* Media Select */

	AC_NEW = 273,              /**< AC New */
	AC_OPEN = 274,             /**< AC Open */
	AC_CLOSE = 275,            /**< AC Close */
	AC_EXIT = 276,             /**< AC Exit */
	AC_SAVE = 277,             /**< AC Save */
	AC_PRINT = 278,            /**< AC Print */
	AC_PROPERTIES = 279,       /**< AC Properties */

	AC_SEARCH = 280,           /**< AC Search */
	AC_HOME = 281,             /**< AC Home */
	AC_BACK = 282,             /**< AC Back */
	AC_FORWARD = 283,          /**< AC Forward */
	AC_STOP = 284,             /**< AC Stop */
	AC_REFRESH = 285,          /**< AC Refresh */
	AC_BOOKMARKS = 286,        /**< AC Bookmarks */

	/* @} *//* Usage page 0x0C */


	/**
	*  \name Mobile keys
	*
	*  These are values that are often used on mobile phones.
	*/
	/* @{ */

	SOFTLEFT = 287, /**< Usually situated below the display on phones and
	                              used as a multi-function feature key for selecting
	                              a software defined function shown on the bottom left
	                              of the display. */
	SOFTRIGHT = 288, /**< Usually situated below the display on phones and
	                               used as a multi-function feature key for selecting
	                               a software defined function shown on the bottom right
	                               of the display. */
	CALL = 289, /**< Used for accepting phone calls. */
	ENDCALL = 290, /**< Used for rejecting phone calls. */

	/* @} *//* Mobile keys */

	/* Add any other keys here. */

	RESERVED = 400,    /**< 400-500 reserved for dynamic keycodes */

	_ = 511,
	// COUNT = 512 /**< not a key, just marks the number of scancodes for array bounds */

}
