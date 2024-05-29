package test_core_crypto

import "base:runtime"
import "core:bytes"
import "core:encoding/hex"
import "core:strings"
import "core:testing"
import "core:crypto/hash"

@(test)
test_hash :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// TODO:
	// - Stick the test vectors in a JSON file or something.
	data_1_000_000_a := strings.repeat("a", 1_000_000, context.temp_allocator)

	digest: [hash.MAX_DIGEST_SIZE]byte
	test_vectors := []struct{
		algo: hash.Algorithm,
		hash: string,
		str:  string,
	} {
		// BLAKE2b
		{
			hash.Algorithm.BLAKE2B,
			"786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce",
			"",
		},
		{
			hash.Algorithm.BLAKE2B,
			"a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918",
			"The quick brown fox jumps over the lazy dog",
		},

		// BLAKE2s
		{
			hash.Algorithm.BLAKE2S,
			"69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9",
			"",
		},
		{
			hash.Algorithm.BLAKE2S,
			"606beeec743ccbeff6cbcdf5d5302aa855c256c29b88c8ed331ea1a6bf3c8812",
			"The quick brown fox jumps over the lazy dog",
		},

		// SHA-224
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		// - https://datatracker.ietf.org/doc/html/rfc3874#section-3.3
		{
			hash.Algorithm.SHA224,
			"d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f",
			"",
		},
		{
			hash.Algorithm.SHA224,
			"23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7",
			"abc",
		},
		{
			hash.Algorithm.SHA224,
			"75388b16512776cc5dba5da1fd890150b0c6455cb4f58b1952522525",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA224,
			"c97ca9a559850ce97a04a96def6d99a9e0e0e2ab14e6b8df265fc0b3",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},
		{
			hash.Algorithm.SHA224,
			"20794655980c91d8bbb4c1ea97618a4bf03f42581948b2ee4ee7ad67",
			data_1_000_000_a,
		},

		// SHA-256
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA256,
			"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
			"",
		},
		{
			hash.Algorithm.SHA256,
			"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
			"abc",
		},
		{
			hash.Algorithm.SHA256,
			"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA256,
			"cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SHA-384
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA384,
			"38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b",
			"",
		},
		{
			hash.Algorithm.SHA384,
			"cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7",
			"abc",
		},
		{
			hash.Algorithm.SHA384,
			"3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA384,
			"09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SHA-512
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA512,
			"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e",
			"",
		},
		{
			hash.Algorithm.SHA512,
			"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
			"abc",
		},
		{
			hash.Algorithm.SHA512,
			"204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA512,
			"8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},
		// SHA-512/256
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		{
			hash.Algorithm.SHA512_256,
			"53048e2681941ef99b2e29b76b4c7dabe4c2d0c634fc6d46e0e2f13107e7af23",
			"abc",
		},
		{
			hash.Algorithm.SHA512_256,
			"3928e184fb8690f840da3988121d31be65cb9d3ef83ee6146feac861e19b563a",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SHA3-224
		//
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA3_224,
			"6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7",
			"",
		},
		{
			hash.Algorithm.SHA3_224,
			"e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf",
			"abc",
		},
		{
			hash.Algorithm.SHA3_224,
			"10241ac5187380bd501192e4e56b5280908727dd8fe0d10d4e5ad91e",
			"abcdbcdecdefdefgefghfghighijhi",
		},
		{
			hash.Algorithm.SHA3_224,
			"fd645fe07d814c397e85e85f92fe58b949f55efa4d3468b2468da45a",
			"jkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_224,
			"9e86ff69557ca95f405f081269685b38e3a819b309ee942f482b6a8b",
			"a",
		},
		{
			hash.Algorithm.SHA3_224,
			"6961f694b2ff3ed6f0c830d2c66da0c5e7ca9445f7c0dca679171112",
			"01234567012345670123456701234567",
		},
		{
			hash.Algorithm.SHA3_224,
			"8a24108b154ada21c9fd5574494479ba5c7e7ab76ef264ead0fcce33",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_224,
			"543e6868e1666c1a643630df77367ae5a62a85070a51c14cbf665cbc",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SHA3-256
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA3_256,
			"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a",
			"",
		},
		{
			hash.Algorithm.SHA3_256,
			"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
			"abc",
		},
		{
			hash.Algorithm.SHA3_256,
			"565ada1ced21278cfaffdde00dea0107964121ac25e4e978abc59412be74550a",
			"abcdbcdecdefdefgefghfghighijhi",
		},
		{
			hash.Algorithm.SHA3_256,
			"8cc1709d520f495ce972ece48b0d2e1f74ec80d53bc5c47457142158fae15d98",
			"jkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_256,
			"80084bf2fba02475726feb2cab2d8215eab14bc6bdd8bfb2c8151257032ecd8b",
			"a",
		},
		{
			hash.Algorithm.SHA3_256,
			"e4786de5f88f7d374b7288f225ea9f2f7654da200bab5d417e1fb52d49202767",
			"01234567012345670123456701234567",
		},
		{
			hash.Algorithm.SHA3_256,
			"41c0dba2a9d6240849100376a8235e2c82e1b9998a999e21db32dd97496d3376",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_256,
			"916f6061fe879741ca6469b43971dfdb28b1a32dc36cb3254e812be27aad1d18",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SHA3-384
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA3_384,
			"0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004",
			"",
		},
		{
			hash.Algorithm.SHA3_384,
			"ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25",
			"abc",
		},
		{
			hash.Algorithm.SHA3_384,
			"9aa92dbb716ebb573def0d5e3cdd28d6add38ada310b602b8916e690a3257b7144e5ddd3d0dbbc559c48480d34d57a9a",
			"abcdbcdecdefdefgefghfghighijhi",
		},
		{
			hash.Algorithm.SHA3_384,
			"77c90323d7392bcdee8a3e7f74f19f47b7d1b1a825ac6a2d8d882a72317879cc26597035f1fc24fe65090b125a691282",
			"jkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_384,
			"1815f774f320491b48569efec794d249eeb59aae46d22bf77dafe25c5edc28d7ea44f93ee1234aa88f61c91912a4ccd9",
			"a",
		},
		{
			hash.Algorithm.SHA3_384,
			"51072590ad4c51b27ff8265590d74f92de7cc55284168e414ca960087c693285b08a283c6b19d77632994cb9eb93f1be",
			"01234567012345670123456701234567",
		},
		{
			hash.Algorithm.SHA3_384,
			"991c665755eb3a4b6bbdfb75c78a492e8c56a22c5c4d7e429bfdbc32b9d4ad5aa04a1f076e62fea19eef51acd0657c22",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_384,
			"79407d3b5916b59c3e30b09822974791c313fb9ecc849e406f23592d04f625dc8c709b98b43b3852b337216179aa7fc7",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SHA3-512
		// https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.SHA3_512,
			"a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26",
			"",
		},
		{
			hash.Algorithm.SHA3_512,
			"b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0",
			"abc",
		},
		{
			hash.Algorithm.SHA3_512,
			"9f9a327944a35988d67effc4fa748b3c07744f736ac70b479d8e12a3d10d6884d00a7ef593690305462e9e9030a67c51636fd346fd8fa0ee28a5ac2aee103d2e",
			"abcdbcdecdefdefgefghfghighijhi",
		},
		{
			hash.Algorithm.SHA3_512,
			"dbb124a0deda966eb4d199d0844fa0beb0770ea1ccddabcd335a7939a931ac6fb4fa6aebc6573f462ced2e4e7178277803be0d24d8bc2864626d9603109b7891",
			"jkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_512,
			"697f2d856172cb8309d6b8b97dac4de344b549d4dee61edfb4962d8698b7fa803f4f93ff24393586e28b5b957ac3d1d369420ce53332712f997bd336d09ab02a",
			"a",
		},
		{
			hash.Algorithm.SHA3_512,
			"5679e353bc8eeea3e801ca60448b249bcfd3ac4a6c3abe429a807bcbd4c9cd12da87a5a9dc74fde64c0d44718632cae966b078397c6f9ec155c6a238f2347cf1",
			"01234567012345670123456701234567",
		},
		{
			hash.Algorithm.SHA3_512,
			"04a371e84ecfb5b8b77cb48610fca8182dd457ce6f326a0fd3d7ec2f1e91636dee691fbe0c985302ba1b0d8dc78c086346b533b49c030d99a27daf1139d6e75e",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.SHA3_512,
			"afebb2ef542e6579c50cad06d2e578f9f8dd6881d7dc824d26360feebf18a4fa73e3261122948efcfd492e74e82e2189ed0fb440d187f382270cb455f21dd185",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},

		// SM3
		{
			hash.Algorithm.SM3,
			"1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b",
			"",
		},
		{
			hash.Algorithm.SM3,
			"66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0",
			"abc",
		},
		{
			hash.Algorithm.SM3,
			"debe9ff92275b8a138604889c18e5a4d6fdb70e5387e5765293dcba39c0c5732",
			"abcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd",
		},
		{
			hash.Algorithm.SM3,
			"5fdfe814b8573ca021983970fc79b2218c9570369b4859684e2e4c3fc76cb8ea",
			"The quick brown fox jumps over the lazy dog",
		},
		{
			hash.Algorithm.SM3,
			"ca27d14a42fc04c1e5ecf574a95a8c2d70ecb5805e9b429026ccac8f28b20098",
			"The quick brown fox jumps over the lazy cog",
		},

		// Keccak-224 (Legacy)
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.Legacy_KECCAK_224,
			"f71837502ba8e10837bdd8d365adb85591895602fc552b48b7390abd",
			"",
		},
		{
			hash.Algorithm.Legacy_KECCAK_224,
			"c30411768506ebe1c2871b1ee2e87d38df342317300a9b97a95ec6a8",
			"abc",
		},

		// Keccak-256 (Legacy)
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.Legacy_KECCAK_256,
			"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
			"",
		},
		{
			hash.Algorithm.Legacy_KECCAK_256,
			"4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45",
			"abc",
		},

		// Keccak-384 (Legacy)
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.Legacy_KECCAK_384,
			"2c23146a63a29acf99e73b88f8c24eaa7dc60aa771780ccc006afbfa8fe2479b2dd2b21362337441ac12b515911957ff",
			"",
		},
		{
			hash.Algorithm.Legacy_KECCAK_384,
			"f7df1165f033337be098e7d288ad6a2f74409d7a60b49c36642218de161b1f99f8c681e4afaf31a34db29fb763e3c28e",
			"abc",
		},

		// Keccak-512 (Legacy)
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{
			hash.Algorithm.Legacy_KECCAK_512,
			"0eab42de4c3ceb9235fc91acffe746b29c29a8c366b7c60e4e67c466f36a4304c00fa9caf9d87976ba469bcbe06713b435f091ef2769fb160cdab33d3670680e",
			"",
		},
		{
			hash.Algorithm.Legacy_KECCAK_512,
			"18587dc2ea106b9a1563e32b3312421ca164c7f1f07bc922a9c83d77cea3a1e5d0c69910739025372dc14ac9642629379540c17e2a65b19d77aa511a9d00bb96",
			"abc",
		},

		// MD5 (Insecure)
		// - https://datatracker.ietf.org/doc/html/rfc1321
		{hash.Algorithm.Insecure_MD5, "d41d8cd98f00b204e9800998ecf8427e", ""},
		{hash.Algorithm.Insecure_MD5, "0cc175b9c0f1b6a831c399e269772661", "a"},
		{hash.Algorithm.Insecure_MD5, "900150983cd24fb0d6963f7d28e17f72", "abc"},
		{
			hash.Algorithm.Insecure_MD5,
			"f96b697d7cb7938d525a2f31aaf161d0",
			"message digest",
		},
		{
			hash.Algorithm.Insecure_MD5,
			"c3fcd3d76192e4007dfb496cca67e13b",
			"abcdefghijklmnopqrstuvwxyz",
		},
		{
			hash.Algorithm.Insecure_MD5,
			"d174ab98d277d9f5a5611c2c9f419d9f",
			"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
		},
		{
			hash.Algorithm.Insecure_MD5,
			"57edf4a22be3c955ac49da2e2107b67a",
			"12345678901234567890123456789012345678901234567890123456789012345678901234567890",
		},

		// SHA-1 (Insecure)
		// - https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
		// - https://www.di-mgt.com.au/sha_testvectors.html
		{hash.Algorithm.Insecure_SHA1, "da39a3ee5e6b4b0d3255bfef95601890afd80709", ""},
		{hash.Algorithm.Insecure_SHA1, "a9993e364706816aba3e25717850c26c9cd0d89d", "abc"},
		{
			hash.Algorithm.Insecure_SHA1,
			"f9537c23893d2014f365adf8ffe33b8eb0297ed1",
			"abcdbcdecdefdefgefghfghighijhi",
		},
		{
			hash.Algorithm.Insecure_SHA1,
			"346fb528a24b48f563cb061470bcfd23740427ad",
			"jkijkljklmklmnlmnomnopnopq",
		},
		{hash.Algorithm.Insecure_SHA1, "86f7e437faa5a7fce15d1ddcb9eaeaea377667b8", "a"},
		{
			hash.Algorithm.Insecure_SHA1,
			"c729c8996ee0a6f74f4f3248e8957edf704fb624",
			"01234567012345670123456701234567",
		},
		{
			hash.Algorithm.Insecure_SHA1,
			"84983e441c3bd26ebaae4aa1f95129e5e54670f1",
			"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		},
		{
			hash.Algorithm.Insecure_SHA1,
			"a49b2446a02c645bf419f995b67091253a04a259",
			"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
		},
	}
	for v, _ in test_vectors {
		algo_name := hash.ALGORITHM_NAMES[v.algo]
		dst := digest[:hash.DIGEST_SIZES[v.algo]]

		data := transmute([]byte)(v.str)

		ctx: hash.Context
		hash.init(&ctx, v.algo)
		hash.update(&ctx, data)
		hash.final(&ctx, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		testing.expectf(
			t,
			dst_str == v.hash,
			"%s/incremental: Expected: %s for input of %s, but got %s instead",
			algo_name,
			v.hash,
			v.str,
			dst_str,
		)
	}

	for algo in hash.Algorithm {
		// Skip the sentinel value.
		if algo == .Invalid {
			continue
		}

		algo_name := hash.ALGORITHM_NAMES[algo]

		// Ensure that the MAX_(DIGEST_SIZE, BLOCK_SIZE) constants are
		// still correct.
		digest_sz := hash.DIGEST_SIZES[algo]
		block_sz := hash.BLOCK_SIZES[algo]
		testing.expectf(
			t,
			digest_sz <= hash.MAX_DIGEST_SIZE,
			"%s: Digest size %d exceeds max %d",
			algo_name,
			digest_sz,
			hash.MAX_DIGEST_SIZE,
		)
		testing.expectf(
			t,
			block_sz <= hash.MAX_BLOCK_SIZE,
			"%s: Block size %d exceeds max %d",
			algo_name,
			block_sz,
			hash.MAX_BLOCK_SIZE,
		)

		// Exercise most of the happy-path for the high level interface.
		rd: bytes.Reader
		bytes.reader_init(&rd, transmute([]byte)(data_1_000_000_a))
		st := bytes.reader_to_stream(&rd)

		digest_a, _ := hash.hash_stream(algo, st, context.temp_allocator)
		digest_b := hash.hash_string(algo, data_1_000_000_a, context.temp_allocator)

		a_str := string(hex.encode(digest_a, context.temp_allocator))
		b_str := string(hex.encode(digest_b, context.temp_allocator))

		testing.expectf(
			t,
			a_str == b_str,
			"%s/cmp: Expected: %s (hash_stream) == %s (hash_bytes)",
			algo_name,
			a_str,
			b_str,
		)

		// Exercise the rolling digest functionality, which also covers
		// each implementation's clone routine.
		ctx, ctx_clone: hash.Context
		hash.init(&ctx, algo)

		api_algo := hash.algorithm(&ctx)
		api_digest_size := hash.digest_size(&ctx)
		testing.expectf(
			t,
			algo == api_algo,
			"%s/algorithm: Expected: %v but got %v instead",
			algo_name,
			algo,
			api_algo,
		)
		testing.expectf(
			t,
			hash.DIGEST_SIZES[algo] == api_digest_size,
			"%s/digest_size: Expected: %d but got %d instead",
			algo_name,
			hash.DIGEST_SIZES[algo],
			api_digest_size,
		)

		hash.update(&ctx, digest_a)
		hash.clone(&ctx_clone, &ctx)
		hash.final(&ctx, digest_a, true)
		hash.final(&ctx, digest_b)

		digest_c := make([]byte, hash.digest_size(&ctx_clone), context.temp_allocator)
		hash.final(&ctx_clone, digest_c)

		a_str = string(hex.encode(digest_a, context.temp_allocator))
		b_str = string(hex.encode(digest_b, context.temp_allocator))
		c_str := string(hex.encode(digest_c, context.temp_allocator))

		testing.expectf(
			t,
			a_str == b_str && b_str == c_str,
			"%s/rolling: Expected: %s (first) == %s (second) == %s (third)",
			algo_name,
			a_str,
			b_str,
			c_str,
		)
	}
}