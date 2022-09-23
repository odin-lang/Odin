ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test strings_test hash_test crypto_test noise_test encoding_test \
	 math_test linalg_glsl_math_test filepath_test reflect_test os_exit_test i18n_test c_libc_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) test image/test_core_image.odin -file

compress_test:
	$(ODIN) test compress/test_core_compress.odin -file -out:test_core_compress

strings_test:
	$(ODIN) test strings/test_core_strings.odin -file -out:test_core_strings

hash_test:
	$(ODIN) test hash -o:speed -no-bounds-check -out:test_hash 

crypto_test:
	$(ODIN) test crypto -o:speed -no-bounds-check -out:test_crypto_hash 

noise_test:
	$(ODIN) test math/noise -out:test_noise

encoding_test:
	$(ODIN) test encoding/hxa    -out:test_hxa -collection:tests=..
	$(ODIN) test encoding/json   -out:test_json
	$(ODIN) test encoding/varint -out:test_varint
	$(ODIN) test encoding/xml    -out:test_xml

math_test:
	$(ODIN) test math/test_core_math.odin -file -collection:tests=.. -out:test_core_math

linalg_glsl_math_test:
	$(ODIN) test math/linalg/glsl/test_linalg_glsl_math.odin -file -collection:tests=.. -out:test_linalg_glsl_math

filepath_test:
	$(ODIN) test path/filepath/test_core_filepath.odin -file -collection:tests=.. -out:test_core_filepath

reflect_test:
	$(ODIN) test reflect/test_core_reflect.odin -file -collection:tests=.. -out:test_core_reflect

os_exit_test:
	$(ODIN) test os/test_core_os_exit.odin -file -out:test_core_os_exit && exit 1 || exit 0

i18n_test:
	$(ODIN) test text/i18n -out:test_core_i18n

c_libc_test:
	$(ODIN) test c/libc -out:test_core_libc