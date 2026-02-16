package test_wycheproof

import "core:bytes"
import "core:encoding/hex"
@(require) import "core:encoding/json"
@(require) import "core:log"
@(require) import "core:os"

Hex_Bytes :: string

hexbytes_compare :: proc(x: Hex_Bytes, b: []byte, allocator := context.allocator) -> bool {
	dst := hexbytes_decode(x)
	defer delete(dst)

	return bytes.equal(dst, b)
}

hexbytes_decode :: proc(x: Hex_Bytes, allocator := context.allocator) -> []byte {
	dst, ok := hex.decode(transmute([]byte)(x), allocator)
	if !ok {
		panic("wycheproof/common/Hex_Bytes: invalid hex encoding")
	}

	return dst
}

Result :: string

result_check :: proc(r: Result, ok: bool, is_strict := true) -> bool {
	switch r {
	case "valid":
		return ok
	case "invalid":
		return !ok
	case "acceptable":
		return !is_strict && ok
	case:
		panic("wycheproof/common/Result: invalid result string")
	}
}

result_is_valid :: proc(r: Result) -> bool {
	return r == "valid"
}

result_is_invalid :: proc(r: Result) -> bool {
	return r == "invalid"
}


// The type namings are not following Odin convention, to better match
// the schema, though the fields do.

load :: proc(tvs: ^$T/Test_Vectors, fn: string) -> bool {
	raw_json, err := os.read_entire_file_from_path(fn, context.allocator)
	if err != os.ERROR_NONE {
		log.error("failed to load raw JSON")
		return false
	}

	if err := json.unmarshal(raw_json, tvs); err != nil {
		log.errorf("failed to parse JSON: %v", err)
		return false
	}

	return true
}

Test_Vectors :: struct($Test_Group: typeid) {
	algorithm:         string                       `json:"algorithm"`,
	generator_version: string                       `json:"generatorVersion"`,
	number_of_tests:   int                          `json:"numberOfTests"`,
	header:            []string                     `json:"header"`,
	notes:             map[string]Test_Vectors_Note `json:"notes"`,
	schema:            string                       `json:"schema"`,
	test_groups:       []Test_Group                 `json:"testGroups"`,
}

Test_Vectors_Note :: struct {
	bug_type:    string   `json:"bugType"`,
	description: string   `json:"description"`,
	links:       []string `json:"links"`,
}

Aead_Test_Group :: struct {
	iv_size:  int                `json:"ivSize"`,
	key_size: int                `json:"keySize"`,
	tag_size: int                `json:"tagSize"`,
	tests:    []Aead_Test_Vector `json:"tests"`,
}

Aead_Test_Vector :: struct {
	tc_id:   int       `json:"tcId"`,
	comment: string    `json:"comment"`,
	key:     Hex_Bytes `json:"key"`,
	iv:      Hex_Bytes `json:"iv"`,
	aad:     Hex_Bytes `json:"aad"`,
	msg:     Hex_Bytes `json:"msg"`,
	ct:      Hex_Bytes `json:"ct"`,
	tag:     Hex_Bytes `json:"tag"`,
	result:  Result    `json:"result"`,
	flags:   []string  `json:"flags"`,
}

Hkdf_Test_Group :: struct {
	key_size: int                `json:"keySize"`,
	tests:    []Hkdf_Test_Vector `json:"tests"`,
}

Hkdf_Test_Vector :: struct {
	tc_id:   int       `json:"tcId"`,
	comment: string    `json:"comment"`,
	ikm:     Hex_Bytes `json:"ikm"`,
	salt:    Hex_Bytes `json:"salt"`,
	info:    Hex_Bytes `json:"info"`,
	size:    int       `json:"size"`,
	okm:     Hex_Bytes `json:"okm"`,
	result:  Result    `json:"result"`,
	flags:   []string  `json:"flags"`,
}

Mac_Test_Group :: struct {
	key_size: int               `json:"keySize"`,
	tag_size: int               `json:"tagSize"`,
	tests:    []Mac_Test_Vector `json:"tests"`,
}

Mac_Test_Vector :: struct {
	tc_id:   int       `json:"tcId"`,
	comment: string    `json:"comment"`,
	key:     Hex_Bytes `json:"key"`,
	msg:     Hex_Bytes `json:"msg"`,
	tag:     Hex_Bytes `json:"tag"`,
	result:  Result    `json:"result"`,
	flags:   []string `json:"flags"`,
}

Ecdh_Test_Group :: struct {
	curve: string             `json:"curve"`,
	tests: []Ecdh_Test_Vector `json:"tests"`,
}

Ecdh_Test_Vector :: struct {
	tc_id:   int       `json:"tcId"`,
	comment: string    `json:"comment"`,
	public:  Hex_Bytes `json:"public"`,
	private: Hex_Bytes `json:"private"`,
	shared:  Hex_Bytes `json:"shared"`,
	result:  Result    `json:"result"`,
	flags:   []string  `json:"flags"`,
}

Eddsa_Test_Group :: struct {
	public_key:     Eddsa_Key         `json:"publicKey"`,
	public_key_der: Hex_Bytes         `json:"publicKeyDer"`,
	public_key_pem: string            `json:"publicKeyPem"`,
	public_key_jwk: Eddsa_Jwk         `json:"publicKeyJwk"`,
	type:           string            `json:"type"`,
	tests:          []Dsa_Test_Vector `json:"tests"`,
}

Eddsa_Key :: struct {
	type:     string    `json:"type"`,
	curve:    string    `json:"curve"`,
	key_size: int       `json:"keySize"`,
	pk:       Hex_Bytes `json:"pk"`,
}

Eddsa_Jwk :: struct {
	kid: string `json:"kid"`,
	crv: string `json:"crv"`,
	kty: string `json:"kty"`,
	x:   string `json:"x"`,
}

Dsa_Test_Vector :: struct {
	tc_id:   int       `json:"tcId"`,
	comment: string    `json:"comment"`,
	msg:     Hex_Bytes `json:"msg"`,
	sig:     Hex_Bytes `json:"sig"`,
	result:  Result    `json:"result"`,
	flags:   []string  `json:"flags"`,
}

Pbkdf_Test_Group :: struct {
	type:  string              `json:"type"`,
	tests: []Pbkdf_Test_Vector `json:"tests"`,
}

Pbkdf_Test_Vector :: struct {
	tc_id:           int       `json:"tcId"`,
	comment:         string    `json:"comment"`,
	password:        Hex_Bytes `json:"password"`,
	salt:            Hex_Bytes `json:"salt"`,
	iteration_count: u32       `json:"iterationCount"`,
	dk_len:          int       `json:"dkLen"`,
	dk:              Hex_Bytes `json:"dk"`,
	result:          Result    `json:"result"`,
	flags:           []string  `json:"flags"`,
}
