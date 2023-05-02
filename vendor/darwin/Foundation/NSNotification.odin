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

NotificationName :: ^String

@(objc_class="NSNotificationCenter")
NotificationCenter :: struct{using _: Object}


@(objc_type=NotificationCenter, objc_name="alloc", objc_is_class_method=true)
NotificationCenter_alloc :: proc() -> ^NotificationCenter {
	return msgSend(^NotificationCenter, NotificationCenter, "alloc")
}

@(objc_type=NotificationCenter, objc_name="init")
NotificationCenter_init :: proc(self: ^NotificationCenter) -> ^NotificationCenter {
	return msgSend(^NotificationCenter, self, "init")
}

@(objc_type=NotificationCenter, objc_name="defaultCenter", objc_is_class_method=true)
NotificationCenter_defaultCenter :: proc() -> ^NotificationCenter {
	return msgSend(^NotificationCenter, NotificationCenter, "defaultCenter")
}

@(objc_type=NotificationCenter, objc_name="addObserver")
NotificationCenter_addObserverName :: proc(self: ^NotificationCenter, name: NotificationName, pObj: ^Object, pQueue: rawptr, block: ^Block) -> ^Object {
	return msgSend(^Object, self, "addObserverName:object:queue:block:", name, pObj, pQueue, block)
}
@(objc_type=NotificationCenter, objc_name="removeObserver")
NotificationCenter_removeObserver :: proc(self: ^NotificationCenter, pObserver: ^Object) {
	msgSend(nil, self, "removeObserver:", pObserver)
}