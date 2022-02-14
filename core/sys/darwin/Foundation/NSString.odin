package objc_Foundation

foreign import "system:Foundation.framework"

@(objc_class="NSString")
String :: struct {using _: Copying(String)}

StringEncoding :: enum UInteger {
	ASCII             = 1,
	NEXTSTEP          = 2,
	JapaneseEUC       = 3,
	UTF8              = 4,
	ISOLatin1         = 5,
	Symbol            = 6,
	NonLossyASCII     = 7,
	ShiftJIS          = 8,
	ISOLatin2         = 9,
	Unicode           = 10,
	WindowsCP1251     = 11,
	WindowsCP1252     = 12,
	WindowsCP1253     = 13,
	WindowsCP1254     = 14,
	WindowsCP1250     = 15,
	ISO2022JP         = 21,
	MacOSRoman        = 30,

	UTF16             = Unicode,

	UTF16BigEndian    = 0x90000100,
	UTF16LittleEndian = 0x94000100,

	UTF32             = 0x8c000100,
	UTF32BigEndian    = 0x98000100,
	UTF32LittleEndian = 0x9c000100,
}

StringCompareOptions :: distinct bit_set[StringCompareOption; UInteger]
StringCompareOption :: enum UInteger {
	CaseInsensitive      = 0,
	LiteralSearch        = 1,
	BackwardsSearch      = 2,
	AnchoredSearch       = 3,
	NumericSearch        = 6,
	DiacriticInsensitive = 7,
	WidthInsensitive     = 8,
	ForcedOrdering       = 9,
	RegularExpression    = 10,
}

unichar :: distinct u16

foreign Foundation {
	__CFStringMakeConstantString :: proc "c" (c: cstring) -> ^String ---
}

AT :: MakeConstantString
MakeConstantString :: proc "c" (#const c: cstring) -> ^String {
	return __CFStringMakeConstantString(c)
}


@(objc_type=String, objc_name="alloc", objc_is_class_method=true)
String_alloc :: proc() -> ^String {
	return msgSend(^String, String, "alloc")
}

@(objc_type=String, objc_name="init")
String_init :: proc(self: ^String) -> ^String {
	return msgSend(^String, self, "init")
}


@(objc_type=String, objc_name="initWithString")
String_initWithString :: proc(self: ^String, other: ^String) -> ^String {
	return msgSend(^String, self, "initWithString:", other)
}

@(objc_type=String, objc_name="initWithCString")
String_initWithCString :: proc(self: ^String, pString: cstring, encoding: StringEncoding) -> ^String {
	return msgSend(^String, self, "initWithCstring:encoding:", pString, encoding)
}

@(objc_type=String, objc_name="initWithBytesNoCopy")
String_initWithBytesNoCopy :: proc(self: ^String, pBytes: rawptr, length: UInteger, encoding: StringEncoding, freeWhenDone: bool) -> ^String {
	return msgSend(^String, self, "initWithBytesNoCopy:length:encoding:freeWhenDone:", pBytes, length, encoding, freeWhenDone)
}

@(objc_type=String, objc_name="initWithOdinString")
String_initWithOdinString :: proc(self: ^String, str: string) -> ^String {
	return String_initWithBytesNoCopy(self, raw_data(str), UInteger(len(str)), .UTF8, false)
}

@(objc_type=String, objc_name="characterAtIndex")
String_characterAtIndex :: proc(self: ^String, index: UInteger) -> unichar {
	return msgSend(unichar, self, "characterAtIndex:", index)
}

@(objc_type=String, objc_name="length")
String_length :: proc(self: ^String) -> UInteger {
	return msgSend(UInteger, self, "length")
}

@(objc_type=String, objc_name="cstringUsingEncoding")
String_cstringUsingEncoding :: proc(self: ^String, encoding: StringEncoding) -> cstring {
	return msgSend(cstring, self, "cStringUsingEncoding:", encoding)
}

@(objc_type=String, objc_name="UTF8String")
String_UTF8String :: proc(self: ^String) -> cstring {
	return msgSend(cstring, self, "UTF8String")
}

@(objc_type=String, objc_name="odinString")
String_odinString :: proc(self: ^String) -> string {
	return string(String_UTF8String(self))
}

@(objc_type=String, objc_name="maximumLengthOfBytesUsingEncoding")
String_maximumLengthOfBytesUsingEncoding :: proc(self: ^String, encoding: StringEncoding) -> UInteger {
	return msgSend(UInteger, self, "maximumLengthOfBytesUsingEncoding:", encoding)
}

@(objc_type=String, objc_name="lengthOfBytesUsingEncoding")
String_lengthOfBytesUsingEncoding :: proc(self: ^String, encoding: StringEncoding) -> UInteger {
	return msgSend(UInteger, self, "lengthOfBytesUsingEncoding:", encoding)
}

@(objc_type=String, objc_name="isEqualToString")
String_isEqualToString :: proc(self, other: ^String) -> BOOL {
	return msgSend(BOOL, self, "isEqualToString:", other)
}

@(objc_type=String, objc_name="rangeOfString")
String_rangeOfString :: proc(self, other: ^String, options: StringCompareOptions) -> Range {
	return msgSend(Range, self, "rangeOfString:options:", other, options)
}