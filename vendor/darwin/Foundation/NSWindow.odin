package objc_Foundation

import NS "vendor:darwin/Foundation"

Rect :: struct {
	using origin: Point,
	using size: Size,
}

WindowStyleFlag :: enum NS.UInteger {
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
WindowStyleMask :: distinct bit_set[WindowStyleFlag; NS.UInteger]
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

BackingStoreType :: enum NS.UInteger {
	Retained    = 0,
	Nonretained = 1,
	Buffered    = 2,
}

@(objc_class="NSColor")
Color :: struct {using _: Object}

@(objc_class="CALayer")
Layer :: struct { using _: NS.Object }

@(objc_type=Layer, objc_name="contentsScale")
Layer_contentsScale :: proc(self: ^Layer) -> Float {
	return msgSend(Float, self, "contentsScale")
}
@(objc_type=Layer, objc_name="setContentsScale")
Layer_setContentsScale :: proc(self: ^Layer, scale: Float) {
	msgSend(nil, self, "setContentsScale:", scale)
}
@(objc_type=Layer, objc_name="frame")
Layer_frame :: proc(self: ^Layer) -> Rect {
	return msgSend(Rect, self, "frame")
}
@(objc_type=Layer, objc_name="addSublayer")
Layer_addSublayer :: proc(self: ^Layer, layer: ^Layer) {
	msgSend(nil, self, "addSublayer:", layer)
}

@(objc_class="NSResponder")
Responder :: struct {using _: Object}

@(objc_class="NSView")
View :: struct {using _: Responder}


@(objc_type=View, objc_name="initWithFrame")
View_initWithFrame :: proc(self: ^View, frame: Rect) -> ^View {
	return msgSend(^View, self, "initWithFrame:", frame)
}
@(objc_type=View, objc_name="layer")
View_layer :: proc(self: ^View) -> ^Layer {
	return msgSend(^Layer, self, "layer")
}
@(objc_type=View, objc_name="setLayer")
View_setLayer :: proc(self: ^View, layer: ^Layer) {
	msgSend(nil, self, "setLayer:", layer)
}
@(objc_type=View, objc_name="wantsLayer")
View_wantsLayer :: proc(self: ^View) -> BOOL {
	return msgSend(BOOL, self, "wantsLayer")
}
@(objc_type=View, objc_name="setWantsLayer")
View_setWantsLayer :: proc(self: ^View, wantsLayer: BOOL) {
	msgSend(nil, self, "setWantsLayer:", wantsLayer)
}

@(objc_class="NSWindow")
Window :: struct {using _: Responder}

@(objc_type=Window, objc_name="alloc", objc_is_class_method=true)
Window_alloc :: proc() -> ^Window {
	return msgSend(^Window, Window, "alloc")
}

@(objc_type=Window, objc_name="initWithContentRect")
Window_initWithContentRect :: proc (self: ^Window, contentRect: Rect, styleMask: WindowStyleMask, backing: BackingStoreType, doDefer: bool) -> ^Window {
	return msgSend(^Window, self, "initWithContentRect:styleMask:backing:defer:", contentRect, styleMask, backing, doDefer)
}
@(objc_type=Window, objc_name="contentView")
Window_contentView :: proc(self: ^Window) -> ^View {
	return msgSend(^View, self, "contentView")
}
@(objc_type=Window, objc_name="setContentView")
Window_setContentView :: proc(self: ^Window, content_view: ^View) {
	msgSend(nil, self, "setContentView:", content_view)
}
@(objc_type=Window, objc_name="frame")
Window_frame :: proc(self: ^Window) -> Rect {
	return msgSend(Rect, self, "frame")
}
@(objc_type=Window, objc_name="setFrame")
Window_setFrame :: proc(self: ^Window, frame: Rect) {
	msgSend(nil, self, "setFrame:", frame)
}
@(objc_type=Window, objc_name="opaque")
Window_opaque :: proc(self: ^Window) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "opaque")
}
@(objc_type=Window, objc_name="setOpaque")
Window_setOpaque :: proc(self: ^Window, ok: NS.BOOL) {
	msgSend(nil, self, "setOpaque:", ok)
}
@(objc_type=Window, objc_name="backgroundColor")
Window_backgroundColor :: proc(self: ^Window) -> ^NS.Color {
	return msgSend(^NS.Color, self, "backgroundColor")
}
@(objc_type=Window, objc_name="setBackgroundColor")
Window_setBackgroundColor :: proc(self: ^Window, color: ^NS.Color) {
	msgSend(nil, self, "setBackgroundColor:", color)
}
@(objc_type=Window, objc_name="makeKeyAndOrderFront")
Window_makeKeyAndOrderFront :: proc(self: ^Window, key: ^NS.Object) {
	msgSend(nil, self, "makeKeyAndOrderFront:", key)
}
@(objc_type=Window, objc_name="setTitle")
Window_setTitle :: proc(self: ^Window, title: ^NS.String) {
	msgSend(nil, self, "setTitle:", title)
}
@(objc_type=Window, objc_name="close")
Window_close :: proc(self: ^Window) {
	msgSend(nil, self, "close")
}
