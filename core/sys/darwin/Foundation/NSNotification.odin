package objc_Foundation

@(objc_class="NSNotification")
Notification :: struct{using _: Object}

Notification_name :: proc(self: ^Notification) -> ^String {
	return msgSend(^String, self, "name")
}

Notification_object :: proc(self: ^Notification) -> ^Object {
	return msgSend(^Object, self, "object")
}

Notification_userInfo :: proc(self: ^Notification) -> ^Dictionary {
	return msgSend(^Dictionary, self, "userInfo")
}