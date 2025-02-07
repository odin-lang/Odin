package sdl3

import "core:c"

typedef int (SDLCALL *SDL_main_func)(int argc, char *argv[]);

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	AppInit               :: proc(appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> AppResult ---
	AppIterate            :: proc(appstate: rawptr) -> AppResult ---
	AppEvent              :: proc(appstate: rawptr, event: ^Event) -> AppResult ---
	AppQuit               :: proc(appstate: rawptr, SDL_AppResult result) ---
	main                  :: proc(argc: c.int, argv: [^]cstring) -> c.int ---
	SetMainReady          :: proc() ---
	RunApp                :: proc(argc: c.int, argv: [^]cstring, mainFunction: main_func, reserved: rawptr) -> c,int ---
	EnterAppMainCallbacks :: proc(argc: c.int, argv: [^]cstring, appinit: AppInit_func, appiter: AppIterate_func, appevent: AppEvent_func, appquit: AppQuit_func) -> c.int ---
	RegisterApp           :: proc(name: cstring, Uint32 style, hInst: rawptr) -> bool ---
	UnregisterApp         :: proc() ---
	GDKSuspendComplete    :: proc() ---

}