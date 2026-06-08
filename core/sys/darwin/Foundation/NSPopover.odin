package objc_Foundation

PopoverBehavior :: enum UInteger {
	ApplicationDefined = 0,
	Transient          = 1,
	Semitransient      = 2,
}

@(objc_class="NSPopover")
Popover :: struct {using _: Object}

@(objc_type=Popover, objc_name="alloc", objc_is_class_method=true)
Popover_alloc :: proc "c" () -> ^Popover {
	return msgSend(^Popover, Popover, "alloc")
}

@(objc_type=Popover, objc_name="contentViewController")
Popover_contentViewController :: proc "c" (self: ^Popover) -> ^ViewController {
	return msgSend(^ViewController, self, "contentViewController")
}
@(objc_type=Popover, objc_name="setContentViewController")
Popover_setContentViewController :: proc "c" (self: ^Popover, viewController: ^ViewController) {
	msgSend(nil, self, "setContentViewController:", viewController)
}

@(objc_type=Popover, objc_name="behavior")
Popover_behavior :: proc "c" (self: ^Popover) -> PopoverBehavior {
	return msgSend(PopoverBehavior, self, "behavior")
}
@(objc_type=Popover, objc_name="setBehavior")
Popover_setBehavior :: proc "c" (self: ^Popover, behavior: PopoverBehavior) {
	msgSend(nil, self, "setBehavior:", behavior)
}

@(objc_type=Popover, objc_name="showRelativeToRect")
Popover_showRelativeToRect :: proc "c" (self: ^Popover, positioningRect: Rect, positioningView: ^View, preferredEdge: RectEdge) {
	msgSend(nil, self, "showRelativeToRect:ofView:preferredEdge:", positioningRect, positioningView, preferredEdge)
}

@(objc_type=Popover, objc_name="positioningRect")
Popover_positioningRect :: proc "c" (self: ^Popover) -> Rect {
	return msgSend(Rect, self, "positioningRect")
}
@(objc_type=Popover, objc_name="setPositioningRect")
Popover_setPositioningRect :: proc "c" (self: ^Popover, positioningRect: Rect) {
	msgSend(nil, self, "setPositioningRect:", positioningRect)
}

@(objc_type=Popover, objc_name="appearance")
Popover_appearance :: proc "c" (self: ^Popover) -> Appearance {
	return msgSend(Appearance, self, "appearance")
}
@(objc_type=Popover, objc_name="setAppearance")
Popover_setAppearance :: proc "c" (self: ^Popover, appearance: ^Appearance) {
	msgSend(nil, self, "setAppearance:", appearance)
}

// Skipping the `effectiveAppearance` instance property for now.
// In the future it can go here.

@(objc_type=Popover, objc_name="animates")
Popover_animates :: proc "c" (self: ^Popover) -> BOOL {
	return msgSend(BOOL, self, "animates")
}
@(objc_type=Popover, objc_name="setAnimates")
Popover_setAnimates :: proc "c" (self: ^Popover, animates: BOOL) {
	msgSend(nil, self, "setAnimates:", animates)
}

@(objc_type=Popover, objc_name="contentSize")
Popover_contentSize :: proc "c" (self: ^Popover) -> Size {
	return msgSend(Size, self, "contentSize")
}
@(objc_type=Popover, objc_name="setContentSize")
Popover_setContentSize :: proc "c" (self: ^Popover, size: Size) {
	msgSend(nil, self, "setContentSize:", size)
}

@(objc_type=Popover, objc_name="isShown")
Popover_isShown :: proc "c" (self: ^Popover) -> BOOL {
	return msgSend(BOOL, self, "isShown")
}
@(objc_type=Popover, objc_name="setShown")
Popover_setShown :: proc "c" (self: ^Popover, shown: BOOL) {
	msgSend(nil, self, "setShown:", shown)
}

@(objc_type=Popover, objc_name="isDetached")
Popover_isDetached :: proc "c" (self: ^Popover) -> BOOL {
	return msgSend(BOOL, self, "isDetached")
}
@(objc_type=Popover, objc_name="setDetached")
Popover_setDetached :: proc "c" (self: ^Popover, detached: BOOL) {
	msgSend(nil, self, "setDetached:", detached)
}

// Skipping the `performClose` instance method for now.
// In the future it can go here.

@(objc_type=Popover, objc_name="close")
Popover_close :: proc "c" (self: ^Popover) {
	msgSend(nil, self, "close")
}

// Skipping the `delegate` instance property for now.
// In the future it can go here.

// Skipping the `NSPopoverCloseReasonKey` global variable, the
// `NSPopoverCloseReasonValue` constants, and all `NSNotificationName`
// global variables for now.
// In the future they can go here.

@(objc_type=Popover, objc_name="init")
Popover_init :: proc "c" (self: ^Popover) -> ^Popover {
	return msgSend(^Popover, self, "init")
}

@(objc_type=Popover, objc_name="initWithCoder")
Popover_initWithCoder :: proc "c" (self: ^Popover, coder: ^Coder) -> ^Popover {
	return msgSend(^Popover, self, "initWithCoder:", coder)
}

@(objc_type=Popover, objc_name="hasFullSizeContent")
Popover_hasFullSizeContent :: proc "c" (self: ^Popover) -> BOOL {
	return msgSend(BOOL, self, "hasFullSizeContent")
}
@(objc_type=Popover, objc_name="setHasFullSizeContent")
Popover_setHasFullSizeContent :: proc "c" (self: ^Popover, hasFullSizeContent: BOOL) {
	msgSend(nil, self, "setHasFullSizeContent:", hasFullSizeContent)
}

// Skipping the `showRelativeToToolbarItem:` instance method for now.
// In the future it can go here.

@(objc_type=Popover, objc_name="window")
Popover_fittingSize :: proc "c" (self: ^Popover) -> ^Window {
	return msgSend(^Window, self, "window")
}