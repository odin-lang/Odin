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

import "core:mem"
import "core:strings"
import "core:fmt"
import "core:time"

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
	addr := addr4 != nil ? addr4 : addr6; // preferring IPv4.
	assert(addr != nil); // If resolve_ok, we'll have at least one address.
	```
*/

// TODO: Rewrite this to work with OS resolver or custom name servers.

resolve :: proc(hostname: string, addr_types: bit_set[Addr_Type] = {.IPv4, .IPv6}) -> (addr4, addr6: Address, ok: bool) {
	if addr := parse_address(hostname); addr != nil {
		switch a in addr {
		case IPv4_Address: addr4 = addr
		case IPv6_Address: addr6 = addr
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

	if .IPv4 in addr_types {
		recs, _ := get_dns_records_from_os(hostname, .IPv4, allocator)
		if len(recs) > 0 {
			addr4 = cast(IPv4_Address) recs[0].(DNS_Record_IPv4) // address is copied
		}
	}

	if .IPv6 in addr_types {
		recs, _ := get_dns_records_from_os(hostname, .IPv6, allocator)
		if len(recs) > 0 {
			addr6 = cast(IPv6_Address) recs[0].(DNS_Record_IPv6) // address is copied
		}
	}

	ok = addr4 != nil || addr6 != nil
	return
}

/*
	`get_dns_records` uses OS-specific methods to query DNS records.
*/
when ODIN_OS == .Windows {
	get_dns_records_from_os :: get_dns_records_windows
} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	get_dns_records_from_os :: get_dns_records_unix
} else {
	#panic("get_dns_records_from_os not implemented on this OS")
}

/*
	A generic DNS client usable on any platform.
*/
get_dns_records_from_nameservers :: proc(hostname: string, type: DNS_Record_Type, name_servers: []Endpoint, host_overrides: []DNS_Record, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
	context.allocator = allocator

	_validate_hostname(hostname) or_return

	hdr := DNS_Header{
		id = 0, 
		is_response = false, 
		opcode = 0, 
		is_authoritative = false, 
		is_truncated = false,
		is_recursion_desired = true,
		is_recursion_available = false,
		response_code = DNS_Response_Code.No_Error,
	}

	id, bits := _pack_dns_header(hdr)
	dns_hdr := [6]u16be{}
	dns_hdr[0] = id
	dns_hdr[1] = bits
	dns_hdr[2] = 1

	dns_query := [2]u16be{ u16be(type), 1 }

	output := [(size_of(u16be) * 6) + name_max + (size_of(u16be) * 2)]u8{}
	b := strings.builder_from_slice(output[:])

	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_hdr[:]))
	_encode_hostname(&b, hostname) or_return
	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_query[:]))

	dns_packet := output[:strings.builder_len(b)]

	dns_response_buf := [4096]u8{}
	dns_response: []u8
	for name_server in name_servers {
		conn, sock_err := make_unbound_udp_socket(family_from_address(name_server.address))
		if sock_err != nil {
			fmt.printf("here\n")
			return
		}
		defer close(conn)

		_, send_err := send(conn, dns_packet[:], name_server)
		if send_err != nil {
			fmt.printf("here2\n")
			continue
		}

		set_err := set_option(conn, .Receive_Timeout, time.Second * 1)
		if set_err != nil {
			fmt.printf("here3\n")
			return
		}

		recv_sz, _, recv_err := recv_udp(conn, dns_response_buf[:])
		if recv_err == UDP_Recv_Error.Timeout {
			fmt.printf("DNS Server response timed out\n")
			continue
		} else if recv_err != nil {
			fmt.printf("here4\n")
			continue
		}

		if recv_sz == 0 {
			continue
		}

		dns_response = dns_response_buf[:recv_sz]

		rsp, _ok := _parse_response(dns_response, type)
		if !_ok {
			return
		}

		if len(rsp) == 0 {
			continue
		}

		return rsp[:], true
	}
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