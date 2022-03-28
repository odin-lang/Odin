ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test strings_test hash_test crypto_test noise_test encoding_test \
	 math_test linalg_glsl_math_test filepath_test reflect_test os_exit_test thread_pool_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) run image/test_core_image.odin

compress_test:
	$(ODIN) run compress/test_core_compress.odin

strings_test:
	$(ODIN) run strings/test_core_strings.odin

hash_test:
	$(ODIN) run hash -out=test_hash -o:speed -no-bounds-check

crypto_test:
	$(ODIN) run crypto -out=crypto_hash -o:speed -no-bounds-check

noise_test:
	$(ODIN) run math/noise -out=test_noise

encoding_test:
	$(ODIN) run encoding/hxa -out=test_hxa -collection:tests=..
	$(ODIN) run encoding/json -out=test_json
	$(ODIN) run encoding/varint -out=test_varint

math_test:
	$(ODIN) run math/test_core_math.odin -out=test_core_math -collection:tests=..

linalg_glsl_math_test:
	$(ODIN) run math/linalg/glsl/test_linalg_glsl_math.odin -out=test_linalg_glsl_math -collection:tests=..

filepath_test:
	$(ODIN) run path/filepath/test_core_filepath.odin -out=test_core_filepath -collection:tests=..

reflect_test:
	$(ODIN) run reflect/test_core_reflect.odin -out=test_core_reflect -collection:tests=..

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -out=test_core_os_exit && exit 1 || exit 0

thread_pool_test:
	$(ODIN) run thread/pool/test_core_thread_pool.odin -out=test_core_thread_pool && exit 1 || exit 0
