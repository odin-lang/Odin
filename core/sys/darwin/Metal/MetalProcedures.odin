package objc_Metal

import NS "core:sys/darwin/Foundation"

@(require)
foreign import "system:Metal.framework"

@(default_calling_convention="c", link_prefix="MTL")
foreign Metal {
	CopyAllDevices             :: proc() -> ^NS.Array ---
	CopyAllDevicesWithObserver :: proc(observer: ^^NS.Object, handler: DeviceNotificationHandler) -> ^NS.Array ---
	CreateSystemDefaultDevice  :: proc() -> ^NS.Object ---
	RemoveDeviceObserver       :: proc(observer: ^NS.Object) ---
}