package objc_Foundation

@(objc_class="NSCursor")
Cursor :: struct {using _: Object}

@(objc_type=Cursor, objc_name="alloc", objc_is_class_method=true)
Cursor_alloc :: proc "c" () -> ^Cursor {
	return msgSend(^Cursor, Cursor, "alloc")
}
@(objc_type=Cursor, objc_name="initWithImage")
Cursor_initWithImage :: proc "c" (self: ^Cursor, image: ^Image, hotSpot: Point) -> ^Cursor {
	return msgSend(^Cursor, self, "initWithImage:hotSpot:", image, hotSpot)
}
@(objc_type=Cursor, objc_name="hide", objc_is_class_method=true)
Cursor_hide :: proc() {
	msgSend(nil, Cursor, "hide")
}
@(objc_type=Cursor, objc_name="unhide", objc_is_class_method=true)
Cursor_unhide :: proc() {
	msgSend(nil, Cursor, "unhide")
}
@(objc_type=Cursor, objc_name="setHiddenUntilMouseMoves", objc_is_class_method=true)
Cursor_setHiddenUntilMouseMoves :: proc(flag: BOOL) {
	msgSend(nil, Cursor, "setHiddenUntilMouseMoves:", flag)
}

@(objc_type=Cursor, objc_name="set")
Cursor_set :: proc(self: ^Cursor) {
	msgSend(EventType, self, "set")
}
@(objc_type=Cursor, objc_name="currentCursor", objc_is_class_method=true)
Cursor_currentCursor :: proc "c" () -> ^Cursor {
	return msgSend(^Cursor, Cursor, "currentCursor")
}
@(objc_type=Cursor, objc_name="IBeamCursor", objc_is_class_method=true)
Cursor_IBeamCursor :: proc "c" () -> ^Cursor {
	return msgSend(^Cursor, Cursor, "IBeamCursor")
}
@(objc_type=Cursor, objc_name="arrowCursor", objc_is_class_method=true)
Cursor_arrowCursor :: proc "c" () -> ^Cursor {
	return msgSend(^Cursor, Cursor, "arrowCursor")
}
@(objc_type=Cursor, objc_name="pointingHandCursor", objc_is_class_method=true)
Cursor_pointingHandCursor :: proc "c" () -> ^Cursor {
	return msgSend(^Cursor, Cursor, "pointingHandCursor")
}

