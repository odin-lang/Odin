package test

import      "core:fmt"
import refl "core:reflect"

main :: proc() {
    // This test recreates how I discovered the bug
    // I've copy-pasted some code from a project I'm working on

    // This will evaluate to false
    should_be_true := refl.enum_value_has_name(Scancode.NUM_LOCK)
    fmt.printfln("Should be true. Got %v.", should_be_true)
}

/*
Scancodes for Win32 keyboard input:
https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#scan-codes

Win32 scancodes are derived from PS/2 Set 1 scancodes.
Win32 scancodes are 2 bytes, but PS/2 Set 1 contains scancodes longer than 2 bytes.
Win32 invents its own 2 byte scancodes to replace these long scancodes.
(E.g. Print Screen is 0xE02AE037 in PS/2 Set 1, but is 0xE037 in Win32.)
Table of Win32 scancodes: https://learn.microsoft.com/en-us/windows/win32/inputdev/about-keyboard-input#scan-codes

⚠️ WARNING: Some keys sort of share the same scancode due to new and legacy scancode definitions.
For some reason, Microsoft uses different scancodes in the context of keyboard messages (WM_KEYDOWN, and everything else in this
list: https://learn.microsoft.com/en-us/windows/win32/inputdev/keyboard-input-notifications). I call these "legacy scancodes."
E.g. Num Lock's scancode is 0xE045 in the context of WM_KEYDOWN, but MapVirtualKeyW(VK_NUMLOCK) returns 0x45.
This causes multiple physical keys to share the same scancode.
E.g. Num Lock's new scancode is 0x45, but Pause's legacy scancode is also 0x45.
But so long as you strictly use new scancodes are strictly use legacy scancodes, no physical keys will share a scancode.
Thanks Microsoft... >:^(

⚠️ WARNING: There are still other edge cases: some physical keys have multiple scancodes, some scancodes are over 2 bytes, etc.
All such edge cases are commented next to the relevant enum value definitions.
Again, thanks Microsoft... >:^(
*/
Scancode :: enum u16 {
    POWER_DOWN = 0xE05E,
    SLEEP      = 0xE05F,
    WAKE_UP    = 0xE063,

    ERROR_ROLL_OVER = 0xFF,

    A  = 0x1E,
    B  = 0x30,
    C  = 0x2E,
    D  = 0x20,
    E  = 0x12,
    F  = 0x21,
    G  = 0x22,
    H  = 0x23,
    I  = 0x17,
    J  = 0x24,
    K  = 0x25,
    L  = 0x26,
    M  = 0x32,
    N  = 0x31,
    O  = 0x18,
    P  = 0x19,
    Q  = 0x10,
    R  = 0x13,
    S  = 0x1F,
    T  = 0x14,
    U  = 0x16,
    V  = 0x2F,
    W  = 0x11,
    X  = 0x2D,
    Y  = 0x15,
    Z  = 0x2C,
    _1 = 0x02,
    _2 = 0x03,
    _3 = 0x04,
    _4 = 0x05,
    _5 = 0x06,
    _6 = 0x07,
    _7 = 0x08,
    _8 = 0x09,
    _9 = 0x0A,
    _0 = 0x0B,

    ENTER         = 0x1C,
    ESCAPE        = 0x01,
    DELETE        = 0x0E,
    TAB           = 0x0F,
    SPACEBAR      = 0x39,
    MINUS         = 0x0C,
    EQUALS        = 0x0D,
    L_BRACE       = 0x1A,
    R_BRACE       = 0x1B,
    BACKSLASH     = 0x2B,
    NON_US_HASH   = 0x2B,
    SEMICOLON     = 0x27,
    APOSTROPHE    = 0x28,
    GRAVE_ACCENT  = 0x29,
    COMMA         = 0x33,
    PERIOD        = 0x34,
    FORWARD_SLASH = 0x35,
    CAPS_LOCK     = 0x3A,

    F1  = 0x3B,
    F2  = 0x3C,
    F3  = 0x3D,
    F4  = 0x3E,
    F5  = 0x3F,
    F6  = 0x40,
    F7  = 0x41,
    F8  = 0x42,
    F9  = 0x43,
    F10 = 0x44,
    F11 = 0x57,
    F12 = 0x58,

    // These are all the same physical key
    // Windows maps Print Screen and Sys Rq to system-level shortcuts, so by default, WM_KEYDOWN does not report Print Screen or Sys Rq
    PRINT_SCREEN        = 0xE037,
    PRINT_SCREEN_SYS_RQ = 0x54,   // Alt + PrintScreen

    SCROLL_LOCK = 0x46,

    // These are all the same physical key
    PAUSE        = 0xE11D, // NOT used by legacy keyboard messages
                           // Win32 scancodes are 2 bytes, the documentation says Pause's scancode is 0xE11D45, which is 3 bytes???
                           // MapVirtualKeyW(VK_PAUSE) returns 0xE11D, so we're just gonna use that
    PAUSE_BREAK  = 0xE046, // Ctrl + Pause
    PAUSE_LEGACY = 0x45,   // ONLY used by legacy keyboard messages

    INSERT         = 0xE052,
    HOME           = 0xE047,
    PAGE_UP        = 0xE049,
    DELETE_FORWARD = 0xE053,
    END            = 0xE04F,
    PAGE_DOWN      = 0xE051,
    RIGHT_ARROW    = 0xE04D,
    LEFT_ARROW     = 0xE04B,
    DOWN_ARROW     = 0xE050,
    UP_ARROW       = 0xE048,

    // These are all the same physical key
    NUM_LOCK        = 0x45,   // NOT used by legacy keyboard messages
    NUM_LOCK_LEGACY = 0xE045, // ONLY used by legacy keyboard messages

    KEYPAD_FORWARD_SLASH = 0xE035,
    KEYPAD_STAR          = 0x37,
    KEYPAD_DASH          = 0x4A,
    KEYPAD_PLUS          = 0x4E,
    KEYPAD_ENTER         = 0xE01C,
    KEYPAD_1             = 0x4F,
    KEYPAD_2             = 0x50,
    KEYPAD_3             = 0x51,
    KEYPAD_4             = 0x4B,
    KEYPAD_5             = 0x4C,
    KEYPAD_6             = 0x4D,
    KEYPAD_7             = 0x47,
    KEYPAD_8             = 0x48,
    KEYPAD_9             = 0x49,
    KEYPAD_0             = 0x52,
    KEYPAD_PERIOD        = 0x53,
    NON_US_BACKSLASH     = 0x56,
    APPLICATION          = 0xE05D,
    POWER                = 0xE05E,
    KEYPAD_EQUALS        = 0x59,

    F13 = 0x64,
    F14 = 0x65,
    F15 = 0x66,
    F16 = 0x67,
    F17 = 0x68,
    F18 = 0x69,
    F19 = 0x6A,
    F20 = 0x6B,
    F21 = 0x6C,
    F22 = 0x6D,
    F23 = 0x6E,
    F24 = 0x76,

    KEYPAD_COMMA    = 0x7E, // on Brazilian keyboards
    INTERNATIONAL_1 = 0x73, // on Brazilian and Japanese keyboards
    INTERNATIONAL_2 = 0x70, // on Japanese keyboards
    INTERNATIONAL_3 = 0x7D, // on Japanese keyboards
    INTERNATIONAL_4 = 0x79, // on Japanese keyboards
    INTERNATIONAL_5 = 0x7B, // on Japanese keyboards
    INTERNATIONAL_6 = 0x5C,

    // These are all the same physical key
    LANG_1        = 0x72, // key release event only, NOT used by legacy keyboard messages
    LANG_1_LEGACY = 0xF2, // key release event only, ONLY used by legacy keyboard messages

    // These are all the same physical key
    LANG_2        = 0x71, // key release event only, NOT used by legacy keyboard messages
    LANG_2_LEGACY = 0xF1, // key release event only, ONLY used by legacy keyboard messages

    LANG3     = 0x78,
    LANG4     = 0x77,
    LANG5     = 0x76,
    L_CONTROL = 0x1D,
    L_SHIFT   = 0x2A,
    L_ALT     = 0x38,
    L_GUI     = 0xE05B,
    R_CONTROL = 0xE01D,
    R_SHIFT   = 0x36,
    R_ALT     = 0xE038,
    R_GUI     = 0xE05C,

    NEXT_TRACK       = 0xE019,
    PREVIOUS_TRACK   = 0xE010,
    STOP             = 0xE024,
    PLAY_PAUSE       = 0xE022,
    MUTE             = 0xE020,
    VOLUME_INCREMENT = 0xE030,
    VOLUME_DECREMENT = 0xE02E,

    // AL stands for "application launch"
    AL_CONSUMER_CONTROL_CONFIGURATION = 0xE06D,
    AL_EMAIL_READER                   = 0xE06C,
    AL_CALCULATOR                     = 0xE021,
    AL_LOCAL_MACHINE_BROWSER          = 0xE06B,

    // AC stands for "application control"
    AC_SEARCH    = 0xE065,
    AC_HOME      = 0xE032,
    AC_BACK      = 0xE06A,
    AC_FORWARD   = 0xE069,
    AC_STOP      = 0xE068,
    AC_REFRESH   = 0xE067,
    AC_BOOKMARKS = 0xE066,
}
