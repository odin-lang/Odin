#+build windows
package sys_windows

@(private = "file")
_ACTIVATION_CONTEXT :: struct {
	// Opaque.
}

TP_WAIT_RESULT :: DWORD // Has value WAIT_OBJECT_0 or WAIT_TIMEOUT.
TP_CALLBACK_PRIORITY :: enum DWORD {
	HIGH,
	NORMAL,
	LOW,
}
TP_SIMPLE_CALLBACK :: struct {
	Instance: PTP_CALLBACK_INSTANCE,
	Context:  PVOID,
}
TP_POOL_STACK_INFORMATION :: struct {
	StackReserve, StackCommit: SIZE_T,
}
TP_VERSION :: DWORD
TP_CALLBACK_ENVIRON_FLAGS :: enum DWORD {
	LongFunction,
	Persistent,
}
#assert(size_of(DWORD) == 4)

// There's multiple versions of this!
// Assume the latest version (aliased to TP_CALLBACK_ENVIRON_V3).
TP_CALLBACK_ENVIRON :: struct {
	Version:                    TP_VERSION,
	Pool:                       PTP_POOL,
	CleanupGroup:               PTP_CLEANUP_GROUP,
	CleanupGroupCancelCallback: PTP_CLEANUP_GROUP_CANCEL_CALLBACK,
	RaceDll:                    PVOID,
	ActivationContext:          ^_ACTIVATION_CONTEXT,
	FinalizationCallback:       PTP_SIMPLE_CALLBACK,
	Flags:                      bit_set[TP_CALLBACK_ENVIRON_FLAGS;DWORD],
	CallbackPriority:           TP_CALLBACK_PRIORITY,
	Size:                       DWORD,
}


PTP_POOL :: distinct rawptr
PTP_POOL_STACK_INFORMATION :: ^TP_POOL_STACK_INFORMATION
PTP_CLEANUP_GROUP :: distinct rawptr
PTP_CALLBACK_INSTANCE :: distinct rawptr
PTP_SIMPLE_CALLBACK :: ^TP_SIMPLE_CALLBACK
PTP_CALLBACK_ENVIRON :: ^TP_CALLBACK_ENVIRON
PTP_WORK :: distinct rawptr
PTP_TIMER :: distinct rawptr
PTP_WAIT :: distinct rawptr
PTP_IO :: distinct rawptr
PTP_WIN32_IO_CALLBACK :: proc "system" (
	Instance: PTP_CALLBACK_INSTANCE,
	Context: PVOID,
	Overlapped: PVOID,
	IoResult: ULONG,
	NumberOfBytesTransferred: ULONG_PTR,
	Io: PTP_IO,
)
PTP_CLEANUP_GROUP_CANCEL_CALLBACK :: proc "system" (ObjectContext: PVOID, CleanupContext: PVOID)
PTP_WAIT_CALLBACK :: proc "system" (
	instance: PTP_CALLBACK_INSTANCE,
	parameter: PVOID,
	wait: PTP_WAIT,
	waitResult: TP_WAIT_RESULT,
)
PTP_TIMER_CALLBACK :: proc "system" (
	instance: PTP_CALLBACK_INSTANCE,
	parameter: PVOID,
	timer: PTP_TIMER,
)
PTP_WORK_CALLBACK :: proc "system" (
	instance: PTP_CALLBACK_INSTANCE,
	parameter: PVOID,
	work: PTP_WORK,
)

PCRITICAL_SECTION :: ^CRITICAL_SECTION
PFILETIME :: ^FILETIME

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention = "system")
foreign kernel32 {
	CreateThreadpool :: proc(reserved: PVOID) -> PTP_POOL ---
	SetThreadpoolThreadMaximum :: proc(ptpp: PTP_POOL, cthrdMost: DWORD) ---
	SetThreadpoolThreadMinimum :: proc(ptpp: PTP_POOL, cthrdMic: DWORD) -> BOOL ---
	SetThreadpoolStackInformation :: proc(ptpp: PTP_POOL, ptpsi: PTP_POOL_STACK_INFORMATION) -> BOOL ---
	QueryThreadpoolStackInformation :: proc(ptpp: PTP_POOL, ptpsi: PTP_POOL_STACK_INFORMATION) -> BOOL ---
	CloseThreadpool :: proc(ptpp: PTP_POOL) ---
	CreateThreadpoolCleanupGroup :: proc() -> PTP_CLEANUP_GROUP ---
	CloseThreadpoolCleanupGroupMembers :: proc(ptpcg: PTP_CLEANUP_GROUP, fCancelPendingCallbacks: BOOL, pvCleanupContext: PVOID) ---
	CloseThreadpoolCleanupGroup :: proc(ptpcg: PTP_CLEANUP_GROUP) ---
	CallbackMayRunLong :: proc(pci: PTP_CALLBACK_INSTANCE) -> BOOL ---
	TrySubmitThreadpoolCallback :: proc(pfns: PTP_SIMPLE_CALLBACK, pv: PVOID, pcbe: PTP_CALLBACK_ENVIRON) -> BOOL ---
	CreateThreadpoolWork :: proc(pfnwk: PTP_WORK_CALLBACK, pv: PVOID, pcbe: PTP_CALLBACK_ENVIRON) -> PTP_WORK ---
	SubmitThreadpoolWork :: proc(pwk: PTP_WORK) ---
	WaitForThreadpoolWorkCallbacks :: proc(pwk: PTP_WORK, fCancelPendingCallbacks: BOOL) ---
	CloseThreadpoolWork :: proc(pwk: PTP_WORK) ---
	CreateThreadpoolTimer :: proc(pfnti: PTP_TIMER_CALLBACK, pv: PVOID, pcbe: PTP_CALLBACK_ENVIRON) -> PTP_TIMER ---
	SetThreadpoolTimer :: proc(pti: PTP_TIMER, pftDueTime: PFILETIME, msPeriod: DWORD, msWindowLength: DWORD) ---
	IsThreadpoolTimerSet :: proc(pti: PTP_TIMER) -> BOOL ---
	WaitForThreadpoolTimerCallbacks :: proc(pti: PTP_TIMER, fCancelPendingCallbacks: BOOL) ---
	CloseThreadpoolTimer :: proc(pti: PTP_TIMER) ---
	CreateThreadpoolWait :: proc(pfnwa: PTP_WAIT_CALLBACK, pv: PVOID, pcbe: PTP_CALLBACK_ENVIRON) -> PTP_WAIT ---
	SetThreadpoolWait :: proc(pwa: PTP_WAIT, h: HANDLE, pftTimeout: PFILETIME) ---
	WaitForThreadpoolWaitCallbacks :: proc(pwa: PTP_WAIT, fCancelPendingCallbacks: BOOL) ---
	CloseThreadpoolWait :: proc(pwa: PTP_WAIT) ---
	CreateThreadpoolIo :: proc(fl: HANDLE, pfnio: PTP_WIN32_IO_CALLBACK, pv: PVOID, pcbe: PTP_CALLBACK_ENVIRON) -> PTP_IO ---
	StartThreadpoolIo :: proc(pio: PTP_IO) ---
	CancelThreadpoolIo :: proc(pio: PTP_IO) ---
	WaitForThreadpoolIoCallbacks :: proc(pio: PTP_IO, fCancelPendingCallbacks: BOOL) ---
	CloseThreadpoolIo :: proc(pio: PTP_IO) ---
	SetThreadpoolTimerEx :: proc(pti: PTP_TIMER, pftDueTime: PFILETIME, msPeriod: DWORD, msWindowLength: DWORD) -> BOOL ---
	SetThreadpoolWaitEx :: proc(pwa: PTP_WAIT, h: HANDLE, pftTimeout: PFILETIME, Reserved: PVOID) -> BOOL ---
	DisassociateCurrentThreadFromCallback :: proc(pci: PTP_CALLBACK_INSTANCE) ---
	FreeLibraryWhenCallbackReturns :: proc(pci: PTP_CALLBACK_INSTANCE, mod: HMODULE) ---
	LeaveCriticalSectionWhenCallbackReturns :: proc(pci: PTP_CALLBACK_INSTANCE, pcs: PCRITICAL_SECTION) ---
	ReleaseMutexWhenCallbackReturns :: proc(pci: PTP_CALLBACK_INSTANCE, mut: HANDLE) ---
	ReleaseSemaphoreWhenCallbackReturns :: proc(pci: PTP_CALLBACK_INSTANCE, sem: HANDLE, crel: DWORD) ---
	SetEventWhenCallbackReturns :: proc(pci: PTP_CALLBACK_INSTANCE, evt: HANDLE) ---
}

TpInitializeCallbackEnviron :: proc(CallbackEnviron: PTP_CALLBACK_ENVIRON) {
	CallbackEnviron.Version = 3
	CallbackEnviron.Pool = nil
	CallbackEnviron.CleanupGroup = nil
	CallbackEnviron.CleanupGroupCancelCallback = nil
	CallbackEnviron.RaceDll = nil
	CallbackEnviron.ActivationContext = nil
	CallbackEnviron.FinalizationCallback = nil
	CallbackEnviron.Flags = {}
	CallbackEnviron.CallbackPriority = .NORMAL
	CallbackEnviron.Size = size_of(TP_CALLBACK_ENVIRON)
}
TpSetCallbackThreadpool :: proc(CallbackEnviron: PTP_CALLBACK_ENVIRON, Pool: PTP_POOL) {
	CallbackEnviron.Pool = Pool
}
TpSetCallbackCleanupGroup :: proc(
	CallbackEnviron: PTP_CALLBACK_ENVIRON,
	CleanupGroup: PTP_CLEANUP_GROUP,
	CleanupGroupCancelCallback: PTP_CLEANUP_GROUP_CANCEL_CALLBACK,
) {
	CallbackEnviron.CleanupGroup = CleanupGroup
	CallbackEnviron.CleanupGroupCancelCallback = CleanupGroupCancelCallback
}
TpSetCallbackActivationContext :: proc(
	CallbackEnviron: PTP_CALLBACK_ENVIRON,
	ActivationContext: ^_ACTIVATION_CONTEXT,
) {
	CallbackEnviron.ActivationContext = ActivationContext
}
TpSetCallbackNoActivationContext :: proc(
	CallbackEnviron: PTP_CALLBACK_ENVIRON,
	ActivationContext: ^_ACTIVATION_CONTEXT,
) {
	CallbackEnviron.ActivationContext = transmute(^_ACTIVATION_CONTEXT)~uintptr(0)
}
TpSetCallbackLongFunction :: proc(CallbackEnviron: PTP_CALLBACK_ENVIRON) {
	CallbackEnviron.Flags |= {.LongFunction}
}
TpSetCallbackRaceWithDll :: proc(CallbackEnviron: PTP_CALLBACK_ENVIRON, DllHandle: PVOID) {
	CallbackEnviron.RaceDll = DllHandle
}
TpSetCallbackFinalizationCallback :: proc(
	CallbackEnviron: PTP_CALLBACK_ENVIRON,
	FinalizationCallback: PTP_SIMPLE_CALLBACK,
) {
	CallbackEnviron.FinalizationCallback = FinalizationCallback
}
TpSetCallbackPriority :: proc(
	CallbackEnviron: PTP_CALLBACK_ENVIRON,
	Priority: TP_CALLBACK_PRIORITY,
) {
	CallbackEnviron.CallbackPriority = Priority
}
TpSetCallbackPersistent :: proc(CallbackEnviron: PTP_CALLBACK_ENVIRON) {
	CallbackEnviron.Flags |= {.Persistent}
}
TpDestroyCallbackEnviron :: proc(CallbackEnviron: PTP_CALLBACK_ENVIRON) {
	//
	// For the current version of the callback environment, no actions
	// need to be taken to tear down an initialized structure.  This
	// may change in a future release.
	//
}

InitializeThreadpoolEnvironment :: proc(pcbe: PTP_CALLBACK_ENVIRON) {
	TpInitializeCallbackEnviron(pcbe)
}
SetThreadpoolCallbackPool :: proc(pcbe: PTP_CALLBACK_ENVIRON, ptpp: PTP_POOL) {
	TpSetCallbackThreadpool(pcbe, ptpp)
}
SetThreadpoolCallbackCleanupGroup :: proc(
	pcbe: PTP_CALLBACK_ENVIRON,
	ptpcg: PTP_CLEANUP_GROUP,
	pfng: PTP_CLEANUP_GROUP_CANCEL_CALLBACK,
) {
	TpSetCallbackCleanupGroup(pcbe, ptpcg, pfng)
}
SetThreadpoolCallbackRunsLong :: proc(pcbe: PTP_CALLBACK_ENVIRON) {
	TpSetCallbackLongFunction(pcbe)
}
SetThreadpoolCallbackLibrary :: proc(pcbe: PTP_CALLBACK_ENVIRON, mod: PVOID) {
	TpSetCallbackRaceWithDll(pcbe, mod)
}
SetThreadpoolCallbackPriority :: proc(pcbe: PTP_CALLBACK_ENVIRON, priority: TP_CALLBACK_PRIORITY) {
	TpSetCallbackPriority(pcbe, priority)
}
DestroyThreadpoolEnvironment :: proc(pcbe: PTP_CALLBACK_ENVIRON) {
	TpDestroyCallbackEnviron(pcbe)
}
