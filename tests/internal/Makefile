ODIN=../../odin

all: all_bsd asan_test

all_bsd: rtti_test map_test pow_test 128_test string_compare_test

rtti_test:
	$(ODIN) run test_rtti.odin -file -vet -strict-style -o:minimal

map_test:
	$(ODIN) run test_map.odin -file -vet -strict-style -o:minimal

pow_test:
	$(ODIN) run test_pow.odin -file -vet -strict-style -o:minimal

128_test:
	$(ODIN) run test_128.odin -file -vet -strict-style -o:minimal

asan_test:
	$(ODIN) run test_asan.odin -file -sanitize:address -debug

string_compare_test:
	$(ODIN) run test_string_compare.odin -file -vet -strict-style -o:minimal
