package objc_Foundation

@(objc_class="NSCursor")
Cursor :: struct {using _: Object}

@(objc_type=Cursor, objc_name="hide", objc_is_class_method=true)
Cursor_hide :: proc() {
	msgSend(nil, Cursor, "hide")
}

@(objc_type=Cursor, objc_name="unhide", objc_is_class_method=true)
Cursor_unhide :: proc() {
	msgSend(nil, Cursor, "unhide")
}

@(objc_type=Cursor, objc_name="arrowCursor", objc_is_class_method=true)
Cursor_arrowCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "arrowCursor")
}

@(objc_type=Cursor, objc_name="IBeamCursor", objc_is_class_method=true)
Cursor_IBeamCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "IBeamCursor")
}

@(objc_type=Cursor, objc_name="closedHandCursor", objc_is_class_method=true)
Cursor_closedHandCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "closedHandCursor")
}

@(objc_type=Cursor, objc_name="pointingHandCursor", objc_is_class_method=true)
Cursor_pointingHandCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "pointingHandCursor")
}

@(objc_type=Cursor, objc_name="operationNotAllowedCursor", objc_is_class_method=true)
Cursor_operationNotAllowedCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "operationNotAllowedCursor")
}

@(objc_type=Cursor, objc_name="resizeUpDownCursor", objc_is_class_method=true)
Cursor_resizeUpDownCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "resizeUpDownCursor")
}

@(objc_type=Cursor, objc_name="resizeLeftRightCursor", objc_is_class_method=true)
Cursor_resizeLeftRightCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "resizeLeftRightCursor")
}

@(objc_type=Cursor, objc_name="currentCursor", objc_is_class_method=true)
Cursor_currentCursor :: proc() -> ^Cursor {
	return msgSend(^Cursor, Cursor, "currentCursor")
}

@(objc_type=Cursor, objc_name="set", objc_is_class_method=false)
Cursor_set :: proc(self: ^Cursor) {
	msgSend(nil, self, "set")
}
