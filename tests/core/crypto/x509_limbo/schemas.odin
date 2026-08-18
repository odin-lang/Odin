package test_x509_limbo

import "core:encoding/json"
import "core:os"

// The subset of the C2SP x509-limbo limbo.json schema this harness consumes.
// See https://github.com/C2SP/x509-limbo.

Limbo :: struct {
	testcases: []Testcase `json:"testcases"`,
}

Testcase :: struct {
	id:                      string    `json:"id"`,
	expected_result:         string    `json:"expected_result"`, // "SUCCESS" | "FAILURE"
	validation_kind:         string    `json:"validation_kind"`, // "SERVER" | "CLIENT" | ...
	validation_time:         string    `json:"validation_time"`, // RFC 3339, or "" when null
	peer_certificate:        string    `json:"peer_certificate"`, // the leaf, PEM
	untrusted_intermediates: []string  `json:"untrusted_intermediates"`, // PEM
	trusted_certs:           []string  `json:"trusted_certs"`, // the roots, PEM
	expected_peer_name:      Peer_Name `json:"expected_peer_name"`,
}

Peer_Name :: struct {
	kind:  string `json:"kind"`, // "DNS" | "IP" | ...
	value: string `json:"value"`,
}

// load reads and parses limbo.json at `path` into `dst`, allocating into the
// current context allocator. Returns false when the file is absent (the caller
// then skips the suite) or does not parse.
load :: proc(dst: ^Limbo, path: string) -> bool {
	raw, err := os.read_entire_file_from_path(path, context.allocator)
	if err != os.ERROR_NONE {
		return false
	}
	defer delete(raw)
	return json.unmarshal(raw, dst) == nil
}
