package objc_Foundation

@(objc_class="NSNotification")
Notification :: struct{using _: Object}


@(objc_type=Notification, objc_name="alloc", objc_is_class_method=true)
Notification_alloc :: proc() -> ^Notification {
	return msgSend(^Notification, Notification, "alloc")
}

@(objc_type=Notification, objc_name="init")
Notification_init :: proc(self: ^Notification) -> ^Notification {
	return msgSend(^Notification, self, "init")
}

@(objc_type=Notification, objc_name="name")
Notification_name :: proc(self: ^Notification) -> ^String {
	return msgSend(^String, self, "name")
}

@(objc_type=Notification, objc_name="object")
Notification_object :: proc(self: ^Notification) -> ^Object {
	return msgSend(^Object, self, "object")
}

@(objc_type=Notification, objc_name="userInfo")
Notification_userInfo :: proc(self: ^Notification) -> ^Dictionary {
	return msgSend(^Dictionary, self, "userInfo")
}