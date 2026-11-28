package test_issue_8177

Case :: struct {
	name:  string,
	items: []int,
}

CASES :: []Case{
	{"one", {1, 2, 3}},
	{"two", {4, 5}},
}

global_ints := []int{1, 2, 3}
global_cases := []Case{{"three", {6, 7}}}
global_nested := [][]u8{{1}, {2, 3}}
global_bytes := #load("data/a.txt", []byte)
global_u16s := #load("data/a.txt", []u16)
global_dir := #load_directory("data")

expect :: proc(ok: bool, what: string) {
	if !ok {
		panic(what)
	}
}

main :: proc() {
	expect(len(global_ints) == 3 && global_ints[1] == 2, "global_ints")

	expect(len(global_cases) == 1 && global_cases[0].name == "three", "global_cases")
	expect(len(global_cases[0].items) == 2 && global_cases[0].items[1] == 7, "global_cases items")

	cases := CASES
	expect(len(cases) == 2 && cases[1].name == "two", "CASES")
	expect(len(cases[0].items) == 3 && cases[0].items[2] == 3, "CASES items")

	expect(len(global_nested) == 2 && len(global_nested[1]) == 2 && global_nested[1][1] == 3, "global_nested")

	expect(string(global_bytes) == "0123456789abcdef", "global_bytes")
	expect(len(global_u16s) == 8 && global_u16s[0] == u16('0') | u16('1') << 8, "global_u16s")

	expect(len(global_dir) == 1 && global_dir[0].name == "a.txt", "global_dir")
	expect(len(global_dir) == 1 && string(global_dir[0].data) == "0123456789abcdef", "global_dir data")
}
