package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

TypeID      :: distinct uint
OptionFlags :: distinct uint
HashCode    :: distinct uint
Index       :: distinct int
TypeRef     :: distinct rawptr

Range :: struct {
	location: Index,
	length:   Index,
}

foreign CoreFoundation {
	// Releases a Core Foundation object.
	CFRelease :: proc(cf: TypeRef) ---
}

// Releases a Core Foundation object.
Release :: proc {
	ReleaseObject,
	ReleaseString,
}

ReleaseObject :: #force_inline proc(cf: TypeRef) {
	CFRelease(cf)
}

// Releases a Core Foundation string.
ReleaseString :: #force_inline proc(theString: String) {
	CFRelease(TypeRef(theString))
}
