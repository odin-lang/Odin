//+build windows
/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/
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
get_dns_records_windows :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
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


	recs := make([dynamic]DNS_Record, 0, count)
	if recs == nil do return // return no results if OOM.

	for r := rec; r != nil; r = r.pNext {
		if r.wType != u16(type) do continue // NOTE(tetra): Should never happen, but...

		switch DNS_Record_Type(r.wType) {
		case .IPv4:
			addr := IPv4_Address(transmute([4]u8) r.Data.A)
			new_rec := DNS_Record_IPv4(addr) // NOTE(tetra): value copy
			append(&recs, new_rec)

		case .IPv6:
			addr := IPv6_Address(transmute([8]u16be) r.Data.AAAA)
			new_rec := DNS_Record_IPv6(addr) // NOTE(tetra): value copy
			append(&recs, new_rec)

		case .CNAME:
			host := string(r.Data.CNAME)
			new_rec := DNS_Record_CNAME(strings.clone(host))
			append(&recs, new_rec)

		case .TXT:
			n := r.Data.TXT.dwStringCount
			ptr := &r.Data.TXT.pStringArray
			c_strs := mem.slice_ptr(ptr, int(n))
			for cstr in c_strs {
				s := string(cstr)
				new_rec := DNS_Record_Text(strings.clone(s))
				append(&recs, new_rec)
			}

		case .NS:
			host := string(r.Data.NS)
			new_rec := DNS_Record_NS(strings.clone(host))
			append(&recs, new_rec)

		case .MX:
			// TODO(tetra): Order by preference priority? (Prefer hosts with lower preference values.)
			// Or maybe not because you're supposed to just use the first one that works
			// and which order they're in changes every few calls.
			host := string(r.Data.MX.pNameExchange)
			preference := int(r.Data.MX.wPreference)
			new_rec := DNS_Record_MX {
				host_name  = strings.clone(host),
				preference = preference }
			append(&recs, new_rec)

		case .SRV:
			record_name := strings.clone(string(r.pName)) // The name of the record in the DNS entry
			target := strings.clone(string(r.Data.SRV.pNameTarget)) // The target hostname/address that the service can be found on
			priority := int(r.Data.SRV.wPriority)
			weight := int(r.Data.SRV.wWeight)
			port := int(r.Data.SRV.wPort)
			ttl := int(r.dwTtl)

			// NOTE(tetra): Srv record name should be of the form '_servicename._protocol.hostname'
			// The record name is the name of the record.
			// Not to be confused with the _target_ of the record, which is--in combination with the port--what we're looking up
			// by making this request in the first place.
			parts := strings.split_n(record_name, ".", 3, context.temp_allocator)
			if len(parts) != 3 {
				continue
			}
			service_name, protocol_name := parts[0], parts[1]

			append(&recs, DNS_Record_SRV {
				record_name   = record_name,
				target        = target,
				port          = port,
				service_name  = service_name,
				protocol_name = protocol_name,
				priority      = priority,
				weight        = weight,
				ttl_seconds   = ttl,
			})
		}
	}

	records = recs[:]
	ok = true
	return
}
