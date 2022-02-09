package objc_Foundation

import "core:c"
import "core:intrinsics"

FastEnumerationState :: struct #packed {
	state:        c.ulong,
	itemsPtr:     [^]^Object,
	mutationsPtr: [^]c.ulong,
	extra:        [5]c.ulong,
}

@(objc_class="NSFastEnumeration")
FastEnumeration :: struct {using _: Object}

@(objc_class="NSEnumerator")
Enumerator :: struct($T: typeid) where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	using _: FastEnumeration,
}

FastEnumeration_countByEnumerating :: proc(self: ^FastEnumeration, state: ^FastEnumerationState, buffer: [^]^Object, len: UInteger) -> UInteger {
	return msgSend(UInteger, self, "countByEnumeratingWithState:objects:count:", state, buffer, len)
}

Enumerator_nextObject :: proc(self: ^$E/Enumerator($T)) -> T {
	return msgSend(T, self, "nextObject")
}

Enumerator_allObjects :: proc(self: ^$E/Enumerator($T)) -> (all: Array(T)) {
	return msgSend(type_of(all), self, "allObjects")
}

Enumerator_iterator :: proc(self: ^$E/Enumerator($T)) -> (obj: T, ok: bool) {
	obj = msgSend(T, self, "nextObject")
	ok = obj != nil
	return
}
