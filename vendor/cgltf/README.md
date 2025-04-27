# :diamond_shape_with_a_dot_inside: cgltf
**glTF loader and writer**
(**Single-file/stb-style C glTF loader and writer**)

Used in: [bgfx](https://github.com/bkaradzic/bgfx), [Filament](https://github.com/google/filament), [gltfpack](https://github.com/zeux/meshoptimizer/tree/master/gltf), [raylib](https://github.com/raysan5/raylib), [Unigine](https://developer.unigine.com/en/docs/2.14.1/third_party?rlang=cpp#cgltf), and more!

## Usage: Loading
Loading from file:
```odin
package main

import "vendor:cgltf"

main :: proc() {
	options: cgltf.options
	data, result := cgltf.parse_file(&options, "scene.gltf")
	if result != .success {
		/* TODO handle error */
	}
	defer cgltf.free(data)
	/* TODO make awesome stuff */
}
```

Loading from memory:
```odin
package main

import "vendor:cgltf"

main :: proc() {
	buf: []byte = ... // data to glb or gltf file data

	options: cgltf.options
	data, result := cgltf.parse(&options, raw_data(buf), len(buf))
	if result != .success {
		/* TODO handle error */
	}
	defer cgltf.free(data)
	/* TODO make awesome stuff */
}
```


Note that cgltf does not load the contents of extra files such as buffers or images into memory by default. You'll need to read these files yourself using URIs from `data.buffers[]` or `data.images[]` respectively.
For buffer data, you can alternatively call `cgltf.load_buffers`, which will use `^clib.FILE` APIs to open and read buffer files. This automatically decodes base64 data URIs in buffers. For data URIs in images, you will need to use `cgltf.load_buffer_base64`.

**For more in-depth documentation and a description of the public interface refer to the top of the `cgltf.h` file.**

## Usage: Writing
When writing glTF data, you need a valid `cgltf.data` structure that represents a valid glTF document. You can construct such a structure yourself or load it using the loader functions described above. The writer functions do not deallocate any memory. So, you either have to do it manually or call `cgltf.free()` if you got the data by loading it from a glTF document.

Writing to file:
```odin
package main

import "vendor:cgltf"

main :: proc() {
	options: cgltf.options
	data: ^cgltf.data = /* TODO must be valid data */
	result := cgltf.write_file(&options, "out.gltf", data)
	if result != .success {
		/* TODO handle error */
	}
}
```

Writing to memory:
```odin
package main

import "vendor:cgltf"

main :: proc() {
	options: cgltf.options
	data: ^cgltf.data = /* TODO must be valid data */

	size := cgltf.write(&options, nil, 0, data)

	buf := make([]byte, size)

	written := cgltf.write(&options, raw_data(buf), size, data)
	if written != size {
		/* TODO handle error */
	}
}
```

Note that cgltf does not write the contents of extra files such as buffers or images. You'll need to write this data yourself.

**For more in-depth documentation and a description of the public interface refer to the top of the `cgltf_write.h` file.**


## Features
cgltf supports core glTF 2.0:
- glb (binary files) and gltf (JSON files)
- meshes (including accessors, buffer views, buffers)
- materials (including textures, samplers, images)
- scenes and nodes
- skins
- animations
- cameras
- morph targets
- extras data

cgltf also supports some glTF extensions:
- EXT_mesh_gpu_instancing
- EXT_meshopt_compression
- KHR_draco_mesh_compression (requires a library like [Google's Draco](https://github.com/google/draco) for decompression though)
- KHR_lights_punctual
- KHR_materials_clearcoat
- KHR_materials_emissive_strength
- KHR_materials_ior
- KHR_materials_iridescence
- KHR_materials_pbrSpecularGlossiness
- KHR_materials_sheen
- KHR_materials_specular
- KHR_materials_transmission
- KHR_materials_unlit
- KHR_materials_variants
- KHR_materials_volume
- KHR_texture_basisu (requires a library like [Binomial Basisu](https://github.com/BinomialLLC/basis_universal) for transcoding to native compressed texture)
- KHR_texture_transform

cgltf does **not** yet support unlisted extensions. However, unlisted extensions can be accessed via "extensions" member on objects.

## Contributing
Everyone is welcome to contribute to the library. If you find any problems, you can submit them using [GitHub's issue system](https://github.com/jkuhlmann/cgltf/issues). If you want to contribute code, you should fork the project and then send a pull request.


## Dependencies
None.

C headers being used by the implementation:
```
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <assert.h> // If asserts are enabled.
```

Note, this library has a copy of the [JSMN JSON parser](https://github.com/zserge/jsmn) embedded in its source.
