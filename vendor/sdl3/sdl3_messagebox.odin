package sdl3

import "core:c"

MessageBoxFlags :: distinct bit_set[MessageBoxFlag; Uint32]
MessageBoxFlag :: enum Uint32 {
	ERROR                 = 4, /**< error dialog */
	WARNING               = 5, /**< warning dialog */
	INFORMATION           = 6, /**< informational dialog */
	BUTTONS_LEFT_TO_RIGHT = 7, /**< buttons placed left to right */
	BUTTONS_RIGHT_TO_LEFT = 8, /**< buttons placed right to left */
}

MessageBoxButtonFlags :: distinct bit_set[MessageBoxButtonFlag; Uint32]
MessageBoxButtonFlag  :: enum Uint32 {
	RETURNKEY_DEFAULT = 0, /**< Marks the default button when return is hit */
	ESCAPEKEY_DEFAULT = 1, /**< Marks the default button when return is hit */
}

MessageBoxButtonData :: struct {
	flags:    MessageBoxButtonFlags,
	buttonID: c.int,     /**< User defined button id (value returned via SDL_ShowMessageBox) */
	text:     cstring,   /**< The UTF-8 button text */
}


MessageBoxColor :: distinct [3]Uint8

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
	flags:       MessageBoxFlags,
	window:      ^Window,                /**< Parent window, can be NULL */
	title:       cstring,                /**< UTF-8 title */
	message:     cstring,                /**< UTF-8 message text */

	numbuttons:  c.int,
	buttons:     [^]MessageBoxButtonData `fmt:"v,numbuttons"`,

	colorScheme: ^MessageBoxColorScheme, /**< MessageBoxColorScheme, can be NULL to use system settings */
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	ShowMessageBox       :: proc(#by_ptr messageboxdata: MessageBoxData, buttonid: ^c.int) -> bool ---
	ShowSimpleMessageBox :: proc(flags: MessageBoxFlags, title, message: cstring, window: ^Window) -> bool ---
}
