package objc_Foundation

@(objc_class="NSColorSpace")
ColorSpace :: struct {using _: Object}

@(objc_class="NSColor")
Color :: struct {using _: Object}

@(objc_type=Color, objc_name="colorWithSRGBRed", objc_is_class_method=true)
Color_colorWithSRGBRed :: proc "c" (red, green, blue, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithSRGBRed:green:blue:alpha:", red, green, blue, alpha)
}

@(objc_type=Color, objc_name="colorWithCalibratedHue", objc_is_class_method=true)
Color_colorWithCalibratedHue :: proc "c" (hue, saturation, brightness, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithCalibratedHue:hue:saturation:brightness:alpha:", hue, saturation, brightness, alpha)
}
@(objc_type=Color, objc_name="colorWithCalibratedRed", objc_is_class_method=true)
Color_colorWithCalibratedRed :: proc "c" (red, green, blue, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithCalibratedRed:green:blue:alpha:", red, green, blue, alpha)
}
@(objc_type=Color, objc_name="colorWithCalibratedWhite", objc_is_class_method=true)
Color_colorWithCalibratedWhite :: proc "c" (white, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithCalibratedWhite:alpha:", white, alpha)
}

@(objc_type=Color, objc_name="colorWithDeviceCyan", objc_is_class_method=true)
Color_colorWithDeviceCyan :: proc "c" (cyan, magenta, yellow, black, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithDeviceCyan:magenta:yellow:black:", cyan, magenta, yellow, black)
}
@(objc_type=Color, objc_name="colorWithDeviceHue", objc_is_class_method=true)
Color_colorWithDeviceHue :: proc "c" (hue, saturation, brightness, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithDeviceHue:hue:saturation:brightness:alpha:", hue, saturation, brightness, alpha)
}
@(objc_type=Color, objc_name="colorWithDeviceRed", objc_is_class_method=true)
Color_colorWithDeviceRed :: proc "c" (red, green, blue, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithDeviceRed:green:blue:alpha:", red, green, blue, alpha)
}
@(objc_type=Color, objc_name="colorWithDeviceWhite", objc_is_class_method=true)
Color_colorWithDeviceWhite :: proc "c" (white, alpha: Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithDeviceWhite:alpha:", white, alpha)
}


@(objc_type=Color, objc_name="blackColor", objc_is_class_method=true)
Color_blackColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "blackColor")
}

@(objc_type=Color, objc_name="whiteColor", objc_is_class_method=true)
Color_whiteColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "whiteColor")
}

@(objc_type=Color, objc_name="redColor", objc_is_class_method=true)
Color_redColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "redColor")
}

@(objc_type=Color, objc_name="greenColor", objc_is_class_method=true)
Color_greenColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "greenColor")
}

@(objc_type=Color, objc_name="orangeColor", objc_is_class_method=true)
Color_orangeColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "orangeColor")
}

@(objc_type=Color, objc_name="purpleColor", objc_is_class_method=true)
Color_purpleColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "purpleColor")
}

@(objc_type=Color, objc_name="cyanColor", objc_is_class_method=true)
Color_cyanColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "cyanColor")
}

@(objc_type=Color, objc_name="blueColor", objc_is_class_method=true)
Color_blueColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "blueColor")
}

@(objc_type=Color, objc_name="magentaColor", objc_is_class_method=true)
Color_magentaColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "magentaColor")
}

@(objc_type=Color, objc_name="yellowColor", objc_is_class_method=true)
Color_yellowColor :: proc "c" () -> ^Color {
	return msgSend(^Color, Color, "yellowColor")
}


@(objc_type=Color, objc_name="getCMYKA")
Color_getCMYKA :: proc "c" (self: ^Color) -> (cyan, magenta, yellow, black, alpha: Float) {
	msgSend(nil, Color, "getCyan:magenta:yellow:black:alpha:", &cyan, &magenta, &yellow, &black, &alpha)
	return
}
@(objc_type=Color, objc_name="getHSBA")
Color_getHSBA :: proc "c" (self: ^Color) -> (hue, saturation, brightness, alpha: Float) {
	msgSend(nil, Color, "getHue:saturation:brightness:alpha:", &hue, &saturation, &brightness, &alpha)
	return
}
@(objc_type=Color, objc_name="getRGBA")
Color_getRGBA :: proc "c" (self: ^Color) -> (red, green, blue, alpha: Float) {
	msgSend(nil, Color, "getRed:green:blue:alpha:", &red, &green, &blue, &alpha)
	return
}
@(objc_type=Color, objc_name="getWhiteAlpha")
Color_getWhiteAlpha :: proc "c" (self: ^Color) -> (white, alpha: Float) {
	msgSend(nil, Color, "getWhite:alpha:", &white, &alpha)
	return
}


@(objc_type=Color, objc_name="colorWithColorSpace", objc_is_class_method=true)
Color_colorWithColorSpace :: proc "c" (space: ^ColorSpace, components: []Float) -> ^Color {
	return msgSend(^Color, Color, "colorWithColorSpace:components:count", space, raw_data(components), Integer(len(components)))
}


@(objc_type=Color, objc_name="colorSpaceName")
Color_colorSpaceName :: proc "c" (self: ^Color) -> ^String {
	return msgSend(^String, self, "colorSpaceName")
}

@(objc_type=Color, objc_name="colorSpace")
Color_colorSpace :: proc "c" (self: ^Color) -> ^ColorSpace {
	return msgSend(^ColorSpace, self, "colorSpace")
}

@(objc_type=Color, objc_name="colorUsingColorSpaceName")
Color_colorUsingColorSpaceName :: proc "c" (self: ^Color, colorSpace: ^String, device: ^Dictionary = nil) -> ^Color {
	if device != nil {
		return msgSend(^Color, self, "colorUsingColorSpaceName:device:", colorSpace, device)
	}
	return msgSend(^Color, self, "colorUsingColorSpaceName:", colorSpace)
}

@(objc_type=Color, objc_name="numberOfComponents")
Color_numberOfComponents :: proc "c" (self: ^Color) -> Integer {
	return msgSend(Integer, self, "numberOfComponents")
}
@(objc_type=Color, objc_name="getComponents")
Color_getComponents :: proc "c" (self: ^Color, components: [^]Float) {
	msgSend(nil, self, "getComponents:", components)
}