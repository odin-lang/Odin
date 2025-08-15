package objc_Foundation

import "base:intrinsics"

@(objc_class="NSBitmapImageRep")
BitmapImageRep :: struct { using _: Object }

@(objc_type=BitmapImageRep, objc_name="alloc", objc_is_class_method=true)
BitmapImageRep_alloc :: proc "c" () -> ^BitmapImageRep {
	return msgSend(^BitmapImageRep, BitmapImageRep, "alloc")
}

@(objc_type=BitmapImageRep, objc_name="initWithBitmapDataPlanes")
BitmapImageRep_initWithBitmapDataPlanes :: proc "c" (
	self: ^BitmapImageRep, 
	bitmapDataPlanes: ^^u8,
	pixelsWide: Integer, 
	pixelsHigh: Integer,
	bitsPerSample: Integer,
	samplesPerPixel: Integer,
	hasAlpha: bool, 
	isPlanar: bool,
	colorSpaceName: ^String,
	bytesPerRow: Integer,
	bitsPerPixel: Integer) -> ^BitmapImageRep {

	return msgSend(^BitmapImageRep, 
		self, 
		"initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bytesPerRow:bitsPerPixel:",
		bitmapDataPlanes,
		pixelsWide, 
		pixelsHigh,
		bitsPerSample,
		samplesPerPixel,
		hasAlpha,
		isPlanar, 
		colorSpaceName,
		bytesPerRow,
		bitsPerPixel)
}

@(objc_type=BitmapImageRep, objc_name="bitmapData")
BitmapImageRep_bitmapData :: proc "c" (self: ^BitmapImageRep) -> rawptr {
	return msgSend(rawptr, self, "bitmapData") 
}

@(objc_type=BitmapImageRep, objc_name="CGImage")
BitmapImageRep_CGImage :: proc "c" (self: ^BitmapImageRep) -> rawptr {
	return msgSend(rawptr, self, "CGImage") 
}
