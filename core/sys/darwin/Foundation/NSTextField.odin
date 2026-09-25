package objc_Foundation

TextAlignment :: enum Integer {
	Left      = 0,
	Right     = 1,
	Center    = 2,
	Justified = 3,
	Natural   = 4,
}

@(objc_class="NSTextField")
TextField :: struct {using _: View}

@(objc_type=TextField, objc_name="labelWithString", objc_is_class_method=true)
TextField_labelWithString :: proc "c" (string: ^String) -> ^TextField {
	return msgSend(^TextField, TextField, "labelWithString:", string)
}

@(objc_type=TextField, objc_name="view")
TextField_view :: proc "c" (self: ^TextField) -> ^View {
	return msgSend(^View, self, "view")
}
@(objc_type=TextField, objc_name="setView")
TextField_setView :: proc "c" (self: ^TextField, view: ^View) {
	msgSend(nil, self, "setView:", view)
}

@(objc_type=TextField, objc_name="setStringValue")
TextField_setStringValue :: proc "c" (self: ^TextField, string: ^String) {
	msgSend(nil, self, "setStringValue:", string)
}

@(objc_type=TextField, objc_name="init")
TextField_init :: proc "c" (self: ^TextField) -> ^TextField {
	return msgSend(^TextField, self, "init")
}
