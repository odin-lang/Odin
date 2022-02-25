/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
		graphitemaster:  pton/ntop IANA test vectors

	A test suite for `core:net`
*/
package test_core_net

import "core:testing"
import "core:mem"
import "core:fmt"
import "core:net"
import "core:strconv"

TEST_count := 0
TEST_fail  := 0

t := &testing.T{}

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.printf("[%v] %v\n", loc, message)
            return
        }
    }
    log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        fmt.printf("log: %v\n", v)
    }
}

_tracking_allocator := mem.Tracking_Allocator{}

print_tracking_allocator_report :: proc() {
	for _, leak in _tracking_allocator.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}

	for bf in _tracking_allocator.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bf.location, bf.memory)
	}
}

main :: proc() {
	mem.tracking_allocator_init(&_tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&_tracking_allocator)

	address_parsing_test(t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)

	print_tracking_allocator_report()
}

@test
address_parsing_test :: proc(t: ^testing.T) {
	for vector in IP_Address_Parsing_Test_Vectors {
		kind := ""
		if      vector.family == .IP6 { kind = "IPv6 address" }
		else if vector.family == .IP4 {
			if vector.non_decimal_ipv4 {
				kind = "non-decimal IPv4 address"
			} else {
				kind = "decimal IPv4 address"
			}
		}

		fmt.printf("Parsing %v as %v\n", vector.textual, kind)

		msg := "-set a proper message-"
		switch vector.family {
		case .IP4:
			/*
				Does `net.parse_ip4_address` think we parsed the address properly?
			*/
			any_addr  := net.parse_address(vector.textual, vector.non_decimal_ipv4)
			parsed_ok := any_addr != nil
			parsed:   net.IP4_Address

			/*
				Ensure that `parse_address` doesn't parse IPv4 addresses into IPv6 addreses by mistake.
			*/
			switch addr in any_addr {
			case net.IP4_Address:
				parsed = addr
			case net.IP6_Address:
				parsed_ok = false
				msg = fmt.tprintf("parse_address mistook %v as IPv6 address %v", vector.textual, addr)
				expect(t, false, msg)
			}

			if !parsed_ok && vector.should_parse {
				msg = fmt.tprintf("parse_ip4_address failed to parse %v, expected %v", vector.textual, binstr_to_address(vector.binstr))

			} else if parsed_ok && !vector.should_parse {
				msg = fmt.tprintf("parse_ip4_address parsed %v into %v, expected failure", vector.textual, parsed)
			}
			expect(t, parsed_ok == vector.should_parse, msg)

			if vector.should_parse && parsed_ok {
				actual_binary := address_to_binstr(parsed)
				msg = fmt.tprintf("parse_ip4_address parsed %v into %v, expected %v", vector.textual, actual_binary, vector.binstr)
				expect(t, actual_binary == vector.binstr, msg)

				/*
					Do we turn an address back into the same string properly?
					No point in testing the roundtrip if the first part failed.
				*/
				if vector.should_roundtrip && actual_binary == vector.binstr {
					stringified := net.address_to_string(parsed)
					msg = fmt.tprintf("address_to_string turned %v into %v, expected %v", parsed, stringified, vector.textual)
					expect(t, stringified == vector.textual, msg)
				}
			}

		case .IP6:
			/*
				Do we parse the address properly?
			*/
			parsed, parsed_ok := net.parse_ip6_address(vector.textual)

			if !parsed_ok && vector.should_parse {
				msg = fmt.tprintf("parse_ip6_address failed to parse %v, expected %v", vector.textual, binstr_to_address(vector.binstr))

			} else if parsed_ok && !vector.should_parse {
				msg = fmt.tprintf("parse_ip6_address parsed %v into %v, expected failure", vector.textual, parsed)
			}
			expect(t, parsed_ok == vector.should_parse, msg)

			if vector.should_parse && parsed_ok {
				actual_binary := address_to_binstr(parsed)
				msg = fmt.tprintf("parse_ip6_address parsed %v into %v, expected %v", vector.textual, actual_binary, vector.binstr)
				expect(t, actual_binary == vector.binstr, msg)

				/*
					Do we turn an address back into the same string properly?
					No point in testing the roundtrip if the first part failed.
				*/
				if vector.should_roundtrip && actual_binary == vector.binstr {
					stringified := net.address_to_string(parsed)
					msg = fmt.tprintf("address_to_string turned %v into %v, expected %v", parsed, stringified, vector.textual)
					expect(t, stringified == vector.textual, msg)
				}
			}
		}
	}
}

address_to_binstr :: proc(address: net.Address) -> (binstr: string) {
	switch t in address {
	case net.IP4_Address:
		b := transmute(u32be)t
		return fmt.tprintf("%08x", b)
	case net.IP6_Address:
		b := transmute(u128be)t
		return fmt.tprintf("%32x", b)
	case:
		return ""
	}
	unreachable()
}

binstr_to_address :: proc(binstr: string) -> (address: net.Address) {
	switch len(binstr) {
	case 8:  // IPv4
		a, ok := strconv.parse_u64_of_base(binstr, 16)
		expect(t, ok, "failed to parse test case bin string")

		ipv4 := u32be(a)
		return net.IP4_Address(transmute([4]u8)ipv4)


	case 32: // IPv6
		a, ok := strconv.parse_u128_of_base(binstr, 16)
		expect(t, ok, "failed to parse test case bin string")

		ipv4 := u128be(a)
		return net.IP6_Address(transmute([8]u16be)ipv4)

	case 0:
		return nil
	}
	panic("Invalid test case")
}

IP_Address_Parsing_Test_Vector :: struct {
	family:           net.Address_Family,
	textual:          string,
	binstr:           string,
	should_parse:     bool,   // We expect this to be parsed.
	should_roundtrip: bool,   // We expect this to roundtrip faithfully.
	non_decimal_ipv4: bool,   // IPv4 inet_aton type address
}

IP_Address_Parsing_Test_Vectors :: []IP_Address_Parsing_Test_Vector{
	// dotted-decimal notation
	{ .IP4, "0.0.0.0",                 "00000000", true,  true,  false },
	{ .IP4, "127.0.0.1",               "7f000001", true,  true,  false },
	{ .IP4, "10.0.128.31",             "0a00801f", true,  true,  false },
	{ .IP4, "255.255.255.255",         "ffffffff", true,  true,  false },

	// Odin custom: Address + port, valid
	{ .IP4, "0.0.0.0:80",              "00000000", true,  false, false },
	{ .IP4, "127.0.0.1:80",            "7f000001", true,  false, false },
	{ .IP4, "10.0.128.31:80",          "0a00801f", true,  false, false },
	{ .IP4, "255.255.255.255:80",      "ffffffff", true,  false, false },

	{ .IP4, "[0.0.0.0]:80",            "00000000", true,  false, false },
	{ .IP4, "[127.0.0.1]:80",          "7f000001", true,  false, false },
	{ .IP4, "[10.0.128.31]:80",        "0a00801f", true,  false, false },
	{ .IP4, "[255.255.255.255]:80",    "ffffffff", true,  false, false },

	// Odin custom: Address + port, invalid
	{ .IP4, "[]:80",                   "00000000", false, false, false },
	{ .IP4, "[0.0.0.0]",               "00000000", false, false, false },
	{ .IP4, "[127.0.0.1]:",            "7f000001", false, false, false },
	{ .IP4, "[10.0.128.31] :80",       "0a00801f", false, false, false },
	{ .IP4, "[255.255.255.255]:65536", "ffffffff", false, false, false },


	// numbers-and-dots notation, but not dotted-decimal
	// IMPORTANT: enable when we support `aton`-like addresses
	{ .IP4, "1.2.03.4",                "01020304", true,  false, true  },
	{ .IP4, "1.2.0x33.4",              "01023304", true,  false, true  },
	{ .IP4, "1.2.0XAB.4",              "0102ab04", true,  false, true  },
	{ .IP4, "1.2.0xabcd",              "0102abcd", true,  false, true  },
	{ .IP4, "1.0xabcdef",              "01abcdef", true,  false, true  },
	{ .IP4, "0x01abcdef",              "01abcdef", true,  false, true  },
	{ .IP4, "00377.0x0ff.65534",       "fffffffe", true,  false, true  },

	// invalid as decimal address
	{ .IP4, ".1.2.3",                  "ffffffff", false, false, false },
	{ .IP4, "1..2.3",                  "ffffffff", false, false, false },
	{ .IP4, "1.2.3.",                  "ffffffff", false, false, false },
	{ .IP4, "1.2.3.4.5",               "ffffffff", false, false, false },
	{ .IP4, "1.2.3.a",                 "ffffffff", false, false, false },
	{ .IP4, "1.256.2.3",               "ffffffff", false, false, false },
	{ .IP4, "1.2.4294967296.3",        "ffffffff", false, false, false },
	{ .IP4, "1.2.-4294967295.3",       "ffffffff", false, false, false },
	{ .IP4, "1.2. 3.4",                "ffffffff", false, false, false },

	// invalid as non-decimal address
	{ .IP4, ".1.2.3",                  "ffffffff", false, false, true },
	{ .IP4, "1..2.3",                  "ffffffff", false, false, true },
	{ .IP4, "1.2.3.",                  "ffffffff", false, false, true },
	{ .IP4, "1.2.3.4.5",               "ffffffff", false, false, true },
	{ .IP4, "1.2.3.a",                 "ffffffff", false, false, true },
	{ .IP4, "1.256.2.3",               "ffffffff", false, false, true },
	{ .IP4, "1.2.4294967296.3",        "ffffffff", false, false, true },
	{ .IP4, "1.2.-4294967295.3",       "ffffffff", false, false, true },
	{ .IP4, "1.2. 3.4",                "ffffffff", false, false, true },

/*
	// ipv6
	{ .IP6, ":",                       "",                                 false, false },
	{ .IP6, "::",                      "00000000000000000000000000000000", true,  true  },
	{ .IP6, "::1",                     "00000000000000000000000000000001", true,  true  },
	{ .IP6, ":::",                     "",                                 false, false },
	{ .IP6, "192.168.1.1",             "",                                 false, false },
	{ .IP6, ":192.168.1.1",            "",                                 false, false },
	{ .IP6, "::192.168.1.1",           "000000000000000000000000c0a80101", true,  true  },
	{ .IP6, "0:0:0:0:0:0:192.168.1.1", "000000000000000000000000c0a80101", true,  true  },
	{ .IP6, "0:0::0:0:0:192.168.1.1",  "000000000000000000000000c0a80101", true,  true  },
	{ .IP6, "::012.34.56.78",          "",                                 false, false },
	{ .IP6, ":ffff:192.168.1.1",       "",                                 false, false },
	{ .IP6, "::ffff:192.168.1.1",      "00000000000000000000ffffc0a80101", true,  true  },
	{ .IP6, ".192.168.1.1",            "",                                 false, false },
	{ .IP6, ":.192.168.1.1",           "",                                 false, false },
	{ .IP6, "a:0b:00c:000d:E:F::",     "000a000b000c000d000e000f00000000", true,  true  },
	{ .IP6, "a:0b:00c:000d:0000e:f::", "",                                 false, false },
	{ .IP6, "1:2:3:4:5:6::",           "00010002000300040005000600000000", true,  true  },
	{ .IP6, "1:2:3:4:5:6:7::",         "00010002000300040005000600070000", true,  true  },
	{ .IP6, "1:2:3:4:5:6:7:8::",       "",                                 false, false },
	{ .IP6, "1:2:3:4:5:6:7::9",        "",                                 false, false },
	{ .IP6, "::1:2:3:4:5:6",           "00000000000100020003000400050006", true,  true  },
	{ .IP6, "::1:2:3:4:5:6:7",         "00000001000200030004000500060007", true,  true  },
	{ .IP6, "::1:2:3:4:5:6:7:8",       "",                                 false, false },
	{ .IP6, "a:b::c:d:e:f",            "000a000b00000000000c000d000e000f", true,  true  },
	{ .IP6, "ffff:c0a8:5e4",           "",                                 false, false },
	{ .IP6, ":ffff:c0a8:5e4",          "",                                 false, false },
	{ .IP6, "0:0:0:0:0:ffff:c0a8:5e4", "00000000000000000000ffffc0a805e4", true,  true  },
	{ .IP6, "0:0:0:0:ffff:c0a8:5e4",   "",                                 false, false },
	{ .IP6, "0::ffff:c0a8:5e4",        "00000000000000000000ffffc0a805e4", true,  true  },
	{ .IP6, "::0::ffff:c0a8:5e4",      "",                                 false, false },
	{ .IP6, "c0a8",                    "",                                 false, false },
*/
}