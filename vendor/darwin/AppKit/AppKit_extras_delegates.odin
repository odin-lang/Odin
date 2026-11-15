#+build darwin:default
package darwin_AppKit

// Hand-written helpers which create `NSApplicationDelegate` and `NSWindowDelegate` objects
// whose methods call the Odin procedures set in a template, without `@(objc_implement)`.

import "base:intrinsics"
import "base:runtime"
import "core:strings"
import NS   "core:sys/darwin/Foundation"
import ObjC "core:sys/darwin/ObjectiveC"

@(private) _UINTEGER_ENCODING :: "Q"
@(private) _POINT_ENCODING    :: "{CGPoint=dd}"
@(private) _SIZE_ENCODING     :: "{CGSize=dd}"
@(private) _RECT_ENCODING     :: "{CGRect=" + _POINT_ENCODING + _SIZE_ENCODING + "}"

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
	applicationShouldTerminateAfterLastWindowClosed:             proc(sender: ^Application) -> bool,
	applicationWillTerminate:                                    proc(notification: ^Notification),
	// Hiding Applications
	applicationWillHide:                                         proc(notification: ^Notification),
	applicationDidHide:                                          proc(notification: ^Notification),
	applicationWillUnhide:                                       proc(notification: ^Notification),
	applicationDidUnhide:                                        proc(notification: ^Notification),
	// Managing Windows
	applicationWillUpdate:                                       proc(notification: ^Notification),
	applicationDidUpdate:                                        proc(notification: ^Notification),
	applicationShouldHandleReopenHasVisibleWindows:              proc(sender: ^Application, flag: bool) -> bool,
	// Managing the Dock Menu
	applicationDockMenu:                                         proc(sender: ^Application) -> ^Menu,
	// Localizing Keyboard Shortcuts
	applicationShouldAutomaticallyLocalizeKeyEquivalents:        proc(application: ^Application) -> bool,
	// Displaying Errors
	applicationWillPresentError:                                 proc(application: ^Application, error: ^Error) -> ^Error,
	// Managing the Screen
	applicationDidChangeScreenParameters:                        proc(notification: ^Notification),
	// Continuing User Activities
	applicationWillContinueUserActivityWithType:                 proc(application: ^Application, userActivityType: ^String) -> bool,
	applicationContinueUserActivityRestorationHandler:           proc(application: ^Application, userActivity: ^UserActivity, restorationHandler: ^NS.Block) -> bool,
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
	applicationOpenFile:                                         proc(sender: ^Application, filename: ^String) -> bool,
	applicationOpenFileWithoutUI:                                proc(sender: id, filename: ^String) -> bool,
	applicationOpenTempFile:                                     proc(sender: ^Application, filename: ^String) -> bool,
	applicationOpenFiles:                                        proc(sender: ^Application, filenames: ^Array),
	applicationShouldOpenUntitledFile:                           proc(sender: ^Application) -> bool,
	applicationOpenUntitledFile:                                 proc(sender: ^Application) -> bool,
	// Printing
	applicationPrintFile:                                        proc(sender: ^Application, filename: ^String) -> bool,
	applicationPrintFilesWithSettingsShowPrintPanels:            proc(application: ^Application, fileNames: ^Array, printSettings: ^Dictionary, showPrintPanels: bool) -> ApplicationPrintReply,
	// Restoring Application State
	applicationSupportsSecureRestorableState:                    proc(app: ^Application) -> bool,
	applicationProtectedDataDidBecomeAvailable:                  proc(notification: ^Notification),
	applicationProtectedDataWillBecomeUnavailable:               proc(notification: ^Notification),
	applicationWillEncodeRestorableState:                        proc(app: ^Application, coder: ^Coder),
	applicationDidDecodeRestorableState:                         proc(app: ^Application, coder: ^Coder),
	// Handling Changes to the Occlusion State
	applicationDidChangeOcclusionState:                          proc(notification: ^Notification),
	// Scripting Your App
	applicationDelegateHandlesKey:                               proc(sender: ^Application, key: ^String) -> bool,
}

@(private)
_ApplicationDelegateInternal :: struct {
	using _: ApplicationDelegateTemplate,
	_context: runtime.Context,
}

application_delegate_register_and_alloc :: proc(template: ApplicationDelegateTemplate, class_name: string, delegate_context: Maybe(runtime.Context)) -> ^ApplicationDelegate {
	class := ObjC.objc_allocateClassPair(intrinsics.objc_find_class("NSObject"), strings.clone_to_cstring(class_name, context.temp_allocator), 0); if class == nil {
		// Class already registered
		return nil
	}
	if template.applicationWillFinishLaunching != nil {
		applicationWillFinishLaunching :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillFinishLaunching(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillFinishLaunching:"), auto_cast applicationWillFinishLaunching, "v@:@")
	}
	if template.applicationDidFinishLaunching != nil {
		applicationDidFinishLaunching :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidFinishLaunching(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidFinishLaunching:"), auto_cast applicationDidFinishLaunching, "v@:@")
	}
	if template.applicationWillBecomeActive != nil {
		applicationWillBecomeActive :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillBecomeActive(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillBecomeActive:"), auto_cast applicationWillBecomeActive, "v@:@")
	}
	if template.applicationDidBecomeActive != nil {
		applicationDidBecomeActive :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidBecomeActive(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidBecomeActive:"), auto_cast applicationDidBecomeActive, "v@:@")
	}
	if template.applicationWillResignActive != nil {
		applicationWillResignActive :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillResignActive(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillResignActive:"), auto_cast applicationWillResignActive, "v@:@")
	}
	if template.applicationDidResignActive != nil {
		applicationDidResignActive :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidResignActive(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidResignActive:"), auto_cast applicationDidResignActive, "v@:@")
	}
	if template.applicationShouldTerminate != nil {
		applicationShouldTerminate :: proc "c" (self: id, cmd: SEL, sender: ^Application) -> ApplicationTerminateReply {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldTerminate(sender)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationShouldTerminate:"), auto_cast applicationShouldTerminate, _UINTEGER_ENCODING+"@:@")
	}
	if template.applicationShouldTerminateAfterLastWindowClosed != nil {
		applicationShouldTerminateAfterLastWindowClosed :: proc "c" (self: id, cmd: SEL, sender: ^Application) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldTerminateAfterLastWindowClosed(sender)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationShouldTerminateAfterLastWindowClosed:"), auto_cast applicationShouldTerminateAfterLastWindowClosed, "B@:@")
	}
	if template.applicationWillTerminate != nil {
		applicationWillTerminate :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillTerminate(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillTerminate:"), auto_cast applicationWillTerminate, "v@:@")
	}
	if template.applicationWillHide != nil {
		applicationWillHide :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillHide(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillHide:"), auto_cast applicationWillHide, "v@:@")
	}
	if template.applicationDidHide != nil {
		applicationDidHide :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidHide(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidHide:"), auto_cast applicationDidHide, "v@:@")
	}
	if template.applicationWillUnhide != nil {
		applicationWillUnhide :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillUnhide(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillUnhide:"), auto_cast applicationWillUnhide, "v@:@")
	}
	if template.applicationDidUnhide != nil {
		applicationDidUnhide :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidUnhide(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidUnhide:"), auto_cast applicationDidUnhide, "v@:@")
	}
	if template.applicationWillUpdate != nil {
		applicationWillUpdate :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillUpdate(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationWillUpdate:"), auto_cast applicationWillUpdate, "v@:@")
	}
	if template.applicationDidUpdate != nil {
		applicationDidUpdate :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidUpdate(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidUpdate:"), auto_cast applicationDidUpdate, "v@:@")
	}
	if template.applicationShouldHandleReopenHasVisibleWindows != nil {
		applicationShouldHandleReopenHasVisibleWindows :: proc "c" (self: id, cmd: SEL, sender: ^Application, flag: bool) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldHandleReopenHasVisibleWindows(sender, flag)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationShouldHandleReopen:hasVisibleWindows:"), auto_cast applicationShouldHandleReopenHasVisibleWindows, "B@:@B")
	}
	if template.applicationDockMenu != nil {
		applicationDockMenu :: proc "c" (self: id, cmd: SEL, sender: ^Application) -> ^Menu {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationDockMenu(sender)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDockMenu:"), auto_cast applicationDockMenu, "@@:@")
	}
	if template.applicationShouldAutomaticallyLocalizeKeyEquivalents != nil {
		applicationShouldAutomaticallyLocalizeKeyEquivalents :: proc "c" (self: id, cmd: SEL, application: ^Application) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldAutomaticallyLocalizeKeyEquivalents(application)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationShouldAutomaticallyLocalizeKeyEquivalents:"), auto_cast applicationShouldAutomaticallyLocalizeKeyEquivalents, "B@:@")
	}
	if template.applicationWillPresentError != nil {
		applicationWillPresentError :: proc "c" (self: id, cmd: SEL, application: ^Application, error: ^Error) -> ^Error {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationWillPresentError(application, error)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:willPresentError:"), auto_cast applicationWillPresentError, "@@:@@")
	}
	if template.applicationDidChangeScreenParameters != nil {
		applicationDidChangeScreenParameters :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidChangeScreenParameters(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidChangeScreenParameters:"), auto_cast applicationDidChangeScreenParameters, "v@:@")
	}
	if template.applicationWillContinueUserActivityWithType != nil {
		applicationWillContinueUserActivityWithType :: proc "c" (self: id, cmd: SEL, application: ^Application, userActivityType: ^String) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationWillContinueUserActivityWithType(application, userActivityType)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:willContinueUserActivityWithType:"), auto_cast applicationWillContinueUserActivityWithType, "B@:@@")
	}
	if template.applicationContinueUserActivityRestorationHandler != nil {
		applicationContinueUserActivityRestorationHandler :: proc "c" (self: id, cmd: SEL, application: ^Application, userActivity: ^UserActivity, restorationHandler: ^NS.Block) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationContinueUserActivityRestorationHandler(application, userActivity, restorationHandler)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:continueUserActivity:restorationHandler:"), auto_cast applicationContinueUserActivityRestorationHandler, "B@:@@?")
	}
	if template.applicationDidFailToContinueUserActivityWithTypeError != nil {
		applicationDidFailToContinueUserActivityWithTypeError :: proc "c" (self: id, cmd: SEL, application: ^Application, userActivityType: ^String, error: ^Error) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidFailToContinueUserActivityWithTypeError(application, userActivityType, error)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:didFailToContinueUserActivityWithType:error:"), auto_cast applicationDidFailToContinueUserActivityWithTypeError, "v@:@@@")
	}
	if template.applicationDidUpdateUserActivity != nil {
		applicationDidUpdateUserActivity :: proc "c" (self: id, cmd: SEL, application: ^Application, userActivity: ^UserActivity) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidUpdateUserActivity(application, userActivity)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:didUpdateUserActivity:"), auto_cast applicationDidUpdateUserActivity, "v@:@@")
	}
	if template.applicationDidRegisterForRemoteNotificationsWithDeviceToken != nil {
		applicationDidRegisterForRemoteNotificationsWithDeviceToken :: proc "c" (self: id, cmd: SEL, application: ^Application, deviceToken: ^Data) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidRegisterForRemoteNotificationsWithDeviceToken(application, deviceToken)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:didRegisterForRemoteNotificationsWithDeviceToken:"), auto_cast applicationDidRegisterForRemoteNotificationsWithDeviceToken, "v@:@@")
	}
	if template.applicationDidFailToRegisterForRemoteNotificationsWithError != nil {
		applicationDidFailToRegisterForRemoteNotificationsWithError :: proc "c" (self: id, cmd: SEL, application: ^Application, error: ^Error) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidFailToRegisterForRemoteNotificationsWithError(application, error)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:didFailToRegisterForRemoteNotificationsWithError:"), auto_cast applicationDidFailToRegisterForRemoteNotificationsWithError, "v@:@@")
	}
	if template.applicationDidReceiveRemoteNotification != nil {
		applicationDidReceiveRemoteNotification :: proc "c" (self: id, cmd: SEL, application: ^Application, userInfo: ^Dictionary) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidReceiveRemoteNotification(application, userInfo)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:didReceiveRemoteNotification:"), auto_cast applicationDidReceiveRemoteNotification, "v@:@@")
	}
	// if template.applicationUserDidAcceptCloudKitShareWithMetadata != nil {
	// 	applicationUserDidAcceptCloudKitShareWithMetadata :: proc "c" (self: id, cmd: SEL, application: ^Application, metadata: ^CKShareMetadata) {
	// 		del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
	// 		context = del._context
	// 		del.applicationUserDidAcceptCloudKitShareWithMetadata(application, metadata)
	// 	}
	// 	ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:userDidAcceptCloudKitShareWithMetadata:"), auto_cast applicationUserDidAcceptCloudKitShareWithMetadata, "v@:@@")
	// }
	// if template.applicationHandlerForIntent != nil {
	// 	applicationHandlerForIntent :: proc "c" (self: id, cmd: SEL, application: ^Application, intent: ^INIntent) -> id {
	// 		del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
	// 		context = del._context
	// 		return del.applicationHandlerForIntent(application, intent)
	// 	}
	// 	ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:handlerForIntent:"), auto_cast applicationHandlerForIntent, "@@:@@")
	// }
	if template.applicationOpenURLs != nil {
		applicationOpenURLs :: proc "c" (self: id, cmd: SEL, application: ^Application, urls: ^Array) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationOpenURLs(application, urls)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:openURLs:"), auto_cast applicationOpenURLs, "v@:@@")
	}
	if template.applicationOpenFile != nil {
		applicationOpenFile :: proc "c" (self: id, cmd: SEL, sender: ^Application, filename: ^String) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenFile(sender, filename)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:openFile:"), auto_cast applicationOpenFile, "B@:@@")
	}
	if template.applicationOpenFileWithoutUI != nil {
		applicationOpenFileWithoutUI :: proc "c" (self: id, cmd: SEL, sender: id, filename: ^String) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenFileWithoutUI(sender, filename)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:openFileWithoutUI:"), auto_cast applicationOpenFileWithoutUI, "B@:@@")
	}
	if template.applicationOpenTempFile != nil {
		applicationOpenTempFile :: proc "c" (self: id, cmd: SEL, sender: ^Application, filename: ^String) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenTempFile(sender, filename)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:openTempFile:"), auto_cast applicationOpenTempFile, "B@:@@")
	}
	if template.applicationOpenFiles != nil {
		applicationOpenFiles :: proc "c" (self: id, cmd: SEL, sender: ^Application, filenames: ^Array) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationOpenFiles(sender, filenames)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:openFiles:"), auto_cast applicationOpenFiles, "v@:@@")
	}
	if template.applicationShouldOpenUntitledFile != nil {
		applicationShouldOpenUntitledFile :: proc "c" (self: id, cmd: SEL, sender: ^Application) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationShouldOpenUntitledFile(sender)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationShouldOpenUntitledFile:"), auto_cast applicationShouldOpenUntitledFile, "B@:@")
	}
	if template.applicationOpenUntitledFile != nil {
		applicationOpenUntitledFile :: proc "c" (self: id, cmd: SEL, sender: ^Application) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationOpenUntitledFile(sender)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationOpenUntitledFile:"), auto_cast applicationOpenUntitledFile, "B@:@")
	}
	if template.applicationPrintFile != nil {
		applicationPrintFile :: proc "c" (self: id, cmd: SEL, sender: ^Application, filename: ^String) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationPrintFile(sender, filename)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:printFile:"), auto_cast applicationPrintFile, "B@:@@")
	}
	if template.applicationPrintFilesWithSettingsShowPrintPanels != nil {
		applicationPrintFilesWithSettingsShowPrintPanels :: proc "c" (self: id, cmd: SEL, application: ^Application, fileNames: ^Array, printSettings: ^Dictionary, showPrintPanels: bool) -> ApplicationPrintReply {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationPrintFilesWithSettingsShowPrintPanels(application, fileNames, printSettings, showPrintPanels)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:printFiles:withSettings:showPrintPanels:"), auto_cast applicationPrintFilesWithSettingsShowPrintPanels, _UINTEGER_ENCODING+"@:@@@B")
	}
	if template.applicationSupportsSecureRestorableState != nil {
		applicationSupportsSecureRestorableState :: proc "c" (self: id, cmd: SEL, app: ^Application) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationSupportsSecureRestorableState(app)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationSupportsSecureRestorableState:"), auto_cast applicationSupportsSecureRestorableState, "B@:@")
	}
	if template.applicationProtectedDataDidBecomeAvailable != nil {
		applicationProtectedDataDidBecomeAvailable :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationProtectedDataDidBecomeAvailable(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationProtectedDataDidBecomeAvailable:"), auto_cast applicationProtectedDataDidBecomeAvailable, "v@:@")
	}
	if template.applicationProtectedDataWillBecomeUnavailable != nil {
		applicationProtectedDataWillBecomeUnavailable :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationProtectedDataWillBecomeUnavailable(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationProtectedDataWillBecomeUnavailable:"), auto_cast applicationProtectedDataWillBecomeUnavailable, "v@:@")
	}
	if template.applicationWillEncodeRestorableState != nil {
		applicationWillEncodeRestorableState :: proc "c" (self: id, cmd: SEL, app: ^Application, coder: ^Coder) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationWillEncodeRestorableState(app, coder)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:willEncodeRestorableState:"), auto_cast applicationWillEncodeRestorableState, "v@:@@")
	}
	if template.applicationDidDecodeRestorableState != nil {
		applicationDidDecodeRestorableState :: proc "c" (self: id, cmd: SEL, app: ^Application, coder: ^Coder) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidDecodeRestorableState(app, coder)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:didDecodeRestorableState:"), auto_cast applicationDidDecodeRestorableState, "v@:@@")
	}
	if template.applicationDidChangeOcclusionState != nil {
		applicationDidChangeOcclusionState :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.applicationDidChangeOcclusionState(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("applicationDidChangeOcclusionState:"), auto_cast applicationDidChangeOcclusionState, "v@:@")
	}
	if template.applicationDelegateHandlesKey != nil {
		applicationDelegateHandlesKey :: proc "c" (self: id, cmd: SEL, sender: ^Application, key: ^String) -> bool {
			del := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.applicationDelegateHandlesKey(sender, key)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("application:delegateHandlesKey:"), auto_cast applicationDelegateHandlesKey, "B@:@@")
	}

	if protocol := ObjC.objc_getProtocol("NSApplicationDelegate"); protocol != nil {
		ObjC.class_addProtocol(class, protocol)
	}
	ObjC.objc_registerClassPair(class)
	del := ObjC.class_createInstance(class, size_of(_ApplicationDelegateInternal))
	del_internal := cast(^_ApplicationDelegateInternal)ObjC.object_getIndexedIvars(del)
	del_internal^ = {
		template,
		delegate_context.(runtime.Context) or_else runtime.default_context(),
	}
	return cast(^ApplicationDelegate)del
}

WindowDelegateTemplate :: struct {
	// Managing Sheets
	windowWillPositionSheetUsingRect:                                    proc(window: ^Window, sheet: ^Window, rect: Rect) -> Rect,
	windowWillBeginSheet:                                                proc(notification: ^Notification),
	windowDidEndSheet:                                                   proc(notification: ^Notification),
	// Sizing Windows
	windowWillResizeToSize:                                              proc(sender: ^Window, frameSize: Size) -> Size,
	windowDidResize:                                                     proc(notification: ^Notification),
	windowWillStartLiveResize:                                           proc(noitifcation: ^Notification),
	windowDidEndLiveResize:                                              proc(notification: ^Notification),
	// Minimizing Windows
	windowWillMiniaturize:                                               proc(notification: ^Notification),
	windowDidMiniaturize:                                                proc(notification: ^Notification),
	windowDidDeminiaturize:                                              proc(notification: ^Notification),
	// Zooming window
	windowWillUseStandardFrameDefaultFrame:                              proc(window: ^Window, newFrame: Rect) -> Rect,
	windowShouldZoomToFrame:                                             proc(window: ^Window, newFrame: Rect) -> bool,
	// Managing Full-Screen Presentation
	windowWillUseFullScreenContentSize:                                  proc(window: ^Window, proposedSize: Size) -> Size,
	windowWillUseFullScreenPresentationOptions:                          proc(window: ^Window, proposedOptions: ApplicationPresentationOptions) -> ApplicationPresentationOptions,
	windowWillEnterFullScreen:                                           proc(notification: ^Notification),
	windowDidEnterFullScreen:                                            proc(notification: ^Notification),
	windowWillExitFullScreen:                                            proc(notification: ^Notification),
	windowDidExitFullScreen:                                             proc(notification: ^Notification),
	// Custom Full-Screen Presentation Animations
	customWindowsToEnterFullScreenForWindow:                             proc(window: ^Window) -> ^Array,
	customWindowsToEnterFullScreenForWindowOnScreen:                     proc(window: ^Window, screen: ^Screen) -> ^Array,
	windowStartCustomAnimationToEnterFullScreenWithDuration:             proc(window: ^Window, duration: TimeInterval),
	windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration:     proc(window: ^Window, screen: ^Screen, duration: TimeInterval),
	windowDidFailToEnterFullScreen:                                      proc(window: ^Window),
	customWindowsToExitFullScreenForWindow:                              proc(window: ^Window) -> ^Array,
	windowStartCustomAnimationToExitFullScreenWithDuration:              proc(window: ^Window, duration: TimeInterval),
	windowDidFailToExitFullScreen:                                       proc(window: ^Window),
	// Moving Windows
	windowWillMove:                                                      proc(notification: ^Notification),
	windowDidMove:                                                       proc(notification: ^Notification),
	windowDidChangeScreen:                                               proc(notification: ^Notification),
	windowDidChangeScreenProfile:                                        proc(notification: ^Notification),
	windowDidChangeBackingProperties:                                    proc(notification: ^Notification),
	// Closing Windows
	windowShouldClose:                                                   proc(sender: ^Window) -> bool,
	windowWillClose:                                                     proc(notification: ^Notification),
	// Managing Key Status
	windowDidBecomeKey:                                                  proc(notification: ^Notification),
	windowDidResignKey:                                                  proc(notification: ^Notification),
	// Managing Main Status
	windowDidBecomeMain:                                                 proc(notification: ^Notification),
	windowDidResignMain:                                                 proc(notification: ^Notification),
	// Managing Field Editors
	windowWillReturnFieldEditorToObject:                                 proc(sender: ^Window, client: id) -> id,
	// Updating Windows
	windowDidUpdate:                                                     proc (notification: ^Notification),
	// Exposing Windows
	windowDidExpose:                                                     proc (notification: ^Notification),
	// Managing Occlusion State
	windowDidChangeOcclusionState:                                       proc(notification: ^Notification),
	// Dragging Windows
	windowShouldDragDocumentWithEventFromWithPasteboard:                 proc(window: ^Window, event: ^Event, dragImageLocation: NS.Point, pasteboard: ^Pasteboard) -> bool,
	// Getting the Undo Manager
	windowWillReturnUndoManager:                                         proc(window: ^Window) -> ^UndoManager,
	// Managing Titles
	windowShouldPopUpDocumentPathMenu:                                   proc(window: ^Window, menu: ^Menu) -> bool,
	// Managing Restorable State
	windowWillEncodeRestorableState:                                     proc(window: ^Window, state: ^Coder),
	windowDidEncodeRestorableState:                                      proc(window: ^Window, state: ^Coder),
	// Managing Presentation in Version Browsers
	windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize: proc(window: ^Window, maxPreferredFrameSize: Size, maxAllowedFrameSize: Size) -> Size,
	windowWillEnterVersionBrowser:                                       proc(notification: ^Notification),
	windowDidEnterVersionBrowser:                                        proc(notification: ^Notification),
	windowWillExitVersionBrowser:                                        proc(notification: ^Notification),
	windowDidExitVersionBrowser:                                         proc(notification: ^Notification),
}

@(private)
_WindowDelegateInternal :: struct {
	using _: WindowDelegateTemplate,
	_context: runtime.Context,
}

window_delegate_register_and_alloc :: proc(template: WindowDelegateTemplate, class_name: string, delegate_context: Maybe(runtime.Context)) -> ^WindowDelegate {
	class := ObjC.objc_allocateClassPair(intrinsics.objc_find_class("NSObject"), strings.clone_to_cstring(class_name, context.temp_allocator), 0); if class == nil {
		// Class already registered
		return nil
	}
	if template.windowWillPositionSheetUsingRect != nil {
		windowWillPositionSheetUsingRect :: proc "c" (self: id, cmd: SEL, window: ^Window, sheet: ^Window, rect: Rect) -> Rect {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillPositionSheetUsingRect(window, sheet, rect)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:willPositionSheet:usingRect:"), auto_cast windowWillPositionSheetUsingRect, _RECT_ENCODING+"@:@@"+_RECT_ENCODING)
	}
	if template.windowWillBeginSheet != nil {
		windowWillBeginSheet :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillBeginSheet(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillBeginSheet:"), auto_cast windowWillBeginSheet, "v@:@")
	}
	if template.windowDidEndSheet != nil {
		windowDidEndSheet :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidEndSheet(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidEndSheet:"), auto_cast windowDidEndSheet, "v@:@")
	}
	if template.windowWillResizeToSize != nil {
		windowWillResizeToSize :: proc "c" (self: id, cmd: SEL, sender: ^Window, frameSize: Size) -> Size {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillResizeToSize(sender, frameSize)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillResize:toSize:"), auto_cast windowWillResizeToSize, _SIZE_ENCODING+"@:@"+_SIZE_ENCODING)
	}
	if template.windowDidResize != nil {
		windowDidResize :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidResize(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidResize:"), auto_cast windowDidResize, "v@:@")
	}
	if template.windowWillStartLiveResize != nil {
		windowWillStartLiveResize :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillStartLiveResize(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillStartLiveResize:"), auto_cast windowWillStartLiveResize, "v@:@")
	}
	if template.windowDidEndLiveResize != nil {
		windowDidEndLiveResize :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidEndLiveResize(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidEndLiveResize:"), auto_cast windowDidEndLiveResize, "v@:@")
	}
	if template.windowWillMiniaturize != nil {
		windowWillMiniaturize :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillMiniaturize(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillMiniaturize:"), auto_cast windowWillMiniaturize, "v@:@")
	}
	if template.windowDidMiniaturize != nil {
		windowDidMiniaturize :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidMiniaturize(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidMiniaturize:"), auto_cast windowDidMiniaturize, "v@:@")
	}
	if template.windowDidDeminiaturize != nil {
		windowDidDeminiaturize :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidDeminiaturize(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidDeminiaturize:"), auto_cast windowDidDeminiaturize, "v@:@")
	}
	if template.windowWillUseStandardFrameDefaultFrame != nil {
		windowWillUseStandardFrameDefaultFrame :: proc(self: id, cmd: SEL, window: ^Window, newFrame: Rect) -> Rect {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillUseStandardFrameDefaultFrame(window, newFrame)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillUseStandardFrame:defaultFrame:"), auto_cast windowWillUseStandardFrameDefaultFrame, _RECT_ENCODING+"@:@"+_RECT_ENCODING)
	}
	if template.windowShouldZoomToFrame != nil {
		windowShouldZoomToFrame :: proc "c" (self: id, cmd: SEL, window: ^Window, newFrame: Rect) -> bool {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldZoomToFrame(window, newFrame)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowShouldZoom:toFrame:"), auto_cast windowShouldZoomToFrame, "B@:@"+_RECT_ENCODING)
	}
	if template.windowWillUseFullScreenContentSize != nil {
		windowWillUseFullScreenContentSize :: proc "c" (self: id, cmd: SEL, window: ^Window, proposedSize: Size) -> Size {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillUseFullScreenContentSize(window, proposedSize)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:willUseFullScreenContentSize:"), auto_cast windowWillUseFullScreenContentSize, _SIZE_ENCODING+"@:@"+_SIZE_ENCODING)
	}
	if template.windowWillUseFullScreenPresentationOptions != nil {
		windowWillUseFullScreenPresentationOptions :: proc(self: id, cmd: SEL, window: ^Window, proposedOptions: ApplicationPresentationOptions) -> ApplicationPresentationOptions {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillUseFullScreenPresentationOptions(window, proposedOptions)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:willUseFullScreenPresentationOptions:"), auto_cast windowWillUseFullScreenPresentationOptions, _UINTEGER_ENCODING+"@:@"+_UINTEGER_ENCODING)
	}
	if template.windowWillEnterFullScreen != nil {
		windowWillEnterFullScreen :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillEnterFullScreen(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillEnterFullScreen:"), auto_cast windowWillEnterFullScreen, "v@:@")
	}
	if template.windowDidEnterFullScreen != nil {
		windowDidEnterFullScreen :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidEnterFullScreen(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidEnterFullScreen:"), auto_cast windowDidEnterFullScreen, "v@:@")
	}
	if template.windowWillExitFullScreen != nil {
		windowWillExitFullScreen :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillExitFullScreen(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillExitFullScreen:"), auto_cast windowWillExitFullScreen, "v@:@")
	}
	if template.windowDidExitFullScreen != nil {
		windowDidExitFullScreen :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidExitFullScreen(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidExitFullScreen:"), auto_cast windowDidExitFullScreen, "v@:@")
	}
	if template.customWindowsToEnterFullScreenForWindow != nil {
		customWindowsToEnterFullScreenForWindow :: proc "c" (self: id, cmd: SEL, window: ^Window) -> ^Array {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.customWindowsToEnterFullScreenForWindow(window)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("customWindowsToEnterFullScreenForWindow:"), auto_cast customWindowsToEnterFullScreenForWindow, "@@:@")
	}
	if template.customWindowsToEnterFullScreenForWindowOnScreen != nil {
		customWindowsToEnterFullScreenForWindowOnScreen :: proc(self: id, cmd: SEL, window: ^Window, screen: ^Screen) -> ^Array {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.customWindowsToEnterFullScreenForWindowOnScreen(window, screen)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("customWindowsToEnterFullScreenForWindow:onScreen:"), auto_cast customWindowsToEnterFullScreenForWindowOnScreen, "@@:@@")
	}
	if template.windowStartCustomAnimationToEnterFullScreenWithDuration != nil {
		windowStartCustomAnimationToEnterFullScreenWithDuration :: proc "c" (self: id, cmd: SEL, window: ^Window, duration: TimeInterval) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowStartCustomAnimationToEnterFullScreenWithDuration(window, duration)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:startCustomAnimationToEnterFullScreenWithDuration:"), auto_cast windowStartCustomAnimationToEnterFullScreenWithDuration, "v@:@@")
	}
	if template.windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration != nil {
		windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration :: proc(self: id, cmd: SEL, window: ^Window, screen: ^Screen, duration: TimeInterval) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration(window, screen, duration)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:startCustomAnimationToEnterFullScreenOnScreen:withDuration:"), auto_cast windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration, "v@:@@d")
	}
	if template.windowDidFailToEnterFullScreen != nil {
		windowDidFailToEnterFullScreen :: proc "c" (self: id, cmd: SEL, window: ^Window) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidFailToEnterFullScreen(window)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidFailToEnterFullScreen:"), auto_cast windowDidFailToEnterFullScreen, "v@:@")
	}
	if template.customWindowsToExitFullScreenForWindow != nil {
		customWindowsToExitFullScreenForWindow :: proc "c" (self: id, cmd: SEL, window: ^Window) -> ^Array {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.customWindowsToExitFullScreenForWindow(window)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("customWindowsToExitFullScreenForWindow:"), auto_cast customWindowsToExitFullScreenForWindow, "@@:@")
	}
	if template.windowStartCustomAnimationToExitFullScreenWithDuration != nil {
		windowStartCustomAnimationToExitFullScreenWithDuration :: proc "c" (self: id, cmd: SEL, window: ^Window, duration: TimeInterval) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowStartCustomAnimationToExitFullScreenWithDuration(window, duration)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:startCustomAnimationToExitFullScreenWithDuration:"), auto_cast windowStartCustomAnimationToExitFullScreenWithDuration, "v@:@d")
	}
	if template.windowDidFailToExitFullScreen != nil {
		windowDidFailToExitFullScreen :: proc "c" (self: id, cmd: SEL, window: ^Window) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidFailToExitFullScreen(window)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidFailToExitFullScreen:"), auto_cast windowDidFailToExitFullScreen, "v@:@")
	}
	if template.windowWillMove != nil {
		windowWillMove :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillMove(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillMove:"), auto_cast windowWillMove, "v@:@")
	}
	if template.windowDidMove != nil {
		windowDidMove :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidMove(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidMove:"), auto_cast windowDidMove, "v@:@")
	}
	if template.windowDidChangeScreen != nil {
		windowDidChangeScreen :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeScreen(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeScreen:"), auto_cast windowDidChangeScreen, "v@:@")
	}
	if template.windowDidChangeScreenProfile != nil {
		windowDidChangeScreenProfile :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeScreenProfile(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeScreenProfile:"), auto_cast windowDidChangeScreenProfile, "v@:@")
	}
	if template.windowDidChangeBackingProperties != nil {
		windowDidChangeBackingProperties :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeBackingProperties(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeBackingProperties:"), auto_cast windowDidChangeBackingProperties, "v@:@")
	}
	if template.windowShouldClose != nil {
		windowShouldClose :: proc "c" (self:id, cmd: SEL, sender: ^Window) -> bool {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldClose(sender)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowShouldClose:"), auto_cast windowShouldClose, "B@:@")
	}
	if template.windowWillClose != nil {
		windowWillClose :: proc "c" (self:id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillClose(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillClose:"), auto_cast windowWillClose, "v@:@")
	}
	if template.windowDidBecomeKey != nil {
		windowDidBecomeKey :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidBecomeKey(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidBecomeKey:"), auto_cast windowDidBecomeKey, "v@:@")
	}
	if template.windowDidResignKey != nil {
		windowDidResignKey :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidResignKey(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidResignKey:"), auto_cast windowDidResignKey, "v@:@")
	}
	if template.windowDidBecomeMain != nil {
		windowDidBecomeMain :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidBecomeMain(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidBecomeMain:"), auto_cast windowDidBecomeMain, "v@:@")
	}
	if template.windowDidResignMain != nil {
		windowDidResignMain :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidResignMain(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidResignMain:"), auto_cast windowDidResignMain, "v@:@")
	}
	if template.windowWillReturnFieldEditorToObject != nil {
		windowWillReturnFieldEditorToObject :: proc "c" (self:id, cmd: SEL, sender: ^Window, client: id) -> id {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillReturnFieldEditorToObject(sender, client)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillReturnFieldEditor:toObject:"), auto_cast windowWillReturnFieldEditorToObject, "@@:@@")
	}
	if template.windowDidUpdate != nil {
		windowDidUpdate :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidUpdate(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidUpdate:"), auto_cast windowDidUpdate, "v@:@")
	}
	if template.windowDidExpose != nil {
		windowDidExpose :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidExpose(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidExpose:"), auto_cast windowDidExpose, "v@:@")
	}
	if template.windowDidChangeOcclusionState != nil {
		windowDidChangeOcclusionState :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeOcclusionState(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeOcclusionState:"), auto_cast windowDidChangeOcclusionState, "v@:@")
	}
	if template.windowShouldDragDocumentWithEventFromWithPasteboard != nil {
		windowShouldDragDocumentWithEventFromWithPasteboard :: proc "c" (self: id, cmd: SEL, window: ^Window, event: ^Event, dragImageLocation: NS.Point, pasteboard: ^Pasteboard) -> bool {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldDragDocumentWithEventFromWithPasteboard(window, event, dragImageLocation, pasteboard)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:shouldDragDocumentWithEvent:from:withPasteboard:"), auto_cast windowShouldDragDocumentWithEventFromWithPasteboard, "B@:@@"+_POINT_ENCODING+"@")
	}
	if template.windowWillReturnUndoManager != nil {
		windowWillReturnUndoManager :: proc "c" (self: id, cmd: SEL, window: ^Window) -> ^UndoManager {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillReturnUndoManager(window)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillReturnUndoManager:"), auto_cast windowWillReturnUndoManager, "@@:@")
	}
	if template.windowShouldPopUpDocumentPathMenu != nil {
		windowShouldPopUpDocumentPathMenu :: proc "c" (self: id, cmd: SEL, window: ^Window, menu: ^Menu) -> bool {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldPopUpDocumentPathMenu(window, menu)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:shouldPopUpDocumentPathMenu:"), auto_cast windowShouldPopUpDocumentPathMenu, "B@:@@")
	}
	if template.windowWillEncodeRestorableState != nil {
		windowWillEncodeRestorableState :: proc "c" (self: id, cmd: SEL, window: ^Window, state: ^Coder) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillEncodeRestorableState(window, state)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:willEncodeRestorableState:"), auto_cast windowWillEncodeRestorableState, "v@:@@")
	}
	if template.windowDidEncodeRestorableState != nil {
		windowDidEncodeRestorableState :: proc "c" (self: id, cmd: SEL, window: ^Window, state: ^Coder) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidEncodeRestorableState(window, state)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:didDecodeRestorableState:"), auto_cast windowDidEncodeRestorableState, "v@:@@")
	}
	if template.windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize != nil {
		windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize :: proc "c" (self: id, cmd: SEL, window: ^Window, maxPreferredFrameSize: Size, maxAllowedFrameSize: Size) -> Size {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			return del.windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize(window, maxPreferredFrameSize, maxPreferredFrameSize)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("window:willResizeForVersionBrowserWithMaxPreferredSize:maxAllowedSize:"), auto_cast windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize, _SIZE_ENCODING+"@:@"+_SIZE_ENCODING+_SIZE_ENCODING)
	}
	if template.windowWillEnterVersionBrowser != nil {
		windowWillEnterVersionBrowser :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillEnterVersionBrowser(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillEnterVersionBrowser:"), auto_cast windowWillEnterVersionBrowser, "v@:@")
	}
	if template.windowDidEnterVersionBrowser != nil {
		windowDidEnterVersionBrowser :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidEnterVersionBrowser(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidEnterVersionBrowser:"), auto_cast windowDidEnterVersionBrowser, "v@:@")
	}
	if template.windowWillExitVersionBrowser != nil {
		windowWillExitVersionBrowser :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowWillExitVersionBrowser(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowWillExitVersionBrowser:"), auto_cast windowWillExitVersionBrowser, "v@:@")
	}
	if template.windowDidExitVersionBrowser != nil {
		windowDidExitVersionBrowser :: proc "c" (self: id, cmd: SEL, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(self)
			context = del._context
			del.windowDidExitVersionBrowser(notification)
		}
		ObjC.class_addMethod(class, intrinsics.objc_find_selector("windowDidExitVersionBrowser:"), auto_cast windowDidExitVersionBrowser, "v@:@")
	}

	if protocol := ObjC.objc_getProtocol("NSWindowDelegate"); protocol != nil {
		ObjC.class_addProtocol(class, protocol)
	}
	ObjC.objc_registerClassPair(class)
	del := ObjC.class_createInstance(class, size_of(_WindowDelegateInternal))
	del_internal := cast(^_WindowDelegateInternal)ObjC.object_getIndexedIvars(del)
	del_internal^ = {
		template,
		delegate_context.(runtime.Context) or_else runtime.default_context(),
	}

	return cast(^WindowDelegate)del
}
