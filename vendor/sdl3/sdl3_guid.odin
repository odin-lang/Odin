package sdl3

import "core:c"

GUID :: struct {
	data: [16]Uint8,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GUIDToString :: proc(guid: GUID, pszGUID: [^]c.char, cbGUID: c.int) ---
	StringToGUID :: proc(pchGUID: cstring) -> GUID ---
}