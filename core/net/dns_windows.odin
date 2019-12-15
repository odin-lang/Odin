package net

import "core:strings"
import "core:mem"

import "core:sys/win32"


// Resolves a hostname to exactly one IPv4 and IPv6 address.
// It's then up to you which one you use.
//
// Note that which one you pass to `dial` determines the family of the socket.
// Note also that this procedure _only_ returns ok=false if something went _wrong_.
resolve :: proc(hostname: string, addr_types: bit_set[Addr_Type] = {.Ipv4, .Ipv6}) -> (ipv4, ipv6: Address, ok: bool) {
	if addr := parse_addr(hostname); addr != nil {
		switch a in addr {
		case Ipv4_Address: ipv4 = addr;
		case Ipv6_Address: ipv6 = addr;
		case: assert(false);
		}
		ok = true;
		return;
	}

	if .Ipv4 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .Ipv4);
		if !rec_ok do return;
		if len(recs) > 0 {
			ipv4 = recs[0].(Dns_Record_Ipv4).addr;
		}
	}

	if .Ipv6 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .Ipv6);
		if !rec_ok do return;
		if len(recs) > 0 {
			ipv6 = recs[0].(Dns_Record_Ipv6).addr;
		}
	}

	ok = true;
	return;
}



Dns_Record_Type :: enum u16 {
    Ipv4 = win32.DNS_TYPE_A,    // Ipv4 address.
    Ipv6 = win32.DNS_TYPE_AAAA, // Ipv6 address.
    Cname = win32.DNS_TYPE_CNAME, // Another host name.
    Txt = win32.DNS_TYPE_TEXT,  // Arbitrary binary data or text.
}

Dns_Record_Ipv4 :: struct {
	addr: Ipv4_Address,
}

Dns_Record_Ipv6 :: struct {
	addr: Ipv6_Address,
}

Dns_Record_Cname :: struct {
	hostname: string,
}

Dns_Record_Text :: struct {
	text: string,
}

Dns_Record :: union {
	Dns_Record_Ipv4,
	Dns_Record_Ipv6,
	Dns_Record_Cname,
	Dns_Record_Text,
}

// Performs a recursive DNS query for records of a particular type for the hostname.
//
// This procedure instructs the DNS resolver to recursively perform requests on our behalf,
// meaning that DNS queries for a hostname will resolve through CNAME records.
//
// Returns records in temporary storage.
get_dns_records :: proc(hostname: string, type: Dns_Record_Type, allocator := context.temp_allocator) -> (records: []Dns_Record, ok: bool) {
	context.allocator = allocator;

	host_cstr := strings.clone_to_cstring(hostname);
	assert(host_cstr != nil);

	rec: ^win32.Dns_Record;
	res := win32.DnsQuery_UTF8(host_cstr, u16(type), 0, nil, &rec, nil);
	if res == win32.DNS_INFO_NO_RECORDS || res == 123 {
		// NOTE(tetra): ERROR_INVALID_NAME is returned if there are no such CNAME or TXT records???
		ok = true;
		return;
	}
	if res != 0 do return;
	defer win32.DnsRecordListFree(rec, 1); // 1 means that we're freeing a list... because the proc name isn't enough.

	count := 0;
	for r := rec; r != nil; r = r.next {
		if r.type != u16(type) do continue; // NOTE(tetra): Should never happen, but...
		count += 1;
	}

	//
	// BUG: make(x,0,count) doesn't work here...
	//
	recs := make([dynamic]Dns_Record);
	reserve(&recs, count);

	for r := rec; r != nil; r = r.next {
		if r.type != u16(type) do continue; // NOTE(tetra): Should never happen, but...
		switch Dns_Record_Type(r.type) {
		case .Ipv4:
			addr := Ipv4_Address(transmute([4]u8) r.data.ip_address);
			append(&recs, Dns_Record_Ipv4 { addr = addr });
		case .Ipv6:
			addr := Ipv6_Address(transmute([8]u16be) r.data.ip6_address);
			append(&recs, Dns_Record_Ipv6 { addr = addr });
		case .Cname:
			host := string(r.data.cname);
			append(&recs, Dns_Record_Cname { hostname = strings.clone(host) });
		case .Txt:
			n := r.data.text.string_count;
			ptr := &r.data.text.string_array;
			c_strs := mem.slice_ptr(ptr, int(n));
			for cstr in c_strs {
				s := string(cstr);
				append(&recs, Dns_Record_Text { text = strings.clone(s) });
			}
		}
	}

	records = recs[:];
	ok = true;
	return;
}