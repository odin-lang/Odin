package sdl3

import "core:c"


hid_device :: struct {}

hid_bus_type :: enum c.int {
	/** Unknown bus type */
	UNKNOWN = 0x00,

	/** USB bus
	    Specifications:
	    https://usb.org/hid */
	USB = 0x01,

	/** Bluetooth or Bluetooth LE bus
	    Specifications:
	    https://www.bluetooth.com/specifications/specs/human-interface-device-profile-1-1-1/
	    https://www.bluetooth.com/specifications/specs/hid-service-1-0/
	    https://www.bluetooth.com/specifications/specs/hid-over-gatt-profile-1-0/ */
	BLUETOOTH = 0x02,

	/** I2C bus
	    Specifications:
	    https://docs.microsoft.com/previous-versions/windows/hardware/design/dn642101(v=vs.85) */
	I2C = 0x03,

	/** SPI bus
	    Specifications:
	    https://www.microsoft.com/download/details.aspx?id=103325 */
	SPI = 0x04,
}

hid_device_info :: struct {
	/** Platform-specific device path */
	path: [^]c.char `fmt:"q,0"`,
	/** Device Vendor ID */
	vendor_id: c.ushort,
	/** Device Product ID */
	product_id: c.ushort,
	/** Serial Number */
	serial_number: [^]c.wchar_t `fmt:"q,0"`,
	/** Device Release Number in binary-coded decimal,
	also known as Device Version Number */
	release_number: c.ushort,
	/** Manufacturer String */
	manufacturer_string: [^]c.wchar_t `fmt:"q,0"`,
	/** Product string */
	product_string: [^]c.wchar_t `fmt:"q,0"`,
	/** Usage Page for this Device/Interface
	(Windows/Mac/hidraw only) */
	usage_page: c.ushort,
	/** Usage for this Device/Interface
	(Windows/Mac/hidraw only) */
	usage: c.ushort,
	/** The USB interface which this logical device
	    represents.

	    Valid only if the device is a USB HID device.
	    Set to -1 in all other cases.
	*/
	interface_number: c.int,

	/** Additional information about the USB interface.
	Valid on libusb and Android implementations. */
	interface_class: c.int,
	interface_subclass: c.int,
	interface_protocol: c.int,

	/** Underlying bus type */
	bus_type: hid_bus_type,

	/** Pointer to the next device */
	next: ^hid_device_info,
}


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	hid_init                     :: proc() -> c.int ---
	hid_exit                     :: proc() -> c.int ---
	hid_device_change_count      :: proc() -> Uint32 ---
	hid_enumerate                :: proc(vendor_id, product_id: c.ushort) -> ^hid_device_info ---
	hid_free_enumeration         :: proc(devs: ^hid_device_info) ---
	hid_open                     :: proc(vendor_id, product_id: c.ushort, serial_number: [^]c.wchar_t) -> ^hid_device ---
	hid_open_path                :: proc(path: cstring) -> ^hid_device ---
	hid_write                    :: proc(dev: ^hid_device, data: [^]byte, length: uint) -> c.int ---
	hid_read_timeout             :: proc(dev: ^hid_device, data: [^]byte, length: uint, milliseconds: c.int) -> c.int ---
	hid_read                     :: proc(dev: ^hid_device, data: [^]byte, length: uint) -> c.int ---
	hid_set_nonblocking          :: proc(dev: ^hid_device, nonblock: c.int) -> c.int ---
	hid_send_feature_report      :: proc(dev: ^hid_device, data: [^]byte, length: uint) -> c.int ---
	hid_get_feature_report       :: proc(dev: ^hid_device, data: [^]byte, length: uint) -> c.int ---
	hid_get_input_report         :: proc(dev: ^hid_device, data: [^]byte, length: uint) -> c.int ---
	hid_close                    :: proc(dev: ^hid_device) -> c.int ---
	hid_get_manufacturer_string  :: proc(dev: ^hid_device, string: [^]c.wchar_t, maxlen: uint) -> c.int ---
	hid_get_product_string       :: proc(dev: ^hid_device, string: [^]c.wchar_t, maxlen: uint) -> c.int ---
	hid_get_serial_number_string :: proc(dev: ^hid_device, string: [^]c.wchar_t, maxlen: uint) -> c.int ---
	hid_get_indexed_string       :: proc(dev: ^hid_device, string_index: c.int, string: [^]c.wchar_t, maxlen: uint) -> c.int ---
	hid_get_device_info          :: proc(dev: ^hid_device) -> ^hid_device_info ---
	hid_get_report_descriptor    :: proc(dev: ^hid_device, buf: [^]byte, buf_size: uint) -> c.int ---
	hid_ble_scan                 :: proc(active: bool) ---
}