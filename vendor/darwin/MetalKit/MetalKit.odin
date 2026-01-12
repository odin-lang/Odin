// Bindings for [[ MetalKit ; https://developer.apple.com/documentation/metalkit ]].
package objc_MetalKit

import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"
import "base:intrinsics"

@(require)
foreign import "system:MetalKit.framework"

@(private)
msgSend :: intrinsics.objc_send

ColorSpaceRef :: struct {}

ViewDelegate :: struct {
	drawInMTKView:          proc "c" (self: ^ViewDelegate, view: ^View),
	drawableSizeWillChange: proc "c" (self: ^ViewDelegate, view: ^View, size: NS.Size),

	user_data: rawptr,
}

@(objc_class="MTKView")
View :: struct {using _: NS.View}

@(objc_type=View, objc_name="alloc", objc_is_class_method=true)
View_alloc :: proc "c" () -> ^View {
	return msgSend(^View, View, "alloc")
}
@(objc_type=View, objc_name="initWithFrame")
View_initWithFrame :: proc "c" (self: ^View, frame: NS.Rect, device: ^MTL.Device) -> ^View {
	return msgSend(^View, self, "initWithFrame:device:", frame, device)
}
@(objc_type=View, objc_name="initWithCoder")
View_initWithCoder :: proc "c" (self: ^View, coder: ^NS.Coder) -> ^View {
	return msgSend(^View, self, "initWithCoder:", coder)
}

@(objc_type=View, objc_name="setDevice")
View_setDevice :: proc "c" (self: ^View, device: ^MTL.Device) {
	msgSend(nil, self, "setDevice:", device)
}
@(objc_type=View, objc_name="device")
View_device :: proc "c" (self: ^View) -> ^MTL.Device {
	return msgSend(^MTL.Device, self, "device")
}

@(objc_type=View, objc_name="draw")
View_draw :: proc "c" (self: ^View) {
	msgSend(nil, self, "draw")
}

@(objc_type=View, objc_name="setDelegate")
View_setDelegate :: proc "c" (self: ^View, delegate: ^ViewDelegate) {
	drawDispatch :: proc "c" (self: ^NS.Value, cmd: NS.SEL, view: ^View) {
		del := (^ViewDelegate)(self->pointerValue())
		del->drawInMTKView(view)
	}
	drawableSizeWillChange :: proc "c" (self: ^NS.Value, cmd: NS.SEL, view: ^View, size: NS.Size) {
		del := (^ViewDelegate)(self->pointerValue())
		del->drawableSizeWillChange(view, size)
	}

	wrapper := NS.Value.valueWithPointer(delegate)

	NS.class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("drawInMTKView:"), auto_cast drawDispatch, "v@:@")

	cbparams :: "v@:@{CGSize=ff}" when size_of(NS.Float) == size_of(f32) else "v@:@{CGSize=dd}"
	NS.class_addMethod(intrinsics.objc_find_class("NSValue"), intrinsics.objc_find_selector("mtkView:drawableSizeWillChange:"), auto_cast drawableSizeWillChange, cbparams)

	msgSend(nil, self, "setDelegate:", wrapper)
}

@(objc_type=View, objc_name="delegate")
View_delegate :: proc "c" (self: ^View) -> ^ViewDelegate {
	wrapper := msgSend(^NS.Value, self, "delegate")
	if wrapper != nil {
		return (^ViewDelegate)(wrapper->pointerValue())
	}
	return nil
}

@(objc_type=View, objc_name="currentDrawable")
View_currentDrawable :: proc "c" (self: ^View) -> ^CA.MetalDrawable {
	return msgSend(^CA.MetalDrawable, self, "currentDrawable")
}

@(objc_type=View, objc_name="setFramebufferOnly")
View_setFramebufferOnly :: proc "c" (self: ^View, framebufferOnly: bool) {
	msgSend(nil, self, "setFramebufferOnly:", framebufferOnly)
}
@(objc_type=View, objc_name="framebufferOnly")
View_framebufferOnly :: proc "c" (self: ^View) -> bool {
	return msgSend(bool, self, "framebufferOnly")
}

@(objc_type=View, objc_name="setDepthStencilAttachmentTextureUsage")
View_setDepthStencilAttachmentTextureUsage :: proc "c" (self: ^View, textureUsage: MTL.TextureUsage) {
	msgSend(nil, self, "setDepthStencilAttachmentTextureUsage:", textureUsage)
}
@(objc_type=View, objc_name="depthStencilAttachmentTextureUsage")
View_depthStencilAttachmentTextureUsage :: proc "c" (self: ^View) -> MTL.TextureUsage {
	return msgSend(MTL.TextureUsage, self, "depthStencilAttachmentTextureUsage")
}

@(objc_type=View, objc_name="setMultisampleColorAttachmentTextureUsage")
View_setMultisampleColorAttachmentTextureUsage :: proc "c" (self: ^View, textureUsage: MTL.TextureUsage) {
	msgSend(nil, self, "setMultisampleColorAttachmentTextureUsage:", textureUsage)
}
@(objc_type=View, objc_name="multisampleColorAttachmentTextureUsage")
View_multisampleColorAttachmentTextureUsage :: proc "c" (self: ^View) -> MTL.TextureUsage {
	return msgSend(MTL.TextureUsage, self, "multisampleColorAttachmentTextureUsage")
}

@(objc_type=View, objc_name="setPresentsWithTransaction")
View_setPresentsWithTransaction :: proc "c" (self: ^View, presentsWithTransaction: bool) {
	msgSend(nil, self, "setPresentsWithTransaction:", presentsWithTransaction)
}
@(objc_type=View, objc_name="presentsWithTransaction")
View_presentsWithTransaction :: proc "c" (self: ^View) -> bool {
	return msgSend(bool, self, "presentsWithTransaction")
}

@(objc_type=View, objc_name="setColorPixelFormat")
View_setColorPixelFormat :: proc "c" (self: ^View, colorPixelFormat: MTL.PixelFormat) {
	msgSend(nil, self, "setColorPixelFormat:", colorPixelFormat)
}
@(objc_type=View, objc_name="colorPixelFormat")
View_colorPixelFormat :: proc "c" (self: ^View) -> MTL.PixelFormat {
	return msgSend(MTL.PixelFormat, self, "colorPixelFormat")
}

@(objc_type=View, objc_name="setDepthStencilPixelFormat")
View_setDepthStencilPixelFormat :: proc "c" (self: ^View, colorPixelFormat: MTL.PixelFormat) {
	msgSend(nil, self, "setDepthStencilPixelFormat:", colorPixelFormat)
}
@(objc_type=View, objc_name="depthStencilPixelFormat")
View_depthStencilPixelFormat :: proc "c" (self: ^View) -> MTL.PixelFormat {
	return msgSend(MTL.PixelFormat, self, "depthStencilPixelFormat")
}

@(objc_type=View, objc_name="setSampleCount")
View_setSampleCount :: proc "c" (self: ^View, sampleCount: NS.UInteger) {
	msgSend(nil, self, "setSampleCount:", sampleCount)
}
@(objc_type=View, objc_name="sampleCount")
View_sampleCount :: proc "c" (self: ^View) -> NS.UInteger {
	return msgSend(NS.UInteger, self, "sampleCount")
}

@(objc_type=View, objc_name="setClearColor")
View_setClearColor :: proc "c" (self: ^View, clearColor: MTL.ClearColor) {
	msgSend(nil, self, "setClearColor:", clearColor)
}
@(objc_type=View, objc_name="clearColor")
View_clearColor :: proc "c" (self: ^View) -> MTL.ClearColor {
	return msgSend(MTL.ClearColor, self, "clearColor")
}

@(objc_type=View, objc_name="setClearDepth")
View_setClearDepth :: proc "c" (self: ^View, clearDepth: f64) {
	msgSend(nil, self, "setClearDepth:", clearDepth)
}
@(objc_type=View, objc_name="clearDepth")
View_clearDepth :: proc "c" (self: ^View) -> f64 {
	return msgSend(f64, self, "clearDepth")
}

@(objc_type=View, objc_name="setClearStencil")
View_setClearStencil :: proc "c" (self: ^View, clearStencil: u32) {
	msgSend(nil, self, "setClearStencil:", clearStencil)
}
@(objc_type=View, objc_name="clearStencil")
View_clearStencil :: proc "c" (self: ^View) -> u32 {
	return msgSend(u32, self, "clearStencil")
}

@(objc_type=View, objc_name="depthStencilTexture")
View_depthStencilTexture :: proc "c" (self: ^View) -> ^MTL.Texture {
	return msgSend(^MTL.Texture, self, "depthStencilTexture")
}
@(objc_type=View, objc_name="multisampleColorTexture")
View_multisampleColorTexture :: proc "c" (self: ^View) -> ^MTL.Texture {
	return msgSend(^MTL.Texture, self, "multisampleColorTexture")
}

@(objc_type=View, objc_name="releaseDrawables")
View_releaseDrawables :: proc "c" (self: ^View) {
	msgSend(nil, self, "releaseDrawables")
}

@(objc_type=View, objc_name="currentRenderPassDescriptor")
View_currentRenderPassDescriptor :: proc "c" (self: ^View) -> ^MTL.RenderPassDescriptor {
	return msgSend(^MTL.RenderPassDescriptor, self, "currentRenderPassDescriptor")
}

@(objc_type=View, objc_name="setPreferredFramesPerSecond")
View_setPreferredFramesPerSecond :: proc "c" (self: ^View, preferredFramesPerSecond: NS.Integer) {
	msgSend(nil, self, "setPreferredFramesPerSecond:", preferredFramesPerSecond)
}
@(objc_type=View, objc_name="preferredFramesPerSecond")
View_preferredFramesPerSecond :: proc "c" (self: ^View) -> NS.Integer {
	return msgSend(NS.Integer, self, "preferredFramesPerSecond")
}

@(objc_type=View, objc_name="setEnableSetNeedsDisplay")
View_setEnableSetNeedsDisplay :: proc "c" (self: ^View, enableSetNeedsDisplay: bool) {
	msgSend(nil, self, "setEnableSetNeedsDisplay:", enableSetNeedsDisplay)
}
@(objc_type=View, objc_name="enableSetNeedsDisplay")
View_enableSetNeedsDisplay :: proc "c" (self: ^View) -> bool {
	return msgSend(bool, self, "enableSetNeedsDisplay")
}

@(objc_type=View, objc_name="setAutoresizeDrawable")
View_setAutoresizeDrawable :: proc "c" (self: ^View, autoresizeDrawable: bool) {
	msgSend(nil, self, "setAutoresizeDrawable:", autoresizeDrawable)
}
@(objc_type=View, objc_name="autoresizeDrawable")
View_autoresizeDrawable :: proc "c" (self: ^View) -> bool {
	return msgSend(bool, self, "autoresizeDrawable")
}

@(objc_type=View, objc_name="setDrawableSize")
View_setDrawableSize :: proc "c" (self: ^View, drawableSize: NS.Size) {
	msgSend(nil, self, "setDrawableSize:", drawableSize)
}
@(objc_type=View, objc_name="drawableSize")
View_drawableSize :: proc "c" (self: ^View) -> NS.Size {
	return msgSend(NS.Size, self, "drawableSize")
}

@(objc_type=View, objc_name="preferredDrawableSize")
View_preferredDrawableSize :: proc "c" (self: ^View) -> NS.Size {
	return msgSend(NS.Size, self, "preferredDrawableSize")
}

@(objc_type=View, objc_name="preferredDevice")
View_preferredDevice :: proc "c" (self: ^View) -> ^MTL.Device {
	return msgSend(^MTL.Device, self, "preferredDevice")
}

@(objc_type=View, objc_name="setPaused")
View_setPaused :: proc "c" (self: ^View, isPaused: bool) {
	msgSend(nil, self, "setPaused:", isPaused)
}
@(objc_type=View, objc_name="isPaused")
View_isPaused :: proc "c" (self: ^View) -> bool {
	return msgSend(bool, self, "isPaused")
}

@(objc_type=View, objc_name="setColorSpace")
View_setColorSpace :: proc "c" (self: ^View, colorSpace: ColorSpaceRef) {
	msgSend(nil, self, "setColorSpace:", colorSpace)
}
@(objc_type=View, objc_name="colorSpace")
View_colorSpace :: proc "c" (self: ^View) -> ColorSpaceRef {
	return msgSend(ColorSpaceRef, self, "colorSpace")
}
