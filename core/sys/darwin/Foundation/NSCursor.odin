package objc_Foundation

@(objc_class="NSCursor")
Cursor :: struct {using _: Object}

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

