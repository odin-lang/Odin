/*
	Copyright 2021-2024 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	A test suite for PNG, TGA, NetPBM, QOI and BMP.
*/
package test_core_image

import "core:testing"

import "core:compress"
import "core:image"
import "core:image/bmp"
import pbm "core:image/netpbm"
import "core:image/png"
import "core:image/qoi"
import "core:image/tga"

import "core:bytes"
import "core:hash"
import "core:strings"
import "core:mem"
import "core:time"

TEST_SUITE_PATH_PNG :: ODIN_ROOT + "tests/core/assets/PNG"
TEST_SUITE_PATH_BMP :: ODIN_ROOT + "tests/core/assets/BMP"

I_Error :: image.Error

Test :: struct {
	file:   string,
	tests:  []struct {
		options:        image.Options,
		expected_error: image.Error,
		dims:           Dims,
		hash:           u32,
	},
}
Default              :: image.Options{}
Alpha_Add            :: image.Options{.alpha_add_if_missing}
Premul_Drop          :: image.Options{.alpha_premultiply, .alpha_drop_if_present}
Just_Drop            :: image.Options{.alpha_drop_if_present}
Blend_BG             :: image.Options{.blend_background}
Blend_BG_Keep        :: image.Options{.blend_background, .alpha_add_if_missing}
Return_Metadata      :: image.Options{.return_metadata}
No_Channel_Expansion :: image.Options{.do_not_expand_channels, .return_metadata}

Dims :: struct {
	width:     int,
	height:    int,
	channels:  int,
	depth:     int,
}

Basic_PNG_Tests := []Test{
	/*
		Basic format tests:
			http://www.schaik.com/pngsuite/pngsuite_bas_png.html
	*/
	{
		"basn0g01", // Black and white.
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_1d8b_1934},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_0da2_8714},
		},
	},
	{
		"basn0g02", // 2 bit (4 level) grayscale
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_cce2_e274},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_2e3f_e285},
		},
	},
	{
		"basn0g04", // 4 bit (16 level) grayscale
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_e6ed_c27d},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_8d0f_641b},
		},
	},
	{
		"basn0g08", // 8 bit (256 level) grayscale
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_7e0a_8ab4},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_c395_683c},
		},
	},
	{
		"basn0g16", // 16 bit (64k level) grayscale
		{
			{Default,     nil, {32, 32, 3, 16}, 0x_d6ae_7df7},
			{Alpha_Add,   nil, {32, 32, 4, 16}, 0x_a9da_b1bf},
		},
	},
	{
		"basn2c08", // 3x8 bits rgb color
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_7855_b9bf},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_2fb5_4036},
		},
	},
	{
		"basn2c16", // 3x16 bits rgb color
		{
			{Default,     nil, {32, 32, 3, 16}, 0x_8ec6_de79},
			{Alpha_Add,   nil, {32, 32, 4, 16}, 0x_0a7e_bae6},
		},
	},
	{
		"basn3p01", // 1 bit (2 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_31ec_284b},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_4d84_31a4},
		},
	},
	{
		"basn3p02", // 2 bit (4 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_279a_463a},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_e4db_b6bc},
		},
	},
	{
		"basn3p04", // 4 bit (16 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_3a9e_038e},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_671f_880f},
		},
	},
	{
		"basn3p08", // 8 bit (256 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_ff6e_2940},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_3952_8682},
		},
	},
	{
		"basn4a08", // 8 bit grayscale + 8 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4,  8}, 0x_905d_5b60},
			{Premul_Drop, nil, {32, 32, 3,  8}, 0x_8c36_b12c},
		},
	},
	{
		"basn4a16", // 16 bit grayscale + 16 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4, 16}, 0x_3000_e35c},
			{Premul_Drop, nil, {32, 32, 3, 16}, 0x_0276_254b},
		},
	},
	{
		"basn6a08", // 3x8 bits rgb color + 8 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4,  8}, 0x_a74d_f32c},
			{Premul_Drop, nil, {32, 32, 3,  8}, 0x_3a5b_8b1c},
		},
	},
	{
		"basn6a16", // 3x16 bits rgb color + 16 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4, 16}, 0x_087b_e531},
			{Premul_Drop, nil, {32, 32, 3, 16}, 0x_de9d_19fd},
		},
	},
}

Interlaced_PNG_Tests  := []Test{
	/*
		Interlaced format tests:
			http://www.schaik.com/pngsuite/pngsuite_int_png.html

		Note that these have the same hash values as the
		non-interlaced versionss above. It would be a failure if
		they didn't, but we need these tests to exercise Adam-7.

	*/

	{
		"basi0g01", // Black and white.
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_1d8b_1934},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_0da2_8714},
		},
	},
	{
		"basi0g02", // 2 bit (4 level) grayscale
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_cce2_e274},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_2e3f_e285},
		},
	},
	{
		"basi0g04", // 4 bit (16 level) grayscale
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_e6ed_c27d},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_8d0f_641b},
		},
	},
	{
		"basi0g08", // 8 bit (256 level) grayscale
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_7e0a_8ab4},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_c395_683c},
		},
	},
	{
		"basi0g16", // 16 bit (64k level) grayscale
		{
			{Default,     nil, {32, 32, 3, 16}, 0x_d6ae_7df7},
			{Alpha_Add,   nil, {32, 32, 4, 16}, 0x_a9da_b1bf},
		},
	},
	{
		"basi2c08", // 3x8 bits rgb color
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_7855_b9bf},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_2fb5_4036},
		},
	},
	{
		"basi2c16", // 3x16 bits rgb color
		{
			{Default,     nil, {32, 32, 3, 16}, 0x_8ec6_de79},
			{Alpha_Add,   nil, {32, 32, 4, 16}, 0x_0a7e_bae6},
		},
	},
	{
		"basi3p01", // 1 bit (2 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_31ec_284b},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_4d84_31a4},
		},
	},
	{
		"basi3p02", // 2 bit (4 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_279a_463a},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_e4db_b6bc},
		},
	},
	{
		"basi3p04", // 4 bit (16 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_3a9e_038e},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_671f_880f},
		},
	},
	{
		"basi3p08", // 8 bit (256 color) paletted
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_ff6e_2940},
			{Alpha_Add,   nil, {32, 32, 4,  8}, 0x_3952_8682},
		},
	},
	{
		"basi4a08", // 8 bit grayscale + 8 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4,  8}, 0x_905d_5b60},
			{Premul_Drop, nil, {32, 32, 3,  8}, 0x_8c36_b12c},
		},
	},
	{
		"basi4a16", // 16 bit grayscale + 16 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4, 16}, 0x_3000_e35c},
			{Premul_Drop, nil, {32, 32, 3, 16}, 0x_0276_254b},
		},
	},
	{
		"basi6a08", // 3x8 bits rgb color + 8 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4,  8}, 0x_a74d_f32c},
			{Premul_Drop, nil, {32, 32, 3,  8}, 0x_3a5b_8b1c},
		},
	},
	{
		"basi6a16", // 3x16 bits rgb color + 16 bit alpha-channel
		{
			{Default,     nil, {32, 32, 4, 16}, 0x_087b_e531},
			{Premul_Drop, nil, {32, 32, 3, 16}, 0x_de9d_19fd},
		},
	},
}

Odd_Sized_PNG_Tests := []Test{
	/*
		"PngSuite", // Odd sizes / PNG-files:
			http://www.schaik.com/pngsuite/pngsuite_siz_png.html

		This tests curious sizes with and without interlacing.
	*/

	{
		"s01i3p01", // 1x1 paletted file, interlaced
		{
			{Default,     nil, { 1,  1, 3,  8}, 0x_d243_369f},
		},
	},
	{
		"s01n3p01", // 1x1 paletted file, no interlacing
		{
			{Default,     nil, { 1,  1, 3,  8}, 0x_d243_369f},
		},
	},
	{
		"s02i3p01", // 2x2 paletted file, interlaced
		{
			{Default,     nil, { 2,  2, 3,  8}, 0x_9e93_1d85},
		},
	},
	{
		"s02n3p01", // 2x2 paletted file, no interlacing
		{
			{Default,     nil, { 2,  2, 3,  8}, 0x_9e93_1d85},
		},
	},
	{
		"s03i3p01", // 3x3 paletted file, interlaced
		{
			{Default,     nil, { 3,  3, 3,  8}, 0x_6916_380e},
		},
	},
	{
		"s03n3p01", // 3x3 paletted file, no interlacing
		{
			{Default,     nil, { 3,  3, 3,  8}, 0x_6916_380e},
		},
	},
	{
		"s04i3p01", // 4x4 paletted file, interlaced
		{
			{Default,     nil, { 4,  4, 3,  8}, 0x_c2e0_d49b},
		},
	},
	{
		"s04n3p01", // 4x4 paletted file, no interlacing
		{
			{Default,     nil, { 4,  4, 3,  8}, 0x_c2e0_d49b},
		},
	},
	{
		"s05i3p02", // 5x5 paletted file, interlaced
		{
			{Default,     nil, { 5,  5, 3,  8}, 0x_1242_b6fb},
		},
	},
	{
		"s05n3p02", // 5x5 paletted file, no interlacing
		{
			{Default,     nil, { 5,  5, 3,  8}, 0x_1242_b6fb},
		},
	},
	{
		"s06i3p02", // 6x6 paletted file, interlaced
		{
			{Default,     nil, { 6,  6, 3,  8}, 0x_d758_9540},
		},
	},
	{
		"s06n3p02", // 6x6 paletted file, no interlacing
		{
			{Default,     nil, { 6,  6, 3,  8}, 0x_d758_9540},
		},
	},
	{
		"s07i3p02", // 7x7 paletted file, interlaced
		{
			{Default,     nil, { 7,  7, 3,  8}, 0x_d2cc_f489},
		},
	},
	{
		"s07n3p02", // 7x7 paletted file, no interlacing
		{
			{Default,     nil, { 7,  7, 3,  8}, 0x_d2cc_f489},
		},
	},
	{
		"s08i3p02", // 8x8 paletted file, interlaced
		{
			{Default,     nil, { 8,  8, 3,  8}, 0x_2ba1_b03e},
		},
	},
	{
		"s08n3p02", // 8x8 paletted file, no interlacing
		{
			{Default,     nil, { 8,  8, 3,  8}, 0x_2ba1_b03e},
		},
	},
	{
		"s09i3p02", // 9x9 paletted file, interlaced
		{
			{Default,     nil, { 9,  9, 3,  8}, 0x_9762_d2ed},
		},
	},
	{
		"s09n3p02", // 9x9 paletted file, no interlacing
		{
			{Default,     nil, { 9,  9, 3,  8}, 0x_9762_d2ed},
		},
	},
	{
		"s32i3p04", // 32x32 paletted file, interlaced
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_ad01_f44d},
		},
	},
	{
		"s32n3p04", // 32x32 paletted file, no interlacing
		{
			{Default,     nil, {32, 32, 3,  8}, 0x_ad01_f44d},
		},
	},
	{
		"s33i3p04", // 33x33 paletted file, interlaced
		{
			{Default,     nil, {33, 33, 3,  8}, 0x_d2f4_ae68},
		},
	},
	{
		"s33n3p04", // 33x33 paletted file, no interlacing
		{
			{Default,     nil, {33, 33, 3,  8}, 0x_d2f4_ae68},
		},
	},
	{
		"s34i3p04", // 34x34 paletted file, interlaced
		{
			{Default,     nil, {34, 34, 3,  8}, 0x_bbed_a3f7},
		},
	},
	{
		"s34n3p04", // 34x34 paletted file, no interlacing
		{
			{Default,     nil, {34, 34, 3,  8}, 0x_bbed_a3f7},
		},
	},
	{
		"s35i3p04", // 35x35 paletted file, interlaced
		{
			{Default,     nil, {35, 35, 3,  8}, 0x_9929_3acf},
		},
	},
	{
		"s35n3p04", // 35x35 paletted file, no interlacing
		{
			{Default,     nil, {35, 35, 3,  8}, 0x_9929_3acf},
		},
	},
	{
		"s36i3p04", // 36x36 paletted file, interlaced
		{
			{Default,     nil, {36, 36, 3,  8}, 0x_f51a_96e0},
		},
	},
	{
		"s36n3p04", // 36x36 paletted file, no interlacing
		{
			{Default,     nil, {36, 36, 3,  8}, 0x_f51a_96e0},
		},
	},
	{
		"s37i3p04", // 37x37 paletted file, interlaced
		{
			{Default,     nil, {37, 37, 3,  8}, 0x_9207_58a4},
		},
	},
	{
		"s37n3p04", // 37x37 paletted file, no interlacing
		{
			{Default,     nil, {37, 37, 3,  8}, 0x_9207_58a4},
		},
	},
	{
		"s38i3p04", // 38x38 paletted file, interlaced
		{
			{Default,     nil, {38, 38, 3,  8}, 0x_eb3b_f324},
		},
	},
	{
		"s38n3p04", // 38x38 paletted file, no interlacing
		{
			{Default,     nil, {38, 38, 3,  8}, 0x_eb3b_f324},
		},
	},
	{
		"s39i3p04", // 39x39 paletted file, interlaced
		{
			{Default,     nil, {39, 39, 3,  8}, 0x_c06d_7da1},
		},
	},
	{
		"s39n3p04", // 39x39 paletted file, no interlacing
		{
			{Default,     nil, {39, 39, 3,  8}, 0x_c06d_7da1},
		},
	},
	{
		"s40i3p04", // 40x40 paletted file, interlaced
		{
			{Default,     nil, {40, 40, 3,  8}, 0x_0d46_58a0},
		},
	},
	{
		"s40n3p04", // 40x40 paletted file, no interlacing
		{
			{Default,     nil, {40, 40, 3,  8}, 0x_0d46_58a0},
		},
	},
}

PNG_bKGD_Tests := []Test{
	/*
"        PngSuite", // Background colors / PNG-files:
			http://www.schaik.com/pngsuite/pngsuite_bck_png.html

		This tests PNGs with and without a bKGD chunk and how we handle
		blending the background.
	*/

	{
		"bgai4a08", // 8 bit grayscale, alpha, no background chunk, interlaced
		{
			{Default,     nil, {32, 32, 4,  8}, 0x_905d_5b60},
			// No background, therefore no background blending and 3 channels.
			{Blend_BG,    nil, {32, 32, 4,  8}, 0x_905d_5b60},
		},
	},
	{
		"bgai4a16", // 16 bit grayscale, alpha, no background chunk, interlaced
		{
			{Default,     nil, {32, 32, 4, 16}, 0x_3000_e35c},
			// No background, therefore no background blending and 3 channels.
			{Blend_BG,    nil, {32, 32, 4, 16}, 0x_3000_e35c},
		},
	},
	{
		"bgan6a08", // 3x8 bits rgb color, alpha, no background chunk
		{
			{Default,     nil, {32, 32, 4,  8}, 0x_a74d_f32c},
			// No background, therefore no background blending and 3 channels.
			{Blend_BG,    nil, {32, 32, 4,  8}, 0x_a74d_f32c},
		},
	},
	{
		"bgan6a16", // 3x16 bits rgb color, alpha, no background chunk
		{
			{Default,     nil, {32, 32, 4, 16}, 0x_087b_e531},
			// No background, therefore no background blending and 3 channels.
			{Blend_BG,    nil, {32, 32, 4, 16}, 0x_087b_e531},
		},
	},
	{
		"bgbn4a08", // 8 bit grayscale, alpha, black background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_905d_5b60},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_8c36_b12c},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_d4a2_3649},
		},
	},
	{
		"bggn4a16", // 16 bit grayscale, alpha, gray background chunk
		{
			{Default,       nil, {32, 32, 4, 16}, 0x_3000_e35c},
			{Blend_BG,      nil, {32, 32, 3, 16}, 0x_0b49_0dc1},
			/*
				Blend with background but keep useless alpha channel.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4, 16}, 0x_073f_eb13},
		},
	},
	{
		"bgwn6a08", // 3x8 bits rgb color, alpha, white background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_a74d_f32c},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_b60d_d910},
			/*
				Blend with background but keep useless alpha channel.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_01ce_2ec6},
		},
	},
	{
		"bgyn6a16", // 3x16 bits rgb color, alpha, yellow background chunk
		{
			{Default,       nil, {32, 32, 4, 16}, 0x_087b_e531},
			{Blend_BG,      nil, {32, 32, 3, 16}, 0x_1a16_7d87},
			/*
				Blend with background but keep useless alpha channel.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4, 16}, 0x_4d73_9955},
		},
	},
}

PNG_tRNS_Tests := []Test{
	/*
		PngSuite - Transparency:
			http://www.schaik.com/pngsuite/pngsuite_trn_png.html

		This tests PNGs with and without a tRNS chunk and how we handle
		keyed transparency.
	*/

	{
		"tbbn0g04", // transparent, black background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_5c8e_af83},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_9b95_ca37},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_5ea6_fd32},
		},
	},
	{
		"tbbn2c16", // transparent, blue background chunk
		{
			{Default,       nil, {32, 32, 4, 16}, 0x_07fe_8090},
			{Blend_BG,      nil, {32, 32, 3, 16}, 0x_5863_8fa2},
			/*
				Blend with background but keep useless alpha channel now set to 65535.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4, 16}, 0x_be56_b8fa},
		},
	},
	{
		"tbbn3p08", // transparent, black background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_8071_0060},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_c821_11f1},
		},
	},
	{
		"tbgn2c16", // transparent, green background chunk
		{
			{Default,       nil, {32, 32, 4, 16}, 0x_07fe_8090},
			{Blend_BG,      nil, {32, 32, 3, 16}, 0x_70da_708a},
			/*
				Blend with background but keep useless alpha channel now set to 65535.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4, 16}, 0x_97b3_a190},
		},
	},
	{
		"tbbn3p08", // transparent, black background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_8071_0060},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_c821_11f1},
		},
	},
	{
		"tbgn3p08", // transparent, light-gray background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_078b_74c4},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_d103_068d},
		},
	},
	{
		"tbrn2c08", // transparent, red background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_0370_ef89},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_6f68_a445},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_2610_a9b7},
		},
	},
	{
		"tbwn0g16", // transparent, white background chunk
		{
			{Default,       nil, {32, 32, 4, 16}, 0x_5386_656a},
			{Blend_BG,      nil, {32, 32, 3, 16}, 0x_6bdd_8c69},
			/*
				Blend with background but keep useless alpha channel now set to 65535.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4, 16}, 0x_1157_5f08},
		},
	},
	{
		"tbwn3p08", // transparent, white background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_4476_4e96},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_dd92_0d33},
		},
	},
	{
		"tbyn3p08", // transparent, yellow background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_18b9_da39},
			/*
				Blend with background but keep useless alpha channel now set to 255.
			*/
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_b1d4_5c1e},
		},
	},
	{
		"tp0n0g08", // not transparent for reference (logo on gray)
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_dfa9_515c},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_dfa9_515c},
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_5796_5874},
		},
	},
	{
		"tp0n2c08", // not transparent for reference (logo on gray)
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_b426_b350},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_b426_b350},
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_679d_24b4},
		},
	},
	{
		"tp0n3p08", // not transparent for reference (logo on gray)
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_1549_3236},
			{Blend_BG,      nil, {32, 32, 3,  8}, 0x_1549_3236},
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_130a_a165},
		},
	},
	{
		"tp1n3p08", // transparent, but no background chunk
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG,      nil, {32, 32, 4,  8}, 0x_9d56_cd67},
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_9d56_cd67},
		},
	},
	{
		"tm3n3p02", // multiple levels of transparency, 3 entries
		{
			{Default,       nil, {32, 32, 4,  8}, 0x_e7da_a7f5},
			{Blend_BG,      nil, {32, 32, 4,  8}, 0x_e7da_a7f5},
			{Blend_BG_Keep, nil, {32, 32, 4,  8}, 0x_e7da_a7f5},
			{Just_Drop,     nil, {32, 32, 3,  8}, 0x_e7f1_a455},
		},
	},
}

PNG_Filter_Tests := []Test{
	/*
		PngSuite - Image filtering:

			http://www.schaik.com/pngsuite/pngsuite_fil_png.html

		This tests PNGs filters.
	*/

	{
		"f00n0g08", // grayscale, no interlacing, filter-type 0
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_3f6b_9bc5},
		},
	},
	{
		"f00n2c08", // color, no interlacing, filter-type 0
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_3f1d_66ad},
		},

	},
	{
		"f01n0g08", // grayscale, no interlacing, filter-type 1
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_0ff8_9d6c},
		},

	},
	{
		"f01n2c08", // color, no interlacing, filter-type 1
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_11c1_b27e},
		},
	},
	{
		"f02n0g08", // grayscale, no interlacing, filter-type 2
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_a86b_4c1d},
		},
	},
	{
		"f02n2c08", // color, no interlacing, filter-type 2
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_7f1c_a785},
		},
	},
	{
		"f03n0g08", // grayscale, no interlacing, filter-type 3
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_66de_99f1},
		},
	},
	{
		"f03n2c08", // color, no interlacing, filter-type 3
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_3164_5d89},
		},
	},
	{
		"f04n0g08", // grayscale, no interlacing, filter-type 4
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_f655_bb7d},
		},
	},
	{
		"f04n2c08", // color, no interlacing, filter-type 4
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_7705_6a6f},
		},
	},
	{
		"f99n0g04", // bit-depth 4, filter changing per scanline
		{
			{Default,       nil, {32, 32, 3,  8}, 0x_d302_6ad9},
		},
	},
}

PNG_Varied_IDAT_Tests := []Test{
	/*
		PngSuite - Chunk ordering:

			http://www.schaik.com/pngsuite/pngsuite_ord_png.html

		This tests IDAT chunks of varying sizes.
	*/

	{
		"oi1n0g16", // grayscale mother image with 1 idat-chunk
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_d6ae_7df7},
		},
	},
	{
		"oi1n2c16", // color mother image with 1 idat-chunk
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
	{
		"oi2n0g16", // grayscale image with 2 idat-chunks
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_d6ae_7df7},
		},
	},
	{
		"oi2n2c16", // color image with 2 idat-chunks
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
	{
		"oi4n0g16", // grayscale image with 4 unequal sized idat-chunks
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_d6ae_7df7},
		},
	},
	{
		"oi4n2c16", // color image with 4 unequal sized idat-chunks
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
	{
		"oi9n0g16", // grayscale image with all idat-chunks length one
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_d6ae_7df7},
		},
	},
	{
		"oi9n2c16", // color image with all idat-chunks length one
		{
			{Default,       nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
}

PNG_ZLIB_Levels_Tests := []Test{
	/*
		PngSuite - Zlib compression:

			http://www.schaik.com/pngsuite/pngsuite_zlb_png.html

		This tests varying levels of ZLIB compression.
	*/

	{
		"z00n2c08", // color, no interlacing, compression level 0 (none)
		{
			{Default,         nil, {32, 32, 3,  8}, 0x_f8f7_d651},
		},
	},
	{
		"z03n2c08", // color, no interlacing, compression level 3
		{
			{Default,         nil, {32, 32, 3,  8}, 0x_f8f7_d651},
		},
	},
	{
		"z06n2c08", // color, no interlacing, compression level 6 (default)
		{
			{Default,         nil, {32, 32, 3,  8}, 0x_f8f7_d651},
		},
	},
	{
		"z09n2c08", // color, no interlacing, compression level 9 (maximum)
		{
			{Default,         nil, {32, 32, 3,  8}, 0x_f8f7_d651},
		},
	},
	{
		"logo-slim", // Odin logo, uses `repl_bytes` repeats at an offset greater than 1.
		{
			{Default,         nil, {500, 260, 4, 8}, 0x_3e75_4e4e},
		},
	},
}

PNG_sPAL_Tests := []Test{
	/*
		PngSuite - Additional palettes:

			http://www.schaik.com/pngsuite/pngsuite_pal_png.html

		This tests handling of sPAL chunks.
	*/

	{
		"pp0n2c16", // six-cube palette-chunk in true-color image
		{
			{Return_Metadata, nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
	{
		"pp0n6a08", // six-cube palette-chunk in true-color+alpha image
		{
			{Return_Metadata, nil, {32, 32, 4,  8}, 0x_0ee0_5c61},
		},
	},
	{
		"ps1n0g08", // six-cube suggested palette (1 byte) in grayscale image
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_7e0a_8ab4},
		},
	},
	{
		"ps1n2c16", // six-cube suggested palette (1 byte) in true-color image
		{
			{Return_Metadata, nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
	{
		"ps2n0g08", // six-cube suggested palette (2 bytes) in grayscale image
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_7e0a_8ab4},
		},
	},
	{
		"ps2n2c16", // six-cube suggested palette (2 bytes) in true-color image
		{
			{Return_Metadata, nil, {32, 32, 3, 16}, 0x_8ec6_de79},
		},
	},
}

PNG_Ancillary_Tests := []Test{
	/*
		PngSuite" - Ancillary chunks:

			http://www.schaik.com/pngsuite/pngsuite_cnk_png.html

		This tests various chunk helpers.
	*/

	{
		"ccwn2c08", // chroma chunk w:0.3127,0.3290 r:0.64,0.33 g:0.30,0.60 b:0.15,0.06
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_61b6_9e8e},
		},
	},
	{
		"ccwn3p08", // chroma chunk w:0.3127,0.3290 r:0.64,0.33 g:0.30,0.60 b:0.15,0.06
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_2e1d_8ef1},
		},
	},
	{
		"cdfn2c08", // physical pixel dimensions, 8x32 flat pixels
		{
			{Return_Metadata, nil, { 8, 32, 3,  8}, 0x_99af_40a3},
		},
	},
	{
		"cdhn2c08", // physical pixel dimensions, 32x8 high pixels
		{
			{Return_Metadata, nil, {32,  8, 3,  8}, 0x_84a4_ef40},
		},
	},
	{
		"cdsn2c08", // physical pixel dimensions, 8x8 square pixels
		{
			{Return_Metadata, nil, { 8,  8, 3,  8}, 0x_82b2_6daf},
		},
	},
	{
		"cdun2c08", // physical pixel dimensions, 1000 pixels per 1 meter
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_ee50_e3ca},
		},
	},
	{
		"ch1n3p04", // histogram 15 colors
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_3a9e_038e},
		},
	},
	{
		"ch2n3p08", // histogram 256 colors
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_ff6e_2940},
		},
	},
	{
		"cm0n0g04", // modification time, 01-jan-2000 12:34:56
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c6bd_1a35},
		},
	},
	{
		"cm7n0g04", // modification time, 01-jan-1970 00:00:00
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c6bd_1a35},
		},
	},
	{
		"cm9n0g04", // modification time, 31-dec-1999 23:59:59
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c6bd_1a35},
		},
	},
	{
		"cs3n2c16", // color, 13 significant bits
		{
			{Return_Metadata, nil, {32, 32, 3, 16}, 0x_7919_bec4},
		},
	},
	{
		"cs3n3p08", // paletted, 3 significant bits
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c472_63e3},
		},
	},
	{
		"cs5n2c08", // color, 5 significant bits
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_1b16_d169},
		},
	},
	{
		"cs5n3p08", // paletted, 5 significant bits
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_1b16_d169},
		},
	},
	{
		"cs8n2c08", // color, 8 significant bits (reference)
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_7306_351c},
		},
	},
	{
		"cs8n3p08", // paletted, 8 significant bits (reference)
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_7306_351c},
		},
	},
	{
		"ct0n0g04", // no textual data
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c6bd_1a35},
		},
	},
	{
		"ct1n0g04", // with textual data
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c6bd_1a35},
		},
	},
	{
		"ctzn0g04", // with compressed textual data
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c6bd_1a35},
		},
	},
	{
		"cten0g04", // international UTF-8, english
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_908f_d2b2},
		},
	},
	{
		"ctfn0g04", // international UTF-8, finnish
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_7f7a_43a7},
		},
	},
	{
		"ctgn0g04", // international UTF-8, greek
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_0ad1_d3d6},
		},
	},
	{
		"cthn0g04", // international UTF-8, hindi
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_c461_c896},
		},
	},
	{
		"ctjn0g04", // international UTF-8, japanese
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_5539_0861},
		},
	},
	{
		"exif2c08", // chunk with jpeg exif data
		{
			{Return_Metadata, nil, {32, 32, 3,  8}, 0x_1a50_22ef},
		},
	},
}


Corrupt_PNG_Tests := []Test{
	/*
		PngSuite - Corrupted files / PNG-files:

			http://www.schaik.com/pngsuite/pngsuite_xxx_png.html

		This test ensures corrupted PNGs are rejected.
	*/

	{
		"xs1n0g01", // signature byte 1 MSBit reset to zero
		{
			{Default, .Invalid_Signature, {}, 0x_0000_0000},
		},
	},
	{
		"xs2n0g01", // signature byte 2 is a 'Q'
		{
			{Default, .Invalid_Signature, {}, 0x_0000_0000},
		},
	},
	{
		"xs4n0g01", // signature byte 4 lowercase
		{
			{Default, .Invalid_Signature, {}, 0x_0000_0000},
		},
	},
	{
		"xs7n0g01", // 7th byte a space instead of control-Z
		{
			{Default, .Invalid_Signature, {}, 0x_0000_0000},
		},
	},
	{
		"xcrn0g04", // added cr bytes
		{
			{Default, .Invalid_Signature, {}, 0x_0000_0000},
		},
	},
	{
		"xlfn0g04", // added lf bytes
		{
			{Default, .Invalid_Signature, {}, 0x_0000_0000},
		},
	},
	{
		"xhdn0g08", // incorrect IHDR checksum
		{
			{Default, compress.General_Error.Checksum_Failed, {}, 0x_0000_0000},
		},
	},
	{
		"xc1n0g08", // color type 1
		{
			{Default, .Unknown_Color_Type, {}, 0x_0000_0000},
		},
	},
	{
		"xc9n2c08", // color type 9
		{
			{Default, .Unknown_Color_Type, {}, 0x_0000_0000},
		},
	},
	{
		"xd0n2c08", // bit-depth 0
		{
			{Default, .Invalid_Color_Bit_Depth_Combo, {}, 0x_0000_0000},
		},
	},
	{
		"xd3n2c08", // bit-depth 3
		{
			{Default, .Invalid_Color_Bit_Depth_Combo, {}, 0x_0000_0000},
		},
	},
	{
		"xd9n2c08", // bit-depth 99
		{
			{Default, .Invalid_Color_Bit_Depth_Combo, {}, 0x_0000_0000},
		},
	},
	{
		"xdtn0g01", // missing IDAT chunk
		{
			{Default, .IDAT_Missing, {}, 0x_0000_0000},
		},
	},
	{
		"xcsn0g01", // incorrect IDAT checksum
		{
			{Default, compress.General_Error.Checksum_Failed, {}, 0x_0000_0000},
		},
	},

}

No_Postprocesing_Tests := []Test{
	/*
		These are some custom tests where we skip expanding to RGB(A).
	*/
	{
		"ps1n0g08", // six-cube suggested palette (1 byte) in grayscale image
		{
			{No_Channel_Expansion, nil, {32, 32, 1,  8}, 0x784b_4a4e},
		},
	},
	{
		"basn0g16", // 16 bit (64k level) grayscale
		{
			{No_Channel_Expansion, nil, {32, 32, 1, 16}, 0x_2ab1_5133},
		},
	},
	{
		"basn3p04", // 4 bit (16 color) paletted
		{
			{No_Channel_Expansion, nil, {32, 32, 1,  8}, 0x_280e_99f1},
		},
	},
}

Text_Title      :: "PngSuite"
Text_Software   :: "Created on a NeXTstation color using \"pnmtopng\"."
Text_Descrption :: "A compilation of a set of images created to test the\nvarious color-types of the PNG format. Included are\nblack&white, color, paletted, with alpha channel, with\ntransparency formats. All bit-depths allowed according\nto the spec are present."

Expected_Text := map[string]map[string]png.Text {
	// .tEXt
	"ct1n0g04" = map[string]png.Text {
		"Title"       = png.Text{
			text=Text_Title,
		},
		"Software"    = png.Text{
			text=Text_Software,
		},
		"Description" = png.Text{
			text=Text_Descrption,
		},
	},
	// .zTXt
	"ctzn0g04" = map[string]png.Text {
		"Title"       = png.Text{
			text=Text_Title,
		},
		"Software"    = png.Text{
			text=Text_Software,
		},
		"Description" = png.Text{
			text=Text_Descrption,
		},
	},
	// .iTXt - international UTF-8, english
	"cten0g04" = map[string]png.Text {
		"Title"       = png.Text{
			keyword_localized="Title",
			language="en",
		},
		"Software"    = png.Text{
			keyword_localized="Software",
			language="en",
		},
		"Description" = png.Text{
			keyword_localized="Description",
			language="en",
		},
	},
	// .iTXt - international UTF-8, finnish
	"ctfn0g04" = map[string]png.Text {
		"Title"       = png.Text{
			keyword_localized = "Otsikko",
			language = "fi",
			text ="PngSuite",
		},
		"Software"    = png.Text{
			keyword_localized = "Ohjelmistot",
			language = "fi",
			text = "Luotu NeXTstation väriä \"pnmtopng\".",
		},
		"Description" = png.Text{
			keyword_localized = "Kuvaus",
			language = "fi",
			text = "kokoelma joukon kuvia luotu testata eri väri-tyyppisiä PNG-muodossa. Mukana on mustavalkoinen, väri, paletted, alpha-kanava, avoimuuden muodossa. Kaikki bit-syvyydessä mukaan sallittua spec on ​​läsnä.",
		},
	},
	// .iTXt - international UTF-8, greek
	"ctgn0g04" = map[string]png.Text {
		"Title"       = png.Text{
			keyword_localized = "Τίτλος",
			language = "el",
			text ="PngSuite",
		},
		"Software"    = png.Text{
			keyword_localized = "Λογισμικό",
			language = "el",
			text = "Δημιουργήθηκε σε ένα χρώμα NeXTstation χρησιμοποιώντας \"pnmtopng\".",
		},
		"Description" = png.Text{
			keyword_localized = "Περιγραφή",
			language = "el",
			text = "Μια συλλογή από ένα σύνολο εικόνων που δημιουργήθηκαν για τη δοκιμή των διαφόρων χρωμάτων-τύπων του μορφή PNG. Περιλαμβάνονται οι ασπρόμαυρες, χρώμα, paletted, με άλφα κανάλι, με μορφές της διαφάνειας. Όλοι λίγο-βάθη επιτρέπεται σύμφωνα με το spec είναι παρόντες.",
		},
	},
	// .iTXt - international UTF-8, hindi
	"cthn0g04" = map[string]png.Text {
		"Title"       = png.Text{
			keyword_localized = "शीर्षक",
			language = "hi",
			text ="PngSuite",
		},
		"Software"    = png.Text{
			keyword_localized = "सॉफ्टवेयर",
			language = "hi",
			text = "एक NeXTstation \"pnmtopng \'का उपयोग कर रंग पर बनाया गया.",
		},
		"Description" = png.Text{
			keyword_localized = "विवरण",
			language = "hi",
			text = "करने के लिए PNG प्रारूप के विभिन्न रंग प्रकार परीक्षण बनाया छवियों का एक सेट का एक संकलन. शामिल काले और सफेद, रंग, पैलेटेड हैं, अल्फा चैनल के साथ पारदर्शिता स्वरूपों के साथ. सभी बिट गहराई कल्पना के अनुसार की अनुमति दी मौजूद हैं.",
		},
	},
	// .iTXt - international UTF-8, japanese
	"ctjn0g04" = map[string]png.Text {
		"Title"       = png.Text{
			keyword_localized = "タイトル",
			language = "ja",
			text ="PngSuite",
		},
		"Software"    = png.Text{
			keyword_localized = "ソフトウェア",
			language = "ja",
			text = "\"pnmtopng\"を使用してNeXTstation色上に作成されます。",
		},
		"Description" = png.Text{
			keyword_localized = "概要",
			language = "ja",
			text = "PNG形式の様々な色の種類をテストするために作成されたイメージのセットのコンパイル。含まれているのは透明度のフォーマットで、アルファチャネルを持つ、白黒、カラー、パレットです。すべてのビット深度が存在している仕様に従ったことができました。",
		},
	},
}

@test
png_test_basic :: proc(t: ^testing.T) {
	run_png_suite(t, Basic_PNG_Tests)
}

@test
png_test_interlaced :: proc(t: ^testing.T) {
	run_png_suite(t, Interlaced_PNG_Tests)
}

@test
png_test_odd_sized :: proc(t: ^testing.T) {
	run_png_suite(t, Odd_Sized_PNG_Tests)
}

@test
png_test_bKGD :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_bKGD_Tests)
}

@test
png_test_tRNS :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_tRNS_Tests)
}

@test
png_test_sPAL :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_sPAL_Tests)
}

@test
png_test_filter :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_Filter_Tests)
}

@test
png_test_varied_idat :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_Varied_IDAT_Tests)
}

@test
png_test_zlib_levels :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_ZLIB_Levels_Tests)
}

@test
png_test_ancillary :: proc(t: ^testing.T) {
	run_png_suite(t, PNG_Ancillary_Tests)
}

@test
png_test_corrupt :: proc(t: ^testing.T) {
	run_png_suite(t, Corrupt_PNG_Tests)
}

@test
png_test_no_postproc :: proc(t: ^testing.T) {
	run_png_suite(t, No_Postprocesing_Tests)
}

run_png_suite :: proc(t: ^testing.T, suite: []Test) {
	for file in suite {
		test_file := strings.concatenate({TEST_SUITE_PATH_PNG, "/", file.file, ".png"}, context.allocator)
		defer delete(test_file)

		img: ^png.Image
		err: png.Error

		count := 0
		for test in file.tests {
			count += 1

			img, err = png.load(test_file, test.options)

			passed := (test.expected_error == nil && err == nil) || (test.expected_error == err)
			testing.expectf(t, passed, "%q failed to load with error %v.", file.file, err)

			if err == nil { // No point in running the other tests if it didn't load.
				pixels := bytes.buffer_to_bytes(&img.pixels)

				// This struct compare fails at -opt:2 if PNG_Dims is not #packed.
				dims      := Dims{img.width, img.height, img.channels, img.depth}
				dims_pass := test.dims == dims
				testing.expectf(t, dims_pass, "%v has %v, expected: %v", file.file, dims, test.dims)
				passed &= dims_pass

				png_hash := hash.crc32(pixels)
				testing.expectf(t, test.hash == png_hash, "%v test %v hash is %08x, expected %08x with %v", file.file, count, png_hash, test.hash, test.options)

				passed &= test.hash == png_hash

				if passed {
					// Roundtrip through QOI to test the QOI encoder and decoder.
					if img.depth == 8 && (img.channels == 3 || img.channels == 4) {
						qoi_buffer: bytes.Buffer
						defer bytes.buffer_destroy(&qoi_buffer)
						qoi_save_err := qoi.save(&qoi_buffer, img)

						testing.expectf(t, qoi_save_err == nil, "%v test %v QOI save failed with %v", file.file, count, qoi_save_err)

						if qoi_save_err == nil {
							qoi_img, qoi_load_err := qoi.load(qoi_buffer.buf[:])
							defer qoi.destroy(qoi_img)

							testing.expectf(t, qoi_load_err == nil, "%v test %v QOI load failed with %v", file.file, count, qoi_load_err)

							qoi_hash := hash.crc32(qoi_img.pixels.buf[:])
							testing.expectf(t, qoi_hash == png_hash, "%v test %v QOI load hash is %08x, expected it match PNG's %08x with %v", file.file, count, qoi_hash, png_hash, test.options)
						}
					}

					// Roundtrip through TGA to test the TGA encoder and decoder.
					if img.depth == 8 && (img.channels == 3 || img.channels == 4) {
						tga_buffer: bytes.Buffer
						defer bytes.buffer_destroy(&tga_buffer)
						tga_save_err := tga.save(&tga_buffer, img)

						testing.expectf(t, tga_save_err == nil, "%v test %v TGA save failed with %v", file.file, count, tga_save_err)
						if tga_save_err == nil {
							tga_img, tga_load_err := tga.load(tga_buffer.buf[:])
							defer tga.destroy(tga_img)

							testing.expectf(t, tga_load_err == nil, "%v test %v TGA load failed with %v", file.file, count, tga_load_err)

							tga_hash := hash.crc32(tga_img.pixels.buf[:])
							testing.expectf(t, tga_hash == png_hash, "%v test %v TGA load hash is %08x, expected it match PNG's %08x with %v", file.file, count, tga_hash, png_hash, test.options)
						}
					}

					{
						// Roundtrip through PBM to test the PBM encoders and decoders - prefer binary
						pbm_buf, pbm_save_err := pbm.save_to_buffer(img)
						defer delete(pbm_buf)

						testing.expectf(t, pbm_save_err == nil, "%v test %v PBM save failed with %v", file.file, count, pbm_save_err)

						if pbm_save_err == nil {
							// Try to load it again.
							pbm_img, pbm_load_err := pbm.load(pbm_buf)
							defer pbm.destroy(pbm_img)

							testing.expectf(t, pbm_load_err == nil, "%v test %v PBM load failed with %v", file.file, count, pbm_load_err)

							if pbm_load_err == nil {
								pbm_hash := hash.crc32(pbm_img.pixels.buf[:])
								testing.expectf(t, pbm_hash == png_hash, "%v test %v PBM load hash is %08x, expected it match PNG's %08x with %v", file.file, count, pbm_hash, png_hash, test.options)
							}
						}
					}

					{
						// Roundtrip through PBM to test the PBM encoders and decoders - prefer ASCII
						pbm_info, _ := pbm.autoselect_pbm_format_from_image(img, false)

						// We already tested the binary formats above.
						if pbm_info.header.format in pbm.ASCII {
							pbm_buf, pbm_save_err := pbm.save_to_buffer(img, pbm_info)
							defer delete(pbm_buf)

							testing.expectf(t, pbm_save_err == nil, "%v test %v PBM save failed with %v", file.file, count, pbm_save_err)

							if pbm_save_err == nil {
								// Try to load it again.
								pbm_img, pbm_load_err := pbm.load(pbm_buf)
								defer pbm.destroy(pbm_img)

								testing.expectf(t, pbm_load_err == nil, "%v test %v PBM load failed with %v", file.file, count, pbm_load_err)

								if pbm_load_err == nil {
									pbm_hash := hash.crc32(pbm_img.pixels.buf[:])
									testing.expectf(t, pbm_hash == png_hash, "%v test %v PBM load hash is %08x, expected it match PNG's %08x with %v", file.file, count, pbm_hash, png_hash, test.options)
								}
							}
						}
					}

					{
						// We still need to test Portable Float Maps
						if (img.channels == 1 || img.channels == 3) && (img.depth == 8 || img.depth == 16) {

							// Make temporary float image
							float_img   := new(image.Image)
							defer png.destroy(float_img)

							float_img.width    = img.width
							float_img.height   = img.height
							float_img.channels = img.channels
							float_img.depth    = 32

							buffer_size := image.compute_buffer_size(img.width, img.height, img.channels, 32)
							resize(&float_img.pixels.buf, buffer_size)

							pbm_info := pbm.Info {
								header = {
									width         = img.width,
									height        = img.height,
									channels      = img.channels,
									depth         = img.depth,
									maxval        = 255 if img.depth == 8 else 65535,
									little_endian = true if ODIN_ENDIAN == .Little else false,
									scale         = 1.0,
									format        = .Pf if img.channels == 1 else .PF,
								},
							}

							// Transform data...
							orig_float := mem.slice_data_cast([]f32, float_img.pixels.buf[:])

							switch img.depth {
							case 8:
								for v, i in img.pixels.buf {
									orig_float[i] = f32(v) / f32(256)
								}
							case 16:
								wide := mem.slice_data_cast([]u16, img.pixels.buf[:])
								for v, i in wide {
									orig_float[i] = f32(v) / f32(65536)
								}
							}

							float_pbm_buf, float_pbm_save_err := pbm.save_to_buffer(float_img, pbm_info)
							defer delete(float_pbm_buf)

							testing.expectf(t, float_pbm_save_err == nil, "%v test %v save as PFM failed with %v", file.file, count, float_pbm_save_err)

							if float_pbm_save_err == nil {
								// Load float image and compare.
								float_pbm_img, float_pbm_load_err := pbm.load(float_pbm_buf)
								defer pbm.destroy(float_pbm_img)

								testing.expectf(t, float_pbm_load_err == nil, "%v test %v PFM load failed with %v", file.file, count, float_pbm_load_err)

								load_float := mem.slice_data_cast([]f32, float_pbm_img.pixels.buf[:])

								testing.expectf(t, len(load_float) == len(orig_float), "%v test %v PFM load returned %v floats, expected %v", file.file, count, len(load_float), len(orig_float))

								// Compare floats
								equal := true
								for orig, i in orig_float {
									if orig != load_float[i] {
										equal = false
										break
									}
								}
								testing.expectf(t, equal, "%v test %v PFM loaded floats to match", file.file, count)
							}
						}
					}
				}

				if .return_metadata in test.options {
					if v, ok := img.metadata.(^image.PNG_Info); ok {
						for c in v.chunks {
							#partial switch(c.header.type) {
							case .gAMA:
								switch(file.file) {
								case "pp0n2c16", "pp0n6a08":
									gamma, gamma_ok := png.gamma(c)
									expected_gamma := f32(1.0)
									testing.expectf(t, gamma == expected_gamma && gamma_ok, "%v test %v gAMA is %v, expected %v", file.file, count, gamma, expected_gamma)
								}
							case .PLTE:
								switch(file.file) {
								case "pp0n2c16", "pp0n6a08":
									plte, plte_ok := png.plte(c)

									expected_plte_len := u16(216)
									testing.expectf(t, expected_plte_len == plte.used && plte_ok, "%v test %v PLTE length is %v, expected %v", file.file, count, plte.used, expected_plte_len)
								}
							case .sPLT:
								switch(file.file) {
								case "ps1n0g08", "ps1n2c16", "ps2n0g08", "ps2n2c16":
									splt, splt_ok := png.splt(c)

									expected_splt_len  := u16(216)
									testing.expectf(t, expected_splt_len == splt.used && splt_ok, "%v test %v sPLT length is %v, expected %v", file.file, count, splt.used, expected_splt_len)

									expected_splt_name := "six-cube"
									testing.expectf(t, expected_splt_name == splt.name && splt_ok, "%v test %v sPLT name is %v, expected %v", file.file, count, splt.name, expected_splt_name)

									png.splt_destroy(splt)
								}
							case .cHRM:
								switch(file.file) {
								case "ccwn2c08", "ccwn3p08":
									chrm, chrm_ok := png.chrm(c)
									expected_chrm := png.cHRM{
										w = png.CIE_1931{x = 0.3127, y = 0.3290},
										r = png.CIE_1931{x = 0.6400, y = 0.3300},
										g = png.CIE_1931{x = 0.3000, y = 0.6000},
										b = png.CIE_1931{x = 0.1500, y = 0.0600},
									}
									testing.expectf(t, expected_chrm == chrm && chrm_ok, "%v test %v cHRM is %v, expected %v", file.file, count, chrm, expected_chrm)
								}
							case .pHYs:
								phys, phys_ok := png.phys(c)
								switch (file.file) {
								case "cdfn2c08":
									expected_phys := png.pHYs{ppu_x =    1, ppu_y =    4, unit = .Unknown}
									testing.expectf(t, expected_phys == phys && phys_ok, "%v test %v cHRM is %v, expected %v", file.file, count, phys, expected_phys)
								case "cdhn2c08":
									expected_phys := png.pHYs{ppu_x =    4, ppu_y =    1, unit = .Unknown}
									testing.expectf(t, expected_phys == phys && phys_ok, "%v test %v cHRM is %v, expected %v", file.file, count, phys, expected_phys)
								case "cdsn2c08":
									expected_phys := png.pHYs{ppu_x =    1, ppu_y =    1, unit = .Unknown}
									testing.expectf(t, expected_phys == phys && phys_ok, "%v test %v cHRM is %v, expected %v", file.file, count, phys, expected_phys)
								case "cdun2c08":
									expected_phys := png.pHYs{ppu_x = 1000, ppu_y = 1000, unit = .Meter}
									testing.expectf(t, expected_phys == phys && phys_ok, "%v test %v cHRM is %v, expected %v", file.file, count, phys, expected_phys)
								}
							case .hIST:
								hist, hist_ok := png.hist(c)
								switch (file.file) {
								case "ch1n3p04":
									testing.expectf(t, hist.used == 15 && hist_ok, "%v test %v hIST has %v entries, expected %v", file.file, count, hist.used, 15)
								case "ch2n3p08":
									testing.expectf(t, hist.used == 256 && hist_ok, "%v test %v hIST has %v entries, expected %v", file.file, count, hist.used, 256)
								}
							case .tIME:
								png_time, png_time_ok := png.time(c)
								expected_time: png.tIME

								core_time, core_time_ok := png.core_time(c)
								expected_core: time.Time

								switch(file.file) {
								case "cm0n0g04": // modification time, 01-jan-2000 12:34:56
									expected_time = png.tIME{year = 2000, month =  1, day =  1, hour = 12, minute = 34, second = 56}
									expected_core = time.Time{_nsec = 946730096000000000}
								case "cm7n0g04": // modification time, 01-jan-1970 00:00:00
									expected_time = png.tIME{year = 1970, month =  1, day =  1, hour =  0, minute =  0, second =  0}
									expected_core = time.Time{_nsec =                  0}
								case "cm9n0g04": // modification time, 31-dec-1999 23:59:59
									expected_time = png.tIME{year = 1999, month = 12, day = 31, hour = 23, minute = 59, second = 59}
									expected_core = time.Time{_nsec = 946684799000000000}

								}
								testing.expectf(t, png_time  == expected_time && png_time_ok,  "%v test %v tIME was %v, expected %v", file.file, count, png_time, expected_time)
								testing.expectf(t, core_time == expected_core && core_time_ok, "%v test %v tIME->core:time is %v, expected %v", file.file, count, core_time, expected_core)
							case .sBIT:
								sbit, sbit_ok  := png.sbit(c)
								expected_sbit: [4]u8

								switch (file.file) {
								case "cs3n2c16": // color, 13 significant bits
									expected_sbit = [4]u8{13, 13, 13,  0}
								case "cs3n3p08": // paletted, 3 significant bits
									expected_sbit = [4]u8{ 3,  3,  3,  0}
								case "cs5n2c08": // color, 5 significant bits
									expected_sbit = [4]u8{ 5,  5,  5,  0}
								case "cs5n3p08": // paletted, 5 significant bits
									expected_sbit = [4]u8{ 5,  5,  5,  0}
								case "cs8n2c08": // color, 8 significant bits (reference)
									expected_sbit = [4]u8{ 8,  8,  8,  0}
								case "cs8n3p08": // paletted, 8 significant bits (reference)
									expected_sbit = [4]u8{ 8,  8,  8,  0}
								case "cdfn2c08", "cdhn2c08", "cdsn2c08", "cdun2c08", "ch1n3p04", "basn3p04":
									expected_sbit = [4]u8{ 4,  4,  4,  0}
								}
								testing.expectf(t, sbit == expected_sbit && sbit_ok, "%v test %v sBIT was %v, expected %v", file.file, count, sbit, expected_sbit)
							case .tEXt, .zTXt:
								text, text_ok := png.text(c)
								defer png.text_destroy(text)

								switch(file.file) {
								case "ct1n0g04": // with textual data
									fallthrough
								case "ctzn0g04": // with compressed textual data
									if file.file in Expected_Text {
										if text.keyword in Expected_Text[file.file] {
											test_text := Expected_Text[file.file][text.keyword].text
											testing.expectf(t, text.text == test_text && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text.text, test_text)
										}
									}
								}
							case .iTXt:
								text, text_ok := png.text(c)
								defer png.text_destroy(text)

								switch(file.file) {
								case "cten0g04": // international UTF-8, english
									if file.file in Expected_Text {
										if text.keyword in Expected_Text[file.file] {
											test := Expected_Text[file.file][text.keyword]
											testing.expectf(t, text.language == test.language && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.keyword_localized == test.keyword_localized && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
										}
									}
								case "ctfn0g04": // international UTF-8, finnish
									if file.file in Expected_Text {
										if text.keyword in Expected_Text[file.file] {
											test := Expected_Text[file.file][text.keyword]
											testing.expectf(t, text.text == test.text && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.language == test.language && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.keyword_localized == test.keyword_localized && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
										}
									}
								case "ctgn0g04": // international UTF-8, greek
									if file.file in Expected_Text {
										if text.keyword in Expected_Text[file.file] {
											test := Expected_Text[file.file][text.keyword]
											testing.expectf(t, text.text == test.text && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.language == test.language && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.keyword_localized == test.keyword_localized && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
										}
									}
								case "cthn0g04": // international UTF-8, hindi
									if file.file in Expected_Text {
										if text.keyword in Expected_Text[file.file] {
											test := Expected_Text[file.file][text.keyword]
											testing.expectf(t, text.text == test.text && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.language == test.language && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.keyword_localized == test.keyword_localized && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
										}
									}
								case "ctjn0g04": // international UTF-8, japanese
									if file.file in Expected_Text {
										if text.keyword in Expected_Text[file.file] {
											test := Expected_Text[file.file][text.keyword]
											testing.expectf(t, text.text == test.text && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.language == test.language && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
											testing.expectf(t, text.keyword_localized == test.keyword_localized && text_ok, "%v test %v text keyword {{%v}}:'%v', expected '%v'", file.file, count, text.keyword, text, test)
										}
									}
								}
							case .eXIf:
								if file.file == "exif2c08" { // chunk with jpeg exif data
									exif, exif_ok := png.exif(c)
									testing.expectf(t, exif.byte_order == .big_endian && exif_ok, "%v test %v eXIf byte order '%v', expected 'big_endian'.", file.file, count, exif.byte_order)
									testing.expectf(t, len(exif.data)  == 978         && exif_ok, "%v test %v eXIf data length '%v', expected '%v'", file.file, len(exif.data), 978)
								}
							}
						}
					}
				}
			}
			png.destroy(img)
		}
	}
	return
}

/*
	Basic format tests:
		https://entropymine.com/jason/bmpsuite/bmpsuite/html/bmpsuite.html - Version 2.8; 2023-11-28

	The BMP Suite image generator itself is GPL, and isn't included, nor did it have its code referenced.
	We do thank the author for the well-researched test suite, which we are free to include:

		"Image files generated by this program are not covered by this license, and are
		in the public domain (except for the embedded ICC profiles)."

	The files with embedded ICC profiles aren't part of Odin's test assets. We don't support BMP metadata.
	We don't support all "possibly correct" images, and thus only ship a subset of these from the BMP Suite.
*/
Basic_BMP_Tests := []Test{
	{
		"pal1", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3ce8_1fae},
		},
	},
	{
		"pal1wb", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3ce8_1fae},
		},
	},
	{
		"pal1bg", {
			{Default,         nil, {127, 64, 3,  8}, 0x_9e91_174a},
		},
	},
	{
		"pal4", {
			{Default,         nil, {127, 64, 3,  8}, 0x_288e_4371},
		},
	},
	{
		"pal4gs", {
			{Default,         nil, {127, 64, 3,  8}, 0x_452d_a01a},
		},
	},
	{
		"pal4rle", {
			{Default,         nil, {127, 64, 3,  8}, 0x_288e_4371},
		},
	},
	{
		"pal8", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8-0", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8gs", {
			{Default,         nil, {127, 64, 3,  8}, 0x_09c2_7834},
		},
	},
	{
		"pal8rle", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8w126", {
			{Default,         nil, {126, 63, 3,  8}, 0x_bb66_4cda},
		},
	},
	{
		"pal8w125", {
			{Default,         nil, {125, 62, 3,  8}, 0x_3ab8_f7c5},
		},
	},
	{
		"pal8w124", {
			{Default,         nil, {124, 61, 3,  8}, 0x_b53e_e6c8},
		},
	},
	{
		"pal8topdown", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8nonsquare", {
			{Default,         nil, {127, 32, 3,  8}, 0x_8409_c689},
		},
	},
	{
		"pal8v4", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8v5", {
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"rgb16", {
			{Default,         nil, {127, 64, 3,  8}, 0x_8b6f_81a2},
		},
	},
	{
		"rgb16bfdef", {
			{Default,         nil, {127, 64, 3,  8}, 0x_8b6f_81a2},
		},
	},
	{
		"rgb16-565", {
			{Default,         nil, {127, 64, 3,  8}, 0x_8c73_a2ff},
		},
	},
	{
		"rgb16-565pal", {
			{Default,         nil, {127, 64, 3,  8}, 0x_8c73_a2ff},
		},
	},
	{
		"rgb24", {
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgb24pal", {
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgb32", {
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgb32bf", {
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgb32bfdef", {
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
}

OS2_Tests := []Test{
	{
		"pal8os2", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2-sz", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2-hs", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2sp", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2v2", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2v2-16", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2v2-sz", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8os2v2-40sz", { // An OS/2-style bitmap. This format can be called OS/2 BMPv1, or Windows BMPv2.
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
}

// BMP files that aren't 100% to spec. Some we support, some we don't.
Questionable_BMP_Tests := []Test{
	{
		"pal1p1", { // Spec says 1-bit image has 2 palette entries. This one has 1.
			{Default,         nil, {127, 64, 3,  8}, 0x_2b54_2560},
		},
	},
	{
		"pal2", { // 2-bit. Allowed on Windows CE. Irfanview doesn't support it.
			{Default,         nil, {127, 64, 3,  8}, 0x_0da2_7594},
		},
	},
	{
		"pal2color", { // 2-bit, with color palette.
			{Default,         nil, {127, 64, 3,  8}, 0x_f0d8_c5d6},
		},
	},
	{
		"pal8offs", { // 300 palette entries (yes, only 256 can be used)
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal8oversizepal", { // Some padding between palette and image data
			{Default,         nil, {127, 64, 3,  8}, 0x_3845_4155},
		},
	},
	{
		"pal4rletrns", { // Using palette tricks to skip pixels
			{Default,         nil, {127, 64, 3,  8}, 0x_eed4_e744},
		},
	},
	{
		"pal4rlecut", { // Using palette tricks to skip pixels
			{Default,         nil, {127, 64, 3,  8}, 0x_473fbc7d},
		},
	},
	{
		"pal8rletrns", { // Using palette tricks to skip pixels
			{Default,         nil, {127, 64, 3,  8}, 0x_fe1f_e560},
		},
	},
	{
		"pal8rlecut", { // Using palette tricks to skip pixels
			{Default,         nil, {127, 64, 3,  8}, 0x_bd04_3619},
		},
	},
	{
		"rgb16faketrns", { // Using palette tricks to skip pixels
			{Default,         nil, {127, 64, 3,  8}, 0x_8b6f_81a2},
		},
	},
	{
		"rgb16-231", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_7393_a163},
		},
	},
	{
		"rgb16-3103", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_3b66_2189},
		},
	},
	{
		"rgba16-4444", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_b785_1f9f},
		},
	},
	{
		"rgba16-5551", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_8b6f_81a2},
		},
	},
	{
		"rgba16-1924", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_f038_2bed},
		},
	},
	{
		"rgb32-xbgr", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgb32fakealpha", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgb32-111110", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_b2c7_a8ff},
		},
	},
	{
		"rgb32-7187", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_b93a_4291},
		},
	},
	{
		"rgba32-1", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_7b67_823d},
		},
	},
	{
		"rgba32-2", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_7b67_823d},
		},
	},
	{
		"rgba32-1010102", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_aa42_0b16},
		},
	},
	{
		"rgba32-81284", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_28a2_4c16},
		},
	},
	{
		"rgba32-61754", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_4aae_26ed},
		},
	},
	{
		"rgba32abf", { // Custom bit fields
			{Default,         nil, {127, 64, 3,  8}, 0x_7b67_823d},
		},
	},
	{
		"rgb32h52", { // Truncated header (RGB bit fields included)
			{Default,         nil, {127, 64, 3,  8}, 0x_025b_ba0a},
		},
	},
	{
		"rgba32h56", { // Truncated header (RGBA bit fields included)
			{Default,         nil, {127, 64, 3,  8}, 0x_7b67_823d},
		},
	},
}

// Unsupported BMP features, or malformed images.
Unsupported_BMP_Tests := []Test{
	{
		"ba-bm", { // An OS/2 Bitmap array. We don't support this BA format.
			{Default, .Unsupported_OS2_File,    {127, 32, 3,  8}, 0x_0000_0000},
		},
	},
	{
		"pal1huffmsb", { // An OS/2 file with Huffman 1D compression
			{Default, .Unsupported_Compression, {127, 32, 3,  8}, 0x_0000_0000},
		},
	},
	{
		"rgb24rle24", { // An OS/2 file with RLE24 compression
			{Default, .Unsupported_Compression, {127, 64, 3,  8}, 0x_0000_0000},
		},
	},
	{
		"rgba64", { // An OS/2 file with RLE24 compression
			{Default, .Unsupported_BPP,         {127, 64, 3,  8}, 0x_0000_0000},
		},
	},
}

// Malformed / malicious files
Known_Bad_BMP_Tests := []Test{
	{
		"badbitcount", {
			{Default, .Unsupported_BPP, {127, 64, 3, 8}, 0x_3ce81fae},
		},
	},
	{
		"badbitssize", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"baddens1", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"baddens2", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"badfilesize", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"badheadersize", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"badpalettesize", {
			{Default, nil, {127, 64, 3, 8}, 0x_3845_4155},
		},
	},
	{
		"badplanes", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"badrle", {
			{Default, nil, {127, 64, 3, 8}, 0x_1457_aae4},
		},
	},
	{
		"badrle4", {
			{Default, nil, {127, 64, 3, 8}, 0x_6764_d2ac},
		},
	},
	{
		"badrle4bis", {
			{Default, nil, {127, 64, 3, 8}, 0x_935d_bb37},
		},
	},
	{
		"badrle4ter", {
			{Default, nil, {127, 64, 3, 8}, 0x_f2ba_5b08},
		},
	},
	{
		"badrlebis", {
			{Default, nil, {127, 64, 3, 8}, 0x_07e2_d730},
		},
	},
	{
		"badrleter", {
			{Default, nil, {127, 64, 3, 8}, 0x_a874_2742},
		},
	},
	{
		"badwidth", {
			{Default, nil, {127, 64, 3, 8}, 0x_3ce8_1fae},
		},
	},
	{
		"pal8badindex", {
			{Default, nil, {127, 64, 3, 8}, 0x_0450_0d02},
		},
	},
	{
		"reallybig", {
			{Default, .Image_Dimensions_Too_Large, {3000000, 2000000, 1, 24}, 0x_0000_0000},
		},
	},
	{
		"rgb16-880", {
			{Default, nil, {127, 64, 3, 8}, 0x_f1c2_0c73},
		},
	},
	{
		"rletopdown", {
			{Default, nil, {127, 64, 3, 8}, 0x_3845_4155},
		},
	},
	{
		"shortfile", {
			{Default, .Short_Buffer, {127, 64, 1, 1}, 0x_0000_0000},
		},
	},
}

@test
bmp_test_basic :: proc(t: ^testing.T) {
	run_bmp_suite(t, Basic_BMP_Tests)
}

@test
bmp_test_os2 :: proc(t: ^testing.T) {
	run_bmp_suite(t, OS2_Tests)
}

@test
bmp_test_questionable :: proc(t: ^testing.T) {
	run_bmp_suite(t, Questionable_BMP_Tests)
}

@test
bmp_test_unsupported :: proc(t: ^testing.T) {
	run_bmp_suite(t, Unsupported_BMP_Tests)
}

@test
bmp_test_known_bad :: proc(t: ^testing.T) {
	run_bmp_suite(t, Known_Bad_BMP_Tests)
}

run_bmp_suite :: proc(t: ^testing.T, suite: []Test) {
	for file in suite {
		test_file := strings.concatenate({TEST_SUITE_PATH_BMP, "/", file.file, ".bmp"}, context.allocator)
		defer delete(test_file)

		for test in file.tests {
			img, err := bmp.load(test_file, test.options)

			passed := (test.expected_error == nil && err == nil) || (test.expected_error == err)
			testing.expectf(t, passed, "%q failed to load with error %v.", file.file, err)

			if err == nil { // No point in running the other tests if it didn't load.
				qoi_file := strings.concatenate({TEST_SUITE_PATH_BMP, "/", file.file, ".qoi"}, context.allocator)
				defer delete(qoi_file)

				qoi.save(qoi_file, img)
				pixels := bytes.buffer_to_bytes(&img.pixels)

				dims   := Dims{img.width, img.height, img.channels, img.depth}
				testing.expectf(t, test.dims == dims, "%v has %v, expected: %v.", file.file, dims, test.dims)

				img_hash := hash.crc32(pixels)
				testing.expectf(t, test.hash == img_hash, "%v test #1's hash is %08x, expected %08x with %v.", file.file, img_hash, test.hash, test.options)
			}
			bmp.destroy(img)
		}
	}
	return
}