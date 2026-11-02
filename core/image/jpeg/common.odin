package jpeg

import "core:compress"
import "core:image"

Image   :: image.Image
Error   :: image.Error
Options :: image.Options

THUMBNAIL_PALETTE_SIZE :: 768
BLOCK_SIZE             :: 8
COEFFICIENT_COUNT      :: BLOCK_SIZE * BLOCK_SIZE
SEGMENT_MAX_SIZE       :: 65533
MAX_COMPONENTS         :: 4

@(private)
HUFFMAN_LOOKAHEAD :: 9

@(private)
Huffman_Table :: struct {
	lookup:       [1 << HUFFMAN_LOOKAHEAD]u16,
	max_code:     [17]i32,
	value_offset: [17]i32,
	symbols:      [256]u8,
	defined:      bool,
}

@(private)
Component :: struct {
	id:            u8,
	h, v:          int,
	quant_index:   u8,
	dc_table:      u8,
	ac_table:      u8,
	width, height: int,
	blocks_w:      int,
	blocks_h:      int,
	stride:        int,
	rows:          int,
	coefficients:  []i16,
	quant:         [COEFFICIENT_COUNT]u16,
	quant_latched: bool,
	dc_pred:       i32,
	plane:         []u8,
	plane_stride:  int,
}

@(private)
Color_Space :: enum {
	Gray,
	YCbCr,
	RGB,
	CMYK,
	YCCK,
}

@(private)
Decoder :: struct {
	ctx:              ^compress.Context,
	bits:             u64,
	count:            u32,
	stopped:          bool,
	huffman:          [2][4]Huffman_Table,
	quant:            [4][COEFFICIENT_COUNT]u16,
	quant_defined:    [4]bool,
	components:       [MAX_COMPONENTS]Component,
	component_count:  int,
	hmax, vmax:       int,
	mcux, mcuy:       int,
	progressive:      bool,
	restart_interval: int,
	eobrun:           int,
	jfif:             bool,
	adobe:            bool,
	adobe_transform:  u8,
	scans:            int,
}

@(private)
zigzag := [COEFFICIENT_COUNT]u8{
	0,   1,  8, 16,  9,  2,  3, 10,
	17, 24, 32, 25, 18, 11,  4,  5,
	12, 19, 26, 33, 40, 48, 41, 34,
	27, 20, 13,  6,  7, 14, 21, 28,
	35, 42, 49, 56, 57, 50, 43, 36,
	29, 22, 15, 23, 30, 37, 44, 51,
	58, 59, 52, 45, 38, 31, 39, 46,
	53, 60, 61, 54, 47, 55, 62, 63,
}
