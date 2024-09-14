#+build windows
package sys_windows

foreign import "system:Dnsapi.lib"

@(default_calling_convention="system")
foreign Dnsapi {
    DnsQuery_UTF8 :: proc(name: cstring, type: u16, options: DWORD, extra: PVOID, results: ^^DNS_RECORD, reserved: PVOID) -> DNS_STATUS ---
    DnsRecordListFree :: proc(list: ^DNS_RECORD, options: DWORD) ---
}
