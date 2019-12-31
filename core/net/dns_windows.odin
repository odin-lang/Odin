package net

import "core:strings"
import "core:mem"

import "core:sys/win32"


// Resolves a hostname to exactly one IPv4 and IPv6 address.
// It's then up to you which one you use.
//
// If hostname is actually a string representation of an IP address, this function
// behaves like `parse_addr`.
// This allows you to pass a generic endpoint string to this function end reliably get
// back the endpoint's IP address.
//
// ```
// 	// Maybe you got this from a config file, so you
//	// don't know if it's a hostname or address.
//	ep_string := "localhost:9000";
//
//	addr_or_host, port, split_ok := net.split_port(ep_string);
//	assert(split_ok);
//	port = (port == 0) ? 9000 : port; // returns zero if no port in the string.
//
//	// Resolving an address just returns the address.
//	addr4, addr6, resolve_ok := net.resolve(addr_or_host);
//	if !resolve_ok {
//		printf("error: cannot resolve %v\n", addr_or_host);
//		return;
//	}
//	addr := addr4 != nil ? addr4 : addr6; // preferring ipv4.
//	assert(addr != nil); // means that we did not resolve it to an addresses.
// ```
//
// Note that which address you pass to `dial` determines the type of the socket.
// Note also that this procedure _only_ returns ok=false if something went _wrong_ with resolution.
resolve :: proc(hostname: string, addr_types: bit_set[Addr_Type] = {.Ipv4, .Ipv6}) -> (addr4, addr6: Address, ok: bool) {
	if addr := parse_addr(hostname); addr != nil {
		switch a in addr {
		case Ipv4_Address: addr4 = addr;
		case Ipv6_Address: addr6 = addr;
		}
		ok = true;
		return;
	}

	//
	// DEBUG: Why is 1024 bytes not enough when the entire map in get_dns_records is only 256 bytes?
	//

	// NOTE(tetra): We might not have used temporary storage yet,
	// and get_dns_records uses it by default.
	// Rather than require the user initialize it manually first,
	// we just use a stack-arena here instead.
	// We can do this because the addresses we return are returned by value,
	// so we don't return data from within this arena.
	buf: [4096]byte;
	arena: mem.Arena;
	mem.init_arena(&arena, buf[:]);
	allocator := mem.arena_allocator(&arena);

	if .Ipv4 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .Ipv4, allocator);
		if !rec_ok do return;
		if len(recs) > 0 {
			addr4 = recs[0].(Dns_Record_Ipv4).addr; // address is copied
		}
	}

	if .Ipv6 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .Ipv6, allocator);
		if !rec_ok do return;
		if len(recs) > 0 {
			addr6 = recs[0].(Dns_Record_Ipv6).addr; // address is copied
		}
	}

	ok = true;
	return;
}



/* TODO: Support CAA, CNAME, MX, NS, TXT, and SRV records. */

Dns_Record_Type :: enum u16 {
    Ipv4 = win32.DNS_TYPE_A,    // Ipv4 address.
    Ipv6 = win32.DNS_TYPE_AAAA, // Ipv6 address.
    Cname = win32.DNS_TYPE_CNAME, // Another host name.
    Txt = win32.DNS_TYPE_TEXT,  // Arbitrary binary data or text.
    Ns = win32.DNS_TYPE_NS,     // Address of a name server. TODO(tetra): .. Name server for what?
    Mx = win32.DNS_TYPE_MX,     // Address and preference priority of a mail exchange server.
}

Dns_Record_Ipv4 :: struct {
	addr: Ipv4_Address,
}

Dns_Record_Ipv6 :: struct {
	addr: Ipv6_Address,
}

Dns_Record_Cname :: struct {
	host: string,
}

Dns_Record_Text :: struct {
	text: string,
}

Dns_Record_Ns :: struct {
	host: string,
}

Dns_Record_Mx :: struct {
	host: string,
	preference: int,
}

Dns_Record :: union {
	Dns_Record_Ipv4,
	Dns_Record_Ipv6,
	Dns_Record_Cname,
	Dns_Record_Text,
	Dns_Record_Ns,
	Dns_Record_Mx,
}

// Performs a recursive DNS query for records of a particular type for the hostname.
//
// This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
// meaning that DNS queries for a hostname will resolve through CNAME records until an
// IP address is reached.
//
// Returns records and their data in temporary storage, unless otherwise specified by `allocator`.
get_dns_records :: proc(hostname: string, type: Dns_Record_Type, allocator := context.temp_allocator) -> (records: []Dns_Record, ok: bool) {
	host_cstr := strings.clone_to_cstring(hostname, context.temp_allocator);

	// NOTE(tetra): We should not be allocating using this allocator after this.
	// We can maybe move this up to the top when Bill makes the temp storage always use the default allocator
	// instead of the context allocator if it hasn't yet been initialized.
	context.allocator = mem.nil_allocator();

	rec: ^win32.Dns_Record;
	res := win32.DnsQuery_UTF8(host_cstr, u16(type), 0, nil, &rec, nil);
	if res == win32.DNS_INFO_NO_RECORDS || res == win32.ERROR_INVALID_NAME {
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

	// TODO(tetra): DEBUG: Using `make([dynamic]Dns_Record, 0, count, allocator)` causes the assert in append to fire.
	recs := make([dynamic]Dns_Record, allocator);
	if !reserve(&recs, count) do return;
	if recs == nil do return; // return no results if OOM.


	for r := rec; r != nil; r = r.next {
		if r.type != u16(type) do continue; // NOTE(tetra): Should never happen, but...

		new_rec: Dns_Record;

		switch Dns_Record_Type(r.type) {
		case .Ipv4:
			addr := Ipv4_Address(transmute([4]u8) r.data.ip_address);
			new_rec = Dns_Record_Ipv4 { addr = addr }; // NOTE(tetra): value copy
		case .Ipv6:
			addr := Ipv6_Address(transmute([8]u16be) r.data.ip6_address);
			new_rec = Dns_Record_Ipv6 { addr = addr }; // NOTE(tetra): value copy
		case .Cname:
			host := string(r.data.cname);
			new_rec = Dns_Record_Cname { host = strings.clone(host, allocator) };
		case .Txt:
			n := r.data.text.string_count;
			ptr := &r.data.text.string_array;
			c_strs := mem.slice_ptr(ptr, int(n));
			for cstr in c_strs {
				s := string(cstr);
				new_rec = Dns_Record_Text { text = strings.clone(s, allocator) };
			}
		case .Ns:
			host := string(r.data.name_host);
			new_rec = Dns_Record_Ns { host = strings.clone(host, allocator) };
		case .Mx:
			// TODO(tetra): Order by preference priority? (Prefer hosts with lower preference values.)
			// Or maybe not because you're supposed to just use the first one that works
			// and which order they're in changes between after every few calls.
			host := string(r.data.mail_exchange.host);
			preference := int(r.data.mail_exchange.preference);
			new_rec = Dns_Record_Mx { host       = strings.clone(host, allocator),
			                          preference = preference };
		}

		append(&recs, new_rec);
	}

	records = recs[:];
	ok = true;
	return;
}