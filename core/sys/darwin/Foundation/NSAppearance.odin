package objc_Foundation

@(objc_class = "NSAppearance")
Appearance :: struct {
	using _: Object,
}

AppearanceName :: distinct ^String
AppearanceNameAqua := AppearanceName(MakeConstantString("NSAppearanceNameAqua"))
AppearanceNameDarkAqua := AppearanceName(MakeConstantString("NSAppearanceNameDarkAqua"))
AppearanceNameVibrantLight := AppearanceName(MakeConstantString("NSAppearanceNameVibrantLight"))
AppearanceNameVibrantDark := AppearanceName(MakeConstantString("NSAppearanceNameVibrantDark"))
AppearanceNameAccessibilityHighContrastAqua := AppearanceName(MakeConstantString("NSAppearanceNameAccessibilityHighContrastAqua"))
AppearanceNameAccessibilityHighContrastDarkAqua := AppearanceName(MakeConstantString("NSAppearanceNameAccessibilityHighContrastDarkAqua"))
AppearanceNameAccessibilityHighContrastVibrantLight := AppearanceName(MakeConstantString("NSAppearanceNameAccessibilityHighContrastVibrantLight"))
AppearanceNameAccessibilityHighContrastVibrantDark := AppearanceName(MakeConstantString("NSAppearanceNameAccessibilityHighContrastVibrantDark"))

@(objc_type = Appearance, objc_name = "appearanceNamed", objc_is_class_method = true)
Appearance_appearanceNamed :: proc "c" (name: AppearanceName) -> ^Appearance {
	return msgSend(^Appearance, Appearance, "appearanceNamed:", name)
}
