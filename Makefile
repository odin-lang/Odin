all: debug

demo:
	./odin run examples/demo

report:
	./odin report

debug:
	./build_odin.sh debug

release:
	./build_odin.sh release

release_native:
	./build_odin.sh release-native

nightly:
	./build_odin.sh nightly
