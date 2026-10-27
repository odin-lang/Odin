package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

// An opaque handle to a HID device, which HID_open and HID_open_path return.
hid_device :: struct {}

// Information about a HID device, as hid_enumerate returns it, as a linked list.
hid_device_info :: struct {
	path:                cstring,     /**< Platform-specific device path */
	vendor_id:           u16,         /**< Device Vendor ID */
	product_id:          u16,         /**< Device Product ID */
	serial_number:       [^]c.wchar_t, /**< Serial Number */
	release_number:      u16,         /**< Device Release Number in binary-coded decimal, also known as Device Version Number */
	manufacturer_string: [^]c.wchar_t, /**< Manufacturer String */
	product_string:      [^]c.wchar_t, /**< Product string */
	usage_page:          u16,         /**< Usage Page for this Device/Interface (Windows/Mac only). */
	usage:               u16,         /**< Usage for this Device/Interface (Windows/Mac only). */
	interface_number:    c.int,       /**< The USB interface which this logical device represents. Valid on both Linux implementations in all cases, and valid on the Windows implementation only if the device contains more than one interface. */
	interface_class:     c.int,       /**< Additional information about the USB interface. Valid on libusb and Android implementations. */
	interface_subclass:  c.int,
	interface_protocol:  c.int,
	next:                ^hid_device_info, /**< Pointer to the next device */
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	// Initialize the HIDAPI library, returns 0 on success.
	hid_init :: proc() -> c.int ---

	// Finalize the HIDAPI library, returns 0 on success.
	hid_exit :: proc() -> c.int ---

	// Check to see if devices may have been added or removed. Returns a counter that changes when devices change.
	hid_device_change_count :: proc() -> u32 ---

	// Enumerate the HID Devices matching a vendor and product id, or all of them with zeros. Free the result with hid_free_enumeration.
	hid_enumerate         :: proc(vendor_id, product_id: u16) -> ^hid_device_info ---
	hid_free_enumeration  :: proc(devs: ^hid_device_info) ---

	// Open a HID device by vendor id, product id and optional serial number, or by its path.
	hid_open      :: proc(vendor_id, product_id: u16, serial_number: [^]c.wchar_t) -> ^hid_device ---
	hid_open_path :: proc(path: cstring, bExclusive: c.int) -> ^hid_device ---
	hid_close     :: proc(dev: ^hid_device) ---

	// Write an Output report to a HID device, returning the number of bytes written or -1 on failure.
	hid_write :: proc(dev: ^hid_device, data: [^]u8, length: c.size_t) -> c.int ---

	// Read an Input report from a HID device, with a timeout in milliseconds, or with the device's blocking mode.
	hid_read_timeout :: proc(dev: ^hid_device, data: [^]u8, length: c.size_t, milliseconds: c.int) -> c.int ---
	hid_read         :: proc(dev: ^hid_device, data: [^]u8, length: c.size_t) -> c.int ---

	// Set the device handle to be non-blocking.
	hid_set_nonblocking :: proc(dev: ^hid_device, nonblock: c.int) -> c.int ---

	// Send and get a Feature report.
	hid_send_feature_report :: proc(dev: ^hid_device, data: [^]u8, length: c.size_t) -> c.int ---
	hid_get_feature_report  :: proc(dev: ^hid_device, data: [^]u8, length: c.size_t) -> c.int ---

	// Get strings from a HID device.
	hid_get_manufacturer_string  :: proc(dev: ^hid_device, str: [^]c.wchar_t, maxlen: c.size_t) -> c.int ---
	hid_get_product_string       :: proc(dev: ^hid_device, str: [^]c.wchar_t, maxlen: c.size_t) -> c.int ---
	hid_get_serial_number_string :: proc(dev: ^hid_device, str: [^]c.wchar_t, maxlen: c.size_t) -> c.int ---
	hid_get_indexed_string       :: proc(dev: ^hid_device, string_index: c.int, str: [^]c.wchar_t, maxlen: c.size_t) -> c.int ---

	// Start or stop a BLE scan on iOS and tvOS to pair Steam Controllers.
	hid_ble_scan :: proc(active: bool) ---
}
