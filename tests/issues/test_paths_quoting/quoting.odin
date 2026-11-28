package test_paths_quoting

S :: #config(S, "")
T :: #config(T, "")

#assert(S == "a\"b\"")
#assert(T == "c d\\")

main :: proc() {
}
