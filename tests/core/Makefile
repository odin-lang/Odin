ODIN=../../odin
PYTHON=$(shell which python3)
COMMON=-no-bounds-check -vet -strict-style -define:ODIN_TEST_FANCY=false

all: all_bsd \
     net_test

all_bsd: download_test_assets \
         c_libc_test \
         compress_test \
         container_test \
         crypto_test \
         encoding_test \
         filepath_test \
         fmt_test \
         hash_test \
         i18n_test \
         image_test \
         linalg_glsl_math_test \
         match_test \
         math_test \
         noise_test \
         odin_test \
         os_exit_test \
         reflect_test \
         runtime_test \
         slice_test \
         strconv_test \
         strings_test \
         thread_test \
         time_test

download_test_assets:
	$(PYTHON) download_assets.py

c_libc_test:
	$(ODIN) test c/libc $(COMMON) -out:test_core_libc

compress_test:
	$(ODIN) test compress $(COMMON) -out:test_core_compress

container_test:
	$(ODIN) test container $(COMMON) -out:test_core_container

crypto_test:
	$(ODIN) test crypto $(COMMON) -o:speed -out:test_crypto

encoding_test:
	$(ODIN) test encoding/base64 $(COMMON) -out:test_base64
	$(ODIN) test encoding/cbor   $(COMMON) -out:test_cbor
	$(ODIN) test encoding/hex    $(COMMON) -out:test_hex
	$(ODIN) test encoding/hxa    $(COMMON) -out:test_hxa
	$(ODIN) test encoding/json   $(COMMON) -out:test_json
	$(ODIN) test encoding/varint $(COMMON) -out:test_varint
	$(ODIN) test encoding/xml    $(COMMON) -out:test_xml

filepath_test:
	$(ODIN) test path/filepath $(COMMON) -out:test_core_filepath

fmt_test:
	$(ODIN) test fmt $(COMMON) -out:test_core_fmt

hash_test:
	$(ODIN) test hash $(COMMON) -o:speed -out:test_hash

image_test:
	$(ODIN) test image $(COMMON) -out:test_core_image

i18n_test:
	$(ODIN) test text/i18n $(COMMON) -out:test_core_i18n

match_test:
	$(ODIN) test text/match $(COMMON) -out:test_core_match

math_test:
	$(ODIN) test math $(COMMON) -out:test_core_math

linalg_glsl_math_test:
	$(ODIN) test math/linalg/glsl $(COMMON) -out:test_linalg_glsl_math

noise_test:
	$(ODIN) test math/noise $(COMMON) -out:test_noise

net_test:
	$(ODIN) test net $(COMMON) -out:test_core_net

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -file -out:test_core_os_exit && exit 1 || exit 0

odin_test:
	$(ODIN) test odin $(COMMON) -out:test_core_odin

reflect_test:
	$(ODIN) test reflect $(COMMON) -out:test_core_reflect

runtime_test:
	$(ODIN) test runtime $(COMMON) -out:test_core_runtime

slice_test:
	$(ODIN) test slice $(COMMON) -out:test_core_slice

strconv_test:
	$(ODIN) test strconv $(COMMON) -out:test_core_strconv

strings_test:
	$(ODIN) test strings $(COMMON) -out:test_core_strings

thread_test:
	$(ODIN) test thread $(COMMON) -out:test_core_thread

time_test:
	$(ODIN) test time $(COMMON) -out:test_core_time

clean:
	rm test_*