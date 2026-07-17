// Windows Audio Session API Bindings Package
package wasapi

import "core:sys/windows"


KSDATAFORMAT_SUBTYPE_IEEE_FLOAT_STRING :: "00000003-0000-0010-8000-00aa00389b71"
KSDATAFORMAT_SUBTYPE_IEEE_FLOAT := windows.GUID{0x00000003, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}}

// MARK: IMMDeviceEnumerator

CLSID_MMDeviceEnumerator_STRING :: "BCDE0395-E52F-467C-8E3D-C4579291692E"
CLSID_MMDeviceEnumerator := &windows.IID{0xBCDE0395, 0xE52F, 0x467C, {0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E}}

IID_IMMDeviceEnumerator_STRING :: "A95664D2-9614-4F35-A746-DE8DB63617E6"
IID_IMMDeviceEnumerator := &windows.IID{0xA95664D2, 0x9614, 0x4F35, {0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6}}

IID_IAudioClient_STRING :: "1CB9AD4C-DBFA-4c32-B178-C2F568A703B2"
IID_IAudioClient := &windows.IID{0x1CB9AD4C, 0xDBFA, 0x4c32, {0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2}}

IID_IAudioRenderClient_STRING :: "F294ACFC-3146-4483-A7BF-ADDCA7C260E2"
IID_IAudioRenderClient := &windows.IID{0xF294ACFC, 0x3146, 0x4483, {0xA7, 0xBF, 0xAD, 0xDC, 0xA7, 0xC2, 0x60, 0xE2}}


IMMDeviceEnumerator :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using immdeviceenumerator_vtable: ^IMMDeviceEnumerator_VTable,
}

IMMDeviceEnumerator_VTable :: struct {
	using iunknown_vtable:  windows.IUnknown_VTable,

	EnumAudioEndpoints: proc "system" (
		This: ^IMMDeviceEnumerator,
		dataFlow: EDataFlow,
		dwStateMask: windows.DWORD,
		ppDevices: [^]IMMDeviceCollection, // Out
	) -> windows.HRESULT,

	GetDefaultAudioEndpoint: proc "system" (
		This: ^IMMDeviceEnumerator,
		dataFlow: EDataFlow,
		role: ERole,
		ppEndpoint: ^^IMMDevice, // Out
	) -> windows.HRESULT,

	GetDevice: proc "system" (
		This: ^IMMDeviceEnumerator,
		pwstrId: windows.LPCWSTR,
		ppDevice: ^^IMMDevice, // Out
	) -> windows.HRESULT,

	RegisterEndpointNotificationCallback: proc "system" (
		This: ^IMMDeviceEnumerator,
		pClient: ^IMMNotificationClient, // In
	) -> windows.HRESULT,

	UnregisterEndpointNotificationCallback: proc "system" (
		This: ^IMMDeviceEnumerator,
		pClient: ^IMMNotificationClient, // In
	) -> windows.HRESULT,
}



// MARK: IMMDeviceCollection

IMMDeviceCollection :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using immdevicecollection_vtable: ^IMMDeviceCollection_VTable,
}

IMMDeviceCollection_VTable :: struct {
	using iunknown_vtable: windows.IUnknown_VTable,

	GetCount: proc "system" (
		This: ^IMMDeviceCollection,
		pcDevices: ^windows.UINT, // Out
	) -> windows.HRESULT,

	Item: proc "system" (
		This: ^IMMDeviceCollection,
		nDevice: windows.UINT,
		ppDevice: ^^IMMDevice,
	) -> windows.HRESULT,
}

// MARK: IMMDevice

IMMDevice :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using immdevice_vtable: ^IMMDevice_VTable,
}

IMMDevice_VTable :: struct {
	using iunknown_vtable:  windows.IUnknown_VTable,

	Activate: proc "system" (
		This: ^IMMDevice,
		iid: windows.REFIID, // In
		dwClsCtx: windows.DWORD, // In
		pActivationParams: ^rawptr, // In Optional PROPVARIANT
		ppInterface: [^]rawptr, // Out
	) -> windows.HRESULT,

	OpenPropertyStore: proc "system" (
		This: ^IMMDevice,
		stgmAccess: windows.DWORD, // In
		ppProperties: [^]^windows.IPropertyStore, // Out
	) -> windows.HRESULT,

	GetId: proc "system" (
		This: ^IMMDevice,
		ppstrId: ^windows.LPWSTR, // Out
	) -> windows.HRESULT,

	GetState: proc "system" (
		This: ^IMMDevice,
		pdwState: ^windows.DWORD, // Out
	) -> windows.HRESULT,
}



// MARK: IMMNotificationClient

IMMNotificationClient :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using immnotificationclient_vtable: ^IMMNotificationClient_VTable,
}

IMMNotificationClient_VTable :: struct {
	using iunknown_vtable: windows.IUnknown_VTable,

	OnDeviceStateChanged: proc "system" (
		This: ^IMMNotificationClient,
		pwstrDeviceId: windows.LPCWSTR,
		dwNewState: windows.DWORD,
	) -> windows.HRESULT,

	OnDeviceAdded: proc "system" (
		This: ^IMMNotificationClient,
		pwstrDeviceId: windows.LPCWSTR,
	) -> windows.HRESULT,

	OnDeviceRemoved: proc "system" (
		This: ^IMMNotificationClient,
		pwstrDeviceId: windows.LPCWSTR,
	) -> windows.HRESULT,

	OnDefaultDeviceChanged: proc "system" (
		This: ^IMMNotificationClient,
		flow: EDataFlow,
		role: ERole,
		pwstrDefaultDeviceId: windows.LPCWSTR, // Optional
	) -> windows.HRESULT,

	OnPropertyValueChanged: proc "system" (
		This: ^IMMNotificationClient,
		pwstrDeviceId: windows.LPCWSTR,
		key: windows.PROPERTYKEY,
	) -> windows.HRESULT,
}


// MARK: IAudioClient

IAudioClient :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using iaudioclient_vtable: ^IAudioClient_VTable,
}

IAudioClient_VTable :: struct {
	using iunknown_vtable:  windows.IUnknown_VTable,

	Initialize: proc "system" (
		This: ^IAudioClient,
		ShareMode: AUDCLNT_SHAREMODE,
		StreamFlags: windows.DWORD,
		hnsBufferDuration: REFERENCE_TIME,
		hnsPeriodicity: REFERENCE_TIME,
		pFormat: ^WAVEFORMATEX, // Const In
		AudioSessionGuid: windows.LPCGUID, // In Optional
	) -> windows.HRESULT,

	GetBufferSize: proc "system" (
		This: ^IAudioClient,
		pNumBufferFrames: ^u32, // Out
	) -> windows.HRESULT,

	GetStreamLatency: proc "system" (
		This: ^IAudioClient,
		phnsLatency: ^REFERENCE_TIME, // Out
	) -> windows.HRESULT,

	GetCurrentPadding: proc "system" (
		This: ^IAudioClient,
		pNumPaddingFrames: ^u32, // Out
	) -> windows.HRESULT,

	IsFormatSupported: proc "system" (
		This: ^IAudioClient,
		ShareMode: AUDCLNT_SHAREMODE, // In
		pFormat: ^WAVEFORMATEX, // Const In
		ppClosestMatch: ^^WAVEFORMATEX, // Out Optional
	) -> windows.HRESULT,

	GetMixFormat: proc "system" (
		This: ^IAudioClient,
		ppDeviceFormat: ^^WAVEFORMATEX, // Out
	) -> windows.HRESULT,

	GetDevicePeriod: proc "system" (
		This: ^IAudioClient,
		phnsDefaultDevicePeriod: ^REFERENCE_TIME, // Out Optional
		phnsMinimumDevicePeriod: ^REFERENCE_TIME, // Out Optional
	) -> windows.HRESULT,

	Start: proc "system" (This: ^IAudioClient) -> windows.HRESULT,
	Stop: proc "system" (This: ^IAudioClient) -> windows.HRESULT,
	Reset: proc "system" (This: ^IAudioClient) -> windows.HRESULT,

	SetEventHandle: proc "system" (
		This: ^IAudioClient,
		eventHandle: windows.HANDLE,
	) -> windows.HRESULT,

	GetService: proc "system" (
		This: ^IAudioClient,
		riid: windows.REFIID, // In
		ppv: ^rawptr, // Out
	) -> windows.HRESULT,
}



// MARK: IAudioClient2

IAudioClient2 :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using iaudioclient2_vtable: ^IAudioClient2_VTable,
}

IAudioClient2_VTable :: struct {
	using iaudioclient_vtable:  IAudioClient_VTable,

	IsOffloadCapable: proc "system" (
		This: ^IAudioClient2,
		Category: AUDIO_STREAM_CATEGORY,
		pbOffloadCapable: ^windows.BOOL, // Out
	) -> windows.HRESULT,

	SetClientProperties: proc "system" (
		This: ^IAudioClient2,
		pProperties: ^AudioClientProperties, // Const In
	) -> windows.HRESULT,

	GetBufferSizeLimits: proc "system" (
		This: ^IAudioClient2,
		pFormat: ^WAVEFORMATEX, // Const In
		bEventDriven: windows.BOOL,
		phnsMinBufferDuration: ^REFERENCE_TIME, // Out
		phnsMaxBufferDuration: ^REFERENCE_TIME, // Out
	) -> windows.HRESULT,
}



// MARK: IAudioClient3

IAudioClient3 :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using iaudioclient3_vtable: ^IAudioClient3_VTable,
}

IAudioClient3_VTable :: struct {
	using iaudioclient2_vtable: IAudioClient2_VTable,

	GetSharedModeEnginePeriod: proc "system" (
		This: ^IAudioClient3,
		pFormat: ^WAVEFORMATEX, // Const In
		pDefaultPeriodInFrames: ^u32, // Out
		pFundamentalPeriodInFrames: ^u32, // Out
		pMinPeriodInFrames: ^u32, // Out
		pMaxPeriodInFrames: ^u32, // Out
	) -> windows.HRESULT,

	GetCurrentSharedModeEnginePeriod: proc "system" (
		This: ^IAudioClient3,
		ppFormat: ^^WAVEFORMATEX, // Out
		pCurrentPeriodInFrames: ^u32, // Out
	) -> windows.HRESULT,

	InitializeSharedAudioStream: proc "system" (
		This: ^IAudioClient3,
		StreamFlags: windows.DWORD,
		PeriodInFrames: u32,
		pFormat: ^WAVEFORMATEX, // Const In
		AudioSessionGuid: windows.LPCGUID, // In Optional
	) -> windows.HRESULT,
}



// MARK: IAudioRenderClient

IAudioRenderClient :: struct #raw_union {
	#subtype iunknown: windows.IUnknown,
	using iaudiorenderclient_vtable: ^IAudioRenderClient_VTable,
}

IAudioRenderClient_VTable :: struct {
	using iunknown_vtable: windows.IUnknown_VTable,

	GetBuffer: proc "system" (
		This: ^IAudioRenderClient,
		NumFramesRequested: u32,
		ppData: ^[^]byte, // NumFramesRequested * pFormat->nBlockAlign
	) -> windows.HRESULT,

	ReleaseBuffer: proc "system" (
		This: ^IAudioRenderClient,
		NumFramesWritten: u32,
		dwFlags: windows.DWORD,
	) -> windows.HRESULT,
}
