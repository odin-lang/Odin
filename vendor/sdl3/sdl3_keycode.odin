package sdl3

Keycode :: distinct Uint32

@(require_results)
SCANCODE_TO_KEYCODE :: #force_inline proc "c" (X: Scancode) -> Keycode {
	return Keycode(X) | K_SCANCODE_MASK
}

K_EXTENDED_MASK          :: 1 << 29
K_SCANCODE_MASK          :: 1 << 30
K_UNKNOWN                :: 0x00000000 /**< 0 */
K_RETURN                 :: 0x0000000d /**< '\r' */
K_ESCAPE                 :: 0x0000001b /**< '\x1B' */
K_BACKSPACE              :: 0x00000008 /**< '\b' */
K_TAB                    :: 0x00000009 /**< '\t' */
K_SPACE                  :: 0x00000020 /**< ' ' */
K_EXCLAIM                :: 0x00000021 /**< '!' */
K_DBLAPOSTROPHE          :: 0x00000022 /**< '"' */
K_HASH                   :: 0x00000023 /**< '#' */
K_DOLLAR                 :: 0x00000024 /**< '$' */
K_PERCENT                :: 0x00000025 /**< '%' */
K_AMPERSAND              :: 0x00000026 /**< '&' */
K_APOSTROPHE             :: 0x00000027 /**< '\'' */
K_LEFTPAREN              :: 0x00000028 /**< '(' */
K_RIGHTPAREN             :: 0x00000029 /**< ')' */
K_ASTERISK               :: 0x0000002a /**< '*' */
K_PLUS                   :: 0x0000002b /**< '+' */
K_COMMA                  :: 0x0000002c /**< ',' */
K_MINUS                  :: 0x0000002d /**< '-' */
K_PERIOD                 :: 0x0000002e /**< '.' */
K_SLASH                  :: 0x0000002f /**< '/' */
K_0                      :: 0x00000030 /**< '0' */
K_1                      :: 0x00000031 /**< '1' */
K_2                      :: 0x00000032 /**< '2' */
K_3                      :: 0x00000033 /**< '3' */
K_4                      :: 0x00000034 /**< '4' */
K_5                      :: 0x00000035 /**< '5' */
K_6                      :: 0x00000036 /**< '6' */
K_7                      :: 0x00000037 /**< '7' */
K_8                      :: 0x00000038 /**< '8' */
K_9                      :: 0x00000039 /**< '9' */
K_COLON                  :: 0x0000003a /**< ':' */
K_SEMICOLON              :: 0x0000003b /**< ';' */
K_LESS                   :: 0x0000003c /**< '<' */
K_EQUALS                 :: 0x0000003d /**< '=' */
K_GREATER                :: 0x0000003e /**< '>' */
K_QUESTION               :: 0x0000003f /**< '?' */
K_AT                     :: 0x00000040 /**< '@' */
K_LEFTBRACKET            :: 0x0000005b /**< '[' */
K_BACKSLASH              :: 0x0000005c /**< '\\' */
K_RIGHTBRACKET           :: 0x0000005d /**< ']' */
K_CARET                  :: 0x0000005e /**< '^' */
K_UNDERSCORE             :: 0x0000005f /**< '_' */
K_GRAVE                  :: 0x00000060 /**< '`' */
K_A                      :: 0x00000061 /**< 'a' */
K_B                      :: 0x00000062 /**< 'b' */
K_C                      :: 0x00000063 /**< 'c' */
K_D                      :: 0x00000064 /**< 'd' */
K_E                      :: 0x00000065 /**< 'e' */
K_F                      :: 0x00000066 /**< 'f' */
K_G                      :: 0x00000067 /**< 'g' */
K_H                      :: 0x00000068 /**< 'h' */
K_I                      :: 0x00000069 /**< 'i' */
K_J                      :: 0x0000006a /**< 'j' */
K_K                      :: 0x0000006b /**< 'k' */
K_L                      :: 0x0000006c /**< 'l' */
K_M                      :: 0x0000006d /**< 'm' */
K_N                      :: 0x0000006e /**< 'n' */
K_O                      :: 0x0000006f /**< 'o' */
K_P                      :: 0x00000070 /**< 'p' */
K_Q                      :: 0x00000071 /**< 'q' */
K_R                      :: 0x00000072 /**< 'r' */
K_S                      :: 0x00000073 /**< 's' */
K_T                      :: 0x00000074 /**< 't' */
K_U                      :: 0x00000075 /**< 'u' */
K_V                      :: 0x00000076 /**< 'v' */
K_W                      :: 0x00000077 /**< 'w' */
K_X                      :: 0x00000078 /**< 'x' */
K_Y                      :: 0x00000079 /**< 'y' */
K_Z                      :: 0x0000007a /**< 'z' */
K_LEFTBRACE              :: 0x0000007b /**< '{' */
K_PIPE                   :: 0x0000007c /**< '|' */
K_RIGHTBRACE             :: 0x0000007d /**< '}' */
K_TILDE                  :: 0x0000007e /**< '~' */
K_DELETE                 :: 0x0000007f /**< '\x7F' */
K_PLUSMINUS              :: 0x000000b1 /**< '\xB1' */
K_CAPSLOCK               :: 0x40000039 /**< SCANCODE_TO_KEYCODE(.CAPSLOCK) */
K_F1                     :: 0x4000003a /**< SCANCODE_TO_KEYCODE(.F1) */
K_F2                     :: 0x4000003b /**< SCANCODE_TO_KEYCODE(.F2) */
K_F3                     :: 0x4000003c /**< SCANCODE_TO_KEYCODE(.F3) */
K_F4                     :: 0x4000003d /**< SCANCODE_TO_KEYCODE(.F4) */
K_F5                     :: 0x4000003e /**< SCANCODE_TO_KEYCODE(.F5) */
K_F6                     :: 0x4000003f /**< SCANCODE_TO_KEYCODE(.F6) */
K_F7                     :: 0x40000040 /**< SCANCODE_TO_KEYCODE(.F7) */
K_F8                     :: 0x40000041 /**< SCANCODE_TO_KEYCODE(.F8) */
K_F9                     :: 0x40000042 /**< SCANCODE_TO_KEYCODE(.F9) */
K_F10                    :: 0x40000043 /**< SCANCODE_TO_KEYCODE(.F10) */
K_F11                    :: 0x40000044 /**< SCANCODE_TO_KEYCODE(.F11) */
K_F12                    :: 0x40000045 /**< SCANCODE_TO_KEYCODE(.F12) */
K_PRINTSCREEN            :: 0x40000046 /**< SCANCODE_TO_KEYCODE(.PRINTSCREEN) */
K_SCROLLLOCK             :: 0x40000047 /**< SCANCODE_TO_KEYCODE(.SCROLLLOCK) */
K_PAUSE                  :: 0x40000048 /**< SCANCODE_TO_KEYCODE(.PAUSE) */
K_INSERT                 :: 0x40000049 /**< SCANCODE_TO_KEYCODE(.INSERT) */
K_HOME                   :: 0x4000004a /**< SCANCODE_TO_KEYCODE(.HOME) */
K_PAGEUP                 :: 0x4000004b /**< SCANCODE_TO_KEYCODE(.PAGEUP) */
K_END                    :: 0x4000004d /**< SCANCODE_TO_KEYCODE(.END) */
K_PAGEDOWN               :: 0x4000004e /**< SCANCODE_TO_KEYCODE(.PAGEDOWN) */
K_RIGHT                  :: 0x4000004f /**< SCANCODE_TO_KEYCODE(.RIGHT) */
K_LEFT                   :: 0x40000050 /**< SCANCODE_TO_KEYCODE(.LEFT) */
K_DOWN                   :: 0x40000051 /**< SCANCODE_TO_KEYCODE(.DOWN) */
K_UP                     :: 0x40000052 /**< SCANCODE_TO_KEYCODE(.UP) */
K_NUMLOCKCLEAR           :: 0x40000053 /**< SCANCODE_TO_KEYCODE(.NUMLOCKCLEAR) */
K_KP_DIVIDE              :: 0x40000054 /**< SCANCODE_TO_KEYCODE(.KP_DIVIDE) */
K_KP_MULTIPLY            :: 0x40000055 /**< SCANCODE_TO_KEYCODE(.KP_MULTIPLY) */
K_KP_MINUS               :: 0x40000056 /**< SCANCODE_TO_KEYCODE(.KP_MINUS) */
K_KP_PLUS                :: 0x40000057 /**< SCANCODE_TO_KEYCODE(.KP_PLUS) */
K_KP_ENTER               :: 0x40000058 /**< SCANCODE_TO_KEYCODE(.KP_ENTER) */
K_KP_1                   :: 0x40000059 /**< SCANCODE_TO_KEYCODE(.KP_1) */
K_KP_2                   :: 0x4000005a /**< SCANCODE_TO_KEYCODE(.KP_2) */
K_KP_3                   :: 0x4000005b /**< SCANCODE_TO_KEYCODE(.KP_3) */
K_KP_4                   :: 0x4000005c /**< SCANCODE_TO_KEYCODE(.KP_4) */
K_KP_5                   :: 0x4000005d /**< SCANCODE_TO_KEYCODE(.KP_5) */
K_KP_6                   :: 0x4000005e /**< SCANCODE_TO_KEYCODE(.KP_6) */
K_KP_7                   :: 0x4000005f /**< SCANCODE_TO_KEYCODE(.KP_7) */
K_KP_8                   :: 0x40000060 /**< SCANCODE_TO_KEYCODE(.KP_8) */
K_KP_9                   :: 0x40000061 /**< SCANCODE_TO_KEYCODE(.KP_9) */
K_KP_0                   :: 0x40000062 /**< SCANCODE_TO_KEYCODE(.KP_0) */
K_KP_PERIOD              :: 0x40000063 /**< SCANCODE_TO_KEYCODE(.KP_PERIOD) */
K_APPLICATION            :: 0x40000065 /**< SCANCODE_TO_KEYCODE(.APPLICATION) */
K_POWER                  :: 0x40000066 /**< SCANCODE_TO_KEYCODE(.POWER) */
K_KP_EQUALS              :: 0x40000067 /**< SCANCODE_TO_KEYCODE(.KP_EQUALS) */
K_F13                    :: 0x40000068 /**< SCANCODE_TO_KEYCODE(.F13) */
K_F14                    :: 0x40000069 /**< SCANCODE_TO_KEYCODE(.F14) */
K_F15                    :: 0x4000006a /**< SCANCODE_TO_KEYCODE(.F15) */
K_F16                    :: 0x4000006b /**< SCANCODE_TO_KEYCODE(.F16) */
K_F17                    :: 0x4000006c /**< SCANCODE_TO_KEYCODE(.F17) */
K_F18                    :: 0x4000006d /**< SCANCODE_TO_KEYCODE(.F18) */
K_F19                    :: 0x4000006e /**< SCANCODE_TO_KEYCODE(.F19) */
K_F20                    :: 0x4000006f /**< SCANCODE_TO_KEYCODE(.F20) */
K_F21                    :: 0x40000070 /**< SCANCODE_TO_KEYCODE(.F21) */
K_F22                    :: 0x40000071 /**< SCANCODE_TO_KEYCODE(.F22) */
K_F23                    :: 0x40000072 /**< SCANCODE_TO_KEYCODE(.F23) */
K_F24                    :: 0x40000073 /**< SCANCODE_TO_KEYCODE(.F24) */
K_EXECUTE                :: 0x40000074 /**< SCANCODE_TO_KEYCODE(.EXECUTE) */
K_HELP                   :: 0x40000075 /**< SCANCODE_TO_KEYCODE(.HELP) */
K_MENU                   :: 0x40000076 /**< SCANCODE_TO_KEYCODE(.MENU) */
K_SELECT                 :: 0x40000077 /**< SCANCODE_TO_KEYCODE(.SELECT) */
K_STOP                   :: 0x40000078 /**< SCANCODE_TO_KEYCODE(.STOP) */
K_AGAIN                  :: 0x40000079 /**< SCANCODE_TO_KEYCODE(.AGAIN) */
K_UNDO                   :: 0x4000007a /**< SCANCODE_TO_KEYCODE(.UNDO) */
K_CUT                    :: 0x4000007b /**< SCANCODE_TO_KEYCODE(.CUT) */
K_COPY                   :: 0x4000007c /**< SCANCODE_TO_KEYCODE(.COPY) */
K_PASTE                  :: 0x4000007d /**< SCANCODE_TO_KEYCODE(.PASTE) */
K_FIND                   :: 0x4000007e /**< SCANCODE_TO_KEYCODE(.FIND) */
K_MUTE                   :: 0x4000007f /**< SCANCODE_TO_KEYCODE(.MUTE) */
K_VOLUMEUP               :: 0x40000080 /**< SCANCODE_TO_KEYCODE(.VOLUMEUP) */
K_VOLUMEDOWN             :: 0x40000081 /**< SCANCODE_TO_KEYCODE(.VOLUMEDOWN) */
K_KP_COMMA               :: 0x40000085 /**< SCANCODE_TO_KEYCODE(.KP_COMMA) */
K_KP_EQUALSAS400         :: 0x40000086 /**< SCANCODE_TO_KEYCODE(.KP_EQUALSAS400) */
K_ALTERASE               :: 0x40000099 /**< SCANCODE_TO_KEYCODE(.ALTERASE) */
K_SYSREQ                 :: 0x4000009a /**< SCANCODE_TO_KEYCODE(.SYSREQ) */
K_CANCEL                 :: 0x4000009b /**< SCANCODE_TO_KEYCODE(.CANCEL) */
K_CLEAR                  :: 0x4000009c /**< SCANCODE_TO_KEYCODE(.CLEAR) */
K_PRIOR                  :: 0x4000009d /**< SCANCODE_TO_KEYCODE(.PRIOR) */
K_RETURN2                :: 0x4000009e /**< SCANCODE_TO_KEYCODE(.RETURN2) */
K_SEPARATOR              :: 0x4000009f /**< SCANCODE_TO_KEYCODE(.SEPARATOR) */
K_OUT                    :: 0x400000a0 /**< SCANCODE_TO_KEYCODE(.OUT) */
K_OPER                   :: 0x400000a1 /**< SCANCODE_TO_KEYCODE(.OPER) */
K_CLEARAGAIN             :: 0x400000a2 /**< SCANCODE_TO_KEYCODE(.CLEARAGAIN) */
K_CRSEL                  :: 0x400000a3 /**< SCANCODE_TO_KEYCODE(.CRSEL) */
K_EXSEL                  :: 0x400000a4 /**< SCANCODE_TO_KEYCODE(.EXSEL) */
K_KP_00                  :: 0x400000b0 /**< SCANCODE_TO_KEYCODE(.KP_00) */
K_KP_000                 :: 0x400000b1 /**< SCANCODE_TO_KEYCODE(.KP_000) */
K_THOUSANDSSEPARATOR     :: 0x400000b2 /**< SCANCODE_TO_KEYCODE(.THOUSANDSSEPARATOR) */
K_DECIMALSEPARATOR       :: 0x400000b3 /**< SCANCODE_TO_KEYCODE(.DECIMALSEPARATOR) */
K_CURRENCYUNIT           :: 0x400000b4 /**< SCANCODE_TO_KEYCODE(.CURRENCYUNIT) */
K_CURRENCYSUBUNIT        :: 0x400000b5 /**< SCANCODE_TO_KEYCODE(.CURRENCYSUBUNIT) */
K_KP_LEFTPAREN           :: 0x400000b6 /**< SCANCODE_TO_KEYCODE(.KP_LEFTPAREN) */
K_KP_RIGHTPAREN          :: 0x400000b7 /**< SCANCODE_TO_KEYCODE(.KP_RIGHTPAREN) */
K_KP_LEFTBRACE           :: 0x400000b8 /**< SCANCODE_TO_KEYCODE(.KP_LEFTBRACE) */
K_KP_RIGHTBRACE          :: 0x400000b9 /**< SCANCODE_TO_KEYCODE(.KP_RIGHTBRACE) */
K_KP_TAB                 :: 0x400000ba /**< SCANCODE_TO_KEYCODE(.KP_TAB) */
K_KP_BACKSPACE           :: 0x400000bb /**< SCANCODE_TO_KEYCODE(.KP_BACKSPACE) */
K_KP_A                   :: 0x400000bc /**< SCANCODE_TO_KEYCODE(.KP_A) */
K_KP_B                   :: 0x400000bd /**< SCANCODE_TO_KEYCODE(.KP_B) */
K_KP_C                   :: 0x400000be /**< SCANCODE_TO_KEYCODE(.KP_C) */
K_KP_D                   :: 0x400000bf /**< SCANCODE_TO_KEYCODE(.KP_D) */
K_KP_E                   :: 0x400000c0 /**< SCANCODE_TO_KEYCODE(.KP_E) */
K_KP_F                   :: 0x400000c1 /**< SCANCODE_TO_KEYCODE(.KP_F) */
K_KP_XOR                 :: 0x400000c2 /**< SCANCODE_TO_KEYCODE(.KP_XOR) */
K_KP_POWER               :: 0x400000c3 /**< SCANCODE_TO_KEYCODE(.KP_POWER) */
K_KP_PERCENT             :: 0x400000c4 /**< SCANCODE_TO_KEYCODE(.KP_PERCENT) */
K_KP_LESS                :: 0x400000c5 /**< SCANCODE_TO_KEYCODE(.KP_LESS) */
K_KP_GREATER             :: 0x400000c6 /**< SCANCODE_TO_KEYCODE(.KP_GREATER) */
K_KP_AMPERSAND           :: 0x400000c7 /**< SCANCODE_TO_KEYCODE(.KP_AMPERSAND) */
K_KP_DBLAMPERSAND        :: 0x400000c8 /**< SCANCODE_TO_KEYCODE(.KP_DBLAMPERSAND) */
K_KP_VERTICALBAR         :: 0x400000c9 /**< SCANCODE_TO_KEYCODE(.KP_VERTICALBAR) */
K_KP_DBLVERTICALBAR      :: 0x400000ca /**< SCANCODE_TO_KEYCODE(.KP_DBLVERTICALBAR) */
K_KP_COLON               :: 0x400000cb /**< SCANCODE_TO_KEYCODE(.KP_COLON) */
K_KP_HASH                :: 0x400000cc /**< SCANCODE_TO_KEYCODE(.KP_HASH) */
K_KP_SPACE               :: 0x400000cd /**< SCANCODE_TO_KEYCODE(.KP_SPACE) */
K_KP_AT                  :: 0x400000ce /**< SCANCODE_TO_KEYCODE(.KP_AT) */
K_KP_EXCLAM              :: 0x400000cf /**< SCANCODE_TO_KEYCODE(.KP_EXCLAM) */
K_KP_MEMSTORE            :: 0x400000d0 /**< SCANCODE_TO_KEYCODE(.KP_MEMSTORE) */
K_KP_MEMRECALL           :: 0x400000d1 /**< SCANCODE_TO_KEYCODE(.KP_MEMRECALL) */
K_KP_MEMCLEAR            :: 0x400000d2 /**< SCANCODE_TO_KEYCODE(.KP_MEMCLEAR) */
K_KP_MEMADD              :: 0x400000d3 /**< SCANCODE_TO_KEYCODE(.KP_MEMADD) */
K_KP_MEMSUBTRACT         :: 0x400000d4 /**< SCANCODE_TO_KEYCODE(.KP_MEMSUBTRACT) */
K_KP_MEMMULTIPLY         :: 0x400000d5 /**< SCANCODE_TO_KEYCODE(.KP_MEMMULTIPLY) */
K_KP_MEMDIVIDE           :: 0x400000d6 /**< SCANCODE_TO_KEYCODE(.KP_MEMDIVIDE) */
K_KP_PLUSMINUS           :: 0x400000d7 /**< SCANCODE_TO_KEYCODE(.KP_PLUSMINUS) */
K_KP_CLEAR               :: 0x400000d8 /**< SCANCODE_TO_KEYCODE(.KP_CLEAR) */
K_KP_CLEARENTRY          :: 0x400000d9 /**< SCANCODE_TO_KEYCODE(.KP_CLEARENTRY) */
K_KP_BINARY              :: 0x400000da /**< SCANCODE_TO_KEYCODE(.KP_BINARY) */
K_KP_OCTAL               :: 0x400000db /**< SCANCODE_TO_KEYCODE(.KP_OCTAL) */
K_KP_DECIMAL             :: 0x400000dc /**< SCANCODE_TO_KEYCODE(.KP_DECIMAL) */
K_KP_HEXADECIMAL         :: 0x400000dd /**< SCANCODE_TO_KEYCODE(.KP_HEXADECIMAL) */
K_LCTRL                  :: 0x400000e0 /**< SCANCODE_TO_KEYCODE(.LCTRL) */
K_LSHIFT                 :: 0x400000e1 /**< SCANCODE_TO_KEYCODE(.LSHIFT) */
K_LALT                   :: 0x400000e2 /**< SCANCODE_TO_KEYCODE(.LALT) */
K_LGUI                   :: 0x400000e3 /**< SCANCODE_TO_KEYCODE(.LGUI) */
K_RCTRL                  :: 0x400000e4 /**< SCANCODE_TO_KEYCODE(.RCTRL) */
K_RSHIFT                 :: 0x400000e5 /**< SCANCODE_TO_KEYCODE(.RSHIFT) */
K_RALT                   :: 0x400000e6 /**< SCANCODE_TO_KEYCODE(.RALT) */
K_RGUI                   :: 0x400000e7 /**< SCANCODE_TO_KEYCODE(.RGUI) */
K_MODE                   :: 0x40000101 /**< SCANCODE_TO_KEYCODE(.MODE) */
K_SLEEP                  :: 0x40000102 /**< SCANCODE_TO_KEYCODE(.SLEEP) */
K_WAKE                   :: 0x40000103 /**< SCANCODE_TO_KEYCODE(.WAKE) */
K_CHANNEL_INCREMENT      :: 0x40000104 /**< SCANCODE_TO_KEYCODE(.CHANNEL_INCREMENT) */
K_CHANNEL_DECREMENT      :: 0x40000105 /**< SCANCODE_TO_KEYCODE(.CHANNEL_DECREMENT) */
K_MEDIA_PLAY             :: 0x40000106 /**< SCANCODE_TO_KEYCODE(.MEDIA_PLAY) */
K_MEDIA_PAUSE            :: 0x40000107 /**< SCANCODE_TO_KEYCODE(.MEDIA_PAUSE) */
K_MEDIA_RECORD           :: 0x40000108 /**< SCANCODE_TO_KEYCODE(.MEDIA_RECORD) */
K_MEDIA_FAST_FORWARD     :: 0x40000109 /**< SCANCODE_TO_KEYCODE(.MEDIA_FAST_FORWARD) */
K_MEDIA_REWIND           :: 0x4000010a /**< SCANCODE_TO_KEYCODE(.MEDIA_REWIND) */
K_MEDIA_NEXT_TRACK       :: 0x4000010b /**< SCANCODE_TO_KEYCODE(.MEDIA_NEXT_TRACK) */
K_MEDIA_PREVIOUS_TRACK   :: 0x4000010c /**< SCANCODE_TO_KEYCODE(.MEDIA_PREVIOUS_TRACK) */
K_MEDIA_STOP             :: 0x4000010d /**< SCANCODE_TO_KEYCODE(.MEDIA_STOP) */
K_MEDIA_EJECT            :: 0x4000010e /**< SCANCODE_TO_KEYCODE(.MEDIA_EJECT) */
K_MEDIA_PLAY_PAUSE       :: 0x4000010f /**< SCANCODE_TO_KEYCODE(.MEDIA_PLAY_PAUSE) */
K_MEDIA_SELECT           :: 0x40000110 /**< SCANCODE_TO_KEYCODE(.MEDIA_SELECT) */
K_AC_NEW                 :: 0x40000111 /**< SCANCODE_TO_KEYCODE(.AC_NEW) */
K_AC_OPEN                :: 0x40000112 /**< SCANCODE_TO_KEYCODE(.AC_OPEN) */
K_AC_CLOSE               :: 0x40000113 /**< SCANCODE_TO_KEYCODE(.AC_CLOSE) */
K_AC_EXIT                :: 0x40000114 /**< SCANCODE_TO_KEYCODE(.AC_EXIT) */
K_AC_SAVE                :: 0x40000115 /**< SCANCODE_TO_KEYCODE(.AC_SAVE) */
K_AC_PRINT               :: 0x40000116 /**< SCANCODE_TO_KEYCODE(.AC_PRINT) */
K_AC_PROPERTIES          :: 0x40000117 /**< SCANCODE_TO_KEYCODE(.AC_PROPERTIES) */
K_AC_SEARCH              :: 0x40000118 /**< SCANCODE_TO_KEYCODE(.AC_SEARCH) */
K_AC_HOME                :: 0x40000119 /**< SCANCODE_TO_KEYCODE(.AC_HOME) */
K_AC_BACK                :: 0x4000011a /**< SCANCODE_TO_KEYCODE(.AC_BACK) */
K_AC_FORWARD             :: 0x4000011b /**< SCANCODE_TO_KEYCODE(.AC_FORWARD) */
K_AC_STOP                :: 0x4000011c /**< SCANCODE_TO_KEYCODE(.AC_STOP) */
K_AC_REFRESH             :: 0x4000011d /**< SCANCODE_TO_KEYCODE(.AC_REFRESH) */
K_AC_BOOKMARKS           :: 0x4000011e /**< SCANCODE_TO_KEYCODE(.AC_BOOKMARKS) */
K_SOFTLEFT               :: 0x4000011f /**< SCANCODE_TO_KEYCODE(.SOFTLEFT) */
K_SOFTRIGHT              :: 0x40000120 /**< SCANCODE_TO_KEYCODE(.SOFTRIGHT) */
K_CALL                   :: 0x40000121 /**< SCANCODE_TO_KEYCODE(.CALL) */
K_ENDCALL                :: 0x40000122 /**< SCANCODE_TO_KEYCODE(.ENDCALL) */
K_LEFT_TAB               :: 0x20000001 /**< Extended key Left Tab */
K_LEVEL5_SHIFT           :: 0x20000002 /**< Extended key Level 5 Shift */
K_MULTI_KEY_COMPOSE      :: 0x20000003 /**< Extended key Multi-key Compose */
K_LMETA                  :: 0x20000004 /**< Extended key Left Meta */
K_RMETA                  :: 0x20000005 /**< Extended key Right Meta */
K_LHYPER                 :: 0x20000006 /**< Extended key Left Hyper */
K_RHYPER                 :: 0x20000007 /**< Extended key Right Hyper */


Keymod :: distinct bit_set[KeymodFlag; Uint16]
KeymodFlag :: enum Uint16 {
	LSHIFT = 0,  /**< the left Shift key is down. */
	RSHIFT = 1,  /**< the right Shift key is down. */
	LEVEL5 = 2,  /**< the Level 5 Shift key is down. */
	LCTRL  = 6,  /**< the left Ctrl (Control) key is down. */
	RCTRL  = 7,  /**< the right Ctrl (Control) key is down. */
	LALT   = 8,  /**< the left Alt key is down. */
	RALT   = 9,  /**< the right Alt key is down. */
	LGUI   = 10, /**< the left GUI key (often the Windows key) is down. */
	RGUI   = 11, /**< the right GUI key (often the Windows key) is down. */
	NUM    = 12, /**< the Num Lock key (may be located on an extended keypad) is down. */
	CAPS   = 13, /**< the Caps Lock key is down. */
	MODE   = 14, /**< the !AltGr key is down. */
	SCROLL = 15, /**< the Scroll Lock key is down. */
}



KMOD_NONE   :: Keymod{}                 /**< no modifier is applicable. */
KMOD_LSHIFT :: Keymod{.LSHIFT}          /**< the left Shift key is down. */
KMOD_RSHIFT :: Keymod{.RSHIFT}          /**< the right Shift key is down. */
KMOD_LEVEL5 :: Keymod{.LEVEL5}          /**< the Level 5 Shift key is down. */
KMOD_LCTRL  :: Keymod{.LCTRL}           /**< the left Ctrl (Control) key is down. */
KMOD_RCTRL  :: Keymod{.RCTRL}           /**< the right Ctrl (Control) key is down. */
KMOD_LALT   :: Keymod{.LALT}            /**< the left Alt key is down. */
KMOD_RALT   :: Keymod{.RALT}            /**< the right Alt key is down. */
KMOD_LGUI   :: Keymod{.LGUI}            /**< the left GUI key (often the Windows key) is down. */
KMOD_RGUI   :: Keymod{.RGUI}            /**< the right GUI key (often the Windows key) is down. */
KMOD_NUM    :: Keymod{.NUM}             /**< the Num Lock key (may be located on an extended keypad) is down. */
KMOD_CAPS   :: Keymod{.CAPS}            /**< the Caps Lock key is down. */
KMOD_MODE   :: Keymod{.MODE}            /**< the !AltGr key is down. */
KMOD_SCROLL :: Keymod{.SCROLL}          /**< the Scroll Lock key is down. */
KMOD_CTRL   :: Keymod{.LCTRL,  .RCTRL}  /**< Any Ctrl key is down. */
KMOD_SHIFT  :: Keymod{.LSHIFT, .RSHIFT} /**< Any Shift key is down. */
KMOD_ALT    :: Keymod{.LALT,   .RALT}   /**< Any Alt key is down. */
KMOD_GUI    :: Keymod{.LGUI,   .RGUI}   /**< Any GUI key is down. */