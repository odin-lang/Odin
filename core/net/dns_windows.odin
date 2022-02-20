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
get_dns_records :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
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
				host       = strings.clone(host),
				preference = preference }
			append(&recs, new_rec)

		case .SRV:
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

			append(&recs, DNS_Record_SRV {
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
destroy_dns_records :: proc(records: []DNS_Record, allocator := context.allocator) {
	context.allocator = allocator

	for rec in records {
		switch r in rec {
		case DNS_Record_IPv4:  // nothing to do
		case DNS_Record_IPv6:  // nothing to do
		case DNS_Record_CNAME:
			delete(string(r))
		case DNS_Record_Text:
			delete(string(r))
		case DNS_Record_NS:
			delete(string(r))
		case DNS_Record_MX:
			delete(r.host)
		case DNS_Record_SRV:
			delete(r.service_name) // NOTE(tetra): the three strings are substrings; the service name is the start of that string.
		}
	}

	delete(records)
}
