package objc_Foundation

@(objc_class="NSColor")
Color :: struct {using _: Object}

@(objc_type=Color, objc_name="colorWithSRGBRed")
Color_colorWithSRGBRed :: proc "c" (red, green, blue, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithSRGBRed:green:blue:alpha:", red, green, blue, alpha)
}

@(objc_type=Color, objc_name="blackColor")
Color_blackColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "blackColor")
}

@(objc_type=Color, objc_name="whiteColor")
Color_whiteColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "whiteColor")
}

@(objc_type=Color, objc_name="redColor")
Color_redColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "redColor")
}

@(objc_type=Color, objc_name="greenColor")
Color_greenColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "greenColor")
}

@(objc_type=Color, objc_name="orangeColor")
Color_orangeColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "orangeColor")
}

@(objc_type=Color, objc_name="purpleColor")
Color_purpleColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "purpleColor")
}

@(objc_type=Color, objc_name="cyanColor")
Color_cyanColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "cyanColor")
}

@(objc_type=Color, objc_name="blueColor")
Color_blueColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "blueColor")
}

@(objc_type=Color, objc_name="magentaColor")
Color_magentaColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "magentaColor")
}

@(objc_type=Color, objc_name="yellowColor")
Color_yellowColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "yellowColor")
}

