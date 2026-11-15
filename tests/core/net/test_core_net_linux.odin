#+build linux
package test_core_net

import "base:runtime"
import "core:fmt"
import "core:net"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:testing"

@(test)
test_enumerate_interfaces_invariants :: proc(t: ^testing.T) {
	interfaces, err := net.enumerate_interfaces()
	defer net.destroy_interfaces(interfaces)
	if !testing.expect_value(t, err, nil) {
		return
	}
	testing.expect(t, len(interfaces) > 0, "no interfaces")

	found_loopback := false
	for iface, i in interfaces {
		name := iface.adapter_name
		testing.expectf(t, name != "", "interface %d has no name", i)
		for other in interfaces[i + 1:] {
			testing.expectf(t, name != other.adapter_name, "%q is listed twice", name)
		}
		testing.expectf(t, (.Up in iface.link.state) != (.Down in iface.link.state), "%s: state %v", name, iface.link.state)

		for gateway, j in iface.gateways {
			testing.expectf(t, !has_address(iface.gateways[j + 1:], gateway), "%s: gateway %s is listed twice", name, net.address_to_string(gateway))
		}
		for broadcast, j in iface.multicast {
			testing.expectf(t, !has_address(iface.multicast[j + 1:], broadcast), "%s: broadcast %s is listed twice", name, net.address_to_string(broadcast))
		}

		for lease in iface.unicast {
			_, address_ip4 := lease.address.(net.IP4_Address)
			_, netmask_ip4 := lease.netmask.(net.IP4_Address)
			testing.expectf(t, address_ip4 == netmask_ip4, "%s: %s has netmask %s of another family", name, net.address_to_string(lease.address), net.address_to_string(net.Address(lease.netmask)))

			prefix, contiguous := netmask_prefix(lease.netmask)
			testing.expectf(t, contiguous, "%s: %s has non-contiguous netmask %s", name, net.address_to_string(lease.address), net.address_to_string(net.Address(lease.netmask)))

			if .Loopback in iface.link.state && lease.address == net.Address(net.IP4_Loopback) && prefix == 8 {
				found_loopback = true
			}
		}
	}
	testing.expect(t, found_loopback, "no loopback interface with 127.0.0.1/8")
}

@(test)
test_enumerate_interfaces_matches_kernel :: proc(t: ^testing.T) {
	interfaces, err := net.enumerate_interfaces()
	defer net.destroy_interfaces(interfaces)
	if !testing.expect_value(t, err, nil) {
		return
	}

	dev, dev_ok := read_file("/proc/net/dev")
	if !testing.expect(t, dev_ok, "cannot read /proc/net/dev") {
		return
	}
	names: [dynamic]string
	names.allocator = context.temp_allocator
	for line, i in strings.split_lines(dev, context.temp_allocator) {
		colon := strings.index_byte(line, ':')
		if i < 2 || colon < 0 {
			continue
		}
		append(&names, strings.trim_space(line[:colon]))
	}
	testing.expectf(t, len(interfaces) == len(names), "%d interfaces, /proc/net/dev lists %d", len(interfaces), len(names))

	for name in names {
		iface := find_interface(interfaces, name)
		if !testing.expectf(t, iface != nil, "%s: missing", name) {
			continue
		}

		if mtu, ok := read_number(fmt.tprintf("/sys/class/net/%s/mtu", name)); ok {
			testing.expectf(t, iface.mtu == u32(mtu), "%s: mtu %d, sysfs says %d", name, iface.mtu, mtu)
		}

		if address, ok := read_file(fmt.tprintf("/sys/class/net/%s/address", name)); ok {
			expected := strings.to_upper(strings.trim_space(address), context.temp_allocator)
			testing.expectf(t, iface.physical_address == expected, "%s: physical address %q, sysfs says %q", name, iface.physical_address, expected)
		}

		if flags, ok := read_number(fmt.tprintf("/sys/class/net/%s/flags", name)); ok {
			testing.expectf(t, (flags & 0x1 != 0) == (.Up in iface.link.state), "%s: state %v, sysfs flags %x", name, iface.link.state, flags)
			testing.expectf(t, (flags & 0x8 != 0) == (.Loopback in iface.link.state), "%s: state %v, sysfs flags %x", name, iface.link.state, flags)
		}
	}

	ip6_leases := 0
	for iface in interfaces {
		for lease in iface.unicast {
			if _, is_ip6 := lease.address.(net.IP6_Address); is_ip6 {
				ip6_leases += 1
			}
		}
	}
	if inet6, ok := read_file("/proc/net/if_inet6"); ok {
		lines := 0
		for line in strings.split_lines(inet6, context.temp_allocator) {
			fields := strings.fields(line, context.temp_allocator)
			if len(fields) != 6 {
				continue
			}
			lines += 1

			address, address_ok := parse_ip6(fields[0])
			prefix, prefix_ok := strconv.parse_uint(fields[2], 16)
			iface := find_interface(interfaces, fields[5])
			if !testing.expectf(t, address_ok && prefix_ok && iface != nil, "cannot match /proc/net/if_inet6 line %q", line) {
				continue
			}
			testing.expectf(t, has_lease(iface, address, int(prefix)), "%s: missing %s/%d", fields[5], net.address_to_string(address), prefix)
		}
		testing.expectf(t, ip6_leases == lines, "%d IPv6 addresses, /proc/net/if_inet6 lists %d", ip6_leases, lines)
	} else {
		testing.expectf(t, ip6_leases == 0, "%d IPv6 addresses without /proc/net/if_inet6", ip6_leases)
	}

	if route, ok := read_file("/proc/net/route"); ok {
		for line, i in strings.split_lines(route, context.temp_allocator) {
			fields := strings.fields(line, context.temp_allocator)
			if i == 0 || len(fields) < 8 || fields[1] != "00000000" || fields[7] != "00000000" {
				continue
			}
			flags, _ := strconv.parse_uint(fields[3], 16)
			if flags & 0x3 != 0x3 || flags & 0x200 != 0 {
				continue
			}
			gateway_value, gateway_ok := strconv.parse_uint(fields[2], 16)
			iface := find_interface(interfaces, fields[0])
			if !testing.expectf(t, gateway_ok && iface != nil, "cannot match /proc/net/route line %q", line) {
				continue
			}
			gateway := net.Address(transmute(net.IP4_Address)u32(gateway_value))
			testing.expectf(t, has_gateway(iface, gateway), "%s: missing default gateway %s", fields[0], net.address_to_string(gateway))
		}
	}

	if route6, ok := read_file("/proc/net/ipv6_route"); ok {
		defaults: [dynamic]string
		defaults.allocator = context.temp_allocator
		for line in strings.split_lines(route6, context.temp_allocator) {
			fields := strings.fields(line, context.temp_allocator)
			if len(fields) != 10 || fields[1] != "00" {
				continue
			}
			flags, _ := strconv.parse_uint(fields[8], 16)
			if flags & 0x2 == 0 || flags & 0x200 != 0 || flags & 0x01000000 != 0 {
				continue
			}
			if gateway, gateway_ok := parse_ip6(fields[4]); gateway_ok {
				append(&defaults, fmt.tprintf("%s %v", fields[9], gateway))
			}
		}
		for iface in interfaces {
			for gateway in iface.gateways {
				if _, is_ip6 := gateway.(net.IP6_Address); !is_ip6 {
					continue
				}
				key := fmt.tprintf("%s %v", iface.adapter_name, gateway)
				found := false
				for d in defaults {
					if d == key {
						found = true
					}
				}
				testing.expectf(t, found, "%s: gateway %s is not an IPv6 default route", iface.adapter_name, net.address_to_string(gateway))
			}
		}
	}
}

@(test)
test_enumerate_interfaces_allocation_failures :: proc(t: ^testing.T) {
	for limit in 0..<100_000 {
		failing := Failing_Allocator{backing = context.allocator, limit = limit}
		allocator := runtime.Allocator{failing_allocator_proc, &failing}

		interfaces, err := net.enumerate_interfaces(allocator)
		if err == nil {
			net.destroy_interfaces(interfaces, allocator)
			return
		}
		if !testing.expectf(t, err == .Allocation_Failure, "allocation %d failing gave %v", limit, err) {
			return
		}
	}
	testing.fail_now(t, "enumerate_interfaces never succeeded")
}

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	limit:   int,
}

@(private="file")
failing_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	failing := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if failing.count >= failing.limit {
			return nil, .Out_Of_Memory
		}
		failing.count += 1
	}
	return failing.backing.procedure(failing.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
read_file :: proc(path: string) -> (string, bool) {
	data, err := os.read_entire_file(path, context.temp_allocator)
	return string(data), err == nil
}

@(private="file")
read_number :: proc(path: string) -> (value: u64, ok: bool) {
	text := read_file(path) or_return
	return strconv.parse_u64(strings.trim_space(text))
}

@(private="file")
find_interface :: proc(interfaces: []net.Network_Interface, name: string) -> ^net.Network_Interface {
	for &iface in interfaces {
		if iface.adapter_name == name {
			return &iface
		}
	}
	return nil
}

@(private="file")
has_lease :: proc(iface: ^net.Network_Interface, address: net.Address, prefix: int) -> bool {
	for lease in iface.unicast {
		lease_prefix, _ := netmask_prefix(lease.netmask)
		if lease.address == address && lease_prefix == prefix {
			return true
		}
	}
	return false
}

@(private="file")
has_gateway :: proc(iface: ^net.Network_Interface, gateway: net.Address) -> bool {
	return has_address(iface.gateways[:], gateway)
}

@(private="file")
has_address :: proc(addresses: []net.Address, address: net.Address) -> bool {
	for a in addresses {
		if a == address {
			return true
		}
	}
	return false
}

@(private="file")
parse_ip6 :: proc(hex: string) -> (address: net.Address, ok: bool) {
	if len(hex) != 32 {
		return nil, false
	}
	bytes: [16]u8
	for &b, i in bytes {
		value := strconv.parse_uint(hex[2 * i:][:2], 16) or_return
		b = u8(value)
	}
	return transmute(net.IP6_Address)bytes, true
}

@(private="file")
netmask_prefix :: proc(netmask: net.Netmask) -> (prefix: int, contiguous: bool) {
	bytes: [16]u8
	count := 0
	switch mask in netmask {
	case net.IP4_Address:
		count = 4
		for b, i in mask {
			bytes[i] = b
		}
	case net.IP6_Address:
		count = 16
		bytes = transmute([16]u8)mask
	case:
		return 0, false
	}

	seen_zero := false
	for b in bytes[:count] {
		for bit in 0..<u8(8) {
			if b & (0x80 >> bit) == 0 {
				seen_zero = true
			} else if seen_zero {
				return 0, false
			} else {
				prefix += 1
			}
		}
	}
	return prefix, true
}
