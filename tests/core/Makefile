ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test strings_test hash_test crypto_test noise_test encoding_test \
<<<<<<< HEAD
	 math_test linalg_glsl_math_test os2_test
=======
	 math_test linalg_glsl_math_test filepath_test reflect_test os_exit_test
>>>>>>> upstream/master

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) run image/test_core_image.odin -file

compress_test:
	$(ODIN) run compress/test_core_compress.odin -file

strings_test:
	$(ODIN) run strings/test_core_strings.odin -file

hash_test:
	$(ODIN) run hash -out=test_hash -o:speed -no-bounds-check

crypto_test:
	$(ODIN) run crypto -out=test_crypto_hash -o:speed -no-bounds-check

noise_test:
	$(ODIN) run math/noise -out=test_noise

encoding_test:
	$(ODIN) run encoding/hxa -out=test_hxa -collection:tests=..
	$(ODIN) run encoding/json -out=test_json
	$(ODIN) run encoding/varint -out=test_varint

math_test:
	$(ODIN) run math/test_core_math.odin -out=test_core_math -file -collection:tests=..

linalg_glsl_math_test:
	$(ODIN) run math/linalg/glsl/test_linalg_glsl_math.odin -file -out=test_linalg_glsl_math -collection:tests=..

filepath_test:
	$(ODIN) run path/filepath/test_core_filepath.odin -file -out=test_core_filepath -collection:tests=..

reflect_test:
	$(ODIN) run reflect/test_core_reflect.odin -file -out=test_core_reflect -collection:tests=..

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -file -out=test_core_os_exit && exit 1 || exit 0

os2_test:
	$(ODIN) run os2/test_os2.odin -out=test_os2
