package sdl3

import "core:c"

DialogFileFilter :: struct {
	name:    cstring,
	pattern: cstring,
}

FileDialogType :: enum c.int {
	OPENFILE,
	SAVEFILE,
	OPENFOLDER,
}

DialogFileCallback :: #type proc "c" (userdata: rawptr, filelist: [^]cstring, filter: c.int)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	ShowOpenFileDialog           :: proc(callback: DialogFileCallback, userdata: rawptr, window: ^Window, filters: [^]DialogFileFilter, nfilters: c.int, default_location: cstring, allow_many: bool) ---
	ShowSaveFileDialog           :: proc(callback: DialogFileCallback, userdata: rawptr, window: ^Window, filters: [^]DialogFileFilter, nfilters: c.int, default_location: cstring) ---
	ShowOpenFolderDialog         :: proc(callback: DialogFileCallback, userdata: rawptr, window: ^Window, default_location: cstring, allow_many: bool) ---
	ShowFileDialogWithProperties :: proc(type: FileDialogType, callback: DialogFileCallback, userdata: rawptr, props: PropertiesID) ---
}

PROP_FILE_DIALOG_FILTERS_POINTER :: "SDL.filedialog.filters"
PROP_FILE_DIALOG_NFILTERS_NUMBER :: "SDL.filedialog.nfilters"
PROP_FILE_DIALOG_WINDOW_POINTER  :: "SDL.filedialog.window"
PROP_FILE_DIALOG_LOCATION_STRING :: "SDL.filedialog.location"
PROP_FILE_DIALOG_MANY_BOOLEAN    :: "SDL.filedialog.many"
PROP_FILE_DIALOG_TITLE_STRING    :: "SDL.filedialog.title"
PROP_FILE_DIALOG_ACCEPT_STRING   :: "SDL.filedialog.accept"
PROP_FILE_DIALOG_CANCEL_STRING   :: "SDL.filedialog.cancel"
