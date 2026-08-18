package x509

import "core:bytes"
import "core:encoding/asn1"
import "core:strings"

// Consumer-facing helpers for reading the primitives `parse` leaves as raw DER:
// distinguished-name (Name) decoding, plus a serial-number display formatter.
// These are conveniences over the raw fields, path validation does not need
// them, and `raw_subject` / `raw_issuer` remain available for the RFC 5280
// binary-comparison rule (which is what issuer/subject matching uses).

// parse_dn decodes a DER Name (an RDNSequence, e.g. cert.raw_subject or
// cert.raw_issuer) into its attributes, the inverse of marshal_dn. Attributes
// outside the recognized set (see DN_Attribute_Type) come back as `Other` with
// their type OID in `oid`. The returned slice is the caller's to free; every
// `value` (and `oid`) is a VIEW into `der`, which must outlive the result.
//
// Values are taken as the raw content octets of the attribute value: correct
// for the UTF8String / PrintableString / IA5String forms certificates use in
// practice, but Teletex/BMP/Universal strings are NOT transcoded (returned as
// their raw bytes).
@(require_results)
parse_dn :: proc(der: []byte, allocator := context.allocator) -> (attrs: []DN_Attribute, err: Error) {
	cur: asn1.Cursor
	asn1.cursor_init(&cur, der)
	seq, e := asn1.read_sequence(&cur)
	if e != .None || asn1.done(&cur) != .None {
		return nil, .Malformed
	}

	// Count AttributeTypeAndValue entries first (an RDN is a SET OF, usually one
	// element), so the result is exact-sized.
	count := 0
	{
		tmp := seq
		for !asn1.is_empty(&tmp) {
			rdn, re := asn1.read_set(&tmp)
			if re != .None {
				return nil, .Malformed
			}
			for !asn1.is_empty(&rdn) {
				if _, ae := asn1.read_sequence(&rdn); ae != .None {
					return nil, .Malformed
				}
				count += 1
			}
		}
	}
	if count == 0 {
		return nil, .None // an empty Name is valid
	}

	out, merr := make([]DN_Attribute, count, allocator)
	if merr != nil {
		return nil, .Allocation_Failed
	}
	i := 0
	for !asn1.is_empty(&seq) {
		rdn, re := asn1.read_set(&seq)
		if re != .None {
			delete(out, allocator)
			return nil, .Malformed
		}
		for !asn1.is_empty(&rdn) {
			atv, ae := asn1.read_sequence(&rdn)
			oid, oe := asn1.read_oid(&atv)
			_, val, ve := asn1.read_any(&atv)
			if ae != .None || oe != .None || ve != .None || asn1.done(&atv) != .None {
				delete(out, allocator)
				return nil, .Malformed
			}
			t, known := _dn_type_from_oid(oid)
			out[i] = DN_Attribute {
				type  = t,
				value = string(val),
			}
			if !known {
				out[i].oid = oid
			}
			i += 1
		}
	}
	return out[:i], .None
}

// dn_get returns the value of the first attribute of `type` (e.g. .Common_Name),
// and whether one was present.
dn_get :: proc(attrs: []DN_Attribute, type: DN_Attribute_Type) -> (value: string, ok: bool) {
	for a in attrs {
		if a.type == type {
			return a.value, true
		}
	}
	return "", false
}

// dn_string renders `attrs` as an RFC 4514 string ("CN=leaf,O=Acme,C=US"):
// RDNs in reverse order, short names for the recognized attributes and the
// dotted OID for `Other`, with RFC 4514 section 2.4 special characters escaped.
// The returned string is the caller's to free.
@(require_results)
dn_string :: proc(attrs: []DN_Attribute, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)
	for i := len(attrs) - 1; i >= 0; i -= 1 {
		a := attrs[i]
		if i != len(attrs) - 1 {
			strings.write_byte(&b, ',')
		}
		switch a.type {
		case .Common_Name:
			strings.write_string(&b, "CN")
		case .Country:
			strings.write_string(&b, "C")
		case .Locality:
			strings.write_string(&b, "L")
		case .State_Or_Province:
			strings.write_string(&b, "ST")
		case .Organization:
			strings.write_string(&b, "O")
		case .Organizational_Unit:
			strings.write_string(&b, "OU")
		case .Serial_Number:
			strings.write_string(&b, "serialNumber")
		case .Other:
			if s, e := asn1.oid_to_string(a.oid, context.temp_allocator); e == .None {
				strings.write_string(&b, s)
			} else {
				strings.write_byte(&b, '?')
			}
		}
		strings.write_byte(&b, '=')
		_dn_escape(&b, a.value)
	}
	return strings.to_string(b)
}

// serial_string formats the certificate serial as upper-case colon-separated
// hex ("07:44:76:…"). The serial is an opaque identifier (up to 20 octets)
// Allocated String
@(require_results)
serial_string :: proc(cert: ^Certificate, allocator := context.allocator) -> string {
	HEX := "0123456789ABCDEF"
	b := strings.builder_make(allocator)
	for octet, i in cert.serial {
		if i != 0 {
			strings.write_byte(&b, ':')
		}
		strings.write_byte(&b, HEX[octet >> 4])
		strings.write_byte(&b, HEX[octet & 0x0F])
	}
	return strings.to_string(b)
}

// _dn_type_from_oid maps an attribute-type OID to a DN_Attribute_Type, the
// inverse of _dn_oid
@(private)
_dn_type_from_oid :: proc(oid: []byte) -> (type: DN_Attribute_Type, is_known_oid: bool) {
	switch {
	case bytes.equal(oid, _OID_AT_CN):
		return .Common_Name, true
	case bytes.equal(oid, _OID_AT_C):
		return .Country, true
	case bytes.equal(oid, _OID_AT_L):
		return .Locality, true
	case bytes.equal(oid, _OID_AT_ST):
		return .State_Or_Province, true
	case bytes.equal(oid, _OID_AT_O):
		return .Organization, true
	case bytes.equal(oid, _OID_AT_OU):
		return .Organizational_Unit, true
	case bytes.equal(oid, _OID_AT_SERIAL):
		return .Serial_Number, true
	}
	return .Other, false
}

// _dn_escape writes `s` into `b` with the RFC 4514 section 2.4 escapes: a
// leading '#' or space and a trailing space are escaped, as are the characters
// " + , ; < > \ and the NUL byte.
@(private)
_dn_escape :: proc(b: ^strings.Builder, s: string) {
	for i in 0 ..< len(s) {
		c := s[i]
		lead := i == 0 && (c == ' ' || c == '#')
		trail := i == len(s) - 1 && c == ' '
		switch c {
		case '"', '+', ',', ';', '<', '>', '\\', 0x00:
			strings.write_byte(b, '\\')
			strings.write_byte(b, c)
		case:
			if lead || trail {
				strings.write_byte(b, '\\')
			}
			strings.write_byte(b, c)
		}
	}
}
