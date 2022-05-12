// +build windows
package sys_windows

foreign import "system:bthprops.lib"

HBLUETOOTH_DEVICE_FIND :: distinct HANDLE
HBLUETOOTH_RADIO_FIND  :: distinct HANDLE

BLUETOOTH_FIND_RADIO_PARAMS :: struct {
	dw_size: DWORD,
}

BLUETOOTH_RADIO_INFO :: struct {
	dw_size:           DWORD,                        // Size of this structure
	address:           BLUETOOTH_ADDRESS,            // Address of radio
	name:              [BLUETOOTH_MAX_NAME_SIZE]u16, // Name of the radio
	device_class:      ULONG,                        // Bluetooth "Class of Device". See: https://btprodspecificationrefs.blob.core.windows.net/assigned-numbers/Assigned%20Number%20Types/Baseband.pdf
	lmp_minor_version: USHORT,                       // This member contains data specific to individual Bluetooth device manufacturers.
	manufacturer:      USHORT,                       // Manufacturer of the Bluetooth radio, expressed as a BTH_MFG_Xxx value. See https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers/
}

BLUETOOTH_DEVICE_SEARCH_PARAMS :: struct {
	dw_size:              DWORD,  // Size of this structure

	return_authenticated: BOOL,   // Return authenticated devices
	return_remembered:    BOOL,   // Return remembered devices
	return_unknown:       BOOL,   // Return unknown devices
	return_connected:     BOOL,   // Return connected devices
	issue_inquiry:        BOOL,   // Issue a new inquiry
	timeout_multiplier:   UCHAR,  // Timeout for the inquiry, expressed in increments of 1.28 seconds
	radio:                HANDLE, // Handle to radio to enumerate - NULL == all radios will be searched
}

BLUETOOTH_ADDRESS :: struct #raw_union {
	addr: u64,
	val:  [6]u8, // The first 3 bytes can be used to find the Manufacturer using http://standards-oui.ieee.org/oui/oui.txt
}

BLUETOOTH_MAX_NAME_SIZE :: 248

BLUETOOTH_DEVICE_INFO :: struct {
	dw_size:       DWORD,                        //  Size in bytes of this structure - must be the size_of(BLUETOOTH_DEVICE_INFO)

	address:       BLUETOOTH_ADDRESS,            //  Bluetooth address
	device_class:  ULONG,                        //  Bluetooth "Class of Device". See: https://btprodspecificationrefs.blob.core.windows.net/assigned-numbers/Assigned%20Number%20Types/Baseband.pdf
	connected:     BOOL,                         //  Device connected/in use
	remembered:    BOOL,                         //  Device remembered
	authenticated: BOOL,                         //  Device authenticated/paired/bonded
	last_seen:     SYSTEMTIME,                   //  Last time the device was seen
	last_used:     SYSTEMTIME,                   //  Last time the device was used for other than RNR, inquiry, or SDP
	name:          [BLUETOOTH_MAX_NAME_SIZE]u16, //  Name of the device
}

@(default_calling_convention="stdcall")
foreign bthprops {
	/*
		Version
	*/
	@(link_name="BluetoothIsVersionAvailable")      bluetooth_is_version_available :: proc(
		major: u8, minor: u8,
	) -> BOOL ---

	/*
		Radio enumeration
	*/
	@(link_name="BluetoothFindFirstRadio")          bluetooth_find_first_radio :: proc(
		find_radio_params: ^BLUETOOTH_FIND_RADIO_PARAMS, radio: ^HANDLE,
	) -> HBLUETOOTH_RADIO_FIND ---

	@(link_name="BluetoothFindNextRadio")           bluetooth_find_next_radio :: proc(
		handle: HBLUETOOTH_RADIO_FIND, radio: ^HANDLE,
	) -> BOOL ---

	@(link_name="BluetoothFindRadioClose")          bluetooth_find_radio_close :: proc(
		handle: HBLUETOOTH_RADIO_FIND,
	) -> BOOL ---

	@(link_name="BluetoothGetRadioInfo")            bluetooth_get_radio_info :: proc(
		radio: HANDLE, radio_info: ^BLUETOOTH_RADIO_INFO,
	) -> DWORD ---

	/*
		Device enumeration
	*/
	@(link_name="BluetoothFindFirstDevice")         bluetooth_find_first_device :: proc(
		search_params: ^BLUETOOTH_DEVICE_SEARCH_PARAMS, device_info: ^BLUETOOTH_DEVICE_INFO,
	) -> HBLUETOOTH_DEVICE_FIND ---

	@(link_name="BluetoothFindNextDevice")          bluetooth_find_next_device :: proc(
		handle: HBLUETOOTH_DEVICE_FIND, device_info: ^BLUETOOTH_DEVICE_INFO,
	) -> BOOL ---

	@(link_name="BluetoothFindDeviceClose")         bluetooth_find_device_close :: proc(
		handle: HBLUETOOTH_DEVICE_FIND,
	) -> BOOL ---

	@(link_name="BluetoothGetDeviceInfo")           bluetooth_get_device_info :: proc(
		radio: HANDLE, device_info: ^BLUETOOTH_DEVICE_INFO,
	) -> DWORD ---

	@(link_name="BluetoothDisplayDeviceProperties") bluetooth_display_device_properties :: proc(
		hwnd_parent: HWND, device_info: ^BLUETOOTH_DEVICE_INFO,
	) -> BOOL ---
}