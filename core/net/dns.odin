package net

import "core:mem"
import "core:os"

DNS_TYPE_A     :: 0x1
DNS_TYPE_NS    :: 0x2
DNS_TYPE_CNAME :: 0x5
DNS_TYPE_MX    :: 0xf
DNS_TYPE_AAAA  :: 0x1c
DNS_TYPE_TEXT  :: 0x10
DNS_TYPE_SRV   :: 0x21

// TODO: Support SRV records.
Dns_Record_Type :: enum u16 {
	Ipv4 = DNS_TYPE_A,    // Ipv4 address.
	Ipv6 = DNS_TYPE_AAAA, // Ipv6 address.
	Cname = DNS_TYPE_CNAME, // Another host name.
	Txt = DNS_TYPE_TEXT,  // Arbitrary binary data or text.
	Ns = DNS_TYPE_NS,     // Address of a name (DNS) server.
	Mx = DNS_TYPE_MX,     // Address and preference priority of a mail exchange server.
	Srv = DNS_TYPE_SRV,   // Address, port, priority, and weight of a host that provides a particular service.
}

// An IPv4 address that the domain name maps to.
// There can be any number of these.
Dns_Record_Ipv4 :: distinct Ipv4_Address

// An IPv6 address that the domain name maps to.
// There can be any number of these.
Dns_Record_Ipv6 :: distinct Ipv6_Address

// Another domain name that the domain name maps to.
// Domains can be pointed to another domain instead of directly to an IP address.
// `get_dns_records` will recursively follow these if you request this type of record.
Dns_Record_Cname :: distinct string

// Arbitrary string data that is associated with the domain name.
// Commonly of the form `key=value` to be parsed, though there is no specific format for them.
// These can be used for any purpose.
Dns_Record_Text :: distinct string

// Domain names of other DNS servers that are associated with the domain name.
// TODO(tetra): Expand on what these records are used for, and when you should use pay attention to these.
Dns_Record_Ns :: distinct string

// Domain names for email servers that are associated with the domain name.
// These records also have values which ranks them in the order they should be preferred. Lower is more-preferred.
Dns_Record_Mx :: struct {
	host: string,
	preference: int,
}

// An endpoint for a service that is available through the domain name.
// This is the way to discover the services that a domain name provides.
//
// Clients MUST attempt to contact the host with the lowest priority that they can reach.
// If two hosts have the same priority, they should be contacted in the order according to their weight.
// Hosts with larger weights should have a proportionally higher chance of being contacted by clients.
// A weight of zero indicates a very low weight, or, when there is no choice (to reduce visual noise).
//
// The host may be "." to indicate that it is "decidedly not available" on this domain.
Dns_Record_Srv :: struct {
	service_name, protocol, host: string,
	port: int,
	priority: int, // lower is higher priority
	weight: int, // relative weight of this host compared to other of same priority; the chance of using this host should be proporitional to this weight.
}

Dns_Record :: union {
	Dns_Record_Ipv4,
	Dns_Record_Ipv6,
	Dns_Record_Cname,
	Dns_Record_Text,
	Dns_Record_Ns,
	Dns_Record_Mx,
	Dns_Record_Srv,
}

Dns_Response_Code :: enum u16be {
	No_Error,
	Format_Error,
	Server_Failure,
	Name_Error,
	Not_Implemented,
	Refused,
}

Dns_Query :: enum u16be {
	Host_Address = 1,
	Authoritative_Name_Server = 2,
	Mail_Destination = 3,
	Mail_Forwarder = 4,
	Cname = 5,
	All = 255,
}

Dns_Header :: struct {
	id: u16be,
	is_response: bool,
	opcode: u16be,
	is_authoritative: bool,
	is_truncated: bool,
	is_recursion_desired: bool,
	is_recursion_available: bool,
	response_code: Dns_Response_Code,
}

Dns_Record_Header :: struct #packed {
	type:   u16be,
	class:  u16be,
	ttl:    u32be,
	length: u16be,
}

/*
   Resolves a hostname to exactly one IPv4 and IPv6 address.
   It's then up to you which one you use.
   Note that which address you pass to `dial` determines the type of the socket you get.
  
   Returns `ok = false` if the host name could not be resolved to any addresses.
  
  
   If hostname is actually a string representation of an IP address, this function
   just parses that address and returns it.
   This allows you to pass a generic endpoint string (i.e: hostname or address) to this function end reliably get
   back the endpoint's IP address.
   e.g:
   ```
   	// Maybe you got this from a config file, so you
  	// don't know if it's a hostname or address.
  	ep_string := "localhost:9000";
  
  	addr_or_host, port, split_ok := net.split_port(ep_string);
  	assert(split_ok);
  	port = (port == 0) ? 9000 : port; // returns zero if no port in the string.
  
  	// Resolving an address just returns the address.
  	addr4, addr6, resolve_ok := net.resolve(addr_or_host);
  	if !resolve_ok {
  		printf("error: cannot resolve %v\n", addr_or_host);
  		return;
  	}
  	addr := addr4 != nil ? addr4 : addr6; // preferring ipv4.
  	assert(addr != nil); // If resolve_ok, we'll have at least one address.
   ```
*/

resolve :: proc(hostname: string, addr_types: bit_set[Addr_Type] = {.Ipv4, .Ipv6}) -> (addr4, addr6: Address, ok: bool) {
	if addr := parse_address(hostname); addr != nil {
		switch a in addr {
		case Ipv4_Address: addr4 = addr
		case Ipv6_Address: addr6 = addr
		}
		ok = true
		return
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
	buf: [4096]byte
	arena: mem.Arena
	mem.init_arena(&arena, buf[:])
	allocator := mem.arena_allocator(&arena)

	if .Ipv4 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .Ipv4, allocator)
		if !rec_ok do return
		if len(recs) > 0 {
			addr4 = cast(Ipv4_Address) recs[0].(Dns_Record_Ipv4) // address is copied
		}
	}

	if .Ipv6 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .Ipv6, allocator)
		if !rec_ok do return
		if len(recs) > 0 {
			addr6 = cast(Ipv6_Address) recs[0].(Dns_Record_Ipv6) // address is copied
		}
	}

	ok = addr4 != nil || addr6 != nil
	return
}
