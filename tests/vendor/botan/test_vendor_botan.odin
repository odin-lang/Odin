package test_vendor_botan

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog: Initial implementation.
        Jeroen van Rijn: Test runner setup.

    Tests for the hashing algorithms within the Botan library.
    Where possible, the official test vectors are used to validate the implementation.
*/

import "core:testing"
import "core:fmt"

import "vendor:botan/md4"
import "vendor:botan/md5"
import "vendor:botan/sha1"
import "vendor:botan/sha2"
import "vendor:botan/sha3"
import "vendor:botan/keccak"
import "vendor:botan/shake"
import "vendor:botan/whirlpool"
import "vendor:botan/ripemd"
import "vendor:botan/blake2b"
import "vendor:botan/tiger"
import "vendor:botan/gost"
import "vendor:botan/streebog"
import "vendor:botan/sm3"
import "vendor:botan/skein512"
import "vendor:botan/siphash"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.println(message)
            return
        }
        fmt.println(" PASS")
    }
    log :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        fmt.printf("log: %v\n", v)
    }
}

main :: proc() {
    t := testing.T{}
    test_md4(&t)
    test_md5(&t)
    test_sha1(&t)
    test_sha224(&t)
    test_sha256(&t)
    test_sha384(&t)
    test_sha512(&t)
    test_sha3_224(&t)
    test_sha3_256(&t)
    test_sha3_384(&t)
    test_sha3_512(&t)
    test_shake_128(&t)
    test_shake_256(&t)
    test_keccak_512(&t)
    test_whirlpool(&t)
    test_gost(&t)
    test_streebog_256(&t)
    test_streebog_512(&t)
    test_blake2b(&t)
    test_ripemd_160(&t)
    test_tiger_128(&t)
    test_tiger_160(&t)
    test_tiger_192(&t)
    test_sm3(&t)
    test_skein512_256(&t)
    test_skein512_512(&t)
    test_siphash_2_4(&t)

    fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
}

TestHash :: struct {
    hash: string,
    str:  string,
}

hex_string :: proc(bytes: []byte, allocator := context.temp_allocator) -> string {
    lut: [16]byte = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'}
    buf := make([]byte, len(bytes) * 2, allocator)
    for i := 0; i < len(bytes); i += 1 {
        buf[i * 2 + 0] = lut[bytes[i] >> 4 & 0xf]
        buf[i * 2 + 1] = lut[bytes[i]      & 0xf]
    }
    return string(buf)
}

@(test)
test_md4 :: proc(t: ^testing.T) {
    // Official test vectors from https://datatracker.ietf.org/doc/html/rfc1320
    test_vectors := [?]TestHash {
        TestHash{"31d6cfe0d16ae931b73c59d7e0c089c0", ""},
        TestHash{"bde52cb31de33e46245e05fbdbd6fb24", "a"},
        TestHash{"a448017aaf21d8525fc10ae87aa6729d", "abc"},
        TestHash{"d9130a8164549fe818874806e1c7014b", "message digest"},
        TestHash{"d79e1c308aa5bbcdeea8ed63df412da9", "abcdefghijklmnopqrstuvwxyz"},
        TestHash{"043f8582f241db351ce627e153e7f0e4", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
        TestHash{"e33b4ddc9c38f2199c3e7b164fcc0536", "12345678901234567890123456789012345678901234567890123456789012345678901234567890"},
    }
    for v, _ in test_vectors {
        computed     := md4.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_md5 :: proc(t: ^testing.T) {
    // Official test vectors from https://datatracker.ietf.org/doc/html/rfc1321
    test_vectors := [?]TestHash {
        TestHash{"d41d8cd98f00b204e9800998ecf8427e", ""},
        TestHash{"0cc175b9c0f1b6a831c399e269772661", "a"},
        TestHash{"900150983cd24fb0d6963f7d28e17f72", "abc"},
        TestHash{"f96b697d7cb7938d525a2f31aaf161d0", "message digest"},
        TestHash{"c3fcd3d76192e4007dfb496cca67e13b", "abcdefghijklmnopqrstuvwxyz"},
        TestHash{"d174ab98d277d9f5a5611c2c9f419d9f", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
        TestHash{"57edf4a22be3c955ac49da2e2107b67a", "12345678901234567890123456789012345678901234567890123456789012345678901234567890"},
    }
    for v, _ in test_vectors {
        computed     := md5.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha1 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"da39a3ee5e6b4b0d3255bfef95601890afd80709", ""},
        TestHash{"a9993e364706816aba3e25717850c26c9cd0d89d", "abc"},
        TestHash{"f9537c23893d2014f365adf8ffe33b8eb0297ed1", "abcdbcdecdefdefgefghfghighijhi"},
        TestHash{"346fb528a24b48f563cb061470bcfd23740427ad", "jkijkljklmklmnlmnomnopnopq"},
        TestHash{"86f7e437faa5a7fce15d1ddcb9eaeaea377667b8", "a"},
        TestHash{"c729c8996ee0a6f74f4f3248e8957edf704fb624", "01234567012345670123456701234567"},
        TestHash{"84983e441c3bd26ebaae4aa1f95129e5e54670f1", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"a49b2446a02c645bf419f995b67091253a04a259", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha1.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha224 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f", ""},
        TestHash{"23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "abc"},
        TestHash{"75388b16512776cc5dba5da1fd890150b0c6455cb4f58b1952522525", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"c97ca9a559850ce97a04a96def6d99a9e0e0e2ab14e6b8df265fc0b3", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha2.hash_224(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha256 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", ""},
        TestHash{"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "abc"},
        TestHash{"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha2.hash_256(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha384 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b", ""},
        TestHash{"cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7", "abc"},
        TestHash{"3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha2.hash_384(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha512 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e", ""},
        TestHash{"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f", "abc"},
        TestHash{"204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha2.hash_512(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha3_224 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7", ""},
        TestHash{"e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf", "abc"},
        TestHash{"10241ac5187380bd501192e4e56b5280908727dd8fe0d10d4e5ad91e", "abcdbcdecdefdefgefghfghighijhi"},
        TestHash{"fd645fe07d814c397e85e85f92fe58b949f55efa4d3468b2468da45a", "jkijkljklmklmnlmnomnopnopq"},
        TestHash{"9e86ff69557ca95f405f081269685b38e3a819b309ee942f482b6a8b", "a"},
        TestHash{"6961f694b2ff3ed6f0c830d2c66da0c5e7ca9445f7c0dca679171112", "01234567012345670123456701234567"},
        TestHash{"8a24108b154ada21c9fd5574494479ba5c7e7ab76ef264ead0fcce33", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"543e6868e1666c1a643630df77367ae5a62a85070a51c14cbf665cbc", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha3.hash_224(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha3_256 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a", ""},
        TestHash{"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532", "abc"},
        TestHash{"565ada1ced21278cfaffdde00dea0107964121ac25e4e978abc59412be74550a", "abcdbcdecdefdefgefghfghighijhi"},
        TestHash{"8cc1709d520f495ce972ece48b0d2e1f74ec80d53bc5c47457142158fae15d98", "jkijkljklmklmnlmnomnopnopq"},
        TestHash{"80084bf2fba02475726feb2cab2d8215eab14bc6bdd8bfb2c8151257032ecd8b", "a"},
        TestHash{"e4786de5f88f7d374b7288f225ea9f2f7654da200bab5d417e1fb52d49202767", "01234567012345670123456701234567"},
        TestHash{"41c0dba2a9d6240849100376a8235e2c82e1b9998a999e21db32dd97496d3376", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"916f6061fe879741ca6469b43971dfdb28b1a32dc36cb3254e812be27aad1d18", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha3.hash_256(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha3_384 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004", ""},
        TestHash{"ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25", "abc"},
        TestHash{"9aa92dbb716ebb573def0d5e3cdd28d6add38ada310b602b8916e690a3257b7144e5ddd3d0dbbc559c48480d34d57a9a", "abcdbcdecdefdefgefghfghighijhi"},
        TestHash{"77c90323d7392bcdee8a3e7f74f19f47b7d1b1a825ac6a2d8d882a72317879cc26597035f1fc24fe65090b125a691282", "jkijkljklmklmnlmnomnopnopq"},
        TestHash{"1815f774f320491b48569efec794d249eeb59aae46d22bf77dafe25c5edc28d7ea44f93ee1234aa88f61c91912a4ccd9", "a"},
        TestHash{"51072590ad4c51b27ff8265590d74f92de7cc55284168e414ca960087c693285b08a283c6b19d77632994cb9eb93f1be", "01234567012345670123456701234567"},
        TestHash{"991c665755eb3a4b6bbdfb75c78a492e8c56a22c5c4d7e429bfdbc32b9d4ad5aa04a1f076e62fea19eef51acd0657c22", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"79407d3b5916b59c3e30b09822974791c313fb9ecc849e406f23592d04f625dc8c709b98b43b3852b337216179aa7fc7", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha3.hash_384(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sha3_512 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26", ""},
        TestHash{"b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0", "abc"},
        TestHash{"9f9a327944a35988d67effc4fa748b3c07744f736ac70b479d8e12a3d10d6884d00a7ef593690305462e9e9030a67c51636fd346fd8fa0ee28a5ac2aee103d2e", "abcdbcdecdefdefgefghfghighijhi"},
        TestHash{"dbb124a0deda966eb4d199d0844fa0beb0770ea1ccddabcd335a7939a931ac6fb4fa6aebc6573f462ced2e4e7178277803be0d24d8bc2864626d9603109b7891", "jkijkljklmklmnlmnomnopnopq"},
        TestHash{"697f2d856172cb8309d6b8b97dac4de344b549d4dee61edfb4962d8698b7fa803f4f93ff24393586e28b5b957ac3d1d369420ce53332712f997bd336d09ab02a", "a"},
        TestHash{"5679e353bc8eeea3e801ca60448b249bcfd3ac4a6c3abe429a807bcbd4c9cd12da87a5a9dc74fde64c0d44718632cae966b078397c6f9ec155c6a238f2347cf1", "01234567012345670123456701234567"},
        TestHash{"04a371e84ecfb5b8b77cb48610fca8182dd457ce6f326a0fd3d7ec2f1e91636dee691fbe0c985302ba1b0d8dc78c086346b533b49c030d99a27daf1139d6e75e", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"afebb2ef542e6579c50cad06d2e578f9f8dd6881d7dc824d26360feebf18a4fa73e3261122948efcfd492e74e82e2189ed0fb440d187f382270cb455f21dd185", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"},
    }
    for v, _ in test_vectors {
        computed     := sha3.hash_512(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_shake_128 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"7f9c2ba4e88f827d616045507605853e", ""},
        TestHash{"f4202e3c5852f9182a0430fd8144f0a7", "The quick brown fox jumps over the lazy dog"},
        TestHash{"853f4538be0db9621a6cea659a06c110", "The quick brown fox jumps over the lazy dof"},
    }
    for v, _ in test_vectors {
        computed     := shake.hash_128(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_shake_256 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762f", ""},
        TestHash{"2f671343d9b2e1604dc9dcf0753e5fe15c7c64a0d283cbbf722d411a0e36f6ca", "The quick brown fox jumps over the lazy dog"},
        TestHash{"46b1ebb2e142c38b9ac9081bef72877fe4723959640fa57119b366ce6899d401", "The quick brown fox jumps over the lazy dof"},
    }
    for v, _ in test_vectors {
        computed     := shake.hash_256(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_keccak_512 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://csrc.nist.gov/csrc/media/projects/cryptographic-standards-and-guidelines/documents/examples/sha_all.pdf
    // https://www.di-mgt.com.au/sha_testvectors.html
    test_vectors := [?]TestHash {
        TestHash{"0eab42de4c3ceb9235fc91acffe746b29c29a8c366b7c60e4e67c466f36a4304c00fa9caf9d87976ba469bcbe06713b435f091ef2769fb160cdab33d3670680e", ""},
        TestHash{"18587dc2ea106b9a1563e32b3312421ca164c7f1f07bc922a9c83d77cea3a1e5d0c69910739025372dc14ac9642629379540c17e2a65b19d77aa511a9d00bb96", "abc"},
    }
    for v, _ in test_vectors {
        computed     := keccak.hash_512(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_whirlpool :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://web.archive.org/web/20171129084214/http://www.larc.usp.br/~pbarreto/WhirlpoolPage.html
    test_vectors := [?]TestHash {
        TestHash{"19fa61d75522a4669b44e39c1d2e1726c530232130d407f89afee0964997f7a73e83be698b288febcf88e3e03c4f0757ea8964e59b63d93708b138cc42a66eb3", ""},
        TestHash{"8aca2602792aec6f11a67206531fb7d7f0dff59413145e6973c45001d0087b42d11bc645413aeff63a42391a39145a591a92200d560195e53b478584fdae231a", "a"},
        TestHash{"33e24e6cbebf168016942df8a7174048f9cebc45cbd829c3b94b401a498acb11c5abcca7f2a1238aaf534371e87a4e4b19758965d5a35a7cad87cf5517043d97", "ab"},
        TestHash{"4e2448a4c6f486bb16b6562c73b4020bf3043e3a731bce721ae1b303d97e6d4c7181eebdb6c57e277d0e34957114cbd6c797fc9d95d8b582d225292076d4eef5", "abc"},
        TestHash{"bda164f0b930c43a1bacb5df880b205d15ac847add35145bf25d991ae74f0b72b1ac794f8aacda5fcb3c47038c954742b1857b5856519de4d1e54bfa2fa4eac5", "abcd"},
        TestHash{"5d745e26ccb20fe655d39c9e7f69455758fbae541cb892b3581e4869244ab35b4fd6078f5d28b1f1a217452a67d9801033d92724a221255a5e377fe9e9e5f0b2", "abcde"},
        TestHash{"a73e425459567308ba5f9eb2ae23570d0d0575eb1357ecf6ac88d4e0358b0ac3ea2371261f5d4c070211784b525911b9eec0ad968429bb7c7891d341cff4e811", "abcdef"},
        TestHash{"08b388f68fd3eb51906ac3d3c699b8e9c3ac65d7ceb49d2e34f8a482cbc3082bc401cead90e85a97b8647c948bf35e448740b79659f3bee42145f0bd653d1f25", "abcdefg"},
        TestHash{"1f1a84d30612820243afe2022712f9dac6d07c4c8bb41b40eacab0184c8d82275da5bcadbb35c7ca1960ff21c90acbae8c14e48d9309e4819027900e882c7ad9", "abcdefgh"},
        TestHash{"11882bc9a31ac1cf1c41dcd9fd6fdd3ccdb9b017fc7f4582680134f314d7bb49af4c71f5a920bc0a6a3c1ff9a00021bf361d9867fe636b0bc1da1552e4237de4", "abcdefghi"},
        TestHash{"717163de24809ffcf7ff6d5aba72b8d67c2129721953c252a4ddfb107614be857cbd76a9d5927de14633d6bdc9ddf335160b919db5c6f12cb2e6549181912eef", "abcdefghij"},
        TestHash{"b97de512e91e3828b40d2b0fdce9ceb3c4a71f9bea8d88e75c4fa854df36725fd2b52eb6544edcacd6f8beddfea403cb55ae31f03ad62a5ef54e42ee82c3fb35", "The quick brown fox jumps over the lazy dog"},
        TestHash{"c27ba124205f72e6847f3e19834f925cc666d0974167af915bb462420ed40cc50900d85a1f923219d832357750492d5c143011a76988344c2635e69d06f2d38c", "The quick brown fox jumps over the lazy eog"},
    }
    for v, _ in test_vectors {
        computed     := whirlpool.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_gost :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"981e5f3ca30c841487830f84fb433e13ac1101569b9c13584ac483234cd656c0", ""},
        TestHash{"e74c52dd282183bf37af0079c9f78055715a103f17e3133ceff1aacf2f403011", "a"},
        TestHash{"b285056dbf18d7392d7677369524dd14747459ed8143997e163b2986f92fd42c", "abc"},
        TestHash{"bc6041dd2aa401ebfa6e9886734174febdb4729aa972d60f549ac39b29721ba0", "message digest"},
        TestHash{"9004294a361a508c586fe53d1f1b02746765e71b765472786e4770d565830a76", "The quick brown fox jumps over the lazy dog"},
        TestHash{"73b70a39497de53a6e08c67b6d4db853540f03e9389299d9b0156ef7e85d0f61", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
        TestHash{"6bc7b38989b28cf93ae8842bf9d752905910a7528a61e5bce0782de43e610c90", "12345678901234567890123456789012345678901234567890123456789012345678901234567890"},
        TestHash{"2cefc2f7b7bdc514e18ea57fa74ff357e7fa17d652c75f69cb1be7893ede48eb", "This is message, length=32 bytes"},
        TestHash{"c3730c5cbccacf915ac292676f21e8bd4ef75331d9405e5f1a61dc3130a65011", "Suppose the original message has length = 50 bytes"},
    }
    for v, _ in test_vectors {
        computed     := gost.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_streebog_256 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"3f539a213e97c802cc229d474c6aa32a825a360b2a933a949fd925208d9ce1bb", ""},
        TestHash{"3e7dea7f2384b6c5a3d0e24aaa29c05e89ddd762145030ec22c71a6db8b2c1f4", "The quick brown fox jumps over the lazy dog"},
        TestHash{"36816a824dcbe7d6171aa58500741f2ea2757ae2e1784ab72c5c3c6c198d71da", "The quick brown fox jumps over the lazy dog."},
    }
    for v, _ in test_vectors {
        computed     := streebog.hash_256(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_streebog_512 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"8e945da209aa869f0455928529bcae4679e9873ab707b55315f56ceb98bef0a7362f715528356ee83cda5f2aac4c6ad2ba3a715c1bcd81cb8e9f90bf4c1c1a8a", ""},
        TestHash{"d2b793a0bb6cb5904828b5b6dcfb443bb8f33efc06ad09368878ae4cdc8245b97e60802469bed1e7c21a64ff0b179a6a1e0bb74d92965450a0adab69162c00fe", "The quick brown fox jumps over the lazy dog"},
        TestHash{"fe0c42f267d921f940faa72bd9fcf84f9f1bd7e9d055e9816e4c2ace1ec83be82d2957cd59b86e123d8f5adee80b3ca08a017599a9fc1a14d940cf87c77df070", "The quick brown fox jumps over the lazy dog."},
    }
    for v, _ in test_vectors {
        computed     := streebog.hash_512(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_blake2b :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce", ""},
        TestHash{"a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918", "The quick brown fox jumps over the lazy dog"},
    }
    for v, _ in test_vectors {
        computed     := blake2b.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_ripemd_160 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://homes.esat.kuleuven.be/~bosselae/ripemd160.html
    test_vectors := [?]TestHash {
        TestHash{"9c1185a5c5e9fc54612808977ee8f548b2258d31", ""},
        TestHash{"0bdc9d2d256b3ee9daae347be6f4dc835a467ffe", "a"},
        TestHash{"8eb208f7e05d987a9b044a8e98c6b087f15a0bfc", "abc"},
        TestHash{"5d0689ef49d2fae572b881b123a85ffa21595f36", "message digest"},
        TestHash{"f71c27109c692c1b56bbdceb5b9d2865b3708dbc", "abcdefghijklmnopqrstuvwxyz"},
        TestHash{"12a053384a9c0c88e405a06c27dcf49ada62eb2b", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"b0e20b6e3116640286ed3a87a5713079b21f5189", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
    }
    for v, _ in test_vectors {
        computed     := ripemd.hash_160(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_tiger_128 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"3293ac630c13f0245f92bbb1766e1616", ""},
        TestHash{"77befbef2e7ef8ab2ec8f93bf587a7fc", "a"},
        TestHash{"2aab1484e8c158f2bfb8c5ff41b57a52", "abc"},
        TestHash{"d981f8cb78201a950dcf3048751e441c", "message digest"},
        TestHash{"1714a472eee57d30040412bfcc55032a", "abcdefghijklmnopqrstuvwxyz"},
        TestHash{"0f7bf9a19b9c58f2b7610df7e84f0ac3", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"8dcea680a17583ee502ba38a3c368651", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
        TestHash{"1c14795529fd9f207a958f84c52f11e8", "12345678901234567890123456789012345678901234567890123456789012345678901234567890"},
        TestHash{"6d12a41e72e644f017b6f0e2f7b44c62", "The quick brown fox jumps over the lazy dog"},
    }
    for v, _ in test_vectors {
        computed     := tiger.hash_128(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_tiger_160 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"3293ac630c13f0245f92bbb1766e16167a4e5849", ""},
        TestHash{"77befbef2e7ef8ab2ec8f93bf587a7fc613e247f", "a"},
        TestHash{"2aab1484e8c158f2bfb8c5ff41b57a525129131c", "abc"},
        TestHash{"d981f8cb78201a950dcf3048751e441c517fca1a", "message digest"},
        TestHash{"1714a472eee57d30040412bfcc55032a0b11602f", "abcdefghijklmnopqrstuvwxyz"},
        TestHash{"0f7bf9a19b9c58f2b7610df7e84f0ac3a71c631e", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"8dcea680a17583ee502ba38a3c368651890ffbcc", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
        TestHash{"1c14795529fd9f207a958f84c52f11e887fa0cab", "12345678901234567890123456789012345678901234567890123456789012345678901234567890"},
        TestHash{"6d12a41e72e644f017b6f0e2f7b44c6285f06dd5", "The quick brown fox jumps over the lazy dog"},
    }
    for v, _ in test_vectors {
        computed     := tiger.hash_160(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_tiger_192 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"3293ac630c13f0245f92bbb1766e16167a4e58492dde73f3", ""},
        TestHash{"77befbef2e7ef8ab2ec8f93bf587a7fc613e247f5f247809", "a"},
        TestHash{"2aab1484e8c158f2bfb8c5ff41b57a525129131c957b5f93", "abc"},
        TestHash{"d981f8cb78201a950dcf3048751e441c517fca1aa55a29f6", "message digest"},
        TestHash{"1714a472eee57d30040412bfcc55032a0b11602ff37beee9", "abcdefghijklmnopqrstuvwxyz"},
        TestHash{"0f7bf9a19b9c58f2b7610df7e84f0ac3a71c631e7b53f78e", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"},
        TestHash{"8dcea680a17583ee502ba38a3c368651890ffbccdc49a8cc", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"},
        TestHash{"1c14795529fd9f207a958f84c52f11e887fa0cabdfd91bfd", "12345678901234567890123456789012345678901234567890123456789012345678901234567890"},
        TestHash{"6d12a41e72e644f017b6f0e2f7b44c6285f06dd5d2c5b075", "The quick brown fox jumps over the lazy dog"},
    }
    for v, _ in test_vectors {
        computed     := tiger.hash_192(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_sm3 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b", ""},
        TestHash{"66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0", "abc"},
        TestHash{"debe9ff92275b8a138604889c18e5a4d6fdb70e5387e5765293dcba39c0c5732", "abcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd"}, 
        TestHash{"5fdfe814b8573ca021983970fc79b2218c9570369b4859684e2e4c3fc76cb8ea", "The quick brown fox jumps over the lazy dog"},
        TestHash{"ca27d14a42fc04c1e5ecf574a95a8c2d70ecb5805e9b429026ccac8f28b20098", "The quick brown fox jumps over the lazy cog"},
    }
    for v, _ in test_vectors {
        computed     := sm3.hash(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_skein512_256 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"39ccc4554a8b31853b9de7a1fe638a24cce6b35a55f2431009e18780335d2621", ""},
        TestHash{"b3250457e05d3060b1a4bbc1428bc75a3f525ca389aeab96cfa34638d96e492a", "The quick brown fox jumps over the lazy dog"},
        TestHash{"41e829d7fca71c7d7154ed8fc8a069f274dd664ae0ed29d365d919f4e575eebb", "The quick brown fox jumps over the lazy dog."},
    }
    for v, _ in test_vectors {
        computed     := skein512.hash_256(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_skein512_512 :: proc(t: ^testing.T) {
    test_vectors := [?]TestHash {
        TestHash{"bc5b4c50925519c290cc634277ae3d6257212395cba733bbad37a4af0fa06af41fca7903d06564fea7a2d3730dbdb80c1f85562dfcc070334ea4d1d9e72cba7a", ""},
        TestHash{"94c2ae036dba8783d0b3f7d6cc111ff810702f5c77707999be7e1c9486ff238a7044de734293147359b4ac7e1d09cd247c351d69826b78dcddd951f0ef912713", "The quick brown fox jumps over the lazy dog"},
        TestHash{"658223cb3d69b5e76e3588ca63feffba0dc2ead38a95d0650564f2a39da8e83fbb42c9d6ad9e03fbfde8a25a880357d457dbd6f74cbcb5e728979577dbce5436", "The quick brown fox jumps over the lazy dog."},
    }
    for v, _ in test_vectors {
        computed     := skein512.hash_512(v.str)
        computed_str := hex_string(computed[:])
        expect(t, computed_str == v.hash, fmt.tprintf("Expected: %s for input of %s, but got %s instead", v.hash, v.str, computed_str))
    }
}

@(test)
test_siphash_2_4 :: proc(t: ^testing.T) {
    // Test vectors from 
    // https://github.com/veorq/SipHash/blob/master/vectors.h
    test_vectors := [?]u64 {
        0x726fdb47dd0e0e31, 0x74f839c593dc67fd, 0x0d6c8009d9a94f5a, 0x85676696d7fb7e2d,
        0xcf2794e0277187b7, 0x18765564cd99a68d, 0xcbc9466e58fee3ce, 0xab0200f58b01d137,
        0x93f5f5799a932462, 0x9e0082df0ba9e4b0, 0x7a5dbbc594ddb9f3, 0xf4b32f46226bada7,
        0x751e8fbc860ee5fb, 0x14ea5627c0843d90, 0xf723ca908e7af2ee, 0xa129ca6149be45e5,
        0x3f2acc7f57c29bdb, 0x699ae9f52cbe4794, 0x4bc1b3f0968dd39c, 0xbb6dc91da77961bd,
        0xbed65cf21aa2ee98, 0xd0f2cbb02e3b67c7, 0x93536795e3a33e88, 0xa80c038ccd5ccec8,
        0xb8ad50c6f649af94, 0xbce192de8a85b8ea, 0x17d835b85bbb15f3, 0x2f2e6163076bcfad,
        0xde4daaaca71dc9a5, 0xa6a2506687956571, 0xad87a3535c49ef28, 0x32d892fad841c342,
        0x7127512f72f27cce, 0xa7f32346f95978e3, 0x12e0b01abb051238, 0x15e034d40fa197ae,
        0x314dffbe0815a3b4, 0x027990f029623981, 0xcadcd4e59ef40c4d, 0x9abfd8766a33735c,
        0x0e3ea96b5304a7d0, 0xad0c42d6fc585992, 0x187306c89bc215a9, 0xd4a60abcf3792b95,
        0xf935451de4f21df2, 0xa9538f0419755787, 0xdb9acddff56ca510, 0xd06c98cd5c0975eb,
        0xe612a3cb9ecba951, 0xc766e62cfcadaf96, 0xee64435a9752fe72, 0xa192d576b245165a,
        0x0a8787bf8ecb74b2, 0x81b3e73d20b49b6f, 0x7fa8220ba3b2ecea, 0x245731c13ca42499,
        0xb78dbfaf3a8d83bd, 0xea1ad565322a1a0b, 0x60e61c23a3795013, 0x6606d7e446282b93,
        0x6ca4ecb15c5f91e1, 0x9f626da15c9625f3, 0xe51b38608ef25f57, 0x958a324ceb064572,
    }

    key: [16]byte
    for i in 0..<16 {
        key[i] = byte(i)
    }

    for i in 0..<len(test_vectors) {
        data := make([]byte, i)
        for j in 0..<i {
            data[j] = byte(j)
        }

        vector   := test_vectors[i]
        computed := siphash.sum_2_4(data[:], key[:])

        expect(t, computed == vector, fmt.tprintf("Expected: 0x%x for input of %v, but got 0x%x instead", vector, data, computed))
    }  
}