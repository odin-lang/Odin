package objc_Metal

import NS "core:sys/darwin/Foundation"
import "core:c"

@(require)
foreign import "system:Metal.framework"

@(default_calling_convention="c", link_prefix="MTL")
foreign Metal {
	CopyAllDevices             :: proc() -> ^NS.Array ---
	CopyAllDevicesWithObserver :: proc(observer: ^id, handler: DeviceNotificationHandler) -> ^NS.Array ---
	CreateSystemDefaultDevice  :: proc() -> ^Device ---
	RemoveDeviceObserver       :: proc(observer: id) ---


	IOCompressionContextDefaultChunkSize :: proc() -> c.size_t ---
	IOCreateCompressionContext           :: proc(path: cstring, type: IOCompressionMethod, chuckSize: c.size_t) -> rawptr ---
	IOCompressionContextAppendData       :: proc(ctx: rawptr, data: rawptr, size: c.size_t) ---
	IOFlushAndDestroyCompressionContext  :: proc(ctx: rawptr) -> IOCompressionStatus ---
}


new :: proc($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, NS.Object) {
	return T.alloc()->init()
}