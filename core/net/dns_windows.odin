package net

import "core:strings"
import "core:mem"

import win "core:sys/windows"

// Performs a recursive DNS query for records of a particular type for the hostname.
//
// NOTE: This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
// meaning that DNS queries for a hostname will resolve through CNAME records until an
// IP address is reached.
//
// WARNING: This procedure allocates memory for each record returned; deleting just the returned slice is not enough!
// See `destroy_records`.
get_dns_records :: proc(hostname: string, type: Dns_Record_Type, allocator := context.allocator) -> (records: []Dns_Record, ok: bool) {
	context.allocator = allocator

	host_cstr := strings.clone_to_cstring(hostname, context.temp_allocator)
	rec: ^win.DNS_RECORD
	res := win.DnsQuery_UTF8(host_cstr, u16(type), 0, nil, &rec, nil)
	switch u32(res) {
	case 0:
		// okay
	case win.ERROR_INVALID_NAME:
		return
	case win.DNS_INFO_NO_RECORDS:
		ok = true
		return
	case:
		return
	}
	defer win.DnsRecordListFree(rec, 1) // 1 means that we're freeing a list... because the proc name isn't enough.

	count := 0
	for r := rec; r != nil; r = r.pNext {
		if r.wType != u16(type) do continue // NOTE(tetra): Should never happen, but...
		count += 1
	}


	recs := make([dynamic]Dns_Record, 0, count)
	if recs == nil do return // return no results if OOM.

	for r := rec; r != nil; r = r.pNext {
		if r.wType != u16(type) do continue // NOTE(tetra): Should never happen, but...

		switch Dns_Record_Type(r.wType) {
		case .Ipv4:
			addr := Ipv4_Address(transmute([4]u8) r.Data.A)
			new_rec := Dns_Record_Ipv4(addr) // NOTE(tetra): value copy
			append(&recs, new_rec)

		case .Ipv6:
			addr := Ipv6_Address(transmute([8]u16be) r.Data.AAAA)
			new_rec := Dns_Record_Ipv6(addr) // NOTE(tetra): value copy
			append(&recs, new_rec)

		case .Cname:
			host := string(r.Data.CNAME)
			new_rec := Dns_Record_Cname(strings.clone(host))
			append(&recs, new_rec)

		case .Txt:
			n := r.Data.TXT.dwStringCount
			ptr := &r.Data.TXT.pStringArray
			c_strs := mem.slice_ptr(ptr, int(n))
			for cstr in c_strs {
				s := string(cstr)
				new_rec := Dns_Record_Text(strings.clone(s))
				append(&recs, new_rec)
			}

		case .Ns:
			host := string(r.Data.NS)
			new_rec := Dns_Record_Ns(strings.clone(host))
			append(&recs, new_rec)

		case .Mx:
			// TODO(tetra): Order by preference priority? (Prefer hosts with lower preference values.)
			// Or maybe not because you're supposed to just use the first one that works
			// and which order they're in changes every few calls.
			host := string(r.Data.MX.pNameExchange)
			preference := int(r.Data.MX.wPreference)
			new_rec := Dns_Record_Mx {
				host       = strings.clone(host),
				preference = preference }
			append(&recs, new_rec)

		case .Srv:
			name := strings.clone(string(r.Data.SRV.pNameTarget))
			priority := int(r.Data.SRV.wPriority)
			weight := int(r.Data.SRV.wWeight)
			port := int(r.Data.SRV.wPort)

			parts := strings.split(name, ".", context.temp_allocator)
			defer delete(parts)
			assert(len(parts) == 3, "Srv record name should be of the form _servicename._protocol.domain")
			service_name, protocol, host := parts[0], parts[1], parts[2]

			if service_name[0] == '_' {
				service_name = service_name[1:]
			}
			if protocol[0] == '_' {
				protocol = protocol[1:]
			}

			append(&recs, Dns_Record_Srv {
				service_name = service_name,
				protocol     = protocol,
				host         = host,
				priority     = priority,
				weight       = weight,
				port         = port,
			})
		}
	}

	records = recs[:]
	ok = true
	return
}

// `records` slice is also destroyed.
destroy_dns_records :: proc(records: []Dns_Record, allocator := context.allocator) {
	context.allocator = allocator

	for rec in records {
		switch r in rec {
		case Dns_Record_Ipv4:  // nothing to do
		case Dns_Record_Ipv6:  // nothing to do
		case Dns_Record_Cname:
			delete(string(r))
		case Dns_Record_Text:
			delete(string(r))
		case Dns_Record_Ns:
			delete(string(r))
		case Dns_Record_Mx:
			delete(r.host)
		case Dns_Record_Srv:
			delete(r.service_name) // NOTE(tetra): the three strings are substrings; the service name is the start of that string.
		}
	}

	delete(records)
}
