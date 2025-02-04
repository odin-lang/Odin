package sdl3

import "core:c"

InitFlags :: distinct bit_set[InitFlag; Uint32]
InitFlag :: enum Uint32 {
	AUDIO     = 4,  /**< `SDL_INIT_AUDIO` implies `SDL_INIT_EVENTS` */
	VIDEO     = 5,  /**< `SDL_INIT_VIDEO` implies `SDL_INIT_EVENTS`, should be initialized on the main thread */
	JOYSTICK  = 9,  /**< `SDL_INIT_JOYSTICK` implies `SDL_INIT_EVENTS`, should be initialized on the same thread as SDL_INIT_VIDEO on Windows if you don't set SDL_HINT_JOYSTICK_THREAD */
	HAPTIC    = 12,
	GAMEPAD   = 13, /**< `SDL_INIT_GAMEPAD` implies `SDL_INIT_JOYSTICK` */
	EVENTS    = 14,
	SENSOR    = 15, /**< `SDL_INIT_SENSOR` implies `SDL_INIT_EVENTS` */
	CAMERA    = 16, /**< `SDL_INIT_CAMERA` implies `SDL_INIT_EVENTS` */
}

INIT_AUDIO     :: InitFlags{.AUDIO}
INIT_VIDEO     :: InitFlags{.VIDEO}
INIT_JOYSTICK  :: InitFlags{.JOYSTICK}
INIT_HAPTIC    :: InitFlags{.HAPTIC}
INIT_GAMEPAD   :: InitFlags{.GAMEPAD}
INIT_EVENTS    :: InitFlags{.EVENTS}
INIT_SENSOR    :: InitFlags{.SENSOR}
INIT_CAMERA    :: InitFlags{.CAMERA}

AppResult :: enum c.int {
	CONTINUE,   /**< Value that requests that the app continue from the main callbacks. */
	SUCCESS,    /**< Value that requests termination with success from the main callbacks. */
	FAILURE,     /**< Value that requests termination with error from the main callbacks. */
}

AppInit_func       :: #type proc "c" (appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> AppResult
AppIterate_func    :: #type proc "c" (appstate: rawptr) -> AppResult
AppEvent_func      :: #type proc "c" (appstate: rawptr, event: ^Event) -> AppResult
AppQuit_func       :: #type proc "c" (appstate: rawptr, result: AppResult)
MainThreadCallback :: #type proc "c" (userdata: rawptr)


PROP_APP_METADATA_NAME_STRING       :: "SDL.app.metadata.name"
PROP_APP_METADATA_VERSION_STRING    :: "SDL.app.metadata.version"
PROP_APP_METADATA_IDENTIFIER_STRING :: "SDL.app.metadata.identifier"
PROP_APP_METADATA_CREATOR_STRING    :: "SDL.app.metadata.creator"
PROP_APP_METADATA_COPYRIGHT_STRING  :: "SDL.app.metadata.copyright"
PROP_APP_METADATA_URL_STRING        :: "SDL.app.metadata.url"
PROP_APP_METADATA_TYPE_STRING       :: "SDL.app.metadata.type"

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	Init                   :: proc(flags: InitFlags) -> bool ---
	InitSubSystem          :: proc(flags: InitFlags) -> bool ---
	QuitSubSystem          :: proc(flags: InitFlags) ---
	WasInit                :: proc(flags: InitFlags) -> InitFlags ---
	Quit                   :: proc() ---
	IsMainThread           :: proc() -> bool ---
	RunOnMainThread        :: proc(callback: MainThreadCallback, userdata: rawptr, wait_complete: bool) -> bool ---
	SetAppMetadata         :: proc(appname, appversion, appidentifier: cstring) -> bool ---
	SetAppMetadataProperty :: proc(name: cstring, value: cstring) -> bool ---
	GetAppMetadataProperty :: proc(name: cstring) -> cstring ---
}