package objc_Foundation

@(objc_class="NSNotification")
Notification :: struct{using _: Object}


@(objc_type=Notification, objc_name="alloc", objc_is_class_method=true)
Notification_alloc :: proc "c" () -> ^Notification {
	return msgSend(^Notification, Notification, "alloc")
}

@(objc_type=Notification, objc_name="init")
Notification_init :: proc "c" (self: ^Notification) -> ^Notification {
	return msgSend(^Notification, self, "init")
}

@(objc_type=Notification, objc_name="name")
Notification_name :: proc "c" (self: ^Notification) -> ^String {
	return msgSend(^String, self, "name")
}

@(objc_type=Notification, objc_name="object")
Notification_object :: proc "c" (self: ^Notification) -> ^Object {
	return msgSend(^Object, self, "object")
}

@(objc_type=Notification, objc_name="userInfo")
Notification_userInfo :: proc "c" (self: ^Notification) -> ^Dictionary {
	return msgSend(^Dictionary, self, "userInfo")
}

NotificationName :: ^String

@(objc_class="NSNotificationCenter")
NotificationCenter :: struct{using _: Object}


@(objc_type=NotificationCenter, objc_name="alloc", objc_is_class_method=true)
NotificationCenter_alloc :: proc "c" () -> ^NotificationCenter {
	return msgSend(^NotificationCenter, NotificationCenter, "alloc")
}

@(objc_type=NotificationCenter, objc_name="init")
NotificationCenter_init :: proc "c" (self: ^NotificationCenter) -> ^NotificationCenter {
	return msgSend(^NotificationCenter, self, "init")
}

@(objc_type=NotificationCenter, objc_name="defaultCenter", objc_is_class_method=true)
NotificationCenter_defaultCenter :: proc "c" () -> ^NotificationCenter {
	return msgSend(^NotificationCenter, NotificationCenter, "defaultCenter")
}

@(objc_type=NotificationCenter, objc_name="addObserverForName")
NotificationCenter_addObserverForName :: proc{NotificationCenter_addObserverForName_old, NotificationCenter_addObserverForName_new}

NotificationCenter_addObserverForName_old :: proc "c" (self: ^NotificationCenter, name: NotificationName, pObj: ^Object, pQueue: rawptr, block: ^Block) -> ^Object {
	return msgSend(^Object, self, "addObserverForName:object:queue:usingBlock:", name, pObj, pQueue, block)
}

NotificationCenter_addObserverForName_new :: proc "c" (self: ^NotificationCenter, name: NotificationName, pObj: ^Object, pQueue: rawptr, block: ^Objc_Block) -> ^Object {
	return msgSend(^Object, self, "addObserverForName:object:queue:usingBlock:", name, pObj, pQueue, block)
}

@(objc_type=NotificationCenter, objc_name="addObserver")
NotificationCenter_addObserver :: proc "c" (self: ^NotificationCenter, observer: ^Object, selector: SEL, name: NotificationName, object: ^Object) {
	msgSend(nil, self, "addObserver:selector:name:object:", observer, selector, name, object)
}

@(objc_type=NotificationCenter, objc_name="removeObserver")
NotificationCenter_removeObserver :: proc "c" (self: ^NotificationCenter, pObserver: ^Object) {
	msgSend(nil, self, "removeObserver:", pObserver)
}