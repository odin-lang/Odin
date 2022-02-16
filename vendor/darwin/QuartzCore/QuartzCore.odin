//+build darwin
package objc_QuartzCore

import NS "vendor:darwin/Foundation"
import MTL "vendor:darwin/Metal"
import "core:intrinsics"

@(private)
msgSend :: intrinsics.objc_send

@(objc_class="CAMetalLayer")
MetalLayer :: struct{ using _: NS.Layer}

@(objc_type=MetalLayer, objc_name="layer", objc_is_class_method=true)
MetalLayer_layer :: proc() -> ^MetalLayer {
	return msgSend(^MetalLayer, MetalLayer, "layer")
}

@(objc_type=MetalLayer, objc_name="device")
MetalLayer_device :: proc(self: ^MetalLayer) -> ^MTL.Device {
	return msgSend(^MTL.Device, self, "device")
}
@(objc_type=MetalLayer, objc_name="setDevice")
MetalLayer_setDevice :: proc(self: ^MetalLayer, device: ^MTL.Device) {
	msgSend(nil, self, "setDevice:", device)
}


@(objc_type=MetalLayer, objc_name="opaque")
MetalLayer_opaque :: proc(self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "opaque")
}
@(objc_type=MetalLayer, objc_name="setOpaque")
MetalLayer_setOpaque :: proc(self: ^MetalLayer, opaque: NS.BOOL) {
	msgSend(nil, self, "setOpaque:", opaque)
}

@(objc_type=MetalLayer, objc_name="preferredDevice")
MetalLayer_preferredDevice :: proc(self: ^MetalLayer) -> ^MTL.Device {
	return msgSend(^MTL.Device, self, "preferredDevice")
}
@(objc_type=MetalLayer, objc_name="pixelFormat")
MetalLayer_pixelFormat :: proc(self: ^MetalLayer) -> MTL.PixelFormat {
	return msgSend(MTL.PixelFormat, self, "pixelFormat")
}
@(objc_type=MetalLayer, objc_name="setPixelFormat")
MetalLayer_setPixelFormat :: proc(self: ^MetalLayer, pixelFormat: MTL.PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}

@(objc_type=MetalLayer, objc_name="framebufferOnly")
MetalLayer_framebufferOnly :: proc(self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "framebufferOnly")
}
@(objc_type=MetalLayer, objc_name="setFramebufferOnly")
MetalLayer_setFramebufferOnly :: proc(self: ^MetalLayer, ok: NS.BOOL) {
	msgSend(nil, self, "setFramebufferOnly:", ok)
}

@(objc_type=MetalLayer, objc_name="frame")
MetalLayer_frame :: proc(self: ^MetalLayer) -> NS.Rect {
	return msgSend(NS.Rect, self, "frame")
}
@(objc_type=MetalLayer, objc_name="setFrame")
MetalLayer_setFrame :: proc(self: ^MetalLayer, frame: NS.Rect) {
	msgSend(nil, self, "setFrame:", frame)
}


@(objc_type=MetalLayer, objc_name="nextDrawable")
MetalLayer_nextDrawable :: proc(self: ^MetalLayer) -> ^MetalDrawable {
	return msgSend(^MetalDrawable, self, "nextDrawable")
}



@(objc_class="CAMetalDrawable")
MetalDrawable :: struct { using _: MTL.Drawable }

@(objc_type=MetalDrawable, objc_name="layer")
MetalDrawable_layer :: proc(self: ^MetalDrawable) -> ^MetalLayer {
	return msgSend(^MetalLayer, self, "layer")
}

@(objc_type=MetalDrawable, objc_name="texture")
MetalDrawable_texture :: proc(self: ^MetalDrawable) -> ^MTL.Texture {
	return msgSend(^MTL.Texture, self, "texture")
}