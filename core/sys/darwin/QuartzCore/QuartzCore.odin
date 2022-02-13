package objc_QuartzCore

import NS "core:sys/darwin/Foundation"
import MTL "core:sys/darwin/Metal"
import "core:intrinsics"

@(private)
msgSend :: intrinsics.objc_send

@(objc_class="CAMetalLayer")
MetalLayer :: struct{ using _: NS.Layer}

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
@(objc_type=MetalLayer, objc_name="framebufferOnly")
MetalLayer_framebufferOnly :: proc(self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "framebufferOnly")
}


@(objc_class="CAMetalDrawable")
MetalDrawable :: struct { using _: MTL.Drawable }

MetalDrawable_layer :: proc(self: ^MetalDrawable) -> ^MetalLayer {
	return msgSend(^MetalLayer, self, "layer")
}

MetalDrawable_texture :: proc(self: ^MetalDrawable) -> ^MTL.Texture {
	return msgSend(^MTL.Texture, self, "texture")
}