package tests_core

import rlibc "core:c/libc"

@(init)
download_assets :: proc "contextless" () {
	if rlibc.system("python3 " + ODIN_ROOT + "tests/core/download_assets.py " + ODIN_ROOT + "tests/core/assets") != 0 {
		panic_contextless("downloading test assets failed!")
	}
}

@(require) import "archive/sevenz"
@(require) import "archive/tar"
@(require) import "archive/zip"
@(require) import "compress"
