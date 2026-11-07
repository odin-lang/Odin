#+build linux
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
	Made available under Odin's license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code

	This file uses netlink/rtnetlink kernel interfaces to list available network interfaces
*/

import "base:intrinsics"
import "core:strings"
import "core:sys/linux"

@(private="file")
NETLINK_BUFFER_SIZE :: 32768

@(private="file")
NETLINK_ATTRIBUTE_TYPE_MASK :: 0x3fff

@(private="file")
NETLINK_DUMPS :: [?]linux.Netlink_Message_Type{.GETLINK, .GETADDR, .GETROUTE}

@(private="file")
Netlink_Dump_Request :: struct {
	header:  linux.Netlink_Message_Header,
	message: linux.Rtnetlink_Generic_Message,
}

@(private="file")
Interface_Builder :: struct {
	interfaces: [dynamic]Network_Interface,
	positions:  map[i32]int,
}

@(private)
_enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Interfaces_Error) {
	context.allocator = allocator

	fd, errno := linux.socket(.NETLINK, .RAW, {.CLOEXEC}, linux.Protocol(linux.Netlink_Protocol.ROUTE))
	if errno != .NONE {
		return nil, .Unable_To_Enumerate_Network_Interfaces
	}
	defer linux.close(fd)

	buf: [NETLINK_BUFFER_SIZE]u8 = ---
	builder: Interface_Builder
	defer delete(builder.positions)

	seq: u32
	for _ in 0..<MAX_INTERFACE_ENUMERATION_TRIES {
		_destroy_builder(&builder)

		interrupted := false
		for type in NETLINK_DUMPS {
			seq += 1
			dump_interrupted, dump_err := _netlink_dump(fd, buf[:], type, seq, &builder)
			if dump_err != nil {
				_destroy_builder(&builder)
				return nil, dump_err
			}
			if dump_interrupted {
				interrupted = true
			}
		}
		if !interrupted {
			break
		}
	}

	if _, shrink_err := shrink(&builder.interfaces); shrink_err != nil {
		_destroy_builder(&builder)
		return nil, .Allocation_Failure
	}
	return builder.interfaces[:], nil
}

@(private="file")
_netlink_dump :: proc(fd: linux.Fd, buf: []u8, type: linux.Netlink_Message_Type, seq: u32, builder: ^Interface_Builder) -> (interrupted: bool, err: Interfaces_Error) {
	request := Netlink_Dump_Request{
		header = {
			len   = size_of(Netlink_Dump_Request),
			type  = type,
			flags = linux.NLM_F_DUMP + {.REQUEST},
			seq   = seq,
		},
		message = {family = u8(linux.Address_Family.UNSPEC)},
	}
	sent, errno := linux.send(fd, ([^]u8)(&request)[:size_of(request)], {})
	if errno != .NONE || sent != size_of(request) {
		return false, .Unable_To_Enumerate_Network_Interfaces
	}

	for {
		received: int
		received, errno = linux.recv(fd, buf, {.TRUNC})
		if errno == .EINTR {
			continue
		}
		if errno != .NONE || received <= 0 || received > len(buf) {
			return false, .Unable_To_Enumerate_Network_Interfaces
		}

		messages := buf[:received]
		for len(messages) > 0 {
			header, payload, ok := _next_message(&messages)
			if !ok {
				return false, .Unable_To_Enumerate_Network_Interfaces
			}
			if header.seq != seq {
				continue
			}
			if .DUMP_INTR in header.flags {
				interrupted = true
			}

			#partial switch header.type {
			case .DONE:
				status, _ := _read(payload, i32)
				if status < 0 {
					return false, .Unable_To_Enumerate_Network_Interfaces
				}
				return
			case .ERROR:
				return false, .Unable_To_Enumerate_Network_Interfaces
			case .NEWLINK:
				err = _parse_link(payload, builder)
			case .NEWADDR:
				err = _parse_address(payload, builder)
			case .NEWROUTE:
				err = _parse_route(payload, builder)
			}
			if err != nil {
				return false, err
			}
		}
	}
}

@(private="file")
_parse_link :: proc(payload: []u8, builder: ^Interface_Builder) -> Interfaces_Error {
	message, ok := _read(payload, linux.Interface_Info_Message)
	if !ok {
		return .Unable_To_Enumerate_Network_Interfaces
	}

	iface := _add_interface(builder, message.index) or_return
	iface.link.state = _link_state(message.flags)

	attributes := _attributes(payload, size_of(message))
	for type, value in _next_attribute(&attributes) {
		#partial switch linux.Interface_Link_Attribute(type) {
		case .IFNAME:
			name, alloc_err := strings.clone(strings.truncate_to_byte(string(value), 0))
			if alloc_err != nil {
				return .Allocation_Failure
			}
			delete(iface.adapter_name)
			iface.adapter_name = name
		case .ADDRESS:
			delete(iface.physical_address)
			iface.physical_address = physical_address_to_string(value)
		case .MTU:
			iface.mtu, _ = _read(value, u32)
		}
	}
	return _attributes_end(attributes)
}

@(private="file")
_parse_address :: proc(payload: []u8, builder: ^Interface_Builder) -> Interfaces_Error {
	message, ok := _read(payload, linux.Interface_Address_Message)
	if !ok {
		return .Unable_To_Enumerate_Network_Interfaces
	}

	family := linux.Address_Family(message.family)
	iface  := _find_interface(builder, i32(message.index))
	if iface == nil || (family != .INET && family != .INET6) {
		return nil
	}

	address, local, broadcast: Address
	attributes := _attributes(payload, size_of(message))
	for type, value in _next_attribute(&attributes) {
		#partial switch linux.Interface_Address_Attribute(type) {
		case .ADDRESS:
			address = _netlink_address(value, family)
		case .LOCAL:
			local = _netlink_address(value, family)
		case .BROADCAST:
			broadcast = _netlink_address(value, family)
		}
	}
	_attributes_end(attributes) or_return

	if local != nil {
		address = local
	}
	if address == nil {
		return nil
	}

	lease := Lease{
		address = address,
		netmask = _prefix_to_netmask(message.prefixlen, family),
	}
	if _, alloc_err := append(&iface.unicast, lease); alloc_err != nil {
		return .Allocation_Failure
	}
	return _append_unique(&iface.multicast, broadcast)
}

@(private="file")
_parse_route :: proc(payload: []u8, builder: ^Interface_Builder) -> Interfaces_Error {
	message, ok := _read(payload, linux.Route_Message)
	if !ok {
		return .Unable_To_Enumerate_Network_Interfaces
	}

	family := linux.Address_Family(message.family)
	if family != .INET && family != .INET6 {
		return nil
	}
	if message.type != .UNICAST || message.dst_len != 0 || .CLONED in message.flags {
		return nil
	}

	table := linux.Route_Table(message.table)
	gateway: Address
	output: i32
	multipath: []u8

	attributes := _attributes(payload, size_of(message))
	for type, value in _next_attribute(&attributes) {
		#partial switch linux.Route_Attribute(type) {
		case .TABLE:
			if value_table, table_ok := _read(value, linux.Route_Table); table_ok {
				table = value_table
			}
		case .OIF:
			output, _ = _read(value, i32)
		case .GATEWAY:
			gateway = _netlink_address(value, family)
		case .MULTIPATH:
			multipath = value
		}
	}
	_attributes_end(attributes) or_return

	if table != .MAIN {
		return nil
	}
	_add_gateway(builder, output, gateway) or_return

	for len(multipath) > 0 {
		hop, hop_ok := _read(multipath, linux.Route_Next_Hop)
		length := int(hop.len)
		if !hop_ok || length < size_of(hop) || length > len(multipath) {
			return .Unable_To_Enumerate_Network_Interfaces
		}
		hop_attributes := multipath[size_of(hop):length]
		multipath = multipath[min(_netlink_align(length), len(multipath)):]

		hop_gateway: Address
		for type, value in _next_attribute(&hop_attributes) {
			if linux.Route_Attribute(type) == .GATEWAY {
				hop_gateway = _netlink_address(value, family)
			}
		}
		_attributes_end(hop_attributes) or_return
		_add_gateway(builder, hop.ifindex, hop_gateway) or_return
	}
	return nil
}

@(private="file")
_add_interface :: proc(builder: ^Interface_Builder, index: i32) -> (^Network_Interface, Interfaces_Error) {
	if position, found := builder.positions[index]; found {
		return &builder.interfaces[position], nil
	}
	if _, alloc_err := append(&builder.interfaces, Network_Interface{}); alloc_err != nil {
		return nil, .Allocation_Failure
	}
	_, position, _, alloc_err := map_entry(&builder.positions, index)
	if alloc_err != nil {
		return nil, .Allocation_Failure
	}
	position^ = len(builder.interfaces) - 1
	return &builder.interfaces[position^], nil
}

@(private="file")
_find_interface :: proc(builder: ^Interface_Builder, index: i32) -> ^Network_Interface {
	if position, found := builder.positions[index]; found {
		return &builder.interfaces[position]
	}
	return nil
}

@(private="file")
_add_gateway :: proc(builder: ^Interface_Builder, index: i32, gateway: Address) -> Interfaces_Error {
	iface := _find_interface(builder, index)
	if iface == nil {
		return nil
	}
	return _append_unique(&iface.gateways, gateway)
}

@(private="file")
_append_unique :: proc(list: ^[dynamic]Address, address: Address) -> Interfaces_Error {
	if address == nil {
		return nil
	}
	for existing in list {
		if existing == address {
			return nil
		}
	}
	if _, alloc_err := append(list, address); alloc_err != nil {
		return .Allocation_Failure
	}
	return nil
}

@(private="file")
_destroy_builder :: proc(builder: ^Interface_Builder) {
	for iface in builder.interfaces {
		delete(iface.adapter_name)
		delete(iface.physical_address)
		delete(iface.unicast)
		delete(iface.multicast)
		delete(iface.gateways)
	}
	delete(builder.interfaces)
	builder.interfaces = nil
	clear(&builder.positions)
}

@(private="file")
_link_state :: proc(flags: linux.Interface_Flags) -> (state: Link_State) {
	if .UP in flags {
		state += {.Up}
	} else {
		state += {.Down}
	}
	if .DORMANT in flags {
		state += {.Dormant}
	}
	if .LOWER_UP not_in flags {
		state += {.Lower_Layer_Down}
	}
	if .LOOPBACK in flags {
		state += {.Loopback}
	}
	return
}

@(private="file")
_netlink_address :: proc(value: []u8, family: linux.Address_Family) -> Address {
	#partial switch family {
	case .INET:
		if address, ok := _read(value, IP4_Address); ok {
			return address
		}
	case .INET6:
		if address, ok := _read(value, IP6_Address); ok {
			return address
		}
	}
	return nil
}

@(private="file")
_prefix_to_netmask :: proc(prefix: u8, family: linux.Address_Family) -> Netmask {
	#partial switch family {
	case .INET:
		bits := min(u32(prefix), 32)
		mask: u32be
		if bits > 0 {
			mask = ~u32be(0) << (32 - bits)
		}
		return transmute(IP4_Address)mask
	case .INET6:
		bits := min(u32(prefix), 128)
		mask: u128be
		if bits > 0 {
			mask = ~u128be(0) << (128 - bits)
		}
		return transmute(IP6_Address)mask
	}
	return nil
}

@(private="file")
_next_message :: proc(data: ^[]u8) -> (header: linux.Netlink_Message_Header, payload: []u8, ok: bool) {
	header = _read(data^, linux.Netlink_Message_Header) or_return
	length := int(header.len)
	if length < size_of(header) || length > len(data) {
		return
	}
	payload = data[size_of(header):length]
	data^ = data[min(_netlink_align(length), len(data)):]
	return header, payload, true
}

@(private="file")
_next_attribute :: proc(data: ^[]u8) -> (type: u16, value: []u8, ok: bool) {
	header := _read(data^, linux.Rtnetlink_Attribute) or_return
	length := int(header.len)
	if length < size_of(header) || length > len(data) {
		return
	}
	value = data[size_of(header):length]
	data^ = data[min(_netlink_align(length), len(data)):]
	return header.type & NETLINK_ATTRIBUTE_TYPE_MASK, value, true
}

@(private="file")
_attributes :: proc(payload: []u8, header_size: int) -> []u8 {
	return payload[min(_netlink_align(header_size), len(payload)):]
}

@(private="file")
_attributes_end :: proc(attributes: []u8) -> Interfaces_Error {
	if len(attributes) >= size_of(linux.Rtnetlink_Attribute) {
		return .Unable_To_Enumerate_Network_Interfaces
	}
	return nil
}

@(private="file")
_netlink_align :: proc(length: int) -> int {
	return (length + 3) &~ 3
}

@(private="file")
_read :: proc(data: []u8, $T: typeid) -> (value: T, ok: bool) {
	if len(data) < size_of(T) {
		return
	}
	return intrinsics.unaligned_load((^T)(raw_data(data))), true
}
