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

Condition_wait :: proc(self: ^Condition) {
	msgSend(nil, self, "wait")
}

Condition_waitUntilDate :: proc(self: ^Condition, limit: ^Date) -> BOOL {
	return msgSend(BOOL, self, "waitUntilDate:", limit)
}

Condition_signal :: proc(self: ^Condition) {
	msgSend(nil, self, "signal")
}

Condition_broadcast :: proc(self: ^Condition) {
	msgSend(nil, self, "broadcast")
}