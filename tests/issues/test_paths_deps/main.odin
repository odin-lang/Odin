package test_paths_deps

DATA :: #load("data.txt", string)

main :: proc() {
	assert(len(DATA) > 0)
}
