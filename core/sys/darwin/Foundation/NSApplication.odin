package objc_Foundation

foreign import "system:Foundation.framework"

import "base:intrinsics"
import "base:runtime"
import "core:strings"

RunLoopMode :: ^String

@(link_prefix="NS")
foreign Foundation {
	RunLoopCommonModes:       RunLoopMode
	DefaultRunLoopMode:       RunLoopMode
	EventTrackingRunLoopMode: RunLoopMode
	ModalPanelRunLoopMode:    RunLoopMode
}

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

ApplicationPrintReply :: enum UInteger {
	PrintingCancelled = 0,
	PrintingSuccess = 1,
	PrintingReplyLater = 2,
	PrintingFailure = 3,
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

@(objc_class="NSApplication")
Application :: struct {using _: Object}

@(objc_type=Application, objc_name="sharedApplication", objc_is_class_method=true)
Application_sharedApplication :: proc "c" () -> ^Application {
	return msgSend(^Application, Application, "sharedApplication")
}

@(objc_type=Application, objc_name="setActivationPolicy")
Application_setActivationPolicy :: proc "c" (self: ^Application, activationPolicy: ActivationPolicy) -> BOOL {
	return msgSend(BOOL, self, "setActivationPolicy:", activationPolicy)
}

@(deprecated="Use NSApplication method activate instead.")
@(objc_type=Application, objc_name="activateIgnoringOtherApps")
Application_activateIgnoringOtherApps :: proc "c" (self: ^Application, ignoreOtherApps: BOOL) {
	msgSend(nil, self, "activateIgnoringOtherApps:", ignoreOtherApps)
}

@(objc_type=Application, objc_name="activate")
Application_activate :: proc "c" (self: ^Application) {
	msgSend(nil, self, "activate")
}

@(objc_type=Application, objc_name="setTitle")
Application_setTitle :: proc "c" (self: ^Application, title: ^String) {
	msgSend(nil, self, "setTitle", title)
}

@(objc_type=Application, objc_name="setMainMenu")
Application_setMainMenu :: proc "c" (self: ^Application, menu: ^Menu) {
	msgSend(nil, self, "setMainMenu:", menu)
}

@(objc_type=Application, objc_name="windows")
Application_windows :: proc "c" (self: ^Application) -> ^Array {
	return msgSend(^Array, self, "windows")
}

@(objc_type=Application, objc_name="run")
Application_run :: proc "c" (self: ^Application) {
	msgSend(nil, self, "run")
}

@(objc_type=Application, objc_name="terminate")
Application_terminate :: proc "c" (self: ^Application, sender: ^Object) {
	msgSend(nil, self, "terminate:", sender)
}

@(objc_type=Application, objc_name="isRunning")
Application_isRunning :: proc "c" (self: ^Application) -> BOOL {
	return msgSend(BOOL, self, "isRunning")
}

@(objc_type=Application, objc_name="currentEvent")
Application_currentEvent :: proc "c" (self: ^Application) -> ^Event {
	return msgSend(^Event, self, "currentEvent")
}

@(objc_type=Application, objc_name="nextEventMatchingMask")
Application_nextEventMatchingMask :: proc "c" (self: ^Application, mask: EventMask, expiration: ^Date, in_mode: RunLoopMode, dequeue: BOOL) -> ^Event {
	return msgSend(^Event, self, "nextEventMatchingMask:untilDate:inMode:dequeue:", mask, expiration, in_mode, dequeue)
}

@(objc_type=Application, objc_name="sendEvent")
Application_sendEvent :: proc "c" (self: ^Application, event: ^Event) {
	msgSend(nil, self, "sendEvent:", event)
}
@(objc_type=Application, objc_name="updateWindows")
Application_updateWindows :: proc "c" (self: ^Application) {
	msgSend(nil, self, "updateWindows")
}


@(objc_class="NSRunningApplication")
RunningApplication :: struct {using _: Object}

@(objc_type=RunningApplication, objc_name="currentApplication", objc_is_class_method=true)
RunningApplication_currentApplication :: proc "c" () -> ^RunningApplication {
	return msgSend(^RunningApplication, RunningApplication, "currentApplication")
}

@(objc_type=RunningApplication, objc_name="localizedName")
RunningApplication_localizedName :: proc "c" (self: ^RunningApplication) -> ^String {
	return msgSend(^String, self, "localizedName")
}

ApplicationDelegateTemplate :: struct {
	// Launching Applications
	applicationWillFinishLaunching:                              proc(notification: ^Notification),
	applicationDidFinishLaunching:                               proc(notification: ^Notification),
	// Managing Active Status
	applicationWillBecomeActive:                                 proc(notification: ^Notification),
	applicationDidBecomeActive:                                  proc(notification: ^Notification),
	applicationWillResignActive:                                 proc(notification: ^Notification),
	applicationDidResignActive:                                  proc(notification: ^Notification),
	// Terminating Applications
	applicationShouldTerminate:                                  proc(sender: ^Application) -> ApplicationTerminateReply,
	applicationShouldTerminateAfterLastWindowClosed:             proc(sender: ^Application) -> BOOL,
	applicationWillTerminate:                                    proc(notification: ^Notification),
	// Hiding Applications
	applicationWillHide:                                         proc(notification: ^Notification),
	applicationDidHide:                                          proc(notification: ^Notification),
	applicationWillUnhide:                                       proc(notification: ^Notification),
	applicationDidUnhide:                                        proc(notification: ^Notification),
	// Managing Windows
	applicationWillUpdate:                                       proc(notification: ^Notification),
	applicationDidUpdate:                                        proc(notification: ^Notification),
	applicationShouldHandleReopenHasVisibleWindows:              proc(sender: ^Application, flag: BOOL) -> BOOL,
	// Managing the Dock Menu
	applicationDockMenu:                                         proc(sender: ^Application) -> ^Menu,
	// Localizing Keyboard Shortcuts
	applicationShouldAutomaticallyLocalizeKeyEquivalents:        proc(application: ^Application) -> BOOL,
	// Displaying Errors
	applicationWillPresentError:                                 proc(application: ^Application, error: ^Error) -> ^Error,
	// Managing the Screen
	applicationDidChangeScreenParameters:                        proc(notification: ^Notification),
	// Continuing User Activities
	applicationWillContinueUserActivityWithType:                 proc(application: ^Application, userActivityType: ^String) -> BOOL,
	applicationContinueUserActivityRestorationHandler:           proc(application: ^Application, userActivity: ^UserActivity, restorationHandler: ^Block) -> BOOL,
	applicationDidFailToContinueUserActivityWithTypeError:       proc(application: ^Application, userActivityType: ^String, error: ^Error),
	applicationDidUpdateUserActivity:                            proc(application: ^Application, userActivity: ^UserActivity),
	// Handling Push Notifications
	applicationDidRegisterForRemoteNotificationsWithDeviceToken: proc(application: ^Application, deviceToken: ^Data),
	applicationDidFailToRegisterForRemoteNotificationsWithError: proc(application: ^Application, error: ^Error),
	applicationDidReceiveRemoteNotification:                     proc(application: ^Application, userInfo: ^Dictionary),
	// Handling CloudKit Invitations
	// TODO: if/when we have cloud kit bindings implement
	// applicationUserDidAcceptCloudKitShareWithMetadata:        proc(application: ^Application, metadata: ^CKShareMetadata),
	// Handling SiriKit Intents
	// TODO: if/when we have siri kit bindings implement
	// applicationHandlerForIntent:                              proc(application: ^Application, intent: ^INIntent) -> id,
	// Opening Files
	applicationOpenURLs:                                         proc(application: ^Application, urls: ^Array),
	applicationOpenFile:                                         proc(sender: ^Application, filename: ^String) -> BOOL,
	applicationOpenFileWithoutUI:                                proc(sender: id, filename: ^String) -> BOOL,
	applicationOpenTempFile:                                     proc(sender: ^Application, filename: ^String) -> BOOL,
	applicationOpenFiles:                                        proc(sender: ^Application, filenames: ^Array),
	applicationShouldOpenUntitledFile:                           proc(sender: ^Application) -> BOOL,
	applicationOpenUntitledFile:                                 proc(sender: ^Application) -> BOOL,
	// Printing
	applicationPrintFile:                                        proc(sender: ^Application, filename: ^String) -> BOOL,
	applicationPrintFilesWithSettingsShowPrintPanels:            proc(application: ^Application, fileNames: ^Array, printSettings: ^Dictionary, showPrintPanels: BOOL) -> ApplicationPrintReply,
	// Restoring Application State
	applicationSupportsSecureRestorableState:                    proc(app: ^Application) -> BOOL,
	applicationProtectedDataDidBecomeAvailable:                  proc(notification: ^Notification),
	applicationProtectedDataWillBecomeUnavailable:               proc(notification: ^Notification),
	applicationWillEncodeRestorableState:                        proc(app: ^Application, coder: ^Coder),
	applicationDidDecodeRestorableState:                         proc(app: ^Application, coder: ^Coder),
	// Handling Changes to the Occlusion State
	applicationDidChangeOcclusionState:                          proc(notification: ^Notification),
	// Scripting Your App
	applicationDelegateHandlesKey:                               proc(sender: ^Application, key: ^String) -> BOOL,
}

ApplicationDelegate :: struct { using _: Object }
_ApplicationDelegateInternal :: struct {
	using _: ApplicationDelegateTemplate,
	_context: runtime.Context,
}

application_delegate_register_and_alloc :: proc(template: ApplicationDelegateTemplate, class_name: string, delegate_context: Maybe(runtime.Context)) -> ^ApplicationDelegate {
	class := objc_allocateClassPair(intrinsics.objc_find_class("NSObject"), strings.clone_to_cstring(class_name, context.temp_allocator), 0); if class == nil {
		// Class already registered
		return nil
	}
	if template.applicationWillFinishLaunching != nil {
		applicationWillFinishLaunching :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillFinishLaunching(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillFinishLaunching:"), auto_cast applicationWillFinishLaunching, "v@:@")
	}
	if template.applicationDidFinishLaunching != nil {
		applicationDidFinishLaunching :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidFinishLaunching(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidFinishLaunching:"), auto_cast applicationDidFinishLaunching, "v@:@")
	}
	if template.applicationWillBecomeActive != nil {
		applicationWillBecomeActive :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillBecomeActive(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillBecomeActive:"), auto_cast applicationWillBecomeActive, "v@:@")
	}
	if template.applicationDidBecomeActive != nil {
		applicationDidBecomeActive :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidBecomeActive(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidBecomeActive:"), auto_cast applicationDidBecomeActive, "v@:@")
	}
	if template.applicationWillResignActive != nil {
		applicationWillResignActive :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillResignActive(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillResignActive:"), auto_cast applicationWillResignActive, "v@:@")
	}
	if template.applicationDidResignActive != nil {
		applicationDidResignActive :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidResignActive(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidResignActive:"), auto_cast applicationDidResignActive, "v@:@")
	}
	if template.applicationShouldTerminate != nil {
		applicationShouldTerminate :: proc "c" (self: id, sender: ^Application) -> ApplicationTerminateReply {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldTerminate(sender)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationShouldTerminate:"), auto_cast applicationShouldTerminate, _UINTEGER_ENCODING+"@:@")
	}
	if template.applicationShouldTerminateAfterLastWindowClosed != nil {
		applicationShouldTerminateAfterLastWindowClosed :: proc "c" (self: id, sender: ^Application) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldTerminateAfterLastWindowClosed(sender)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationShouldTerminateAfterLastWindowClosed:"), auto_cast applicationShouldTerminateAfterLastWindowClosed, "B@:@")
	}
	if template.applicationWillTerminate != nil {
		applicationWillTerminate :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillTerminate(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillTerminate:"), auto_cast applicationWillTerminate, "v@:@")
	}
	if template.applicationWillHide != nil {
		applicationWillHide :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillHide(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillHide:"), auto_cast applicationWillHide, "v@:@")
	}
	if template.applicationDidHide != nil {
		applicationDidHide :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidHide(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidHide:"), auto_cast applicationDidHide, "v@:@")
	}
	if template.applicationWillUnhide != nil {
		applicationWillUnhide :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillUnhide(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillUnhide:"), auto_cast applicationWillUnhide, "v@:@")
	}
	if template.applicationDidUnhide != nil {
		applicationDidUnhide :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidUnhide(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidUnhide:"), auto_cast applicationDidUnhide, "v@:@")
	}
	if template.applicationWillUpdate != nil {
		applicationWillUpdate :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillUpdate(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationWillUpdate:"), auto_cast applicationWillUpdate, "v@:@")
	}
	if template.applicationDidUpdate != nil {
		applicationDidUpdate :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidUpdate(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidUpdate:"), auto_cast applicationDidUpdate, "v@:@")
	}
	if template.applicationShouldHandleReopenHasVisibleWindows != nil {
		applicationShouldHandleReopenHasVisibleWindows :: proc "c" (self: id, sender: ^Application, flag: BOOL) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldHandleReopenHasVisibleWindows(sender, flag)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationShouldHandleReopen:hasVisibleWindows:"), auto_cast applicationShouldHandleReopenHasVisibleWindows, "B@:@B")
	}
	if template.applicationDockMenu != nil {
		applicationDockMenu :: proc "c" (self: id, sender: ^Application) -> ^Menu {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationDockMenu(sender)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDockMenu:"), auto_cast applicationDockMenu, "@@:@")
	}
	if template.applicationShouldAutomaticallyLocalizeKeyEquivalents != nil {
		applicationShouldAutomaticallyLocalizeKeyEquivalents :: proc "c" (self: id, application: ^Application) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldAutomaticallyLocalizeKeyEquivalents(application)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationShouldAutomaticallyLocalizeKeyEquivalents:"), auto_cast applicationShouldAutomaticallyLocalizeKeyEquivalents, "B@:@")
	}
	if template.applicationWillPresentError != nil {
		applicationWillPresentError :: proc "c" (self: id, application: ^Application, error: ^Error) -> ^Error {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationWillPresentError(application, error)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:willPresentError:"), auto_cast applicationWillPresentError, "@@:@@")
	}
	if template.applicationDidChangeScreenParameters != nil {
		applicationDidChangeScreenParameters :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidChangeScreenParameters(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidChangeScreenParameters:"), auto_cast applicationDidChangeScreenParameters, "v@:@")
	}
	if template.applicationWillContinueUserActivityWithType != nil {
		applicationWillContinueUserActivityWithType :: proc "c" (self: id, application: ^Application, userActivityType: ^String) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationWillContinueUserActivityWithType(application, userActivityType)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:willContinueUserActivityWithType:"), auto_cast applicationWillContinueUserActivityWithType, "B@:@@")
	}
	if template.applicationContinueUserActivityRestorationHandler != nil {
		applicationContinueUserActivityRestorationHandler :: proc "c" (self: id, application: ^Application, userActivity: ^UserActivity, restorationHandler: ^Block) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationContinueUserActivityRestorationHandler(application, userActivity, restorationHandler)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:continueUserActivity:restorationHandler:"), auto_cast applicationContinueUserActivityRestorationHandler, "B@:@@?")
	}
	if template.applicationDidFailToContinueUserActivityWithTypeError != nil {
		applicationDidFailToContinueUserActivityWithTypeError :: proc "c" (self: id, application: ^Application, userActivityType: ^String, error: ^Error) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidFailToContinueUserActivityWithTypeError(application, userActivityType, error)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:didFailToContinueUserActivityWithType:error:"), auto_cast applicationDidFailToContinueUserActivityWithTypeError, "v@:@@@")
	}
	if template.applicationDidUpdateUserActivity != nil {
		applicationDidUpdateUserActivity :: proc "c" (self: id, application: ^Application, userActivity: ^UserActivity) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidUpdateUserActivity(application, userActivity)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:didUpdateUserActivity:"), auto_cast applicationDidUpdateUserActivity, "v@:@@")
	}
	if template.applicationDidRegisterForRemoteNotificationsWithDeviceToken != nil {
		applicationDidRegisterForRemoteNotificationsWithDeviceToken :: proc "c" (self: id, application: ^Application, deviceToken: ^Data) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidRegisterForRemoteNotificationsWithDeviceToken(application, deviceToken)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:didRegisterForRemoteNotificationsWithDeviceToken:"), auto_cast applicationDidRegisterForRemoteNotificationsWithDeviceToken, "v@:@@")
	}
	if template.applicationDidFailToRegisterForRemoteNotificationsWithError != nil {
		applicationDidFailToRegisterForRemoteNotificationsWithError :: proc "c" (self: id, application: ^Application, error: ^Error) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidFailToRegisterForRemoteNotificationsWithError(application, error)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:didFailToRegisterForRemoteNotificationsWithError:"), auto_cast applicationDidFailToRegisterForRemoteNotificationsWithError, "v@:@@")
	}
	if template.applicationDidReceiveRemoteNotification != nil {
		applicationDidReceiveRemoteNotification :: proc "c" (self: id, application: ^Application, userInfo: ^Dictionary) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidReceiveRemoteNotification(application, userInfo)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:didReceiveRemoteNotification:"), auto_cast applicationDidReceiveRemoteNotification, "v@:@@")
	}
	// if template.applicationUserDidAcceptCloudKitShareWithMetadata != nil {
	// 	applicationUserDidAcceptCloudKitShareWithMetadata :: proc "c" (self: id, application: ^Application, metadata: ^CKShareMetadata) {
	// 		del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
	// 		context = del._context
	// 		del.applicationUserDidAcceptCloudKitShareWithMetadata(application, metadata)
	// 	}
	// 	class_addMethod(class, intrinsics.objc_find_selector("application:userDidAcceptCloudKitShareWithMetadata:"), auto_cast applicationUserDidAcceptCloudKitShareWithMetadata, "v@:@@")
	// }
	// if template.applicationHandlerForIntent != nil {
	// 	applicationHandlerForIntent :: proc "c" (self: id, application: ^Application, intent: ^INIntent) -> id {
	// 		del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
	// 		context = del._context
	// 		return del.applicationHandlerForIntent(application, intent)
	// 	}
	// 	class_addMethod(class, intrinsics.objc_find_selector("application:handlerForIntent:"), auto_cast applicationHandlerForIntent, "@@:@@")
	// }
	if template.applicationOpenURLs != nil {
		applicationOpenURLs :: proc "c" (self: id, application: ^Application, urls: ^Array) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationOpenURLs(application, urls)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:openURLs:"), auto_cast applicationOpenURLs, "v@:@@")
	}
	if template.applicationOpenFile != nil {
		applicationOpenFile :: proc "c" (self: id, sender: ^Application, filename: ^String) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenFile(sender, filename)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:openFile:"), auto_cast applicationOpenFile, "B@:@@")
	}
	if template.applicationOpenFileWithoutUI != nil {
		applicationOpenFileWithoutUI :: proc "c" (self: id, sender: id, filename: ^String) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenFileWithoutUI(sender, filename)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:openFileWithoutUI:"), auto_cast applicationOpenFileWithoutUI, "B@:@@")
	}
	if template.applicationOpenTempFile != nil {
		applicationOpenTempFile :: proc "c" (self: id, sender: ^Application, filename: ^String) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenTempFile(sender, filename)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:openTempFile:"), auto_cast applicationOpenTempFile, "B@:@@")
	}
	if template.applicationOpenFiles != nil {
		applicationOpenFiles :: proc "c" (self: id, sender: ^Application, filenames: ^Array) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationOpenFiles(sender, filenames)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:openFiles:"), auto_cast applicationOpenFiles, "v@:@@")
	}
	if template.applicationShouldOpenUntitledFile != nil {
		applicationShouldOpenUntitledFile :: proc "c" (self: id, sender: ^Application) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldOpenUntitledFile(sender)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationShouldOpenUntitledFile:"), auto_cast applicationShouldOpenUntitledFile, "B@:@")
	}
	if template.applicationOpenUntitledFile != nil {
		applicationOpenUntitledFile :: proc "c" (self: id, sender: ^Application) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenUntitledFile(sender)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationOpenUntitledFile:"), auto_cast applicationOpenUntitledFile, "B@:@")
	}
	if template.applicationPrintFile != nil {
		applicationPrintFile :: proc "c" (self: id, sender: ^Application, filename: ^String) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationPrintFile(sender, filename)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:printFile:"), auto_cast applicationPrintFile, "B@:@@")
	}
	if template.applicationPrintFilesWithSettingsShowPrintPanels != nil {
		applicationPrintFilesWithSettingsShowPrintPanels :: proc "c" (self: id, application: ^Application, fileNames: ^Array, printSettings: ^Dictionary, showPrintPanels: BOOL) -> ApplicationPrintReply {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationPrintFilesWithSettingsShowPrintPanels(application, fileNames, printSettings, showPrintPanels)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:printFiles:withSettings:showPrintPanels:"), auto_cast applicationPrintFilesWithSettingsShowPrintPanels, _UINTEGER_ENCODING+"@:@@@B")
	}
	if template.applicationSupportsSecureRestorableState != nil {
		applicationSupportsSecureRestorableState :: proc "c" (self: id, app: ^Application) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationSupportsSecureRestorableState(app)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationSupportsSecureRestorableState:"), auto_cast applicationSupportsSecureRestorableState, "B@:@")
	}
	if template.applicationProtectedDataDidBecomeAvailable != nil {
		applicationProtectedDataDidBecomeAvailable :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationProtectedDataDidBecomeAvailable(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationProtectedDataDidBecomeAvailable:"), auto_cast applicationProtectedDataDidBecomeAvailable, "v@:@")
	}
	if template.applicationProtectedDataWillBecomeUnavailable != nil {
		applicationProtectedDataWillBecomeUnavailable :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationProtectedDataWillBecomeUnavailable(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationProtectedDataWillBecomeUnavailable:"), auto_cast applicationProtectedDataWillBecomeUnavailable, "v@:@")
	}
	if template.applicationWillEncodeRestorableState != nil {
		applicationWillEncodeRestorableState :: proc "c" (self: id, app: ^Application, coder: ^Coder) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationWillEncodeRestorableState(app, coder)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:willEncodeRestorableState:"), auto_cast applicationWillEncodeRestorableState, "v@:@@")
	}
	if template.applicationDidDecodeRestorableState != nil {
		applicationDidDecodeRestorableState :: proc "c" (self: id, app: ^Application, coder: ^Coder) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidDecodeRestorableState(app, coder)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:didDecodeRestorableState:"), auto_cast applicationDidDecodeRestorableState, "v@:@@")
	}
	if template.applicationDidChangeOcclusionState != nil {
		applicationDidChangeOcclusionState :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.applicationDidChangeOcclusionState(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("applicationDidChangeOcclusionState:"), auto_cast applicationDidChangeOcclusionState, "v@:@")
	}
	if template.applicationDelegateHandlesKey != nil {
		applicationDelegateHandlesKey :: proc "c" (self: id, sender: ^Application, key: ^String) -> BOOL {
			del := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.applicationDelegateHandlesKey(sender, key)
		}
		class_addMethod(class, intrinsics.objc_find_selector("application:delegateHandlesKey:"), auto_cast applicationDelegateHandlesKey, "B@:@@")
	}

	objc_registerClassPair(class)
	del := class_createInstance(class, size_of(_ApplicationDelegateInternal))
	del_internal := cast(^_ApplicationDelegateInternal)object_getIndexedIvars(del)
	del_internal^ = {
		template,
		delegate_context.(runtime.Context) or_else runtime.default_context(),
	}
	return cast(^ApplicationDelegate)del
}

@(objc_type=Application, objc_name="setDelegate")
Application_setDelegate :: proc "c" (self: ^Application, delegate: ^ApplicationDelegate) {
	msgSend(nil, self, "setDelegate:", delegate)
}
