ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test strings_test hash_test crypto_test encoding_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) run image/test_core_image.odin -out=test_image -o:speed -no-bounds-check

compress_test:
	$(ODIN) run compress/test_core_compress.odin -out=test_compress -o:speed -no-bounds-check

strings_test:
	$(ODIN) run strings/test_core_strings.odin -out=test_strings -o:speed -no-bounds-check

odin_test:
	$(ODIN) run odin -out=test_odin -o:speed -no-bounds-check

hash_test:
	$(ODIN) run hash -out=test_hash -o:speed -no-bounds-check

crypto_test:
	$(ODIN) run crypto -out=crypto_hash -o:speed -no-bounds-check

encoding_test:
	$(ODIN) run encoding/json -out=test_encoding_json -o:speed -no-bounds-check
	$(ODIN) run encoding/xml  -out=test_encoding_xml  -o:speed -no-bounds-check
