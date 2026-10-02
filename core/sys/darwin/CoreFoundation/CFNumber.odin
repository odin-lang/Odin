package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

Boolean :: distinct TypeRef
Number  :: distinct TypeRef

NumberType :: enum Index {
	SInt8     = 1,
	SInt16    = 2,
	SInt32    = 3,
	SInt64    = 4,
	Float32   = 5,
	Float64   = 6,
	Char      = 7,
	Short     = 8,
	Int       = 9,
	Long      = 10,
	LongLong  = 11,
	Float     = 12,
	Double    = 13,
	CFIndex   = 14,
	NSInteger = 15,
	CGFloat   = 16,
	Max       = 16,
}

@(default_calling_convention="c")
foreign CoreFoundation {
	kCFBooleanTrue:  Boolean
	kCFBooleanFalse: Boolean
}

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	BooleanGetTypeID :: proc() -> TypeID ---
	BooleanGetValue :: proc(boolean: Boolean) -> b8 ---
	NumberGetTypeID :: proc() -> TypeID ---
	NumberCreate :: proc(allocator: AllocatorRef, theType: NumberType, valuePtr: rawptr) -> Number ---
	NumberGetType :: proc(number: Number) -> NumberType ---
	NumberGetValue :: proc(number: Number, theType: NumberType, valuePtr: rawptr) -> b8 ---
}
