package x509

import "core:bytes"
import "core:crypto/ecdsa"
import "core:crypto/ed25519"
import "core:crypto/hash"
import "core:crypto/rsa"
import "core:net"
import "core:slice"
import "core:strings"
import "core:time"

// valid_at returns true if and only if (⟺) `now` falls within the
// certificate's validity window (inclusive on both ends, per RFC 5280
// section 4.1.2.5). Obtain `now` from e.g. time.now().
@(require_results)
valid_at :: proc "contextless" (cert: ^Certificate, now: time.Time) -> bool {
	return time.diff(cert.not_before, now) >= 0 && time.diff(now, cert.not_after) >= 0
}

// verify_hostname checks `host` against the certificate's subject
// alternative names per RFC 6125:
//
//   - IP-literal hosts match iPAddress SANs by byte equality only.
//   - DNS hosts match dNSName SANs case-insensitively; one wildcard is
//     permitted as the ENTIRE left-most label of the SAN
//     ("*.example.com" matches "a.example.com" but never
//     "a.b.example.com", "example.com", or partial labels like
//     "f*.example.com").
//   - The legacy CommonName fallback is not implemented (deprecated
//     since RFC 6125).
//
// Returns .None on match, .Hostname_Mismatch when SANs of the right
// kind exist but none match, and .No_SAN when the certificate carries
// no SAN of the queried kind.
@(require_results)
verify_hostname :: proc(cert: ^Certificate, host: string) -> Error {
	hostname := strings.trim_suffix(host, ".")

	// IP literal?
	if addr := net.parse_address(hostname); addr != nil {
		if len(cert.ip_addresses) == 0 {
			return .No_SAN
		}
		addr_bytes: [16]byte
		addr_len: int
		switch a in addr {
		case net.IP4_Address:
			tmp := a
			copy(addr_bytes[:], tmp[:])
			addr_len = 4
		case net.IP6_Address:
			tmp := transmute([16]byte)a
			copy(addr_bytes[:], tmp[:])
			addr_len = 16
		}
		for san in cert.ip_addresses {
			if bytes.equal(san, addr_bytes[:addr_len]) {
				return .None
			}
		}
		return .Hostname_Mismatch
	}

	if len(cert.dns_names) == 0 {
		return .No_SAN
	}
	for san in cert.dns_names {
		if _match_hostname(san, hostname) {
			return .None
		}
	}
	return .Hostname_Mismatch
}

// _match_hostname implements the RFC 6125 section 6.4.3 subset described on verify_hostname.
@(private)
_match_hostname :: proc(pattern, host: string) -> bool {
	p := strings.trim_suffix(pattern, ".")
	if len(p) == 0 || len(host) == 0 {
		return false
	}

	// DNS comparisons are ASCII case-insensitive (RFC 4343): dNSNames are
	// IA5String and IDNs travel as punycode A-labels, so `_ascii_eq_fold`is used.
	if !strings.has_prefix(p, "*.") {
		return _ascii_eq_fold(p, host)
	}

	// Wildcard: "*." + base. The host's first label is consumed by the wildcard; the
	// remainder must equal the base, and the wildcard must not swallow more than one label.
	base := p[2:]
	dot := strings.index_byte(host, '.')
	if dot < 1 {
		// No label boundary (or empty first label); a bare host can't match a wildcard.
		return false
	}
	rest := host[dot + 1:]
	if len(rest) == 0 {
		return false
	}
	// The base itself may not contain another wildcard.
	if strings.index_byte(base, '*') >= 0 {
		return false
	}
	return _ascii_eq_fold(base, rest)
}

// ============================================================
// Signature verification and chain (path) validation.
//
// verify_signature checks that `cert`'s signature was produced by the
// private key matching `issuer`'s public key, over cert.raw_tbs (the
// signed TBSCertificate). It checks ONLY the cryptographic signature,
// not validity periods, names, basic constraints, or that `issuer` is
// actually authorized to issue `cert`; verify_chain does all of that.
//
// Returns .None on a good signature, .Signature_Invalid on a bad one, and
// .Unsupported_Algorithm when the signature algorithm (SHA-1, which is rejected
// per RFC 9155; ECDSA P-521; or RSA-PSS with an unrecognized digest) or the
// issuer key type is not implemented here.
@(require_results)
verify_signature :: proc(cert: ^Certificate, issuer: ^Certificate) -> Error {
	#partial switch cert.signature_algorithm {
	case .RSA_SHA1:
		// SHA-1 signatures are deprecated and rejected (RFC 9155); the
		// algorithm is recognized at parse time for identification only.
		return .Unsupported_Algorithm

	case .RSA_SHA256, .RSA_SHA384, .RSA_SHA512:
		if issuer.public_key_algorithm != .RSA {
			// An RSA signature paired with a non-RSA issuer key can never verify.
			return .Unsupported_Algorithm
		}
		pub: rsa.Public_Key
		if !rsa.public_key_set_bytes(&pub, issuer.rsa_n, issuer.rsa_e) {
			return .Signature_Invalid
		}
		h := _hash_for_rsa(cert.signature_algorithm)
		if !rsa.verify_pkcs1(&pub, h, cert.raw_tbs, cert.signature) {
			return .Signature_Invalid
		}
		return .None

	case .RSA_PSS:
		if issuer.public_key_algorithm != .RSA {
			return .Unsupported_Algorithm
		}
		// The parser decodes the RSASSA-PSS-params into cert.pss_*, leaving a
		// digest it cannot verify as .Invalid; SHA-1 is likewise rejected 
		// (RFC 9155), for the message digest or the MGF.
		if cert.pss_hash == .Invalid || cert.pss_mgf_hash == .Invalid {
			return .Unsupported_Algorithm
		}
		if cert.pss_hash == .Insecure_SHA1 || cert.pss_mgf_hash == .Insecure_SHA1 {
			return .Unsupported_Algorithm
		}
		pub: rsa.Public_Key
		if !rsa.public_key_set_bytes(&pub, issuer.rsa_n, issuer.rsa_e) {
			return .Signature_Invalid
		}
		if !rsa.verify_pss(&pub, cert.pss_hash, cert.pss_salt_len, cert.raw_tbs, cert.signature, mgf1_algo = cert.pss_mgf_hash) {
			return .Signature_Invalid
		}
		return .None

	case .ECDSA_SHA256, .ECDSA_SHA384, .ECDSA_SHA512:
		curve: ecdsa.Curve
		#partial switch issuer.public_key_algorithm {
		case .ECDSA_P256:
			curve = .SECP256R1
		case .ECDSA_P384:
			curve = .SECP384R1
		case:
			// P-521 (unsupported by the verifier) or a non-EC issuer key paired with an ECDSA signature.
			return .Unsupported_Algorithm
		}
		h := _hash_for_ecdsa(cert.signature_algorithm)
		pub: ecdsa.Public_Key
		if !ecdsa.public_key_set_bytes(&pub, curve, issuer.ec_point) {
			return .Signature_Invalid
		}
		if !ecdsa.verify_asn1(&pub, h, cert.raw_tbs, cert.signature) {
			return .Signature_Invalid
		}
		return .None

	case .Ed25519:
		if issuer.public_key_algorithm != .Ed25519 {
			return .Unsupported_Algorithm
		}
		pub: ed25519.Public_Key
		if !ed25519.public_key_set_bytes(&pub, issuer.ec_point) {
			return .Signature_Invalid
		}
		if !ed25519.verify(&pub, cert.raw_tbs, cert.signature) {
			return .Signature_Invalid
		}
		return .None
	}
	return .Unsupported_Algorithm
}

@(private)
_hash_for_ecdsa :: proc "contextless" (s: Signature_Algorithm) -> hash.Algorithm {
	#partial switch s {
	case .ECDSA_SHA384:
		return .SHA384
	case .ECDSA_SHA512:
		return .SHA512
	}
	return .SHA256
}

// _hash_for_rsa maps an RSA PKCS#1 v1.5 signature algorithm to its message
// digest. RSA_SHA1 is rejected before reaching here (see verify_signature).
@(private)
_hash_for_rsa :: proc "contextless" (s: Signature_Algorithm) -> hash.Algorithm {
	#partial switch s {
	case .RSA_SHA384:
		return .SHA384
	case .RSA_SHA512:
		return .SHA512
	}
	return .SHA256
}

// Verify_Options parameterizes verify_chain.
Verify_Options :: struct {
	// Trust anchors. A chain is accepted iff it terminates at one of
	// these (matched by name + signature, as ordinary issuers). Usually
	// self-signed roots, but any certificate trusted a priori works.
	roots:         []^Certificate,
	// Untrusted intermediates available to bridge the leaf to a root.
	// Order does not matter; verify_chain searches them.
	intermediates: []^Certificate,
	// Reference time for every certificate's validity window.
	current_time:  time.Time,
	// If non-empty, the leaf must pass verify_hostname for this name.
	dns_name:      string,
	// If set, the leaf's ExtKeyUsage must permit this purpose (a leaf
	// with no EKU extension is unrestricted and always passes). TLS
	// clients pass .Server_Auth.
	required_eku:  Maybe(EKU_Bit),
}

// _MAX_CHAIN_DEPTH bounds path search depth, to stop cycles among
// mutually-issuing intermediates.
@(private)
_MAX_CHAIN_DEPTH :: 10

// _MAX_SIG_CHECKS caps the total number of signature verifications a
// single verify_chain may perform across its entire path search.
// Guard for path-building denial of service, RFC 4158 section 2.4.2.
@(private)
_MAX_SIG_CHECKS :: 100

// verify_chain builds and validates a certificate path from `leaf` to
// one of opts.roots, using opts.intermediates to bridge the gap. On
// success it returns the verified chain leaf-first (chain[0] == leaf,
// chain[len-1] is the trust anchor); the slice is allocated & freed.
//
// Each non-anchor certificate in the path is checked for:
// - validity at opts.current_time;
// - Signature verifies against the next certificate's key;
// - Name chaining (issuer DN == subject DN);
// For every intermediate issuer:
// - It is a CA (basicConstraints);
// - Is within pathLenConstraint (counting only non-self-issued
//   intermediates, per RFC 5280 section 6.1.4);
// - if it declares KeyUsage: permits keyCertSign.

// A certificate carrying a critical extension this package does not
// interpret fails the path closed (see .Unhandled_Critical_Extension).
// When opts.dns_name is set the leaf must pass verify_hostname; when
// opts.required_eku is set the leaf AND every intermediate must permit
// that purpose (e.g. an email-only sub-CA cannot issue a TLS server leaf).
//
// The trust anchor is treated as trusted input: it must be valid at 
// opts.current_time and is name-chained + signature-checked as the issuer 
// below it, but its CA authorization (basicConstraints / keyCertSign /
// pathLenConstraint) and its own self-signature are NOT re-checked. 
// An expired anchor is still rejected; resilience to that comes
// from the search trying every other available anchor and intermediate.
//
@(require_results)
verify_chain :: proc(
	leaf: ^Certificate,
	opts: Verify_Options,
	allocator := context.allocator,
) -> (
	chain: []^Certificate,
	err: Error,
) {
	// Leaf-definitive checks
	if leaf.unhandled_critical {
		return nil, .Unhandled_Critical_Extension
	}
	if verr := _check_validity(leaf, opts.current_time); verr != .None {
		return nil, verr
	}
	// A leaf signed with an algorithm the verifier cannot check (RSA-PSS with
	// an unrecognized digest, ECDSA P-521) surfaces via `saw_unsupported` from
	// the per-edge verify_signature call, so an unbuildable path still returns
	// .Unsupported_Algorithm.
	if opts.dns_name != "" {
		if herr := verify_hostname(leaf, opts.dns_name); herr != .None {
			return nil, herr
		}
	}

	// Reserve the whole path up front: with capacity in hand, the appends below should never 
	// reallocate, so single point of OOM risk
	acc, aerr := make([dynamic]^Certificate, 0, _MAX_CHAIN_DEPTH + 1, allocator)
	if aerr != nil {
		return nil, .Allocation_Failed
	}
	append(&acc, leaf)

	saw_unsupported := false
	saw_eku_reject := false
	opts_local := opts
	budget := _MAX_SIG_CHECKS
	if _build_to_anchor(leaf, &opts_local, &acc, 0, &saw_unsupported, &saw_eku_reject, &budget) {
		// Success: caller owns the returned chain.
		// EKU nesting (leaf + every intermediate permits opts.required_eku)
		// was enforced as a usability gate during the search itself, so any
		// path returned here already satisfies it.
		return acc[:], .None
	}
	delete(acc)
	// An unimplemented signature algorithm is a hard capability gap and
	// outranks the EKU policy mismatch; both outrank the generic failure.
	switch {
	case saw_unsupported:
		return nil, .Unsupported_Algorithm
	case saw_eku_reject:
		return nil, .Incompatible_Usage
	case:
		return nil, .Unknown_Authority
	}
}

// Performs a depth-first search for a path from `cert` up to a trust anchor. 
// `acc` holds the chain so far, leaf-first and including `cert`; on success 
// the matched issuers (ending at the anchor) are appended. `depth` is the 
// recursion depth and len(acc) - 1 is the number of intermediates already 
// below the next issuer (used for pathLenConstraint). `budget` is the shared
// remaining signature-verification allowance (see _MAX_SIG_CHECKS); when it is
// exhausted the search stops. `saw_unsupported` / `saw_eku_reject` are
// set when a branch was abandoned only because the signature algorithm
// was unimplemented, or because a cert failed the required-EKU check, so
// verify_chain can report the more specific error when no path is found.
@(private)
_build_to_anchor :: proc(
	cert: ^Certificate,
	opts: ^Verify_Options,
	acc: ^[dynamic]^Certificate,
	depth: int,
	saw_unsupported: ^bool,
	saw_eku_reject: ^bool,
	budget: ^int,
) -> (found: bool) {
	if depth >= _MAX_CHAIN_DEPTH {
		return false
	}

	// EKU nesting: when the caller requires a purpose, the leaf and every
	// intermediate must permit it. `cert` here is always the leaf (depth 0)
	// or an intermediate being extended through, so anchors stay exempt. 
	// Enforcing EKU as a usability gate lets the search backtrack and try an 
	// alternative issuer that does permit the purpose (two same-subject/same-key 
	// intermediates can differ in EKU); a post-build filter would instead commit 
	// to whichever path was found first and reject the whole verification.
	if eku_ask, ok := opts.required_eku.?; ok {
		if !_permits_eku(cert, eku_ask) {
			saw_eku_reject^ = true
			return false
		}
	}

	// Non-self-issued intermediates already beneath the next issuer, for the pathLenConstraint check (RFC 5280 section 6.1.4)
	below := _non_self_issued_below(acc)

	// Prefer terminating at a trust anchor. The anchor must have issued `cert`
	// (name chaining + signature) and be valid at `now`, but as TRUSTED INPUT
	// its CA authorization (basicConstraints / keyCertSign / pathLenConstraint)
	// and its own self-signature are NOT re-checked. See _anchor_usable.
	for root in opts.roots {
		if !_is_issuer_of(root, cert) || !_anchor_usable(root, opts.current_time) {
			continue
		}
		if budget^ <= 0 {
			return false
		}
		budget^ -= 1
		#partial switch verify_signature(cert, root) {
		case .None:
			append(acc, root)
			// Chain is complete: enforce every CA's name constraints over it.
			// On violation, keep searching — a different anchor/path may satisfy them.
			if _check_name_constraints(acc[:]) {
				return true
			}
			pop(acc)
		case .Unsupported_Algorithm:
			saw_unsupported^ = true
		case:
		// bad signature: not this anchor
		}
	}

	// Otherwise extend through an untrusted intermediate and recurse.
	for inter in opts.intermediates {
		if inter == cert || slice.contains(acc[:], inter) {
			continue
		}
		if !_is_issuer_of(inter, cert) || !_issuer_usable(inter, opts.current_time, below) {
			continue
		}
		if budget^ <= 0 {
			return false
		}
		budget^ -= 1
		#partial switch verify_signature(cert, inter) {
		case .None:
			append(acc, inter)
			if _build_to_anchor(inter, opts, acc, depth + 1, saw_unsupported, saw_eku_reject, budget) {
				return true
			}
			pop(acc) // backtrack
		case .Unsupported_Algorithm:
			saw_unsupported^ = true
		case:
		// bad signature: not this issuer
		}
	}
	return false
}

@(private)
_check_validity :: proc "contextless" (cert: ^Certificate, now: time.Time) -> Error {
	if time.diff(now, cert.not_before) > 0 {
		return .Not_Yet_Valid
	}
	if time.diff(cert.not_after, now) > 0 {
		return .Expired
	}
	return .None
}

// Reports whether `issuer` could have issued `cert`: the issuer's 
// subject DN must equal cert's issuer DN (RFC 5280 section 6.1
// name chaining, by binary DER comparison). The authority/subject key
// identifiers are NOT used as a filter, RFC 5280 section 4.2.1.1 
// (and RFC 4158) make them a non-authoritative path-building hint.
@(private)
_is_issuer_of :: proc(issuer, cert: ^Certificate) -> bool {
	return bytes.equal(issuer.raw_subject, cert.raw_issuer)
}

// Counts the non-self-issued intermediates already in the path below 
// the next issuer, i.e. everything in `acc` except the leaf (index 0). 
// A self-issued certificate (subject DN == issuer DN, used for CA key 
// rollover) does not count against pathLenConstraint (RFC 5280 sections 
// 4.2.1.9 and 6.1.4(l)).
@(private)
_non_self_issued_below :: proc(acc: ^[dynamic]^Certificate) -> int {
	n := 0
	// Skip the leaf at index 0; it is the end-entity, not an intermediate.
	for i in 1 ..< len(acc) {
		c := acc[i]
		if !bytes.equal(c.raw_subject, c.raw_issuer) {
			n += 1
		}
	}
	return n
}

// Applies the RFC 5280 section 6.1.4 checks to an INTERMEDIATE issuer: 
// a CA with (if asserted) keyCertSign, valid at `now`, within its 
// pathLenConstraint given `below` non-self-issued intermediates beneath 
// it, and with no uninterpreted critical extension.
@(private)
_issuer_usable :: proc(issuer: ^Certificate, now: time.Time, below: int) -> bool {
	if issuer.unhandled_critical {
		return false
	}
	// Name constraints asserted by this issuer are enforced on the completed
	// chain (see _check_name_constraints), so an NC-bearing CA is usable here.
	if !issuer.basic_constraints_valid || !issuer.is_ca {
		return false
	}
	if issuer.has_key_usage && .Key_Cert_Sign not_in issuer.key_usage {
		return false
	}
	if issuer.max_path_len >= 0 && below > issuer.max_path_len {
		return false
	}
	if _check_validity(issuer, now) != .None {
		return false
	}
	return true
}

// The anchor is trusted input, so unlike _issuer_usable its CA authorization
// (basicConstraints / keyCertSign / pathLenConstraint) and self-signature are
// NOT re-checked. Still required: valid at `now` (resilience to an expired
// anchor comes from the search trying other anchors/intermediates) and no
// uninterpreted critical extension. Any nameConstraints it asserts are
// enforced on the completed chain (see _check_name_constraints).
@(private)
_anchor_usable :: proc(anchor: ^Certificate, now: time.Time) -> bool {
	if anchor.unhandled_critical {
		return false
	}
	if _check_validity(anchor, now) != .None {
		return false
	}
	return true
}

// Reports whether `cert` allows the given Extended Key Usage purpose: 
// no EKU extension means unrestricted, anyExtendedKeyUsage
// permits everything, otherwise the purpose must be listed. Applied to
// the leaf and every intermediate for EKU nesting (see verify_chain).
@(private)
_permits_eku :: proc(cert: ^Certificate, ask: EKU_Bit) -> bool {
	if !cert.has_ext_key_usage {
		return true // no EKU extension: unrestricted
	}
	if .Any in cert.ext_key_usage {
		return true
	}
	return ask in cert.ext_key_usage
}
