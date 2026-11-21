package test_riscv64

import "core:crypto/chacha20"
import chacha_simd128 "core:crypto/_chacha20/simd128"
import chacha_simd256 "core:crypto/_chacha20/simd256"
import "core:hash"
import "core:image"
import "core:image/jpeg"
import "core:math/rand"
import "core:testing"

@(test)
simd_paths_chacha20 :: proc(t: ^testing.T) {
	impls := make([dynamic]chacha20.Implementation, 0, 3, context.temp_allocator)
	append(&impls, chacha20.Implementation.Portable)
	if chacha_simd128.is_performant() {
		append(&impls, chacha20.Implementation.Simd128)
	}
	if chacha_simd256.is_performant() {
		append(&impls, chacha20.Implementation.Simd256)
	}

	plaintext := "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
	key: [chacha20.KEY_SIZE]byte
	for &k, i in key {
		k = u8(i)
	}
	iv := [chacha20.IV_SIZE]byte{7 = 0x4a}
	want := [114]byte{
		0x6e, 0x2e, 0x35, 0x9a, 0x25, 0x68, 0xf9, 0x80, 0x41, 0xba, 0x07, 0x28, 0xdd, 0x0d, 0x69, 0x81,
		0xe9, 0x7e, 0x7a, 0xec, 0x1d, 0x43, 0x60, 0xc2, 0x0a, 0x27, 0xaf, 0xcc, 0xfd, 0x9f, 0xae, 0x0b,
		0xf9, 0x1b, 0x65, 0xc5, 0x52, 0x47, 0x33, 0xab, 0x8f, 0x59, 0x3d, 0xab, 0xcd, 0x62, 0xb3, 0x57,
		0x16, 0x39, 0xd6, 0x24, 0xe6, 0x51, 0x52, 0xab, 0x8f, 0x53, 0x0c, 0x35, 0x9f, 0x08, 0x61, 0xd8,
		0x07, 0xca, 0x0d, 0xbf, 0x50, 0x0d, 0x6a, 0x61, 0x56, 0xa3, 0x8e, 0x08, 0x8a, 0x22, 0xb6, 0x5e,
		0x52, 0xbc, 0x51, 0x4d, 0x16, 0xcc, 0xf8, 0x06, 0x81, 0x8c, 0xe9, 0x1a, 0xb7, 0x79, 0x37, 0x36,
		0x5a, 0xf9, 0x0b, 0xbf, 0x74, 0xa3, 0x5b, 0xe6, 0xb4, 0x0b, 0x8e, 0xed, 0xf2, 0x78, 0x5e, 0x42,
		0x87, 0x4d,
	}
	for impl in impls {
		got: [114]byte
		ctx: chacha20.Context
		chacha20.init(&ctx, key[:], iv[:], impl)
		chacha20.seek(&ctx, 1)
		chacha20.xor_bytes(&ctx, got[:], transmute([]byte)plaintext)
		testing.expectf(t, got == want, "%v: RFC 8439 2.4.2 mismatch", impl)
	}

	rand.reset(0xc4ac4a20)
	src := make([]byte, 64 * 19 + 13, context.temp_allocator)
	ref := make([]byte, len(src), context.temp_allocator)
	got := make([]byte, len(src), context.temp_allocator)
	_ = rand.read(src)
	lengths := [?]int{0, 1, 63, 64, 65, 127, 128, 191, 256, 257, 511, 512, 575, 1024, 1100, len(src)}
	for round in 0..<8 {
		_ = rand.read(key[:])
		xiv: [chacha20.XIV_SIZE]byte
		_ = rand.read(xiv[:])
		ivs := [2][]byte{xiv[:chacha20.IV_SIZE], xiv[:]}
		for nonce in ivs {
			for n in lengths {
				ctx: chacha20.Context
				chacha20.init(&ctx, key[:], nonce, .Portable)
				chacha20.seek(&ctx, u64(round) * 3)
				chacha20.xor_bytes(&ctx, ref[:n], src[:n])
				for impl in impls[1:] {
					chacha20.init(&ctx, key[:], nonce, impl)
					chacha20.seek(&ctx, u64(round) * 3)
					chacha20.xor_bytes(&ctx, got[:n], src[:n])
					testing.expectf(t, string(got[:n]) == string(ref[:n]), "%v: iv %v bytes, %v bytes, round %v differ from Portable", impl, len(nonce), n, round)
				}
			}
		}
	}
}

@(test)
simd_paths_jpeg_save :: proc(t: ^testing.T) {
	Case :: struct {
		depth, channels: int,
		profile:         jpeg.Profile,
		subsampling:     jpeg.Subsampling,
		size:            int,
		crc:             u32,
	}
	cases := [?]Case{
		{8,  1, .Baseline,    .S444,  612, 0x5306b3dd},
		{8,  2, .Baseline,    .S444,  606, 0x2a95a45e},
		{8,  3, .Baseline,    .S444, 1300, 0xb907a777},
		{8,  4, .Baseline,    .S444, 1294, 0x663e14c1},
		{8,  1, .Progressive, .S420,  574, 0xfc20b07b},
		{8,  2, .Progressive, .S420,  561, 0x342bfde7},
		{8,  3, .Progressive, .S420, 1008, 0xd15872a8},
		{8,  4, .Progressive, .S420,  989, 0xb6ba6078},
		{16, 1, .Extended,    .S444,  973, 0x3a3f6c06},
		{16, 2, .Extended,    .S444,  977, 0x0c6775f8},
		{16, 3, .Extended,    .S444, 2474, 0xfc62ee80},
		{16, 4, .Extended,    .S444, 2448, 0xe8316d18},
		{16, 1, .Progressive, .S420, 1087, 0x1c54929c},
		{16, 2, .Progressive, .S420, 1097, 0x71e6875d},
		{16, 3, .Progressive, .S420, 1826, 0x2e4ae968},
		{16, 4, .Progressive, .S420, 1807, 0xf4a1a422},
	}
	for c in cases {
		img := jpeg_pattern(41, 23, c.channels, c.depth)
		defer delete(img.pixels)
		buf: [dynamic]u8
		defer delete(buf)
		err := jpeg.save_to_buffer(&buf, &img, {}, 85, c.subsampling, c.profile)
		testing.expectf(t, err == nil, "%v: %v", c, err)
		testing.expectf(t, len(buf) == c.size && hash.crc32(buf[:]) == c.crc, "%v: got size %v, crc %08x", c, len(buf), hash.crc32(buf[:]))
	}
}

@(private = "file")
jpeg_pattern :: proc(width, height, channels, depth: int) -> (img: image.Image) {
	img = image.Image{width = width, height = height, channels = channels, depth = depth}
	resize(&img.pixels, width * height * channels * depth / 8)
	seed := u32(0x9e3779b9)
	for y in 0..<height {
		for x in 0..<width {
			for c in 0..<channels {
				seed = seed * 1664525 + 1013904223
				v := (x * 7 + y * 3 + c * 50 + int(seed >> 29)) & 255
				i := (y * width + x) * channels + c
				if depth == 8 {
					img.pixels[i] = u8(v)
				} else {
					w := u16(v) << 8 | u16(seed >> 24)
					img.pixels[2 * i] = u8(w)
					img.pixels[2 * i + 1] = u8(w >> 8)
				}
			}
		}
	}
	return
}
