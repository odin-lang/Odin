package objc_Foundation

@(objc_class="NSDictionary")
Dictionary :: struct {using _: Copying(Dictionary)}

Dictionary_dictionary :: proc() -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "dictionary")
}

Dictionary_dictionaryWithObject :: proc(object: ^Object, forKey: ^Object) -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "dictionaryWithObject:forKey:", object, forKey)
}

Dictionary_dictionaryWithObjects :: proc(objects: [^]^Object, forKeys: [^]^Object, count: UInteger) -> ^Dictionary {
	return msgSend(^Dictionary, Dictionary, "dictionaryWithObjects:forKeys:count", objects, forKeys, count)
}


Dictionary_initWithObjects :: proc(self: ^Dictionary, objects: [^]^Object, forKeys: [^]^Object, count: UInteger) -> ^Dictionary {
	return msgSend(^Dictionary, self, "initWithObjects:forKeys:count", objects, forKeys, count)
}

Dictionary_objectForKey :: proc(self: ^Dictionary, key: ^Object) -> ^Object {
	return msgSend(^Dictionary, self, "objectForKey:", key)
}

// TODO(bill): enumerator