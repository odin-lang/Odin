//+build darwin
package darwin

import "core:runtime"

foreign import core_foundation "system:CoreFoundation.framework"

CFTypeRef   :: distinct rawptr

CFStringRef :: distinct CFTypeRef

CFIndex :: int

CFRange :: struct {
	location: CFIndex,
	length:   CFIndex,
}

CFStringEncoding :: enum u32 {
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

foreign core_foundation {
	// Copies the character contents of a string to a local C string buffer after converting the characters to a given encoding.
	CFStringGetCString :: proc(theString: CFStringRef, buffer: [^]byte, bufferSize: CFIndex, encoding: CFStringEncoding) -> Bool ---
	
	// Returns the number (in terms of UTF-16 code pairs) of Unicode characters in a string.
	CFStringGetLength :: proc(theString: CFStringRef) -> CFIndex ---
	
	// Returns the maximum number of bytes a string of a specified length (in Unicode characters) will take up if encoded in a specified encoding.
	CFStringGetMaximumSizeForEncoding :: proc(length: CFIndex, encoding: CFStringEncoding) -> CFIndex ---
	
	// Fetches a range of the characters from a string into a byte buffer after converting the characters to a specified encoding.
	CFStringGetBytes :: proc(
		thestring: CFStringRef,
		range: CFRange,
		encoding: CFStringEncoding,
		lossByte: u8,
		isExternalRepresentation: Bool,
		buffer: [^]byte,
		maxBufLen: CFIndex,
		usedBufLen: ^CFIndex,
	) -> CFIndex ---
	
	// Releases a Core Foundation object.
	@(link_name="CFRelease")
	_CFRelease :: proc(cf: CFTypeRef) ---
}

// Releases a Core Foundation object.
CFRelease :: proc {
	CFReleaseString,
}

// Releases a Core Foundation string.
CFReleaseString :: #force_inline proc(theString: CFStringRef) {
	_CFRelease(CFTypeRef(theString))
}

CFStringCopyToOdinString :: proc(theString: CFStringRef, allocator := context.allocator) -> (str: string, ok: bool) #optional_ok {
	length := CFStringGetLength(theString)
	max    := CFStringGetMaximumSizeForEncoding(length, .UTF8)

	buf, err := make([]byte, max, allocator)
	if err != nil { return }
	
	raw_str := runtime.Raw_String{
		data = raw_data(buf),
	}
	CFStringGetBytes(theString, {0, length}, .UTF8, 0, false, raw_data(buf), max, &raw_str.len)

	return transmute(string)raw_str, true
}
