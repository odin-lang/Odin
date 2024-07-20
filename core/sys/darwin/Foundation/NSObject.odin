package objc_Foundation

import "base:intrinsics"

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

alloc :: proc "c" ($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, T, "alloc")
}
@(objc_type=Object, objc_name="init")
init :: proc "c" (self: ^$T) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, self, "init")
}
@(objc_type=Object, objc_name="copy")
copy :: proc "c" (self: ^Copying($T)) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return msgSend(^T, self, "copy")
}

new :: proc "c" ($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	return init(alloc(T))
}

@(objc_type=Object, objc_name="retain")
retain :: proc "c" (self: ^Object) {
	_ = msgSend(^Object, self, "retain")
}
@(objc_type=Object, objc_name="release")
release :: proc "c" (self: ^Object) {
	msgSend(nil, self, "release")
}
@(objc_type=Object, objc_name="autorelease")
autorelease :: proc "c" (self: ^Object) {
	msgSend(nil, self, "autorelease")
}
@(objc_type=Object, objc_name="retainCount")
retainCount :: proc "c" (self: ^Object) -> UInteger {
	return msgSend(UInteger, self, "retainCount")
}
@(objc_type=Object, objc_name="class")
class :: proc "c" (self: ^Object) -> Class {
	return msgSend(Class, self, "class")
}

@(objc_type=Object, objc_name="hash")
hash :: proc "c" (self: ^Object) -> UInteger {
	return msgSend(UInteger, self, "hash")
}

@(objc_type=Object, objc_name="isEqual")
isEqual :: proc "c" (self, pObject: ^Object) -> BOOL {
	return msgSend(BOOL, self, "isEqual:", pObject)
}

@(objc_type=Object, objc_name="description")
description :: proc "c" (self: ^Object) -> ^String {
	return msgSend(^String, self, "description")
}

@(objc_type=Object, objc_name="debugDescription")
debugDescription :: proc "c" (self: ^Object) -> ^String {
	if msgSendSafeCheck(self, intrinsics.objc_find_selector("debugDescription")) {
		return msgSend(^String, self, "debugDescription")
	}
	return nil
}

bridgingCast :: proc "c" ($T: typeid, obj: ^Object) where intrinsics.type_is_pointer(T), intrinsics.type_is_subtype_of(T, ^Object) {
	return (T)(obj)
}


@(objc_class="NSCoder")
Coder :: struct {using _: Object}
// TODO(bill): Implement all the methods for this massive type