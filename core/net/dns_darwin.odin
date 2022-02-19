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
import "core:bytes"
import "core:mem"
import "core:time"
import "core:os"
import "core:fmt"

/*
	TODO(cloin): Does the DNS Resolver need to recursively hop through CNAMEs to get the IP
	or is that what recursion desired does? Do we need to handle recursion unavailable?
	How do we deal with is_authoritative / is_truncated?

	TODO(cloin): How do we cache resolv.conf in a threadsafe way?

	TODO(cloin): Handle more record types
*/

name_max  :: 255

@private
_pack_dns_header :: proc(hdr: DNS_Header) -> (id: u16be, bits: u16be) {
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

@private
_unpack_dns_header :: proc(id: u16be, bits: u16be) -> (hdr: DNS_Header) {
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

@private
_load_resolv_conf :: proc(allocator := context.allocator) -> (dns_servers: []string, ok: bool) {
	context.allocator = allocator

	res, success := os.read_entire_file_from_filename("/etc/resolv.conf", allocator)
	if !success {
		return
	}
	defer delete(res)

	_dns_servers := make([dynamic]string, 0, allocator)
	resolv_str := string(res)
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

		append(&_dns_servers, server_ip_str)
	}

	return _dns_servers[:], true
}

@private
_load_hosts :: proc(allocator := context.allocator) -> (hosts: []DNS_Host_Entry, ok: bool) {
	context.allocator = allocator

	res, success := os.read_entire_file_from_filename("/etc/hosts", allocator)
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

		name_str := splits[1]
		if len(name_str) == 0 {
			continue
		}

		append(&_hosts, DNS_Host_Entry{name_str, addr})
	}

	return _hosts[:], true
}

/*
	www.google.com -> 3www6google3com0
*/
@private
_encode_hostname :: proc(b: ^strings.Builder, hostname: string, allocator := context.allocator) -> (ok: bool) {
	
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

@private
_decode_hostname :: proc(packet: []u8, start_idx: int, allocator := context.allocator) -> (hostname: string, encode_size: int, ok: bool) {
	output := [name_max]u8{}
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

			if print_size + label_size + 1 > name_max {
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

	return strings.clone(strings.to_string(b)), out_size, true
}

// Uses RFC 952 & RFC 1123
@private
_validate_hostname :: proc(hostname: string) -> (ok: bool) {
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

@private
_parse_record :: proc(packet: []u8, cur_off: ^int, filter: DNS_Record_Type = nil) -> (record: DNS_Record, ok: bool) {
	record_buf := packet[cur_off^:]
	hostname, hn_sz := _decode_hostname(packet, cur_off^) or_return

	ahdr_sz := size_of(DNS_Record_Header)
	if len(record_buf) - hn_sz < ahdr_sz {
		return
	}

	record_hdr_bytes := record_buf[hn_sz:hn_sz+ahdr_sz]
	record_hdr := cast(^DNS_Record_Header)raw_data(record_hdr_bytes)

	data_sz := record_hdr.length
	data_off := cur_off^ + int(hn_sz) + int(ahdr_sz);
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
			hostname, _ := _decode_hostname(packet, data_off) or_return
			_record = DNS_Record_CNAME(hostname)
		case .NS:
			name, _ := _decode_hostname(packet, data_off + (size_of(u16be) * 3)) or_return
			_record = DNS_Record_NS(name)
		case .SRV:
			if len(data) <= 6 {
				return
			}

			priority: u16be = mem.slice_data_cast([]u16be, data)[0]
			weight:   u16be = mem.slice_data_cast([]u16be, data)[1]
			port:     u16be = mem.slice_data_cast([]u16be, data)[2]
			name, _ := _decode_hostname(packet, data_off + (size_of(u16be) * 3)) or_return
			_record = DNS_Record_SRV{
				priority = int(priority),
				weight   = int(weight),
				port     = int(port),
				service_name = name,
			}
		case .MX:
			if len(data) <= 2 {
				return
			}

			preference: u16be = mem.slice_data_cast([]u16be, data)[0]
			hostname, _ := _decode_hostname(packet, data_off + size_of(u16be)) or_return
			_record = DNS_Record_MX{
				host       = hostname,
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

@private
_parse_response :: proc(response: []u8, filter: DNS_Record_Type = nil, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
	header_size_bytes :: 12
	if len(response) < header_size_bytes {
		return
	}

	_records := make([dynamic]DNS_Record, 0) 

	dns_hdr_chunks := mem.slice_data_cast([]u16be, response[:header_size_bytes]) 
	hdr := _unpack_dns_header(dns_hdr_chunks[0], dns_hdr_chunks[1])
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
		hostname, hn_sz := _decode_hostname(response, cur_idx) or_return
		DNS_Query := mem.slice_data_cast([]u16be, response[cur_idx+hn_sz:cur_idx+hn_sz+dq_sz])

		cur_idx += hn_sz + dq_sz
	}

	for i := 0; i < answer_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := _parse_record(response, &cur_idx, filter) or_return
		if rec == nil {
			continue
		}

		append(&_records, rec)
	}

	for i := 0; i < authority_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := _parse_record(response, &cur_idx, filter) or_return
		if rec == nil {
			continue
		}

		append(&_records, rec)
	}

	for i := 0; i < additional_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := _parse_record(response, &cur_idx, filter) or_return
		if rec == nil {
			continue
		}

		append(&_records, rec)
	}
	
	return _records[:], true
}

// Performs a recursive DNS query for records of a particular type for the hostname.
//
// NOTE: This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
// meaning that DNS queries for a hostname will resolve through CNAME records until an
// IP Address is reached.
//
get_dns_records :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
	context.allocator = allocator

	dns_servers := _load_resolv_conf() or_return
	defer delete(dns_servers)
	if len(dns_servers) == 0 {
		return
	}

	hosts := _load_hosts() or_return
	defer delete(hosts)
	if len(hosts) == 0 {
		return
	}

	host_records := make([dynamic]DNS_Record, 0)
	for host in hosts {
		if strings.compare(host.name, hostname) == 0 {
			if type == .IPv4 && family_from_address(host.addr) == .IPv4 {
				addr4 := cast(DNS_Record_IPv4)host.addr.(IPv4_Address)
				append(&host_records, addr4)
			} else if type == .IPv6 && family_from_address(host.addr) == .IPv6 {
				addr6 := cast(DNS_Record_IPv6)host.addr.(IPv6_Address)
				append(&host_records, addr6)
			}
		}
	}
	if len(host_records) > 0 {
		return host_records[:], true
	}

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

	DNS_Query := [2]u16be{ u16be(type), 1 }

	output := [(size_of(u16be) * 6) + name_max + (size_of(u16be) * 2)]u8{}
	b := strings.builder_from_slice(output[:])

	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_hdr[:]))
	_encode_hostname(&b, hostname) or_return
	strings.write_bytes(&b, mem.slice_data_cast([]u8, DNS_Query[:]))

	dns_packet := output[:strings.builder_len(b)]

	dns_response_buf := [4096]u8{}
	dns_response: []u8
	for dns_server in dns_servers {
		addr := parse_address(dns_server)
		if addr == nil {
			return
		}

		conn, sock_err := make_unbound_udp_socket(family_from_address(addr))
		if sock_err != nil {
			fmt.printf("here\n")
			return
		}
		defer close(conn)

		dns_addr := Endpoint{addr, 53}
		send_sz, send_err := send(conn, dns_packet[:], dns_addr)
		if send_err != nil {
			fmt.printf("here2 %v\n", send_err)
			continue
		}

		set_err := set_option(conn, .Receive_Timeout, time.Second)
		if set_err != nil {
			fmt.printf("here3\n")
			return
		}

		recv_sz, recv_addr, recv_err := recv_udp(conn, dns_response_buf[:])
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
