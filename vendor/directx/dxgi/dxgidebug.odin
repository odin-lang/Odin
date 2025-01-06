package directx_dxgi

import win32 "core:sys/windows"
import "core:c"

DEBUG_RLO_FLAGS :: enum u32 { // TODO: convert to bit_set
	SUMMARY	        = 0x1,
	DETAIL	        = 0x2,
	IGNORE_INTERNAL	= 0x4,
	ALL	            = 0x7,
}

UINT :: win32.UINT
INT :: win32.INT
UINT64 :: win32.UINT64
LPCSTR :: win32.LPCSTR
DEBUG_ID :: win32.GUID
INFO_QUEUE_MESSAGE_ID :: i32

DEBUG_ALL  := DEBUG_ID{0xe48ae283, 0xda80, 0x490b, {0x87, 0xe6, 0x43, 0xe9, 0xa9, 0xcf, 0xda, 0x8}}
DEBUG_DX   := DEBUG_ID{0x35cdd7fc, 0x13b2, 0x421d, {0xa5, 0xd7, 0x7e, 0x44, 0x51, 0x28, 0x7d, 0x64}}
DEBUG_DXGI := DEBUG_ID{0x25cddaa4, 0xb1c6, 0x47e1, {0xac, 0x3e, 0x98, 0x87, 0x5b, 0x5a, 0x2e, 0x2a}}
DEBUG_APP  := DEBUG_ID{0x6cd6e01, 0x4219, 0x4ebd, {0x87, 0x9, 0x27, 0xed, 0x23, 0x36, 0xc, 0x62}}

INFO_QUEUE_MESSAGE_CATEGORY :: enum u32 {
	UNKNOWN                 = 0,
	MISCELLANEOUS	        = UNKNOWN + 1,
	INITIALIZATION	        = MISCELLANEOUS + 1,
	CLEANUP                 = INITIALIZATION + 1,
	COMPILATION	            = CLEANUP + 1,
	STATE_CREATION          = COMPILATION + 1,
	STATE_SETTING           = STATE_CREATION + 1,
	STATE_GETTING           = STATE_SETTING + 1,
	RESOURCE_MANIPULATION	= STATE_GETTING + 1,
	EXECUTION               = RESOURCE_MANIPULATION + 1,
	SHADER                  = EXECUTION + 1,
}

INFO_QUEUE_MESSAGE_SEVERITY :: enum u32 {
	CORRUPTION = 0,
	ERROR      = CORRUPTION + 1,
	WARNING    = ERROR + 1,
	INFO       = WARNING + 1,
	MESSAGE    = INFO + 1,
}

INFO_QUEUE_MESSAGE :: struct {
	Producer:              DEBUG_ID,
	Category:              INFO_QUEUE_MESSAGE_CATEGORY,
	Severity:              INFO_QUEUE_MESSAGE_SEVERITY,
	ID:                    INFO_QUEUE_MESSAGE_ID,
	pDescription:          [^]c.char,
	DescriptionByteLength: SIZE_T,
}

INFO_QUEUE_FILTER_DESC :: struct {
	NumCategories: UINT,
	pCategoryList: [^]INFO_QUEUE_MESSAGE_CATEGORY,
	NumSeverities: UINT,
	pSeverityList: [^]INFO_QUEUE_MESSAGE_SEVERITY,
	NumIDs:        UINT,
	pIDList:       [^]INFO_QUEUE_MESSAGE_ID,
}

INFO_QUEUE_FILTER :: struct {
	AllowList: INFO_QUEUE_FILTER_DESC,
	DenyList:  INFO_QUEUE_FILTER_DESC,
}

INFO_QUEUE_DEFAULT_MESSAGE_COUNT_LIMIT :: 1024


IInfoQueue_UUID_STRING :: "D67441C7-672A-476f-9E82-CD55B44949CE"
IInfoQueue_UUID := &IID{0xD67441C7, 0x672A, 0x476f, {0x9E, 0x82, 0xCD, 0x55, 0xB4, 0x49, 0x49, 0xCE}}
IInfoQueue :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxgiinfoqueue_vtable: ^IInfoQueue_VTable,
}
IInfoQueue_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetMessageCountLimit:                          proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, MessageCountLimit: UINT64) -> HRESULT,
	ClearStoredMessages:                           proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID),
	GetMessage:                                    proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, MessageIndex: UINT64, pMessage: ^INFO_QUEUE_MESSAGE, pMessageByteLength: ^SIZE_T) -> HRESULT,
	GetNumStoredMessagesAllowedByRetrievalFilters: proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT64,
	GetNumStoredMessages:                          proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT64,
	GetNumMessagesDiscardedByMessageCountLimit:    proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT64,
	GetMessageCountLimit:                          proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT64,
	GetNumMessagesAllowedByStorageFilter:          proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT64,
	GetNumMessagesDeniedByStorageFilter:           proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT64,
	AddStorageFilterEntries:                       proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, pFilter: INFO_QUEUE_FILTER) -> HRESULT,
	GetStorageFilter:                              proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, pFilter: ^INFO_QUEUE_FILTER, pFilterByteLength: ^SIZE_T) -> HRESULT,
	ClearStorageFilter:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID),
	PushEmptyStorageFilter:                        proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> HRESULT,
	PushDenyAllStorageFilter:                      proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> HRESULT,
	PushCopyOfStorageFilter:                       proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> HRESULT,
	PushStorageFilter:                             proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	PopStorageFilter:                              proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID),
	GetStorageFilterStackSize:                     proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT,
	AddRetrievalFilterEntries:                     proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	GetRetrievalFilter:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, pFilter: ^INFO_QUEUE_FILTER, pFilterByteLength: ^SIZE_T) -> HRESULT,
	ClearRetrievalFilter:                          proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID),
	PushEmptyRetrievalFilter:                      proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> HRESULT,
	PushDenyAllRetrievalFilter:                    proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> HRESULT,
	PushCopyOfRetrievalFilter:                     proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> HRESULT,
	PushRetrievalFilter:                           proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	PopRetrievalFilter:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID),
	GetRetrievalFilterStackSize:                   proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> UINT,
	AddMessage:                                    proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, Category: INFO_QUEUE_MESSAGE_CATEGORY, Severity: INFO_QUEUE_MESSAGE_SEVERITY, ID: INFO_QUEUE_MESSAGE_ID, pDescription: LPCSTR) -> HRESULT,
	AddApplicationMessage:                         proc "system" (this: ^IInfoQueue, Severity: INFO_QUEUE_MESSAGE_SEVERITY, pDescription: LPCSTR) -> HRESULT,
	SetBreakOnCategory:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, Category: INFO_QUEUE_MESSAGE_CATEGORY, bEnable: BOOL) -> HRESULT,
	SetBreakOnSeverity:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, Severity: INFO_QUEUE_MESSAGE_SEVERITY, bEnable: BOOL) -> HRESULT,
	SetBreakOnID:                                  proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, ID: INFO_QUEUE_MESSAGE_ID, bEnable: BOOL) -> HRESULT,
	GetBreakOnCategory:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, Category: INFO_QUEUE_MESSAGE_CATEGORY) -> BOOL,
	GetBreakOnSeverity:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, Severity: INFO_QUEUE_MESSAGE_SEVERITY) -> BOOL,
	GetBreakOnID:                                  proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, ID: INFO_QUEUE_MESSAGE_ID) -> BOOL,
	SetMuteDebugOutput:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID, bMute: BOOL),
	GetMuteDebugOutput:                            proc "system" (this: ^IInfoQueue, Producer: DEBUG_ID) -> BOOL,
}

IDebug_UUID_STRING :: "119E7452-DE9E-40fe-8806-88F90C12B441"
IDebug_UUID := &IID{0x119E7452, 0xDE9E, 0x40fe, {0x88, 0x06, 0x88, 0xF9, 0x0C, 0x12, 0xB4, 0x41}}
IDebug :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxgidebug_vtable: ^IDebug_VTable,
}
IDebug_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	ReportLiveObjects: proc "system" (this: ^IDebug, apiid: GUID, flags: DEBUG_RLO_FLAGS),
}

IDebug1_UUID_STRING :: "c5a05f0c-16f2-4adf-9f4d-a8c4d58ac550"
IDebug1_UUID := &IID{0xc5a05f0c, 0x16f2, 0x4adf, {0x9f, 0x4d, 0xa8, 0xc4, 0xd5, 0x8a, 0xc5, 0x50}}
IDebug1 :: struct #raw_union {
	#subtype idxgidebug: IDebug,
	using idxgidebug1_vtable: ^IDebug1_VTable,
}
IDebug1_VTable :: struct {
	using idxgidebug_vtable: IDebug_VTable,
	EnableLeakTrackingForThread:    proc "system" (this: ^IDebug1),
	DisableLeakTrackingForThread:   proc "system" (this: ^IDebug1),
	IsLeakTrackingEnabledForThread: proc "system" (this: ^IDebug1) -> BOOL,
}
