package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

AttributedString        :: distinct TypeRef
MutableAttributedString :: distinct TypeRef

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	AttributedStringGetTypeID :: proc() -> TypeID ---
	AttributedStringCreate :: proc(alloc: AllocatorRef, str: String, attributes: Dictionary) -> AttributedString ---
	AttributedStringGetString :: proc(aStr: AttributedString) -> String ---
	AttributedStringGetLength :: proc(aStr: AttributedString) -> Index ---

	AttributedStringCreateMutable :: proc(alloc: AllocatorRef, maxLength: Index) -> MutableAttributedString ---
	AttributedStringCreateMutableCopy :: proc(alloc: AllocatorRef, maxLength: Index, aStr: AttributedString) -> MutableAttributedString ---
	AttributedStringReplaceString :: proc(aStr: MutableAttributedString, range: Range, replacement: String) ---
	AttributedStringSetAttributes :: proc(aStr: MutableAttributedString, range: Range, replacement: Dictionary, clearOtherAttributes: b8) ---
	AttributedStringSetAttribute :: proc(aStr: MutableAttributedString, range: Range, attrName: String, value: TypeRef) ---
}
