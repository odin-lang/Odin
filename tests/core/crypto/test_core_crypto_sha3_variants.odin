package test_core_crypto

import "core:encoding/hex"
import "core:fmt"
import "core:testing"

import "core:crypto/kmac"
import "core:crypto/shake"
import "core:crypto/tuplehash"

import tc "tests:common"

@(test)
test_sha3_variants :: proc(t: ^testing.T) {
	tc.log(t, "Testing SHA3 derived functions")

	test_shake(t)
	test_cshake(t)
	test_tuplehash(t)
	test_kmac(t)
}

@(test)
test_shake :: proc(t: ^testing.T) {
	tc.log(t, "Testing SHAKE")

	test_vectors := []struct {
		sec_strength: int,
		output:       string,
		str:          string,
	} {
		// SHAKE128
		{128, "7f9c2ba4e88f827d616045507605853e", ""},
		{128, "f4202e3c5852f9182a0430fd8144f0a7", "The quick brown fox jumps over the lazy dog"},
		{128, "853f4538be0db9621a6cea659a06c110", "The quick brown fox jumps over the lazy dof"},

		// SHAKE256
		{256, "46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762f", ""},
		{
			256,
			"2f671343d9b2e1604dc9dcf0753e5fe15c7c64a0d283cbbf722d411a0e36f6ca",
			"The quick brown fox jumps over the lazy dog",
		},
		{
			256,
			"46b1ebb2e142c38b9ac9081bef72877fe4723959640fa57119b366ce6899d401",
			"The quick brown fox jumps over the lazy dof",
		},
	}

	for v in test_vectors {
		dst := make([]byte, len(v.output) / 2, context.temp_allocator)

		ctx: shake.Context
		switch v.sec_strength {
		case 128:
			shake.init_128(&ctx)
		case 256:
			shake.init_256(&ctx)
		}

		shake.write(&ctx, transmute([]byte)(v.str))
		shake.read(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		tc.expect(
			t,
			dst_str == v.output,
			fmt.tprintf(
				"SHAKE%d: Expected: %s for input of %s, but got %s instead",
				v.sec_strength,
				v.output,
				v.str,
				dst_str,
			),
		)
	}
}

@(test)
test_cshake :: proc(t: ^testing.T) {
	tc.log(t, "Testing cSHAKE")

	test_vectors := []struct {
		sec_strength: int,
		domainsep:    string,
		output:       string,
		str:          string,
	} {
		// cSHAKE128
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/cSHAKE_samples.pdf
		{
			128,
			"Email Signature",
			"c1c36925b6409a04f1b504fcbca9d82b4017277cb5ed2b2065fc1d3814d5aaf5",
			"00010203",
		},
		{
			128,
			"Email Signature",
			"c5221d50e4f822d96a2e8881a961420f294b7b24fe3d2094baed2c6524cc166b",
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7",
		},

		// cSHAKE256
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/cSHAKE_samples.pdf
		{
			256,
			"Email Signature",
			"d008828e2b80ac9d2218ffee1d070c48b8e4c87bff32c9699d5b6896eee0edd164020e2be0560858d9c00c037e34a96937c561a74c412bb4c746469527281c8c",
			"00010203",
		},
		{
			256,
			"Email Signature",
			"07dc27b11e51fbac75bc7b3c1d983e8b4b85fb1defaf218912ac86430273091727f42b17ed1df63e8ec118f04b23633c1dfb1574c8fb55cb45da8e25afb092bb",
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7",
		},
	}

	for v in test_vectors {
		dst := make([]byte, len(v.output) / 2, context.temp_allocator)

		domainsep := transmute([]byte)(v.domainsep)

		ctx: shake.Context
		switch v.sec_strength {
		case 128:
			shake.init_cshake_128(&ctx, domainsep)
		case 256:
			shake.init_cshake_256(&ctx, domainsep)
		}

		data, _ := hex.decode(transmute([]byte)(v.str))
		shake.write(&ctx, data)
		shake.read(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		tc.expect(
			t,
			dst_str == v.output,
			fmt.tprintf(
				"cSHAKE%d: Expected: %s for input of %s, but got %s instead",
				v.sec_strength,
				v.output,
				v.str,
				dst_str,
			),
		)
	}
}

@(test)
test_tuplehash :: proc(t: ^testing.T) {
	tc.log(t, "Testing TupleHash(XOF)")

	test_vectors := []struct {
		sec_strength: int,
		domainsep:    string,
		output:       string,
		tuple:        []string,
		is_xof:       bool,
	} {
		// TupleHash128
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/TupleHash_samples.pdf
		{
			128,
			"",
			"c5d8786c1afb9b82111ab34b65b2c0048fa64e6d48e263264ce1707d3ffc8ed1",
			[]string{
				"000102",
				"101112131415",
			},
			false,
		},
		{
			128,
			"My Tuple App",
			"75cdb20ff4db1154e841d758e24160c54bae86eb8c13e7f5f40eb35588e96dfb",
			[]string{
				"000102",
				"101112131415",
			},
			false,
		},
		{
			128,
			"My Tuple App",
			"e60f202c89a2631eda8d4c588ca5fd07f39e5151998deccf973adb3804bb6e84",
			[]string{
				"000102",
				"101112131415",
				"202122232425262728",
			},
			false,
		},

		// TupleHash256
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/TupleHash_samples.pdf
		{
			256,
			"",
			"cfb7058caca5e668f81a12a20a2195ce97a925f1dba3e7449a56f82201ec607311ac2696b1ab5ea2352df1423bde7bd4bb78c9aed1a853c78672f9eb23bbe194",
			[]string{
				"000102",
				"101112131415",
			},
			false,
		},
		{
			256,
			"My Tuple App",
			"147c2191d5ed7efd98dbd96d7ab5a11692576f5fe2a5065f3e33de6bba9f3aa1c4e9a068a289c61c95aab30aee1e410b0b607de3620e24a4e3bf9852a1d4367e",
			[]string{
				"000102",
				"101112131415",
			},
			false,
		},
		{
			256,
			"My Tuple App",
			"45000be63f9b6bfd89f54717670f69a9bc763591a4f05c50d68891a744bcc6e7d6d5b5e82c018da999ed35b0bb49c9678e526abd8e85c13ed254021db9e790ce",
			[]string{
				"000102",
				"101112131415",
				"202122232425262728",
			},
			false,
		},

		// TupleHashXOF128
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/TupleHashXOF_samples.pdf
		{
			128,
			"",
			"2f103cd7c32320353495c68de1a8129245c6325f6f2a3d608d92179c96e68488",
			[]string{
				"000102",
				"101112131415",
			},
			true,
		},
		{
			128,
			"My Tuple App",
			"3fc8ad69453128292859a18b6c67d7ad85f01b32815e22ce839c49ec374e9b9a",
			[]string{
				"000102",
				"101112131415",
			},
			true,
		},
		{
			128,
			"My Tuple App",
			"900fe16cad098d28e74d632ed852f99daab7f7df4d99e775657885b4bf76d6f8",
			[]string{
				"000102",
				"101112131415",
				"202122232425262728",
			},
			true,
		},

		// TupleHashXOF256
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/TupleHashXOF_samples.pdf
		{
			256,
			"",
			"03ded4610ed6450a1e3f8bc44951d14fbc384ab0efe57b000df6b6df5aae7cd568e77377daf13f37ec75cf5fc598b6841d51dd207c991cd45d210ba60ac52eb9",
			[]string{
				"000102",
				"101112131415",
			},
			true,
		},
		{
			256,
			"My Tuple App",
			"6483cb3c9952eb20e830af4785851fc597ee3bf93bb7602c0ef6a65d741aeca7e63c3b128981aa05c6d27438c79d2754bb1b7191f125d6620fca12ce658b2442",
			[]string{
				"000102",
				"101112131415",
			},
			true,
		},
		{
			256,
			"My Tuple App",
			"0c59b11464f2336c34663ed51b2b950bec743610856f36c28d1d088d8a2446284dd09830a6a178dc752376199fae935d86cfdee5913d4922dfd369b66a53c897",
			[]string{
				"000102",
				"101112131415",
				"202122232425262728",
			},
			true,
		},
	}

	for v in test_vectors {
		dst := make([]byte, len(v.output) / 2, context.temp_allocator)

		domainsep := transmute([]byte)(v.domainsep)

		ctx: tuplehash.Context
		switch v.sec_strength {
		case 128:
			tuplehash.init_128(&ctx, domainsep)
		case 256:
			tuplehash.init_256(&ctx, domainsep)
		}

		for e in v.tuple {
			data, _ := hex.decode(transmute([]byte)(e))
			tuplehash.write_element(&ctx, data)
		}

		suffix: string
		switch v.is_xof {
		case true:
			suffix = "XOF"
			tuplehash.read(&ctx, dst)
		case false:
			tuplehash.final(&ctx, dst)
		}

		dst_str := string(hex.encode(dst, context.temp_allocator))

		tc.expect(
			t,
			dst_str == v.output,
			fmt.tprintf(
				"TupleHash%s%d: Expected: %s for input of %v, but got %s instead",
				suffix,
				v.sec_strength,
				v.output,
				v.tuple,
				dst_str,
			),
		)
	}
}

@(test)
test_kmac :: proc(t:^testing.T) {
	tc.log(t, "Testing KMAC")

	test_vectors := []struct {
		sec_strength: int,
		key:          string,
		domainsep:    string,
		msg:          string,
		output:       string,
	} {
		// KMAC128
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/KMAC_samples.pdf
		{
			128,
			"404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f",
			"",
			"00010203",
			"e5780b0d3ea6f7d3a429c5706aa43a00fadbd7d49628839e3187243f456ee14e",
		},
		{
			128,
			"404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f",
			"My Tagged Application",
			"00010203",
			"3b1fba963cd8b0b59e8c1a6d71888b7143651af8ba0a7070c0979e2811324aa5",
		},
		{
			128,
			"404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f",
			"My Tagged Application",
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7",
			"1f5b4e6cca02209e0dcb5ca635b89a15e271ecc760071dfd805faa38f9729230",
		},

		// KMAC256
		// - https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/KMAC_samples.pdf
		{
			256,
			"404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f",
			"My Tagged Application",
			"00010203",
			"20c570c31346f703c9ac36c61c03cb64c3970d0cfc787e9b79599d273a68d2f7f69d4cc3de9d104a351689f27cf6f5951f0103f33f4f24871024d9c27773a8dd",
		},
		{
			256,
			"404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f",
			"",
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7",
			"75358cf39e41494e949707927cee0af20a3ff553904c86b08f21cc414bcfd691589d27cf5e15369cbbff8b9a4c2eb17800855d0235ff635da82533ec6b759b69",
		},
		{
			256,
			"404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f",
			"My Tagged Application",
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7",
			"b58618f71f92e1d56c1b8c55ddd7cd188b97b4ca4d99831eb2699a837da2e4d970fbacfde50033aea585f1a2708510c32d07880801bd182898fe476876fc8965",
		},
	}

	for v in test_vectors {
		dst := make([]byte, len(v.output) / 2, context.temp_allocator)

		key, _ := hex.decode(transmute([]byte)(v.key))
		domainsep := transmute([]byte)(v.domainsep)

		ctx: kmac.Context
		switch v.sec_strength {
		case 128:
			kmac.init_128(&ctx, key, domainsep)
		case 256:
			kmac.init_256(&ctx, key, domainsep)
		}

		data, _ := hex.decode(transmute([]byte)(v.msg))
		kmac.update(&ctx, data)
		kmac.final(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		tc.expect(
			t,
			dst_str == v.output,
			fmt.tprintf(
				"KMAC%d: Expected: %s for input of (%s, %s, %s), but got %s instead",
				v.sec_strength,
				v.output,
				v.key,
				v.domainsep,
				v.msg,
				dst_str,
			),
		)
	}
}
