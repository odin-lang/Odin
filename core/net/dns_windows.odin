#+build windows
package net

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

import "core:strings"
import "core:mem"

import win "core:sys/windows"

@(private)
_get_dns_records_os :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, err: DNS_Error) {
	context.allocator = allocator

	options := win.DNS_QUERY_OPTIONS{}
	if strings.has_suffix(hostname, ".local") {
		options = {.MULTICAST_ONLY, .MULTICAST_WAIT} // 0x00020500
	}

	host_cstr := strings.clone_to_cstring(hostname, context.temp_allocator)
	rec: ^win.DNS_RECORD
	res := win.DnsQuery_UTF8(host_cstr, u16(type), options, nil, &rec, nil)

	switch u32(res) {
	case 0:
		// okay
	case win.ERROR_INVALID_NAME:
		return nil, .Invalid_Hostname_Error
	case win.DNS_INFO_NO_RECORDS:
		return
	case:
		return nil, .System_Error
	}
	defer win.DnsRecordListFree(rec, 1) // 1 means that we're freeing a list... because the proc name isn't enough.

	count := 0
	for r := rec; r != nil; r = r.pNext {
		if r.wType != u16(type) {
			// NOTE(tetra): Should never happen, but...
			continue
		}
		count += 1
	}

	recs := make([dynamic]DNS_Record, 0, count)
	if recs == nil {
		return nil, .System_Error // return no results if OOM.
	}

	for r := rec; r != nil; r = r.pNext {
		if r.wType != u16(type) {
			continue // NOTE(tetra): Should never happen, but...
		}

		base_record := DNS_Record_Base{
			record_name = strings.clone(string(r.pName)),
			ttl_seconds = r.dwTtl,
		}

		switch DNS_Record_Type(r.wType) {
		case .IP4:
			addr := IP4_Address(transmute([4]u8)r.Data.A)
			record := DNS_Record_IP4{
				base    = base_record,
				address = addr,
			}
			append(&recs, record)

		case .IP6:
			addr := IP6_Address(transmute([8]u16be) r.Data.AAAA)
			record := DNS_Record_IP6{
				base    = base_record,
				address = addr,
			}
			append(&recs, record)

		case .CNAME:
			record := DNS_Record_CNAME{
				base      = base_record,
				host_name = strings.clone(string(r.Data.CNAME)),
			}
			append(&recs, record)

		case .TXT:
			n := r.Data.TXT.dwStringCount
			ptr := &r.Data.TXT.pStringArray
			c_strs := mem.slice_ptr(ptr, int(n))

			for cstr in c_strs {
				record := DNS_Record_TXT{
					base  = base_record,
					value = strings.clone(string(cstr)),
				}
				append(&recs, record)
			}

		case .NS:
			record := DNS_Record_NS{
				base      = base_record,
				host_name = strings.clone(string(r.Data.NS)),
			}
			append(&recs, record)

		case .MX:
			/*
				TODO(tetra): Order by preference priority? (Prefer hosts with lower preference values.)
				Or maybe not because you're supposed to just use the first one that works
				and which order they're in changes every few calls.
			*/

			record := DNS_Record_MX{
				base       = base_record,
				host_name  = strings.clone(string(r.Data.MX.pNameExchange)),
				preference = int(r.Data.MX.wPreference),
			}
			append(&recs, record)

		case .SRV:
			// NOTE(tetra): Srv record name should be of the form '_servicename._protocol.hostname'
			// The record name is the name of the record.
			// Not to be confused with the _target_ of the record, which is--in combination with the port--what we're looking up
			// by making this request in the first place.

			service_name, protocol_name: string

			s := base_record.record_name
			i := strings.index_byte(s, '.')
			if i > -1 {
				service_name = s[:i]
				s = s[len(service_name) + 1:]
			} else {
				continue
			}

			i  = strings.index_byte(s, '.')
			if i > -1 {
				protocol_name = s[:i]
			} else {
				continue
			}

			append(&recs, DNS_Record_SRV {
				base          = base_record,
				target        = strings.clone(string(r.Data.SRV.pNameTarget)), // The target hostname/address that the service can be found on
				port          = int(r.Data.SRV.wPort),
				service_name  = service_name,
				protocol_name = protocol_name,
				priority      = int(r.Data.SRV.wPriority),
				weight        = int(r.Data.SRV.wWeight),

			})
		}
	}

	records = recs[:]
	return
}