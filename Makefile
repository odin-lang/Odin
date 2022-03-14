all: debug demo

demo:
	./odin run examples/demo/demo.odin

report:
	./odin.sh report

debug:
	./build_odin.sh debug

release:
	./build_odin.sh release

release_native:
	./build_odin.sh release-native

nightly:
	./build_odin.sh nightly
