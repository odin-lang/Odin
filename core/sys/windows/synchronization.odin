package sys_windows

foreign import Synchronization "system:Synchronization.lib"

@(default_calling_convention="c")
foreign Synchronization {
	WaitOnAddress :: proc(Address: PVOID, CompareAddress: PVOID, AddressSize: SIZE_T, dwMilliseconds: DWORD) -> BOOL ---
	WakeByAddressSingle :: proc(Address: PVOID) ---
	WakeByAddressAll :: proc(Address: PVOID) ---
}
