package objc_Foundation

@(objc_class="NSBundle")
Bundle :: struct { using _: Object }

@(objc_type=Bundle, objc_name="mainBundle", objc_is_class_method=true)
Bundle_mainBundle :: proc "c" () -> ^Bundle {
	return msgSend(^Bundle, Bundle, "mainBundle")
}

@(objc_type=Bundle, objc_name="bundleWithPath", objc_is_class_method=true)
Bundle_bundleWithPath :: proc "c" (path: ^String) -> ^Bundle {
	return msgSend(^Bundle, Bundle, "bundleWithPath:", path)
}

@(objc_type=Bundle, objc_name="bundleWithURL", objc_is_class_method=true)
Bundle_bundleWithURL :: proc "c" (url: ^URL) -> ^Bundle {
	return msgSend(^Bundle, Bundle, "bundleWithUrl:", url)
}


@(objc_type=Bundle, objc_name="alloc", objc_is_class_method=true)
Bundle_alloc :: proc "c" () -> ^Bundle {
	return msgSend(^Bundle, Bundle, "alloc")
}

@(objc_type=Bundle, objc_name="init")
Bundle_init :: proc "c" (self: ^Bundle) -> ^Bundle {
	return msgSend(^Bundle, self, "init")
}

@(objc_type=Bundle, objc_name="initWithPath")
Bundle_initWithPath :: proc "c" (self: ^Bundle, path: ^String) -> ^Bundle {
	return msgSend(^Bundle, self, "initWithPath:", path)
}

@(objc_type=Bundle, objc_name="initWithURL")
Bundle_initWithURL :: proc "c" (self: ^Bundle, url: ^URL) -> ^Bundle {
	return msgSend(^Bundle, self, "initWithUrl:", url)
}

@(objc_type=Bundle, objc_name="allBundles")
Bundle_allBundles :: proc "c" () -> (all: ^Array) {
	return msgSend(type_of(all), Bundle, "allBundles")
}

@(objc_type=Bundle, objc_name="allFrameworks")
Bundle_allFrameworks :: proc "c" () -> (all: ^Array) {
	return msgSend(type_of(all), Bundle, "allFrameworks")
}

@(objc_type=Bundle, objc_name="load")
Bundle_load :: proc "c" (self: ^Bundle) -> BOOL {
	return msgSend(BOOL, self, "load")
}
@(objc_type=Bundle, objc_name="unload")
Bundle_unload :: proc "c" (self: ^Bundle) -> BOOL {
	return msgSend(BOOL, self, "unload")
}

@(objc_type=Bundle, objc_name="isLoaded")
Bundle_isLoaded :: proc "c" (self: ^Bundle) -> BOOL {
	return msgSend(BOOL, self, "isLoaded")
}

@(objc_type=Bundle, objc_name="preflightAndReturnError")
Bundle_preflightAndReturnError :: proc "contextless" (self: ^Bundle) -> (ok: BOOL, error: ^Error) {
	ok = msgSend(BOOL, self, "preflightAndReturnError:", &error)
	return
}

@(objc_type=Bundle, objc_name="loadAndReturnError")
Bundle_loadAndReturnError :: proc "contextless" (self: ^Bundle) -> (ok: BOOL, error: ^Error) {
	ok = msgSend(BOOL, self, "loadAndReturnError:", &error)
	return
}

@(objc_type=Bundle, objc_name="bundleURL")
Bundle_bundleURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "bundleURL")
}

@(objc_type=Bundle, objc_name="resourceURL")
Bundle_resourceURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "resourceURL")
}

@(objc_type=Bundle, objc_name="executableURL")
Bundle_executableURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "executableURL")
}

@(objc_type=Bundle, objc_name="URLForAuxiliaryExecutable")
Bundle_URLForAuxiliaryExecutable :: proc "c" (self: ^Bundle, executableName: ^String) -> ^URL {
	return msgSend(^URL, self, "URLForAuxiliaryExecutable:", executableName)
}

@(objc_type=Bundle, objc_name="privateFrameworksURL")
Bundle_privateFrameworksURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "privateFrameworksURL")
}

@(objc_type=Bundle, objc_name="sharedFrameworksURL")
Bundle_sharedFrameworksURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "sharedFrameworksURL")
}

@(objc_type=Bundle, objc_name="sharedSupportURL")
Bundle_sharedSupportURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "sharedSupportURL")
}

@(objc_type=Bundle, objc_name="builtInPlugInsURL")
Bundle_builtInPlugInsURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "builtInPlugInsURL")
}

@(objc_type=Bundle, objc_name="appStoreReceiptURL")
Bundle_appStoreReceiptURL :: proc "c" (self: ^Bundle) -> ^URL {
	return msgSend(^URL, self, "appStoreReceiptURL")
}

@(objc_type=Bundle, objc_name="bundlePath")
Bundle_bundlePath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "bundlePath")
}

@(objc_type=Bundle, objc_name="resourcePath")
Bundle_resourcePath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "resourcePath")
}

@(objc_type=Bundle, objc_name="executablePath")
Bundle_executablePath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "executablePath")
}

@(objc_type=Bundle, objc_name="PathForAuxiliaryExecutable")
Bundle_PathForAuxiliaryExecutable :: proc "c" (self: ^Bundle, executableName: ^String) -> ^String {
	return msgSend(^String, self, "PathForAuxiliaryExecutable:", executableName)
}

@(objc_type=Bundle, objc_name="privateFrameworksPath")
Bundle_privateFrameworksPath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "privateFrameworksPath")
}

@(objc_type=Bundle, objc_name="sharedFrameworksPath")
Bundle_sharedFrameworksPath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "sharedFrameworksPath")
}

@(objc_type=Bundle, objc_name="sharedSupportPath")
Bundle_sharedSupportPath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "sharedSupportPath")
}

@(objc_type=Bundle, objc_name="builtInPlugInsPath")
Bundle_builtInPlugInsPath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "builtInPlugInsPath")
}

@(objc_type=Bundle, objc_name="appStoreReceiptPath")
Bundle_appStoreReceiptPath :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "appStoreReceiptPath")
}

@(objc_type=Bundle, objc_name="bundleIdentifier")
Bundle_bundleIdentifier :: proc "c" (self: ^Bundle) -> ^String {
	return msgSend(^String, self, "bundleIdentifier")
}

@(objc_type=Bundle, objc_name="infoDictionary")
Bundle_infoDictionary :: proc "c" (self: ^Bundle) -> ^Dictionary {
	return msgSend(^Dictionary, self, "infoDictionary")
}

@(objc_type=Bundle, objc_name="localizedInfoDictionary")
Bundle_localizedInfoDictionary :: proc "c" (self: ^Bundle) -> ^Dictionary {
	return msgSend(^Dictionary, self, "localizedInfoDictionary")
}

@(objc_type=Bundle, objc_name="objectForInfoDictionaryKey")
Bundle_objectForInfoDictionaryKey :: proc "c" (self: ^Bundle, key: ^String) -> ^Object {
	return msgSend(^Object, self, "objectForInfoDictionaryKey:", key)
}

@(objc_type=Bundle, objc_name="localizedStringForKey")
Bundle_localizedStringForKey :: proc "c" (self: ^Bundle, key: ^String, value: ^String = nil, tableName: ^String = nil) -> ^String {
	return msgSend(^String, self, "localizedStringForKey:value:table:", key, value, tableName)
}
