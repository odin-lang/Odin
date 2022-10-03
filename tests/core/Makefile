ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test strings_test hash_test crypto_test noise_test encoding_test \
	 math_test linalg_glsl_math_test filepath_test reflect_test c_libc_test os_exit_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) test image/test_core_image.odin -file

compress_test:
	$(ODIN) test compress/test_core_compress.odin -file

strings_test:
	$(ODIN) test strings/test_core_strings.odin -file

hash_test:
	$(ODIN) test hash -o:speed -no-bounds-check 

crypto_test:
	$(ODIN) test crypto -o:speed -no-bounds-check 

noise_test:
	$(ODIN) test math/noise

encoding_test:
	$(ODIN) test encoding/hxa
	$(ODIN) test encoding/json
	$(ODIN) test encoding/varint
	$(ODIN) test encoding/xml

math_test:
	$(ODIN) test math/test_core_math.odin -file

linalg_glsl_math_test:
	$(ODIN) test math/linalg/glsl/test_linalg_glsl_math.odin -file

filepath_test:
	$(ODIN) test path/filepath

reflect_test:
	$(ODIN) test reflect/test_core_reflect.odin -file

c_libc_test:
	$(ODIN) test c/libc

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -file && exit 1 || exit 0