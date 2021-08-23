/*
	SDL2 example for Odin.

	`SDL2.dll` needs to be available.
	If `USE_SDL2_IMAGE` is enabled, `SDL2_image.dll` and `libpng16-16.dll` also need to be present.

	On Windows this means placing them next to the executable.

	This example code is available as a Public Domain reference under the Unlicense (https://unlicense.org/),
	or under Odin's BSD-3 license. Choose whichever you prefer.
*/

package hellope
import "vendor:sdl2"
import "core:log"
import "core:os"
import core_img "core:image"
import "core:math"

USE_SDL2_IMAGE :: #config(USE_SDL2_IMAGE, true);

when USE_SDL2_IMAGE {
	import "core:strings"
	import sdl_img "vendor:sdl2/image"
} else {
	import "core:image/png"
}

WINDOW_TITLE  :: "Hellope World!";
WINDOW_X      := i32(400);
WINDOW_Y      := i32(400);
WINDOW_WIDTH  := i32(800);
WINDOW_HEIGHT := i32(600);
WINDOW_FLAGS  :: sdl2.WindowFlags{.SHOWN, };

/*
	If `true`, center the window using the desktop extents of the primary adapter.
	If `false`, position at WINDOW_X, WINDOW_Y.
*/
CENTER_WINDOW :: true;

/*
	Relative path to Odin logo
*/
ODIN_LOGO_PATH :: "../../../../misc/logo-slim.png";

Texture_Asset :: struct {
	tex: ^sdl2.Texture,
	w:   i32,
	h:   i32,

	scale: f32,
	pivot: struct {
		x: f32,
		y: f32,
	},
}

Surface :: struct {
	surf: ^sdl2.Surface,
	/*
		If using `core:image/png`, `img` will hold the pointer to the `Image` returned by `png.load`.
		Unused when `USE_SDL2_IMAGE` is enabled.
	*/
	img:  ^core_img.Image,
}

CTX :: struct {
	window:        ^sdl2.Window,
	surface:       ^sdl2.Surface,
	renderer:      ^sdl2.Renderer,
	textures:      [dynamic]Texture_Asset, 

	should_close:  bool,
	app_start:     f64,

	frame_start:   f64,
	frame_end:     f64,
	frame_elapsed: f64,

}

ctx := CTX{};

init_sdl :: proc() -> (ok: bool) {
	if sdl_res := sdl2.Init(sdl2.INIT_VIDEO); sdl_res < 0 {
		log.errorf("sdl2.init returned %v.", sdl_res);
		return false;
	}

	when USE_SDL2_IMAGE {
		img_init_flags := sdl_img.INIT_PNG;
		img_res        := sdl_img.InitFlags(sdl_img.Init(img_init_flags));
		if img_init_flags != img_res {
			log.errorf("sdl2_image.init returned %v.", img_res);
		}
	}

	if CENTER_WINDOW {
		/*
			Get desktop bounds for primary adapter
		*/
		bounds := sdl2.Rect{};
		if e := sdl2.GetDisplayBounds(0, &bounds); e != 0 {
			log.errorf("Unable to get desktop bounds.");
			return false;
		}

		WINDOW_X = ((bounds.w - bounds.x) / 2) - (WINDOW_WIDTH  / 2) + bounds.x;
		WINDOW_Y = ((bounds.h - bounds.y) / 2) - (WINDOW_HEIGHT / 2) + bounds.y;
	}

	ctx.window = sdl2.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_FLAGS);
	if ctx.window == nil {
		log.errorf("sdl2.CreateWindow failed.");
		return false;
	}

	ctx.surface = sdl2.GetWindowSurface(ctx.window);
	if ctx.surface == nil {
		log.errorf("sdl2.GetWindowSurface failed.");
		return false;
	}

	ctx.renderer = sdl2.CreateRenderer(ctx.window, -1, {.ACCELERATED, .PRESENTVSYNC});
	if ctx.surface == nil {
		log.errorf("sdl2.CreateRenderer failed.");
		return false;
	}

	return true;
}

when USE_SDL2_IMAGE { 
	load_surface_from_image_file :: proc(image_path: string) -> (surface: ^Surface) {
		path := strings.clone_to_cstring(image_path, context.temp_allocator);

		surface = new(Surface);
		surface.surf = sdl_img.Load(path);
		if surface.surf == nil {
			log.errorf("Couldn't load %v.", ODIN_LOGO_PATH);
		}
		return;
	}
} else {
	load_surface_from_image_file :: proc(image_path: string) -> (surface: ^Surface) {

		/*
			Load PNG using `core:image/png`.
		*/
		res_img, res_error := png.load(image_path);
		if res_error != nil {
			log.errorf("Couldn't load %v.", ODIN_LOGO_PATH);
			return nil;
		}

		surface = new(Surface);
		surface.img = res_img;

		/*
			Convert it into an SDL2 Surface.
		*/
  		rmask := u32(0x000000ff);
  		gmask := u32(0x0000ff00);
  		bmask := u32(0x00ff0000);
  		amask := u32(0xff000000) if res_img.channels == 4 else u32(0x0);

  		depth := i32(res_img.depth) * i32(res_img.channels);
  		pitch := i32(res_img.width) * i32(res_img.channels);

  		surface.surf = sdl2.CreateRGBSurfaceFrom(
  			raw_data(res_img.pixels.buf),
  			i32(res_img.width), i32(res_img.height), depth, pitch,
  			rmask, gmask, bmask, amask,
  		);

  		return;
	}
}

destroy_surface :: proc(surface: ^Surface) {
	assert(surface != nil);

	when !USE_SDL2_IMAGE {
		png.destroy(surface.img);
	}
	sdl2.FreeSurface(surface.surf);
	free(surface);
}

init_resources :: proc() -> (ok: bool) {
	logo_surface: ^Surface;

	if logo_surface = load_surface_from_image_file(ODIN_LOGO_PATH); logo_surface == nil {
		log.errorf("Couldn't load image %v.", ODIN_LOGO_PATH);
	}

	tex := sdl2.CreateTextureFromSurface(ctx.renderer, logo_surface.surf);
	if tex == nil {
		log.errorf("Couldn't convert image to texture.");
		return false;
	}
	odin_logo := Texture_Asset{
		tex = tex,
		w = logo_surface.surf.w,
		h = logo_surface.surf.h,

		/*
			By default the image is at scale 1, with the pivot in the middle of the image.
		*/
		scale = 1.00,
		pivot = { 0.5, 0.5, },
	};

	destroy_surface(logo_surface);
	append(&ctx.textures, odin_logo);

	return true;
}

draw :: proc() {
  	sdl2.SetRenderDrawColor(ctx.renderer, 255, 142, 27, 0xff);
  	sdl2.RenderClear(ctx.renderer);

  	tex := ctx.textures[0];
	r := sdl2.Rect{
		x = (WINDOW_WIDTH  / 2) - i32(f32(tex.w) * tex.scale * tex.pivot.x),
		y = (WINDOW_HEIGHT / 2) - i32(f32(tex.h) * tex.scale * tex.pivot.y),
		w = i32(f32(tex.w) * tex.scale),
		h = i32(f32(tex.h) * tex.scale),
	};
    sdl2.RenderCopy(ctx.renderer, tex.tex, nil, &r);
  	sdl2.RenderPresent(ctx.renderer);
}

cleanup :: proc() {
	defer delete(ctx.textures);
	sdl2.DestroyWindow(ctx.window);
	sdl2.Quit();
}

process_input :: proc() {
	e: sdl2.Event;

	for sdl2.PollEvent(&e) != 0 {
		#partial switch(e.type) {
		case .QUIT:
			ctx.should_close = true;
		case .KEYDOWN:
			#partial switch(e.key.keysym.sym) {
			case .ESCAPE:
				ctx.should_close = true;
			}
		}
	}
}

update :: proc() {
	breathe_speed := math.PI * 0.35;
	time_running  := ctx.frame_start - ctx.app_start;
	angle         := breathe_speed * time_running;

	ctx.textures[0].scale = 0.75 + f32(math.sin(angle)) * 0.5;
	ctx.textures[0].pivot = { 0.5 + f32(math.cos(angle)), 0.5 + f32(math.sin(angle)) };
}

loop :: proc() {
	ctx.frame_start   = ctx.app_start;
	ctx.frame_elapsed = 0.001; // Set frame time to 1ms for the first frame to avoid problems.

	for !ctx.should_close {
		process_input();
		update();
		draw();

		ctx.frame_end     = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency());
		ctx.frame_elapsed = ctx.frame_end - ctx.frame_start;
		ctx.frame_start   = ctx.frame_end;
	}
}

main :: proc() {
	context.logger = log.create_console_logger();

	if res := init_sdl(); !res {
		log.errorf("Initialization failed.");
		os.exit(1);
	}

	if res := init_resources(); !res {
		log.errorf("Couldn't initialize resources.");
		os.exit(1);
	}
	defer cleanup();

	/*
		Global start time.
	*/
	ctx.app_start = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency());

	loop();

	now     := f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency());
	elapsed := now - ctx.app_start;
	log.infof("Finished in %v seconds!\n", elapsed);
}