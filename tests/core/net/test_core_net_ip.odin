package test_core_net

import "base:runtime"
import "core:encoding/csv"
import "core:math/rand"
import "core:net"
import "core:strings"
import "core:testing"

IANA_IP4_SPECIAL_REGISTRY :: #load("iana-ipv4-special-registry-1.csv", string)
IANA_IP6_SPECIAL_REGISTRY :: #load("iana-ipv6-special-registry-1.csv", string)

@(test)
test_parse_prefix :: proc(t: ^testing.T) {
	Case :: struct {
		input:    string,
		strict:   bool,
		expected: string,
	}
	cases := []Case{
		{"10.0.0.0/8",               false, "10.0.0.0/8"},
		{"10.0.0.0/8",               true,  "10.0.0.0/8"},
		{"192.168.1.5/24",           false, "192.168.1.5/24"},
		{"192.168.1.5/24",           true,  ""},
		{"0.0.0.0/0",                true,  "0.0.0.0/0"},
		{"255.255.255.255/32",       true,  "255.255.255.255/32"},
		{"10.0.0.0/31",              true,  "10.0.0.0/31"},
		{"10.0.0.0/33",              false, ""},
		{"10.0.0.0/08",              false, ""},
		{"10.0.0.0/",                false, ""},
		{"10.0.0.0",                 false, ""},
		{"10.0.0.0/-1",              false, ""},
		{"10.0.0.0/8/8",             false, ""},
		{"10.0.0.0/8 ",              false, ""},
		{" 10.0.0.0/8",              false, ""},
		{"10.0.0/8",                 false, ""},
		{"010.0.0.0/8",              false, ""},
		{"0x0a.0.0.0/8",             false, ""},
		{"10.0.0.0:80/8",            false, ""},
		{"[10.0.0.0]:80/8",          false, ""},
		{"2001:db8::/32",            true,  "2001:db8::/32"},
		{"2001:DB8::/32",            true,  "2001:db8::/32"},
		{"2001:db8::1/32",           false, "2001:db8::1/32"},
		{"2001:db8::1/32",           true,  ""},
		{"::/0",                     true,  "::/0"},
		{"::1/128",                  true,  "::1/128"},
		{"2001:db8::/127",           true,  "2001:db8::/127"},
		{"::ffff:10.0.0.0/104",      true,  "::ffff:10.0.0.0/104"},
		{"::/129",                   false, ""},
		{"2001:db8::/032",           false, ""},
		{"[2001:db8::]/32",          false, ""},
		{"fe80::1%eth0/64",          false, ""},
		{"/8",                       false, ""},
		{"",                         false, ""},
	}
	for c in cases {
		prefix, ok := net.parse_prefix(c.input, c.strict)
		if c.expected == "" {
			testing.expectf(t, !ok, "parse_prefix(%q, strict=%v) should fail, got %v", c.input, c.strict, prefix)
			continue
		}
		if !testing.expectf(t, ok, "parse_prefix(%q, strict=%v) failed", c.input, c.strict) {
			continue
		}
		output := net.prefix_to_string(prefix)
		testing.expectf(t, output == c.expected, "parse_prefix(%q) gave %s, expected %s", c.input, output, c.expected)
	}
}

@(test)
test_netmasks :: proc(t: ^testing.T) {
	for family in net.Address_Family {
		bits := family == .IP4 ? 32 : 128
		for length in 0..=bits {
			netmask, netmask_ok := net.netmask_from_length(family, length)
			hostmask, hostmask_ok := net.hostmask_from_length(family, length)
			if !testing.expectf(t, netmask_ok && hostmask_ok, "%v /%d: no mask", family, length) {
				continue
			}
			back, back_ok := net.length_from_netmask(netmask)
			testing.expectf(t, back_ok && back == length, "%v /%d: length_from_netmask gave %d, %v", family, length, back, back_ok)

			net_value  := ip_value(net.Address(netmask))
			host_value := ip_value(hostmask)
			all        := max(u128) >> uint(128 - bits)
			testing.expectf(t, net_value & host_value == 0 && net_value | host_value == all, "%v /%d: netmask and hostmask don't partition", family, length)
		}
		_, below := net.netmask_from_length(family, -1)
		_, above := net.netmask_from_length(family, bits + 1)
		testing.expectf(t, !below && !above, "%v: out-of-range lengths accepted", family)
	}

	Case :: struct {
		mask:   string,
		length: int,
	}
	cases := []Case{
		{"255.255.255.0",          24},
		{"255.255.255.254",        31},
		{"255.255.255.255",        32},
		{"0.0.0.0",                 0},
		{"128.0.0.0",               1},
		{"255.0.255.0",            -1},
		{"0.0.0.255",              -1},
		{"ffff:ffff:ffff:ffff::",  64},
		{"ffff:ffff:ffff:fffe::",  63},
		{"::",                      0},
		{"ffff::ffff",             -1},
	}
	for c in cases {
		length, ok := net.length_from_netmask(net.Netmask(ip_address(c.mask)))
		if c.length < 0 {
			testing.expectf(t, !ok, "length_from_netmask(%s) should fail, got %d", c.mask, length)
		} else {
			testing.expectf(t, ok && length == c.length, "length_from_netmask(%s) gave %d, %v, expected %d", c.mask, length, ok, c.length)
		}
	}

	lease := net.Lease{address = ip_address("192.168.1.5"), netmask = net.Netmask(ip_address("255.255.255.0"))}
	prefix, ok := net.prefix_from_lease(lease)
	testing.expectf(t, ok && net.prefix_to_string(prefix) == "192.168.1.5/24", "prefix_from_lease gave %v, %v", prefix, ok)

	lease.netmask = net.Netmask(ip_address("ffff::"))
	_, ok = net.prefix_from_lease(lease)
	testing.expect(t, !ok, "prefix_from_lease accepted a netmask of another family")
}

@(test)
test_prefix_bounds :: proc(t: ^testing.T) {
	Case :: struct {
		prefix:             string,
		network:            string,
		last:               string,
		broadcast:          string,
		first_host:         string,
		first_host_anycast: string,
		last_host:          string,
		addresses:          u128,
		addresses_ok:       bool,
		hosts:              u128,
		hosts_anycast:      u128,
		hosts_anycast_ok:   bool,
	}
	cases := []Case{
		{"192.168.1.130/24", "192.168.1.0", "192.168.1.255",   "192.168.1.255",   "192.168.1.1", "192.168.1.1", "192.168.1.254",   256,           true,  254,           254,           true},
		{"10.0.0.0/8",       "10.0.0.0",    "10.255.255.255",  "10.255.255.255",  "10.0.0.1",    "10.0.0.1",    "10.255.255.254",  1 << 24,       true,  1 << 24 - 2,   1 << 24 - 2,   true},
		{"0.0.0.0/0",        "0.0.0.0",     "255.255.255.255", "255.255.255.255", "0.0.0.1",     "0.0.0.1",     "255.255.255.254", 1 << 32,       true,  1 << 32 - 2,   1 << 32 - 2,   true},
		{"10.0.0.0/30",      "10.0.0.0",    "10.0.0.3",        "10.0.0.3",        "10.0.0.1",    "10.0.0.1",    "10.0.0.2",        4,             true,  2,             2,             true},
		{"10.0.0.0/31",      "10.0.0.0",    "10.0.0.1",        "",                "10.0.0.0",    "10.0.0.0",    "10.0.0.1",        2,             true,  2,             2,             true},
		{"10.0.0.7/32",      "10.0.0.7",    "10.0.0.7",        "",                "10.0.0.7",    "10.0.0.7",    "10.0.0.7",        1,             true,  1,             1,             true},
		{"2001:db8::/64",    "2001:db8::",  "2001:db8::ffff:ffff:ffff:ffff", "",  "2001:db8::1", "2001:db8::",  "2001:db8::ffff:ffff:ffff:ffff", 1 << 64, true, 1 << 64 - 1, 1 << 64, true},
		{"2001:db8::/126",   "2001:db8::",  "2001:db8::3",     "",                "2001:db8::1", "2001:db8::",  "2001:db8::3",     4,             true,  3,             4,             true},
		{"2001:db8::/127",   "2001:db8::",  "2001:db8::1",     "",                "2001:db8::",  "2001:db8::",  "2001:db8::1",     2,             true,  2,             2,             true},
		{"2001:db8::1/128",  "2001:db8::1", "2001:db8::1",     "",                "2001:db8::1", "2001:db8::1", "2001:db8::1",     1,             true,  1,             1,             true},
		{"::/0",             "::",          "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", "", "::1", "::",         "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", 0, false, max(u128), 0,  false},
	}
	for c in cases {
		prefix := ip_prefix(c.prefix)
		expect_address(t, c.prefix, "network_address", net.network_address(prefix), c.network)
		expect_address(t, c.prefix, "last_address", net.last_address(prefix), c.last)
		expect_address(t, c.prefix, "first_host", net.first_host(prefix), c.first_host)
		expect_address(t, c.prefix, "first_host(include_anycast)", net.first_host(prefix, include_anycast = true), c.first_host_anycast)
		expect_address(t, c.prefix, "last_host", net.last_host(prefix), c.last_host)

		broadcast, broadcast_ok := net.broadcast_address(prefix)
		if c.broadcast == "" {
			testing.expectf(t, !broadcast_ok, "%s: broadcast_address should fail, got %v", c.prefix, broadcast)
		} else {
			expect_address(t, c.prefix, "broadcast_address", broadcast, c.broadcast)
			testing.expectf(t, net.is_directed_broadcast(prefix, broadcast), "%s: is_directed_broadcast(%v) is false", c.prefix, broadcast)
		}

		addresses, addresses_ok := net.address_count(prefix)
		testing.expectf(t, addresses_ok == c.addresses_ok && addresses == c.addresses, "%s: address_count gave %v, %v", c.prefix, addresses, addresses_ok)
		hosts, hosts_ok := net.host_count(prefix)
		testing.expectf(t, hosts_ok && hosts == c.hosts, "%s: host_count gave %v, %v", c.prefix, hosts, hosts_ok)
		hosts_anycast, hosts_anycast_ok := net.host_count(prefix, include_anycast = true)
		testing.expectf(t, hosts_anycast_ok == c.hosts_anycast_ok && hosts_anycast == c.hosts_anycast, "%s: host_count(include_anycast) gave %v, %v", c.prefix, hosts_anycast, hosts_anycast_ok)
	}

	testing.expect(t, !net.is_directed_broadcast(ip_prefix("10.1.2.0/24"), ip_address("10.1.2.254")))
	testing.expect(t, !net.is_directed_broadcast(ip_prefix("10.1.2.0/31"), ip_address("10.1.2.1")))
	testing.expect(t, net.network_address(net.IP4_Prefix{length = 33}) == nil)
}

@(test)
test_prefix_containment :: proc(t: ^testing.T) {
	Contains :: struct {
		prefix:   string,
		address:  string,
		expected: bool,
	}
	contains := []Contains{
		{"10.0.0.0/8",      "10.255.255.255",  true},
		{"10.0.0.0/8",      "11.0.0.0",        false},
		{"10.0.0.0/8",      "9.255.255.255",   false},
		{"10.0.0.0/8",      "::ffff:10.0.0.1", false},
		{"192.168.1.5/24",  "192.168.1.200",   true},
		{"0.0.0.0/0",       "255.255.255.255", true},
		{"0.0.0.0/0",       "::",              false},
		{"::/0",            "::",              true},
		{"2001:db8::/32",   "2001:db9::",      false},
		{"2001:db8::1/128", "2001:db8::1",     true},
	}
	for c in contains {
		actual := net.prefix_contains(ip_prefix(c.prefix), ip_address(c.address))
		testing.expectf(t, actual == c.expected, "prefix_contains(%s, %s) gave %v", c.prefix, c.address, actual)
	}

	Pair :: struct {
		a, b:     string,
		contains: bool,
		overlap:  bool,
	}
	pairs := []Pair{
		{"10.0.0.0/8",    "10.1.0.0/16",     true,  true},
		{"10.1.0.0/16",   "10.0.0.0/8",      false, true},
		{"10.0.0.0/8",    "10.0.0.0/8",      true,  true},
		{"10.0.0.0/8",    "11.0.0.0/8",      false, false},
		{"10.0.0.0/31",   "10.0.0.1/32",     true,  true},
		{"0.0.0.0/0",     "::/0",            false, false},
		{"::/0",          "2001:db8::/32",   true,  true},
		{"2001:db8::/33", "2001:db8:8000::/33", false, false},
	}
	for c in pairs {
		a, b := ip_prefix(c.a), ip_prefix(c.b)
		testing.expectf(t, net.prefix_contains_prefix(a, b) == c.contains, "prefix_contains_prefix(%s, %s) should be %v", c.a, c.b, c.contains)
		testing.expectf(t, net.prefixes_overlap(a, b) == c.overlap, "prefixes_overlap(%s, %s) should be %v", c.a, c.b, c.overlap)
		testing.expectf(t, net.ranges_overlap(net.prefix_to_range(a), net.prefix_to_range(b)) == c.overlap, "ranges_overlap(%s, %s) should be %v", c.a, c.b, c.overlap)
	}
}

@(test)
test_range_to_prefixes :: proc(t: ^testing.T) {
	Case :: struct {
		range:    string,
		expected: []string,
	}
	cases := []Case{
		{"10.0.0.1-10.0.0.9",                         {"10.0.0.1/32", "10.0.0.2/31", "10.0.0.4/30", "10.0.0.8/31"}},
		{"0.0.0.0-255.255.255.255",                   {"0.0.0.0/0"}},
		{"192.168.0.0-192.168.255.255",               {"192.168.0.0/16"}},
		{"10.0.0.5-10.0.0.5",                         {"10.0.0.5/32"}},
		{"255.255.255.254-255.255.255.255",           {"255.255.255.254/31"}},
		{"2001:db8::-2001:db8::ffff",                 {"2001:db8::/112"}},
		{"2001:db8::1-2001:db8::4",                   {"2001:db8::1/128", "2001:db8::2/127", "2001:db8::4/128"}},
		{"::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", {"::/0"}},
	}
	for c in cases {
		range, ok := net.parse_range(c.range)
		if !testing.expectf(t, ok, "parse_range(%q) failed", c.range) {
			continue
		}
		testing.expectf(t, net.range_to_string(range) == c.range, "range_to_string gave %s, expected %s", net.range_to_string(range), c.range)
		prefixes, err := net.range_to_prefixes(range)
		testing.expect_value(t, err, nil)
		expect_prefixes(t, c.range, prefixes, c.expected)
		delete(prefixes)
	}

	worst := []struct{range: string, count: int}{
		{"0.0.0.1-255.255.255.254", 62},
		{"::1-ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe", 254},
	}
	for c in worst {
		range, _ := net.parse_range(c.range)
		prefixes, _ := net.range_to_prefixes(range)
		testing.expectf(t, len(prefixes) == c.count, "%s: %d prefixes, expected %d", c.range, len(prefixes), c.count)
		delete(prefixes)
	}

	for bad in ([]string{"10.0.0.9-10.0.0.1", "10.0.0.1-::1", "10.0.0.1", "10.0.0-10.0.1", "10.0.0.0/8-10.0.0.9"}) {
		_, ok := net.parse_range(bad)
		testing.expectf(t, !ok, "parse_range(%q) should fail", bad)
	}
	_, err := net.range_to_prefixes(net.IP4_Range{first = {10, 0, 0, 9}, last = {10, 0, 0, 1}})
	testing.expect_value(t, err, runtime.Allocator_Error.Invalid_Argument)
}

@(test)
test_aggregate_prefixes :: proc(t: ^testing.T) {
	Case :: struct {
		input:    []string,
		expected: []string,
	}
	aggregate := []Case{
		{{"10.0.0.0/24", "10.0.1.0/24"},                    {"10.0.0.0/23"}},
		{{"10.0.0.0/24", "10.0.2.0/24"},                    {"10.0.0.0/24", "10.0.2.0/24"}},
		{{"10.0.1.0/24", "10.0.2.0/24"},                    {"10.0.1.0/24", "10.0.2.0/24"}},
		{{"10.1.0.0/16", "10.0.0.0/8"},                     {"10.0.0.0/8"}},
		{{"192.168.1.5/24", "192.168.0.0/24"},              {"192.168.0.0/23"}},
		{{"0.0.0.0/1", "128.0.0.0/1"},                      {"0.0.0.0/0"}},
		{{"255.255.255.255/32", "255.255.255.254/32"},      {"255.255.255.254/31"}},
		{{"2001:db8::/33", "2001:db8:8000::/33", "10.0.0.128/25", "10.0.0.0/25"}, {"10.0.0.0/24", "2001:db8::/32"}},
		{{"10.0.0.0/24", "10.0.0.0/24"},                    {"10.0.0.0/24"}},
		{{},                                                {}},
	}
	for c in aggregate {
		input := ip_prefixes(c.input)
		output, err := net.aggregate_prefixes(input)
		testing.expect_value(t, err, nil)
		expect_prefixes(t, "aggregate_prefixes", output, c.expected)
		delete(output)
	}

	ranges := []Case{
		{{"10.0.3.0/24", "10.0.0.0/24", "10.0.1.0/24"},    {"10.0.0.0-10.0.1.255", "10.0.3.0-10.0.3.255"}},
		{{"255.255.255.0/24", "0.0.0.0/0"},                 {"0.0.0.0-255.255.255.255"}},
		{{"::/1", "8000::/1"},                              {"::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"}},
	}
	for c in ranges {
		output, err := net.prefixes_to_ranges(ip_prefixes(c.input))
		testing.expect_value(t, err, nil)
		actual := make([]string, len(output), context.temp_allocator)
		for range, i in output {
			actual[i] = net.range_to_string(range)
		}
		testing.expectf(t, strings_equal(actual, c.expected), "prefixes_to_ranges(%v) gave %v, expected %v", c.input, actual, c.expected)
		delete(output)
	}

	Summary :: struct {
		input:    []string,
		expected: string,
	}
	summaries := []Summary{
		{{"10.0.0.0/24", "10.0.3.0/24"},       "10.0.0.0/22"},
		{{"10.0.0.0/8", "192.168.0.0/16"},     "0.0.0.0/0"},
		{{"192.168.1.5/24"},                   "192.168.1.0/24"},
		{{"2001:db8::/48", "2001:db8:1::/48"}, "2001:db8::/47"},
		{{"10.0.0.0/8", "::/0"},               ""},
		{{},                                   ""},
	}
	for c in summaries {
		summary, ok := net.summarize_prefixes(ip_prefixes(c.input))
		if c.expected == "" {
			testing.expectf(t, !ok, "summarize_prefixes(%v) should fail, got %v", c.input, summary)
		} else {
			testing.expectf(t, ok && net.prefix_to_string(summary) == c.expected, "summarize_prefixes(%v) gave %v, expected %s", c.input, summary, c.expected)
		}
	}

	Exclude :: struct {
		prefix, hole: string,
		expected:     []string,
	}
	excludes := []Exclude{
		{"10.0.0.0/8", "10.1.2.0/24", {
			"10.0.0.0/16", "10.1.0.0/23", "10.1.3.0/24", "10.1.4.0/22", "10.1.8.0/21", "10.1.16.0/20", "10.1.32.0/19", "10.1.64.0/18",
			"10.1.128.0/17", "10.2.0.0/15", "10.4.0.0/14", "10.8.0.0/13", "10.16.0.0/12", "10.32.0.0/11", "10.64.0.0/10", "10.128.0.0/9",
		}},
		{"10.0.0.0/24",    "10.0.0.0/24",     {}},
		{"10.0.0.0/24",    "10.0.0.0/8",      {}},
		{"10.0.0.0/24",    "11.0.0.0/8",      {"10.0.0.0/24"}},
		{"10.0.0.0/24",    "::/0",            {"10.0.0.0/24"}},
		{"2001:db8::/126", "2001:db8::1/128", {"2001:db8::/128", "2001:db8::2/127"}},
		{"::/0",           "::/1",            {"8000::/1"}},
	}
	for c in excludes {
		output, err := net.prefix_exclude(ip_prefix(c.prefix), ip_prefix(c.hole))
		testing.expect_value(t, err, nil)
		expect_prefixes(t, c.prefix, output, c.expected)
		delete(output)
	}
}

@(test)
test_subnets :: proc(t: ^testing.T) {
	count, ok := net.subnet_count(ip_prefix("10.0.0.0/8"), 16)
	testing.expect(t, ok && count == 256)
	_, ok = net.subnet_count(ip_prefix("10.0.0.0/8"), 7)
	testing.expect(t, !ok)
	_, ok = net.subnet_count(ip_prefix("::/0"), 128)
	testing.expect(t, !ok)

	expect_prefix(t, "subnet_nth", net.subnet_nth(ip_prefix("10.9.9.9/8"), 16, 255), "10.255.0.0/16")
	_, ok = net.subnet_nth(ip_prefix("10.0.0.0/8"), 16, 256)
	testing.expect(t, !ok)
	expect_prefix(t, "subnet_nth", net.subnet_nth(ip_prefix("::/0"), 128, 5), "::5/128")
	expect_prefix(t, "subnet_nth", net.subnet_nth(ip_prefix("::/0"), 0, 0), "::/0")

	subnets, err := net.split_prefix(ip_prefix("192.168.0.0/24"), 26)
	testing.expect_value(t, err, nil)
	expect_prefixes(t, "split_prefix", subnets, {"192.168.0.0/26", "192.168.0.64/26", "192.168.0.128/26", "192.168.0.192/26"})
	delete(subnets)
	_, err = net.split_prefix(ip_prefix("10.0.0.0/8"), 7)
	testing.expect_value(t, err, runtime.Allocator_Error.Invalid_Argument)
	_, err = net.split_prefix(ip_prefix("::/0"), 128)
	testing.expect_value(t, err, runtime.Allocator_Error.Invalid_Argument)

	expect_prefix(t, "prefix_supernet", net.prefix_supernet(ip_prefix("10.1.2.0/24"), 8), "10.0.0.0/8")
	expect_prefix(t, "prefix_supernet", net.prefix_supernet(ip_prefix("10.1.2.0/24"), 0), "0.0.0.0/0")
	_, ok = net.prefix_supernet(ip_prefix("10.1.2.0/24"), 25)
	testing.expect(t, !ok)

	expect_prefix(t, "prefix_next", net.prefix_next(ip_prefix("192.168.1.5/24")), "192.168.2.0/24")
	expect_prefix(t, "prefix_prev", net.prefix_prev(ip_prefix("10.0.1.0/24")), "10.0.0.0/24")
	expect_prefix(t, "prefix_next", net.prefix_next(ip_prefix("2001:db8::/64")), "2001:db8:0:1::/64")
	_, ok = net.prefix_next(ip_prefix("255.255.255.0/24"))
	testing.expect(t, !ok)
	_, ok = net.prefix_prev(ip_prefix("0.0.0.0/24"))
	testing.expect(t, !ok)
	_, ok = net.prefix_next(ip_prefix("::/0"))
	testing.expect(t, !ok)

	expect_prefix(t, "common_supernet", net.common_supernet(ip_prefix("10.0.0.0/24"), ip_prefix("10.0.1.0/24")), "10.0.0.0/23")
	expect_prefix(t, "common_supernet", net.common_supernet(ip_prefix("10.0.0.0/8"), ip_prefix("10.0.0.0/8")), "10.0.0.0/8")
	expect_prefix(t, "common_supernet", net.common_supernet(ip_prefix("::/128"), ip_prefix("8000::/128")), "::/0")
	_, ok = net.common_supernet(ip_prefix("10.0.0.0/8"), ip_prefix("::/0"))
	testing.expect(t, !ok)

	next, next_ok := net.address_next(ip_address("10.0.0.255"))
	testing.expect(t, next_ok && next == ip_address("10.0.1.0"))
	_, next_ok = net.address_next(ip_address("255.255.255.255"))
	testing.expect(t, !next_ok)
	_, next_ok = net.address_prev(ip_address("::"))
	testing.expect(t, !next_ok)
	testing.expect(t, net.address_compare(ip_address("10.0.0.1"), ip_address("::")) < 0)
	testing.expect(t, net.address_compare(ip_address("10.0.0.2"), ip_address("10.0.0.1")) > 0)
	testing.expect(t, net.address_compare(ip_address("::1"), ip_address("::1")) == 0)
}

@(test)
test_mapped_addresses :: proc(t: ^testing.T) {
	mapped := ip_address("::ffff:10.0.0.1")
	testing.expect(t, net.is_ip4_mapped(mapped))
	testing.expect(t, !net.is_ip4_mapped(ip_address("10.0.0.1")))
	testing.expect(t, !net.is_ip4_mapped(ip_address("::10.0.0.1")))
	testing.expect(t, !net.is_ip4_mapped(ip_address("0:0:0:0:1:ffff:a00:1")))
	testing.expect_value(t, net.address_unmapped(mapped), net.Address(net.IP4_Address{10, 0, 0, 1}))
	testing.expect_value(t, net.address_unmapped(ip_address("::1")), ip_address("::1"))
	testing.expect_value(t, net.map_to_ip6(net.address_unmapped(mapped)), mapped)
	testing.expect_value(t, net.address_to_string(mapped), "::ffff:10.0.0.1")

	testing.expect_value(t, net.classify_address(mapped), net.Address_Category.IP4_Mapped)
	testing.expect_value(t, net.classify_address(net.address_unmapped(mapped)), net.Address_Category.Private_Use)
	testing.expect(t, !net.prefix_contains(ip_prefix("10.0.0.0/8"), mapped))
	testing.expect(t, net.prefix_contains(ip_prefix("10.0.0.0/8"), net.address_unmapped(mapped)))

	prefix, ok := net.map_prefix_to_ip6(net.IP4_Prefix{{10, 0, 0, 0}, 8})
	testing.expect(t, ok && net.prefix_to_string(prefix) == "::ffff:10.0.0.0/104")
	testing.expect(t, net.prefix_contains(prefix, mapped))
	everything, _ := net.map_prefix_to_ip6(net.IP4_Prefix{{}, 0})
	testing.expect_value(t, net.Prefix(everything), ip_prefix("::ffff:0:0/96"))

	unmapped, unmapped_ok := net.unmap_prefix(ip_prefix("::ffff:0:0/96").(net.IP6_Prefix))
	testing.expect(t, unmapped_ok && unmapped == net.IP4_Prefix{{}, 0})
	_, unmapped_ok = net.unmap_prefix(ip_prefix("::ffff:0:0/95").(net.IP6_Prefix))
	testing.expect(t, !unmapped_ok)
	_, unmapped_ok = net.unmap_prefix(ip_prefix("::/96").(net.IP6_Prefix))
	testing.expect(t, !unmapped_ok)
}

@(test)
test_classify_address :: proc(t: ^testing.T) {
	Case :: struct {
		address:            string,
		category:           net.Address_Category,
		globally_reachable: bool,
	}
	cases := []Case{
		{"127.0.0.1",        .Loopback,            false},
		{"127.255.255.255",  .Loopback,            false},
		{"10.1.2.3",         .Private_Use,         false},
		{"172.16.0.0",       .Private_Use,         false},
		{"172.31.255.255",   .Private_Use,         false},
		{"172.32.0.0",       .Global_Unicast,      true},
		{"192.168.0.1",      .Private_Use,         false},
		{"100.64.0.1",       .Shared_Address,      false},
		{"100.127.255.255",  .Shared_Address,      false},
		{"100.128.0.0",      .Global_Unicast,      true},
		{"169.254.1.1",      .Link_Local,          false},
		{"0.0.0.0",          .Unspecified,         false},
		{"0.1.2.3",          .This_Network,        false},
		{"192.0.2.1",        .Documentation,       false},
		{"198.51.100.7",     .Documentation,       false},
		{"203.0.113.9",      .Documentation,       false},
		{"198.18.0.1",       .Benchmarking,        false},
		{"198.19.255.255",   .Benchmarking,        false},
		{"198.20.0.0",       .Global_Unicast,      true},
		{"192.0.0.1",        .Translation,         false},
		{"192.0.0.8",        .Dummy,               false},
		{"192.0.0.9",        .Protocol_Assignment, true},
		{"192.0.0.100",      .Protocol_Assignment, false},
		{"192.0.0.171",      .Translation,         false},
		{"192.88.99.1",      .Deprecated,          false},
		{"192.88.99.2",      .Translation,         false},
		{"192.175.48.1",     .Protocol_Assignment, true},
		{"224.0.0.1",        .Multicast,           false},
		{"224.0.1.1",        .Multicast,           true},
		{"239.255.255.250",  .Multicast,           false},
		{"240.0.0.1",        .Reserved,            false},
		{"255.255.255.254",  .Reserved,            false},
		{"255.255.255.255",  .Limited_Broadcast,   false},
		{"8.8.8.8",          .Global_Unicast,      true},
		{"1.1.1.1",          .Global_Unicast,      true},
		{"::1",              .Loopback,            false},
		{"::",               .Unspecified,         false},
		{"::2",              .Reserved,            false},
		{"::ffff:1.2.3.4",   .IP4_Mapped,          false},
		{"64:ff9b::1.2.3.4", .Translation,         true},
		{"64:ff9b:1::1",     .Translation,         false},
		{"100::1",           .Discard_Only,        false},
		{"100:0:0:1::1",     .Dummy,               false},
		{"2001::1",          .Translation,         true},
		{"2001:1::1",        .Protocol_Assignment, true},
		{"2001:1::4",        .Protocol_Assignment, false},
		{"2001:2::1",        .Benchmarking,        false},
		{"2001:10::1",       .Deprecated,          false},
		{"2001:20::1",       .Protocol_Assignment, true},
		{"2001:db8::1",      .Documentation,       false},
		{"2001:200::1",      .Global_Unicast,      true},
		{"2002:c000:204::1", .Translation,         true},
		{"3fff::1",          .Documentation,       false},
		{"4000::1",          .Reserved,            false},
		{"5f00::1",          .Protocol_Assignment, false},
		{"fc00::1",          .Unique_Local,        false},
		{"fd12:3456::1",     .Unique_Local,        false},
		{"fe80::1",          .Link_Local,          false},
		{"febf::1",          .Link_Local,          false},
		{"fec0::1",          .Deprecated,          false},
		{"ff02::1",          .Multicast,           false},
		{"ff0e::1",          .Multicast,           true},
		{"2606:4700::1111",  .Global_Unicast,      true},
	}
	for c in cases {
		address  := ip_address(c.address)
		category := net.classify_address(address)
		testing.expectf(t, category == c.category, "classify_address(%s) gave %v, expected %v", c.address, category, c.category)
		reachable := net.is_globally_reachable(address)
		testing.expectf(t, reachable == c.globally_reachable, "is_globally_reachable(%s) gave %v", c.address, reachable)
	}

	testing.expect(t, net.is_loopback(ip_address("127.0.0.1")))
	testing.expect(t, !net.is_private_use(ip_address("127.0.0.1")))
	testing.expect(t, net.is_private_use(ip_address("10.0.0.1")))
	testing.expect(t, !net.is_private_use(ip_address("fd00::1")))
	testing.expect(t, net.is_unique_local(ip_address("fd00::1")))
	testing.expect(t, net.is_shared_address(ip_address("100.64.0.1")))
	testing.expect(t, net.is_link_local(ip_address("169.254.0.1")))
	testing.expect(t, net.is_link_local(ip_address("fe80::1")))
	testing.expect(t, net.is_documentation(ip_address("2001:db8::1")))
	testing.expect(t, net.is_benchmarking(ip_address("2001:2::1")))
	testing.expect(t, net.is_multicast(ip_address("ff02::fb")))
	testing.expect(t, net.is_unspecified(ip_address("::")))
	testing.expect(t, net.is_limited_broadcast(ip_address("255.255.255.255")))
	testing.expect(t, net.is_global_unicast(ip_address("8.8.8.8")))
	testing.expect(t, !net.is_global_unicast(ip_address("10.0.0.1")))
	testing.expect_value(t, net.classify_address(nil), net.Address_Category.Unspecified)

	Scope :: struct {
		address: string,
		scope:   net.Multicast_Scope,
		ok:      bool,
	}
	scopes := []Scope{
		{"224.0.0.251",     .Link_Local,         true},
		{"224.0.1.1",       .Global,             true},
		{"239.255.255.250", .Site_Local,         true},
		{"239.192.0.1",     .Organization_Local, true},
		{"239.1.2.3",       .Admin_Local,        true},
		{"10.0.0.1",        {},                  false},
		{"ff01::1",         .Interface_Local,    true},
		{"ff02::1",         .Link_Local,         true},
		{"ff05::2",         .Site_Local,         true},
		{"ff3e::8000:1",    .Global,             true},
		{"fe80::1",         {},                  false},
	}
	for c in scopes {
		scope, ok := net.multicast_scope(ip_address(c.address))
		testing.expectf(t, ok == c.ok && scope == c.scope, "multicast_scope(%s) gave %v, %v", c.address, scope, ok)
	}
}

@(test)
test_registry_matches_iana :: proc(t: ^testing.T) {
	check_registry(t, IANA_IP4_SPECIAL_REGISTRY, net.IP4_SPECIAL_PURPOSE_REGISTRY[:])
	check_registry(t, IANA_IP6_SPECIAL_REGISTRY, net.IP6_SPECIAL_PURPOSE_REGISTRY[:])
}

@(test)
test_prefix_properties :: proc(t: ^testing.T) {
	for _ in 0..<500 {
		for bits in ([]int{32, 128}) {
			first := random_value(bits)
			span  := random_value(bits) & (max(u128) >> uint(128 - rand.int_max(bits + 1)))
			last  := ip_all_ones(bits) - first < span ? ip_all_ones(bits) : first + span
			range, range_ok := net.range_make(ip_from_value(first, bits), ip_from_value(last, bits))
			if !testing.expect(t, range_ok) {
				return
			}
			check_range_decomposition(t, range, first, last, bits)

			prefix, _ := net.prefix_from_address(ip_from_value(random_value(bits), bits), rand.int_max(bits + 1))
			masked    := net.prefix_masked(prefix)

			parsed, parsed_ok := net.parse_prefix(net.prefix_to_string(prefix))
			testing.expectf(t, parsed_ok && parsed == prefix, "parse_prefix(prefix_to_string(%v)) gave %v", prefix, parsed)

			from_range, _ := net.range_to_prefixes(net.prefix_to_range(prefix))
			testing.expectf(t, len(from_range) == 1 && from_range[0] == masked, "range_to_prefixes(prefix_to_range(%v)) gave %v", prefix, from_range)
			delete(from_range)

			length := ip_prefix_length(prefix)
			split_length := min(length + rand.int_max(7), bits)
			subnets, split_err := net.split_prefix(prefix, split_length)
			testing.expect_value(t, split_err, nil)
			aggregated, _ := net.aggregate_prefixes(subnets)
			testing.expectf(t, len(aggregated) == 1 && aggregated[0] == masked, "aggregate_prefixes(split_prefix(%v, %d)) gave %v", prefix, split_length, aggregated)
			delete(aggregated)
			delete(subnets)

			probe := ip_from_value(ip_value(net.network_address(prefix)) + random_value(bits) % 4096, bits)
			testing.expectf(t, net.prefix_contains(prefix, probe) == net.range_contains(net.prefix_to_range(prefix), probe), "prefix_contains and range_contains disagree on %v in %v", probe, prefix)
		}

		v4 := ip_from_value(random_value(32), 32).(net.IP4_Address)
		testing.expect_value(t, net.classify_address(net.address_unmapped(net.map_to_ip6(v4))), net.classify_address(v4))
	}
}

check_range_decomposition :: proc(t: ^testing.T, range: net.Address_Range, first, last: u128, bits: int) {
	prefixes, err := net.range_to_prefixes(range)
	defer delete(prefixes)
	if !testing.expect_value(t, err, nil) || !testing.expect(t, len(prefixes) > 0) {
		return
	}
	testing.expectf(t, len(prefixes) <= max(1, 2 * bits - 2), "%v: %d prefixes", range, len(prefixes))
	testing.expectf(t, ip_value(net.network_address(prefixes[0])) == first, "%v: starts at %v", range, prefixes[0])
	testing.expectf(t, ip_value(net.last_address(prefixes[len(prefixes) - 1])) == last, "%v: ends at %v", range, prefixes[len(prefixes) - 1])
	for prefix, i in prefixes {
		testing.expectf(t, net.prefix_is_canonical(prefix), "%v: %v is not canonical", range, prefix)
		if i == 0 {
			continue
		}
		previous := prefixes[i - 1]
		testing.expectf(t, ip_value(net.last_address(previous)) + 1 == ip_value(net.network_address(prefix)), "%v: gap between %v and %v", range, previous, prefix)
		supernet, _ := net.common_supernet(previous, prefix)
		mergeable := ip_prefix_length(previous) == ip_prefix_length(prefix) && ip_prefix_length(supernet) == ip_prefix_length(prefix) - 1
		testing.expectf(t, !mergeable, "%v: %v and %v could merge", range, previous, prefix)
	}

	ranges, ranges_err := net.prefixes_to_ranges(prefixes)
	testing.expect_value(t, ranges_err, nil)
	testing.expectf(t, len(ranges) == 1 && ranges[0] == range, "prefixes_to_ranges(range_to_prefixes(%v)) gave %v", range, ranges)
	delete(ranges)

	aggregated, _ := net.aggregate_prefixes(prefixes)
	testing.expectf(t, ip_prefixes_equal(aggregated, prefixes), "aggregate_prefixes changed the minimal set for %v", range)
	delete(aggregated)
}

check_registry :: proc(t: ^testing.T, csv_data: string, registry: []net.Special_Purpose_Entry) {
	reader: csv.Reader
	csv.reader_init_with_string(&reader, csv_data)
	defer csv.reader_destroy(&reader)
	records, err := csv.read_all(&reader, context.temp_allocator)
	if !testing.expect_value(t, err, nil) || !testing.expect(t, len(records) > 1) {
		return
	}

	Row :: struct {
		prefix: net.Prefix,
		record: []string,
	}
	rows := make([dynamic]Row, context.temp_allocator)
	for record in records[1:] {
		for block in strings.split(record[0], ",", context.temp_allocator) {
			prefix, ok := net.parse_prefix(strip_footnote(block), strict = true)
			if testing.expectf(t, ok, "IANA block %q doesn't parse", block) {
				append(&rows, Row{prefix, record})
			}
		}
	}
	testing.expectf(t, len(rows) == len(registry), "registry has %d entries, IANA has %d", len(registry), len(rows))
	for entry in registry {
		found := false
		for row in rows {
			found ||= row.prefix == entry.prefix
		}
		testing.expectf(t, found, "%v is not in the IANA registry", entry.prefix)
	}

	for row in rows {
		network := ip_value(net.network_address(row.prefix))
		last    := ip_value(net.last_address(row.prefix))
		_, is_ip4 := row.prefix.(net.IP4_Prefix)
		bits    := 32 if is_ip4 else 128
		probes  := [3]u128{network, last, network + (last - network) / 2}
		for probe in probes {
			address := ip_from_value(probe, bits)
			covered := false
			for other in rows {
				covered ||= ip_prefix_length(other.prefix) > ip_prefix_length(row.prefix) && net.prefix_contains(other.prefix, address)
			}
			if covered {
				continue
			}
			entry, ok := net.special_purpose_entry(address)
			if !testing.expectf(t, ok && entry.prefix == row.prefix, "special_purpose_entry(%v) gave %v, expected %v", address, entry.prefix, row.prefix) {
				continue
			}
			name := strings.trim(row.record[1], "\"")
			rfc, _ := strings.remove_all(row.record[2], "[", context.temp_allocator)
			rfc, _  = strings.remove_all(rfc, "]", context.temp_allocator)
			testing.expectf(t, entry.name == name, "%v: name %q, IANA has %q", row.prefix, entry.name, name)
			testing.expectf(t, entry.rfc == rfc, "%v: rfc %q, IANA has %q", row.prefix, entry.rfc, rfc)
			flags := [5]net.Registry_Flag{entry.source, entry.destination, entry.forwardable, entry.globally_reachable, entry.reserved_by_protocol}
			for flag, i in flags {
				expected := iana_flag(row.record[5 + i])
				testing.expectf(t, flag == expected, "%v: %s is %v, IANA has %q", row.prefix, records[0][5 + i], flag, row.record[5 + i])
			}
		}

		if before, ok := net.address_prev(ip_from_value(network, bits)); ok {
			entry, _ := net.special_purpose_entry(before)
			testing.expectf(t, entry.prefix != row.prefix, "%v matched %v", before, row.prefix)
		}
		if after, ok := net.address_next(ip_from_value(last, bits)); ok {
			entry, _ := net.special_purpose_entry(after)
			testing.expectf(t, entry.prefix != row.prefix, "%v matched %v", after, row.prefix)
		}
	}
}

strip_footnote :: proc(raw: string) -> string {
	field := strings.trim_space(raw)
	if bracket := strings.index_byte(field, '['); bracket >= 0 {
		field = strings.trim_space(field[:bracket])
	}
	return field
}

iana_flag :: proc(field: string) -> net.Registry_Flag {
	switch strip_footnote(field) {
	case "True":  return .True
	case "False": return .False
	}
	return .Not_Applicable
}

ip_address :: proc(address_string: string) -> net.Address {
	address := net.parse_address(address_string)
	assert(address != nil, address_string)
	return address
}

ip_prefix :: proc(prefix_string: string) -> net.Prefix {
	prefix, ok := net.parse_prefix(prefix_string)
	assert(ok, prefix_string)
	return prefix
}

ip_prefixes :: proc(prefix_strings: []string) -> []net.Prefix {
	prefixes := make([]net.Prefix, len(prefix_strings), context.temp_allocator)
	for prefix_string, i in prefix_strings {
		prefixes[i] = ip_prefix(prefix_string)
	}
	return prefixes
}

ip_prefix_length :: proc(prefix: net.Prefix) -> int {
	switch v in prefix {
	case net.IP4_Prefix: return int(v.length)
	case net.IP6_Prefix: return int(v.length)
	}
	return -1
}

ip_value :: proc(address: net.Address) -> u128 {
	switch v in address {
	case net.IP4_Address: return u128(net.ip4_to_u32(v))
	case net.IP6_Address: return net.ip6_to_u128(v)
	}
	return 0
}

ip_from_value :: proc(value: u128, bits: int) -> net.Address {
	if bits == 32 {
		return net.ip4_from_u32(u32(value))
	}
	return net.ip6_from_u128(value)
}

ip_all_ones :: proc(bits: int) -> u128 {
	return max(u128) >> uint(128 - bits)
}

random_value :: proc(bits: int) -> u128 {
	return rand.uint128() & ip_all_ones(bits)
}

ip_prefixes_equal :: proc(a, b: []net.Prefix) -> bool {
	if len(a) != len(b) {
		return false
	}
	for prefix, i in a {
		if prefix != b[i] {
			return false
		}
	}
	return true
}

strings_equal :: proc(a, b: []string) -> bool {
	if len(a) != len(b) {
		return false
	}
	for s, i in a {
		if s != b[i] {
			return false
		}
	}
	return true
}

expect_address :: proc(t: ^testing.T, prefix: string, what: string, actual: net.Address, expected: string, loc := #caller_location) {
	testing.expectf(t, actual == ip_address(expected), "%s: %s gave %v, expected %s", prefix, what, net.address_to_string(actual), expected, loc = loc)
}

expect_prefix :: proc(t: ^testing.T, what: string, actual: net.Prefix, ok: bool, expected: string, loc := #caller_location) {
	testing.expectf(t, ok && net.prefix_to_string(actual) == expected, "%s gave %v, %v, expected %s", what, actual, ok, expected, loc = loc)
}

expect_prefixes :: proc(t: ^testing.T, what: string, actual: []net.Prefix, expected: []string, loc := #caller_location) {
	strs := make([]string, len(actual), context.temp_allocator)
	for prefix, i in actual {
		strs[i] = net.prefix_to_string(prefix)
	}
	testing.expectf(t, strings_equal(strs, expected), "%s gave %v, expected %v", what, strs, expected, loc = loc)
}
