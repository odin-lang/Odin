ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) test image/test_core_image.odin
	rm test_core_image

compress_test:
	$(ODIN) test compress/test_core_compress.odin
	rm test_core_compress
