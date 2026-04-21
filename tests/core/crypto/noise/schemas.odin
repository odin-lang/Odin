package test_noise

import "core:encoding/json"
import "core:log"
import "core:os"

import "../common"

Message :: struct {
	payload:    common.Hex_Bytes `json:"payload"`,
	ciphertext: common.Hex_Bytes `json:"ciphertext"`,
}

Vector :: struct {
	name: string `json:"name"`,

	protocol_name:    string `json:"protocol_name"`,
	fail:             bool   `json:"fail"`,
	fallback:         bool   `json:"fallback"`,
	fallback_pattern: string `json:"fallback_pattern"`,

	init_prologue:      common.Hex_Bytes   `json:"init_prologue"`,
	init_psks:          []common.Hex_Bytes `json:"init_psks"`,
	init_static:        common.Hex_Bytes   `json:"init_static"`,
	init_ephemeral:     common.Hex_Bytes   `json:"init_ephemeral"`,
	init_remote_static: common.Hex_Bytes   `json:"init_remote_static"`,

	resp_prologue:      common.Hex_Bytes   `json:"resp_prologue"`,
	resp_psks:          []common.Hex_Bytes `json:"resp_psks"`,
	resp_static:        common.Hex_Bytes   `json:"resp_static"`,
	resp_ephemeral:     common.Hex_Bytes   `json:"resp_ephemeral"`,
	resp_remote_static: common.Hex_Bytes   `json:"resp_remote_static"`,

	handshake_hash: common.Hex_Bytes `json:"handshake_hash"`,

	messages: []Message `json:"messages"`,
}

Test_Vectors :: struct {
	vectors: []Vector `json:"vectors"`,
}

load :: proc(tvs: ^Test_Vectors, fn: string) -> bool {
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
