all: default

demo:
	./odin run examples/demo/demo.odin -file

report:
	./odin report

default:
	PROGRAM=make ./build_odin.sh # debug

debug:
	./build_odin.sh debug

release:
	./build_odin.sh release

release-native:
	./build_odin.sh release-native

release_native:
	./build_odin.sh release-native

nightly:
	./build_odin.sh nightly
