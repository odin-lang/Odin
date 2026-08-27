package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

Array        :: distinct TypeRef
MutableArray :: distinct TypeRef

ArrayRetainCallBack          :: proc "c" (allocator: AllocatorRef, value: rawptr) -> rawptr
ArrayReleaseCallBack         :: proc "c" (allocator: AllocatorRef, value: rawptr)
ArrayCopyDescriptionCallBack :: proc "c" (value: rawptr) -> String
ArrayEqualCallBack           :: proc "c" (value1, value2: rawptr) -> b8

ArrayCallBacks :: struct {
	version:         Index,
	retain:          ArrayRetainCallBack,
	release:         ArrayReleaseCallBack,
	copyDescription: ArrayCopyDescriptionCallBack,
	equal:           ArrayEqualCallBack,
}

@(default_calling_convention="c")
foreign CoreFoundation {
	kCFTypeArrayCallBacks: ArrayCallBacks
}

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	ArrayGetTypeID :: proc() -> TypeID ---
	ArrayCreate :: proc(allocator: AllocatorRef, values: [^]rawptr, numValues: Index, callBacks: ^ArrayCallBacks) -> Array ---
	ArrayCreateMutable :: proc(allocator: AllocatorRef, capacity: Index, callBacks: ^ArrayCallBacks) -> MutableArray ---
	ArrayGetCount :: proc(theArray: Array) -> Index ---
	ArrayGetValueAtIndex :: proc(theArray: Array, idx: Index) -> rawptr ---
	ArrayGetFirstIndexOfValue :: proc(theArray: Array, range: Range, value: rawptr) -> Index ---
	ArrayAppendValue :: proc(theArray: MutableArray, value: rawptr) ---
}
