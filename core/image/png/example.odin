//+ignore
package png

import "core:compress"
import "core:image"
import "core:image/png"
import "core:bytes"
import "core:fmt"

// For PPM writer
import "core:mem"
import "core:os"

main :: proc() {
	file: string;

	options := image.Options{};
	err:       compress.Error;
	img:      ^image.Image;

	file = "../../../misc/logo-slim.png";

	img, err = png.load(file, options);
	defer png.destroy(img);

	if err != png.E_General.OK {
		fmt.printf("Trying to read PNG file %v returned %v\n", file, err);
	} else {
		v:  png.Info;
		ok: bool;

		fmt.printf("Image: %vx%vx%v, %v-bit.\n", img.width, img.height, img.channels, img.depth);

		if v, ok = img.sidecar.(png.Info); ok {
			// Handle ancillary chunks as you wish.
			// We provide helper functions for a few types.
			for c in v.chunks {
				#partial switch (c.header.type) {
					case .tIME:
						t, _ := png.core_time(c);
						fmt.printf("[tIME]: %v\n", t);
					case .gAMA:
						fmt.printf("[gAMA]: %v\n", png.gamma(c));
					case .pHYs:
						phys := png.phys(c);
						if phys.unit == .Meter {
							xm    := f32(img.width)  / f32(phys.ppu_x);
							ym    := f32(img.height) / f32(phys.ppu_y);
							dpi_x, dpi_y := png.phys_to_dpi(phys);
							fmt.printf("[pHYs] Image resolution is %v x %v pixels per meter.\n", phys.ppu_x, phys.ppu_y);
							fmt.printf("[pHYs] Image resolution is %v x %v DPI.\n", dpi_x, dpi_y);
							fmt.printf("[pHYs] Image dimensions are %v x %v meters.\n", xm, ym);
						} else {
							fmt.printf("[pHYs] x: %v, y: %v pixels per unknown unit.\n", phys.ppu_x, phys.ppu_y);
						}
					case .iTXt, .zTXt, .tEXt:
						res, ok_text := png.text(c);
						if ok_text {
							if c.header.type == .iTXt {
								fmt.printf("[iTXt] %v (%v:%v): %v\n", res.keyword, res.language, res.keyword_localized, res.text);
							} else {
								fmt.printf("[tEXt/zTXt] %v: %v\n", res.keyword, res.text);
							}
						}
						defer png.text_destroy(res);
					case .bKGD:
						fmt.printf("[bKGD] %v\n", img.background);
					case .eXIf:
						res, ok_exif := png.exif(c);
						if ok_exif {
							/*
								Other than checking the signature and byte order, we don't handle Exif data.
								If you wish to interpret it, pass it to an Exif parser.
							*/
							fmt.printf("[eXIf] %v\n", res);
						}
					case .PLTE:
						plte, plte_ok := png.plte(c);
						if plte_ok {
							fmt.printf("[PLTE] %v\n", plte);
						} else {
							fmt.printf("[PLTE] Error\n");
						}
					case .hIST:
						res, ok_hist := png.hist(c);
						if ok_hist {
							fmt.printf("[hIST] %v\n", res);
						}
					case .cHRM:
						res, ok_chrm := png.chrm(c);
						if ok_chrm {
							fmt.printf("[cHRM] %v\n", res);
						}
					case .sPLT:
						res, ok_splt := png.splt(c);
						if ok_splt {
							fmt.printf("[sPLT] %v\n", res);
						}
						png.splt_destroy(res);
					case .sBIT:
						if res, ok_sbit := png.sbit(c); ok_sbit {
							fmt.printf("[sBIT] %v\n", res);
						}
					case .iCCP:
						res, ok_iccp := png.iccp(c);
						if ok_iccp {
							fmt.printf("[iCCP] %v\n", res);
						}
						png.iccp_destroy(res);
					case .sRGB:
						if res, ok_srgb := png.srgb(c); ok_srgb {
							fmt.printf("[sRGB] Rendering intent: %v\n", res);
						}
					case:
						type := c.header.type;
						name := png.chunk_type_to_name(&type);
						fmt.printf("[%v]: %v\n", name, c.data);
				}
			}
		}
	}

	if err == E_General.OK && .do_not_decompress_image not_in options && .info not_in options {
		if ok := write_image_as_ppm("out.ppm", img); ok {
			fmt.println("Saved decoded image.");
		} else {
			fmt.println("Error saving out.ppm.");
			fmt.println(img);
		}
	}
}

// Crappy PPM writer used during testing. Don't use in production.
write_image_as_ppm :: proc(filename: string, image: ^image.Image) -> (success: bool) {

	_bg :: proc(bg: Maybe([3]u16), x, y: int, high := true) -> (res: [3]u16) {
		if v, ok := bg.?; ok {
			res = v;
		} else {
			if high {
				l := u16(30 * 256 + 30);

				if (x & 4 == 0) ~ (y & 4 == 0) {
					res = [3]u16{l, 0, l};
				} else {
					res = [3]u16{l >> 1, 0, l >> 1};
				}
			} else {
				if (x & 4 == 0) ~ (y & 4 == 0) {
					res = [3]u16{30, 30, 30};
				} else {
					res = [3]u16{15, 15, 15};
				}
			}
		}
		return;
	}

	// profiler.timed_proc();
	using image;
	using os;

	flags: int = O_WRONLY|O_CREATE|O_TRUNC;

	img := image;

	// PBM 16-bit images are big endian
	when ODIN_ENDIAN == "little" {
		if img.depth == 16 {
			// The pixel components are in Big Endian. Let's byteswap back.
			input  := mem.slice_data_cast([]u16,   img.pixels.buf[:]);
			output := mem.slice_data_cast([]u16be, img.pixels.buf[:]);
			#no_bounds_check for v, i in input {
				output[i] = u16be(v);
			}
		}
	}

	pix := bytes.buffer_to_bytes(&img.pixels);

	if len(pix) == 0 || len(pix) < image.width * image.height * int(image.channels) {
		return false;
	}

	mode: int = 0;
	when ODIN_OS == "linux" || ODIN_OS == "darwin" {
		// NOTE(justasd): 644 (owner read, write; group read; others read)
		mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
	}

	fd, err := open(filename, flags, mode);
	if err != 0 {
		return false;
	}
	defer close(fd);

	write_string(fd,
		fmt.tprintf("P6\n%v %v\n%v\n", width, height, (1 << depth -1)),
	);

	if channels == 3 {
		// We don't handle transparency here...
		write_ptr(fd, raw_data(pix), len(pix));
	} else {
		bpp := depth == 16 ? 2 : 1;
		bytes_needed := width * height * 3 * bpp;

		op := bytes.Buffer{};
		bytes.buffer_init_allocator(&op, bytes_needed, bytes_needed);
		defer bytes.buffer_destroy(&op);

		if channels == 1 {
			if depth == 16 {
				assert(len(pix) == width * height * 2);
				p16 := mem.slice_data_cast([]u16, pix);
				o16 := mem.slice_data_cast([]u16, op.buf[:]);
				#no_bounds_check for len(p16) != 0 {
					r := u16(p16[0]);
					o16[0] = r;
					o16[1] = r;
					o16[2] = r;
					p16 = p16[1:];
					o16 = o16[3:];
				}
			} else {
				o := 0;
				for i := 0; i < len(pix); i += 1 {
					r := pix[i];
					op.buf[o  ] = r;
					op.buf[o+1] = r;
					op.buf[o+2] = r;
					o += 3;
				}
			}
			write_ptr(fd, raw_data(op.buf), len(op.buf));
		} else if channels == 2 {
			if depth == 16 {
				p16 := mem.slice_data_cast([]u16, pix);
				o16 := mem.slice_data_cast([]u16, op.buf[:]);

				bgcol := img.background;

				#no_bounds_check for len(p16) != 0 {
					r  := f64(u16(p16[0]));
					bg:   f64;
					if bgcol != nil {
						v := bgcol.([3]u16)[0];
						bg = f64(v);
					}
					a  := f64(u16(p16[1])) / 65535.0;
					l  := (a * r) + (1 - a) * bg;

					o16[0] = u16(l);
					o16[1] = u16(l);
					o16[2] = u16(l);

					p16 = p16[2:];
					o16 = o16[3:];
				}
			} else {
				o := 0;
				for i := 0; i < len(pix); i += 2 {
					r := pix[i]; a := pix[i+1]; a1 := f32(a) / 255.0;
					c := u8(f32(r) * a1);
					op.buf[o  ] = c;
					op.buf[o+1] = c;
					op.buf[o+2] = c;
					o += 3;
				}
			}
			write_ptr(fd, raw_data(op.buf), len(op.buf));
		} else if channels == 4 {
			if depth == 16 {
				p16 := mem.slice_data_cast([]u16be, pix);
				o16 := mem.slice_data_cast([]u16be, op.buf[:]);

				#no_bounds_check for len(p16) != 0 {

					bg := _bg(img.background, 0, 0);
					r     := f32(p16[0]);
					g     := f32(p16[1]);
					b     := f32(p16[2]);
					a     := f32(p16[3]) / 65535.0;

					lr  := (a * r) + (1 - a) * f32(bg[0]);
					lg  := (a * g) + (1 - a) * f32(bg[1]);
					lb  := (a * b) + (1 - a) * f32(bg[2]);

					o16[0] = u16be(lr);
					o16[1] = u16be(lg);
					o16[2] = u16be(lb);

					p16 = p16[4:];
					o16 = o16[3:];
				}
			} else {
				o := 0;

				for i := 0; i < len(pix); i += 4 {

					x := (i / 4)  % width;
					y := i / width / 4;

					_b := _bg(img.background, x, y, false);
					bgcol := [3]u8{u8(_b[0]), u8(_b[1]), u8(_b[2])};

					r := f32(pix[i]);
					g := f32(pix[i+1]);
					b := f32(pix[i+2]);
					a := f32(pix[i+3]) / 255.0;

					lr := u8(f32(r) * a + (1 - a) * f32(bgcol[0]));
					lg := u8(f32(g) * a + (1 - a) * f32(bgcol[1]));
					lb := u8(f32(b) * a + (1 - a) * f32(bgcol[2]));
					op.buf[o  ] = lr;
					op.buf[o+1] = lg;
					op.buf[o+2] = lb;
					o += 3;
				}
			}
			write_ptr(fd, raw_data(op.buf), len(op.buf));
		} else {
			return false;
		}
	}
	return true;
}
