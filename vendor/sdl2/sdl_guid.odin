package sdl2

import "core:c"

GUID :: struct {
    data: [16]u8,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
    GUIDToString    :: proc(guid: GUID, pszGUID: cstring, cbGUID: c.int) ---
    GUIDFromString  :: proc(pchGUID: cstring) -> GUID ---
}