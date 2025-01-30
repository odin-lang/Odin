package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

Keysym :: struct {
	scancode: Scancode, /**< SDL physical key code - see ::SDL_Scancode for details */
	sym:      Keycode,  /**< SDL virtual key code - see ::SDL_Keycode for details */
	mod:      Keymod,   /**< current key modifiers */
	unused:   u32,
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetKeyboardFocus        :: proc() -> ^Window ---
	GetKeyboardState        :: proc(numkeys: ^c.int) -> [^]u8 ---
	GetKeyFromScancode      :: proc(scancode: Scancode) -> Keycode ---
	GetScancodeFromKey      :: proc(key: Keycode) -> Scancode ---
	GetScancodeName         :: proc(scancode: Scancode) -> cstring ---
	GetScancodeFromName     :: proc(name: cstring) -> Scancode ---
	GetKeyName              :: proc(key: Keycode) -> cstring ---
	GetKeyFromName          :: proc(name: cstring) -> Keycode ---
	StartTextInput          :: proc() ---
	IsTextInputActive       :: proc() -> bool ---
	StopTextInput           :: proc() ---
	SetTextInputRect        :: proc(rect: ^Rect) ---
	HasScreenKeyboardSupport:: proc() -> bool ---
	IsScreenKeyboardShown   :: proc(window: ^Window) -> bool ---
}

GetKeyboardStateAsSlice :: proc "c" () -> []u8 {
	numkeys: c.int
	keys := GetKeyboardState(&numkeys)
	if keys != nil {
		return keys[:numkeys]
	}
	return nil
}

GetModState :: #force_inline proc "c" () -> Keymod { return transmute(Keymod)u16(SDL_GetModState()) }
SetModState :: #force_inline proc "c" (modstate: Keymod) { SDL_SetModState(c.int(transmute(u16)modstate)) }

@(default_calling_convention="c")
@(private="file")
foreign lib {
	SDL_GetModState :: proc() -> c.int ---
	SDL_SetModState :: proc(modstate: c.int) ---
}

