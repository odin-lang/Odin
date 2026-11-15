package test_core_net

import "core:mem"
import "core:net"
import "core:testing"

@(private)
SRV_RESPONSE :: [?]u8{
	0, 0, 0x81, 0x80, 0, 1, 0, 1, 0, 0, 0, 0,
	4, '_', 's', 'i', 'p', 4, '_', 't', 'c', 'p', 7, 'e', 'x', 'a', 'm', 'p', 'l', 'e', 0, 0, 0x21, 0, 1,
	0xC0, 0x0C, 0, 0x21, 0, 1, 0, 0, 0, 60, 0, 12,
	0, 10, 0, 5, 0x13, 0xC4, 4, 'h', 'o', 's', 't', 0,
}

@(private)
SRV_RESPONSE_TWO_LABELS :: [?]u8{
	0, 0, 0x81, 0x80, 0, 1, 0, 1, 0, 0, 0, 0,
	4, '_', 's', 'i', 'p', 7, 'e', 'x', 'a', 'm', 'p', 'l', 'e', 0, 0, 0x21, 0, 1,
	0xC0, 0x0C, 0, 0x21, 0, 1, 0, 0, 0, 60, 0, 12,
	0, 10, 0, 5, 0x13, 0xC4, 4, 'h', 'o', 's', 't', 0,
}

@(private)
A_THEN_TRUNCATED_RESPONSE :: [?]u8{
	0, 0, 0x81, 0x80, 0, 1, 0, 2, 0, 0, 0, 0,
	0, 0, 1, 0, 1,
	0, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4, 127, 0, 0, 2,
	0, 0, 1,
}

@test
test_dns_srv_names_outlive_temp_allocator :: proc(t: ^testing.T) {
	packet := SRV_RESPONSE
	records, _, ok := net.parse_response(packet[:], .SRV)
	defer net.destroy_dns_records(records)
	if !testing.expect(t, ok) || !testing.expect_value(t, len(records), 1) {
		return
	}

	free_all(context.temp_allocator)
	scribble := make([]u8, 4096, context.temp_allocator)
	for &b in scribble {
		b = 'x'
	}

	srv := records[0].(net.DNS_Record_SRV)
	testing.expect_value(t, srv.record_name,   "_sip._tcp.example")
	testing.expect_value(t, srv.service_name,  "_sip")
	testing.expect_value(t, srv.protocol_name, "_tcp")
	testing.expect_value(t, srv.target,        "host")
	testing.expect_value(t, srv.priority,      10)
	testing.expect_value(t, srv.weight,        5)
	testing.expect_value(t, srv.port,          5060)
}

@test
test_dns_parse_failure_frees_records :: proc(t: ^testing.T) {
	a_then_truncated := A_THEN_TRUNCATED_RESPONSE
	srv_two_labels   := SRV_RESPONSE_TWO_LABELS

	cases := [?]struct {
		packet: []u8,
		filter: net.DNS_Record_Type,
	}{
		{a_then_truncated[:], .IP4},
		{srv_two_labels[:],   .SRV},
	}

	for c in cases {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)

		records, _, ok := net.parse_response(c.packet, c.filter, mem.tracking_allocator(&track))
		testing.expect(t, !ok)
		testing.expect_value(t, len(records), 0)
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
	}
}
