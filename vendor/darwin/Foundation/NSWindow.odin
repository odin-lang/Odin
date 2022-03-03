package objc_Foundation

import NS "vendor:darwin/Foundation"

Rect :: struct {
	x, y: f64,
	width, height: f64,
}

@(objc_class="NSColor")
Color :: struct {using _: Object}

@(objc_class="CALayer")
Layer :: struct { using _: NS.Object }

@(objc_class="NSResponder")
Responder :: struct {using _: Object}

@(objc_class="NSView")
View :: struct {using _: Responder}

@(objc_type=View, objc_name="layer")
View_layer :: proc(self: ^View) -> ^Layer {
	return msgSend(^Layer, self, "layer")
}
@(objc_type=View, objc_name="setLayer")
View_setLayer :: proc(self: ^View, layer: ^Layer) {
	msgSend(nil, self, "setLayer:", layer)
}
@(objc_type=View, objc_name="setSubLayer")
View_setSubLayer :: proc(self: ^View, layer: ^Layer) {
	msgSend(nil, self, "setSubLayer:", layer)
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

@(objc_type=Window, objc_name="contentView")
Window_contentView :: proc(self: ^Window) -> ^View {
	return msgSend(^View, self, "contentView")
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
