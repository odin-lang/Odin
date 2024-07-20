// +build windows, linux, darwin
package net

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

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

import "core:mem"
import "core:strings"
import "core:time"
import "core:os"
/*
	Default configuration for DNS resolution.
*/
when ODIN_OS == .Windows {
	DEFAULT_DNS_CONFIGURATION :: DNS_Configuration{
		resolv_conf        = "",
		hosts_file         = "%WINDIR%\\system32\\drivers\\etc\\hosts",
	}
} else when ODIN_OS == .Linux || ODIN_OS == .Darwin || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
	DEFAULT_DNS_CONFIGURATION :: DNS_Configuration{
		resolv_conf        = "/etc/resolv.conf",
		hosts_file         = "/etc/hosts",
	}
} else {
	#panic("Please add a configuration for this OS.")
}

@(init)
init_dns_configuration :: proc() {
	/*
		Resolve %ENVIRONMENT% placeholders in their paths.
	*/
	dns_configuration.resolv_conf, _ = replace_environment_path(dns_configuration.resolv_conf)
	dns_configuration.hosts_file,  _ = replace_environment_path(dns_configuration.hosts_file)
}

destroy_dns_configuration :: proc() {
	delete(dns_configuration.resolv_conf)
	delete(dns_configuration.hosts_file)
}

dns_configuration := DEFAULT_DNS_CONFIGURATION

// Always allocates for consistency.
replace_environment_path :: proc(path: string, allocator := context.allocator) -> (res: string, ok: bool) {
	// Nothing to replace. Return a clone of the original.
	if strings.count(path, "%") != 2 {
		return strings.clone(path, allocator), true
	}

	left  := strings.index(path, "%") + 1
	assert(left > 0 && left <= len(path)) // should be covered by there being two %

	right := strings.index(path[left:], "%") + 1
	assert(right > 0 && right <= len(path)) // should be covered by there being two %

	env_key := path[left: right]
	env_val := os.get_env(env_key, allocator)
	defer delete(env_val)

	res, _ = strings.replace(path, path[left - 1: right + 1], env_val, 1, allocator)
	return res, true
}


/*
	Resolves a hostname to exactly one IP4 and IP6 endpoint.
	It's then up to you which one you use.
	Note that which address you use to open a socket, determines the type of the socket you get.

	Returns `ok=false` if the host name could not be resolved to any endpoints.

	Returned endpoints have the same port as provided in the string, or 0 if absent.
	If you want to use a specific port, just modify the field after the call to this procedure.

	If the hostname part of the endpoint is actually a string representation of an IP address, DNS resolution will be skipped.
	This allows you to pass both strings like "example.com:9000" and "1.2.3.4:9000" to this function end reliably get
	back an endpoint in both cases.
*/
resolve :: proc(hostname_and_maybe_port: string) -> (ep4, ep6: Endpoint, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname_and_maybe_port) or_return
	switch t in target {
	case Endpoint:
		// NOTE(tetra): The hostname was actually an IP address; nothing to resolve, so just return it.
		switch _ in t.address {
		case IP4_Address: ep4 = t
		case IP6_Address: ep6 = t
		case:             unreachable()
		}
		return

	case Host:
		err4, err6: Network_Error = ---, ---
		ep4, err4 = resolve_ip4(t.hostname)
		ep6, err6 = resolve_ip6(t.hostname)
		ep4.port  = t.port if err4 == nil else 0
		ep6.port  = t.port if err6 == nil else 0
		if err4 != nil && err6 != nil {
			err = err4
		}
		return
	}
	unreachable()
}

resolve_ip4 :: proc(hostname_and_maybe_port: string) -> (ep4: Endpoint, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname_and_maybe_port) or_return
	switch t in target {
	case Endpoint:
		// NOTE(tetra): The hostname was actually an IP address; nothing to resolve, so just return it.
		switch _ in t.address {
		case IP4_Address:
			return t, nil
		case IP6_Address:
			err = .Unable_To_Resolve
			return
		}
	case Host:
		recs, _ := get_dns_records_from_os(t.hostname, .IP4, context.temp_allocator)
		if len(recs) == 0 {
			err = .Unable_To_Resolve
			return
		}
		ep4 = {
			address = recs[0].(DNS_Record_IP4).address,
			port = t.port,
		}
		return
	}
	unreachable()
}

resolve_ip6 :: proc(hostname_and_maybe_port: string) -> (ep6: Endpoint, err: Network_Error) {
	target := parse_hostname_or_endpoint(hostname_and_maybe_port) or_return
	switch t in target {
	case Endpoint:
		// NOTE(tetra): The hostname was actually an IP address; nothing to resolve, so just return it.
		switch _ in t.address {
		case IP4_Address:
			err = .Unable_To_Resolve
			return
		case IP6_Address:
			return t, nil
		}
	case Host:
		recs, _ := get_dns_records_from_os(t.hostname, .IP6, context.temp_allocator)
		if len(recs) == 0 {
			err = .Unable_To_Resolve
			return
		}
		ep6 = {
			address = recs[0].(DNS_Record_IP6).address,
			port = t.port,
		}
		return
	}
	unreachable()
}

/*
	Performs a recursive DNS query for records of a particular type for the hostname using the OS.

	NOTE: This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
	meaning that DNS queries for a hostname will resolve through CNAME records until an
	IP address is reached.

	IMPORTANT: This procedure allocates memory for each record returned; deleting just the returned slice is not enough!
	See `destroy_records`.
*/
get_dns_records_from_os :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, err: DNS_Error) {
	return _get_dns_records_os(hostname, type, allocator)
}

/*
	A generic DNS client usable on any platform.
	Performs a recursive DNS query for records of a particular type for the hostname.

	NOTE: This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
	meaning that DNS queries for a hostname will resolve through CNAME records until an
	IP address is reached.

	IMPORTANT: This procedure allocates memory for each record returned; deleting just the returned slice is not enough!
	See `destroy_records`.
*/
get_dns_records_from_nameservers :: proc(hostname: string, type: DNS_Record_Type, name_servers: []Endpoint, host_overrides: []DNS_Record, allocator := context.allocator) -> (records: []DNS_Record, err: DNS_Error) {
	context.allocator = allocator

	if type != .SRV {
		// NOTE(tetra): 'hostname' can contain underscores when querying SRV records
		ok := validate_hostname(hostname)
		if !ok {
			return nil, .Invalid_Hostname_Error
		}
	}

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
	ok := encode_hostname(&b, hostname)
	if !ok {
		return nil, .Invalid_Hostname_Error
	}
	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_query[:]))

	dns_packet := output[:strings.builder_len(b)]

	dns_response_buf := [4096]u8{}
	dns_response: []u8
	for name_server in name_servers {
		conn, sock_err := make_unbound_udp_socket(family_from_endpoint(name_server))
		if sock_err != nil {
			return nil, .Connection_Error
		}
		defer close(conn)

		_ = send(conn, dns_packet[:], name_server) or_continue

		if set_option(conn, .Receive_Timeout, time.Second * 1) != nil {
			return nil, .Connection_Error
		}

		// recv_sz, _, recv_err := recv_udp(conn, dns_response_buf[:])
		// if recv_err == UDP_Recv_Error.Timeout {
		// 	continue
		// } else if recv_err != nil {
		// 	continue
		// }
		recv_sz, _ := recv_udp(conn, dns_response_buf[:]) or_continue
		if recv_sz == 0 {
			continue
		}

		dns_response = dns_response_buf[:recv_sz]

		rsp, _ok := parse_response(dns_response, type)
		if !_ok {
			return nil, .Server_Error
		}

		if len(rsp) == 0 {
			continue
		}

		return rsp[:], nil
	}

	return
}

// `records` slice is also destroyed.
destroy_dns_records :: proc(records: []DNS_Record, allocator := context.allocator) {
	context.allocator = allocator

	for rec in records {
		switch r in rec {
		case DNS_Record_IP4:
			delete(r.base.record_name)

		case DNS_Record_IP6:
			delete(r.base.record_name)

		case DNS_Record_CNAME:
			delete(r.base.record_name)
			delete(r.host_name)

		case DNS_Record_TXT:
			delete(r.base.record_name)
			delete(r.value)

		case DNS_Record_NS:
			delete(r.base.record_name)
			delete(r.host_name)

		case DNS_Record_MX:
			delete(r.base.record_name)
			delete(r.host_name)

		case DNS_Record_SRV:
			delete(r.record_name)
			delete(r.target)
		}
	}

	delete(records, allocator)
}

/*
	TODO(cloin): Does the DNS Resolver need to recursively hop through CNAMEs to get the IP
	or is that what recursion desired does? Do we need to handle recursion unavailable?
	How do we deal with is_authoritative / is_truncated?
*/

NAME_MAX  :: 255
LABEL_MAX :: 63

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
	hdr.response_code          = DNS_Response_Code(bits & 0xF)

	return hdr
}

load_resolv_conf :: proc(resolv_conf_path: string, allocator := context.allocator) -> (name_servers: []Endpoint, ok: bool) {
	context.allocator = allocator

	res := os.read_entire_file_from_filename(resolv_conf_path) or_return
	defer delete(res)
	resolv_str := string(res)

	id_str := "nameserver"
	id_len := len(id_str)

	_name_servers := make([dynamic]Endpoint, 0, allocator)
	for line in strings.split_lines_iterator(&resolv_str) {
		if len(line) == 0 || line[0] == '#' {
			continue
		}

		if len(line) < id_len || strings.compare(line[:id_len], id_str) != 0 {
			continue
		}

		server_ip_str := strings.trim_left_space(line[id_len:])
		if len(server_ip_str) == 0 {
			continue
		}

		addr := parse_address(server_ip_str)
		if addr == nil {
			continue
		}

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

	res := os.read_entire_file_from_filename(hosts_file_path, allocator) or_return
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
			if len(hostname) != 0 {
				append(&_hosts, DNS_Host_Entry{hostname, addr})
			}
		}
	}

	return _hosts[:], true
}

// www.google.com -> 3www6google3com0
encode_hostname :: proc(b: ^strings.Builder, hostname: string) -> (ok: bool) {
	_hostname := hostname
	for section in strings.split_iterator(&_hostname, ".") {
		if len(section) > LABEL_MAX {
			return
		}

		strings.write_byte(b, u8(len(section)))
		strings.write_string(b, section)
	}
	strings.write_byte(b, 0)

	return true
}

skip_hostname :: proc(packet: []u8, start_idx: int) -> (encode_size: int, ok: bool) {
	out_size := 0

	cur_idx := start_idx
	iteration_max := 0
	top: for cur_idx < len(packet) {
		if packet[cur_idx] == 0 {
			out_size += 1
			break
		}

		if iteration_max > 255 {
			return
		}

		if packet[cur_idx] > 63 && packet[cur_idx] != 0xC0 {
			return
		}

		switch packet[cur_idx] {
		case 0xC0:
			out_size += 2
			break top
		case:
			label_size := int(packet[cur_idx]) + 1
			idx2 := cur_idx + label_size

			if idx2 < cur_idx + 1 || idx2 > len(packet) {
				return
			}

			out_size += label_size
			cur_idx = idx2
		}

		iteration_max += 1
	}

	if start_idx + out_size > len(packet) {
		return
	}

	return out_size, true
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
	labels_added := 0
	for cur_idx < len(packet) {
		if packet[cur_idx] == 0 {

			if (level == 0) {
				out_size += 1
			}

			break
		}

		if iteration_max > 255 {
			return
		}

		if packet[cur_idx] > 63 && packet[cur_idx] != 0xC0 {
			return
		}

		switch packet[cur_idx] {

		// This is a offset to more data in the packet, jump to it
		case 0xC0:
			pkt := packet[cur_idx:cur_idx+2]
			val := (^u16be)(raw_data(pkt))^
			offset := int(val & 0x3FFF)
			if offset > len(packet) {
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
				return
			}

			if print_size + label_size + 1 > NAME_MAX {
				return
			}

			if labels_added > 0 {
				strings.write_byte(&b, '.')
			}
			strings.write_bytes(&b, packet[cur_idx+1:idx2])
			print_size += label_size + 1
			labels_added += 1

			cur_idx = idx2

			if (level == 0) {
				out_size += label_size + 1
			}
		}

		iteration_max += 1
	}

	if start_idx + out_size > len(packet) {
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
			case 'a'..='z', 'A'..='Z', '0'..='9', '-':
				continue
			}
		}
	}

	return true
}

parse_record :: proc(packet: []u8, cur_off: ^int, filter: DNS_Record_Type = nil) -> (record: DNS_Record, ok: bool) {
	record_buf := packet[cur_off^:]

	srv_record_name, hn_sz := decode_hostname(packet, cur_off^, context.temp_allocator) or_return
	// TODO(tetra): Not sure what we should call this.
	// Is it really only used in SRVs?
	// Maybe some refactoring is required?

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

	if u16be(filter) != record_hdr.type {
		return nil, true
	}

	_record: DNS_Record
	#partial switch DNS_Record_Type(record_hdr.type) {
		case .IP4:
			if len(data) != 4 {
				return
			}

			addr := (^IP4_Address)(raw_data(data))^

			_record = DNS_Record_IP4{
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				address = addr,
			}

		case .IP6:
			if len(data) != 16 {
				return
			}

			addr := (^IP6_Address)(raw_data(data))^

			_record = DNS_Record_IP6{
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				address = addr,
			}

		case .CNAME:
			hostname, _ := decode_hostname(packet, data_off) or_return

			_record = DNS_Record_CNAME{
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				host_name = hostname,
			}

		case .TXT:
			_record = DNS_Record_TXT{
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				value = strings.clone(string(data)),
			}

		case .NS:
			name, _ := decode_hostname(packet, data_off) or_return

			_record = DNS_Record_NS{
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				host_name = name,
			}

		case .SRV:
			if len(data) <= 6 {
				return
			}

			_data := mem.slice_data_cast([]u16be, data)

			priority, weight, port := _data[0], _data[1], _data[2]
			target, _ := decode_hostname(packet, data_off + (size_of(u16be) * 3)) or_return

			// NOTE(tetra): Srv record name should be of the form '_servicename._protocol.hostname'
			// The record name is the name of the record.
			// Not to be confused with the _target_ of the record, which is--in combination with the port--what we're looking up
			// by making this request in the first place.

			// NOTE(Jeroen): Service Name and Protocol Name can probably just be string slices into the record name.
			// It's already cloned, after all. I wouldn't put them on the temp allocator like this.

			parts := strings.split_n(srv_record_name, ".", 3, context.temp_allocator)
			if len(parts) != 3 {
				return
			}
			service_name, protocol_name := parts[0], parts[1]

			_record = DNS_Record_SRV{
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				target        = target,
				service_name  = service_name,
				protocol_name = protocol_name,
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
				base = DNS_Record_Base{
					record_name = strings.clone(srv_record_name),
					ttl_seconds = u32(record_hdr.ttl),
				},
				host_name  = hostname,
				preference = int(preference),
			}

		case:
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
	context.allocator = allocator

	HEADER_SIZE_BYTES :: 12
	if len(response) < HEADER_SIZE_BYTES {
		return
	}

	_records := make([dynamic]DNS_Record, 0)

	dns_hdr_chunks := mem.slice_data_cast([]u16be, response[:HEADER_SIZE_BYTES])
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

	cur_idx := HEADER_SIZE_BYTES

	for _ in 0..<question_count {
		if cur_idx == len(response) {
			continue
		}

		dq_sz :: 4
		hn_sz := skip_hostname(response, cur_idx) or_return

		cur_idx += hn_sz + dq_sz
	}

	for _ in 0..<answer_count {
		if cur_idx == len(response) {
			continue
		}

		rec := parse_record(response, &cur_idx, filter) or_return
		if rec != nil {
			append(&_records, rec)
		}
	}

	for _ in 0..<authority_count {
		if cur_idx == len(response) {
			continue
		}

		rec := parse_record(response, &cur_idx, filter) or_return
		if rec != nil {
			append(&_records, rec)
		}
	}

	for _ in 0..<additional_count {
		if cur_idx == len(response) {
			continue
		}

		rec := parse_record(response, &cur_idx, filter) or_return
		if rec != nil {
			append(&_records, rec)
		}
	}

	return _records[:], true
}
