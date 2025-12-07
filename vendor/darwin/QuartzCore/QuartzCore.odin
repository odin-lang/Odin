// Bindings for [[ QuartzCore ; https://developer.apple.com/documentation/quartzcore ]].
package objc_QuartzCore

import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import "base:intrinsics"

@(private)
msgSend :: intrinsics.objc_send

@(objc_class="CAMetalLayer")
MetalLayer :: struct{ using _: NS.Layer}

@(objc_type=MetalLayer, objc_name="layer", objc_is_class_method=true)
MetalLayer_layer :: proc "c" () -> ^MetalLayer {
	return msgSend(^MetalLayer, MetalLayer, "layer")
}

@(objc_type=MetalLayer, objc_name="device")
MetalLayer_device :: proc "c" (self: ^MetalLayer) -> ^MTL.Device {
	return msgSend(^MTL.Device, self, "device")
}
@(objc_type=MetalLayer, objc_name="setDevice")
MetalLayer_setDevice :: proc "c" (self: ^MetalLayer, device: ^MTL.Device) {
	msgSend(nil, self, "setDevice:", device)
}


@(objc_type=MetalLayer, objc_name="opaque")
MetalLayer_opaque :: proc "c" (self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "opaque")
}
@(objc_type=MetalLayer, objc_name="setOpaque")
MetalLayer_setOpaque :: proc "c" (self: ^MetalLayer, opaque: NS.BOOL) {
	msgSend(nil, self, "setOpaque:", opaque)
}

@(objc_type=MetalLayer, objc_name="preferredDevice")
MetalLayer_preferredDevice :: proc "c" (self: ^MetalLayer) -> ^MTL.Device {
	return msgSend(^MTL.Device, self, "preferredDevice")
}
@(objc_type=MetalLayer, objc_name="pixelFormat")
MetalLayer_pixelFormat :: proc "c" (self: ^MetalLayer) -> MTL.PixelFormat {
	return msgSend(MTL.PixelFormat, self, "pixelFormat")
}
@(objc_type=MetalLayer, objc_name="setPixelFormat")
MetalLayer_setPixelFormat :: proc "c" (self: ^MetalLayer, pixelFormat: MTL.PixelFormat) {
	msgSend(nil, self, "setPixelFormat:", pixelFormat)
}

@(objc_type=MetalLayer, objc_name="framebufferOnly")
MetalLayer_framebufferOnly :: proc "c" (self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "framebufferOnly")
}
@(objc_type=MetalLayer, objc_name="setFramebufferOnly")
MetalLayer_setFramebufferOnly :: proc "c" (self: ^MetalLayer, ok: NS.BOOL) {
	msgSend(nil, self, "setFramebufferOnly:", ok)
}
@(objc_type=MetalLayer, objc_name="maximumDrawableCount")
MetalLayer_maximumDrawableCount :: proc "c" (self: ^MetalLayer) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "maximumDrawableCount")
}
@(objc_type=MetalLayer, objc_name="setMaximumDrawableCount")
MetalLayer_setMaximumDrawableCount :: proc "c" (self: ^MetalLayer, count: NS.UInteger) {
	msgSend(nil, self, "setMaximumDrawableCount:", count)
}

@(objc_type=MetalLayer, objc_name="drawableSize")
MetalLayer_drawableSize :: proc "c" (self: ^MetalLayer) -> NS.Size {
	return msgSend(NS.Size, self, "drawableSize")
}
@(objc_type=MetalLayer, objc_name="setDrawableSize")
MetalLayer_setDrawableSize :: proc "c" (self: ^MetalLayer, drawableSize: NS.Size) {
	msgSend(nil, self, "setDrawableSize:", drawableSize)
}
@(objc_type=MetalLayer, objc_name="displaySyncEnabled")
MetalLayer_displaySyncEnabled :: proc "c" (self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "displaySyncEnabled")
}
@(objc_type=MetalLayer, objc_name="setDisplaySyncEnabled")
MetalLayer_setDisplaySyncEnabled :: proc "c" (self: ^MetalLayer, enabled: NS.BOOL) {
	msgSend(nil, self, "setDisplaySyncEnabled:", enabled)
}
@(objc_type=MetalLayer, objc_name="presentsWithTransaction")
MetalLayer_presentsWithTransaction :: proc "c" (self: ^MetalLayer) -> NS.BOOL {
	return msgSend(NS.BOOL, self, "presentsWithTransaction")
}
@(objc_type=MetalLayer, objc_name="setPresentsWithTransaction")
MetalLayer_setPresentsWithTransaction :: proc "c" (self: ^MetalLayer, enabled: NS.BOOL) {
	msgSend(nil, self, "setPresentsWithTransaction:", enabled)
}

@(objc_type=MetalLayer, objc_name="frame")
MetalLayer_frame :: proc "c" (self: ^MetalLayer) -> NS.Rect {
	return msgSend(NS.Rect, self, "frame")
}
@(objc_type=MetalLayer, objc_name="setFrame")
MetalLayer_setFrame :: proc "c" (self: ^MetalLayer, frame: NS.Rect) {
	msgSend(nil, self, "setFrame:", frame)
}


@(objc_type=MetalLayer, objc_name="nextDrawable")
MetalLayer_nextDrawable :: proc "c" (self: ^MetalLayer) -> ^MetalDrawable {
	return msgSend(^MetalDrawable, self, "nextDrawable")
}



@(objc_class="CAMetalDrawable")
MetalDrawable :: struct { using _: MTL.Drawable }

@(objc_type=MetalDrawable, objc_name="layer")
MetalDrawable_layer :: proc "c" (self: ^MetalDrawable) -> ^MetalLayer {
	return msgSend(^MetalLayer, self, "layer")
}

@(objc_type=MetalDrawable, objc_name="texture")
MetalDrawable_texture :: proc "c" (self: ^MetalDrawable) -> ^MTL.Texture {
	return msgSend(^MTL.Texture, self, "texture")
}

DrawablePresentedHandler :: ^NS.Block
@(objc_type=MetalDrawable, objc_name="addPresentedHandler")
MetalDrawable_addPresentedHandler :: proc "c" (self: ^MetalDrawable, block: DrawablePresentedHandler) {
	msgSend(nil, self, "addPresentedHandler:", block)
}

