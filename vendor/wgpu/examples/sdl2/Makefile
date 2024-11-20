FILES := $(wildcard *)

# NOTE: changing this requires changing the same values in the `web/index.html`.
INITIAL_MEMORY_PAGES := 2000
MAX_MEMORY_PAGES     := 65536

PAGE_SIZE := 65536
INITIAL_MEMORY_BYTES := $(shell expr $(INITIAL_MEMORY_PAGES) \* $(PAGE_SIZE))
MAX_MEMORY_BYTES     := $(shell expr $(MAX_MEMORY_PAGES) \* $(PAGE_SIZE))

web/triangle.wasm: $(FILES) ../../wgpu.js ../../../../core/sys/wasm/js/odin.js
	odin build . \
		-target:js_wasm32 -out:web/triangle.wasm -o:size \
        -extra-linker-flags:"--export-table --import-memory --initial-memory=$(INITIAL_MEMORY_BYTES) --max-memory=$(MAX_MEMORY_BYTES)"

	cp ../../wgpu.js web/wgpu.js
	cp ../../../../core/sys/wasm/js/odin.js web/odin.js
