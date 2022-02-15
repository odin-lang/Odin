package net

import "core:strings"
import "core:bytes"
import "core:mem"

import "core:os"
import "core:fmt"


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



// TODO: Support SRV records.
Dns_Record_Type :: enum u16 {
	Ipv4 = os.DNS_TYPE_A,    // Ipv4 address.
	Ipv6 = os.DNS_TYPE_AAAA, // Ipv6 address.
	Cname = os.DNS_TYPE_CNAME, // Another host name.
	Txt = os.DNS_TYPE_TEXT,  // Arbitrary binary data or text.
	Ns = os.DNS_TYPE_NS,     // Address of a name (DNS) server.
	Mx = os.DNS_TYPE_MX,     // Address and preference priority of a mail exchange server.
	Srv = os.DNS_TYPE_SRV,   // Address, port, priority, and weight of a host that provides a particular service.
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

@private
_pack_dns_header :: proc(hdr: Dns_Header) -> (id: u16be, bits: u16be) {
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
_unpack_dns_header :: proc(id: u16be, bits: u16be) -> (hdr: Dns_Header) {
	hdr.id = id
	hdr.is_response            = (bits & (1 << 15)) != 0
	hdr.opcode                 = (bits >> 11) & 0xF
	hdr.is_authoritative       = (bits & (1 << 10)) != 0
	hdr.is_truncated           = (bits & (1 <<  9)) != 0
	hdr.is_recursion_desired   = (bits & (1 <<  8)) != 0
	hdr.is_recursion_available = (bits & (1 <<  7)) != 0
	hdr.response_code = Dns_Response_Code(bits & 0xF)

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
_encode_hostname :: proc(hostname: string, allocator := context.allocator) -> (encoded_name: []u8, ok: bool) {
	encoded_name = make([]u8, len(hostname) + 2)
	b := strings.builder_from_slice(encoded_name)
	
	label_max :: 63
	
	_hostname := hostname
	for section in strings.split_iterator(&_hostname, ".") {
		if len(section) > label_max {
			return
		}

		strings.write_byte(&b, u8(len(section)))
		strings.write_string(&b, section)
	}
	strings.write_byte(&b, 0)

	return encoded_name, true
}

@private
_decode_hostname :: proc(packet: []u8, start_idx: int, allocator := context.allocator) -> (hostname: string, encode_size: int, ok: bool) {
	b := strings.make_builder()
	defer strings.destroy_builder(&b)

	encoded_name := packet[start_idx:]

	cur_off := 0
	for ;; {
		name_chunk: []u8

		// Branch and pull in name fragment
		if encoded_name[cur_off] == 0xC0 {
			offset := encoded_name[cur_off + 1] 
			name_chunk = packet[offset:]
		} else {
			name_chunk = encoded_name[cur_off:]
		}

		length := name_chunk[0]
		if length == 0 {
			cur_off += 1
			break
		}
		if length > 63 {
			return
		}

		strings.write_bytes(&b, name_chunk[1:length + 1])

		if encoded_name[cur_off] == 0xC0 {
			cur_off += 2
			break
		} else {
			cur_off += int(length) + 1
		}

		if cur_off + 1 == len(encoded_name) {
			break
		}

		strings.write_byte(&b, '.')
	}

	return strings.to_string(b), cur_off, true
}

@private
_parse_record :: proc(packet: []u8, cur_off: ^int) -> (record: Dns_Record, ok: bool) {
	record_buf := packet[cur_off^:]

	hostname, hn_sz := _decode_hostname(packet, cur_off^) or_return

	ahdr_sz := size_of(Dns_Record_Header)
	if len(record_buf) - hn_sz < ahdr_sz {
		return
	}

	record_hdr_bytes := record_buf[hn_sz:hn_sz+ahdr_sz]
	record_hdr := cast(^Dns_Record_Header)raw_data(record_hdr_bytes)

	data_sz := record_hdr.length
	data_off := cur_off^ + int(hn_sz) + int(ahdr_sz);
	data := packet[data_off:data_off+int(data_sz)]
	cur_off^ += int(hn_sz) + int(ahdr_sz) + int(data_sz)

	_record: Dns_Record
	#partial switch Dns_Record_Type(record_hdr.type) {
		case .Ipv4:
			if len(data) != 4 {
				return
			}

			addr_val: u32be = mem.slice_data_cast([]u32be, data)[0]
			addr := Ipv4_Address(transmute([4]u8)addr_val)
			_record = Dns_Record_Ipv4(addr)
		case .Ipv6:
			if len(data) != 16 {
				return
			}

			addr_val: u128be = mem.slice_data_cast([]u128be, data)[0]
			addr := Ipv6_Address(transmute([8]u16be)addr_val)
			_record = Dns_Record_Ipv6(addr)
		case:
			fmt.printf("ignoring %d\n", record_hdr.type)
			return
	}

	return _record, true
}

@private
_parse_response :: proc(response: []u8, allocator := context.allocator) -> (records: [dynamic]Dns_Record, ok: bool) {
	header_size_bytes :: 12
	if len(response) < header_size_bytes {
		return
	}

	_records := make([dynamic]Dns_Record, 0) 

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

		
		hostname, hn_sz := _decode_hostname(response, cur_idx) or_return
		dns_query := mem.slice_data_cast([]u16be, response[cur_idx+hn_sz:cur_idx+hn_sz+4])

		cur_idx += hn_sz + 4
	}

	for i := 0; i < answer_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := _parse_record(response, &cur_idx) or_return
		append(&_records, rec)
	}
	for i := 0; i < authority_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := _parse_record(response, &cur_idx) or_return
		append(&_records, rec)
	}
	for i := 0; i < additional_count; i += 1 {
		if cur_idx == len(response) {
			continue
		}

		rec := _parse_record(response, &cur_idx) or_return
		append(&_records, rec)
	}
	
	return _records, true
}

// Performs a recursive DNS query for records of a particular type for the hostname.
//
// NOTE: This procedure instructs the DNS resolver to recursively perform CNAME requests on our behalf,
// meaning that DNS queries for a hostname will resolve through CNAME records until an
// IP address is reached.
//
// TODO(cloin): Doesn't use the type information to form queries yet
get_dns_records :: proc(hostname: string, type: Dns_Record_Type, allocator := context.allocator) -> (records: []Dns_Record, ok: bool) {
	context.allocator = allocator

	dns_servers := _load_resolv_conf() or_return
	defer delete(dns_servers)
	if len(dns_servers) == 0 {
		return
	}

	hdr := Dns_Header{
		id = 0, 
		is_response = false, 
		opcode = 0, 
		is_authoritative = false, 
		is_truncated = false,
		is_recursion_desired = true,
		is_recursion_available = false,
		response_code = Dns_Response_Code.No_Error,
	}

	id, bits := _pack_dns_header(hdr)

	b := strings.make_builder()
	defer strings.destroy_builder(&b)

	dns_hdr := [6]u16be{}
	dns_hdr[0] = id
	dns_hdr[1] = bits
	dns_hdr[2] = 1

	encoded_name := _encode_hostname(hostname) or_return
	dns_query := [2]u16be{ u16be(type), 1 }

	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_hdr[:]))
	strings.write_bytes(&b, encoded_name)
	strings.write_bytes(&b, mem.slice_data_cast([]u8, dns_query[:]))

	dns_packet := transmute([]u8)strings.to_string(b)

	dns_response_buf := [4096]u8{}
	dns_response: []u8
	for dns_server in dns_servers {
		addr := parse_address(dns_server)
		if addr == nil {
			return
		}

		skaddr := endpoint_to_sockaddr({addr, 53})
		sksize := os.socklen_t(size_of(skaddr))

		conn, err1 := os.socket(os.AF_INET, os.SOCK_DGRAM, os.IPPROTO_UDP)
		if err1 != os.ERROR_NONE {
			return
		}

		send_sz, err2 := os.sendto(conn, dns_packet[:], 0, cast(^os.SOCKADDR)&skaddr, sksize)
		if err2 != os.ERROR_NONE {
			return
		}

		recv_sz, err3 := os.recvfrom(conn, dns_response_buf[:], 0, cast(^os.SOCKADDR)&skaddr, &sksize)
		if err3 != os.ERROR_NONE {
			fmt.printf("recv error: %d\n", err3)
			return
		}

		dns_response = dns_response_buf[:recv_sz]
		os.close(os.Handle(conn))

		if recv_sz == 0 {
			continue
		}

		rsp, _ok := _parse_response(dns_response)
		if !_ok {
			return
		}

		if len(rsp) > 0 {
			return rsp[:], true
		}
	}

	return
}

destroy_dns_records :: proc(records: []Dns_Record, allocator := context.allocator) {
	context.allocator = allocator

	delete(records)
}
