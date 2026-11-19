package test_core_image

import "base:runtime"
import "core:bytes"
import "core:compress"
import "core:image"
import "core:image/bmp"
import "core:image/jpeg"
import pbm "core:image/netpbm"
import "core:image/png"
import "core:image/qoi"
import "core:image/tga"
import "core:io"
import "core:os"
import "core:testing"

Trickle_Reader :: struct {
	data:     []byte,
	position: int,
	chunk:    int,
	seekable: bool,
}

trickle_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Trickle_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if r.position >= len(r.data) {
			return 0, .EOF
		}
		count := min(r.chunk, len(p), len(r.data) - r.position)
		copy(p, r.data[r.position:][:count])
		r.position += count
		return i64(count), nil
	case .Seek:
		if !r.seekable {
			return 0, .Unsupported
		}
		target: i64
		switch whence {
		case .Start:   target = offset
		case .Current: target = i64(r.position) + offset
		case .End:     target = i64(len(r.data)) + offset
		}
		if target < 0 {
			return 0, .Invalid_Offset
		}
		r.position = int(min(target, i64(len(r.data))))
		return target, nil
	case .Size:
		if !r.seekable {
			return 0, .Unsupported
		}
		return i64(len(r.data)), nil
	case .Query:
		if r.seekable {
			return io.query_utility({.Read, .Seek, .Size, .Query})
		}
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

Stream_Kind :: enum {
	Memory,
	Bytes_Reader,
	One_Byte_No_Seek,
	Odd_Chunks_Seekable,
}

stream_test_context :: proc(kind: Stream_Kind, data: ^[]byte, br: ^bytes.Reader, tr: ^Trickle_Reader) -> compress.Context {
	switch kind {
	case .Memory:
		return compress.init_context(data)
	case .Bytes_Reader:
		return compress.init_context(bytes.reader_init(br, data^))
	case .One_Byte_No_Seek:
		tr^ = {data = data^, chunk = 1}
		return compress.init_context(io.Stream{procedure = trickle_proc, data = tr})
	case .Odd_Chunks_Seekable:
		tr^ = {data = data^, chunk = 4097, seekable = true}
		return compress.init_context(io.Stream{procedure = trickle_proc, data = tr})
	}
	return {}
}

Context_Loader :: #type proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error)

png_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	return png.load_from_context(ctx, options, allocator)
}

bmp_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	return bmp.load_from_context(ctx, options, allocator)
}

jpeg_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	return jpeg.load_from_context(ctx, options, allocator)
}

qoi_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	return qoi.load_from_context(ctx, options, allocator)
}

tga_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	return tga.load_from_context(ctx, options, allocator)
}

pbm_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	return pbm.load_from_context(ctx, allocator)
}

expect_stream_loads :: proc(t: ^testing.T, name: string, data: []byte, loader: Context_Loader, options: image.Options, want: ^image.Image, want_err: image.Error, loc := #caller_location) {
	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		img, err := loader(&ctx, options, context.allocator)
		defer image.destroy(img)

		testing.expectf(t, err == want_err, "%v, %v, %v: load returned %v, expected %v", name, kind, options, err, want_err, loc=loc)
		if err != nil || want_err != nil || want == nil {
			continue
		}
		same_dims := img.width == want.width && img.height == want.height && img.channels == want.channels && img.depth == want.depth
		testing.expectf(t, same_dims, "%v, %v, %v: loaded %vx%vx%v@%v, expected %vx%vx%v@%v", name, kind, options, img.width, img.height, img.channels, img.depth, want.width, want.height, want.channels, want.depth, loc=loc)
		testing.expectf(t, bytes.equal(img.pixels[:], want.pixels[:]), "%v, %v, %v: pixels differ", name, kind, options, loc=loc)

		generic_input := data
		generic_br: bytes.Reader
		generic_tr: Trickle_Reader
		generic_ctx := stream_test_context(kind, &generic_input, &generic_br, &generic_tr)
		defer compress.destroy_context(&generic_ctx)

		generic, generic_err := image.load(&generic_ctx, options)
		defer image.destroy(generic)
		testing.expectf(t, generic_err == nil, "%v, %v, %v: image.load returned %v", name, kind, options, generic_err, loc=loc)
		if generic_err == nil {
			testing.expectf(t, bytes.equal(generic.pixels[:], want.pixels[:]), "%v, %v, %v: image.load pixels differ", name, kind, options, loc=loc)
		}
	}
}

expect_stream_loads_file :: proc(t: ^testing.T, name, filename: string, loader: Context_Loader, options: image.Options, want: ^image.Image, want_err: image.Error, loc := #caller_location) {
	data, read_err := os.read_entire_file(filename, context.allocator)
	defer delete(data)
	testing.expectf(t, read_err == nil, "%v: couldn't read %v: %v", name, filename, read_err, loc=loc)
	if read_err == nil {
		expect_stream_loads(t, name, data, loader, options, want, want_err, loc)
	}
}

@test
tga_test_footer :: proc(t: ^testing.T) {
	src := new(image.Image)
	defer image.destroy(src)
	src.width, src.height, src.channels, src.depth = 3, 2, 3, 8
	resize(&src.pixels, 3 * 2 * 3)
	for &p, i in src.pixels {
		p = u8(i * 13)
	}

	saved: [dynamic]byte
	defer delete(saved)
	testing.expect_value(t, tga.save(&saved, src), nil)

	extension_offset := u32le(len(saved))
	extension: image.TGA_Extension
	extension.extension_size = size_of(image.TGA_Extension)
	copy(extension.author_name[:], "Odin")
	extension_bytes := transmute([size_of(image.TGA_Extension)]u8)extension
	append(&saved, ..extension_bytes[:])

	footer := image.TGA_Footer{extension_area_offset = extension_offset}
	copy(footer.signature[:], image.New_TGA_Signature)
	footer_bytes := transmute([size_of(image.TGA_Footer)]u8)footer
	append(&saved, ..footer_bytes[:])

	for kind in Stream_Kind {
		input := saved[:]
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		img, err := tga.load_from_context(&ctx, {.return_metadata})
		defer image.destroy(img)
		testing.expectf(t, err == nil, "%v: load returned %v", kind, err)
		if err != nil {
			continue
		}
		testing.expectf(t, bytes.equal(img.pixels[:], src.pixels[:]), "%v: pixels differ", kind)

		info, ok := img.metadata.(^image.TGA_Info)
		testing.expectf(t, ok, "%v: no TGA metadata", kind)
		if !ok {
			continue
		}
		_, has_footer    := info.footer.?
		ext, has_ext     := info.extension.?
		seekable         := kind != .One_Byte_No_Seek
		testing.expectf(t, has_footer == seekable, "%v: footer present %v, expected %v", kind, has_footer, seekable)
		testing.expectf(t, has_ext == seekable, "%v: extension present %v, expected %v", kind, has_ext, seekable)
		if has_ext {
			testing.expectf(t, string(ext.author_name[:4]) == "Odin", "%v: author is %q", kind, ext.author_name[:4])
		}
	}
}
