package objc_Foundation

Locking :: struct($T: typeid) {using _: Object}

Locking_lock :: proc(self: ^Locking($T)) {
	msgSend(nil, self, "lock")
}
Locking_unlock :: proc(self: ^Locking($T)) {
	msgSend(nil, self, "unlock")
}

@(objc_class="NSCondition")
Condition :: struct {using _: Locking(Condition) }


@(objc_type=Condition, objc_name="alloc", objc_is_class_method=true)
Condition_alloc :: proc() -> ^Condition {
	return msgSend(^Condition, Condition, "alloc")
}

@(objc_type=Condition, objc_name="init")
Condition_init :: proc(self: ^Condition) -> ^Condition {
	return msgSend(^Condition, self, "init")
}

@(objc_type=Condition, objc_name="wait")
Condition_wait :: proc(self: ^Condition) {
	msgSend(nil, self, "wait")
}

@(objc_type=Condition, objc_name="waitUntilDate")
Condition_waitUntilDate :: proc(self: ^Condition, limit: ^Date) -> BOOL {
	return msgSend(BOOL, self, "waitUntilDate:", limit)
}

@(objc_type=Condition, objc_name="signal")
Condition_signal :: proc(self: ^Condition) {
	msgSend(nil, self, "signal")
}

@(objc_type=Condition, objc_name="broadcast")
Condition_broadcast :: proc(self: ^Condition) {
	msgSend(nil, self, "broadcast")
}

@(objc_type=Condition, objc_name="lock")
Condition_lock :: proc(self: ^Condition) {
	msgSend(nil, self, "lock")
}
@(objc_type=Condition, objc_name="unlock")
Condition_unlock :: proc(self: ^Condition) {
	msgSend(nil, self, "unlock")
}