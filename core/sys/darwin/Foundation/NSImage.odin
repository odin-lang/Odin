package objc_Foundation

@(objc_class="NSImage")
Image :: struct { using _: Object }

@(objc_type=Image, objc_name="alloc", objc_is_class_method=true)
Image_alloc :: proc "c" () -> ^Image {
	return msgSend(^Image, Image, "alloc")
}

@(objc_type=Image, objc_name="initWithSize")
Image_initWithSize :: proc "c" (self: ^Image, size: Size) -> ^Image {
	return msgSend(^Image, self, "initWithSize:", size)
}

@(objc_type=Image, objc_name="addRepresentation")
Image_addRepresentation :: proc(self: ^Image, rep: ^ImageRep) {
	msgSend(nil, self, "addRepresentation:", rep)
}
