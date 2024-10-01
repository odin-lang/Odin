#+build windows
package sys_windows
import "core:c"

HIDD_CONFIGURATION :: struct {
	cookie: PVOID,
	size: ULONG,
	RingBufferSize: ULONG,
}
PHIDD_CONFIGURATION :: ^HIDD_CONFIGURATION

HIDD_ATTRIBUTES :: struct {
	Size: ULONG,
	VendorID: USHORT,
	ProductID: USHORT,
	VersionNumber: USHORT,
}
PHIDD_ATTRIBUTES :: ^HIDD_ATTRIBUTES

HIDP_CAPS :: struct {
	Usage: USAGE,
	UsagePage: USAGE,
	InputReportByteLength: USHORT,
	OutputReportByteLength: USHORT,
	FeatureReportByteLength: USHORT,
	Reserved: [17]USHORT,
	NumberLinkCollectionNodes: USHORT,
	NumberInputButtonCaps: USHORT,
	NumberInputValueCaps: USHORT,
	NumberInputDataIndices: USHORT,
	NumberOutputButtonCaps: USHORT,
	NumberOutputValueCaps: USHORT,
	NumberOutputDataIndices: USHORT,
	NumberFeatureButtonCaps: USHORT,
	NumberFeatureValueCaps: USHORT,
	NumberFeatureDataIndices: USHORT,
}
PHIDP_CAPS :: ^HIDP_CAPS

HIDP_BUTTON_CAPS :: struct {
	UsagePage: USAGE,
	ReportID: UCHAR,
	IsAlias: BOOLEAN,
	BitField: USHORT,
	LinkCollection: USHORT,
	LinkUsage: USAGE,
	LinkUsagePage: USAGE,
	IsRange: BOOLEAN,
	IsStringRange: BOOLEAN,
	IsDesignatorRange: BOOLEAN,
	IsAbsolute: BOOLEAN,
	ReportCount: USHORT,
	Reserved2: USHORT,
	Reserved: [9]ULONG,
	using _: struct #raw_union {
		Range: struct {
			UsageMin: USAGE,
			UsageMax: USAGE,
			StringMin: USHORT,
			StringMax: USHORT,
			DesignatorMin: USHORT,
			DesignatorMax: USHORT,
			DataIndexMin: USHORT,
			DataIndexMax: USHORT,
		},
		NotRange: struct {
			Usage: USAGE,
			Reserved1: USAGE,
			StringIndex: USHORT,
			Reserved2: USHORT,
			DesignatorIndex: USHORT,
			Reserved3: USHORT,
			DataIndex: USHORT,
			Reserved4: USHORT,
		},
	},
}
PHIDP_BUTTON_CAPS :: ^HIDP_BUTTON_CAPS

HIDP_VALUE_CAPS :: struct {
	UsagePage: USAGE,
	ReportID: UCHAR,
	IsAlias: BOOLEAN,
	BitField: USHORT,
	LinkCollection: USHORT,
	LinkUsage: USAGE,
	LinkUsagePage: USAGE,
	IsRange: BOOLEAN,
	IsStringRange: BOOLEAN,
	IsDesignatorRange: BOOLEAN,
	IsAbsolute: BOOLEAN,
	HasNull: BOOLEAN,
	Reserved: UCHAR,
	BitSize: USHORT,
	ReportCount: USHORT,
	Reserved2: [5]USHORT,
	UnitsExp: ULONG,
	Units: ULONG,
	LogicalMin: LONG,
	LogicalMax: LONG,
	PhysicalMin: LONG,
	PhysicalMax: LONG,
	using _: struct #raw_union {
		Range: struct {
			UsageMin: USAGE,
			UsageMax: USAGE,
			StringMin: USHORT,
			StringMax: USHORT,
			DesignatorMin: USHORT,
			DesignatorMax: USHORT,
			DataIndexMin: USHORT,
			DataIndexMax: USHORT,
		},
		NotRange: struct {
			Usage: USAGE,
			Reserved1: USAGE,
			StringIndex: USHORT,
			Reserved2: USHORT,
			DesignatorIndex: USHORT,
			Reserved3: USHORT,
			DataIndex: USHORT,
			Reserved4: USHORT,
		},
	},
}
PHIDP_VALUE_CAPS :: ^HIDP_VALUE_CAPS

HIDP_DATA :: struct {
	DataIndex: USHORT,
	Reserved: USHORT,
	using _ : struct #raw_union {
		RawValue: ULONG,
		On: BOOLEAN,
	},
}
PHIDP_DATA :: ^HIDP_DATA

HIDP_LINK_COLLECTION_NODE :: struct {
	LinkUsage: USAGE,
	LinkUsagePage: USAGE,
	Parent: USHORT,
	NumberOfChildren: USHORT,
	NextSibling: USHORT,
	FirstChild: USHORT,
	CollectionType: [8]ULONG,
	IsAlias: [1]ULONG,
	Reserved: [23]ULONG,
	UserContext: PVOID,
}
PHIDP_LINK_COLLECTION_NODE :: ^HIDP_LINK_COLLECTION_NODE

HIDP_PREPARSED_DATA :: rawptr
PHIDP_PREPARSED_DATA :: ^HIDP_PREPARSED_DATA

HIDP_REPORT_TYPE :: enum c.int {
	Input,
	Output,
	Feature,
}

HIDP_STATUS_SUCCESS : NTSTATUS : 0x110000
HIDP_STATUS_NULL : NTSTATUS : -2146369535  //0x80110001
HIDP_STATUS_INVALID_PREPARSED_DATA : NTSTATUS : -1072627711 //0xC0110001
HIDP_STATUS_INVALID_REPORT_TYPE : NTSTATUS : -1072627710 //0xC0110002
HIDP_STATUS_INVALID_REPORT_LENGTH : NTSTATUS : -1072627709 //0xC0110003
HIDP_STATUS_USAGE_NOT_FOUND : NTSTATUS : -1072627708 //0xC0110004
HIDP_STATUS_VALUE_OUT_OF_RANGE : NTSTATUS : -1072627707 //0xC0110005
HIDP_STATUS_BAD_LOG_PHY_VALUES : NTSTATUS : -1072627706 //0xC0100006
HIDP_STATUS_BUFFER_TOO_SMALL : NTSTATUS : -1072627705 //0xC0110007
HIDP_STATUS_INTERNAL_ERROR : NTSTATUS : -1072627704 //0xC0110008
HIDP_STATUS_I8042_TRANS_UNKNOWN : NTSTATUS : -1072627703 //0xC0110009
HIDP_STATUS_INCOMPATIBLE_REPORT_ID : NTSTATUS : -1072627702 //0xC011000A
HIDP_STATUS_NOT_VALUE_ARRAY : NTSTATUS : -1072627701 //0xC011000B
HIDP_STATUS_IS_VALUE_ARRAY : NTSTATUS : -1072627700 //0xC011000C
HIDP_STATUS_DATA_INDEX_NOT_FOUND : NTSTATUS : -1072627699 //0xC011000D
HIDP_STATUS_DATA_INDEX_OUT_OF_RANGE : NTSTATUS : -1072627698 //0xC011000E
HIDP_STATUS_BUTTON_NOT_PRESSED : NTSTATUS : -1072627697 //0xC011000F
HIDP_STATUS_REPORT_DOES_NOT_EXIST : NTSTATUS : -1072627696 //0xC0110010
HIDP_STATUS_NOT_IMPLEMENTED : NTSTATUS : -1072627680 //0xC0110020
HIDP_STATUS_NOT_BUTTON_ARRAY : NTSTATUS : -1072627679 //0xC0110021
HIDP_STATUS_I8242_TRANS_UNKNOWN :: HIDP_STATUS_I8042_TRANS_UNKNOWN

foreign import hid "system:hid.lib"
@(default_calling_convention="system")
foreign hid {
	HidP_GetCaps :: proc(PreparsedData: PHIDP_PREPARSED_DATA, Capabilities: PHIDP_CAPS) -> NTSTATUS ---
	HidP_GetButtonCaps :: proc(ReportType: HIDP_REPORT_TYPE, ButtonCaps: PHIDP_BUTTON_CAPS, ButtonCapsLength: PUSHORT, PreparsedData: PHIDP_PREPARSED_DATA) -> NTSTATUS ---
	HidP_GetValueCaps :: proc(ReportType: HIDP_REPORT_TYPE, ValueCaps: PHIDP_VALUE_CAPS, ValueCapsLength: PUSHORT, PreparsedData: PHIDP_PREPARSED_DATA) -> NTSTATUS ---
	HidP_GetUsages :: proc(ReportType: HIDP_REPORT_TYPE, UsagePage: USAGE, LinkCollection: USHORT, UsageList: PUSAGE, UsageLength: PULONG, PreparsedData: PHIDP_PREPARSED_DATA, Report: PCHAR, ReportLength: ULONG) -> NTSTATUS ---
	HidP_GetUsageValue :: proc(ReportType: HIDP_REPORT_TYPE, UsagePage: USAGE, LinkCollection: USHORT, Usage: USAGE, UsageValue: PULONG, PreparsedData: PHIDP_PREPARSED_DATA, Report: PCHAR, ReportLength: ULONG) -> NTSTATUS ---
	HidP_GetData :: proc(ReportType: HIDP_REPORT_TYPE, DataList: PHIDP_DATA, DataLength: PULONG, PreparsedData: PHIDP_PREPARSED_DATA, Report: PCHAR, ReportLength: ULONG) -> NTSTATUS ---
	HidP_GetLinkCollectionNodes :: proc(LinkCollectionNodes: PHIDP_LINK_COLLECTION_NODE, LinkCollectionNodesLength: PULONG, PreparsedData: PHIDP_PREPARSED_DATA) -> NTSTATUS ---

	HidD_GetAttributes :: proc(HidDeviceObject: HANDLE, Attributes: PHIDD_ATTRIBUTES) -> BOOLEAN ---
	HidD_GetHidGuid :: proc(HidGuid: LPGUID) ---
	HidD_GetPreparsedData :: proc(HidDeviceObject: HANDLE, PreparsedData: ^PHIDP_PREPARSED_DATA) -> BOOLEAN ---
	HidD_FreePreparsedData :: proc(PreparsedData: PHIDP_PREPARSED_DATA) -> BOOLEAN ---
	HidD_FlushQueue :: proc(HidDeviceObject: HANDLE) -> BOOLEAN ---
	HidD_GetConfiguration :: proc(HidDeviceObject: HANDLE, Configuration: PHIDD_CONFIGURATION, ConfigurationLength: ULONG) -> BOOLEAN ---
	HidD_SetConfiguration :: proc(HidDeviceObject: HANDLE, Configuration: PHIDD_CONFIGURATION, ConfigurationLength: ULONG) -> BOOLEAN ---
	HidD_GetFeature :: proc(HidDeviceObject: HANDLE, ReportBuffer: PVOID, ReportBufferLength: ULONG) -> BOOLEAN ---
	HidD_SetFeature :: proc(HidDeviceObject: HANDLE, ReportBuffer: PVOID, ReportBufferLength: ULONG) -> BOOLEAN ---
	HidD_GetInputReport :: proc(HidDeviceObject: HANDLE, ReportBuffer: PVOID, ReportBufferLength: ULONG) -> BOOLEAN ---
	HidD_SetOutputReport :: proc(HidDeviceObject: HANDLE, ReportBuffer: PVOID, ReportBufferLength: ULONG) -> BOOLEAN ---
	HidD_GetNumInputBuffers :: proc(HidDeviceObject: HANDLE, NumberBuffers: PULONG) -> BOOLEAN ---
	HidD_SetNumInputBuffers :: proc(HidDeviceObject: HANDLE, NumberBuffers: ULONG) -> BOOLEAN ---
	HidD_GetPhysicalDescriptor :: proc(HidDeviceObject: HANDLE, Buffer: PVOID, BufferLength: ULONG) -> BOOLEAN ---
	HidD_GetManufacturerString :: proc(HidDeviceObject: HANDLE, Buffer: PVOID, BufferLength: ULONG) -> BOOLEAN ---
	HidD_GetProductString :: proc(HidDeviceObject: HANDLE, Buffer: PVOID, BufferLength: ULONG) -> BOOLEAN ---
	HidD_GetIndexedString :: proc(HidDeviceObject: HANDLE, StringIndex: ULONG, Buffer: PVOID, BufferLength: ULONG) -> BOOLEAN ---
	HidD_GetSerialNumberString :: proc(HidDeviceObject: HANDLE, Buffer: PVOID, BufferLength: ULONG) -> BOOLEAN ---
	HidD_GetMsGenreDescriptor :: proc(HidDeviceObject: HANDLE, Buffer: PVOID, BufferLength: ULONG) -> BOOLEAN ---
}
