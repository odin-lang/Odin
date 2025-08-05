package objc_Foundation
@(objc_class = "NSToolbar")

Toolbar :: struct { using _: Object }

@(objc_type = Toolbar, objc_name = "alloc", objc_is_class_method = true)
Toolbar_alloc :: proc "c" () -> ^Toolbar {
	return msgSend(^Toolbar, Toolbar, "alloc")
}

@(objc_type = Toolbar, objc_name = "init")
Toolbar_init :: proc "c" (self: ^Toolbar) -> ^Toolbar {
	return msgSend(^Toolbar, self, "init")
}
