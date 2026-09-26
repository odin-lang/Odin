package test_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:testing"
import "core:crypto/kmac"
import "core:crypto/shake"
import "core:crypto/tuplehash"
import "core:crypto/turboshake"
import "core:strings"

@(test)
test_shake :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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

		testing.expectf(
			t,
			dst_str == v.output,
			"SHAKE%d: Expected: %s for input of %s, but got %s instead",
			v.sec_strength,
			v.output,
			v.str,
			dst_str,
		)
	}
}

@(test)
test_cshake :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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

		// cSHAKE128 - bytepad edge case (https://github.com/golang/go/issues/69169)
		//
		// If the implementation incorrectly pads an extra rate-bytes of 0s
		// if the domain separator is exactly rate-bytes long, this will
		// return:
		//
		//  430d3ebae1528304465f3b6f2ed34a7b931af804afe97d0e2a2796abf5725281
		//
		// See: https://github.com/golang/go/issues/69169
		{
			128,
			strings.repeat("x", 168-7, context.temp_allocator),
			"2cf20c4b26c9ee7751eaa273368e616c868e7275178634e1ecdbac80d4cab5f4",
			"",
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

		data, _ := hex.decode(transmute([]byte)(v.str), context.temp_allocator)
		shake.write(&ctx, data)
		shake.read(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		testing.expectf(
			t,
			dst_str == v.output,
			"cSHAKE%d: Expected: %s for input of %s, but got %s instead",
			v.sec_strength,
			v.output,
			v.str,
			dst_str,
		)
	}
}

@(test)
test_tuplehash :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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
			data, _ := hex.decode(transmute([]byte)(e), context.temp_allocator)
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

		testing.expectf(
			t,
			dst_str == v.output,
			"TupleHash%s%d: Expected: %s for input of %v, but got %s instead",
			suffix,
			v.sec_strength,
			v.output,
			v.tuple,
			dst_str,
		)
	}
}

@(test)
test_kmac :: proc(t:^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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

		key, _ := hex.decode(transmute([]byte)(v.key), context.temp_allocator)
		domainsep := transmute([]byte)(v.domainsep)

		ctx: kmac.Context
		switch v.sec_strength {
		case 128:
			kmac.init_128(&ctx, key, domainsep)
		case 256:
			kmac.init_256(&ctx, key, domainsep)
		}

		data, _ := hex.decode(transmute([]byte)(v.msg), context.temp_allocator)
		kmac.update(&ctx, data)
		kmac.final(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		testing.expectf(
			t,
			dst_str == v.output,
			"KMAC%d: Expected: %s for input of (%s, %s, %s), but got %s instead",
			v.sec_strength,
			v.output,
			v.key,
			v.domainsep,
			v.msg,
			dst_str,
		)
	}
}

@(test)
test_turboshake :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Test vectors are based on the repetition of the pattern `00 01 02 ..
   	// F9 FA` with a specific length. ptn(n) defines a string by repeating
   	// the pattern `00 01 02 .. F9 FA` as many times as necessary and
   	// truncated to n bytes,
	ptn :: proc(n: int, allocator := context.temp_allocator) -> []byte {
		p := make([]byte, n, allocator)
		for i in 0..<n {
			p[i] = byte(i % 251) // repeats 00..FA
		}
		return p
	}


	test_vectors := []struct {
		sec_strength: int,
		domainsep:    byte,
		output:       string,
		msg:          []byte,
		out_len:      int,
		last_only:    bool,
	} {
		// TurboSHAKE128
		// - https://datatracker.ietf.org/doc/html/rfc9861#section-5

		// TurboSHAKE128(M=`00`^0, D=`1F`, 32)
		{
			128,
			0x1f,
			"1e415f1c5983aff2169217277d17bb538cd945a397ddec541f1ce41af2c1b74c",
			[]byte{},
			32,
			false,
		},

		// TurboSHAKE128(M=`00`^0, D=`1F`, 64)
		{
			128,
			0x1f,
			"1e415f1c5983aff2169217277d17bb538cd945a397ddec541f1ce41af2c1b74c3e8ccae2a4dae56c84a04c2385c03c15e8193bdf58737363321691c05462c8df",
			[]byte{},
			64,
			false,
		},

		// TurboSHAKE128(M=`00`^0, D=`1F`, 10032), last 32 bytes
		{
			128,
			0x1f,
			"a3b9b0385900ce761f22aed548e754da10a5242d62e8c658e3f3a923a7555607",
			[]byte{},
			10032,
			true,
		},

		// TurboSHAKE128(M=ptn(17**0), D=`1F`, 32)
		{
			128,
			0x1f,
			"55cedd6f60af7bb29a4042ae832ef3f58db7299f893ebb9247247d856958daa9",
			ptn(1),
			32,
			false,
		},

		// TurboSHAKE128(M=ptn(17**1), D=`1F`, 32)
		{
			128,
			0x1f,
			"9c97d036a3bac819db70ede0ca554ec6e4c2a1a4ffbfd9ec269ca6a111161233",
			ptn(17),
			32,
			false,
		},

		// TurboSHAKE128(M=ptn(17**2), D=`1F`, 32)
		{
			128,
			0x1f,
			"96c77c279e0126f7fc07c9b07f5cdae1e0be60bdbe10620040e75d7223a624d2",
			ptn(17 * 17),
			32,
			false,
		},

		// TurboSHAKE128(M=ptn(17**3), D=`1F`, 32)
		{
			128,
			0x1f,
			"d4976eb56bcf118520582b709f73e1d6853e001fdaf80e1b13e0d0599d5fb372",
			ptn(17 * 17 * 17),
			32,
			false,
		},

		// TurboSHAKE128(M=ptn(17**4), D=`1F`, 32)
		{
			128,
			0x1f,
			"da67c7039e98bf530cf7a37830c6664e14cbab7f540f58403b1b82951318ee5c",
			ptn(17 * 17 * 17 * 17),
			32,
			false,
		},

		// TurboSHAKE128(M=ptn(17**5), D=`1F`, 32)
		{
			128,
			0x1f,
			"b97a906fbf83ef7c812517abf3b2d0aea0c4f60318ce11cf103925127f59eecd",
			ptn(17 * 17 * 17 * 17 * 17),
			32,
			false,
		},

		// TurboSHAKE128(M=ptn(17**6), D=`1F`, 32)
		{
			128,
			0x1f,
			"35cd494adeded2f25239af09a7b8ef0c4d1ca4fe2d1ac370fa63216fe7b4c2b1",
			ptn(17 * 17 * 17 * 17 * 17 * 17),
			32,
			false,
		},

		// TurboSHAKE128(M=`FF FF FF`, D=`01`, 32)
		{
			128,
			0x01,
			"bf323f940494e88ee1c540fe660be8a0c93f43d15ec006998462fa994eed5dab",
			[]byte{0xff, 0xff, 0xff},
			32,
			false,
		},

		// TurboSHAKE128(M=`FF`, D=`06`, 32)
		{
			128,
			0x06,
			"8ec9c66465ed0d4a6c35d13506718d687a25cb05c74cca1e42501abd83874a67",
			[]byte{0xff},
			32,
			false,
		},

		// TurboSHAKE128(M=`FF FF FF`, D=`07`, 32)
		{
			128,
			0x07,
			"b658576001cad9b1e5f399a9f77723bba05458042d68206f7252682dba3663ed",
			[]byte{0xff, 0xff, 0xff},
			32,
			false,
		},

		// TurboSHAKE128(M=`FF FF FF FF FF FF FF`, D=`0B`, 32)
		{
			128,
			0x0b,
			"8deeaa1aec47ccee569f659c21dfa8e112db3cee37b18178b2acd805b799cc37",
			[]byte{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff},
			32,
			false,
		},

		// TurboSHAKE128(M=`FF`, D=`30`, 32)
		{
			128,
			0x30,
			"553122e2135e363c3292bed2c6421fa232bab03daa07c7d6636603286506325b",
			[]byte{0xff},
			32,
			false,
		},

		// TurboSHAKE128(M=`FF FF FF`, D=`7F`, 32)
		{
			128,
			0x7f,
			"16274cc656d44cefd422395d0f9053bda6d28e122aba15c765e5ad0e6eaf26f9",
			[]byte{0xff, 0xff, 0xff},
			32,
			false,
		},

		// TurboSHAKE256
		// - https://datatracker.ietf.org/doc/html/rfc9861#section-5

		// TurboSHAKE256(M=`00`^0, D=`1F`, 64)
		{
			256,
			0x1f,
			"367a329dafea871c7802ec67f905ae13c57695dc2c6663c61035f59a18f8e7db11edc0e12e91ea60eb6b32df06dd7f002fbafabb6e13ec1cc20d995547600db0",
			[]byte{},
			64,
			false,
		},

		// TurboSHAKE256(M=`00`^0, D=`1F`, 10032), last 32 bytes
		{
			256,
			0x1f,
			"abefa11630c661269249742685ec082f207265dccf2f43534e9c61ba0c9d1d75",
			[]byte{},
			10032,
			true,
		},

		// TurboSHAKE256(M=ptn(17**0), D=`1F`, 64)
		{
			256,
			0x1f,
			"3e1712f928f8eaf1054632b2aa0a246ed8b0c378728f60bc970410155c28820e90cc90d8a3006aa2372c5c5ea176b0682bf22bae7467ac94f74d43d39b0482e2",
			ptn(1),
			64,
			false,
		},

		// TurboSHAKE256(M=ptn(17**1), D=`1F`, 64)
		{
			256,
			0x1f,
			"b3bab0300e6a191fbe6137939835923578794ea54843f5011090fa2f3780a9e5cb22c59d78b40a0fbff9e672c0fbe0970bd2c845091c6044d687054da5d8e9c7",
			ptn(17),
			64,
			false,
		},

		// TurboSHAKE256(M=ptn(17**2), D=`1F`, 64)
		{
			256,
			0x1f,
			"66b810db8e90780424c0847372fdc95710882fde31c6df75beb9d4cd9305cfcae35e7b83e8b7e6eb4b78605880116316fe2c078a09b94ad7b8213c0a738b65c0",
			ptn(17 * 17),
			64,
			false,
		},

		// TurboSHAKE256(M=ptn(17**3), D=`1F`, 64)
		{
			256,
			0x1f,
			"c74ebc919a5b3b0dd1228185ba02d29ef442d69d3d4276a93efe0bf9a16a7dc0cd4eabadab8cd7a5edd96695f5d360abe09e2c6511a3ec397da3b76b9e1674fb",
			ptn(17 * 17 * 17),
			64,
			false,
		},

		// TurboSHAKE256(M=ptn(17**4), D=`1F`, 64)
		{
			256,
			0x1f,
			"02cc3a8897e6f4f6ccb6fd46631b1f5207b66c6de9c7b55b2d1a23134a170afdac234eaba9a77cff88c1f020b73724618c5687b362c430b248cd38647f848a1d",
			ptn(17 * 17 * 17 * 17),
			64,
			false,
		},

		// TurboSHAKE256(M=ptn(17**5), D=`1F`, 64)
		{
			256,
			0x1f,
			"add53b06543e584b5823f626996aee50fe45ed15f20243a7165485acb4aa76b4ffda75cedf6d8cdc95c332bd56f4b986b58bb17d1778bfc1b1a97545cdf4ec9f",
			ptn(17 * 17 * 17 * 17 * 17),
			64,
			false,
		},

		// TurboSHAKE256(M=ptn(17**6), D=`1F`, 64)
		{
			256,
			0x1f,
			"9e11bc59c24e73993c1484ec66358ef71db74aefd84e123f7800ba9c4853e02cfe701d9e6bb765a304f0dc34a4ee3ba82c410f0da70e86bfbd90ea877c2d6104",
			ptn(17 * 17 * 17 * 17 * 17 * 17),
			64,
			false,
		},

		// TurboSHAKE256(M=`FF FF FF`, D=`01`, 64)
		{
			256,
			0x01,
			"d21c6fbbf587fa2282f29aea620175fb0257413af78a0b1b2a87419ce031d933ae7a4d383327a8a17641a34f8a1d1003ad7da6b72dba84bb62fef28f62f12424",
			[]byte{0xff, 0xff, 0xff},
			64,
			false,
		},

		// TurboSHAKE256(M=`FF`, D=`06`, 64)
		{
			256,
			0x06,
			"738d7b4e37d18b7f22ad1b5313e357e3dd7d07056a26a303c433fa3533455280f4f5a7d4f700efb437fe6d281405e07be32a0a972e22e63adc1b090daefe004b",
			[]byte{0xff},
			64,
			false,
		},

		// TurboSHAKE256(M=`FF FF FF`, D=`07`, 64)
		{
			256,
			0x07,
			"18b3b5b7061c2e67c1753a00e6ad7ed7ba1c906cf93efb7092eaf27fbeebb755ae6e292493c110e48d260028492b8e09b5500612b8f2578985ded5357d00ec67",
			[]byte{0xff, 0xff, 0xff},
			64,
			false,
		},

		// TurboSHAKE256(M=`FF FF FF FF FF FF FF`, D=`0B`, 64)
		{
			256,
			0x0b,
			"bb36764951ec97e9d85f7ee9a67a7718fc005cf42556be79ce12c0bde50e5736d6632b0d0dfb202d1bbb8ffe3dd74cb00834fa756cb03471bab13a1e2c16b3c0",
			[]byte{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff},
			64,
			false,
		},

		// TurboSHAKE256(M=`FF`, D=`30`, 64)
		{
			256,
			0x30,
			"f3fe12873d34bcbb2e608779d6b70e7f86bec7e90bf113cbd4fdd0c4e2f4625e148dd7ee1a52776cf77f240514d9ccfc3b5ddab8ee255e39ee389072962c111a",
			[]byte{0xff},
			64,
			false,
		},

		// TurboSHAKE256(M=`FF FF FF`, D=`7F`, 64)
		{
			256,
			0x7f,
			"abe569c1f77ec340f02705e7d37c9ab7e155516e4a6a150021d70b6fac0bb40c069f9a9828a0d575cd99f9bae435ab1acf7ed9110ba97ce0388d074bac768776",
			[]byte{0xff, 0xff, 0xff},
			64,
			false,
		},
	}

	for v in test_vectors {
		dst := make([]byte, v.out_len, context.temp_allocator)

		ctx: turboshake.Context
		switch v.sec_strength {
		case 128:
			turboshake.init_128(&ctx, v.domainsep)
		case 256:
			turboshake.init_256(&ctx, v.domainsep)
		}

		turboshake.write(&ctx, v.msg)
		turboshake.read(&ctx, dst)

		got := dst
		if v.last_only {
			got = got[len(got)-32:]
		}

		got_str := string(hex.encode(got, context.temp_allocator))

		testing.expectf(
			t,
			got_str == v.output,
			"TurboSHAKE%d: expected %s, got %s",
			v.sec_strength,
			v.output,
			got_str,
		)
	}
}
