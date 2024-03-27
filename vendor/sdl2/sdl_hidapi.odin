package sdl2

import "core:c"

hid_device :: struct {}

hid_device_info :: struct
{
    path: cstring,
    vendor_id: c.ushort,
    product_id: c.ushort,
    serial_number: ^c.wchar_t,
    release_number: c.ushort,
    manufacturer_string: ^c.wchar_t,
    product_string: ^c.wchar_t,
    usage_page: c.ushort,
    usage: c.ushort,
    interface_number: c.int,
    interface_class: c.int,
    interface_subclass: c.int,
    interface_protocol: c.int,
    next : ^hid_device_info,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
    hid_init                     :: proc() -> c.int ---
    hid_exit                     :: proc() -> c.int ---
    hid_device_change_count      :: proc() -> u32 ---
    hid_enumerate                :: proc(vendor_id, product_id: c.ushort) -> ^hid_device_info ---
    hid_free_enumeration         :: proc(devs: ^hid_device_info) ---
    hid_open                     :: proc(vendor_id, product_id: c.ushort, serial_number: ^c.wchar_t) -> ^hid_device ---
    hid_write                    :: proc(dev: ^hid_device, data: cstring, length: c.size_t) -> c.int ---
    hid_read_timeout             :: proc(dev: ^hid_device, data: cstring, length: c.size_t, milliseconds: c.int) -> c.int ---
    hid_read                     :: proc(dev: ^hid_device, data: cstring, length: c.size_t) -> c.int ---
    hid_set_nonblocking          :: proc(dev: ^hid_device, nonblock: bool) -> c.int ---
    hid_send_feature_report      :: proc(dev: ^hid_device, data: cstring, length: c.size_t) -> c.int ---
    hid_close                    :: proc(dev: ^hid_device) ---
    hid_get_manufacturer_string  :: proc(dev: ^hid_device, str: ^c.wchar_t, maxLen: c.size_t) -> c.int ---
    hid_get_product_string       :: proc(dev: ^hid_device, str: ^c.wchar_t, maxLen: c.size_t) -> c.int ---
    hid_get_serial_number_string :: proc(dev: ^hid_device, str: ^c.wchar_t, maxLen: c.size_t) -> c.int ---
    hid_get_indexed_string       :: proc(dev: ^hid_device, stringIndex: c.int, str: ^c.wchar_t, maxLen: c.size_t) -> c.int ---
    hid_ble_scan                 :: proc(active : bool) ---
}