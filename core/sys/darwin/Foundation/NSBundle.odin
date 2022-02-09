package objc_Foundation

@(objc_class="NSBundle")
Bundle :: struct { using _: Object }

Bundle_mainBundle :: proc() -> ^Bundle {
	return msgSend(^Bundle, Bundle, "mainBundle")
}

Bundle_bundleWithPath :: proc(path: ^String) -> ^Bundle {
	return msgSend(^Bundle, Bundle, "bundleWithPath:", path)
}

Bundle_bundleWithURL :: proc(url: ^URL) -> ^Bundle {
	return msgSend(^Bundle, Bundle, "bundleWithUrl:", url)
}
Bundle_bundle :: proc{
	Bundle_bundleWithPath,
	Bundle_bundleWithURL,
}


Bundle_initWithPath :: proc(self: ^Bundle, path: ^String) -> ^Bundle {
	return msgSend(^Bundle, self, "initWithPath:", path)
}

Bundle_initWithURL :: proc(self: ^Bundle, url: ^URL) -> ^Bundle {
	return msgSend(^Bundle, self, "initWithUrl:", url)
}
Bundle_init :: proc{
	Bundle_initWithPath,
	Bundle_initWithURL,
}


Bundle_allBundles :: proc() -> (all: ^Array(^Bundle)) {
	return msgSend(type_of(all), Bundle, "allBundles")
}

Bundle_allFrameworks :: proc() -> (all: ^Array(^Object)) {
	return msgSend(type_of(all), Bundle, "allFrameworks")
}

Bundle_load :: proc(self: ^Bundle) -> BOOL {
	return msgSend(BOOL, self, "load")
}
Bundle_unload :: proc(self: ^Bundle) -> BOOL {
	return msgSend(BOOL, self, "unload")
}

Bundle_isLoaded :: proc(self: ^Bundle) -> BOOL {
	return msgSend(BOOL, self, "isLoaded")
}

Bundle_preflightAndReturnError :: proc(self: ^Bundle) -> (ok: BOOL, error: ^Error) {
	ok = msgSend(BOOL, self, "preflightAndReturnError:", &error)
	return
}

Bundle_loadAndReturnError :: proc(self: ^Bundle) -> (ok: BOOL, error: ^Error) {
	ok = msgSend(BOOL, self, "loadAndReturnError:", &error)
	return
}

Bundle_bundleURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "bundleURL")
}

Bundle_resourceURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "resourceURL")
}

Bundle_executableURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "executableURL")
}

Bundle_URLForAuxiliaryExecutable :: proc(self: ^Bundle, executableName: ^String) -> ^URL {
	return msgSend(^URL, self, "URLForAuxiliaryExecutable:", executableName)
}

Bundle_privateFrameworksURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "privateFrameworksURL")
}

Bundle_sharedFrameworksURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "sharedFrameworksURL")
}


Bundle_sharedSupportURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "sharedSupportURL")
}

Bundle_builtInPlugInsURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "builtInPlugInsURL")
}

Bundle_appStoreReceiptURL :: proc(self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "appStoreReceiptURL")
}




Bundle_bundlePath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "bundlePath")
}

Bundle_resourcePath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "resourcePath")
}

Bundle_executablePath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "executablePath")
}

Bundle_PathForAuxiliaryExecutable :: proc(self: ^Bundle, executableName: ^String) -> ^String {
	return msgSend(^String, self, "PathForAuxiliaryExecutable:", executableName)
}

Bundle_privateFrameworksPath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "privateFrameworksPath")
}

Bundle_sharedFrameworksPath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "sharedFrameworksPath")
}


Bundle_sharedSupportPath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "sharedSupportPath")
}

Bundle_builtInPlugInsPath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "builtInPlugInsPath")
}

Bundle_appStoreReceiptPath :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "appStoreReceiptPath")
}

Bundle_bundleIdentifier :: proc(self: ^Bundle) -> ^String {
	return msgSend(^String, self, "bundleIdentifier")
}


Bundle_infoDictionary :: proc(self: ^Bundle) -> ^Dictionary {
	return msgSend(^Dictionary, self, "infoDictionary")
}

Bundle_localizedInfoDictionary :: proc(self: ^Bundle) -> ^Dictionary {
	return msgSend(^Dictionary, self, "localizedInfoDictionary")
}

Bundle_objectForInfoDictionaryKey :: proc(self: ^Bundle, key: ^String) -> ^Object {
	return msgSend(^Object, self, "objectForInfoDictionaryKey:", key)
}

Bundle_localizedStringForKey :: proc(self: ^Bundle, key: ^String, value: ^String = nil, tableName: ^String = nil) -> ^String {
	return msgSend(^String, self, "localizedStringForKey:value:table:", key, value, tableName)
}
