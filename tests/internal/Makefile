ODIN=../../odin
COMMON=-file -vet -strict-style -o:minimal

all: asan_test rtti_test map_test pow_test 128_test string_compare_test

rtti_test:
	$(ODIN) test test_rtti.odin $(COMMON)

map_test:
	$(ODIN) test test_map.odin $(COMMON)

pow_test:
	$(ODIN) test test_pow.odin $(COMMON)

128_test:
	$(ODIN) test test_128.odin $(COMMON)

asan_test:
	$(ODIN) test test_asan.odin $(COMMON) -sanitize:address -debug

string_compare_test:
	$(ODIN) test test_string_compare.odin $(COMMON)