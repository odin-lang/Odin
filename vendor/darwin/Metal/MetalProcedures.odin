package objc_Metal

import NS "vendor:darwin/Foundation"

@(require)
foreign import "system:Metal.framework"

@(default_calling_convention="c", link_prefix="MTL")
foreign Metal {
	CopyAllDevices             :: proc() -> ^NS.Array ---
	CopyAllDevicesWithObserver :: proc(observer: ^id, handler: DeviceNotificationHandler) -> ^NS.Array ---
	CreateSystemDefaultDevice  :: proc() -> ^Device ---
	RemoveDeviceObserver       :: proc(observer: id) ---
}


new :: proc($T: typeid) -> ^T where intrinsics.type_is_subtype_of(T, NS.Object) {
	return T.alloc()->init()
}