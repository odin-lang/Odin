package objc_Foundation

import "core:intrinsics"

ActivationPolicy :: enum UInteger {
	Regular    = 0,
	Accessory  = 1,
	Prohibited = 2,
}

ApplicationDelegate :: struct {
	willFinishLaunching:                  proc "c" (self: ^ApplicationDelegate, notification: ^Notification),
	didFinishLaunching:                   proc "c" (self: ^ApplicationDelegate, notification: ^Notification),
	shouldTerminateAfterLastWindowClosed: proc "c" (self: ^ApplicationDelegate, sender: ^Application),

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
	shouldTerminateAfterLastWindowClosed :: proc "c" (self: ^Value, _: SEL, application: ^Application) {
		del := (^ApplicationDelegate)(self->pointerValue())
		del->shouldTerminateAfterLastWindowClosed(application)
	}

	wrapper := Value.valueWithPointer(delegate)

	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationWillFinishLaunching:"),                  auto_cast willFinishLaunching,                  "v@:@")
	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationDidFinishLaunching:"),                   auto_cast didFinishLaunching,                   "v@:@")
	class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("applicationShouldTerminateAfterLastWindowClosed:"), auto_cast shouldTerminateAfterLastWindowClosed, "B@:@")

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