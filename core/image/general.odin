package image

import "core:mem"
import "core:bytes"

Loader_Proc :: #type proc(data: []byte, options: Options, allocator: mem.Allocator) -> (img: ^Image, err: Error)
Destroy_Proc :: #type proc(img: ^Image)

@(private)
_internal_loaders: [Which_File_Type]Loader_Proc
_internal_destroyers: [Which_File_Type]Destroy_Proc

register :: proc(kind: Which_File_Type, loader: Loader_Proc, destroyer: Destroy_Proc) {
	assert(loader != nil)
	assert(destroyer != nil)
	assert(_internal_loaders[kind] == nil)
	_internal_loaders[kind] = loader

	assert(_internal_destroyers[kind] == nil)
	_internal_destroyers[kind] = destroyer
}

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	loader := _internal_loaders[which(data)]
	if loader == nil {

		// Check if there is at least one loader, otherwise panic to let the user know about misuse.
		for a_loader in _internal_loaders {
			if a_loader != nil {
				return nil, .Unsupported_Format
			}
		}

		panic("image.load called when no image loaders are registered. Register a loader by first importing a subpackage (eg: `import \"core:image/png\"`), or with image.register")
	}
	return loader(data, options, allocator)
}


destroy :: proc(img: ^Image, allocator := context.allocator) {
	if img == nil {
		return
	}
	context.allocator = allocator
	destroyer := _internal_destroyers[img.which]
	if destroyer != nil {
		destroyer(img)
	} else {
		assert(img.metadata == nil)
		bytes.buffer_destroy(&img.pixels)
		free(img)
	}
}

Which_File_Type :: enum {
	Unknown,

	BMP,
	DjVu, // AT&T DjVu file format
	EXR,
	FLIF,
	GIF,
	HDR, // Radiance RGBE HDR
	ICNS, // Apple Icon Image
	JPEG,
	JPEG_2000,
	JPEG_XL,
	NetPBM, // NetPBM family
	PIC, // Softimage PIC
	PNG, // Portable Network Graphics
	PSD, // Photoshop PSD
	QOI, // Quite Okay Image
	SGI_RGB, // Silicon Graphics Image RGB file format
	Sun_Rast, // Sun Raster Graphic
	TGA, // Targa Truevision
	TIFF, // Tagged Image File Format
	WebP,
	XBM, // X BitMap
}

which_bytes :: proc(data: []byte) -> Which_File_Type {
	test_tga :: proc(s: string) -> bool {
		get8 :: #force_inline proc(s: ^string) -> u8 {
			v := s[0]
			s^ = s[1:]
			return v
		}
		get16le :: #force_inline  proc(s: ^string) -> u16 {
			v := u16(s[0]) | u16(s[1])<<16
			s^ = s[2:]
			return v
		}
		s := s
		s = s[1:] // skip offset

		color_type := get8(&s)
		if color_type > 1 {
			return false
		}
		image_type := get8(&s) // image type
		if color_type == 1 { // Colormap (Paletted) Image
			if image_type != 1 && image_type != 9 { // color type requires 1 or 9
				return false
			}
			s = s[4:] // skip index of first colormap
			bpcme := get8(&s) // check bits per colormap entry
			if bpcme != 8 && bpcme != 15 && bpcme != 16 && bpcme != 24 && bpcme != 32 {
				return false
			}
			s = s[4:] // skip image origin (x, y)
		} else { // Normal image without colormap
			if image_type != 2 && image_type != 3 && image_type != 10 && image_type != 11 {
				return false
			}
			s = s[9:] // skip colormap specification
		}
		if get16le(&s) < 1 || get16le(&s) < 1 { // test width and height
			return false
		}
		bpp := get8(&s) // bits per pixel
		if color_type == 1 && bpp != 8 && bpp != 16 {
			return false
		}
		if bpp != 8 && bpp != 15 && bpp != 16 && bpp != 24 && bpp != 32 {
			return false
		}
		return true
	}

	header: [128]byte
	copy(header[:], data)
	s := string(header[:])

	switch {
	case s[:2] == "BM":
		return .BMP
	case s[:8] == "AT&TFORM":
		switch s[12:16] {
		case "DJVU", "DJVM":
			return .DjVu
		}
	case s[:4] == "\x76\x2f\x31\x01":
		return .EXR
	case s[:6] == "GIF87a", s[:6] == "GIF89a":
		return .GIF
	case s[6:10] == "JFIF", s[6:10] == "Exif":
		return .JPEG
	case s[:3] == "\xff\xd8\xff":
		switch s[3] {
		case 0xdb, 0xee, 0xe1, 0xe0:
			return .JPEG
		}
		switch {
		case s[:12] == "\xff\xd8\xff\xe0\x00\x10\x4a\x46\x49\x46\x00\x01":
			return .JPEG
		}
	case s[:4] == "\xff\x4f\xff\x51", s[:12] == "\x00\x00\x00\x0c\x6a\x50\x20\x20\x0d\x0a\x87\x0a":
		return .JPEG_2000
	case s[:12] == "\x00\x00\x00\x0c\x4a\x58\x4c\x20\x0d\x0a\x87\x0a":
		return .JPEG_XL
	case s[0] == 'P':
		switch s[2] {
		case '\t', '\n', '\r':
			switch s[1] {
			case '1', '4': // PBM
				return .NetPBM
			case '2', '5': // PGM
				return .NetPBM
			case '3', '6': // PPM
				return .NetPBM
			case '7':      // PAM
				return .NetPBM
			case 'F', 'f': // PFM
				return .NetPBM
			}
		}
	case s[:8] == "\x89PNG\r\n\x1a\n":
		return .PNG
	case s[:4] == "qoif":
		return .QOI
	case s[:2] == "\x01\xda":
		return .SGI_RGB
	case s[:4] == "\x59\xA6\x6A\x95":
		return .Sun_Rast
	case s[:4] == "MM\x2a\x00", s[:4] == "II\x00\x2A":
		return .TIFF
	case s[:4] == "RIFF" && s[8:12] == "WEBP":
		return .WebP
	case s[:8] == "#define ":
		return .XBM

	case s[:11] == "#?RADIANCE\n", s[:7] == "#?RGBE\n":
		return .HDR
	case s[:4] == "\x38\x42\x50\x53":
		return .PSD
	case s[:4] == "\x53\x80\xF6\x34" && s[88:92] == "PICT":
		return .PIC
	case s[:4] == "\x69\x63\x6e\x73":
		return .ICNS
	case s[:4] == "\x46\x4c\x49\x46":
		return .FLIF
	case:
		// More complex formats
		if test_tga(s) {
			return .TGA
		}


	}
	return .Unknown
}
