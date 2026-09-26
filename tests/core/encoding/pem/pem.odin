package test_core_pem

import "core:bytes"
import "core:encoding/hex"
import "core:encoding/pem"
import "core:testing"

// RFC 7468 Section 9.
@(private)
CMS_PEM_TEXT : string : \
`-----BEGIN CMS-----
MIGDBgsqhkiG9w0BCRABCaB0MHICAQAwDQYLKoZIhvcNAQkQAwgwXgYJKoZIhvcN
AQcBoFEET3icc87PK0nNK9ENqSxItVIoSa0o0S/ISczMs1ZIzkgsKk4tsQ0N1nUM
dvb05OXi5XLPLEtViMwvLVLwSE0sKlFIVHAqSk3MBkkBAJv0Fx0=
-----END CMS-----`
@(private)
CMS_PEM_PAYLOAD : string : "308183060b2a864886f70d0109100109a0743072020100300d060b2a864886f70d0109100308305e06092a864886f70d010701a051044f789c73cecf2b49cd2bd10da92c48b5522849ad28d12fc849ccccb35648ce482c2a4e2db10d0dd6750c76f6f4e4e5e2e572cf2c4b5588cc2f2d52f0484d2c2a514854702a4a4dcc064901009bf4171d"
@(private)
NOT_PEM_TEXT : string : \
`
Socialism is not in the least what it pretends to be.
It is not the pioneer of a better and finer world, but the spoiler of what thousands of years of civilization have created.
It does not build, it destroys.
For destruction is the essence of it.
It produces nothing, it only consumes what the social order based on private ownership in the means of production has created. `
@(private)
COMMENT_TEXT : string : "# 9.  Textual Encoding of Cryptographic Message Syntax"

@(test)
test_pem_roundtrip :: proc(t: ^testing.T) {
	// Decode.
	blk, remaining, err := pem.decode(transmute([]byte)(CMS_PEM_TEXT))
	if !testing.expectf(t, err == nil, "PEM decode failed: %v", err) {
		return
	}
	defer pem.block_delete(blk)

	if !testing.expectf(t, len(remaining) == 0, "PEM decode left trailing garbage: '%s'", remaining) {
		return
	}

	// Ensure contents match.
	if !testing.expectf(t, blk.label == pem.LABEL_CMS, "PEM unexpected label: '%s'", blk.label) {
		return
	}
	expected_payload, _ := hex.decode(transmute([]byte)(CMS_PEM_PAYLOAD))
	defer delete(expected_payload)

	if !testing.expectf(t, bytes.equal(pem.block_bytes(blk), expected_payload), "PEM unexpected data: '%x'", blk.data) {
		return
	}

	// Encode and compare.
	encoded := pem.encode(blk.label, pem.block_bytes(blk))
	defer delete(encoded)
	testing.expectf(t, CMS_PEM_TEXT == transmute(string)(encoded), "PEM encode mismatch: '%s'", encoded)
}

@(test)
test_pem_no_blocks :: proc(t: ^testing.T) {
	blk, remaining, err := pem.decode(transmute([]byte)(NOT_PEM_TEXT))
	testing.expect(t, blk == nil)
	testing.expect(t, len(remaining) == 0)
	testing.expect(t, err == nil)
}

@(test)
test_pem_surrounded :: proc(t: ^testing.T) {
	blob := COMMENT_TEXT + "\n" + CMS_PEM_TEXT + "\n" + NOT_PEM_TEXT

	// Should skip `COMMENT_TEXT`
	blk, remaining, err := pem.decode(transmute([]byte)(blob))
	if !testing.expectf(t, err == nil, "PEM decode failed: %v", err) {
		return
	}
	defer pem.block_delete(blk)

	// Check if the decode is correct by ensuring it round-trips.
	encoded := pem.encode(blk.label, pem.block_bytes(blk))
	defer delete(encoded)
	if !testing.expectf(t, CMS_PEM_TEXT == transmute(string)(encoded), "PEM encode mismatch: '%s'", encoded) {
		return
	}

	testing.expectf(t, NOT_PEM_TEXT == transmute(string)(remaining), "PEM remaining not preserved: '%s'", remaining)
}
