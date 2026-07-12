package x509

import "core:bytes"
import "core:encoding/asn1"

// Name-constraint processing (RFC 5280 section 4.2.1.10 + the section 6.1.4
// path-validation checks), scoped to the dNSName and iPAddress GeneralName
// forms. A NameConstraints extension that uses any other base form 
// (directoryName, rfc822Name, uniformResourceIdentifier, otherName, …), a 
// non-zero minimum, a maximum, or that fails to decode causes the whole chain 
// to be rejected (fail closed): we never accept a constraint we cannot fully 
// evaluate.

// GeneralName context tags used in NameConstraints (X.509 GeneralName CHOICE).
@(private)
_GN_OTHER_NAME :: 0 // otherName        [0] (constructed)
@(private)
_GN_RFC822 :: 1     // rfc822Name       [1]
@(private)
_GN_DNS :: 2        // dNSName          [2]
@(private)
_GN_DIR :: 4        // directoryName    [4] (constructed)
@(private)
_GN_URI :: 6        // uniformResourceIdentifier [6]
@(private)
_GN_IP :: 7         // iPAddress        [7]

// _check_name_constraints enforces every NameConstraints extension in `chain`
// (leaf at index 0, trust anchor last). Each CA's constraints apply to every
// certificate below it; checking each CA independently against each
// subordinate yields the RFC 5280 permitted=intersection / excluded=union
// semantics without accumulator state. Returns true when the chain is
// acceptable, false when a name is forbidden (or a constraint cannot be
// evaluated, in which case we reject rather than guess).
@(private)
_check_name_constraints :: proc(chain: []^Certificate) -> bool {
	// RFC 5280 4.2.1.10: NameConstraints MUST appear only in a CA certificate.
	// A non-CA end entity that carries it is malformed — reject the chain.
	if _, leaf_has := _find_name_constraints(chain[0]); leaf_has && !chain[0].is_ca {
		return false
	}
	// ci walks the CAs (anchor down to the first intermediate above the leaf);
	// the leaf (index 0) never constrains.
	for ci := len(chain) - 1; ci >= 1; ci -= 1 {
		nc, has := _find_name_constraints(chain[ci])
		if !has {
			continue
		}
		if !_nc_decidable(nc) {
			return false // a form/feature we cannot evaluate: fail closed
		}
		for sub := ci - 1; sub >= 0; sub -= 1 {
			c := chain[sub]
			// RFC 5280 section 6.1.4(b): constraints are not applied to a
			// self-issued intermediate, only to the final (leaf) certificate.
			if sub != 0 && bytes.equal(c.raw_subject, c.raw_issuer) {
				continue
			}
			if !_names_permitted(nc, c) {
				return false
			}
		}
	}
	return true
}

// _find_name_constraints returns the raw extnValue DER of the cert's
// NameConstraints extension, if present.
@(private)
_find_name_constraints :: proc(cert: ^Certificate) -> (der: []byte, ok: bool) {
	for ext in cert.extensions {
		if bytes.equal(ext.oid, _OID_EXT_NAME_CONSTRAINTS) {
			return ext.value, true
		}
	}
	return nil, false
}

// _names_permitted checks a subordinate certificate's dNSName and iPAddress
// SANs against one CA's NameConstraints: each name form, when the CA lists
// permitted subtrees for it, must match at least one; and no name may match an
// excluded subtree.
@(private)
_names_permitted :: proc(nc: []byte, sub: ^Certificate) -> bool {
	for dns in sub.dns_names {
		if _nc_section_has(nc, false, _GN_DNS) && !_nc_dns_match(nc, false, dns) {
			return false
		}
		if _nc_dns_match(nc, true, dns) {
			return false
		}
	}
	for ip in sub.ip_addresses {
		if _nc_section_has(nc, false, _GN_IP) && !_nc_ip_match(nc, false, ip) {
			return false
		}
		if _nc_ip_match(nc, true, ip) {
			return false
		}
	}
	return true
}

// _nc_decidable structurally validates a NameConstraints and reports whether we
// can fully evaluate it. It returns false, so the caller fails closed, when the
// extension is malformed (an element other than permittedSubtrees [0] /
// excludedSubtrees [1], neither section present, or an empty GeneralSubtrees,
// which SIZE (1..MAX) forbids), or when a subtree uses a base form other than
// dNSName / iPAddress or carries a minimum/maximum (barred by the RFC 5280
// profile). Only a NameConstraints whose every subtree is a bare
// dNSName/iPAddress is decidable.
@(private)
_nc_decidable :: proc(nc: []byte) -> bool {
	cur: asn1.Cursor
	asn1.cursor_init(&cur, nc)
	seq, e := asn1.read_sequence(&cur)
	if e != .None || asn1.done(&cur) != .None {
		return false
	}
	sections := 0
	for !asn1.is_empty(&seq) {
		tag, content, re := asn1.read_any(&seq)
		if re != .None {
			return false
		}
		// The only permitted members are permittedSubtrees [0] / excludedSubtrees
		// [1]; a NULL or any other element (CABF 7.1.2.5.2) is malformed.
		if tag.class != .Context_Specific || (tag.number != 0 && tag.number != 1) {
			return false
		}
		sections += 1
		if !_nc_section_wellformed(content) {
			return false
		}
	}
	return sections > 0
}

// _nc_section_wellformed checks one GeneralSubtrees body: at least one subtree
// (SIZE (1..MAX)), every base a bare dNSName/iPAddress, no minimum/maximum.
@(private)
_nc_section_wellformed :: proc(content: []byte) -> bool {
	cur: asn1.Cursor
	asn1.cursor_init(&cur, content)
	count := 0
	for !asn1.is_empty(&cur) {
		gs, e := asn1.read_sequence(&cur)
		if e != .None {
			return false
		}
		count += 1
		tag, _, be := asn1.read_any(&gs)
		if be != .None || tag.class != .Context_Specific {
			return false
		}
		if tag.number != _GN_DNS && tag.number != _GN_IP {
			return false // directoryName / rfc822 / URI / otherName / …
		}
		// minimum [0] / maximum [1] must both be absent (RFC 5280 profile).
		if asn1.done(&gs) != .None {
			return false
		}
	}
	return count > 0
}

// _nc_section returns the raw content octets of the permitted [0] (or excluded
// [1]) GeneralSubtrees, i.e. the concatenation of GeneralSubtree elements.
@(private)
_nc_section :: proc(nc: []byte, excluded: bool) -> (content: []byte, present: bool) {
	want := u32(excluded ? 1 : 0)
	cur: asn1.Cursor
	asn1.cursor_init(&cur, nc)
	seq, e := asn1.read_sequence(&cur)
	if e != .None {
		return nil, false
	}
	for !asn1.is_empty(&seq) {
		tag, c, re := asn1.read_any(&seq)
		if re != .None {
			return nil, false
		}
		if tag.class == .Context_Specific && tag.number == want {
			return c, true
		}
	}
	return nil, false
}

// _nc_section_has reports whether the given section contains at least one
// subtree whose base is `form`.
@(private)
_nc_section_has :: proc(nc: []byte, excluded: bool, form: u32) -> bool {
	content, present := _nc_section(nc, excluded)
	if !present {
		return false
	}
	cur: asn1.Cursor
	asn1.cursor_init(&cur, content)
	for !asn1.is_empty(&cur) {
		gs, e := asn1.read_sequence(&cur)
		if e != .None {
			return false
		}
		tag, _, be := asn1.read_any(&gs)
		if be != .None {
			return false
		}
		if tag.class == .Context_Specific && tag.number == form {
			return true
		}
	}
	return false
}

// _nc_dns_match reports whether `name` matches any dNSName subtree in the
// given section.
@(private)
_nc_dns_match :: proc(nc: []byte, excluded: bool, name: string) -> bool {
	content, present := _nc_section(nc, excluded)
	if !present {
		return false
	}
	cur: asn1.Cursor
	asn1.cursor_init(&cur, content)
	for !asn1.is_empty(&cur) {
		gs, e := asn1.read_sequence(&cur)
		if e != .None {
			return false
		}
		tag, base, be := asn1.read_any(&gs)
		if be != .None {
			return false
		}
		if tag.class == .Context_Specific && tag.number == _GN_DNS {
			c := string(base)
			// A wildcard SAN "*.B" stands for every "<label>.B". Matching it as
			// a literal string lets it slip past an exclusion of some x.B
			// (CVE-2025-61727). Handle the leftmost "*" explicitly.
			if len(name) >= 2 && name[0] == '*' && name[1] == '.' {
				b := name[2:]
				if excluded {
					// Fail closed: exclude the wildcard if its subtree overlaps
					// the constraint at all (constraint covers b, or b covers it).
					if _dns_in_constraint(c, b) || _dns_in_constraint(b, _strip_dot(c)) {
						return true
					}
				} else if _dns_in_constraint(_strip_dot(c), b) {
					// Permitted only if every child of b is inside the subtree.
					return true
				}
			} else if _dns_in_constraint(c, name) {
				return true
			}
		}
	}
	return false
}

// _strip_dot drops a single leading '.', normalizing a subtree constraint to a
// bare domain for the wildcard-overlap comparisons above.
@(private)
_strip_dot :: proc "contextless" (s: string) -> string {
	return s[1:] if len(s) > 0 && s[0] == '.' else s
}

// _nc_ip_match reports whether `ip` (a 4- or 16-octet address) matches any
// iPAddress subtree in the given section. In NameConstraints an iPAddress
// base is the address followed by a mask of equal length (8 octets for IPv4,
// 32 for IPv6).
@(private)
_nc_ip_match :: proc(nc: []byte, excluded: bool, ip: []byte) -> bool {
	content, present := _nc_section(nc, excluded)
	if !present {
		return false
	}
	cur: asn1.Cursor
	asn1.cursor_init(&cur, content)
	for !asn1.is_empty(&cur) {
		gs, e := asn1.read_sequence(&cur)
		if e != .None {
			return false
		}
		tag, base, be := asn1.read_any(&gs)
		if be != .None {
			return false
		}
		if tag.class == .Context_Specific && tag.number == _GN_IP {
			if len(base) == 2 * len(ip) {
				addr := base[:len(ip)]
				mask := base[len(ip):]
				if _ip_in_subnet(ip, addr, mask) {
					return true
				}
			}
		}
	}
	return false
}

// _ip_in_subnet reports whether ip lies in addr/mask (all equal length).
@(private)
_ip_in_subnet :: proc "contextless" (ip, addr, mask: []byte) -> bool {
	for i in 0 ..< len(ip) {
		if (ip[i] & mask[i]) != (addr[i] & mask[i]) {
			return false
		}
	}
	return true
}

// _dns_in_constraint implements the RFC 5280 section 4.2.1.10 dNSName rule:
// `name` satisfies `constraint` when it equals the constraint or extends it on
// the left at a label boundary. An empty constraint matches everything; a
// leading-dot constraint (".example.com") matches proper subdomains only.
// Comparison is ASCII case-insensitive.
@(private)
_dns_in_constraint :: proc "contextless" (constraint, name: string) -> bool {
	if len(constraint) == 0 {
		return true
	}
	if constraint[0] == '.' {
		return _ascii_suffix_fold(name, constraint)
	}
	if _ascii_eq_fold(name, constraint) {
		return true
	}
	// name must end with "." + constraint, so the constraint aligns to a label.
	if len(name) > len(constraint) + 1 && name[len(name) - len(constraint) - 1] == '.' {
		return _ascii_suffix_fold(name, constraint)
	}
	return false
}

@(private)
_ascii_lower :: proc "contextless" (b: byte) -> byte {
	return b + 0x20 if b >= 'A' && b <= 'Z' else b
}

@(private)
_ascii_eq_fold :: proc "contextless" (a, b: string) -> bool {
	if len(a) != len(b) {
		return false
	}
	for i in 0 ..< len(a) {
		if _ascii_lower(a[i]) != _ascii_lower(b[i]) {
			return false
		}
	}
	return true
}

@(private)
_ascii_suffix_fold :: proc "contextless" (s, suffix: string) -> bool {
	if len(suffix) > len(s) {
		return false
	}
	off := len(s) - len(suffix)
	for i in 0 ..< len(suffix) {
		if _ascii_lower(s[off + i]) != _ascii_lower(suffix[i]) {
			return false
		}
	}
	return true
}
