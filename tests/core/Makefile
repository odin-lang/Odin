ODIN=../../odin
PYTHON=$(shell which python3)

all: c_libc_test \
	 compress_test \
	 crypto_test \
	 download_test_assets \
	 encoding_test \
	 filepath_test \
	 fmt_test \
	 hash_test \
	 i18n_test \
	 image_test \
	 linalg_glsl_math_test \
	 match_test \
	 math_test \
	 net_test \
	 noise_test \
	 os_exit_test \
	 reflect_test \
	 slice_test \
	 strings_test \
	 thread_test \
	 runtime_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) run image/test_core_image.odin -file -out:test_core_image

compress_test:
	$(ODIN) run compress/test_core_compress.odin -file -out:test_core_compress

strings_test:
	$(ODIN) run strings/test_core_strings.odin -file -out:test_core_strings

hash_test:
	$(ODIN) run hash -o:speed -no-bounds-check -out:test_hash 

crypto_test:
	$(ODIN) run crypto -o:speed -no-bounds-check -out:test_crypto

noise_test:
	$(ODIN) run math/noise -out:test_noise

encoding_test:
	$(ODIN) run encoding/hxa    -out:test_hxa -collection:tests=..
	$(ODIN) run encoding/json   -out:test_json
	$(ODIN) run encoding/varint -out:test_varint
	$(ODIN) run encoding/xml    -out:test_xml

math_test:
	$(ODIN) run math/test_core_math.odin -file -collection:tests=.. -out:test_core_math

linalg_glsl_math_test:
	$(ODIN) run math/linalg/glsl/test_linalg_glsl_math.odin -file -collection:tests=.. -out:test_linalg_glsl_math

filepath_test:
	$(ODIN) run path/filepath/test_core_filepath.odin -file -collection:tests=.. -out:test_core_filepath

reflect_test:
	$(ODIN) run reflect/test_core_reflect.odin -file -collection:tests=.. -out:test_core_reflect

slice_test:
	$(ODIN) run slice/test_core_slice.odin -file -out:test_core_slice

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -file -out:test_core_os_exit && exit 1 || exit 0

i18n_test:
	$(ODIN) run text/i18n -out:test_core_i18n

match_test:
	$(ODIN) run text/match -out:test_core_match

c_libc_test:
	$(ODIN) run c/libc -out:test_core_libc

net_test:
	$(ODIN) run net -out:test_core_net

fmt_test:
	$(ODIN) run fmt -out:test_core_fmt

thread_test:
	$(ODIN) run thread -out:test_core_thread

runtime_test:
	$(ODIN) run runtime -out:test_core_runtime
