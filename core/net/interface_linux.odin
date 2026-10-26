#+build linux
#+private file
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

import "core:c"
import "core:mem"
import "core:strings"
import "core:sys/linux"

Ifs :: map[c.int]Network_Interface

// from /usr/include/linux/netlink.h
nlmsghdr :: struct {
	nlmsg_len:            u32,
	nlmsg_type:           u16,
	nlmsg_flags:          NLM_Flags,
	nlmsg_seq, nlmsg_pid: u32,
}

NLMSG :: enum u16 {
	NOOP = 1,
	ERROR,
	DONE,
	OVERRUN,
}

NLM_Flag :: enum {
	REQUEST,
	MULTI,
	ACK,
	ECHO,
	DUMP_INTR,
	DUMP_FILTERED,
	ROOT = 8,
	MATCH,
	ATOMIC,
}
NLM_Flags :: bit_set[NLM_Flag;c.ushort]
NLM_F_DUMP :: NLM_Flags{.ROOT, .MATCH}

// from /usr/include/linux/if_link.h
IFLA :: enum u16 {
	UNSPEC,
	ADDRESS,
	BROADCAST,
	IFNAME,
	MTU,
	LINK,
	QDISC,
	STATS,
	PERM_ADDRESS,
}

// from /usr/include/linux/if_addr.h
ifaddrmsg :: struct {
	fa_family:                        AF,
	fa_prefixlen, fa_flags, fa_scope: u8,
	fa_index:                         u32,
}

IFA :: enum u16 {
	UNSPEC,
	ADDRESS,
	LOCAL,
	LABEL,
	BROADCAST,
	ANYCAST,
	CACHEINFO,
}

Ifs :: map[c.int]Network_Interface

// from /usr/include/net/if.h
IFF :: enum {
	UP,
	BROADCAST,
	DEBUG,
	LOOPBACK,
	POINTOPOINT,
	RUNNING,
	NOARP,
	PROMISC,
	NOTRAILERS,
	ALLMULTI,
	MASTER,
	SLAVE,
	MULTICAST,
	PORTSEL,
	AUTOMEDIA,
	DYNAMIC,
	LOWER_UP,
	DORMANT,
	ECHO,
}
IFF_Flags :: bit_set[IFF;c.uint]

// from /usr/include/linux/rtnetlink.h
ifinfomsg :: struct {
	ifi_family: AF,
	__ifi_pad:  u8,
	ifi_type:   c.ushort,
	ifi_index:  c.int,
	ifi_flags:  IFF_Flags,
	ifi_change: c.uint,
}

rtgenmsg :: struct {
	rtgen_family: AF,
}

rtattr :: struct {
	rta_len, rta_type: c.ushort,
}

RTM :: enum {
	NEWLINK = 16,
	GETLINK = 18,
	NEWADDR = 20,
	GETADDR = 22,
	// ...
}

// from /usr/include/bits/socket.h
AF :: enum u8 {
	UNSPEC,
	INET = 2,
	INET6 = 10,
	// ...
}

_nlmsg_align :: #force_inline proc(#any_int len: uintptr) -> uintptr {
	NLMSG_ALIGNTO :: uintptr(4)
	// return (len + NLMSG_ALIGNTO - 1) & ~(NLMSG_ALIGNTO - 1)
	return mem.align_forward_uintptr(len, NLMSG_ALIGNTO)
}

_rta_align :: _nlmsg_align

_buffer_after :: #force_inline proc(header: ^$T) -> [^]byte {
	return transmute([^]byte)(uintptr(header) + size_of(T))
}

_buffer_end :: #force_inline proc(slice: []byte) -> uintptr {
	return uintptr(raw_data(slice)) + uintptr(len(slice))
}

_nlmsg_payload :: #force_inline proc(nlh: ^nlmsghdr) -> []byte {
	return _buffer_after(nlh)[:nlh.nlmsg_len - size_of(nlmsghdr)]
}

_nlmsg_iter :: proc(iter: ^^nlmsghdr, buf: []u8) -> (h: ^nlmsghdr, cont: bool) {
	if iter^ == nil {
		iter^ = transmute(^nlmsghdr)raw_data(buf)
	} else {
		iter^ = transmute(^nlmsghdr)(uintptr(iter^) + _nlmsg_align(iter^.nlmsg_len))
	}
	(_buffer_end(buf) >= size_of(nlmsghdr) + uintptr(iter^)) or_return
	return iter^, true
}

_rta_iter :: proc(
	iter: ^^rtattr,
	nlh: ^nlmsghdr,
	len: uintptr,
	$rta_types: typeid,
) -> (
	type: rta_types,
	data: []u8,
	cont: bool,
) where size_of(rta_types) ==
	size_of(c.ushort) {
	if iter^ == nil {
		iter^ = transmute(^rtattr)(uintptr(nlh) + size_of(nlmsghdr) + _rta_align(len))
	} else {
		iter^ = transmute(^rtattr)(uintptr(iter^) + _rta_align(iter^.rta_len))
	}
	(_buffer_end(_nlmsg_payload(nlh)) >= size_of(rtattr) + uintptr(iter^)) or_return
	return transmute(rta_types)iter^.rta_type, _rta_payload(iter^), true
}

_rta_payload :: #force_inline proc(rta: ^rtattr) -> []byte {
	return _buffer_after(rta)[:rta.rta_len - size_of(rtattr)]
}

Nlmsghdr_Callback :: struct($T: typeid) {
	fn:  proc(ctx: ^T, h: ^nlmsghdr) -> linux.Errno,
	ctx: ^T,
}

_netlink_enumerate :: proc(
	fd: linux.Fd,
	seq: u32,
	type: u16,
	cb: Nlmsghdr_Callback($T),
) -> linux.Errno {
	Request :: struct {
		header: nlmsghdr,
		msg:    rtgenmsg,
	}

	req := Request {
		header = {
			nlmsg_len = size_of(Request),
			nlmsg_type = type,
			nlmsg_flags = NLM_F_DUMP | {.REQUEST},
			nlmsg_seq = seq,
		},
		msg = {rtgen_family = .UNSPEC},
	}

	written := linux.send(fd, mem.any_to_bytes(req), {}) or_return

	buf: [8192]byte
	for {
		read := linux.recv(fd, buf[:], {.DONTWAIT}) or_return
		iter: ^nlmsghdr
		for h in _nlmsg_iter(&iter, buf[:read]) {
			#partial switch NLMSG(h.nlmsg_type) {
			case .DONE:
				return .NONE
			case .ERROR:
				err := -_read_T(_nlmsg_payload(h), linux.Errno)
				return linux.Errno(err)
			case:
				cb.fn(cb.ctx, h) or_return
			}
		}
	}
	return .NONE
}

_rtnetlink_enumerate :: proc(cb: Nlmsghdr_Callback($T)) -> linux.Errno {
	fd := linux.socket(.NETLINK, .RAW, {.CLOEXEC}, nil) or_return
	defer linux.close(fd)

	_netlink_enumerate(fd, 1, u16(RTM.GETLINK), cb) or_return
	_netlink_enumerate(fd, 2, u16(RTM.GETADDR), cb) or_return

	return .NONE
}

_mac_to_string :: proc(mac: [6]u8, allocator := context.allocator) -> string {
	return fmt.aprintf(
		"{:02x}:{:02x}:{:02x}:{:02x}:{:02x}:{:02x}",
		mac[0],
		mac[1],
		mac[2],
		mac[3],
		mac[4],
		mac[5],
		allocator = allocator,
	)
}

// reinterpret_copy first bytes as T
_read_T :: proc(slice: []byte, $T: typeid) -> T {
	assert(size_of(T) <= len(slice))
	return mem.reinterpret_copy(T, raw_data(slice))
}

_flags_to_link_state :: proc(flags: IFF_Flags) -> (state: Link_State) {
	/*
		TODO: Refine this based on the type of adapter.
	*/
	if .UP in flags do state += {.Up}
	else do state += {.Down}
	if .DORMANT in flags do state += {.Dormant}
	if .LOWER_UP not_in flags do state += {.Lower_Layer_Down}
	if .LOOPBACK in flags do state += {.Loopback}
	return
}

_handle_newlink :: proc(ifs: ^Ifs, h: ^nlmsghdr) {
	ifi := _read_T(_nlmsg_payload(h), ifinfomsg)

	ifs[ifi.ifi_index] = {
		unicast = make([dynamic]Lease),
		link = {state = _flags_to_link_state(ifi.ifi_flags)},
	}

	// we can do this because we add elements only in the previous line
	ifs0 := &ifs[ifi.ifi_index]

	iter: ^rtattr
	for type, data in _rta_iter(&iter, h, size_of(ifinfomsg), IFLA) {
		#partial switch type {
		case .IFNAME:
			ifs0.adapter_name = strings.clone_from(data[:len(data) - 1])
		case .ADDRESS:
			ifs0.physical_address = _mac_to_string(_read_T(data, [6]byte))
		case .MTU:
			ifs0.mtu = _read_T(data, c.uint)
		// there could be something interesting in `case .STATS:`
		}
	}
}

_handle_newaddr :: proc(ifs: ^Ifs, h: ^nlmsghdr) -> bool {
	to_addr :: proc(bytes: []u8, af: AF) -> Address {
		#partial switch af {
		case .INET:
			return _read_T(bytes, IP4_Address)
		case .INET6:
			return _read_T(bytes, IP6_Address)
		case:
			return nil
		}
	}

	prefix_to_netmask :: proc(prefixlen: u8, family: AF) -> Netmask {
		#partial switch family {
		case .INET:
			return transmute(IP4_Address)(~((u32be(1) << (32 - prefixlen)) - 1))
		case .INET6:
			return transmute(IP6_Address)(~((u128be(1) << (128 - prefixlen)) - 1))
		}
		assert(false)
		return nil
	}

	ifa := _read_T(_nlmsg_payload(h), ifaddrmsg)
	ifs0 := (&ifs[c.int(ifa.fa_index)]) or_return

	iter: ^rtattr
	lease: Lease
	for type, data in _rta_iter(&iter, h, size_of(ifaddrmsg), IFA) {
		#partial switch type {
		case .ADDRESS:
			lease.address = to_addr(data, ifa.fa_family)
		case .LABEL:
			if ifs0.adapter_name == "" {
				ifs0.adapter_name = strings.clone_from(data[:len(data) - 1])
			}
		case .BROADCAST:
			append(&ifs0.multicast, to_addr(data, ifa.fa_family))
		}
	}
	lease.netmask = prefix_to_netmask(ifa.fa_prefixlen, ifa.fa_family)
	append(&ifs0.unicast, lease)
	return true
}

_parse_nlmsg :: proc(ifs: ^Ifs, h: ^nlmsghdr) -> linux.Errno {
	#partial switch RTM(h.nlmsg_type) {
	case .NEWLINK:
		_handle_newlink(ifs, h)
	case .NEWADDR:
		if !_handle_newaddr(ifs, h) do return .EPROTO
	case:
		panic("the netlink request got an unsupported nlmsg_type")
	}
	return .NONE
}

@(private)
_enumerate_interfaces :: proc(
	allocator := context.allocator,
) -> (
	interfaces: []Network_Interface,
	err: Interfaces_Error,
) {
	context.allocator = allocator

	/*
	 * Interfaces are id-ed with their idx since it is easier to get
	 * from `nlmsghdr` messages
	 */
	idx_to_interface := make(Ifs)
	defer delete(idx_to_interface)

	/*
	 * Use rtnetlink to enumerate interfaces, the callback will populate
	 * `idx_to_interface` incrementally
	 */
	if err := _rtnetlink_enumerate(
		&idx_to_interface,
		_handle_newlink,
		_handle_newaddr,
		_handle_newroute,
	); err != .NONE {
		if err := _rtnetlink_enumerate(Nlmsghdr_Callback(Ifs){_parse_nlmsg, &idx_to_interface});
		   err != .NONE {
			return nil, Interfaces_Error.Unable_To_Enumerate_Network_Interfaces
		}

		// Dump the interfaces into a slice
		// NOTE: the order isn't stable
		interfaces = make([]Network_Interface, len(idx_to_interface))
		idx := 0
		for _, intf in idx_to_interface {
			interfaces[idx] = intf
			idx += 1
		}
		return
	}
}

// from /usr/include/linux/netlink.h
nlmsghdr :: struct {
	nlmsg_len:            u32,
	nlmsg_type:           u16,
	nlmsg_flags:          NLM_Flags,
	nlmsg_seq, nlmsg_pid: u32,
}

NLMSG :: enum u16 {
	NOOP = 1,
	ERROR,
	DONE,
	OVERRUN,
}

NLM_FLAG :: enum {
	REQUEST,
	MULTI,
	ACK,
	ECHO,
	DUMP_INTR,
	DUMP_FILTERED,
	ROOT = 8,
	MATCH,
	ATOMIC,
}
NLM_Flags :: bit_set[NLM_FLAG;c.ushort]
NLM_F_DUMP :: NLM_Flags{.ROOT, .MATCH}

// from /usr/include/net/if.h
IFF :: enum {
	UP,
	BROADCAST,
	DEBUG,
	LOOPBACK,
	POINTOPOINT,
	RUNNING,
	NOARP,
	PROMISC,
	NOTRAILERS,
	ALLMULTI,
	MASTER,
	SLAVE,
	MULTICAST,
	PORTSEL,
	AUTOMEDIA,
	DYNAMIC,
	LOWER_UP,
	DORMANT,
	ECHO,
}
IFF_Flags :: bit_set[IFF;c.uint]

// from /usr/include/linux/rtnetlink.h
rtgenmsg :: struct {
	rtgen_family: AF,
}

rtattr :: struct {
	rta_len, rta_type: c.ushort,
}

RTM :: enum {
	NEWLINK  = 16,
	GETLINK  = 18,
	NEWADDR  = 20,
	GETADDR  = 22,
	NEWROUTE = 24,
	GETROUTE = 26,
	// ...
}

// from /usr/include/bits/socket.h
AF :: enum u8 {
	UNSPEC,
	INET = 2,
	INET6 = 10,
	// ...
}

_nlmsg_align :: #force_inline proc(#any_int len: uintptr) -> uintptr {
	NLMSG_ALIGNTO :: uintptr(4)
	// return (len + NLMSG_ALIGNTO - 1) & ~(NLMSG_ALIGNTO - 1)
	return mem.align_forward_uintptr(len, NLMSG_ALIGNTO)
}

_rta_align :: _nlmsg_align

_buffer_after :: #force_inline proc(header: ^$T) -> [^]byte {
	return transmute([^]byte)(uintptr(header) + size_of(T))
}

_buffer_end :: #force_inline proc(slice: []byte) -> uintptr {
	return uintptr(raw_data(slice)) + uintptr(len(slice))
}

_nlmsg_payload :: #force_inline proc(nlh: ^nlmsghdr) -> []byte {
	return _buffer_after(nlh)[:nlh.nlmsg_len - size_of(nlmsghdr)]
}

_nlmsg_iter :: proc(iter: ^^nlmsghdr, buf: []u8) -> (h: ^nlmsghdr, cont: bool) {
	if iter^ == nil {
		iter^ = transmute(^nlmsghdr)raw_data(buf)
	} else {
		iter^ = transmute(^nlmsghdr)(uintptr(iter^) + _nlmsg_align(iter^.nlmsg_len))
	}
	(_buffer_end(buf) >= size_of(nlmsghdr) + uintptr(iter^)) or_return
	return iter^, true
}

_rta_iter :: proc(
	iter: ^^rtattr,
	nlh: ^nlmsghdr,
	len: uintptr,
	$rta_types: typeid,
) -> (
	type: rta_types,
	data: []u8,
	cont: bool,
) where size_of(rta_types) ==
	size_of(c.ushort) {
	if iter^ == nil {
		iter^ = transmute(^rtattr)(uintptr(nlh) + size_of(nlmsghdr) + _rta_align(len))
	} else {
		iter^ = transmute(^rtattr)(uintptr(iter^) + _rta_align(iter^.rta_len))
	}
	(_buffer_end(_nlmsg_payload(nlh)) >= size_of(rtattr) + uintptr(iter^)) or_return
	return transmute(rta_types)iter^.rta_type, _rta_payload(iter^), true
}

_rta_payload :: #force_inline proc(rta: ^rtattr) -> []byte {
	return _buffer_after(rta)[:rta.rta_len - size_of(rtattr)]
}

Nlmsghdr_Callback :: proc(ifs: ^Ifs, h: ^nlmsghdr) -> linux.Errno

_netlink_enumerate :: proc(
	fd: linux.Fd,
	seq: u32,
	type: u16,
	cb: Nlmsghdr_Callback,
	ifs: ^Ifs,
) -> linux.Errno {
	Request :: struct {
		header: nlmsghdr,
		msg:    rtgenmsg,
	}

	req := Request {
		header = {
			nlmsg_len = size_of(Request),
			nlmsg_type = type,
			nlmsg_flags = NLM_F_DUMP | {.REQUEST},
			nlmsg_seq = seq,
		},
		msg = {rtgen_family = .UNSPEC},
	}

	written := linux.send(fd, mem.any_to_bytes(req), {}) or_return

	buf: [8192]byte
	for {
		read := linux.recv(fd, buf[:], {.DONTWAIT}) or_return
		iter: ^nlmsghdr
		for h in _nlmsg_iter(&iter, buf[:read]) {
			#partial switch NLMSG(h.nlmsg_type) {
			case .DONE:
				return .NONE
			case .ERROR:
				err := -_read_T(_nlmsg_payload(h), linux.Errno)
				return linux.Errno(err)
			case:
				cb(ifs, h) or_return
			}
		}
	}
	return .NONE
}

_rtnetlink_enumerate :: proc(
	ifs: ^Ifs,
	newlink_cb, newaddr_cb, newroute_cb: Nlmsghdr_Callback,
) -> linux.Errno {
	fd := linux.socket(.NETLINK, .RAW, {.CLOEXEC}, nil) or_return
	defer linux.close(fd)

	_netlink_enumerate(fd, 1, u16(RTM.GETLINK), newlink_cb, ifs) or_return
	_netlink_enumerate(fd, 2, u16(RTM.GETADDR), newaddr_cb, ifs) or_return
	_netlink_enumerate(fd, 3, u16(RTM.GETROUTE), newroute_cb, ifs) or_return

	return .NONE
}

// reinterpret_copy first bytes as T
_read_T :: proc(slice: []byte, $T: typeid) -> T {
	assert(size_of(T) <= len(slice))
	return mem.reinterpret_copy(T, raw_data(slice))
}

_flags_to_link_state :: proc(flags: IFF_Flags) -> (state: Link_State) {
	/*
		TODO: Refine this based on the type of adapter.
	*/
	if .UP in flags do state += {.Up}
	else do state += {.Down}
	if .DORMANT in flags do state += {.Dormant}
	if .LOWER_UP not_in flags do state += {.Lower_Layer_Down}
	if .LOOPBACK in flags do state += {.Loopback}
	return
}

_handle_newlink: Nlmsghdr_Callback : proc(ifs: ^Ifs, h: ^nlmsghdr) -> linux.Errno {
	// from /usr/include/linux/rtnetlink.h
	ifinfomsg :: struct {
		ifi_family: AF,
		__ifi_pad:  u8,
		ifi_type:   c.ushort,
		ifi_index:  c.int,
		ifi_flags:  IFF_Flags,
		ifi_change: c.uint,
	}

	// from /usr/include/linux/if_link.h
	IFLA :: enum u16 {
		UNSPEC,
		ADDRESS,
		BROADCAST,
		IFNAME,
		MTU,
		LINK,
		QDISC,
		STATS,
		PERM_ADDRESS,
	}


	if RTM(h.nlmsg_type) != .NEWLINK do return .EPROTO
	ifi := _read_T(_nlmsg_payload(h), ifinfomsg)

	ifs[ifi.ifi_index] = {
		unicast = make([dynamic]Lease),
		link = {state = _flags_to_link_state(ifi.ifi_flags)},
	}

	// we can do this because we add elements only in the previous line
	ifs0 := &ifs[ifi.ifi_index]

	iter: ^rtattr
	for type, data in _rta_iter(&iter, h, size_of(ifinfomsg), IFLA) {
		#partial switch type {
		case .IFNAME:
			ifs0.adapter_name = strings.clone_from(data[:len(data) - 1])
		case .ADDRESS:
			ifs0.physical_address = physical_address_to_string(data[:6])
		case .MTU:
			ifs0.mtu = _read_T(data, c.uint)
		// there could be something interesting in `case .STATS:`
		}
	}

	return .NONE
}

_to_addr :: proc(bytes: []u8, af: AF) -> Address {
	#partial switch af {
	case .INET:
		return _read_T(bytes, IP4_Address)
	case .INET6:
		return _read_T(bytes, IP6_Address)
	case:
		return nil
	}
}

_handle_newaddr: Nlmsghdr_Callback : proc(ifs: ^Ifs, h: ^nlmsghdr) -> linux.Errno {

	prefix_to_netmask :: proc(prefixlen: u8, family: AF) -> Netmask {
		#partial switch family {
		case .INET:
			return transmute(IP4_Address)(~((u32be(1) << (32 - prefixlen)) - 1))
		case .INET6:
			return transmute(IP6_Address)(~((u128be(1) << (128 - prefixlen)) - 1))
		}
		assert(false)
		return nil
	}

	// from /usr/include/linux/if_addr.h
	ifaddrmsg :: struct {
		fa_family:                        AF,
		fa_prefixlen, fa_flags, fa_scope: u8,
		fa_index:                         u32,
	}

	IFA :: enum u16 {
		UNSPEC,
		ADDRESS,
		LOCAL,
		LABEL,
		BROADCAST,
		ANYCAST,
		CACHEINFO,
	}


	if RTM(h.nlmsg_type) != .NEWADDR do return .EPROTO

	ifa := _read_T(_nlmsg_payload(h), ifaddrmsg)
	ifs0, ok := &ifs[c.int(ifa.fa_index)]

	if !ok {
		// this branch is a last resort, interfaces should first be created by
		// a .NEWLINK nlmsghdr
		ifs[c.int(ifa.fa_index)] = {
			unicast = make([dynamic]Lease),
		}
		ifs0 = &ifs[c.int(ifa.fa_index)]
	}

	iter: ^rtattr
	lease: Lease
	for type, data in _rta_iter(&iter, h, size_of(ifaddrmsg), IFA) {
		#partial switch type {
		case .ADDRESS:
			lease.address = _to_addr(data, ifa.fa_family)
		case .LABEL:
			if ifs0.adapter_name == "" {
				ifs0.adapter_name = strings.clone_from(data[:len(data) - 1])
			}
		/*
		 * we can read broadcast addresses from the GETROUTE netlink request
		 * case .BROADCAST:
		 * 	append(&ifs0.multicast, _to_addr(data, ifa.fa_family))
		*/
		}
	}
	lease.netmask = prefix_to_netmask(ifa.fa_prefixlen, ifa.fa_family)
	append(&ifs0.unicast, lease)
	return .NONE
}

_handle_newroute: Nlmsghdr_Callback : proc(ifs: ^Ifs, h: ^nlmsghdr) -> linux.Errno {
	// from /usr/include/linux/rtnetlink.h
	RTN :: enum u8 {
		UNSPEC,
		UNICAST,
		LOCAL,
		BROADCAST,
		// we could get a bit more info if we use .ANYCAST and .MULTICAST properly
		ANYCAST,
		MULTICAST,
		BLACKHOLE,
		UNREACHABLE,
		PROHIBIT,
		THROW,
		NAT,
		XRESOLVE,
	}

	rtmsg :: struct {
		rtm_family:                      AF,
		rtm_dst_len:                     u8,
		rtm_src_len, rtm_tos, rtm_table: u8,
		// rtm_prot can be RTPROT_DHCP (16), which signals that it's
		// coming from a dhcp client, might be useful
		rtm_protocol, rtm_scope:         u8,
		rtm_type:                        RTN,
		rtm_flags:                       u32, // RTM_Flags,
	}

	RTA :: enum u16 {
		UNSPEC,
		DST,
		SRC,
		IIF,
		OIF,
		GATEWAY,
		PRIORITY,
		PREFSRC,
		METRICS,
		MULTIPATH,
		PROTOINFO,
		FLOW,
		CACHEINFO,
		SESSION,
		MP_ALGO,
		TABLE,
		MARK,
		MFC_STATS,
		VIA,
		NEWDST,
		PREF,
		ENCAP_TYPE,
		ENCAP,
		EXPIRES,
	}


	msg := _read_T(_nlmsg_payload(h), rtmsg)

	iter: ^rtattr
	gateways := make([dynamic]Address)
	defer delete(gateways)
	broadcasts := make([dynamic]Address)
	defer delete(broadcasts)
	intf_idx: Maybe(i32) = nil

	for type, data in _rta_iter(&iter, h, size_of(rtmsg), RTA) {
		#partial switch type {
		case .DST:
			if msg.rtm_type == .BROADCAST {
				append(&broadcasts, _to_addr(data, msg.rtm_family))
			}
		case .OIF:
			intf_idx = _read_T(data, i32)
		case .GATEWAY:
			append(&gateways, _to_addr(data, msg.rtm_family))
		}
	}

	if intf_idx, ok := intf_idx.(i32); ok {
		ifs0 := &ifs[intf_idx]
		append(&ifs0.gateways, ..gateways[:])
		append(&ifs0.multicast, ..broadcasts[:])
	}

	return .NONE
}
