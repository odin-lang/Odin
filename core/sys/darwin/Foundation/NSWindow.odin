package objc_Foundation

import "core:strings"
import "base:runtime"
import "base:intrinsics"

Rect :: struct {
	using origin: Point,
	using size: Size,
}

Depth :: enum UInteger {
	onehundredtwentyeightBitRGB = 544,
	sixtyfourBitRGB             = 528,
	twentyfourBitRGB            = 520,
}

when size_of(Float) == 8 {
	_RECT_ENCODING :: "{CGRect="+_POINT_ENCODING+_SIZE_ENCODING+"}"
} else {
	_RECT_ENCODING :: "{NSRect="+_POINT_ENCODING+_SIZE_ENCODING+"}"
}

WindowStyleFlag :: enum UInteger {
	Titled                 = 0,
	Closable               = 1,
	Miniaturizable         = 2,
	Resizable              = 3,
	TexturedBackground     = 8,
	UnifiedTitleAndToolbar = 12,
	FullScreen             = 14,
	FullSizeContentView    = 15,
	UtilityWindow          = 4,
	DocModalWindow         = 6,
	NonactivatingPanel     = 7,
	HUDWindow              = 13,
}
WindowStyleMask :: distinct bit_set[WindowStyleFlag; UInteger]
WindowStyleMaskBorderless             :: WindowStyleMask{}
WindowStyleMaskTitled                 :: WindowStyleMask{.Titled}
WindowStyleMaskClosable               :: WindowStyleMask{.Closable}
WindowStyleMaskMiniaturizable         :: WindowStyleMask{.Miniaturizable}
WindowStyleMaskResizable              :: WindowStyleMask{.Resizable}
WindowStyleMaskTexturedBackground     :: WindowStyleMask{.TexturedBackground}
WindowStyleMaskUnifiedTitleAndToolbar :: WindowStyleMask{.UnifiedTitleAndToolbar}
WindowStyleMaskFullScreen             :: WindowStyleMask{.FullScreen}
WindowStyleMaskFullSizeContentView    :: WindowStyleMask{.FullSizeContentView}
WindowStyleMaskUtilityWindow          :: WindowStyleMask{.UtilityWindow}
WindowStyleMaskDocModalWindow         :: WindowStyleMask{.DocModalWindow}
WindowStyleMaskNonactivatingPanel     :: WindowStyleMask{.NonactivatingPanel}
WindowStyleMaskHUDWindow              :: WindowStyleMask{.HUDWindow}

BackingStoreType :: enum UInteger {
	Retained    = 0,
	Nonretained = 1,
	Buffered    = 2,
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
	windowShouldZoomToFrame:                                             proc(window: ^Window, newFrame: Rect) -> BOOL,
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
	windowShouldClose:                                                   proc(sender: ^Window) -> BOOL,
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
	windowShouldDragDocumentWithEventFromWithPasteboard:                 proc(window: ^Window, event: ^Event, dragImageLocation: Point, pasteboard: ^Pasteboard) -> BOOL,
	// Getting the Undo Manager
	windowWillReturnUndoManager:                                         proc(window: ^Window) -> ^UndoManager,
	// Managing Titles
	windowShouldPopUpDocumentPathMenu:                                   proc(window: ^Window, menu: ^Menu) -> BOOL,
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

Window_Title_Visibility :: enum UInteger {
	Visible,
	Hidden,
}

WindowDelegate :: struct { using _: Object } // This is not the same as NSWindowDelegate
_WindowDelegateInternal :: struct {
	using _: WindowDelegateTemplate,
	_context: runtime.Context,
}

window_delegate_register_and_alloc :: proc(template: WindowDelegateTemplate, class_name: string, delegate_context: Maybe(runtime.Context)) -> ^WindowDelegate {
	class := objc_allocateClassPair(intrinsics.objc_find_class("NSObject"), strings.clone_to_cstring(class_name, context.temp_allocator), 0); if class == nil {
		// Class already registered
		return nil
	}
	if template.windowWillPositionSheetUsingRect != nil {
		windowWillPositionSheetUsingRect :: proc "c" (self: id, window: ^Window, sheet: ^Window, rect: Rect) -> Rect {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillPositionSheetUsingRect(window, sheet, rect)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:willPositionSheet:usingRect:"), auto_cast windowWillPositionSheetUsingRect, _RECT_ENCODING+"@:@@"+_RECT_ENCODING)
	}
	if template.windowWillBeginSheet != nil {
		windowWillBeginSheet :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillBeginSheet(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillBeginSheet:"), auto_cast windowWillBeginSheet, "v@:@")
	}
	if template.windowDidEndSheet != nil {
		windowDidEndSheet :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidEndSheet(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidEndSheet:"), auto_cast windowDidEndSheet, "v@:@")
	}
	if template.windowWillResizeToSize != nil {
		windowWillResizeToSize :: proc "c" (self: id, sender: ^Window, frameSize: Size) -> Size {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillResizeToSize(sender, frameSize)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillResize:toSize:"), auto_cast windowWillResizeToSize, _SIZE_ENCODING+"@:@"+_SIZE_ENCODING)
	}
	if template.windowDidResize != nil {
		windowDidResize :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidResize(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidResize:"), auto_cast windowDidResize, "v@:@")
	}
	if template.windowWillStartLiveResize != nil {
		windowWillStartLiveResize :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillStartLiveResize(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillStartLiveResize:"), auto_cast windowWillStartLiveResize, "v@:@")
	}
	if template.windowDidEndLiveResize != nil {
		windowDidEndLiveResize :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidEndLiveResize(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidEndLiveResize:"), auto_cast windowDidEndLiveResize, "v@:@")
	}
	if template.windowWillMiniaturize != nil {
		windowWillMiniaturize :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillMiniaturize(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillMiniaturize:"), auto_cast windowWillMiniaturize, "v@:@")
	}
	if template.windowDidMiniaturize != nil {
		windowDidMiniaturize :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidMiniaturize(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidMiniaturize:"), auto_cast windowDidMiniaturize, "v@:@")
	}
	if template.windowDidDeminiaturize != nil {
		windowDidDeminiaturize :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidDeminiaturize(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidDeminiaturize:"), auto_cast windowDidDeminiaturize, "v@:@")
	}
	if template.windowWillUseStandardFrameDefaultFrame != nil {
		windowWillUseStandardFrameDefaultFrame :: proc(self: id, window: ^Window, newFrame: Rect) -> Rect {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillUseStandardFrameDefaultFrame(window, newFrame)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillUseStandardFrame:defaultFrame:"), auto_cast windowWillUseStandardFrameDefaultFrame, _RECT_ENCODING+"@:@"+_RECT_ENCODING)
	}
	if template.windowShouldZoomToFrame != nil {
		windowShouldZoomToFrame :: proc "c" (self: id, window: ^Window, newFrame: Rect) -> BOOL {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldZoomToFrame(window, newFrame)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowShouldZoom:toFrame:"), auto_cast windowShouldZoomToFrame, "B@:@"+_RECT_ENCODING)
	}
	if template.windowWillUseFullScreenContentSize != nil {
		windowWillUseFullScreenContentSize :: proc "c" (self: id, window: ^Window, proposedSize: Size) -> Size {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillUseFullScreenContentSize(window, proposedSize)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:willUseFullScreenContentSize:"), auto_cast windowWillUseFullScreenContentSize, _SIZE_ENCODING+"@:@"+_SIZE_ENCODING)
	}
	if template.windowWillUseFullScreenPresentationOptions != nil {
		windowWillUseFullScreenPresentationOptions :: proc(self: id, window: ^Window, proposedOptions: ApplicationPresentationOptions) -> ApplicationPresentationOptions {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillUseFullScreenPresentationOptions(window, proposedOptions)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:willUseFullScreenPresentationOptions:"), auto_cast windowWillUseFullScreenPresentationOptions, _UINTEGER_ENCODING+"@:@"+_UINTEGER_ENCODING)
	}
	if template.windowWillEnterFullScreen != nil {
		windowWillEnterFullScreen :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillEnterFullScreen(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillEnterFullScreen:"), auto_cast windowWillEnterFullScreen, "v@:@")
	}
	if template.windowDidEnterFullScreen != nil {
		windowDidEnterFullScreen :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidEnterFullScreen(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidEnterFullScreen:"), auto_cast windowDidEnterFullScreen, "v@:@")
	}
	if template.windowWillExitFullScreen != nil {
		windowWillExitFullScreen :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillExitFullScreen(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillExitFullScreen:"), auto_cast windowWillExitFullScreen, "v@:@")
	}
	if template.windowDidExitFullScreen != nil {
		windowDidExitFullScreen :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidExitFullScreen(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidExitFullScreen:"), auto_cast windowDidExitFullScreen, "v@:@")
	}
	if template.customWindowsToEnterFullScreenForWindow != nil {
		customWindowsToEnterFullScreenForWindow :: proc "c" (self: id, window: ^Window) -> ^Array {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.customWindowsToEnterFullScreenForWindow(window)
		}
		class_addMethod(class, intrinsics.objc_find_selector("customWindowsToEnterFullScreenForWindow:"), auto_cast customWindowsToEnterFullScreenForWindow, "@@:@")
	}
	if template.customWindowsToEnterFullScreenForWindowOnScreen != nil {
		customWindowsToEnterFullScreenForWindowOnScreen :: proc(self: id, window: ^Window, screen: ^Screen) -> ^Array {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.customWindowsToEnterFullScreenForWindowOnScreen(window, screen)
		}
		class_addMethod(class, intrinsics.objc_find_selector("customWindowsToEnterFullScreenForWindow:onScreen:"), auto_cast customWindowsToEnterFullScreenForWindowOnScreen, "@@:@@")
	}
	if template.windowStartCustomAnimationToEnterFullScreenWithDuration != nil {
		windowStartCustomAnimationToEnterFullScreenWithDuration :: proc "c" (self: id, window: ^Window, duration: TimeInterval) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowStartCustomAnimationToEnterFullScreenWithDuration(window, duration)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:startCustomAnimationToEnterFullScreenWithDuration:"), auto_cast windowStartCustomAnimationToEnterFullScreenWithDuration, "v@:@@")
	}
	if template.windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration != nil {
		windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration :: proc(self: id, window: ^Window, screen: ^Screen, duration: TimeInterval) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration(window, screen, duration)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:startCustomAnimationToEnterFullScreenOnScreen:withDuration:"), auto_cast windowStartCustomAnimationToEnterFullScreenOnScreenWithDuration, "v@:@@d")
	}
	if template.windowDidFailToEnterFullScreen != nil {
		windowDidFailToEnterFullScreen :: proc "c" (self: id, window: ^Window) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidFailToEnterFullScreen(window)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidFailToEnterFullScreen:"), auto_cast windowDidFailToEnterFullScreen, "v@:@")
	}
	if template.customWindowsToExitFullScreenForWindow != nil {
		customWindowsToExitFullScreenForWindow :: proc "c" (self: id, window: ^Window) -> ^Array {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.customWindowsToExitFullScreenForWindow(window)
		}
		class_addMethod(class, intrinsics.objc_find_selector("customWindowsToExitFullScreenForWindow:"), auto_cast customWindowsToExitFullScreenForWindow, "@@:@")
	}
	if template.windowStartCustomAnimationToExitFullScreenWithDuration != nil {
		windowStartCustomAnimationToExitFullScreenWithDuration :: proc "c" (self: id, window: ^Window, duration: TimeInterval) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowStartCustomAnimationToExitFullScreenWithDuration(window, duration)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:startCustomAnimationToExitFullScreenWithDuration:"), auto_cast windowStartCustomAnimationToExitFullScreenWithDuration, "v@:@d")
	}
	if template.windowDidFailToExitFullScreen != nil {
		windowDidFailToExitFullScreen :: proc "c" (self: id, window: ^Window) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidFailToExitFullScreen(window)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidFailToExitFullScreen:"), auto_cast windowDidFailToExitFullScreen, "v@:@")
	}
	if template.windowWillMove != nil {
		windowWillMove :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillMove(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillMove:"), auto_cast windowWillMove, "v@:@")
	}
	if template.windowDidMove != nil {
		windowDidMove :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidMove(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidMove:"), auto_cast windowDidMove, "v@:@")
	}
	if template.windowDidChangeScreen != nil {
		windowDidChangeScreen :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeScreen(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeScreen:"), auto_cast windowDidChangeScreen, "v@:@")
	}
	if template.windowDidChangeScreenProfile != nil {
		windowDidChangeScreenProfile :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeScreenProfile(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeScreenProfile:"), auto_cast windowDidChangeScreenProfile, "v@:@")
	}
	if template.windowDidChangeBackingProperties != nil {
		windowDidChangeBackingProperties :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeBackingProperties(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeBackingProperties:"), auto_cast windowDidChangeBackingProperties, "v@:@")
	}
	if template.windowShouldClose != nil {
		windowShouldClose :: proc "c" (self:id, sender: ^Window) -> BOOL {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldClose(sender)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowShouldClose:"), auto_cast windowShouldClose, "B@:@")
	}
	if template.windowWillClose != nil {
		windowWillClose :: proc "c" (self:id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillClose(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillClose:"), auto_cast windowWillClose, "v@:@")
	}
	if template.windowDidBecomeKey != nil {
		windowDidBecomeKey :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidBecomeKey(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidBecomeKey:"), auto_cast windowDidBecomeKey, "v@:@")
	}
	if template.windowDidResignKey != nil {
		windowDidResignKey :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidResignKey(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidResignKey:"), auto_cast windowDidResignKey, "v@:@")
	}
	if template.windowDidBecomeMain != nil {
		windowDidBecomeMain :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidBecomeMain(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidBecomeMain:"), auto_cast windowDidBecomeMain, "v@:@")
	}
	if template.windowDidResignMain != nil {
		windowDidResignMain :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidResignMain(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidResignMain:"), auto_cast windowDidResignMain, "v@:@")
	}
	if template.windowWillReturnFieldEditorToObject != nil {
		windowWillReturnFieldEditorToObject :: proc "c" (self:id, sender: ^Window, client: id) -> id {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillReturnFieldEditorToObject(sender, client)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillReturnFieldEditor:toObject:"), auto_cast windowWillReturnFieldEditorToObject, "@@:@@")
	}
	if template.windowDidUpdate != nil {
		windowDidUpdate :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidUpdate(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidUpdate:"), auto_cast windowDidUpdate, "v@:@")
	}
	if template.windowDidExpose != nil {
		windowDidExpose :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidExpose(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidExpose:"), auto_cast windowDidExpose, "v@:@")
	}
	if template.windowDidChangeOcclusionState != nil {
		windowDidChangeOcclusionState :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidChangeOcclusionState(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidChangeOcclusionState:"), auto_cast windowDidChangeOcclusionState, "v@:@")
	}
	if template.windowShouldDragDocumentWithEventFromWithPasteboard != nil {
		windowShouldDragDocumentWithEventFromWithPasteboard :: proc "c" (self: id, window: ^Window, event: ^Event, dragImageLocation: Point, pasteboard: ^Pasteboard) -> BOOL {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldDragDocumentWithEventFromWithPasteboard(window, event, dragImageLocation, pasteboard)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:shouldDragDocumentWithEvent:from:withPasteboard:"), auto_cast windowShouldDragDocumentWithEventFromWithPasteboard, "B@:@@"+_POINT_ENCODING+"@")
	}
	if template.windowWillReturnUndoManager != nil {
		windowWillReturnUndoManager :: proc "c" (self: id, window: ^Window) -> ^UndoManager {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillReturnUndoManager(window)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillReturnUndoManager:"), auto_cast windowWillReturnUndoManager, "@@:@")
	}
	if template.windowShouldPopUpDocumentPathMenu != nil {
		windowShouldPopUpDocumentPathMenu :: proc "c" (self: id, window: ^Window, menu: ^Menu) -> BOOL {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowShouldPopUpDocumentPathMenu(window, menu)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:shouldPopUpDocumentPathMenu:"), auto_cast windowShouldPopUpDocumentPathMenu, "B@:@@")
	}
	if template.windowWillEncodeRestorableState != nil {
		windowWillEncodeRestorableState :: proc "c" (self: id, window: ^Window, state: ^Coder) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillEncodeRestorableState(window, state)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:willEncodeRestorableState:"), auto_cast windowWillEncodeRestorableState, "v@:@@")
	}
	if template.windowDidEncodeRestorableState != nil {
		windowDidEncodeRestorableState :: proc "c" (self: id, window: ^Window, state: ^Coder) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidEncodeRestorableState(window, state)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:didDecodeRestorableState:"), auto_cast windowDidEncodeRestorableState, "v@:@@")
	}
	if template.windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize != nil {
		windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize :: proc "c" (self: id, window: ^Window, maxPreferredFrameSize: Size, maxAllowedFrameSize: Size) -> Size {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			return del.windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize(window, maxPreferredFrameSize, maxPreferredFrameSize)
		}
		class_addMethod(class, intrinsics.objc_find_selector("window:willResizeForVersionBrowserWithMaxPreferredSize:maxAllowedSize:"), auto_cast windowWillResizeForVersionBrowserWithMaxPreferredSizeMaxAllowedSize, _SIZE_ENCODING+"@:@"+_SIZE_ENCODING+_SIZE_ENCODING)
	}
	if template.windowWillEnterVersionBrowser != nil {
		windowWillEnterVersionBrowser :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillEnterVersionBrowser(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillEnterVersionBrowser:"), auto_cast windowWillEnterVersionBrowser, "v@:@")
	}
	if template.windowDidEnterVersionBrowser != nil {
		windowDidEnterVersionBrowser :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidEnterVersionBrowser(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidEnterVersionBrowser:"), auto_cast windowDidEnterVersionBrowser, "v@:@")
	}
	if template.windowWillExitVersionBrowser != nil {
		windowWillExitVersionBrowser :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowWillExitVersionBrowser(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowWillExitVersionBrowser:"), auto_cast windowWillExitVersionBrowser, "v@:@")
	}
	if template.windowDidExitVersionBrowser != nil {
		windowDidExitVersionBrowser :: proc "c" (self: id, notification: ^Notification) {
			del := cast(^_WindowDelegateInternal)object_getIndexedIvars(self)
			context = del._context
			del.windowDidExitVersionBrowser(notification)
		}
		class_addMethod(class, intrinsics.objc_find_selector("windowDidExitVersionBrowser:"), auto_cast windowDidExitVersionBrowser, "v@:@")
	}

	objc_registerClassPair(class)
	del := class_createInstance(class, size_of(_WindowDelegateInternal))
	del_internal := cast(^_WindowDelegateInternal)object_getIndexedIvars(del)
	del_internal^ = {
		template,
		delegate_context.(runtime.Context) or_else runtime.default_context(),
	}

	return cast(^WindowDelegate)del
}

@(objc_class="CALayer")
Layer :: struct { using _: Object }

@(objc_type=Layer, objc_name="contentsScale")
Layer_contentsScale :: proc "c" (self: ^Layer) -> Float {
	return msgSend(Float, self, "contentsScale")
}
@(objc_type=Layer, objc_name="setContentsScale")
Layer_setContentsScale :: proc "c" (self: ^Layer, scale: Float) {
	msgSend(nil, self, "setContentsScale:", scale)
}
@(objc_type=Layer, objc_name="frame")
Layer_frame :: proc "c" (self: ^Layer) -> Rect {
	return msgSend(Rect, self, "frame")
}
@(objc_type=Layer, objc_name="addSublayer")
Layer_addSublayer :: proc "c" (self: ^Layer, layer: ^Layer) {
	msgSend(nil, self, "addSublayer:", layer)
}

@(objc_class="NSResponder")
Responder :: struct {using _: Object}

@(objc_class="NSView")
View :: struct {using _: Responder}


@(objc_type=View, objc_name="initWithFrame")
View_initWithFrame :: proc "c" (self: ^View, frame: Rect) -> ^View {
	return msgSend(^View, self, "initWithFrame:", frame)
}
@(objc_type=View, objc_name="bounds")
View_bounds :: proc "c" (self: ^View) -> Rect {
	return msgSend(Rect, self, "bounds")
}
@(objc_type=View, objc_name="layer")
View_layer :: proc "c" (self: ^View) -> ^Layer {
	return msgSend(^Layer, self, "layer")
}
@(objc_type=View, objc_name="setLayer")
View_setLayer :: proc "c" (self: ^View, layer: ^Layer) {
	msgSend(nil, self, "setLayer:", layer)
}
@(objc_type=View, objc_name="wantsLayer")
View_wantsLayer :: proc "c" (self: ^View) -> BOOL {
	return msgSend(BOOL, self, "wantsLayer")
}
@(objc_type=View, objc_name="setWantsLayer")
View_setWantsLayer :: proc "c" (self: ^View, wantsLayer: BOOL) {
	msgSend(nil, self, "setWantsLayer:", wantsLayer)
}
@(objc_type=View, objc_name="convertPointFromView")
View_convertPointFromView :: proc "c" (self: ^View, point: Point, view: ^View) -> Point {
	return msgSend(Point, self, "convertPoint:fromView:", point, view)
}
@(objc_type=View, objc_name="addSubview")
View_addSubview :: proc "c" (self: ^View, view: ^View) {
	msgSend(nil, self, "addSubview:", view)
}

@(objc_class="NSWindow")
Window :: struct {using _: Responder}

@(objc_type=Window, objc_name="alloc", objc_is_class_method=true)
Window_alloc :: proc "c" () -> ^Window {
	return msgSend(^Window, Window, "alloc")
}

@(objc_type=Window, objc_name="initWithContentRect")
Window_initWithContentRect :: proc (self: ^Window, contentRect: Rect, styleMask: WindowStyleMask, backing: BackingStoreType, doDefer: BOOL) -> ^Window {
	return msgSend(^Window, self, "initWithContentRect:styleMask:backing:defer:", contentRect, styleMask, backing, doDefer)
}
@(objc_type=Window, objc_name="contentView")
Window_contentView :: proc "c" (self: ^Window) -> ^View {
	return msgSend(^View, self, "contentView")
}
@(objc_type=Window, objc_name="setContentView")
Window_setContentView :: proc "c" (self: ^Window, content_view: ^View) {
	msgSend(nil, self, "setContentView:", content_view)
}
@(objc_type=Window, objc_name="contentLayoutRect")
Window_contentLayoutRect :: proc "c" (self: ^Window) -> Rect {
	return msgSend(Rect, self, "contentLayoutRect")
}
@(objc_type=Window, objc_name="frame")
Window_frame :: proc "c" (self: ^Window) -> Rect {
	return msgSend(Rect, self, "frame")
}
@(objc_type=Window, objc_name="setFrame")
Window_setFrame :: proc "c" (self: ^Window, frame: Rect) {
	msgSend(nil, self, "setFrame:", frame)
}
@(objc_type=Window, objc_name="opaque")
Window_opaque :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "opaque")
}
@(objc_type=Window, objc_name="setOpaque")
Window_setOpaque :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setOpaque:", ok)
}
@(objc_type=Window, objc_name="backgroundColor")
Window_backgroundColor :: proc "c" (self: ^Window) -> ^Color {
	return msgSend(^Color, self, "backgroundColor")
}
@(objc_type=Window, objc_name="setBackgroundColor")
Window_setBackgroundColor :: proc "c" (self: ^Window, color: ^Color) {
	msgSend(nil, self, "setBackgroundColor:", color)
}
@(objc_type=Window, objc_name="makeKeyAndOrderFront")
Window_makeKeyAndOrderFront :: proc "c" (self: ^Window, key: ^Object) {
	msgSend(nil, self, "makeKeyAndOrderFront:", key)
}
@(objc_type=Window, objc_name="setTitle")
Window_setTitle :: proc "c" (self: ^Window, title: ^String) {
	msgSend(nil, self, "setTitle:", title)
}
@(objc_type=Window, objc_name="setTitlebarAppearsTransparent")
Window_setTitlebarAppearsTransparent :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setTitlebarAppearsTransparent:", ok)
}
@(objc_type=Window, objc_name="setMovable")
Window_setMovable :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setMovable:", ok)
}
@(objc_type=Window, objc_name="setMovableByWindowBackground")
Window_setMovableByWindowBackground :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setMovableByWindowBackground:", ok)
}
@(objc_type=Window, objc_name="setStyleMask")
Window_setStyleMask :: proc "c" (self: ^Window, style_mask: WindowStyleMask) {
	msgSend(nil, self, "setStyleMask:", style_mask)
}
@(objc_type=Window, objc_name="close")
Window_close :: proc "c" (self: ^Window) {
	msgSend(nil, self, "close")
}
@(objc_type=Window, objc_name="setDelegate")
Window_setDelegate :: proc "c" (self: ^Window, delegate: ^WindowDelegate) {
	msgSend(nil, self, "setDelegate:", delegate)
}
@(objc_type=Window, objc_name="backingScaleFactor")
Window_backingScaleFactor :: proc "c" (self: ^Window) -> Float {
	return msgSend(Float, self, "backingScaleFactor")
}
@(objc_type=Window, objc_name="setWantsLayer")
Window_setWantsLayer :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setWantsLayer:", ok)
}
@(objc_type=Window, objc_name="setIsMiniaturized")
Window_setIsMiniaturized :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setIsMiniaturized:", ok)
}
@(objc_type=Window, objc_name="setIsVisible")
Window_setIsVisible :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setIsVisible:", ok)
}
@(objc_type=Window, objc_name="setIsZoomed")
Window_setIsZoomed :: proc "c" (self: ^Window, ok: BOOL) {
	msgSend(nil, self, "setIsZoomed:", ok)
}
@(objc_type=Window, objc_name="isZoomable")
Window_isZoomable :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "isZoomable")
}
@(objc_type=Window, objc_name="isResizable")
Window_isResizable :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "isResizable")
}
@(objc_type=Window, objc_name="isModalPanel")
Window_isModalPanel :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "isModalPanel")
}
@(objc_type=Window, objc_name="isMiniaturizable")
Window_isMiniaturizable :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "isMiniaturizable")
}
@(objc_type=Window, objc_name="isFloatingPanel")
Window_isFloatingPanel :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "isFloatingPanel")
}
@(objc_type=Window, objc_name="hasCloseBox")
Window_hasCloseBox :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "hasCloseBox")
}
@(objc_type=Window, objc_name="hasTitleBar")
Window_hasTitleBar :: proc "c" (self: ^Window) -> BOOL {
	return msgSend(BOOL, self, "hasTitleBar")
}
@(objc_type=Window, objc_name="orderedIndex")
Window_orderedIndex :: proc "c" (self: ^Window) -> Integer {
	return msgSend(Integer, self, "orderedIndex")
}
@(objc_type=Window, objc_name="setMinSize")
Window_setMinSize :: proc "c" (self: ^Window, size: Size) {
	msgSend(nil, self, "setMinSize:", size)
}
@(objc_type=Window, objc_name="setTitleVisibility")
Window_setTitleVisibility :: proc "c" (self: ^Window, visibility: Window_Title_Visibility) {
	msgSend(nil, self, "setTitleVisibility:", visibility)
}
@(objc_type=Window, objc_name="performZoom")
Window_performZoom :: proc "c" (self: ^Window) {
	msgSend(nil, self, "performZoom:", self)
}
@(objc_type=Window, objc_name="setFrameAutosaveName")
NSWindow_setFrameAutosaveName :: proc "c" (self: ^Window, name: ^String) {
	msgSend(nil, self, "setFrameAutosaveName:", name)
}
@(objc_type=Window, objc_name="performWindowDragWithEvent")
Window_performWindowDragWithEvent :: proc "c" (self: ^Window, event: ^Event) {
	msgSend(nil, self, "performWindowDragWithEvent:", event)
}
@(objc_type=Window, objc_name="setToolbar")
Window_setToolbar :: proc "c" (self: ^Window, toolbar: ^Toolbar) {
	msgSend(nil, self, "setToolbar:", toolbar)
}