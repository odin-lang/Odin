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
@(objc_type=View, objc_name="translatesAutoresizingMaskIntoConstraints")
View_translatesAutoresizingMaskIntoConstraints :: proc "c" (self: ^View) -> BOOL {
	return msgSend(BOOL, self, "translatesAutoresizingMaskIntoConstraints")
}
@(objc_type=View, objc_name="setTranslatesAutoresizingMaskIntoConstraints")
View_setTranslatesAutoresizingMaskIntoConstraints :: proc "c" (self: ^View, translatesAutoresizingMaskIntoConstraints: BOOL) {
	msgSend(nil, self, "setTranslatesAutoresizingMaskIntoConstraints:", translatesAutoresizingMaskIntoConstraints)
}
@(objc_type=View, objc_name="bottomAnchor")
View_bottomAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "bottomAnchor")
}
@(objc_type=View, objc_name="centerXAnchor")
View_centerXAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "centerXAnchor")
}
@(objc_type=View, objc_name="centerYAnchor")
View_centerYAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "centerYAnchor")
}
@(objc_type=View, objc_name="firstBaselineAnchor")
View_firstBaselineAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "firstBaselineAnchor")
}
@(objc_type=View, objc_name="heightAnchor")
View_heightAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "heightAnchor")
}
@(objc_type=View, objc_name="lastBaselineAnchor")
View_lastBaselineAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "lastBaselineAnchor")
}
@(objc_type=View, objc_name="leadingAnchor")
View_leadingAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "leadingAnchor")
}
@(objc_type=View, objc_name="leftAnchor")
View_leftAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "leftAnchor")
}
@(objc_type=View, objc_name="rightAnchor")
View_rightAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "rightAnchor")
}
@(objc_type=View, objc_name="topAnchor")
View_topAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "topAnchor")
}
@(objc_type=View, objc_name="trailingAnchor")
View_trailingAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "trailingAnchor")
}
@(objc_type=View, objc_name="widthAnchor")
View_widthAnchor :: proc "c" (self: ^View) -> ^LayoutAnchor {
	return msgSend(^LayoutAnchor, self, "widthAnchor")
}
@(objc_type=View, objc_name="layoutSubtreeIfNeeded")
View_layoutSubtreeIfNeeded :: proc "c" (self: ^View) {
	msgSend(nil, self, "layoutSubtreeIfNeeded")
}
@(objc_type=View, objc_name="fittingSize")
View_fittingSize :: proc "c" (self: ^View) -> Size {
	return msgSend(Size, self, "fittingSize")
}
@(objc_type=View, objc_name="window")
View_window :: proc "c" (self: ^View) -> ^Window {
	return msgSend(^Window, self, "window")
}
