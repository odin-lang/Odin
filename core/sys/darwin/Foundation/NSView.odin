package objc_Foundation

@(objc_class="NSView")
View :: struct {using _: Responder}

@(objc_type=View, objc_name="alloc", objc_is_class_method=true)
View_alloc :: proc "c" () -> ^View {
	return msgSend(^View, View, "alloc")
}

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
@(objc_type=View, objc_name="isFlipped")
View_isFlipped :: proc "c" (self: ^View) -> BOOL {
	return msgSend(BOOL, self, "isFlipped")
}
@(objc_type=View, objc_name="setIsFlipped")
View_setIsFlipped :: proc "c" (self: ^View, flipped: BOOL) {
	msgSend(nil, self, "setIsFlipped:", flipped)
}
