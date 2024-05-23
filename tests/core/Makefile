ODIN=../../odin
PYTHON=$(shell which python3)
COMMON=-vet -strict-style
COLLECTION=-collection:tests=..

all: all_bsd \
     net_test

all_bsd: c_libc_test \
         compress_test \
         container_test \
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
         noise_test \
         os_exit_test \
         reflect_test \
         slice_test \
         strings_test \
         thread_test \
         runtime_test \
         time_test \
         fmt_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) run image $(COMMON) -out:test_core_image

compress_test:
	$(ODIN) run compress $(COMMON) -out:test_core_compress

container_test:
	$(ODIN) run container $(COMMON) $(COLLECTION) -out:test_core_container

strings_test:
	$(ODIN) run strings $(COMMON) -out:test_core_strings

hash_test:
	$(ODIN) run hash $(COMMON) -o:speed -no-bounds-check -out:test_hash

crypto_test:
	$(ODIN) run crypto $(COMMON) $(COLLECTION) -o:speed -no-bounds-check -out:test_crypto

noise_test:
	$(ODIN) run math/noise $(COMMON) -out:test_noise

encoding_test:
	$(ODIN) run encoding/hxa    $(COMMON) $(COLLECTION) -out:test_hxa
	$(ODIN) run encoding/json   $(COMMON) -out:test_json
	$(ODIN) run encoding/varint $(COMMON) -out:test_varint
	$(ODIN) run encoding/xml    $(COMMON) -out:test_xml
	$(ODIN) run encoding/cbor   $(COMMON) -out:test_cbor
	$(ODIN) run encoding/hex    $(COMMON) -out:test_hex
	$(ODIN) run encoding/base64 $(COMMON) -out:test_base64

math_test:
	$(ODIN) run math $(COMMON) $(COLLECTION) -out:test_core_math

linalg_glsl_math_test:
	$(ODIN) run math/linalg/glsl $(COMMON) $(COLLECTION) -out:test_linalg_glsl_math

filepath_test:
	$(ODIN) run path/filepath $(COMMON) $(COLLECTION) -out:test_core_filepath

reflect_test:
	$(ODIN) run reflect $(COMMON) $(COLLECTION) -out:test_core_reflect

slice_test:
	$(ODIN) run slice $(COMMON) -out:test_core_slice

os_exit_test:
	$(ODIN) run os/test_core_os_exit.odin -file -out:test_core_os_exit && exit 1 || exit 0

i18n_test:
	$(ODIN) run text/i18n $(COMMON) -out:test_core_i18n

match_test:
	$(ODIN) run text/match $(COMMON) -out:test_core_match

c_libc_test:
	$(ODIN) run c/libc $(COMMON) -out:test_core_libc

net_test:
	$(ODIN) run net $(COMMON) -out:test_core_net

fmt_test:
	$(ODIN) run fmt $(COMMON) -out:test_core_fmt

thread_test:
	$(ODIN) run thread $(COMMON) -out:test_core_thread

runtime_test:
	$(ODIN) run runtime $(COMMON) -out:test_core_runtime

time_test:
	$(ODIN) run time $(COMMON) -out:test_core_time
