#+build ignore
package png_example

import "core:image"
import "core:image/png"
import "core:image/tga"
import "core:fmt"
import "core:mem"

demo :: proc() {
	options := image.Options{.return_metadata}
	err:       image.Error
	img:      ^image.Image

	PNG_FILE :: ODIN_ROOT + "misc/logo-slim.png"

	img, err = png.load(PNG_FILE, options)
	defer png.destroy(img)

	if err != nil {
		fmt.eprintfln("Trying to read PNG file %v returned %v.", PNG_FILE, err)
	} else {
		fmt.printfln("Image: %vx%vx%v, %v-bit.", img.width, img.height, img.channels, img.depth)

		if v, ok := img.metadata.(^image.PNG_Info); ok {
			// Handle ancillary chunks as you wish.
			// We provide helper functions for a few types.
			for c in v.chunks {
				#partial switch c.header.type {
				case .tIME:
					if t, t_ok := png.core_time(c); t_ok {
						fmt.printfln("[tIME]: %v", t)
					}
				case .gAMA:
					if gama, gama_ok := png.gamma(c); gama_ok {
						fmt.printfln("[gAMA]: %v", gama)
					}
				case .pHYs:
					if phys, phys_ok := png.phys(c); phys_ok {
						if phys.unit == .Meter {
							xm    := f32(img.width)  / f32(phys.ppu_x)
							ym    := f32(img.height) / f32(phys.ppu_y)
							dpi_x, dpi_y := png.phys_to_dpi(phys)
							fmt.printfln("[pHYs] Image resolution is %v x %v pixels per meter.", phys.ppu_x, phys.ppu_y)
							fmt.printfln("[pHYs] Image resolution is %v x %v DPI.", dpi_x, dpi_y)
							fmt.printfln("[pHYs] Image dimensions are %v x %v meters.", xm, ym)
						} else {
							fmt.printfln("[pHYs] x: %v, y: %v pixels per unknown unit.", phys.ppu_x, phys.ppu_y)
						}
					}
				case .iTXt, .zTXt, .tEXt:
					res, ok_text := png.text(c)
					if ok_text {
						if c.header.type == .iTXt {
							fmt.printfln("[iTXt] %v (%v:%v): %v", res.keyword, res.language, res.keyword_localized, res.text)
						} else {
							fmt.printfln("[tEXt/zTXt] %v: %v", res.keyword, res.text)
						}
					}
					defer png.text_destroy(res)
				case .bKGD:
					fmt.printfln("[bKGD] %v", img.background)
				case .eXIf:
					if res, ok_exif := png.exif(c); ok_exif {
						/*
							Other than checking the signature and byte order, we don't handle Exif data.
							If you wish to interpret it, pass it to an Exif parser.
						*/
						fmt.printfln("[eXIf] %v", res)
					}
				case .PLTE:
					if plte, plte_ok := png.plte(c); plte_ok {
						fmt.printfln("[PLTE] %v", plte)
					} else {
						fmt.printfln("[PLTE] Error")
					}
				case .hIST:
					if res, ok_hist := png.hist(c); ok_hist {
						fmt.printfln("[hIST] %v", res)
					}
				case .cHRM:
					if res, ok_chrm := png.chrm(c); ok_chrm {
						fmt.printfln("[cHRM] %v", res)
					}
				case .sPLT:
					res, ok_splt := png.splt(c)
					if ok_splt {
						fmt.printfln("[sPLT] %v", res)
					}
					png.splt_destroy(res)
				case .sBIT:
					if res, ok_sbit := png.sbit(c); ok_sbit {
						fmt.printfln("[sBIT] %v", res)
					}
				case .iCCP:
					res, ok_iccp := png.iccp(c)
					if ok_iccp {
						fmt.printfln("[iCCP] %v", res)
					}
					png.iccp_destroy(res)
				case .sRGB:
					if res, ok_srgb := png.srgb(c); ok_srgb {
						fmt.printfln("[sRGB] Rendering intent: %v", res)
					}
				case:
					type := c.header.type
					name := png.chunk_type_to_name(&type)
					fmt.printfln("[%v]: %v", name, c.data)
				}
			}
		}
	}

	fmt.printfln("Done parsing metadata.")

	if err == nil && .do_not_decompress_image not_in options && .info not_in options {
		if err = tga.save("out.tga", img); err == nil {
			fmt.println("Saved decoded image.")
		} else {
			fmt.eprintfln("Error %v saving out.ppm.", err)
		}
	}
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	demo()

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %m", leak.location, leak.size)
	}
}