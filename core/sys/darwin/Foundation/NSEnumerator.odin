package objc_Foundation

import "core:c"
import "base:intrinsics"

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


@(objc_type=FastEnumeration, objc_name="alloc", objc_is_class_method=true)
FastEnumeration_alloc :: proc "c" () -> ^FastEnumeration {
	return msgSend(^FastEnumeration, FastEnumeration, "alloc")
}

@(objc_type=FastEnumeration, objc_name="init")
FastEnumeration_init :: proc "c" (self: ^FastEnumeration) -> ^FastEnumeration {
	return msgSend(^FastEnumeration, self, "init")
}


@(objc_type=FastEnumeration, objc_name="countByEnumerating")
FastEnumeration_countByEnumerating :: proc "c" (self: ^FastEnumeration, state: ^FastEnumerationState, buffer: [^]^Object, len: UInteger) -> UInteger {
	return msgSend(UInteger, self, "countByEnumeratingWithState:objects:count:", state, buffer, len)
}

Enumerator_nextObject :: proc "c" (self: ^$E/Enumerator($T)) -> T {
	return msgSend(T, self, "nextObject")
}

Enumerator_allObjects :: proc "c" (self: ^$E/Enumerator($T)) -> (all: ^Array) {
	return msgSend(type_of(all), self, "allObjects")
}

Enumerator_iterator :: proc "contextless" (self: ^$E/Enumerator($T)) -> (obj: T, ok: bool) {
	obj = msgSend(T, self, "nextObject")
	ok = obj != nil
	return
}
