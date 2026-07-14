package test_x509_limbo

// Differential conformance harness for core:crypto/x509 verify_chain against the
// C2SP x509-limbo corpus.
//
//   Fetch the corpus (once):
//     curl -sL https://raw.githubusercontent.com/C2SP/x509-limbo/main/limbo.json \
//       -o tests/core/assets/X509-Limbo/limbo.json
//   Run:
//     odin test tests/core/crypto/x509_limbo -o:speed
//
// When the corpus is absent the suite logs a notice and passes, so a plain
// `odin test` does not break. Reviewed divergences are in allow.odin. 
// Any test case failure not in the allow.odin should be considered a regression.

import "core:log"
import "core:mem"
import "core:os"
import "core:slice"
import "core:testing"
import "core:time"

import "core:crypto/x509"
import "core:encoding/pem"

BASE_PATH :: ODIN_ROOT + "tests/core/assets/X509-Limbo"

// 2024-01-01T00:00:00Z, x509-limbo's default validation instant for cases whose
// validation_time is null.
DEFAULT_TIME :: i64(1_704_067_200)

// Arena for the parsed 41 MB corpus (strings + case structs).
CORPUS_ARENA_SIZE :: 5 * 41 * (1024 * 1024)

Bucket :: enum {
	Agree, // our verdict matches expected_result
	Skip, // the chain uses an algorithm we do not verify (P-521 / Ed448 / DSA)
	We_Accept_They_Reject, // DANGEROUS: expected FAILURE, we accepted
	We_Reject_They_Accept, // safe/stricter: expected SUCCESS, we rejected
}

@(test)
test_x509_limbo :: proc(t: ^testing.T) {
	arena: mem.Arena
	backing, berr := make([]byte, CORPUS_ARENA_SIZE)
	if berr != nil {
		log.errorf("x509-limbo: could not reserve %d bytes", CORPUS_ARENA_SIZE)
		return
	}
	defer delete(backing)
	mem.arena_init(&arena, backing)
	context.allocator = mem.arena_allocator(&arena)

	path, _ := os.join_path([]string{BASE_PATH, "limbo.json"}, context.allocator)

	corpus: Limbo
	if !load(&corpus, path) {
		log.infof("x509-limbo corpus not found at %s; skipping (fetch from C2SP/x509-limbo)", path)
		return
	}

	counts: [Bucket]int
	// These outlive the per-case temp resets, so back them with the corpus arena.
	unexpected_accept := make([dynamic]string)
	unexpected_reject := make([dynamic]string)

	for &tc in corpus.testcases {
		bucket := run_case(&tc)
		counts[bucket] += 1
		#partial switch bucket {
		case .We_Accept_They_Reject:
			if !slice.contains(ACCEPT_ALLOW, tc.id) {
				append(&unexpected_accept, tc.id)
			}
		case .We_Reject_They_Accept:
			if !slice.contains(REJECT_ALLOW, tc.id) {
				append(&unexpected_reject, tc.id)
			}
		}
		free_all(context.temp_allocator)
	}

	log.infof(
		"x509-limbo: %d cases | agree %d | skip %d | we-accept/they-reject %d | we-reject/they-accept %d",
		len(corpus.testcases),
		counts[.Agree],
		counts[.Skip],
		counts[.We_Accept_They_Reject],
		counts[.We_Reject_They_Accept],
	)

	// Security-critical gate: no un-reviewed chain we accept that limbo rejects.
	for id in unexpected_accept {
		testing.expectf(t, false, "x509-limbo REGRESSION (we accept, limbo rejects): %s", id)
	}
	// Over-rejection gate (safe direction, but still a reviewed-set change).
	for id in unexpected_reject {
		testing.expectf(t, false, "x509-limbo over-rejection (we reject, limbo accepts): %s", id)
	}
}

// run_case parses a testcase's certificates, runs verify_chain, and buckets the
// verdict against the case's expected_result. All per-case allocation uses the
// temp allocator, reset by the caller after each case.
run_case :: proc(tc: ^Testcase) -> Bucket {
	expect_ok := tc.expected_result == "SUCCESS"

	// Fixed backing keeps ^Certificate addresses stable; chains are tiny.
	store: [64]x509.Certificate
	n := 0

	leaf: ^x509.Certificate
	inters:= make([dynamic]^x509.Certificate,context.temp_allocator)
	roots:= make([dynamic]^x509.Certificate,context.temp_allocator)

	// A cert that fails to parse (or overflows the backing) means we reject.
	if lp := _add_pems(store[:], &n, tc.peer_certificate, nil); lp == nil {
		return _verdict(false, expect_ok)
	} else {
		leaf = lp
	}
	for s in tc.untrusted_intermediates {
		if _add_pems(store[:], &n, s, &inters) == nil {
			return _verdict(false, expect_ok)
		}
	}
	for s in tc.trusted_certs {
		if _add_pems(store[:], &n, s, &roots) == nil {
			return _verdict(false, expect_ok)
		}
	}

	// Skip chains that use an algorithm the verifier cannot check; verify_chain
	// would report Unsupported_Algorithm, which is neither accept nor reject.
	for &c in store[:n] {
		if !_supported_key(c.public_key_algorithm) {
			return .Skip
		}
	}
	if !_supported_sig(leaf.signature_algorithm) {
		return .Skip
	}
	for c in inters {
		if !_supported_sig(c.signature_algorithm) {
			return .Skip
		}
	}

	now := DEFAULT_TIME
	if tc.validation_time != "" {
		if tm, consumed := time.rfc3339_to_time_utc(tc.validation_time); consumed > 0 {
			now = time.to_unix_seconds(tm)
		}
	}

	opts := x509.Verify_Options {
		roots         = roots[:],
		intermediates = inters[:],
		current_time  = time.unix(now, 0),
	}
	if tc.expected_peer_name.kind != "" && tc.expected_peer_name.value != "" {
		opts.dns_name = tc.expected_peer_name.value
	}
	// limbo's SERVER profile implies the serverAuth EKU (webpki / CABF).
	if tc.validation_kind == "SERVER" {
		opts.required_eku = .Server_Auth
	}

	// The chain is temp-allocated; the caller's per-case free_all reclaims it.
	_, verr := x509.verify_chain(leaf, opts, context.temp_allocator)
	return _verdict(verr == .None, expect_ok)
}

// _add_pems decodes every PEM block in `s` into `store` (bumping `n`), appending
// each parsed cert's pointer to `out` when non-nil, and returns the first cert's
// pointer (nil on any parse failure or backing overflow). A single limbo field
// may hold a bundle of concatenated certificates.
_add_pems :: proc(
	store: []x509.Certificate,
	n: ^int,
	s: string,
	out: ^[dynamic]^x509.Certificate,
) -> ^x509.Certificate {
	first: ^x509.Certificate
	data := transmute([]byte)s
	for len(data) > 0 {
		blk, rest, derr := pem.decode(data, context.temp_allocator)
		if derr != nil || blk == nil {
			break // no more blocks
		}
		data = rest
		if n^ >= len(store) {
			return nil
		}
		c, perr := x509.parse(pem.block_bytes(blk), context.temp_allocator)
		if perr != .None {
			return nil
		}
		store[n^] = c
		p := &store[n^]
		n^ += 1
		if first == nil {
			first = p
		}
		if out != nil {
			append(out, p)
		}
	}
	return first
}

_verdict :: proc(our_ok, expect_ok: bool) -> Bucket {
	switch {
	case our_ok == expect_ok:
		return .Agree
	case our_ok && !expect_ok:
		return .We_Accept_They_Reject
	case:
		return .We_Reject_They_Accept
	}
}

_supported_key :: proc(a: x509.Public_Key_Algorithm) -> bool {
	return a == .RSA || a == .ECDSA_P256 || a == .ECDSA_P384 || a == .Ed25519
}

_supported_sig :: proc(a: x509.Signature_Algorithm) -> bool {
	#partial switch a {
	case .RSA_SHA1, .RSA_SHA256, .RSA_SHA384, .RSA_SHA512, .RSA_PSS:
		return true
	case .ECDSA_SHA256, .ECDSA_SHA384, .ECDSA_SHA512, .Ed25519:
		return true
	}
	return false
}
