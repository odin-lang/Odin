package test_wycheproof

import "core:crypto/hash"
import "core:fmt"
import "core:strings"

panic_fn :: proc(arg: any)

hash_name_to_algorithm :: proc(alg_str: string) -> (hash.Algorithm, bool) {
	alg_enums := [][hash.Algorithm]string {
		hash.ALGORITHM_NAMES,
		// The HMAC test vectors omit `-`.
		#partial [hash.Algorithm]string {
			.SHA224 = "SHA224",
			.SHA256 = "SHA256",
			.SHA384 = "SHA384",
			.SHA512 = "SHA512",
			.SHA512_256 = "SHA512/256",
			.Insecure_SHA1 = "SHA1",
		},
	}
	for &e in alg_enums {
		for n, alg in e {
			if n == alg_str {
				return alg, true
			}
		}
	}

	return .Invalid, false
}

MAC_ALGORITHM :: enum {
	Invalid,
	HMAC,
	KMAC128,
	KMAC256,
	SIPHASH_1_3,
	SIPHASH_2_4,
	SIPHASH_4_8,
}

mac_algorithm :: proc(alg_str: string) -> (MAC_ALGORITHM, hash.Algorithm, string, bool) {
	PREFIX_HMAC :: "HMAC"

	if strings.has_prefix(alg_str, PREFIX_HMAC) {
		alg_str_ := strings.trim_prefix(alg_str, PREFIX_HMAC)
		alg, ok := hash_name_to_algorithm(alg_str_)
		alg_str_ = fmt.aprintf("hmac/%s", strings.to_lower(alg_str_))
		return .HMAC, alg, alg_str_, ok
	}

	ALG_KMAC128 :: "KMAC128"
	ALG_KMAC256 :: "KMAC256"
	ALG_SIPHASH_1_3 :: "SipHash-1-3"
	ALG_SIPHASH_2_4 :: "SipHash-2-4"
	ALG_SIPHASH_4_8 :: "SipHash-4-8"

	mac_alg := MAC_ALGORITHM.Invalid
	ok := true
	switch alg_str {
	case ALG_KMAC128:
		mac_alg = .KMAC128
	case ALG_KMAC256:
		mac_alg = .KMAC256
	case ALG_SIPHASH_1_3:
		mac_alg = .SIPHASH_1_3
	case ALG_SIPHASH_2_4:
		mac_alg = .SIPHASH_2_4
	case ALG_SIPHASH_4_8:
		mac_alg = .SIPHASH_4_8
	case:
		ok = false
	}
	return mac_alg, .Invalid, strings.to_lower(alg_str), ok
}