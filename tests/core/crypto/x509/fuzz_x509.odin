package test_core_x509

// Deterministic mutational fuzzing for the certificate parser, seeded
// (and reproducible) via the test runner's logged random seed.
//
// Invariants on every input: parse never panics, never reads outside
// the input (bounds checks + address sanitizer in CI), never leaks on
// error paths (the runner's tracking allocator), and on success every
// raw view lies within the input buffer.

import "core:crypto/x509"
import "core:math/rand"
import "core:testing"

FUZZ_MUTATE_ITERS :: 1500
FUZZ_RANDOM_ITERS :: 2048

// _check_views asserts that a successfully-parsed Certificate only
// references memory inside its input.
@(private="file")
_check_views :: proc(t: ^testing.T, cert: ^x509.Certificate, der: []byte) {
	in_bounds :: proc(view: []byte, der: []byte) -> bool {
		if len(view) == 0 {
			return true
		}
		base := uintptr(raw_data(der))
		view_start := uintptr(raw_data(view))
		return view_start >= base && view_start + uintptr(len(view)) <= base + uintptr(len(der))
	}

	testing.expect(t, in_bounds(cert.raw, der), "raw out of bounds")
	testing.expect(t, in_bounds(cert.raw_tbs, der), "raw_tbs out of bounds")
	testing.expect(t, in_bounds(cert.raw_issuer, der), "raw_issuer out of bounds")
	testing.expect(t, in_bounds(cert.raw_subject, der), "raw_subject out of bounds")
	testing.expect(t, in_bounds(cert.raw_spki, der), "raw_spki out of bounds")
	testing.expect(t, in_bounds(cert.serial, der), "serial out of bounds")
	testing.expect(t, in_bounds(cert.signature, der), "signature out of bounds")
	testing.expect(t, cert.version >= 1 && cert.version <= 3, "version range")
	for name in cert.dns_names {
		testing.expect(t, in_bounds(transmute([]byte)name, der), "dns name out of bounds")
	}
	for ip in cert.ip_addresses {
		testing.expect(t, in_bounds(ip, der), "ip out of bounds")
		testing.expect(t, len(ip) == 4 || len(ip) == 16, "ip width")
	}
	for ext in cert.extensions {
		testing.expect(t, in_bounds(ext.oid, der), "ext oid out of bounds")
		testing.expect(t, in_bounds(ext.value, der), "ext value out of bounds")
	}
}

// Every single-bit flip of a real certificate: parse must fail cleanly
// or succeed with intact invariants.
@(test)
test_fuzz_bitflips :: proc(t: ^testing.T) {
	buf := make([]byte, len(EC_DER))
	defer delete(buf)

	for i in 0 ..< len(EC_DER) {
		for bit in 0 ..< uint(8) {
			copy(buf, EC_DER)
			buf[i] ~= 1 << bit
			cert, err := x509.parse(buf)
			if err == .None {
				_check_views(t, &cert, buf)
				x509.destroy(&cert)
			}
		}
	}
}

// Random multi-byte mutations across all three fixtures.
@(test)
test_fuzz_mutations :: proc(t: ^testing.T) {
	fixtures := [?][]byte{RSA_DER, EC_DER, ED_DER}

	max_len := 0
	for f in fixtures {
		max_len = max(max_len, len(f))
	}
	buf := make([]byte, max_len)
	defer delete(buf)

	for _ in 0 ..< FUZZ_MUTATE_ITERS {
		fixture := rand.choice(fixtures[:])
		input := buf[:len(fixture)]
		copy(input, fixture)

		// Mutate 1-16 positions, occasionally truncating instead —
		// length-field damage is where TLV parsers historically break.
		if rand.int_max(8) == 0 {
			input = input[:rand.int_max(len(input) + 1)]
		}
		for _ in 0 ..< 1 + rand.int_max(16) {
			if len(input) == 0 {
				break
			}
			input[rand.int_max(len(input))] = byte(rand.uint32())
		}

		cert, err := x509.parse(input)
		if err == .None {
			_check_views(t, &cert, input)
			x509.destroy(&cert)
		}
	}
}

// Pure noise: parse must reject (or, vanishingly unlikely, accept with
// invariants intact) without panicking.
@(test)
test_fuzz_random_garbage :: proc(t: ^testing.T) {
	buf: [128]byte

	for _ in 0 ..< FUZZ_RANDOM_ITERS {
		n := rand.int_max(len(buf) + 1)
		input := buf[:n]
		for i in 0 ..< n {
			input[i] = byte(rand.uint32())
		}
		// Bias towards the outer shape so mutation reaches the TBS walk.
		if n > 4 && rand.int_max(2) == 0 {
			input[0] = 0x30
			input[1] = byte(rand.int_max(n))
		}

		cert, err := x509.parse(input)
		if err == .None {
			_check_views(t, &cert, input)
			x509.destroy(&cert)
		}
	}
}
