package test_core_crypto

import "core:bytes"
import "core:encoding/hex"
import "core:testing"

import "core:crypto"
import "core:crypto/ecdsa"
import "core:crypto/ed25519"
import "core:crypto/hash"

@(test)
test_ecdsa :: proc(t: ^testing.T) {
	test_vectors_deterministic := []struct{
		curve:    ecdsa.Curve,
		hash:     hash.Algorithm,
		priv_key: string,
		pub_key:  string,
		msg:      string,
		sig_raw:  string,
	} {
		// Test vectors from RFC 6979
		{
			.SECP256R1,
			.SHA256,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"sample",
			"efd48b2aacb6a8fd1140dd9cd45e81d69d2c877b56aaf991c34d0ea84eaf3716f7cb1c942d657c41d436c7a1b6e29f65f3e900dbb9aff4064dc4ab2f843acda8",
		},
		{
			.SECP256R1,
			.SHA384,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"sample",
			"0eafea039b20e9b42309fb1d89e213057cbf973dc0cfc8f129edddc800ef77194861f0491e6998b9455193e34e7b0d284ddd7149a74b95b9261f13abde940954",
		},
		{
			.SECP256R1,
			.SHA512,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"sample",
			"8496a60b5e9b47c825488827e0495b0e3fa109ec4568fd3f8d1097678eb97f002362ab1adbe2b8adf9cb9edab740ea6049c028114f2460f96554f61fae3302fe",
		},
		{
			.SECP256R1,
			.SHA256,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"test",
			"f1abb023518351cd71d881567b1ea663ed3efcf6c5132b354f28d3b0b7d38367019f4113742a2b14bd25926b49c649155f267e60d3814b4c0cc84250e46f0083",
		},
		{
			.SECP256R1,
			.SHA384,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"test",
			"83910e8b48bb0c74244ebdf7f07a1c5413d61472bd941ef3920e623fbccebeb68ddbec54cf8cd5874883841d712142a56a8d0f218f5003cb0296b6b509619f2c",
		},
		{
			.SECP256R1,
			.SHA512,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"test",
			"461d93f31b6540894788fd206c07cfa0cc35f46fa3c91816fff1040ad1581a0439af9f15de0db8d97e72719c74820d304ce5226e32dedae67519e840d1194e55",
		},
		{
			.SECP384R1,
			.SHA384,
			"6b9d3dad2e1b8c1c05b19875b6659f4de23c3b667bf297ba9aa47740787137d896d5724e4c70a825f872c9ea60d2edf5",
			"04ec3a4e415b4e19a4568618029f427fa5da9a8bc4ae92e02e06aae5286b300c64def8f0ea9055866064a254515480bc138015d9b72d7d57244ea8ef9ac0c621896708a59367f9dfb9f54ca84b3f1c9db1288b231c3ae0d4fe7344fd2533264720",
			"sample",
			"94edbb92a5ecb8aad4736e56c691916b3f88140666ce9fa73d64c4ea95ad133c81a648152e44acf96e36dd1e80fabe4699ef4aeb15f178cea1fe40db2603138f130e740a19624526203b6351d0a3a94fa329c145786e679e7b82c71a38628ac8",
		},
		{
			.SECP384R1,
			.SHA512,
			"6b9d3dad2e1b8c1c05b19875b6659f4de23c3b667bf297ba9aa47740787137d896d5724e4c70a825f872c9ea60d2edf5",
			"04ec3a4e415b4e19a4568618029f427fa5da9a8bc4ae92e02e06aae5286b300c64def8f0ea9055866064a254515480bc138015d9b72d7d57244ea8ef9ac0c621896708a59367f9dfb9f54ca84b3f1c9db1288b231c3ae0d4fe7344fd2533264720",
			"sample",
			"ed0959d5880ab2d869ae7f6c2915c6d60f96507f9cb3e047c0046861da4a799cfe30f35cc900056d7c99cd7882433709512c8cceee3890a84058ce1e22dbc2198f42323ce8aca9135329f03c068e5112dc7cc3ef3446defceb01a45c2667fdd5",
		},
		{
			.SECP384R1,
			.SHA384,
			"6b9d3dad2e1b8c1c05b19875b6659f4de23c3b667bf297ba9aa47740787137d896d5724e4c70a825f872c9ea60d2edf5",
			"04ec3a4e415b4e19a4568618029f427fa5da9a8bc4ae92e02e06aae5286b300c64def8f0ea9055866064a254515480bc138015d9b72d7d57244ea8ef9ac0c621896708a59367f9dfb9f54ca84b3f1c9db1288b231c3ae0d4fe7344fd2533264720",
			"test",
			"8203b63d3c853e8d77227fb377bcf7b7b772e97892a80f36ab775d509d7a5feb0542a7f0812998da8f1dd3ca3cf023dbddd0760448d42d8a43af45af836fce4de8be06b485e9b61b827c2f13173923e06a739f040649a667bf3b828246baa5a5",
		},
		{
			.SECP384R1,
			.SHA512,
			"6b9d3dad2e1b8c1c05b19875b6659f4de23c3b667bf297ba9aa47740787137d896d5724e4c70a825f872c9ea60d2edf5",
			"04ec3a4e415b4e19a4568618029f427fa5da9a8bc4ae92e02e06aae5286b300c64def8f0ea9055866064a254515480bc138015d9b72d7d57244ea8ef9ac0c621896708a59367f9dfb9f54ca84b3f1c9db1288b231c3ae0d4fe7344fd2533264720",
			"test",
			"a0d5d090c9980faf3c2ce57b7ae951d31977dd11c775d314af55f76c676447d06fb6495cd21b4b6e340fc236584fb277976984e59b4c77b0e8e4460dca3d9f20e07b9bb1f63beefaf576f6b2e8b224634a2092cd3792e0159ad9cee37659c736",
		},
		// Special case that exercises the rejection sampling.
		// https://github.com/C2SP/CCTV/tree/main/RFC6979
		{
			.SECP256R1,
			.SHA256,
			"c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721",
			"0460fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb67903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299",
			"wv[vnX",
			"efd9073b652e76da1b5a019c0e4a2e3fa529b035a6abb91ef67f0ed7a1f212343db4706c9d9f4a4fe13bb5e08ef0fab53a57dbab2061c83a35fa411c68d2ba33",
		},
	}
	for v, _ in test_vectors_deterministic {
		priv_bytes, _ := hex.decode(transmute([]byte)(v.priv_key), context.temp_allocator)
		pub_bytes, _ := hex.decode(transmute([]byte)(v.pub_key), context.temp_allocator)
		msg_bytes := bytes.clone(transmute([]byte)(v.msg), context.temp_allocator)
		sig_bytes, _ := hex.decode(transmute([]byte)(v.sig_raw), context.temp_allocator)

		priv_key: ecdsa.Private_Key
		ok := ecdsa.private_key_set_bytes(&priv_key, v.curve, priv_bytes)
		testing.expectf(
			t,
			ok,
			"Expected %s to be a valid %v private key",
			v.priv_key,
			v.curve,
		)

		priv_key_bytes := make([]byte, ecdsa.PRIVATE_KEY_SIZES[v.curve], context.temp_allocator)
		ecdsa.private_key_bytes(&priv_key, priv_key_bytes)
		priv_s := string(hex.encode(priv_key_bytes, context.temp_allocator))
		testing.expectf(
			t,
			priv_s == v.priv_key,
			"Expected private key %s round-trip, got %s",
			v.priv_key,
			priv_s,
		)

		pub_key: ecdsa.Public_Key
		ok = ecdsa.public_key_set_bytes(&pub_key, v.curve, pub_bytes)
		testing.expectf(
			t,
			ok,
			"Expected %s to be a valid %s public key",
			v.pub_key,
			v.curve,
		)

		pub_key_bytes := make([]byte, ecdsa.PUBLIC_KEY_SIZES[v.curve], context.temp_allocator)
		ecdsa.public_key_bytes(&pub_key, pub_key_bytes)
		pub_s := string(hex.encode(pub_key_bytes, context.temp_allocator))
		testing.expectf(
			t,
			pub_s == v.pub_key,
			"Expected public key %s round-trip, got %s",
			v.pub_key,
			pub_s,
		)

		priv_pub_key: ecdsa.Public_Key
		ecdsa.public_key_set_priv(&priv_pub_key, &priv_key)
		ok = ecdsa.public_key_equal(&pub_key, &priv_pub_key)
		testing.expectf(
			t,
			ok,
			"Expected %v to be %s's public key",
			&priv_pub_key,
			v.priv_key,
		)

		ok = ecdsa.verify_raw(&pub_key, v.hash, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok,
			"Expected true for verify(%s, %v, %s, %s)",
			v.pub_key,
			v.hash,
			v.msg,
			v.sig_raw,
		)

		// Signatures are deterministic for these test cases.
		sig := make([]byte, ecdsa.RAW_SIGNATURE_SIZES[v.curve], context.temp_allocator)
		ok = ecdsa.sign_raw(&priv_key, v.hash, msg_bytes, sig, true)
		x := string(hex.encode(sig[:], context.temp_allocator))
		testing.expectf(
			t,
			ok && x == v.sig_raw,
			"Expected %s for sign(%s, %v, %s), got %s",
			v.sig_raw,
			v.priv_key,
			v.hash,
			v.msg,
			x,
		)

		// But when possible, we also add entropy by default.
		when crypto.HAS_RAND_BYTES {
			ok = ecdsa.sign_raw(&priv_key, v.hash, msg_bytes, sig)
			x = string(hex.encode(sig[:], context.temp_allocator))
			testing.expectf(
				t,
				ok && x != v.sig_raw,
				"Expected not %s for sign(%s, %v, %s), got %s",
				v.sig_raw,
				v.priv_key,
				v.hash,
				v.msg,
				x,
			)
		}

		// Corrupt the message and make sure verification fails.
		msg_bytes[0] ~= 0x69
		ok = ecdsa.verify_raw(&pub_key, v.hash, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok == false,
			"Expected false for verify(%s, %v %s (corrupted), %s)",
			v.pub_key,
			v.hash,
			v.msg,
			v.sig_raw,
		)
	}

	// ASN.1 tests requires entorpy.
	when crypto.HAS_RAND_BYTES == false {
		return
	}
	msg_str : string : "Feed the Fire. Let the Last Cinders Burn."
	for _ in 0 ..< 1000 {
		msg := transmute([]byte)(msg_str)

		priv_key: ecdsa.Private_Key
		ok := ecdsa.private_key_generate(&priv_key, .SECP256R1)
		testing.expectf(t, ok, "Failed to generate private key")

		sig: []byte
		sig, ok = ecdsa.sign_asn1(&priv_key, .SHA256, msg, context.temp_allocator)
		testing.expectf(
			t,
			ok && len(sig) > 0,
			"Failed for sign(%v, secp256r1/SHA256, %s)",
			priv_key,
			msg,
		)

		pub_key := &priv_key._pub_key
		ok = ecdsa.verify_asn1(pub_key, .SHA256, msg, sig)
		testing.expectf(
			t,
			ok,
			"Expected true for verify(%v, SHA256, %s, %x)",
			pub_key,
			msg,
			sig,
		)
	}
}

@(test)
test_ed25519 :: proc(t: ^testing.T) {
	test_vectors_rfc := []struct {
		priv_key: string,
		pub_key:  string,
		msg:      string,
		sig:      string,
	} {
		// Test vectors from RFC 8032
		{
			"9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
			"d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
			"",
			"e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b",
		},
		{
			"4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
			"3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
			"72",
			"92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00",
		},
		{
			"c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
			"fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
			"af82",
			"6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a",
		},
		// TEST 1024 omitted for brevity, because all that does is add more to SHA-512
		{
			"833fe62409237b9d62ec77587520911e9a759cec1d19755b7da901b96dca3d42",
			"ec172b93ad5e563bf4932c70e1245034c35467ef2efd4d64ebf819683467e2bf",
			"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
			"dc2a4459e7369633a52b1bf277839a00201009a3efbf3ecb69bea2186c26b58909351fc9ac90b3ecfdfbc7c66431e0303dca179c138ac17ad9bef1177331a704",
		},
	}
	for v, _ in test_vectors_rfc {
		priv_bytes, _ := hex.decode(transmute([]byte)(v.priv_key), context.temp_allocator)
		pub_bytes, _ := hex.decode(transmute([]byte)(v.pub_key), context.temp_allocator)
		msg_bytes, _ := hex.decode(transmute([]byte)(v.msg), context.temp_allocator)
		sig_bytes, _ := hex.decode(transmute([]byte)(v.sig), context.temp_allocator)

		priv_key: ed25519.Private_Key
		ok := ed25519.private_key_set_bytes(&priv_key, priv_bytes)
		testing.expectf(
			t,
			ok,
			"Expected %s to be a valid private key",
			v.priv_key,
		)

		key_bytes: [32]byte
		ed25519.private_key_bytes(&priv_key, key_bytes[:])
		priv_s := string(hex.encode(key_bytes[:], context.temp_allocator))
		testing.expectf(
			t,
			priv_s == v.priv_key,
			"Expected private key %s round-trip, got %s",
			v.priv_key,
			priv_s,
		)

		pub_key: ed25519.Public_Key
		ok = ed25519.public_key_set_bytes(&pub_key, pub_bytes)
		testing.expectf(
			t,
			ok,
			"Expected %s to be a valid public key (priv->pub: %s)",
			v.pub_key,
		)

		ed25519.public_key_bytes(&pub_key, key_bytes[:])
		pub_s := string(hex.encode(priv_key._pub_key._b[:], context.temp_allocator))
		testing.expectf(
			t,
			pub_s == v.pub_key,
			"Expected public key %s round-trip, got %s",
			v.pub_key,
			pub_s,
		)

		sig: [ed25519.SIGNATURE_SIZE]byte
		ed25519.sign(&priv_key, msg_bytes, sig[:])
		x := string(hex.encode(sig[:], context.temp_allocator))
		testing.expectf(
			t,
			x == v.sig,
			"Expected %s for sign(%s, %s), got %s",
			v.sig,
			v.priv_key,
			v.msg,
			x,
		)

		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok,
			"Expected true for verify(%s, %s, %s)",
			v.pub_key,
			v.msg,
			v.sig,
		)

		ok = ed25519.verify(&priv_key._pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok,
			"Expected true for verify(pub(%s), %s %s)",
			v.priv_key,
			v.msg,
			v.sig,
		)

		// Corrupt the message and make sure verification fails.
		switch len(msg_bytes) {
		case 0:
			tmp_msg := []byte{69}
			msg_bytes = tmp_msg[:]
		case:
			msg_bytes[0] = msg_bytes[0] ~ 69
		}
		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok == false,
			"Expected false for verify(%s, %s (corrupted), %s)",
			v.pub_key,
			v.msg,
			v.sig,
		)
	}

	// Test cases from "Taming the many EdDSAs", which aim to exercise
	// all of the ed25519 edge cases/implementation differences.
	//
	// - https://eprint.iacr.org/2020/1244
	// - https://github.com/novifinancial/ed25519-speccheck
	test_vectors_speccheck := []struct {
		pub_key:        string,
		msg:            string,
		sig:            string,
		pub_key_ok:     bool,
		sig_ok:         bool,
		sig_ok_relaxed: bool, // Ok if the small-order A check is relaxed.
	} {
		// S = 0, small-order A, small-order R
		{
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa",
			"8c93255d71dcab10e8f379c26200f3c7bd5f09d9bc3068d3ef4edeb4853022b6",
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac037a0000000000000000000000000000000000000000000000000000000000000000",
			true,
			false,
			true,
		},
		// 0 < S < L, small-order A, mixed-order R
		{
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa",
			"9bd9f44f4dcc75bd531b56b2cd280b0bb38fc1cd6d1230e14861d861de092e79",
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43a5bb704786be79fc476f91d3f3f89b03984d8068dcf1bb7dfc6637b45450ac04",
			true,
			false,
			true,
		},
		// 0 < S < L, mixed-order A, small-order R
		{
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43",
			"aebf3f2601a0c8c5d39cc7d8911642f740b78168218da8471772b35f9d35b9ab",
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c4bd45aecaca5b24fb97bc10ac27ac8751a7dfe1baff8b953ec9f5833ca260e",
			true,
			true,
			true,
		},
		// 0 < S < L, mixed-order A, mixed-order R
		{
			"cdb267ce40c5cd45306fa5d2f29731459387dbf9eb933b7bd5aed9a765b88d4d",
			"9bd9f44f4dcc75bd531b56b2cd280b0bb38fc1cd6d1230e14861d861de092e79",
			"9046a64750444938de19f227bb80485e92b83fdb4b6506c160484c016cc1852f87909e14428a7a1d62e9f22f3d3ad7802db02eb2e688b6c52fcd6648a98bd009",
			true,
			true,
			true,
		},
		// 0 < S < L, mixed-order A, mixed-order R
		{
			"cdb267ce40c5cd45306fa5d2f29731459387dbf9eb933b7bd5aed9a765b88d4d",
			"e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec4011eaccd55b53f56c",
			"160a1cb0dc9c0258cd0a7d23e94d8fa878bcb1925f2c64246b2dee1796bed5125ec6bc982a269b723e0668e540911a9a6a58921d6925e434ab10aa7940551a09",
			true,
			true, // cofactored-only
			true,
		},
		// 0 < S < L, mixed-order A, L-order R
		{
			"cdb267ce40c5cd45306fa5d2f29731459387dbf9eb933b7bd5aed9a765b88d4d",
			"e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec4011eaccd55b53f56c",
			"21122a84e0b5fca4052f5b1235c80a537878b38f3142356b2c2384ebad4668b7e40bc836dac0f71076f9abe3a53f9c03c1ceeeddb658d0030494ace586687405",
			true,
			true, // cofactored only, (fail if 8h is pre-reduced)
			true,
		},
		// S > L, L-order A, L-order R
		{
			"442aad9f089ad9e14647b1ef9099a1ff4798d78589e66f28eca69c11f582a623",
			"85e241a07d148b41e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec40",
			"e96f66be976d82e60150baecff9906684aebb1ef181f67a7189ac78ea23b6c0e547f7690a0e2ddcd04d87dbc3490dc19b3b3052f7ff0538cb68afb369ba3a514",
			true,
			false,
			false,
		},
		// S >> L, L-order A, L-order R
		{
			"442aad9f089ad9e14647b1ef9099a1ff4798d78589e66f28eca69c11f582a623",
			"85e241a07d148b41e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec40",
			"8ce5b96c8f26d0ab6c47958c9e68b937104cd36e13c33566acd2fe8d38aa19427e71f98a473474f2f13f06f97c20d58cc3f54b8bd0d272f42b695dd7e89a8c22",
			true,
			false,
			false,
		},
		// 0 < S < L, mixed-order A, small-order R (non-canonical R, reduced for hash)
		{
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43",
			"9bedc267423725d473888631ebf45988bad3db83851ee85c85e241a07d148b41",
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03be9678ac102edcd92b0210bb34d7428d12ffc5df5f37e359941266a4e35f0f",
			true,
			false,
			false,
		},
		// 0 < S < L, mixed-order A, small-order R (non-canonical R, not reduced for hash)
		{
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43",
			"9bedc267423725d473888631ebf45988bad3db83851ee85c85e241a07d148b41",
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffca8c5b64cd208982aa38d4936621a4775aa233aa0505711d8fdcfdaa943d4908",
			true,
			false,
			false,
		},
		// 0 < S < L, small-order A, mixed-order R (non-canonical A, reduced for hash)
		{
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
			"e96b7021eb39c1a163b6da4e3093dcd3f21387da4cc4572be588fafae23c155b",
			"a9d55260f765261eb9b84e106f665e00b867287a761990d7135963ee0a7d59dca5bb704786be79fc476f91d3f3f89b03984d8068dcf1bb7dfc6637b45450ac04",
			false,
			false,
			false,
		},
		// 0 < S < L, small-order A, mixed-order R (non-canonical A, not reduced for hash)
		{
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
			"39a591f5321bbe07fd5a23dc2f39d025d74526615746727ceefd6e82ae65c06f",
			"a9d55260f765261eb9b84e106f665e00b867287a761990d7135963ee0a7d59dca5bb704786be79fc476f91d3f3f89b03984d8068dcf1bb7dfc6637b45450ac04",
			false,
			false,
			false,
		},
	}
	for v, i in test_vectors_speccheck {
		pub_bytes, _ := hex.decode(transmute([]byte)(v.pub_key), context.temp_allocator)
		msg_bytes, _ := hex.decode(transmute([]byte)(v.msg), context.temp_allocator)
		sig_bytes, _ := hex.decode(transmute([]byte)(v.sig), context.temp_allocator)

		pub_key: ed25519.Public_Key
		ok := ed25519.public_key_set_bytes(&pub_key, pub_bytes)
		testing.expectf(
			t,
			ok == v.pub_key_ok,
			"speccheck/%d: Expected %s to be a (in)valid public key, got %v",
			i,
			v.pub_key,
			ok,
		)

		// If A is rejected for being non-canonical, skip signature check.
		if !v.pub_key_ok {
			continue
		}

		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok == v.sig_ok,
			"speccheck/%d Expected %v for verify(%s, %s, %s)",
			i,
			v.sig_ok,
			v.pub_key,
			v.msg,
			v.sig,
		)

		// If the signature is accepted, skip the relaxed signature check.
		if v.sig_ok {
			continue
		}

		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes, true)
		testing.expectf(
			t,
			ok == v.sig_ok_relaxed,
			"speccheck/%d Expected %v for verify(%s, %s, %s, true)",
			i,
			v.sig_ok_relaxed,
			v.pub_key,
			v.msg,
			v.sig,
		)
	}
}
