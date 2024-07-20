package objc_Foundation

foreign import "system:Foundation.framework"

ErrorDomain :: ^String

foreign Foundation {
	@(linkage="weak") CocoaErrorDomain:    ErrorDomain
	@(linkage="weak") POSIXErrorDomain:    ErrorDomain
	@(linkage="weak") OSStatusErrorDomain: ErrorDomain
	@(linkage="weak") MachErrorDomain:     ErrorDomain
}

ErrorUserInfoKey :: ^String

foreign Foundation {
	@(linkage="weak") UnderlyingErrorKey:                  ErrorUserInfoKey
	@(linkage="weak") LocalizedDescriptionKey:             ErrorUserInfoKey
	@(linkage="weak") LocalizedFailureReasonErrorKey:      ErrorUserInfoKey
	@(linkage="weak") LocalizedRecoverySuggestionErrorKey: ErrorUserInfoKey
	@(linkage="weak") LocalizedRecoveryOptionsErrorKey:    ErrorUserInfoKey
	@(linkage="weak") RecoveryAttempterErrorKey:           ErrorUserInfoKey
	@(linkage="weak") HelpAnchorErrorKey:                  ErrorUserInfoKey
	@(linkage="weak") DebugDescriptionErrorKey:            ErrorUserInfoKey
	@(linkage="weak") LocalizedFailureErrorKey:            ErrorUserInfoKey
	@(linkage="weak") StringEncodingErrorKey:              ErrorUserInfoKey
	@(linkage="weak") URLErrorKey:                         ErrorUserInfoKey
	@(linkage="weak") FilePathErrorKey:                    ErrorUserInfoKey
}

@(objc_class="NSError")
Error :: struct { using _: Copying(Error) }


@(objc_type=Error, objc_name="alloc", objc_is_class_method=true)
Error_alloc :: proc "c" () -> ^Error {
	return msgSend(^Error, Error, "alloc")
}

@(objc_type=Error, objc_name="init")
Error_init :: proc "c" (self: ^Error) -> ^Error {
	return msgSend(^Error, self, "init")
}

@(objc_type=Error, objc_name="errorWithDomain", objc_is_class_method=true)
Error_errorWithDomain :: proc "c" (domain: ErrorDomain, code: Integer, userInfo: ^Dictionary) -> ^Error {
	return msgSend(^Error, Error, "errorWithDomain:code:userInfo:", domain, code, userInfo)
}

@(objc_type=Error, objc_name="initWithDomain")
Error_initWithDomain :: proc "c" (self: ^Error, domain: ErrorDomain, code: Integer, userInfo: ^Dictionary) -> ^Error {
	return msgSend(^Error, self, "initWithDomain:code:userInfo:", domain, code, userInfo)
}

@(objc_type=Error, objc_name="code")
Error_code :: proc "c" (self: ^Error) -> Integer {
	return msgSend(Integer, self, "code")
}

@(objc_type=Error, objc_name="domain")
Error_domain :: proc "c" (self: ^Error) -> ErrorDomain {
	return msgSend(ErrorDomain, self, "domain")
}

@(objc_type=Error, objc_name="userInfo")
Error_userInfo :: proc "c" (self: ^Error) -> ^Dictionary {
	return msgSend(^Dictionary, self, "userInfo")
}

@(objc_type=Error, objc_name="localizedDescription")
Error_localizedDescription :: proc "c" (self: ^Error) -> ^String {
	return msgSend(^String, self, "localizedDescription")
}

@(objc_type=Error, objc_name="localizedRecoveryOptions")
Error_localizedRecoveryOptions :: proc "c" (self: ^Error) -> (options: ^Array) {
	return msgSend(type_of(options), self, "localizedRecoveryOptions")
}

@(objc_type=Error, objc_name="localizedRecoverySuggestion")
Error_localizedRecoverySuggestion :: proc "c" (self: ^Error) -> ^String {
	return msgSend(^String, self, "localizedRecoverySuggestion")
}

@(objc_type=Error, objc_name="localizedFailureReason")
Error_localizedFailureReason :: proc "c" (self: ^Error) -> ^String {
	return msgSend(^String, self, "localizedFailureReason")
}