package win32

foreign import "system:Dnsapi.lib"

Dns_Status :: u32; // zero is success

DNS_TYPE_A    :: 0x1;
DNS_TYPE_CNAME :: 0x5;
DNS_TYPE_AAAA :: 0x1c;
DNS_TYPE_TEXT :: 0x10;

DNS_INFO_NO_RECORDS :: 9501;
DNS_QUERY_NO_RECURSION :: 0x00000004;

@(default_calling_convention="std")
foreign Dnsapi {
    DnsQuery_UTF8 :: proc(name: cstring, type: u16, options: u32, extra: rawptr, results: ^^Dns_Record, reserved: rawptr) -> Dns_Status ---;
    DnsRecordListFree :: proc(list: ^Dns_Record, options: u32) ---;
}

Dns_Record :: struct {
    next: ^Dns_Record,
    name: cstring,
    type: u16,
    data_length: u16,
    flags: u32,
    ttl: u32,
    _: u32,
    data: struct #raw_union {
        cname: cstring,
        ip_address: u32be,
        ip6_address: u128be,
        text: struct {
            string_count: u32,
            string_array: cstring,
        },
    }
}