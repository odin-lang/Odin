package CoreFoundation

foreign import CoreFoundation "system:CoreFoundation.framework"

Locale :: distinct TypeRef

@(link_prefix="CF", default_calling_convention="c")
foreign CoreFoundation {
	LocaleGetTypeID :: proc() -> TypeID ---
	LocaleCopyCurrent :: proc() -> Locale ---
}
