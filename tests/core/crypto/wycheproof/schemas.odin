package test_wycheproof

@(require) import "core:encoding/json"
@(require) import "core:log"
@(require) import "core:os"

import "../common"

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

Test_Group_Source :: struct {
	name:    string `json:"name"`,
	version: string `json:"version"`,
}

Aead_Test_Group :: struct {
	iv_size:  int                `json:"ivSize"`,
	key_size: int                `json:"keySize"`,
	tag_size: int                `json:"tagSize"`,
	tests:    []Aead_Test_Vector `json:"tests"`,
}

Aead_Test_Vector :: struct {
	tc_id:   int              `json:"tcId"`,
	comment: string           `json:"comment"`,
	key:     common.Hex_Bytes `json:"key"`,
	iv:      common.Hex_Bytes `json:"iv"`,
	aad:     common.Hex_Bytes `json:"aad"`,
	msg:     common.Hex_Bytes `json:"msg"`,
	ct:      common.Hex_Bytes `json:"ct"`,
	tag:     common.Hex_Bytes `json:"tag"`,
	result:  Result           `json:"result"`,
	flags:   []string         `json:"flags"`,
}

Hkdf_Test_Group :: struct {
	key_size: int                `json:"keySize"`,
	tests:    []Hkdf_Test_Vector `json:"tests"`,
}

Hkdf_Test_Vector :: struct {
	tc_id:   int              `json:"tcId"`,
	comment: string           `json:"comment"`,
	ikm:     common.Hex_Bytes `json:"ikm"`,
	salt:    common.Hex_Bytes `json:"salt"`,
	info:    common.Hex_Bytes `json:"info"`,
	size:    int              `json:"size"`,
	okm:     common.Hex_Bytes `json:"okm"`,
	result:  Result           `json:"result"`,
	flags:   []string         `json:"flags"`,
}

Mac_Test_Group :: struct {
	key_size: int               `json:"keySize"`,
	tag_size: int               `json:"tagSize"`,
	tests:    []Mac_Test_Vector `json:"tests"`,
}

Mac_Test_Vector :: struct {
	tc_id:   int              `json:"tcId"`,
	comment: string           `json:"comment"`,
	key:     common.Hex_Bytes `json:"key"`,
	msg:     common.Hex_Bytes `json:"msg"`,
	tag:     common.Hex_Bytes `json:"tag"`,
	result:  Result           `json:"result"`,
	flags:   []string         `json:"flags"`,
}

Ecdh_Test_Group :: struct {
	curve: string             `json:"curve"`,
	tests: []Ecdh_Test_Vector `json:"tests"`,
}

Ecdh_Test_Vector :: struct {
	tc_id:   int              `json:"tcId"`,
	comment: string           `json:"comment"`,
	public:  common.Hex_Bytes `json:"public"`,
	private: common.Hex_Bytes `json:"private"`,
	shared:  common.Hex_Bytes `json:"shared"`,
	result:  Result           `json:"result"`,
	flags:   []string         `json:"flags"`,
}

Eddsa_Test_Group :: struct {
	public_key:     Eddsa_Key         `json:"publicKey"`,
	public_key_der: common.Hex_Bytes  `json:"publicKeyDer"`,
	public_key_pem: string            `json:"publicKeyPem"`,
	public_key_jwk: Eddsa_Jwk         `json:"publicKeyJwk"`,
	type:           string            `json:"type"`,
	tests:          []Dsa_Test_Vector `json:"tests"`,
}

Eddsa_Key :: struct {
	type:     string           `json:"type"`,
	curve:    string           `json:"curve"`,
	key_size: int              `json:"keySize"`,
	pk:       common.Hex_Bytes `json:"pk"`,
}

Eddsa_Jwk :: struct {
	kid: string `json:"kid"`,
	crv: string `json:"crv"`,
	kty: string `json:"kty"`,
	x:   string `json:"x"`,
}

Ecdsa_Key :: struct {
	type:         string           `json:"type"`,
	curve:        string           `json:"curve"`,
	key_size:     int              `json:"keySize"`,
	uncompressed: common.Hex_Bytes `json:"uncompressed"`,
	wx:           common.Hex_Bytes `json:"wx"`,
	wy:           common.Hex_Bytes `json:"wy"`,
}

Ecdsa_Test_Group :: struct {
	public_key:     Ecdsa_Key         `json:"publicKey"`,
	public_key_der: common.Hex_Bytes  `json:"publicKeyDer"`,
	public_key_pem: string            `json:"publicKeyPem"`,
	type:           string            `json:"type"`,
	sha:            string            `json:"sha"`,
	tests:          []Dsa_Test_Vector `json:"tests"`,
}

Dsa_Test_Vector :: struct {
	tc_id:   int              `json:"tcId"`,
	comment: string           `json:"comment"`,
	msg:     common.Hex_Bytes `json:"msg"`,
	sig:     common.Hex_Bytes `json:"sig"`,
	result:  Result           `json:"result"`,
	flags:   []string         `json:"flags"`,
}

Pbkdf_Test_Group :: struct {
	type:  string              `json:"type"`,
	tests: []Pbkdf_Test_Vector `json:"tests"`,
}

Pbkdf_Test_Vector :: struct {
	tc_id:           int              `json:"tcId"`,
	comment:         string           `json:"comment"`,
	password:        common.Hex_Bytes `json:"password"`,
	salt:            common.Hex_Bytes `json:"salt"`,
	iteration_count: u32              `json:"iterationCount"`,
	dk_len:          int              `json:"dkLen"`,
	dk:              common.Hex_Bytes `json:"dk"`,
	result:          Result           `json:"result"`,
	flags:           []string         `json:"flags"`,
}

Kem_Test_Group :: struct {
	type:          string            `json:"type"`,
	source:        Test_Group_Source `json:"source"`,
	parameter_set: string            `json:"parameterSet"`,
	tests:         []Kem_Test_Vector `json:"tests"`,
}

Kem_Test_Vector :: struct {
	tc_id:           int              `json:"tcId"`,
	flags:           []string         `json:"flags"`,
	comment:         string           `json:"comment"`,
	seed:            common.Hex_Bytes `json:"seed"`,
	m:               common.Hex_Bytes `json:"m"`,
	ek:              common.Hex_Bytes `json:"ek"`,
	dk:              common.Hex_Bytes `json:"dk"`,
	c:               common.Hex_Bytes `json:"c"`,
	k:               common.Hex_Bytes `json:"K"`,
	result:          Result           `json:"result"`,
}
