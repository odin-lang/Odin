package x509

import "core:bytes"
import "core:crypto/hash"
import "core:encoding/asn1"

/*
Ref: RFC 5280, Section 4.1, wire format:

This grammar is decoded via a cursor over the DER. The contents flatten into
the certificate (see x509.odin).

	Certificate / TBSCertificate  -> Certificate          (flattened; raw, raw_tbs)
	signatureAlgorithm + value    -> signature_algorithm, signature_oid, signature
	Version                       -> version              (int: 1 / 2 / 3)
	CertificateSerialNumber       -> serial               ([]byte, raw INTEGER content)
	Validity / Time               -> not_before, not_after (time.Time)
	Name (issuer / subject)       -> raw_issuer, raw_subject ([]byte DER; not decoded)
	SubjectPublicKeyInfo          -> raw_spki, public_key_algorithm, rsa_n/rsa_e/ec_point
	Extension                     -> Extension struct, in `extensions`
	issuer/subjectUniqueID        -> skipped (obsolete)

Certificate  ::=  SEQUENCE  {
	tbsCertificate       TBSCertificate,
	signatureAlgorithm   AlgorithmIdentifier,
	signatureValue       BIT STRING  
}

TBSCertificate  ::=  SEQUENCE  {
	version         [0]  EXPLICIT Version DEFAULT v1,
	serialNumber         CertificateSerialNumber,
	signature            AlgorithmIdentifier,
	issuer               Name,
	validity             Validity,
	subject              Name,
	subjectPublicKeyInfo SubjectPublicKeyInfo,
	issuerUniqueID  [1]  IMPLICIT UniqueIdentifier OPTIONAL,
	subjectUniqueID [2]  IMPLICIT UniqueIdentifier OPTIONAL,
	extensions      [3]  EXPLICIT Extensions OPTIONAL 
}

Version  ::=  INTEGER  {  v1(0), v2(1), v3(2)  }

CertificateSerialNumber  ::=  INTEGER

Validity ::= SEQUENCE {
	notBefore      Time,
	notAfter       Time }

Time ::= CHOICE {
	utcTime        UTCTime,
	generalTime    GeneralizedTime }

UniqueIdentifier  ::=  BIT STRING

SubjectPublicKeyInfo  ::=  SEQUENCE  {
	algorithm            AlgorithmIdentifier,
	subjectPublicKey     BIT STRING  }

Extensions  ::=  SEQUENCE SIZE (1..MAX) OF Extension

Extension  ::=  SEQUENCE  {
	extnID      OBJECT IDENTIFIER,
	critical    BOOLEAN DEFAULT FALSE,
	extnValue   OCTET STRING
				-- contains the DER encoding of an ASN.1 value
				-- corresponding to the extension type identified
				-- by extnID
}

AlgorithmIdentifier  ::=  SEQUENCE  {
	algorithm               OBJECT IDENTIFIER,
	parameters              ANY DEFINED BY algorithm OPTIONAL  
}

Name ::= CHOICE { -- only one possibility for now --
     rdnSequence  RDNSequence 
}

RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

RelativeDistinguishedName ::= SET SIZE (1..MAX) OF AttributeTypeAndValue

AttributeTypeAndValue ::= SEQUENCE {
	type     AttributeType,
	value    AttributeValue 
}

AttributeType ::= OBJECT IDENTIFIER

AttributeValue ::= ANY -- DEFINED BY AttributeType

DirectoryString ::= CHOICE {
	teletexString           TeletexString (SIZE (1..MAX)),
	printableString         PrintableString (SIZE (1..MAX)),
	universalString         UniversalString (SIZE (1..MAX)),
	utf8String              UTF8String (SIZE (1..MAX)),
	bmpString               BMPString (SIZE (1..MAX)) 
}

*/

// parse decodes one DER certificate. The returned Certificate holds views into `der`, which must outlive it;
// the allocated tables are released with destroy(). Trailing bytes after the certificate are an error.
@(require_results)
parse :: proc(der: []byte, allocator := context.allocator) -> (cert: Certificate, err: Error) {
	r: asn1.Cursor
	asn1.cursor_init(&r, der)

	outer, oerr := asn1.read_sequence(&r)
	if oerr != .None || asn1.done(&r) != .None {
		return {}, .Malformed
	}
	cert.raw = der[:r.pos]

	// tbsCertificate: capture the full element (header included);
	tbs_start := outer.pos
	tbs, terr := asn1.read_sequence(&outer)
	if terr != .None {
		return {}, .Malformed
	}
	cert.raw_tbs = outer.data[tbs_start:outer.pos]

	// signatureAlgorithm + signatureValue.
	sig_oid, sig_params, serr := _read_algorithm_identifier(&outer)
	if serr != .None {
		return {}, .Malformed
	}
	cert.signature_oid = sig_oid
	cert.signature_algorithm = _signature_algorithm(sig_oid)
	if cert.signature_algorithm == .RSA_PSS {
		if perr := _parse_pss_params(&cert, sig_params); perr != .None {
			return {}, perr
		}
	}

	sig_bits, sberr := asn1.read_bit_string_octets(&outer)
	if sberr != .None || asn1.done(&outer) != .None {
		return {}, .Malformed
	}
	cert.signature = sig_bits

	// ---- TBSCertificate ----

	// [0] EXPLICIT version (DEFAULT v1).
	cert.version = 1
	vr, has_version, verr := asn1.read_explicit(&tbs, 0)
	if verr != .None {
		return {}, .Malformed
	}
	if has_version {
		v, vierr := asn1.read_i64(&vr)
		if vierr != .None || asn1.done(&vr) != .None {
			return {}, .Malformed
		}
		if v < 0 || v > 2 {
			return {}, .Unsupported_Version
		}
		cert.version = int(v) + 1
	}

	// The serial is read as a raw INTEGER (not unsigned): RFC 5280 requires it to be positive, but non-conformant CAs issue negative
	// serials and rejecting them is a validation policy, not a parsing one. The two's-complement content is preserved verbatim.
	serial, snerr := asn1.read_integer_bytes(&tbs)
	if snerr != .None {
		return {}, .Malformed
	}
	cert.serial = serial

	// signature must match the outer signatureAlgorithm per RFC 5280 section 4.1.1.2,
	// the OID always, and for RSA-PSS the parameters too (they carry the digest).
	tbs_sig_oid, tbs_sig_params, tserr := _read_algorithm_identifier(&tbs)
	if tserr != .None {
		return {}, .Malformed
	}
	if !bytes.equal(tbs_sig_oid, sig_oid) {
		return {}, .Malformed
	}
	if cert.signature_algorithm == .RSA_PSS && !bytes.equal(tbs_sig_params, sig_params) {
		return {}, .Malformed
	}

	// issuer
	issuer_start := tbs.pos
	if _, ierr := asn1.read_sequence(&tbs); ierr != .None {
		return {}, .Malformed
	}
	cert.raw_issuer = tbs.data[issuer_start:tbs.pos]

	// validity
	validity, vderr := asn1.read_sequence(&tbs)
	if vderr != .None {
		return {}, .Invalid_Validity
	}
	nb, nberr := asn1.read_time(&validity)
	na, naerr := asn1.read_time(&validity)
	if nberr != .None || naerr != .None || asn1.done(&validity) != .None {
		return {}, .Invalid_Validity
	}
	cert.not_before = nb
	cert.not_after = na

	// subject
	subject_start := tbs.pos
	if _, suberr := asn1.read_sequence(&tbs); suberr != .None {
		return {}, .Malformed
	}
	cert.raw_subject = tbs.data[subject_start:tbs.pos]

	// subjectPublicKeyInfo, full element preserved for hashing
	spki_start := tbs.pos
	spki, sperr := asn1.read_sequence(&tbs)
	if sperr != .None {
		return {}, .Malformed
	}
	cert.raw_spki = tbs.data[spki_start:tbs.pos]
	if kerr := _parse_spki(&cert, &spki); kerr != .None {
		return {}, kerr
	}

	// issuerUniqueID / subjectUniqueID - obsolete; skip if present
	for number in u32(1) ..= u32(2) {
		if asn1.is_empty(&tbs) {
			break
		}
		tag, perr := asn1.peek_tag(&tbs)
		if perr != .None {
			return {}, .Malformed
		}
		if tag.class == .Context_Specific && tag.number == number {
			if asn1.skip(&tbs) != .None {
				return {}, .Malformed
			}
		}
	}

	// [3] EXPLICIT extensions.
	cert.max_path_len = -1
	er, has_exts, eerr := asn1.read_explicit(&tbs, 3)
	if eerr != .None || asn1.done(&tbs) != .None {
		return {}, .Malformed
	}
	if has_exts {
		if cert.version != 3 {
			return {}, .Malformed
		}
		if xerr := _parse_extensions(&cert, &er, allocator); xerr != .None {
			destroy(&cert, allocator)
			return {}, xerr
		}
	}

	return cert, .None
}

// Internals.

// _read_algorithm_identifier reads SEQUENCE { OID, params ANY OPTIONAL }, returning the OID content and the raw parameter element
// (nil when absent).
@(private)
_read_algorithm_identifier :: proc(
	r: ^asn1.Cursor,
) -> (
	oid: []byte,
	params: []byte,
	err: asn1.Error,
) {
	alg, aerr := asn1.read_sequence(r)
	if aerr != .None {
		return nil, nil, aerr
	}
	oid, err = asn1.read_oid(&alg)
	if err != .None {
		return nil, nil, err
	}
	if !asn1.is_empty(&alg) {
		params_start := alg.pos
		if serr := asn1.skip(&alg); serr != .None {
			return nil, nil, serr
		}
		params = alg.data[params_start:alg.pos]
	}
	if derr := asn1.done(&alg); derr != .None {
		return nil, nil, derr
	}
	return oid, params, .None
}

@(private)
_signature_algorithm :: proc(oid: []byte) -> Signature_Algorithm {
	switch {
	case bytes.equal(oid, _OID_SIG_RSA_SHA256):
		return .RSA_SHA256
	case bytes.equal(oid, _OID_SIG_ECDSA_SHA256):
		return .ECDSA_SHA256
	case bytes.equal(oid, _OID_SIG_RSA_SHA384):
		return .RSA_SHA384
	case bytes.equal(oid, _OID_SIG_RSA_SHA512):
		return .RSA_SHA512
	case bytes.equal(oid, _OID_SIG_ECDSA_SHA384):
		return .ECDSA_SHA384
	case bytes.equal(oid, _OID_SIG_ECDSA_SHA512):
		return .ECDSA_SHA512
	case bytes.equal(oid, _OID_ED25519):
		return .Ed25519
	case bytes.equal(oid, _OID_SIG_RSA_PSS):
		return .RSA_PSS
	case bytes.equal(oid, _OID_SIG_RSA_SHA1):
		return .RSA_SHA1
	}
	return .Unknown
}

// _hash_from_oid maps a bare hash-algorithm OID (as it appears in an
// RSASSA-PSS AlgorithmIdentifier) to a hash.Algorithm, reporting ok=false for
// digests this package does not verify (leaving the field .Invalid so the
// verifier fails closed rather than the parser rejecting the certificate).
@(private)
_hash_from_oid :: proc(oid: []byte) -> (hash.Algorithm, bool) {
	switch {
	case bytes.equal(oid, _OID_HASH_SHA256):
		return .SHA256, true
	case bytes.equal(oid, _OID_HASH_SHA384):
		return .SHA384, true
	case bytes.equal(oid, _OID_HASH_SHA512):
		return .SHA512, true
	case bytes.equal(oid, _OID_HASH_SHA1):
		return .Insecure_SHA1, true
	}
	return .Invalid, false
}

// _parse_pss_params decodes RSASSA-PSS-params (RFC 4055 section 3.1) from the
// signatureAlgorithm parameters into cert.pss_*:
//   SEQUENCE { hashAlgorithm [0], maskGenAlgorithm [1], saltLength [2] INTEGER,
//              trailerField [3] INTEGER }, all EXPLICIT and all with defaults.
// Omitted fields take their RFC 4055 defaults (SHA-1 / MGF1-SHA-1 / salt 20).
// A structurally broken params element is .Malformed; an unrecognized digest is
// NOT an error here, the hash is left .Invalid for verify_signature to reject.
@(private)
_parse_pss_params :: proc(cert: ^Certificate, params: []byte) -> Error {
	// RFC 4055 defaults (applied when a field is absent).
	cert.pss_hash = .Insecure_SHA1
	cert.pss_mgf_hash = .Insecure_SHA1
	cert.pss_salt_len = 20
	if len(params) == 0 {
		return .None // absent parameters: all defaults
	}

	cur: asn1.Cursor
	asn1.cursor_init(&cur, params)
	seq, e := asn1.read_sequence(&cur)
	if e != .None || asn1.done(&cur) != .None {
		return .Malformed
	}

	// hashAlgorithm [0] EXPLICIT AlgorithmIdentifier
	if inner, present, ie := asn1.read_explicit(&seq, 0); ie != .None {
		return .Malformed
	} else if present {
		oid, _, oe := _read_algorithm_identifier(&inner)
		if oe != .None || asn1.done(&inner) != .None {
			return .Malformed
		}
		cert.pss_hash, _ = _hash_from_oid(oid) // .Invalid when unrecognized
	}

	// maskGenAlgorithm [1] EXPLICIT AlgorithmIdentifier { id-mgf1, hashAlgorithm }
	if inner, present, ie := asn1.read_explicit(&seq, 1); ie != .None {
		return .Malformed
	} else if present {
		mgf_oid, mgf_params, me := _read_algorithm_identifier(&inner)
		if me != .None || asn1.done(&inner) != .None {
			return .Malformed
		}
		if !bytes.equal(mgf_oid, _OID_MGF1) {
			cert.pss_mgf_hash = .Invalid // an MGF other than MGF1: unverifiable here
		} else {
			mp: asn1.Cursor
			asn1.cursor_init(&mp, mgf_params)
			hoid, _, he := _read_algorithm_identifier(&mp)
			if he != .None || asn1.done(&mp) != .None {
				return .Malformed
			}
			cert.pss_mgf_hash, _ = _hash_from_oid(hoid)
		}
	}

	// saltLength [2] EXPLICIT INTEGER
	if inner, present, ie := asn1.read_explicit(&seq, 2); ie != .None {
		return .Malformed
	} else if present {
		sl, se := asn1.read_i64(&inner)
		if se != .None || asn1.done(&inner) != .None || sl < 0 {
			return .Malformed
		}
		cert.pss_salt_len = int(sl)
	}

	// trailerField [3] EXPLICIT INTEGER, only trailerFieldBC (1) is defined.
	if inner, present, ie := asn1.read_explicit(&seq, 3); ie != .None {
		return .Malformed
	} else if present {
		tf, te := asn1.read_i64(&inner)
		if te != .None || asn1.done(&inner) != .None || tf != 1 {
			return .Malformed
		}
	}

	if asn1.done(&seq) != .None {
		return .Malformed
	}
	return .None
}

@(private)
_parse_spki :: proc(cert: ^Certificate, spki: ^asn1.Cursor) -> Error {
	key_oid, key_params, aerr := _read_algorithm_identifier(spki)
	if aerr != .None {
		return .Malformed
	}
	key_bits, kberr := asn1.read_bit_string_octets(spki)
	if kberr != .None || asn1.done(spki) != .None {
		return .Malformed
	}

	switch {
	case bytes.equal(key_oid, _OID_KEY_RSA):
		cert.public_key_algorithm = .RSA
		// RSAPublicKey ::= SEQUENCE { modulus INTEGER, publicExponent INTEGER }
		kr: asn1.Cursor
		asn1.cursor_init(&kr, key_bits)
		rsa, rerr := asn1.read_sequence(&kr)
		if rerr != .None || asn1.done(&kr) != .None {
			return .Malformed
		}
		n, nerr := asn1.read_unsigned_integer_bytes(&rsa)
		e, eerr := asn1.read_unsigned_integer_bytes(&rsa)
		if nerr != .None || eerr != .None || asn1.done(&rsa) != .None {
			return .Malformed
		}
		cert.rsa_n = n
		cert.rsa_e = e

	case bytes.equal(key_oid, _OID_KEY_EC):
		// Parameters carry the named curve: OID wrapped in the params element we captured raw
		pr: asn1.Cursor
		asn1.cursor_init(&pr, key_params)
		curve_oid, cerr := asn1.read_oid(&pr)
		if cerr != .None || asn1.done(&pr) != .None {
			return .Malformed
		}
		switch {
		case bytes.equal(curve_oid, _OID_CURVE_P256):
			cert.public_key_algorithm = .ECDSA_P256
		case bytes.equal(curve_oid, _OID_CURVE_P384):
			cert.public_key_algorithm = .ECDSA_P384
		case bytes.equal(curve_oid, _OID_CURVE_P521):
			cert.public_key_algorithm = .ECDSA_P521
		case:
			cert.public_key_algorithm = .Unknown
		}
		cert.ec_point = key_bits

	case bytes.equal(key_oid, _OID_ED25519):
		cert.public_key_algorithm = .Ed25519
		if len(key_bits) != 32 {
			return .Malformed
		}
		cert.ec_point = key_bits

	case:
		cert.public_key_algorithm = .Unknown
	}
	return .None
}

@(private)
_parse_extensions :: proc(
	cert: ^Certificate,
	er: ^asn1.Cursor,
	allocator := context.allocator,
) -> Error {
	exts, xerr := asn1.read_sequence(er)
	if xerr != .None || asn1.done(er) != .None {
		return .Malformed
	}

	// Find allocation size
	count := 0
	{
		tmp := exts
		for !asn1.is_empty(&tmp) {
			if asn1.skip(&tmp) != .None {
				return .Malformed
			}
			count += 1
		}
	}
	exts_table, merr := make([]Extension, count, allocator)
	if merr != nil {
		return .Allocation_Failed
	}
	cert.extensions = exts_table

	for i in 0 ..< count {
		// Extension ::= SEQUENCE { extnID OID, critical BOOLEAN DEFAULT FALSE, extnValue OCTET STRING }
		ext, eerr := asn1.read_sequence(&exts)
		if eerr != .None {
			return .Malformed
		}
		oid, oerr := asn1.read_oid(&ext)
		if oerr != .None {
			return .Malformed
		}
		critical := false
		tag, perr := asn1.peek_tag(&ext)
		if perr != .None {
			return .Malformed
		}
		if tag == asn1.universal(.Boolean) {
			c, berr := asn1.read_boolean(&ext)
			if berr != .None {
				return .Malformed
			}
			critical = c
		}
		value, verr := asn1.read_octet_string(&ext)
		if verr != .None || asn1.done(&ext) != .None {
			return .Malformed
		}

		// RFC 5280 section 4.2: "A certificate MUST NOT include more than one instance of a particular extension."
		for j in 0 ..< i {
			if bytes.equal(cert.extensions[j].oid, oid) {
				return .Duplicate_Extension
			}
		}
		cert.extensions[i] = Extension {
			oid      = oid,
			critical = critical,
			value    = value,
		}

		if herr := _parse_known_extension(cert, oid, critical, value, allocator); herr != .None {
			return herr
		}
	}
	return .None
}

@(private)
_parse_known_extension :: proc(
	cert: ^Certificate,
	oid: []byte,
	critical: bool,
	value: []byte,
	allocator := context.allocator,
) -> Error {
	vr: asn1.Cursor
	asn1.cursor_init(&vr, value)

	switch {
	case bytes.equal(oid, _OID_EXT_BASIC_CONSTRAINTS):
		// BasicConstraints ::= SEQUENCE { cA BOOLEAN DEFAULT FALSE, pathLenConstraint INTEGER OPTIONAL }
		bc, err := asn1.read_sequence(&vr)
		if err != .None || asn1.done(&vr) != .None {
			return .Invalid_Extension
		}
		if !asn1.is_empty(&bc) {
			tag, perr := asn1.peek_tag(&bc)
			if perr != .None {
				return .Invalid_Extension
			}
			if tag == asn1.universal(.Boolean) {
				ca, berr := asn1.read_boolean(&bc)
				if berr != .None {
					return .Invalid_Extension
				}
				cert.is_ca = ca
			}
		}
		if !asn1.is_empty(&bc) {
			depth, derr := asn1.read_i64(&bc)
			if derr != .None || depth < 0 {
				return .Invalid_Extension
			}
			cert.max_path_len = int(depth)
		}
		if asn1.done(&bc) != .None {
			return .Invalid_Extension
		}
		cert.basic_constraints_valid = true

	case bytes.equal(oid, _OID_EXT_KEY_USAGE):
		bits, unused, err := asn1.read_bit_string(&vr)
		if err != .None || asn1.done(&vr) != .None {
			return .Invalid_Extension
		}
		total := len(bits) * 8 - unused
		usage: Key_Usage
		for bit in Key_Usage_Bit {
			i := int(bit)
			if i >= total {
				continue
			}
			if bits[i / 8] & (0x80 >> uint(i % 8)) != 0 {
				usage += {bit}
			}
		}
		cert.key_usage = usage
		cert.has_key_usage = true

	case bytes.equal(oid, _OID_EXT_EXT_KEY_USAGE):
		seq, err := asn1.read_sequence(&vr)
		if err != .None || asn1.done(&vr) != .None {
			return .Invalid_Extension
		}
		for !asn1.is_empty(&seq) {
			purpose, perr := asn1.read_oid(&seq)
			if perr != .None {
				return .Invalid_Extension
			}
			switch {
			case bytes.equal(purpose, _OID_EKU_SERVER_AUTH):
				cert.ext_key_usage += {.Server_Auth}
			case bytes.equal(purpose, _OID_EKU_CLIENT_AUTH):
				cert.ext_key_usage += {.Client_Auth}
			case bytes.equal(purpose, _OID_EKU_CODE_SIGNING):
				cert.ext_key_usage += {.Code_Signing}
			case bytes.equal(purpose, _OID_EKU_EMAIL_PROTECTION):
				cert.ext_key_usage += {.Email_Protection}
			case bytes.equal(purpose, _OID_EKU_TIME_STAMPING):
				cert.ext_key_usage += {.Time_Stamping}
			case bytes.equal(purpose, _OID_EKU_OCSP_SIGNING):
				cert.ext_key_usage += {.OCSP_Signing}
			case bytes.equal(purpose, _OID_EKU_ANY):
				cert.ext_key_usage += {.Any}
			case:
				cert.eku_has_unknown = true
			}
		}
		cert.has_ext_key_usage = true

	case bytes.equal(oid, _OID_EXT_SAN):
		return _parse_san(cert, &vr, allocator)

	case bytes.equal(oid, _OID_EXT_SUBJECT_KEY_ID):
		ski, err := asn1.read_octet_string(&vr)
		if err != .None || asn1.done(&vr) != .None {
			return .Invalid_Extension
		}
		cert.subject_key_id = ski

	case bytes.equal(oid, _OID_EXT_AUTHORITY_KEY_ID):
		// AuthorityKeyIdentifier ::= SEQUENCE { keyIdentifier [0] IMPLICIT OCTET STRING OPTIONAL, ... }
		aki, err := asn1.read_sequence(&vr)
		if err != .None || asn1.done(&vr) != .None {
			return .Invalid_Extension
		}
		if !asn1.is_empty(&aki) {
			tag, perr := asn1.peek_tag(&aki)
			if perr != .None {
				return .Invalid_Extension
			}
			if tag == asn1.context_specific(0, false) {
				kid, kerr := asn1.expect(&aki, tag)
				if kerr != .None {
					return .Invalid_Extension
				}
				cert.authority_key_id = kid
			}
		}
		// authorityCertIssuer [1] and authorityCertSerialNumber [2] are intentionally not decoded: keyIdentifier is the form used in
		// practice, and AKI is only a path-building hint (issuers are matched by DN + signature), so the other fields carry no
		// validation weight here.

	case:
		if critical {
			cert.unhandled_critical = true
		}
	}
	return .None
}

// GeneralNames ::= SEQUENCE OF GeneralName; we extract dNSName ([2] IA5String) and iPAddress ([7] OCTET STRING).
@(private)
_parse_san :: proc(cert: ^Certificate, vr: ^asn1.Cursor, allocator := context.allocator) -> Error {
	names, err := asn1.read_sequence(vr)
	if err != .None || asn1.done(vr) != .None {
		return .Invalid_Extension
	}

	dns_count, ip_count := 0, 0
	{
		tmp := names
		for !asn1.is_empty(&tmp) {
			tag, content, gerr := asn1.read_any(&tmp)
			if gerr != .None || tag.class != .Context_Specific {
				return .Invalid_Extension
			}
			switch tag.number {
			case 2:
				dns_count += 1
			case 7:
				if len(content) != 4 && len(content) != 16 {
					return .Invalid_Extension
				}
				ip_count += 1
			}
		}
	}

	// On allocation failure the caller (parse) unwinds every table via destroy.
	if dns_count > 0 {
		dns_table, derr := make([]string, dns_count, allocator)
		if derr != nil {
			return .Allocation_Failed
		}
		cert.dns_names = dns_table
	}
	if ip_count > 0 {
		ip_table, ierr := make([][]byte, ip_count, allocator)
		if ierr != nil {
			return .Allocation_Failed
		}
		cert.ip_addresses = ip_table
	}

	di, ii := 0, 0
	for !asn1.is_empty(&names) {
		tag, content, gerr := asn1.read_any(&names)
		if gerr != .None {
			return .Invalid_Extension
		}
		switch tag.number {
		case 2:
			cert.dns_names[di] = string(content)
			di += 1
		case 7:
			cert.ip_addresses[ii] = content
			ii += 1
		}
	}
	return .None
}
