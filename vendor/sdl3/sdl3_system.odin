package sdl3

import "core:c"

// Windows

import win32 "core:sys/windows"

WindowsMessageHook :: #type proc(userdata: rawptr, msg: ^win32.MSG) -> bool

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetWindowsMessageHook    :: proc(callback: WindowsMessageHook, userdata: rawptr) ---
	GetDirect3D9AdapterIndex :: proc(displayID: DisplayID) -> c.int ---
	GetDXGIOutputInfo        :: proc(displayID: DisplayID, adapterIndex: ^c.int, outputIndex: ^c.int) -> bool ---
}

// UNIX

X11EventHook :: #type proc "c" (userdata: rawptr, xevent: rawptr /* ^xlib.XEvent */) -> bool

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetX11EventHook :: proc(callback: X11EventHook, userdata: rawptr) ---
}

// Linux

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetLinuxThreadPriority          :: proc(threadID: Sint64, priority: c.int)                        -> bool ---
	SetLinuxThreadPriorityAndPolicy :: proc(threadID: Sint64, sdlPriority: c.int, schedPolicy: c.int) -> bool ---
}

// iOS

iOSAnimationCallback :: #type proc "c" (userdata: rawptr)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetiOSAnimationCallback :: proc(window: ^Window, interval: c.int, callback: iOSAnimationCallback, callbackParam: rawptr) -> bool ---
	SetiOSEventPump         :: proc(enabled: bool) ---
}

// Android

RequestAndroidPermissionCallback :: #type proc "c" (userdata: rawptr, permission: cstring, granted: bool)


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetAndroidJNIEnv               :: proc() -> rawptr ---
	GetAndroidActivity             :: proc() -> rawptr ---
	GetAndroidSDKVersion           :: proc() -> c.int ---
	IsChromebook                   :: proc() -> bool ---
	IsDeXMode                      :: proc() -> bool ---
	SendAndroidBackButton          :: proc()  ---
	GetAndroidInternalStoragePath  :: proc() -> cstring ---
	GetAndroidExternalStorageState :: proc() -> Uint32 ---
	GetAndroidExternalStoragePath  :: proc() -> cstring ---
	GetAndroidCachePath            :: proc() -> cstring ---
	RequestAndroidPermission       :: proc(permission: cstring, cb: RequestAndroidPermissionCallback, userdata: rawptr) -> bool ---
	ShowAndroidToast               :: proc(message: cstring, duration: c.int, gravity: c.int, xoffset, yoffset: c.int) -> bool ---
	SendAndroidMessage             :: proc(command: Uint32, param: c.int) -> bool ---
}

// General

Sandbox :: enum c.int {
	NONE = 0,
	UNKNOWN_CONTAINER,
	FLATPAK,
	SNAP,
	MACOS,
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	IsTablet                                   :: proc() -> bool ---
	IsTV                                       :: proc() -> bool ---
	GetSandbox                                 :: proc() -> Sandbox ---
	OnApplicationWillTerminate                 :: proc() ---
	OnApplicationDidReceiveMemoryWarning       :: proc() ---
	OnApplicationWillEnterBackground           :: proc() ---
	OnApplicationDidEnterBackground            :: proc() ---
	OnApplicationWillEnterForeground           :: proc() ---
	OnApplicationDidEnterForeground            :: proc() ---
	OnApplicationDidChangeStatusBarOrientation :: proc() ---
}


// GDK

XTaskQueueHandle :: distinct rawptr
XUserHandle      :: distinct rawptr

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetGDKTaskQueue   :: proc(outTaskQueue: ^XTaskQueueHandle) -> bool ---
	GetGDKDefaultUser :: proc(outUserHandle: ^XUserHandle)     -> bool ---
}