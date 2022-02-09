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

Error_errorWithDomain :: proc(domain: ErrorDomain, code: Integer, userInfo: ^Dictionary) -> ^Error {
	return msgSend(^Error, Error, "errorWithDomain:code:userInfo:", domain, code, userInfo)
}

Error_initWithDomain :: proc(self: ^Error, domain: ErrorDomain, code: Integer, userInfo: ^Dictionary) -> ^Error {
	return msgSend(^Error, self, "initWithDomain:code:userInfo:", domain, code, userInfo)
}

Error_code :: proc(self: ^Error) -> Integer {
	return msgSend(Integer, self, "code")
}

Error_domain :: proc(self: ^Error) -> ErrorDomain {
	return msgSend(ErrorDomain, self, "domain")
}

Error_userInfo :: proc(self: ^Error) -> ^Dictionary {
	return msgSend(^Dictionary, self, "userInfo")
}

Error_localizedDescription :: proc(self: ^Error) -> ^String {
	return msgSend(^String, self, "localizedDescription")
}

Error_localizedRecoveryOptions :: proc(self: ^Error) -> (options: ^Array(^Object)) {
	return msgSend(type_of(options), self, "localizedRecoveryOptions")
}

Error_localizedRecoverySuggestion :: proc(self: ^Error) -> ^String {
	return msgSend(^String, self, "localizedRecoverySuggestion")
}

Error_localizedFailureReason :: proc(self: ^Error) -> ^String {
	return msgSend(^String, self, "localizedFailureReason")
}