ODIN=../../odin
PYTHON=$(shell which python3)
COMMON=-no-bounds-check -vet -strict-style
COLLECTION=-collection:tests=..

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
         os_exit_test \
         reflect_test \
         runtime_test \
         slice_test \
         strings_test \
         thread_test \
         time_test

download_test_assets:
	$(PYTHON) download_assets.py

c_libc_test:
	$(ODIN) run c/libc $(COMMON) -out:test_core_libc

compress_test:
	$(ODIN) test compress $(COMMON) -out:test_core_compress

container_test:
	$(ODIN) test container $(COMMON) -out:test_core_container

crypto_test:
	$(ODIN) test crypto $(COMMON) -o:speed -out:test_crypto

encoding_test:
	$(ODIN) test encoding/base64 $(COMMON) -out:test_base64
	$(ODIN) test encoding/cbor   $(COMMON) -out:test_cbor
	$(ODIN) run encoding/hex     $(COMMON) -out:test_hex
	$(ODIN) run encoding/hxa     $(COMMON) $(COLLECTION) -out:test_hxa
	$(ODIN) run encoding/json    $(COMMON) -out:test_json
	$(ODIN) run encoding/varint  $(COMMON) -out:test_varint
	$(ODIN) run encoding/xml     $(COMMON) -out:test_xml

filepath_test:
	$(ODIN) run path/filepath $(COMMON) $(COLLECTION) -out:test_core_filepath

fmt_test:
	$(ODIN) run fmt $(COMMON) -out:test_core_fmt

hash_test:
	$(ODIN) run hash $(COMMON) -o:speed -out:test_hash

i18n_test:
	$(ODIN) run text/i18n $(COMMON) -out:test_core_i18n

image_test:
	$(ODIN) test image $(COMMON) -out:test_core_image

linalg_glsl_math_test:
	$(ODIN) run math/linalg/glsl $(COMMON) $(COLLECTION) -out:test_linalg_glsl_math

match_test:
	$(ODIN) run text/match $(COMMON) -out:test_core_match

math_test:
	$(ODIN) run math $(COMMON) $(COLLECTION) -out:test_core_math

net_test:
	$(ODIN) run net $(COMMON) -out:test_core_net

noise_test:
	$(ODIN) run math/noise $(COMMON) -out:test_noise

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -file -out:test_core_os_exit && exit 1 || exit 0

reflect_test:
	$(ODIN) run reflect $(COMMON) $(COLLECTION) -out:test_core_reflect

runtime_test:
	$(ODIN) run runtime $(COMMON) -out:test_core_runtime

slice_test:
	$(ODIN) run slice $(COMMON) -out:test_core_slice

strings_test:
	$(ODIN) run strings $(COMMON) -out:test_core_strings

thread_test:
	$(ODIN) run thread $(COMMON) -out:test_core_thread

time_test:
	$(ODIN) run time $(COMMON) -out:test_core_time