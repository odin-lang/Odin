package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

MessageBoxFlag :: enum u32 {
	_ = 0,
	ERROR                 = 4,   /**< error dialog */
	WARNING               = 5,   /**< warning dialog */
	INFORMATION           = 6,   /**< informational dialog */
	BUTTONS_LEFT_TO_RIGHT = 7,   /**< buttons placed left to right */
	BUTTONS_RIGHT_TO_LEFT = 8,   /**< buttons placed right to left */
}


MessageBoxFlags :: distinct bit_set[MessageBoxFlag; u32]

MESSAGEBOX_ERROR                 :: MessageBoxFlags{.ERROR}
MESSAGEBOX_WARNING               :: MessageBoxFlags{.WARNING}
MESSAGEBOX_INFORMATION           :: MessageBoxFlags{.INFORMATION}
MESSAGEBOX_BUTTONS_LEFT_TO_RIGHT :: MessageBoxFlags{.BUTTONS_LEFT_TO_RIGHT}
MESSAGEBOX_BUTTONS_RIGHT_TO_LEFT :: MessageBoxFlags{.BUTTONS_RIGHT_TO_LEFT}

MessageBoxButtonFlag :: enum u32 {
	RETURNKEY_DEFAULT = 0,  /**< Marks the default button when return is hit */
	ESCAPEKEY_DEFAULT = 1,  /**< Marks the default button when escape is hit */
}
MessageBoxButtonFlags :: distinct bit_set[MessageBoxButtonFlag; u32]

MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT :: MessageBoxButtonFlags{.RETURNKEY_DEFAULT}
MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT :: MessageBoxButtonFlags{.ESCAPEKEY_DEFAULT}

MessageBoxButtonData :: struct {
	flags:    MessageBoxButtonFlags, /**< ::SDL_MessageBoxButtonFlags */
	buttonid: c.int,                 /**< User defined button id (value returned via SDL_ShowMessageBox) */
	text:     cstring,               /**< The UTF-8 button text */
}

MessageBoxColor :: struct {
	r, g, b: u8,
}

MessageBoxColorType :: enum c.int {
	BACKGROUND,
	TEXT,
	BUTTON_BORDER,
	BUTTON_BACKGROUND,
	BUTTON_SELECTED,
}

MessageBoxColorScheme :: struct {
	colors: [MessageBoxColorType]MessageBoxColor,
}

MessageBoxData :: struct {
	flags:  MessageBoxFlags, /**< ::SDL_MessageBoxFlags */
	window: ^Window,         /**< Parent window, can be NULL */
	title:   cstring,        /**< UTF-8 title */
	message: cstring,        /**< UTF-8 message text */

	numbuttons: c.int,
	buttons:    ^MessageBoxButtonData,

	colorScheme: ^MessageBoxColorScheme,   /**< ::SDL_MessageBoxColorScheme, can be NULL to use system settings */
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	ShowMessageBox       :: proc(messageboxdata: ^MessageBoxData, buttonid: ^c.int) -> c.int ---
	ShowSimpleMessageBox :: proc(flags: MessageBoxFlags, title: cstring, message: cstring, window: ^Window) -> c.int ---
}
