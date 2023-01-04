package objc_Foundation

import "core:intrinsics"

ActivationPolicy :: enum UInteger {
	Regular    = 0,
	Accessory  = 1,
	Prohibited = 2,
}

ApplicationTerminateReply :: enum UInteger {
	TerminateCancel = 0,
	TerminateNow = 1,
	TerminateLater = 2,
}

ApplicationPresentationOptionFlag :: enum UInteger {
	AutoHideDock = 0,
	HideDock = 1,
	AutoHideMenuBar = 2,
	HideMenuBar = 3,
	DisableAppleMenu = 4,
	DisableProcessSwitching = 5,
	DisableForceQuit = 6,
	DisableSessionTermination = 7,
	DisableHideApplication = 8,
	DisableMenuBarTransparency = 9,
	FullScreen = 10,
	AutoHideToolbar = 11,
	DisableCursorLocationAssistance = 12,
}
ApplicationPresentationOptions :: distinct bit_set[ApplicationPresentationOptionFlag; UInteger]
ApplicationPresentationOptionsDefault                         :: ApplicationPresentationOptions {}
ApplicationPresentationOptionsAutoHideDock                    :: ApplicationPresentationOptions {.AutoHideDock}
ApplicationPresentationOptionsHideDock                        :: ApplicationPresentationOptions {.HideDock}
ApplicationPresentationOptionsAutoHideMenuBar                 :: ApplicationPresentationOptions {.AutoHideMenuBar}
ApplicationPresentationOptionsHideMenuBar                     :: ApplicationPresentationOptions {.HideMenuBar}
ApplicationPresentationOptionsDisableAppleMenu                :: ApplicationPresentationOptions {.DisableAppleMenu}
ApplicationPresentationOptionsDisableProcessSwitching         :: ApplicationPresentationOptions {.DisableProcessSwitching}
ApplicationPresentationOptionsDisableForceQuit                :: ApplicationPresentationOptions {.DisableForceQuit}
ApplicationPresentationOptionsDisableSessionTermination       :: ApplicationPresentationOptions {.DisableSessionTermination}
ApplicationPresentationOptionsDisableHideApplication          :: ApplicationPresentationOptions {.DisableHideApplication}
ApplicationPresentationOptionsDisableMenuBarTransparency      :: ApplicationPresentationOptions {.DisableMenuBarTransparency}
ApplicationPresentationOptionsFullScreen                      :: ApplicationPresentationOptions {.FullScreen}
ApplicationPresentationOptionsAutoHideToolbar                 :: ApplicationPresentationOptions {.AutoHideToolbar}
ApplicationPresentationOptionsDisableCursorLocationAssistance :: ApplicationPresentationOptions {.DisableCursorLocationAssistance}

ApplicationDelegate :: struct {
	willFinishLaunching:                  proc "c" (self: ^ApplicationDelegate, notification: ^Notification),
	didFinishLaunching:                   proc "c" (self: ^ApplicationDelegate, notification: ^Notification),
	shouldTerminateAfterLastWindowClosed: proc "c" (self: ^ApplicationDelegate, sender: ^Application) -> BOOL,
	applicationShouldTerminate:           proc "c" (self: ^ApplicationDelegate, sender: ^Application) -> ApplicationTerminateReply,
	applicationWillTerminate:             proc "c" (self: ^ApplicationDelegate, notification: ^Notification),

	user_data: rawptr,
}

@(objc_class="NSApplication")
Application :: struct {using _: Object}

@(objc_type=Application, objc_name="sharedApplication", objc_is_class_method=true)
Application_sharedApplication :: proc() -> ^Application {
	return msgSend(^Application, Application, "sharedApplication")
}

@(objc_type=Application, objc_name="setDelegate")
Application_setDelegate :: proc(self: ^Application, delegate: ^ApplicationDelegate) {
	willFinishLaunching :: proc "c" (self: ^Value, _: SEL, notification: ^Notification) {
		del := (^ApplicationDelegate)(self->pointerValue())
		del->willFinishLaunching(notification)
	}
	didFinishLaunching :: proc "c" (self: ^Value, _: SEL, notification: ^Notification) {
		del := (^ApplicationDelegate)(self->pointerValue())
		del->didFinishLaunching(notification)
	}
	shouldTerminateAfterLastWindowClosed :: proc "c" (self: ^Value, _: SEL, application: ^Application) -> BOOL {
		del := (^ApplicationDelegate)(self->pointerValue())
		return del->shouldTerminateAfterLastWindowClosed(application)
	}
	applicationShouldTerminate :: proc "c" (self: ^Value, _: SEL, application: ^Application) -> ApplicationTerminateReply {
		del := (^ApplicationDelegate)(self->pointerValue())
		return del->applicationShouldTerminate(application)
	}
	applicationWillTerminate :: proc "c" (self: ^Value, _: SEL, notification: ^Notification) {
		del := (^ApplicationDelegate)(self->pointerValue())
		del->applicationWillTerminate(notification)
	}

	wrapper := Value.valueWithPointer(delegate)

	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationWillFinishLaunching:"),                  auto_cast willFinishLaunching,                  "v@:@")
	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationDidFinishLaunching:"),                   auto_cast didFinishLaunching,                   "v@:@")
	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationShouldTerminateAfterLastWindowClosed:"), auto_cast shouldTerminateAfterLastWindowClosed, "B@:@")
	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationWillTerminate:"),                        auto_cast applicationWillTerminate, "v@:@")
	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationShouldTerminate:"),                      auto_cast applicationShouldTerminate, size_of(UInteger) == 4 ? "I@:@" : "Q@:@")

	msgSend(nil, self, "setDelegate:", wrapper)
}

@(objc_type=Application, objc_name="setActivationPolicy")
Application_setActivationPolicy :: proc(self: ^Application, activationPolicy: ActivationPolicy) -> BOOL {
	return msgSend(BOOL, self, "setActivationPolicy:", activationPolicy)
}

@(objc_type=Application, objc_name="activateIgnoringOtherApps")
Application_activateIgnoringOtherApps :: proc(self: ^Application, ignoreOtherApps: BOOL) {
	msgSend(nil, self, "activateIgnoringOtherApps:", ignoreOtherApps)
}

@(objc_type=Application, objc_name="setMainMenu")
Application_setMainMenu :: proc(self: ^Application, menu: ^Menu) {
	msgSend(nil, self, "setMainMenu:", menu)
}

@(objc_type=Application, objc_name="windows")
Application_windows :: proc(self: ^Application) -> ^Array {
	return msgSend(^Array, self, "windows")
}

@(objc_type=Application, objc_name="run")
Application_run :: proc(self: ^Application) {
	msgSend(nil, self, "run")
}


@(objc_type=Application, objc_name="terminate")
Application_terminate :: proc(self: ^Application, sender: ^Object) {
	msgSend(nil, self, "terminate:", sender)
}

@(objc_type=Application, objc_name="updateWindows")
Application_updateWindows :: proc(self: ^Application) {
	msgSend(nil, self, "updateWindows")
}

@(objc_type=Application, objc_name="nextEventMatchingMask")
Application_nextEventMatchingMask :: proc(self: ^Application, mask: EventMask, expiration: ^Date, mode: RunLoopMode, deque: BOOL) -> ^Event {
	return msgSend(^Event, self, "nextEventMatchingMask:untilDate:inMode:dequeue:", mask, expiration, mode, deque)
}

@(objc_type=Application, objc_name="sendEvent")
Application_sendEvent :: proc(self: ^Application, event: ^Event) {
	msgSend(nil, self, "sendEvent:", event)
}

@(objc_class="NSRunningApplication")
RunningApplication :: struct {using _: Object}

@(objc_type=RunningApplication, objc_name="currentApplication", objc_is_class_method=true)
RunningApplication_currentApplication :: proc() -> ^RunningApplication {
	return msgSend(^RunningApplication, RunningApplication, "currentApplication")
}

@(objc_type=RunningApplication, objc_name="localizedName")
RunningApplication_localizedName :: proc(self: ^RunningApplication) -> ^String {
	return msgSend(^String, self, "localizedName")
}