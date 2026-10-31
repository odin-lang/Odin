#+build windows
package sys_windows

HDEVINFO :: distinct HANDLE

SP_DEVINFO_DATA :: struct {
	cbSize:    DWORD,
	ClassGuid: GUID,
	DevInst:   DWORD,
	Reserved:  ULONG_PTR,
}
PSP_DEVINFO_DATA :: ^SP_DEVINFO_DATA

SP_DEVICE_INTERFACE_DATA :: struct {
	cbSize:             DWORD,
	InterfaceClassGuid: GUID,
	Flags:              DWORD,
	Reserved:           ULONG_PTR,
}
PSP_DEVICE_INTERFACE_DATA :: ^SP_DEVICE_INTERFACE_DATA

SP_DEVICE_INTERFACE_DETAIL_DATA_W :: struct {
	cbSize:     DWORD,
	DevicePath: [ANYSIZE_ARRAY]WCHAR,
}
PSP_DEVICE_INTERFACE_DETAIL_DATA_W :: ^SP_DEVICE_INTERFACE_DETAIL_DATA_W

DIGCF_DEFAULT:         DWORD : 0x00000001
DIGCF_PRESENT:         DWORD : 0x00000002
DIGCF_ALLCLASSES:      DWORD : 0x00000004
DIGCF_PROFILE:         DWORD : 0x00000008
DIGCF_DEVICEINTERFACE: DWORD : 0x00000010

SPDRP_ADDRESS:                     DWORD : 28
SPDRP_BASE_CONTAINERID:            DWORD : 36
SPDRP_BUSNUMBER:                   DWORD : 21
SPDRP_BUSTYPEGUID:                 DWORD : 19
SPDRP_CAPABILITIES:                DWORD : 15
SPDRP_CHARACTERISTICS:             DWORD : 27
SPDRP_CLASS:                       DWORD : 7
SPDRP_CLASSGUID:                   DWORD : 8
SPDRP_COMPATIBLEIDS:               DWORD : 2
SPDRP_CONFIGFLAGS:                 DWORD : 10
SPDRP_DEVICEDESC:                  DWORD : 0
SPDRP_DEVICE_POWER_DATA:           DWORD : 30
SPDRP_DEVTYPE:                     DWORD : 25
SPDRP_DRIVER:                      DWORD : 9
SPDRP_ENUMERATOR_NAME:             DWORD : 22
SPDRP_EXCLUSIVE:                   DWORD : 26
SPDRP_FRIENDLYNAME:                DWORD : 12
SPDRP_HARDWAREID:                  DWORD : 1
SPDRP_INSTALL_STATE:               DWORD : 34
SPDRP_LEGACYBUSTYPE:               DWORD : 20
SPDRP_LOCATION_INFORMATION:        DWORD : 13
SPDRP_LOCATION_PATHS:              DWORD : 35
SPDRP_LOWERFILTERS:                DWORD : 18
SPDRP_MAXIMUM_PROPERTY:            DWORD : 37
SPDRP_MFG:                         DWORD : 11
SPDRP_PHYSICAL_DEVICE_OBJECT_NAME: DWORD : 14
SPDRP_REMOVAL_POLICY:              DWORD : 31
SPDRP_REMOVAL_POLICY_HW_DEFAULT:   DWORD : 32
SPDRP_REMOVAL_POLICY_OVERRIDE:     DWORD : 33
SPDRP_SECURITY:                    DWORD : 23
SPDRP_SECURITY_SDS:                DWORD : 24
SPDRP_SERVICE:                     DWORD : 4
SPDRP_UI_NUMBER:                   DWORD : 16
SPDRP_UI_NUMBER_DESC_FORMAT:       DWORD : 29
SPDRP_UNUSED0:                     DWORD : 3
SPDRP_UNUSED1:                     DWORD : 5
SPDRP_UNUSED2:                     DWORD : 6
SPDRP_UPPERFILTERS:                DWORD : 17

foreign import setupapi "system:setupapi.lib"
@(default_calling_convention = "system")
foreign setupapi {
	SetupDiGetClassDevsW              :: proc(ClassGuid: ^GUID, Enumerator: PCWSTR, hwndParent: HWND, Flags: DWORD) -> HDEVINFO ---
	SetupDiDestroyDeviceInfoList      :: proc(DeviceInfoSet: HDEVINFO) -> BOOL ---
	SetupDiEnumDeviceInterfaces       :: proc(DeviceInfoSet: HDEVINFO, DeviceInfoData: PSP_DEVINFO_DATA, GUID: ^GUID, MemberIndex: DWORD, DeviceInterfaceData: PSP_DEVICE_INTERFACE_DATA) -> BOOL ---
	SetupDiGetDeviceInterfaceDetailW  :: proc(DeviceInfoSet: HDEVINFO, DeviceInterfaceData: PSP_DEVICE_INTERFACE_DATA, DeviceInterfaceDetailData: PSP_DEVICE_INTERFACE_DETAIL_DATA_W, DeviceInterfaceDetailDataSize: DWORD, RequiredSize: PDWORD, DeviceInfoData: PSP_DEVINFO_DATA) -> BOOL ---
	SetupDiEnumDeviceInfo             :: proc(DeviceInfoSet: HDEVINFO, MemberIndex: DWORD, DeviceInfoData: PSP_DEVINFO_DATA) -> BOOL ---
	SetupDiGetDeviceRegistryPropertyW :: proc(DeviceInfoSet: HDEVINFO, DeviceInfoData: PSP_DEVINFO_DATA, Property: DWORD, PropertyRegDataType: PDWORD, PropertyBuffer: PBYTE, PropertyBufferSize: DWORD, RequiredSize: PDWORD) -> BOOL ---
}
