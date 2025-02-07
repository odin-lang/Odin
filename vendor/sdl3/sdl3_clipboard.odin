package sdl3

ClipboardDataCallback    :: #type proc "c" (userdata: rawptr, mime_type: cstring, size: ^uint) -> rawptr
ClipboardCleanupCallback :: #type proc "c" (userdata: rawptr)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetClipboardText        :: proc(text: cstring) -> bool ---
	GetClipboardText        :: proc() -> [^]Uint8 ---
	HasClipboardText        :: proc() -> bool ---
	SetPrimarySelectionText :: proc(text: cstring) -> bool ---
	GetPrimarySelectionText :: proc() -> [^]Uint8 ---
	HasPrimarySelectionText :: proc() -> bool ---
	SetClipboardData        :: proc(callback: ClipboardDataCallback, cleanup: ClipboardCleanupCallback, userdata: rawptr, mime_types: [^]cstring, num_mime_types: uint) -> bool ---
	ClearClipboardData      :: proc() -> bool ---
	GetClipboardData        :: proc(mime_type: cstring, size: ^uint) -> rawptr ---
	HasClipboardData        :: proc(mime_type: cstring) -> bool ---
	GetClipboardMimeTypes   :: proc(num_mime_types: ^uint) -> [^][^]Uint8 ---
}