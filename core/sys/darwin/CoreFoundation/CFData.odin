package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

Data        :: distinct TypeRef
MutableData :: distinct TypeRef

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	DataGetTypeID :: proc() -> TypeID ---
	DataCreate :: proc(allocator: AllocatorRef, bytes: [^]u8, length: Index) -> Data ---
	DataCreateMutable :: proc(allocator: AllocatorRef, capacity: Index) -> MutableData ---
	DataGetLength :: proc(theData: Data) -> Index ---
	DataGetBytePtr :: proc(theData: Data) -> [^]u8 ---
}
