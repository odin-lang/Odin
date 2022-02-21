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
import "core:time"
import "core:os"
import "core:fmt"

/*
	Default configuration for DNS resolution.
*/
when ODIN_OS == .Windows {
	getenv :: proc(key: string) -> (val: string) {
		return os.get_env(key)
	}

	DEFAULT_DNS_CONFIGURATION :: DNS_Configuration{
		resolv_conf        = "",
		hosts_file         = "%WINDIR%\\system32\\drivers\\etc\\hosts",
		name_servers       = nil,
		hosts_file_entries = nil,
	}
} else when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	getenv :: proc(key: string) -> (val: string) {
		val, _ = os.getenv(key)
		return
	}

	DEFAULT_DNS_CONFIGURATION :: DNS_Configuration{
		resolv_conf        = "/etc/resolv.conf",
		hosts_file         = "/etc/hosts",
		name_servers       = nil,
		hosts_file_entries = nil,
	}
} else {
	#panic("Please add a configuration for this OS.")
}

@(init)
reload_dns_configuration :: proc() {
	/*
		The idea is that we can use this to parse resolve and hosts files so we don't need to look them up on each resolve.

		Also resolve %ENVIRONMENT% placeholders in their paths.
	*/
	_dns_configuration.resolv_conf, _ = replace_environment_path(_dns_configuration.resolv_conf)
	_dns_configuration.hosts_file,  _ = replace_environment_path(_dns_configuration.hosts_file)
}

/*
	Always allocates for consistency.
*/
replace_environment_path :: proc(path: string, allocator := context.allocator) -> (res: string, ok: bool) {
	/*
		Nothing to replace. Return a clone of the original.
	*/
	if strings.count(path, "%") != 2 {
		return strings.clone(path), true
	}

	left  := strings.index(path, "%") + 1
	assert(left > 0 && left <= len(path)) // should be covered by there being two %

	right := strings.index(path[left:], "%") + 1
	assert(right > 0 && right <= len(path)) // should be covered by there being two %

	env_key := path[left: right]
	env_val := getenv(env_key)
	defer delete(env_val)

	res, _ = strings.replace(path, path[left - 1: right + 1], env_val, 1)

	return res, true
}

destroy_dns_configuration :: proc() {
	delete(_dns_configuration.resolv_conf)
	delete(_dns_configuration.hosts_file)
	delete(_dns_configuration.name_servers)
	delete(_dns_configuration.hosts_file_entries)
}

@(private)
_dns_configuration := DEFAULT_DNS_CONFIGURATION

/*
	TODO: Wrap this in a mutex.
*/
get_dns_configuration :: proc() -> (configuration: DNS_Configuration, ok: bool) {
	return _dns_configuration, true
}

/*
	TODO: Wrap this in a mutex.
*/
set_dns_configuration :: proc(configuration: DNS_Configuration) -> (ok: bool) {
	_dns_configuration = configuration
	return true
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
	addr := addr4 != nil ? addr4 : addr6; // preferring IPv4.
	assert(addr != nil); // If resolve_ok, we'll have at least one address.
	```
*/

// TODO: Rewrite this to work with OS resolver or custom name servers.
resolve :: proc(hostname: string, families_to_resolve: bit_set[Address_Family] = {.IPv4, .IPv6}) -> (addr4, addr6: Address, ok: bool) {
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

	if .IPv4 in families_to_resolve {
		recs, _ := get_dns_records_from_os(hostname, .IPv4, allocator)
		if len(recs) > 0 {
			addr4 = cast(IPv4_Address) recs[0].(DNS_Record_IPv4) // address is copied
		}
	}

	if .IPv6 in families_to_resolve {
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
	Performs a recursive DNS query for records of a particular type for the hostname.

	NOTE: This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
	meaning that DNS queries for a hostname will resolve through CNAME records until an
	IP address is reached.
*/
get_dns_records_from_nameservers :: proc(hostname: string, type: DNS_Record_Type, name_servers: []Endpoint, host_overrides: []DNS_Record, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
	context.allocator = allocator

	validate_hostname(hostname) or_return

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

	id, bits := pack_dns_header(hdr)
	dns_hdr := [6]u16be{}
	dns_hdr[0] = id
	dns_hdr[1] = bits
	dns_hdr[2] = 1

	dns_query := [2]u16be{ u16be(type), 1 }

	output := [(size_of(u16be) * 6) + NAME_MAX + (size_of(u16be) * 2)]u8{}
	b := strings.builder_from_slice(output[:])

	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_hdr[:]))
	encode_hostname(&b, hostname) or_return
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

		rsp, _ok := parse_response(dns_response, type)
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
			delete(r.host_name)
		case DNS_Record_SRV:
			delete(r._entire_name_buffer)
		}
	}

	delete(records)
}

/*
	TODO(cloin): Does the DNS Resolver need to recursively hop through CNAMEs to get the IP
	or is that what recursion desired does? Do we need to handle recursion unavailable?
	How do we deal with is_authoritative / is_truncated?

	TODO(cloin): How do we cache resolv.conf and hosts in a threadsafe way?

	TODO(cloin): Handle more record types
*/

NAME_MAX :: 255

pack_dns_header :: proc(hdr: DNS_Header) -> (id: u16be, bits: u16be) {
	id = hdr.id
	bits = hdr.opcode << 1 | u16be(hdr.response_code)
	if hdr.is_response {
		bits |= 1 << 15
	}
	if hdr.is_authoritative {
		bits |= 1 << 10
	}
	if hdr.is_truncated {
		bits |= 1 << 9
	}
	if hdr.is_recursion_desired {
		bits |= 1 << 8
	}
	if hdr.is_recursion_available {
		bits |= 1 << 7
	}

	return id, bits
}

unpack_dns_header :: proc(id: u16be, bits: u16be) -> (hdr: DNS_Header) {
	hdr.id = id
	hdr.is_response            = (bits & (1 << 15)) != 0
	hdr.opcode                 = (bits >> 11) & 0xF
	hdr.is_authoritative       = (bits & (1 << 10)) != 0
	hdr.is_truncated           = (bits & (1 <<  9)) != 0
	hdr.is_recursion_desired   = (bits & (1 <<  8)) != 0
	hdr.is_recursion_available = (bits & (1 <<  7)) != 0
	hdr.response_code = DNS_Response_Code(bits & 0xF)

	return hdr
}

load_resolv_conf :: proc(resolv_conf_path: string, allocator := context.allocator) -> (name_servers: []Endpoint, ok: bool) {
	context.allocator = allocator

	res, success := os.read_entire_file_from_filename(resolv_conf_path)
	if !success {
		return
	}
	defer delete(res)
	resolv_str := string(res)

	_name_servers := make([dynamic]Endpoint, 0, allocator)
	for line in strings.split_lines_iterator(&resolv_str) {
		if len(line) == 0 || line[0] == '#' {
			continue
		}

		id_str := "nameserver"
		if strings.compare(line[:len(id_str)], id_str) != 0 {
			continue
		}

		server_ip_str := strings.trim_left_space(line[len(id_str):])
		if len(server_ip_str) == 0 {
			continue
		}

		addr := parse_address(server_ip_str)
		endpoint := Endpoint{
			addr,
			53,
		}
		append(&_name_servers, endpoint)
	}

	return _name_servers[:], true
}

load_hosts :: proc(hosts_file_path: string, allocator := context.allocator) -> (hosts: []DNS_Host_Entry, ok: bool) {
	context.allocator = allocator

	res, success := os.read_entire_file_from_filename(hosts_file_path, allocator)
	if !success {
		return
	}
	defer delete(res)

	_hosts := make([dynamic]DNS_Host_Entry, 0, allocator)
	hosts_str := string(res)
	for line in strings.split_lines_iterator(&hosts_str) {
		if len(line) == 0 || line[0] == '#' {
			continue
		}

		splits := strings.fields(line)
		defer delete(splits)

		ip_str := splits[0]
		addr := parse_address(ip_str)
		if addr == nil {
			continue
		}

		for hostname in splits[1:] {
			if len(hostname) == 0 {
				continue
			}

			append(&_hosts, DNS_Host_Entry{hostname, addr})
		}
	}

	return _hosts[:], true
}

/*
	www.google.com -> 3www6google3com0
*/
encode_hostname :: proc(b: ^strings.Builder, hostname: string, allocator := context.allocator) -> (ok: bool) {

	label_max :: 63

	_hostname := hostname
	for section in strings.split_iterator(&_hostname, ".") {
		if len(section) > label_max {
			return
		}

		strings.write_byte(b, u8(len(section)))
		strings.write_string(b, section)
	}
	strings.write_byte(b, 0)

	return true
}

decode_hostname :: proc(packet: []u8, start_idx: int, allocator := context.allocator) -> (hostname: string, encode_size: int, ok: bool) {
	output := [NAME_MAX]u8{}
	b := strings.builder_from_slice(output[:])

	// If you're on level 0, update out_bytes, everything through a pointer
	// doesn't count towards this hostname's packet length

	// Evaluate tokens to generate the hostname
	out_size := 0
	level := 0
	print_size := 0
	cur_idx := start_idx
	iteration_max := 0
	for cur_idx < len(packet) {
		if packet[cur_idx] == 0 {

			if (level == 0) {
				out_size += 1
			}

			break
		}

		if iteration_max > 255 {
			fmt.printf("Taking too long, not bothering\n")
			return
		}

		if packet[cur_idx] > 63 && packet[cur_idx] != 0xC0 {
			fmt.printf("Can't handle this token!\n")
			return
		}

		switch packet[cur_idx] {

		// This is a offset to more data in the packet, jump to it
		case 0xC0:
			pkt := packet[cur_idx:cur_idx+2]
			val := (^u16be)(raw_data(pkt))^
			offset := int(val & 0x3FFF)
			if offset > len(packet) {
				fmt.printf("Packet offset invalid\n")
				return
			}

			cur_idx = offset

			if (level == 0) {
				out_size += 2
				level += 1
			}

		// This is a label, insert it into the hostname
		case:
			label_size := int(packet[cur_idx])
			idx2 := cur_idx + label_size + 1
			if idx2 < cur_idx + 1 || idx2 > len(packet) {
				fmt.printf("Invalid index for hostname!\n")
				return
			}

			if print_size + label_size + 1 > NAME_MAX {
				fmt.printf("label too large for hostname!\n")
				return
			}

			strings.write_byte(&b, '.')
			strings.write_bytes(&b, packet[cur_idx+1:idx2])
			print_size += label_size + 1

			cur_idx = idx2

			if (level == 0) {
				out_size += label_size + 1
			}
		}

		iteration_max += 1
	}

	if start_idx + out_size > len(packet) {
		fmt.printf("not enough bytes in packet for hostname!\n")
		return
	}

	return strings.clone(strings.to_string(b), allocator), out_size, true
}

// Uses RFC 952 & RFC 1123
validate_hostname :: proc(hostname: string) -> (ok: bool) {
	if len(hostname) > 255 || len(hostname) == 0 {
		return
	}

	if hostname[0] == '-' {
		return
	}

	_hostname := hostname
	for label in strings.split_iterator(&_hostname, ".") {
		if len(label) > 63 || len(label) == 0 {
			return
		}

		for ch in label {
			switch ch {
			case:
				return
			case 'a'..'z', 'A'..'Z', '0'..'9', '-':
				continue
			}
		}
	}

	return true
}

parse_record :: proc(packet: []u8, cur_off: ^int, filter: DNS_Record_Type = nil) -> (record: DNS_Record, ok: bool) {
	record_buf := packet[cur_off^:]
	_, hn_sz := decode_hostname(packet, cur_off^) or_return

	ahdr_sz := size_of(DNS_Record_Header)
	if len(record_buf) - hn_sz < ahdr_sz {
		return
	}

	record_hdr_bytes := record_buf[hn_sz:hn_sz+ahdr_sz]
	record_hdr := cast(^DNS_Record_Header)raw_data(record_hdr_bytes)

	data_sz := record_hdr.length
	data_off := cur_off^ + int(hn_sz) + int(ahdr_sz)
	data := packet[data_off:data_off+int(data_sz)]
	cur_off^ += int(hn_sz) + int(ahdr_sz) + int(data_sz)

	// nil == aggregate *everything*
	if filter == nil || u16be(filter) != record_hdr.type {
		return nil, true
	}

	_record: DNS_Record
	#partial switch DNS_Record_Type(record_hdr.type) {
		case .IPv4:
			if len(data) != 4 {
				return
			}

			addr_val: u32be = mem.slice_data_cast([]u32be, data)[0]
			addr := IPv4_Address(transmute([4]u8)addr_val)
			_record = DNS_Record_IPv4(addr)
		case .IPv6:
			if len(data) != 16 {
				return
			}

			addr_val: u128be = mem.slice_data_cast([]u128be, data)[0]
			addr := IPv6_Address(transmute([8]u16be)addr_val)
			_record = DNS_Record_IPv6(addr)
		case .CNAME:
			hostname, _ := decode_hostname(packet, data_off) or_return
			_record = DNS_Record_CNAME(hostname)
		case .NS:
			name, _ := decode_hostname(packet, data_off + (size_of(u16be) * 3)) or_return
			_record = DNS_Record_NS(name)
		case .SRV:
			if len(data) <= 6 {
				return
			}

			priority: u16be = mem.slice_data_cast([]u16be, data)[0]
			weight:   u16be = mem.slice_data_cast([]u16be, data)[1]
			port:     u16be = mem.slice_data_cast([]u16be, data)[2]
			name, _ := decode_hostname(packet, data_off + (size_of(u16be) * 3)) or_return

			parts := strings.split_n(name, ".", 3)
			if len(parts) != 3 {
				return
			}
			service_name, protocol_name, host_name := parts[0], parts[1], parts[2]
			if service_name[0] == '_' {
				service_name = service_name[1:]
			}
			if protocol_name[0] == '_' {
				protocol_name = protocol_name[1:]
			}

			_record = DNS_Record_SRV{
				_entire_name_buffer = name,
				service_name  = service_name,
				protocol_name = protocol_name,
				host_name     = host_name,
				priority      = int(priority),
				weight        = int(weight),
				port          = int(port),
			}
		case .MX:
			if len(data) <= 2 {
				return
			}

			preference: u16be = mem.slice_data_cast([]u16be, data)[0]
			hostname, _ := decode_hostname(packet, data_off + size_of(u16be)) or_return
			_record = DNS_Record_MX{
				host_name  = hostname,
				preference = int(preference),
			}
		case:
			fmt.printf("ignoring %d\n", record_hdr.type)
			return

	}

	return _record, true
}

/*
	DNS Query Response Format:
	- DNS_Header (packed)
	- Query Count
	- Answer Count
	- Authority Count
	- Additional Count
	- Query[]
		- Hostname -- encoded
		- Type
		- Class
	- Answer[]
		- DNS Record Data
	- Authority[]
		- DNS Record Data
	- Additional[]
		- DNS Record Data

	DNS Record Data:
	- DNS_Record_Header
	- Data[]
*/

parse_response :: proc(response: []u8, filter: DNS_Record_Type = nil, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
	header_size_bytes :: 12
	if len(response) < header_size_bytes {
		return
	}

	_records := make([dynamic]DNS_Record, 0)

	dns_hdr_chunks := mem.slice_data_cast([]u16be, response[:header_size_bytes])
	hdr := unpack_dns_header(dns_hdr_chunks[0], dns_hdr_chunks[1])
	if !hdr.is_response {
		return
	}

	question_count := int(dns_hdr_chunks[2])
	if question_count != 1 {
		return
	}
	answer_count := int(dns_hdr_chunks[3])
	authority_count := int(dns_hdr_chunks[4])
	additional_count := int(dns_hdr_chunks[5])

	cur_idx := header_size_bytes

	for i := 0; i < question_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		dq_sz :: 4
		hostname, hn_sz := decode_hostname(response, cur_idx) or_return
		dns_query := mem.slice_data_cast([]u16be, response[cur_idx+hn_sz:cur_idx+hn_sz+dq_sz])

		cur_idx += hn_sz + dq_sz
	}

	for i := 0; i < answer_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := parse_record(response, &cur_idx, filter) or_return
		if rec == nil {
			continue
		}

		append(&_records, rec)
	}

	for i := 0; i < authority_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := parse_record(response, &cur_idx, filter) or_return
		if rec == nil {
			continue
		}

		append(&_records, rec)
	}

	for i := 0; i < additional_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := parse_record(response, &cur_idx, filter) or_return
		if rec == nil {
			continue
		}

		append(&_records, rec)
	}

	return _records[:], true
}