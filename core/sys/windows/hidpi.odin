// +build windows
package sys_windows
import "core:c"

USAGE :: distinct USHORT
PUSAGE :: ^USAGE

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

PHIDP_PREPARSED_DATA :: rawptr

HIDP_REPORT_TYPE :: enum c.int {
	Input,
	Output,
	Feature,
}

HIDP_STATUS_SUCCESS : NTSTATUS : 0x110000

foreign import hid "system:hid.lib"
@(default_calling_convention="system")
foreign hid {
	HidP_GetCaps :: proc(PreparsedData: PHIDP_PREPARSED_DATA, Capabilities: PHIDP_CAPS) -> NTSTATUS ---
	HidP_GetButtonCaps :: proc(ReportType: HIDP_REPORT_TYPE, ButtonCaps: PHIDP_BUTTON_CAPS, ButtonCapsLength: PUSHORT, PreparsedData: PHIDP_PREPARSED_DATA) -> NTSTATUS ---
	HidP_GetValueCaps :: proc(ReportType: HIDP_REPORT_TYPE, ValueCaps: PHIDP_VALUE_CAPS, ValueCapsLength: PUSHORT, PreparsedData: PHIDP_PREPARSED_DATA) -> NTSTATUS ---
	HidP_GetUsages :: proc(ReportType: HIDP_REPORT_TYPE, UsagePage: USAGE, LinkCollection: USHORT, UsageList: PUSAGE, UsageLength: PULONG, PreparsedData: PHIDP_PREPARSED_DATA, Report: PCHAR, ReportLength: ULONG) -> NTSTATUS ---
	HidP_GetUsageValue :: proc(ReportType: HIDP_REPORT_TYPE, UsagePage: USAGE, LinkCollection: USHORT, Usage: USAGE, UsageValue: PULONG, PreparsedData: PHIDP_PREPARSED_DATA, Report: PCHAR, ReportLength: ULONG) -> NTSTATUS ---
}
