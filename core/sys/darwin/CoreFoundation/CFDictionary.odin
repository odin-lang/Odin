package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

Dictionary        :: distinct TypeRef
MutableDictionary :: distinct TypeRef

DictionaryRetainCallBack          :: proc "c" (allocator: AllocatorRef, value: rawptr) -> rawptr
DictionaryReleaseCallBack         :: proc "c" (allocator: AllocatorRef, value: rawptr)
DictionaryCopyDescriptionCallBack :: proc "c" (value: rawptr) -> String
DictionaryEqualCallBack           :: proc "c" (value1, value2: rawptr) -> b8
DictionaryHashCallBack            :: proc "c" (value: rawptr) -> HashCode

DictionaryKeyCallBacks :: struct {
	version:         Index,
	retain:          DictionaryRetainCallBack,
	release:         DictionaryReleaseCallBack,
	copyDescription: DictionaryCopyDescriptionCallBack,
	equal:           DictionaryEqualCallBack,
	hash:            DictionaryHashCallBack,
}

DictionaryValueCallBacks :: struct {
	version:         Index,
	retain:          DictionaryRetainCallBack,
	release:         DictionaryReleaseCallBack,
	copyDescription: DictionaryCopyDescriptionCallBack,
	equal:           DictionaryEqualCallBack,
}

@(default_calling_convention="c")
foreign CoreFoundation {
	kCFTypeDictionaryKeyCallBacks: DictionaryKeyCallBacks
	kCFTypeDictionaryValueCallBacks: DictionaryValueCallBacks
}

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	DictionaryGetTypeID :: proc() -> TypeID ---
	DictionaryCreate :: proc(allocator: AllocatorRef, keys, values: [^]rawptr, numValues: Index, keyCallBacks: ^DictionaryKeyCallBacks, valueCallBacks: ^DictionaryValueCallBacks) -> Dictionary ---
	DictionaryCreateMutable :: proc(allocator: AllocatorRef, capacity: Index, keyCallBacks: ^DictionaryKeyCallBacks, valueCallBacks: ^DictionaryValueCallBacks) -> MutableDictionary ---
	DictionaryGetCount :: proc(theDict: Dictionary) -> Index ---
	DictionaryContainsKey :: proc(theDict: Dictionary, key: rawptr) -> b8 ---
	DictionaryGetValue :: proc(theDict: Dictionary, key: rawptr) -> rawptr ---
	DictionaryGetKeysAndValues :: proc(theDict: Dictionary, keys, values: [^]rawptr) ---
	DictionarySetValue :: proc(theDict: MutableDictionary, key, value: rawptr) ---
	DictionaryRemoveValue :: proc(theDict: MutableDictionary, key: rawptr) ---
}
