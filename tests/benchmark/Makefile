ODIN=../../odin
COMMON=-no-bounds-check -vet -strict-style -define:ODIN_TEST_FANCY=false

all: crypto_bench \
     hash_bench

crypto_bench:
	$(ODIN) test crypto $(COMMON) -o:speed -out:bench_crypto

hash_bench:
	$(ODIN) test hash $(COMMON) -o:speed -out:bench_hash

clean:
	rm bench_*