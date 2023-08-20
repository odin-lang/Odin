package objc_Foundation

@(objc_class = "NSScreen")
Screen :: struct {
	using _: Object,
}

@(objc_type = Screen, objc_name = "mainScreen")
Screen_mainScreen :: proc "c" () -> ^Screen {
	return msgSend(^Screen, Screen, "mainScreen")
}

@(objc_type = Screen, objc_name = "deepestScreen")
Screen_deepestScreen :: proc "c" () -> ^Screen {
	return msgSend(^Screen, Screen, "deepestScreen")
}

@(objc_type = Screen, objc_name = "screens")
Screen_screens :: proc "c" () -> ^Screen {
	return msgSend(^Screen, Screen, "screens")
}

@(objc_type = Screen, objc_name = "frame")
Screen_frame :: proc "c" (self: ^Screen) -> Rect {
	return msgSend(Rect, self, "frame")
}
