package objc_Foundation

@(objc_class="NSViewController")
ViewController :: struct {using _: Object}

@(objc_type=ViewController, objc_name="alloc", objc_is_class_method=true)
ViewController_alloc :: proc "c" () -> ^ViewController {
	return msgSend(^ViewController, ViewController, "alloc")
}

@(objc_type=ViewController, objc_name="view")
ViewController_view :: proc "c" (self: ^ViewController) -> ^View {
	return msgSend(^View, self, "view")
}
@(objc_type=ViewController, objc_name="setView")
ViewController_setView :: proc "c" (self: ^ViewController, view: ^View) {
	msgSend(nil, self, "setView:", view)
}

@(objc_type=ViewController, objc_name="init")
ViewController_init :: proc "c" (self: ^ViewController) -> ^ViewController {
	return msgSend(^ViewController, self, "init")
}
