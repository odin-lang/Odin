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
init :: proc(self: ^$T) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, self, "init")
}
copy :: proc(self: ^Copying($T)) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, self, "copy")
}

new :: proc($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return init(alloc(T))
}

@(objc_type=Object, objc_name="retain")
retain :: proc(self: ^Object) {
	_ = msgSend(^Object, self, "retain")
}
@(objc_type=Object, objc_name="release")
release :: proc(self: ^Object) {
	msgSend(nil, self, "release")
}
@(objc_type=Object, objc_name="autorelease")
autorelease :: proc(self: ^Object) {
	msgSend(nil, self, "autorelease")
}
@(objc_type=Object, objc_name="retainCount")
retainCount :: proc(self: ^Object) -> UInteger {
	return msgSend(UInteger, self, "retainCount")
}


@(objc_type=Object, objc_name="hash")
hash :: proc(self: ^Object) -> UInteger {
	return msgSend(UInteger, self, "hash")
}

@(objc_type=Object, objc_name="isEqual")
isEqual :: proc(self, pObject: ^Object) -> BOOL {
	return msgSend(BOOL, self, "isEqual:", pObject)
}

@(objc_type=Object, objc_name="description")
description :: proc(self: ^Object) -> ^String {
	return msgSend(^String, self, "description")
}

@(objc_type=Object, objc_name="debugDescription")
debugDescription :: proc(self: ^Object) -> ^String {
	if msgSendSafeCheck(self, intrinsics.objc_find_selector("debugDescription")) {
		return msgSend(^String, self, "debugDescription")
	}
	return nil
}

bridgingCast :: proc($T: typeid, obj: ^Object) where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	return (T)(obj)
}


@(objc_class="NSCoder")
Coder :: struct {using _: Object}
// TODO(bill): Implement all the methods for this massive type