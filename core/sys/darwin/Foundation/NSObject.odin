package objc_Foundation

import "core:intrinsics"

methodSignatureForSelector :: proc "c" (obj: ^Object, selector: SEL) -> rawptr {
	return msgSend(rawptr, obj, "methodSignatureForSelector:", selector)
}

respondsToSelector :: proc "c" (obj: ^Object, selector: SEL) -> BOOL {
	return msgSend(BOOL, obj, "respondsToSelector:", selector)
}

msgSendSafeCheck :: proc "c" (obj: ^Object, selector: SEL) -> BOOL {
	return respondsToSelector(obj, selector) || methodSignatureForSelector(obj, selector) != nil
}


@(objc_class="NSObject")
Object :: struct {using _: intrinsics.objc_object}

@(objc_class="NSObject")
Copying :: struct($T: typeid) {using _: Object}

alloc :: proc($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, T, "alloc")
}
init :: proc(self: ^$T) -> ^T where intrinsics.type_is_subtype_of(T, Object){
	return msgSend(^T, self, "init")
}
retain :: proc(self: ^$T) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, self, "retain")
}
release :: proc(self: ^$T) where intrinsics.type_is_subtype_of(T, Object) {
	msgSend(nil, self, "release")
}
retainCount :: proc(self: ^$T) -> UInteger where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(UInteger, self, "retainCount")
}

copy :: proc(self: ^Copying($T)) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, self, "copy")
}

hash :: proc(self: ^Object) -> UInteger {
	return msgSend(UInteger, self, "hash")
}

isEqual :: proc(self, pObject: ^Object) -> BOOL {
	return msgSend(BOOL, self, "isEqual:", pObject)
}

description :: proc(self: ^Object) -> ^String {
	return msgSend(^String, self, "description")
}

debugDescription :: proc(self: ^Object) -> ^String {
	if msgSendSafeCheck(self, intrinsics.objc_selector_name("debugDescription")) {
		return msgSend(^String, self, "debugDescription")
	}
	return nil
}


@(objc_class="NSCoder")
Coder :: struct {using _: Object}
// TODO(bill): Implement all the methods for this massive type