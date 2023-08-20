package objc_Foundation

@(objc_class = "NSScreen")
Screen :: struct {
	using _: Object,
}

@(objc_type = Screen, objc_name = "main")
Screen_main :: proc "c" () -> ^Screen {
	return msgSend(^Screen, Screen, "main")
}

@(objc_type = Screen, objc_name = "frame")
Screen_frame :: proc "c" (self: ^Screen) -> ^Rect {
	return msgSend(^Rect, self, "main")
}
