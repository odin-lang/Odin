package objc_Foundation

@(objc_class="NSDictionary")
Dictionary :: struct {using _: Copying(Dictionary)}

@(objc_type=Dictionary, objc_name="dictionary", objc_is_class_method=true)
Dictionary_dictionary :: proc() -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "dictionary")
}

@(objc_type=Dictionary, objc_name="dictionaryWithObject", objc_is_class_method=true)
Dictionary_dictionaryWithObject :: proc(object: ^Object, forKey: ^Object) -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "dictionaryWithObject:forKey:", object, forKey)
}

@(objc_type=Dictionary, objc_name="dictionaryWithObjects", objc_is_class_method=true)
Dictionary_dictionaryWithObjects :: proc(objects: [^]^Object, forKeys: [^]^Object, count: UInteger) -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "dictionaryWithObjects:forKeys:count", objects, forKeys, count)
}


@(objc_type=Dictionary, objc_name="alloc", objc_is_class_method=true)
Dictionary_alloc :: proc() -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "alloc")
}

@(objc_type=Dictionary, objc_name="init")
Dictionary_init :: proc(self: ^Dictionary) -> ^Dictionary {
	return msgSend(^Dictionary, self, "init")
}

@(objc_type=Dictionary, objc_name="initWithObjects")
Dictionary_initWithObjects :: proc(self: ^Dictionary, objects: [^]^Object, forKeys: [^]^Object, count: UInteger) -> ^Dictionary {
	return msgSend(^Dictionary, self, "initWithObjects:forKeys:count", objects, forKeys, count)
}

@(objc_type=Dictionary, objc_name="objectForKey")
Dictionary_objectForKey :: proc(self: ^Dictionary, key: ^Object) -> ^Object {
	return msgSend(^Dictionary, self, "objectForKey:", key)
}

@(objc_type=Dictionary, objc_name="count")
Dictionary_count :: proc(self: ^Dictionary) -> UInteger {
	return msgSend(UInteger, self, "count")
}

@(objc_type=Dictionary, objc_name="keyEnumerator")
Dictionary_keyEnumerator :: proc(self: ^Dictionary, $KeyType: typeid) -> (enumerator: ^Enumerator(KeyType)) {
	return msgSend(type_of(enumerator), self, "keyEnumerator")
}
